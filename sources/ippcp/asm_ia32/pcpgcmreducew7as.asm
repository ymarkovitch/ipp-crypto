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
;               Reduction over AES-GCM polynomial (x^128 + x^7 + x^2 + x + 1)
; 
;     Content:
;        GCMreduce()
;

.686P
.387
.XMM
.MODEL FLAT,C

INCLUDE asmdefs.inc
INCLUDE ia_emm.inc

IF (_IPP GE _IPP_W7) AND (_IPP LT _IPP_V8)

IFDEF IPP_PIC
LD_ADDR MACRO reg:REQ, addr:REQ
LOCAL LABEL
        call     LABEL
LABEL:  pop      reg
        sub      reg, LABEL-addr
ENDM
ELSE
LD_ADDR MACRO reg:REQ, addr:REQ
        lea      reg, addr
ENDM
ENDIF


IPPCODE SEGMENT 'CODE' ALIGN (IPP_ALIGN_FACTOR)


ALIGN IPP_ALIGN_FACTOR
CONST_TABLE:
_maskW123 dd    000000000h,0FFFFFFFFh,0FFFFFFFFh,0FFFFFFFFh
_maskW0   dd    0FFFFFFFFh,000000000h,000000000h,000000000h
_maskW3   dd    000000000h,000000000h,000000000h,0FFFFFFFFh

maskW123 equ [edi+(_maskW123 - CONST_TABLE)]
maskW0   equ [edi+(_maskW0   - CONST_TABLE)]
maskW3   equ [edi+(_maskW3   - CONST_TABLE)]



;*************************************************************
;* vpod GCMreduce(const Ipp8u* pProduct, Ipp8u* pResult)
;*************************************************************
;;
;; Lib = W7
;;
;; Caller = ippsRijndael128GCMProcessIV
;; Caller = ippsRijndael128GCMProcessAAD
;; Caller = ippsRijndael128GCMEncrypt
;; Caller = ippsRijndael128GCMDecrypt
;; Caller = ippsRijndael128GCMGetTag
;;
ALIGN IPP_ALIGN_FACTOR
IPPASM GCMreduce PROC NEAR C PUBLIC \
      USES esi edi,\
      pSrc: PTR DWORD,\  ; product
      pDst: PTR DWORD   ; reduction

   mov      esi, pSrc
   movdqu   xmm3, oword ptr[esi]
   movdqu   xmm6, oword ptr[esi+16]

   LD_ADDR  edi, CONST_TABLE

   mov      esi, pDst

   ; we shift the result of the multiplication by one bit position to the left
   ; cope for the fact that bits are reversed
   movdqu   xmm4, xmm3
   movdqu   xmm5, xmm6
   pslld    xmm3, 1
   pslld    xmm6, 1
   psrld    xmm4, 31
   psrld    xmm5, 31
   pshufd   xmm4, xmm4, 10010011b   ; ==147
   pshufd   xmm5, xmm5, 10010011b   ; ==147
   movdqu   xmm7,  xmm4
   pand     xmm4, oword ptr maskW123    ;xmm13 holds the mask 0xffffffffffffffffffffffff00000000
   pand     xmm5, oword ptr maskW123
   pand     xmm7, oword ptr maskW0      ;xmm12 holds the mask 0x000000000000000000000000ffffffff
   por      xmm3, xmm4
   por      xmm6, xmm5
   por      xmm6, xmm7

   ;first phase of the reduction
   movdqu   xmm0, xmm3
   movdqu   xmm1, xmm3
   movdqu   xmm2, xmm3     ;move xmm3 into xmm7, xmm8, xmm9 in order to perform the three shifts independently
   pslld    xmm0, 31       ; packed right shifting << 31
   pslld    xmm1, 30       ; packed right shifting shift << 30
   pslld    xmm2, 25       ; packed right shifting shift << 25
   pxor     xmm0, xmm1     ;xor the shifted versions
   pxor     xmm0, xmm2
   pshufd   xmm1, xmm0, 57   ;move the least significant 32-bit word to
                             ; the most significant word position
                             ; and right shift all other three 32-bit words by 32 bits
   movdqu   xmm0, xmm1
   pand     xmm0, oword ptr maskW3 ;xmm11 holds the mask 0xffffffff000000000000000000000000
   pxor     xmm3, xmm0             ;first phase of the reduction complete

   ;second phase of the reduction
   movdqu   xmm2,xmm3    ; make 3 copies of xmm3 (in in xmm2, xmm4, xmm5) for doing three shift operations
   movdqu   xmm4,xmm3
   movdqu   xmm5,xmm3
   psrld    xmm2,1       ; packed left shifting >> 1
   psrld    xmm4,2       ; packed left shifting >> 2
   psrld    xmm5,7       ; packed left shifting >> 7
   pxor     xmm2,xmm4    ; xor the shifted versions
   pxor     xmm2,xmm5
   movdqu   xmm5, oword ptr maskW3 ; xmm11
   pandn    xmm5, xmm1    ; see step1
   pxor     xmm2,xmm5
   pxor     xmm3, xmm2
   pxor     xmm6, xmm3    ;the result is in xmm6

   movdqu   oword ptr[esi], xmm6
   ret
IPPASM GCMreduce endp

ENDIF
END
