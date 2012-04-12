#include <SPI.h>
#include <SdFat.h>
#include <SdFatUtil.h>
#include <Servo.h>
#include <stdlib.h>
#include "button.h"
#include "microvga.h"

#define A0 0
#define A1 1

#define PinLed         3
#define PinSdCardCS    4
#define PinNext        5
#define PinPrev        6
#define PinServo       7
#define PinMicroVgaCS  8
#define PinEthernetCS 10
#define PinLight      A0
#define PinTemp       A1

typedef void (*SlideInitFunc)();
typedef void (*SlideLoopFunc)();

struct Slide {
  SlideInitFunc init;
  SlideLoopFunc loop;
};

#define SLIDE_COUNT 10
int g_slide;
Slide g_slides[SLIDE_COUNT] = {
  { 
    slide00Init, slide00
  }
  ,
  { 
    slide01Init, slide01
  }
  ,
  { 
    slide02Init, slide02
  }
  ,
  { 
    slide03Init, slide03
  }
  ,
  { 
    slide04Init, slide04
  }
  ,
  { 
    slide05Init, slide05
  }
  ,
  { 
    slide06Init, slide06
  }
  ,
  { 
    slide07Init, slide07
  }
  ,
  { 
    slide08Init, slide08
  }
  ,
  { 
    slide09Init, slide09
  }
};

Button g_buttonNext, g_buttonPrev;
Servo g_servo;
Sd2Card g_sdCard;
SdVolume g_sdVolume;
SdFile g_sdRoot;
MicroVga g_vga;
unsigned long g_lastTempUpdate;
unsigned long g_startTime;

void setup() {
  Serial.begin(19200);
  pinMode(PinLed, OUTPUT);
  g_buttonNext.attach(PinNext);
  g_buttonPrev.attach(PinPrev);
  g_servo.attach(PinServo);

  g_vga.init(PinMicroVgaCS);

  pinMode(PinEthernetCS, OUTPUT);
  digitalWrite(PinEthernetCS, HIGH);
  g_sdCard.init(SPI_HALF_SPEED, PinSdCardCS);
  g_sdVolume.init(&g_sdCard);
  g_sdRoot.openRoot(&g_sdVolume);

  g_lastTempUpdate = millis();
  g_slide = 0;
  g_slides[g_slide].init();
}

void nextSlide() {
  if(g_slide >= SLIDE_COUNT - 1) {
    return;
  }
  g_slide++;
  g_slides[g_slide].init();
}

void prevSlide() {
  if(g_slide <= 0) {
    return;
  }
  g_slide--;
  g_slides[g_slide].init();
}

void loop() {
  g_slides[g_slide].loop();

  if(millis() - g_lastTempUpdate > 100) {
    char str[10];

    float temp = readTemp();
    //Serial.println(temp);
    g_vga.gotoXY(74, 1);
    dtostrf(temp, 2, 1, str);
    g_vga.puts(str);
    g_vga.putch(167); // degrees

    g_vga.gotoXY(63, 1);
    if(g_startTime > 0) {
      unsigned long time = (millis() - g_startTime) / 1000;
      int minutes = time / 60;
      int seconds = time % 60;
      itoa(minutes, str, 10);
      g_vga.puts(str);
      g_vga.putch(':');
      itoa(seconds, str, 10);
      if(strlen(str) == 1) {
        g_vga.putch('0');
      }
      g_vga.puts(str);
    }
    else {
      g_vga.puts("00:00");
    }

    g_lastTempUpdate = millis();
  }

  if(g_buttonNext.isPressed()) {
    g_buttonNext.clearPressed();
    nextSlide();
  }
  if(g_buttonPrev.isPressed()) {
    g_buttonPrev.clearPressed();
    prevSlide();
  }
}

float readTemp() {
  float rawVal = analogRead(PinTemp);
  float val = rawVal / 10.65;
  return val;
}

void loadSlide(const char* fileName) {
  SdFile file;

  if(!file.open(&g_sdRoot, fileName, O_READ)) {
    Serial.print("Failed to open: ");
    Serial.println(fileName);
    return;
  }

  Serial.println("BEGIN");
  g_vga.clearScreen();
  g_vga.cursorOff();
  int16_t n;
  uint8_t buf[50];
  while ((n = file.read(buf, sizeof(buf))) > 0) {
    for(uint8_t i = 0; i < n; i++) {
      Serial.print(buf[i]);
      g_vga.putch(buf[i]);
    }
  }
  Serial.println();
  Serial.println("END");
}

/************************ slide 0: before start ********************/
void slide00Init() {
  g_startTime = 0;
  Serial.println("0: before start");
  g_vga.clearScreen();
}

void slide00() {
}

/************************ slide 1: intro ***************************/
void slide01Init() {
  g_startTime = millis();
  Serial.println("1: intro");
  loadSlide("slide01.ans");
}

void slide01() {
}

/************************ slide 2: microcontrollers ****************/
void slide02Init() {
  Serial.println("2: microcontrollers");
  loadSlide("slide02.ans");
}

void slide02() {
}

/************************ slide 3: arduino *************************/
void slide03Init() {
  Serial.println("slide 3: arduino");
  loadSlide("slide03.ans");
}

void slide03() {
}

/************************ slide 4: uno ******************************/
void slide04Init() {
  Serial.println("slide 4: uno");
  loadSlide("slide04.ans");
}

void slide04() {
}

/************************ slide 5: blink ***************************/
unsigned long g_lastBlinkTime;
unsigned long g_lastBlinkState;

void slide05Init() {
  Serial.println("slide 5: blink");
  loadSlide("slide05.ans");
  g_lastBlinkTime = millis();
  g_lastBlinkState = LOW;
}

void slide05() {
  unsigned long time = millis();
  if(time - g_lastBlinkTime > 500) {
    g_lastBlinkState = g_lastBlinkState == LOW ? HIGH : LOW;
    digitalWrite(PinLed, g_lastBlinkState);
    g_vga.gotoXY(21, 9);
    g_vga.puts(g_lastBlinkState == HIGH ? "ON " : "OFF");
    g_lastBlinkTime = time;
  }
}

/************************ slide 6: fade ****************************/
unsigned long g_fadeDirection;
unsigned long g_lastFadeTime;
int g_fadeVal;

void slide06Init() {
  Serial.println("slide 6: fade");
  loadSlide("slide06.ans");
  g_fadeDirection = 1;
  g_fadeVal = 0;
}

void slide06() {
  unsigned long time = millis();
  if(time - g_lastFadeTime > 10) {
    g_fadeVal += g_fadeDirection;
    if(g_fadeVal > 200) {
      g_fadeDirection = -1;
    }
    if(g_fadeVal < 1) {
      g_fadeDirection = 1;
    }
    char str[10];
    g_vga.gotoXY(21, 9);
    itoa(g_fadeVal, str, 10);
    g_vga.puts(str);
    g_vga.puts("   ");
    analogWrite(PinLed, g_fadeVal);
    g_lastFadeTime = time;
  }
}

/************************ slide 7: light sensor ********************/
unsigned long g_lastLightSensorInput;

void slide07Init() {
  Serial.println("slide 7: light sensor");
  loadSlide("slide07.ans");
  g_lastLightSensorInput = millis();
}

void slide07() {
  unsigned long time = millis();
  if(time - g_lastLightSensorInput > 100) {
    int val = analogRead(PinLight);
    Serial.println(val);

    char temp[10];
    g_vga.gotoXY(18, 22);
    itoa(val, temp, 10);
    g_vga.puts(temp);
    g_vga.puts("   ");

    g_lastLightSensorInput = time;
  }
}

/************************ slide 8: light sensor w/servo ************/
int g_lastServoPos;

void slide08Init() {
  Serial.println("slide 8: light sensor w/servo");
  loadSlide("slide08.ans");
  g_lastServoPos = 0;
}

void slide08() {
  int val = analogRead(PinLight);

  char temp[10];
  g_vga.gotoXY(18, 22);
  itoa(val, temp, 10);
  g_vga.puts(temp);
  g_vga.puts("   ");

  g_lastServoPos = (g_lastServoPos * 0.9) + (constrain(map(val, 500, 800, 0, 170), 0, 170) * 0.1);
  g_servo.write(g_lastServoPos);
}

/************************ slide 9: end ********************/
void slide09Init() {
  Serial.println("slide 9: end");
  loadSlide("slide09.ans");
}

void slide09() {
}




