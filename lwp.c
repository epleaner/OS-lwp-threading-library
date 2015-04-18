//
//  lwp.c
//  OS: Program 1
//
//  Created by Eli Pleaner on 4/7/15.
//  Copyright (c) 2015 Eli Pleaner. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lwp.h"

#define LWP_MAX_STACK_SIZE	50
#define REGISTER_SIZE 27

typedef struct queueNode{
	int index;
	struct queueNode *next;
} node;

node *qhead, *qtail;

lwp_context lwp_ptable[LWP_PROC_LIMIT];/* the process table           */
int lwp_procs = 0;           /* the current number of LWPs  */
int lwp_running = -1;         /* the index of the currently running LWP */
ptr_int_t * driverStackPointer;
lwp_context *currentLWP;
schedfun *schedFun;

//	Adds a node to the tail, initializing queue if need be
void qinsert(int index) { 
	if(qhead == NULL) {
		qhead = malloc(sizeof(node));
		qhead->index = index;
		qhead->next = NULL;
		qtail = qhead;
	}
	else {
		qtail->next = malloc(sizeof(node));
		qtail->next->index = index;
		qtail->next->next = NULL;
		qtail = qtail->next;
	}
}

//	Removes head from queue
int qdelete() {
	int removed = qhead->index;
	node *toFree = qhead;
	qhead = qhead->next;
	free(toFree);
	return removed;
}

//	Removes a node with specific index from queue
int qremove(int index) {
	node *curr = qhead;
	node *toFree;
	
	//	If head is matching node, move head to next
	if(qhead && qhead->index == index) {
		toFree = qhead;
		qhead = qhead->next;
		free(toFree);
		return index;
	}
	while(curr && curr->next) {
		if(curr->next->index == index) {
			toFree = curr->next;
			curr->next = curr->next->next;
			free(toFree);
			return index;
		}
		curr = curr->next;
	}
	
	return -1;
}

//	Utility
void qprint() {
	node *curr = qhead;
	printf("Queue: ");
	while(curr) {
		printf("%d ", curr->index);
		curr = curr->next;
	}
	printf("\n");
}

void qrewind() {
	node *tailPrev = qhead;
	
	//	If only one or two elements, no need to rewind
	if(!qhead || !qhead->next) return;
	
	//	Go until second to last element
	while(tailPrev && tailPrev->next && tailPrev->next->next) {
		tailPrev = tailPrev->next;
	}
	
	//	move tail to head, make second to last the tail
	qtail->next = qhead;
	qhead = qtail;
	qtail = tailPrev;
	qtail->next = NULL;
}

void updateProcessTable(int index) {
	int i;
	
	for(i = index; i < lwp_procs + 1; i++) {
		lwp_ptable[i] = lwp_ptable[i + 1];
	}		
}

int roundRobin() {
	int next = qdelete();
	qinsert(next);
	return next;	
}

void setNextScheduled() {
	int next;
		
	if(lwp_procs == 0) {
		printf("No LWP processes have been created\n");
	}
	else if(schedFun == 0 || *schedFun == NULL) {
		next = roundRobin();
	} else {
		next = (*schedFun)();
		//qremove(next);
		//qinsert(next);
	}
	
	currentLWP = &lwp_ptable[next];
	
	//	Update lwp_running to next LWP's index in ptable
	lwp_running = next;
}

/* Creates a new lightweight process which calls the given function
 *	with the given argument. The new processes' stack will be
 *	stacksize words. The LWP's process table entry will include:
 *
 *	pid			a unique integer process id
 *	stack		a pointer to the memory region for this thread's stack
 *	stacksize	the size of this thread's stack in words
 *	sp			this thread's current stack pointer (top of stack)
 *
 *	Returns the (lightweight) process id of the new thread, or 
 *	-1 if more than LWP_PROC_LIMIT threads already exist
 *
 *	1. Malloc new processes's stack to be stacksize words
 *	2. Push the one argument onto stack
 *	3. Push the return address onto stack (func)
 *	4. Push bogus BP
 *	5. Call SAVE_STATE() so that RESTORE_STATE() will always work
 *	6. Push address of bogus BP (as new BP)
 *	6. Create lwp_context struct and insert it into driver's process table 
 */
int  new_lwp(lwpfun func, void * args, size_t stacksize) {
	lwp_context *processTableEntry;
	ptr_int_t *lwpSP, *newBP;
	ptr_int_t *stack;
	
	if(lwp_procs > LWP_PROC_LIMIT) return -1;
		
	//	Allocate stack
	stack = malloc(stacksize);

	// pointer to LWP's stack	
	lwpSP = stack + stacksize;
	
	//	Copy argument
	*lwpSP = (ptr_int_t) args;
	
	//	Adjust LWP SP for argument
	lwpSP-= 2;
				
	//	Copy return address
	*lwpSP = (ptr_int_t) func;
	
	//	Shift stack pointer down
	lwpSP--;
		
	//	Push bogus base pointer
	*lwpSP = 7;
	
	//	Save SP where BP was pushed as new BP
	newBP = lwpSP;
	
	//	Shift stack pointer down
	lwpSP--;
	
	//	Push 6 bogus registers
	int i;
	for(i = 0; i < 6; i++) {
		*lwpSP = i + 1;
	
		//	Shift stack pointer down
		lwpSP--;
	}
	
	//	Push real base pointer
	*lwpSP = (ptr_int_t) newBP;
			
	//	Create LWP's process table entry
	processTableEntry = malloc(sizeof(lwp_context));
	processTableEntry->pid = ++lwp_procs;
	processTableEntry->stack = stack;
	processTableEntry->stacksize = stacksize;
	processTableEntry->sp = lwpSP;
	
	//	Insert new LWP into process table
	lwp_ptable[processTableEntry->pid - 1] = *processTableEntry;
	
	//	Insert into queue
	qinsert(processTableEntry->pid - 1);
				
	return processTableEntry->pid;	
}

/*	Terminates the current LWP, frees its resources, and moves all the
 *	others up in the process table. If there are no other threads, call
 *	lwp_stop()
 *
 *	1. Free all memory allocated to current LWP
 *	2. If no other threads, call lwp_stop
 *	3. Otherwise, move others up in process table, updating lwp_procs
 *	4. Give control to next scheduled LWP
 */
void lwp_exit() {
	free(currentLWP->stack);
	free(currentLWP);
	
	qremove(--lwp_procs);
		
	if(lwp_procs == 0) {
		lwp_stop();
	}
	
	else {
		if(schedFun == 0 || *schedFun == NULL) {
			qrewind();
		}
		
		updateProcessTable(lwp_running);
		
		//	Get next LWP to run
		setNextScheduled();
	
		//	Set SP to next LWP's TOS
		SetSP(currentLWP->sp);
	
		//	Restore next LWP's state
		RESTORE_STATE();
	}
}

/*	Returns the pid of the calling LWP. The return value of lwp_getpid()
 *	is undefined if not called by a LWP.
 */
int  lwp_getpid() {
	if (lwp_running > -1) {
		return lwp_ptable[lwp_running].pid;
	}
	return (int) NULL;
}

/*	Yields control to another LWP. Which one depends on the scheduler.
 *	Saves the current LWP's context, picks the next one, restores that
 *	thread's context, and returns.
 * 
 *	1. SAVE_STATE on current LWP
 *	2. Get next LWP from scheduler
 *	3. Set stack pointer to next LWP's TOS
 *	4. RESTORE_STATE for next LWP
 *	5. Update lwp_running
 */
void lwp_yield() {	
	SAVE_STATE();
	
	//	Update LWP SP after saving state
	GetSP(currentLWP->sp);
	
	//	Get next LWP to run
	setNextScheduled();
	
	//	Set SP to next LWP's TOS
	SetSP(currentLWP->sp);
	
	//	Restore next LWP's state
	RESTORE_STATE();
}

/*	On first call
 *	Save the "real" context with SAVE_STATE(),
 *	Save the “real” stack pointer somewhere where lwp_stop() can find it,
 *	Pick one of the lightweight processes to run and switch to its stack,
 *	Load its context with RESTORE_STATE() and you should be off and running.
 *
 *	1. SAVE_STATE of "real" driver context
 *	2. Save driver stack pointer for lwp_stop()
 *	3. Choose LWP and switch to LWP stack (set SP)
 *	4. Set return address of LWP to driver TOS
 *	5. Call RESTORE_STATE for LWP
 */
void lwp_start() {
	if(lwp_procs == 0) {
		return;
	}
	
	//	Save driver state
	SAVE_STATE();
	
	//	Save original SP, updating it to point to 
	//	top of saved registers
	GetSP(driverStackPointer);
	
	//	Get next LWP to run
	setNextScheduled();
	
	//	Set SP to next LWP's TOS
	SetSP(currentLWP->sp);
	
	//	Restore next LWP's state
	RESTORE_STATE();
}

/*	Stops the LWP system, restores the original stack pointer and returns
 *	to that context. (Whenever lwp_start() was called from). lwp_stop()
 *	does not destroy any existing contexts, and the thread processing
 *	will be restarted by a call to lwp_start()
 *
 *	1. Restore original stack pointer
 *	2. Restore state for original context
 */
void lwp_stop() {
	//	Restore original SP
	SetSP(driverStackPointer);
	
	//	Restore original context state, updating SP
	RESTORE_STATE();
}

/*	Causes the LWP package to use the function scheduler to choose the next
 *	next process to run. (*scheduler)() must return an integer in the range
 *	0...lwp_procs - 1. If scheduler is NULL, or has never been set, the 
 *	do round-robin scheduling.
 */
void lwp_set_scheduler(schedfun sched) {
	if(schedFun == 0) {
		schedFun = malloc(sizeof(schedfun));
	}
	
	*schedFun = sched;
}