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
//        ippsRSA_GetSizePrivateKeyType2()
//
*/

#include "owncp.h"
#include "pcpbn.h"
#include "pcpngrsa.h"

#include "pcprsa_sizeof_privkey2.h"

/*F*
// Name: ippsRSA_GetSizePrivateKeyType2
//
// Purpose: Returns context size (bytes) of RSA private key (type2) context
//
// Returns:                   Reason:
//    ippStsNullPtrErr           NULL == pSize
//
//    ippStsNotSupportedModeErr  MIN_RSA_SIZE > (factorPbitSize+factorQbitSize)
//                               MAX_RSA_SIZE < (factorPbitSize+factorQbitSize)
//
//    ippStsBadArgErr            0 >= factorPbitSize
//                               0 >= factorQbitSize
//                               factorQbitSize > factorPbitSize
//
//    ippStsNoErr                no error
//
// Parameters:
//    factorPbitSize    bitsize of RSA modulus (bitsize of P)
//    factorPbitSize    bitsize of private exponent (bitsize of Q)
//    pSize             pointer to the size of RSA key context (bytes)
*F*/


IPPFUN(IppStatus, ippsRSA_GetSizePrivateKeyType2,(int factorPbitSize, int factorQbitSize, int* pKeySize))
{
   IPP_BAD_PTR1_RET(pKeySize);
   IPP_BADARG_RET((factorPbitSize<=0) || (factorQbitSize<=0), ippStsBadArgErr);
   IPP_BADARG_RET((factorPbitSize < factorQbitSize), ippStsBadArgErr);
   IPP_BADARG_RET((MIN_RSA_SIZE>(factorPbitSize+factorQbitSize) || (factorPbitSize+factorQbitSize)>MAX_RSA_SIZE), ippStsNotSupportedModeErr);

   *pKeySize = cpSizeof_RSA_privateKey2(factorPbitSize, factorQbitSize);
   return ippStsNoErr;
}
