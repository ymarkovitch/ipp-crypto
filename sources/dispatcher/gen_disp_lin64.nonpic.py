#===============================================================================
# Copyright 2017-2019 Intel Corporation
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
#===============================================================================

#
# Intel(R) Integrated Performance Primitives (Intel(R) IPP) Cryptography
#

import re
import sys
import os
import hashlib

Header   = sys.argv[1]    ## Intel(R) IPP Crypto dispatcher will be generated for fucntions in Header
OutDir   = sys.argv[2]    ## Output folder for generated files
cpulist  = sys.argv[3]    ## Actual CPU list: semicolon separated string
compiler = sys.argv[4]

cpulist = cpulist.split(';')

headerID= False      ## Header ID define to avoid multiple include like: #if !defined( __IPPCP_H__ )

from gen_disp_common import readNextFunction

HDR= open( Header, 'r' )
h= HDR.readlines()
HDR.close()


## keep filename only
(incdir, Header)= os.path.split(Header)

## original header name to declare external functions as internal for dispatcher
OrgH= Header

isFunctionFound = True
curLine = 0
FunType = ""
FunName = ""
FunArg = ""
  
if(compiler == "GNU"):
    while (isFunctionFound == True):

        result = readNextFunction(h, curLine, headerID)

        curLine         = result['curLine']
        FunType         = result['FunType']
        FunName         = result['FunName']
        FunArg          = result['FunArg']
        isFunctionFound = result['success']

        if (isFunctionFound == True):

            ##################################################
            ## create dispatcher files ASM
            ##################################################
            ASMDISP= open( os.sep.join([OutDir, "jmp_" + FunName+"_" + hashlib.sha512(FunName.encode('utf-8')).hexdigest()[:8] +".asm"]), 'w' )
            ASMDISP.write("""
.data
.align 8
.quad  .Lin_{FunName}
.Larraddr_{FunName}:
""".format(FunName=FunName))

            for cpu in cpulist:
                ASMDISP.write("    .quad "+cpu+"_"+FunName+"\n")

            ASMDISP.write("""
.text
.globl {FunName}
.Lin_{FunName}:
    call ippcpSafeInit
    .align 16

{FunName}:
    movslq  ippcpJumpIndexForMergedLibs,%rax
    leaq    .Larraddr_{FunName}(%rip),%r11
    jmpq    *(%r11,%rax,8)

.type {FunName}, @function
.size {FunName}, .-{FunName}
""".format(FunName=FunName))
            ASMDISP.close()
else:
    while (isFunctionFound == True):

        result = readNextFunction(h, curLine, headerID)

        curLine         = result['curLine']
        FunType         = result['FunType']
        FunName         = result['FunName']
        FunArg          = result['FunArg']
        isFunctionFound = result['success']

        if (isFunctionFound == True):

            ##################################################
            ## create dispatcher files: C file with inline asm
            ##################################################
            DISP= open( os.sep.join([OutDir, "jmp_"+FunName+"_" + hashlib.sha512(FunName.encode('utf-8')).hexdigest()[:8] + ".c"]), 'w' )

            DISP.write("""#include "ippcp.h"\n\n#pragma warning(disable : 1478 1786) // deprecated\n\n""")

            DISP.write("typedef "+FunType+" (*IPP_PROC)"+FunArg+";\n\n")
            DISP.write("extern int ippcpJumpIndexForMergedLibs;\n")
            DISP.write("extern IppStatus ippcpSafeInit( void );\n\n")

            DISP.write("extern "+FunType+" in_"+FunName+FunArg+";\n")

            for cpu in cpulist:
                DISP.write("extern "+FunType+" "+cpu+"_"+FunName+FunArg+";\n")

            DISP.write("static IPP_PROC arraddr[] =\n{{\n	(IPP_PROC)in_{}".format(FunName))

            for cpu in cpulist:
                DISP.write(",\n	(IPP_PROC)"+cpu+"_"+FunName+"")

            DISP.write("\n};")

            DISP.write("""
#undef  IPPAPI
#define IPPAPI(type,name,arg) __declspec(naked) type name arg

IPPAPI({FunType}, {FunName},{FunArg})
{{
    __asm{{
        movsxd rax, dword ptr ippcpJumpIndexForMergedLibs
        jmp    qword ptr [8*rax+8+arraddr]
    }}
}}

IPPAPI({FunType}, in_{FunName},{FunArg})
{{
     __asm{{
        call ippcpSafeInit
        lea  rax, {FunName}
        jmp  rax
  }}
}};
""".format(FunType=FunType, FunName=FunName, FunArg=FunArg))

        DISP.close()
