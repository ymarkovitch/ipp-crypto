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
//     RSA Functions
// 
//  Contents:
//        ippsRSA_GetPrivateKeyType2()
//
*/

#include "owncp.h"
#include "pcpbn.h"
#include "pcpngrsa.h"

/*F*
// Name: ippsRSA_GetPrivateKeyType2
//
// Purpose: Extract key component from the key context
//
// Returns:                   Reason:
//    ippStsNullPtrErr           NULL == pKey
//
//    ippStsContextMatchErr     !RSA_PRV_KEY_VALID_ID()
//                              !BN_VALID_ID(pFactorP), !BN_VALID_ID(pFactorQ)
//                              !BN_VALID_ID(pCrtExpP), !BN_VALID_ID(pCrtExpQ)
//                              !BN_VALID_ID(pInverseQ)
//
//    ippStsIncompleteContextErr no ippsRSA_SetPrivateKeyType2() call
//
//    ippStsSizeErr              BN_ROOM(pFactorP), BN_ROOM(pFactorQ)
//                               BN_ROOM(pCrtExpP), BN_ROOM(pCrtExpQ)
//                               BN_ROOM(pInverseQ) is not enough
//
//    ippStsNoErr                no error
//
// Parameters:
//    pFactorP    (optional) pointer to the prime factor (P)
//    pFactorQ    (optional) pointer to the prime factor (Q)
//    pCrtExpP    (optional) pointer to the p's CRT exponent (dP)
//    pCrtExpQ    (optional) pointer to the q's CRT exponent (dQ)
//    pInverseQ   (optional) pointer to CRT coefficient (invQ)
//    pKey        pointer to the key context
*F*/
IPPFUN(IppStatus, ippsRSA_GetPrivateKeyType2,(IppsBigNumState* pFactorP,
                                              IppsBigNumState* pFactorQ,
                                              IppsBigNumState* pCrtExpP,
                                              IppsBigNumState* pCrtExpQ,
                                              IppsBigNumState* pInverseQ,
                                              const IppsRSAPrivateKeyState* pKey))
{
   IPP_BAD_PTR1_RET(pKey);
   pKey = (IppsRSAPrivateKeyState*)( IPP_ALIGNED_PTR(pKey, RSA_PRIVATE_KEY_ALIGNMENT) );
   IPP_BADARG_RET(!RSA_PRV_KEY2_VALID_ID(pKey), ippStsContextMatchErr);

   if(pFactorP) {
      pFactorP = (IppsBigNumState*)( IPP_ALIGNED_PTR(pFactorP, BN_ALIGNMENT) );
      IPP_BADARG_RET(!BN_VALID_ID(pFactorP), ippStsContextMatchErr);
      IPP_BADARG_RET(!RSA_PRV_KEY_IS_SET(pKey), ippStsIncompleteContextErr);
      IPP_BADARG_RET(BN_ROOM(pFactorP) < BITS_BNU_CHUNK(RSA_PRV_KEY_BITSIZE_P(pKey)), ippStsSizeErr);

      BN_Set(MOD_MODULUS(RSA_PRV_KEY_PMONT(pKey)),
             MOD_LEN(RSA_PRV_KEY_PMONT(pKey)),
             pFactorP);
   }

   if(pFactorQ) {
      pFactorQ = (IppsBigNumState*)( IPP_ALIGNED_PTR(pFactorQ, BN_ALIGNMENT) );
      IPP_BADARG_RET(!BN_VALID_ID(pFactorQ), ippStsContextMatchErr);
      IPP_BADARG_RET(!RSA_PRV_KEY_IS_SET(pKey), ippStsIncompleteContextErr);
      IPP_BADARG_RET(BN_ROOM(pFactorQ) < BITS_BNU_CHUNK(RSA_PRV_KEY_BITSIZE_Q(pKey)), ippStsSizeErr);

      BN_Set(MOD_MODULUS(RSA_PRV_KEY_QMONT(pKey)),
             MOD_LEN(RSA_PRV_KEY_QMONT(pKey)),
             pFactorQ);
   }

   if(pCrtExpP) {
      cpSize expLen = BITS_BNU_CHUNK(RSA_PRV_KEY_BITSIZE_P(pKey));
      FIX_BNU(RSA_PRV_KEY_DP(pKey), expLen);

      pCrtExpP = (IppsBigNumState*)( IPP_ALIGNED_PTR(pCrtExpP, BN_ALIGNMENT) );
      IPP_BADARG_RET(!BN_VALID_ID(pCrtExpP), ippStsContextMatchErr);
      IPP_BADARG_RET(!RSA_PRV_KEY_IS_SET(pKey), ippStsIncompleteContextErr);
      IPP_BADARG_RET(BN_ROOM(pCrtExpP) < expLen, ippStsSizeErr);

      BN_Set(RSA_PRV_KEY_DP(pKey), expLen, pCrtExpP);
   }

   if(pCrtExpQ) {
      cpSize expLen = BITS_BNU_CHUNK(RSA_PRV_KEY_BITSIZE_Q(pKey));
      FIX_BNU(RSA_PRV_KEY_DQ(pKey), expLen);

      pCrtExpQ = (IppsBigNumState*)( IPP_ALIGNED_PTR(pCrtExpQ, BN_ALIGNMENT) );
      IPP_BADARG_RET(!BN_VALID_ID(pCrtExpQ), ippStsContextMatchErr);
      IPP_BADARG_RET(!RSA_PRV_KEY_IS_SET(pKey), ippStsIncompleteContextErr);
      IPP_BADARG_RET(BN_ROOM(pCrtExpQ) < expLen, ippStsSizeErr);

      BN_Set(RSA_PRV_KEY_DQ(pKey), expLen, pCrtExpQ);
   }

   if(pInverseQ) {
      cpSize coeffLen = BITS_BNU_CHUNK(RSA_PRV_KEY_BITSIZE_P(pKey));
      gsModEngine* pMontP = RSA_PRV_KEY_PMONT(pKey);
      FIX_BNU(RSA_PRV_KEY_INVQ(pKey), coeffLen);

      pInverseQ = (IppsBigNumState*)( IPP_ALIGNED_PTR(pInverseQ, BN_ALIGNMENT) );
      IPP_BADARG_RET(!BN_VALID_ID(pInverseQ), ippStsContextMatchErr);
      IPP_BADARG_RET(!RSA_PRV_KEY_IS_SET(pKey), ippStsIncompleteContextErr);
      IPP_BADARG_RET(BN_ROOM(pInverseQ) < coeffLen, ippStsSizeErr);

      MOD_METHOD( pMontP )->decode(BN_NUMBER(pInverseQ), RSA_PRV_KEY_INVQ(pKey), pMontP);

      BN_Set(BN_NUMBER(pInverseQ), MOD_LEN(RSA_PRV_KEY_PMONT(pKey)), pInverseQ);
   }

   return ippStsNoErr;
}
