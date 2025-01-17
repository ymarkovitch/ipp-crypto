;===============================================================================
; Copyright 2014-2019 Intel Corporation
; All Rights Reserved.
;
; If this  software was obtained  under the  Intel Simplified  Software License,
; the following terms apply:
;
; The source code,  information  and material  ("Material") contained  herein is
; owned by Intel Corporation or its  suppliers or licensors,  and  title to such
; Material remains with Intel  Corporation or its  suppliers or  licensors.  The
; Material  contains  proprietary  information  of  Intel or  its suppliers  and
; licensors.  The Material is protected by  worldwide copyright  laws and treaty
; provisions.  No part  of  the  Material   may  be  used,  copied,  reproduced,
; modified, published,  uploaded, posted, transmitted,  distributed or disclosed
; in any way without Intel's prior express written permission.  No license under
; any patent,  copyright or other  intellectual property rights  in the Material
; is granted to  or  conferred  upon  you,  either   expressly,  by implication,
; inducement,  estoppel  or  otherwise.  Any  license   under such  intellectual
; property rights must be express and approved by Intel in writing.
;
; Unless otherwise agreed by Intel in writing,  you may not remove or alter this
; notice or  any  other  notice   embedded  in  Materials  by  Intel  or Intel's
; suppliers or licensors in any way.
;
;
; If this  software  was obtained  under the  Apache License,  Version  2.0 (the
; "License"), the following terms apply:
;
; You may  not use this  file except  in compliance  with  the License.  You may
; obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
;
;
; Unless  required  by   applicable  law  or  agreed  to  in  writing,  software
; distributed under the License  is distributed  on an  "AS IS"  BASIS,  WITHOUT
; WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;
; See the   License  for the   specific  language   governing   permissions  and
; limitations under the License.
;===============================================================================

; 
; 
;     Purpose:  Cryptography Primitive.
;               Big Number Arithmetic
; 
;     Content:
;        cpMul_BNU_FullSize()
;
    .686P
    .387
    .XMM
    .MODEL FLAT,C


INCLUDE asmdefs.inc
INCLUDE ia_emm.inc
INCLUDE pcpvariant.inc

IF _USE_NN_MUL_BNU_FS_ EQ _USE
IF _IPP GE _IPP_W7



IPPDATA SEGMENT 'DATA' ALIGN (IPP_ALIGN_FACTOR)

   ALIGN IPP_ALIGN_FACTOR

    MASK1 DQ 0000000000000000H

   ALIGN IPP_ALIGN_FACTOR
IPPDATA SEGMENT 'DATA' ALIGN (IPP_ALIGN_FACTOR)


    fastmovq MACRO mm1,mm2

    pshufw mm1,mm2,11100100b

    ENDM


    DEEP_UNROLLED_MULADD MACRO

    main_loop:

    movd mm1,DWORD PTR[eax + ecx]
    movd mm2,DWORD PTR[edx + ecx]
    movd mm3,DWORD PTR[eax + ecx + 4]
    movd mm4,DWORD PTR[edx + ecx + 4]
    movd mm5,DWORD PTR[eax + ecx + 8]
    movd mm6,DWORD PTR[edx + ecx + 8]

    pmuludq mm1,mm0
    paddq mm1,mm2
    pmuludq mm3,mm0
    paddq mm3,mm4
    pmuludq mm5,mm0
    paddq mm5,mm6


    movd mm2,DWORD PTR[edx + ecx + 12]
    paddq mm7,mm1
    movd mm1,DWORD PTR[eax + ecx + 12]

    pmuludq mm1,mm0
    paddq mm1,mm2
    movd mm2,DWORD PTR[edx + ecx + 24]
    movd DWORD PTR[edx + ecx],mm7

    psrlq mm7,32
    paddq mm7,mm3

    movd mm3,DWORD PTR[eax + ecx + 16]
    movd mm4,DWORD PTR[edx + ecx + 16]

    pmuludq mm3,mm0


    movd DWORD PTR[edx + ecx + 4],mm7

    psrlq mm7,32
    paddq mm3,mm4
    movd mm4,DWORD PTR[edx + ecx + 28]
    paddq mm7,mm5
    movd mm5,DWORD PTR[eax + ecx + 20]
    movd mm6,DWORD PTR[edx + ecx + 20]

    pmuludq mm5,mm0
    movd DWORD PTR[edx + ecx + 8],mm7
    psrlq mm7,32


    paddq mm5,mm6
    movd mm6,DWORD PTR[edx + ecx + 32]
    paddq mm7,mm1

    movd mm1,DWORD PTR[eax + ecx + 24]


    pmuludq mm1,mm0


    movd DWORD PTR[edx + ecx + 12],mm7
    psrlq mm7,32

    paddq mm1,mm2
    movd mm2,DWORD PTR[edx + ecx + 36]
    paddq mm7,mm3

    movd mm3,DWORD PTR[eax + ecx + 28]
    pmuludq mm3,mm0

    movd DWORD PTR[edx + ecx + 16],mm7
    psrlq mm7,32
    paddq mm3,mm4
    movd mm4,DWORD PTR[edx + ecx + 40]
    paddq mm7,mm5

    movd mm5,DWORD PTR[eax + ecx + 32]
    pmuludq mm5,mm0

    movd DWORD PTR[edx + ecx + 20],mm7
    psrlq mm7,32

    paddq mm5,mm6
    movd mm6,DWORD PTR[edx + ecx + 44]
    paddq mm7,mm1
    movd mm1,DWORD PTR[eax + ecx + 36]
    pmuludq mm1,mm0
    movd DWORD PTR[edx + ecx + 24],mm7
    psrlq mm7,32

    paddq mm1,mm2
    movd mm2,DWORD PTR[edx + ecx + 48]
    paddq mm7,mm3
    movd mm3,DWORD PTR[eax + ecx + 40]
    pmuludq mm3,mm0

    movd DWORD PTR[edx + ecx + 28],mm7
    psrlq mm7,32
    paddq mm3,mm4
    movd mm4,DWORD PTR[edx + ecx + 52]
    paddq mm7,mm5

    movd mm5,DWORD PTR[eax + ecx + 44]
    pmuludq mm5,mm0

    movd DWORD PTR[edx + ecx + 32],mm7
    psrlq mm7,32
    paddq mm5,mm6
    movd mm6,DWORD PTR[edx + ecx + 56]
    paddq mm7,mm1

    movd mm1,DWORD PTR[eax + ecx + 48]
    pmuludq mm1,mm0

    movd DWORD PTR[edx + ecx + 36],mm7
    psrlq mm7,32

    paddq mm1,mm2
    movd mm2,DWORD PTR[edx + ecx + 60]
    paddq mm7,mm3

    movd mm3,DWORD PTR[eax + ecx + 52]
    pmuludq mm3,mm0

    movd DWORD PTR[edx + ecx + 40],mm7
    psrlq mm7,32
    paddq mm3,mm4
    paddq mm7,mm5

    movd mm5,DWORD PTR[eax + ecx + 56]

    pmuludq mm5,mm0
    movd DWORD PTR[edx + ecx + 44],mm7
    psrlq mm7,32
    paddq mm5,mm6
    paddq mm7,mm1

    movd mm1,DWORD PTR[eax + ecx + 60]

    pmuludq mm1,mm0
    movd DWORD PTR[edx + ecx + 48],mm7
    psrlq mm7,32

    paddq mm7,mm3
    movd DWORD PTR[edx + ecx + 52],mm7
    psrlq mm7,32
    paddq mm1,mm2
    paddq mm7,mm5
    movd DWORD PTR[edx + ecx + 56],mm7
    psrlq mm7,32

    paddq mm7,mm1
    movd DWORD PTR[edx + ecx + 60],mm7
    psrlq mm7,32



    add ecx,64
    cmp ecx,edi
    jl main_loop


    ENDM

    UNROLL8_MULADD MACRO

;   main_loop1:

    movd mm1,DWORD PTR[eax + ecx]
    movd mm2,DWORD PTR[edx + ecx]
    movd mm3,DWORD PTR[eax + ecx + 4]
    movd mm4,DWORD PTR[edx + ecx + 4]
    movd mm5,DWORD PTR[eax + ecx + 8]
    movd mm6,DWORD PTR[edx + ecx + 8]

    pmuludq mm1,mm0
    paddq mm1,mm2
    pmuludq mm3,mm0
    paddq mm3,mm4
    pmuludq mm5,mm0
    paddq mm5,mm6


    movd mm2,DWORD PTR[edx + ecx + 12]
    paddq mm7,mm1
    movd mm1,DWORD PTR[eax + ecx + 12]

    pmuludq mm1,mm0
    paddq mm1,mm2
    movd mm2,DWORD PTR[edx + ecx + 24]
    movd DWORD PTR[edx + ecx],mm7

    psrlq mm7,32
    paddq mm7,mm3

    movd mm3,DWORD PTR[eax + ecx + 16]
    movd mm4,DWORD PTR[edx + ecx + 16]

    pmuludq mm3,mm0


    movd DWORD PTR[edx + ecx + 4],mm7

    psrlq mm7,32
    paddq mm3,mm4
    movd mm4,DWORD PTR[edx + ecx + 28]
    paddq mm7,mm5
    movd mm5,DWORD PTR[eax + ecx + 20]
    movd mm6,DWORD PTR[edx + ecx + 20]

    pmuludq mm5,mm0
    movd DWORD PTR[edx + ecx + 8],mm7
    psrlq mm7,32


    paddq mm5,mm6
;    movd mm6,DWORD PTR[edx + ecx + 32]
    paddq mm7,mm1

    movd mm1,DWORD PTR[eax + ecx + 24]


    pmuludq mm1,mm0


    movd DWORD PTR[edx + ecx + 12],mm7
    psrlq mm7,32

    paddq mm1,mm2
;   movd mm2,DWORD PTR[edx + ecx + 36]
    paddq mm7,mm3

    movd mm3,DWORD PTR[eax + ecx + 28]
    pmuludq mm3,mm0

    movd DWORD PTR[edx + ecx + 16],mm7
    psrlq mm7,32
    paddq mm3,mm4
;   movd mm4,DWORD PTR[edx + ecx + 40]
    paddq mm7,mm5

;   movd mm5,DWORD PTR[eax + ecx + 32]
;   pmuludq mm5,mm0

    movd DWORD PTR[edx + ecx + 20],mm7
    psrlq mm7,32

;   paddq mm5,mm6
;   movd mm6,DWORD PTR[edx + ecx + 44]
    paddq mm7,mm1
;   movd mm1,DWORD PTR[eax + ecx + 36]
;   pmuludq mm1,mm0
    movd DWORD PTR[edx + ecx + 24],mm7
    psrlq mm7,32

;   paddq mm1,mm2
;   movd mm2,DWORD PTR[edx + ecx + 48]
    paddq mm7,mm3
;   movd mm3,DWORD PTR[eax + ecx + 40]
;   pmuludq mm3,mm0

    movd DWORD PTR[edx + ecx + 28],mm7   ;//
    psrlq mm7,32
;   paddq mm3,mm4
;   movd mm4,DWORD PTR[edx + ecx + 52]
;   paddq mm7,mm5

;   movd mm5,DWORD PTR[eax + ecx + 44]
;   pmuludq mm5,mm0

;   movd DWORD PTR[edx + ecx + 32],mm7
;   psrlq mm7,32
;   paddq mm5,mm6
;   movd mm6,DWORD PTR[edx + ecx + 56]
;   paddq mm7,mm1

;   movd mm1,DWORD PTR[eax + ecx + 48]
;   pmuludq mm1,mm0

;   movd DWORD PTR[edx + ecx + 36],mm7
;   psrlq mm7,32

;   paddq mm1,mm2
;   movd mm2,DWORD PTR[edx + ecx + 60]
;   paddq mm7,mm3

;   movd mm3,DWORD PTR[eax + ecx + 52]
;   pmuludq mm3,mm0

;   movd DWORD PTR[edx + ecx + 40],mm7
;   psrlq mm7,32
;   paddq mm3,mm4
;   paddq mm7,mm5

;   movd mm5,DWORD PTR[eax + ecx + 56]

;   pmuludq mm5,mm0
;   movd DWORD PTR[edx + ecx + 44],mm7
;   psrlq mm7,32
;   paddq mm5,mm6
;   paddq mm7,mm1

;   movd mm1,DWORD PTR[eax + ecx + 60]

;   pmuludq mm1,mm0
;   movd DWORD PTR[edx + ecx + 48],mm7
;   psrlq mm7,32

;   paddq mm7,mm3
;   movd DWORD PTR[edx + ecx + 52],mm7
;   psrlq mm7,32
;   paddq mm1,mm2
;   paddq mm7,mm5
;   movd DWORD PTR[edx + ecx + 56],mm7
;   psrlq mm7,32

;   paddq mm7,mm1
;   movd DWORD PTR[edx + ecx + 60],mm7
;   psrlq mm7,32



    add ecx,32
;   cmp ecx,edi
;   jl main_loop1

    ENDM



    MULADD_START MACRO i,j
    movd mm1,DWORD PTR[eax + 4*j]
    movd mm3,DWORD PTR[eax + 4*j]
    pmuludq mm1,mm0
    paddq mm7,mm1
    movd DWORD PTR[edx + 4*(i+j)],mm7
    pand mm3,mm6
    psrlq mm7,32
    paddq mm7,mm3
    ENDM


    MULADD MACRO i,j
    movd mm1,DWORD PTR[eax + 4*j]
    movd mm3,DWORD PTR[eax + 4*j]
    movd mm2,DWORD PTR[edx + 4*(i+j)]
    pmuludq mm1,mm0
    pand mm3,mm6
    paddq mm1,mm2
    paddq mm7,mm1
    movd DWORD PTR[edx + 4*(i+j)],mm7
    psrlq mm7,32
    paddq mm7,mm3
    ENDM

    SQR_DECOMPOSE MACRO i

    movd mm7,DWORD PTR[eax + 4*i]
    movd mm0,DWORD PTR[eax + 4*i]
    movd mm6,DWORD PTR[eax + 4*i]
    if i ne 0
    movd mm1,DWORD PTR[edx + 4*(2*i)]
    endif
    pslld mm0,1
    pmuludq mm7,mm7
    psrad mm6,32
    if i ne 0
    paddq mm7,mm1
    endif
    movd DWORD PTR[edx + 4*(2*i)],mm7
    psrlq mm7,32


    ENDM

    STORE_CARRY MACRO i,s
    movq [edx + 4*(i + s)],mm7
;   psrlq mm7,32
;   movd DWORD PTR[edx + 4*(i + s + 1)],mm7
    ENDM

    STORE_CARRY_NEXT MACRO i,s
    movd mm4,DWORD PTR[edx + 4*(i + s)]
    paddq mm4,mm7
    movd DWORD PTR[edx + 4*(i + s)],mm4
    psrlq mm7,32
    movd DWORD PTR[edx + 4*(i + s + 1)],mm7
    ENDM

    LAST_STEP MACRO s
    movd mm7,DWORD PTR[eax + 4*(s - 1)]
    movd mm2,DWORD PTR[edx + 4*(2*s - 2)]
    pmuludq mm7,mm7
    paddq mm7,mm2
    movd mm4,DWORD PTR[edx + 4*(2*s - 1)]
    movd DWORD PTR[edx + 4*(2*s - 2)],mm7
    psrlq mm7,32
    paddq mm4,mm7
    movd DWORD PTR[edx + 4*(2*s - 1)],mm4
    ENDM


    INNER_LOOP MACRO i, nsize

    j = i + 1
    s = nsize - i - 1

    SQR_DECOMPOSE i


    repeat s
if i eq 0
    MULADD_START i,j
else
    MULADD i,j
endif
    j = j + 1
    endm


if i eq 0
    STORE_CARRY i,nsize
else
    STORE_CARRY_NEXT i,nsize
endif
    ENDM

    OUTER_LOOP MACRO nsize

    i = 0

    repeat nsize - 1
    INNER_LOOP i,nsize
    i = i + 1
    endm

    LAST_STEP nsize

    ENDM







    MULADD_wt_addcarry MACRO i,j
    movd mm1,DWORD PTR[eax + 4*j]
    movd mm2,DWORD PTR[edx + 4*(i+j)]
    pmuludq mm1,mm0
    paddq mm1,mm2
    paddq mm7,mm1
    movd DWORD PTR[edx + 4*(i+j)],mm7
    psrlq mm7,32
    ENDM

    MULADD_START_wt_addcarry MACRO i,j
    movd mm1,DWORD PTR[eax + 4*j]
    pmuludq mm1,mm0
    paddq mm7,mm1
    movd DWORD PTR[edx + 4*(i+j)],mm7
    psrlq mm7,32
    ENDM



    SQR_DECOMPOSE8 MACRO i
    xor esi,esi
    movd mm7,DWORD PTR[eax + 4*i]
    movd mm0,DWORD PTR[eax + 4*i]
    movd mm6,DWORD PTR[eax + 4*i]
    if i ne 0
    movd mm1,DWORD PTR[edx + 4*(2*i)]
    endif
    pslld mm0,1
    pmuludq mm7,mm7
    psrad mm6,32
    if i ne 0
    paddq mm7,mm1
    endif
    movd DWORD PTR[edx + 4*(2*i)],mm7
    psrlq mm7,32
    movd esi,mm6

    ENDM




    INNER_LOOP8 MACRO i, nsize

    j = i + 1
    s = nsize - i - 1

    SQR_DECOMPOSE8 i

cmp esi,0

je @CATSTR(_else,i)
ALIGN IPP_ALIGN_FACTOR
    repeat s
if i eq 0
    MULADD_START i,j
else
    MULADD i,j
endif
    j = j + 1
    endm

jmp @CATSTR(_next,i)

@CATSTR(_else,i):



    j = i + 1
    s = nsize - i - 1

ALIGN IPP_ALIGN_FACTOR
    repeat s
if i eq 0
    MULADD_START_wt_addcarry i,j
else
    MULADD_wt_addcarry i,j
endif
    j = j + 1
    endm


@CATSTR(_next,i):


if i eq 0
    STORE_CARRY i,nsize
else
    STORE_CARRY_NEXT i,nsize
endif
    ENDM

    OUTER_LOOP MACRO nsize

    i = 0

    repeat nsize - 1
    INNER_LOOP i,nsize
    i = i + 1
    endm

    LAST_STEP nsize

    ENDM




    OUTER_LOOP8 MACRO nsize

    INNER_LOOP8 0,nsize
    INNER_LOOP8 1,nsize
    INNER_LOOP8 2,nsize
    INNER_LOOP8 3,nsize
    INNER_LOOP8 4,nsize
    INNER_LOOP8 5,nsize
    INNER_LOOP8 6,nsize

    LAST_STEP nsize

    ENDM







    MULADD_START1 MACRO i,j
    movd mm1,DWORD PTR[eax + 4*j]
    pmuludq mm1,mm0
    paddq mm7,mm1
    movd DWORD PTR[edx + 4*(i+j)],mm7
    psrlq mm7,32
    ENDM

    MULADD_START_wt_carry MACRO i
    movd mm7,DWORD PTR[eax]
    movd mm2,DWORD PTR[edx + 4*(i)]
    pmuludq mm7,mm0
    paddq mm7,mm2
    movd DWORD PTR[edx + 4*(i)],mm7
    psrlq mm7,32
    ENDM

    MULADD_START_wt_carry1 MACRO
    movd mm7,DWORD PTR[eax]
    pmuludq mm7,mm0
    movd DWORD PTR[edx],mm7
    psrlq mm7,32
    ENDM


    MULADD1 MACRO i,j
    movd mm1,DWORD PTR[eax + 4*j]
    movd mm2,DWORD PTR[edx + 4*(i+j)]
    pmuludq mm1,mm0
    paddq mm1,mm2
    paddq mm7,mm1
    movd DWORD PTR[edx + 4*(i+j)],mm7
    psrlq mm7,32
    ENDM

    INNER_LOOP1 MACRO i, nsize
    j = 0
;   pandn mm7,mm7
    movd mm0,DWORD PTR[ebx + 4*i]

    repeat nsize
if i eq 0
    if j eq 0
        MULADD_START_wt_carry1
    else
        MULADD_START1 i,j
    endif
else
    if j eq 0
        MULADD_START_wt_carry i
    else
        MULADD1 i,j
    endif
endif
    j = j + 1
    endm
    movd DWORD PTR[edx + 4*(i + nsize)],mm7
    ENDM

    OUTER_LOOP1 MACRO nsize
    i = 0
    repeat nsize
    INNER_LOOP1 i,nsize
    i = i + 1
    endm
    ENDM


    PUBLIC cpMul_BNU_FullSize
IPPDATA ENDS

IPPCODE SEGMENT 'CODE' ALIGN (IPP_ALIGN_FACTOR)


IPPASM    cpMul_BNU_FullSize PROC NEAR

   push                ebp
   mov                 ebp, esp
   sub esp,28
   mov                 DWORD PTR [ebp-8],ebx
   mov                 DWORD PTR [ebp-12],edx
   mov                 DWORD PTR [ebp-16],edi
   mov                 DWORD PTR [ebp-20],esi
   mov                 DWORD PTR [ebp-24],ecx

    mov   eax,[ebp + 8]   ;a
    mov   edi,[ebp + 12]  ;a_len
    mov   ebx,[ebp + 16]  ;b
    mov   esi,[ebp + 20]  ;b_len
    mov   edx,[ebp + 24]  ;r

    cmp   eax,ebx
    jne   simple_mul

    cmp   edi,4
    je    sqr4
    cmp   edi,5
    je    sqr5
    cmp   edi,6
    je    sqr6
    cmp   edi,7
    je    sqr7
    cmp   edi,8
    je    sqr8
    cmp   edi,9
    je    sqr9
    cmp   edi,10
    je    sqr10
    cmp   edi,11
    je    sqr11
    cmp   edi,12
    je    sqr12
    cmp   edi,13
    je    sqr13
    cmp   edi,14
    je    sqr14
    cmp   edi,15
    je    sqr15
    cmp   edi,16
    je    sqr16
    cmp   edi,17
    je    sqr17
;    cmp   edi,32
;    je    sqr32

simple_mul:
    cmp   edi,4
    jne   next5
    cmp   esi,4
    je    mul4
next5:
    cmp   edi,5
    jne   next6
    cmp   esi,5
    je    mul5
next6:
    cmp   edi,6
    jne   next7
    cmp   esi,6
    je    mul6
next7:
    cmp   edi,7
    jne   next8
    cmp   esi,7
    je    mul7
next8:
    cmp   edi,8
    jne   next9
    cmp   esi,8
    je    mul8
next9:
    cmp   edi,9
    jne   next10
    cmp   esi,9
    je    mul9
next10:
    cmp   edi,10
    jne   next11
    cmp   esi,10
    je    mul10
next11:
    cmp   edi,11
    jne   next12
    cmp   esi,11
    je    mul11
next12:
    cmp   edi,12
    jne   next13
    cmp   esi,12
    je    mul12
next13:
    cmp   edi,13
    jne   next14
    cmp   esi,13
    je    mul13
next14:
    cmp   edi,14
    jne   next15
    cmp   esi,14
    je    mul14
next15:
    cmp   edi,15
    jne   next16
    cmp   esi,15
    je    mul15
next16:
    cmp   edi,16
    jne   next17
    cmp   esi,16
    je    mul16
next17:
    cmp   edi,17
    jne   next2
    cmp   esi,17
    je    mul17

next2:

if 1
    add esi,edi
    xor ecx,ecx
    init_loop:
    mov [edx],ecx
    add edx,4
    add esi,-1
    jne init_loop

    mov esi,[ebp + 20]  ;b_len
    mov edx,[ebp + 24]  ;r
endif

if 1
    test edi,0fh
    jne sm_loop

endif

    shl edi,2
    shl esi,2

    outer_big_loop:

    pandn mm7,mm7

    ;movq mm7,MASK1
    xor ecx,ecx

    movd mm0,DWORD PTR[ebx] ;b


    DEEP_UNROLLED_MULADD

    movd DWORD PTR[edx + ecx],mm7
    add edx,4
    add ebx,4
    add esi,-4
    jne outer_big_loop

    jmp finish

    sm_loop:

    cmp edi,8

    jne sm_loop1

    shl edi,2
    shl esi,2

    outer_middle_loop:

    pandn mm7,mm7

    ;movq mm7,MASK1
    xor ecx,ecx

    movd mm0,DWORD PTR[ebx] ;b


    UNROLL8_MULADD

    movd DWORD PTR[edx + ecx],mm7
    add edx,4
    add ebx,4
    add esi,-4
    jne outer_middle_loop

    jmp finish

    sm_loop1:

    shl edi,2
    shl esi,2

    outer_small_loop:

    pandn mm7,mm7


    xor ecx,ecx

    movd mm0,DWORD PTR[ebx] ;b



    inner_small_loop:

    movd mm1,DWORD PTR[eax + ecx]
    movd mm2,DWORD PTR[edx + ecx]


    pmuludq mm1,mm0
    paddq mm2,mm1
    paddq mm7,mm2
    movd DWORD PTR[edx + ecx],mm7
    psrlq mm7,32

    add ecx,4

    cmp ecx,edi
    jl  inner_small_loop

    movd DWORD PTR[edx + ecx],mm7
    add edx,4
    add ebx,4
    add esi,-4
    jne outer_small_loop









    finish:







    mov                 ebx,DWORD PTR [ebp-8]
    mov                 edx,DWORD PTR [ebp-12]
    mov                 edi,DWORD PTR [ebp-16]
    mov                 esi,DWORD PTR [ebp-20]
    mov                 ecx,DWORD PTR [ebp-24]
    mov                 esp,ebp
    pop                 ebp


    emms
    ret


squaring:

sqr4:
   OUTER_LOOP 4
    jmp finish
sqr5:
   OUTER_LOOP 5
    jmp finish
sqr6:
   OUTER_LOOP 6
    jmp finish
sqr7:
   OUTER_LOOP 7
    jmp finish
sqr8:
   OUTER_LOOP 8
    jmp finish
sqr9:
   OUTER_LOOP 9
    jmp finish
sqr10:
   OUTER_LOOP 10
    jmp finish
sqr11:
   OUTER_LOOP 11
    jmp finish
sqr12:
    OUTER_LOOP 12
    jmp finish
sqr13:
   OUTER_LOOP 13
    jmp finish
sqr14:
   OUTER_LOOP 14
    jmp finish
sqr15:
   OUTER_LOOP 15
    jmp finish
sqr16:
    OUTER_LOOP 16
    jmp finish
sqr17:
    OUTER_LOOP 17
    jmp finish
;sqr32:
;    OUTER_LOOP 32
;    jmp finish

mul4:
    OUTER_LOOP1 4
    jmp finish
mul5:
    OUTER_LOOP1 5
    jmp finish
mul6:
    OUTER_LOOP1 6
    jmp finish
mul7:
    OUTER_LOOP1 7
    jmp finish
mul8:
    OUTER_LOOP1 8
    jmp finish
mul9:
    OUTER_LOOP1 9
    jmp finish
mul10:
    OUTER_LOOP1 10
    jmp finish
mul11:
    OUTER_LOOP1 11
    jmp finish
mul12:
    OUTER_LOOP1 12
    jmp finish
mul13:
    OUTER_LOOP1 13
    jmp finish
mul14:
    OUTER_LOOP1 14
    jmp finish
mul15:
    OUTER_LOOP1 15
    jmp finish
mul16:
    OUTER_LOOP1 16
    jmp finish
mul17:
    OUTER_LOOP1 17
    jmp finish

IPPASM    cpMul_BNU_FullSize endp

ENDIF
ENDIF ;; _USE_NN_MUL_BNU_FS_
END
