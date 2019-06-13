class Pac {

  // Counter for the points since the start of the game.
  private int points;
  

  /* pac-man sprites */

  private final PImage pacsprites = loadImage("pacman.png");
  private int ox; // x coordinate in the sprite sheet.
  private int oy; // y coordinate in the sprite sheet.
  private boolean stopped;


  /* Movement variables */

  // Pixel position.
  private PVector pos;
  // Current direction.
  private Dir dir;
  // User defined direction.
  private Dir nextDir;
  // Counts stoped frames after eating a power pellet (3).
  private int powerPelletStopCounter;


  Pac () {
    ox = oy = 0;
    stopped = true;

    pos = new PVector(14*tileL, 26*tileL+8);
    dir = Dir.N;
    nextDir = Dir.N;
    powerPelletStopCounter = 0;
  }


  /**
   * Checks the dot and pellet collisions, handles crossing the tunnel, turns, stopping
   * before a wall and moving.
   *
   * @return 0 if nothing happened, 1 if just ate a dot, 2 if just ate a power pellet;
   */
  int move () {
    if (powerPelletStopCounter > 0) {
      powerPelletStopCounter--;
      return 0;
    }

    stopped = false;

    int gridX = floor(pos.x/tileL);
    int gridY = floor(pos.y/tileL);

    /* Check the tile for dots and pellets. */
    if (grid[gridY][gridX] == 1) {
      points += 10;
      grid[gridY][gridX] = 8;
      // Stop moving for a frame when a dot is eaten.
      return 1;
    } else if (grid[gridY][gridX] == 7) {
      points += 50;
      grid[gridY][gridX] = 8;
      // Stop moving for 3 frames when a pp is eaten.
      powerPelletStopCounter = 2;
      return 2;
    }

    float spercent = speedPercentage();

    /* Check if it's crossing the tunnel and move accordingly. */
    float nextX = pos.x + dir.x * speed * spercent;
    if (nextX < 0) {
      pos.x = width + nextX;
      return 0;
    } else if (nextX > width) {
      pos.x = nextX - width;
      return 0;
    }

    /* Check if it's in turn condition and do it (pre and post turn). */
    if (dir != nextDir &&                                     // It's a turn
      gridX + nextDir.x >= 0 && gridX + nextDir.x <= 27 &&  // Not in the tunnel
      grid[gridY + nextDir.y][gridX + nextDir.x] != 0 ) {   // Target is not a wall

      //inPreTurn = true;

      // In the case of a reverse, just do it and return.
      if ((dir.x == 0 && dir.y == -nextDir.y) || (dir.y == 0 && dir.x == -nextDir.x)) {
        dir = nextDir;
        float sX = dir.x * speed * spercent;
        float sY = dir.y * speed * spercent;
        PVector s = new PVector(sX, sY);
        pos.add(s);
        return 0;
      }

      // Distance from the center of the tile.
      float dfcx = 8 - (pos.x % 16);
      float dfcy = 8 - (pos.y % 16);
      float sdfcx = Math.signum(dfcx);
      float sdfcy = Math.signum(dfcy);

      // Update the position.
      pos.x += (abs(dir.x) * sdfcx + nextDir.x) * speed * spercent;
      pos.y += (abs(dir.y) * sdfcy + nextDir.y) * speed * spercent;

      // If the centerline is reached, stop the turn.
      if ( (dir.y == 0 && (dfcx < 1.5 && dfcx > -1.5)) || (dir.x == 0 && (dfcy < 1.5 && dfcy > -1.5)) ) {
        dir = nextDir;
      }

      return 0;
    }

    /* Return if it's goind to hit a wall. */
    if (floor( (pos.x + dir.x*9) /tileL) >= 0 && floor( (pos.x + dir.x*9) /tileL) <= 27 &&
      grid[floor( (pos.y + dir.y*9) /tileL)][floor( (pos.x + dir.x*9) /tileL)] == 0) {
      stopped = true;
      // make sure it doesn't stop with the mouth closed
      if (ox == 0) ox = 14;
      return 0;
    }

    /* Update pac-man's position. */
    float sX = dir.x * speed * spercent;
    float sY = dir.y * speed * spercent;
    PVector s = new PVector(sX, sY);
    pos.add(s);

    return 0;
  }


  /**
   * Lookup in the levelSpecs table for the current speed.
   *
   * @return current speed;
   */
  private float speedPercentage () {
    if (mode.equals("scared")) return levelSpecs[level][9];
    return levelSpecs[level][2];
  }


  /**
   * Sets the nextDir on user input.
   *
   * @param nextDir direction chosen by the player;
   */
  void changeDir (Dir nextDir) {
    this.nextDir = nextDir;
  }


  /**
   * Renders pac-man and swaps the sprites.
   */
  void render () {

    if (!stopped && !waitingInput) {
      swapSprite();
    }

    pushMatrix();
    translate(pos.x, pos.y);
    beginShape();
    texture(pacsprites);

    vertex(-10, -10, ox, oy);
    vertex(10, -10, ox+13, oy);
    vertex(10, 10, ox+13, oy+13);
    vertex(-10, 10, ox, oy+13);

    endShape();
    popMatrix();
  }


  /**
   * Changes the xy coordinates of the sprite sheet, to animate the movement.
   */
  private void swapSprite () {
    // Changing the y offset to the direction of movement.
    if (dir == Dir.U) {
      oy = 0;
    } else if (dir == Dir.D) {
      oy = 14;
    } else if (dir == Dir.L) {
      oy = 28;
    } else if (dir == Dir.R) {
      oy = 42;
    }

    // Changing the x offset changes the moment in the animation (mouth opens and closes).
    int time = frameCount % 12;
    if (time < 3) {
      ox =  0;
    } else if (time < 6) {
      ox = 14;
    } else if (time < 9) {
      ox = 28;
    } else ox = 14;
  }
}
