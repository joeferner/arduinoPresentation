
#include <SPI.h>
#include "microvga.h"

#define PIN_RDY 9

void MicroVga::init(int pinCS) {
  SPI.begin();
  _pinCS = pinCS;
  pinMode(_pinCS, OUTPUT);
  pinMode(PIN_RDY, INPUT);
  digitalWrite(_pinCS, HIGH);
}

void MicroVga::putch(char ch) {
  SPI.setDataMode(SPI_MODE1);
  SPI.setClockDivider(SPI_CLOCK_DIV4);
  digitalWrite(_pinCS, LOW);
  while(digitalRead(PIN_RDY) == HIGH);
  delayMicroseconds(100);
  SPI.transfer(ch);
  digitalWrite(_pinCS, HIGH);
}

void MicroVga::puts(const char* s) {
  while (*s != 0) { 
    putch(*s++);
  }
}

void MicroVga::clearScreen() {
  puts("\033[2J");
}

void MicroVga::cursorOn() {
  puts("\033[25h");
}

void MicroVga::cursorOff() {
  puts("\033[25l");
}

void MicroVga::gotoXY(uint8_t x, uint8_t y) {
  if (x > MAX_X || y > MAX_Y) {
    return;
  }

  x--;
  y--;

  putch(0x1B);
  putch('[');
  putch((y / 10) + '0');
  putch((y % 10) + '0');
  putch(';');
  putch((x / 10) + '0');
  putch((x % 10) + '0');
  putch('f');
}

void MicroVga::textColor(int color) {
  putch('\033');
  putch('[');
  if (color & 0x8) 
    putch('1');
  else 
    putch('2');
  putch('m');

  putch('\033');
  putch('[');
  putch('3');
  putch(((color & 0x7) % 10) + '0');
  putch('m');
}

void MicroVga::textBackground(int color) {
  putch('\033');
  putch('[');
  if (color & 0x8) 
    putch('5');
  else 
    putch('6');
  putch('m');

  putch('\033');
  putch('[');
  putch('4');
  putch((color & 0x7) + '0');
  putch('m');
}

void MicroVga::textAttr(int attr) {
  textColor(attr & 0xF);
  textBackground(attr >> 4);
}




