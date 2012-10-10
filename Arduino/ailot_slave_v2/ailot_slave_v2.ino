#include <Servo.h>
#include <Wire.h>

#define BAUDRATE 19200

#define GYRO 0x68         // gyro I2C address
#define GYRO_XOUT_H 0x1D   // IMU-3000 Register address for GYRO_XOUT_H
#define REG_TEMP 0x1B     // IMU-3000 Register address for 
#define ACCEL 0x53        // Accel I2c Address
#define ADXL345_POWER_CTL 0x2D

#define PI 3.14159265358979

#define DROP_1 120
#define DROP_2 60
#define DROP_3 0
#define NODROP 180

const int rudderPin = 2;
const int elevatorPin = 3;
const int throttlePin = 4;
const int aileronPin = 5;
const int dropPin = 6;
const int pingPin = 7;

Servo aileron;
Servo rudder;
Servo elevator;
Servo throttle;
Servo drop;

//各種変数
int warning_stop = 0;
int keep = 0;
int release_box = 0;
int program = 0;
int autopilot = 0;

//入力用
int rudder_in = 90;
int aileron_in = 90;
int elevator_in = 90;
int throttle_in = 0;

//自動操作用
int rudder_deg = 90;
int aileron_deg = 90;
int elevator_deg = 90;
int throttle_deg = 0;
int drop_deg = NODROP;

/// IMU ///
byte buffer[14];   // Array to store ADC values 
float gyro_x_low = 0;
float gyro_y_low = 0;
float gyro_z_low = 0;
float accel_x_low = 0;
float accel_y_low = 0;
float accel_z_low = 0;
float gyro_x_high = 0;
float gyro_y_high = 0;
float gyro_z_high = 0;
float accel_x_high = 0;
float accel_y_high = 0;
float accel_z_high = 0;

unsigned long curtime;
unsigned long oldTime = 0;
unsigned long newTime;
unsigned long interval;

/// Other Sensors ///
int altitude = 0;
int battery = 0;
/////////////////////

void setup(){
  Serial.begin(BAUDRATE);
  Serial.flush();
  while(1){
     if(Serial.available() > 0){
       if(Serial.read() == 'a'){
         break;
       }
     }
  }
  Serial.flush();
  setup_imu();
  rudder.attach(rudderPin,1030,2100);
  elevator.attach(elevatorPin,1030,2100);
  throttle.attach(throttlePin,1030,2100);
  aileron.attach(aileronPin,1030,2100);
  drop.attach(dropPin,1030,2100);
}

void loop(){
  get_imu();
  get_altitude();
  serial_in();
  control_servo();
  serial_out();
  delay(20);
}

void interupt(){
}

//操舵系
void setrudder(int deg){
  rudder.write(deg);
}
void setelevator(int deg){
  elevator.write(deg);
}
void setthrottle(int deg){
  throttle.write(deg);
}
void setaileron(int deg){
  aileron.write(deg);
}

//投下装置
void setdrop(int box){
  switch(box){
    case 0:
      drop.write(NODROP);
    break;
    case 1:
      drop.write(DROP_1);    
    break;
    case 2:
      drop.write(DROP_2);
    break;
    case 3:
      drop.write(DROP_3);    
    break;
    default:
      drop.write(NODROP);
    break;
  }
}


void control_servo(){
  if(autopilot == 0){
    setrudder(rudder_in);
    setelevator(elevator_in);
    setthrottle(throttle_in);
    setaileron(aileron_in);
    setdrop(release_box);
  }else if(keep == 1){
    
  }else{
    switch(program){
      //keep
      case 0:
      
      break;
      //hover
      case 1:
    
      break;
      //loop
      case 2: 
      
      break;
      //eight_loop
      case 3:
      
      break;
      default:
      
      break;
    }
  } 
}

//センサ系
void setup_imu(){
  //IMU Sensor Setup
  Wire.begin();
  // Set Gyro settings
  // Sample Rate 1kHz, Filter Bandwidth 42Hz, Gyro Range 500 d/s 
  writeTo(GYRO, 0x16, 0x1B);
  //set accel register data address
  writeTo(GYRO, 0x18, 0x32);
  // set accel i2c slave address
  writeTo(GYRO, 0x14, ACCEL);
    
  // Set passthrough mode to Accel so we can turn it on
  writeTo(GYRO, 0x3D, 0x08);
  // set accel power control to 'measure'
  writeTo(ACCEL, ADXL345_POWER_CTL, 8);
  // set accel range to +-2 g, and change accel output to MSB
  writeTo(ACCEL, 0x31, 0x04);
  //cancel pass through to accel, gyro will now read accel for us   
  writeTo(GYRO, 0x3D, 0x28);
    
  writeTo(GYRO, 0x0C, 0xFF);
  writeTo(GYRO, 0x0D, 0xc0);
  writeTo(GYRO, 0x0E, 0xFF);
  writeTo(GYRO, 0x0F, 0x8b);
  writeTo(GYRO, 0x10, 0x00);
  writeTo(GYRO, 0x11, 0x0c);
}

void get_imu(){
  // Read the Gyro X, Y and Z and Accel X, Y and Z all through the gyro  
  // First set the register start address for X on Gyro  
  Wire.beginTransmission(GYRO);
  Wire.write(REG_TEMP); //Register Address GYRO_XOUT_H
  Wire.endTransmission();
  // New read the 14 data bytes
  Wire.beginTransmission(GYRO);
  Wire.requestFrom(GYRO,14); // Read 14 bytes
  int i = 0;
  while(Wire.available())
  {
    buffer[i] = Wire.read();
    i++;
  }
  Wire.endTransmission();
  curtime = micros();
  newTime = curtime;
  interval = newTime - oldTime;
  oldTime = newTime;

  // Gyro format is MSB first
  gyro_x_high = buffer[2];
  gyro_x_low = buffer[3];
  gyro_y_high = buffer[4];
  gyro_y_low = buffer[5];
  gyro_z_high = buffer[6];
  gyro_z_low = buffer[7];
    
  // Accel is LSB first. Also because of orientation of chips
  // accel y output is in same orientation as gyro x
  // and accel x is gyro -y
  accel_x_high = buffer[9];
  accel_x_low = buffer[8];
  accel_y_high = buffer[11];
  accel_y_low = buffer[10];
  accel_z_high = buffer[13];
  accel_z_low = buffer[12];
}

void get_altitude(){
  long duration;
  
  pinMode(pingPin, OUTPUT);
  digitalWrite(pingPin, LOW);
  delayMicroseconds(2);
  digitalWrite(pingPin, HIGH);
  delayMicroseconds(5);
  digitalWrite(pingPin, LOW);
  
  pinMode(pingPin, INPUT);
  duration = pulseIn(pingPin, HIGH,20000);
  altitude = duration / 29 / 2;
}

void get_battery(){
  
}

// Write a value to address register on device
void writeTo(int device, byte address, byte val) {
  Wire.beginTransmission(device); // start transmission to device 
  Wire.write(address);             // send register address
  Wire.write(val);                 // send value to write
  Wire.endTransmission();         // end transmission
}

void serial_in(){
  if(Serial.available()>0 && Serial.peek() == 'a'){
    if(Serial.available()>9){
      Serial.read();
      warning_stop = Serial.read(); //warning_stop
      keep = Serial.read(); //keep
      release_box = Serial.read(); //release
      program = Serial.read(); //program
      autopilot = Serial.read(); //autopilot
      throttle_in = Serial.read(); //throttle
      rudder_in = Serial.read(); //rudder
      aileron_in = Serial.read(); //aileron
      elevator_in = Serial.read(); //elevator
    }
  }else{
    Serial.read(); 
  }
}

void serial_out(){
  /*
  Serial.write('a');
  delayMicroseconds(1);
  Serial.write(interval>>8);
  delayMicroseconds(1);
  Serial.write(interval & 0x00FF);
  delayMicroseconds(1);
  Serial.write(accel_x_high);
  delayMicroseconds(1);
  Serial.write(accel_x_low);
  delayMicroseconds(1);
  Serial.write(accel_y_high);
  delayMicroseconds(1);
  Serial.write(accel_y_low);
  delayMicroseconds(1);
  Serial.write(accel_z_high);
  delayMicroseconds(1);
  Serial.write(accel_z_low);
  delayMicroseconds(1);
  Serial.write(gyro_x_high);
  delayMicroseconds(1);
  Serial.write(gyro_x_low);
  delayMicroseconds(1);
  Serial.write(gyro_y_high);
  delayMicroseconds(1);
  Serial.write(gyro_y_low);
  delayMicroseconds(1);
  Serial.write(gyro_z_high);
  delayMicroseconds(1);
  Serial.write(gyro_z_low);
  delayMicroseconds(1);
*/
  Serial.print(altitude);
  delayMicroseconds(1);
  Serial.println();
  delayMicroseconds(1);
}

