class Blinky extends Ghost {
  
  Blinky (PVector pos, Dir dir, PVector scatterTarget, int oy) {
    super(pos, dir, scatterTarget, oy);
  }
  
  
  public void updateTarget (PVector pacpos, Dir pacdir) {
    chaseTarget = new PVector(floor(pacpos.x/tileL), floor(pacpos.y/tileL));
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
