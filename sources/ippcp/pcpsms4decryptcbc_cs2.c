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
//        ippsSMS4DecryptCBC_CS2()
//
*/

#include "owncp.h"
#include "pcpsms4.h"
#include "pcptool.h"
#include "pcpsms4_decrypt_cbc.h"

/*F*
//    Name: ippsSMS4DecryptCBC_CS2
//
// Purpose: SMS4-CBC_CS2 decryption.
//
// Returns:                Reason:
//    ippStsNullPtrErr        pCtx == NULL
//                            pSrc == NULL
//                            pDst == NULL
//                            pIV  == NULL
//    ippStsContextMatchErr   !VALID_SMS4_ID()
//    ippStsLengthErr         len <MBS_SMS4
//    ippStsNoErr             no errors
//
// Parameters:
//    pSrc        pointer to the source data buffer
//    pDst        pointer to the target data buffer
//    len         input/output buffer length (in bytes)
//    pCtx        pointer to the SMS4 context
//    pIV         pointer to the initialization vector
//
*F*/
IPPFUN(IppStatus, ippsSMS4DecryptCBC_CS2,(const Ipp8u* pSrc, Ipp8u* pDst, int len,
                                          const IppsSMS4Spec* pCtx,
                                          const Ipp8u* pIV))
{
   /* test context */
   IPP_BAD_PTR1_RET(pCtx);
   /* use aligned SMS4 context */
   pCtx = (IppsSMS4Spec*)( IPP_ALIGNED_PTR(pCtx, SMS4_ALIGNMENT) );
   /* test the context ID */
   IPP_BADARG_RET(!VALID_SMS4_ID(pCtx), ippStsContextMatchErr);

   /* test source, target buffers and initialization pointers */
   IPP_BAD_PTR3_RET(pSrc, pIV, pDst);
   /* test stream length */
   IPP_BADARG_RET((len<MBS_SMS4), ippStsLengthErr);

   ////////////////////////////////////////////////////////////////
   {
      int tail = len & (MBS_SMS4-1); /* length of the last partial block */

      if(tail) {
         Ipp8u lastIV[MBS_SMS4];
         Ipp8u lastDecBlk[MBS_SMS4+MBS_SMS4];
         int n;

         len -= MBS_SMS4+tail;

         if(len) {
            CopyBlock16(pSrc+len-MBS_SMS4, lastIV);
            cpDecryptSMS4_cbc(pIV, pSrc, pDst, len, pCtx);
            pSrc += len;
            pDst += len;
         }
         else
            CopyBlock16(pIV, lastIV);

         /* decrypt last  block */
         cpSMS4_Cipher(lastDecBlk+MBS_SMS4, pSrc, SMS4_DRK(pCtx));

         CopyBlock16(lastDecBlk+MBS_SMS4, lastDecBlk);
         for(n=0; n<tail; n++) lastDecBlk[n] = pSrc[n+MBS_SMS4];
         /* decrypt penultimate  block */
         cpSMS4_Cipher(lastDecBlk, lastDecBlk, SMS4_DRK(pCtx));

         for(n=0; n<MBS_SMS4; n++) {
            Ipp8u c = pSrc[n];
            pDst[n] = lastDecBlk[n] ^ lastIV[n];
            lastIV[n] = c;
         }
         for(tail+=MBS_SMS4; n<tail; n++)
            pDst[n] = lastDecBlk[n] ^ pSrc[n];
      }

      else
         cpDecryptSMS4_cbc(pIV, pSrc, pDst, len, pCtx);

      return ippStsNoErr;
   }
}
