//Clipboard, copy and paste related header file---
import java.awt.*;
import java.awt.event.*;
import java.awt.datatransfer.*;
import javax.swing.*;
import java.io.*;
//------------------------------------------------

//UI, textfields and knobs related header files---
import controlP5.*;//FOR UI STUFF
import g4p_controls.*;//for the text input stuff
//------------------------------------------------





//Contrast algo using luminance contrast
Boolean contrast(color color1, color color2, float RATIO) {

  float ratio;
  float L1 = 0.2126 * pow(red(color1)/255, 2.2) + 0.7152 * pow(green(color1)/255, 2.2) + 0.0722 * pow(blue(color1)/255, 2.2);
  float L2 = 0.2126 * pow(red(color2)/255, 2.2) + 0.7152 * pow(green(color2)/255, 2.2) + 0.0722 * pow(blue(color2)/255, 2.2);
  if (L1>=L2) {
    ratio=(L1+0.05) / (L2+0.05);
  } else {
    ratio=(L2+0.05) / (L1+0.05);
  }

  if (ratio>=RATIO) {
    return true;
  } else {
    return false;
  }
}

//picker class for handling color picking activity
public class Picker {
  public int x, y;

  public Picker(int x, int y) {
    set(x, y);

    noFill();
    stroke(#ffffff);
    ellipse(x, y, 5, 5);
    stroke(#000000);
    ellipse(x, y, 6, 6);
    noStroke();
  }

  public void set(int x, int y) {
    this.x=x;
    this.y=y;
  }

  public void put() {
    noFill();
    stroke(#ffffff);
    ellipse(x, y, 5, 5);
    stroke(#000000);
    ellipse(x, y, 6, 6);
    noStroke();
  }
}

//Colorspace class for handling the colorspace - displaying and redrawing
public class ColorSpace {
  //definition of the class

  //location variables & size - size will be on number as its always going to be a square ( atleast the main color space )
  public int x, y, SIZE;
  int barThickness = 30, gap = 20;
  public int selectedColor = 0;//this is actually the selected color on the side BAR, basically the hue.
  public int pickedColor = 0;//this is the color picked by the mouse in the color space
  public int outputColor = 0;


  Picker picker;

  //Direct draw image object for faster drawing :)
  PImage csImage, barImage;

  //Constructor
  public ColorSpace (int x, int y, int SIZE) {
    this.x = x;
    this.y = y;
    this.SIZE = SIZE;

    //Initiate the direct draw ojbect
    csImage = new PImage (SIZE, SIZE);
    barImage = new PImage (barThickness, SIZE);

    picker = new Picker (x, y);


    //set the color mode
    colorMode(HSB, SIZE);

    redrawColorSpace();
  }

  //overloading contructor for handling accessibility color space
  public ColorSpace (int x, int y, int SIZE, float cRatio) {
    this.x=x;
    this.y=y;
    this.SIZE=SIZE;

    //Initiate the direct draw ojbect
    csImage = new PImage (SIZE, SIZE);
    barImage = new PImage (barThickness, SIZE);

    picker = new Picker (x, y);

    //set the color mode
    colorMode(HSB, SIZE);

    redrawMaskedColorSpace(cRatio, 0);
  }

  public void redrawColorSpace() {
    colorMode(HSB, SIZE);
    //run a loop to set each pixel in the csImage object to the color values by varying S and B for a constant H of the selected color
    for ( int i=0; i<SIZE; i++) {
      for ( int j=0; j<SIZE; j++ ) {
        csImage.set(i, j, color(selectedColor, i, SIZE-j));
      }
    }
    image(csImage, x, y);

    //The color selector bar
    for (int i=0; i<SIZE; i++) {
      for (int j=0; j<barThickness; j++) {
        barImage.set(j, i, color(SIZE-i, SIZE, SIZE));
      }
    }
    image(barImage, x+SIZE+gap, y);

    //draw triangle pointers
    noStroke();
    fill(#ffffff);
    triangle(x+SIZE+gap-6, SIZE-selectedColor+3+y, x+SIZE+gap-6, SIZE-selectedColor-3+y, x+SIZE+gap, SIZE-selectedColor+y);

    mouseSelectColor();

    pick();
    picker.put();
    pickedColor=csImage.get(picker.x-x, picker.y-y);
    fill(pickedColor);

    rect(x, y+SIZE+20, 100, 50);
  }

  //redraw function, but with masked colors for accessibility
  public void redrawMaskedColorSpace(float cRatio, int pColor) {
    colorMode(HSB, SIZE);
    //run a loop to set each pixel in the csImage object to the color values by varying S and B for a constant H of the selected color
    for ( int i=0; i<SIZE; i++) {
      for ( int j=0; j<SIZE; j++ ) {
        if (contrast(color(selectedColor, i, SIZE-j), color(pColor), cRatio)) {
          //if ratio is fine, assign the color as before
          csImage.set(i, j, color(selectedColor, i, SIZE-j));
        } else {
          //else assign black
          csImage.set(i, j, color(random(40)));
          if (picker.x==this.x+i && picker.y==this.y+j) {
            //if picker is in the masked area then do the following...
            picker.x++;
            picker.y++;
            //picker.set(picker.x,picker.y);
            picker.put();
          }
        }
      }
    }
    image(csImage, x, y);

    //The color selector bar
    for (int i=0; i<SIZE; i++) {
      for (int j=0; j<barThickness; j++) {
        barImage.set(j, i, color(SIZE-i, SIZE, SIZE));
      }
    }
    image(barImage, x+SIZE+gap, y);

    //draw triangle pointers
    noStroke();
    fill(#ffffff);
    triangle(x+SIZE+gap-6, SIZE-selectedColor+3+y, x+SIZE+gap-6, SIZE-selectedColor-3+y, x+SIZE+gap, SIZE-selectedColor+y);

    mouseSelectColor();
    pick();

    picker.put();
    outputColor = csImage.get(picker.x-x, picker.y-y);
    fill(outputColor);    
    rect(x, y+SIZE+20, 100, 50);

    fill(#111111);
    stroke(#444444);
    rect(x+130, y+SIZE+20, 70, 20);
    fill(#999999);
    textSize(14);
    text("#", x+110, y+SIZE+35);
    textSize(12);
    text(hex(outputColor, 6), x+140, y+SIZE+35);
  }

  //function for selecting color from the color bar (HUE)----
  public void mouseSelectColor() {
    if (mousePressed 
      && mouseX>=x+SIZE+gap
      && mouseX<=x+SIZE+gap+barThickness
      && mouseY>=y
      && mouseY<=y+SIZE) {
      selectedColor = SIZE-mouseY+y;
    }
  }
  //---------------------------------------------------------


  //function for picking color from the color space (SAT, & BRIGHTNESS)----
  public void pick() {
    if (mousePressed
      && mouseX>=x
      && mouseX<x+SIZE
      && mouseY>=y
      && mouseY<=y+SIZE) {

      picker.set(mouseX, mouseY);
    }
  }
  //-----------------------------------------------------------------------
}



//The default program area -- >

ColorSpace fGround;
ColorSpace bGround;
PImage logo;
PFont font;

ControlP5 cp5;
Knob myKnobA;
GTextField bgInput;

void setup() {
  smooth();
  size ( 732, 465 ); 
  background(#333333);   

  font = loadFont("Verdana-48.vlw");
  textFont(font);

  logo = loadImage("logo_kntrst.jpg");

  bGround = new ColorSpace(20, 80, 256);
  fGround = new ColorSpace(406, 80, 256, 4.5);

  cp5 = new ControlP5(this);

  //knob for the contrast ratio control
  myKnobA = cp5.addKnob("contrast_ratio")
    .setRange(0.0, 20.0)
      .setValue(4.5)
        .setPosition(347, 180)
          .setRadius(20)
            .setColorForeground(#444444)
              .setColorBackground(#222222)
                .setDragDirection(Knob.VERTICAL)
                  .setDecimalPrecision(1)
                    ;

  //foreground input text box
  bgInput = new GTextField(this, bGround.x+130, bGround.y+bGround.SIZE+20, 70, 20);
  bgInput.tag = "fgInput";

  //bgInput.setPromptText("Text field 1");
  bgInput.setText("FFFFFF");  
  //bgInput.setFocus(true);




  //Copy Button --
  cp5.addButton("copy")
    .setValue(0)
      .setPosition(fGround.x+210, fGround.y+fGround.SIZE+20)
        .setSize(45, 20)
          .setColorBackground(#666666)
            ;
  //--------------
}

float contrastRatio=4.5;
void contrast_ratio(float theValue) {
  contrastRatio=theValue;
}

public void copy(int theValue) {
  String selection = hex(fGround.outputColor, 6);
  StringSelection data = new StringSelection(selection);
  Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
  clipboard.setContents(data, data);
}

void draw() {

  background(#333333);
  image(logo, 20, 20, logo.width/2, logo.height/2);
  fill(#999999);
  textSize(14);
  text("Background", 20, 70);
  text("Foreground (Accessible Colors)", 406, 70);
  textSize(14);
  text("#", bGround.x+110, bGround.y+bGround.SIZE+35);
  textSize(10);
  fill(#555555);
  text("(ctrl+v to paste)",bGround.x+130, bGround.y+bGround.SIZE+60);
  stroke(#444444);
  line(366, 80, 366, 160);
  line(366, 260, 366, 405);

  fill(#666666);
  textSize(10);
  text("KNTRST v1.0 A utility to help UI dsigners choose accessible colors based on WCAG 2.0 guidelines.", 20, 445);
  fill(#666666);
  text("©", 525, 445);
  fill(#111111);
  text("Written by Nithin Davis Nanthikkara", 540, 445);
  fGround.redrawMaskedColorSpace(contrastRatio, bGround.pickedColor);
  bGround.redrawColorSpace();

  //update the textField to display the selected color everytime the mouse is pressed----
  if (mousePressed) {
    bgInput.setText(hex(bGround.pickedColor, 6));
  }
  //-------------------------------------------------------------------------------------


  //bGround.pickedColor=unhex("FF" + fgInput.getText().substring(0));
  //println(unhex("FF" + fgInput.getText().substring(0)));
}
public void handleTextEvents(GEditableTextControl textControl, GEvent event) { 

  switch(event) {
  case ENTERED:
    //set the pointer the type color
    bGround.selectedColor=int(hue(unhex(bgInput.getText())));
    bGround.picker.set(bGround.x+int(saturation(unhex(bgInput.getText()))), bGround.y+bGround.SIZE-int(brightness(unhex(bgInput.getText()))));
    break;
  }
}
