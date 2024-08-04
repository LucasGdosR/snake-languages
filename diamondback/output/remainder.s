  section .text
  extern error
  extern print
  global our_code_starts_here

remainder_func:
  mov rax, [rsp + 8]
  mov [rsp  -8], rax
  mov rax, 1
  mov [rsp  -16], rax
  mov rax, [rsp  -8]
  mov rbx, [rsp  -16]
  cmp rax, rbx
  je near temp_true_19
  mov rax, 0
  jmp near temp_end_20
temp_true_19:
  mov rax, 0x2
temp_end_20:
  cmp rax, 0
  je near temp_else_1
  mov rax, -1
  jmp near temp_end_2
temp_else_1:
  mov rax, [rsp + 16]
  mov [rsp  -8], rax
  mov rax, 1
  mov [rsp  -16], rax
  mov rax, [rsp  -8]
  mov rbx, [rsp  -16]
  cmp rax, rbx
  jg near temp_true_3
  mov rax, 0
  jmp near temp_end_4
temp_true_3:
  mov rax, 0x2
temp_end_4:
  mov [rsp  -8], rax
  mov rax, [rsp + 8]
  mov [rsp  -16], rax
  mov rax, 1
  mov [rsp  -24], rax
  mov rax, [rsp  -16]
  mov rbx, [rsp  -24]
  cmp rax, rbx
  jg near temp_true_5
  mov rax, 0
  jmp near temp_end_6
temp_true_5:
  mov rax, 0x2
temp_end_6:
  mov [rsp  -16], rax
  mov rax, [rsp  -16]
  cmp rax, 0
  je near temp_else_17
  mov rax, 1
  jmp near temp_end_18
temp_else_17:
  mov rax, [rsp + 8]
  mov [rsp  -24], rax
  mov rax, -1
  mov [rsp  -32], rax
  mov rax, [rsp  -24]
  mov rbx, [rsp  -32]
  sar rax, 1
  sar rbx, 1
  imul rax, rbx
  jo near internal_error_overflow
  shl rax, 1
  jo near internal_error_overflow
  add rax, 1
  mov [rsp + 8], rax
temp_end_18:
  mov rax, [rsp  -8]
  cmp rax, 0
  je near temp_else_15
  mov rax, 1
  jmp near temp_end_16
temp_else_15:
  mov rax, [rsp + 16]
  mov [rsp  -24], rax
  mov rax, -1
  mov [rsp  -32], rax
  mov rax, [rsp  -24]
  mov rbx, [rsp  -32]
  sar rax, 1
  sar rbx, 1
  imul rax, rbx
  jo near internal_error_overflow
  shl rax, 1
  jo near internal_error_overflow
  add rax, 1
  mov [rsp + 16], rax
temp_end_16:
temp_while_test_11:
  mov rax, [rsp + 16]
  mov [rsp  -24], rax
  mov rax, [rsp + 8]
  mov [rsp  -32], rax
  mov rax, [rsp  -24]
  mov rbx, [rsp  -32]
  cmp rax, rbx
  jg near temp_true_13
  mov rax, 0
  jmp near temp_end_14
temp_true_13:
  mov rax, 0x2
temp_end_14:
  cmp rax, 0x2
  jne near temp_end_12
  mov rax, [rsp + 16]
  mov [rsp  -24], rax
  mov rax, [rsp + 8]
  mov [rsp  -32], rax
  mov rax, [rsp  -24]
  mov rbx, [rsp  -32]
  sar rax, 1
  sar rbx, 1
  sub rax, rbx
  jo near internal_error_overflow
  shl rax, 1
  jo near internal_error_overflow
  add rax, 1
  mov [rsp + 16], rax
  jmp near temp_while_test_11
temp_end_12:
  mov rax, [rsp + 16]
  mov [rsp  -24], rax
  mov rax, [rsp + 8]
  mov [rsp  -32], rax
  mov rax, [rsp  -24]
  mov rbx, [rsp  -32]
  cmp rax, rbx
  je near temp_true_9
  mov rax, 0
  jmp near temp_end_10
temp_true_9:
  mov rax, 0x2
temp_end_10:
  cmp rax, 0
  je near temp_else_7
  mov rax, 1
  jmp near temp_end_8
temp_else_7:
  mov rax, [rsp + 16]
temp_end_8:
temp_end_2:
  ret
internal_error_overflow:
  mov rdi, 1
  push 0
  call error
our_code_starts_here:
push rbx
  mov [rsp - 8], rdi

  mov rax, 1
  mov [rsp  -16], rax
  mov rax, 27
  mov [rsp  -24], rax
  mov rax, 9
  mov [rsp  -32], rax
  sub rsp, 32
  call remainder_func
  add rsp, 32
  mov rdi, rax
  sub rsp, 32
  call print
  add rsp, 32
  mov rax, 27
  mov [rsp  -24], rax
  mov rax, -7
  mov [rsp  -32], rax
  sub rsp, 32
  call remainder_func
  add rsp, 32
  mov rdi, rax
  sub rsp, 32
  call print
  add rsp, 32
  mov rax, -25
  mov [rsp  -24], rax
  mov rax, -7
  mov [rsp  -32], rax
  sub rsp, 32
  call remainder_func
  add rsp, 32
  mov rdi, rax
  sub rsp, 32
  call print
  add rsp, 32
  mov rax, -25
  mov [rsp  -24], rax
  mov rax, 9
  mov [rsp  -32], rax
  sub rsp, 32
  call remainder_func
  add rsp, 32
  mov rdi, rax
  sub rsp, 32
  call print
  add rsp, 32
  mov rax, 29
  mov [rsp  -24], rax
  mov rax, 9
  mov [rsp  -32], rax
  sub rsp, 32
  call remainder_func
  add rsp, 32
  mov rdi, rax
  sub rsp, 32
  call print
  add rsp, 32
  mov rax, 31
  mov [rsp  -24], rax
  mov rax, 9
  mov [rsp  -32], rax
  sub rsp, 32
  call remainder_func
  add rsp, 32
  mov rdi, rax
  sub rsp, 32
  call print
  add rsp, 32
  mov rax, 33
  mov [rsp  -24], rax
  mov rax, 9
  mov [rsp  -32], rax
  sub rsp, 32
  call remainder_func
  add rsp, 32
  mov rdi, rax
  sub rsp, 32
  call print
  add rsp, 32
  mov rax, 33
  mov [rsp  -24], rax
  mov rax, 1
  mov [rsp  -32], rax
  sub rsp, 32
  call remainder_func
  add rsp, 32
  mov rdi, rax
  sub rsp, 32
  call print
  add rsp, 32
  pop rbx
ret


