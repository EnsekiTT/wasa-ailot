color background=color(80,80,80);
int frameRate=60;
int meterTextSize=14;
int meterNameTextSize=18;
int metersmallTextSize=10;
int meterTextColour=240;
//メータの背景の地の部分の色
int meterBackgroundColour=25;
//目盛りの色，フレームの色
int meterGraduationColour=230;
//円形メータの目盛り間隔
int roundMeterGraduationAngle=5;
color[] colourStock={color(255,0,0),color(0,255,0),color(0,0,255),color(255,255,255),color(0,0,0)};
/*** meterBar number:
0:red
1:green
2:blue
3:white
4:black ***/

//入力値変化を模擬するためのテスト値群
int test=9;
int stest=1;
int temp=1;

void setup() {
  frameRate(frameRate);
  size(800, 600);
  textFont(createFont("Verdana", 36));
  noStroke();
}

void draw() {
  background(background);

//値変化を模擬するためのテスト用関数
  if (temp==30){
    test=test+1;
    temp=1;
    stest=-stest;
  }
  temp++;
  
  drawVerticalBarMeter("Throttle",test,100,0,570,500,20,350,3,"%");
  drawCheckRamp("AUTO",stest-1,650,530,40,40);
  drawStickPosition(0,1,2,-2,width/2-90,530,100);
  drawStickPosition(1,0,2,-2,width/2+55,530,100);
  drawCountRamp("Remaining",2,3,650,480,100,30,0);
  drawDirectionMeter("Angle of Attack",90,test*3,125,460,200,3);
  drawDirectionMeter("Direction",180,test*3,125,230,200,3);
  drawRollMeter("Roll",90,test*3,400,345,200,3);
  int aaa=mouseButton;
  text(aaa,400,300);
  
  //"YOU/I have controll"の部分の背景長方形
  fill(meterBackgroundColour);
  rect(650-120,570-30,240,40);
  
  textSwitch(stest-1,"YOU have control.",3,"I have control.",0,650,570,24);
}

/***
drawVerticalBarMeter：垂直型バーメータ描画関数
(表示名，入力値，最大値，最小値，x位置，y位置(左下基準)，幅，高さ，バーの色決定用整数，表示単位)

動作：
・下端から上方へ棒グラフが描写される．
・範囲をオーバーした場合は"OVER"と表示され，バーは赤くなる．

注釈：
・表示名は""にすると表示されない．
・色決定用整数はcolourStock関数の項を参照すること．
・単位は""にすると，単位用の[]が表示されなくなる．

***/
void drawVerticalBarMeter(String name, int value, int max, int min, int x, int yLeftDown, int w, int h, int colour, String unit){
  int y= yLeftDown-h;
  fill(meterBackgroundColour);
  rect(x, y, w, h);
  stroke(meterGraduationColour,100);
  for (int i=1; i < 10 ; i++ ){
    if (i==5){
      line(x+w*0.15 ,y+0.1*i*h ,x+w*0.85,y+0.1*i*h);
    }else{
      line(x+w*0.23 ,y+0.1*i*h ,x+w*0.77,y+0.1*i*h);
    }
  }
  noStroke();
  textSize(meterTextSize);
  if (max<value) {
    fill(colourStock[0]);
    rect(x+w*0.2, y+h, w*0.6, -h);
    fill(meterTextColour);
    text("OVER", x+w+5, y+h/2+meterTextSize/2);
  }else if (min>value) {
    fill(meterTextColour);
    text("OVER", x+w+5, y+h/2+meterTextSize/2);
  }else{
    fill(colourStock[colour],240);
    rect(x+w*0.2, y+h, w*0.6, -h*(1-norm(value,max,min)));
    fill(meterTextColour);
    text(str(value), x+w+5, y+h/2+meterTextSize/2);
    if (unit==""){
    }else{
      text("["+unit+"]", x+w+meterTextSize*2.5, y+h/2+meterTextSize/2);
    }
  }
  text(str(min), x+w+5, y+h);
  text(str(max), x+w+5, y+meterTextSize);
  textAlign(CENTER);
  textSize(meterNameTextSize);
  text(name, x+w/2, y+h+meterNameTextSize+5);
  textAlign(LEFT);
  textSize(meterTextSize);
}

/***
drawHorizontalBarMeter：水平型バーメータ描画関数
(表示名，入力値，最大最小値の絶対値，x位置，y位置(左下基準)，幅，高さ，バーの色決定用整数，表示単位)

動作：
・垂直型と異なり，最大値と最小値の絶対値は同じ．
・中央がゼロとなり，左右にバーが伸びる形である．
・範囲を超えた場合は"OVER RANGE"と表示され，バーが赤くなる．

注釈：
・表示名は""にすると表示されない．
・色決定用整数はcolourStock関数の項を参照すること．
・単位は""にすると，単位用の[]が表示されなくなる．

***/
void drawHorizontalBarMeter(String name, int value, int max, int x, int yLeftDown, int w, int h, int colour, String unit){
  int y= yLeftDown-h;
  fill(meterBackgroundColour);
  rect(x, y, w, h);
  stroke(meterGraduationColour,100);
  for (int i=1; i < 10 ; i++ ){
    if (i==5){
      line(x+w*0.1*i ,y+0.15*h ,x+w*0.1*i,y+h*0.85);
    }else{
      line(x+w*0.1*i ,y+0.23*h ,x+w*0.1*i,y+h*0.77);
    }
  }
  noStroke();
  textSize(meterTextSize);
  textAlign(CENTER);
  if (max<value) {
    fill(colourStock[0]);
    rect(x+w/2, y+h*0.2, w/2, h*0.6);
    fill(meterTextColour);
    text("OVER RANGE", x+w/2, y-meterTextSize/2);
  }else if (-max>value) {
    fill(colourStock[0]);
    rect(x+w/2, y+h*0.2, -w/2, h*0.6);
    fill(meterTextColour);
    text("OVER RANGE", x+w/2, y-meterTextSize/2);
  }else{
    fill(colourStock[colour],240);
    rect(x+w/2, y+h*0.2, w/2*(map(value,max,-max,1,-1)), h*0.6);
    fill(meterTextColour);
    text(str(value), x+w/2, y-meterTextSize/2);
    if (unit==""){
    }else{
      text("["+unit+"]", x+w/2+meterTextSize*2, y-meterTextSize/2);
    }
  }
  text(str(-max), x, y-meterTextSize/2);
  text(str(max), x+w, y-meterTextSize/2);
  textSize(meterNameTextSize);
  text(name, x+w/2, y+h+meterNameTextSize);
  textAlign(LEFT);
  textSize(meterTextSize);
}

/***
drawCheckRamp：OnOffチェックボックス型ランプ描写関数
(表示名，入力値，x位置，y位置(左下基準)，幅，高さ)

動作：
・四角形のランプが表示される．
・入力値が0の場合"OFF"，0以外の場合"ON"と表示される．
・"OFF"の場合は赤黒く，"ON"の場合明るい水色に点灯する．

注釈：
・表示名は""にすると表示されない．
・文字サイズは固定のため，あまり大きくすると見づらい．

***/
void drawCheckRamp(String name,int io, int x, int yLeftDown, int w, int h){
  int y= yLeftDown-h;
  String sign="OFF";
  fill(meterBackgroundColour);
  rect(x, y, w, h);
  textAlign(CENTER);
  
  if (io==0) {
    sign="OFF";
    fill(50,0,0);
    rect(x+2, y+2, w-4, h-4);
    fill(255);
  }else{
    sign="ON";
    fill(0,255,200);
    rect(x+2, y+2, w-4, h-4);
    fill(0);
  }
  text(sign, x+w/2, y+h/2+meterTextSize/2);
  textAlign(LEFT);
  fill(meterTextColour);
  textSize(meterNameTextSize);
  text(name, x+w+5, y-2+h/2+meterNameTextSize/2);
  textSize(meterTextSize);
}
/***
drawSwitchRamp：OnOffスイッチ型ランプ描写関数
(表示名，入力値，x位置，y位置(左下基準)，幅，高さ)

動作：
・四角形のランプが表示される．
・チェックボックス型と異なり，初めからOnOff領域が表示される．
・入力値が0の場合"OFF"，0以外の場合"ON"と小さく表示される．
・"OFF"の場合は赤黒く，"ON"の場合明るい水色に点灯する．

注釈：
・表示名は""にすると表示されない．
・文字サイズは固定のため，あまり大きくすると見づらい．

***/
void drawSwitchRamp(String name,int io, int x, int yLeftDown, int w, int h){
  int y= yLeftDown-h;
  fill(meterBackgroundColour);
  rect(x, y, w, h);
  textAlign(CENTER);
  textSize(metersmallTextSize);
  if (io==0) {
    fill(50,0,0);
    rect(x+2, y+2, w/2-2, h-4);
    fill(meterTextColour);
    text("OFF", x+2+(w/2-2)/2, y-2);
  }else{
    fill(0,255,200);
    rect(x+w/2, y+2, w/2-2, h-4);
    fill(meterTextColour);
    text("ON", x+w/2+(w/2-2)/2, y-2);
  }
  fill(meterTextColour);
  textAlign(LEFT);
  textSize(meterNameTextSize);
  text(name, x+w+5, y-2+h/2+meterNameTextSize/2);
  textSize(meterTextSize);
}

/***
draｗDirectionMeter：方向指示器描写関数
(表示名，表示オフセット角度，入力角度，x位置(中心基準)，y位置(中心基準)，直径，針色決定用整数)

動作：
・円形のゲージが表示される．
・表示オフセット角度が0の場合，針は下を0度として表示される．
・左回りが正である．

注釈：
・表示名は""にすると表示されない．
・色決定用整数はcolourStock関数の項を参照すること．
・汎用性を重視して，360度を自動的に0度に換算するようにはなっていない．
・目盛り間隔はグローバル変数であるroundMeterGraduationAngleによって定義されている．

***/
void drawDirectionMeter(String name, int initialAngle, int angle, int x, int y, int r,int col){
  fill(meterGraduationColour);
  ellipse(x, y, r+1, r+1);
  fill(meterBackgroundColour);
  ellipse(x,y,r,r);
  stroke(meterGraduationColour,100);
  for(int i=0 ; i<(180/roundMeterGraduationAngle) ; i++){
    line(x+r/2*sin(radians(i*roundMeterGraduationAngle)),y+r/2*cos(radians(i*roundMeterGraduationAngle)),x-r/2*sin(radians(i*roundMeterGraduationAngle)),y-r/2*cos(radians(i*roundMeterGraduationAngle)));
  }
  ellipse(x,y,r*0.9,r*0.9);
  stroke(meterGraduationColour,50);
  for(int i=0 ; i<(180/45) ; i++){
    line(x+r/2*sin(radians(i*45)),y+r/2*cos(radians(i*45)),x-r/2*sin(radians(i*45)),y-r/2*cos(radians(i*45)));
  }
  noStroke();
  fill(colourStock[col],150);
  triangle(x+r*0.4*sin(radians(initialAngle+angle)),y+r*0.4*cos(radians(initialAngle+angle)),x+r*0.05*sin(radians(initialAngle+150+angle)),y+r*0.05*cos(radians(initialAngle+150+angle)),x+r*0.05*sin(radians(initialAngle+210+angle)),y+r*0.05*cos(radians(initialAngle+210+angle)));
  fill(meterBackgroundColour);
  stroke(meterGraduationColour, 150);
  ellipse(x,y,r*0.05,r*0.05);
  noStroke();
  textAlign(CENTER);
  textSize(meterNameTextSize);
  fill(meterTextColour);
  text(name,x,y+r/2+meterNameTextSize);
  textSize(meterTextSize);
  text(angle, x+r/2+meterTextSize*1, y+meterTextSize/2);
  textAlign(LEFT);
}

/***
draｗStickPosition：スティック位置描画用関数
(x軸入力値，y軸入力値，最大値，最小値，x位置(中心基準)，y位置(中心基準)，直径)

動作：
・円形のゲージが表示される．
・x軸入力値とy軸入力値を組み合わせて，円形表示域に白点がプロットされる．

注釈：
・表示名はない．
・PS3のスティックの位置に対応することを考えて作られた関数であり，汎用性は低い．

***/
void drawStickPosition(int xValue, int yValue, int max, int min, int x, int yLeftDown, int r){
  int y= yLeftDown;
  fill(meterGraduationColour,150);
  ellipse(x, y, r+3, r+3);
  fill(meterBackgroundColour);
  ellipse(x, y, r, r);
  stroke(meterGraduationColour,50);
  line(x-r/3, y, x+r/3, y);
  line(x, y-r/3, x, y+r/3);
  noStroke();
  fill(meterGraduationColour);
  ellipse(x+r/2*map(xValue,max,min,1,-1), y-r/2*map(yValue,max,min,1,-1), 3, 3);
}

/***
draｗCountRamp：残量描画用関数
(表示名，残数，全数，x位置，y位置(左下基準)，幅，高さ，針色決定用整数)

動作：
・全数分のランプが表示され，そのうち残数分が点灯する．

注釈：
・表示名は""にすると表示されない．
・全数＞残数となるようにしないと，表示がおかしくなる．
***/
void drawCountRamp(String name, int value, int number, int x, int yLeftDown, int w, int h, color col){
  int y= yLeftDown-h;
  float r=w/5;
  fill(meterTextColour);
  textAlign(CENTER);
  text(name, x+w/2, y-4);
  textAlign(LEFT);
  fill(meterBackgroundColour);
  rect(x,y,w,h);
  stroke(colourStock[col]);
  noFill();
  for(int i=0; i<number ; i++){
    ellipse(x+(i+1)*w/(number+1),y+h/2,r-1,r-1);
  }
  fill(colourStock[col]);
  noStroke();
  for(int i=0; i<value ; i++){
    ellipse(x+(i+1)*w/(number+1),y+h/2,r,r);
  }
}
/***
textSwitch：切り替えテキスト描写関数
(入力値，入力値がゼロの時表示する文章，入力値ゼロの時のテキストカラー設定用整数，入力値がゼロでない時に表示する文章，入力値非ゼロの時のテキストカラー設定用整数，x位置(中心基準)，y位置(中心基準)，フォントサイズ)

動作：
・条件によって表示内容が変化するテキストを描写する．
・入力値がゼロか否かで表示内容が変化する．

注釈：
・フォントがプロポーショナルフォントではないため，文章長さから幅が確定できない．このため，見栄えのために背景のグレーキューブを別途描写する必要がある．

***/
void textSwitch(int sw, String whenZero, int col1, String whenNotZero, int col2, int x, int y, int s){
  textSize(s);
  textAlign(CENTER);
  if (sw==0){
    fill(colourStock[col1]);
    text(whenZero, x, y);
  }else{
    fill(colourStock[col2]);
    text(whenNotZero, x, y);
  }
  textSize(meterTextSize);
  textAlign(LEFT);
}

/***
draｗRollMeter：ロールゲージ描写関数
(表示名，表示オフセット角度，入力角度，x位置(中心基準)，y位置(中心基準)，直径，針色決定用整数)

動作：
・円形のゲージが表示される．
・表示オフセット角度が0の場合，針は下を0度として表示される．
・右回りが正である．

注釈：
・表示名は""にすると表示されない．
・色決定用整数はcolourStock関数の項を参照すること．
・汎用性を重視して，360度を自動的に0度に換算するようにはなっていない．
・目盛り間隔はグローバル変数であるroundMeterGraduationAngleによって定義されている．
・右手系を想定して右回りが正となっているが，これは他の円形ゲージとは異なる．

***/
void drawRollMeter(String name, int initialAngle, int angle, int x, int y, int r,int col){
  fill(meterGraduationColour);
  ellipse(x, y, r+1, r+1);
  fill(meterBackgroundColour);
  ellipse(x,y,r,r);
  stroke(meterGraduationColour,100);
  for(int i=0 ; i<(180/roundMeterGraduationAngle) ; i++){
    line(x+r/2*sin(radians(i*roundMeterGraduationAngle)),y+r/2*cos(radians(i*roundMeterGraduationAngle)),x-r/2*sin(radians(i*roundMeterGraduationAngle)),y-r/2*cos(radians(i*roundMeterGraduationAngle)));
  }
  ellipse(x,y,r*0.9,r*0.9);
  stroke(meterGraduationColour,50);
  for(int i=0 ; i<(180/45) ; i++){
    line(x+r/2*sin(radians(i*45)),y+r/2*cos(radians(i*45)),x-r/2*sin(radians(i*45)),y-r/2*cos(radians(i*45)));
  }
  stroke(meterGraduationColour);
  strokeWeight(5);
  fill(colourStock[col],150);
  line(x+r*0.4*sin(radians(initialAngle-angle)),y+r*0.4*cos(radians(initialAngle-angle)),x-r*0.4*sin(radians(initialAngle-angle)),y-r*0.4*cos(radians(initialAngle-angle)));
  line(x,y,x+r*0.3*sin(radians(initialAngle+90-angle)),y+r*0.3*cos(radians(initialAngle+90-angle)));
  noStroke();
  strokeWeight(1);
  textAlign(CENTER);
  textSize(meterNameTextSize);
  fill(meterTextColour);
  text(name,x,y+r/2+meterNameTextSize);
  textSize(meterTextSize);
  text(angle, x+r/2+meterTextSize*1, y+meterTextSize/2);
  textAlign(LEFT);
}
