#include "/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/cores/arduino/Arduino.h"
#include "/Applications/Arduino.app/Contents/Resources/Java/libraries/Servo/Servo.h"
 
Servo myservo;  // create servo object to control a servo 

int potpin = 0;  // analog pin used to connect the potentiometer
int val;    // variable to read the value from the analog pin 
int dig;

int main (void)
{
  init();
  setup();
  for(;;){
    loop();
  }
  return 0;
}

void setup() {
  myservo.attach(8,1250,3300);  // attaches the servo on pin 9 to the servo object
  Serial.begin(9600);// 9600bpsでポートを開く
}

void loop() {
  val = analogRead(potpin);            // reads the value of the potentiometer (value between 0 and 1023) 
  dig = map(val, 0, 1023, 1250, 3300);     // scale it to use it with the servo (value between 0 and 180) 
  myservo.write(dig);                  // sets the servo position according to the scaled value 
  Serial.println(dig, DEC);
  delay(15);                           // waits for the servo to get there 
}
