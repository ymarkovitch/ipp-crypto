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
// 
//  Purpose:
//     Cryptography Primitive.
//     Decrypt byte data stream according to TDES (CFB mode)
// 
//  Contents:
//     ippsTDESDecryptCFB()
// 
// 
*/

#include "owndefs.h"

#ifndef _OPENMP

#include "owncp.h"
#include "pcpdes.h"
#include "pcptool.h"


/*F*
//    Name: ippsTDESDecryptCFB
//
// Purpose: Decrypt byte data block stream according to TDES in CFB mode.
//
// Returns:                Reason:
//    ippStsNullPtrErr        pCtx1 == NULL
//                            pCtx2 == NULL
//                            pCtx3 == NULL
//                            pSrc == NULL
//                            pDst == NULL
//    ippStsContextMatchErr   pCtx1->idCtx != idCtxDES
//                            pCtx2->idCtx != idCtxDES
//                            pCtx3->idCtx != idCtxDES
//    ippStsLengthErr         len <1
//    ippStsCFBSizeErr        (1>cfbBlkSize || cfbBlkSize>MBS_DES)
//    ippStsUnderRunErr       (len%cfbBlkSize)
//    ippStsNoErr             no errors
//
// Parameters:
//    pSrc        pointer to the source byte data stream
//    pDst        pointer to the target byte data stream
//    len         plaintext stream length (bytes)
//    cfbBlkSize  CFB block size (bytes)
//    pCtx1-3     pointers to the DES context
//    pIV         pointer to the init vector
//    padding     the padding scheme indicator
//
*F*/
IPPFUN(IppStatus, ippsTDESDecryptCFB,(const Ipp8u* pSrc, Ipp8u* pDst, int len, int cfbBlkSize,
                                      const IppsDESSpec* pCtx1, const IppsDESSpec* pCtx2, const IppsDESSpec* pCtx3,
                                      const Ipp8u* pIV,
                                      IppsPadding padding))
{
   Ipp64u inpBuffer[2];
   Ipp64u outBuffer;

   /* test contexts */
   IPP_BAD_PTR3_RET(pCtx1, pCtx2, pCtx3);
   /* use aligned DES contexts */
   pCtx1 = (IppsDESSpec*)( IPP_ALIGNED_PTR(pCtx1, DES_ALIGNMENT) );
   pCtx2 = (IppsDESSpec*)( IPP_ALIGNED_PTR(pCtx2, DES_ALIGNMENT) );
   pCtx3 = (IppsDESSpec*)( IPP_ALIGNED_PTR(pCtx3, DES_ALIGNMENT) );

   IPP_BADARG_RET(!DES_ID_TEST(pCtx1), ippStsContextMatchErr);
   IPP_BADARG_RET(!DES_ID_TEST(pCtx2), ippStsContextMatchErr);
   IPP_BADARG_RET(!DES_ID_TEST(pCtx3), ippStsContextMatchErr);
   /* test source and destination pointers */
   IPP_BAD_PTR3_RET(pSrc, pDst, pIV);
   /* test stream length */
   IPP_BADARG_RET((len<1), ippStsLengthErr);
   /* test CFB value */
   IPP_BADARG_RET(((1>cfbBlkSize) || (MBS_DES<cfbBlkSize)), ippStsCFBSizeErr);

   /* force ippPaddingNONE padding */
   if(ippPaddingNONE!=padding)
      padding = ippPaddingNONE;
   /* test stream integrity */
   //IPP_BADARG_RET(((len%cfbBlkSize) && (ippPaddingNONE==padding)), ippStsUnderRunErr);
   IPP_BADARG_RET((len%cfbBlkSize), ippStsUnderRunErr);

   /* read IV */
   CopyBlock8(pIV, inpBuffer);

   /* decrypt data block-by-block of cfbLen each */
   while(len>=cfbBlkSize) {
      int n;

      /* decryption */
      outBuffer = Cipher_DES(inpBuffer[0], DES_EKEYS(pCtx1), DESspbox);
      outBuffer = Cipher_DES(outBuffer,    DES_DKEYS(pCtx2), DESspbox);
      outBuffer = Cipher_DES(outBuffer,    DES_EKEYS(pCtx3), DESspbox);

      /* store output and put feedback into the buffer */
      for(n=0; n<cfbBlkSize; n++) {
         ((Ipp8u*)(inpBuffer+1))[n] = pSrc[n];
         pDst[n] = (Ipp8u)( ((Ipp8u*)&outBuffer)[n] ^ pSrc[n] );
      }

      /* shift buffer for the next CFB operation */
      if(MBS_DES==cfbBlkSize)
         inpBuffer[0] = inpBuffer[1];
      else
         #if (IPP_ENDIAN == IPP_BIG_ENDIAN)
         inpBuffer[0] = LSL64(inpBuffer[0], cfbBlkSize*8)
                       |LSR64(inpBuffer[1], 64-cfbBlkSize*8);
         #else
         inpBuffer[0] = LSR64(inpBuffer[0], cfbBlkSize*8)
                       |LSL64(inpBuffer[1], 64-cfbBlkSize*8);
         #endif

      pSrc += cfbBlkSize;
      pDst += cfbBlkSize;
      len  -= cfbBlkSize;
   }

   return ippStsNoErr;
}

#endif /* #ifndef _OPENMP */
