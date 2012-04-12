
#include <wiring.h>
#include "button.h"

void Button::attach(unsigned char pin) {
  _pin = pin;
  pinMode(_pin, INPUT);
}

int Button::isPressed() {
  unsigned char state = digitalRead(_pin);
  if(state == HIGH) {
    if(!_isCleared) {
      if(_lastState == LOW) {
        _highStartTime = millis();
      }
      if(millis() - _highStartTime > 100) {
        _isPressed = 1;
      }
    }
  }
  else if(state == LOW) {
    _isPressed = 0;
    _isCleared = 0;
  }
  _lastState = state;

  return _isPressed;
}

int Button::clearPressed() {
  _isPressed = 0;
  _isCleared = 1;
}



