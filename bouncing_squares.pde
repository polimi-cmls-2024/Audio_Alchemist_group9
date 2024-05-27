import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;

int numSquares = 4; // Number of squares
int squareSize = 50; // Size of the squares 
float[] x = new float[numSquares]; // position x
float[] y = new float[numSquares]; // position y
float[] xSpeed = new float[numSquares]; // speed in the x direction
float[] ySpeed = new float[numSquares]; // speed in the y direction
int[] hitSquare = new int[numSquares]; 
int[] R = new int[numSquares]; 
int[] G = new int[numSquares];
int[] B = new int[numSquares];

void setup() {
  size(1000, 600);
  oscP5 = new OscP5(this, 12000);
  myRemoteLocation = new NetAddress("127.0.0.1", 57120);
  
  // Colors for the squares since we know the number in advance we can choose the colors and match with the GUI
  R[0] = 204; G[0] = 255; B[0] = 0; // Electric Lime
  R[1] = 172; G[1] = 229; B[1] = 238; // Blizzard Blue
  R[2] = 255; G[2] = 153; B[2] = 102; // Atomic Tangerine
  R[3] = 204; G[3] = 102; B[3] = 102; // Fuzzy Wuzzy
  
  // Initialization of the positions and the speeds 
  for (int i = 0; i < numSquares; i++) {
    x[i] = random(squareSize, width - squareSize);
    y[i] = random(squareSize, height - squareSize);
    xSpeed[i] = random(1, 3);
    ySpeed[i] = random(1, 3);
  }
}

void draw() {
  background(0);
  
  
  for (int i = 0; i < numSquares; i++) {
   
    // Check if the square collides the wall
    if (x[i] > width - squareSize || x[i] < 0) {
      xSpeed[i] *= -1;
      hitSquare[i] = 1;
    }
    if (y[i] > height - squareSize || y[i] < 0) {
      ySpeed[i] *= -1;
      hitSquare[i] = 1;
    }
    
    // Adjust position
    x[i] += xSpeed[i];
    y[i] += ySpeed[i];
    
    // Draw the squares
    fill(R[i], G[i], B[i]);
    rect(x[i], y[i], squareSize, squareSize);
  
    // If the square had hit a wall send the information and the parameters for the effect
    if (hitSquare[i] == 1) {
      String param = randomParam(i);
      float value = randomValue(param);
      sendOscMessage("/effectChange", i, param, value);
      println("Sending OSC message: /effectChange " + i + " " + param + " " + value);
      hitSquare[i] = 0;
    }
  }
}

// function that sends a message to SuperCollider
void sendOscMessage(String address, int effectIndex, String param, float value) {
  OscMessage myMessage = new OscMessage(address);
  myMessage.add(effectIndex);
  myMessage.add(param);
  myMessage.add(value);
  oscP5.send(myMessage, myRemoteLocation);
}

// Parameters for the effect in coherence whith what they produce
String randomParam(int effectIndex) {
  if (effectIndex == 0) { // Reverb
    String[] params = { "decay", "damp", "amp" };
    return params[int(random(params.length))];
  } else if (effectIndex == 1) { // Chorus
    String[] params = { "depth", "blend", "rate", "amp" };
    return params[int(random(params.length))];
  } else if (effectIndex == 2) { // SpaceEcho
    String[] params = { "echo", "repeatRate", "amp" };
    return params[int(random(params.length))];
  } else if (effectIndex == 3) { // Distortion
    String[] params = { "drive", "tone", "amp" };
    return params[int(random(params.length))];
  }
  return "amp"; // Default fallback
}

float randomValue(String param) {
  if (param.equals("decay")) {
    return random(0.2, 10);
  } else if (param.equals("damp")) {
    return random(0, 1);
  } else if (param.equals("amp")) {
    return random(0.75, 1);
  } else if (param.equals("depth")) {
    return random(0, 0.02);
  } else if (param.equals("blend")) {
    return random(0, 1);
  } else if (param.equals("rate")) {
    return random(0.05, 10);
  } else if (param.equals("echo")) {
    return random(0.1, 2);
  } else if (param.equals("repeatRate")) {
    return random(0.1, 5);
  } else if (param.equals("drive")) {
    return random(0, 1);
  } else if (param.equals("tone")) {
    return random(0, 15);
  }
  return random(0.0, 1.0); // Default fallback
}
