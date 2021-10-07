//creates an array that keeps track of which keys are pressed
var keys = [];

//updates the keys array
keyPressed = function(){
  keys[keyCode] = true;
};
keyReleased = function(){
  keys[keyCode] = false;
};


// x, y, size, speed variables for the player
var playerX = 200;
var playerY = 200;
var playerClr = 0;
var speed = 2;

draw = function() {
  //draw the background
  background(50, 255, 255);
  
  //draw the player
  fill(playerClr);
  ellipse(playerX, playerY, 50, 50);
  
  //moves the player with arrow keys or WASD
  if(keys[UP] || keys[87]){
    playerY -= speed;
  }
  if(keys[DOWN] || keys[83]){
    playerY += speed;
  }
  if(keys[RIGHT] || keys[68]){
    playerX += speed;
  }
  if(keys[LEFT] || keys[65]){
    playerX -= speed;
  }
};

mouseClicked = function () {
  playerClr = color(random(0, 255), random(0, 255), random(0, 255));
};
