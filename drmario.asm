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
colors: .word 0x00ff00, 0xff0000, 0x0000ff  # Green, Red, Blue

##############################################################################
# Mutable Data
##############################################################################

##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    lw $t0, ADDR_DSPL # $t0 = base address for display
    # Initialize the game
    jal instantiate_map # Save return address at $ra and calls instantiate map to build map
    
    # Draw the initalize position of the pill
    jal random_color
    
    addi $t3, $t0, 1428
    sw $t1, 0( $t3 )
    addi $t3, $t0, 1684
    sw $t1, 0( $t3 )
    
    
    j game_loop
    

# This function sets $t1 and $t2 as two random colors.
random_color: 
    li $v0, 42 # Syscall for random number generation
    li $a1, 3 # Upper bound (exclusive): 3 (0, 1, or 2)
    syscall
    la $t3, colors # Load color array in
    sll $a0, $a0, 2
    add $t3, $t3, $a0 # Calculate address of new color
    lw $t1, 0( $t3 )
    
    la $t3, colors # Load color array in
    sll $a0, $a0, 2
    add $t3, $t3, $a0 # Calculate address of new color
    lw $t2, 0( $t3 )
    
    jr $ra
    
# This function instializes the map boundaries
instantiate_map: 
    li $t1, 0x808080 # $t1 = gray
    
    # Draw the left gray wall
    addi $t3, $zero, 1652 # t3 tracks the current location starting from the top
    addi $t4, $zero, 8052 # t4 is the bottem row
    wall_draw_left:
        beq $t3, $t4 wall_draw_left_end # Checks if reached the bottom yet.
        add $t5, $t0, $t3 # If it has not, update $t5 which is where we want to draw
        sw $t1, 0( $t5 ) # Draw the pixel
        addi $t3, $t3, 256 # Move down a row
        j wall_draw_left
    wall_draw_left_end:
    
    # Draw the right gray wall
    addi $t3, $zero, 1716 # t3 tracks the current location starting from the top
    addi $t4, $zero, 8116 # t4 is the bottem row
    wall_draw_right:
        beq $t3, $t4 wall_draw_right_end # Checks if reached the bottom yet.
        add $t5, $t0, $t3 # If it has not, update $t5 which is where we want to draw
        sw $t1, 0( $t5 ) # Draw the pixel
        addi $t3, $t3, 256 # Move down a row
        j wall_draw_right
    wall_draw_right_end:
    
    # Draw the bottom row
    addi $t3, $zero, 7796 # t3 tracks the current location starting from the left
    addi $t4, $zero, 7864 # t4 is the right part
    wall_bottom:
        beq $t3, $t4 wall_bottom_end # Checks if reached the bottom yet.
        add $t5, $t0, $t3 # If it has not, update $t5 which is where we want to draw
        sw $t1, 0( $t5 ) # Draw the pixel
        addi $t3, $t3, 4 # Move down a row
        j wall_bottom
    wall_bottom_end:

    # Draw the top row
    addi $t3, $zero, 1656 # t3 tracks the current location starting from the left
    addi $t4, $zero, 1680 # t4 is the right part
    wall_top_left: # Draw the left top part
        beq $t3, $t4 wall_top_left_end # Checks if reached the bottom yet.
        add $t5, $t0, $t3 # If it has not, update $t5 which is where we want to draw
        sw $t1, 0( $t5 ) # Draw the pixel
        addi $t3, $t3, 4 # Move down a row
        j wall_top_left
    wall_top_left_end: 
    addi $t3, $zero, 1692 # t3 tracks the current location starting from the left
    addi $t4, $zero, 1716 # t4 is the right part
    wall_top_right: #Draw the right top part
        beq $t3, $t4 wall_top_right_end # Checks if reached the bottom yet.
        add $t5, $t0, $t3 # If it has not, update $t5 which is where we want to draw
        sw $t1, 0( $t5 ) # Draw the pixel
        addi $t3, $t3, 4 # Move down a row
        j wall_top_right
    wall_top_right_end:
    
    # Now manually draw the top part
    addi $t3, $t0, 1420
    sw $t1, 0( $t3 )
    addi $t3, $t0, 1164
    sw $t1, 0( $t3 )
    addi $t3, $t0, 1436
    sw $t1, 0( $t3 )
    addi $t3, $t0, 1180
    sw $t1, 0( $t3 ) 
    
    jr $ra # Returns to the main function



game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	# 4. Sleep
	
    # 5. Go back to Step 1
    j game_loop
