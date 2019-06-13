class Pinky extends Ghost {
  
  
  Pinky (PVector pos, Dir dir, PVector scatterTarget, int oy) {
    super(pos, dir, scatterTarget, oy);
  }
  
  
  public void updateTarget () {
    chaseTarget = new PVector(floor(pac.pos.x/tileL)+pac.dir.x*4, floor(pac.pos.y/tileL)+pac.dir.y*4);
    // Recreate the overflow bug.
    if (pac.dir == Dir.U) {
      chaseTarget.x -= 4;
    }
  }
  
  
  public float speedPercentage () {
    // Scared speed.
    if (mode.equals("scared")) {
      return levelSpecs[level][10];
    }
    // Tunnel speed.
    if (floor(pos.y/tileL) == 17 && (floor(pos.x/tileL) < 6 || floor(pos.x/tileL) > 21) ) {
      return levelSpecs[level][4];
    }
    // Normal speed.
    return levelSpecs[level][3];
  }
  
  
  public int currentDotLimit () {
    return 0;
  }
  
}
