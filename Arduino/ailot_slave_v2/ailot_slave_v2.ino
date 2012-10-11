#include <Servo.h>
#include <Wire.h>

//Baud rate 9600 or 19200
#define BAUDRATE 19200
// IMU settings
#define GYRO 0x68         // gyro I2C address
#define GYRO_XOUT_H 0x1D   // IMU-3000 Register address for GYRO_XOUT_H
#define REG_TEMP 0x1B     // IMU-3000 Register address for 
#define ACCEL 0x53        // Accel I2c Address
#define ADXL345_POWER_CTL 0x2D

// 
#define PI 3.14159265358979
// Drop Servo Values
#define DROP_1 120
#define DROP_2 60
#define DROP_3 0
#define NODROP 180

// Output pin assigne
const int rudderPin = 2;
const int elevatorPin = 3;
const int throttlePin = 4;
const int aileronPin = 5;
const int dropPin = 6;
const int pingPin = 7;

// Servo Class Setting
Servo aileron;
Servo rudder;
Servo elevator;
Servo throttle;
Servo drop;

// State variables
int warning_stop = 0;
int keep = 0;
int release_box = 0;
int program = 0;
int autopilot = 0;

// Input controlled variables
byte inbuf[9] = {0,0,0,0,0,0,0,0,0};
int rudder_in = 90;
int aileron_in = 90;
int elevator_in = 90;
int throttle_in = 0;

// Input old controlled variables
int rudder_in_old = 90;
int aileron_in_old = 90;
int elevator_in_old = 90;
int throttle_in_old = 0;

// Default controlled variables
int rudder_deg = 90;
int aileron_deg = 90;
int elevator_deg = 90;
int throttle_deg = 0;
int drop_deg = NODROP;

// Sensor Output values
byte outbuf[17];

// IMU values
byte buffer[14];   // Array to store ADC values 
int gyro_x = 0;
int gyro_y = 0;
int gyro_z = 0;

int gyro_x_past = 0;
int gyro_y_past = 0;
int gyro_z_past = 0;

int gyro_x_bias = 5;
int gyro_y_bias = 32;
int gyro_z_bias = 1;

int accel_x = 0;
int accel_y = 0;
int accel_z = 0;

int accel_x_past = 0;
int accel_y_past = 0;
int accel_z_past = 0;

int accel_x_bias = 0;
int accel_y_bias = 0;
int accel_z_bias = 0;

//
unsigned long curtime;
unsigned long oldTime = 0;
unsigned long newTime;
unsigned long interval;

// PID settings
int permit;

int kp_accel_x;
int ki_accel_x;
int kd_accel_x;
int setpoint_accel_x;

int kp_accel_y;
int ki_accel_y;
int kd_accel_y;
int setpoint_accel_y;

int kp_accel_z;
int ki_accel_z;
int kd_accel_z;
int setpoint_accel_z;

int kp_gyro_x;
int ki_gyro_x;
int kd_gyro_x;
int setpoint_gyro_x;

int kp_gyro_y;
int ki_gyro_y;
int kd_gyro_y;
int setpoint_gyro_y;

int kp_gyro_z;
int ki_gyro_z;
int kd_gyro_z;
int setpoint_gyro_z;

/// Other Sensors ///
int altitude = 0;
int battery = 0;



/**********************************/
/***
Setup
***/
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
  outbuf[0] = (byte)'b';
  rudder.attach(rudderPin,1030,2100);
  elevator.attach(elevatorPin,1030,2100);
  throttle.attach(throttlePin,1030,2100);
  aileron.attach(aileronPin,1030,2100);
  drop.attach(dropPin,1030,2100);
}

/***
main loop
***/
void loop(){
  get_imu();
  get_altitude();
  serial_out();
  serial_in();
  set_serial_data();
  control_servo();
  delay(20);
}


/***
servo controls
***/
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

/***
Drop Servo controls
***/
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

void set_serial_data(){
  warning_stop = inbuf[0];
  release_box = inbuf[1];
  throttle_in = inbuf[2];
  rudder_in = inbuf[3];
  aileron_in = inbuf[4];
  elevator_in = inbuf[5];
}

void control_servo(){
  if(warning_stop == 1){
    setthrottle(0); 
  }
  setrudder(rudder_in);
  setelevator(elevator_in);
  setthrottle(throttle_in);
  setaileron(aileron_in);
  setdrop(release_box);
}

//Sensors
void setup_imu(){
  //IMU Sensor Setup
  Wire.begin();
  // Set Gyro settings
  // Sample Rate 1kHz, Filter Bandwidth 42Hz, Gyro Range 500 d/s 
  writeTo(GYRO, 0x16, 0x0B);
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

  outbuf[1] = interval >> 8;
  outbuf[2] = interval & 0x00FF;
  for(int i = 2; i < 14; i++){
    outbuf[i+1] = buffer[i];
  }
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
  outbuf[15] = altitude >> 8;
  outbuf[16] = altitude & 0x00FF;
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
  int safety = 0;
  byte temp = 0;
  byte backup = 0;
  if(Serial.available()>7){
    while(true){
       if(Serial.read() == 'a') break;
       safety++;
       if(safety > 15){
         break; 
       }
    }
    if(safety <= 15){
      for(int i = 0; i < 6; i++){
        temp = Serial.read();
        backup = inbuf[i];
        if(temp != -1){
          inbuf[i] = temp;
        }else{
          inbuf[i] = backup; 
        }
      }
    }
  }
}

void serial_out(){
  for(int i = 0; i < 17; i++){
    Serial.write(outbuf[i]);
  }
}

