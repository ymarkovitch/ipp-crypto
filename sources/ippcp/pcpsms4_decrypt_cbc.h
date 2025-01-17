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
// 
//  Purpose:
//     Cryptography Primitive.
//     SMS4 encryption/decryption
// 
//  Contents:
//        cpDecryptSMS4_cbc()
//
*/

#include "owncp.h"
#include "pcpsms4.h"
#include "pcptool.h"

#if !defined _PCP_SMS4_DECRYPT_CBC_H
#define _PCP_SMS4_DECRYPT_CBC_H

/*F*
//    Name: ippsSMS4DecryptCBC
//
// Purpose: SMS4-CBC decryption.
//
// Returns:                Reason:
//    ippStsNullPtrErr        pCtx == NULL
//                            pSrc == NULL
//                            pDst == NULL
//                            pIV  == NULL
//    ippStsContextMatchErr   !VALID_SMS4_ID()
//    ippStsLengthErr         len <1
//    ippStsUnderRunErr       0!=(dataLen%MBS_SMS4)
//    ippStsNoErr             no errors
//
// Parameters:
//    pSrc        pointer to the source data buffer
//    pDst        pointer to the target data buffer
//    dataLen     input/output buffer length (in bytes)
//    pCtx        pointer to the SMS4 context
//    pIV         pointer to the initialization vector
//
*F*/
static void cpDecryptSMS4_cbc(const Ipp8u* pIV,
                              const Ipp8u* pSrc, Ipp8u* pDst, int dataLen,
                              const IppsSMS4Spec* pCtx)
{
   const Ipp32u* pRoundKeys = SMS4_DRK(pCtx);

   /* copy IV */
   Ipp32u iv[MBS_SMS4/sizeof(Ipp32u)];
   CopyBlock16(pIV, iv);

   /* do decryption */
   #if (_IPP>=_IPP_P8) || (_IPP32E>=_IPP32E_Y8)
   if(IsFeatureEnabled(ippCPUID_AES)) {
      int processedLen = cpSMS4_CBC_dec_aesni(pDst, pSrc, dataLen, pRoundKeys, (Ipp8u*)iv);
      pSrc += processedLen;
      pDst += processedLen;
      dataLen -= processedLen;
   }
   #endif

   for(; dataLen>0; dataLen-=MBS_SMS4, pSrc+=MBS_SMS4, pDst+=MBS_SMS4) {
      Ipp32u tmp[MBS_SMS4/sizeof(ipp32u)];

      cpSMS4_Cipher((Ipp8u*)tmp, (Ipp8u*)pSrc, pRoundKeys);

      tmp[0] ^= iv[0];
      tmp[1] ^= iv[1];
      tmp[2] ^= iv[2];
      tmp[3] ^= iv[3];

      iv[0] = ((Ipp32u*)pSrc)[0];
      iv[1] = ((Ipp32u*)pSrc)[1];
      iv[2] = ((Ipp32u*)pSrc)[2];
      iv[3] = ((Ipp32u*)pSrc)[3];

      CopyBlock16(tmp, pDst);
   }
}

#endif /* #if !defined _PCP_SMS4_DECRYPT_CBC_H */
