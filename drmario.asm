################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Dr Mario.
#
# Student 1: Qi Wen Wei, 1010465168
# Student 2: Name, Student Number (if applicable)
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       64
# - Unit height in pixels:      32
# - Display width in pixels:    1
# - Display height in pixels:   1
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################
    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
# How long each row in the bitmap is
ROW_LENGTH:
    .word 64
# Color list
colors: .word 0x00ff00, 0xff0000, 0x0000ff, 0x000000  # Green, Red, Blue, Black

##############################################################################
# Mutable Data

# State of the current board
# Think of it as a 27x15 array.
# If a index at a array is 
board: .space 405 # 27 rows x 15 columns = 405
##############################################################################
# Code
##############################################################################
	.text
	.globl main
	
# Before beginning, here is some information for how I'm storing my data in the registers
# $s0 = base address for display
# $s1 = address to the board state
# $s3 = Pill 1 Position
# $s4 = Pill 2 Position
# For example: Say we have the pill like the following
#     B
#     B
# Then, in this case Pill 1 refers to the bottem one while Pill 2 refers to the top one
# For example: Say we have the pill like the following
#     BB
# Then, in this case Pill 1 refers to the left one while Pill 2 refers to the right one

# $s5 = Pill 1 Color
# $s6 = Pill 2 Color
# $s7 = Virus Color



    # Run the game.
main:
    lw $s0, ADDR_DSPL
    la $s1, board # Load in the basic board address to $s1
    
    # Instantiate the board as filled with zeros.
    la $t0, board
    li $t1, 405       # Total bytes to initialize (27*15 = 405)
    li $t2, 0         # Value to store (0)
    set_zero_board:
        beqz $t1, exit_zero_board     # Exit loop when counter ($t1) reaches 0
        sb $t2, 0( $t0 )    # Store 0 at current address
        addi $t0, $t0, 1  # Move to next byte
        addi $t1, $t1, -1 # Decrement counter
        j set_zero_board  # Repeat
    exit_zero_board:

    
    
    # Initialize the game
    jal instantiate_map # Save return address at $ra and calls instantiate map to build map
    
    # Draw the initalize position of the pill
    jal random_color
    addi $s4, $s0, 1428
    sw $s5, 0( $s4 )
    addi $s3, $s0, 1684
    sw $s6, 0( $s3 )
    
    j game_loop
    

# This function sets $s5 and $s6 as two random colors.
random_color: 
    li $v0, 42 # Syscall for random number generation
    li $a0, 0               # Use generator ID 0 (default)
    li $a1, 3 # Upper bound (exclusive): 3 (0, 1, or 2)
    syscall
    la $t3, colors # Load color array in
    sll $a0, $a0, 2
    add $t3, $t3, $a0 # Calculate address of new color
    lw $s5, 0( $t3 ) 
    
    li $v0, 42 # Syscall for random number generation
    li $a0, 0               # Use generator ID 0 (default)
    li $a1, 3 # Upper bound (exclusive): 3 (0, 1, or 2)
    syscall
    la $t3, colors # Load color array in
    sll $a0, $a0, 2
    add $t3, $t3, $a0 # Calculate address of new color
    lw $s6, 0( $t3 ) 
    
    jr $ra
    
# This function instializes the map boundaries
instantiate_map: 
    addi $sp, $sp, -4        # Allocate space on the stack
    sw $ra, 0($sp)           # Save the original return address
    
    li $t7, 0x808080 # $t1 = gray
    
    # Draw the left gray wall
    addi $t3, $zero, 1652 # t3 tracks the current location starting from the top
    addi $t4, $zero, 8052 # t4 is the bottem row
    wall_draw_left:
        beq $t3, $t4, wall_draw_left_end # Checks if reached the bottom yet.
        # This section draws it on the bitmap
        add $t5, $s0, $t3 # If it has not, update $t5 which is where we want to draw
        sw $t7, 0( $t5 ) # Draw the pixel
        addi $t3, $t3, 256 # Move down a row
        
        # This section adds it to the board state
        addi $a0, $t5, 0
        addi $a1, $zero, 1
        jal set_board_by_addr
        
        j wall_draw_left
    wall_draw_left_end:
    
    # Draw the right gray wall
    addi $t3, $zero, 1716 # t3 tracks the current location starting from the top
    addi $t4, $zero, 8116 # t4 is the bottem row
    wall_draw_right:
        beq $t3, $t4, wall_draw_right_end # Checks if reached the bottom yet.
        add $t5, $s0, $t3 # If it has not, update $t5 which is where we want to draw
        sw $t7, 0( $t5 ) # Draw the pixel
        addi $t3, $t3, 256 # Move down a row
        
        # This section adds it to the board state
        addi $a0, $t5, 0
        addi $a1, $zero, 1
        jal set_board_by_addr
        
        j wall_draw_right
    wall_draw_right_end:
    
    # Draw the bottom row
    addi $t3, $zero, 7796 # t3 tracks the current location starting from the left
    addi $t4, $zero, 7864 # t4 is the right part
    wall_bottom:
        beq $t3, $t4, wall_bottom_end # Checks if reached the bottom yet.
        add $t5, $s0, $t3 # If it has not, update $t5 which is where we want to draw
        sw $t7, 0( $t5 ) # Draw the pixel
        addi $t3, $t3, 4 # Move down a row
        j wall_bottom
    wall_bottom_end:

    # Draw the top row
    addi $t3, $zero, 1656 # t3 tracks the current location starting from the left
    addi $t4, $zero, 1680 # t4 is the right part
    wall_top_left: # Draw the left top part
        beq $t3, $t4, wall_top_left_end # Checks if reached the bottom yet.
        add $t5, $s0, $t3 # If it has not, update $t5 which is where we want to draw
        sw $t7, 0( $t5 ) # Draw the pixel
        addi $t3, $t3, 4 # Move down a row
        j wall_top_left
    wall_top_left_end: 
    addi $t3, $zero, 1692 # t3 tracks the current location starting from the left
    addi $t4, $zero, 1716 # t4 is the right part
    wall_top_right: #Draw the right top part
        beq $t3, $t4, wall_top_right_end # Checks if reached the bottom yet.
        add $t5, $s0, $t3 # If it has not, update $t5 which is where we want to draw
        sw $t7, 0( $t5 ) # Draw the pixel
        addi $t3, $t3, 4 # Move down a row
        j wall_top_right
    wall_top_right_end:
    
    # Now manually draw the top part
    addi $t3, $s0, 1420
    sw $t7, 0( $t3 )
    addi $t3, $s0, 1164
    sw $t7, 0( $t3 )
    addi $t3, $s0, 1436
    sw $t7, 0( $t3 )
    addi $t3, $s0, 1180
    sw $t7, 0( $t3 ) 
    
    lw $ra, 0($sp)           # Restore original return address
    addi $sp, $sp, 4         # Free stack space
    jr $ra                   # Return to main function



game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	# 4. Sleep
	
	# How do I draw the current pill falling? I erase it at the beginning of the game_loop. After all the information is proessed, then I draw that one again the end
	# Setting the current pill positions to black
      
    la $t3, colors
    addi $t3, $t3, 12
	sw $t3, 0( $s3 )
    sw $t3, 0( $s4 )
	
	
	# Checks if a key has been pressed.
	# If it has call keyboard_input
	lw $t0, ADDR_KBRD 
	lw $t8, 0( $t0 )
	beq $t8, 1, keybord_input
	
	# Updates the screen to show new changes
    update_board:
    
    
	sw $s5, 0( $s3 )
    sw $s6, 0( $s4 )
	
	# Pauses the program for 1 miliseconds
	li $v0, 32
    li $a0, 1
    syscall

	
    # 5. Go back to Step 1
    j game_loop

# Ok, so a lot of my logic is based on the idea of converting the values of (1142) which is the memory address over to a more easier and manipulatable variable.
# For example, 1912 would convert to (0,0) on the board. 

# Notice that our board is (27 x 15) with it starting from two higher than the top left of the jar.
# Finally, here are the keyboard inputs map to the commands.
# A and D are the standard moving left and right
# W is rotate
# S is move down


# Input: $a0 = address offset (e.g., 1912, 1428, etc.)
# Output: $v0 = X (row), $v1 = Y (column)
addr_to_board:
    sub $t8, $a0, 1140      # Subtract the board's top-left offset (1140)
    li $t9, 256             # Bytes per row (64 columns * 4 bytes per pixel)
    
    divu $t8, $t9 # Divide by bytes per row: X = quotient, remainder = column offset
    mflo $v0 # $v0 = X (row)
    mfhi $t2 # $t2 = column offset (bytes)
    srl $v1, $t2, 2 # Convert bytes to Y (columns): divide by 4 (since 4 bytes per pixel)
    
    jr $ra  # Return to caller

# Get the value at the index board[$a0][$a1].
# For example board[i][0] where i >= 2 is 5 because it's the wall.
get_val_at_board:
    mul $t8, $a0, 15
    add $t8, $t8, $a1 # Get the index in the board
    add $t8, $t8, $s1 # Get the address on the board
    lb $v0, 0 ($t8)
    jr $ra

# The two functions above finally allows us to define the next two functions. The first loads a value $a1 into the board at $a0. The second reads
#--------------------------------------------------------------
# Sets the board value corresponding to a bitmap address.
# Input: $a0 = bitmap address, $a1 = value to set
#--------------------------------------------------------------
set_board_by_addr:
    addi $sp, $sp, -4        # Allocate space on the stack
    sw $ra, 0($sp)           # Save the original return address


    sub $a0, $a0, $s0
    jal addr_to_board
    add $t0, $v0, $zero # X position of Pill 1 on board
    add $t1, $v1, $zero # Y position of Pill 1 on board
    
    mul $t8, $t0, 15
    add $t8, $t8, $t1 # Get the index in the board
    add $t8, $t8, $s1 # Get the address on the board
    sb $a1, 0 ($t8)   # Set value at the board
   
    lw $ra, 0($sp)           # Restore original return address
    addi $sp, $sp, 4         # Free stack space
    jr $ra                   # Return to caller
    
    
#--------------------------------------------------------------
# Gets the board value corresponding to a bitmap address.
# Input:  $a0 = bitmap address
# Output: $v0 = value at the board
#--------------------------------------------------------------
get_board_by_addr:
    addi $sp, $sp, -4        # Allocate space on the stack
    sw $ra, 0($sp)           # Save the original return address

    sub $a0, $a0, $s0
    jal addr_to_board
    add $a0, $v0, $zero # X position of Pill 1 on board
    add $a1, $v1, $zero # Y position of Pill 1 on board
    jal get_val_at_board
    
    lw $ra, 0($sp)           # Restore original return address
    addi $sp, $sp, 4         # Free stack space
    jr $ra                   # Return to caller
    
    
    
# Central function that handles all the keyboard inputs
keybord_input: 
    lw $a0, 4($t0)                  # Load second word from keyboard
    beq $a0, 0x71, respond_to_Q     # Check if the key 'q' was pressed
    beq $a0, 0x77, respond_to_W     # Check if the key 'w' was pressed
    beq $a0, 0x73, respond_to_S     # Check if the key 's' was pressed

    beq $a0, 0x61, respond_to_A     # Check if the key 'a' was pressed
    beq $a0, 0x64, respond_to_D     # Check if the key 'd' was pressed
    j update_board
    
    
# Exits program when called
respond_to_Q:
    li $v0, 10                      # Quit gracefully
    syscall
    
# Moves Down the current pill
respond_to_S:
    addi $s3, $s3, 256
    addi $s4, $s4, 256
    j update_board
    
# Move left the current pill
respond_to_A:
    # Check if current pill is horizontal or not
    addi $t4, $s3, 4
    bne $s4, $t4, vertical_left_move
        # If the pill is currently horizontal, this means we only need to check the left of pill 1
        addi $a0, $s3, -4
        jal get_board_by_addr
        bne $v0, 0, finite_no_left_movement 
        j finite_left_movement
    # If the pill is currently vertical, this means we need to check the left of both pill 1 and 2.
    vertical_left_move:
        addi $a0, $s3, -4
        jal get_board_by_addr
        bne $v0, 0, finite_no_left_movement 
        addi $a0, $s4, -4
        jal get_board_by_addr
        bne $v0, 0, finite_no_left_movement 
        j finite_left_movement
    finite_left_movement:
        addi $s3, $s3, -4
        addi $s4, $s4, -4
    finite_no_left_movement:
    j update_board
    
# Move left the current pill
respond_to_D:
    # Check if current pill is horizontal or not
    addi $t4, $s3, 4
    bne $s4, $t4, vertical_right_move
        # If the pill is currently horizontal, this means we only need to check the right of pill 2
        addi $a0, $s4, 4
        jal get_board_by_addr
        bne $v0, 0, finite_no_right_movement 
        j finite_right_movement
    # If the pill is currently vertical, this means we need to check the right of both pill 1 and 2.
    vertical_right_move:
        addi $a0, $s3, 4
        jal get_board_by_addr
        bne $v0, 0, finite_no_right_movement 
        addi $a0, $s4, 4
        jal get_board_by_addr
        bne $v0, 0, finite_no_right_movement 
        j finite_right_movement
    finite_right_movement:
        addi $s3, $s3, 4
        addi $s4, $s4, 4
    finite_no_right_movement:
    j update_board


# Rotates the pill
respond_to_W:
    # Update the relative address
    sub $t5, $s3, $s0
    sub $t6, $s4, $s0


    add $a0, $t5, $zero
    jal addr_to_board
    add $t0, $v0, $zero # X position of Pill 1 on board
    add $t1, $v1, $zero # Y position of Pill 1 on board
    
    add $a0, $t6, $zero
    jal addr_to_board
    add $t3, $v0, $zero # X position of Pill 2 on board
    add $t4, $v1, $zero # Y position of Pill 2 on board
    
    # Updates the pill
    addi $t2, $t1, 1
    bne $t2, $t4, rotate_h_v
    # If the pill is currently horizontal
    addi $s4, $s3, -256
    j finish_rotate
    # If the pill is currently vertical
    rotate_h_v:
        addi $s4, $s3, 4
        # Then we update the colour
        addi $t2, $s5, 0
        addi $s5, $s6, 0
        addi $s6, $t2, 0
    finish_rotate:
    j update_board

# generate viruses in random locations with random colors

generate_viruses:
    la $t0, viruses      # load address of array of viruses
    li $t1, 4            # generate 4 viruses (creates a counter to decrement from)
    li $t2, 8            # x bounds 1-8
    li $t3, 16           # y bounds 1-16

# load $s7 with a random color
virus_color:
    # make 4 random x, y coords Min: , Max: 
    li $v0, 42           # syscall to generate rand number
    li $a0, 0            # generator ID is 0 by default
    li $a1, 3            # upper bound (exclusive) set to 3
    syscall
    la $t3, colors       # Load color array in
    sll $a0, $a0, 2
    add $t3, $t3, $a0    # Calculate address of new color
    lw $s7, 0($t3) 
    jr $ra

generate_virus_loop:

    # generate random x coord
    li $v0, 42           # syscall for random number generator
    li $a0, 0            # generator id
    li $a1, 8            # upper bound 8 exclusive
    syscall
    addi $a0, $a0, 1     # shift range from 0-7 to 1-8
    sw $a0, 0($t0)       # store x coord in first index of $t0 (array for virus)

    # generate random color and store it in $s7
    jal virus_color      # call virus_color
    sw $s7, 8($t0)       # store color

    # generate next virus in virus array
    addi $t0, $t0, 12               # increment through 12 bytes in array to move thru (x, y, color)
    addi $t1, $t1, -1               # decrement counter
    bnez $t1, generate_virus_loop   # jump to generate_virus_loop if $t1 is not 0

    jr $ra