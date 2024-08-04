  section .text
  extern error
  extern print
  global our_code_starts_here

fibonacci_func:
  mov rax, [rsp + 8]
  mov [rsp  -8], rax
  mov rax, 3
  mov [rsp  -16], rax
  mov rax, [rsp  -8]
  mov rbx, [rsp  -16]
  cmp rax, rbx
  jl near temp_true_7
  mov rax, 0
  jmp near temp_end_8
temp_true_7:
  mov rax, 0x2
temp_end_8:
  cmp rax, 0
  je near temp_else_1
  mov rax, 1
  jmp near temp_end_2
temp_else_1:
  mov rax, [rsp + 8]
  mov [rsp  -8], rax
  mov rax, 7
  mov [rsp  -16], rax
  mov rax, [rsp  -8]
  mov rbx, [rsp  -16]
  cmp rax, rbx
  jl near temp_true_5
  mov rax, 0
  jmp near temp_end_6
temp_true_5:
  mov rax, 0x2
temp_end_6:
  cmp rax, 0
  je near temp_else_3
  mov rax, 3
  jmp near temp_end_4
temp_else_3:
  mov rax, [rsp + 8]
  mov [rsp  -8], rax
  mov rax, 3
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
  mov [rsp  -8], rax
  sub rsp, 8
  call fibonacci_func
  add rsp, 8
  mov [rsp  -8], rax
  mov rax, [rsp + 8]
  mov [rsp  -16], rax
  mov rax, 5
  mov [rsp  -24], rax
  mov rax, [rsp  -16]
  mov rbx, [rsp  -24]
  sar rax, 1
  sar rbx, 1
  sub rax, rbx
  jo near internal_error_overflow
  shl rax, 1
  jo near internal_error_overflow
  add rax, 1
  mov [rsp  -16], rax
  sub rsp, 16
  call fibonacci_func
  add rsp, 16
  mov [rsp  -16], rax
  mov rax, [rsp  -8]
  mov rbx, [rsp  -16]
  sar rax, 1
  sar rbx, 1
  add rax, rbx
  jo near internal_error_overflow
  shl rax, 1
  jo near internal_error_overflow
  add rax, 1
temp_end_4:
temp_end_2:
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
  call fibonacci_func
  add rsp, 16
  pop rbx
ret


