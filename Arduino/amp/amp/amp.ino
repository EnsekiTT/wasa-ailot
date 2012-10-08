#include <Servo.h>

Servo servo00;

void setup(){
  servo00.attach(2);
  servo00.writeMicroseconds(1500);
  Serial.begin(9600);
}

void loop() {
  servo00.writeMicroseconds(1400);
  delay(1000);
  servo00.writeMicroseconds(1000);
  delay(1000);
  Serial.println("test");
}
