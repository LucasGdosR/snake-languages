  section .text
  extern error
  extern print
  global our_code_starts_here

make_node_with_val_func:
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
  ret
add_element_at_beginning_func:
  mov rax, [rsp + 8]
  mov [rsp  -8], rax
  sub rsp, 8
  call make_node_with_val_func
  add rsp, 8
  mov [rsp  -8], rax
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
  mov rbx, [rsp  -16]
  mov [rbx + 0], rax
  mov rax, [rsp  -8]
  ret
add_element_at_end_func:
  mov rax, [rsp + 8]
  mov [rsp  -8], rax
  sub rsp, 8
  call make_node_with_val_func
  add rsp, 8
  mov [rsp  -8], rax
  mov rax, [rsp + 16]
  mov [rsp  -16], rax
temp_while_test_1:
  mov rax, [rsp  -16]
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
  mov rbx, 0x2
  cmp rax, 0
  jne near temp_false_5
  add rbx, 4
temp_false_5:
  mov rax, rbx
  cmp rax, 0x2
  je near temp_else_3
  mov rax, 0x2
  jmp near temp_end_4
temp_else_3:
  mov rax, 0x6
temp_end_4:
  cmp rax, 0x6
  jne near temp_end_2
  mov rax, [rsp  -16]
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
  mov [rsp  -16], rax
  jmp near temp_while_test_1
temp_end_2:
  mov rax, [rsp  -16]
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
  shl rax, 3
  add rax, rbx
  mov [rsp  -24], rax
  mov rax, [rsp  -8]
  mov rbx, [rsp  -24]
  mov [rbx + 0], rax
  mov rax, [rsp + 16]
  ret
get_e_at_i_func:
  mov rax, [rsp + 16]
  mov [rsp  -8], rax
  mov rax, 1
  mov [rsp  -16], rax
temp_while_test_6:
  mov rax, [rsp  -16]
  mov [rsp  -24], rax
  mov rax, [rsp + 8]
  mov [rsp  -32], rax
  mov rax, [rsp  -24]
  mov rbx, [rsp  -32]
  cmp rax, rbx
  jl near temp_true_8
  mov rax, 0x2
  jmp near temp_end_9
temp_true_8:
  mov rax, 0x6
temp_end_9:
  cmp rax, 0x6
  jne near temp_end_7
  mov rax, [rsp  -16]
  add rax, 2
  jo near internal_error_overflow
  mov [rsp  -16], rax
  mov rax, [rsp  -8]
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
  mov [rsp  -8], rax
  jmp near temp_while_test_6
temp_end_7:
  mov rax, [rsp  -8]
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
  ret
range_func:
  mov rax, 1
  mov [rsp  -8], rax
  mov rax, 1
  mov [rsp  -24], rax
  sub rsp, 24
  call make_node_with_val_func
  add rsp, 24
  mov [rsp  -16], rax
  mov rax, [rsp  -16]
  mov [rsp  -24], rax
temp_while_test_10:
  mov rax, [rsp  -8]
  mov [rsp  -32], rax
  mov rax, [rsp + 8]
  mov [rsp  -40], rax
  mov rax, [rsp  -32]
  mov rbx, [rsp  -40]
  cmp rax, rbx
  jl near temp_true_12
  mov rax, 0x2
  jmp near temp_end_13
temp_true_12:
  mov rax, 0x6
temp_end_13:
  cmp rax, 0x6
  jne near temp_end_11
  mov rax, [rsp  -8]
  add rax, 2
  jo near internal_error_overflow
  mov [rsp  -8], rax
  mov rax, [rsp  -24]
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
  shl rax, 3
  add rax, rbx
  mov [rsp  -32], rax
  mov rax, [rsp  -8]
  mov [rsp  -40], rax
  sub rsp, 40
  call make_node_with_val_func
  add rsp, 40
  mov rbx, [rsp  -32]
  mov [rbx + 0], rax
  mov rax, [rsp  -24]
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
  mov [rsp  -24], rax
  jmp near temp_while_test_10
temp_end_11:
  mov rax, [rsp  -16]
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

  mov rax, 11
  mov [rsp  -24], rax
  sub rsp, 24
  call range_func
  add rsp, 24
  mov [rsp  -16], rax
  mov rax, 5
  mov [rsp  -24], rax
  sub rsp, 24
  call add_element_at_end_func
  add rsp, 24
  mov [rsp  -16], rax
  mov rax, 7
  mov [rsp  -24], rax
  sub rsp, 24
  call add_element_at_beginning_func
  add rsp, 24
  mov [rsp  -16], rax
  mov rax, [rsp  -8]
  mov [rsp  -24], rax
  sub rsp, 24
  call get_e_at_i_func
  add rsp, 24
  pop rbx
ret


