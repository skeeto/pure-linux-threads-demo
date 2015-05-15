;; Pure assembly, library-free Linux threading demo
bits 64
global _start

;; sys/syscall.h
%define SYS_write	1
%define SYS_mmap	9
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

;; sys/mman.h
%define MAP_GROWSDOWN	0x0100
%define MAP_ANONYMOUS	0x0020
%define MAP_PRIVATE	0x0002
%define PROT_READ	0x1
%define PROT_WRITE	0x2
%define PROT_EXEC	0x4

%define THREAD_FLAGS \
 CLONE_VM|CLONE_FS|CLONE_FILES|CLONE_SIGHAND|CLONE_PARENT|CLONE_THREAD|CLONE_IO

%define STACK_SIZE	(4096 * 1024)

%define MAX_LINES	1000000	; number of output lines before exiting

section .data
count:	dq MAX_LINES

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
	mov rax, -1
	lock xadd [count], rax
	jl .exit
	ret
.exit	mov rdi, 0
	mov rax, SYS_exit
	syscall

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

;; long thread_create(void (*)(void))
thread_create:
	push rdi
	call stack_create
	lea rsi, [rax + STACK_SIZE - 8]
	pop qword [rsi]
	mov rdi, THREAD_FLAGS
	mov rax, SYS_clone
	syscall
	ret

;; void *stack_create(void)
stack_create:
	mov rdi, 0
	mov rsi, STACK_SIZE
	mov rdx, PROT_WRITE | PROT_READ
	mov r10, MAP_ANONYMOUS | MAP_PRIVATE | MAP_GROWSDOWN
	mov rax, SYS_mmap
	syscall
	ret
