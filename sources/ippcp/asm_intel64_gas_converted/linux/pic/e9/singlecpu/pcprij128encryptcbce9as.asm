###############################################################################
# Copyright 2019 Intel Corporation
# All Rights Reserved.
#
# If this  software was obtained  under the  Intel Simplified  Software License,
# the following terms apply:
#
# The source code,  information  and material  ("Material") contained  herein is
# owned by Intel Corporation or its  suppliers or licensors,  and  title to such
# Material remains with Intel  Corporation or its  suppliers or  licensors.  The
# Material  contains  proprietary  information  of  Intel or  its suppliers  and
# licensors.  The Material is protected by  worldwide copyright  laws and treaty
# provisions.  No part  of  the  Material   may  be  used,  copied,  reproduced,
# modified, published,  uploaded, posted, transmitted,  distributed or disclosed
# in any way without Intel's prior express written permission.  No license under
# any patent,  copyright or other  intellectual property rights  in the Material
# is granted to  or  conferred  upon  you,  either   expressly,  by implication,
# inducement,  estoppel  or  otherwise.  Any  license   under such  intellectual
# property rights must be express and approved by Intel in writing.
#
# Unless otherwise agreed by Intel in writing,  you may not remove or alter this
# notice or  any  other  notice   embedded  in  Materials  by  Intel  or Intel's
# suppliers or licensors in any way.
#
#
# If this  software  was obtained  under the  Apache License,  Version  2.0 (the
# "License"), the following terms apply:
#
# You may  not use this  file except  in compliance  with  the License.  You may
# obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
#
#
# Unless  required  by   applicable  law  or  agreed  to  in  writing,  software
# distributed under the License  is distributed  on an  "AS IS"  BASIS,  WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#
# See the   License  for the   specific  language   governing   permissions  and
# limitations under the License.
###############################################################################

 
 .section .note.GNU-stack,"",%progbits 
 
.text
.p2align 5, 0x90
 
.globl EncryptCBC_RIJ128_AES_NI
.type EncryptCBC_RIJ128_AES_NI, @function
 
EncryptCBC_RIJ128_AES_NI:
 
    movslq       %r8d, %r8
    movdqu       (%r9), %xmm0
.p2align 5, 0x90
.Lblks_loopgas_1: 
    movdqu       (%rdi), %xmm1
    movdqa       (%rcx), %xmm4
    mov          %rcx, %r9
    pxor         %xmm1, %xmm0
    pxor         %xmm4, %xmm0
    movdqa       (16)(%r9), %xmm4
    add          $(16), %r9
    mov          %rdx, %r10
    sub          $(1), %r10
.p2align 5, 0x90
.Lcipher_loopgas_1: 
    aesenc       %xmm4, %xmm0
    movdqa       (16)(%r9), %xmm4
    add          $(16), %r9
    dec          %r10
    jnz          .Lcipher_loopgas_1
    aesenclast   %xmm4, %xmm0
    movdqu       %xmm0, (%rsi)
    add          $(16), %rdi
    add          $(16), %rsi
    sub          $(16), %r8
    jnz          .Lblks_loopgas_1
    pxor         %xmm4, %xmm4
vzeroupper 
 
    ret
.Lfe1:
.size EncryptCBC_RIJ128_AES_NI, .Lfe1-(EncryptCBC_RIJ128_AES_NI)
 
