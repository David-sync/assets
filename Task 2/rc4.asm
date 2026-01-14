.386
.model flat, stdcall
option casemap:none

include \masm32\include\kernel32.inc
includelib \masm32\lib\kernel32.lib


.data
    msgInputKey     db "Nhap key: ", 0
    msgInputPlain   db "Nhap plainText: ", 0
    msgCipher       db "Hex: ", 0
    newline         db 13, 10, 0

    hStdIn          dd ?           
    hStdOut         dd ?         
    bytesRead       dd ?         
    bytesWritten    dd ?   

    key             db 256 dup(0)
    keyLen          dd ?            
    
    plainText       db 256 dup(0)
    plainLen        dd ?            

    Sbox            db 256 dup(?)
    hexBuffer       db 0, 0, 20h 
.code

start:
    push -11
    call GetStdHandle
    mov hStdOut, eax

    push -10
    call GetStdHandle
    mov hStdIn, eax


    push 0
    push offset bytesWritten
    push 10                 
    push offset msgInputKey
    push hStdOut
    call WriteConsoleA

    push 0                  ; Reserved
    push offset bytesRead   ; Lưu số lượng ký tự đọc được vào đây
    push 256           ; Đọc tối đa 256 ký tự
    push offset key         ; Lưu vào biến key
    push hStdIn             ; Từ bàn phím
    call ReadConsoleA

    mov eax, bytesRead
    sub eax, 2              ; Trừ đi \r\n
    mov keyLen, eax         ; Lưu độ dài chuẩn


    push 0
    push offset bytesWritten
    push 16                 ; Độ dài chuỗi "Nhap PlainText: "
    push offset msgInputPlain
    push hStdOut
    call WriteConsoleA

    push 0
    push offset bytesRead
    push 256
    push offset plainText
    push hStdIn
    call ReadConsoleA

    mov eax, bytesRead
    sub eax, 2              ; Trừ đi \r\n
    mov plainLen, eax       ; Lưu độ dài chuẩn


    push 0
    push offset bytesWritten 
    push 5                 ; độ dài string này
    push offset msgCipher ; string: "Hex: "
    push hStdOut
    call WriteConsoleA

    call KSA

    call PRGA

    push 0
    push offset bytesWritten
    push 2
    push offset newline ; xuống dòng cho đẹp
    push hStdOut
    call WriteConsoleA

    push 0
    call ExitProcess


KSA proc
    push ebx     ; push ebx, esi, edi vì hàm này sẽ ghi đè 
    push esi
    push edi
    
    xor ecx, ecx            
initLoop:    ; khởi tạo mảng sbox 256 phần tử
    mov byte ptr [Sbox + ecx], cl
    inc ecx   ; ecx tăng từ 0 đến 255 và được lưu vào mảng Sbox ở trên
    cmp ecx, 256
    jl initLoop

    xor ecx, ecx            ; i trong công thức  
    xor ebx, ebx            ; j trong công thức
    
scrambleLoop:  ; bước xáo trộn
    ;j = j + S[i]
    xor eax, eax
    mov al, [Sbox + ecx]    
    add bl, al              
    
    ; i % keyLen
    mov eax, ecx            

    xor edx, edx   ; phép chia 32-bit dùng edx:eax         
    
    ; eax / keyLen
    div [keyLen]   ; thương ở eax, số dư trong edx
    
    ; j = j + key[index] (S[i] đã được cộng ở trên rồi)
    xor eax, eax           
    mov al, [key + edx]     ; Lấy key tại vị trí số dư (edx)
    add bl, al              ; j = j + key[i % keyLen]

    ; swap S[i] và S[j]
    mov al, [Sbox + ecx]    
    mov dl, [Sbox + ebx]   
    mov [Sbox + ecx], dl    
    mov [Sbox + ebx], al   

    ; tiếp tục vòng lặp 
    inc ecx  ; i
    cmp ecx, 256            
    jl scrambleLoop         

    pop edi
    pop esi
    pop ebx
    ret
KSA endp


PRGA proc
    push ebx
    push esi
    push edi

    xor ecx, ecx            ; k
    xor esi, esi            ; i
    xor edi, edi            ; j

myLoop:
    cmp ecx, [plainLen]     ; so sánh với plaintext len
    jge endPrga             

    ; i = (i + 1) mod 256
    inc esi              ; i = i + 1   
    and esi, 0FFh        ; AND 0ff tương đương với mod 256
    

    ; j = (j + S[i]) mod 256
    xor eax, eax         
    mov al, [Sbox + esi]   ; al = S[i]
    add edi, eax        ; j = j + al
    and edi, 0FFh          ; j mod 256


    ; swap S[i] và S[j]
    mov al, [Sbox + esi]
    mov bl, [Sbox + edi]
    mov [Sbox + esi], bl
    mov [Sbox + edi], al

    ; tạo keystream 
    ; t = (S[i] + S[j]) mod 256 sau đó k = S[t]
    add al, bl          ; vừa swap xong nên giá trị vẫn nằm trong al và bl
    movzx eax, al      ; mở rộng 8 bit ra 32 bit để làm chỉ số mảng
    mov bl, [Sbox + eax]    ; bl = k = S[t]

    ; xor plaintext với k (keystream)
    mov al, [plainText + ecx]
    xor al, bl        ; xor với kí tự trong plaintext

    ; in hex
    push ecx                
    push eax                
    call byteToHex ; kết quả đang trong al được chuyển qua hex 

    ; in
    push 0
    push offset bytesWritten
    push 3
    push offset hexBuffer
    push hStdOut
    call WriteConsoleA

    pop eax  
    pop ecx

    inc ecx          ; k = k + 1       
    jmp myLoop       ; tiếp tục

endPrga:
    pop edi
    pop esi
    pop ebx
    ret
PRGA endp


byteToHex proc
    push ebx
    push edx

    mov dl, al      ; dl = al 

    shr al, 4       ; dịch phải 4 bit, ví dụ AC thì dịch 4 bit để lấy A
    cmp al, 9       ; điều kiện để xử lí số hoặc chữ
    jbe isDigit1
    add al, 55              
    jmp store1
isDigit1:
    add al, 48              
store1:
    mov [hexBuffer], al

    mov al, dl              
    and al, 0Fh
    cmp al, 9
    jbe isDigit2
    add al, 55              
    jmp store2
isDigit2:
    add al, 48              
store2:
    mov [hexBuffer+1], al
    
    pop edx
    pop ebx
    ret
byteToHex endp

end start