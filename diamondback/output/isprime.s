  section .text
  extern error
  extern print
  global our_code_starts_here

remainder_func:
temp_while_test_5:
  mov rax, [rsp + 16]
  mov [rsp  -8], rax
  mov rax, [rsp + 8]
  mov [rsp  -16], rax
  mov rax, [rsp  -8]
  mov rbx, [rsp  -16]
  cmp rax, rbx
  jg near temp_true_7
  mov rax, 0
  jmp near temp_end_8
temp_true_7:
  mov rax, 0x2
temp_end_8:
  cmp rax, 0x2
  jne near temp_end_6
  mov rax, [rsp + 16]
  mov [rsp  -8], rax
  mov rax, [rsp + 8]
  mov [rsp  -16], rax
  mov rax, [rsp  -8]
  mov rbx, [rsp  -16]
  sar rax, 1
  sar rbx, 1
  sub rax, rbx
  jo near internal_error_overflow
  shl rax, 1
  jo near internal_error_overflow
  add rax, 1
  mov [rsp + 16], rax
  jmp near temp_while_test_5
temp_end_6:
  mov rax, [rsp + 16]
  mov [rsp  -8], rax
  mov rax, [rsp + 8]
  mov [rsp  -16], rax
  mov rax, [rsp  -8]
  mov rbx, [rsp  -16]
  cmp rax, rbx
  je near temp_true_3
  mov rax, 0
  jmp near temp_end_4
temp_true_3:
  mov rax, 0x2
temp_end_4:
  cmp rax, 0
  je near temp_else_1
  mov rax, 1
  jmp near temp_end_2
temp_else_1:
  mov rax, [rsp + 16]
temp_end_2:
  ret
is_prime_func:
  mov rax, 5
  mov [rsp  -8], rax
temp_while_test_13:
  mov rax, [rsp + 8]
  mov [rsp  -16], rax
  mov rax, [rsp  -8]
  mov [rsp  -24], rax
  mov rax, [rsp  -16]
  mov rbx, [rsp  -24]
  cmp rax, rbx
  jg near temp_true_19
  mov rax, 0
  jmp near temp_end_20
temp_true_19:
  mov rax, 0x2
temp_end_20:
  cmp rax, 0x2
  jne near temp_end_14
  mov rax, 1
  mov [rsp  -16], rax
  mov rax, [rsp + 8]
  mov [rsp  -24], rax
  mov rax, [rsp  -8]
  mov [rsp  -32], rax
  sub rsp, 32
  call remainder_func
  add rsp, 32
  mov [rsp  -24], rax
  mov rax, [rsp  -16]
  mov rbx, [rsp  -24]
  cmp rax, rbx
  je near temp_true_17
  mov rax, 0
  jmp near temp_end_18
temp_true_17:
  mov rax, 0x2
temp_end_18:
  cmp rax, 0
  je near temp_else_15
  mov rax, [rsp + 8]
  add rax, 2
  jo near internal_error_overflow
  mov [rsp  -8], rax
  jmp near temp_end_16
temp_else_15:
  mov rax, [rsp  -8]
  add rax, 2
  jo near internal_error_overflow
  mov [rsp  -8], rax
temp_end_16:
  jmp near temp_while_test_13
temp_end_14:
  mov rax, [rsp + 8]
  mov [rsp  -16], rax
  mov rax, [rsp  -8]
  mov [rsp  -24], rax
  mov rax, [rsp  -16]
  mov rbx, [rsp  -24]
  cmp rax, rbx
  je near temp_true_11
  mov rax, 0
  jmp near temp_end_12
temp_true_11:
  mov rax, 0x2
temp_end_12:
  cmp rax, 0
  je near temp_else_9
  mov rax, 0x2
  jmp near temp_end_10
temp_else_9:
  mov rax, 0
temp_end_10:
  ret
internal_error_overflow:
  mov rdi, 1
  push 0
  call error
our_code_starts_here:
push rbx
  mov [rsp - 8], rdi

  mov rax, [rsp  -8]
  mov [rsp  -16], rax
  sub rsp, 16
  call is_prime_func
  add rsp, 16
  pop rbx
ret


