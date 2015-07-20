;conventional registers used for entering kernel mode.
;       arch/ABI   instruction          syscall #   retval Notes
;       ───────────────────────────────────────────────────────────────────
;
;       i386       int $0x80            eax         eax
;       x86_64     syscall              rax         rax

;conventional register mapping for syscall arguments
;       arch/ABI   arg1   arg2   arg3   arg4   arg5   arg6   arg7
;       ──────────────────────────────────────────────────────────
;       i386       ebx    ecx    edx    esi    edi    ebp    -
;       x86_64     rdi    rsi    rdx    r10    r8     r9     -


;; Pure assembly, library-free Linux threading demo
bits 32
global _start

;; sys/syscall.h
%define SYS_write	4
%define SYS_mmap2	192
%define SYS_clone	120
%define SYS_exit	1

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
	mov ebx, threadfn
	call thread_create
	mov ebx, threadfn
	call thread_create

.loop:	call check_count
	mov ebx, .hello
	call puts
	mov ebx, 0
	jmp .loop

.hello:	db `Hello from \e[93;1mmain\e[0m!\n\0`

;; void threadfn(void)
threadfn:
	call check_count
	mov ebx, .hello
	call puts
	jmp threadfn
.hello:	db `Hello from \e[91;1mthread\e[0m!\n\0`

;; void check_count(void) -- may not return
check_count:
	mov eax, -1
	lock xadd [count], eax
	jl .exit
	ret
.exit	mov ebx, 0
	mov eax, SYS_exit
	int 0x80

;; void puts(char *)
puts:
	mov ecx, ebx
	mov edx, -1
.count:	inc edx
	cmp byte [ecx + edx], 0
	jne .count
	mov ebx, STDOUT
	mov eax, SYS_write
	int 0x80
	ret

;; long thread_create(void (*)(void))
thread_create:
	push ebx
	call stack_create
	lea ecx, [eax + STACK_SIZE - 8]
	pop dword [ecx]
	mov ebx, THREAD_FLAGS
	mov eax, SYS_clone
	int 0x80
	ret

;; void *stack_create(void)
stack_create:
	mov ebx, 0
	mov ecx, STACK_SIZE
	mov edx, PROT_WRITE | PROT_READ
	mov esi, MAP_ANONYMOUS | MAP_PRIVATE | MAP_GROWSDOWN
	mov eax, SYS_mmap2
	int 0x80
	ret
