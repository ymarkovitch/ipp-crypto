;===============================================================================
; Copyright 2015-2019 Intel Corporation
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
;               Big Number Operations
;
;     Content:
;        cpSqr_avx2()
;        cpMontRed_avx2()
;

include asmdefs.inc
include ia_32e.inc

IF (_IPP32E GE _IPP32E_L9)

IPPCODE SEGMENT 'CODE' ALIGN (IPP_ALIGN_FACTOR)

DIGIT_BITS = 27
DIGIT_MASK = (1 SHL DIGIT_BITS) -1

;*************************************************************
;* void cpSqr_avx2(Ipp64u* pR,
;*           const Ipp64u* pA, int aSize,
;*                 Ipp64u* pBuffer)
;*************************************************************
ALIGN IPP_ALIGN_FACTOR
IPPASM cpSqr_avx2_V0 PROC PUBLIC FRAME
      USES_GPR rsi,rdi,rbx,rbp,r12,r13
      LOCAL_FRAME = sizeof(qword)*6
      USES_XMM_AVX ymm6,ymm7,ymm8,ymm9,ymm10,ymm11,ymm12,ymm13,ymm14
      COMP_ABI 4

      movsxd   rdx, edx             ; redLen value counter
      vpxor    ymm11, ymm11, ymm11

;; expands A
      vmovdqu  ymmword ptr[rsi+rdx*sizeof(qword)], ymm11 ; size of buffer = redLen+4

;
; stack struct
;
pResult  = 0                        ; pointer to result
pA       = pResult+sizeof(qword)    ; pointer to A operand
redLen   = pA+sizeof(qword)         ; length
len4     = redLen+sizeof(qword)     ; x4 length
pA2      = len4+sizeof(qword)       ; pointer to buffer (contains doubled input (A*2) and temporary result (A^2) )
pAxA     = pA2+sizeof(qword)        ; pointer to temporary result (A^2)

      lea      rax, [rdx+3]                     ; len4 = ((redLen+3) &(-4))/4
      and      rax, -4                          ; multiple 4 length of operand (in ymmwords)
      shr      rax, 2

      mov      qword ptr[rsp+pResult], rdi      ; store pointer to result
      mov      qword ptr[rsp+pA], rsi           ; store pointer to input A
      mov      qword ptr[rsp+redLen], rdx       ; store redLen
      mov      qword ptr[rsp+len4], rax         ; store len4

      mov      rdi, rcx                         ; pointer to word buffer
      shl      rax, 2
      mov      qword ptr[rsp+pAxA], rdi         ; pointer to temporary result (low A^2)
      lea      rbx, [rdi+rax*sizeof(qword)]     ; pointer to temporary result (high A^2)
      lea      r9, [rbx+rax*sizeof(qword)]      ; pointer to doubled input (A*2)
      mov      qword ptr[rsp+pA2], r9

;; clear temporary result and double input
clr_dbl_loop:
      vmovdqu  ymm0, ymmword ptr[rsi]
      vpaddq   ymm0, ymm0, ymm0
      vmovdqu  ymmword ptr[rdi], ymm11
      vmovdqu  ymmword ptr[rbx], ymm11
      vmovdqu  ymmword ptr[r9],  ymm0
      add      rsi, sizeof(ymmword)
      add      rdi, sizeof(ymmword)
      add      rbx, sizeof(ymmword)
      add      r9,  sizeof(ymmword)
      sub      rax, sizeof(ymmword)/sizeof(qword)
      jg       clr_dbl_loop

;;
;; squaring
;;
      mov      rsi, qword ptr[rsp+pA]     ; restore A
      mov      rdi, qword ptr[rsp+pAxA]   ; restore temp result buffer
      mov      r9,  qword ptr[rsp+pA2]    ; restore temp double buffer

      mov      rax, rsi                   ; tsrc = src + sizeof(qword)*n, n=0,1,2,3
      mov      rcx, 4
ALIGN IPP_ALIGN_FACTOR
sqr_offset_loop:                          ; for(n=0; n<4; n++)

      mov      r10, qword ptr[rsp+len4]
      mov      r12, 3
      and      r12, r10                      ; init vflg = len4%4
      lea      r11, [r10-(4*2-1)]            ; init inner_loop counter (hcnt = len4 -7)
      shr      r10, 2                        ; init outer_loop counter (vcnt = len4/4 -1)
      sub      r10, 1                        ;

      push     r9       ; (optr_d256)
      push     rsi      ; (optr_s256)
      push     rdi      ; (optr_r256)
      push     rax      ; (optr_a256)

ALIGN IPP_ALIGN_FACTOR
sqr_outer_loop:                                             ; for(i=0; i<vcnt; i++)
      vpbroadcastq ymm10, qword ptr[rax]                          ; av0 = {optr_a256[0]}
      vpbroadcastq ymm11, qword ptr[rax+sizeof(qword)*4]          ; av1 = {optr_a256[4]}
      vpbroadcastq ymm12, qword ptr[rax+sizeof(qword)*8]          ; av2 = {optr_a256[8]}
      vpbroadcastq ymm13, qword ptr[rax+sizeof(qword)*12]         ; av3 = {optr_a256[12]}

      vmovdqu     ymm7, ymmword ptr[r9+sizeof(ymmword)*4]         ; di3 = optr_d256[4]
      vmovdqu     ymm8, ymmword ptr[r9+sizeof(ymmword)*5]         ; di2 = optr_d256[5]
      vmovdqu     ymm9, ymmword ptr[r9+sizeof(ymmword)*6]         ; di1 = optr_d256[6]

      vpmuludq    ymm0, ymm10, ymmword ptr[rsi]                   ; t0 = av0*optr_s256[0]
      vpmuludq    ymm1, ymm10, ymmword ptr[r9+sizeof(ymmword)]    ; t1 = av0*optr_d256[1]
      vpmuludq    ymm2, ymm10, ymmword ptr[r9+sizeof(ymmword)*2]  ; t2 = av0*optr_d256[2]
      vpmuludq    ymm3, ymm10, ymmword ptr[r9+sizeof(ymmword)*3]  ; t3 = av0*optr_d256[3]
      vpmuludq    ymm4, ymm10, ymm7                               ; t4 = av0*optr_d256[4]
      vpmuludq    ymm5, ymm10, ymm8                               ; t5 = av0*optr_d256[5]
      vpmuludq    ymm6, ymm10, ymm9                               ; t6 = av0*optr_d256[6]

      vpmuludq    ymm14,ymm11, ymmword ptr[rsi+sizeof(ymmword)*1] ; t2+= av1*optr_s256[1]
      vpaddq      ymm2, ymm2, ymm14
      vpmuludq    ymm14,ymm11, ymmword ptr[r9+sizeof(ymmword)*2]  ; t3+= av1*optr_d256[2]
      vpaddq      ymm3, ymm3, ymm14
      vpmuludq    ymm14,ymm11, ymmword ptr[r9+sizeof(ymmword)*3]  ; t4+= av1*optr_d256[3]
      vpaddq      ymm4, ymm4, ymm14
      vpmuludq    ymm14,ymm11, ymm7                               ; t5 = av1*optr_d256[4]
      vpaddq      ymm5, ymm5, ymm14
      vpmuludq    ymm14,ymm11, ymm8                               ; t6 = av1*optr_d256[5]
      vpaddq      ymm6, ymm6, ymm14

      vpmuludq    ymm14,ymm12, ymmword ptr[rsi+sizeof(ymmword)*2] ; t4+= av2*optr_s256[2]
      vpaddq      ymm4, ymm4, ymm14
      vpmuludq    ymm14,ymm12, ymmword ptr[r9+sizeof(ymmword)*3]  ; t5+= av2*optr_d256[3]
      vpaddq      ymm5, ymm5, ymm14
      vpmuludq    ymm14,ymm12, ymm7                               ; t6+= av2*optr_d256[4]
      vpaddq      ymm6, ymm6, ymm14

      vpmuludq    ymm14,ymm13, ymmword ptr[rsi+sizeof(ymmword)*3] ; t4+= av3*optr_s256[3]
      vpaddq      ymm6, ymm6, ymm14

      vpaddq      ymm0, ymm0, ymmword ptr[rdi+sizeof(ymmword)*0]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*0], ymm0        ; optr_r256[0] = t0
      vpaddq      ymm1, ymm1, ymmword ptr[rdi+sizeof(ymmword)*1]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*1], ymm1        ; optr_r256[1] = t1
      vpaddq      ymm2, ymm2, ymmword ptr[rdi+sizeof(ymmword)*2]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*2], ymm2        ; optr_r256[2] = t2
      vpaddq      ymm3, ymm3, ymmword ptr[rdi+sizeof(ymmword)*3]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*3], ymm3        ; optr_r256[3] = t3
      vpaddq      ymm4, ymm4, ymmword ptr[rdi+sizeof(ymmword)*4]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*4], ymm4        ; optr_r256[4] = t4
      vpaddq      ymm5, ymm5, ymmword ptr[rdi+sizeof(ymmword)*5]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*5], ymm5        ; optr_r256[5] = t5
      vpaddq      ymm6, ymm6, ymmword ptr[rdi+sizeof(ymmword)*6]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*6], ymm6        ; optr_r256[6] = t6

      push        r11
      push        rdi
      push        r9
      add         rdi, sizeof(ymmword)*(8-1)
      add         r9,  sizeof(ymmword)*(8-1)

ALIGN IPP_ALIGN_FACTOR
sqr_inner_loop:                                 ; for(j=0; j<hcnt; j++)
      vmovdqu     ymm6, ymmword ptr[r9]            ; iptr_d[0]

      vpmuludq    ymm0, ymm13, ymm7                ; av3*iptr_d[-3]
      vpmuludq    ymm1, ymm12, ymm8                ; av2*iptr_d[-2]
      vpmuludq    ymm2, ymm11, ymm9                ; av1*iptr_d[-1]
      vpmuludq    ymm3, ymm10, ymm6                ; av0*iptr_d[ 0]
      vpaddq      ymm0, ymm0, ymm1                 ; and accumulate
      vpaddq      ymm0, ymm0, ymm2
      vpaddq      ymm0, ymm0, ymm3
      vpaddq      ymm0, ymm0, ymmword ptr[rdi]
      vmovdqu     ymmword ptr[rdi], ymm0

      vmovdqa     ymm7, ymm8
      vmovdqa     ymm8, ymm9
      vmovdqa     ymm9, ymm6

      add         r9, sizeof(ymmword)
      add         rdi,sizeof(ymmword)
      sub         r11,1
      jg          sqr_inner_loop

      vpmuludq    ymm1, ymm11, ymm9                ; av1*iptr_d[-1]
      vpmuludq    ymm2, ymm12, ymm8                ; av2*iptr_d[-2]
      vpmuludq    ymm3, ymm13, ymm7                ; av3*iptr_d[-3]
      vpaddq      ymm1, ymm1, ymm2                 ; and accumulate
      vpaddq      ymm1, ymm1, ymm3
      vpaddq      ymm1, ymm1, ymmword ptr[rdi]
      vmovdqu     ymmword ptr[rdi], ymm1

      vpmuludq    ymm2, ymm12, ymm9                ; av2*iptr_d[-1]
      vpmuludq    ymm3, ymm13, ymm8                ; av3*iptr_d[-2]
      vpaddq      ymm2, ymm2, ymm3                 ; and accumulate
      vpaddq      ymm2, ymm2, ymmword ptr[rdi+sizeof(ymmword)*1]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*1], ymm2

      vpmuludq    ymm3, ymm13, ymm9                ; accumulate av3*iptr_d[-1]
      vpaddq      ymm3, ymm3, ymmword ptr[rdi+sizeof(ymmword)*2]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*2], ymm3

      pop         r9
      pop         rdi
      pop         r11
      add         r9,  sizeof(ymmword)*4
      add         rdi, sizeof(ymmword)*8
      add         rax, sizeof(ymmword)*4
      add         rsi, sizeof(ymmword)*4
      sub         r11, 4
      sub         r10, 1
      jg          sqr_outer_loop

      cmp         r12, 2
      ja          _4n_3             ; len4 = 4*n+3
      jz          _4n_2             ; len4 = 4*n+2
      jp          _4n_1             ; len4 = 4*n+1
      jmp         _4n_0             ; len4 = 4*n

_4n_3:
      vpbroadcastq ymm10, qword ptr[rax]                          ; av0 = {optr_a256[0]}
      vpmuludq    ymm0, ymm10, ymmword ptr[rsi]
      vpaddq      ymm0, ymm0, ymmword ptr[rdi]
      vmovdqu     ymmword ptr[rdi], ymm0

      vpmuludq    ymm1, ymm10, ymmword ptr[r9+sizeof(ymmword)]
      vpaddq      ymm1, ymm1, ymmword ptr[rdi+sizeof(ymmword)]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)], ymm1

      vpmuludq    ymm2, ymm10, ymmword ptr[r9+sizeof(ymmword)*2]
      vpaddq      ymm2, ymm2, ymmword ptr[rdi+sizeof(ymmword)*2]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*2], ymm2

      vpmuludq    ymm3, ymm10, ymmword ptr[r9+sizeof(ymmword)*3]
      vpaddq      ymm3, ymm3, ymmword ptr[rdi+sizeof(ymmword)*3]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*3], ymm3

      vpmuludq    ymm4, ymm10, ymmword ptr[r9+sizeof(ymmword)*4]
      vpaddq      ymm4, ymm4, ymmword ptr[rdi+sizeof(ymmword)*4]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*4], ymm4

      vpmuludq    ymm5, ymm10, ymmword ptr[r9+sizeof(ymmword)*5]
      vpaddq      ymm5, ymm5, ymmword ptr[rdi+sizeof(ymmword)*5]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*5], ymm5

      vpmuludq    ymm6, ymm10, ymmword ptr[r9+sizeof(ymmword)*6]
      vpaddq      ymm6, ymm6, ymmword ptr[rdi+sizeof(ymmword)*6]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*6], ymm6

      add         rdi, sizeof(ymmword)*2
      add         rsi, sizeof(ymmword)*1
      add         rax, sizeof(ymmword)*1
      add         r9,  sizeof(ymmword)*1
_4n_2:
      vpbroadcastq ymm10, qword ptr[rax]                          ; av0 = {optr_a256[0]}
      vpmuludq    ymm0, ymm10, ymmword ptr[rsi]
      vpaddq      ymm0, ymm0, ymmword ptr[rdi]
      vmovdqu     ymmword ptr[rdi], ymm0

      vpmuludq    ymm1, ymm10, ymmword ptr[r9+sizeof(ymmword)]
      vpaddq      ymm1, ymm1, ymmword ptr[rdi+sizeof(ymmword)]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)], ymm1

      vpmuludq    ymm2, ymm10, ymmword ptr[r9+sizeof(ymmword)*2]
      vpaddq      ymm2, ymm2, ymmword ptr[rdi+sizeof(ymmword)*2]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*2], ymm2

      vpmuludq    ymm3, ymm10, ymmword ptr[r9+sizeof(ymmword)*3]
      vpaddq      ymm3, ymm3, ymmword ptr[rdi+sizeof(ymmword)*3]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*3], ymm3

      vpmuludq    ymm4, ymm10, ymmword ptr[r9+sizeof(ymmword)*4]
      vpaddq      ymm4, ymm4, ymmword ptr[rdi+sizeof(ymmword)*4]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*4], ymm4

      vpmuludq    ymm5, ymm10, ymmword ptr[r9+sizeof(ymmword)*5]
      vpaddq      ymm5, ymm5, ymmword ptr[rdi+sizeof(ymmword)*5]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*5], ymm5

      add         rdi, sizeof(ymmword)*2
      add         rsi, sizeof(ymmword)*1
      add         rax, sizeof(ymmword)*1
      add         r9,  sizeof(ymmword)*1
_4n_1:
      vpbroadcastq ymm10, qword ptr[rax]                          ; av0 = {optr_a256[0]}
      vpmuludq    ymm0, ymm10, ymmword ptr[rsi]
      vpaddq      ymm0, ymm0, ymmword ptr[rdi]
      vmovdqu     ymmword ptr[rdi], ymm0

      vpmuludq    ymm1, ymm10, ymmword ptr[r9+sizeof(ymmword)]
      vpaddq      ymm1, ymm1, ymmword ptr[rdi+sizeof(ymmword)]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)], ymm1

      vpmuludq    ymm2, ymm10, ymmword ptr[r9+sizeof(ymmword)*2]
      vpaddq      ymm2, ymm2, ymmword ptr[rdi+sizeof(ymmword)*2]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*2], ymm2

      vpmuludq    ymm3, ymm10, ymmword ptr[r9+sizeof(ymmword)*3]
      vpaddq      ymm3, ymm3, ymmword ptr[rdi+sizeof(ymmword)*3]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*3], ymm3

      vpmuludq    ymm4, ymm10, ymmword ptr[r9+sizeof(ymmword)*4]
      vpaddq      ymm4, ymm4, ymmword ptr[rdi+sizeof(ymmword)*4]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*4], ymm4

      add         rdi, sizeof(ymmword)*2
      add         rsi, sizeof(ymmword)*1
      add         rax, sizeof(ymmword)*1
      add         r9,  sizeof(ymmword)*1
_4n_0:
      vpbroadcastq ymm10, qword ptr[rax]                          ; av0 = {optr_a256[0]}
      vpbroadcastq ymm11, qword ptr[rax+sizeof(qword)*4]          ; av1 = {optr_a256[4]}
      vpbroadcastq ymm12, qword ptr[rax+sizeof(qword)*8]          ; av2 = {optr_a256[8]}
      vpbroadcastq ymm13, qword ptr[rax+sizeof(qword)*12]         ; av3 = {optr_a256[12]}

      vpmuludq    ymm0, ymm10, ymmword ptr[rsi]                   ; t0 = av0*optr_s256[0]
      vpmuludq    ymm1, ymm10, ymmword ptr[r9+sizeof(ymmword)]    ; t1 = av0*optr_d256[1]
      vpmuludq    ymm2, ymm10, ymmword ptr[r9+sizeof(ymmword)*2]  ; t2 = av0*optr_d256[2]
      vpmuludq    ymm3, ymm10, ymmword ptr[r9+sizeof(ymmword)*3]  ; t3 = av0*optr_d256[3]

      vpmuludq    ymm14,ymm11, ymmword ptr[rsi+sizeof(ymmword)*1] ; t2+= av1*optr_s256[1]
      vpaddq      ymm2, ymm2, ymm14
      vpmuludq    ymm14,ymm11, ymmword ptr[r9+sizeof(ymmword)*2]  ; t3+= av1*optr_d256[2]
      vpaddq      ymm3, ymm3, ymm14
      vpmuludq    ymm4, ymm11, ymmword ptr[r9+sizeof(ymmword)*3]  ; t4 = av1*optr_d256[3]

      vpmuludq    ymm14,ymm12, ymmword ptr[rsi+sizeof(ymmword)*2] ; t4+= av2*optr_s256[2]
      vpaddq      ymm4, ymm4, ymm14
      vpmuludq    ymm5, ymm12, ymmword ptr[r9+sizeof(ymmword)*3]  ; t5 = av2*optr_d256[3]

      vpmuludq    ymm6, ymm13, ymmword ptr[rsi+sizeof(ymmword)*3] ; t6 = av3*optr_s256[3]

      vpaddq      ymm0, ymm0, ymmword ptr[rdi+sizeof(ymmword)*0]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*0], ymm0        ; optr_r256[0] = t0
      vpaddq      ymm1, ymm1, ymmword ptr[rdi+sizeof(ymmword)*1]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*1], ymm1        ; optr_r256[1] = t1
      vpaddq      ymm2, ymm2, ymmword ptr[rdi+sizeof(ymmword)*2]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*2], ymm2        ; optr_r256[2] = t2
      vpaddq      ymm3, ymm3, ymmword ptr[rdi+sizeof(ymmword)*3]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*3], ymm3        ; optr_r256[3] = t3
      vpaddq      ymm4, ymm4, ymmword ptr[rdi+sizeof(ymmword)*4]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*4], ymm4        ; optr_r256[4] = t4
      vpaddq      ymm5, ymm5, ymmword ptr[rdi+sizeof(ymmword)*5]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*5], ymm5        ; optr_r256[5] = t5
      vpaddq      ymm6, ymm6, ymmword ptr[rdi+sizeof(ymmword)*6]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*6], ymm6        ; optr_r256[6] = t6

      pop         rax
      pop         rdi
      pop         rsi
      pop         r9
      add         rdi, sizeof(qword)
      add         rax, sizeof(qword)
      sub         rcx, 1
      jg          sqr_offset_loop

   REST_XMM_AVX
   REST_GPR
   ret
IPPASM cpSqr_avx2_V0 ENDP

ALIGN IPP_ALIGN_FACTOR
IPPASM cpSqr_avx2 PROC PUBLIC FRAME
      USES_GPR rsi,rdi,rbx,rbp,r12,r13
      LOCAL_FRAME = sizeof(qword)*6
      USES_XMM_AVX ymm6,ymm7,ymm8,ymm9,ymm10,ymm11,ymm12,ymm13,ymm14
      COMP_ABI 4

      movsxd   rdx, edx             ; redLen value counter
      vpxor    ymm11, ymm11, ymm11

;; expands A
      vmovdqu  ymmword ptr[rsi+rdx*sizeof(qword)], ymm11 ; size of buffer = redLen+4

;
; stack struct
;
pResult  = 0                        ; pointer to result
pA       = pResult+sizeof(qword)    ; pointer to A operand
redLen   = pA+sizeof(qword)         ; length
len4     = redLen+sizeof(qword)     ; x4 length
pA2      = len4+sizeof(qword)       ; pointer to buffer (contains doubled input (A*2) and temporary result (A^2) )
pAxA     = pA2+sizeof(qword)        ; pointer to temporary result (A^2)

      lea      rax, [rdx+3]                     ; len4 = ((redLen+3) &(-4))/4
      and      rax, -4                          ; multiple 4 length of operand (in ymmwords)
      shr      rax, 2

      mov      qword ptr[rsp+pResult], rdi      ; store pointer to result
      mov      qword ptr[rsp+pA], rsi           ; store pointer to input A
      mov      qword ptr[rsp+redLen], rdx       ; store redLen
      mov      qword ptr[rsp+len4], rax         ; store len4

      mov      rdi, rcx                         ; pointer to word buffer
      shl      rax, 2
      mov      qword ptr[rsp+pAxA], rdi         ; pointer to temporary result (low A^2)
      lea      rbx, [rdi+rax*sizeof(qword)]     ; pointer to temporary result (high A^2)
      lea      r9, [rbx+rax*sizeof(qword)]      ; pointer to doubled input (A*2)
      mov      qword ptr[rsp+pA2], r9

;; clear temporary result and double input
clr_dbl_loop:
      vmovdqu  ymm0, ymmword ptr[rsi]
      vpaddq   ymm0, ymm0, ymm0
      vmovdqu  ymmword ptr[rdi], ymm11
      vmovdqu  ymmword ptr[rbx], ymm11
      vmovdqu  ymmword ptr[r9],  ymm0
      add      rsi, sizeof(ymmword)
      add      rdi, sizeof(ymmword)
      add      rbx, sizeof(ymmword)
      add      r9,  sizeof(ymmword)
      sub      rax, sizeof(ymmword)/sizeof(qword)
      jg       clr_dbl_loop

;;
;; squaring
;;
      mov      rsi, qword ptr[rsp+pA]     ; restore A
      mov      rdi, qword ptr[rsp+pAxA]   ; restore temp result buffer
      mov      r9,  qword ptr[rsp+pA2]    ; restore temp double buffer

      mov      rax, rsi                   ; tsrc = src + sizeof(qword)*n, n=0,1,2,3
      mov      rcx, 4
ALIGN IPP_ALIGN_FACTOR
sqr_offset_loop:                          ; for(n=0; n<4; n++)

      mov      r10, qword ptr[rsp+len4]
      mov      r12, 3
      and      r12, r10                      ; init vflg = len4%4
      lea      r11, [r10-(4*2-1)]            ; init inner_loop counter (hcnt = len4 -7)
      shr      r10, 2                        ; init outer_loop counter (vcnt = len4/4 -1)
      sub      r10, 1                        ;

      push     r9       ; (optr_d256)
      push     rsi      ; (optr_s256)
      push     rdi      ; (optr_r256)
      push     rax      ; (optr_a256)

ALIGN IPP_ALIGN_FACTOR
sqr_outer_loop:                                             ; for(i=0; i<vcnt; i++)
      vpbroadcastq ymm10, qword ptr[rax]                          ; av0 = {optr_a256[0]}
      vpbroadcastq ymm11, qword ptr[rax+sizeof(qword)*4]          ; av1 = {optr_a256[4]}
      vpbroadcastq ymm12, qword ptr[rax+sizeof(qword)*8]          ; av2 = {optr_a256[8]}
      vpbroadcastq ymm13, qword ptr[rax+sizeof(qword)*12]         ; av3 = {optr_a256[12]}

      vmovdqu     ymm7, ymmword ptr[r9+sizeof(ymmword)*4]         ; di3 = optr_d256[4]
      vmovdqu     ymm8, ymmword ptr[r9+sizeof(ymmword)*5]         ; di2 = optr_d256[5]
      vmovdqu     ymm9, ymmword ptr[r9+sizeof(ymmword)*6]         ; di1 = optr_d256[6]

      vpmuludq    ymm0, ymm10, ymmword ptr[rsi]                   ; t0 = av0*optr_s256[0]
      vpmuludq    ymm1, ymm10, ymmword ptr[r9+sizeof(ymmword)]    ; t1 = av0*optr_d256[1]
      vpmuludq    ymm2, ymm10, ymmword ptr[r9+sizeof(ymmword)*2]  ; t2 = av0*optr_d256[2]
      vpmuludq    ymm3, ymm10, ymmword ptr[r9+sizeof(ymmword)*3]  ; t3 = av0*optr_d256[3]
      vpmuludq    ymm4, ymm10, ymm7                               ; t4 = av0*optr_d256[4]
      vpmuludq    ymm5, ymm10, ymm8                               ; t5 = av0*optr_d256[5]
      vpmuludq    ymm6, ymm10, ymm9                               ; t6 = av0*optr_d256[6]

      vpmuludq    ymm14,ymm11, ymmword ptr[rsi+sizeof(ymmword)*1] ; t2+= av1*optr_s256[1]
      vpaddq      ymm2, ymm2, ymm14
      vpmuludq    ymm14,ymm11, ymmword ptr[r9+sizeof(ymmword)*2]  ; t3+= av1*optr_d256[2]
      vpaddq      ymm3, ymm3, ymm14
      vpmuludq    ymm14,ymm11, ymmword ptr[r9+sizeof(ymmword)*3]  ; t4+= av1*optr_d256[3]
      vpaddq      ymm4, ymm4, ymm14
      vpmuludq    ymm14,ymm11, ymm7                               ; t5 = av1*optr_d256[4]
      vpaddq      ymm5, ymm5, ymm14
      vpmuludq    ymm14,ymm11, ymm8                               ; t6 = av1*optr_d256[5]
      vpaddq      ymm6, ymm6, ymm14

      vpmuludq    ymm14,ymm12, ymmword ptr[rsi+sizeof(ymmword)*2] ; t4+= av2*optr_s256[2]
      vpaddq      ymm4, ymm4, ymm14
      vpmuludq    ymm14,ymm12, ymmword ptr[r9+sizeof(ymmword)*3]  ; t5+= av2*optr_d256[3]
      vpaddq      ymm5, ymm5, ymm14
      vpmuludq    ymm14,ymm12, ymm7                               ; t6+= av2*optr_d256[4]
      vpaddq      ymm6, ymm6, ymm14

      vpmuludq    ymm14,ymm13, ymmword ptr[rsi+sizeof(ymmword)*3] ; t4+= av3*optr_s256[3]
      vpaddq      ymm6, ymm6, ymm14

      vpaddq      ymm0, ymm0, ymmword ptr[rdi+sizeof(ymmword)*0]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*0], ymm0        ; optr_r256[0] = t0
      vpaddq      ymm1, ymm1, ymmword ptr[rdi+sizeof(ymmword)*1]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*1], ymm1        ; optr_r256[1] = t1
      vpaddq      ymm2, ymm2, ymmword ptr[rdi+sizeof(ymmword)*2]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*2], ymm2        ; optr_r256[2] = t2
      vpaddq      ymm3, ymm3, ymmword ptr[rdi+sizeof(ymmword)*3]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*3], ymm3        ; optr_r256[3] = t3
      vpaddq      ymm4, ymm4, ymmword ptr[rdi+sizeof(ymmword)*4]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*4], ymm4        ; optr_r256[4] = t4
      vpaddq      ymm5, ymm5, ymmword ptr[rdi+sizeof(ymmword)*5]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*5], ymm5        ; optr_r256[5] = t5
      vpaddq      ymm6, ymm6, ymmword ptr[rdi+sizeof(ymmword)*6]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*6], ymm6        ; optr_r256[6] = t6

      push        r11
      push        rdi
      push        r9
      add         rdi, sizeof(ymmword)*(8-1)
      add         r9,  sizeof(ymmword)*(8-1)

      sub         r11, 4
      jl          exit_sqr_inner_loop4
ALIGN IPP_ALIGN_FACTOR
sqr_inner_loop4:                                ; for(j=0; j<hcnt; j++)
      vmovdqu     ymm6, ymmword ptr[r9]            ; iptr_d[0]
      vpmuludq    ymm14, ymm13, ymm7               ; av3*iptr_d[-3]
      vpaddq      ymm0,  ymm14, ymmword ptr[rdi]
      vpmuludq    ymm14, ymm12, ymm8               ; av2*iptr_d[-2]
      vpaddq      ymm0,  ymm0, ymm14
      vpmuludq    ymm14, ymm11, ymm9               ; av1*iptr_d[-1]
      vpaddq      ymm0,  ymm0, ymm14
      vpmuludq    ymm14, ymm10, ymm6               ; av0*iptr_d[ 0]
      vpaddq      ymm0,  ymm0, ymm14
      vmovdqu     ymmword ptr[rdi], ymm0

      vmovdqu     ymm7,  ymmword ptr[r9+sizeof(ymmword)] ; iptr_d[0]
      vpmuludq    ymm14, ymm13, ymm8                     ; av3*iptr_d[-3]
      vpaddq      ymm1,  ymm14, ymmword ptr[rdi+sizeof(ymmword)]
      vpmuludq    ymm14, ymm12, ymm9                     ; av2*iptr_d[-2]
      vpaddq      ymm1,  ymm1, ymm14
      vpmuludq    ymm14, ymm11, ymm6                     ; av1*iptr_d[-1]
      vpaddq      ymm1,  ymm1, ymm14
      vpmuludq    ymm14, ymm10, ymm7                     ; av0*iptr_d[ 0]
      vpaddq      ymm1,  ymm1, ymm14
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)], ymm1

      vmovdqu     ymm8,  ymmword ptr[r9+sizeof(ymmword)*2]  ; iptr_d[0]
      vpmuludq    ymm14, ymm13, ymm9                        ; av3*iptr_d[-3]
      vpaddq      ymm2,  ymm14, ymmword ptr[rdi+sizeof(ymmword)*2]
      vpmuludq    ymm14, ymm12, ymm6                        ; av2*iptr_d[-2]
      vpaddq      ymm2,  ymm2, ymm14
      vpmuludq    ymm14, ymm11, ymm7                        ; av1*iptr_d[-1]
      vpaddq      ymm2,  ymm2, ymm14
      vpmuludq    ymm14, ymm10, ymm8                        ; av0*iptr_d[ 0]
      vpaddq      ymm2,  ymm2, ymm14
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*2], ymm2

      vmovdqu     ymm9,  ymmword ptr[r9+sizeof(ymmword)*3]  ; iptr_d[0]
      vpmuludq    ymm14, ymm13, ymm6                        ; av3*iptr_d[-3]
      vpaddq      ymm3,  ymm14, ymmword ptr[rdi+sizeof(ymmword)*3]
      vpmuludq    ymm14, ymm12, ymm7                        ; av2*iptr_d[-2]
      vpaddq      ymm3,  ymm3, ymm14
      vpmuludq    ymm14, ymm11, ymm8                        ; av1*iptr_d[-1]
      vpaddq      ymm3,  ymm3, ymm14
      vpmuludq    ymm14, ymm10, ymm9                        ; av0*iptr_d[ 0]
      vpaddq      ymm3,  ymm3, ymm14
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*3], ymm3

      add         r9, sizeof(ymmword)*4
      add         rdi,sizeof(ymmword)*4
      sub         r11,4
      jge         sqr_inner_loop4

exit_sqr_inner_loop4:
      add         r11, 4
      jz          exit_sqr_inner_loop
sqr_inner_loop:
      vmovdqu     ymm6, ymmword ptr[r9]            ; iptr_d[0]
      vpmuludq    ymm14, ymm13, ymm7               ; av3*iptr_d[-3]
      vpaddq      ymm0,  ymm14, ymmword ptr[rdi]
      vpmuludq    ymm14, ymm12, ymm8               ; av2*iptr_d[-2]
      vpaddq      ymm0,  ymm0, ymm14
      vpmuludq    ymm14, ymm11, ymm9               ; av1*iptr_d[-1]
      vpaddq      ymm0,  ymm0, ymm14
      vpmuludq    ymm14, ymm10, ymm6               ; av0*iptr_d[ 0]
      vpaddq      ymm0,  ymm0, ymm14
      vmovdqu     ymmword ptr[rdi], ymm0
      vmovdqa     ymm7, ymm8
      vmovdqa     ymm8, ymm9
      vmovdqa     ymm9, ymm6

      add         r9,  sizeof(ymmword)
      add         rdi, sizeof(ymmword)
      sub         r11, 1
      jg          sqr_inner_loop

exit_sqr_inner_loop:
      vpmuludq    ymm1, ymm11, ymm9                ; av1*iptr_d[-1]
      vpmuludq    ymm2, ymm12, ymm8                ; av2*iptr_d[-2]
      vpmuludq    ymm3, ymm13, ymm7                ; av3*iptr_d[-3]
      vpaddq      ymm1, ymm1, ymm2                 ; and accumulate
      vpaddq      ymm1, ymm1, ymm3
      vpaddq      ymm1, ymm1, ymmword ptr[rdi]
      vmovdqu     ymmword ptr[rdi], ymm1

      vpmuludq    ymm2, ymm12, ymm9                ; av2*iptr_d[-1]
      vpmuludq    ymm3, ymm13, ymm8                ; av3*iptr_d[-2]
      vpaddq      ymm2, ymm2, ymm3                 ; and accumulate
      vpaddq      ymm2, ymm2, ymmword ptr[rdi+sizeof(ymmword)*1]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*1], ymm2

      vpmuludq    ymm3, ymm13, ymm9                ; accumulate av3*iptr_d[-1]
      vpaddq      ymm3, ymm3, ymmword ptr[rdi+sizeof(ymmword)*2]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*2], ymm3

      pop         r9
      pop         rdi
      pop         r11
      add         r9,  sizeof(ymmword)*4
      add         rdi, sizeof(ymmword)*8
      add         rax, sizeof(ymmword)*4
      add         rsi, sizeof(ymmword)*4
      sub         r11, 4
      sub         r10, 1
      jg          sqr_outer_loop

      cmp         r12, 2
      ja          _4n_3             ; len4 = 4*n+3
      jz          _4n_2             ; len4 = 4*n+2
      jp          _4n_1             ; len4 = 4*n+1
      jmp         _4n_0             ; len4 = 4*n

_4n_3:
      vpbroadcastq ymm10, qword ptr[rax]                          ; av0 = {optr_a256[0]}
      vpmuludq    ymm0, ymm10, ymmword ptr[rsi]
      vpaddq      ymm0, ymm0, ymmword ptr[rdi]
      vmovdqu     ymmword ptr[rdi], ymm0

      vpmuludq    ymm1, ymm10, ymmword ptr[r9+sizeof(ymmword)]
      vpaddq      ymm1, ymm1, ymmword ptr[rdi+sizeof(ymmword)]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)], ymm1

      vpmuludq    ymm2, ymm10, ymmword ptr[r9+sizeof(ymmword)*2]
      vpaddq      ymm2, ymm2, ymmword ptr[rdi+sizeof(ymmword)*2]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*2], ymm2

      vpmuludq    ymm3, ymm10, ymmword ptr[r9+sizeof(ymmword)*3]
      vpaddq      ymm3, ymm3, ymmword ptr[rdi+sizeof(ymmword)*3]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*3], ymm3

      vpmuludq    ymm4, ymm10, ymmword ptr[r9+sizeof(ymmword)*4]
      vpaddq      ymm4, ymm4, ymmword ptr[rdi+sizeof(ymmword)*4]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*4], ymm4

      vpmuludq    ymm5, ymm10, ymmword ptr[r9+sizeof(ymmword)*5]
      vpaddq      ymm5, ymm5, ymmword ptr[rdi+sizeof(ymmword)*5]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*5], ymm5

      vpmuludq    ymm6, ymm10, ymmword ptr[r9+sizeof(ymmword)*6]
      vpaddq      ymm6, ymm6, ymmword ptr[rdi+sizeof(ymmword)*6]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*6], ymm6

      add         rdi, sizeof(ymmword)*2
      add         rsi, sizeof(ymmword)*1
      add         rax, sizeof(ymmword)*1
      add         r9,  sizeof(ymmword)*1
_4n_2:
      vpbroadcastq ymm10, qword ptr[rax]                          ; av0 = {optr_a256[0]}
      vpmuludq    ymm0, ymm10, ymmword ptr[rsi]
      vpaddq      ymm0, ymm0, ymmword ptr[rdi]
      vmovdqu     ymmword ptr[rdi], ymm0

      vpmuludq    ymm1, ymm10, ymmword ptr[r9+sizeof(ymmword)]
      vpaddq      ymm1, ymm1, ymmword ptr[rdi+sizeof(ymmword)]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)], ymm1

      vpmuludq    ymm2, ymm10, ymmword ptr[r9+sizeof(ymmword)*2]
      vpaddq      ymm2, ymm2, ymmword ptr[rdi+sizeof(ymmword)*2]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*2], ymm2

      vpmuludq    ymm3, ymm10, ymmword ptr[r9+sizeof(ymmword)*3]
      vpaddq      ymm3, ymm3, ymmword ptr[rdi+sizeof(ymmword)*3]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*3], ymm3

      vpmuludq    ymm4, ymm10, ymmword ptr[r9+sizeof(ymmword)*4]
      vpaddq      ymm4, ymm4, ymmword ptr[rdi+sizeof(ymmword)*4]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*4], ymm4

      vpmuludq    ymm5, ymm10, ymmword ptr[r9+sizeof(ymmword)*5]
      vpaddq      ymm5, ymm5, ymmword ptr[rdi+sizeof(ymmword)*5]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*5], ymm5

      add         rdi, sizeof(ymmword)*2
      add         rsi, sizeof(ymmword)*1
      add         rax, sizeof(ymmword)*1
      add         r9,  sizeof(ymmword)*1
_4n_1:
      vpbroadcastq ymm10, qword ptr[rax]                          ; av0 = {optr_a256[0]}
      vpmuludq    ymm0, ymm10, ymmword ptr[rsi]
      vpaddq      ymm0, ymm0, ymmword ptr[rdi]
      vmovdqu     ymmword ptr[rdi], ymm0

      vpmuludq    ymm1, ymm10, ymmword ptr[r9+sizeof(ymmword)]
      vpaddq      ymm1, ymm1, ymmword ptr[rdi+sizeof(ymmword)]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)], ymm1

      vpmuludq    ymm2, ymm10, ymmword ptr[r9+sizeof(ymmword)*2]
      vpaddq      ymm2, ymm2, ymmword ptr[rdi+sizeof(ymmword)*2]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*2], ymm2

      vpmuludq    ymm3, ymm10, ymmword ptr[r9+sizeof(ymmword)*3]
      vpaddq      ymm3, ymm3, ymmword ptr[rdi+sizeof(ymmword)*3]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*3], ymm3

      vpmuludq    ymm4, ymm10, ymmword ptr[r9+sizeof(ymmword)*4]
      vpaddq      ymm4, ymm4, ymmword ptr[rdi+sizeof(ymmword)*4]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*4], ymm4

      add         rdi, sizeof(ymmword)*2
      add         rsi, sizeof(ymmword)*1
      add         rax, sizeof(ymmword)*1
      add         r9,  sizeof(ymmword)*1
_4n_0:
      vpbroadcastq ymm10, qword ptr[rax]                          ; av0 = {optr_a256[0]}
      vpbroadcastq ymm11, qword ptr[rax+sizeof(qword)*4]          ; av1 = {optr_a256[4]}
      vpbroadcastq ymm12, qword ptr[rax+sizeof(qword)*8]          ; av2 = {optr_a256[8]}
      vpbroadcastq ymm13, qword ptr[rax+sizeof(qword)*12]         ; av3 = {optr_a256[12]}

      vpmuludq    ymm0, ymm10, ymmword ptr[rsi]                   ; t0 = av0*optr_s256[0]
      vpmuludq    ymm1, ymm10, ymmword ptr[r9+sizeof(ymmword)]    ; t1 = av0*optr_d256[1]
      vpmuludq    ymm2, ymm10, ymmword ptr[r9+sizeof(ymmword)*2]  ; t2 = av0*optr_d256[2]
      vpmuludq    ymm3, ymm10, ymmword ptr[r9+sizeof(ymmword)*3]  ; t3 = av0*optr_d256[3]

      vpmuludq    ymm14,ymm11, ymmword ptr[rsi+sizeof(ymmword)*1] ; t2+= av1*optr_s256[1]
      vpaddq      ymm2, ymm2, ymm14
      vpmuludq    ymm14,ymm11, ymmword ptr[r9+sizeof(ymmword)*2]  ; t3+= av1*optr_d256[2]
      vpaddq      ymm3, ymm3, ymm14
      vpmuludq    ymm4, ymm11, ymmword ptr[r9+sizeof(ymmword)*3]  ; t4 = av1*optr_d256[3]

      vpmuludq    ymm14,ymm12, ymmword ptr[rsi+sizeof(ymmword)*2] ; t4+= av2*optr_s256[2]
      vpaddq      ymm4, ymm4, ymm14
      vpmuludq    ymm5, ymm12, ymmword ptr[r9+sizeof(ymmword)*3]  ; t5 = av2*optr_d256[3]

      vpmuludq    ymm6, ymm13, ymmword ptr[rsi+sizeof(ymmword)*3] ; t6 = av3*optr_s256[3]

      vpaddq      ymm0, ymm0, ymmword ptr[rdi+sizeof(ymmword)*0]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*0], ymm0        ; optr_r256[0] = t0
      vpaddq      ymm1, ymm1, ymmword ptr[rdi+sizeof(ymmword)*1]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*1], ymm1        ; optr_r256[1] = t1
      vpaddq      ymm2, ymm2, ymmword ptr[rdi+sizeof(ymmword)*2]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*2], ymm2        ; optr_r256[2] = t2
      vpaddq      ymm3, ymm3, ymmword ptr[rdi+sizeof(ymmword)*3]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*3], ymm3        ; optr_r256[3] = t3
      vpaddq      ymm4, ymm4, ymmword ptr[rdi+sizeof(ymmword)*4]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*4], ymm4        ; optr_r256[4] = t4
      vpaddq      ymm5, ymm5, ymmword ptr[rdi+sizeof(ymmword)*5]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*5], ymm5        ; optr_r256[5] = t5
      vpaddq      ymm6, ymm6, ymmword ptr[rdi+sizeof(ymmword)*6]
      vmovdqu     ymmword ptr[rdi+sizeof(ymmword)*6], ymm6        ; optr_r256[6] = t6

      pop         rax
      pop         rdi
      pop         rsi
      pop         r9
      add         rdi, sizeof(qword)
      add         rax, sizeof(qword)
      sub         rcx, 1
      jg          sqr_offset_loop

   REST_XMM_AVX
   REST_GPR
   ret
IPPASM cpSqr_avx2 ENDP


;*************************************************************
;* void cpMontRed_avx2(Ipp64u* pR,
;*                     Ipp64u* pProduct,
;*               const Ipp64u* pModulus, int mSize,
;*                     Ipp64u* k0)
;*************************************************************
ALIGN IPP_ALIGN_FACTOR
IPPASM cpMontRed_avx2 PROC PUBLIC FRAME
      USES_GPR rsi,rdi,rbx,rbp,r12,r13
      LOCAL_FRAME = sizeof(qword)*7
      USES_XMM_AVX ymm6,ymm7,ymm8,ymm9,ymm10,ymm11,ymm12,ymm13
      COMP_ABI 5

pRes     = 0
pProd    = pRes+sizeof(qword)
pMod     = pProd+sizeof(qword)
mLen     = pMod+sizeof(qword)
pLen     = mLen+sizeof(qword)
len4     = pLen+sizeof(qword)
flagl    = len4+sizeof(qword)

      movsxd   r9,  ecx                                  ; length of the modulus
      mov      qword ptr[rsp+pRes], rdi
      mov      qword ptr[rsp+pProd], rsi
      mov      qword ptr[rsp+pMod], rdx
      mov      qword ptr[rsp+mLen], r9
      lea      rcx, [r9+r9]                              ; length of the product
      mov      qword ptr[rsp+pLen], rcx
      lea      r11, [r9+sizeof(ymmword)/sizeof(qword)-1] ; multiple 4 length of the modulus
      and      r11, -(sizeof(ymmword)/sizeof(qword))
      mov      qword ptr[rsp+len4], r11
      mov      r11, 3                                    ; flagl = mLen %4
      and      r11, r9
      mov      qword ptr[rsp+flagl], r11

      mov      rbx, rdx                ; copy pointer to Modulus

      vpxor    ymm11, ymm11, ymm11     ; expands modulus product
      vmovdqu  ymmword ptr[rbx+r9*sizeof(qword)], ymm11
      vmovdqu  ymmword ptr[rsi+rcx*sizeof(qword)], ymm11

ALIGN IPP_ALIGN_FACTOR
;;
;; process modulus[] by quadruples (n[j], n[j+1], n[j+2] and n[j+3]) per pass
;;
outer_reduction_loop4:
      mov      r10, qword ptr[rsi]                 ; ac0, ac1, ac2, ac3
      mov      r11, qword ptr[rsi+sizeof(qword)]
      mov      r12, qword ptr[rsi+sizeof(qword)*2]
      mov      r13, qword ptr[rsi+sizeof(qword)*3]

      mov      rdx, r10                            ; y0 = (ac0*m0) & DIGIT_MASK
      imul     edx, r8d
      and      edx, DIGIT_MASK
      vmovd    xmm8, edx
      vpbroadcastq ymm8, xmm8

      mov      rax, rdx                            ; ac0 += pn[0]*y0
      imul     rax, qword ptr[rbx]
      add      r10, rax
      shr      r10, DIGIT_BITS
      mov      rax, rdx                            ; ac1 += pn[1]*y0
      imul     rax, qword ptr[rbx+sizeof(qword)]
      add      r11, rax
      add      r11, r10
      mov      rax, rdx                            ; ac2 += pn[2]*y0
      imul     rax, qword ptr[rbx+sizeof(qword)*2]
      add      r12, rax
      imul     rdx, qword ptr[rbx+sizeof(qword)*3] ; ac2 += pn[2]*y0
      add      r13, rdx
      cmp      r9, 1
      jz       last_1                              ; to process latest n[mLen-1]

      mov      rdx, r11                            ; y1 = (ac1*m0) & DIGIT_MASK
      imul     edx, r8d
      and      edx, DIGIT_MASK
      vmovd    xmm9, edx
      vpbroadcastq ymm9, xmm9

      mov      rax, rdx                            ; ac1 += pn[0]*y1
      imul     rax, qword ptr[rbx]
      add      r11, rax
      shr      r11, DIGIT_BITS
      mov      rax, rdx                            ; ac2 += pn[1]*y1
      imul     rax, qword ptr[rbx+sizeof(qword)]
      add      r12, rax
      add      r12, r11
      imul     rdx, qword ptr[rbx+sizeof(qword)*2] ; ac3 += pn[2]*y1
      add      r13, rdx
      cmp      r9, 2
      jz       last_2                              ; to process latest n[mLen-2], n[mLen-1]

      mov      rdx, r12                            ; y2 = (ac2*m0) & DIGIT_MASK
      imul     edx, r8d
      and      edx, DIGIT_MASK
      vmovd    xmm10, edx
      vpbroadcastq ymm10, xmm10

      mov      rax, rdx                            ; ac2 += pn[0]*y2
      imul     rax, qword ptr[rbx]
      add      r12, rax
      shr      r12, DIGIT_BITS
      imul     rdx, qword ptr[rbx+sizeof(qword)]   ; ac3 += pn[1]*y2
      add      r13, rdx
      add      r13, r12
      cmp      r9, 3
      jz       last_3                              ; to process latest n[mLen-3], n[mLen-2], n[mLen-1]

      mov      rdx, r13                            ; y3 = (ac3*m0) & DIGIT_MASK
      imul     edx, r8d
      and      edx, DIGIT_MASK
      vmovd    xmm11, edx
      vpbroadcastq ymm11, xmm11

      imul     rdx, qword ptr[rbx]                 ; ac3 += pn[0]*y3
      add      r13, rdx
      shr      r13, DIGIT_BITS

      vmovq    xmm0, r13
      vpaddq   ymm0,  ymm0, ymmword ptr[rsi+sizeof(ymmword)]
      vmovdqu  ymmword ptr[rsi+sizeof(ymmword)], ymm0

      add      rbx, sizeof(qword)*4                ; advance pointer to modulus
      add      rsi, sizeof(ymmword)                ; advance pointer to product

      mov      r11, qword ptr[rsp+len4]            ; init hcnt = len4 (number of qwordrs)
      sub      r11, sizeof(ymmword)/sizeof(qword)

ALIGN IPP_ALIGN_FACTOR
inner_reduction_loop16:
      sub      r11, 4*sizeof(ymmword)/sizeof(qword)
      jl       exit_inner_reduction_loop16

      vmovdqu  ymm0, ymmword ptr[rsi]                       ; r0
      vmovdqu  ymm1, ymmword ptr[rsi+sizeof(ymmword)]       ; r1
      vmovdqu  ymm2, ymmword ptr[rsi+sizeof(ymmword)*2]     ; r2
      vmovdqu  ymm3, ymmword ptr[rsi+sizeof(ymmword)*3]     ; r3

      vpmuludq ymm13, ymm8, ymmword ptr[rbx]                                  ; r0 += y0 * pn[j]
      vpaddq   ymm0,  ymm0, ymm13
      vpmuludq ymm13, ymm8, ymmword ptr[rbx+sizeof(ymmword)]                  ; r1 += y0 * pn[j+1]
      vpaddq   ymm1,  ymm1, ymm13
      vpmuludq ymm13, ymm8, ymmword ptr[rbx+sizeof(ymmword)*2]                ; r2 += y0 * pn[j+2]
      vpaddq   ymm2,  ymm2, ymm13
      vpmuludq ymm13, ymm8, ymmword ptr[rbx+sizeof(ymmword)*3]                ; r3 += y0 * pn[j+3]
      vpaddq   ymm3,  ymm3, ymm13

      vpmuludq ymm13, ymm9, ymmword ptr[rbx-sizeof(qword)]                    ; r0 += y1 * pn[-1+j]
      vpaddq   ymm0,  ymm0, ymm13
      vpmuludq ymm13, ymm9, ymmword ptr[rbx-sizeof(qword)+sizeof(ymmword)]    ; r1 += y1 * pn[-1+j+1]
      vpaddq   ymm1,  ymm1, ymm13
      vpmuludq ymm13, ymm9, ymmword ptr[rbx-sizeof(qword)+sizeof(ymmword)*2]  ; r2 += y1 * pn[-1+j+2]
      vpaddq   ymm2,  ymm2, ymm13
      vpmuludq ymm13, ymm9, ymmword ptr[rbx-sizeof(qword)+sizeof(ymmword)*3]  ; r3 += y1 * pn[-1+j+3]
      vpaddq   ymm3,  ymm3, ymm13

      vpmuludq ymm13, ymm10,ymmword ptr[rbx-sizeof(qword)*2]                  ; r0 += y2 * pn[-2+j]
      vpaddq   ymm0,  ymm0, ymm13
      vpmuludq ymm13, ymm10,ymmword ptr[rbx-sizeof(qword)*2+sizeof(ymmword)]  ; r1 += y2 * pn[-2+j+1]
      vpaddq   ymm1,  ymm1, ymm13
      vpmuludq ymm13, ymm10,ymmword ptr[rbx-sizeof(qword)*2+sizeof(ymmword)*2]; r2 += y2 * pn[-2+j+2]
      vpaddq   ymm2,  ymm2, ymm13
      vpmuludq ymm13, ymm10,ymmword ptr[rbx-sizeof(qword)*2+sizeof(ymmword)*3]; r3 += y2 * pn[-2+j+3]
      vpaddq   ymm3,  ymm3, ymm13

      vpmuludq ymm13, ymm11,ymmword ptr[rbx-sizeof(qword)*3]                  ; r0 += y3 * pn[-3+j]
      vpaddq   ymm0,  ymm0, ymm13
      vpmuludq ymm13, ymm11,ymmword ptr[rbx-sizeof(qword)*3+sizeof(ymmword)]  ; r1 += y3 * pn[-3+j+1]
      vpaddq   ymm1,  ymm1, ymm13
      vpmuludq ymm13, ymm11,ymmword ptr[rbx-sizeof(qword)*3+sizeof(ymmword)*2]; r2 += y3 * pn[-3+j+2]
      vpaddq   ymm2,  ymm2, ymm13
      vpmuludq ymm13, ymm11,ymmword ptr[rbx-sizeof(qword)*3+sizeof(ymmword)*3]; r3 += y3 * pn[-3+j+3]
      vpaddq   ymm3,  ymm3, ymm13

      vmovdqu  ymmword ptr[rsi], ymm0
      vmovdqu  ymmword ptr[rsi+sizeof(ymmword)], ymm1
      vmovdqu  ymmword ptr[rsi+sizeof(ymmword)*2], ymm2
      vmovdqu  ymmword ptr[rsi+sizeof(ymmword)*3], ymm3

      add      rsi, sizeof(ymmword)*4
      add      rbx, sizeof(ymmword)*4
      jmp      inner_reduction_loop16

exit_inner_reduction_loop16:
      add      r11, 4*(sizeof(ymmword)/sizeof(qword))
      jz       exit_inner_reduction

inner_reduction_loop4:
      sub      r11, sizeof(ymmword)/sizeof(qword)
      jl       exit_inner_reduction

      vmovdqu  ymm0, ymmword ptr[rsi]                          ; r0

      vpmuludq ymm13, ymm8, ymmword ptr[rbx]                   ; r0 += y0 * pn[j]
      vpaddq   ymm0,  ymm0, ymm13
      vpmuludq ymm13, ymm9, ymmword ptr[rbx-sizeof(qword)]     ; r0 += y1 * pn[-1+j]
      vpaddq   ymm0,  ymm0, ymm13
      vpmuludq ymm13, ymm10,ymmword ptr[rbx-sizeof(qword)*2]   ; r0 += y2 * pn[-2+j]
      vpaddq   ymm0,  ymm0, ymm13
      vpmuludq ymm13, ymm11,ymmword ptr[rbx-sizeof(qword)*3]   ; r0 += y3 * pn[-3+j]
      vpaddq   ymm0,  ymm0, ymm13

      vmovdqu  ymmword ptr[rsi], ymm0

      add      rsi, sizeof(ymmword)
      add      rbx, sizeof(ymmword)
      jmp      inner_reduction_loop4

exit_inner_reduction:
      mov      rax, qword ptr[rsp+flagl]
      cmp      rax, 2
      ja       _4n_3                   ; mLen = 4*n+3
      jz       _4n_2                   ; mLen = 4*n+2
      jp       next_reduction_loop4    ; mLen = 4*n+1
;;    jmp      _4n_0                   ; mLen = 4*n

;; mLen = 4*n
_4n_0:
      vpmuludq ymm0, ymm9, ymmword ptr[rbx-sizeof(qword)]   ; r0 += pa[j] + y1*pn[-1+j] + y2*pn[-2+j] + y3*pn[-3+j]
      vpmuludq ymm1, ymm10,ymmword ptr[rbx-sizeof(qword)*2]
      vpmuludq ymm2, ymm11,ymmword ptr[rbx-sizeof(qword)*3]
      vpaddq   ymm0,  ymm0, ymm1
      vpaddq   ymm0,  ymm0, ymm2
      vpaddq   ymm0, ymm0, ymmword ptr[rsi]
      vmovdqu  ymmword ptr[rsi], ymm0
      jmp      next_reduction_loop4

;; mLen = 4*n+2
_4n_2:
      vpmuludq ymm0,  ymm11,ymmword ptr[rbx-sizeof(qword)*3]   ; r0 += pa[j] + y3 * pn[-3+j]
      vpaddq   ymm0,  ymm0, ymmword ptr[rsi]
      vmovdqu  ymmword ptr[rsi], ymm0
      jmp      next_reduction_loop4

;; mLen = 48n+3
_4n_3:
      vpmuludq ymm0, ymm10,ymmword ptr[rbx-sizeof(qword)*2]    ; r0 += pa[j] + y2 * pn[-2+j] + y3 * pn[-3+j]
      vpmuludq ymm1, ymm11,ymmword ptr[rbx-sizeof(qword)*3]
      vpaddq   ymm0,  ymm0, ymm1
      vpaddq   ymm0, ymm0, ymmword ptr[rsi]
      vmovdqu  ymmword ptr[rsi], ymm0

next_reduction_loop4:
      mov      rsi, qword ptr[rsp+pProd]           ; advance pointer to product
      add      rsi, sizeof(ymmword)
      mov      qword ptr[rsp+pProd], rsi
      mov      rbx, qword ptr[rsp+pMod]            ; restore pointer to modulus

      sub      r9, sizeof(ymmword)/sizeof(qword)
      jg       outer_reduction_loop4

exit_outer_reduction_loop4:
;     add      r9, sizeof(ymmword)/sizeof(qword)
      cmp      r9, 2
      ja       last_3                  ; mLen = 4*n+3
      jz       last_2                  ; mLen = 4*n+2
      jp       last_1                  ; mLen = 4*n+1
      jmp      normalization           ; mLen = 4*n


;; process latest n[mLen-3], n[mLen-2], n[mLen-1]
last_3:
      mov      qword ptr[rsi+sizeof(qword)*3], r13 ; pr[3] = ac3

      add      rsi, sizeof(qword)*4
      add      rbx, sizeof(qword)*4

      mov      r11, qword ptr[rsp+len4]            ; init a_counter
      sub      r11, sizeof(ymmword)/sizeof(qword)
ALIGN IPP_ALIGN_FACTOR
rem_loop4_4n_3:
      vpmuludq ymm0, ymm8, ymmword ptr[rbx]                 ; r0 += pa[j] + y0*pn[j]
      vpmuludq ymm1, ymm9, ymmword ptr[rbx-sizeof(qword)]   ;             + y1*pn[-1+j]
      vpmuludq ymm2, ymm10,ymmword ptr[rbx-sizeof(qword)*2] ;             + y2*pn[-2+j]
      vpaddq   ymm0, ymm0, ymm1
      vpaddq   ymm0, ymm0, ymm2
      vpaddq   ymm0, ymm0, ymmword ptr[rsi]
      vmovdqu  ymmword ptr[rsi], ymm0

      add      rsi, sizeof(ymmword)
      add      rbx, sizeof(ymmword)
      sub      r11, sizeof(ymmword)/sizeof(qword)
      jg       rem_loop4_4n_3

      vpmuludq ymm2, ymm10,ymmword ptr[rbx-sizeof(qword)*2] ; r0 += pa[j+1] + y2*pn[-2+j]
      vpaddq   ymm2, ymm2, ymmword ptr[rsi]
      vmovdqu  ymmword ptr[rsi], ymm2
      jmp      normalization

;; process latest n[mLen-2], n[mLen-1]
last_2:
      mov      qword ptr[rsi+sizeof(qword)*2], r12   ; pr[2] = ac2
      mov      qword ptr[rsi+sizeof(qword)*3], r13   ; pr[3] = ac3

      add      rbx, sizeof(qword)*4
      add      rsi, sizeof(qword)*4

      mov      r11, qword ptr[rsp+len4]            ; init a_counter
      sub      r11, sizeof(ymmword)/sizeof(qword)

ALIGN IPP_ALIGN_FACTOR
rem_loop4_4n_2:
      vpmuludq ymm0, ymm8, ymmword ptr[rbx]                 ; r0 += pa[j] + y0 * pn[j]
      vpmuludq ymm1, ymm9, ymmword ptr[rbx-sizeof(qword)]   ;             + y1 * pn[-1+j]
      vpaddq   ymm0, ymm0, ymm1
      vpaddq   ymm0, ymm0, ymmword ptr[rsi]
      vmovdqu  ymmword ptr[rsi], ymm0

      add      rsi, sizeof(ymmword)
      add      rbx, sizeof(ymmword)
      sub      r11, sizeof(ymmword)/sizeof(qword)
      jg       rem_loop4_4n_2
      jmp      normalization

;; process latest n[mLen-1]
last_1:
      mov      qword ptr[rsi+sizeof(qword)], r11   ; pr[1] = ac1
      mov      qword ptr[rsi+sizeof(qword)*2], r12 ; pr[2] = ac2
      mov      qword ptr[rsi+sizeof(qword)*3], r13 ; pr[3] = ac3

      add      rbx, sizeof(qword)*4
      add      rsi, sizeof(qword)*4

      mov      r11, qword ptr[rsp+len4]            ; init a_counter
      sub      r11, sizeof(ymmword)/sizeof(qword)

ALIGN IPP_ALIGN_FACTOR
rem_loop4_4n_1:
      vpmuludq ymm0, ymm8, ymmword ptr[rbx]        ; r0 += pa[j] + y0 * pn[j]
      vpaddq   ymm0, ymm0, ymmword ptr[rsi]
      vmovdqu  ymmword ptr[rsi], ymm0

      add      rbx, sizeof(ymmword)
      add      rsi, sizeof(ymmword)
      sub      r11, sizeof(ymmword)/sizeof(qword)
      jg       rem_loop4_4n_1


;; normalize result
;;
ALIGN IPP_ALIGN_FACTOR
normalization:
      mov      rax, qword ptr[rsp+flagl]
      mov      rsi, qword ptr[rsp+pProd]
      mov      rdi, qword ptr[rsp+pRes]
      mov      r9,  qword ptr[rsp+mLen]
      lea      rsi, [rsi+rax*sizeof(qword)]
      xor      rax, rax
norm_loop:
      add      rax, qword ptr[rsi]
      add      rsi, sizeof(qword)
      mov      rdx, DIGIT_MASK
      and      rdx, rax
      shr      rax, DIGIT_BITS
      mov      qword ptr[rdi], rdx
      add      rdi, sizeof(qword)
      sub      r9, 1
      jg       norm_loop
      mov      qword ptr[rdi], rax

   REST_XMM_AVX
   REST_GPR
   ret
IPPASM cpMontRed_avx2 ENDP

ENDIF       ;  _IPP32E_L9
END
