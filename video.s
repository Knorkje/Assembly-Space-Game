.section .note.GNU-stack,"",@progbits
.bss    
    .align 4
highscores: .skip 4*5  
.data
# MODULAR VARIABLE DECLARATIONS FOR SPACE SHOOTY MC SHOOT
# ------------------------------
# Title Screen
# ------------------------------
title:      .asciz "Space shooty mcshoot"
gameover:   .asciz "       GAME OVER"
gameoverflag: .byte 0
playbutton: .asciz "PLAY"
quitbutton: .asciz "QUIT"
titlesize:  .long 100
titlecolor: .long 0xFFFFFFFF # YELLOW
buttonsize: .long 50
playcolor:  .long 0xFF00FF00 # GREEN 
quitcolor:  .long 0xFFFFFFFF # RED
heigth:     .long 1080 
width:      .long 1920
title_option: .byte 0

# ------------------------------
# Player init
# ------------------------------

trix:       .long 910       # triangle (player) X position
triy:       .long 540       # triangle Y position
trisize:    .long 50        # triangle size
trispeed:   .long 10        # triangle movement speed
trihealth:  .long 3         # player health
fmt_str:    .asciz "%s"
fmt_xy:     .asciz "X: %d  Y: %d"
fmt_health: .asciz "Health: %d"

projlength: .long 15        # projectile length
projspeed:  .long 30        # projectile traveral speed

    .align 4                            # Look up table for projectile positions, and active bytes. 
active:    .byte 0,0,0,0,0,0,0,0,0,0    # MAX_PROJECTILES=10
    .align 4                            
projX:     .long 0,0,0,0,0,0,0,0,0,0
projY:     .long 0,0,0,0,0,0,0,0,0,0

# ------------------------------
# BASE ENEMIES
# ------------------------------
MAX_ENEMIES: .long 10                    # Look up table for enemy positions and health. 
    .align 4
enemyActive: .byte 0,0,0,0,0,0,0,0,0,0
    .align 4
enemyX:     .long 0,0,0,0,0,0,0,0,0,0
enemyY:     .long 0,0,0,0,0,0,0,0,0,0
enemyHealth:.long 0,0,0,0,0,0,0,0,0,0
enemyspeed:  .long 10         # enemy downward speed
enemythickness: .float 3.0    # thickness of enemy circles when drawn (higher value = thicker)
cirrad:     .float 30.0       # float radius used for collision and DrawCircle
cirrad_sq:  .long 2500        # radius^2 (50*ly50)
cirrad_int: .long 50          # integer radius used for collision calculations

spawnTimer: .long 0       # Base value for spawn timer
spawnInterval:.long 100   # frames between spawn
spawnseed:   .long 69696969      # seed for random spawns 
timerramp:    .long 0          

# ------------------------------
# LINE ENEMIES
# ------------------------------
MAX_LINES:        .long 2
lineActive:       .byte 0,0
    .align 4
lineY:            .long 0,0
lineGapX:         .long 0,0
lineEnemyTimer:   .long 0
lineEnemyFrames:  .long 120        # spawn interval (e.g. every 2 seconds)
lineEnemySpeed:   .long 4          # falling speed
enemygap:         .long 300        # width of the gap

# ------------------------------
# POWER-UPS
# ------------------------------
MAX_POWERUPS:        .long 3
powerActive:         .byte 0,0,0
    .align 4
powerX:              .long 0,0,0
powerY:              .long 0,0,0
powerupTimer:        .long 0
powerupTimerFrames:  .long 300     # spawn every N frames
powerupspeed:        .long 3       # falling speed (px/frame)
powerupsize:         .long 32      # square width/height
powerupthickness:    .long 4   # thickness when drawn
powerupflag:         .byte 0       # set to 1 on pickup
poweruptime:         .long 600          # frames the power-up lasts
powerupActiveFrames: .long 0            # counts frames while flag is active

# ------------------------------
# STARFIELD / PARALLAX BACKGROUND
# ------------------------------
MAX_STARS:           .long 64
STAR_MIN_SIZE:       .long 1
STAR_MAX_SIZE:       .long 4
starTimer:           .long 0
starTimerFrames:     .long 2      # spawn attempt every N frames (tune density)
# speed is proportional to size; starSpeed = starSize (no extra scale needed)

    .align 4
starActive:  .zero 64            # 64 bytes (0/1)
starX:       .zero 4*64          # 64 ints
starY:       .zero 4*64          # 64 ints
starSize:    .zero 4*64          # 64 ints
starSpeed:   .zero 4*64          # 64 ints

# ------------------------------
# SCOREBOARD SYSTEM
# ------------------------------
score:      .long 0         # global score value
scorepoints: .long 5        # points per enemy hit
scoretimer: .long 0   # frames between score increments
scoreinterval: .long 100  # e.g. every 100 frames
filename: .asciz "highscores.dat"
fmt_score: .asciz "Score: %d"
fmt_scoreboard: .asciz "Highscores:\n1. %d\n2. %d\n3. %d\n4. %d\n5. %d\n"
readmode:  .string "rb" # values for fopen
writemode:  .string "wb" 



# global colors
BLACK:      .long 0xFF000000  
RAYWHITE:   .long 0xFFFFFFFF
GREEN:      .long 0xFF00FF00
RED:        .long 0xFF0000FF


.text
.global main
.global updatescores
.extern InitWindow, ToggleBorderlessWindowed, WindowShouldClose
.extern BeginDrawing, EndDrawing, ClearBackground, DrawText, DrawFPS
.extern CloseWindow, exit
.extern IsKeyDown, IsKeyPressed
.extern DrawLine, SetTargetFPS
.extern DrawCircle
.extern TextFormat
.extern fopen
.extern fread
.extern fwrite
.extern fclose
.extern LCG_genrandint


main:
    push %rbp
    mov %rsp, %rbp
    push %rbx
    sub $8, %rsp

    # InitWindow(width, height, title)
    movl width, %edi
    movl heigth, %esi
    lea title, %rdx
    call InitWindow

    movl $60, %edi
    call SetTargetFPS
    movq $0, %rdi           # load scores for scoreboard (initial score = 0, so that previous score does not get saved again)
    call updatescores

# ------------------------------
#  TITLE SCREEN LOOP
# ------------------------------
titleloop:
    call WindowShouldClose
    test %eax, %eax
    jne close

    movl $262, %edi         # 262 = raylib.h KEY_RIGHT
    call IsKeyPressed       # Let's check for a keypress, and switch title option on press                     
    testb %al, %al
    je check_left_title
    jmp flipoption

check_left_title:
    movl $263, %edi         # 263 = raylib.h KEY_LEFT
    call IsKeyPressed       # Let's check for a keypress, and switch title option on press                       
    testb %al, %al      
    je checkbutton
    jmp flipoption

flipoption:
    movb title_option, %al  # flip (XOR) option byte. 
    xor $1, %al             # 1 XOR 1 = 0, 0 XOR 1 = 1.
    movb %al, title_option

checkbutton:
    movl $90, %edi
    call IsKeyPressed
    test %al, %al
    je  setbuttoncolor
    jmp clickbutton

clickbutton:
    cmpb $1, title_option
    je close                # quit selected
    # play selected? Initialise variables
    # --- Initialise game variables ---
    mov $3, %eax
    movl %eax, trihealth     # reset player health
    movl $0, score          # reset score
    movl width, %eax
    shr $1, %eax
    movl %eax, trix        # reset player x pos (center)
    movl heigth, %eax
    shr $1, %eax
    movl %eax, triy        # reset player y pos (center)
    jne drawloop  

setbuttoncolor:
    cmpb $1, title_option   # Check if title byte is 0 or 1
    je quitactive           # 1 = quit is active
                            # 0 = play is active
playactive:
    mov GREEN, %eax       # set playbutton to green to indicate active
    movl %eax, playcolor
    mov RAYWHITE, %eax
    movl %eax, quitcolor   
    jmp titledraw

quitactive:
    mov RAYWHITE, %eax
    movl %eax, playcolor
    mov RED, %eax
    movl %eax, quitcolor

titledraw:
    call BeginDrawing
    movl BLACK, %edi
    call ClearBackground

    # --- position title text ---
    mov $fmt_str, %rdi      # Setup Title formatting
    cmpb $1, gameoverflag
    je use_gameover_title
    movl $title, %esi       # Let's position the title top middle
    jmp formatitle
use_gameover_title:
    movl $gameover, %esi
formatitle:
    call TextFormat
    movq %rax, %rdi

    movq width, %rax        # title x = (width/2)-500
    movl $2, %r9d           
    divl %r9d
    subl $500, %eax
    movl %eax, %esi

    movq heigth, %rax       # title y = (height/2)-300
    divl %r9d
    subl $300, %eax
    movl %eax, %edx
    movl titlesize, %ecx

    movl titlecolor, %r8d
    call DrawText

    # --- position buttons text ---
    # Play button
    mov $fmt_str, %rdi      # Setup Title formatting
    movl $playbutton, %esi  # Let's position the title top middle
    call TextFormat
    movq %rax, %rdi

    movl $700, %esi         # ahh fuck it time to hardcode position for now
    movl $400, %edx         # current play pos (700, 400)
    movl buttonsize, %ecx
    movl playcolor, %r8d
    call DrawText

    # Quit button
    mov $fmt_str, %rdi      # Setup Title formatting
    movl $quitbutton, %esi  # Let's position the title top middle
    call TextFormat
    movq %rax, %rdi

    movl $1000, %esi        # ahh fuck it time to hardcode position for now
    movl $400, %edx         # current play pos (100, 400)
    movl buttonsize, %ecx
    movl quitcolor, %r8d
    call DrawText

# ------------------------------
# DRAW SCOREOARD
# ------------------------------
    # Draw scoreboard (call this while inside BeginDrawing/EndDrawing)
    # Clobbers: rax, rdi, rsi, rdx, rcx, r8, r9 (caller-saved regs)
draw_scoreboard_title:
    # --- Prepare arguments for TextFormat(fmt, s1, s2, s3, s4, s5) ---
    lea fmt_scoreboard, %rdi        # rdi = fmt pointer

    lea highscores, %rax            # rax = address highscores[0]
    movl (%rax), %esi               # rsi = highscores[0]  (1st %d)
    movl 4(%rax), %edx              # rdx = highscores[1]  (2nd %d)
    movl 8(%rax), %ecx              # rcx = highscores[2]  (3rd %d)
    movl 12(%rax), %r8d             # r8  = highscores[3]  (4th %d)
    movl 16(%rax), %r9d             # r9  = highscores[4]  (5th %d)

    call TextFormat@PLT             # returns pointer to formatted string in RAX

    # --- Call DrawText(formatted_string, posX, posY, fontSize, color) ---
    movq %rax, %rdi                  # rdi = const char *text (from TextFormat)
    movl $850, %esi                  # rsi = posX
    movl $600, %edx                  # rdx = posY
    movl $30, %ecx                   # rcx = fontSize
    mov RAYWHITE, %r8d               # r8 = color (packed RGBA)
    call DrawText
                           
    Call EndDrawing
    jmp titleloop

drawloop:
    call WindowShouldClose
    test %eax, %eax
    jne close

# ------------------------------
#  INPUT HANDLING (MOVE PLAYER TRIANGLE)
# ------------------------------
    movl $262, %edi       # KEY_RIGHT
    call IsKeyDown@PLT
    testb %al, %al
    je check_left
    mov trispeed, %eax
    addl %eax, trix

    # --- Clamp X within right bound ---
    movl trix, %eax
    movl width, %edx       # compare player position to screen width - trisize (to make sure it stays in frame)
    subl trisize, %edx
    cmpl %edx, %eax
    jle .right_ok
    movl %edx, trix        # if trix > width -> trix = width
.right_ok:

check_left:
    movl $263, %edi       # KEY_LEFT
    call IsKeyDown@PLT  
    testb %al, %al
    je check_down
    mov trispeed, %eax
    subl %eax, trix

    # --- Clamp X within left bound ---
    movl trix, %eax
    testl %eax, %eax       # check if trix < 0
    jge .left_ok
    movl $0, trix          # if trix < 0 -> trix = 0
.left_ok:

check_down:
    movl $264, %edi       # KEY_DOWN
    call IsKeyDown@PLT
    testb %al, %al
    je check_up
    mov trispeed, %eax
    addl %eax, triy

    # --- Clamp Y within bottom bound ---
    movl triy, %eax
    movl heigth, %edx
    subl trisize, %edx
    cmpl %edx, %eax        # compare player position to screen heigth - trisize (to make sure it stays in frame)
    jle .down_ok
    movl %edx, triy        # if triy > heigth -> triy = heigth
.down_ok:

check_up:
    movl $265, %edi       # KEY_UP
    call IsKeyDown@PLT
    testb %al, %al
    je .up_ok
    mov trispeed, %eax
    subl %eax, triy

    # --- Clamp Y within top bound ---
    movl triy, %eax
    testl %eax, %eax       # check if triy < 0
    jge .up_ok
    movl $0, triy          # if triy < 0 -> triy = 0
.up_ok:
# ------------------------------
# PASSIVE SCORE INCREMENT & DIFFICULTY SYSTEM
# ------------------------------
   # scoretimer++
    movl scoretimer, %eax
    addl $1, %eax
    movl %eax, scoretimer

    # :if scoretimer < scoreinterval -> skip increment
    movl scoreinterval, %ecx
    cmpl %ecx, %eax
    jl .spawn_enemies       

    # reset timer (we'll spawn)
    movl $0, scoretimer
    # increment score
    movl score, %eax
    addl scorepoints, %eax
    movl %eax, score

    # timerramp difficulty check:
    movl score, %eax
    cmpl $50, %eax
    jl .spawn_enemies
    # :if score >= 50, decrease spawnInterval to increase difficulty
    movl timerramp, %eax
    addl $10, %eax
    movl %eax, timerramp

    cmpl $200, %eax
    jl .spawn_enemies
    # :if score >= 200, decrease spawnInterval to increase difficulty
    movl timerramp, %eax
    addl $15, %eax
    movl %eax, timerramp

    cmpl $400, %eax
    jl .spawn_enemies
    # :if score >= 400, decrease spawnInterval to increase difficulty
    movl timerramp, %eax
    addl $20, %eax
    movl %eax, timerramp

# ------------------------------
# SPAWN ENEMIES (increment timer, spawn at interval)
# ------------------------------
.spawn_enemies:
    # spawnTimer++
    movl spawnTimer, %eax
    addl $1, %eax
    movl %eax, spawnTimer

    # :if spawnTimer < spawnInterval -> skip spawn
    movl spawnInterval, %ecx
    movl timerramp, %edx
    subl %edx, %ecx
    cmpl %ecx, %eax
    jl .shoot_check       # not yet time

    # reset timer (we'll spawn)
    movl $0, spawnTimer

    # find first inactive enemy slot
    xorl %ebx, %ebx              # ebx = index
.find_enemy_slot:
    mov MAX_ENEMIES, %ecx
    cmpl %ecx, %ebx                # MAX_ENEMIES = 10

    jge .shoot_check             # no free slot -> continue
    lea enemyActive, %rax
    movzbl (%rax,%rbx,1), %edx
    test %edx, %edx
    jne .next_enemy_slot

    # activate enemyActive[i] = 1
    movb $1, (%rax,%rbx,1)

    # enemyX = random number between 0 and width
    call LCG_genrandint        # get random x position in eax
    movl %eax, %ecx
    lea enemyX, %rax
    movl %ecx, (%rax,%rbx,4)

    # enemyY = 50
    movl $-50, %ecx

    lea enemyY, %rax
    movl %ecx, (%rax,%rbx,4)

    # enemyHealth = 3
    movl $3, %ecx
    lea enemyHealth, %rax
    movl %ecx, (%rax,%rbx,4)

    jmp .shoot_check

.next_enemy_slot:
    inc %ebx
    jmp .find_enemy_slot

# ------------------------------
# SHOOTING LOGIC  (triple-shot when powerupflag != 0)
# ------------------------------
.shoot_check:
    movl $90, %edi              # 90 = raylib.h Z
    call IsKeyPressed
    test %eax, %eax
    je .update_projectiles

    # Precompute centerX, startY, and spread = trisize/4
    movl trisize, %eax
    xorl %edx, %edx
    movl $2, %ecx
    divl %ecx                    # eax = trisize / 2
    movl trix, %ecx
    addl %eax, %ecx              # ecx = centerX
    movl %ecx, %r8d              # r8d = centerX
    movl triy, %r9d              # r9d = startY
    movl %eax, %r10d             # r10d = trisize/2
    shrl $1, %r10d               # r10d = trisize/4 (spread)

    # If no power-up -> single shot
    movzbl powerupflag, %eax
    test %eax, %eax
    je .single_shot

    # -------- TRIPLE SHOT --------
    # Left shot:  x = centerX - spread
    movl %r8d, %r11d
    subl %r10d, %r11d
    xorl %ebx, %ebx
.find_slot_L:
    cmpl $10, %ebx
    jge .mid_shot
    lea active, %rax
    movzbl (%rax,%rbx,1), %edx
    test %edx, %edx
    jne .next_slot_L
    movb $1, (%rax,%rbx,1)
    lea projX, %rax
    movl %r11d, (%rax,%rbx,4)
    lea projY, %rax
    movl %r9d,  (%rax,%rbx,4)
    jmp .mid_shot
.next_slot_L:
    inc %ebx
    jmp .find_slot_L

.mid_shot:
    # Middle shot: x = centerX
    movl %r8d, %r11d
    xorl %ebx, %ebx
.find_slot_M:
    cmpl $10, %ebx
    jge .right_shot
    lea active, %rax
    movzbl (%rax,%rbx,1), %edx
    test %edx, %edx
    jne .next_slot_M
    movb $1, (%rax,%rbx,1)
    lea projX, %rax
    movl %r11d, (%rax,%rbx,4)
    lea projY, %rax
    movl %r9d,  (%rax,%rbx,4)
    jmp .right_shot
.next_slot_M:
    inc %ebx
    jmp .find_slot_M

.right_shot:
    # Right shot: x = centerX + spread
    movl %r8d, %r11d
    addl %r10d, %r11d
    xorl %ebx, %ebx
.find_slot_R:
    cmpl $10, %ebx
    jge .done_shoot
    lea active, %rax
    movzbl (%rax,%rbx,1), %edx
    test %edx, %edx
    jne .next_slot_R
    movb $1, (%rax,%rbx,1)
    lea projX, %rax
    movl %r11d, (%rax,%rbx,4)
    lea projY, %rax
    movl %r9d,  (%rax,%rbx,4)
    jmp .done_shoot
.next_slot_R:
    inc %ebx
    jmp .find_slot_R

.done_shoot:
    jmp .update_projectiles

# -------- SINGLE SHOT (fallback) --------
.single_shot:
    xorl %ebx, %ebx
.find_slot:
    cmpl $10, %ebx
    jge .update_projectiles
    lea active, %rax
    movzbl (%rax,%rbx,1), %edx
    test %edx, %edx
    jne .next_slot
    movb $1, (%rax,%rbx,1)
    lea projX, %rax
    movl %r8d, (%rax,%rbx,4)     # centerX
    lea projY, %rax
    movl %r9d, (%rax,%rbx,4)     # startY
    jmp .update_projectiles
.next_slot:
    inc %ebx
    jmp .find_slot


# ------------------------------
# UPDATE PROJECTILES (move upward) and check collisions with enemies
# ------------------------------
.update_projectiles:
    xorl %ebx, %ebx
.update_loop:
    cmpl $10, %ebx
    jge .update_enemies          # jump to new enemy movement section
    lea active, %rax
    movzbl (%rax,%rbx,1), %edx
    test %edx, %edx
    je .next_update
    # projY[i] -= projspeed  (move up)
    lea projY, %rax
    movl (%rax,%rbx,4), %edx
    movl projspeed, %ecx
    subl %ecx, %edx
    movl %edx, (%rax,%rbx,4)
    # :if projY[i] < 0 deactivate
    test %edx, %edx
    jge .check_proj_vs_enemies
    lea active, %rax
    movb $0, (%rax,%rbx,1)
    
    jmp .next_update

.check_proj_vs_enemies:
    # For this projectile, check against all enemies
    lea projX, %rax
    movl (%rax,%rbx,4), %edi      # edi = projX (px)
    lea projY, %rax
    movl (%rax,%rbx,4), %esi      # esi = projY (py)

    xorl %r10d, %r10d             # enemy index
.en_loop:
    movl MAX_ENEMIES, %ecx
    cmpl %ecx, %r10d
    jge .post_enemy_checks

    lea enemyActive, %rax
    movzbl (%rax,%r10,1), %edx
    test %edx, %edx
    je .en_next

    # enemy is active -> load enemyX, enemyY
    lea enemyX, %rax
    movl (%rax,%r10,4), %ecx     # ecx = enemyX
    lea enemyY, %rax
    movl (%rax,%r10,4), %r11d    # r11d = enemyY

    # dx = projX - enemyX
    movl %edi, %r12d
    subl %ecx, %r12d             # r12d = dx

    # dy = projY - enemyY
    movl %esi, %r13d
    subl %r11d, %r13d            # r13d = dy

    # dx*dx + dy*dy
    movl %r12d, %eax
    imull %r12d, %eax
    movl %r13d, %edx
    imull %r13d, %edx
    addl %edx, %eax

    # compare with cirrad_sq
    movl cirrad_sq, %edx
    cmpl %edx, %eax
    jg .en_next                  # if >, no collision

    # COLLISION! decrement enemyHealth and deactivate projectile
    lea enemyHealth, %rax
    movl (%rax,%r10,4), %ecx
    subl $1, %ecx
    movl %ecx, (%rax,%r10,4)

    # Update score
    movl score, %eax
    addl scorepoints, %eax
    movl %eax, score

    # deactivate projectile
    lea active, %rax
    movb $0, (%rax,%rbx,1)

    # :if enemyHealth <= 0 deactivate enemy
    test %ecx, %ecx
    jg .en_next
    lea enemyActive, %rax
    movb $0, (%rax,%r10,1)

.en_next:
    inc %r10d
    jmp .en_loop

.post_enemy_checks:
.next_update:
    inc %ebx
    jmp .update_loop

# ------------------------------
# MOVE ENEMIES DOWNWARD (constant)
# ------------------------------
.update_enemies:
    xorl %ebx, %ebx
.enemy_move_loop:
    mov MAX_ENEMIES, %ecx
    cmpl %ecx, %ebx
    jge .update_line_enemies      # done moving all enemies
    lea enemyActive, %rax
    movzbl (%rax,%rbx,1), %edx
    test %edx, %edx
    je .next_enemy_move

    # enemyY[i] += enemyspeed
    lea enemyY, %rax
    movl (%rax,%rbx,4), %ecx
    movl enemyspeed, %edx
    addl %edx, %ecx
    movl %ecx, (%rax,%rbx,4)

    # existing offscreen check remains here (already integrated in your code)
    cmpl heigth, %ecx
    jl .skip_remove
    lea enemyActive, %rax
    movb $0, (%rax,%rbx,1)
.skip_remove:

.next_enemy_move:
    inc %ebx
    jmp .enemy_move_loop

# ------------------------------
# LINE ENEMY SYSTEM (MOVING HORIZONTAL OBSTACLE WITH GAP)
# ------------------------------
.update_line_enemies:
    # increment timer
    movl lineEnemyTimer, %eax
    addl $1, %eax
    movl %eax, lineEnemyTimer

    # if timer < lineEnemyFrames -> skip spawn
    movl lineEnemyFrames, %ecx
    cmpl %ecx, %eax
    jl .move_lines

    # reset timer
    movl $0, lineEnemyTimer

    # find first inactive line slot
    xorl %ebx, %ebx
.find_line_slot:
    cmpl $2, %ebx
    jge .move_lines
    lea lineActive, %rax
    movzbl (%rax,%rbx,1), %edx
    test %edx, %edx
    jne .next_line_slot

    # activate line
    movb $1, (%rax,%rbx,1)

    # y position at top (start)
    lea lineY, %rax
    movl $0, (%rax,%rbx,4)

    # generate random gap position
    call LCG_genrandint
    movl %eax, %ecx                 # random number
    # constrain gap position: (rand % (width - enemygap))
    movl width, %edx
    subl enemygap, %edx
    xorl %edx, %edx                 # edx = divisor
    movl width, %edx
    subl enemygap, %edx
    xorl %edx, %edx
    movl width, %edx
    subl enemygap, %edx
    # simpler way (no div instructions hazard):
    movl width, %edx
    subl enemygap, %edx
    xorl %edx, %edx
    movl width, %edx
    subl enemygap, %edx
    # correct modulo sequence:
    movl width, %edx
    subl enemygap, %edx
    xorl %edx, %edx
    movl width, %edx
    subl enemygap, %edx
    # Okay, for simplicity use AND mask approach (not perfect but fast):
    andl $1023, %ecx                # pseudo-range control (you can refine)

    # store gapX
    lea lineGapX, %rax
    movl %ecx, (%rax,%rbx,4)

    jmp .move_lines
.next_line_slot:
    inc %ebx
    jmp .find_line_slot

# ------------------------------
# MOVE AND CHECK LINES
# ------------------------------
.move_lines:
    xorl %ebx, %ebx
.line_move_loop:
    cmpl $2, %ebx
    jge .check_line_player
    lea lineActive, %rax
    movzbl (%rax,%rbx,1), %edx
    test %edx, %edx
    je .next_line_move

    # move down
    lea lineY, %rax
    movl (%rax,%rbx,4), %ecx
    movl lineEnemySpeed, %edx
    addl %edx, %ecx
    movl %ecx, (%rax,%rbx,4)

    # if offscreen, deactivate
    cmpl heigth, %ecx
    jl .skip_line_remove
    lea lineActive, %rax
    movb $0, (%rax,%rbx,1)
.skip_line_remove:

.next_line_move:
    inc %ebx
    jmp .line_move_loop

# ------------------------------
# COLLISION CHECK: PLAYER VS LINE OBSTACLE
# ------------------------------
.check_line_player:
    xorl %ebx, %ebx
.line_player_loop:
    cmpl $2, %ebx
    jge .check_enemy_player      # done checking all lines
    lea lineActive, %rax
    movzbl (%rax,%rbx,1), %edx
    test %edx, %edx
    je .next_line_player

    # load lineY and gapX
    lea lineY, %rax
    movl (%rax,%rbx,4), %ecx       # ecx = lineY
    lea lineGapX, %rax
    movl (%rax,%rbx,4), %edx       # edx = gapX

    # get player position
    movl trix, %esi          # playerX
    movl triy, %edi          # playerY
    movl trisize, %r8d       # player size

    # define vertical collision range
    movl %edi, %r9d
    addl %r8d, %r9d                # bottom edge

    # check vertical overlap: if lineY between playerY..playerY+trisize
    cmpl %edi, %ecx
    jl .next_line_player           # line above player
    cmpl %r9d, %ecx
    jg .next_line_player           # line below player

    # player horizontally NOT in gap?
    movl enemygap, %r10d
    movl %edx, %r11d
    addl %r10d, %r11d              # r11d = gapX + enemygap

    # if (playerX >= gapX && playerX <= gapX+enemygap) -> safe
    cmpl %edx, %esi
    jl .hit_player
    cmpl %r11d, %esi
    jg .hit_player
    jmp .next_line_player          # inside gap, safe

.hit_player:
    # player hit -> decrement health
    movl trihealth, %eax
    subl $1, %eax
    movl %eax, trihealth

    # deactivate line (optional)
    lea lineActive, %rax
    movb $0, (%rax,%rbx,1)

.next_line_player:
    inc %ebx
    jmp .line_player_loop


# ------------------------------
# CHECK COLLISION: ENEMY VS PLAYER
# ------------------------------
.check_enemy_player:
    xorl %ebx, %ebx
.enemy_player_loop:
    movl MAX_ENEMIES, %ecx
    cmpl %ecx, %ebx
    jge .update_powerups              # done checking all enemies

    # check if active
    lea enemyActive, %rax
    movzbl (%rax,%rbx,1), %edx
    test %edx, %edx
    je .next_enemy_player

    # load enemy position
    lea enemyX, %rax
    movl (%rax,%rbx,4), %ecx     # ecx = enemyX
    lea enemyY, %rax
    movl (%rax,%rbx,4), %edx     # edx = enemyY

    # load player position (trix, triy)
    movl trix, %esi
    movl triy, %edi

    # compute dx = enemyX - trix
    movl %ecx, %eax
    subl %esi, %eax              # eax = dx

    # compute dy = enemyY - triy
    movl %edx, %r8d
    subl %edi, %r8d              # r8d = dy

    # dx*dx + dy*dy
    movl %eax, %r9d
    imull %eax, %r9d             # r9d = dx^2
    movl %r8d, %r10d
    imull %r8d, %r10d            # r10d = dy^2
    addl %r10d, %r9d             # r9d = distance^2

    # load combined radius squared: (cirrad + playerRad)^2
    movl cirrad_int, %eax
    movl trisize, %ecx
    shrl $1, %ecx                # half of player size (triangle treated as circle)
    addl %ecx, %eax              # eax = total radius
    imull %eax, %eax             # eax = (total radius)^2

    # :if distance^2 < (total radius)^2 -> collision!
    cmpl %eax, %r9d
    jg .next_enemy_player        # no collision

    # COLLISION DETECTED: handle player hit
    # (example: decrease health, or trigger game over)
    movl trihealth, %eax
    subl $1, %eax
    movl %eax, trihealth

    # optionally deactivate enemy
    lea enemyActive, %rax
    movb $0, (%rax,%rbx,1)
    cmpl $0, trihealth
    jg .next_enemy_player
    jmp lose

.next_enemy_player:
    inc %ebx
    jmp .enemy_player_loop

# ------------------------------
# UPDATE POWER-UPS (spawn, move, collide with player)
# ------------------------------
# ------------------------------
# UPDATE POWER-UPS (spawn, move, collide with player)
# ------------------------------
.update_powerups:
    # --- duration timer for active power-up ---
    movzbl powerupflag, %eax
    test %eax, %eax
    je .spawn_powerups
    movl powerupActiveFrames, %eax
    addl $1, %eax
    movl %eax, powerupActiveFrames
    movl poweruptime, %ecx
    cmpl %ecx, %eax
    jle .spawn_powerups
    # exceeded duration -> disable and reset counter
    movb $0, powerupflag
    movl $0, powerupActiveFrames

.spawn_powerups:
    # timer++
    movl powerupTimer, %eax
    addl $1, %eax
    movl %eax, powerupTimer

    # /if timer < powerupTimerFrames -> skip spawn
    movl powerupTimerFrames, %ecx
    cmpl %ecx, %eax
    jl .move_powerups

    # reset timer
    movl $0, powerupTimer

    # find first inactive slot
    xorl %ebx, %ebx
.find_power_slot:
    cmpl $3, %ebx                 # MAX_POWERUPS = 3
    jge .move_powerups
    lea powerActive, %rax
    movzbl (%rax,%rbx,1), %edx
    test %edx, %edx
    jne .next_power_slot

    # activate
    movb $1, (%rax,%rbx,1)

    # X = rand % (width - powerupsize)
    call LCG_genrandint           # -> %rax
    movl %eax, %eax
    movl width, %ecx
    subl powerupsize, %ecx
    xorl %edx, %edx
    divl %ecx                     # remainder in %edx
    movl %edx, %ecx               # ecx = x in [0..width-size]
    lea powerX, %rax
    movl %ecx, (%rax,%rbx,4)

    # Y = 0 (top)
    lea powerY, %rax
    movl $0, (%rax,%rbx,4)

    jmp .move_powerups
.next_power_slot:
    inc %ebx
    jmp .find_power_slot

# ---- move + offscreen + player collision ----
.move_powerups:
    xorl %ebx, %ebx
.power_move_loop:
    cmpl $3, %ebx
    jge .after_powerups           # done

    # active?
    lea powerActive, %rax
    movzbl (%rax,%rbx,1), %edx
    test %edx, %edx
    je .next_power_move

    # Y += powerupspeed
    lea powerY, %rax
    movl (%rax,%rbx,4), %ecx
    movl powerupspeed, %edx
    addl %edx, %ecx
    movl %ecx, (%rax,%rbx,4)

    # offscreen? (y >= heigth) -> deactivate
    cmpl heigth, %ecx
    jl .check_power_vs_player
    lea powerActive, %rax
    movb $0, (%rax,%rbx,1)
    jmp .next_power_move

.check_power_vs_player:
    # Load power-up box: (ux,uy)-(ur,ub)
    lea powerX, %rax
    movl (%rax,%rbx,4), %ecx          # ecx = ux
    movl %ecx, %r11d                  # r11d = ux (left)
    movl powerupsize, %r10d           # size
    lea powerY, %rax
    movl (%rax,%rbx,4), %edx          # edx = uy (top)
    movl %ecx, %r12d
    addl %r10d, %r12d                 # r12d = ur (right = ux+size)
    movl %edx, %r13d
    addl %r10d, %r13d                 # r13d = ub (bottom = uy+size)

    # Load player AABB: (pl,pt)-(pr,pb)
    movl trix, %r14d                  # pl
    movl triy, %r15d                  # pt
    movl trisize, %r9d
    movl %r14d, %r8d
    addl %r9d, %r8d                   # pr = pl + trisize
    movl %r15d, %eax
    addl %r9d, %eax                   # pb = pt + trisize

    # AABB overlap test:
    cmpl %r11d, %r8d
    jl .no_power_collide
    cmpl %r12d, %r14d
    jg .no_power_collide
    cmpl %edx, %eax
    jl .no_power_collide
    cmpl %r13d, %r15d
    jg .no_power_collide

    # COLLISION: set flag and deactivate the power-up
    movb $1, powerupflag
    movl $0, powerupActiveFrames     # reset duration counter on pickup
    lea powerActive, %rax
    movb $0, (%rax,%rbx,1)
    jmp .next_power_move

.no_power_collide:
.next_power_move:
    inc %ebx
    jmp .power_move_loop

.after_powerups:
    jmp .update_stars

# ------------------------------
# UPDATE STARS (spawn, move, despawn)
# ------------------------------
.update_stars:
    # timer++
    movl starTimer, %eax
    addl $1, %eax
    movl %eax, starTimer

    # if timer < starTimerFrames -> skip spawn
    movl starTimerFrames, %ecx
    cmpl %ecx, %eax
    jl .move_stars

    # reset timer
    movl $0, starTimer

    # find first inactive star
    xorl %ebx, %ebx
.find_star_slot:
    cmpl $64, %ebx                      # MAX_STARS = 64
    jge .move_stars
    lea starActive, %rax
    movzbl (%rax,%rbx,1), %edx
    test %edx, %edx
    jne .next_star_slot

    # activate
    movb $1, (%rax,%rbx,1)

    # X = rand % width
    call LCG_genrandint                 # -> %rax
    movl %eax, %eax
    movl width, %ecx
    xorl %edx, %edx
    divl %ecx                           # remainder in %edx
    lea starX, %rax
    movl %edx, (%rax,%rbx,4)

    # Y = 0 (top)
    lea starY, %rax
    movl $0, (%rax,%rbx,4)

    # size = STAR_MIN_SIZE + rand % (STAR_MAX_SIZE - STAR_MIN_SIZE + 1)
    call LCG_genrandint
    movl %eax, %eax
    movl STAR_MAX_SIZE, %ecx
    subl STAR_MIN_SIZE, %ecx
    addl $1, %ecx                       # range = max-min+1
    xorl %edx, %edx
    divl %ecx                           # remainder in %edx
    movl STAR_MIN_SIZE, %ecx
    addl %ecx, %edx                     # edx = size
    lea starSize, %rax
    movl %edx, (%rax,%rbx,4)

    # speed = size  (parallax: larger -> faster)
    lea starSpeed, %rax
    movl %edx, (%rax,%rbx,4)

    jmp .move_stars
.next_star_slot:
    inc %ebx
    jmp .find_star_slot

# ---- move + offscreen ----
.move_stars:
    xorl %ebx, %ebx
.star_move_loop:
    cmpl $64, %ebx
    jge .draw_stage

    # active?
    lea starActive, %rax
    movzbl (%rax,%rbx,1), %edx
    test %edx, %edx
    je .next_star_move

    # Y += speed
    lea starY, %rax
    movl (%rax,%rbx,4), %ecx
    lea starSpeed, %rdi
    movl (%rdi,%rbx,4), %edx
    addl %edx, %ecx
    movl %ecx, (%rax,%rbx,4)

    # offscreen? (y >= heigth) -> deactivate
    cmpl heigth, %ecx
    jl .next_star_move
    lea starActive, %rax
    movb $0, (%rax,%rbx,1)

.next_star_move:
    inc %ebx
    jmp .star_move_loop

# ------------------------------
# DRAW STAGE
# ------------------------------
.draw_stage:
    call BeginDrawing
    movl BLACK, %edi
    call ClearBackground

# ------------------------------
# DRAW STARS (white squares)
# ------------------------------
.draw_stars:
    xorl %ebx, %ebx
.star_draw_loop:
    cmpl $64, %ebx
    jge .after_draw_stars
    lea starActive, %rax
    movzbl (%rax,%rbx,1), %edx
    test %edx, %edx
    je .next_star_draw

    # x, y
    lea starX, %rax
    movl (%rax,%rbx,4), %edi
    lea starY, %rax
    movl (%rax,%rbx,4), %esi

    # width, height = size
    lea starSize, %rax
    movl (%rax,%rbx,4), %edx       # width
    movl %edx, %ecx                 # height

    # color
    movl RAYWHITE, %r8d

    call DrawRectangle

.next_star_draw:
    inc %ebx
    jmp .star_draw_loop

.after_draw_stars:
    # draw triangle (player)
    # LINE AC
    movl trix, %edi
    movl triy, %esi
    addl trisize, %esi

    movl trisize, %eax
    xor %edx, %edx
    movl $2, %r9d
    divl %r9d
    movl trix, %edx
    addl %eax, %edx
    movl triy, %ecx
    movl GREEN, %r8d
    call DrawLine

    # LINE AB
    movl trix, %edi
    movl triy, %esi
    addl trisize, %esi
    movl trix, %edx
    addl trisize, %edx
    movl triy, %ecx
    addl trisize, %ecx
    movl GREEN, %r8d
    call DrawLine

    # LINE BC
    movl trix, %edi
    addl trisize, %edi
    movl triy, %esi
    addl trisize, %esi
    movl trisize, %eax
    xor %edx, %edx
    movl $2, %r9d
    divl %r9d
    movl trix, %edx
    addl %eax, %edx
    movl triy, %ecx
    movl GREEN, %r8d
    call DrawLine

# ------------------------------
# DRAW PROJECTILES
# ------------------------------
    xorl %ebx, %ebx
.draw_proj_loop:
    mov MAX_ENEMIES, %ecx
    cmpl %ecx, %ebx
    jge .draw_enemies
    lea active, %rax
    movzbl (%rax,%rbx,1), %edx
    test %edx, %edx
    je .dp_next

    # load projectile base coords
    lea projX, %rax
    movl (%rax,%rbx,4), %edi      # rdi = startX (arg1)
    lea projY, %rax
    movl (%rax,%rbx,4), %esi      # rsi = startY (arg2)

    # endX = startX  -> put into rdx
    movl %edi, %edx

    # endY = startY - projlength -> put into rcx
    movl %esi, %ecx
    movl projlength, %r9d
    subl %r9d, %ecx

    # color in r8d (5th arg)
    movl RAYWHITE, %r8d
    call DrawLine

.dp_next:
    inc %ebx
    jmp .draw_proj_loop

# ------------------------------
# DRAW ENEMIES
# ------------------------------

.draw_enemies:
    xorl %ebx, %ebx
.en_draw_loop:
    movl MAX_ENEMIES, %ecx      # if ebx >= MAX_ENEMIES -> done
    cmpl %ecx, %ebx
    jge .draw_lines
    lea enemyActive, %rax
    movzbl (%rax,%rbx,1), %edx
    test %edx, %edx
    je .en_draw_next

    # load enemy center coords
    lea enemyX, %rax
    movl (%rax,%rbx,4), %edi   # centerX
    lea enemyY, %rax
    movl (%rax,%rbx,4), %esi   # centerY

    # load float radius into xmm0 (raylib expects float as radius)
    movss cirrad, %xmm0

    # color in edx
    movl RED, %edx

    call DrawCircle

    # Draw inner circle (thickness effect)
    lea enemyX, %rax
    movl (%rax,%rbx,4), %edi   # centerX
    lea enemyY, %rax
    movl (%rax,%rbx,4), %esi   # centerY

    movss cirrad, %xmm0
    subss enemythickness, %xmm0   # decrease radius for next circle (thickness effect)
    
    movl BLACK, %edx
    call DrawCircle
    

.en_draw_next:
    inc %ebx
    jmp .en_draw_loop

# ------------------------------
# DRAW LINE OBSTACLES
# ------------------------------
.draw_lines:
    xorl %ebx, %ebx
.draw_line_loop:
    cmpl $2, %ebx
    jge .draw_powerups
    lea lineActive, %rax
    movzbl (%rax,%rbx,1), %edx
    test %edx, %edx
    je .next_draw_line

    # load Y and gapX
    lea lineY, %rax
    movl (%rax,%rbx,4), %esi        # lineY
    lea lineGapX, %rax
    movl (%rax,%rbx,4), %edi        # gapX

    # draw left segment (from 0 to gapX)
    movl $0, %edx
    movl %esi, %ecx
    movl RED, %r8d
    call DrawLine                   # (startX=0, startY=lineY, endX=gapX, endY=lineY)

    lea lineY, %rax
    movl (%rax,%rbx,4), %esi        # lineY
    lea lineGapX, %rax
    movl (%rax,%rbx,4), %edi        # gapX

    # draw right segment (from gapX+enemygap to width)
    addl enemygap, %edi
    movl %esi, %ecx
    movl width, %edx
    movl RED, %r8d
    call DrawLine

.next_draw_line:
    inc %ebx
    jmp .draw_line_loop

# ------------------------------
# DRAW POWER-UPS (green squares)
# ------------------------------
.draw_powerups:
    xorl %ebx, %ebx
.power_draw_loop:
    cmpl $3, %ebx
    jge .draw_ui
    lea powerActive, %rax
    movzbl (%rax,%rbx,1), %edx
    test %edx, %edx
    je .next_power_draw

    # posX, posY
    lea powerX, %rax
    movl (%rax,%rbx,4), %edi
    lea powerY, %rax
    movl (%rax,%rbx,4), %esi

    # width, height = powerupsize
    movl powerupsize, %edx
    movl powerupsize, %ecx

    # color
    movl GREEN, %r8d

    call DrawRectangle

.next_power_draw:
    inc %ebx
    jmp .power_draw_loop



.draw_ui:
    movl heigth, %edi
    movl $10, %esi
    call DrawFPS

    # --- position debug text ---
    mov $fmt_xy, %rdi
    movl trix, %esi
    movl triy, %edx
    call TextFormat

    mov %rax, %rdi
    mov $10, %esi
    mov $40, %edx
    mov $20, %ecx
    mov GREEN, %r8d
    call DrawText

    # --- position score text ---
    mov $fmt_score, %rdi
    movl score, %esi
    call TextFormat

    mov %rax, %rdi
    mov $10, %esi
    mov $10, %edx
    mov $30, %ecx
    mov GREEN, %r8d
    call DrawText

    # --- position health text ---
    mov $fmt_health, %rdi
    movl trihealth, %esi
    call TextFormat

    mov %rax, %rdi
    mov $10, %esi
    mov $1000, %edx
    mov $30, %ecx
    mov RED, %r8d
    call DrawText

    call EndDrawing
    jmp drawloop

# ------- GAME OVER SEQUENCE -------
lose:
    mov RED, %eax
    mov %eax, titlecolor
    movb $1, gameoverflag
    movq score, %rdi
    call updatescores

    jmp titleloop


close:
    movq $0, %rdi       # Just in case, sort scores on exit
    call updatescores  

    call CloseWindow
    mov $0, %rdi
    call exit

# -----------------------------------------------------------
#  updatescores(int score)
#   - Loads highscores from "highscores.dat" (or zeros if missing)
#   - Inserts 'score' into the correct descending position
#   - Saves highscores back to "highscores.dat"
# -----------------------------------------------------------
updatescores:
	# Prologue
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$32, %rsp              # locals:
	                              # -8(%rbp)  : FILE* fp
	                              # -12(%rbp) : int i
	                              # -16(%rbp) : int j
	                              # -20(%rbp) : int score

	# Save argument
	movl	%edi, -20(%rbp)

# ---------------------------------------
# Load highscores (rb), or init zeros
# ---------------------------------------
	leaq	readmode, %rsi      # mode = "rb"
	leaq	filename, %rdi     # filename
	call	fopen@PLT
	movq	%rax, -8(%rbp)         # fp

	cmpq	$0, -8(%rbp)
	jne	readfile

# File missing -> highscores = {0,0,0,0,0}
	movl	$0, -12(%rbp)          # i = 0
initloop:
	cmpl	$5, -12(%rbp)
	jge	afterload
	movl	-12(%rbp), %eax
	movslq  %eax, %rax              # for index usage, zero extend 32 bit-> 64 (otherwise compiler will complain)
	leaq	highscores, %rdx        # "wah wah, not a valid base index expression" STFU
	movl	$0, (%rdx,%rax,4)
	incl	-12(%rbp)
	jmp	initloop

# Read existing table
readfile:
	# fread(void *ptr, size_t size, size_t nmemb, FILE *stream)
	leaq	highscores, %rdi  # ptr
	movl	$4, %esi                # size = sizeof(int)
	movl	$5, %edx                # nmemb = 5
	movq	-8(%rbp), %rcx          # stream = fp
	call	fread@PLT

	# fclose(fp)
	movq	-8(%rbp), %rdi
	call	fclose@PLT

afterload:

# ---------------------------------------
# Insert 'score' (descending order)
# ---------------------------------------
	movl	$0, -12(%rbp)          # i = 0
findpos:
	cmpl	$5, -12(%rbp)
	jge	save            # reached end, nothing to insert

	# if (score > highscores[i]) break and shift
	movl	-12(%rbp), %eax
	movslq  %eax, %rax
	leaq	highscores, %rdx
	movl	(%rdx,%rax,4), %eax     # eax = highscores[i]
	cmpl	%eax, -20(%rbp)         # score > highscores[i] ?
	jg	    shift_and_replace

	# i++
	incl	-12(%rbp)
	jmp	    findpos

# Shift down from j = 4 .. i+1
shift_and_replace:
	movl	$4, -16(%rbp)          # j = 4
shiftloop:
	movl	-16(%rbp), %eax
	cmpl	-12(%rbp), %eax
	jle	insert             # stop when j <= i

	# highscores[j] = highscores[j-1]
	movl	-16(%rbp), %eax
	decl	%eax
    movslq  %eax, %rax
	leaq	highscores, %rdx
	movl	(%rdx,%rax,4), %ecx     # ecx = highscores[j-1]

	movl	-16(%rbp), %eax
	cltq
	leaq	highscores, %rdx
	movl	%ecx, (%rdx,%rax,4)     # highscores[j] = ecx

	decl	-16(%rbp)               # j--
	jmp	shiftloop

# Place the new score at highscores[i]
insert:
	movl	-12(%rbp), %eax
	movslq  %eax, %rax
	leaq	highscores, %rdx
	movl	-20(%rbp), %ecx         # score
	movl	%ecx, (%rdx,%rax,4)
	jmp	save

# ---------------------------------------
# Save highscores (wb)
# ---------------------------------------
save:
	leaq	writemode, %rsi   # mode = "wb"
	leaq	filename, %rdi     # filename
	call	fopen
	movq	%rax, -8(%rbp)          # fp
	cmpq	$0, -8(%rbp)
	je  end                    # if open failed, just return

	# fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream)
	leaq	highscores, %rdi        # ptr
	movl	$4, %esi                # size = sizeof(int)
	movl	$5, %edx                # nmemb = 5
	movq	-8(%rbp), %rcx          # stream
	call	fwrite

	# fclose(fp)
	movq	-8(%rbp), %rdi
	call	fclose

# Epilogue
end:
	leave
	ret

# -------------------------------------------------------------------

LCG_genrandint:
    push %rbp
    mov %rsp, %rbp
    movl spawnseed, %eax      # load current seed
    imull $1664525, %eax      # multiply by c
    addl $1013904223, %eax    # add a
    movl %eax, spawnseed      # store new seed

    mov width, %ecx           # load width as modulus
    xorl %edx, %edx           # clear edx for div
    divl %ecx                 # eax = seed % width
    movl %edx, %eax
    pop %rbp
    ret
