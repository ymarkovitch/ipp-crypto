/*******************************************************************************
* Copyright 2002-2019 Intel Corporation
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
//  Purpose:
//     Intel(R) Integrated Performance Primitives. Cryptography Primitives.
//     Internal Miscellaneous BNU Definitions & Function Prototypes
// 
// 
*/

#if !defined(_PCP_BNUMISC_H)
#define _PCP_BNUMISC_H

#include "pcpbnuimpl.h"


/* bit operations */
#define BITSIZE_BNU(p,ns)  ((ns)*BNU_CHUNK_BITS-cpNLZ_BNU((p)[(ns)-1]))
#define BIT_BNU(bnu, ns,nbit) ((((nbit)>>BNU_CHUNK_LOG2) < (ns))? ((((bnu))[(nbit)>>BNU_CHUNK_LOG2] >>((nbit)&(BNU_CHUNK_BITS))) &1) : 0)

#define TST_BIT(bnu, nbit)    (((Ipp8u*)(bnu))[(nbit)/8] &  ((1<<((nbit)%8)) &0xFF))
#define SET_BIT(bnu, nbit)    (((Ipp8u*)(bnu))[(nbit)/8] |= ((1<<((nbit)%8)) &0xFF))
#define CLR_BIT(bnu, nbit)    (((Ipp8u*)(bnu))[(nbit)/8] &=~((1<<((nbit)%8)) &0xFF))

/* convert bitsize nbits into  the number of BNU_CHUNK_T */
#define BITS_BNU_CHUNK(nbits) (((nbits)+BNU_CHUNK_BITS-1)/BNU_CHUNK_BITS)

/* mask for top BNU_CHUNK_T */
#define MASK_BNU_CHUNK(nbits) ((BNU_CHUNK_T)(-1) >>((BNU_CHUNK_BITS- ((nbits)&(BNU_CHUNK_BITS-1))) &(BNU_CHUNK_BITS-1)))

/* copy BNU content */
#define COPY_BNU(dst, src, len) \
{ \
   cpSize __idx; \
   for(__idx=0; __idx<(len); __idx++) (dst)[__idx] = (src)[__idx]; \
}

/* expand by zeros */
#define ZEXPAND_BNU(srcdst,srcLen, dstLen) \
{ \
   cpSize __idx; \
   for(__idx=(srcLen); __idx<(dstLen); __idx++) (srcdst)[__idx] = 0; \
}

/* copy and expand by zeros */
#define ZEXPAND_COPY_BNU(dst,dstLen, src,srcLen) \
{ \
   cpSize __idx; \
   for(__idx=0; __idx<(srcLen); __idx++) (dst)[__idx] = (src)[__idx]; \
   for(; __idx<(dstLen); __idx++)    (dst)[__idx] = 0; \
}

/* fix actual length */
#define FIX_BNU(src,srcLen) \
   for(; ((srcLen)>1) && (0==(src)[(srcLen)-1]); (srcLen)--) {}


/* copy and set */
__INLINE void cpCpy_BNU(BNU_CHUNK_T* pDst, const BNU_CHUNK_T* pSrc, cpSize ns)
{  COPY_BNU(pDst, pSrc, ns); }

__INLINE void cpSet_BNU(BNU_CHUNK_T* pDst, cpSize ns, BNU_CHUNK_T val)
{
   ZEXPAND_BNU(pDst, 0, ns);
   pDst[0] = val;
}

/* fix up */

/*   Name: cpFix_BNU
//
// Purpose: fix up BigNums.
//
// Returns:
//    fixed nsA
//
// Parameters:
//    pA       BigNum ctx
//    nsA      Size of pA
//
*/

__INLINE int cpFix_BNU(const BNU_CHUNK_T* pA, int nsA)
{
   FIX_BNU(pA, nsA);
   return nsA;
}

/*   Name: cpCmp_BNU 
//
// Purpose: Compare two BigNums.
//
// Returns:
//    negative, if A < B
//           0, if A = B
//    positive, if A > B
//
// Parameters:
//    pA       BigNum ctx
//    nsA      Size of pA
//    pB       BigNum ctx
//    nsB      Size of pB
//
*/
__INLINE int cpCmp_BNU(const BNU_CHUNK_T* pA, cpSize nsA, const BNU_CHUNK_T* pB, cpSize nsB)
{
   if(nsA!=nsB)
      return nsA>nsB? 1 : -1;
   else {
      for(; nsA>0; nsA--) {
         if(pA[nsA-1] > pB[nsA-1])
            return 1;
         else if(pA[nsA-1] < pB[nsA-1])
            return -1;
      }
      return 0;
   }
}

/*   Name: cpEqu_BNU_CHUNK
//
// Purpose: Compare two BNU_CHUNKs.
//
// Returns:
//    positive, if A  = b
//    0       , if A != b
//
// Parameters:
//    pA       BigNum ctx
//    nsA      Size of pA
//    b        BNU_CHUNK_T to compare
//
*/

__INLINE int cpEqu_BNU_CHUNK(const BNU_CHUNK_T* pA, cpSize nsA, BNU_CHUNK_T b)
{
   return (pA[0]==b && 1==cpFix_BNU(pA, nsA));
}

/*
// test
//
// returns
//     0, if A = 0
//    >0, if A > 0
//    <0, looks like impossible (or error) case
*/
__INLINE int cpTst_BNU(const BNU_CHUNK_T* pA, int nsA)
{
   for(; (nsA>0) && (0==pA[nsA-1]); nsA--) ;
   return nsA;
}

/* number of leading/trailing zeros */
#define cpNLZ_BNU OWNAPI(cpNLZ_BNU)
 cpSize cpNLZ_BNU(BNU_CHUNK_T x);

#define cpNTZ_BNU OWNAPI(cpNTZ_BNU)
 cpSize cpNTZ_BNU(BNU_CHUNK_T x);

/* logical shift left/right */
#define cpLSR_BNU OWNAPI(cpLSR_BNU)
    int cpLSR_BNU(BNU_CHUNK_T* pR, const BNU_CHUNK_T* pA, cpSize nsA, cpSize nBits);

/* most significant BNU bit */
#define cpMSBit_BNU OWNAPI(cpMSBit_BNU)
    int cpMSBit_BNU(const BNU_CHUNK_T* pA, cpSize nsA);

/* BNU <-> hex-string conversion */
#define cpToOctStr_BNU OWNAPI(cpToOctStr_BNU)
    int cpToOctStr_BNU(Ipp8u* pStr, cpSize strLen, const BNU_CHUNK_T* pA, cpSize nsA);
#define cpFromOctStr_BNU OWNAPI(cpFromOctStr_BNU)
    int cpFromOctStr_BNU(BNU_CHUNK_T* pA, const Ipp8u* pStr, cpSize strLen);

#endif /* _PCP_BNUMISC_H */
