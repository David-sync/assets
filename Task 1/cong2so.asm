include \masm32\include\masm32rt.inc


.data
    msg db "Nhap vao 2 so: ", 0
    msg2 db "Ket qua: ", 0

    bytes_read1 dd 0
    bytes_read2 dd 0

    buffer1 db 64 dup(?)
    buffer2 db 64 dup(?)
    bufferOutput db 128 dup(?)



.code
main PROC

    push offset msg
    call StdOut

    push 64
    push offset buffer1
    call StdIn
    mov bytes_read1, eax

    push 64
    push offset buffer2
    call StdIn
    mov bytes_read2, eax



    mov esi, offset buffer1
    add esi, bytes_read1
    sub esi, 1
    mov edi, offset buffer2
    add edi, bytes_read2
    sub edi, 1


    mov ecx, offset bufferOutput
    add ecx, 127 
    mov byte ptr [ecx], 0
    dec ecx

    xor ebx, ebx
    
myLoop:
    cmp bytes_read1, 0
    jg continue
    cmp bytes_read2, 0 
    jg continue
    jmp endLoop


continue:
    xor eax, eax

    cmp bytes_read1, 0
    jle oneIsZero

    mov al, [esi]
    sub al, '0'
    dec esi
    dec bytes_read1
    jmp numberTwo

oneIsZero:
    jmp numberTwo

numberTwo:
    xor edx, edx

    cmp bytes_read2, 0
    jle twoIsZero

    mov dl, [edi]
    sub dl, '0'
    dec edi
    dec bytes_read2


twoIsZero:
    add eax, edx
    add eax, ebx

    xor ebx, ebx

    cmp eax, 9
    jle Done

    sub eax, 10
    mov ebx, 1


Done:
    add al, '0'
    mov [ecx], al
    dec ecx 
    jmp myLoop



endLoop:
    ;so nho cuoi cung neu con
    cmp ebx, 1
    jne actuallyDone 
    add ebx, 48
    mov [ecx], bl
    dec ecx

actuallyDone:
    inc ecx
    push ecx

    push offset msg2
    call StdOut

    pop ecx
    push ecx
    call StdOut

    push 0
    call ExitProcess


main ENDP

END main
