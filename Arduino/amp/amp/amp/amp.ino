// Controlling a servo position using a potentiometer (variable resistor) 
// by Michal Rinott <http://people.interaction-ivrea.it/m.rinott> 

#include <Servo.h> 
 
Servo myservo;  // create servo object to control a servo 

int potpin = 0;  // analog pin used to connect the potentiometer
int val;    // variable to read the value from the analog pin 
int dig;
void setup() 
{ 
  myservo.attach(8,1000,2300);  // attaches the servo on pin 9 to the servo object
  //myservo.attach(8,0,3300);  // attaches the servo on pin 9 to the servo object
  Serial.begin(9600);	// 9600bpsでポートを開く
} 
 
void loop() 
{ 
  val = analogRead(potpin);            // reads the value of the potentiometer (value between 0 and 1023) 
  dig = map(val, 0, 1023, 1000, 2300);     // scale it to use it with the servo (value between 0 and 180) 
  //dig = map(val, 0, 1023, 0, 3300);     // scale it to use it with the servo (value between 0 and 180) 
  myservo.write(dig);                  // sets the servo position according to the scaled value 
  Serial.println(dig, DEC);
  delay(19);                           // waits for the servo to get there 
} 
