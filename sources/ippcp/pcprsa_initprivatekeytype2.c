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
//        ippsRSA_InitPrivateKeyType2()
//
*/

#include "owncp.h"
#include "pcpbn.h"
#include "pcpngrsa.h"

#include "pcprsa_sizeof_privkey2.h"

/*F*
// Name: ippsRSA_InitPrivateKeyType2
//
// Purpose: Init RSA private key context
//
// Returns:                   Reason:
//    ippStsNullPtrErr           NULL == pKey
//
//    ippStsNotSupportedModeErr  MIN_RSA_SIZE > (factorPbitSize+factorQbitSize)
//                               MAX_RSA_SIZE < (factorPbitSize+factorQbitSize)
//
//    ippStsBadArgErr            0 >= factorPbitSize
//                               0 >= factorQbitSize
//                               factorQbitSize > factorPbitSize
//
//    ippStsMemAllocErr          keyCtxSize is not enough for operation
//
//    ippStsNoErr                no error
//
// Parameters:
//    factorPbitSize       bitsize of RSA modulus (bitsize of P)
//    factorQbitSize       bitsize of private exponent (bitsize of Q)
//    pKey                 pointer to the key context
//    keyCtxSize           size of memmory accosizted with key comtext
*F*/

IPPFUN(IppStatus, ippsRSA_InitPrivateKeyType2,(int factorPbitSize, int factorQbitSize,
                                               IppsRSAPrivateKeyState* pKey, int keyCtxSize))
{
   IPP_BAD_PTR1_RET(pKey);
   IPP_BADARG_RET((factorPbitSize<=0) || (factorQbitSize<=0), ippStsBadArgErr);
   IPP_BADARG_RET((factorPbitSize < factorQbitSize), ippStsBadArgErr);
   IPP_BADARG_RET((MIN_RSA_SIZE>(factorPbitSize+factorQbitSize) || (factorPbitSize+factorQbitSize)>MAX_RSA_SIZE), ippStsNotSupportedModeErr);

   /* test available size of context buffer */
   IPP_BADARG_RET(keyCtxSize<cpSizeof_RSA_privateKey2(factorPbitSize,factorQbitSize), ippStsMemAllocErr);

   pKey = (IppsRSAPrivateKeyState*)( IPP_ALIGNED_PTR(pKey, RSA_PRIVATE_KEY_ALIGNMENT) );

   RSA_PRV_KEY_ID(pKey) = idCtxRSA_PrvKey2;
   RSA_PRV_KEY_MAXSIZE_N(pKey) = 0;
   RSA_PRV_KEY_MAXSIZE_D(pKey) = 0;
   RSA_PRV_KEY_BITSIZE_N(pKey) = 0;
   RSA_PRV_KEY_BITSIZE_D(pKey) = 0;
   RSA_PRV_KEY_BITSIZE_P(pKey) = factorPbitSize;
   RSA_PRV_KEY_BITSIZE_Q(pKey) = factorQbitSize;

   RSA_PRV_KEY_D(pKey) = NULL;

   {
      Ipp8u* ptr = (Ipp8u*)pKey;

      int factorPlen = BITS_BNU_CHUNK(factorPbitSize);
      int factorQlen = BITS_BNU_CHUNK(factorQbitSize);
      int factorPlen32 = BITS2WORD32_SIZE(factorPbitSize);
      int factorQlen32 = BITS2WORD32_SIZE(factorQbitSize);
      int rsaModulusLen32 = BITS2WORD32_SIZE(factorPbitSize+factorQbitSize);
      int montPsize;
      int montQsize;
      int montNsize;
      rsaMontExpGetSize(factorPlen32, &montPsize);
      rsaMontExpGetSize(factorQlen32, &montQsize);
      rsaMontExpGetSize(rsaModulusLen32, &montNsize);

      /* allocate internal contexts */
      ptr += sizeof(IppsRSAPrivateKeyState);

      RSA_PRV_KEY_DP(pKey) = (BNU_CHUNK_T*)( IPP_ALIGNED_PTR((ptr), (int)sizeof(BNU_CHUNK_T)) );
      ptr += factorPlen*sizeof(BNU_CHUNK_T);

      RSA_PRV_KEY_DQ(pKey) = (BNU_CHUNK_T*)(ptr);
      ptr += factorQlen*sizeof(BNU_CHUNK_T);

      RSA_PRV_KEY_INVQ(pKey) = (BNU_CHUNK_T*)(ptr);
      ptr += factorPlen*sizeof(BNU_CHUNK_T);

      RSA_PRV_KEY_PMONT(pKey) = (gsModEngine*)( IPP_ALIGNED_PTR((ptr), (MONT_ALIGNMENT)) );
      ptr += montPsize;

      RSA_PRV_KEY_QMONT(pKey) = (gsModEngine*)( IPP_ALIGNED_PTR((ptr), (MONT_ALIGNMENT)) );
      ptr += montQsize;

      RSA_PRV_KEY_NMONT(pKey) = (gsModEngine*)( IPP_ALIGNED_PTR((ptr), (MONT_ALIGNMENT)) );
      ptr += montNsize;

      ZEXPAND_BNU(RSA_PRV_KEY_DP(pKey), 0, factorPlen);
      ZEXPAND_BNU(RSA_PRV_KEY_DQ(pKey), 0, factorQlen);
      ZEXPAND_BNU(RSA_PRV_KEY_INVQ(pKey), 0, factorPlen);

      gsModEngineInit(RSA_PRV_KEY_PMONT(pKey), 0, factorPbitSize, MOD_ENGINE_RSA_POOL_SIZE, gsModArithRSA());
      gsModEngineInit(RSA_PRV_KEY_QMONT(pKey), 0, factorQbitSize, MOD_ENGINE_RSA_POOL_SIZE, gsModArithRSA());
      gsModEngineInit(RSA_PRV_KEY_NMONT(pKey), 0, factorPbitSize+factorQbitSize, MOD_ENGINE_RSA_POOL_SIZE, gsModArithRSA());

      return ippStsNoErr;
   }
}
