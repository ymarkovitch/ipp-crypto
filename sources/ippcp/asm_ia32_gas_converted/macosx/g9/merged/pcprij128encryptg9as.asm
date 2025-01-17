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

 
.text
.p2align 5, 0x90
 
.globl _g9_Encrypt_RIJ128_AES_NI

 
_g9_Encrypt_RIJ128_AES_NI:
    push         %ebp
    mov          %esp, %ebp
    push         %esi
    push         %edi
 
    movl         (8)(%ebp), %esi
    movl         (20)(%ebp), %ecx
    movl         (16)(%ebp), %eax
    movl         (12)(%ebp), %edi
    movdqu       (%esi), %xmm0
    pxor         (%ecx), %xmm0
    lea          (,%eax,4), %edx
    lea          (-144)(%ecx,%edx,4), %ecx
    cmp          $(12), %eax
    jl           .Lkey_128gas_1
    jz           .Lkey_192gas_1
.Lkey_256gas_1: 
    aesenc       (-64)(%ecx), %xmm0
    aesenc       (-48)(%ecx), %xmm0
.Lkey_192gas_1: 
    aesenc       (-32)(%ecx), %xmm0
    aesenc       (-16)(%ecx), %xmm0
.Lkey_128gas_1: 
    aesenc       (%ecx), %xmm0
    aesenc       (16)(%ecx), %xmm0
    aesenc       (32)(%ecx), %xmm0
    aesenc       (48)(%ecx), %xmm0
    aesenc       (64)(%ecx), %xmm0
    aesenc       (80)(%ecx), %xmm0
    aesenc       (96)(%ecx), %xmm0
    aesenc       (112)(%ecx), %xmm0
    aesenc       (128)(%ecx), %xmm0
    aesenclast   (144)(%ecx), %xmm0
    movdqu       %xmm0, (%edi)
    pop          %edi
    pop          %esi
    pop          %ebp
    ret
 
