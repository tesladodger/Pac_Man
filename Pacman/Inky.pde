class Inky extends Ghost {
  
  
  Inky (PVector pos, Dir dir, PVector scatterTarget, int oy) {
    super(pos, dir, scatterTarget, oy);
  }
  
  
  public void updateTarget (PVector pacpos, Dir pacdir) {
    
    // Position of blinky.
    PVector blinkypos = ghosts[0].pos;
    
    // Two tiles in front of pac-man.
    PVector pacp2 = new PVector(pacpos.x+pacdir.x*32, pacpos.y+pacdir.y*36);
    // Overflow bug.
    if (pacdir == Dir.U) pacp2.x -= 32;
    
    // Vector from blinky to pacpp2.
    PVector bl2pac2 = PVector.sub(pacp2, blinkypos);
    
    // The target is the point two tiles in front of pacman plus the vector from blinky to that point.
    chaseTarget = PVector.add(pacp2, bl2pac2);
    
    chaseTarget.x /= 16;
    chaseTarget.y /= 16;
  }
  
  
  public float speedPercentage () {
    if (floor(pos.y/tileL) == 17 && (floor(pos.x/tileL) < 6 || floor(pos.x/tileL) > 21) ) {
      return levelSpecs[level-1][4];
    }
    return levelSpecs[level-1][3];
  }
  
  
  public int currentDotLimit () {
    if (level == 1) return 30;
    return 0;
  }
  
}
