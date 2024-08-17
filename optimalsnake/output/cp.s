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

  mov rax, 11
  mov [rsp  -16], rax ; x @ -16
  mov rax, 11         ; no need to fetch x
  mov rdi, rax
  sub rsp, 32
  call print
  add rsp, 32
  mov rax, 11         ; no need to fetch x
  mov [rsp  -24], rax ; y @ -24
  mov rax, 11         ; no need to fetch y
  mov rdi, rax
  sub rsp, 48
  call print
  add rsp, 48
  mov rax, 9
  mov [rsp  -32], rax ; x is shadowed, new x @ -32
  mov rax, 11         ; no need to fetch the old x!
  mov [rsp  -40], rax ; y is shadowed, new y @ -40
  mov rax, 7
  mov [rsp  -48], rax ; z @ -48
  mov rax, 9          ; no need to fetch the new x
  mov rdi, rax
  sub rsp, 64
  call print
  add rsp, 64
  mov rax, 7          ; no need to fetch z yet
  mov rdi, rax
  sub rsp, 64
  call print
  add rsp, 64
  mov rax, 5
  mov [rsp  -48], rax ; set z 3
  mov rax, [rsp  -48] ; z was modified, so fetch it
  mov rdi, rax
  sub rsp, 64
  call print
  add rsp, 64
  mov rax, 11         ; no need to fetch the old x!
  mov rdi, rax        ; even though it was shadowed!
  sub rsp, 32
  call print
  add rsp, 32
  pop rbx
ret


