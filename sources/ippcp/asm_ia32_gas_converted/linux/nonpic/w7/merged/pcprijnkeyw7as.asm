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
 
.p2align 4, 0x90
 
.globl w7_Touch_SubsDword_8uT
.type w7_Touch_SubsDword_8uT, @function
 
w7_Touch_SubsDword_8uT:
    push         %ebp
    mov          %esp, %ebp
    push         %ebx
    push         %esi
    push         %edi
 
    movl         (12)(%ebp), %esi
    movl         (16)(%ebp), %edx
    xor          %ecx, %ecx
.Ltouch_tblgas_1: 
    mov          (%esi,%ecx), %eax
    add          $(64), %ecx
    cmp          %edx, %ecx
    jl           .Ltouch_tblgas_1
    movl         (8)(%ebp), %edx
    mov          %edx, %eax
    and          $(255), %eax
    movzbl       (%esi,%eax), %eax
    shr          $(8), %edx
    mov          %edx, %ebx
    and          $(255), %ebx
    movzbl       (%esi,%ebx), %ebx
    shl          $(8), %ebx
    shr          $(8), %edx
    mov          %edx, %ecx
    and          $(255), %ecx
    movzbl       (%esi,%ecx), %ecx
    shl          $(16), %ecx
    shr          $(8), %edx
    movzbl       (%esi,%edx), %edx
    shl          $(24), %edx
    or           %ebx, %eax
    or           %ecx, %eax
    or           %edx, %eax
    pop          %edi
    pop          %esi
    pop          %ebx
    pop          %ebp
    ret
.Lfe1:
.size w7_Touch_SubsDword_8uT, .Lfe1-(w7_Touch_SubsDword_8uT)
 
