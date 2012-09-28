import procontroll.*;
import java.io.*;

int WINDOW_X=640;
int WINDOW_Y=480;

int length = 25;
float[] lx = new float[length];
float[] ly = new float[length];
float[] rx = new float[length];
float[] ry = new float[length];
float segLength = 18;

ControllButton SELECT;
ControllButton START;
ControllButton LEFTA;
ControllButton RIGHTA;
ControllButton TOPA;
ControllButton BOTTOMA;
ControllButton L1;
ControllButton R1;
ControllButton L2;
ControllButton R2;
ControllButton L3;
ControllButton R3;
ControllButton SquareB;
ControllButton TriangleB;
ControllButton CircleB;
ControllButton CrossB;
ControllButton PS;
ControllSlider LsliderX;
ControllSlider LsliderY;
ControllSlider RsliderX;
ControllSlider RsliderY;

ControllStick LSTICK;
ControllStick RSTICK;

/*
WASA_ailot
0:Aileron
1:Elevator
2:Rudder
3:Throttle
4:DropGoods
*/
char[] Control_Default_Set = new char[20];
char[] Control_Set = new char[20];


void ServoNeutral(){
  
}
void AutoPilotIO(){
}
void KeepPoseIO(){
}
void DropGoods(){ 
}
void EmergencyCode(){
}
void ResetDrop(){
}
void BackMenu(){
  
}
void NextMenu(){
}
void INCParameter(){
}
void DECParameter(){
}
void NextCode(){
}
void BackCode(){
}
void UpThrottle(){
}
void SeventyFiveThrottle(){
}
void ThrottleCut(){
}
void DownThrottle(){
}

void setup(){
  ControllIO   controll = ControllIO.getInstance(this);                         // 入力へのポインタ
  ControllDevice device = controll.getDevice("PLAYSTATION(R)3 Controller");     // 個々の入力装置を指定
  SELECT = device.getButton("0");
  L3 = device.getButton("1");
  R3 = device.getButton("2");
  START = device.getButton("3");
  TOPA = device.getButton("4");
  RIGHTA = device.getButton("5");
  BOTTOMA = device.getButton("6");
  LEFTA = device.getButton("7");
  L2 = device.getButton("8");
  R2 = device.getButton("9");
  L1 = device.getButton("10");
  R1 = device.getButton("11");
  TriangleB = device.getButton("12");
  CircleB = device.getButton("13");
  CrossB = device.getButton("14");
  SquareB = device.getButton("15");
  PS = device.getButton("16");
  
  LsliderX = device.getSlider("x");
  LsliderY = device.getSlider("y");
  RsliderX = device.getSlider("z");
  RsliderY = device.getSlider("rz");
  
  LSTICK = new ControllStick(LsliderX,LsliderY);
  RSTICK = new ControllStick(RsliderX,RsliderY);
  
  SELECT.plug("ServoNeutral",ControllIO.ON_PRESS);
  START.plug("AutoPilotIO",ControllIO.ON_PRESS);
  L1.plug("KeepPoseIO",ControllIO.ON_RELEASE);
  R1.plug("DropGoods",ControllIO.ON_RELEASE);
  L2.plug("EmergencyCode",ControllIO.ON_PRESS);
  R2.plug("ResetDrop",ControllIO.ON_PRESS);
  L3.plug("BackMenu",ControllIO.ON_RELEASE);
  R3.plug("NextMenu",ControllIO.ON_RELEASE);
  
  TOPA.plug("INCParameter",ControllIO.ON_RELEASE);
  BOTTOMA.plug("DECParameter",ControllIO.ON_RELEASE);
  RIGHTA.plug("NextCode",ControllIO.ON_RELEASE);
  LEFTA.plug("BackCode",ControllIO.ON_RELEASE);
  
  TriangleB.plug("UpThrottle",ControllIO.ON_RELEASE);
  CircleB.plug("SeventyFiveThrottle",ControllIO.ON_PRESS);
  CrossB.plug("ThrottleCut",ControllIO.ON_PRESS);
  SquareB.plug("DownThrottle",ControllIO.ON_RELEASE);
  
  size(WINDOW_X, WINDOW_Y);
  strokeWeight(9);
  stroke(255, 100);
}

void draw(){
  background(0);
  float LX = LSTICK.getX();
  float LY = LSTICK.getY();
  float RX = RSTICK.getX();
  float RY = RSTICK.getY();
  rdragSegment(0, (RX+1)*WINDOW_X/2, (RY+1)*WINDOW_Y/2);
  ldragSegment(0, (LX+1)*WINDOW_X/2, (LY+1)*WINDOW_Y/2);
  for(int i = 0; i < lx.length-1; i++){
     ldragSegment(i+1, lx[i], ly[i]);
     rdragSegment(i+1, rx[i], ry[i]);
  }
}

void ldragSegment(int i, float xin, float yin) {
  float dx = xin - lx[i];
  float dy = yin - ly[i];
  float angle = atan2(dy, dx);  
  lx[i] = xin - cos(angle) * segLength;
  ly[i] = yin - sin(angle) * segLength;
  segment(lx[i], ly[i], angle);
}
void rdragSegment(int i, float xin, float yin) {
  float dx = xin - rx[i];
  float dy = yin - ry[i];
  float angle = atan2(dy, dx);  
  rx[i] = xin - cos(angle) * segLength;
  ry[i] = yin - sin(angle) * segLength;
  segment(rx[i], ry[i], angle);
}

void segment(float x, float y, float a) {
  pushMatrix();
  translate(x, y);
  rotate(a);
  
  /*print(x/640);
  print(",");
  print(y/480);
  print(",");
  print(a*255);
  println();
  */
  stroke(x,y,a);
  line(0, 0, segLength, 0);
  popMatrix();
}
