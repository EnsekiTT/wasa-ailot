import procontroll.*;
import processing.serial.*;
import java.io.*;

int WINDOW_X=640;
int WINDOW_Y=480;
int BAUDRATE=19200;
//Serial Port
Serial ailotPort;

/*
serial_out
Warning Stop (1 stop, 0 normal)
Keep (1 active, 0 nonactive)
Release (0 close, 1 1_open, 2 2_open, 3 3_open)
Program Number (0 keep, 1 hover, 2 loop, 3 eight_loop)
Auto Pilot Activate (1 active, 0 nonactive)
Throttle (0~120%)
rudder (0~120%)
Aileron (0~120%)
Elevator (0~120%)
*/
class serial_out{
  int warning_stop;
  int keep;
  int release;
  int program;
  int autopilot;
  int throttle;
  int temp_throttle;
  int rudder;
  int aileron;
  int elevator;
}
serial_out ailot_out = new serial_out();

//Every numbers neutral

int rudder_min = 0;
int rudder_max = 180;
int rudder_def = (rudder_max - rudder_min)/2;

int aileron_min = 0;
int aileron_max = 180;
int aileron_def = (aileron_max - aileron_min)/2;

int elevator_min = 0;
int elevator_max = 180;
int elevator_def = (elevator_max - elevator_min)/2;

int throttle_min = 0;
int throttle_max = 180;
int throttle_def = 0;

/*
serial_in
Acceleration X (0x0000~0xFFFF)
Acceleration Y (0x0000~0xFFFF)
Acceleration Z (0x0000~0xFFFF)
Angular Velocity X (0x0000~0xFFFF)
Angular Velocity Y (0x0000~0xFFFF)
Angular Velocity Z (0x0000~0xFFFF)
Altitude (0x0000~0xFFFF)
*/
class serial_in{
  int accel_X;
  int accel_Y;
  int accel_Z;
  int angVel_X;
  int angVel_Y;
  int angVel_Z;
  int altitude;
  int battery;
  int interval;
}
serial_in ailot_in = new serial_in();
serial_in ailot_in_old = new serial_in();

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

//Stick
float LX;
float LY;
float RX;
float RY;

boolean start = true;

void ServoNeutral(){
  ailot_out.rudder = rudder_def;
  ailot_out.aileron = aileron_def;
  ailot_out.elevator = elevator_def;
}
void AutoPilotIO(){
  if(ailot_out.autopilot == 0){
    ailot_out.autopilot = 1; 
  }else{
    ailot_out.autopilot = 0;
  }
}
void KeepPoseIO(){
  if(ailot_out.keep == 0){
    ailot_out.keep = 1; 
  }else{
    ailot_out.keep = 0; 
  }
}

void DropGoods(){
  ailot_out.release++;
  if(ailot_out.release > 3){
     ailot_out.release = 0; 
  }
}
void EmergencyCode(){
  if(ailot_out.warning_stop == 1){
     ailot_out.warning_stop = 0; 
  }else{
    ailot_out.warning_stop = 1;
  }
  ailot_out.keep = 0;
  ailot_out.release = 0;
  ailot_out.program = 0;
  ailot_out.autopilot = 0;
  ailot_out.throttle = throttle_def;
  ailot_out.rudder = rudder_def;
  ailot_out.aileron = aileron_def;
  ailot_out.elevator = elevator_def;
}
void ResetDrop(){
  ailot_out.release = 0;
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
  ailot_out.program++;
  if(ailot_out.program > 3){
    ailot_out.program = 0; 
  }
}

void BackCode(){
  ailot_out.program--;
  if(ailot_out.program < 0){
    ailot_out.program = 0; 
  }
}

void UpThrottle(){
  ailot_out.temp_throttle += 10;
  if(ailot_out.temp_throttle > 160){
    ailot_out.temp_throttle += 5; 
  }
  if(ailot_out.temp_throttle > 180){
    ailot_out.temp_throttle = 180; 
  }
}
void SeventyFiveThrottle(){
  ailot_out.temp_throttle = 135;
}
void ThrottleCut(){
  ailot_out.temp_throttle = 0;
}
void DownThrottle(){
  ailot_out.temp_throttle -= 10;
  if(ailot_out.temp_throttle < 10){
    ailot_out.temp_throttle = 0;
  }
}

void StartMission(){
  start = false;
}

void setup(){
  //Serial Port Setup
  println(Serial.list());
  ailotPort = new Serial(this, Serial.list()[0], BAUDRATE);
  ailotPort.clear();
  //ailotPort = new Serial(this,"/dev/tty.usbmodemfd121", 57600);
  //ailotPort = new Serial(this,"/dev/tty.usbmodemfa131", 19200);
  //ailotPort = new Serial(this,"/dev/tty.usbserial-A501DG6P", 9600);
  //Controler Setup
  ControllIO   controll = ControllIO.getInstance(this);                         // 入力へのポインタ
  ControllDevice device = controll.getDevice("PLAYSTATION(R)3 Controller");  // 個々の入力装置を指定
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
  L2.plug("EmergencyCode",ControllIO.ON_RELEASE);
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
  
  PS.plug("StartMission",ControllIO.ON_RELEASE);
  
  size(WINDOW_X, WINDOW_Y);
  while(start){}
}

/*
serial_out
Warning Stop (1 stop, 0 normal)
Keep (1 active, 0 nonactive)
Release (0 close, 1 1_open, 2 2_open, 3 3_open)
Program Number (0 keep, 1 hover, 2 loop, 3 eight_loop, 4 through)
Auto Pilot Activate (1 active, 0 nonactive)
Throttle (0~120%)
rudder (0~120%)
Aileron (0~120%)
Elevator (0~120%)
check sum (sum(0~9))

class serial_out{
  int warning_stop;
  int keep;
  int release;
  int program;
  int autopilot;
  int throttle;
  int rudder;
  int aileron;
  int elevator;
  int checksum;
}
  ailot_out.rudder = rudder_def;
  ailot_out.aileron = aileron_def;
  ailot_out.elevator = elevator_def;
*/
int counter = 0;
void draw(){
  LX = LSTICK.getX();
  LY = LSTICK.getY();
  RX = RSTICK.getX();
  RY = RSTICK.getY();
  ailot_out.rudder = (int)(-RX*rudder_def)+rudder_def;
  ailot_out.elevator = (int)(LY*elevator_def)+elevator_def;
  ailot_out.aileron = (int)(LX*aileron_def)+aileron_def;
  ailot_out.throttle = (int)(-RY*30)+ailot_out.temp_throttle+throttle_def;
  if(ailot_out.throttle < 0){
    ailot_out.throttle = 0; 
  }else if(ailot_out.throttle >= 180){
    ailot_out.throttle = 180; 
  }
  serialOutput();
  delay(20);
}

void serialEvent(Serial p){
  if(ailotPort.available()>14){
    ailot_in.interval = ailotPort.read() << 8;
    ailot_in.interval &= ailotPort.read();
    ailot_in.accel_X = ailotPort.read() << 8;
    ailot_in.accel_X &= ailotPort.read();
    ailot_in.accel_Y = ailotPort.read() << 8;
    ailot_in.accel_Y &= ailotPort.read();
    ailot_in.accel_Z = ailotPort.read() << 8;
    ailot_in.accel_Z &= ailotPort.read();
  
    ailot_in.angVel_X = ailotPort.read() << 8;
    ailot_in.angVel_X &= ailotPort.read();
    ailot_in.angVel_Y = ailotPort.read() << 8;
    ailot_in.angVel_Y &= ailotPort.read();
    ailot_in.angVel_Z = ailotPort.read() << 8;
    ailot_in.angVel_Z &= ailotPort.read();
  
    ailot_in.altitude = ailotPort.read() << 8;
    ailot_in.altitude &= ailotPort.read();
  }
  /*
  if(ailotPort.available()>9 && output == false){
    print((int)ailotPort.read());
    print(",");
    print((int)ailotPort.read());
    print(",");
    print((int)ailotPort.read());
    print(",");
    print((int)ailotPort.read());
    print(",");
    print((int)ailotPort.read());
    print(",");
    println();
    print((int)ailotPort.read());
    print(",");
    print((int)ailotPort.read());
    print(",");
    print((int)ailotPort.read());
    print(",");
    print((int)ailotPort.read());
    print(",");
    print((int)ailotPort.read());
    print(",");
    println();
  }*/
}


boolean output = false;
void serialOutput(){
  output = true;
  ailotPort.write('a');
  ailotPort.write(ailot_out.warning_stop);
  ailotPort.write(ailot_out.keep);
  ailotPort.write(ailot_out.release);
  ailotPort.write(ailot_out.program);
  ailotPort.write(ailot_out.autopilot);
  ailotPort.write(ailot_out.throttle);
  ailotPort.write(ailot_out.rudder);
  ailotPort.write(ailot_out.aileron);
  ailotPort.write(ailot_out.elevator);
  output = false;
}
