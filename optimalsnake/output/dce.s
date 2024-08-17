  section .text
  extern error
  extern print
  global our_code_starts_here

internal_error_overflow:
  mov rdi, 1
  push 0
  call error
our_code_starts_here:
push rbx
  mov [rsp - 8], rdi

  mov rax, 0x2
  mov [rsp  -16], rax ; x @ -16
  mov rax, 15
  mov [rsp  -24], rax ; seven @ -24
  mov rax, 7
  mov [rsp  -32], rax ; y @ -32
temp_while_test_1:
  mov rax, 15         ; seven wasn't fetched from the stack
  mov [rsp  -40], rax
  mov rax, [rsp  -32] ; fetch y from the stack
  mov [rsp  -48], rax
  mov rax, [rsp  -40]
  mov rbx, [rsp  -48]
  cmp rax, rbx        ; cmp seven and y
  jg near temp_true_3
  mov rax, 0
  jmp near temp_end_4
temp_true_3:
  mov rax, 0x2
temp_end_4:
  cmp rax, 0x2
  jne near temp_end_2 ; this jump ends the loop
  mov rax, [rsp  -32] ; fetch y from the stack
  add rax, 2          ; add1
  jo near internal_error_overflow
  mov [rsp  -32], rax ; update y in the stack
  mov rax, [rsp  -32] ; this is the setup for print
  mov rdi, rax        ; notice that both "ifs" were eliminated
  sub rsp, 48
  call print
  add rsp, 48
  jmp near temp_while_test_1
temp_end_2:
  mov rax, 0          ; while false turned into false
  mov rax, [rsp  -32] ; fetch y from the stack to print
  mov rdi, rax
  sub rsp, 48
  call print
  add rsp, 48
  mov rax, 15         ; seven is not fetched from the stack
  pop rbx
ret


