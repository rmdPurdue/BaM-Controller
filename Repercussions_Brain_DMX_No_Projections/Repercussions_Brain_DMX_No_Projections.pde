// XBee API receipts built off of Justin Downs johnhenryhammer.com
import processing.serial.*;
import oscP5.*;
import netP5.*;
import dmxP512.*;
import controlP5.*;

DmxP512 dmxOutput;
int universeSize = 128;
boolean DMXPRO = true;
String DMXPRO_PORT = "COM22";
int DMXPRO_BAUDRATE = 115000;

/*****     Objects for OSC, UDP, CP5 connections    *****/
OscP5 oscP5;
NetAddress myRemoteLocation;
ControlP5 cp5;

/*****     Objects for XBee Communication        *****/
int apiIdentifier,localAddress,packetLength;
int[] address = new int[8];
int[] dataIn = new int[100];
int[] dancer1Address = new int[4];
int[] dancer2Address = new int[4];
int[] addressHigh = new int[4];
int options,checksum;
int frameID = 1;
int destination[] = {0x00, 0x13, 0xA2, 0x00, 0x40, 0xF9, 0x79, 0x0C}; //not needed
int[] payload = new int[0];
Serial xbee;

/*****     Objects to store data for each dancer *****/
Dancer dancer1, dancer2;
String d1StrAddr;

boolean fade = false;
int fadeCount = 0;

PFont dataFont, labelFont;

/*****   Initialize boolean for dancer MAC Address storage  *****/
  boolean enteredMacAddresses, recMacAddresses; 

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
  size(840,700);
  //fullScreen();
  background(0,0,0);

/*****   Initialize Dancer objects for storage  *****/
  dancer1 = new Dancer();
  dancer2 = new Dancer();
  
/*****   Initialize boolean for dancer MAC Address storage  *****/
  enteredMacAddresses = false;
  recMacAddresses = false;

/*****   Initialize OSC and network objects     *****/
  oscP5 = new OscP5(this, 8000);
  myRemoteLocation = new NetAddress("127.0.0.1", 8000);
  
/*****  Set up ControlP5 object   *****/
  cp5 = new ControlP5(this);

/*****   Set up serial ports for XBee           *****/
  String ports[] = Serial.list();
  int numPorts = ports.length;
  println(ports);
  if(numPorts < 1) {
    fill(0,0,0);
    textSize(14);
    text("No serial ports connected.",20,380);
  }
  //xbee = new Serial(this, "COM4", 9600);
  
  dataFont = loadFont("DS-Digital-Bold-48.vlw");
  labelFont = loadFont("Arial-BoldMT-48.vlw");
}

void draw() {
  if(!enteredMacAddresses) {
    //enter in mac addresses
    drawMacAddress();
    //String d1addrString = drawMacAddress();
    //println("recieved mac address in loop" + d1addrString);
    
    //if(recMacAddresses) {
      //for testing
      println("global var address string in loop: " + d1StrAddr);
      
      println("recieved mac address in loop" + dancer1.getStringAddr());
      
      //conversion will look something like this
      //dancer1.setMacAddress(hex2long(dancer1.getStringAddr()));
    //}
    enteredMacAddresses = true;
  }
  
  try {
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
  printOSC();
}

void oscEvent(OscMessage theOscMessage) {
  println("Got OSC Message.");
  println("### received an OSC message.");
  println("Address Pattern: "+theOscMessage.addrPattern());
  println("Typetag: "+theOscMessage.typetag());
  println("Timetag: "+theOscMessage.timetag());
}

/* 
  Adding in functionality for multiple dancers: 
  Given # of dancers, have the fields appear (or not appear)
  based on if that dancer # is valid. Use this link
  https://forum.processing.org/two/discussion/1576/controlp5-basic-example-text-input-field
  to create different fields per dancer.
*/

//String drawMacAddress() {
void drawMacAddress() {  // maybe this never exits
  stroke(0,0,0);
  fill(0,0,0);
  rect(0, 0, width, height);
  
  cp5.addTextfield("MAC_Address_1")
    .setPosition(20,100)
    .setSize(200,40)
    //.setFont(labelFont)
    .setFocus(true)
    .setColor(color(255,0,0))
    ;
  
  //cp5.addBang("Submit")
  //  .setPosition(240, 100)
  //  .setSize(80, 40)
  //  .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
  //  ;
  //text(cp5.get(Textfield.class,"MAC_Address").getText(), 360,130);
  //return cp5.get(Textfield.class,"MAC_Address").getText();
}

//void keyPressed() {
//  if (key==RETURN || key==ENTER) {
//    //try 2
//    d1StrAddr = cp5.get(Textfield.class,"MAC_Address_1").getText();
    
//    //ideal
//    dancer1.setStringAddr(cp5.get(Textfield.class,"MAC_Address_1").getText());
//    recMacAddresses = true;
//  }
//}  

//void Submit() {
//  //try 2
//  d1StrAddr = cp5.get(Textfield.class,"MAC_Address_1").getText();
  
//  //ideal
//  dancer1.setStringAddr(cp5.get(Textfield.class,"MAC_Address_1").getText());
//  recMacAddresses = true;
  
//  //repeat the following line for the different fields
//  //dancer1.setStringAddr(cp5.get(Textfield.class,"MAC_Address_1").getText());
//}

void MAC_Address_1(String theText) {
  // automatically receives results from controller input
  println("a textfield event for controller 'input' : "+theText);
  
  //try 2
  d1StrAddr = cp5.get(Textfield.class,"MAC_Address_1").getText();
    
  //ideal
  dancer1.setStringAddr(cp5.get(Textfield.class,"MAC_Address_1").getText());
  recMacAddresses = true;
}

long hex2long(String s) {
  String digits = "0123456789ABCDEF";
  s = s.toUpperCase();
  long val = 0;
  for (int i = 0; i < s.length(); i++) {
     char c = s.charAt(i);
     long d = digits.indexOf(c);
     val = 16*val + d;
   }
   return val;
}

void printOSC() {
  /* create an osc bundle */
  OscBundle myBundle = new OscBundle();
  
  ///* createa new osc message object */
  //OscMessage myMessage = new OscMessage("/test");
  //myMessage.add("abc");
  
  ///* add an osc message to the osc bundle */
  //myBundle.add(myMessage);
  
  //println(myMessage);
  
  ///* reset and clear the myMessage object for refill. */
  //myMessage.clear();
  
  ///* refill the osc message object again */
  //myMessage.setAddrPattern("/test2");
  //myMessage.add("defg");
  
  //for(int i = 1; i <= 2; i++) {
    int i = 2;
    OscMessage myMessage = messageBuilder(i, 3, 0);
    myMessage.add("hello");
    myBundle.add(myMessage);
    oscEvent(myMessage);
  //}
  
  //println(myMessage);
  
  //myBundle.setTimetag(myBundle.now() + 10000);
  /* send the osc bundle, containing 2 osc messages, to a remote location. */
  //oscP5.send(myBundle, myRemoteLocation);
}

OscMessage messageBuilder(int dancer, int location, int sensor) {
  String[] addressComponents = new String[3]; 
  
  switch(dancer) {
    case 1:
      addressComponents[0] = "/dancer1";
      break;
    case 2:
      addressComponents[0] = "/dancer2";
      break;
    //case 3:
    //  addressComponents[0] = "/dancer3";
    //  break;
    //case 4:
    //  addressComponents[0] = "/dancer4";
    //  break;
    //case 5:
    //  addressComponents[0] = "/dancer5";
    //  break;
    //case 6:
    //  addressComponents[0] = "/dancer6";
    //  break;
    //case 7:
    //  addressComponents[0] = "/dancer7";
    //  break;
    default:
      addressComponents[0] = "/unknown_dancer";
      break;
  }
  
  switch(location) {
    case 0:
      addressComponents[1] = "back";
      break;
    case 1:
      addressComponents[1] = "l_arm";
      break;
    case 2:
      addressComponents[1] = "r_arm";
      break;
    case 3:
      addressComponents[1] = "l_ankle";
      break;
    case 4:
      addressComponents[1] = "r_ankle";
      break;
    default:
      addressComponents[1] = "unknown_location";
      break;
  }
      
    switch(sensor) {
      case 0:
        addressComponents[2] = "gyro";
        break;
      case 1:
        addressComponents[2] = "accel";
        break;
      case 2:
        addressComponents[2] = "adc"; //change later, adc will have sub stream names
        break;
      default:
        addressComponents[2] = "unknown_sensor";
        break;     
  }
  //println(output); //convert myMessage to string
  
  String address = join(addressComponents, "/");
  OscMessage output = new OscMessage(address);
  return output;
}

void drawData() {
  stroke(0,0,0);
  fill(0,0,0);
  //rect(0,0,width,60);
  //rect(0,height-60,width,60);
  rect(0, 0, width, height);
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
  long macAddress;
  String addressString;
  
  Dancer() {
    for(int i = 0; i < 26; i++) {
      state[i] = false;
      address[i] = 0;
      macAddress = 0;
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
  
  void setMacAddress(long value) {
    macAddress = value;
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
  
  long getMacAddress() {
    return macAddress;
  }
  
  int getLevel(int index) {
    return level[index];
  }
  
  void setStringAddr(String addr) {
    addressString = addr;
  }
  
  String getStringAddr() {
    return addressString;
  }
}
  