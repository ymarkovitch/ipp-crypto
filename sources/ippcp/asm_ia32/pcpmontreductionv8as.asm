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
;     Purpose:  Cryptography Primitive.
;               Big Number Arithmetic (Montgomery Reduction)
;
;     Content:
;        cpMontRedAdc_BNU()
;
;     History:
;      This implementation used instead of previous one
;      (see pcpmontredictw7as.asm)
;
;      Extra reduction (R=A-M) has been added to perform MontReduction safe
;
.686P
.387
.XMM
.MODEL FLAT,C

INCLUDE asmdefs.inc
INCLUDE ia_emm.inc

IF _IPP GE _IPP_V8
INCLUDE pcpvariant.inc
INCLUDE pcpbnu.inc

IF _USE_NN_MONTMUL_ EQ _NUSE


MULADD_wt_carry MACRO i
   movd     xmm7,DWORD PTR[eax]           ;; pM[0]
   pmuludq  xmm7,xmm0                     ;; t = pM[0] * u
   movd     xmm2,DWORD PTR[edx+4*(i)]     ;; pBuffer[i]
   paddq    xmm7,xmm2                     ;; t += pBuffer[i]
   movd     DWORD PTR[edx+4*(i)],xmm7     ;; pBuffer[i] = LO(t)
   psrlq    xmm7,32                       ;; carryLcl = HI(t)
ENDM

MULADD1 MACRO i,j,nsize
   movd     xmm1,DWORD PTR[eax+4*j]       ;; pM[j]
   pmuludq  xmm1,xmm0                     ;; t = pM[j] * u
   movd     xmm2,DWORD PTR[edx+4*(i+j)]   ;; pBuffer[i+j]
   paddq    xmm1,xmm2                     ;; t +=pBuffer[i+j]
   paddq    xmm7,xmm1                     ;;    +carryLcl
   movd     DWORD PTR[edx+4*(i+j)],xmm7   ;; pBuffer[i+j] = LO(t)
   psrlq    xmm7,32                       ;; carryLcl = HI(t)
ENDM

INNER_LOOP1 MACRO i, size
   j = 0
   movd     xmm0,DWORD PTR[edx+4*i]          ;; pBuffer[i]

   pmuludq  xmm0,xmm5                        ;; u = (Ipp32u)( m0*pBuffer[i] )
   movd     xmm4,DWORD PTR[edx+4*(i+size)]   ;; w = pBuffer[i+mSize]
   paddq    xmm4,xmm6                        ;;    +carryGbl

   repeat size
      if j eq 0
         MULADD_wt_carry i
      else
         MULADD1 i,j,size
      endif
      j = j + 1
   endm

   paddq    xmm7,xmm4                        ;; w+= carryLcl

   movd     DWORD PTR[edx+4*(i+size)],xmm7   ;; pBuffer[i+mSize] = LO(w)
;  pshufw   xmm6,xmm7,11111110b              ;; carryGbl = HI(w)
   pshuflw  xmm6,xmm7,11111110b              ;; carryGbl = HI(w)
ENDM

OUTER_LOOP1 MACRO nsize
   movd     xmm5,DWORD PTR m0 ; m0
   pandn    xmm6,xmm6         ; init carryGbl = 0

   i = 0
   repeat nsize
      INNER_LOOP1 i,nsize
      i = i + 1
   endm

   psrlq    xmm7,32
ENDM



UNROLL8 MACRO
   movd     xmm1,DWORD PTR[eax+ecx]
   movd     xmm2,DWORD PTR[edx+ecx]
   movd     xmm3,DWORD PTR[eax+ecx+4]
   movd     xmm4,DWORD PTR[edx+ecx+4]
   movd     xmm5,DWORD PTR[eax+ecx+8]
   movd     xmm6,DWORD PTR[edx+ecx+8]

   pmuludq  xmm1,xmm0
   paddq    xmm1,xmm2
   pmuludq  xmm3,xmm0
   paddq    xmm3,xmm4
   pmuludq  xmm5,xmm0
   paddq    xmm5,xmm6

   paddq    xmm7,xmm1
   movd     xmm1,DWORD PTR[eax+ecx+12]
   movd     xmm2,DWORD PTR[edx+ecx+12]
   movd     DWORD PTR[edx+ecx],xmm7
   psrlq    xmm7,32

   pmuludq  xmm1,xmm0
   paddq    xmm1,xmm2

   paddq    xmm7,xmm3
   movd     xmm3,DWORD PTR[eax+ecx+16]
   movd     xmm4,DWORD PTR[edx+ecx+16]
   movd     DWORD PTR[edx+ecx+4],xmm7
   psrlq    xmm7,32

   pmuludq xmm3,xmm0
   paddq   xmm3,xmm4

   paddq    xmm7,xmm5
   movd     xmm5,DWORD PTR[eax+ecx+20]
   movd     xmm6,DWORD PTR[edx+ecx+20]
   movd     DWORD PTR[edx+ecx+8],xmm7
   psrlq    xmm7,32

   pmuludq  xmm5,xmm0
   paddq    xmm5,xmm6

   paddq    xmm7,xmm1
   movd     xmm1,DWORD PTR[eax+ecx+24]
   movd     xmm2,DWORD PTR[edx+ecx+24]
   movd     DWORD PTR[edx+ecx+12],xmm7
   psrlq    xmm7,32

   pmuludq  xmm1,xmm0
   paddq    xmm1,xmm2

   paddq    xmm7,xmm3
   movd     xmm3,DWORD PTR[eax+ecx+28]
   movd     xmm4,DWORD PTR[edx+ecx+28]
   movd     DWORD PTR[edx+ecx+16],xmm7
   psrlq    xmm7,32

   pmuludq  xmm3,xmm0
   paddq    xmm3,xmm4

   paddq    xmm7,xmm5
   movd     DWORD PTR[edx+ecx+20],xmm7
   psrlq    xmm7,32

   paddq    xmm7,xmm1
   movd     DWORD PTR[edx+ecx+24],xmm7
   psrlq    xmm7,32

   paddq    xmm7,xmm3
   movd     DWORD PTR[edx+ecx+28],xmm7
   psrlq    xmm7,32
ENDM

UNROLL16 MACRO
   movd     xmm1,DWORD PTR[eax+ecx]
   movd     xmm2,DWORD PTR[edx+ecx]
   movd     xmm3,DWORD PTR[eax+ecx+4]
   movd     xmm4,DWORD PTR[edx+ecx+4]
   movd     xmm5,DWORD PTR[eax+ecx+8]
   movd     xmm6,DWORD PTR[edx+ecx+8]

   pmuludq  xmm1,xmm0
   paddq    xmm1,xmm2
   pmuludq  xmm3,xmm0
   paddq    xmm3,xmm4
   pmuludq  xmm5,xmm0
   paddq    xmm5,xmm6

   paddq    xmm7,xmm1
   movd     xmm1,DWORD PTR[eax+ecx+12]
   movd     xmm2,DWORD PTR[edx+ecx+12]
   movd     DWORD PTR[edx+ecx],xmm7
   psrlq    xmm7,32

   pmuludq  xmm1,xmm0
   paddq    xmm1,xmm2

   paddq    xmm7,xmm3
   movd     xmm3,DWORD PTR[eax+ecx+16]
   movd     xmm4,DWORD PTR[edx+ecx+16]
   movd     DWORD PTR[edx+ecx+4],xmm7
   psrlq    xmm7,32

   pmuludq  xmm3,xmm0
   paddq    xmm3,xmm4

   paddq    xmm7,xmm5
   movd     xmm5,DWORD PTR[eax+ecx+20]
   movd     xmm6,DWORD PTR[edx+ecx+20]
   movd     DWORD PTR[edx+ecx+8],xmm7
   psrlq    xmm7,32

   pmuludq  xmm5,xmm0
   paddq    xmm5,xmm6

   paddq    xmm7,xmm1
   movd     xmm1,DWORD PTR[eax+ecx+24]
   movd     xmm2,DWORD PTR[edx+ecx+24]
   movd     DWORD PTR[edx+ecx+12],xmm7
   psrlq    xmm7,32

   pmuludq  xmm1,xmm0
   paddq    xmm1,xmm2

   paddq    xmm7,xmm3
   movd     xmm3,DWORD PTR[eax+ecx+28]
   movd     xmm4,DWORD PTR[edx+ecx+28]
   movd     DWORD PTR[edx+ecx+16],xmm7
   psrlq    xmm7,32

   pmuludq  xmm3,xmm0
   paddq    xmm3,xmm4

   paddq    xmm7,xmm5
   movd     xmm5,DWORD PTR[eax+ecx+32]
   movd     xmm6,DWORD PTR[edx+ecx+32]
   movd     DWORD PTR[edx+ecx+20],xmm7
   psrlq    xmm7,32

   pmuludq  xmm5,xmm0
   paddq    xmm5,xmm6

   paddq    xmm7,xmm1
   movd     xmm1,DWORD PTR[eax+ecx+36]
   movd     xmm2,DWORD PTR[edx+ecx+36]
   movd     DWORD PTR[edx+ecx+24],xmm7
   psrlq    xmm7,32

   pmuludq  xmm1,xmm0
   paddq    xmm1,xmm2

   paddq    xmm7,xmm3
   movd     xmm3,DWORD PTR[eax+ecx+40]
   movd     xmm4,DWORD PTR[edx+ecx+40]
   movd     DWORD PTR[edx+ecx+28],xmm7
   psrlq    xmm7,32

   pmuludq  xmm3,xmm0
   paddq    xmm3,xmm4

   paddq    xmm7,xmm5
   movd     xmm5,DWORD PTR[eax+ecx+44]
   movd     xmm6,DWORD PTR[edx+ecx+44]
   movd     DWORD PTR[edx+ecx+32],xmm7
   psrlq    xmm7,32

   pmuludq  xmm5,xmm0
   paddq    xmm5,xmm6

   paddq    xmm7,xmm1
   movd     xmm1,DWORD PTR[eax+ecx+48]
   movd     xmm2,DWORD PTR[edx+ecx+48]
   movd     DWORD PTR[edx+ecx+36],xmm7
   psrlq    xmm7,32

   pmuludq  xmm1,xmm0
   paddq    xmm1,xmm2

   paddq    xmm7,xmm3
   movd     xmm3,DWORD PTR[eax+ecx+52]
   movd     xmm4,DWORD PTR[edx+ecx+52]
   movd     DWORD PTR[edx+ecx+40],xmm7
   psrlq    xmm7,32

   pmuludq  xmm3,xmm0
   paddq    xmm3,xmm4

   paddq    xmm7,xmm5
   movd     xmm5,DWORD PTR[eax+ecx+56]
   movd     xmm6,DWORD PTR[edx+ecx+56]
   movd     DWORD PTR[edx+ecx+44],xmm7
   psrlq    xmm7,32

   pmuludq  xmm5,xmm0
   paddq    xmm5,xmm6

   paddq    xmm7,xmm1
   movd     xmm1,DWORD PTR[eax+ecx+60]
   movd     xmm2,DWORD PTR[edx+ecx+60]
   movd     DWORD PTR[edx+ecx+48],xmm7
   psrlq    xmm7,32

   pmuludq  xmm1,xmm0
   paddq    xmm1,xmm2

   paddq    xmm7,xmm3
   movd     DWORD PTR[edx+ecx+52],xmm7
   psrlq    xmm7,32

   paddq    xmm7,xmm5
   movd     DWORD PTR[edx+ecx+56],xmm7
   psrlq    xmm7,32

   paddq    xmm7,xmm1
   movd     DWORD PTR[edx+ecx+60],xmm7
   psrlq    xmm7,32
ENDM


IPPCODE SEGMENT 'CODE' ALIGN (IPP_ALIGN_FACTOR)

IF(_USE_C_cpMontRedAdc_BNU_ EQ 0)
;*************************************************************
;* void cpMontRedAdc_BNU(Ipp32u* pR,
;*                       Ipp32u* pBuffer,
;*                 const Ipp32u* pModulo, int mSize, Ipp32u m0)
;*
;*************************************************************

;;
;; Lib = V8
;;
;; Caller = ippsMontMul
;;
IPPASM cpMontRedAdc_BNU PROC NEAR C PUBLIC \
      USES esi edi ebx,\
      pR:       PTR DWORD,\    ; pointer to the reduction
      pBuffer:  PTR DWORD,\    ; pointer to the product
      pModulo:  PTR DWORD,\    ; pointer to the modulo
      mSize:        DWORD,\    ; modulo size
      m0:           DWORD     ; helper

   mov      eax,pModulo       ; modulo address
   mov      edi,mSize         ; modulo size
   mov      edx,pBuffer       ; temp product address

;
; spesial cases
;
tst_reduct4:
   cmp      edi,4             ; special case
   jne      tst_reduct5
   OUTER_LOOP1 4
   add      edx,4*4
   jmp      finish

tst_reduct5:
   cmp      edi,5             ; special case
   jne      tst_reduct6
   OUTER_LOOP1 5
   add      edx,4*5
   jmp      finish

tst_reduct6:
   cmp      edi,6             ; special case
   jne      tst_reduct7
   OUTER_LOOP1 6
   add      edx,4*6
   jmp      finish

tst_reduct7:
   cmp      edi,7             ; special case
   jne      tst_reduct8
   OUTER_LOOP1 7
   add      edx,4*7
   jmp      finish

tst_reduct8:
   cmp      edi,8             ; special case
   jne      tst_reduct9
   OUTER_LOOP1 8
   add      edx,4*8
   jmp      finish

tst_reduct9:
   cmp      edi,9             ; special case
   jne      tst_reduct10
   OUTER_LOOP1 9
   add      edx,4*9
   jmp      finish

tst_reduct10:
   cmp      edi,10            ; special case
   jne      tst_reduct11
   OUTER_LOOP1 10
   add      edx,4*10
   jmp      finish

tst_reduct11:
   cmp      edi,11            ; special case
   jne      tst_reduct12
   OUTER_LOOP1 11
   add      edx,4*11
   jmp      finish

tst_reduct12:
   cmp      edi,12            ; special case
   jne      tst_reduct13
   OUTER_LOOP1 12
   add      edx,4*12
   jmp      finish

tst_reduct13:
   cmp      edi,13            ; special case
   jne      tst_reduct14
   OUTER_LOOP1 13
   add      edx,4*13
   jmp      finish

tst_reduct14:
   cmp      edi,14            ; special case
   jne      tst_reduct15
   OUTER_LOOP1 14
   add      edx,4*14
   jmp      finish

tst_reduct15:
   cmp      edi,15            ; special case
   jne      tst_reduct16
   OUTER_LOOP1 15
   add      edx,4*15
   jmp      finish

tst_reduct16:
   cmp      edi,16            ; special case
   jne      reduct_general
   OUTER_LOOP1 16
   add      edx,4*16
   jmp      finish

;
; general case
;
reduct_general:
   sub      esp,4             ; allocate slot for carryGbl

   pandn    xmm6,xmm6         ; init carryGbl = 0

   mov      ebx,edi
   shl      ebx,2             ; modulo size in bytes (outer counter)
   shl      edi,2

mainLoop:
   movd     xmm0,DWORD PTR m0       ; m0 helper
   movd     xmm1,DWORD PTR[edx]     ; pBuffer[i]
   movd     DWORD PTR[esp],xmm6     ; save carryGbl

   pmuludq  xmm0,xmm1               ; u = (Ipp32u)( m0*pBuffer[i] )

   xor      ecx,ecx                 ; inner index
   pandn    xmm7,xmm7               ; int carryLcl = 0

;
; case: 0 != mSize%8
;
   mov      esi,edi                 ; copy modulo size copy
   and      esi,7*4                 ; and test (inner counter)
   jz       testSize_8

small_loop:
   movd     xmm1,DWORD PTR[eax+ecx] ; pModulo[]
   pmuludq  xmm1,xmm0               ; t = pModulo[]*u
   movd     xmm2,DWORD PTR[edx+ecx] ; pBuffer[]
   paddq    xmm1,xmm2               ; t +=pBuffer[]
   paddq    xmm7,xmm1               ;    +carryLcl
   movd     DWORD PTR[edx+ecx],xmm7 ; pBuffer[] = LO(t)
   psrlq    xmm7,32                 ; carryLcl  = HI(t)

   add      ecx,4
   cmp      ecx,esi
   jl       small_loop

;
; case: mSize==8
;
testSize_8:
   mov      esi,edi                 ; copy modulo size copy
   and      esi,8*4                 ; and test
   jz       testSize_16

   UNROLL8
   add      ecx,8*4

;
; case: mSize==16*n
;
testSize_16:
   mov      esi,edi                 ; copy modulo size copy
   and      esi,0FFFFFFC0h          ; and test
   jz       next_term

unroll16_loop:
   UNROLL16
   add      ecx,16*4
   cmp      ecx,esi
   jl       unroll16_loop

next_term:
   movd     xmm1,DWORD PTR[edx+ecx] ; pBuffer[]
   paddq    xmm7,xmm1               ; t = pBuffer[]+carryLcl
   movd     xmm6,DWORD PTR[esp]     ; carryGbl
   paddq    xmm6,xmm7               ; t +=carryGbl
   movd     DWORD PTR[edx+ecx],xmm6 ; pBuffer[] = LO(t)
   psrlq    xmm6,32                 ; carryGbl  = HI(t)

   add      edx,4                   ; advance pBuffer
   sub      ebx,4                   ; decrease outer counter
   jg       mainLoop

   add      esp,4                   ; release slot for carryGbl
   shr      edi,2                   ; restore mSize


;;
;; finish
;;
finish:
   pxor     xmm7,xmm7               ; converr carryGbl into the mask
   psubd    xmm7,xmm6

   mov      esi,pR                  ; pointer to the result
   pandn    xmm0,xmm0               ; borrow=0
   xor      ecx,ecx                 ; index =0
   ; perform pR[] = pBuffer[] - pModulus[]
subtract_loop:
   movd     xmm1,DWORD PTR[edx+ecx*4]; pBuffer[]
   paddq    xmm0,xmm1
   movd     xmm2,DWORD PTR[eax+ecx*4]; pModulus[]
   psubq    xmm0,xmm2
   movd     DWORD PTR[esi+ecx*4],xmm0
   pshuflw  xmm0,xmm0,11111110b

   add      ecx,1
   cmp      ecx,edi
   jl       subtract_loop

   pcmpeqd  xmm6,xmm6               ; convert borrow into the mask
   pxor     xmm0,xmm6
   por      xmm0,xmm7               ; common (carryGbl and borrow) mask

   pcmpeqd  xmm7,xmm7               ; mask and
   pxor     xmm7,xmm0               ; ~mask

   xor      ecx,ecx                 ; index =0
   ; masked copy: pR[] = (mask & pR[]) | (~mask & pBuffer[])
masked_copy_loop:
   movd     xmm1,DWORD PTR[esi+ecx*4]; pR[]
   pand     xmm1,xmm0
   movd     xmm2,DWORD PTR[edx+ecx*4]; pBuffer[]
   pand     xmm2,xmm7
   por      xmm1,xmm2
   movd     DWORD PTR[esi+ecx*4],xmm1; pR[]

   add      ecx,1
   cmp      ecx,edi
   jl       masked_copy_loop
   ret
IPPASM cpMontRedAdc_BNU ENDP
ENDIF

ENDIF ;; _IPP_V8
ENDIF ;; _USE_NN_MONTMUL_
END
