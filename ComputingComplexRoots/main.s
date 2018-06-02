section .data
get_epsilon:
        db "epsilon = %lf", 10,0
get_order:
        db "order = %d", 10,0
get_coeff:
        db "coeff %d = %lf %lf", 10,0
get_initial:
        db "initial = %lf %lf", 10,0
print_root:
	db "root = %.17g %.17g", 10, 0
fs_malloc_failed:
	db "A call to malloc() failed", 10, 0
zero:
	dq 0.0
one:
	dq 1.0


section .bss
epsilon: resq 1
order: resq 1
coeff_index: resq 1
coeff_real: resq 1
coeff_img: resq 1
initial_real: resq 1
initial_img: resq 1
rarray: resq 1
iarray: resq 1
d_rarray: resq 1
d_iarray: resq 1
tmp: resq 1
f_xR: resq 1
f_xI: resq 1
df_xR: resq 1
df_xI: resq 1
initr_power: resq 1
initi_power: resq 1
resultr: resq 1
resulti: resq 1
	
extern printf, scanf, calloc, free
global main
section .text
main:
	finit
	enter 0, 0
	
	mov rdi, get_epsilon
	mov rsi, epsilon
	mov rax, 0
	call scanf

	mov rdi, get_order
	mov rsi, order
	mov rax, 0
	call scanf
	
	mov rdi, qword [order]
	inc rdi
	mov rsi, 8
	call calloc
	cmp rax, 0
	je .malloc_failed
	mov qword [rarray], rax
	
        mov rdi, qword [order]
	inc rdi
	mov rsi, 8
	call calloc
	cmp rax, 0
	je .malloc_failed
	mov qword [iarray], rax
	
        mov rdi, qword [order]
	inc rdi
	mov rsi, 8
	call calloc
	cmp rax, 0
	je .malloc_failed
	mov qword [d_rarray], rax
	
        mov rdi, qword [order]
	inc rdi
	mov rsi, 8
	call calloc
	cmp rax, 0
	je .malloc_failed
	mov qword [d_iarray], rax

	mov r15, qword [order]
	inc r15
        .my_loop:
            dec r15
            mov rdi, get_coeff
            mov rsi, coeff_index
            mov rdx, coeff_real
            mov rcx, coeff_img
            mov rax, 0
            call scanf
            mov r10, qword[coeff_index]

            movsd xmm0, qword[coeff_real]
            
            movsd xmm1, qword[coeff_img]
            
            fild qword[coeff_index]
            fld qword[coeff_real]
            fmulp st1,st0
            fstp qword[tmp]
            movsd xmm2, qword[tmp]
            
            fild qword[coeff_index]
            fld qword[coeff_img]
            fmulp
            fstp qword[tmp]
            movsd xmm3, qword[tmp]
            
            mov rax, 8
            mul r10
            add rax, qword[rarray]
            movsd qword[rax], xmm0
            
            mov rax, 8
            mul r10
            add rax, qword[iarray]
            movsd qword[rax], xmm1
            
            mov rax, 8
            mul r10 ; rax=rax*r10
            add rax, qword[d_rarray] ; rax=rax+rarray
            movsd qword[rax], xmm2
            
            mov rax, 8
            mul r10
            add rax, qword[d_iarray]
            movsd qword[rax], xmm3
            
            cmp r15, 0
            jg .my_loop
            
        mov rdi, get_initial
	mov rsi, initial_real
	mov rdx, initial_img
	mov rax, 0
        call scanf
	
        fld qword[epsilon]
	fld qword[epsilon]
	fmulp
        fstp qword[epsilon]
	
.function:
        finit
        fld qword[zero]
	fst qword[f_xR]
	fst qword[f_xI]
	fst qword[df_xR]
	fst qword[df_xI]
	fst qword[initi_power]
	fst qword[resultr]
	fstp qword[resulti]
	fld qword[one]
	fstp qword[initr_power]
	
	mov r15, -1
        .my_loop2: ;r15 is our i
            inc r15
            
            mov rax, 8
            mul r15 ;rax=rax*i
            add rax, qword[iarray] ;now rax has address of iarray[i]
            mov r14, rax ;r14 has address of iarray[i]
            
            fld qword[r14] ;load iarray[i]
            fld qword[initi_power]
            fmulp
            fstp qword[tmp]

            mov rax, 8
            mul r15 ;rax=rax*i
            add rax, qword[rarray] ;now rax has address of rarray[i]
            mov r13, rax; r13 has address of rarray[i]
            
            fld qword[r13] 
            fld qword[initr_power]
            fmulp
            fld qword[tmp]
            fsubp st1, st0 ; ( (arrayr[i] * initr_power) - (arrayi[i] * initi_power) )
            fld qword[f_xR]
            faddp st1, st0
            fstp qword[f_xR] ;updated f_xR
            
            fld qword[r14]
            fld qword[initr_power]
            fmulp
            fstp qword[tmp]
            fld qword[initi_power]
            fld qword[r13]
            fmulp
            fld qword[tmp]
            faddp st1,st0
            fld qword[f_xI]
            faddp st1, st0
            fstp qword[f_xI] ;updated f_xI
            
            cmp r15, qword [order]
            
            je .skip_der ;if i<=order
            
            inc r15 ;because deriative array shifted left by one
            
            mov rax, 8
            mul r15 ;rax=rax*i
            add rax, qword[d_iarray] ;now rax has address of d_iarray[i]
            mov r14, rax ;now r14 has address of d_iarray[i]
            
            mov rax, 8
            mul r15 ;rax=rax*i
            add rax, qword[d_rarray] ;now rax has address of d_iarray[i]
            mov r13, rax ;now r13 has address of d_rarray[i]
            
            fld qword[r14] ;load iarray[i]
            fld qword[initi_power]
            fmulp
            fstp qword[tmp]
            
            fld qword[r13] 
            fld qword[initr_power]
            fmulp
            fld qword[tmp]
            fsubp st1, st0 
            fld qword[df_xR]
            faddp st1, st0
            fstp qword[df_xR] ;updated df_xR
            
            fld qword[r14]
            fld qword[initr_power]
            fmulp
            fstp qword[tmp]
            fld qword[initi_power]
            fld qword[r13]
            fmulp
            fld qword[tmp]
            faddp st1,st0
            fld qword[df_xI]
            faddp st1, st0
            fstp qword[df_xI] ;updated df_xI
            
            dec r15 ;because deriative array shifted left by one
            
.skip_der:
            
            fld qword[initr_power]
            fld qword[initial_real]
            fmulp
            fld qword[initi_power]
            fld qword[initial_img]
            fmulp
            fsubp st1, st0
            fstp qword[tmp]
            
            fld qword[initr_power]
            fld qword[initial_img]
            fmulp
            fld qword[initi_power]
            fld qword[initial_real]
            fmulp
            faddp st1, st0
            fstp qword[initi_power]
            
            fld qword[tmp]
            fstp qword[initr_power]
            
            cmp r15, qword [order]
            jl .my_loop2
            
            ;if (||Z||<epsilon)
            fld qword[f_xR]
            fld qword[f_xR]
            fmulp
            fld qword[f_xI]
            fld qword[f_xI]
            fmulp
            faddp ;sum in st1
            fld qword[epsilon] ;epsilon*epsilon in st0
            fcomi
            jnb .finish
            
            ;solve f(x)/f'(x)
            finit
            fld qword[df_xR]
            fld qword[df_xR]
            fmulp
            fld qword[df_xI]
            fld qword[df_xI]
            fmulp
            faddp
            fstp qword[tmp]
            fld qword[df_xI]
            fld qword[f_xI]
            fmulp
            fld qword[f_xR]
            fld qword[df_xR]
            fmulp
            faddp
            fld qword[tmp]
            fdivp st1,st0
            fstp qword[resultr]
            
            finit
            fld qword[df_xR]
            fld qword[df_xR]
            fmulp
            fld qword[df_xI]
            fld qword[df_xI]
            fmulp
            faddp
            fstp qword[tmp]
            fld qword[f_xI]
            fld qword[df_xR]
            fmulp
            fld qword[f_xR]
            fld qword[df_xI]
            fmulp
            fsubp st1, st0
            fld qword[tmp]
            fdivp st1,st0
            fstp qword[resulti]
            
            fld qword[initial_real]
            fld qword[resultr]
            fsubp st1, st0
            fstp qword[initial_real]
            
            fld qword[initial_img]
            fld qword[resulti]
            fsubp st1, st0
            fstp qword[initial_img]
            
            jmp .function

.finish:
	mov rdi, print_root
	movsd xmm0, qword [initial_real]
	movsd xmm1, qword [initial_img]
	mov rax, 2
	call printf
        mov rdi, qword [rarray]
	call free
	mov rdi, qword [iarray]
	call free
	mov rdi, qword [d_rarray]
	call free
	mov rdi, qword [d_iarray]
	call free
	jmp .end
	
.malloc_failed:
	mov rdi, fs_malloc_failed
	mov rax, 0
	call printf
	jmp .end

.end:
	leave
	ret