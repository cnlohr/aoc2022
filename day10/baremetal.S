.section .initial_jump
.align 4
.global _start
_start: jal ra, asmmain

#define BUFFLEN 128

.section .rodata
.align 4
newline:      .ascii "\n\0"
errormsg:     .ascii "INPUT ERROR\n\0"
debug:        .ascii "DEBUG\n\0"

#define MAX_COLUMNS 11
#define MAX_DEPTH 100

.section .data
.align 4
scratchchar: .ascii "*\0"
_stdin_iseof: .long 0
.align 4
strbuffer: .space BUFFLEN, 0
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


CheckIO:
	addi s1, s1, 1
	// First section (The display)
	bne s3, x0, .skipnewline
	la t0, newline
	csrw 0x138, t0
.skipnewline:
	addi t0, s3, -1
	blt s0, t0, .isdot
	addi t0, s3, +2
	bge s0, t0, .isdot
	li t0, '#'
	j .contp
.isdot:
	li t0, '.'
.contp:
	la t1, scratchchar
	sb t0, 0(t1)
	csrw 0x138, t1
	addi s3, s3, 1
	li t0, 40
	bne t0, s3, .skipreset
	li s3, 0
	
.skipreset:
	blt s1, s2, .skip_ack_ct
	mul t0, s2, s0
	add s4, s4, t0
	addi s2, s2, 40

.skip_ack_ct:
	ret



asmmain:
	la sp, _sstack

	li s0, 1  // x = 1 (The register)
	li s1, 0  // cycle = 0
	li s2, 20 // ackcyc (When to check for the frequency)
	li s3, 0  // dpycyc (display cursor enter)
	li s4, 0  // signal strength

instruction_loop:

	li a0, BUFFLEN-1
	la a1, strbuffer
	jal ra, read_line
	blt a0, x0, shutdown  //EOF?

	jal CheckIO

	la a0, strbuffer
	lw t0, 0(a0) // Read the first 4 characters of the buffer.
	li t1, 0x706f6f6e // poon (backwards noop) in hex.
	beq t0, t1, instruction_loop // NOP!
	li t1, 0x78646461 // xdda (backwards addx) in hex.
	bne t0, t1, abort
	
	//addx
	//csrw 0x137, a0
	//la a1, strbuffer
	//csrw 0x138, a1
	//la a1, scratchchar
	//csrw 0x138, a1
	
	jal CheckIO
	addi a0, a0, 4
	jal ra, atoi_eptr // a0 in string, a0 out value, a1 points to end of string.
	
	add s0, s0, a0
	
	j instruction_loop

.nopcode:
	j instruction_loop


abort:
	la t0, errormsg
	csrw 0x138, t0
shutdown:
	la t0, newline
	csrw 0x138, t0
	csrw 0x136, s4
	csrw 0x138, t0

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
	
	// Future note: Not sure what these are.
//	addi t1, t1, -1
//	beq t1, x0, .read_line_fail  // If 1 fail

	la t0, _stdin_iseof
	lw t0, 0(t0)
	bne t0, x0, .read_line_fail

.read_line_continue:
	jal ra, getchar
	ble a0, x0, .read_line_eof_ok
	addi t0, a0, -10 //EOL
	beqz t0, .read_line_done
	addi t0, a0, 1 // EOF
	beqz t0, .read_line_done
	sb a0, 0(a1)
	addi t1, t1, -1
	addi a1, a1, 1
	beq t1, x0, .read_line_fail_with_null
	j .read_line_continue

.read_line_eof_ok:
	la t1, _stdin_iseof
	li t0, 1
	sw t0, 0(t1)
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




// Input:  a0: string
// Output: a0: number (base-10, signed) / a1: pointer to end of string.
// Clobber: t0, t1, t2
atoi_eptr:
	// Pull-off whitespace.
	li t2, 1
	beq a0, x0, .atoiabort
	addi a1, a0, -1
	li a0, 0
.aotiloop:
	addi a1, a1, 1
	lbu t0, 0(a1)
	beq t0, x0, .atoiabort
	li t1, '-'
	beq t0, t1, .negativeskip
	li t1, '0'
	blt t0, t1, .aotiloop
	li t1, '9'+1
	bge t0, t1, .aotiloop
	li t2, 0 // Not negative.
.atoigo:
	// t2 = 1 for negative, 0 for positive.

	// t0 is character in question.
	addi t0, t0, -'0'
	li t1, 10
	mul a0, a0, t1
	add a0, a0, t0 // running = running * 10 + new char
.negativeskip:
	addi a1, a1, 1
	lbu t0, 0(a1)
	beq t0, x0, .atoiend
	li t1, '0'
	blt t0, t1, .atoiend
	li t1, '9'
	blt t1, t0, .atoiend
	j .atoigo
.atoiabort:
	li a0, 0
.atoiend:
	bne t2, x0, .atoiinvertneg
	// a0 is number to return
	// a1 is pointer to end of string.
	ret
.atoiinvertneg:
	sub a0, x0, a0
	ret