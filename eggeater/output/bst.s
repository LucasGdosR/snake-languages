  section .text
  extern error
  extern print
  global our_code_starts_here

make_node_func:
  mov rax, 7
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
  mov rax, [rsp + 8]
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
  mov rax, 0
  mov rbx, [rsp  -16]
  mov [rbx + 0], rax
  mov rax, [rsp  -8]
  mov [rsp  -16], rax
  and rax, 7
  cmp rax, 0
  jne near internal_error_not_a_pointer
  mov rax, 5
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
  mov rax, 0
  mov rbx, [rsp  -16]
  mov [rbx + 0], rax
  mov rax, [rsp  -8]
  ret
val_func:
  mov rax, [rsp + 8]
  mov [rsp  -8], rax
  and rax, 7
  cmp rax, 0
  jne near internal_error_not_a_pointer
  mov rax, 1
  sar rax, 1
  cmp rax, 0
  jl near internal_error_out_of_bounds
  mov rbx, [rsp  -8]
  cmp rax, [rbx + 0]
  jge near internal_error_out_of_bounds
  add rax, 1
  mov rax, [rbx + rax * 8]
  ret
left_func:
  mov rax, [rsp + 8]
  mov [rsp  -8], rax
  and rax, 7
  cmp rax, 0
  jne near internal_error_not_a_pointer
  mov rax, 3
  sar rax, 1
  cmp rax, 0
  jl near internal_error_out_of_bounds
  mov rbx, [rsp  -8]
  cmp rax, [rbx + 0]
  jge near internal_error_out_of_bounds
  add rax, 1
  mov rax, [rbx + rax * 8]
  ret
right_func:
  mov rax, [rsp + 8]
  mov [rsp  -8], rax
  and rax, 7
  cmp rax, 0
  jne near internal_error_not_a_pointer
  mov rax, 5
  sar rax, 1
  cmp rax, 0
  jl near internal_error_out_of_bounds
  mov rbx, [rsp  -8]
  cmp rax, [rbx + 0]
  jge near internal_error_out_of_bounds
  add rax, 1
  mov rax, [rbx + rax * 8]
  ret
add_private_func:
  mov rax, 1
  mov [rsp  -8], rax
  mov rax, [rsp + 8]
  mov [rsp  -24], rax
  sub rsp, 24
  call val_func
  add rsp, 24
  mov [rsp  -16], rax
  mov rax, [rsp + 16]
  mov [rsp  -24], rax
  sub rsp, 24
  call val_func
  add rsp, 24
  mov [rsp  -24], rax
  mov rax, [rsp  -16]
  mov rbx, [rsp  -24]
  cmp rax, rbx
  jl near temp_true_9
  mov rax, 0x2
  jmp near temp_end_10
temp_true_9:
  mov rax, 0x6
temp_end_10:
  cmp rax, 0x2
  je near temp_else_1
  mov rax, [rsp + 16]
  mov [rsp  -24], rax
  sub rsp, 24
  call left_func
  add rsp, 24
  mov rbx, 0x2
  cmp rax, 0
  jne near temp_false_8
  add rbx, 4
temp_false_8:
  mov rax, rbx
  cmp rax, 0x2
  je near temp_else_6
  mov rax, [rsp + 16]
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
  jmp near temp_end_7
temp_else_6:
  mov rax, [rsp + 16]
  mov [rsp  -24], rax
  sub rsp, 24
  call left_func
  add rsp, 24
  mov [rsp  -16], rax
  mov rax, [rsp + 8]
  mov [rsp  -24], rax
  sub rsp, 24
  call add_private_func
  add rsp, 24
temp_end_7:
  jmp near temp_end_2
temp_else_1:
  mov rax, [rsp + 16]
  mov [rsp  -24], rax
  sub rsp, 24
  call right_func
  add rsp, 24
  mov rbx, 0x2
  cmp rax, 0
  jne near temp_false_5
  add rbx, 4
temp_false_5:
  mov rax, rbx
  cmp rax, 0x2
  je near temp_else_3
  mov rax, [rsp + 16]
  mov [rsp  -16], rax
  and rax, 7
  cmp rax, 0
  jne near internal_error_not_a_pointer
  mov rax, 5
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
  jmp near temp_end_4
temp_else_3:
  mov rax, [rsp + 16]
  mov [rsp  -24], rax
  sub rsp, 24
  call right_func
  add rsp, 24
  mov [rsp  -16], rax
  mov rax, [rsp + 8]
  mov [rsp  -24], rax
  sub rsp, 24
  call add_private_func
  add rsp, 24
temp_end_4:
temp_end_2:
  ret
add_func:
  mov rax, [rsp + 8]
  mov [rsp  -8], rax
  sub rsp, 8
  call make_node_func
  add rsp, 8
  mov [rsp  -8], rax
  mov rax, [rsp + 16]
  mov rbx, 0x2
  cmp rax, 0
  jne near temp_false_13
  add rbx, 4
temp_false_13:
  mov rax, rbx
  cmp rax, 0x2
  je near temp_else_11
  mov rax, [rsp  -8]
  jmp near temp_end_12
temp_else_11:
  mov rax, [rsp + 16]
  mov [rsp  -16], rax
  mov rax, [rsp  -8]
  mov [rsp  -24], rax
  sub rsp, 24
  call add_private_func
  add rsp, 24
temp_end_12:
  mov rax, [rsp + 16]
  ret
has_func:
  mov rax, [rsp + 16]
  mov rbx, 0x2
  cmp rax, 0
  jne near temp_false_24
  add rbx, 4
temp_false_24:
  mov rax, rbx
  cmp rax, 0x2
  je near temp_else_14
  mov rax, 0x2
  jmp near temp_end_15
temp_else_14:
  mov rax, [rsp + 16]
  mov [rsp  -8], rax
  sub rsp, 8
  call val_func
  add rsp, 8
  mov [rsp  -8], rax
  mov rax, [rsp + 8]
  mov [rsp  -16], rax
  mov rax, [rsp  -8]
  mov [rsp  -24], rax
  mov rax, [rsp  -16]
  mov rbx, [rsp  -24]
  cmp rax, rbx
  je near temp_true_22
  mov rax, 0x2
  jmp near temp_end_23
temp_true_22:
  mov rax, 0x6
temp_end_23:
  cmp rax, 0x2
  je near temp_else_16
  mov rax, 0x6
  jmp near temp_end_17
temp_else_16:
  mov rax, [rsp + 8]
  mov [rsp  -16], rax
  mov rax, [rsp  -8]
  mov [rsp  -24], rax
  mov rax, [rsp  -16]
  mov rbx, [rsp  -24]
  cmp rax, rbx
  jl near temp_true_20
  mov rax, 0x2
  jmp near temp_end_21
temp_true_20:
  mov rax, 0x6
temp_end_21:
  cmp rax, 0x2
  je near temp_else_18
  mov rax, [rsp + 16]
  mov [rsp  -24], rax
  sub rsp, 24
  call left_func
  add rsp, 24
  mov [rsp  -16], rax
  mov rax, [rsp + 8]
  mov [rsp  -24], rax
  sub rsp, 24
  call has_func
  add rsp, 24
  jmp near temp_end_19
temp_else_18:
  mov rax, [rsp + 16]
  mov [rsp  -24], rax
  sub rsp, 24
  call right_func
  add rsp, 24
  mov [rsp  -16], rax
  mov rax, [rsp + 8]
  mov [rsp  -24], rax
  sub rsp, 24
  call has_func
  add rsp, 24
temp_end_19:
temp_end_17:
temp_end_15:
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

  mov rax, 1
  mov [rsp  -24], rax
  sub rsp, 24
  call make_node_func
  add rsp, 24
  mov [rsp  -16], rax
  mov rax, [rsp  -16]
  mov rdi, rax
  sub rsp, 32
  call print
  add rsp, 32
  mov rax, [rsp  -16]
  mov [rsp  -32], rax
  mov rax, 5
  mov [rsp  -40], rax
  sub rsp, 40
  call has_func
  add rsp, 40
  mov rdi, rax
  sub rsp, 32
  call print
  add rsp, 32
  mov rax, [rsp  -16]
  mov [rsp  -32], rax
  mov rax, 5
  mov [rsp  -40], rax
  sub rsp, 40
  call add_func
  add rsp, 40
  mov rdi, rax
  sub rsp, 32
  call print
  add rsp, 32
  mov rax, [rsp  -16]
  mov [rsp  -32], rax
  mov rax, 5
  mov [rsp  -40], rax
  sub rsp, 40
  call has_func
  add rsp, 40
  mov rdi, rax
  sub rsp, 32
  call print
  add rsp, 32
  mov rax, [rsp  -16]
  mov [rsp  -32], rax
  mov rax, 3
  mov [rsp  -40], rax
  sub rsp, 40
  call add_func
  add rsp, 40
  mov rdi, rax
  sub rsp, 32
  call print
  add rsp, 32
  mov rax, [rsp  -16]
  mov [rsp  -32], rax
  mov rax, -3
  mov [rsp  -40], rax
  sub rsp, 40
  call add_func
  add rsp, 40
  mov rdi, rax
  sub rsp, 32
  call print
  add rsp, 32
  mov rax, [rsp  -16]
  mov [rsp  -32], rax
  mov rax, -1
  mov [rsp  -40], rax
  sub rsp, 40
  call add_func
  add rsp, 40
  mov rdi, rax
  sub rsp, 32
  call print
  add rsp, 32
  mov rax, [rsp  -16]
  mov [rsp  -32], rax
  mov rax, -5
  mov [rsp  -40], rax
  sub rsp, 40
  call add_func
  add rsp, 40
  mov rdi, rax
  sub rsp, 32
  call print
  add rsp, 32
  mov rax, [rsp  -16]
  mov [rsp  -32], rax
  mov rax, 7
  mov [rsp  -40], rax
  sub rsp, 40
  call add_func
  add rsp, 40
  pop rbx
ret


