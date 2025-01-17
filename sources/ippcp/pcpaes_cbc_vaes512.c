/*******************************************************************************
* Copyright 2019 Intel Corporation
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
//     AES encryption/decryption (CBC mode)
//
//  Contents:
//     DecryptCBC_RIJ128pipe_VAES_NI()
//
//
*/

#include "owncp.h"
#include "pcpaesm.h"
#include "pcpaes_decrypt_vaes512.h"

#if(_IPP32E>=_IPP32E_K0)
#ifdef _MSC_VER
#pragma warning(disable: 4310) // zmmintrin.h bug: truncation of constant value
#endif
////////////////////////////////////////////////////////////////////////////////

void DecryptCBC_RIJ128pipe_VAES_NI(const Ipp8u* pSrc,       // pointer to the ciphertext
                                   Ipp8u* pDst,             // pointer to the plaintext
                                   int len,                 // message length
                                   const IppsAESSpec* pCtx, // pointer to context
                                   const Ipp8u* pIV)        // pointer to the Initialization Vector
{
   int cipherRounds = RIJ_NR(pCtx) - 1;

   __m128i* pRkey   = (__m128i*)RIJ_DKEYS(pCtx) + cipherRounds + 1;
   __m512i* pSrc512 = (__m512i*)pSrc;
   __m512i* pDst512 = (__m512i*)pDst;
   __m512i* pIV512  = (__m512i*)pIV;

   // load IV
   __m512i IV = _mm512_maskz_expandloadu_epi64(0xC0, pIV512);

   int blocks;
   // 4 blocks of 128-bit can be loaded into one zmm register
   // assuming that vaesdec latency is 4, we need 4 zmm registers to make effective pipeline
   for (blocks = len / MBS_RIJ128; blocks >= (4 * 4); blocks -= (4 * 4)) {
      __m512i blk0 = _mm512_loadu_si512(pSrc512);
      __m512i blk1 = _mm512_loadu_si512(pSrc512 + 1);
      __m512i blk2 = _mm512_loadu_si512(pSrc512 + 2);
      __m512i blk3 = _mm512_loadu_si512(pSrc512 + 3);

      // prepare blocks for the last xor
      __m512i z0 = _mm512_alignr_epi64(blk0, IV, 6);
      __m512i z1 = _mm512_alignr_epi64(blk1, blk0, 6);
      __m512i z2 = _mm512_alignr_epi64(blk2, blk1, 6);
      __m512i z3 = _mm512_alignr_epi64(blk3, blk2, 6);

      // update IV
      IV = blk3;

      cpAESDecrypt4_VAES_NI(&blk0, &blk1, &blk2, &blk3, pRkey, cipherRounds);

      // the last xor
      blk0 = _mm512_xor_si512(blk0, z0);
      blk1 = _mm512_xor_si512(blk1, z1);
      blk2 = _mm512_xor_si512(blk2, z2);
      blk3 = _mm512_xor_si512(blk3, z3);

      _mm512_storeu_si512(pDst512, blk0);
      _mm512_storeu_si512(pDst512 + 1, blk1);
      _mm512_storeu_si512(pDst512 + 2, blk2);
      _mm512_storeu_si512(pDst512 + 3, blk3);

      pSrc512 += 4;
      pDst512 += 4;
   }

   if ((3 * 4) <= blocks) {
      __m512i blk0 = _mm512_loadu_si512(pSrc512);
      __m512i blk1 = _mm512_loadu_si512(pSrc512 + 1);
      __m512i blk2 = _mm512_loadu_si512(pSrc512 + 2);

      __m512i z0 = _mm512_alignr_epi64(blk0, IV, 6);
      __m512i z1 = _mm512_alignr_epi64(blk1, blk0, 6);
      __m512i z2 = _mm512_alignr_epi64(blk2, blk1, 6);

      // update IV
      IV = blk2;

      cpAESDecrypt3_VAES_NI(&blk0, &blk1, &blk2, pRkey, cipherRounds);

      blk0 = _mm512_xor_si512(blk0, z0);
      blk1 = _mm512_xor_si512(blk1, z1);
      blk2 = _mm512_xor_si512(blk2, z2);

      _mm512_storeu_si512(pDst512, blk0);
      _mm512_storeu_si512(pDst512 + 1, blk1);
      _mm512_storeu_si512(pDst512 + 2, blk2);

      pSrc512 += 3;
      pDst512 += 3;
      blocks -= (3 * 4);
   }
   if ((4 * 2) <= blocks) {
      __m512i blk0 = _mm512_loadu_si512(pSrc512);
      __m512i blk1 = _mm512_loadu_si512(pSrc512 + 1);

      __m512i z0 = _mm512_alignr_epi64(blk0, IV, 6);
      __m512i z1 = _mm512_alignr_epi64(blk1, blk0, 6);

      // update IV
      IV = blk1;

      cpAESDecrypt2_VAES_NI(&blk0, &blk1, pRkey, cipherRounds);

      blk0 = _mm512_xor_si512(blk0, z0);
      blk1 = _mm512_xor_si512(blk1, z1);

      _mm512_storeu_si512(pDst512, blk0);
      _mm512_storeu_si512(pDst512 + 1, blk1);

      pSrc512 += 2;
      pDst512 += 2;
      blocks -= (2 * 4);
   }
   for (; blocks >= 4; blocks -= 4) {
      __m512i blk0 = _mm512_loadu_si512(pSrc512);

      __m512i z0 = _mm512_alignr_epi64(blk0, IV, 6);

      // update IV
      IV = blk0;

      cpAESDecrypt1_VAES_NI(&blk0, pRkey, cipherRounds);

      blk0 = _mm512_xor_si512(blk0, z0);

      _mm512_storeu_si512(pDst512, blk0);

      pSrc512 += 1;
      pDst512 += 1;
   }
   if (blocks) {
      __mmask8 k = (1 << (blocks + blocks)) - 1;
      __m512i blk0 = _mm512_maskz_loadu_epi64(k, pSrc512);

      __m512i z0 = _mm512_maskz_alignr_epi64(k, blk0, IV, 6);

      cpAESDecrypt1_VAES_NI(&blk0, pRkey, cipherRounds);

      blk0 = _mm512_maskz_xor_epi64(k, blk0, z0);

      _mm512_mask_storeu_epi64(pDst512, k, blk0);
   }
}

#endif /* _IPP32E>=_IPP32E_K0 */
