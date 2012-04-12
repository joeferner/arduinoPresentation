
#ifndef _button_h_
#define _button_h_

class Button {
public:
  void attach(unsigned char pin); 
  int isPressed();
  int clearPressed();

private:
  unsigned char _pin;
  unsigned char _isPressed;
  unsigned char _isCleared;
  unsigned long _highStartTime;
  unsigned char _lastState;
};

#endif

