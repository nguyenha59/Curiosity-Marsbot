#Nguyen Thi Ha
.eqv IN_ADRESS_HEXA_KEYBOARD 0xFFFF0012
.eqv OUT_ADRESS_HEXA_KEYBOARD 0xFFFF0014
.eqv KEY_CODE 0xFFFF0004 		# ASCII code from keyboard, 1 byte
.eqv KEY_READY 0xFFFF0000 	# =1 if has a new keycode ?
			#Auto clear after lw

.eqv HEADING 0xffff8010 		# Integer: An angle between 0 and 359
 			# 0 : North (up)
 			# 90: East (right)
			# 180: South (down)
			# 270: West (left)
.eqv MOVING 0xffff8050 		# Boolean: whether or not to move
.eqv LEAVETRACK 0xffff8020 	# Boolean (0 or non-0):
 			# whether or not to leave a track
.eqv WHEREX 0xffff8030 		# Integer: Current x-location of MarsBot
.eqv WHEREY 0xffff8040 		# Integer: Current y-location of MarsBot


# Key value
#0-3
	.eqv KEY_0 0x11
	.eqv KEY_1 0x21
	.eqv KEY_2 0x41
	.eqv KEY_3 0x81
#4-7
	.eqv KEY_4 0x12
	.eqv KEY_5 0x22
	.eqv KEY_6 0x42
	.eqv KEY_7 0x82
#8-b
	.eqv KEY_8 0x14
	.eqv KEY_9 0x24
	.eqv KEY_a 0x44
	.eqv KEY_b 0x84
#c-f
	.eqv KEY_c 0x18
	.eqv KEY_d 0x28
	.eqv KEY_e 0x48
	.eqv KEY_f 0x88

#-------------------------------------------------------------------------------
.data
        #Funtion code
	ChuyenDong: .asciiz "1b4" # command code
	DungLai: .asciiz "c68"
	ReTrai: .asciiz "444"
        RePhai: .asciiz "666"
	DeVet: .asciiz "dad"
	DungDeVet: .asciiz "cbc"
	DiNguoc: .asciiz "999"
	MaLoi:  .asciiz "Ma khong hop le!"
 		
	going: .word 0
	tracking: .word 0
 
	InputCode: .space 8  	
	CodeLong: .word 0  		
 	InputCode1: .space 8 	
 	#chia Path thanh:
	toado_x: .word 0 : 16 
	toado_y: .word 0 : 16 
	huongdi: .word 0 : 16
	PathLong: .word 4  		
	a_current: .word 0 

.text
main: 
li $k0, KEY_CODE
 	li $k1, KEY_READY
#---------------------------------------------------------
# Enable the interrupt of Keyboard matrix 4x4 of Digital Lab Sim
#---------------------------------------------------------
	li $t1, IN_ADRESS_HEXA_KEYBOARD
	li $t3, 0x80 # bit 7 = 1 to enable
	sb $t3, 0($t1)
#---------------------------------------------------------
 
#cai dat vi tri ban dau
setting: 

	# x = 0; y = 0; a = 90
	lw $t7, PathLong # PathLong += 4
	addi $t7, $zero, 4
	sw $t7, PathLong
 
	li $t7, 90
	sw $t7, a_current 
	jal ROTATE
	nop
 
	sw $t7, huongdi # huongdi[0] = 90
 
	j waitForKey

#---------------------------------------------------------
 
Error: 
	li $v0, 4
	la $a0, MaLoi
	syscall
#---------------------------------------------------------
   
Print: 
	li $v0, 4
	la $a0, InputCode
	syscall
	j resetInput

resetInput: 
	jal Delete   
	nop   

#---------------------------------------------------------
 
waitForKey: 
	lw $t5, 0($k1)   # $t5 = [$k1] = KEY_READY
	beq $t5, $zero, waitForKey  # if $t5 == 0 -> Polling 
	nop
	beq $t5, $zero, waitForKey
 
readKey: 
	lw $t6, 0($k0)   # $t6 = [$k0] = KEY_CODE
	beq $t6, 0x8, resetInput  # if $t6 != 'ENTER' -> Polling
	
	bne $t6, 0x0a, waitForKey  
	nop
	bne $t6, 0x0a, waitForKey
	
#Cac code chuc nang
#--------------------------------------------------------------------------------------------------	
#Chuong trinh con thuc hien ma code vua nhan tu digital lab sim	
checkInput: 
	lw $s2, CodeLong   # CodeLong != 3 -> invalid code
	bne $s2, 3, Error
  
	la $s3, ChuyenDong
	jal Equal
	beq $t0, 1, CodeGo
  
	la $s3, DungLai
	jal Equal
	beq $t0, 1, CodeStop
  
	la $s3, ReTrai
	jal Equal
	beq $t0, 1, CodeLeft
 
	la $s3, RePhai
	jal Equal
	beq $t0, 1, CodeRight
 
	la $s3, DeVet
	jal Equal
	beq $t0, 1, CodeTrack

	la $s3, DungDeVet
	jal Equal
	beq $t0, 1, CodeUntrack
 
	la $s3, DiNguoc
	jal Equal
	beq $t0, 1, CodeReturn
	nop
 
	j Error
 
#--------------------------------------------
CodeGo:  
	jal strcpy 	
	jal GO 		
	j Print
#--------------------------------------------  
CodeStop:  
	jal strcpy
	jal STOP
	j Print
#--------------------------------------------
CodeTrack:  
	jal strcpy
	jal TRACK
	j Print
#-------------------------------------------- 
CodeUntrack: 
	jal strcpy
	jal UNTRACK
	j Print

#--------------------------------------------   
CodeRight:
	jal strcpy
	lw $t7, going
	lw $s0, tracking
 
	jal STOP
	nop
	jal UNTRACK
	nop
 
	la $s5, a_current
	lw $s6, 0($s5)  # $s6 is heading at now
	addi $s6, $s6, 90 # increase alpha by 90*
	sw $s6, 0($s5)  # update a_current
 
	jal storePath
	jal ROTATE
 
	beqz $s0, noTrack1
	nop
	jal TRACK
	noTrack1: nop
 
	beqz $t7, noGo1
	nop
	jal GO
noGo1: 
	nop
	j Print 
 
#--------------------------------------------  
CodeLeft: 
	jal strcpy
	lw $t7, going
	lw $s0, tracking
 
	jal STOP
	nop
	jal UNTRACK
	nop

	la $s5, a_current
	lw $s6, 0($s5)  # $s6 is heading at now
	addi $s6, $s6, -90 # decrease alpha by 90*
	sw $s6, 0($s5)  # update a_current
 
	jal storePath
	jal ROTATE
 
	beqz $s0, noTrack2
	nop
	jal TRACK
	noTrack2: nop
 
	beqz $t7, noGo2
	nop
	jal GO
noGo2: 
	nop
	j Print 

#--------------------------------------------
CodeReturn:
	jal strcpy
	li $t7, IN_ADRESS_HEXA_KEYBOARD # Disable interrupts when going backward
    	sb $zero, 0($t7)

	lw $s5, PathLong  # $s5 = CodeLong
	jal UNTRACK
	jal GO
 
begin: 
	addi $s5, $s5, -4   # CodeLong-- 
	lw $s6, huongdi($s5)  # $s6 = huongdi[CodeLong]
	addi $s6, $s6, 180  # $s6 = the reverse direction of alpha
	sw $s6, a_current
	jal ROTATE
	nop

	lw $t9, toado_x($s5)  # $t9 = toado_x[i] 
	lw $t7, toado_y($s5)  # $t9 = toado_y[i]
 
Go_to_first_point_of_edge:
	li $t8, WHEREX   # $t8 = x_current
	lw $t8, 0($t8)
	
	bne $t8, $t9, Go_to_first_point_of_edge # x_current == toado_x[i]
	nop   
	bne $t8, $t9, Go_to_first_point_of_edge
  
	li $t8, WHEREY   # $t8 = y_current
	lw $t8, 0($t8)
	
	bne $t8, $t7, Go_to_first_point_of_edge # y_current == toado_y[i]
	nop    
	bne $t8, $t7, Go_to_first_point_of_edge # y_current == toado_y[i]
 
	beq $s5, 0, finish # PathLong == 0
	nop    # -> end

	j begin  # else -> turn
 
finish: 
	jal STOP
	sw $zero, a_current  # update heading
	jal ROTATE
 
	addi $s5, $zero, 4
	sw $s5, PathLong  # reset PathLong = 0
 
	j Print
 
#-----------------------------------------------------------
#luu lai vi tri hien tai va huong di cua marsbot
#-----------------------------------------------------------

storePath: 
        #backup
	addi $sp, $sp, 4   
	sw $t1, 0($sp)
	addi $sp, $sp, 4
	sw $t2, 0($sp)
	addi $sp, $sp, 4
	sw $t3, 0($sp)
	addi $sp, $sp, 4
	sw $t4, 0($sp)
	addi $sp, $sp, 4
	sw $s1, 0($sp)
	addi $sp, $sp, 4
	sw $s2, 0($sp)
	addi $sp, $sp, 4
	sw $s3, 0($sp)
	addi $sp, $sp, 4
	sw $s4, 0($sp)
 
	lw $s1, WHEREX   # s1 = x 
	lw $s2, WHEREY   # s2 = y
	lw $s4, a_current  # s4 = a_current
	
	lw $t3, PathLong  # $t3 = PathLong
	sw $s1, toado_x($t3)  # store: x, y, alpha
	sw $s2, toado_y($t3)
	sw $s4, huongdi($t3)
	
	addi $t3, $t3, 4   # update long
	sw $t3, PathLong
	
	#restore
	lw $s4, 0($sp)   
	addi $sp, $sp, -4
	lw $s3, 0($sp)
	addi $sp, $sp, -4
	lw $s2, 0($sp)
	addi $sp, $sp, -4
	lw $s1, 0($sp)
	addi $sp, $sp, -4
	lw $t4, 0($sp)
	addi $sp, $sp, -4
	lw $t3, 0($sp)
	addi $sp, $sp, -4
	lw $t2, 0($sp)
	addi $sp, $sp, -4
	lw $t1, 0($sp)
	addi $sp, $sp, -4
	
	jr $ra  

#===============================================================================
#Cac chuc nang cua Marsbot		
#-----------------------------------------------------------------------------
# GO procedure, to start running
# param[in] none
#-----------------------------------------------------------
GO:   
        #backup
	addi $sp, $sp, 4  
	sw $at, 0($sp)
	addi $sp, $sp, 4
	sw $k0, 0($sp)

	li $at, MOVING   # change MOVING port
	addi $k0, $zero, 1  # to logic 1,
	sb $k0, 0($at)   # to start running
	
	li $t7, 1   # going = 0
	sw $t7, going  
	
	#restore
	lw $k0, 0($sp)  
	addi $sp, $sp, -4
	lw $at, 0($sp)
	addi $sp, $sp, -4
 
	jr $ra
#-----------------------------------------------------------
# STOP procedure, to stop running
# param[in] none
#-----------------------------------------------------------
STOP:  
        #backup
	addi $sp, $sp, 4   
	sw $at, 0($sp)
	
	li $at, MOVING   # change MOVING port to 0
	sb $zero, 0($at)  # to stop
	
	sw $zero, going  # going = 0
	
	#restore
	lw $at, 0($sp)   
	addi $sp, $sp, -4
 
	jr $ra
 
#-----------------------------------------------------------
# TRACK procedure, to start drawing line
# param[in] none
#-----------------------------------------------------------
TRACK:  
        #backup
	addi $sp, $sp, 4   
	sw $at, 0($sp)
	addi $sp, $sp, 4
	sw $k0, 0($sp)

	li $at, LEAVETRACK  # change LEAVETRACK port
	addi $k0, $zero,1  # to logic 1,
	sb $k0, 0($at)   # to start tracking
	
	addi $s0, $zero, 1
	sw $s0, tracking
	
	#restore
	lw $k0, 0($sp)   
	addi $sp, $sp, -4
	lw $at, 0($sp)
	addi $sp, $sp, -4
    
	jr $ra
 
#-----------------------------------------------------------
# UNTRACK procedure, to stop drawing line
# param[in] none
#-----------------------------------------------------------
UNTRACK:  
        #restore
	addi $sp, $sp, 4  
	sw $at, 0($sp)
	
	li $at, LEAVETRACK # change LEAVETRACK port to 0
	sb $zero, 0($at) # to stop drawing tail
	
	sw $zero, tracking
	
	#backup
	lw $at, 0($sp)  
	addi $sp, $sp, -4
    
	jr $ra

#-----------------------------------------------------------
# ROTATE_RIGHT procedure, to control robot to rotate
# param[in] HuongDi variable, store heading at present
#-----------------------------------------------------------
ROTATE: 
        #backup
	addi $sp, $sp, 4  
	sw $t1, 0($sp)
	addi $sp, $sp, 4
	sw $t2, 0($sp)
	addi $sp, $sp, 4
	sw $t3, 0($sp)
	
	li $t1, HEADING # change HEADING port
	la $t2, a_current
	lw $t3, 0($t2)  # $t3 is heading at now
	sw $t3, 0($t1)  # to rotate robot
	
	#restore
	lw $t3, 0($sp)  
	addi $sp, $sp, -4
	lw $t2, 0($sp)
	addi $sp, $sp, -4
	lw $t1, 0($sp)
	addi $sp, $sp, -4
   
	jr $ra
 

#-----------------------------------------------------------     
#Code check xem ma code nhan duoc va ma code theo dau bai cho co dung format hay khong	
#Luc nay $s3 se chua dia chi co cac code chuc nang theo format da cho
#$t0 la output neu code nhan vao dung format se tra ve 1, nguoc lai la 0	
Equal: 
	addi $sp, $sp, 4   # back up
	sw $t1, 0($sp)
	addi $sp, $sp, 4
	sw $s1, 0($sp)
	addi $sp,$sp,4
	sw $t2, 0($sp)
	addi $sp, $sp, 4
	sw $t3, 0($sp)
	
	xor $t0, $zero, $zero  # $t0 = return value = 0
	xor $t1, $zero, $zero  # $t1 = i = 0
 
Equal_loop: 
	beq $t1, 3, Equal_equal  # if i = 3 -> end loop -> equal
	nop
	
	lb $t2, InputCode($t1)  # $t2 = InputCode[i]
	
	add $t3, $s3, $t1  # $t3 = s + i
	lb $t3, 0($t3)   # $t3 = s[i]
	
	beq $t2, $t3, Equal_next  # if $t2 == $t3 -> continue the loop
	nop
	
	j Equal_end

Equal_next: 
	addi $t1, $t1, 1
	j Equal_loop

Equal_equal: 
	add $t0, $zero, 1  # i++

Equal_end: 
        #restock
	lw $t3, 0($sp)   
	addi $sp, $sp, -4
	lw $t2, 0($sp)
	addi $sp, $sp, -4
	lw $s1, 0($sp)
	addi $sp, $sp, -4
	lw $t1, 0($sp)
	addi $sp, $sp, -4

	jr $ra

#-----------------------------------------------------------    
Delete: 
        #backup
	addi $sp, $sp, 4   
	sw $t1, 0($sp)
	addi $sp, $sp, 4 
	sw $t2, 0($sp) 
	addi $sp, $sp, 4 
	sw $s1, 0($sp)
	addi $sp, $sp, 4
	sw $t3, 0($sp)
	addi $sp, $sp, 4 
	sw $s2, 0($sp)
	
	#processing
	lw $t3, CodeLong   # $t3 = CodeLong
	addi $t1, $zero, -1  # $t1 = -1 = i
    
Delete_loop: 
	addi $t1, $t1, 1   # i++ 
	sb $zero, InputCode  # InputCode[i] = '\0'
	    
	bne $t1, $t3, Delete_loop # if $t1 <=3 resetInput loop
	nop
	    
	sw $zero, CodeLong  # reset CodeLong = 0
 
Delete_end: 
        #restore
	lw $s2, 0($sp)  
	addi $sp, $sp, -4
	lw $t3, 0($sp)
	addi $sp, $sp, -4
	lw $s1, 0($sp)
	addi $sp, $sp, -4
	lw $t2, 0($sp)
	addi $sp, $sp, -4
	lw $t1, 0($sp)
	addi $sp, $sp, -4
	
	jr $ra
	
#-----------------------------------------------------------   
strcpy:
        #backup
	addi $sp, $sp, 4   
	sw $t1, 0($sp)
	addi $sp, $sp, 4 
	sw $t2, 0($sp) 
	addi $sp, $sp, 4 
	sw $s1, 0($sp)
	addi $sp, $sp, 4
	sw $t3, 0($sp)
	addi $sp, $sp, 4 
	sw $s2, 0($sp)
	
	#processing
	li $t2, 0
	la $s1, InputCode1
	la $s2, InputCode
	
strcpy_loop:
	beq $t2, 3, strcpy_end
	
	lb $t1, 0($s2)
	sb $t1, 0($s1)
	
	addi $s1, $s1, 1
	addi $s2, $s2, 1
	addi $t2, $t2, 1
	
	j strcpy_loop
	
strcpy_end: 
        #restore
	lw $s2, 0($sp)   
	addi $sp, $sp, -4
	lw $t3, 0($sp)
	addi $sp, $sp, -4
	lw $s1, 0($sp)
	addi $sp, $sp, -4
	lw $t2, 0($sp)
	addi $sp, $sp, -4
	lw $t1, 0($sp)
	addi $sp, $sp, -4
	
	jr $ra	

#--------------------------------------------------------------------
		
				
#Nhan code input
#---------------------------------------------------------------
#===============================================================================
# GENERAL INTERRUPT SERVED ROUTINE for all interrupts
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.ktext 0x80000180
#-------------------------------------------------------
# SAVE the current REG FILE to stack
#-------------------------------------------------------
backup: 
	addi $sp,$sp,4
	sw $ra,0($sp)
	addi $sp,$sp,4
	sw $t1,0($sp)
	addi $sp,$sp,4
	sw $t2,0($sp)
	addi $sp,$sp,4
	sw $t3,0($sp)
	addi $sp,$sp,4
	sw $a0,0($sp)
	addi $sp,$sp,4
	sw $at,0($sp)
	addi $sp,$sp,4
	sw $s0,0($sp)
	addi $sp,$sp,4
	sw $s1,0($sp)
	addi $sp,$sp,4
	sw $s2,0($sp)
	addi $sp,$sp,4
	sw $s4,0($sp)
	addi $sp,$sp,4
	sw $t4,0($sp)
	addi $sp,$sp,4
	sw $s3,0($sp)
#--------------------------------------------------------
# Processing
#--------------------------------------------------------
get_cod:
	li $t1, IN_ADRESS_HEXA_KEYBOARD
	li $t2, OUT_ADRESS_HEXA_KEYBOARD
scan_row1:
	li $t3, 0x11
	sb $t3, 0($t1)
	lbu $a0, 0($t2)
	bnez $a0, get_code_in_char
scan_row2:
	li $t3, 0x12
	sb $t3, 0($t1)
	lbu $a0, 0($t2)
	bnez $a0, get_code_in_char
scan_row3:
	li $t3, 0x14
	sb $t3, 0($t1)
	lbu $a0, 0($t2)
	bnez $a0, get_code_in_char
scan_row4:
	li $t3, 0x18
	sb $t3, 0($t1)
	lbu $a0, 0($t2)
	bnez $a0, get_code_in_char

get_code_in_char:
	beq $a0, KEY_0, case_0
	beq $a0, KEY_1, case_1
	beq $a0, KEY_2, case_2
	beq $a0, KEY_3, case_3
	beq $a0, KEY_4, case_4
	beq $a0, KEY_5, case_5
	beq $a0, KEY_6, case_6
	beq $a0, KEY_7, case_7
	beq $a0, KEY_8, case_8
	beq $a0, KEY_9, case_9
	beq $a0, KEY_a, case_a
	beq $a0, KEY_b, case_b
	beq $a0, KEY_c, case_c
	beq $a0, KEY_d, case_d
	beq $a0, KEY_e, case_e
	beq $a0, KEY_f, case_f
 
case_0: 
	li $s0, '0'  
	j store_code
case_1: 
	li $s0, '1'
	j store_code
case_2: 
	li $s0, '2'
	j store_code
case_3: 
	li $s0, '3'
	j store_code
case_4: 
	li $s0, '4'
	j store_code
case_5: 
	li $s0, '5'
	j store_code
case_6: 
	li $s0, '6'
	j store_code
case_7: 
	li $s0, '7'
	j store_code
case_8: 
	li $s0, '8'
	j store_code
case_9: 
	li $s0, '9'
	j store_code
case_a: 
	li $s0, 'a'
	j store_code
case_b: 
	li $s0, 'b'
	j store_code
case_c: 
	li $s0, 'c'
	j store_code
case_d: 
	li $s0, 'd'
	j store_code
case_e: 
	li $s0, 'e'
	j store_code
case_f: 
	li $s0, 'f'
	j store_code
 
store_code: 
	la $s1, InputCode
	la $s2, CodeLong
	lw $s3, 0($s2)   # $s3 = strlen(InputCode)
	addi $t4, $t4, -1   # $t4 = i 

store_code1: 
	addi $t4, $t4, 1
	bne $t4, $s3, store_code1
	add $s1, $s1, $t4  # $s1 = InputCode + i
	sb $s0, 0($s1)   # InputCode[i] = $s0
    
	addi $s0, $zero, '\n'  # add '\n' character to end of string
	addi $s1, $s1, 1
	sb $s0, 0($s1)
    
	addi $s3, $s3, 1
	sw $s3, 0($s2)   # update CodeLong
  
#--------------------------------------------------------
# Evaluate the return address of main routine
# epc <= epc + 4
#--------------------------------------------------------
next_pc:
	mfc0 $at, $14  # $at <= Coproc0.$14 = Coproc0.epc
	addi $at, $at, 4  # $at = $at + 4 (next instruction)
	mtc0 $at, $14  # Coproc0.$14 = Coproc0.epc <= $at
#--------------------------------------------------------
# RESTORE the REG FILE from STACK
#--------------------------------------------------------
restore: 
	lw $s3, 0($sp)
	addi $sp, $sp, -4
	lw $t4, 0($sp)
	addi $sp, $sp, -4
	lw $s2, 0($sp)
	addi $sp, $sp, -4
	lw $s1, 0($sp)
	addi $sp, $sp, -4
	lw $s0, 0($sp)
	addi $sp, $sp, -4
	lw $at, 0($sp)
	addi $sp, $sp, -4
	lw $a0, 0($sp)
	addi $sp, $sp, -4
	lw $t3, 0($sp)
	addi $sp, $sp, -4
	lw $t2, 0($sp)
	addi $sp, $sp, -4
	lw $t1, 0($sp)
	addi $sp, $sp, -4
	lw $ra, 0($sp)
	addi $sp, $sp, -4
return: eret # Return from exception
