// import libraries
import java.awt.Frame;
import java.awt.BorderLayout;
import controlP5.*; // http://www.sojamo.de/libraries/controlP5/
import processing.serial.*;

/* SETTINGS BEGIN */

// Serial port to connect to
String serialPortName = "/dev/ttyUSB1";

// If you want to debug the plotter without using a real serial port set this to true
boolean mockupSerial = false;

/* SETTINGS END */

Serial serialPort; // Serial port object

// interface stuff
ControlP5 cp5;

// Settings for the plotter are saved in this file
JSONObject plotterConfigJSON;

//max capacity of input buffer
int le_in_buf = 3000;

// plots
int graphWidth = 1200;
Graph LineGraph = new Graph(200, 150, graphWidth, 450, color (20, 20, 200));
int maxSize = 1000;
int frameSize = 150;
float[][] lineGraphValues = new float[6][maxSize];
float[][] currentDraw = new float[6][frameSize];
float[] lineGraphSampleNumbers = new float[frameSize];
color[] graphColors = new color[6];

// helper for saving the executing path
String topSketchPath = "";

//slider
int sliderTicks2 = maxSize;
int lastSave = sliderTicks2;
void setup() {
  frame.setTitle("Realtime plotter - AKA");
  size(1500, 860);

  // set line graph colors
  graphColors[0] = color(62, 12, 232);//blue  
  graphColors[1] = color(200, 46, 232);//violet 
  graphColors[2] = color(255, 0, 0); //red
  //graphColors[3] = color(131, 255, 20);//green 
  graphColors[3] = color(0,0,0);//black
  graphColors[4] = color(13, 255, 0);//cian
  graphColors[5] = color(232, 158, 12);//orange

  // settings save file
  topSketchPath = sketchPath();
  plotterConfigJSON = loadJSONObject(topSketchPath+"/plotter_config.json");

  // gui
  cp5 = new ControlP5(this);
  
  // init charts
  setChartSettings();
  // build x axis values for the line graph
  for (int i=0; i<lineGraphSampleNumbers.length; i++) {  
        lineGraphSampleNumbers[i] = i;
  }
  
  // start serial communication
  if (!mockupSerial) {
    //String serialPortName = Serial.list()[3];
    serialPort = new Serial(this, serialPortName, 115200);
  }
  else
    serialPort = null;

  // build the gui
  int x = 400;
  int y = 0;
  
  //cp5.addTextlabel("multipliers").setText("multipliers").setPosition(x-80, y).setColor(0);
  //cp5.addtext(nf(mouseX)+":"+nf(mouseY), 150, 650);
  cp5.addToggle("lgVisible1").setPosition(x-180, y=y+40).setValue(int(getPlotterConfigString("lgVisible1"))).setMode(ControlP5.SWITCH).setColorActive(graphColors[0]);
  cp5.addTextfield("lgMultiplier1").setPosition(x-120, y).setText(getPlotterConfigString("lgMultiplier1")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  cp5.addToggle("lgVisible2").setPosition(x-180, y=y+40).setValue(int(getPlotterConfigString("lgVisible2"))).setMode(ControlP5.SWITCH).setColorActive(graphColors[1]);  
  cp5.addTextfield("lgMultiplier2").setPosition(x-120, y).setText(getPlotterConfigString("lgMultiplier2")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  cp5.addToggle("lgVisible3").setPosition(x-180, y=y+40).setValue(int(getPlotterConfigString("lgVisible3"))).setMode(ControlP5.SWITCH).setColorActive(graphColors[2]);
  cp5.addTextfield("lgMultiplier3").setPosition(x-120, y).setText(getPlotterConfigString("lgMultiplier3")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  
  cp5.addToggle("lgVisible4").setPosition(x+30, y=40).setValue(int(getPlotterConfigString("lgVisible4"))).setMode(ControlP5.SWITCH).setColorActive(graphColors[3]);  
  cp5.addTextfield("lgMultiplier4").setPosition(x+90, y).setText(getPlotterConfigString("lgMultiplier4")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  cp5.addToggle("lgVisible5").setPosition(x+30, y=y+40).setValue(int(getPlotterConfigString("lgVisible5"))).setMode(ControlP5.SWITCH).setColorActive(graphColors[4]);
  cp5.addTextfield("lgMultiplier5").setPosition(x+90, y).setText(getPlotterConfigString("lgMultiplier5")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  cp5.addToggle("lgVisible6").setPosition(x+30, y=y+40).setValue(int(getPlotterConfigString("lgVisible6"))).setMode(ControlP5.SWITCH).setColorActive(graphColors[5]);
  cp5.addTextfield("lgMultiplier6").setPosition(x+90, y).setText(getPlotterConfigString("lgMultiplier6")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  
  //for PID parameter 
  cp5.addTextfield("angle-PID KP").setPosition(x+550, y=40).setText(getPlotterConfigString("angle-PID KP")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  cp5.addTextfield("angle-PID KI").setPosition(x+550, y=80).setText(getPlotterConfigString("angle-PID KI")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  cp5.addTextfield("angle-PID KD").setPosition(x+550, y=120).setText(getPlotterConfigString("angle-PID KD")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  
  //set max and min value
  //cp5.addTextlabel("label").setText("on/off").setPosition(x, y+40).setColor(0);
  //cp5.addTextfield("lgMaxY").setPosition(x, y+50).setText(getPlotterConfigString("lgMaxY")).setWidth(40).setAutoClear(false);
  //cp5.addTextfield("lgMinY").setPosition(x, y+200).setText(getPlotterConfigString("lgMinY")).setWidth(40).setAutoClear(false);
  
  //Slider
  cp5.addSlider("sliderTicks2").setPosition(200,700).setSize(graphWidth,50).setRange(1,maxSize) // values can range from big to small as well
   .setValue(maxSize)
   //.setNumberOfTickMarks(maxSize)
   .setSliderMode(Slider.FLEXIBLE)
   .showTickMarks(false)
   .setSliderBarSize(50)
   ;
   
   Textlabel myTextlabelA = cp5.addTextlabel("slide_text")
                    .setText("Slide left to see past values, slide to the right-most to continue update")
                    .setPosition(400,760)
                    .setColorValue(0)
                    .setFont(createFont("Georgia",20))
                    ;
   myTextlabelA.draw(this);
   
  background(255);
  
}

byte[] inBuffer = new byte[le_in_buf]; // holds serial message
int i = 0; // loop variable
void draw() {
  /* Read serial and update values */
  if (mockupSerial || serialPort.available() > 0) {
    String myString = "";
    if (!mockupSerial) {
      
      try {
        serialPort.readBytesUntil('\r', inBuffer);
      }
      catch (Exception e) {
      }
      myString = new String(inBuffer);
    }
    else {
      
      myString = mockupSerialFunction();
    }

    //println(myString);

    // split the string at delimiter (space)
    String[] nums = split(myString, ' ');


    int numberOfInvisibleLineGraphs = 0;
    for (i=0; i<6; i++) {
      if (int(getPlotterConfigString("lgVisible"+(i+1))) == 0) {
        numberOfInvisibleLineGraphs++;
      }
    }

    // build the arrays for line graphs
    for (i=0; i<nums.length; i++) {
      // update line graph
      try {
        if (i<lineGraphValues.length && sliderTicks2 == maxSize) {
          
          for (int k=0; k<lineGraphValues[i].length-1; k++) {            
            lineGraphValues[i][k] = lineGraphValues[i][k+1];//First shift value to the left and...
          }
          //...and update the last value to memory lineGraphValues(maximum capacity is "maxSize") here, that makes an effect of the graph is updating
          lineGraphValues[i][lineGraphValues[i].length-1] = float(nums[i])*float(getPlotterConfigString("lgMultiplier"+(i+1)));
        }
      }
      catch (Exception e) {
      }
    }
  }
  
  background(255);//this command clears everything to update the new plot
  LineGraph.DrawAxis();//then after clearing we need to draw the axises again
  for (int i=0;i<lineGraphValues.length; i++) {//run through 6 line input data
    if (int(getPlotterConfigString("lgVisible"+(i+1))) == 1){ //if that line is invisible
      LineGraph.GraphColor = graphColors[i];//get color first
      /*this deals with scrollable, 
      job: update the current frame(currentDraw). Or save the data from linegraphsValues(size 1000) to currentDraw data(size 150)
      Condition:
      (1) (sliderTick2>lineGraphSampleNumbers.length+1 because frame size is 150, it means the very first frame starts from 0 to 99; in another word, if the slider position less than 100 means it is the first data frame. No more scrolling
      (2) (sliderTicks2 != lastSave) means user scrolls backward the past, or in another words, the position of sliderTicks2 has changed. lastSave parameter saved the last position of slider
      (3) (sliderTicks2 == maxSize) means if the slider is at position 1000 -> continue to update      
      */
   //print(parameter+" ");
      
      if(sliderTicks2>lineGraphSampleNumbers.length+1 && sliderTicks2 != lastSave || sliderTicks2 == maxSize){        
        for (int k=sliderTicks2-1,kk=lineGraphSampleNumbers.length-1; k>(sliderTicks2-lineGraphSampleNumbers.length-1); k--,kk--) {            
          currentDraw[i][kk] = lineGraphValues[i][k];//coppy value from a part of lineGraphvalues(length is "maxSize") to currentDraw(length is "frameSize")
        }
      }
      LineGraph.LineGraph(lineGraphSampleNumbers, currentDraw[i],float(getPlotterConfigString("lgMultiplier"+(i+1))));//parse the lgMultiplier to lineGraph method to display the real value of data //<>//
    }
  }
  lastSave = sliderTicks2;//save the last SliderTicks2 position after update all visible lines
}

// called each time the chart settings are changed by the user 
void setChartSettings() {
  LineGraph.xLabel=" Samples axis, not time axis";
  LineGraph.yLabel="Value - magnitude";
  LineGraph.Title="PID tuning";  
  LineGraph.xDiv=int (frameSize/LineGraph.xDiv);  
  LineGraph.xMax=frameSize; 
  LineGraph.xMin=0;  
  LineGraph.yMax=int(getPlotterConfigString("lgMaxY")); 
  LineGraph.yMin=int(getPlotterConfigString("lgMinY"));
}

// handle gui actions
void controlEvent(ControlEvent theEvent) {
  if (theEvent.isAssignableFrom(Textfield.class) || theEvent.isAssignableFrom(Toggle.class) || theEvent.isAssignableFrom(Button.class)) {
    String parameter = theEvent.getName();
    String value = "";
    if (theEvent.isAssignableFrom(Textfield.class))
      value = theEvent.getStringValue();
    else if (theEvent.isAssignableFrom(Toggle.class) || theEvent.isAssignableFrom(Button.class))
      value = theEvent.getValue()+"";
    //print(parameter+" ");
    //println(value);
    plotterConfigJSON.setString(parameter, value);
    saveJSONObject(plotterConfigJSON, topSketchPath+"/plotter_config.json");
    sendData2MCU(parameter, value);
  }
  setChartSettings();
}
void sendData2MCU(String parameter, String value){
     if (!mockupSerial) {
     print("set "+parameter+" "+value+";\n");
     if(parameter == "angle-PID KP"){
       serialPort.write(value);
       serialPort.clear();
     }else if(parameter == "angle-PID KI"){
       serialPort.write(value);
       serialPort.clear();
     }else if(parameter == "angle-PID KD"){
       serialPort.write(value);
       serialPort.clear();
     }
    }
}
// get gui settings from settings file
String getPlotterConfigString(String id) {
  String r = "";
  try {
    r = plotterConfigJSON.getString(id);
  } 
  catch (Exception e) {
    r = "";
  }
  return r;
}