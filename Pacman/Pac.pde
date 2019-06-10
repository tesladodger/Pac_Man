class Pac {

  // Counter for the points since the start of the game.
  private int points;


  /* Pacman sprites */

  private final PImage pacsprites = loadImage("pacman.png");
  private int ox; // x coordinate in the sprite sheet.
  private int oy; // y coordinate in the sprite sheet.
  private boolean stopped; // this is only used for animation, not movement.


  /* Movement variables */

  // Pixel position.
  private PVector pos;
  // Current direction.
  private Dir dir;
  // User defined direction.
  private Dir nextDir;


  Pac () {
    ox = oy = 0;
    stopped = true;

    pos = new PVector(14*tileL, 26*tileL+8);
    dir = Dir.N;
    nextDir = Dir.N;
  }


  /**
   * Checks the dot and pellet collisions, handles crossing the tunnel, turns and pre-turns,
   * stopping before a wall and moving.
   */
  void move () {
    int gridX = floor(pos.x/tileL);
    int gridY = floor(pos.y/tileL);

    /* Check the tile for dots and pellets. */
    if (grid[gridY][gridX] == 1) {
      points += 10;
      grid[gridY][gridX] = 8;
      return; // Stop moving for a frame when a dot is eaten.
    }

    float spercent = speedPercentage();

    /* Check if it's crossing the tunnel and move accordingly. */
    float nextX = pos.x + dir.x * speed * spercent;
    if (nextX < 0) {
      pos.x = width + nextX;
      return;
    } else if (nextX > width) {
      pos.x = nextX - width;
      return;
    }

    /* Check if a turn can be made right now. */
    // If the tile in the desired direction of movement is not a wall and if it's
    // reasonlably in the middle of the tile (might remove this later).
    if (gridX + nextDir.x >= 0 && gridX + nextDir.x <= 27 &&
      grid[gridY + nextDir.y][gridX + nextDir.x] != 0 && 
      (pos.x % tileL > 6.5 && pos.x % tileL < 9.5) && (pos.y % tileL > 6.5 && pos.y % tileL < 9.5)) {
      // change direction
      dir = nextDir;
    }

    /* Check if it's in pre-turn condition and start it. */


    /* Return if it's goind to hit a wall. */
    if (floor( (pos.x + dir.x*8) /tileL) >= 0 && floor( (pos.x + dir.x*8) /tileL) <= 27 &&
      grid[floor( (pos.y + dir.y*8) /tileL)][floor( (pos.x + dir.x*8) /tileL)] == 0) {
      pos.x = pos.x - (pos.x % tileL) + 8;
      pos.y = pos.y - (pos.y % tileL) + 8;
      nextDir = Dir.N;
      stopped = true;
      // make sure it doesn't stop with the mouth closed
      if (ox == 0) ox = 14;
      return;
    }

    /* Update pacman's position. */
    if (dir != Dir.N) {
      stopped = false;
      float sX = dir.x * speed * spercent;
      float sY = dir.y * speed * spercent;
      PVector s = new PVector(sX, sY);
      pos.add(s);
    }
  }


  /**
   * Lookup in the levelSpecs table for the current speed.
   *
   * @return current speed;
   */
  private float speedPercentage () {
    return levelSpecs[level-1][2];
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
   * Renders pacman and swaps the sprites.
   */
  void render () {

    if (!stopped) {
      swapSprite();
    }

    pushMatrix();
    translate(pos.x, pos.y);
    beginShape();
    texture(pacsprites);

    vertex(-8, -8, ox, oy);
    vertex(8, -8, ox+13, oy);
    vertex(8, 8, ox+13, oy+13);
    vertex(-8, 8, ox, oy+13);

    endShape();
    popMatrix();
  }


  /**
   * Changes the xy coordinates of the sprite sheet, to animate the movement.
   */
  void swapSprite () {
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
