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
;        cpMulAdc_BNU_school()
; 
;

include asmdefs.inc
include ia_32e.inc
include pcpbnumulschool.inc
include pcpvariant.inc

IF (_ADCOX_NI_ENABLING_ EQ _FEATURE_OFF_) OR (_ADCOX_NI_ENABLING_ EQ _FEATURE_TICKTOCK_)
IF (_IPP32E GE _IPP32E_M7) AND (_IPP32E LT _IPP32E_L9)


IPPCODE SEGMENT 'CODE' ALIGN (IPP_ALIGN_FACTOR)


;*************************************************************
;* Ipp64u  cpMulAdc_BNU_school(Ipp64u* pR;
;*                       const Ipp64u* pA, int  aSize,
;*                       const Ipp64u* pB, int  bSize)
;* returns pR[aSize+bSize]
;*
;*************************************************************
ALIGN IPP_ALIGN_FACTOR
IPPASM cpMulAdc_BNU_school PROC PUBLIC FRAME
   USES_GPR rbx,rbp,rsi,rdi,r12,r13,r14,r15
   LOCAL_FRAME = (1*sizeof(qword))
   USES_XMM
   COMP_ABI 5

; rdi = pDst
; rsi = pSrcA
; edx = lenA
; rcx = pSrcB
; r8d = lenB

;;
;; stack structure:
;;counterB = (0)
;;counterA = (counterB+sizeof(qword))
counterA = (0)


   cmp      edx, r8d
   jl       general_case_mul_entry
   jg       general_case_mul
IF (_IPP32E LT _IPP32E_E9)
   cmp      edx, 4
ELSE
   cmp      edx, 8
ENDIF
   jg       general_case_mul

IF (_IPP32E GE _IPP32E_E9)
   cmp     edx, 4
   jg      more_then_4
ENDIF

   cmp      edx, 3
   ja       mul_4x4
   jz       mul_3x3
   jp       mul_2x2
  ;         mul_1x1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; fixed-size multipliers (1-4)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ALIGN IPP_ALIGN_FACTOR
mul_1x1:
   mov      rax, qword ptr [rsi]
   mul      qword ptr [rcx]
   mov      qword ptr [rdi], rax
   mov      qword ptr [rdi+sizeof(qword)], rdx
   mov      rax, qword ptr [rdi+sizeof(qword)*1]
   REST_XMM
   REST_GPR
   ret

  ALIGN IPP_ALIGN_FACTOR
mul_2x2:
   mov      r8, [rcx]
   mov      r9, [rcx+sizeof(qword)*1]
   MUL_NxN  2, rdi, rsi, rcx, rbx, rbp, r15, r14, r13, r12, r11, r10, r9, r8
   mov      rax, qword ptr [rdi+sizeof(qword)*3]
   REST_XMM
   REST_GPR
   ret

  ALIGN IPP_ALIGN_FACTOR
mul_3x3:
   mov      r8, [rcx]
   mov      r9, [rcx+sizeof(qword)*1]
   mov      r10,[rcx+sizeof(qword)*2]
   MUL_NxN  3, rdi, rsi, rcx, rbx, rbp, r15, r14, r13, r12, r11, r10, r9, r8
   mov      rax, qword ptr [rdi+sizeof(qword)*5]
   REST_XMM
   REST_GPR
   ret

  ALIGN IPP_ALIGN_FACTOR
mul_4x4:
   mov      r8, [rcx]
   mov      r9, [rcx+sizeof(qword)*1]
   mov      r10,[rcx+sizeof(qword)*2]
   mov      r11,[rcx+sizeof(qword)*3]
   MUL_NxN  4, rdi, rsi, rcx, rbx, rbp, r15, r14, r13, r12, r11, r10, r9, r8
   mov      rax, qword ptr [rdi+sizeof(qword)*7]
   REST_XMM
   REST_GPR
   ret


IF (_IPP32E GE _IPP32E_E9)
more_then_4:
   cmp      edx, 7
   ja       mul_8x8
   jz       mul_7x7
   jp       mul_6x6
  ;         mul_5x5

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; fixed-size multipliers (5-8)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ALIGN IPP_ALIGN_FACTOR
mul_5x5:
   mov      r8, [rcx]
   mov      r9, [rcx+sizeof(qword)*1]
   mov      r10,[rcx+sizeof(qword)*2]
   mov      r11,[rcx+sizeof(qword)*3]
   mov      r12,[rcx+sizeof(qword)*4]
   MUL_NxN  5, rdi, rsi, rcx, rbx, rbp, r15, r14, r13, r12, r11, r10, r9, r8
   mov      rax, qword ptr [rdi+sizeof(qword)*9]
   REST_XMM
   REST_GPR
   ret

  ALIGN IPP_ALIGN_FACTOR
mul_6x6:
   mov      r8, [rcx]
   mov      r9, [rcx+sizeof(qword)*1]
   mov      r10,[rcx+sizeof(qword)*2]
   mov      r11,[rcx+sizeof(qword)*3]
   mov      r12,[rcx+sizeof(qword)*4]
   mov      r13,[rcx+sizeof(qword)*5]
   MUL_NxN  6, rdi, rsi, rcx, rbx, rbp, r15, r14, r13, r12, r11, r10, r9, r8
   mov      rax, qword ptr [rdi+sizeof(qword)*11]
   REST_XMM
   REST_GPR
   ret

  ALIGN IPP_ALIGN_FACTOR
mul_7x7:
   mov      r8, [rcx]
   mov      r9, [rcx+sizeof(qword)*1]
   mov      r10,[rcx+sizeof(qword)*2]
   mov      r11,[rcx+sizeof(qword)*3]
   mov      r12,[rcx+sizeof(qword)*4]
   mov      r13,[rcx+sizeof(qword)*5]
   mov      r14,[rcx+sizeof(qword)*6]
   MUL_NxN  7, rdi, rsi, rcx, rbx, rbp, r15, r14, r13, r12, r11, r10, r9, r8
   mov      rax, qword ptr [rdi+sizeof(qword)*13]
   REST_XMM
   REST_GPR
   ret

  ALIGN IPP_ALIGN_FACTOR
mul_8x8:
   mov      r8, [rcx]
   mov      r9, [rcx+sizeof(qword)*1]
   mov      r10,[rcx+sizeof(qword)*2]
   mov      r11,[rcx+sizeof(qword)*3]
   mov      r12,[rcx+sizeof(qword)*4]
   mov      r13,[rcx+sizeof(qword)*5]
   mov      r14,[rcx+sizeof(qword)*6]
   mov      r15,[rcx+sizeof(qword)*7]
   MUL_NxN  8, rdi, rsi, rcx, rbx, rbp, r15, r14, r13, r12, r11, r10, r9, r8
   mov      rax, qword ptr [rdi+sizeof(qword)*15]
   REST_XMM
   REST_GPR
   ret
ENDIF


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; general case multiplier
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ALIGN IPP_ALIGN_FACTOR
general_case_mul_entry:
   ; swap operands if lenA < lenB then exchange operands
   xor      rsi, rcx
   xor      edx, r8d
   xor      rcx, rsi
   xor      r8d, edx
   xor      rsi, rcx
   xor      edx, r8d

B0 equ   r10   ; b[i], b[i+1]
B1 equ   r11

T0 equ   r12   ; temporary
T1 equ   r13
T2 equ   r14
T3 equ   r15

idx equ  rbx   ; index
rDst equ rdi
rSrc equ rsi

  ALIGN IPP_ALIGN_FACTOR
general_case_mul:
   movsxd   rdx, edx    ; expand length
   movsxd   r8,  r8d

   lea      rdi, [rdi+rdx*sizeof(qword)-sizeof(qword)*4] ; rdi = &R[lenA-4]
   lea      rsi, [rsi+rdx*sizeof(qword)-sizeof(qword)*4] ; rsi = &A[lenA-4]

   mov      idx, 4                        ; negative
   sub      idx, rdx                      ; A-counter
   mov      qword ptr [rsp+counterA], idx

   mov      rax, qword ptr [rsi+idx*sizeof(qword)] ; a[0]
   mov      B0, qword ptr [rcx]                    ; b[0]
   test     r8, 1
   jz       init_even_B

;********** lenSrcB = 2*n+ 1 (multiply only) *********************
init_odd_B:
   xor      T0, T0
   cmp      idx, 0
   jge      skip_mul1

   MULx1    rdi, rsi, idx, B0, T0, T1, T2, T3

skip_mul1:
   cmp      idx, 2
   ja       fin_mul1x4n_1   ; idx=3
   jz       fin_mul1x4n_2   ; idx=2
   jp       fin_mul1x4n_3   ; idx=1
   ;        fin_mul1x4n_4   ; idx=0

fin_mul1x4n_4:
   MULx1_4N_4_ELOG rdi, rsi, B0, T0,T1,T2,T3
   add      rcx, sizeof(qword)
   add      r8, 1
   jmp      mla2x4n_4
fin_mul1x4n_3:
   MULx1_4N_3_ELOG rdi, rsi, B0, T0,T1,T2,T3
   add      rcx, sizeof(qword)
   add      r8, 1
   jmp      mla2x4n_3
fin_mul1x4n_2:
   MULx1_4N_2_ELOG rdi, rsi, B0, T0,T1,T2,T3
   add      rcx, sizeof(qword)
   add      r8, 1
   jmp      mla2x4n_2
fin_mul1x4n_1:
   MULx1_4N_1_ELOG rdi, rsi, B0, T0,T1,T2,T3
   add      rcx, sizeof(qword)
   add      r8, 1
   jmp      mla2x4n_1


;********** lenSrcB = 2*n (multiply only) ************************
init_even_B:
   mov      rbp, rax
   mul      B0                                  ; {T2:T1:T0} = a[0]*B0
   mov      B1, qword ptr [rcx+sizeof(qword)]
   xor      T2, T2
   mov      T0, rax
   mov      rax, rbp                            ; restore a[0]
   mov      T1, rdx

   cmp      idx, 0
   jge      skip_mul_nx2

   MULx2    rdi, rsi, idx, B0,B1, T0,T1,T2,T3

skip_mul_nx2:
   cmp      idx, 2
   ja       fin_mul2x4n_1   ; idx=3
   jz       fin_mul2x4n_2   ; idx=2
   jp       fin_mul2x4n_3   ; idx=1
   ;        fin_mul2x4n_4   ; idx=0

fin_mul2x4n_4:
   MULx2_4N_4_ELOG rdi, rsi, B0,B1, T0,T1,T2,T3
   add      rcx, sizeof(qword)*2
  ALIGN IPP_ALIGN_FACTOR
mla2x4n_4:
   sub      r8, 2
   jz       quit
   MLAx2_PLOG  B0,B1, rcx, T0,T1,T2,T3
   cmp      idx, 0
   jz       skip_mla_x2
   MLAx2    rdi, rsi, idx, B0,B1, T0,T1,T2,T3
skip_mla_x2:
   MLAx2_4N_4_ELOG rdi, rsi, B0,B1, T0,T1,T2,T3
   add      rcx, sizeof(qword)*2
   jmp      mla2x4n_4

fin_mul2x4n_3:
   MULx2_4N_3_ELOG rdi, rsi, B0,B1, T0,T1,T2,T3
   add      rcx, sizeof(qword)*2
  ALIGN IPP_ALIGN_FACTOR
mla2x4n_3:
   sub      r8, 2
   jz       quit
   MLAx2_PLOG  B0,B1, rcx, T0,T1,T2,T3
   MLAx2    rdi, rsi, idx, B0,B1, T0,T1,T2,T3
   MLAx2_4N_3_ELOG rdi, rsi, B0,B1, T0,T1,T2,T3
   add      rcx, sizeof(qword)*2
   jmp      mla2x4n_3

fin_mul2x4n_2:
   MULx2_4N_2_ELOG rdi, rsi, B0,B1, T0,T1,T2,T3
   add      rcx, sizeof(qword)*2
  ALIGN IPP_ALIGN_FACTOR
mla2x4n_2:
   sub      r8, 2
   jz       quit
   MLAx2_PLOG  B0,B1, rcx, T0,T1,T2,T3
   MLAx2    rdi, rsi, idx, B0,B1, T0,T1,T2,T3
   MLAx2_4N_2_ELOG rdi, rsi, B0,B1, T0,T1,T2,T3
   add      rcx, sizeof(qword)*2
   jmp      mla2x4n_2

fin_mul2x4n_1:
   MULx2_4N_1_ELOG rdi, rsi, B0,B1, T0,T1,T2,T3
   add      rcx, sizeof(qword)*2
  ALIGN IPP_ALIGN_FACTOR
mla2x4n_1:
   sub      r8, 2
   jz       quit
   MLAx2_PLOG  B0,B1, rcx, T0,T1,T2,T3
   MLAx2    rdi, rsi, idx, B0,B1, T0,T1,T2,T3
   MLAx2_4N_1_ELOG rdi, rsi, B0,B1, T0,T1,T2,T3
   add      rcx, sizeof(qword)*2
   jmp      mla2x4n_1

quit:
   mov   rax, rdx

   REST_XMM
   REST_GPR
   ret
IPPASM cpMulAdc_BNU_school ENDP

ENDIF

ENDIF ;; _ADCOX_NI_ENABLING_
END
