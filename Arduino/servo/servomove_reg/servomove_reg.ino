#include <Servo.h>

Servo servo;

void setup() {
     Serial.begin(9600) ;      // パソコン(ArduinoIDE)とシリアル通信の準備を行う
     servo.attach(3);
}
void loop() {
     int ans , tv ;

     ans = analogRead(0) ;              // アナログ０番ピンからセンサー値を読込む
     tv  = map(ans,0,1023,0,180) ;     // センサー値を電圧に変換する
     //servo.write(tv);
     Serial.println(tv) ;             // 値をパソコン(ＩＤＥ)に送る
     delay(250) ;                      // １秒毎に繰り返す
}
