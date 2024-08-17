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

  mov rax, -5   ; if comparison is folded and eliminated
  mov rdi, rax  ; all calculations are eliminated
  sub rsp, 32
  call print    ; just call print
  add rsp, 32
  pop rbx
ret


