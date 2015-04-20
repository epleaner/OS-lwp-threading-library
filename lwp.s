	.file	"lwp.c"
	.comm	qhead,4,4
	.comm	qtail,4,4
	.comm	lwp_ptable,480,32
.globl lwp_procs
	.bss
	.align 4
	.type	lwp_procs, @object
	.size	lwp_procs, 4
lwp_procs:
	.zero	4
.globl lwp_running
	.data
	.align 4
	.type	lwp_running, @object
	.size	lwp_running, 4
lwp_running:
	.long	-1
	.comm	driverStackPointer,4,4
	.comm	currentLWP,4,4
	.comm	schedFun,4,4
	.text
.globl qinsert
	.type	qinsert, @function
qinsert:
	pushl	%ebp
	movl	%esp, %ebp
	pushl	%ebx
	subl	$20, %esp
	movl	qhead, %eax
	testl	%eax, %eax
	jne	.L2
	movl	$8, (%esp)
	call	malloc
	movl	%eax, qhead
	movl	qhead, %eax
	movl	8(%ebp), %edx
	movl	%edx, (%eax)
	movl	qhead, %eax
	movl	$0, 4(%eax)
	movl	qhead, %eax
	movl	%eax, qtail
	jmp	.L4
.L2:
	movl	qtail, %ebx
	movl	$8, (%esp)
	call	malloc
	movl	%eax, 4(%ebx)
	movl	qtail, %eax
	movl	4(%eax), %eax
	movl	8(%ebp), %edx
	movl	%edx, (%eax)
	movl	qtail, %eax
	movl	4(%eax), %eax
	movl	$0, 4(%eax)
	movl	qtail, %eax
	movl	4(%eax), %eax
	movl	%eax, qtail
.L4:
	addl	$20, %esp
	popl	%ebx
	popl	%ebp
	ret
	.size	qinsert, .-qinsert
.globl qdelete
	.type	qdelete, @function
qdelete:
	pushl	%ebp
	movl	%esp, %ebp
	subl	$40, %esp
	movl	qhead, %eax
	movl	(%eax), %eax
	movl	%eax, -16(%ebp)
	movl	qhead, %eax
	movl	%eax, -12(%ebp)
	movl	qhead, %eax
	movl	4(%eax), %eax
	movl	%eax, qhead
	movl	-12(%ebp), %eax
	movl	%eax, (%esp)
	call	free
	movl	-16(%ebp), %eax
	leave
	ret
	.size	qdelete, .-qdelete
.globl qremove
	.type	qremove, @function
qremove:
	pushl	%ebp
	movl	%esp, %ebp
	subl	$40, %esp
	movl	qhead, %eax
	movl	%eax, -16(%ebp)
	movl	qhead, %eax
	testl	%eax, %eax
	je	.L10
	movl	qhead, %eax
	movl	(%eax), %eax
	cmpl	8(%ebp), %eax
	jne	.L10
	movl	qhead, %eax
	movl	%eax, -12(%ebp)
	movl	qhead, %eax
	movl	4(%eax), %eax
	movl	%eax, qhead
	movl	-12(%ebp), %eax
	movl	%eax, (%esp)
	call	free
	movl	8(%ebp), %eax
	jmp	.L9
.L13:
	movl	-16(%ebp), %eax
	movl	4(%eax), %eax
	movl	(%eax), %eax
	cmpl	8(%ebp), %eax
	jne	.L11
	movl	-16(%ebp), %eax
	movl	4(%eax), %eax
	movl	%eax, -12(%ebp)
	movl	-16(%ebp), %eax
	movl	4(%eax), %eax
	movl	4(%eax), %edx
	movl	-16(%ebp), %eax
	movl	%edx, 4(%eax)
	movl	-12(%ebp), %eax
	movl	%eax, (%esp)
	call	free
	movl	8(%ebp), %eax
	jmp	.L9
.L11:
	movl	-16(%ebp), %eax
	movl	4(%eax), %eax
	movl	%eax, -16(%ebp)
.L10:
	cmpl	$0, -16(%ebp)
	je	.L12
	movl	-16(%ebp), %eax
	movl	4(%eax), %eax
	testl	%eax, %eax
	jne	.L13
.L12:
	movl	$-1, %eax
.L9:
	leave
	ret
	.size	qremove, .-qremove
	.section	.rodata
.LC0:
	.string	"Queue: "
.LC1:
	.string	"%d "
	.text
.globl qprint
	.type	qprint, @function
qprint:
	pushl	%ebp
	movl	%esp, %ebp
	subl	$40, %esp
	movl	qhead, %eax
	movl	%eax, -12(%ebp)
	movl	$.LC0, %eax
	movl	%eax, (%esp)
	call	printf
	jmp	.L16
.L17:
	movl	-12(%ebp), %eax
	movl	(%eax), %edx
	movl	$.LC1, %eax
	movl	%edx, 4(%esp)
	movl	%eax, (%esp)
	call	printf
	movl	-12(%ebp), %eax
	movl	4(%eax), %eax
	movl	%eax, -12(%ebp)
.L16:
	cmpl	$0, -12(%ebp)
	jne	.L17
	movl	$10, (%esp)
	call	putchar
	leave
	ret
	.size	qprint, .-qprint
.globl qrewind
	.type	qrewind, @function
qrewind:
	pushl	%ebp
	movl	%esp, %ebp
	subl	$16, %esp
	movl	qhead, %eax
	movl	%eax, -4(%ebp)
	movl	qhead, %eax
	testl	%eax, %eax
	je	.L27
	movl	qhead, %eax
	movl	4(%eax), %eax
	testl	%eax, %eax
	jne	.L23
	jmp	.L26
.L25:
	movl	-4(%ebp), %eax
	movl	4(%eax), %eax
	movl	%eax, -4(%ebp)
.L23:
	cmpl	$0, -4(%ebp)
	je	.L24
	movl	-4(%ebp), %eax
	movl	4(%eax), %eax
	testl	%eax, %eax
	je	.L24
	movl	-4(%ebp), %eax
	movl	4(%eax), %eax
	movl	4(%eax), %eax
	testl	%eax, %eax
	jne	.L25
.L24:
	movl	qtail, %eax
	movl	qhead, %edx
	movl	%edx, 4(%eax)
	movl	qtail, %eax
	movl	%eax, qhead
	movl	-4(%ebp), %eax
	movl	%eax, qtail
	movl	qtail, %eax
	movl	$0, 4(%eax)
	jmp	.L26
.L27:
	nop
.L26:
	leave
	ret
	.size	qrewind, .-qrewind
.globl updateProcessTable
	.type	updateProcessTable, @function
updateProcessTable:
	pushl	%ebp
	movl	%esp, %ebp
	subl	$16, %esp
	movl	8(%ebp), %eax
	movl	%eax, -4(%ebp)
	jmp	.L29
.L30:
	movl	-4(%ebp), %eax
	movl	-4(%ebp), %edx
	addl	$1, %edx
	sall	$4, %eax
	sall	$4, %edx
	movl	lwp_ptable(%edx), %ecx
	movl	%ecx, lwp_ptable(%eax)
	movl	lwp_ptable+4(%edx), %ecx
	movl	%ecx, lwp_ptable+4(%eax)
	movl	lwp_ptable+8(%edx), %ecx
	movl	%ecx, lwp_ptable+8(%eax)
	movl	lwp_ptable+12(%edx), %edx
	movl	%edx, lwp_ptable+12(%eax)
	addl	$1, -4(%ebp)
.L29:
	movl	lwp_procs, %eax
	addl	$1, %eax
	cmpl	-4(%ebp), %eax
	jg	.L30
	leave
	ret
	.size	updateProcessTable, .-updateProcessTable
.globl roundRobin
	.type	roundRobin, @function
roundRobin:
	pushl	%ebp
	movl	%esp, %ebp
	subl	$40, %esp
	call	qdelete
	movl	%eax, -12(%ebp)
	movl	-12(%ebp), %eax
	movl	%eax, (%esp)
	call	qinsert
	movl	-12(%ebp), %eax
	leave
	ret
	.size	roundRobin, .-roundRobin
	.section	.rodata
	.align 4
.LC2:
	.string	"No LWP processes have been created"
	.text
.globl setNextScheduled
	.type	setNextScheduled, @function
setNextScheduled:
	pushl	%ebp
	movl	%esp, %ebp
	subl	$40, %esp
	movl	lwp_procs, %eax
	testl	%eax, %eax
	jne	.L35
	movl	$.LC2, (%esp)
	call	puts
	jmp	.L36
.L35:
	movl	schedFun, %eax
	testl	%eax, %eax
	je	.L37
	movl	schedFun, %eax
	movl	(%eax), %eax
	testl	%eax, %eax
	jne	.L38
.L37:
	call	roundRobin
	movl	%eax, -12(%ebp)
	jmp	.L36
.L38:
	movl	schedFun, %eax
	movl	(%eax), %eax
	call	*%eax
	movl	%eax, -12(%ebp)
.L36:
	movl	-12(%ebp), %eax
	sall	$4, %eax
	addl	$lwp_ptable, %eax
	movl	%eax, currentLWP
	movl	-12(%ebp), %eax
	movl	%eax, lwp_running
	leave
	ret
	.size	setNextScheduled, .-setNextScheduled
.globl new_lwp
	.type	new_lwp, @function
new_lwp:
	pushl	%ebp
	movl	%esp, %ebp
	subl	$56, %esp
	movl	lwp_procs, %eax
	cmpl	$29, %eax
	jle	.L41
	movl	$-1, %eax
	jmp	.L42
.L41:
	movl	16(%ebp), %eax
	sall	$2, %eax
	movl	%eax, (%esp)
	call	malloc
	movl	%eax, -16(%ebp)
	movl	16(%ebp), %eax
	sall	$2, %eax
	addl	-16(%ebp), %eax
	movl	%eax, -24(%ebp)
	movl	12(%ebp), %edx
	movl	-24(%ebp), %eax
	movl	%edx, (%eax)
	subl	$4, -24(%ebp)
	movl	12(%ebp), %edx
	movl	-24(%ebp), %eax
	movl	%edx, (%eax)
	subl	$4, -24(%ebp)
	movl	8(%ebp), %edx
	movl	-24(%ebp), %eax
	movl	%edx, (%eax)
	subl	$4, -24(%ebp)
	movl	-24(%ebp), %eax
	movl	$7, (%eax)
	movl	-24(%ebp), %eax
	movl	%eax, -20(%ebp)
	subl	$4, -24(%ebp)
	movl	$0, -12(%ebp)
	jmp	.L43
.L44:
	movl	-12(%ebp), %eax
	addl	$1, %eax
	movl	%eax, %edx
	movl	-24(%ebp), %eax
	movl	%edx, (%eax)
	subl	$4, -24(%ebp)
	addl	$1, -12(%ebp)
.L43:
	cmpl	$5, -12(%ebp)
	jle	.L44
	movl	-20(%ebp), %edx
	movl	-24(%ebp), %eax
	movl	%edx, (%eax)
	movl	lwp_procs, %eax
	addl	$1, %eax
	movl	%eax, lwp_procs
	movl	lwp_procs, %eax
	movl	%eax, -40(%ebp)
	movl	-16(%ebp), %eax
	movl	%eax, -36(%ebp)
	movl	16(%ebp), %eax
	movl	%eax, -32(%ebp)
	movl	-24(%ebp), %eax
	movl	%eax, -28(%ebp)
	movl	-40(%ebp), %eax
	subl	$1, %eax
	sall	$4, %eax
	movl	-40(%ebp), %edx
	movl	%edx, lwp_ptable(%eax)
	movl	-36(%ebp), %edx
	movl	%edx, lwp_ptable+4(%eax)
	movl	-32(%ebp), %edx
	movl	%edx, lwp_ptable+8(%eax)
	movl	-28(%ebp), %edx
	movl	%edx, lwp_ptable+12(%eax)
	movl	-40(%ebp), %eax
	subl	$1, %eax
	movl	%eax, (%esp)
	call	qinsert
	movl	-40(%ebp), %eax
.L42:
	leave
	ret
	.size	new_lwp, .-new_lwp
.globl lwp_exit
	.type	lwp_exit, @function
lwp_exit:
	pushl	%ebp
	movl	%esp, %ebp
	subl	$24, %esp
	movl	currentLWP, %eax
	movl	4(%eax), %eax
	movl	%eax, (%esp)
	call	free
	movl	lwp_procs, %eax
	subl	$1, %eax
	movl	%eax, lwp_procs
	movl	lwp_procs, %eax
	movl	%eax, (%esp)
	call	qremove
	movl	lwp_procs, %eax
	testl	%eax, %eax
	jne	.L47
	call	lwp_stop
	jmp	.L51
.L47:
	movl	schedFun, %eax
	testl	%eax, %eax
	je	.L49
	movl	schedFun, %eax
	movl	(%eax), %eax
	testl	%eax, %eax
	jne	.L50
.L49:
	call	qrewind
.L50:
	movl	lwp_running, %eax
	movl	%eax, (%esp)
	call	updateProcessTable
	call	setNextScheduled
	movl	currentLWP, %eax
	movl	12(%eax), %eax
#APP
# 258 "lwp.c" 1
	movl  %eax,%esp
# 0 "" 2
# 261 "lwp.c" 1
	popl  %ebp
# 0 "" 2
# 261 "lwp.c" 1
	popl  %edi
# 0 "" 2
# 261 "lwp.c" 1
	popl  %esi
# 0 "" 2
# 261 "lwp.c" 1
	popl  %edx
# 0 "" 2
# 261 "lwp.c" 1
	popl  %ecx
# 0 "" 2
# 261 "lwp.c" 1
	popl  %ebx
# 0 "" 2
# 261 "lwp.c" 1
	popl  %eax
# 0 "" 2
# 261 "lwp.c" 1
	movl  %ebp,%esp
# 0 "" 2
#NO_APP
.L51:
	leave
	ret
	.size	lwp_exit, .-lwp_exit
.globl lwp_getpid
	.type	lwp_getpid, @function
lwp_getpid:
	pushl	%ebp
	movl	%esp, %ebp
	movl	lwp_running, %eax
	testl	%eax, %eax
	js	.L53
	movl	lwp_running, %eax
	sall	$4, %eax
	movl	lwp_ptable(%eax), %eax
	jmp	.L54
.L53:
	movl	$0, %eax
.L54:
	popl	%ebp
	ret
	.size	lwp_getpid, .-lwp_getpid
.globl lwp_yield
	.type	lwp_yield, @function
lwp_yield:
	pushl	%ebp
	movl	%esp, %ebp
	subl	$8, %esp
#APP
# 286 "lwp.c" 1
	pushl %eax
# 0 "" 2
# 286 "lwp.c" 1
	pushl %ebx
# 0 "" 2
# 286 "lwp.c" 1
	pushl %ecx
# 0 "" 2
# 286 "lwp.c" 1
	pushl %edx
# 0 "" 2
# 286 "lwp.c" 1
	pushl %esi
# 0 "" 2
# 286 "lwp.c" 1
	pushl %edi
# 0 "" 2
# 286 "lwp.c" 1
	pushl %ebp
# 0 "" 2
#NO_APP
	movl	currentLWP, %eax
#APP
# 289 "lwp.c" 1
	movl  %esp,%edx
# 0 "" 2
#NO_APP
	movl	%edx, 12(%eax)
	call	setNextScheduled
	movl	currentLWP, %eax
	movl	12(%eax), %eax
#APP
# 295 "lwp.c" 1
	movl  %eax,%esp
# 0 "" 2
# 298 "lwp.c" 1
	popl  %ebp
# 0 "" 2
# 298 "lwp.c" 1
	popl  %edi
# 0 "" 2
# 298 "lwp.c" 1
	popl  %esi
# 0 "" 2
# 298 "lwp.c" 1
	popl  %edx
# 0 "" 2
# 298 "lwp.c" 1
	popl  %ecx
# 0 "" 2
# 298 "lwp.c" 1
	popl  %ebx
# 0 "" 2
# 298 "lwp.c" 1
	popl  %eax
# 0 "" 2
# 298 "lwp.c" 1
	movl  %ebp,%esp
# 0 "" 2
#NO_APP
	leave
	ret
	.size	lwp_yield, .-lwp_yield
.globl lwp_start
	.type	lwp_start, @function
lwp_start:
	pushl	%ebp
	movl	%esp, %ebp
	subl	$8, %esp
	movl	lwp_procs, %eax
	testl	%eax, %eax
	je	.L62
.L59:
#APP
# 319 "lwp.c" 1
	pushl %eax
# 0 "" 2
# 319 "lwp.c" 1
	pushl %ebx
# 0 "" 2
# 319 "lwp.c" 1
	pushl %ecx
# 0 "" 2
# 319 "lwp.c" 1
	pushl %edx
# 0 "" 2
# 319 "lwp.c" 1
	pushl %esi
# 0 "" 2
# 319 "lwp.c" 1
	pushl %edi
# 0 "" 2
# 319 "lwp.c" 1
	pushl %ebp
# 0 "" 2
# 323 "lwp.c" 1
	movl  %esp,%eax
# 0 "" 2
#NO_APP
	movl	%eax, driverStackPointer
	call	setNextScheduled
	movl	currentLWP, %eax
	movl	12(%eax), %eax
#APP
# 329 "lwp.c" 1
	movl  %eax,%esp
# 0 "" 2
# 332 "lwp.c" 1
	popl  %ebp
# 0 "" 2
# 332 "lwp.c" 1
	popl  %edi
# 0 "" 2
# 332 "lwp.c" 1
	popl  %esi
# 0 "" 2
# 332 "lwp.c" 1
	popl  %edx
# 0 "" 2
# 332 "lwp.c" 1
	popl  %ecx
# 0 "" 2
# 332 "lwp.c" 1
	popl  %ebx
# 0 "" 2
# 332 "lwp.c" 1
	popl  %eax
# 0 "" 2
# 332 "lwp.c" 1
	movl  %ebp,%esp
# 0 "" 2
#NO_APP
	jmp	.L61
.L62:
	nop
.L61:
	leave
	ret
	.size	lwp_start, .-lwp_start
.globl lwp_stop
	.type	lwp_stop, @function
lwp_stop:
	pushl	%ebp
	movl	%esp, %ebp
	movl	driverStackPointer, %eax
#APP
# 345 "lwp.c" 1
	movl  %eax,%esp
# 0 "" 2
# 348 "lwp.c" 1
	popl  %ebp
# 0 "" 2
# 348 "lwp.c" 1
	popl  %edi
# 0 "" 2
# 348 "lwp.c" 1
	popl  %esi
# 0 "" 2
# 348 "lwp.c" 1
	popl  %edx
# 0 "" 2
# 348 "lwp.c" 1
	popl  %ecx
# 0 "" 2
# 348 "lwp.c" 1
	popl  %ebx
# 0 "" 2
# 348 "lwp.c" 1
	popl  %eax
# 0 "" 2
# 348 "lwp.c" 1
	movl  %ebp,%esp
# 0 "" 2
#NO_APP
	popl	%ebp
	ret
	.size	lwp_stop, .-lwp_stop
.globl lwp_set_scheduler
	.type	lwp_set_scheduler, @function
lwp_set_scheduler:
	pushl	%ebp
	movl	%esp, %ebp
	subl	$24, %esp
	movl	schedFun, %eax
	testl	%eax, %eax
	jne	.L66
	movl	$4, (%esp)
	call	malloc
	movl	%eax, schedFun
.L66:
	movl	schedFun, %eax
	movl	8(%ebp), %edx
	movl	%edx, (%eax)
	leave
	ret
	.size	lwp_set_scheduler, .-lwp_set_scheduler
	.ident	"GCC: (GNU) 4.4.7 20120313 (Red Hat 4.4.7-11)"
	.section	.note.GNU-stack,"",@progbits
