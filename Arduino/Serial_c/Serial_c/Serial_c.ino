#include <Servo.h>

Servo servo00;
int incomingByte;
int in_buf_counter = 0;
int in_counter = 0;
int in_buffer[6] = {0,0,0,0,0,0};

void setup(){
  Serial.begin(9600);     // opens serial port, sets data rate to 9600 bps
  servo00.attach(3);
  servo00.writeMicroseconds(1500);
}

void loop() {
  // send data only when you receive data:
  if(Serial.available() > 0) {
    // read the incoming byte:
    incomingByte = Serial.read();
    Serial.println(incomingByte, BIN);
    if(in_counter % 2 == 1){
      in_buffer[in_buf_counter] += incomingByte;
      in_buf_counter++;
    }else{
      in_buffer[in_buf_counter] = incomingByte << 8;
    }
    in_counter++;
  }
  
  if(in_buf_counter >= 6){
    in_buf_counter = 0;
    for(int i = 0; i < 6; i++){
      Serial.println(in_buffer[i], HEX);
    }
  }
  
  if(in_counter >= 12){
    in_counter = 0;
  }

  /*
  servo00.writeMicroseconds(1400);
  delay(1000);
  servo00.writeMicroseconds(1000);
  delay(1000);
  */
}

