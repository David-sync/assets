.386
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
includelib \masm32\lib\kernel32.lib

.data
    hStdIn      dd 0
    hStdOut     dd 0
    bytesRead   dd 0
    bytesWritten dd 0

    msgInputA   db "Nhap so A: ", 0
    lenMsgA  equ $ - msgInputA      
    msgInputB   db "Nhap so B: ", 0
    lenMsgB  equ $ - msgInputB
    
    msgResult   db "Ket qua: ", 0
    lenMsgRes equ $ - msgResult
    
    newline     db 13, 10           
    lenNewline  equ $ - newline

    buffer1     db 32 dup(0)        
    buffer2     db 32 dup(0)    
    bufferOut   db 64 dup(0)     

    len1        dd 0
    len2        dd 0
    var_i       dd 0
    var_j       dd 0
    idx_p1      dd 0
    idx_p2      dd 0
    max_len     dd 0

.code
main:

    push STD_OUTPUT_HANDLE
    call GetStdHandle
    mov hStdOut, eax
    
    push STD_INPUT_HANDLE
    call GetStdHandle
    mov hStdIn, eax

    push 0
    push offset bytesWritten
    push lenMsgA
    push offset msgInputA
    push hStdOut
    call WriteConsole

    push 0
    push offset bytesRead
    push 32                 
    push offset buffer1
    push hStdIn
    call ReadConsole
    
    mov eax, bytesRead 
    sub eax, 2   ; trừ 2 kí tự xuống dòng 13 và 10
    mov len1, eax


    push 0
    push offset bytesWritten
    push lenMsgB
    push offset msgInputB
    push hStdOut
    call WriteConsole

    push 0
    push offset bytesRead
    push 32                 
    push offset buffer2
    push hStdIn
    call ReadConsole
    
    mov eax, bytesRead ; tương tự với len1, trừ 13, 10
    sub eax, 2
    mov len2, eax


    mov eax, len1
    add eax, len2
    mov max_len, eax   ; độ dài tối đa dựa trên 2 len buffer

    mov eax, len1
    dec eax
    mov var_i, eax  ; i

myLoop1:
    cmp var_i, 0    ; var i đang là độ dài của chuỗi 1
    jl done         ; nếu hết độ dài thì nhảy xuống in 

    mov eax, len2    
    dec eax
    mov var_j, eax   ; tương tự với chuỗi 2, nhưng thay vì in thì check còn chuỗi 1 không

    myLoop2:
        cmp var_j, 0
        jl Next_i    ; kiểm tra var_i để lặp tiếp

        mov esi, offset buffer1  ; địa chỉ buff1
        add esi, var_i          ; trỏ tới phần tử cuối cùng vì + len_buff_1
        mov al, [esi]           
        sub al, '0'             ; chuyển kí tự đó qua int

        mov edi, offset buffer2 ; tương tự lấy địa chỉ buff_2
        add edi, var_j          ; trỏ tới phần tử cuối cùng len_buff2
        mov dl, [edi] 
        sub dl, '0'             ; chuyển qua int

        mul dl           ; nhân al với dl, logic chính

        mov ecx, var_i          ; tính toán địa chỉ để lưu vào bufferOuput
        add ecx, var_j          ; bằng cách cộng var_i với var_j, để cộng từng cộng
        inc ecx                 ; +1 vì ban đầu tính max_len
                                ; ví dụ 36 * 1 thì max_len sẽ là 3, var_i + var_j = 3
                                ; vậy mảng bufferOutput sẽ là [0, 0, 0] với index là 0 1 2 
                                ; nhưng khi var_i trỏ tới số 3 thì i=0, số 6 thì i=1
                                ; var_j trỏ tới số 1 là i = 0
                                ; cộng lại thì chỉ mới là 1, mà ta cần ghi phép nhân 6 với 1 vào index số 2
                                ; nên phải +1
        
        mov idx_p2, ecx         ; giá trị vừa tính để tính cộng vào offset BufferOuput
        dec ecx                 
        mov idx_p1, ecx         ; sau khi -1 thì sẽ là index tiếp theo bên trái

        mov ebx, offset bufferOut 
        mov ecx, idx_p2
        add al, [ebx + ecx]     ; cộng số đầu tiên

        ; tách 2 số ra (nếu có)
        mov ah, 0               ; có thể dùng lệnh movzx eax, al vì mình sẽ dùng toàn bộ AX nên phải xử lí rác ở ah
        mov dl, 10             
        div dl                  ; chia 10 để tách số, thương nằm trong al, dư nằm trong ah

        mov [ebx + ecx], ah     ; ghi số đầu tiên vào buffer
        
        mov ecx, idx_p1       ; idex_p1 < idx_p2 1 đơn vị
        add [ebx + ecx], al    ; trỏ sang bên trái của vị trí vừa ghi

        dec var_j           ; tiếp tục với số tiếp theo
        jmp myLoop2         ; again

    Next_i:
        dec var_i           ; hết số trong vòng lặp trong thì tiếp tục với buffer1
        jmp myLoop1

done:
    push 0
    push offset bytesWritten
    push lenMsgRes
    push offset msgResult
    push hStdOut
    call WriteConsole


    mov ecx, 0              ; quét bufferOutput
    mov esi, offset bufferOut

viTriBatDau:
    mov eax, max_len
    dec eax                 ; index cuối cùng
    cmp ecx, eax
    jge timThay         ; nếu chạy đến số cuối rồi thì dừng (kể cả nó là 0)

    ; Kiểm tra số nguyên 0, số 0 chứ không phải '0'
    cmp byte ptr [esi + ecx], 0 
    jne timThay         ; gặp số khác 0 thì ngon luôn
    
    inc ecx                 ; bỏ qua số 0
    jmp viTriBatDau

timThay:
    push ecx               ; sau tỉ tỉ bước tính toán thì ecx giữ vị trí bắt đầu của buffer, lưu tạm để giữ mốc

convertLoop:
    cmp ecx, max_len
    jge print
    
    add byte ptr [esi + ecx], '0'  
    inc ecx
    jmp convertLoop

print:
    pop ecx                 ; lấy điểm bắt đầu hồi nãy ra để tính độ dài chuỗi và điểm bắt đầu trong buffer

    mov eax, max_len        ; tính độ dài chuỗi
    sub eax, ecx          
    
    lea edx, [esi + ecx]    ; vị trí bắt đầu (byte khác 0 đầu tiên)

    push 0
    push offset bytesWritten
    push eax                ; độ dài
    push edx                ; offset buffer
    push hStdOut
    call WriteConsole

    push 0
    push offset bytesWritten
    push lenNewline         
    push offset newline      ; in kí tự xuống dòng cho đẹp
    push hStdOut
    call WriteConsole
    
    push 0
    call ExitProcess

end main