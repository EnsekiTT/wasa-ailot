#include <Servo.h>
#include <Wire.h>

#define GYRO 0x68         // gyro I2C address
#define GYRO_XOUT_H 0x1D   // IMU-3000 Register address for GYRO_XOUT_H
#define REG_TEMP 0x1B     // IMU-3000 Register address for 
#define ACCEL 0x53        // Accel I2c Address
#define ADXL345_POWER_CTL 0x2D

#define PI 3.14159265358979

#define DROP_1 1300
#define DROP_2 1500
#define DROP_3 1700
#define NODROP 1000

Servo aileron;
Servo rudder;
Servo elevator;
Servo throttle;
Servo drop;

//各種変数
int warning_stop = 1;
int keep = 0;
int release_box = 0;
int program = 0;
int autopilot = 0;

//入力用
int rudder_in = 1500;
int aileron_in = 1500;
int elevator_in = 1500;
int throttle_in = 1023;

//操作用
int rudder_deg = 1500;
int aileron_deg = 1500;
int elevator_deg = 1500;
int throttle_deg = 1023;
int drop_deg = NODROP;


/// IMU ///
byte buffer[14];   // Array to store ADC values 
float gyro_x = 0;
float gyro_y = 0;
float gyro_z = 0;
float accel_x = 0;
float accel_y = 0;
float accel_z = 0;

unsigned long curtime;
unsigned long oldTime = 0;
unsigned long newTime;
unsigned long interval;

/// Other Sensors ///
int altitude = 0;
int battery = 0;
///////////

void setup(){
  Serial.begin(19200);
  rudder.attach(0);
  elevator.attach(1);
  throttle.attach(2);
  aileron.attach(3);
  drop.attach(4);
  //setup_imu();
}

void loop(){
  serial_in();
  control_servo();
  rudder.writeMicroseconds(rudder_deg);
  aileron.writeMicroseconds(aileron_deg);
  elevator.writeMicroseconds(elevator_deg);
  throttle.writeMicroseconds(throttle_deg);
  drop.writeMicroseconds(drop_deg);
  //get_imu();
  serial_out();
}

//操舵系
void setrudder(int deg){
  rudder_deg = deg;
}
void setelevator(int deg){
  elevator_deg = deg;
}
void setthrottle(int deg){
  throttle_deg = deg;
}
void setaileron(int deg){
  aileron_deg = deg;
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

//投下装置
void setdrop(int box){
  switch(box){
    case 0:
      drop_deg = NODROP;
    break;
    case 1:
      drop_deg = DROP_1;    
    break;
    case 2:
      drop_deg = DROP_2;
    break;
    case 3:
      drop_deg = DROP_3;    
    break;
    default:
      drop_deg = NODROP;
    break;
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
  }
  Wire.endTransmission();
  curtime = micros();
  newTime = curtime;
  interval = newTime - oldTime;
  oldTime = newTime;

  // Gyro format is MSB first
  gyro_x = buffer[2] << 8 | buffer[3];
  gyro_y = buffer[4] << 8 | buffer[5];
  gyro_z = buffer[6] << 8 | buffer[7];
    
  // Accel is LSB first. Also because of orientation of chips
  // accel y output is in same orientation as gyro x
  // and accel x is gyro -y
  accel_x = buffer[9] << 8 | buffer[8];
  accel_y = buffer[11] << 8 | buffer[10];
  accel_z = buffer[13] << 8 | buffer[12];
}

void get_altitude(){
  
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
  if(Serial.available() > 12){
    warning_stop = Serial.read(); //warning_stop
    keep = Serial.read(); //keep
    release_box = Serial.read(); //release
    program = Serial.read(); //program
    autopilot = Serial.read(); //autopilot
    throttle_in = Serial.read() << 8; //throttle_low
    throttle_in += Serial.read(); //throttle_high
    rudder_in = Serial.read() << 8; //rudder_low
    rudder_in += Serial.read(); //rudder_high
    aileron_in = Serial.read() << 8; //aileron_low
    aileron_in += Serial.read(); //aileron_high
    elevator_in = Serial.read() << 8; //elevator_low
    elevator_in += Serial.read(); //elevator_high
  }
}

void serial_out(){
  
}

