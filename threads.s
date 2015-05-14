;; Pure assembly, no stdlib, Linux threading demo
bits 64
default rel
global _start

;; sys/syscall.h
%define SYS_write	1
%define SYS_brk		12
%define SYS_clone	56
%define SYS_exit	60

;; unistd.h
%define STDIN		0
%define STDOUT		1
%define STDERR		2

;; sched.h
%define CLONE_VM	0x00000100
%define CLONE_FS	0x00000200
%define CLONE_FILES	0x00000400
%define CLONE_SIGHAND	0x00000800
%define CLONE_PARENT	0x00008000
%define CLONE_THREAD	0x00010000
%define CLONE_IO	0x80000000

%define THREAD_FLAGS \
 CLONE_VM|CLONE_FS|CLONE_FILES|CLONE_SIGHAND|CLONE_PARENT|CLONE_THREAD|CLONE_IO

%define STACK_SIZE	(4096 * 1024)

%define MAX_LINES	1000000	; number of output lines before exiting

section .bss
count:	resq 1

section .text
_start:
	; Spawn a few threads
	mov rdi, threadfn
	call thread_create
	mov rdi, threadfn
	call thread_create

.loop:	call check_count
	mov rdi, .hello
	call puts
	mov rdi, 0
	jmp .loop

.hello:	db `Hello from \e[93;1mmain\e[0m!\n\0`

;; void threadfn(void)
threadfn:
	call check_count
	mov rdi, .hello
	call puts
	jmp threadfn
.hello:	db `Hello from \e[91;1mthread\e[0m!\n\0`

;; void check_count(void) -- may not return
check_count:
	mov rax, 1
	lock xadd [count], rax
.check:	cmp rax, MAX_LINES
	jge .exit
	ret
.exit	mov rdi, 0
	jmp exit

;; void puts(char *)
puts:
	mov rsi, rdi
	mov rdx, -1
.count:	inc rdx
	cmp byte [rsi + rdx], 0
	jne .count
	mov rdi, STDOUT
	mov rax, SYS_write
	syscall
	ret

;; void thread_create(void (*)(void))
thread_create:
	push rdi
	mov rdi, STACK_SIZE
	call sbrk
	lea rsi, [rax + STACK_SIZE - 8]
	pop rcx
	mov [rsi], rcx
	mov rdi, THREAD_FLAGS
	mov rax, SYS_clone
	syscall
	ret

;; noreturn exit(int)
exit:
	mov rax, SYS_exit
	syscall

;; void *sbrk(size_t)
sbrk:
	push rdi
	xor rdi, rdi
	mov rax, SYS_brk
	syscall			; get current brk
	pop rdi
	add rdi, rax
	push rax
	mov rax, SYS_brk
	syscall
	pop rax
	ret
