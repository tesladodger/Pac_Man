class Pinky extends Ghost {
  
  
  Pinky (PVector pos, Dir dir, PVector scatterTarget, int oy) {
    super(pos, dir, scatterTarget, oy);
  }
  
  
  public void updateTarget (PVector pacpos, Dir pacdir) {
    chaseTarget = new PVector(floor(pacpos.x/tileL)+pacdir.x*4, floor(pacpos.y/tileL)+pacdir.y*4);
    // Recreate the overflow bug.
    if (pacdir == Dir.U) {
      chaseTarget.x -= 4;
    }
  }
  
  
  public float speedPercentage () {
    if (floor(pos.y/tileL) == 17 && (floor(pos.x/tileL) < 6 || floor(pos.x/tileL) > 21) ) {
      return levelSpecs[level-1][4];
    }
    return levelSpecs[level-1][3];
  }
  
  
  public int currentDotLimit () {
    return 0;
  }
  
}
