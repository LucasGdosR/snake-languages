  section .text
  extern error
  extern print
  global our_code_starts_here

make_point_func:
  mov rax, 5
  sar rax, 1
  cmp rax, 0
  jl near internal_error_negative_array
  mov rbx, rax
  mov rax, r15
  mov [r15 + 0], rbx
  shl rbx, 3
  add r15, rbx
  add r15, 8
  mov [rsp  -8], rax
  mov rax, [rsp  -8]
  mov [rsp  -16], rax
  and rax, 7
  cmp rax, 0
  jne near internal_error_not_a_pointer
  mov rax, 1
  sar rax, 1
  cmp rax, 0
  jl near internal_error_out_of_bounds
  mov rbx, [rsp  -16]
  cmp rax, [rbx + 0]
  jge near internal_error_out_of_bounds
  add rax, 1
  shl rax, 3
  add rax, rbx
  mov [rsp  -16], rax
  mov rax, [rsp + 16]
  mov rbx, [rsp  -16]
  mov [rbx + 0], rax
  mov rax, [rsp  -8]
  mov [rsp  -16], rax
  and rax, 7
  cmp rax, 0
  jne near internal_error_not_a_pointer
  mov rax, 3
  sar rax, 1
  cmp rax, 0
  jl near internal_error_out_of_bounds
  mov rbx, [rsp  -16]
  cmp rax, [rbx + 0]
  jge near internal_error_out_of_bounds
  add rax, 1
  shl rax, 3
  add rax, rbx
  mov [rsp  -16], rax
  mov rax, [rsp + 8]
  mov rbx, [rsp  -16]
  mov [rbx + 0], rax
  mov rax, [rsp  -8]
  ret
add_vectors_func:
  mov rax, 5
  sar rax, 1
  cmp rax, 0
  jl near internal_error_negative_array
  mov rbx, rax
  mov rax, r15
  mov [r15 + 0], rbx
  shl rbx, 3
  add r15, rbx
  add r15, 8
  mov [rsp  -8], rax
  mov rax, [rsp  -8]
  mov [rsp  -16], rax
  and rax, 7
  cmp rax, 0
  jne near internal_error_not_a_pointer
  mov rax, 1
  sar rax, 1
  cmp rax, 0
  jl near internal_error_out_of_bounds
  mov rbx, [rsp  -16]
  cmp rax, [rbx + 0]
  jge near internal_error_out_of_bounds
  add rax, 1
  shl rax, 3
  add rax, rbx
  mov [rsp  -16], rax
  mov rax, [rsp + 16]
  mov [rsp  -24], rax
  and rax, 7
  cmp rax, 0
  jne near internal_error_not_a_pointer
  mov rax, 1
  sar rax, 1
  cmp rax, 0
  jl near internal_error_out_of_bounds
  mov rbx, [rsp  -24]
  cmp rax, [rbx + 0]
  jge near internal_error_out_of_bounds
  add rax, 1
  mov rax, [rbx + rax * 8]
  mov [rsp  -24], rax
  mov rax, [rsp + 8]
  mov [rsp  -32], rax
  and rax, 7
  cmp rax, 0
  jne near internal_error_not_a_pointer
  mov rax, 1
  sar rax, 1
  cmp rax, 0
  jl near internal_error_out_of_bounds
  mov rbx, [rsp  -32]
  cmp rax, [rbx + 0]
  jge near internal_error_out_of_bounds
  add rax, 1
  mov rax, [rbx + rax * 8]
  mov [rsp  -32], rax
  mov rax, [rsp  -24]
  mov rbx, [rsp  -32]
  sar rax, 1
  sar rbx, 1
  add rax, rbx
  jo near internal_error_overflow
  shl rax, 1
  jo near internal_error_overflow
  add rax, 1
  mov rbx, [rsp  -16]
  mov [rbx + 0], rax
  mov rax, [rsp  -8]
  mov [rsp  -16], rax
  and rax, 7
  cmp rax, 0
  jne near internal_error_not_a_pointer
  mov rax, 3
  sar rax, 1
  cmp rax, 0
  jl near internal_error_out_of_bounds
  mov rbx, [rsp  -16]
  cmp rax, [rbx + 0]
  jge near internal_error_out_of_bounds
  add rax, 1
  shl rax, 3
  add rax, rbx
  mov [rsp  -16], rax
  mov rax, [rsp + 16]
  mov [rsp  -24], rax
  and rax, 7
  cmp rax, 0
  jne near internal_error_not_a_pointer
  mov rax, 3
  sar rax, 1
  cmp rax, 0
  jl near internal_error_out_of_bounds
  mov rbx, [rsp  -24]
  cmp rax, [rbx + 0]
  jge near internal_error_out_of_bounds
  add rax, 1
  mov rax, [rbx + rax * 8]
  mov [rsp  -24], rax
  mov rax, [rsp + 8]
  mov [rsp  -32], rax
  and rax, 7
  cmp rax, 0
  jne near internal_error_not_a_pointer
  mov rax, 3
  sar rax, 1
  cmp rax, 0
  jl near internal_error_out_of_bounds
  mov rbx, [rsp  -32]
  cmp rax, [rbx + 0]
  jge near internal_error_out_of_bounds
  add rax, 1
  mov rax, [rbx + rax * 8]
  mov [rsp  -32], rax
  mov rax, [rsp  -24]
  mov rbx, [rsp  -32]
  sar rax, 1
  sar rbx, 1
  add rax, rbx
  jo near internal_error_overflow
  shl rax, 1
  jo near internal_error_overflow
  add rax, 1
  mov rbx, [rsp  -16]
  mov [rbx + 0], rax
  mov rax, [rsp  -8]
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
  mov rax, 11
  mov [rsp  -24], rax
  sub rsp, 24
  call make_point_func
  add rsp, 24
  mov [rsp  -16], rax
  mov rax, 5
  mov [rsp  -32], rax
  mov rax, 7
  mov [rsp  -40], rax
  sub rsp, 40
  call make_point_func
  add rsp, 40
  mov [rsp  -24], rax
  mov rax, -5
  mov [rsp  -32], rax
  mov rax, 21
  mov [rsp  -40], rax
  sub rsp, 40
  call make_point_func
  add rsp, 40
  mov [rsp  -32], rax
  mov rax, [rsp  -16]
  mov [rsp  -48], rax
  mov rax, [rsp  -24]
  mov [rsp  -56], rax
  sub rsp, 56
  call add_vectors_func
  add rsp, 56
  mov rdi, rax
  sub rsp, 48
  call print
  add rsp, 48
  mov rax, [rsp  -16]
  mov [rsp  -48], rax
  mov rax, [rsp  -32]
  mov [rsp  -56], rax
  sub rsp, 56
  call add_vectors_func
  add rsp, 56
  mov rdi, rax
  sub rsp, 48
  call print
  add rsp, 48
  mov rax, [rsp  -24]
  mov [rsp  -48], rax
  mov rax, [rsp  -32]
  mov [rsp  -56], rax
  sub rsp, 56
  call add_vectors_func
  add rsp, 56
  mov rdi, rax
  sub rsp, 48
  call print
  add rsp, 48
  mov rax, [rsp  -32]
  mov [rsp  -48], rax
  mov rax, [rsp  -16]
  mov [rsp  -56], rax
  sub rsp, 56
  call add_vectors_func
  add rsp, 56
  mov rdi, rax
  sub rsp, 48
  call print
  add rsp, 48
  mov rax, [rsp  -32]
  mov [rsp  -48], rax
  mov rax, [rsp  -24]
  mov [rsp  -56], rax
  sub rsp, 56
  call add_vectors_func
  add rsp, 56
  pop rbx
ret


