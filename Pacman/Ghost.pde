abstract class Ghost {


  /* Movement variables */

  PVector pos;    // Current pixel position
  int nextGridX;  // Next grid x coord
  int nextGridY;  // Next grid y coord

  private Dir dir;      // Current direction
  private Dir nextDir;  // Direction to take in the next tile

  // When chosing the next direction, the ghost will loop this array. The order
  // is important to break ties if the distance of two directions is the same.
  private Dir[] dirs = {Dir.U, Dir.L, Dir.D, Dir.R};

  private PVector scatterTarget;  // scatter mode target
  PVector chaseTarget;            // chase mode target (updated before moving)

  private int dotCounter;  // Counter of dots eaten (to exit the house)


  /* Sprites and animation */

  private boolean inHouse;       // true if the ghost is still in the house
  private boolean exitingHouse;  // set true when the ghost has to leave the house

  private final PImage ghostsprites = loadImage("ghosts.png");  // Sprite sheet
  private int ox;  // Sprite sheet x offset
  private int oy;  // Sprite sheet y offset


  /**
   * Constructor.
   *
   * @param pos initial position;
   * @param dir initial direction;
   * @param scatterTarget of this ghost;
   * @param oy y offset in the sprite sheet;
   */
  Ghost (PVector pos, Dir dir, PVector scatterTarget, int oy) {
    this.pos = pos;
    this.dir = dir;
    nextDir = dir;
    nextGridX = floor(pos.x/tileL) + dir.x;
    nextGridY = floor(pos.y/tileL) + dir.y;
    this.scatterTarget = scatterTarget;
    dotCounter = 0;
    inHouse = true;
    exitingHouse = false;
    this.oy = oy;
  }


  /**
   * Calls the moveToTarget method with the appropriate target for the current mode.
   */
  void move () {
    if (waitingInput) return;
    if (exitingHouse) {
      exitHouse();
      return;
    }
    if (inHouse) {
      animateInHouse();
      return;
    }
    if (mode.equals("scatter")) moveToTarget(scatterTarget);
    else if (mode.equals("chase")) {
      updateTarget();
      moveToTarget(chaseTarget);
    }
    else if (mode.equals("scared")) moveToTarget(new PVector(r.nextInt(28), r.nextInt(36)));
  }


  /**
   * When a ghost enters a new tile, it looks to the tile ahead and decides which
   * direction it's going to take.
   *
   * @param target vector to the grid position of the current target.
   */
  private void moveToTarget (PVector target) {

    /* Check if it's a new tile and it's roughly in the middle of a tile. */
    if (nextGridX == floor(pos.x/tileL) && nextGridY == floor(pos.y/tileL) &&
      (pos.x % tileL > 6.5 && pos.x % tileL < 9.5) && (pos.y % tileL > 6.5 && pos.y % tileL < 9.5)) {
       
      /* Change direction. */
      dir = nextDir;

      /* Calculate the next position in the grid. */
      nextGridX = floor(pos.x/tileL) + dir.x;
      nextGridY = floor(pos.y/tileL) + dir.y;

      /* Calculate the next direction. */
      // If it's currently crossing the tunnel, correct nextDirX. Otherwise, calculate the
      // next direction.
      if (nextGridY == 17 && (nextGridX + dir.x < 0 || nextGridX + dir.x > 27)) {
        if (nextGridX == 0) nextGridX = 27;
        else if (nextGridX == 27) nextGridX = 0;
      } else {

        // Loop the directions and find the turn that is closer to the target.
        Float minDist = Float.POSITIVE_INFINITY;
        for (Dir current : dirs) {

          // Don't turn up on red zones
          if (current == Dir.U && (
            ( nextGridY == 14 && (nextGridX == 12 || nextGridX == 15) ) || 
            ( nextGridY == 26 && (nextGridX == 12 || nextGridX == 15) ) )) {
            continue;
          }

          // Don't turn back
          if ((current.x == -dir.x && current.y == 0) || (current.x == 0 && current.y == -dir.y)) continue;

          // Calculate the distance.
          float tempdist = PVector.dist(target, new PVector(nextGridX+current.x, nextGridY+current.y));
          // If the distance is less and the position is not a wall, chose that direction.
          if (tempdist < minDist && grid[nextGridY+current.y][nextGridX+current.x] != 0) {
            nextDir = current;
            minDist = tempdist;
          }
        }
      }
    }

    // Move the ghost.
    float sX = dir.x * speed * speedPercentage();
    float sY = dir.y * speed * speedPercentage();
    PVector s = new PVector(sX, sY);
    pos.add(s);

    // Crossing the tunel.
    if (pos.x < 0) pos.x += width;
    else if (pos.x > width) pos.x -= width;
  }


  /**
   * Called in the mode changes that require the ghosts to reverse direction.
   */
  void reverseDir () {
    if (dir == Dir.U) nextDir = Dir.D;
    else if (dir == Dir.D) nextDir = Dir.U;
    else if (dir == Dir.R) nextDir = Dir.L;
    else if (dir == Dir.L) nextDir = Dir.R;
  }


  /**
   * Just moves the ghost up and down while they're in the house.
   */
  private void animateInHouse () {
    if (pos.y < 270) dir = Dir.D;
    else if (pos.y > 290) dir = Dir.U;
    pos.y += dir.y * 1.2;
  }


  /**
   * Animation of exiting the house.
   */
  private void exitHouse () {
    // Calculate the distance from the center of the screen.
    float dfc = 224 - pos.x;
    
    // If it's not in the center, move to it.
    if (dfc > 1.5 || dfc < -1.5) {
      if (dfc > 0) {  // On the left
        dir = Dir.R;
        pos.x += 1.2;
      } else {        // On the right
        dir = Dir.L;
        pos.x -= 1.2;
      }
      return;
    }

    // If it's not in position, go up.
    if (pos.y > 233.5) {
      dir = Dir.U;
      pos.y -= 1.2;
      return;
    }

    // In position, go to left or right.
    if (modeCounter == 0) {
      dir = Dir.L;
      nextDir = Dir.L;
    } else {
      dir = Dir.R;
      nextDir = Dir.R;
    }

    nextGridX = floor(pos.x/tileL) + dir.x;
    nextGridY = floor(pos.y/tileL) + dir.y;
    exitingHouse = false;
  }


  /**
   * Renders the ghost with the correct sprite.
   */
  void render () {
    pushMatrix();
    translate(pos.x, pos.y);
    beginShape();
    texture(ghostsprites);

    int cx = currentXOffset();

    vertex(-10, -10, cx, oy);
    vertex(10, -10, cx+14, oy);
    vertex(10, 10, cx+14, oy+14);
    vertex(-10, 10, cx, oy+14);

    endShape();
    popMatrix();
  }


  /**
   * Changes the x offset to represent the direction of movement and the animation.
   *
   * @return x offset;
   */
  private int currentXOffset () {
    // Changing the x offset to the direction of movement.
    if (inHouse || exitingHouse) {
      if (dir == Dir.U) {
        ox = 0;
      } else if (dir == Dir.D) {
        ox = 30;
      } else if (dir == Dir.L) {
        ox = 60;
      } else if (dir == Dir.R) {
        ox = 90;
      }
    } else if (nextDir == Dir.U) {
      ox = 0;
    } else if (nextDir == Dir.D) {
      ox = 30;
    } else if (nextDir == Dir.L) {
      ox = 60;
    } else if (nextDir == Dir.R) {
      ox = 90;
    }

    if (frameCount % 20 < 10) {
      return ox;
    } else {
      return ox+15;
    }
  }


  /**
   * Used to update the chase target before the move() call.
   *
   * @param pacpos the current position of pac-man;
   * @param pacdir pac-man's direction of travel;
   */
  public abstract void updateTarget () ;


  /**
   * Lookup in the levelSpecs table for the current speed.
   *
   * @return current speed;
   */
  public abstract float speedPercentage () ;


  public abstract int currentDotLimit () ;
}
