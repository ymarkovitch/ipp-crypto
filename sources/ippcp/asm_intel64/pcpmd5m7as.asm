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
;               Message block processing according to MD5
;              (derived from the RSA Data Security, Inc. MD5 Message-Digest Algorithm)
; 
;     Content:
;        UpdateMD5
; 
;
include asmdefs.inc
include ia_32e.inc
include pcpvariant.inc

IF (_ENABLE_ALG_MD5_)
IF _IPP32E GE _IPP32E_M7


;;
;; Magic functions defined in RFC 1321
;;
MAGIC_F MACRO F:REQ, X:REQ,Y:REQ,Z:REQ ;; ((Z) ^ ((X) & ((Y) ^ (Z))))
   mov      F,Z
   xor      F,Y
   and      F,X
   xor      F,Z
ENDM

MAGIC_G MACRO F:REQ, X:REQ,Y:REQ,Z:REQ ;; F((Z),(X),(Y))
   MAGIC_F  F,Z,X,Y
ENDM

MAGIC_H MACRO F:REQ, X:REQ,Y:REQ,Z:REQ ;; ((X) ^ (Y) ^ (Z))
   mov      F,Z
   xor      F,Y
   xor      F,X
ENDM

MAGIC_I MACRO F:REQ, X:REQ,Y:REQ,Z:REQ ;; ((Y) ^ ((X) | ~(Z)))
   mov      F,Z
   not      F
   or       F,X
   xor      F,Y
ENDM

ROT_L MACRO r, nbits
   IF _IPP32E GE _IPP32E_L9
   rorx  r,r,(32-nbits)
   ELSEIF _IPP32E GE _IPP32E_Y8
   shld  r,r,nbits
   ELSE
   rol   r,nbits
   ENDIF
ENDM

;;
;; single MD5 step
;;
;; A = B +ROL32((A +MAGIC(B,C,D) +data +const), nrot)
;;
xMD5_STEP MACRO MAGIC_FUN:REQ, A:REQ,B:REQ,C:REQ,D:REQ, FUN:REQ,TMP:REQ, data:REQ, MD5const:REQ, nrot:REQ
   mov         TMP,[data]
;  lea         A,[TMP+A+MD5const]
   add         A, MD5const
   add         A, TMP
   MAGIC_FUN   FUN, B,C,D
   add         A,FUN
   rol         A,nrot
   add         A,B
ENDM

MD5_STEP MACRO MAGIC_FUN:REQ, A:REQ,B:REQ,C:REQ,D:REQ, FUN:REQ,TMP:REQ, data:REQ, MD5const:REQ, nrot:REQ
   mov         TMP,[data]
   add         A, MD5const
   add         A, TMP
   MAGIC_FUN   FUN, B,C,D
   add         A,FUN
   ROT_L       A,nrot
   add         A,B
ENDM

IPPCODE SEGMENT 'CODE' ALIGN (IPP_ALIGN_FACTOR)

;*****************************************************************************************
;* Purpose:    Update internal digest according to message block
;*
;* void UpdateMD5(DigestMD5digest, const Ipp32u* mblk, int mlen, const void* pParam)
;*
;*****************************************************************************************

;;
;; MD5 left rotations (number of bits)
;;
rot11 =  7
rot12 =  12
rot13 =  17
rot14 =  22
rot21 =  5
rot22 =  9
rot23 =  14
rot24 =  20
rot31 =  4
rot32 =  11
rot33 =  16
rot34 =  23
rot41 =  6
rot42 =  10
rot43 =  15
rot44 =  21

ALIGN IPP_ALIGN_FACTOR

;;
;; Lib = M7
;;
;; Caller = ippsMD5Update
;; Caller = ippsMD5Final
;; Caller = ippsMD5MessageDigest
;;
;; Caller = ippsHMACMD5Update
;; Caller = ippsHMACMD5Final
;; Caller = ippsHMACMD5MessageDigest
;;

ALIGN IPP_ALIGN_FACTOR
IPPASM UpdateMD5 PROC PUBLIC FRAME
      USES_GPR rbx,rsi,rdi,r12
      USES_XMM
      COMP_ABI 4

;; rdi = hash
;; rsi = data buffer
;; rdx = buffer length
;; rcx = address of MD5 constants

MBS_MD5  equ   (64)

   movsxd   r12, edx

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; process next data block
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

md5_block_loop:
;   prefetcht0  [rsi+64]

;;
;; init A, B, C, D by the internal digest
;;
   mov      r8d, [rdi+0*4]    ; r8d  = digest[0] (A)
   mov      r9d, [rdi+1*4]    ; r9d  = digest[1] (B)
   mov      r10d,[rdi+2*4]    ; r10d = digest[2] (C)
   mov      r11d,[rdi+3*4]    ; r11d = digest[3] (D)

;;
;; perform 0-63 steps
;;
;;          MAGIC    A,   B,   C,   D,    FUN,TMP, pData,      cnt,        nrot
;;          -------------------------------------------------------------------
   MD5_STEP MAGIC_F, r8d, r9d, r10d,r11d, edx,ecx, <rsi+ 0*4>, 0d76aa478h, rot11
   MD5_STEP MAGIC_F, r11d,r8d, r9d, r10d, edx,ecx, <rsi+ 1*4>, 0e8c7b756h, rot12
   MD5_STEP MAGIC_F, r10d,r11d,r8d, r9d,  edx,ecx, <rsi+ 2*4>, 0242070dbh, rot13
   MD5_STEP MAGIC_F, r9d, r10d,r11d,r8d,  edx,ecx, <rsi+ 3*4>, 0c1bdceeeh, rot14
   MD5_STEP MAGIC_F, r8d, r9d, r10d,r11d, edx,ecx, <rsi+ 4*4>, 0f57c0fafh, rot11
   MD5_STEP MAGIC_F, r11d,r8d, r9d, r10d, edx,ecx, <rsi+ 5*4>, 04787c62ah, rot12
   MD5_STEP MAGIC_F, r10d,r11d,r8d, r9d,  edx,ecx, <rsi+ 6*4>, 0a8304613h, rot13
   MD5_STEP MAGIC_F, r9d, r10d,r11d,r8d,  edx,ecx, <rsi+ 7*4>, 0fd469501h, rot14
   MD5_STEP MAGIC_F, r8d, r9d, r10d,r11d, edx,ecx, <rsi+ 8*4>, 0698098d8h, rot11
   MD5_STEP MAGIC_F, r11d,r8d, r9d, r10d, edx,ecx, <rsi+ 9*4>, 08b44f7afh, rot12
   MD5_STEP MAGIC_F, r10d,r11d,r8d, r9d,  edx,ecx, <rsi+10*4>, 0ffff5bb1h, rot13
   MD5_STEP MAGIC_F, r9d, r10d,r11d,r8d,  edx,ecx, <rsi+11*4>, 0895cd7beh, rot14
   MD5_STEP MAGIC_F, r8d, r9d, r10d,r11d, edx,ecx, <rsi+12*4>, 06b901122h, rot11
   MD5_STEP MAGIC_F, r11d,r8d, r9d, r10d, edx,ecx, <rsi+13*4>, 0fd987193h, rot12
   MD5_STEP MAGIC_F, r10d,r11d,r8d, r9d,  edx,ecx, <rsi+14*4>, 0a679438eh, rot13
   MD5_STEP MAGIC_F, r9d, r10d,r11d,r8d,  edx,ecx, <rsi+15*4>, 049b40821h, rot14

   MD5_STEP MAGIC_G, r8d, r9d, r10d,r11d, edx,ecx, <rsi+ 1*4>, 0f61e2562h, rot21
   MD5_STEP MAGIC_G, r11d,r8d, r9d, r10d, edx,ecx, <rsi+ 6*4>, 0c040b340h, rot22
   MD5_STEP MAGIC_G, r10d,r11d,r8d, r9d,  edx,ecx, <rsi+11*4>, 0265e5a51h, rot23
   MD5_STEP MAGIC_G, r9d, r10d,r11d,r8d,  edx,ecx, <rsi+ 0*4>, 0e9b6c7aah, rot24
   MD5_STEP MAGIC_G, r8d, r9d, r10d,r11d, edx,ecx, <rsi+ 5*4>, 0d62f105dh, rot21
   MD5_STEP MAGIC_G, r11d,r8d, r9d, r10d, edx,ecx, <rsi+10*4>, 002441453h, rot22
   MD5_STEP MAGIC_G, r10d,r11d,r8d, r9d,  edx,ecx, <rsi+15*4>, 0d8a1e681h, rot23
   MD5_STEP MAGIC_G, r9d, r10d,r11d,r8d,  edx,ecx, <rsi+ 4*4>, 0e7d3fbc8h, rot24
   MD5_STEP MAGIC_G, r8d, r9d, r10d,r11d, edx,ecx, <rsi+ 9*4>, 021e1cde6h, rot21
   MD5_STEP MAGIC_G, r11d,r8d, r9d, r10d, edx,ecx, <rsi+14*4>, 0c33707d6h, rot22
   MD5_STEP MAGIC_G, r10d,r11d,r8d, r9d,  edx,ecx, <rsi+ 3*4>, 0f4d50d87h, rot23
   MD5_STEP MAGIC_G, r9d, r10d,r11d,r8d,  edx,ecx, <rsi+ 8*4>, 0455a14edh, rot24
   MD5_STEP MAGIC_G, r8d, r9d, r10d,r11d, edx,ecx, <rsi+13*4>, 0a9e3e905h, rot21
   MD5_STEP MAGIC_G, r11d,r8d, r9d, r10d, edx,ecx, <rsi+ 2*4>, 0fcefa3f8h, rot22
   MD5_STEP MAGIC_G, r10d,r11d,r8d, r9d,  edx,ecx, <rsi+ 7*4>, 0676f02d9h, rot23
   MD5_STEP MAGIC_G, r9d, r10d,r11d,r8d,  edx,ecx, <rsi+12*4>, 08d2a4c8ah, rot24

   MD5_STEP MAGIC_H, r8d, r9d, r10d,r11d, edx,ecx, <rsi+ 5*4>, 0fffa3942h, rot31
   MD5_STEP MAGIC_H, r11d,r8d, r9d, r10d, edx,ecx, <rsi+ 8*4>, 08771f681h, rot32
   MD5_STEP MAGIC_H, r10d,r11d,r8d, r9d,  edx,ecx, <rsi+11*4>, 06d9d6122h, rot33
   MD5_STEP MAGIC_H, r9d, r10d,r11d,r8d,  edx,ecx, <rsi+14*4>, 0fde5380ch, rot34
   MD5_STEP MAGIC_H, r8d, r9d, r10d,r11d, edx,ecx, <rsi+ 1*4>, 0a4beea44h, rot31
   MD5_STEP MAGIC_H, r11d,r8d, r9d, r10d, edx,ecx, <rsi+ 4*4>, 04bdecfa9h, rot32
   MD5_STEP MAGIC_H, r10d,r11d,r8d, r9d,  edx,ecx, <rsi+ 7*4>, 0f6bb4b60h, rot33
   MD5_STEP MAGIC_H, r9d, r10d,r11d,r8d,  edx,ecx, <rsi+10*4>, 0bebfbc70h, rot34
   MD5_STEP MAGIC_H, r8d, r9d, r10d,r11d, edx,ecx, <rsi+13*4>, 0289b7ec6h, rot31
   MD5_STEP MAGIC_H, r11d,r8d, r9d, r10d, edx,ecx, <rsi+ 0*4>, 0eaa127fah, rot32
   MD5_STEP MAGIC_H, r10d,r11d,r8d, r9d,  edx,ecx, <rsi+ 3*4>, 0d4ef3085h, rot33
   MD5_STEP MAGIC_H, r9d, r10d,r11d,r8d,  edx,ecx, <rsi+ 6*4>, 004881d05h, rot34
   MD5_STEP MAGIC_H, r8d, r9d, r10d,r11d, edx,ecx, <rsi+ 9*4>, 0d9d4d039h, rot31
   MD5_STEP MAGIC_H, r11d,r8d, r9d, r10d, edx,ecx, <rsi+12*4>, 0e6db99e5h, rot32
   MD5_STEP MAGIC_H, r10d,r11d,r8d, r9d,  edx,ecx, <rsi+15*4>, 01fa27cf8h, rot33
   MD5_STEP MAGIC_H, r9d, r10d,r11d,r8d,  edx,ecx, <rsi+ 2*4>, 0c4ac5665h, rot34

   MD5_STEP MAGIC_I, r8d, r9d, r10d,r11d, edx,ecx, <rsi+ 0*4>, 0f4292244h, rot41
   MD5_STEP MAGIC_I, r11d,r8d, r9d, r10d, edx,ecx, <rsi+ 7*4>, 0432aff97h, rot42
   MD5_STEP MAGIC_I, r10d,r11d,r8d, r9d,  edx,ecx, <rsi+14*4>, 0ab9423a7h, rot43
   MD5_STEP MAGIC_I, r9d, r10d,r11d,r8d,  edx,ecx, <rsi+ 5*4>, 0fc93a039h, rot44
   MD5_STEP MAGIC_I, r8d, r9d, r10d,r11d, edx,ecx, <rsi+12*4>, 0655b59c3h, rot41
   MD5_STEP MAGIC_I, r11d,r8d, r9d, r10d, edx,ecx, <rsi+ 3*4>, 08f0ccc92h, rot42
   MD5_STEP MAGIC_I, r10d,r11d,r8d, r9d,  edx,ecx, <rsi+10*4>, 0ffeff47dh, rot43
   MD5_STEP MAGIC_I, r9d, r10d,r11d,r8d,  edx,ecx, <rsi+ 1*4>, 085845dd1h, rot44
   MD5_STEP MAGIC_I, r8d, r9d, r10d,r11d, edx,ecx, <rsi+ 8*4>, 06fa87e4fh, rot41
   MD5_STEP MAGIC_I, r11d,r8d, r9d, r10d, edx,ecx, <rsi+15*4>, 0fe2ce6e0h, rot42
   MD5_STEP MAGIC_I, r10d,r11d,r8d, r9d,  edx,ecx, <rsi+ 6*4>, 0a3014314h, rot43
   MD5_STEP MAGIC_I, r9d, r10d,r11d,r8d,  edx,ecx, <rsi+13*4>, 04e0811a1h, rot44
   MD5_STEP MAGIC_I, r8d, r9d, r10d,r11d, edx,ecx, <rsi+ 4*4>, 0f7537e82h, rot41
   MD5_STEP MAGIC_I, r11d,r8d, r9d, r10d, edx,ecx, <rsi+11*4>, 0bd3af235h, rot42
   MD5_STEP MAGIC_I, r10d,r11d,r8d, r9d,  edx,ecx, <rsi+ 2*4>, 02ad7d2bbh, rot43
   MD5_STEP MAGIC_I, r9d, r10d,r11d,r8d,  edx,ecx, <rsi+ 9*4>, 0eb86d391h, rot44

;;
;; update digest
;;
   add      [rdi+0*4],r8d     ; advance digest
   add      [rdi+1*4],r9d
   add      [rdi+2*4],r10d
   add      [rdi+3*4],r11d

   add      rsi, MBS_MD5
   sub      r12, MBS_MD5
   jg       md5_block_loop

   REST_XMM
   REST_GPR
   ret
IPPASM UpdateMD5 ENDP

ENDIF    ;; _IPP32E GE _IPP32E_M7
ENDIF    ;; _ENABLE_ALG_MD5_
END

