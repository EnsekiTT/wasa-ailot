import procontroll.*;
import processing.serial.*;
import java.io.*;

int WINDOW_X=640;
int WINDOW_Y=480;
int BAUDRATE=19200;
long INT_MAX=32767;
long ONES_MICRO=1000000;
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
  long interval;
}
serial_in ailot_in = new serial_in();
serial_in ailot_in_old = new serial_in();
int[] inbuf = new int[18];
int gyro_x_past = 0;
int gyro_y_past = 0;
int gyro_z_past = 0;
int gyro_x_bias = 5;
int gyro_y_bias = 32;
int gyro_z_bias = 1;

//pid values;
double En_a=0;
double En_1_a=0;
double En_2_a=0;
double MVn_1_a=0;
double MVn_a=0;

double En_e=0;
double En_1_e=0;
double En_2_e=0;
double MVn_1_e=0;
double MVn_e=0;

double En_r=0;
double En_1_r=0;
double En_2_r=0;
double MVn_1_r=0;
double MVn_r=0;

double angle_x = 0.0;
double angle_y = 0.0;
double angle_z = 0.0;

boolean eightloop = true;

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
    resetAngle();
    ailot_out.autopilot = 1;
    eightloop = true;
  }else{
    ailot_out.autopilot = 0;
    eightloop = true;
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
  println(ailot_out.program);
}

void BackCode(){
  ailot_out.program--;
  if(ailot_out.program < 0){
    ailot_out.program = 0; 
  }
  println(ailot_out.program);
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
  ailotPort.buffer(20);
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
  while(start){
    ailotPort.read();
  }
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
  if(ailot_out.autopilot == 1){
    autopilot(); 
  }else{
    humanpilot(); 
  }
  serialOutput();
}

void showdata(){
  //print((int)angle_x);
  //println(); 
}

void setControl(){
  ailot_in.interval = (byte)(inbuf[0]&0x00FF) << 8 | (byte)(inbuf[1]&0x00FF);
  
  ailot_in.angVel_X = (byte)inbuf[2] << 8 | inbuf[3];
  ailot_in.angVel_Y = (byte)inbuf[4] << 8 | inbuf[5];
  ailot_in.angVel_Z = (byte)inbuf[6] << 8 | inbuf[7];

  ailot_in.accel_X = (byte)inbuf[9] << 8 | inbuf[8];
  ailot_in.accel_Y = (byte)inbuf[11] << 8 | inbuf[10];
  ailot_in.accel_Z = (byte)inbuf[13] << 8 | inbuf[12];  
  
  ailot_in.altitude = inbuf[14] << 8 | inbuf[15];
  //ailot_in.battery = (byte)inbuf[16];
}

void resetAngle(){
   angle_x = 0;
   angle_y = 0;
   angle_z = 0; 
}

void getAngle(){
  angle_x += (double)((long)500*(long)ailot_in.interval)*((double)gyro_x_past + (double)ailot_in.angVel_X - gyro_x_bias*2) / (double)INT_MAX / (double)ONES_MICRO / 2.0;
  angle_y += (double)((long)500*(long)ailot_in.interval)*((double)gyro_y_past + (double)ailot_in.angVel_Y - gyro_y_bias*2) / (double)INT_MAX / (double)ONES_MICRO / 2.0;
  angle_z += (double)((long)500*(long)ailot_in.interval)*((double)gyro_z_past + (double)ailot_in.angVel_Z - gyro_z_bias*2) / (double)INT_MAX / (double)ONES_MICRO / 2.0;
  gyro_x_past = ailot_in.angVel_X;
  gyro_y_past = ailot_in.angVel_Y;
  gyro_z_past = ailot_in.angVel_Z;
}

/*
ailot_out.rudder
ailot_out.elevator
ailot_out.aileron
*/
int past_control_aileron;
int past_control_elevator;
int past_control_rudder;
void autopilot(){
   switch(ailot_out.program){
      //keep
      case 0:
        past_control_aileron = ailot_out.aileron;
        past_control_elevator = ailot_out.elevator;
        past_control_rudder = ailot_out.rudder;
        ailot_out.aileron = past_control_aileron;
        ailot_out.elevator = past_control_elevator;
        ailot_out.rudder = past_control_rudder;
      break;
      //hover
      case 1:
        ailot_out.aileron = (int)pid_aileron(0, 1.0, 0.01, 0.01)/10+aileron_def;
        ailot_out.rudder = (int)pid_rudder(0, 0.7, 0.01, 0.01)/3+rudder_def;
        ailot_out.elevator = (int)pid_elevator(0, 0.7, 0.01, 0.01)/10+elevator_def;
      break;
      //loop
      case 2: 
        ailot_out.aileron = (int)pid_aileron(0, 1.0, 0.01, 0.01)/10+aileron_def;
        ailot_out.rudder = (int)pid_rudder(370, 0.5, 0.01, 0.01)/3+rudder_def;
        ailot_out.elevator = (int)pid_elevator(0, 0.5, 0.01, 0.01)/10+elevator_def;
      break;
      //eight_loop
      case 3:
        if(eightloop){
          ailot_out.aileron = (int)pid_aileron(0, 0.1, 0.01, 0.01)/10+aileron_def;
          ailot_out.rudder = (int)pid_rudder(360, 0.5, 0.01, 0.01)/3+rudder_def;
          ailot_out.elevator = (int)pid_elevator(0, 0.5, 0.01, 0.01)/10+elevator_def;
          if((int)angle_z > 360){
            eightloop = false;
          }
        }else{
          ailot_out.aileron = (int)pid_aileron(0, 5, 1, 2);
          ailot_out.rudder = (int)pid_rudder(0, 5, 1, 2);
          ailot_out.elevator = (int)pid_elevator(0, 5, 1, 2);
          if((int)angle_z < 0){
            eightloop = true; 
          }
        }      
      break;
      default:
        ailot_out.program = 0;
      break;
   }
}

void humanpilot(){
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
}

double pid_aileron(double setangle, double Kp, double Ki, double Kd){
  MVn_1_a = MVn_a;
  En_2_a = En_1_a;
  En_1_a = En_a;
  En_a = setangle - angle_x;
  double dMVn = (Kp*(En_a-En_1_a) + Ki*En_a + Kd*((En_a-En_1_a)-(En_1_a-En_2_a)));
  MVn_a = MVn_1_a+dMVn;
  return MVn_a;
}

double pid_elevator(double setangle, double Kp, double Ki, double Kd){
  MVn_1_e = MVn_e;
  En_2_e = En_1_e;
  En_1_e = En_e;
  En_e = setangle - angle_y;
  double dMVn = (Kp*(En_e-En_1_e) + Ki*En_e + Kd*((En_e-En_1_e)-(En_1_e-En_2_e)));
  MVn_e = MVn_1_e+dMVn;
  return MVn_e;
}
double pid_rudder(double setangle, double Kp, double Ki, double Kd){
  MVn_1_r = MVn_r;
  En_2_r = En_1_r;
  En_1_r = En_r;
  En_r = setangle - angle_z;
  double dMVn = (Kp*(En_r-En_1_r) + Ki*En_r + Kd*((En_r-En_1_r)-(En_1_r-En_2_r)));
  MVn_r = MVn_1_r+dMVn;
  return MVn_r;
}

void serialEvent(Serial p){
  int safety = 0;
  char check;
  int temp = 0;
  int backup = 0;
  if(ailotPort.available()>17 && output == false){
    while(true){
       check = (char)ailotPort.read();
       if(check == 'b'){
         break;
       }
       safety++;
       if(safety > 20){
         break; 
       }
    }
    if(safety <= 20){
      for(int i = 0; i < 16; i++){
        temp = ailotPort.read();
        backup = inbuf[i];
        if(temp == -1){
          temp = ailotPort.read();
          if(temp == -1){
            inbuf[i] = backup;
          }else{
            inbuf[i] = temp; 
          }
        }else{
          inbuf[i] = temp; 
        }
      }
      getAngle();
    }
  }
  setControl();
  showdata();
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
