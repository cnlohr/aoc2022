.section .initial_jump
.align 4
.global _start
_start: jal ra, asmmain

#define BUFFLEN 128

.section .rodata
.align 4
newline:    .ascii "\n\0"
your_score: .ascii "Your Score: \0"
strbuffer: .space BUFFLEN, 0


.section .data
.align 4
_stdin_iseof: .long 0


#define PRINT_NUM( str, val ) \
	la t0, str;\
	csrw 0x138, t0;\
	csrw 0x136, val;\
	la t0, newline;\
	csrw 0x138, t0


.section .text
.align 4
asmmain:
	la sp, _sstack

	li a2, 0 // Score

.keep_reading:
	li a0, BUFFLEN
	la a1, strbuffer
	jal ra, read_line
	li t0, 3
	blt a0, t0, .done
	lb t0, -1(a1)
	lb t1, -3(a1)

	addi t0, t0, -'A'
	addi t1, t1, -'X'

	// TODO PICKUP HERE

	j .keep_reading
.done

	la t0, your_score
	csrw 0x138, t0
	csrw 0x136, a2
	la t0, newline;
	csrw 0x138, t0


	// Shutdown
	la a5, 0x5555
	li a6, 0x11100000
	sw a5, 0(a6)


/*
	li a6, 0 // Which "Top Elf" we're on.

	li a3, 0 // Elf # with biggest
	li a4, 0 // amount of calories biggest elf has.
	li a5, 0 // Current elf #
.new_elf:
	// For when we were only looking for highest elf.
	//blt a2, a4, .start_elf

	mv a0, a5
	mv a1, a2
	jal ra, record_elf

	mv a4, a2
	mv a3, a5
.start_elf:
	jal ra, is_eof
	bne a0, x0, .done_counting
	li a2, 0 // Current calories of elf
	addi a5, a5, 1
.keep_counting:
	jal ra, read_num_base_10
	add a2, a2, a0
	bge a0, x0, .keep_counting
	sub a2, a2, a0
	j .new_elf
.done_counting:

	la t4, top_elves
	la t1, top_elves + NUM_TOP_ELVES*4
	li t2, 0 // Sum of calories
.print_elves:
	lw t3, 0(t4)
	add t2, t2, t3
	addi t4, t4, 4

	PRINT_NUM( top_elf_calories, t3 )

	bne t4, t1, .print_elves

	PRINT_NUM( total_calories, t2 );
*/
/*
record_elf: // (elf_number, number of calories)
	la t4, top_elves
	la t1, top_elves + NUM_TOP_ELVES*4
.keep_searching:
	lw t2, 0(t4)	// If t2 < a1, we have a hit
	blt t2, a1, .hit_record_elf
	beq t4, t1, .done_record_elf
	addi t4, t4, 4
	j .keep_searching
.hit_record_elf:
	// Slide down eveything else in the array.
	lw t5, 0(t4)
	sw a1, 0(t4)
	beq t4, t1, .done_record_elf
	addi t4, t4, 4
	mv a1, t5
	j .hit_record_elf
.done_record_elf:
	ret
*/

getchar:
	la t0, 0x10000005  // UART Status address
	lw a0, 0(t0)
	andi a0, a0, 0x1
	beq a0, x0, getchar
	addi t0, t0, -5
	lw a0, 0(t0)
	ret

is_eof:
	la t0, _stdin_iseof
	lw a0, 0(t0)
	ret



/*
	addi sp, sp, -12
	sw ra, 12(sp)
	sw t4, 8(sp)
	sw t3, 4(sp)

	lw t3, 8(sp)
	lw t4, 4(sp)
	lw ra, 12(sp)
	addi sp, sp, -12
*/

read_line: // a0 = size of string including null, a1 = pointer to string
			// RETURN ==>> a0 = number of chars read.  a1 = pointer to end-of-string.
	mv t3, ra 
	mv t2, a1
	mv t1, a0
	beq t1, x0, .read_line_fail
	sb x0, 0(a1) // Force a null termination, if possible.
	addi t1, t1, -1
	beq t1, x0, .read_line_fail

	la t0, _stdin_iseof
	lw t0, 0(t0)
	bne t0, x0, .read_line_fail

.read_line_continue:
	jal ra, getchar
	addi t0, a0, -10 //EOL
	beqz t0, .read_line_done
	addi t0, a0, 1 // EOF
	beqz t0, .read_line_done
	sb a0, 0(a1)
	addi t1, t1, -1
	addi a1, a1, 1
	beq t1, x0, .read_line_fail_with_null
	j .read_line_continue

.read_line_done:
	sb x0, 0(a1) // Force a null termination, if possible.
	sub a0, a1, t2
	mv ra, t3
	ret

.read_line_fail_with_null:
	sb x0, 0(a1) // Force a null termination, if possible.	
.read_line_fail:
	li a0, -1
	mv ra, t3
	ret



// fffffeda = newline
// fffffed4 = EOF char
read_num_base_10:
	mv t2, ra
	li t1, 10
	li t3, -1

	jal ra, getchar
	addi t3, a0, - '0'
	bgeu t3, t1, .failout

.more_chars:
	jal ra, getchar
	addi a0, a0, - '0'
	bgeu a0, t1, .breakout
	mul t3, t1, t3
	add t3, t3, a0
	mv t5, x0
	j .more_chars

.breakout:
	mv a0, t3
	mv ra, t2
	ret

.failout:
	addi t3, a0, 1
	bne t3, x0, .skipsub
	la t1, _stdin_iseof
	addi t3, x0, 1
	sw t3, 0(t1)
	addi a0, a0, 256
.skipsub:
	addi a0, a0, -256
	mv ra, t2
	ret



