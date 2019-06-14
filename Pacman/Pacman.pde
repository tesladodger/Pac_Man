/*
 * A recriation of the mechanics of the original game, including bugs
 * (like the overflow bug when pac-man is facing up).
 * I try to use the exact logic and behaviors, and approximate the 
 * timings as well as I can.
 * 
 * The sprites are all made by me.
 *
 * Given the pixel density of today's screens, the size of a tile
 * was changed to 16*16. Since the grid is 28*36, we get a 448*576
 * screen. I had to decrease the tolerances in pac-man's movement,
 * because what would be round up in an 8*8 tile isn't in a 16*16, and
 * doesn't look as good. A lot of coordinates and sizes are hard-coded,
 * more for simplicity than speed.
 */

import java.util.Random;
import processing.sound.*;

/* ------------------------------------------------------------------- Look and sound */
// Tile length. In most places, tileL and tileL/2 are hard-coded. I don't plan on 
// changing the dimensions, so it's not really a problem.
private static final int tileL = 16;

// Background image.
private PImage backgroundImage;

// Emulogic font (in the data folder).
private PFont font;

// Intro song (I recreated with <a>https://beepbox.co/</a> ).
SoundFile intro;


/* ------------------------------------------------------------------- Movement */
// Speed tuned by loking at the ghost timings in the original
private static final float speed = 2.54; // [pixels/frame]

// Enumeration of the directions of travel.
enum Dir {
  U (0, -1), D (0, 1), L (-1, 0), R (1, 0), N (0, 0);
  int x, y;
  private Dir (int x, int y) {
    this.x = x;
    this.y = y;
  }
}

Random r;


/* ------------------------------------------------------------------- Game state */
// Current level of the player.
private int level;

// How many lives are still available.
private int lives;

// Ghosts can be in 'chase', 'scatter' or 'frightened' mode.
private String mode;

// When changing to scared mode, save the current mode to change back.
private String prevMode;

// Counts the mode changes.
private int modeCounter;

// Timer for each mode.
private long modeStopwatch;

// Timer for the scared mode.
private long scaredModeStopwatch;

// Counter for how many ghosts are eaten with a single power pellet.
private int ghostsEaten;

// Timer to free the most prefered ghost from the house.
private long freeGhostsTimer;

// Before a round, this is set to true. False when pac-man starts moving.
private boolean waitingInput;

// Index of the active ghost in the house.
private int activeI;


/* ------------------------------------------------------------------- Characters */
Pac pac;
Ghost[] ghosts;


void setup () {
  size(448, 576, P2D);
  backgroundImage = loadImage("maze2.png");
  textureMode(IMAGE);
  imageMode(CENTER);
  ellipseMode(CENTER);
  textAlign(CENTER);
  font = createFont("emulogic.ttf", 16);
  textFont(font, 16);
  intro = new SoundFile(this, "introtune.wav");
  
  r = new Random();
  level = 1;
  lives = 2;
  waitingInput = true;
  activeI = 1;
  
  pac = new Pac();
  ghosts = new Ghost[4];
  ghosts[0] = new Blinky(new PVector(14*tileL, 14*tileL+8), Dir.L, new PVector(25, 0),  0);
  ghosts[1] = new Pinky (new PVector(14*tileL, 17*tileL+8), Dir.U, new PVector(3, 0),   15);
  ghosts[2] = new Inky  (new PVector(12*tileL, 17*tileL+8), Dir.D, new PVector(27, 35), 30);
  ghosts[3] = new Clyde (new PVector(16*tileL, 17*tileL+8), Dir.D, new PVector(0, 35),  45);
  ghosts[0].inHouse = false;
  
  mode = "scatter";
  modeCounter = 0;
}


void draw () {
  background(0);
  image(backgroundImage, 224, 288, width, height);
  surface.setTitle(int(frameRate) + " fps");
  if (frameCount == 1) intro.play();
  
  
  /* Logic */
  
  changeMode();
  //System.out.println(mode);
  int x = pac.move();
  // If pac-man just ate a dot, increase the dot counter of the active ghost in the house.
  if (x == 1) {
    if (ghosts[activeI].inHouse) ghosts[activeI].dotCounter += 1;
    freeGhostsTimer = System.currentTimeMillis();
  }
  // Power pellet, scare the ghosts.
  else if (x == 2) {
    prevMode = mode;
    mode = "scared";
    for (Ghost g : ghosts) {
      g.reverseDir();
    }
    ghostsEaten = 0;
    scaredModeStopwatch = System.currentTimeMillis();
  }
  
  updateGhosts();


  /* Render */
  
  drawDots();
  drawHUD();
  pac.render();
  if (frameCount < 200) return;
  for (Ghost g : ghosts) g.render();
}


/**
 * Loops the ghosts to:
 * - exit the house;
 * - update the target;
 * - move;
 */
void updateGhosts () {
  
  // Get the active ghost in the house.
  activeI = 0;
  for (int i = ghosts.length-1; i > 0; i--) {
    if (ghosts[i].inHouse) activeI = i;
  }
  
  // Free the active ghost if the timer is up or the dot counter is reached.
  int timeLimit = level < 5 ? 4000 : 3000;
  if (!waitingInput && ghosts[activeI].inHouse && 
     ( System.currentTimeMillis() - freeGhostsTimer >= timeLimit || 
       ghosts[activeI].dotCounter >= ghosts[activeI].currentDotLimit() ) ) {
      
    ghosts[activeI].inHouse = false;
    ghosts[activeI].exitingHouse = true;
    freeGhostsTimer = System.currentTimeMillis();
    
  }
  
  for (Ghost g : ghosts) {
    g.move();
    // Murder the ghosts in scared mode.
    if (mode.equals("scared") && g.sameTileAsPac() && !g.returningHome) {
      // Points to pac-man.
      pac.points += 200 * Math.pow(2, ghostsEaten++);
      // Ghost returns home.
      g.returningHome = true;
    }
  }
  
  
}


/*
 * 0 is a wall, 1 is a dot, an 8 is part of the path without a dot, 7 is a power pellet.
 * Don't forget the x and y coordinates are swapped, the correct usage is grid[y][x]. 
 */
static final int[][] grid = {
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, 
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, 
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, 
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, 
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0}, 
  {0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0}, 
  {0, 7, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 7, 0}, 
  {0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0}, 
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0}, 
  {0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0}, 
  {0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0}, 
  {0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 0}, 
  {0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 8, 0, 0, 8, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0}, 
  {0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 8, 0, 0, 8, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0}, 
  {0, 0, 0, 0, 0, 0, 1, 0, 0, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 0, 0, 1, 0, 0, 0, 0, 0, 0}, 
  {0, 0, 0, 0, 0, 0, 1, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 1, 0, 0, 0, 0, 0, 0}, 
  {0, 0, 0, 0, 0, 0, 1, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 1, 0, 0, 0, 0, 0, 0}, 
  {8, 8, 8, 8, 8, 8, 1, 8, 8, 8, 0, 0, 0, 0, 0, 0, 0, 0, 8, 8, 8, 1, 8, 8, 8, 8, 8, 8}, 
  {0, 0, 0, 0, 0, 0, 1, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 1, 0, 0, 0, 0, 0, 0}, 
  {0, 0, 0, 0, 0, 0, 1, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 1, 0, 0, 0, 0, 0, 0}, 
  {0, 0, 0, 0, 0, 0, 1, 0, 0, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 0, 0, 1, 0, 0, 0, 0, 0, 0}, 
  {0, 0, 0, 0, 0, 0, 1, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 1, 0, 0, 0, 0, 0, 0}, 
  {0, 0, 0, 0, 0, 0, 1, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 1, 0, 0, 0, 0, 0, 0}, 
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0}, 
  {0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0}, 
  {0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0}, 
  {0, 7, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 8, 8, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 7, 0}, 
  {0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0}, 
  {0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0}, 
  {0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 0}, 
  {0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0}, 
  {0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0}, 
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0}, 
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, 
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, 
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
};


/* 
 * Table for the level specific values:
 * - Type of fruit;
 * - Bonus points;
 * - Pac-man speed;
 * - Ghost speed;
 * - Ghost tunnel speed;
 * - Dots left for Elroy 1;
 * - Elroy 1 speed;
 * - Dots left for Elroy 2;
 * - Elroy 2 speed;
 * - Pac-man speed in frightened mode;
 * - Ghost speed in frightened mode;
 * - Frightened mode time;
 * - Number of flashes before end of frightened mode;
 */
static final float[][] levelSpecs = new float[][] {
  {}, // empty index so the lookup is level instead of level-1
  //fruit bonus pcspd gspd tspd elrd elspd elrd2 elrspd2 frpcspd frgspd frtmms #flashes level
  {    0,  100,  .80, .75, .40,  20,   .80,  10,    .85,    .90,   .50,  6000,     5},  // 1
  {    1,  300,  .90, .85, .45,  30,   .90,  15,    .95,    .95,   .55,  5000,     5},  // 2
  {    2,  500,  .90, .85, .45,  40,   .90,  20,    .95,    .95,   .55,  4000,     5},  // 3
  {    2,  500,  .90, .85, .45,  40,   .90,  20,    .95,    .95,   .55,  3000,     5},  // 4
  {    3,  700,  1  , .85, .50,  40,   1  ,  20,   1.05,    1  ,   .60,  2000,     5},  // 5
  {    3,  700,  1  , .95, .50,  50,   1  ,  25,   1.05,    1  ,   .60,  5000,     5},  // 6
  {    4, 1000,  1  , .95, .50,  50,   1  ,  25,   1.05,    1  ,   .60,  2000,     5},  // 7
  {    4, 1000,  1  , .95, .50,  50,   1  ,  25,   1.05,    1  ,   .60,  2000,     5},  // 8
  {    5, 2000,  1  , .95, .50,  60,   1  ,  30,   1.05,    1  ,   .60,  1000,     3},  // 9
  {    5, 2000,  1  , .95, .50,  60,   1  ,  30,   1.05,    1  ,   .60,  5000,     5},  // 10
  {    6, 3000,  1  , .95, .50,  60,   1  ,  30,   1.05,    1  ,   .60,  2000,     5},  // 11
  {    6, 3000,  1  , .95, .50,  80,   1  ,  40,   1.05,    1  ,   .60,  1000,     3},  // 12
  {    7, 5000,  1  , .95, .50,  80,   1  ,  40,   1.05,    1  ,   .60,  1000,     3},  // 13
  {    7, 5000,  1  , .95, .50,  80,   1  ,  40,   1.05,    1  ,   .60,  3000,     5},  // 14
  {    7, 5000,  1  , .95, .50, 100,   1  ,  50,   1.05,    1  ,   .60,  1000,     3},  // 15
  {    7, 5000,  1  , .95, .50, 100,   1  ,  50,   1.05,    1  ,   .60,  1000,     3},  // 16
  {    7, 5000,  1  , .95, .50, 100,   1  ,  50,   1.05,    1  ,   .60,  0   ,     0},  // 17
  {    7, 5000,  1  , .95, .50, 100,   1  ,  50,   1.05,    1  ,   .60,  1000,     3},  // 18
  {    7, 5000,  1  , .95, .50, 120,   1  ,  60,   1.05,    1  ,   .60,  0   ,     0},  // 19
  {    7, 5000,  1  , .95, .50, 120,   1  ,  60,   1.05,    1  ,   .60,  0   ,     0},  // 20
  {    7, 5000,  .90, .95, .50, 120,   1  ,  60,   1.05,    1  ,   .60,  0   ,     0}   // 21+
};


/*
 * Duration of each ghost mode in milliseconds.
 */
private static final int[][] modeTimes = new int[][] {
  {7000, 20000, 7000, 20000, 5000, 20000, 5000}, // Level 1
  {7000, 20000, 7000, 20000, 5000, 1033000, 17}, // 2-4
  {7000, 20000, 7000, 20000, 5000, 1037000, 17}, // 5+
};


/**
 * Changes the ghost modes between chase and scatter and stops scared mode.
 */
private void changeMode () {
  if (waitingInput) return;
  
  if (mode.equals("scared") && System.currentTimeMillis() - scaredModeStopwatch > levelSpecs[level][11]) {
    mode = prevMode;
    // The time spent in scared mode needs to be returned to the current mode.
    modeStopwatch += (int) levelSpecs[level][11];
    return;
  }
  
  if (modeCounter == 7) return;
  
  int index;
  if (level == 1) index = 0;
  else if (level < 5) index = 1;
  else index = 2;
  
  if (System.currentTimeMillis() - modeStopwatch > modeTimes[index][modeCounter]) {
    if (mode.equals("scatter")) mode = "chase";
    else if (mode.equals("chase")) mode = "scatter";
    else return;
    for (Ghost g : ghosts) g.reverseDir();
    modeCounter++;
    modeStopwatch = System.currentTimeMillis();
  }
}


/**
 * Renders the dots and power pellets. The frame count check is to make the power pellets
 * blink.
 */
private void drawDots () {
  noStroke();
  fill(#ffb897);
  for (int y = 0; y < 36; y++) {
    for (int x = 0; x < 28; x++) {

      //// Draw the grid for debugging
      //stroke(255);
      //noFill();
      //rectMode(CENTER);
      //rect(x*tileL+tileL/2, y*tileL+tileL/2, tileL, tileL);

      if (grid[y][x] == 1) {
        ellipse(x*tileL+8, y*tileL+8, 4, 4);
        continue;
      }
      if (frameCount % 20 < 10) continue;
      if (grid[y][x] == 7) {
        ellipse(x*tileL+8, y*tileL+8, 13, 13);
      }
    }
  }
}


/**
 * Draw the score, a pac-man in the bottom left for every life and the current fruit.
 */
private void drawHUD () {
  // Player One
  if (frameCount < 200) {
    fill(#0055ff);
    text("PLAYER ONE", 224, 240);
  }
  // Ready
  
  if (waitingInput) {
    fill(#ffff00);
    text("READY!", 224, 335);
  }
  
  // Score
  fill(255);
  text("HIGH SCORE", 224, 16);
  if (pac.points > 0) {
    textAlign(RIGHT);
    text(pac.points, 272, 32);
    textAlign(CENTER);
  }
  
  // Lives
  for (int i = 0; i < lives; i++) {
    beginShape();
    texture(pac.pacsprites);
    float x = 32 + i*24;
    float y = 34*tileL + 8;
    vertex(x, y, 14, 28);
    vertex(20 + x, y, 27, 28);
    vertex(20 + x, 20 + y, 27, 41);
    vertex(x, 20 + y, 14, 41);
    endShape();
  }
}


void keyPressed () {
  if (frameCount < 290) return;
  
  if (keyCode == UP) {
    pac.changeDir(Dir.U);
  }
  if (keyCode == DOWN) {
    pac.changeDir(Dir.D);
  }
  if (keyCode == LEFT) {
    pac.changeDir(Dir.L);
    if (waitingInput) {
      pac.dir = Dir.L;
      waitingInput = false;
      modeStopwatch = freeGhostsTimer = System.currentTimeMillis();
    }
  }
  if (keyCode == RIGHT) {
    pac.changeDir(Dir.R);
    if (waitingInput) {
      pac.dir = Dir.R;
      waitingInput = false;
      modeStopwatch = freeGhostsTimer = System.currentTimeMillis();
    }
  }
}
