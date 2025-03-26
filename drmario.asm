################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Dr Mario.
#
# Student 1: Qi Wen Wei, 1010465168
# Student 2: Marina Tanaka, 1009784299
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
# virus color
VIRUS_COLORS: .word 0x028a0f, 0xd21404, 0x0442f6 # green, red, blue with a tint
GAME_OVER_ARRAY:  .word
    0, -1, -1, 0, 0, 0, 0, -1, 0, 0, -1, 0, 0, 0, -1, 0, 0, -1, -1,
    -1, 0, 0, 0, 0, 0, -1, 0, -1, 0, -1, -1, 0, -1, -1, 0, -1, 0, 0,
    -1, 0, -1, -1, -1, 0, -1, -1, -1, 0, -1, -1, -1, -1, -1, 0, -1, -1, 0,
    -1, 0, 0, -1, 0, 0, -1, 0, -1, 0, -1, 0, -1, 0, -1, 0, -1, 0, 0,
    0, -1, -1, 0, 0, 0, -1, 0, -1, 0, -1, 0, 0, 0, -1, 0, 0, -1, -1,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, -1, 0, 0, -1, 0, 0, 0, -1, 0, 0, -1, -1, 0, -1, -1, 0, 0, 0,
    -1, 0, -1, 0, -1, -1, 0, -1, -1, 0, -1, 0, 0, 0, -1, 0, -1, 0, 0, 
    -1, 0, -1, 0, 0, -1, 0, -1, 0, 0, -1, -1, 0, 0, -1, -1, 0, 0, 0
    -1, 0, -1, 0, 0, -1, -1, -1, 0, 0, -1, 0, 0, 0, -1, 0, -1, 0, 0, 
    0, -1, 0, 0, 0, 0, -1, 0, 0, 0, 0, -1, -1, 0, -1, 0, 0, -1, 0, 
    
##############################################################################
# Mutable Data

# State of the current board
# Think of it as a 27x17 array.
# If a index at a array is 1, then it's a wall
# If a index at a array is 0, then it's empty space
board: .space 459 # 27 rows x 17 columns = 405
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
    la $s1, board                     # Load in the basic board address to $s1
    
    # Instantiate the board as filled with zeros.
    la $t0, board
    li $t1, 405                       # Total bytes to initialize (27*17 = 459)
    li $t2, 0                         # Value to store (0)
    set_zero_board:
        beqz $t1, exit_zero_board     # Exit loop when counter ($t1) reaches 0
        sb $t2, 0( $t0 )              # Store 0 at current address
        addi $t0, $t0, 1              # Move to next byte
        addi $t1, $t1, -1             # Decrement counter
        j set_zero_board              # Repeat
    exit_zero_board:

    
    # Initialize the game
    jal instantiate_map # Save return address at $ra and calls instantiate map to build map
    
    # Draw the initalize position of the pill
    jal random_color
    addi $s4, $s0, 1428
    sw $s5, 0( $s4 )
    addi $s3, $s0, 1684
    sw $s6, 0( $s3 )
    
    jal virus_initializer
    jal virus_generate_loop
    
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
        
        # This section adds it to the board state
        addi $a0, $t5, 0
        addi $a1, $zero, 1
        jal set_board_by_addr
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
        
        # This section adds it to the board state
        addi $a0, $t5, 0
        addi $a1, $zero, 1
        jal set_board_by_addr
        j wall_top_left
    wall_top_left_end: 
    addi $t3, $zero, 1692 # t3 tracks the current location starting from the left
    addi $t4, $zero, 1716 # t4 is the right part
    wall_top_right: #Draw the right top part
        beq $t3, $t4, wall_top_right_end # Checks if reached the bottom yet.
        add $t5, $s0, $t3 # If it has not, update $t5 which is where we want to draw
        sw $t7, 0( $t5 ) # Draw the pixel
        addi $t3, $t3, 4 # Move down a row
        
        # This section adds it to the board state
        addi $a0, $t5, 0
        addi $a1, $zero, 1
        jal set_board_by_addr
        j wall_top_right
    wall_top_right_end:
    
    # Now manually draw the top part
    addi $t3, $s0, 1420
    sw $t7, 0( $t3 )
    # This section adds it to the board state
    addi $a0, $t3, 0
    addi $a1, $zero, 1
    jal set_board_by_addr
    
    addi $t3, $s0, 1164
    sw $t7, 0( $t3 )
    # This section adds it to the board state
    addi $a0, $t3, 0
    addi $a1, $zero, 1
    jal set_board_by_addr
    
    addi $t3, $s0, 1436
    sw $t7, 0( $t3 )
    # This section adds it to the board state
    addi $a0, $t3, 0
    addi $a1, $zero, 1
    jal set_board_by_addr
    
    addi $t3, $s0, 1180
    sw $t7, 0( $t3 ) 
    # This section adds it to the board state
    addi $a0, $t3, 0
    addi $a1, $zero, 1
    jal set_board_by_addr
    
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

# Notice that our board is (27 x 17) with it starting from two higher than the top left of the jar.
# Finally, here are the keyboard inputs map to the commands.
# A and D are the standard moving left and right
# W is rotate
# S is move down


# Input: $a0 = address offset (e.g., 1912, 1428, etc.)
# Output: $v0 = X (row), $v1 = Y (column)
addr_to_board:
    sub $t8, $a0, 1140      # Subtract the board's top-left offset (1140)
    li $t9, 256             # Bytes per row (64 columns * 4 bytes per pixel)
    
    divu $t8, $t9           # Divide by bytes per row: X = quotient, remainder = column offset
    mflo $v0                # $v0 = X (row)
    mfhi $t2                # $t2 = column offset (bytes)
    srl $v1, $t2, 2         # Convert bytes to Y (columns): divide by 4 (since 4 bytes per pixel)
    
    jr $ra  # Return to caller

# Get the value at the index board[$a0][$a1].
# For example board[i][0] where i >= 2 is 5 because it's the wall.
get_val_at_board:
    mul $t8, $a0, 17
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
    addi $sp, $sp, -4         # Allocate space on the stack
    sw $ra, 0($sp)            # Save the original return address

    sub $a0, $a0, $s0
    jal addr_to_board
    add $t0, $v0, $zero       # X position of Pill 1 on board
    add $t1, $v1, $zero       # Y position of Pill 1 on board
    
    mul $t8, $t0, 17
    add $t8, $t8, $t1          # Get the index in the board
    add $t8, $t8, $s1          # Get the address on the board
    sb $a1, 0 ($t8)            # Set value at the board
    
    lw $ra, 0($sp)             # Restore original return address
    addi $sp, $sp, 4         # Free stack space
    jr $ra                     # Return to caller
    
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
    beq $a0, 0x20, respond_to_space # check if space bar was pressed
    beq $a0, 0x71, respond_to_Q     # Check if the key 'q' was pressed
    beq $a0, 0x77, respond_to_W     # Check if the key 'w' was pressed
    beq $a0, 0x73, respond_to_S     # Check if the key 's' was pressed

    beq $a0, 0x61, respond_to_A     # Check if the key 'a' was pressed
    beq $a0, 0x64, respond_to_D     # Check if the key 'd' was pressed
    j update_board

# pauses game when called
respond_to_space:
    lw $t0, ADDR_KBRD                   # load keyboard addr
    lw $t1, 0($t0)                      # grab keyboard ready bit
    beq $t1, $zero, respond_to_space    # loop until these 3 lines until something is pressed
    
    lw $t0, 4($t0)                      # Get the key value
    lw $t1, 0x20                        # store space ascii in t1
    bne $t0, $t1, respond_to_space      # loop until key pressed is space bar
    
    jr $ra                              # if space bar is pressed, return to game_loop

# Exits program when called
respond_to_Q:
    li $v0, 10                      # Quit gracefully
    syscall
    
# Moves Down the current pill
respond_to_S:
    # Check if current pill is horizontal or not
    addi $t4, $s3, 4                        # t4 is the address of second half of pill
    bne $s4, $t4, vertical_down_move        # if pill is vertical, jump to vert down move
        # If the pill is currently horizontal, this means we need to check the bottom of pill 1 and 2
        addi $a0, $s3, 256                  # go to addr of pixel under s3
        jal get_board_by_addr               # check if there is smth at that address
        bne $v0, 0, finite_no_down_movement # if addr is not empty, skip
        addi $a0, $s4, 256                  # repeat process for second half of pill
        jal get_board_by_addr
        bne $v0, 0, finite_no_down_movement 
        j finite_down_movement              # else: go down
    vertical_down_move:
        # If the pill is currently vertical, this means we need to check the bottom of pill 1
        addi $a0, $s3, 256                  # if block under is taken: skip
        jal get_board_by_addr
        bne $v0, 0, finite_no_down_movement 
    finite_down_movement:                   # shift both halves down one row
        addi $s3, $s3, 256
        addi $s4, $s4, 256
    finite_no_down_movement:
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
    
# Move right the current pill
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
    # If the pill is currently horizontal, check if it can rotate to that position
    addi $a0, $s3, -256
    jal get_board_by_addr
    bne $v0, 0, finish_rotate
    addi $s4, $s3, -256
    j finish_rotate
    # If the pill is currently vertical
    rotate_h_v:
        # Check if location to be updated is a wall or not
        addi $a0, $s3, 4
        jal get_board_by_addr
        bne $v0, 0, finish_rotate
        
        addi $s4, $s3, 4
        # Then we update the colour
        addi $t2, $s5, 0
        addi $s5, $s6, 0
        addi $s6, $t2, 0
    finish_rotate:
    j update_board

# CREATE A FUNCTION THAT STORES/RESTORES ALL T REGISTERS FOR WHEN WE CALL FUNCTIONS
# IMPLEMENT UPDATING THE BOARD SO THAT VIRUSES ARE 1 AND OTHER
# PILLS ON THE BOARD ARE 1 SO THAT THEY DETECT COLLISION
# MAYBE FOR NOW MAKE VIRUSES AND PILLS SAME COLOR
# SO THAT DETECTING A FOUR IN A ROW IS EASIER

# generate viruses in random locations with random colors
virus_initializer:
    li $t1, 0               # loop counter = 0
    li $t9, 4               # make 4 viruses
    
virus_generate_loop:
    beq $t1, $t9, virus_end   # if $t1 == $t9, jump to virus_end
    lui $t0, 0x1000           # Load upper 16 bits of 0x10008000
    ori $t0, $t0, 0x8000      # Load lower 16 bits of 0x10008000
    li $v0, 42                # rand generator for x-coord
    li $a0, 0                 # lower bound is 0
    li $a1, 15                # upper bound is 15
    syscall
    add $t2, $zero, $a0     # store rand gen x-coord in t2
    addi $t2, $t2, 30      # now bounds are 30-45
    
    li $v0, 42              # rand generator for y-coord
    li $a0, 0               # lower bound is 0
    li $a1, 17              # upper bound is 17
    syscall
    add $t3, $zero, $a0     # store rand gen x-coord in t3
    addi $t3, $t3, 13      # now bounds are 13-30
    
    sll $t2, $t2, 2         # multiply x-coord by 16
    sll $t3, $t3, 8         # multiply y_coord by 4
    add $t0, $t0, $t2       # add x offset to top left
    add $t0, $t0, $t3       # add y offset to that too
    
    lw $t4, 0($t0)            # load value at current memory address
    bne $t4, 0, virus_generate_loop  # if occupied, generate a new position
    jal make_virus            # jump and link make_virus as a subroutine
    j virus_generate_loop     # jump back to the top

make_virus:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    li $v0, 42                  # random number generator
    li $a0, 0                   # lower bound is 0
    li $a1, 3                   # upper bound is 3
    syscall
    add $a1, $zero, $a0         # index of VIRUS_COLORS
    la $a0, VIRUS_COLORS        # load address of colors
    sll $t5 $a1 2               # t5 = $a1 * 4 
    add $t6 $a0 $t5             # t6 = head of array + t5
    lw $t7, 0($t6)              # load the color value from $t6 into $t7
    sw $t7, 0($t0)              # draw pixel of color t6 at t0
    # This section adds it to the board state
    addi $a0, $t0, 0
    # save t1, t9 on the stack, run set_virus_occupied, then restore
    jal store_registers
    jal set_virus_occupied
    jal restore_registers
    addi $t1, $t1, 1            # increment virus counter
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# input:
# a0 - bitmap addr of virus position
set_virus_occupied:
    addi $a1, $zero, 1
    addi $sp, $sp, -4         # open up space on stack
    sw $ra, 0($sp)            # save the original return address

    sub $a0, $a0, $s0
    jal addr_to_board
    add $t0, $v0, $zero       # x-coord of virus
    add $t1, $v1, $zero       # y-coord of virus
    
    mul $t8, $t0, 17
    add $t8, $t8, $t1          # get index
    add $t8, $t8, $s1          # get address
    sb $a1, 0 ($t8)            # set value at the board
    
    lw $ra, 0($sp)             # restore original return address
    addi $sp, $sp, 4           # free stack space
    jr $ra

virus_end:
    j update_board
    
game_over:
    la $a0 GAME_OVER_ARRAY

store_registers:            # push all t registers onto stack 
    addi $sp, $sp, -40        
    sw $t0, 36($sp)
    sw $t1, 32($sp)
    sw $t2, 28($sp)
    sw $t3, 24($sp)
    sw $t4, 20($sp)
    sw $t5, 16($sp)
    sw $t6, 12($sp)
    sw $t7, 8($sp)
    sw $t8, 4($sp)
    sw $t9, 0($sp)
    jr $ra
    
restore_registers:            # pop all t registers from stack (reverse order LIFO)
    lw $t9, 0($sp)
    lw $t8, 4($sp)
    lw $t7, 8($sp)
    lw $t6, 12($sp)
    lw $t5, 16($sp)
    lw $t4, 20($sp)
    lw $t3, 24($sp)
    lw $t2, 28($sp)
    lw $t1, 32($sp)
    lw $t0, 36($sp)
    addi $sp, $sp, 40         # Deallocate all space at once
    jr $ra
