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
 
.globl _s8_cpAddMulDgt_BNU

 
_s8_cpAddMulDgt_BNU:
    push         %ebp
    mov          %esp, %ebp
    push         %edi
 
    movl         (12)(%ebp), %eax
    movl         (8)(%ebp), %edx
    movl         (16)(%ebp), %edi
    xor          %ecx, %ecx
    shl          $(2), %edi
    movd         (20)(%ebp), %mm0
    pandn        %mm7, %mm7
.Lmain_loopgas_1: 
    movd         (%ecx,%eax), %mm1
    movd         (%edx,%ecx), %mm2
    pmuludq      %mm0, %mm1
    paddq        %mm1, %mm7
    paddq        %mm2, %mm7
    movd         %mm7, (%edx,%ecx)
    psrlq        $(32), %mm7
    add          $(4), %ecx
    cmp          %edi, %ecx
    jl           .Lmain_loopgas_1
    movd         %mm7, %eax
    emms
    pop          %edi
    pop          %ebp
    ret
 
