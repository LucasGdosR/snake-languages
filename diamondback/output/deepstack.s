  section .text
  extern error
  extern print
  global our_code_starts_here

shallow_stack_func:
  mov rax, [rsp + 8]
  ret
regular_stack_func:
  mov rax, [rsp + 16]
  ret
deep_stack_func:
  mov rax, [rsp + 16]
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
  call shallow_stack_func
  add rsp, 16
  mov [rsp  -16], rax
  mov rax, [rsp  -8]
  mov [rsp  -24], rax
  sub rsp, 24
  call regular_stack_func
  add rsp, 24
  mov [rsp  -16], rax
  mov rax, [rsp  -8]
  mov [rsp  -24], rax
  mov rax, [rsp  -8]
  mov [rsp  -32], rax
  sub rsp, 32
  call deep_stack_func
  add rsp, 32
  mov [rsp  -16], rax
  mov rax, [rsp  -8]
  mov [rsp  -24], rax
  mov rax, [rsp  -8]
  mov [rsp  -32], rax
  sub rsp, 32
  call deep_stack_func
  add rsp, 32
  mov [rsp  -16], rax
  mov rax, [rsp  -8]
  mov [rsp  -24], rax
  mov rax, [rsp  -8]
  mov [rsp  -32], rax
  sub rsp, 32
  call deep_stack_func
  add rsp, 32
  pop rbx
ret


