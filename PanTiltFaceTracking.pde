
import hypermedia.video.*;  //Include the video library to capture images from the webcam
import java.awt.Rectangle;  //A rectangle class which keeps track of the face coordinates.
import processing.serial.*; //The serial library is needed to communicate with the Arduino.
import java.awt.Point;
import java.awt.image.*;
import javax.imageio.*;
import java.io.*;

OpenCV opencv;  //Create an instance of the OpenCV library.


//Screen Size Parameters

//int width = 1280;
//int height = 960;

int width = 640;
int height = 480;

int videoScale = 8;

//number of columsn and rows
int cols,rows;

// contrast/brightness values
int contrast_value    = 0;
int brightness_value  = 0;

Serial port; // The serial port

//Variables for keeping track of the current servo positions.
char servoTiltPosition = 90;
char servoPanPosition = 90;

//The pan/tilt servo ids for the Arduino serial command interface.
char tiltChannel = 0;
char panChannel = 1;

char led = 3;
char led_on = 1;
char led_off = 0;

//These variables hold the x and y location for the middle of the detected face.
int midFaceY=0;
int midFaceX=0;

//The variables correspond to the middle of the screen, and will be compared to the midFace values
int midScreenY = (height/2);
int midScreenX = (width/2);
int midScreenWindow = 10;  //This is the acceptable 'error' for the center of the screen. 

//The degree of change that will be applied to the servo each time we update the position.
int stepSize=1;

//Fonts
PFont font;

//Create limit boundaries
int leftLimit = 5;
int rightLimit = 175;
int upLimit = 5;
int downLimit = 175;

//Value whether we have a face or not
boolean hasFace = false;

//create a memo for the face that we are tracking to limit false positives
int memoFaceX ;
int memoFaceY;

//Set threshold
int threshold = 80;

//Create image to save
PImage faceFound;
PImage tempFace;

void setup() {
  //Create a window for the sketch.
  size( width, height );
  cols = width/videoScale;
  rows = height/videoScale;
  
  

  font = createFont("Monospaced", 12);
  textFont(font);
  textAlign(CENTER, CENTER);

  //Set OpenCV
  opencv = new OpenCV( this );
  
  opencv.capture( width, height );                   // open video stream
  opencv.cascade( OpenCV.CASCADE_FRONTALFACE_ALT );  // load detection description, here-> front face detection : "haarcascade_frontalface_alt.xml"

  println("Welcome To The Face Finder");
  println(Serial.list()); // List COM-ports (Use this to figure out which port the Arduino is connected to)

  //select first com-port from the list (change the number in the [] if your sketch fails to connect to the Arduino)
  port = new Serial(this, Serial.list()[1], 57600);   //Baud rate is set to 57600 to match the Arduino baud rate.

  // print usage
 // println( "Drag mouse on X-axis inside this sketch window to change contrast" );
 // println( "Drag mouse on Y-axis inside this sketch window to change brightness" );
  
  //Send the initial pan/tilt angles to the Arduino to set the device up to look straight forward.
  port.write(tiltChannel);    //Send the Tilt Servo ID
  port.write(servoTiltPosition);  //Send the Tilt Position (currently 90 degrees)
  port.write(panChannel);         //Send the Pan Servo ID
  port.write(servoPanPosition);   //Send the Pan Position (currently 90 degrees)
  port.write(led);
  port.write(led_off);
}


public void stop() {
  opencv.stop();
  super.stop();
}



void draw() {
  background(0);
  

  
  // grab a new frame
  // and convert to gray
  opencv.read();
  opencv.convert( GRAY );
  opencv.contrast( contrast_value );
  opencv.brightness( brightness_value );

  // proceed detection
  hasFace = false;
  Rectangle[] faces = opencv.detect( 1.2, 2, OpenCV.HAAR_DO_CANNY_PRUNING, 40, 40 );
  
  // display the image
  image( opencv.image(), 0, 0 );
  
  

  
  // Begin loop for columns
  for (int i = 0; i < height/5; i++) {
    // Begin loop for rows
    for (int j = 0; j < width/5; j++) {
      
      // Scaling up to draw a rectangle at (x,y)
      int x = i*videoScale;
      int y = j*videoScale;
      noFill();
      stroke(0);
      // For every column and row, a rectangle is drawn at an (x,y) location scaled and sized by videoScale.
      rect(x+servoPanPosition-90,y+servoTiltPosition-90,videoScale,videoScale); 
    }
  }
  
  
  
  // draw face area(s)
  noFill();
  stroke(255,0,0);
  for( int i=0; i<faces.length; i++ ) {
    rect( faces[i].x, faces[i].y, faces[i].width, faces[i].height );
    //tempFace = opencv.image(faces[i].width, faces[i].height, ARGB);
    //tempFace = opencv.image();
    //tempFace.save("face.jpg");

  }
  
  
  //Find out if any faces were detected.
  if(faces.length > 0){
    hasFace = true;
    port.write(led);
    port.write(led_off);
    //If a face was found, find the midpoint of the first face in the frame.
    //NOTE: The .x and .y of the face rectangle corresponds to the upper left corner of the rectangle,
    //      so we manipulate these values to find the midpoint of the rectangle.
    midFaceY = faces[0].y + (faces[0].height/2);
    midFaceX = faces[0].x + (faces[0].width/2);
    
    int fX = midFaceX+(int)servoPanPosition-90;
    int fY = midFaceY+(int)servoTiltPosition-90;
     println("Face detected at " + fX + "," + fY );
     //if(midFaceY < 9){midFaceY = midFaceY - 48;}
     //if(midFaceX < 9){midFaceX = midFaceX - 48;}
     
     char y = (char)midFaceY;
     char x = (char)midFaceX;
     
  int centerX = midScreenX+(int)servoPanPosition-90;
  int centerY = midScreenY+(int)servoTiltPosition-90;
  
  text(centerX + "," + centerY , 320, 240);
  fill(255, 204, 0);
    
    //Find out if the Y component of the face is below the middle of the screen.
    if(midFaceY < (midScreenY - midScreenWindow)){
      if(servoTiltPosition >= 5)servoTiltPosition -= stepSize; //If it is below the middle of the screen, update the tilt position variable to lower the tilt servo.
    }
    //Find out if the Y component of the face is above the middle of the screen.
    else if(midFaceY > (midScreenY - midScreenWindow)){
      if(servoTiltPosition <= 175)servoTiltPosition += stepSize; //Update the tilt position variable to raise the tilt servo.
    }
    //Find out if the X component of the face is to the left of the middle of the screen.
    if(midFaceX < (midScreenX - midScreenWindow)){
      if(servoPanPosition >= 5)servoPanPosition += stepSize; //Update the pan position variable to move the servo to the left.
    }
    //Find out if the X component of the face is to the right of the middle of the screen.
    else if(midFaceX > (midScreenX + midScreenWindow)){
      if(servoPanPosition <= 175)servoPanPosition -= stepSize; //Update the pan position variable to move the servo to the right.
    }
  
  }
  else if(faces.length == 0){
  hasFace = false;    
  port.write(led);
  port.write(led_on);
   
  if(servoTiltPosition >= 120){servoTiltPosition += stepSize ;}      
  else if (servoTiltPosition <= 60){servoTiltPosition -= stepSize;}
      
  if(servoPanPosition >= 120){servoPanPosition -= stepSize;}
  else if(servoPanPosition <= 60){servoPanPosition += stepSize;}
      
    }  //(hasFace != true)
    
  //Update the servo positions by sending the serial command to the Arduino.
  port.write(tiltChannel);      //Send the tilt servo ID
  port.write(servoTiltPosition); //Send the updated tilt position.
  port.write(panChannel);        //Send the Pan servo ID
  port.write(servoPanPosition);  //Send the updated pan position.
  delay(1);

}



