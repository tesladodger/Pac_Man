class Inky extends Ghost {
  
  
  Inky (PVector pos, Dir dir, PVector scatterTarget, int oy) {
    super(pos, dir, scatterTarget, oy);
  }
  
  
  public void updateTarget () {
    
    // Position of blinky.
    PVector blinkypos = ghosts[0].pos;
    
    // Two tiles in front of pac-man.
    PVector pacp2 = new PVector(pac.pos.x+pac.dir.x*32, pac.pos.y+pac.dir.y*36);
    // Overflow bug.
    if (pac.dir == Dir.U) pacp2.x -= 32;
    
    // Vector from blinky to pacpp2.
    PVector bl2pac2 = PVector.sub(pacp2, blinkypos);
    
    // The target is the point two tiles in front of pacman plus the vector from blinky to that point.
    chaseTarget = PVector.add(pacp2, bl2pac2);
    
    chaseTarget.x /= 16;
    chaseTarget.y /= 16;
    
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
    if (level == 1) return 30;
    return 0;
  }
  
}
