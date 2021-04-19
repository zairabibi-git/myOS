global start
extern long_mode_start

section .text
bits 32
start:
	mov esp, stack_top

	;subroutines
	call check_multiboot
	call check_cpuid
	call check_long_mode
	
	; we need to implement virtual memory 
	; in order to enter 64-bit long mode
	; this can be done through paging

	; paging allows us to map virtual addresses to physical addresses
	call setup_page_tables
	call enable_paging

	; loading the global derscriptor table
	lgdt [gdt64.pointer]

	; load code segment into code selector
	jmp gdt64.code_segment:long_mode_start

	hlt

check_multiboot:
	cmp eax, 0x36d76289
	jne .no_multiboot
	ret
.no_multiboot:
	mov al, "M"		; error code for no Multiboot
	jmp error

check_cpuid:
	pushfd			; push all flag registers onto the stack
	pop eax
	mov ecx, eax	; make a copy of eax in ecx to compare
	xor eax, 1 << 21	; flipping bit 21
	push eax		; push onto stack
	popfd			; copy into flag registers
	pushfd
	pop eax			; copy flags back into eax
	push ecx
	popfd			; doing this so the flags remain whatever they were before this subroutine
	
	cmp eax, ecx
	;if they match, then cpu has not allowed us to flip bit 21
	;which means that the cpu id is not available
	je .no_cpuid
	ret
.no_cpuid:
	mov al, "C"		; error code for no CPU ID
	jmp error

check_long_mode:
	mov eax, 0x80000000
	cpuid
	; cpuid returns a number in eax
	; if eax>0x80000000, then the cpu supports extended processor information
	; which n turn means that it supports long mode
	cmp eax, 0x80000001
	jb .no_long_mode	; if eax<0x80000000, it means no long mode support

	; otherwise we can use extended processor information to check for long mode
	mov eax, 0x80000001
	cpuid
	; cpuid will store a value in edx
	; if lm bit is set, then long mode is available
	; lm bit is bit 29
	test edx, 1 << 29
	jz .no_long_mode
	
	ret
.no_long_mode:
	mov al, "L"		; error code for no long mode
	jmp error

; subroutine for setting up page table
setup_page_tables:
	;doing identity mapping 
	;i.e. mapping physical address to the exact same physical address
	mov eax, page_table_l3
	or eax, 0b11 ; enabling present and writeable flags
	mov [page_table_l4], eax 	; set eax as the first entry of l4
	
	mov eax, page_table_l2
	or eax, 0b11 ; present, writable
	mov [page_table_l3], eax	; set eax as the first entry of l3

	mov ecx, 0 ; counter

; loop
.loop:

	mov eax, 0x200000 ; 2MiB
	mul ecx			  ; multiplying eax value with ecx gives the correct address of next page
	or eax, 0b10000011 ; present, writable, huge page
	mov [page_table_l2 + ecx * 8], eax

	inc ecx ; increment counter
	cmp ecx, 512 ; checks if the whole table is mapped
	jne .loop ; if not, continue

	ret

enable_paging:
	; pass page table loction to cpu
	; the cpu looks for address in the cr3 register
	mov eax, page_table_l4
	mov cr3, eax	; copy the address into cr3

	; enable physical address extension (PAE)
	; necessary for 64-bit paging
	; can be done by enabling PAE flag in cr4 (5th bit)
	mov eax, cr4
	or eax, 1 << 5
	mov cr4, eax

	; enable long mode
	; we'll work with model specific registers
	mov ecx, 0xC0000080
	rdmsr	; read model specific register
	; enable lng mode flag (bit 8)
	or eax, 1 << 8
	wrmsr	; write back into model specific registers

	; enable paging
	mov eax, cr0
	or eax, 1 << 31
	mov cr0, eax

	ret

error:
	; print "ERR: X" where X is the error code
	mov dword [0xb8000], 0x4f524f45
	mov dword [0xb8004], 0x4f3a4f52
	mov dword [0xb8008], 0x4f204f20
	mov byte  [0xb800a], al
	hlt

section .bss
; reserving memory for page tables
; each table is of size 4 KB
align 4096
; page tables has 4 levels: l1, l2, l3 and l4
page_table_l4:
	resb 4096
page_table_l3:
	resb 4096
page_table_l2:
	resb 4096
stack_bottom:
	resb 4096 * 4
stack_top:

; to convert from 32-bit compatibility sub mode to 64-bit mode
; we will create a 64-bit global decriptor table
; create a read-only data section 
section .rodata
gdt64:
	dq 0 ; zero entry
.code_segment: equ $ - gdt64
	; code segment, in here we will enable executable flag,
	; set the descriptor type to 1,
	; enable the present flag,
	; and also enable the 64-bit flag
	dq (1 << 43) | (1 << 44) | (1 << 47) | (1 << 53) ; code segment
.pointer:
	dw $ - gdt64 - 1 ; length
	dq gdt64 ; address
