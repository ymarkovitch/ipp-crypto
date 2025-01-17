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
;               Rijndael Inverse Cipher function
; 
;     Content:
;        Decrypt_RIJ128_AES_NI()
; 
;
include asmdefs.inc
include ia_32e.inc
include pcpvariant.inc

IF (_AES_NI_ENABLING_ EQ _FEATURE_ON_) OR (_AES_NI_ENABLING_ EQ _FEATURE_TICKTOCK_)
IF (_IPP32E GE _IPP32E_Y8)


IPPCODE SEGMENT 'CODE' ALIGN (IPP_ALIGN_FACTOR)


;***************************************************************
;* Purpose:    single block RIJ128 Inverse Cipher
;*
;* void Decrypt_RIJ128_AES_NI(const Ipp32u* inpBlk,
;*                                  Ipp32u* outBlk,
;*                                  int nr,
;*                            const Ipp32u* pRKey,
;*                            const Ipp32u Tables[][256])
;***************************************************************

;;
;; Lib = Y8
;;
;; Caller = ippsRijndael128DecryptECB
;; Caller = ippsRijndael128DecryptCBC
;;
ALIGN IPP_ALIGN_FACTOR
IPPASM Decrypt_RIJ128_AES_NI PROC PUBLIC FRAME
      USES_GPR rsi, rdi
      LOCAL_FRAME = 0
      USES_XMM
      COMP_ABI 4
;; rdi:     pInpBlk:  PTR DWORD,    ; input  block address
;; rsi:     pOutBlk:  PTR DWORD,    ; output block address
;; rdx:     nr:           DWORD,    ; number of rounds
;; rcx      pKey:     PTR DWORD     ; key material address

SC equ   (4)


   lea      rax,[rdx*SC]
   lea      rax,[rax*4]

   movdqu   xmm0, oword ptr[rdi]       ; input block

   ;;whitening
   pxor     xmm0, oword ptr[rcx+rax]

   cmp      rdx,12                     ; switch according to number of rounds
   jl       key_128
   jz       key_192

   ;;
   ;; regular rounds
   ;;
key_256:
   aesdec      xmm0,oword ptr[rcx+9*SC*4+4*SC*4]
   aesdec      xmm0,oword ptr[rcx+9*SC*4+3*SC*4]
key_192:
   aesdec      xmm0,oword ptr[rcx+9*SC*4+2*SC*4]
   aesdec      xmm0,oword ptr[rcx+9*SC*4+1*SC*4]
key_128:
   aesdec      xmm0,oword ptr[rcx+9*SC*4-0*SC*4]
   aesdec      xmm0,oword ptr[rcx+9*SC*4-1*SC*4]
   aesdec      xmm0,oword ptr[rcx+9*SC*4-2*SC*4]
   aesdec      xmm0,oword ptr[rcx+9*SC*4-3*SC*4]
   aesdec      xmm0,oword ptr[rcx+9*SC*4-4*SC*4]
   aesdec      xmm0,oword ptr[rcx+9*SC*4-5*SC*4]
   aesdec      xmm0,oword ptr[rcx+9*SC*4-6*SC*4]
   aesdec      xmm0,oword ptr[rcx+9*SC*4-7*SC*4]
   aesdec      xmm0,oword ptr[rcx+9*SC*4-8*SC*4]
   ;;
   ;; last rounds
   ;;
   aesdeclast  xmm0,oword ptr[rcx+9*SC*4-9*SC*4]

   movdqu   oword ptr[rsi], xmm0    ; output block

   REST_XMM
   REST_GPR
   ret
IPPASM Decrypt_RIJ128_AES_NI ENDP
ENDIF

ENDIF ;; _AES_NI_ENABLING_
END
