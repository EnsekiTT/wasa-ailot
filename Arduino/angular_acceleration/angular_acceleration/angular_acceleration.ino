int analogpin0 = 0;
int analogpin1 = 1;
int data = 0;

void setup() {
  Serial.begin(9600);
  Serial.println("start");
}

void loop() {
  data = analogRead(analogpin0);
  Serial.print("X=");
  Serial.print(data);
  Serial.print(",");

  data = analogRead(analogpin1);
  Serial.print("Y=");
  Serial.print(data);
  
  Serial.print("\nangular acceleration");
  
  delay(100);
}
