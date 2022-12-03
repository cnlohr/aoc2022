.section .initial_jump
.align 4
.global _start
_start: jal ra, asmmain

#define BUFFLEN 1024

.section .rodata
.align 4
mark :      .ascii "MARK:\0"
debug :      .ascii "DEBUG:\0"
space :      .ascii " \0"
newline:    .ascii "\n\0"
errormess:  .ascii "\nError in input\n\0"
your_score: .ascii "Your Score: \0"

strbuffer: .space BUFFLEN, 0
linelength: .long 0

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

	li s8, 0 // Score (cumulative)

	.keep_reading:
		li a0, BUFFLEN
		la a1, strbuffer
		jal ra, read_line
		blt a0, x0, .done // a0 is bytes read.
		la t0, linelength
		sw a0, 0(t0)

		srli t0, a0, 1   // half-line-length
		la s3, strbuffer // Pointer to start string
		add s2, s3, t0   // Pointer to end-of-first-string

		li s4, -1       // type
		li s5, 0        // Score (This line)

		.typeloop:
			addi s4, s4, 1 // type++

			li s6, 0 // Found a hit on left
			li s7, 0 // Found a hit on right

			la t3, strbuffer  // Pointer to string start
			mv t4, s2

			.innerloop:
				lb a0, 0(t3)
				jal ra, get_item_priority
				xor a0, a0, s4 // See if left is a hit. 
				seqz a0, a0
				or s6, s6, a0

				lb a0, 0(t4)
				jal ra, get_item_priority
				xor a0, a0, s4 // See if right is a hit. 
				seqz a0, a0
				or s7, s7, a0

				addi t3, t3, 1 // advance pointers
				addi t4, t4, 1
				bne t3, s2, .innerloop

			// See if a11 and a10 are both set.
			and s6, s6, s7

			// If so, add the item priority.
			mul t0, s6, s4
			add s5, s5, t0

			li t0, 52
			blt s4, t0, .typeloop

		PRINT_NUM( strbuffer, s5 );
		beq s5, x0, errmark_out // At least one thing has to match.
		add s8, s8, s5 // total score += this line score

		jal ra, is_eof
		beq a0, x0, .keep_reading

.done:

	la t1, your_score
	csrw 0x138, t1
	csrw 0x136, s8
	la t1, newline
	csrw 0x138, t1


shutdown:
	// Shutdown
	la a5, 0x5555
	li a6, 0x11100000
	sw a5, 0(a6)


errmark_out:
	la t0, errormess
	csrw 0x138, t0
	j shutdown



get_item_priority:
	li t0, 'A'
	blt a0, t0, errmark_out
	li t0, 'Z'+1
	blt a0, t0, .uppercase

	li t0, 'a'
	blt a0, t0, errmark_out
	li t0, 'z'+1
	blt a0, t0, .lowercase

	j errmark_out
.lowercase:
	addi a0, a0, 1-'a'
	ret
.uppercase:
	addi a0, a0, 27-'A'
	ret




getchar:
	la t0, 0x10000005  // UART Status address
	lw a0, 0(t0)
	andi a0, a0, 0x1
	beq a0, x0, getchar
	addi t0, t0, -5
	lw a0, 0(t0)
	blt a0, x0, .hiteof
	ret
.hiteof:
	la t0, _stdin_iseof
	li a0, 1
	lw a0, 0(t0)
	li a0, 0
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



