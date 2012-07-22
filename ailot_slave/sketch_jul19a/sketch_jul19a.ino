int val;

void setup(){
  //シリアル通信開始
  Serial.begin(9600);
  //13ピンをデジタル出力に設定
  pinMode(13,OUTPUT0); 
}

void loop(){
  if(Serial.available()>0){
    val=Serial.read();
  }
  if(val=='H'){
    digitalWrite(13,HIGH);
  }else{
    digitalWrite(12,LOW);
  }
}
