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
//     RSASSA-PKCS-v1_5
// 
//     Signatire Scheme with Appendix Signatute Generation
// 
//  Contents:
//        ippsRSASign_PKCS1v15_rmf()
//
*/

#include "owndefs.h"
#include "owncp.h"
#include "pcpngrsa.h"
#include "pcphash_rmf.h"
#include "pcptool.h"

#include "pcprsa_pkcs1c15_data.h"
#include "pcprsa_generatesing_pkcs1v15.h"

IPPFUN(IppStatus, ippsRSASign_PKCS1v15_rmf,(const Ipp8u* pMsg, int msgLen,
                                                  Ipp8u* pSign,
                                            const IppsRSAPrivateKeyState* pPrvKey,
                                            const IppsRSAPublicKeyState*  pPubKey,
                                            const IppsHashMethod* pMethod,
                                                  Ipp8u* pScratchBuffer))
{
   IppHashAlgId hashAlg;

   /* test private key context */
   IPP_BAD_PTR3_RET(pPrvKey, pScratchBuffer, pMethod);
   pPrvKey = (IppsRSAPrivateKeyState*)( IPP_ALIGNED_PTR(pPrvKey, RSA_PRIVATE_KEY_ALIGNMENT) );
   IPP_BADARG_RET(!RSA_PRV_KEY_VALID_ID(pPrvKey), ippStsContextMatchErr);
   IPP_BADARG_RET(!RSA_PRV_KEY_IS_SET(pPrvKey), ippStsIncompleteContextErr);

   /* test hash algorith ID */
   hashAlg = pMethod->hashAlgId;
   IPP_BADARG_RET(ippHashAlg_SM3==hashAlg, ippStsNotSupportedModeErr);

   /* use aligned public key context if defined */
   if(pPubKey) {
      pPubKey = (IppsRSAPublicKeyState*)( IPP_ALIGNED_PTR(pPubKey, RSA_PUBLIC_KEY_ALIGNMENT) );
      IPP_BADARG_RET(!RSA_PUB_KEY_VALID_ID(pPubKey), ippStsContextMatchErr);
      IPP_BADARG_RET(!RSA_PUB_KEY_IS_SET(pPubKey), ippStsIncompleteContextErr);
   }

   /* test data pointer */
   IPP_BAD_PTR2_RET(pMsg, pSign);
   /* test length */
   IPP_BADARG_RET(msgLen<0, ippStsLengthErr);

   {
      Ipp8u md[IPP_SHA512_DIGEST_BITSIZE/BYTESIZE];
      int mdLen = pMethod->hashLen;
      ippsHashMessage_rmf(pMsg, msgLen, md, pMethod);

      {
         const Ipp8u* pSalt = pksc15_salt[hashAlg].pSalt;
         int saltLen = pksc15_salt[hashAlg].saltLen;

         int sts = GenerateSing(md, mdLen,
                         pSalt, saltLen,
                         pSign,
                         pPrvKey, pPubKey,
                         (BNU_CHUNK_T*)(IPP_ALIGNED_PTR((pScratchBuffer), (int)sizeof(BNU_CHUNK_T))));

         return (1==sts)? ippStsNoErr : ippStsSizeErr;
      }
   }
}
