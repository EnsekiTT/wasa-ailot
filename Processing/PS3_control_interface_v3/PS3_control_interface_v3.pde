import java.io.*;
import procontroll.*;
import processing.serial.*;

int WINDOW_X=800;
int WINDOW_Y=600;
int BAUDRATE=115200;
long INT_MAX=32767;
long ONES_MICRO=1000000;
//Serial Port
Serial ailotPort;

/*** Meter define by ITO ***/
color background=color(80,80,80);
int frameRate=60;
int meterTextSize=14;
int meterNameTextSize=18;
int metersmallTextSize=10;
int meterTextColour=240;
//メータの背景の地の部分の色
int meterBackgroundColour=25;
//目盛りの色，フレームの色
int meterGraduationColour=230;
//円形メータの目盛り間隔
int roundMeterGraduationAngle=5;
color[] colourStock={color(255,0,0),color(0,255,0),color(0,0,255),color(255,255,255),color(0,0,0)};
/*** meterBar number:
0:red
1:green
2:blue
3:white
4:black ***/
/*** Meter define end ***/

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
int rudder_offset = 0;

int aileron_min = 0;
int aileron_max = 180;
int aileron_def = (aileron_max - aileron_min)/2;
int aileron_offset = 15;

int elevator_min = 0;
int elevator_max = 180;
int elevator_def = (elevator_max - elevator_min)/2;
int elevator_offset = 15;

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
int menu = 0;
void BackMenu(){
  menu--;
  if(menu < 0) menu = 0;
}
void NextMenu(){
  menu++;
  if(menu > 3) menu = 3;
}
void INCParameter(){
  switch(menu){
    case 0:
      aileron_offset++;
    break;
    case 1:
      elevator_offset++;
    break;
    case 2:
      rudder_offset++;
    break; 
  }
}
void DECParameter(){
  switch(menu){
    case 0:
      aileron_offset--;
    break;
    case 1:
      elevator_offset--;
    break;
    case 2:
      rudder_offset--;
    break; 
  }  
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
  if(start == true){
    start = false;
  }else{
    while(ailotPort.available()>0){
      ailotPort.read(); 
    }
  }
  ailotPort.clear();
  resetAngle();
}


void setup(){
  //Serial Port Setup
  println(Serial.list());
  ailotPort = new Serial(this, Serial.list()[0], BAUDRATE, 'E', 8, 1.0);
  ailotPort.buffer(10);
  ailotPort.clear();
  delay(20);  //ailotPort = new Serial(this,"/dev/tty.usbmodemfd121", 57600);
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
  
  
  frameRate(frameRate);
  size(WINDOW_X, WINDOW_Y);
  noStroke();
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
  delay(10);
  serialOutput();
  background(background);
  showdata();
}

void showdata(){
  //background(background);
  drawVerticalBarMeter("Throttle",ailot_out.throttle,180,0,570,420,20,350,3,"%");
  drawVerticalBarMeter("Altitude",ailot_in.altitude,360,0,650,420,20,350,3,"cm");
  
    //"YOU/I have controll"の部分の背景長方形
  fill(meterBackgroundColour);
  rect(650-120,570-30,240,40);
  textSwitch(ailot_out.autopilot,"YOU have control.",3,"I have control.",0,650,570,24);
  fill(meterBackgroundColour);
  rect(650-120,500-30,240,40);
  selectSwitch(ailot_out.program, 650, 500, 24);
  fill(meterBackgroundColour);
  rect(650-120,500-60,240,40);
  selectMenu(menu, 650, 470, 24);

  drawStickPosition((int)(LX*100),(int)(-LY*100),100,-100,width/2-90,530,100);//right
  drawStickPosition((int)(RX*100),(int)(-RY*100),100,-100,width/2+55,530,100);//left
  drawCountRamp("Remaining",3-ailot_out.release,3,200,100,100,30,0);
  drawDirectionMeter("Angle of Attack",90,-(int)angle_y,125,460,200,3);
  drawDirectionMeter("Direction",180,(int)angle_z,125,230,200,3);
  drawRollMeter("Roll",90,(int)angle_x,400,345,200,3);
  /*
  print(angle_x);
  print(angle_y);
  print(angle_z);
  println();
  */
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
  angle_x += (double)((long)500*(long)ailot_in.interval)*((double)gyro_x_past + (double)ailot_in.angVel_X - gyro_x_bias*2) / (double)INT_MAX / (double)ONES_MICRO;
  angle_y += (double)((long)500*(long)ailot_in.interval)*((double)gyro_y_past + (double)ailot_in.angVel_Y - gyro_y_bias*2) / (double)INT_MAX / (double)ONES_MICRO;
  angle_z += (double)((long)500*(long)ailot_in.interval)*((double)gyro_z_past + (double)ailot_in.angVel_Z - gyro_z_bias*2) / (double)INT_MAX / (double)ONES_MICRO;
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
      //straght
      case 1:
        ailot_out.aileron = (int)pid_aileron(0, 0.1, 0.01, 0.01)/15+aileron_def+aileron_offset;
        ailot_out.rudder = (int)pid_rudder(0, 0.15, 0.0, 0.01)/9+rudder_def+rudder_offset;
        ailot_out.elevator = (int)pid_elevator(0, 0.05, 0.0, 0.01)/9+elevator_def+elevator_offset;
      break;
      //loop
      case 2: 
        ailot_out.aileron = (int)pid_aileron(0, 0.1, 0.01, 0.01)/15+aileron_def+aileron_offset;
        ailot_out.rudder = (int)pid_rudder(10, 0.15, 0.0, 0.01)/9+rudder_def+rudder_offset;
        ailot_out.elevator = (int)pid_elevator(0, 0.05, 0.0, 0.01)/9+elevator_def+elevator_offset;
      break;
      //eight_loop
      case 3:
        if(eightloop){
          ailot_out.aileron = (int)pid_aileron(0, 0.1, 0.01, 0.01)/10+aileron_def+aileron_offset;
          ailot_out.rudder = (int)pid_rudder(10, 0.15, 0.0, 0.01)/10+rudder_def+rudder_offset;
          ailot_out.elevator = (int)pid_elevator(0, 0.05, 0.0, 0.01)/10+elevator_def+elevator_offset;
          if((int)angle_z > 360){
            eightloop = false;
          }
        }else{
          ailot_out.aileron = (int)pid_aileron(0, 0.1, 0.01, 0.01)/10+aileron_def+aileron_offset;
          ailot_out.rudder = (int)pid_rudder(-10, 0.15, 0.0, 0.01)/10+rudder_def+rudder_offset;
          ailot_out.elevator = (int)pid_elevator(0, 0.01, 0.0, 0.01)/10+elevator_def+elevator_offset;
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
  ailot_out.rudder = (int)(-RX*rudder_def)+rudder_def+rudder_offset;
  ailot_out.elevator = (int)(LY*elevator_def/3)+elevator_def+elevator_offset;
  ailot_out.aileron = (int)(LX*aileron_def/3)+aileron_def+aileron_offset;
  ailot_out.throttle = (int)(-RY*30)+ailot_out.temp_throttle+throttle_def;
  if(ailot_out.throttle < 1){
    ailot_out.throttle = 1; 
  }else if(ailot_out.throttle >= 180){
    ailot_out.throttle = 180; 
  } 
}

double pid_aileron(double setangle, double Kp, double Ki, double Kd){
  MVn_1_a = MVn_a;
  En_2_a = En_1_a;
  En_1_a = En_a;
  En_a = setangle - ailot_in.angVel_X;
  double dMVn = (Kp*(En_a-En_1_a) + Ki*En_a + Kd*((En_a-En_1_a)-(En_1_a-En_2_a)));
  MVn_a = MVn_1_a+dMVn;
  return MVn_a;
}

double pid_elevator(double setangle, double Kp, double Ki, double Kd){
  MVn_1_e = MVn_e;
  En_2_e = En_1_e;
  En_1_e = En_e;
  En_e = ailot_in.angVel_Y - setangle;
  /*
  if(  250 - ailot_in.altitude < 0){
    En_e += 3; 
  }
  */
  double dMVn = (Kp*(En_e-En_1_e) + Ki*En_e + Kd*((En_e-En_1_e)-(En_1_e-En_2_e)));
  MVn_e = MVn_1_e+dMVn;
  return MVn_e;
}
double pid_rudder(double setangle, double Kp, double Ki, double Kd){
  MVn_1_r = MVn_r;
  En_2_r = En_1_r;
  En_1_r = En_r;
  En_r = setangle - ailot_in.angVel_Z;
  double dMVn = (Kp*(En_r-En_1_r) + Ki*En_r + Kd*((En_r-En_1_r)-(En_1_r-En_2_r)));
  MVn_r = MVn_1_r+dMVn;
  return MVn_r;
}

void serialEvent(Serial p){
  //print((char)ailotPort.read());
  
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
          inbuf[i] = backup;
        }else{
          inbuf[i] = temp; 
        }
      }
      getAngle();
    }
  }
  setControl();
  
}


boolean output = false;
void serialOutput(){
  output = true;
  ailotPort.write('a');
  ailotPort.write(ailot_out.warning_stop);
  ailotPort.write(ailot_out.release);
  ailotPort.write(ailot_out.throttle);
  ailotPort.write(ailot_out.rudder);
  ailotPort.write(ailot_out.aileron);
  ailotPort.write(ailot_out.elevator);
  output = false;
}

/*** Meter designed by ITO ***/
/***
drawVerticalBarMeter：垂直型バーメータ描画関数
(表示名，入力値，最大値，最小値，x位置，y位置(左下基準)，幅，高さ，バーの色決定用整数，表示単位)

動作：
・下端から上方へ棒グラフが描写される．
・範囲をオーバーした場合は"OVER"と表示され，バーは赤くなる．

注釈：
・表示名は""にすると表示されない．
・色決定用整数はcolourStock関数の項を参照すること．
・単位は""にすると，単位用の[]が表示されなくなる．

***/
void drawVerticalBarMeter(String name, int value, int max, int min, int x, int yLeftDown, int w, int h, int colour, String unit){
  int y= yLeftDown-h;
  fill(meterBackgroundColour);
  rect(x, y, w, h);
  stroke(meterGraduationColour,100);
  for (int i=1; i < 10 ; i++ ){
    if (i==5){
      line(x+w*0.15 ,y+0.1*i*h ,x+w*0.85,y+0.1*i*h);
    }else{
      line(x+w*0.23 ,y+0.1*i*h ,x+w*0.77,y+0.1*i*h);
    }
  }
  noStroke();
  textSize(meterTextSize);
  if (max<value) {
    fill(colourStock[0]);
    rect(x+w*0.2, y+h, w*0.6, -h);
    fill(meterTextColour);
    text("OVER", x+w+5, y+h/2+meterTextSize/2);
  }else if (min>value) {
    fill(meterTextColour);
    text("OVER", x+w+5, y+h/2+meterTextSize/2);
  }else{
    fill(colourStock[colour],240);
    rect(x+w*0.2, y+h, w*0.6, -h*(1-norm(value,max,min)));
    fill(meterTextColour);
    text(str(value), x+w+5, y+h/2+meterTextSize/2);
    if (unit==""){
    }else{
      text("["+unit+"]", x+w+meterTextSize*2.5, y+h/2+meterTextSize/2);
    }
  }
  text(str(min), x+w+5, y+h);
  text(str(max), x+w+5, y+meterTextSize);
  textAlign(CENTER);
  textSize(meterNameTextSize);
  text(name, x+w/2, y+h+meterNameTextSize+5);
  textAlign(LEFT);
  textSize(meterTextSize);
}

/***
drawHorizontalBarMeter：水平型バーメータ描画関数
(表示名，入力値，最大最小値の絶対値，x位置，y位置(左下基準)，幅，高さ，バーの色決定用整数，表示単位)

動作：
・垂直型と異なり，最大値と最小値の絶対値は同じ．
・中央がゼロとなり，左右にバーが伸びる形である．
・範囲を超えた場合は"OVER RANGE"と表示され，バーが赤くなる．

注釈：
・表示名は""にすると表示されない．
・色決定用整数はcolourStock関数の項を参照すること．
・単位は""にすると，単位用の[]が表示されなくなる．

***/
void drawHorizontalBarMeter(String name, int value, int max, int x, int yLeftDown, int w, int h, int colour, String unit){
  int y= yLeftDown-h;
  fill(meterBackgroundColour);
  rect(x, y, w, h);
  stroke(meterGraduationColour,100);
  for (int i=1; i < 10 ; i++ ){
    if (i==5){
      line(x+w*0.1*i ,y+0.15*h ,x+w*0.1*i,y+h*0.85);
    }else{
      line(x+w*0.1*i ,y+0.23*h ,x+w*0.1*i,y+h*0.77);
    }
  }
  noStroke();
  textSize(meterTextSize);
  textAlign(CENTER);
  if (max<value) {
    fill(colourStock[0]);
    rect(x+w/2, y+h*0.2, w/2, h*0.6);
    fill(meterTextColour);
    text("OVER RANGE", x+w/2, y-meterTextSize/2);
  }else if (-max>value) {
    fill(colourStock[0]);
    rect(x+w/2, y+h*0.2, -w/2, h*0.6);
    fill(meterTextColour);
    text("OVER RANGE", x+w/2, y-meterTextSize/2);
  }else{
    fill(colourStock[colour],240);
    rect(x+w/2, y+h*0.2, w/2*(map(value,max,-max,1,-1)), h*0.6);
    fill(meterTextColour);
    text(str(value), x+w/2, y-meterTextSize/2);
    if (unit==""){
    }else{
      text("["+unit+"]", x+w/2+meterTextSize*2, y-meterTextSize/2);
    }
  }
  text(str(-max), x, y-meterTextSize/2);
  text(str(max), x+w, y-meterTextSize/2);
  textSize(meterNameTextSize);
  text(name, x+w/2, y+h+meterNameTextSize);
  textAlign(LEFT);
  textSize(meterTextSize);
}

/***
drawCheckRamp：OnOffチェックボックス型ランプ描写関数
(表示名，入力値，x位置，y位置(左下基準)，幅，高さ)

動作：
・四角形のランプが表示される．
・入力値が0の場合"OFF"，0以外の場合"ON"と表示される．
・"OFF"の場合は赤黒く，"ON"の場合明るい水色に点灯する．

注釈：
・表示名は""にすると表示されない．
・文字サイズは固定のため，あまり大きくすると見づらい．

***/
void drawCheckRamp(String name,int io, int x, int yLeftDown, int w, int h){
  int y= yLeftDown-h;
  String sign="OFF";
  fill(meterBackgroundColour);
  rect(x, y, w, h);
  textAlign(CENTER);
  
  if (io==0) {
    sign="OFF";
    fill(50,0,0);
    rect(x+2, y+2, w-4, h-4);
    fill(255);
  }else{
    sign="ON";
    fill(0,255,200);
    rect(x+2, y+2, w-4, h-4);
    fill(0);
  }
  text(sign, x+w/2, y+h/2+meterTextSize/2);
  textAlign(LEFT);
  fill(meterTextColour);
  textSize(meterNameTextSize);
  text(name, x+w+5, y-2+h/2+meterNameTextSize/2);
  textSize(meterTextSize);
}
/***
drawSwitchRamp：OnOffスイッチ型ランプ描写関数
(表示名，入力値，x位置，y位置(左下基準)，幅，高さ)

動作：
・四角形のランプが表示される．
・チェックボックス型と異なり，初めからOnOff領域が表示される．
・入力値が0の場合"OFF"，0以外の場合"ON"と小さく表示される．
・"OFF"の場合は赤黒く，"ON"の場合明るい水色に点灯する．

注釈：
・表示名は""にすると表示されない．
・文字サイズは固定のため，あまり大きくすると見づらい．

***/
void drawSwitchRamp(String name,int io, int x, int yLeftDown, int w, int h){
  int y= yLeftDown-h;
  fill(meterBackgroundColour);
  rect(x, y, w, h);
  textAlign(CENTER);
  textSize(metersmallTextSize);
  if (io==0) {
    fill(50,0,0);
    rect(x+2, y+2, w/2-2, h-4);
    fill(meterTextColour);
    text("OFF", x+2+(w/2-2)/2, y-2);
  }else{
    fill(0,255,200);
    rect(x+w/2, y+2, w/2-2, h-4);
    fill(meterTextColour);
    text("ON", x+w/2+(w/2-2)/2, y-2);
  }
  fill(meterTextColour);
  textAlign(LEFT);
  textSize(meterNameTextSize);
  text(name, x+w+5, y-2+h/2+meterNameTextSize/2);
  textSize(meterTextSize);
}

/***
draｗDirectionMeter：方向指示器描写関数
(表示名，表示オフセット角度，入力角度，x位置(中心基準)，y位置(中心基準)，直径，針色決定用整数)

動作：
・円形のゲージが表示される．
・表示オフセット角度が0の場合，針は下を0度として表示される．
・左回りが正である．

注釈：
・表示名は""にすると表示されない．
・色決定用整数はcolourStock関数の項を参照すること．
・汎用性を重視して，360度を自動的に0度に換算するようにはなっていない．
・目盛り間隔はグローバル変数であるroundMeterGraduationAngleによって定義されている．

***/
void drawDirectionMeter(String name, int initialAngle, int angle, int x, int y, int r,int col){
  fill(meterGraduationColour);
  ellipse(x, y, r+1, r+1);
  fill(meterBackgroundColour);
  ellipse(x,y,r,r);
  stroke(meterGraduationColour,100);
  for(int i=0 ; i<(180/roundMeterGraduationAngle) ; i++){
    line(x+r/2*sin(radians(i*roundMeterGraduationAngle)),y+r/2*cos(radians(i*roundMeterGraduationAngle)),x-r/2*sin(radians(i*roundMeterGraduationAngle)),y-r/2*cos(radians(i*roundMeterGraduationAngle)));
  }
  ellipse(x,y,r*0.9,r*0.9);
  stroke(meterGraduationColour,50);
  for(int i=0 ; i<(180/45) ; i++){
    line(x+r/2*sin(radians(i*45)),y+r/2*cos(radians(i*45)),x-r/2*sin(radians(i*45)),y-r/2*cos(radians(i*45)));
  }
  noStroke();
  fill(colourStock[col],150);
  triangle(x+r*0.4*sin(radians(initialAngle+angle)),y+r*0.4*cos(radians(initialAngle+angle)),x+r*0.05*sin(radians(initialAngle+150+angle)),y+r*0.05*cos(radians(initialAngle+150+angle)),x+r*0.05*sin(radians(initialAngle+210+angle)),y+r*0.05*cos(radians(initialAngle+210+angle)));
  fill(meterBackgroundColour);
  stroke(meterGraduationColour, 150);
  ellipse(x,y,r*0.05,r*0.05);
  noStroke();
  textAlign(CENTER);
  textSize(meterNameTextSize);
  fill(meterTextColour);
  text(name,x,y+r/2+meterNameTextSize);
  textSize(meterTextSize);
  text(angle, x+r/2+meterTextSize*1, y+meterTextSize/2);
  textAlign(LEFT);
}

/***
draｗStickPosition：スティック位置描画用関数
(x軸入力値，y軸入力値，最大値，最小値，x位置(中心基準)，y位置(中心基準)，直径)

動作：
・円形のゲージが表示される．
・x軸入力値とy軸入力値を組み合わせて，円形表示域に白点がプロットされる．

注釈：
・表示名はない．
・PS3のスティックの位置に対応することを考えて作られた関数であり，汎用性は低い．

***/
void drawStickPosition(int xValue, int yValue, int max, int min, int x, int yLeftDown, int r){
  int y= yLeftDown;
  fill(meterGraduationColour,150);
  ellipse(x, y, r+3, r+3);
  fill(meterBackgroundColour);
  ellipse(x, y, r, r);
  stroke(meterGraduationColour,50);
  line(x-r/3, y, x+r/3, y);
  line(x, y-r/3, x, y+r/3);
  noStroke();
  fill(meterGraduationColour);
  ellipse(x+r/2*map(xValue,max,min,1,-1), y-r/2*map(yValue,max,min,1,-1), 3, 3);
}

/***
draｗCountRamp：残量描画用関数
(表示名，残数，全数，x位置，y位置(左下基準)，幅，高さ，針色決定用整数)

動作：
・全数分のランプが表示され，そのうち残数分が点灯する．

注釈：
・表示名は""にすると表示されない．
・全数＞残数となるようにしないと，表示がおかしくなる．
***/
void drawCountRamp(String name, int value, int number, int x, int yLeftDown, int w, int h, color col){
  int y= yLeftDown-h;
  float r=w/5;
  fill(meterTextColour);
  textAlign(CENTER);
  text(name, x+w/2, y-4);
  textAlign(LEFT);
  fill(meterBackgroundColour);
  rect(x,y,w,h);
  stroke(colourStock[col]);
  noFill();
  for(int i=0; i<number ; i++){
    ellipse(x+(i+1)*w/(number+1),y+h/2,r-1,r-1);
  }
  fill(colourStock[col]);
  noStroke();
  for(int i=0; i<value ; i++){
    ellipse(x+(i+1)*w/(number+1),y+h/2,r,r);
  }
}
/***
textSwitch：切り替えテキスト描写関数
(入力値，入力値がゼロの時表示する文章，入力値ゼロの時のテキストカラー設定用整数，入力値がゼロでない時に表示する文章，入力値非ゼロの時のテキストカラー設定用整数，x位置(中心基準)，y位置(中心基準)，フォントサイズ)

動作：
・条件によって表示内容が変化するテキストを描写する．
・入力値がゼロか否かで表示内容が変化する．

注釈：
・フォントがプロポーショナルフォントではないため，文章長さから幅が確定できない．このため，見栄えのために背景のグレーキューブを別途描写する必要がある．

***/
void textSwitch(int sw, String whenZero, int col1, String whenNotZero, int col2, int x, int y, int s){
  textSize(s);
  textAlign(CENTER);
  if (sw==0){
    fill(colourStock[col1]);
    text(whenZero, x, y);
  }else{
    fill(colourStock[col2]);
    text(whenNotZero, x, y);
  }
  textSize(meterTextSize);
  textAlign(LEFT);
}

void selectSwitch(int sw, int x, int y, int s){
  textSize(s);
  textAlign(CENTER);
  fill(colourStock[1]);
  switch(sw){
    case 0:
      text("Keep Value", x, y);
    break; 
    case 1:
      text("Keep Straight", x, y);
    break; 
    case 2:
      text("Loop", x, y);
    break; 
    case 3:
      text("Eight Loop", x, y);
    break; 
    case 4:
      text("Through", x, y);
    break;
  }
  textSize(meterTextSize);
  textAlign(LEFT);
}

void selectMenu(int sw, int x, int y, int s){
  textSize(s);
  textAlign(CENTER);
  fill(colourStock[1]);
  switch(sw){
    case 0:
      text("Aileron", x, y);
    break; 
    case 1:
      text("Elevator", x, y);
    break; 
    case 2:
      text("Rudder", x, y);
    break; 
  }
  textSize(meterTextSize);
  textAlign(LEFT);
}
/***
draｗRollMeter：ロールゲージ描写関数
(表示名，表示オフセット角度，入力角度，x位置(中心基準)，y位置(中心基準)，直径，針色決定用整数)

動作：
・円形のゲージが表示される．
・表示オフセット角度が0の場合，針は下を0度として表示される．
・右回りが正である．

注釈：
・表示名は""にすると表示されない．
・色決定用整数はcolourStock関数の項を参照すること．
・汎用性を重視して，360度を自動的に0度に換算するようにはなっていない．
・目盛り間隔はグローバル変数であるroundMeterGraduationAngleによって定義されている．
・右手系を想定して右回りが正となっているが，これは他の円形ゲージとは異なる．

***/
void drawRollMeter(String name, int initialAngle, int angle, int x, int y, int r,int col){
  fill(meterGraduationColour);
  ellipse(x, y, r+1, r+1);
  fill(meterBackgroundColour);
  ellipse(x,y,r,r);
  stroke(meterGraduationColour,100);
  for(int i=0 ; i<(180/roundMeterGraduationAngle) ; i++){
    line(x+r/2*sin(radians(i*roundMeterGraduationAngle)),y+r/2*cos(radians(i*roundMeterGraduationAngle)),x-r/2*sin(radians(i*roundMeterGraduationAngle)),y-r/2*cos(radians(i*roundMeterGraduationAngle)));
  }
  ellipse(x,y,r*0.9,r*0.9);
  stroke(meterGraduationColour,50);
  for(int i=0 ; i<(180/45) ; i++){
    line(x+r/2*sin(radians(i*45)),y+r/2*cos(radians(i*45)),x-r/2*sin(radians(i*45)),y-r/2*cos(radians(i*45)));
  }
  stroke(meterGraduationColour);
  strokeWeight(5);
  fill(colourStock[col],150);
  line(x+r*0.4*sin(radians(initialAngle-angle)),y+r*0.4*cos(radians(initialAngle-angle)),x-r*0.4*sin(radians(initialAngle-angle)),y-r*0.4*cos(radians(initialAngle-angle)));
  line(x,y,x+r*0.3*sin(radians(initialAngle+90-angle)),y+r*0.3*cos(radians(initialAngle+90-angle)));
  noStroke();
  strokeWeight(1);
  textAlign(CENTER);
  textSize(meterNameTextSize);
  fill(meterTextColour);
  text(name,x,y+r/2+meterNameTextSize);
  textSize(meterTextSize);
  text(angle, x+r/2+meterTextSize*1, y+meterTextSize/2);
  textAlign(LEFT);
}
