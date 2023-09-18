.global main			#main method global scope
.text				#program instructions

main:  #sets up the handler by enabling interrupts  and backing up $evec 
	movsg $2, $evec		#copy the old handler to $2
	sw $2, old_vector($0)	#store the old vector in the variable old_vector
	
	la $2, handler		#load the address of our handler
	movgs $evec, $2		#store it to $evec as the new location

	movsg $2, $cctrl 	#copy the value of $cctrl into $2
	andi $2, $2, 0x000f	#mask all interrupts
	
	ori $2, $2, 0xc2	#enable IRQ2 adn IRQ3 and IE
	movgs $cctrl, $2	#copy back to $cctrl the new cpu control
	
	sw $0, 0x72003($0)	#acknowledge any interupts from timer
	sw $0, 0x73005($0)	#acknowledge any interrupts from parallel interface
	
	addi $9, $0, 24	
	sw $9, 0x72001($0)	#store 24 auto load value in
	
	addi $9, $0, 0x2  		
	sw $9, 0x72000($0)	#enable the autorestart
	
	addi $10, $0, 0x3
	sw $10, 0x73004($0)	#turn on parallel interrupts

loop:			#termiates the program if the flag is set(to zero) and displays if write flag is set
	lw $3, flag($0)			#load in the flag for terminating
	beqz $3, end			#if it is zero branch to end
	
	lw $3, write($0)		#if the flag for write hasnt been set branch to output it
	bnez $3, display		#branch to display if it hasnt been set
	
check_r:				#transmits the \r char to serial port 2
	#polled i/o for the serial port 2
	lw $3, 0x71003($0)
	andi $3, $3, 0x2		#check if the tds bit is set
	beqz $3, check_r		#if not loop up and try again
	
	addi $3, $0, '\r'		#load in the \r char
	sw $3, 0x71000($0)		#transmit the character to serial port 2
	addi $3, $0, 1		
	sw $3, write($0)		#turn off the flag(by setting it to 1)	
	
	
check_n:				#transmits the \n char to serial port 2
	#polled i/o for the serial port 2
	lw $3, 0x71003($0)
	andi $3, $3, 0x2		 #check if the tds bit is set
	beqz $3, check_n		#if not loop up and try again
	
	addi $3, $0, '\n'		#load in the \n char
	sw $3, 0x71000($0)		#transmit the character to serial port 2
	
	addi $3, $0, 1		
	sw $3, write($0)		#turn off the flag	
	
	
check_ten_sec:				#transmits the the tens secounds char to serial port 2
	lw $3, 0x71003($0)
	andi $3, $3, 0x2		 #check if the tds bit is set
	beqz $3, check_ten_sec		#if not loop up and try again
	
	lw $3, counter($0)		#load in the counter variable
	divui $3, $3, 1000		#divide it by 1000
	addi $3, $3, 48			#add 48 to convert it to ascii
	
	sw $3, 0x71000($0)		#transmit the character to serial port 2
	
	addi $3, $0, 1		
	sw $3, write($0)		#turn off the flag
	
check_one_sec:				#transmits the the ones secounds char to serial port 2
	lw $3, 0x71003($0)
	andi $3, $3, 0x2		#check if the tds bit is set
	beqz $3, check_one_sec		#if not loop up and try again
	
	lw $3, counter($0)		#load in the counter variable
	divui $3, $3, 100		#divide it by 100
	remi $3, $3, 10			#mod it by 10
	
	addi $3, $3, 48			#add 48 to convert it to ascii
	
	sw $3, 0x71000($0)		#transmit the character to serial port 2
	
	addi $3, $0, 1		
	sw $3, write($0)		#turn off the flag

check_dot:				#transmits the the ones secounds char to serial port 2
	lw $3, 0x71003($0)
	andi $3, $3, 0x2		#check if the tds bit is set
	beqz $3, check_dot		#if not loop up and try again
	
	addi $3, $0, 46			#store in $3 the ascii for a dot
	
	sw $3, 0x71000($0)		#transmit the character to serial port 2
	
	addi $3, $0, 1		
	sw $3, write($0)		#turn off the flag
		
check_dec_one:				#transmits the first decimal char to serial port 2
	lw $3, 0x71003($0)
	andi $3, $3, 0x2		 #check if the tds bit is set
	beqz $3, check_dec_one		#if not loop up and try again
	
	lw $3, counter($0)		#load in the counter variable
	divui $3, $3, 10		#divide it by 10
	remi $3, $3, 10			#mod it by 10
	
	addi $3, $3, 48			#add 48 to convert it to ascii
	
	sw $3, 0x71000($0)		#transmit the character to serial port 2
	
	addi $3, $0, 1		
	sw $3, write($0)		#turn off the flag
	
check_dec_two:				#transmits the second decimal char to serial port 2
	lw $3, 0x71003($0)
	andi $3, $3, 0x2		 #check if the tds bit is set
	beqz $3, check_dec_two		#if not loop up and try again
	
	lw $3, counter($0)		#load in the counter variable
	remi $3, $3, 10			#mod it by 10
	
	addi $3, $3, 48			#add 48 to convert it to ascii
	
	sw $3, 0x71000($0)		#transmit the character to serial port 2
	
	addi $3, $0, 1		
	sw $3, write($0)		#turn off the flag	
	
	
	
display:				#display the value of counter to ssd
	lw $3, counter($0)		#read in the value from counter
	divui $3, $3, 100
	
	divui $4, $3, 10		#divide it by 10 to get the leftmost digit
	remi $5, $4, 10			#mod divide it by 10 to get the left digit
	
	remi $6, $3, 10			#mod divide it by 10 to get the right digit
	
	sw $5, 0x73008($0)		#store the left digit in the left lower ssd
	sw $6, 0x73009($0)		#store the right digit in the right lower ssd

	j loop				#jump back to loop
	
handler:				#handler for exceptions
	movsg $13, $estat		#get the exception stslow operaatus register
	andi $13, $13, 0xffb0		#check if its IRQ2 by masking everything but 1
	beqz $13, user_interrupt	#if its zero only IRQ2 is 1, branch to uir
	
	movsg $13, $estat		#get the exception status register
	andi $13, $13, 0xff70		#check if its IRQ3 by masking everything but 1
	beqz $13, parallel_interrupt	#if its zero only IRQ3 is 1, branch to uir
	
	
	lw $13, old_vector($0)		#otherwise jump to the default handler
	jr $13				#jump to the old handler
	
parallel_interrupt:			#parallel interrupt handler
	sw $0, 0x73005($0)
	
	lw $13, 0x73001($0)		#loads into $13 the parallel push buttonr register contents
	beqz $13, switches_on		#if the result is zero branch to switches_on to return
	
	andi $13, $13, 1		#and it with 1 to see if button zero was pressed
	sequi $13, $13, 1		#if its one set $13 to 1
	bnez $13, button_zero		#if not equal to zero branch to button zero
	
	lw $13, 0x73001($0)		#loads into $13 the parallel push buttonr register contents
	andi $13, $13, 2		#and it with 2 to see if button one was pressed
	sequi $13, $13, 2		#if its 2 set $13 to 1
	bnez $13, button_one		#if not equal to zero branch to button one
	
	lw $13, 0x73001($0)		#loads into $13 the parallel push buttonr register contents
	andi $13, $13, 4		#and it with 4 to see if button two was pressed
	sequi $13, $13, 4		#if its 4 set $13 to 1
	bnez $13, button_two		#if not equal to zero branch to button two
	
button_zero:				#start or stop the stopwatch
	lw $13, 0x72000($0)		#load in the timer control register
	xori $13, $13, 1		#toggle the timer enable bit by xor with 1
	sw $13, 0x72000($0)		#store it in the timer control register
	rfe				#return from the exception
		
button_one:        			#reset the counter
	lw $13, 0x72000($0)         	#load in the timer control register
   	seqi $13, $13, 0x3         	
   	bnez $13, write_serial		#if the result is on do nothing and return
    	sw $0, counter($0)     		#store zero into the counter
    	rfe     			#return from the exception
    	 
button_two:				#terminate the program
	sw $0, flag($0)			#store zero in flag variable to endicate temination
	rfe				#return from the exception
	
	
write_serial:
	sw $0, write($0)		#set the flag for writing to the serial port 2
	rfe
	
switches_on:				#return from the exception label
	rfe
	
user_interrupt:
	sw $0, 0x72003($0)		#acknowledge the interrupt to turn it off
	
	lw $13, counter($0)		#increment the counter by 1
	addi $13, $13, 1
	sw $13, counter($0)
	
	rfe				#return from the exception
	
end:					#end the program
	jr $ra
	
.data
#counter variable
counter:
	.word 0
#location of our old $evec
old_vector:
	.word 0
#flag variable for when to end the program
flag:
	.word 1
#flag variable for when to write the time to serial port 2
write:
	.word 1
