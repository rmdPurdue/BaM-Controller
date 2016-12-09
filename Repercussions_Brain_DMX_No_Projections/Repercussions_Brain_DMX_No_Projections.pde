// XBee API receipts built off of Justin Downs johnhenryhammer.com
import processing.serial.*;
import oscP5.*;
import netP5.*;
import dmxP512.*;

DmxP512 dmxOutput;
int universeSize = 128;
boolean DMXPRO = true;
String DMXPRO_PORT = "COM22";
int DMXPRO_BAUDRATE = 115000;

/*****     Objects for OSC, UDP connections      *****/
OscP5 oscP5;
NetAddress myRemoteLocation;

/*****     Objects for XBee Communication        *****/
int apiIdentifier,localAddress,packetLength;
int[] address = new int[8];
int[] dataIn = new int[100];
int[] dancer1Address = new int[4];
int[] dancer2Address = new int[4];
int[] addressHigh = new int[4];
int options,checksum;
int frameID = 1;
int destination[] = {0x00, 0x13, 0xA2, 0x00, 0x40, 0xF9, 0x79, 0x0C};
int[] payload = new int[0];
Serial xbee;

/*****     Objects to store data for each dancer *****/
Dancer dancer1, dancer2;

boolean rotateDancer1, rotateDancer2, drawDancer1, drawDancer2, shiftDancer1, shiftDancer2,
        scaleDancer1, scaleDancer2, lxDancer1, lxDancer2;
String dancer1Type,dancer2Type;
int dancer1r, dancer2r, dancer1g, dancer2g, dancer1b, dancer2b, dancer1x, dancer2x, dancer1y, dancer2y,
    dancer1w, dancer2w, dancer1h, dancer2h, dancer1Scale, dancer2Scale, dancer1Shift, dancer2Shift,
    dancer1WidthFactor, dancer2WidthFactor, dancer1HeightFactor, dancer2HeightFactor, dancer1Angle, dancer2Angle,
    dancer1Intensity, dancer2Intensity, dancer1Pan, dancer2Pan, dancer1Tilt, dancer2Tilt,
    dancer1Cyan, dancer2Cyan, dancer1Yellow, dancer2Yellow, dancer1Magenta, dancer2Magenta,
    dancer1Gobo, dancer2Gobo;

boolean fade = false;
int fadeCount = 0;

PFont dataFont, labelFont;

void setup() {
  frameRate(30);
  
/*****   Set address bytes for coordinator xbee  *****/
  addressHigh[0] = char(0x00);
  addressHigh[1] = char(0x13);
  addressHigh[2] = char(0xA2);
  addressHigh[3] = char(0x00);
  dancer1Address[0] = char(0x40);
  dancer1Address[1] = char(0xA7);
  dancer1Address[2] = char(0x16);
  dancer1Address[3] = char(0x37);
  dancer2Address[0] = char(0x40);
  dancer2Address[1] = char(0xA8);
  dancer2Address[2] = char(0x9B);
  dancer2Address[3] = char(0xBF);

/*****   Setup display window                   *****/
//  size(840,700);
  fullScreen();
  background(0,0,0);

/*****   Initialize Dancer objecys for storage  *****/
  dancer1 = new Dancer();
  dancer2 = new Dancer();

/*****   Initialize OSC and network objects     *****/
  oscP5 = new OscP5(this, 8000);
  myRemoteLocation = new NetAddress("127.0.0.1", 8000);

/*****   Set up serial ports for XBee           *****/
  String ports[] = Serial.list();
  int numPorts = ports.length;
  println(ports);
  if(numPorts < 1) {
    fill(0,0,0);
    textSize(14);
    text("No serial ports connected.",20,380);
  }
  xbee = new Serial(this, "COM4", 9600);

  dmxOutput = new DmxP512(this,universeSize,false);
  dmxOutput.setupDmxPro(DMXPRO_PORT,DMXPRO_BAUDRATE);
  
  dataFont = loadFont("DS-Digital-Bold-48.vlw");
  labelFont = loadFont("Arial-BoldMT-48.vlw");
}

void draw() {
  try {
  dmxOutput.set(27,5);
  dmxOutput.set(1,73);
  dmxOutput.set(101,73);
  dmxOutput.set(127,5);
  drawData();
  if(fade && fadeCount < 75) {
    if(fadeCount == 50) {
      fill(0,0,0);
    } else {
      fill(0,0,0,10);
    }
    rect(0,0,width,height);
    fadeCount++;
  } else {
    receive();      // Check for incoming XBee data and parse it
    if(lxDancer1) {
      dmxOutput.set(102, dancer1.getLevel(dancer1Intensity));
      dmxOutput.set(125, dancer1.getLevel(dancer1Pan));
      dmxOutput.set(126, dancer1.getLevel(dancer1Tilt));
      dmxOutput.set(103, dancer1.getLevel(dancer1Cyan));
      dmxOutput.set(104, dancer1.getLevel(dancer1Yellow));
      dmxOutput.set(105, dancer1.getLevel(dancer1Magenta));
      dmxOutput.set(107, dancer1.getLevel(dancer1Gobo));
    }
    if(lxDancer2) {
      dmxOutput.set(2, dancer2.getLevel(dancer2Intensity));
      dmxOutput.set(25, dancer2.getLevel(dancer2Pan));
      dmxOutput.set(26, dancer2.getLevel(dancer2Tilt));
      dmxOutput.set(3, dancer2.getLevel(dancer2Cyan));
      dmxOutput.set(4, dancer2.getLevel(dancer2Yellow));
      dmxOutput.set(5, dancer2.getLevel(dancer2Magenta));
      dmxOutput.set(7, dancer2.getLevel(dancer2Gobo));
    }
/*

    if(drawDancer1) {
      drawShapes(dancer1Type, dancer1.getLevel(dancer1r), dancer1.getLevel(dancer1g), dancer1.getLevel(dancer1b), dancer1.getLevel(dancer1x), dancer1.getLevel(dancer1y), dancer1.getLevel(dancer1w), dancer1.getLevel(dancer1h));
    }
    if(drawDancer2) {
      drawShapes(dancer2Type, dancer2.getLevel(dancer2r), dancer2.getLevel(dancer2g), dancer2.getLevel(dancer2g), dancer2.getLevel(dancer2x), dancer2.getLevel(dancer2y), dancer2.getLevel(dancer2w), dancer2.getLevel(dancer2h));
    }
    if(scaleDancer1) {
      scaleShapes(dancer2Type, dancer2.getLevel(dancer2r), dancer2.getLevel(dancer2g), dancer2.getLevel(dancer2b), dancer1x, dancer1y, dancer1w, dancer1h, dancer2.getLevel(dancer2Scale)/10);
    }
    if(scaleDancer2) {
      scaleShapes(dancer2Type, dancer2.getLevel(dancer2r), dancer2.getLevel(dancer2g), dancer2.getLevel(dancer2b), dancer2x, dancer2y, dancer2w, dancer2h, dancer2.getLevel(dancer2Scale)/10);
    }
    if(shiftDancer1) {
      shiftShapes(dancer1Type, dancer1.getLevel(dancer1r), dancer1.getLevel(dancer1g), dancer1.getLevel(dancer1b), dancer1x, dancer1y, dancer1w, dancer1h, dancer1.getLevel(dancer1Shift), dancer1.getLevel(dancer1WidthFactor), dancer1.getLevel(dancer1HeightFactor));
    }
    if(shiftDancer2) {
      shiftShapes(dancer2Type, dancer2.getLevel(dancer2r), dancer2.getLevel(dancer2g), dancer2.getLevel(dancer2b), dancer2x, dancer2y, dancer2w, dancer2h, dancer2.getLevel(dancer2Shift), dancer2.getLevel(dancer2WidthFactor), dancer2.getLevel(dancer2HeightFactor));
    }
    if(rotateDancer1) {
      rotateShapes(dancer1Type, dancer1.getLevel(dancer1r), dancer1.getLevel(dancer1g), dancer1.getLevel(dancer1b), dancer1x, dancer1y, dancer1w, dancer1h, dancer1.getLevel(dancer1Angle));
    }
    if(rotateDancer2) {
      rotateShapes(dancer2Type, dancer2.getLevel(dancer2r), dancer2.getLevel(dancer2g), dancer2.getLevel(dancer2b), dancer2x, dancer2y, dancer2w, dancer2h, dancer2.getLevel(dancer2Angle));
    }
*/
  delay(250);
  }
  println(millis());
  } catch (Exception e) {
    println("draw ()" + e.getMessage());
    try {
      Thread.currentThread().sleep(150);
    } catch (Exception el) {
    }
  }
}

void drawData() {
  stroke(0,0,0);
  fill(0,0,0);
  rect(0,0,width,60);
  rect(0,height-60,width,60);
  textFont(dataFont);
  textAlign(CENTER);
  textSize(36);
  for(int i = 0; i < 25; i++) {
    stroke(255,255,255);
    fill(255,255,255);
    if(i < 12) {
      text(dancer2.getLevel(i),50+(i*75),height-40);
      text(dancer1.getLevel(i),50+(i*75),30);
    } else {
      text(dancer2.getLevel(i),50+((24-i)*75),height-10);
      text(dancer1.getLevel(i),50+((24-i)*75),60);
    }
  }
}
/*
void drawShapes(String type, int r, int g, int b, int x, int y, int w, int h) {
  fill(r,g,b,127);
  stroke(r,g,b,127);
  if(type.equals("ellipse")) {
    ellipse(x+300,y+300,w,h);
  } else if(type.equals("rect")) {
    rect(x+300,y+300,w,h);
  } else {
    ellipse(x,y,w,h);
  }
}

void scaleShapes(String type, int r, int g, int b, int x, int y, int w, int h, float i) {
  pushMatrix();
  scale(i/5);
  fill(r,g,b,127);
  stroke(r,g,b,127);
  if(type.equals("ellipse")) {
    translate(x/(i/5),y/(i/5));
    ellipse(0,0,w,h);
  } else if(type.equals("rect")) {
    translate(x/(i/5),y/(i/5));
    rect(0,0,w,h);
  } else {
    ellipse(0,0,w,h);
  }
  popMatrix();
}

void shiftShapes(String type, int r, int g, int b, int x, int y, int w, int h, float i, float j, float k) {
  fill(r,g,b,127);
  stroke(r,g,b,127);
  pushMatrix();
  translate(i*j/100,i*k/100);
  if(type.equals("ellipse")) {
    ellipse(x,y,w,h);
  } else if(type.equals("rect")) {
    rect(x*2,y*2,w,h);
  } else {
    ellipse(x*2,y*2,w,h);
  }
  popMatrix();
}

void rotateShapes(String type, int r, int g, int b, int x, int y, int w, int h, float i) {
  println(type);
  pushMatrix();
  translate(x*2,y*2);
  rotate(i/15);
  fill(r,g,b,127);
  stroke(r,g,b,127);
  if(type.equals("ellipse")) {
    ellipse(x/4,y/4,w,h);
  } else if(type.equals("rect")) {
    rect((x/2)-w,(y/2)-h,w,h);
  } else {
    ellipse(x/4,y/4,w,h);
  }
  popMatrix();
}
*/
void oscEvent(OscMessage theOscMessage) {
  println("Got OSC Message.");
  println("### received an OSC message.");
  println("Address Pattern: "+theOscMessage.addrPattern());
  println("Typetag: "+theOscMessage.typetag());
  println("Timetag: "+theOscMessage.timetag());
  /*
  if(theOscMessage.checkAddrPattern("/draw") == true) {
    if(theOscMessage.checkTypetag("isiiiiiii")) {
      if(theOscMessage.get(0).intValue() == 1) {
        drawDancer1 = true;
        dancer1Type = theOscMessage.get(1).stringValue();
        dancer1r = theOscMessage.get(2).intValue();
        dancer1g = theOscMessage.get(3).intValue();
        dancer1b = theOscMessage.get(4).intValue();
        dancer1x = theOscMessage.get(5).intValue();
        dancer1y = theOscMessage.get(6).intValue();
        dancer1w = theOscMessage.get(7).intValue();
        dancer1h = theOscMessage.get(8).intValue();
      } else if(theOscMessage.get(0).intValue() == 2) {
        drawDancer2 = true;
        dancer2Type = theOscMessage.get(1).stringValue();
        dancer2r = theOscMessage.get(2).intValue();
        dancer2g = theOscMessage.get(3).intValue();
        dancer2b = theOscMessage.get(4).intValue();
        dancer2x = theOscMessage.get(5).intValue();
        dancer2y = theOscMessage.get(6).intValue();
        dancer2w = theOscMessage.get(7).intValue();
        dancer2h = theOscMessage.get(8).intValue();
      }
    }
  } else if(theOscMessage.checkAddrPattern("/shift") == true) {
    if(theOscMessage.checkTypetag("isiiiiiiiiii")) {
      if(theOscMessage.get(0).intValue() == 1) {
        shiftDancer1 = true;
        dancer1Type = theOscMessage.get(1).stringValue();
        dancer1r = theOscMessage.get(2).intValue();
        dancer1g = theOscMessage.get(3).intValue();
        dancer1b = theOscMessage.get(4).intValue();
        dancer1x = theOscMessage.get(5).intValue();
        dancer1y = theOscMessage.get(6).intValue();
        dancer1w = theOscMessage.get(7).intValue();
        dancer1h = theOscMessage.get(8).intValue();
        dancer1Shift = theOscMessage.get(9).intValue();
        dancer1WidthFactor = theOscMessage.get(10).intValue();
        dancer1HeightFactor = theOscMessage.get(11).intValue();
      } else if(theOscMessage.get(0).intValue() == 2) {
        shiftDancer2 = true;
        dancer2Type = theOscMessage.get(1).stringValue();
        dancer2r = theOscMessage.get(2).intValue();
        dancer2g = theOscMessage.get(3).intValue();
        dancer2b = theOscMessage.get(4).intValue();
        dancer2x = theOscMessage.get(5).intValue();
        dancer2y = theOscMessage.get(6).intValue();
        dancer2w = theOscMessage.get(7).intValue();
        dancer2h = theOscMessage.get(8).intValue();
        dancer2Shift = theOscMessage.get(9).intValue();
        dancer2WidthFactor = theOscMessage.get(10).intValue();
        dancer2HeightFactor = theOscMessage.get(11).intValue();
      }
    }
  } else if(theOscMessage.checkAddrPattern("/scale") == true) {
    if(theOscMessage.checkTypetag("isiiiiiiii")) {
      if(theOscMessage.get(0).intValue() == 1) {
        scaleDancer1 = true;
        dancer1Type = theOscMessage.get(1).stringValue();
        dancer1r = theOscMessage.get(2).intValue();
        dancer1g = theOscMessage.get(3).intValue();
        dancer1b = theOscMessage.get(4).intValue();
        dancer1x = theOscMessage.get(5).intValue();
        dancer1y = theOscMessage.get(6).intValue();
        dancer1w = theOscMessage.get(7).intValue();
        dancer1h = theOscMessage.get(8).intValue();
        dancer1Scale = theOscMessage.get(9).intValue();
      } else if(theOscMessage.get(0).intValue() == 2) {
        scaleDancer2 = true;
        dancer2Type = theOscMessage.get(1).stringValue();
        dancer2r = theOscMessage.get(2).intValue();
        dancer2g = theOscMessage.get(3).intValue();
        dancer2b = theOscMessage.get(4).intValue();
        dancer2x = theOscMessage.get(5).intValue();
        dancer2y = theOscMessage.get(6).intValue();
        dancer2w = theOscMessage.get(7).intValue();
        dancer2h = theOscMessage.get(8).intValue();
        dancer2Scale = theOscMessage.get(9).intValue();
      }
    }
  } else if(theOscMessage.checkAddrPattern("/rotate") == true) {
    if(theOscMessage.checkTypetag("isiiiiiiii")) {
      if(theOscMessage.get(0).intValue() == 1) {
        rotateDancer1 = true;
        dancer1Type = theOscMessage.get(1).stringValue();
        dancer1r = theOscMessage.get(2).intValue();
        dancer1g = theOscMessage.get(3).intValue();
        dancer1b = theOscMessage.get(4).intValue();
        dancer1x = theOscMessage.get(5).intValue();
        dancer1y = theOscMessage.get(6).intValue();
        dancer1w = theOscMessage.get(7).intValue();
        dancer1h = theOscMessage.get(8).intValue();
        dancer1Angle = theOscMessage.get(9).intValue();
      } else if(theOscMessage.get(0).intValue() == 2) {
        rotateDancer2 = true;
        dancer2Type = theOscMessage.get(1).stringValue();
        dancer2r = theOscMessage.get(2).intValue();
        dancer2g = theOscMessage.get(3).intValue();
        dancer2b = theOscMessage.get(4).intValue();
        dancer2x = theOscMessage.get(5).intValue();
        dancer2y = theOscMessage.get(6).intValue();
        dancer2w = theOscMessage.get(7).intValue();
        dancer2h = theOscMessage.get(8).intValue();
        dancer2Angle = theOscMessage.get(9).intValue();
      }
    }
  } else if(theOscMessage.checkAddrPattern("/fade") == true) {
    fade = true;
    fadeCount = 0;
    rotateDancer1 = false;
    rotateDancer2 = false;
    drawDancer1 = false;
    drawDancer2 = false;
    shiftDancer1 = false;
    shiftDancer2 = false;
    scaleDancer1 = false;
    scaleDancer2 = false;
  } else */
  if(theOscMessage.checkAddrPattern("/lights") == true) {
    if(theOscMessage.checkTypetag("iiiiiiii")) {
      println("Lights message");
      if(theOscMessage.get(0).intValue() == 1) {
        lxDancer1 = true;
        dancer1Intensity = theOscMessage.get(1).intValue();
        dancer1Pan = theOscMessage.get(2).intValue();
        dancer1Tilt = theOscMessage.get(3).intValue();
        dancer1Cyan = theOscMessage.get(4).intValue();
        dancer1Yellow = theOscMessage.get(5).intValue();
        dancer1Magenta = theOscMessage.get(6).intValue();
        dancer1Gobo = theOscMessage.get(7).intValue();
      } else if(theOscMessage.get(0).intValue() == 2) {
        lxDancer2 = true;
        dancer2Intensity = theOscMessage.get(1).intValue();
        dancer2Pan = theOscMessage.get(2).intValue();
        dancer2Tilt = theOscMessage.get(3).intValue();
        dancer2Cyan = theOscMessage.get(4).intValue();
        dancer2Yellow = theOscMessage.get(5).intValue();
        dancer2Magenta = theOscMessage.get(6).intValue();
        dancer2Gobo = theOscMessage.get(7).intValue();
      }
    } 
  }
}

/*****   Function for receiving XBee Packets    *****/
void receive() {
  int timeout = 100;
  packetLength = checkHeader(timeout);
  if(packetLength > 0) {
    println("Got XBee message.");
    apiIdentifier = getIdentifier(timeout);
    address = getLongAddress(timeout);
    localAddress = getLocalAddress(timeout);
    options = getOptions(timeout);
    dataIn = getInfo(packetLength, timeout);
    checksum = getChecksum(timeout);
    write();
  }
}

int checkHeader(int timeout) {
  long startTime = millis();
  int length = 0;
  int inByte = 0;
  
  while(((millis() - startTime) < timeout) && (inByte != 0x7E)) {
    if(xbee.available() > 0) {
      inByte = xbee.read();
    }
  }
  
  if(inByte == 0x7E) {
    while(xbee.available() < 2);
    int lengthMSB = escapedByte();
    int lengthLSB = escapedByte();
    length = (lengthMSB << 8) + lengthLSB;
  }
  
  return length;
}

int getChecksum(int timeout) {
  int checksum = 'Z';
  long startTime = millis();
  while(xbee.available() < 1 && ((millis() - startTime) < timeout));
  if(xbee.available() > 0) {
    checksum = escapedByte();
    return checksum;
  }
  return 0;
}

int getIdentifier(int timeout) {
  long startTime = millis();
  int apiIdentifier = 'Z';
  while(xbee.available() < 1 && ((millis() - startTime) < timeout));
  if(xbee.available() > 0) {
    apiIdentifier = escapedByte();
    return apiIdentifier;
  }
  return 'N';
}

int getLocalAddress(int timeout) {
  int localAddress = 0;
  long startTime = millis();
  while(xbee.available() < 2 && ((millis() - startTime) < timeout));
  if(xbee.available() > 0) {
    int localAd = escapedByte();
    int localAd2 = escapedByte();
    localAddress = (localAd << 8) + localAd2;
    return localAddress;
  }
  return 0;
}

int[] getLongAddress(int timeout) {
  long startTime = millis();
  int addrByte = 'Z';
  while(xbee.available() < 8 && ((millis() - startTime) < timeout));
  if(xbee.available() > 0) {
    for(int i = 0; i < 8; i++) {
      addrByte = escapedByte();
      if(address != null) {
        address[i] = addrByte;
      }
    }
    return address;
  }
  return null;
}

int[] getInfo(int packetLength, int timeout) {
  long startTime = millis();
  while(xbee.available() < (packetLength - 12) && ((millis() - startTime) < timeout));
  if(xbee.available() > 0) {
    for(int i = 0; i < (packetLength - 12); i++) {
      if(dataIn != null) {
        dataIn[i] = escapedByte();
      }
    }
    return dataIn;
  }
  return null;
}

int getOptions(int timeout) {
  int options = 'Z';
  long startTime = millis();
  while(xbee.available() < 1 && ((millis() - startTime) < timeout));
  if(xbee.available() > 0) {
    options = escapedByte();
    return options;
  }
  return '0';
}

int escapedByte() {
  int outByte = 0;
  int inByte = xbee.read();
  if(inByte != 0x7D) {
    outByte = inByte;
  } else {
    outByte = xbee.read() ^ 0x20;
  }
  return outByte;
}

void write() {
  if(dataIn != null && address != null) {
  if(address[4] == dancer1Address[0] && address[5] == dancer1Address[1] &&
     address[6] == dancer1Address[2] && address[7] == dancer1Address[3]) {
    for(int i = 0; i < 19; i++) {
      dancer1.setLevel(i, dataIn[i]);
    }
  } else if(address[4] == dancer2Address[0] && address[5] == dancer2Address[1] &&
            address[6] == dancer2Address[2] && address[7] == dancer2Address[3]) {
    for(int i = 0; i < 19; i++) {
      dancer2.setLevel(i, dataIn[i]);
    }
  }
  }
}

class Dancer {
  boolean state[] = new boolean[26];
  int address[] = new int[26];
  int level[] = new int[26];
  
  Dancer() {
    for(int i = 0; i < 26; i++) {
      state[i] = false;
      address[i] = 0;
      level[i] = 0;
    }
    level[20] = 0;
    level[21] = 64;
    level[22] = 128;
    level[23] = 192;
    level[24] = 255;
    level[25] = 20;
  }
  
  void setState(int index, boolean value) {
    state[index] = value;
  }
  
  void setAddress(int index, int value) {
    address[index] = value;
  }
  
  void setLevel(int index, int value) {
    level[index] = value;
  }
  
  boolean getState(int index) {
    return state[index];
  }
  
  int getAddress(int index) {
    return address[index];
  }
  
  int getLevel(int index) {
    return level[index];
  }
}
  