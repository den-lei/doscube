;based off firecube 
;https://www.pouet.net/prod.php?which=11132 
;just played a bit with the code to get better with assembly
org 100h

mov al, 0x13       ; video mode
int 10h            ; switch video mode to AL
push 0x0a000       ; init
pop ss

; PALETTE
out dx, al         ; select palette colors
inc dx

; Cube
mov bp, BackBuffer ; Backbuffer address
	
main:
    mov ch, 0xF8
    mov di, bp
    mov si, bp
.copy:
    mov al, [si]
    shr al, 4
    mov [ss:di], al
    stosb           ; store
    lodsb           ; load
    loop .copy

mov ebx, 11010010111111010000000101101000b
mov di, cube3d
mov cl, 2
.cube:
    sbb ax, ax
    and ax, 64
    sub ax, 64/2
    stosw
    shr ebx, 1
    jnz .cube
    mov bx, 1001101111011010b
    inc word [si]    ; this is the angle increment
    loop .cube

mov cl, 16
mov bx, cube3d
	
.rot_coords:
    fild word [bx+4]    ; offset z
    call Load

    mov al, 3
.rotation:
    fldpi
    fimul word [si]
    fidiv word [persp+2]
    fchs  
    fsincos
    fld st2
    fmul st2
    fld st4
    fmul st2
    fsubrp st1
    fxch
    fmulp st3,st0
    fxch
    fmulp st3,st0
    fxch
    faddp st2
    fxch st2
    dec al
    jnz .rotation
    fild word [persp+2]
    fadd st1,st0
    fdivp st1
    fmul st1,st0
    fmulp st2
    fistp word [bx+96]
    fistp word [bx+96+2]
    lea bx,[bx+6]
    loop .rot_coords

mov cl, 15
lines:
    call Load
    lea bx, [bx + 6]   ; bx = bx + 6
    call Load
    ; Berechnung der Differenzen zwischen den Koordinaten
    fsub to st2        ; x1 y1 x2-x1 y2
    fxch               ; y1 x1 x2-x1 y2
    fsub to st3        ; y1 x1 x2-x1 y2-y1
    ; Initialisierung für die Schleife zur Berechnung der Linienlänge
    fld st2            ; x2-x1 y1 x1 x2-x1 y2-y1
    fmul st0           ; (x2-x1)² y1 x1 x2-x1 y2-y1
    fld st4            ; y2-y1 (x2-x1)² y1 x1 x2-x1 y2-y1
    fmul st0           ; (y2-y1)² (x2-x1)² y1 x1 x2-x1 y2-y1
    faddp st1          ; (y2-y1)² + (x2-x1)² y1 x1 x2-x1 y2-y1
    fsqrt              ; length y1 x1 x2-x1 y2-y1

    ; Berechnung der Längenverhältnisse für den Schleifendurchlauf
    fdiv to st3        ; length y1 x1 x2-x1/length y2-y1
    fdiv to st4        ; length y1 x1 x2-x1/length y2-y1/length
    
    pusha              ; Speichern der Register für die Schleifenberechnung
    mov si, sistr      ; Laden des Startpunkts der Linie
    fistp word [si]    ; st0=y1, st1=x1, st2=x2-x1/length, st3=y2-y1/length
    mov cx, [si]

linefpulength:
    fadd st3           ; st0 = st0 + st3 (y1+=deltay)
    fist word [si]
    fxch               ; st0=x1, st1=y1
    mov di, [si]       ; y offset
persp:
    imul di, 320       ; this "320" is also used as a perspective factor
    fadd st2           ; st0 = st0 + st2 (x1+=deltax)
    fist word [si]
    fxch               ; st0=y1, st1=x1
    add di, [si]       ; x offset
    add di, 32090      ; x/y centering
    add di, bp
    mov al, 16
    stosb
    loop linefpulength
    finit
    popa
    loop lines
jne main

Load:
    fild word [bx+2]
    fild word [bx]
    ret

cube3d:
    sistr    equ    cube3d+192
    BackBuffer    equ    cube3d+96+96+8
