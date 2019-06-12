class Clyde extends Ghost {

  
  Clyde (PVector pos, Dir dir, PVector scatterTarget, int oy) {
    super(pos, dir, scatterTarget, oy);
  }


  public void updateTarget (PVector pacpos, Dir pacdir) {
    float xdist = abs(pacpos.x - (nextGridX*16));
    float ydist = abs(pacpos.y - (nextGridY*16));
    float tempDist =  sqrt(xdist*xdist + ydist*ydist);
    
    // If it gets too close to pac-man (8 tiles), use the scatter target.
    if (tempDist <= 128) {
      chaseTarget = new PVector(0, 35);
    }
    // Otherwise, the target is pac-man's tile.
    else {
      chaseTarget = new PVector(floor(pacpos.x/tileL), floor(pacpos.y/tileL));
    }
  }


  public float speedPercentage () {
    if (floor(pos.y/tileL) == 17 && (floor(pos.x/tileL) < 6 || floor(pos.x/tileL) > 21) ) {
      return levelSpecs[level-1][4];
    }
    return levelSpecs[level-1][3];
  }


  public int currentDotLimit () {
    if (level == 1) return 60;
    if (level == 2) return 50;
    return 0;
  }
  
}
