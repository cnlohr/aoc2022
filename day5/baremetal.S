.section .initial_jump
.align 4
.global _start
_start: jal ra, asmmain

#define BUFFLEN 128

.section .rodata
.align 4
newline:     .ascii "\n\0"
errormsg:     .ascii "INPUT ERROR\n\0"
debug:        .ascii "DEBUG\n\0"

#define MAX_COLUMNS 11
#define MAX_DEPTH 100

.section .data
.align 4
scratchchar: .ascii " \0"
_stdin_iseof: .long 0
gameboard: .space MAX_COLUMNS*MAX_DEPTH, 0
strbuffer: .space BUFFLEN*2, 0
towerheights: .space MAX_COLUMNS*4,0

#define PRINT_NUM( str, val ) \
	la t0, str;\
	csrw 0x138, t0;\
	csrw 0x136, val;\
	la t0, newline;\
	csrw 0x138, t0

#define PUTCHAR( ch ) \
	la t0, scratchchar; \
	sb ch, 0(t0); \
	csrw 0x138, t0; \



.section .text
.align 4

columnappend: // a0 = which column, a1 = char to append, a0, a1 remain unchanged. Promise.  Though t0..t2 are blown.
	la t0, towerheights
	slli t1, a0, 2
	add t0, t1, t0
	lw t1, 0(t0)      //t1 is now height
	addi t2, t1, 1
	sw t2, 0(t0)



	// Form address from t1 (height) and column.
	li t2, MAX_DEPTH
	mul t0, a0, t2
	add t0, t0, t1

	la t1, gameboard
	add t0, t0, t1
	sb a1, 0(t0)

	ret


columnpull: //a0 = which column, a0 becomes value in column. t0..t2 get wrekt
	la t0, towerheights
	slli t1, a0, 2
	add t0, t1, t0
	lw t1, 0(t0)      //t1 is now height
	addi t1, t1, -1
	sw t1, 0(t0)




	li t2, MAX_DEPTH
	mul t0, a0, t2
	add t0, t0, t1
	la t1, gameboard  //XXX TODO: I think there is a shortcut for this.
	add t0, t0, t1
	lb a0, 0(t0)

	ret

cargomove: // Moving one at a time.
	// a0 = quantity
	// a1 = from
	// a2 = to
	addi sp, sp, -12
	sw ra, 12(sp)

	mv t3, a0
	mv t4, a1
	mv t5, a2
	li t6, 0
.cagomoveStartcopy:
	bge t6, t3, .cargomoveFreeret
	mv a0, t4
	jal ra, columnpull

	mv t0, a0
	mv a0, t5
	mv a1, t0
	jal ra, columnappend
	addi t6, t6, 1
	j .cagomoveStartcopy
.cargomoveFreeret:
	lw ra, 12(sp)
	addi sp, sp, 12
	ret



cargomoveFlip: // Moving a pile.
	// a0 = quantity
	// a1 = from
	// a2 = to
	addi sp, sp, -12
	sw ra, 12(sp)

	mv t3, a0
	mv t4, a1
	mv t5, a2
	li t6, 0
.cargomoveFlipStartCopy:
	bge t6, t3, .cargomoveMidpoint
	mv a0, t4
	jal ra, columnpull
	mv a1, a0
	mv a0, x0
	jal ra, columnappend
	addi t6, t6, 1
	j .cargomoveFlipStartCopy
.cargomoveMidpoint:
	li t6, 0

.cargomoveFlipContCopy:
	bge t6, t3, .cargomoveFlipret
	mv a0, x0
	jal ra, columnpull
	mv a1, a0
	mv a0, t5
	jal ra, columnappend
	addi t6, t6, 1
	j .cargomoveFlipContCopy

.cargomoveFlipret:
	lw ra, 12(sp)
	addi sp, sp, 12
	ret


printtree: //Warning: Destroys A0
	li t5, 0 //i
	li t6, 0 //j
	li t4, 0 //maxheight
.printtreeKeepReading:
	la t0, towerheights
	slli t1, t5, 2
	add t0, t0, t1
	lw t6, 0(t0) // j = towerheights[5]

	blt t6, t4, printtreeNotGT
		mv t4, t6
	printtreeNotGT:
	addi t5, t5, 1
	li t0, MAX_COLUMNS
	blt t5, t0, .printtreeKeepReading

	addi t6, t4,-1

.printtreeNextRow:
	blt t6, x0, .printtreeDone
	li t5, 0
.printtreenext_col:
	la t0, towerheights
	slli t1, t5, 2
	add t0, t0, t1
	lw t0, 0(t0)
	li t1, ' '
	addi t0, t0, -1
	blt t0, t6, .printtreehaschar
		// Get value from column array
		li t0, MAX_DEPTH
		mul t0, t0, t5
		la t1, gameboard
		add t0, t1, t0
		add t0, t6, t0
		lb t1, 0(t0)
.printtreehaschar:
	PUTCHAR( t1 )
	addi t5, t5, 1
	li t0, MAX_COLUMNS
	blt t5, t0, .printtreenext_col
	li t1, '\n' 
	PUTCHAR( t1 );
	addi t6, t6, -1
	j .printtreeNextRow

.printtreeDone:
	li t1, '\n' 
	PUTCHAR( t1 );
	ret


asmmain:
	la sp, _sstack

.newline:
	li s2, 0 //placeinline

.keep_reading:
	jal getchar
	blt a0, x0, abort
	li t0, 0x0a
	bne a0, t0, .notnewline
		li t0, 2
		blt s2, t0, .movemode
		j .newline
	.notnewline:
	addi s2, s2, 1
	andi t0, s2, 3
	li t1, 2
	bne t0, t1, .keep_reading
		li t0, 'A'
		blt a0, t0, .keep_reading
		li t0, 'Z'+1
		bge a0, t0, .keep_reading
		mv a1, a0
		srli t0, s2, 2
		addi a0, t0, 1 //which_column
		// Neat: You can "return" to somewhere else.
		la ra, .keep_reading
		j columnappend

	// Need to now flip everything upside down.
.movemode:

	li s2, 0 //placeinline = 0;
.copystart:
	addi s2, s2, 1 //First column is scratch.
	la a0, towerheights
	sll t0, s2, 2
	add a0, a0, t0
	lw a0, 0(a0)
	mv a1, s2
	li a2, MAX_COLUMNS-1 
	jal cargomove

	la a0, towerheights
	addi a0, a0, (MAX_COLUMNS-1)*4
	lw a0, 0(a0)
	li a1, MAX_COLUMNS-1
	mv a2, s2
	jal cargomoveFlip	

	li t0, MAX_COLUMNS-1
	blt s2, t0, .copystart
donecopy:
	jal ra, printtree

	// Now, process the moves.

keep_moving:
	jal dupstdintospace
	jal read_num_base_10
	mv s3, a0  //qty
	jal dupstdintospace
	jal read_num_base_10
	mv s4, a0  //from
	jal dupstdintospace
	jal read_num_base_10
	mv s5, a0  //to

	jal is_eof
	bne a0, x0, done

	mv a0, s3
	mv a1, s4
	mv a2, s5

	jal cargomoveFlip  //Part 1
//	jal cargomove      //Part 2

	
	j keep_moving
	//Part 1: JDTMRWCQJ
done:

	jal ra, printtree

	la ra, shutdown

	j printtree

abort:
	la t0, errormsg
	csrw 0x138, t0
shutdown:
	la a5, 0x5555
	li a6, 0x11100000
	sw a5, 0(a6)


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


// Read a word, until whitespace or newline is found.
// no return.  A0 is not corrupted.  Destroys t0..t4
dupstdintospace:
	mv t2, ra
	mv t4, a0
doread:
	jal ra, getchar
	blt a0, x0, .failout_is_eof
	li t0, ' '
	beq a0, t0, .dupstdintospaceDone
	li t0, '\n'
	beq a0, t0, .dupstdintospaceDone
	j doread

.failout_is_eof:
	la t1, _stdin_iseof
	li t3, 1
	sw t3, 0(t1)
.dupstdintospaceDone:
	mv ra, t2
	mv a0, t4
	ret


// fffffeda = newline
// fffffed4 = EOF char
// reads until non-numerical char
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



