# Assembly-Space-Game
Assembly space invaders/galaga inspired space shooter. Made for the Computer Organisation course during my Computer Science &amp; Engineering course at TU Delft. 
Made in x86 AT&T assembly, using the raylib library. 

<img width="1622" height="975" alt="unnamed" src="https://github.com/user-attachments/assets/d331148d-ad13-4cd6-bb92-db45864272c2" />

To run the game, open the file in a WSL environment, or a subsystem like WSL in visual studio code. 
Make sure to install raylib and its dependencies, using

<code>sudo apt update
sudo apt install build-essential cmake git pkg-config \
    libx11-dev libxcursor-dev libxrandr-dev libxinerama-dev libxi-dev \
    libgl1-mesa-dev libglu1-mesa-dev \
    libasound2-dev libpulse-dev libopenal-dev libvorbis-dev libogg-dev
</code>

Or in a repository

<code>sudo add-apt-repository ppa:texus/raylib
sudo apt update
sudo apt install libraylib5-dev
</code>

To compile video.s using gcc, use the following command

<code>gcc -no-pie video.s -o game -lraylib -lm -ldl -lpthread - lx11</code>
