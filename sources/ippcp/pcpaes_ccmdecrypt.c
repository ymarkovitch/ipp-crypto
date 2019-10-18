/*******************************************************************************
* Copyright 2013-2019 Intel Corporation
* All Rights Reserved.
*
* If this  software was obtained  under the  Intel Simplified  Software License,
* the following terms apply:
*
* The source code,  information  and material  ("Material") contained  herein is
* owned by Intel Corporation or its  suppliers or licensors,  and  title to such
* Material remains with Intel  Corporation or its  suppliers or  licensors.  The
* Material  contains  proprietary  information  of  Intel or  its suppliers  and
* licensors.  The Material is protected by  worldwide copyright  laws and treaty
* provisions.  No part  of  the  Material   may  be  used,  copied,  reproduced,
* modified, published,  uploaded, posted, transmitted,  distributed or disclosed
* in any way without Intel's prior express written permission.  No license under
* any patent,  copyright or other  intellectual property rights  in the Material
* is granted to  or  conferred  upon  you,  either   expressly,  by implication,
* inducement,  estoppel  or  otherwise.  Any  license   under such  intellectual
* property rights must be express and approved by Intel in writing.
*
* Unless otherwise agreed by Intel in writing,  you may not remove or alter this
* notice or  any  other  notice   embedded  in  Materials  by  Intel  or Intel's
* suppliers or licensors in any way.
*
*
* If this  software  was obtained  under the  Apache License,  Version  2.0 (the
* "License"), the following terms apply:
*
* You may  not use this  file except  in compliance  with  the License.  You may
* obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
*
*
* Unless  required  by   applicable  law  or  agreed  to  in  writing,  software
* distributed under the License  is distributed  on an  "AS IS"  BASIS,  WITHOUT
* WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*
* See the   License  for the   specific  language   governing   permissions  and
* limitations under the License.
*******************************************************************************/

/*
//     Intel(R) Integrated Performance Primitives. Cryptography Primitives.
// 
//     Context:
//        ippsAES_CCMDecrypt()
//
*/

#include "owndefs.h"
#include "owncp.h"
#include "pcpaesauthccm.h"
#include "pcptool.h"

#if (_ALG_AES_SAFE_==_ALG_AES_SAFE_COMPOSITE_GF_)
#elif (_ALG_AES_SAFE_==_ALG_AES_SAFE_COMPACT_SBOX_)
#  include "pcprijtables.h"
#else
#endif

/*F*
//    Name: ippsAES_CCMDecrypt
//
// Purpose: Decrypts data and updates authentication tag.
//
// Returns:                Reason:
//    ippStsNullPtrErr        pState == NULL
//                            pSrc == NULL
//                            pDst == NULL
//    ippStsContextMatchErr   !VALID_AESCCM_ID()
//    ippStsLengthErr         if exceed overall length of message is being processed
//    ippStsNoErr             no errors
//
// Parameters:
//    pSrc        pointer to the cipher text beffer
//    pDst        pointer to the plane text bubber
//    len         length of the bugger
//    pState      pointer to the CCM context
//
*F*/
IPPFUN(IppStatus, ippsAES_CCMDecrypt,(const Ipp8u* pSrc, Ipp8u* pDst, int len, IppsAES_CCMState* pState))
{
   /* test pState pointer */
   IPP_BAD_PTR1_RET(pState);

   /* test state ID */
   IPP_BADARG_RET(idCtxAESCCM !=AESCCM_ID(pState), ippStsContextMatchErr);

   /* test source/destination data */
   IPP_BAD_PTR2_RET(pSrc, pDst);

   /* test message length */
   IPP_BADARG_RET(len<0 || AESCCM_LENPRO(pState)+len >AESCCM_MSGLEN(pState), ippStsLengthErr);

   /*
   // enctypt payload and update MAC
   */
   if(len) {
      /* setup encoder method */
      IppsAESSpec* pAES = AESCCM_CIPHER_ALIGNED(pState);
      RijnCipher encoder = RIJ_ENCODER(pAES);

      Ipp32u flag = (Ipp32u)( AESCCM_LENPRO(pState) &(MBS_RIJ128-1) );

      Ipp32u qLen;
      Ipp32u counterVal;

      Ipp32u MAC[NB(128)];
      Ipp32u CTR[NB(128)];
      Ipp32u   S[NB(128)];
      /* extract from the state */
      CopyBlock16(AESCCM_MAC(pState), MAC);
      CopyBlock16(AESCCM_CTR0(pState), CTR);
      CopyBlock16(AESCCM_Si(pState), S);
      counterVal = AESCCM_COUNTER(pState);

      /* extract qLen */
      qLen = (((Ipp8u*)CTR)[0] &0x7) +1; /* &0x7 just to fix KW issue */

      if(flag) {
         Ipp32u tmpLen = (Ipp32u)( IPP_MIN(len, MBS_RIJ128-1) );
         XorBlock(pSrc, (Ipp8u*)S+flag, pDst, tmpLen);

         /* copy as much input as possible into the internal buffer*/
         CopyBlock(pDst, AESCCM_BLK(pState)+flag, tmpLen);

         /* update MAC */
         if(flag+tmpLen == MBS_RIJ128) {
            XorBlock16(MAC, AESCCM_BLK(pState), MAC);
            //encoder(MAC, MAC, RIJ_NR(pAES), RIJ_EKEYS(pAES), (const Ipp32u (*)[256])RIJ_ENC_SBOX(pAES));
            #if (_ALG_AES_SAFE_==_ALG_AES_SAFE_COMPACT_SBOX_)
            encoder((Ipp8u*)MAC, (Ipp8u*)MAC, RIJ_NR(pAES), RIJ_EKEYS(pAES), RijEncSbox/*NULL*/);
            #else
            encoder((Ipp8u*)MAC, (Ipp8u*)MAC, RIJ_NR(pAES), RIJ_EKEYS(pAES), NULL);
            #endif
         }

         AESCCM_LENPRO(pState) += tmpLen;
         pSrc += tmpLen;
         pDst += tmpLen;
         len  -= tmpLen;
      }

      #if (_IPP>=_IPP_P8) || (_IPP32E>=_IPP32E_Y8)
      if(AES_NI_ENABLED==RIJ_AESNI(pAES)) {
         Ipp32u processedLen = len & -MBS_RIJ128;
         if(processedLen) {
            /* local state: MAC, counter block, counter bits mask */
            __ALIGN16 Ipp8u localState[3*MBS_RIJ128];

            /* format counter block and fill local state */
            Ipp32u n;
            for(n=0; n<MBS_RIJ128-qLen; n++) localState[MBS_RIJ128*2+n] = 0;
            for(n=MBS_RIJ128-qLen; n<MBS_RIJ128; n++) localState[MBS_RIJ128*2+n] = 0xFF;
            CopyBlock(CounterEnc((Ipp32u*)localState, qLen, counterVal), ((Ipp8u*)CTR)+MBS_RIJ128-qLen, qLen);
            CopyBlock(CTR, localState+MBS_RIJ128, MBS_RIJ128);
            CopyBlock(MAC, localState, MBS_RIJ128);

            /* encrypt and authenticate */
            DecryptAuth_RIJ128_AES_NI(pSrc, pDst, RIJ_NR(pAES), RIJ_EKEYS(pAES), processedLen, localState);

            /* update parameters */
            CopyBlock(localState, MAC, MBS_RIJ128);
            CopyBlock(localState+MBS_RIJ128, S, MBS_RIJ128);
            counterVal += processedLen/MBS_RIJ128;

            pSrc += processedLen;
            pDst += processedLen;
            len -= processedLen;
         }
      }
      #endif

      while(len >= MBS_RIJ128) {
         Ipp32u counterEnc[2];
         /* increment counter and format counter block */
         counterVal++;
         CopyBlock(CounterEnc(counterEnc, qLen, counterVal), ((Ipp8u*)CTR)+MBS_RIJ128-qLen, qLen);
         /* encode counter block */
         //encoder(CTR, S, RIJ_NR(pAES), RIJ_EKEYS(pAES), (const Ipp32u (*)[256])RIJ_ENC_SBOX(pAES));
         #if (_ALG_AES_SAFE_==_ALG_AES_SAFE_COMPACT_SBOX_)
         encoder((Ipp8u*)CTR, (Ipp8u*)S, RIJ_NR(pAES), RIJ_EKEYS(pAES), RijEncSbox/*NULL*/);
         #else
         encoder((Ipp8u*)CTR, (Ipp8u*)S, RIJ_NR(pAES), RIJ_EKEYS(pAES), NULL);
         #endif

         /* store cipher text */
         XorBlock16(pSrc, S, pDst);

         /* update MAC */
         XorBlock16(MAC, pDst, MAC);
         //encoder(MAC, MAC, RIJ_NR(pAES), RIJ_EKEYS(pAES), (const Ipp32u (*)[256])RIJ_ENC_SBOX(pAES));
         #if (_ALG_AES_SAFE_==_ALG_AES_SAFE_COMPACT_SBOX_)
         encoder((Ipp8u*)MAC, (Ipp8u*)MAC, RIJ_NR(pAES), RIJ_EKEYS(pAES), RijEncSbox/*NULL*/);
         #else
         encoder((Ipp8u*)MAC, (Ipp8u*)MAC, RIJ_NR(pAES), RIJ_EKEYS(pAES), NULL);
         #endif

         AESCCM_LENPRO(pState) += MBS_RIJ128;
         pSrc += MBS_RIJ128;
         pDst += MBS_RIJ128;
         len  -= MBS_RIJ128;
      }

      if(len) {
         Ipp32u counterEnc[2];
         /* increment counter and format counter block */
         counterVal++;
         CopyBlock(CounterEnc(counterEnc, qLen, counterVal), ((Ipp8u*)CTR)+MBS_RIJ128-qLen, qLen);
         /* encode counter block */
         //encoder(CTR, S, RIJ_NR(pAES), RIJ_EKEYS(pAES), (const Ipp32u (*)[256])RIJ_ENC_SBOX(pAES));
         #if (_ALG_AES_SAFE_==_ALG_AES_SAFE_COMPACT_SBOX_)
         encoder((Ipp8u*)CTR, (Ipp8u*)S, RIJ_NR(pAES), RIJ_EKEYS(pAES), RijEncSbox/*NULL*/);
         #else
         encoder((Ipp8u*)CTR, (Ipp8u*)S, RIJ_NR(pAES), RIJ_EKEYS(pAES), NULL);
         #endif

         /* store cipher text */
         XorBlock(pSrc, S, pDst, len);

         /* store partial data block */
         CopyBlock(pDst, AESCCM_BLK(pState), len);

         AESCCM_LENPRO(pState) += len;
      }

      /* update state */
      CopyBlock16(MAC, AESCCM_MAC(pState));
      CopyBlock16(S, AESCCM_Si(pState));
      AESCCM_COUNTER(pState) = counterVal;
   }

   return ippStsNoErr;
}
