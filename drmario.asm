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
##############################################################################

##############################################################################
# Code
##############################################################################
	.text
	.globl main
	
# Before beginning, here is some information for how I'm storing my data in the registers
# $s0 = base address for display
# $s1 = address to the board
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




    # Run the game.
main:
    lw $s0, ADDR_DSPL
    # Initialize the game
    jal instantiate_map # Save return address at $ra and calls instantiate map to build map
    
    # Draw the initalize position of the pill
    jal random_color
    addi $s4, $s0, 1940
    sw $s5, 0( $s4 )
    addi $s3, $s0, 2196
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
    li $t1, 0x808080 # $t1 = gray
    
    # Draw the left gray wall
    addi $t3, $zero, 1652 # t3 tracks the current location starting from the top
    addi $t4, $zero, 8052 # t4 is the bottem row
    wall_draw_left:
        beq $t3, $t4 wall_draw_left_end # Checks if reached the bottom yet.
        add $t5, $s0, $t3 # If it has not, update $t5 which is where we want to draw
        sw $t1, 0( $t5 ) # Draw the pixel
        addi $t3, $t3, 256 # Move down a row
        j wall_draw_left
    wall_draw_left_end:
    
    # Draw the right gray wall
    addi $t3, $zero, 1716 # t3 tracks the current location starting from the top
    addi $t4, $zero, 8116 # t4 is the bottem row
    wall_draw_right:
        beq $t3, $t4 wall_draw_right_end # Checks if reached the bottom yet.
        add $t5, $s0, $t3 # If it has not, update $t5 which is where we want to draw
        sw $t1, 0( $t5 ) # Draw the pixel
        addi $t3, $t3, 256 # Move down a row
        j wall_draw_right
    wall_draw_right_end:
    
    # Draw the bottom row
    addi $t3, $zero, 7796 # t3 tracks the current location starting from the left
    addi $t4, $zero, 7864 # t4 is the right part
    wall_bottom:
        beq $t3, $t4 wall_bottom_end # Checks if reached the bottom yet.
        add $t5, $s0, $t3 # If it has not, update $t5 which is where we want to draw
        sw $t1, 0( $t5 ) # Draw the pixel
        addi $t3, $t3, 4 # Move down a row
        j wall_bottom
    wall_bottom_end:

    # Draw the top row
    addi $t3, $zero, 1656 # t3 tracks the current location starting from the left
    addi $t4, $zero, 1680 # t4 is the right part
    wall_top_left: # Draw the left top part
        beq $t3, $t4 wall_top_left_end # Checks if reached the bottom yet.
        add $t5, $s0, $t3 # If it has not, update $t5 which is where we want to draw
        sw $t1, 0( $t5 ) # Draw the pixel
        addi $t3, $t3, 4 # Move down a row
        j wall_top_left
    wall_top_left_end: 
    addi $t3, $zero, 1692 # t3 tracks the current location starting from the left
    addi $t4, $zero, 1716 # t4 is the right part
    wall_top_right: #Draw the right top part
        beq $t3, $t4 wall_top_right_end # Checks if reached the bottom yet.
        add $t5, $s0, $t3 # If it has not, update $t5 which is where we want to draw
        sw $t1, 0( $t5 ) # Draw the pixel
        addi $t3, $t3, 4 # Move down a row
        j wall_top_right
    wall_top_right_end:
    
    # Now manually draw the top part
    addi $t3, $s0, 1420
    sw $t1, 0( $t3 )
    addi $t3, $s0, 1164
    sw $t1, 0( $t3 )
    addi $t3, $s0, 1436
    sw $t1, 0( $t3 )
    addi $t3, $s0, 1180
    sw $t1, 0( $t3 ) 
    
    jr $ra # Returns to the main function



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

# Ok, so a lot of my logic is based on the idea of converting the values of (1912) which is the memory address over to a more easier and manipulatable variable.
# For example, 1912 would convert to (0,0) on the board. 

# Notice that our board is (23 x 13).
# Finally, here are the keyboard inputs map to the commands.
# A and D are the standard moving left and right
# W is rotate
# S is move down


# Input: $a0 = address offset (e.g., 1912, 1428, etc.)
# Output: $v0 = X (row), $v1 = Y (column)
addr_to_board:
    sub $t8, $a0, 1912      # Subtract the board's top-left offset (1912)
    li $t9, 256             # Bytes per row (64 columns * 4 bytes per pixel)
    
    divu $t8, $t9 # Divide by bytes per row: X = quotient, remainder = column offset
    mflo $v0 # $v0 = X (row)
    mfhi $t2 # $t2 = column offset (bytes)
    srl $v1, $t2, 2 # Convert bytes to Y (columns): divide by 4 (since 4 bytes per pixel)
    
    jr $ra  # Return to caller

# Input: $a0 = X (row), $a1 = Y (col)
# Output: $v0 = address offset
board_to_addr:
    li $t0, 256 # Bytes per row (64 columns * 4 bytes per pixel)
    mul $t1, $a0, $t0 # $t1 = X * bytes per row
    sll $t2, $a1, 2 # $t2 = Y * 4 (bytes)
    add $t3, $t1, $t2 # $t3 = offset within the board
    addi $v0, $t3, 1912 # Add the board's top-left offset (1912)
    
    jr $ra
    
# Central function that handles all the keyboard inputs
keybord_input: 
    lw $a0, 4($t0)                  # Load second word from keyboard
    beq $a0, 0x71, respond_to_Q     # Check if the key 'q' was pressed
    beq $a0, 0x77, respond_to_W     # Check if the key 'w' was pressed

    j update_board
    
    
# Exits program when callde
respond_to_Q:
    li $v0, 10                      # Quit gracefully
    syscall
    

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
    bne $t2, $t4 rotate_h_v
    # If the pill is currently horizontal
    addi $s4, $s3, -256
    j finish_rotate
    # If the pill is currently vertical
    rotate_h_v:
        addi $s4, $s3, 4
    finish_rotate:
    j update_board
