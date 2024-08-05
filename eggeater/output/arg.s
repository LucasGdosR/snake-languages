  section .text
  extern error
  extern print
  global our_code_starts_here

f_func:
  mov rax, [rsp + 8]
  mov rdi, rax
  sub rsp, 16
  call print
  add rsp, 16
  ret
internal_error_overflow:
  mov rdi, 1
  push 0
  call error
internal_error_out_of_bounds:
  mov rdi, 2
  push 0
  call error
internal_error_negative_array:
  mov rdi, 3
  push 0
  call error
internal_error_not_a_pointer:
  mov rdi, 4
  push 0
  call error
our_code_starts_here:
push rbx
  mov r15, rdi
  mov [rsp - 8], rsi

  mov rax, 3
  mov [rsp  -16], rax
  mov rax, 5
  mov [rsp  -24], rax
  sub rsp, 24
  call f_func
  add rsp, 24
  pop rbx
ret


