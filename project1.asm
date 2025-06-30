.data
curr_base: .asciiz "Enter the current system: "
next_base: .asciiz "Enter the new system: "
num: .asciiz "Enter the number: "
output_message: .asciiz "The number in the new system: "
invalid_num: .asciiz "Invalid number for base "
error_msg: .asciiz "Conversion error"
newline: .asciiz "\n"

buffer: .space 32          
digits: .space 32          
result: .space 32         

.text
.globl main
main:
   
    li $v0, 4
    la $a0, curr_base
    syscall
    li $v0, 5
    syscall
    move $s1, $v0

    li $v0, 4
    la $a0, num
    syscall
    li $v0, 8
    la $a0, buffer
    li $a1, 32
    syscall

    # remove the newline character
    la $a0, buffer
remove_newline:
    lb $t2, 0($a0)
    beq $t2, $zero, done_remove
    beq $t2, 0x0A, set_null_terminator
    addi $a0, $a0, 1
    j remove_newline
set_null_terminator:
    sb $zero, 0($a0)
done_remove:
    # count size of buffer
    li $t0, 0
    la $a0, buffer
count_size:
    lb $t2, 0($a0)
    beq $t2, $zero, done_count
    addi $t0, $t0, 1
    addi $a0, $a0, 1
    j count_size
done_count:
    move $t5, $t0           # $t5 holds the size of the number

    # validate number and store digits
    la $a0, buffer
    move $a1, $s1           # current base
    la $a2, digits
    jal numToArray          # convert the number to an array 
    beq $v0, -1, invalid_number 

    li $v0, 4
    la $a0, next_base
    syscall
    li $v0, 5
    syscall
    move $s2, $v0


    move $a0, $s1           # current base
    la $a1, digits          # address of the digits array that holds the number
    jal OtherToDecimal
    beq $v0, -1, conversion_error

 
    move $a0, $s2           # target base
    move $a1, $v0           # decimal number (result from OtherToDecimal)
    jal DecimalToOther

    j end_program

conversion_error:
    li $v0, 4
    la $a0, error_msg
    syscall
    li $v0, 10
    syscall

invalid_number:
    li $v0, 4
    la $a0, invalid_num
    syscall
    li $v0, 1
    move $a0, $s1
    syscall
    li $v0, 10
    syscall

end_program:
    li $v0, 10
    syscall

numToArray:
    li $t0, 0              # $t0 -> size of valid digits array
    move $a0, $a0          
    move $t1, $t5          # $t1 -> size of the buffer
    add $a0, $a0, $t1     
    addi $a0, $a0, -1     

numToArray_loop:
    beq $t1, $zero, numToArray_done  
    lb $t2, 0($a0)                   
    beq $t2, $zero, numToArray_done     
    # check if character is a digit (0-9)
    blt $t2, '0', alphacheck
    bgt $t2, '9', alphacheck
    sub $t3, $t2, '0'                # $t3 = ascii - '0'
    j valid_digit

alphacheck:

    li $t4, 'A'
    blt $t2, $t4, invalid_digit
    li $t4, 'F'
    bgt $t2, $t4, invalid_digit
    sub $t3, $t2, 'A'      # $t3 = ascii - 'A'
    addi $t3, $t3, 10      # adjust for 10-15 range

valid_digit:
    bge $t3, $a1, invalid_digit  
    sb $t3, 0($a2)         # store valid numeric value in digits array
    addi $a2, $a2, 1      
    addi $t0, $t0, 1       
    addi $a0, $a0, -1    
    addi $t1, $t1, -1      
    j numToArray_loop      

invalid_digit:
    li $v0, -1           
    jr $ra                 

numToArray_done:
    move $v0, $t0
    jr $ra


OtherToDecimal:
    li $v0, 0              # initialize result = 0
    li $t6, 1              # initialize power (base^0)


convert_loop:
    lb $t8, 0($a1)         
    beq $t0, $zero, end_convert  
    mul $t9, $t8, $t6      # $t9 = digit * power
    add $v0, $v0, $t9      
    mul $t6, $t6, $a0      # power *= base (base^n)
    addi $a1, $a1, 1 
    addi $t0, $t0, -1  

    j convert_loop

end_convert:
    jr $ra



DecimalToOther:
    li $t0, 0              # initialize index for result array
    li $t3, 0            

Convert_loop:
    beq $a1, $zero, print_digits  
    divu $t1, $a1, $a0     # divide decimal number by target base
    mfhi $t3               # get remainder (current digit)
    mflo $a1               # update quotient
    sb $t3, result($t0)    # store remainder in result array
    addi $t0, $t0, 1     
    j Convert_loop

# print the converted number
print_digits:
    move $t1, $t0
    addi $t1, $t1, -1 
    li $v0, 4
    la $a0, output_message
    syscall

print_loop:
    lb $a0, result($t1)
    blt $a0, 10, print_digit # for digits
    addi $a0, $a0, 55        # for characters
    j print_char

print_digit:
    addi $a0, $a0, 48

print_char:
    li $v0, 11
    syscall
    addi $t1, $t1, -1
    bgez $t1, print_loop 
    jr $ra