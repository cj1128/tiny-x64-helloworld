section .data
message: db "hello, world", 0xa

section .text

global nomain
nomain:
  mov rax, 1
  mov rdi, 1
  mov rsi, message
  mov rdx, 13
  syscall
  mov rax, 60
  xor rdi, rdi
  syscall
