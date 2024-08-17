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

  mov rax, 7
  mov [rsp  -16], rax
  mov rax, 7
  pop rbx
ret


