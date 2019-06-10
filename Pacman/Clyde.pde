class Clyde extends Ghost {
  
  
  
  Clyde (PVector pos, Dir dir, PVector scatterTarget, int oy) {
    super(pos, dir, scatterTarget, oy);
  }
  
  
  public void updateTarget (PVector pacpos, Dir pacdir) {
    
  }
  
  public float speedPercentage () {
    return 1;
  }
  
  public int currentDotLimit () {
    return 1;
  }
  
}
