#define BUILD 912
/*
   Copyright (C) 2009, 2010 Matt Reba, Jeremiah Dillingham

    This file is part of BrewTroller.

    BrewTroller is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    BrewTroller is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with BrewTroller.  If not, see <http://www.gnu.org/licenses/>.

TestTroller - Open Source Brewing Computer - Test Program
Software Lead: Matt Reba (matt_AT_brewtroller_DOT_com)
Hardware Lead: Jeremiah Dillingham (jeremiah_AT_brewtroller_DOT_com)

Documentation, Forums and more information available at http://www.brewtroller.com

Compiled on Arduino-0017 (http://arduino.cc/en/Main/Software)
With Sanguino Software v1.4 (http://code.google.com/p/sanguino/downloads/list)
using OneWire Library (http://www.arduino.cc/playground/Learning/OneWire)
*/


//*****************************************************************************************************************************
// BEGIN CODE
//*****************************************************************************************************************************
#include <avr/pgmspace.h>
#include <pin.h>
#include "HWProfile.h"
#include <Wire.h>
#include <menu.h>

//**********************************************************************************
// Compile Time Logic
//**********************************************************************************

#if defined(__AVR_ATmega1284P__) || defined(__AVR_ATmega1284__)
  #define EEPROM_BLOCK_SIZE 256
#else
  #define EEPROM_BLOCK_SIZE 128
#endif

//Heat Output Pin Array
#ifdef OUTPUT_GPIO
  pin gpioPin[OUT_GPIO_COUNT];
#endif


#ifdef OUTPUT_MUX
    pin muxLatchPin, muxDataPin, muxClockPin, muxENPin;
    unsigned long vlvBits;
#endif

#ifdef DIGITAL_INPUTS
  pin digitalInPin[DIGITALIN_COUNT];
  boolean triggers[DIGITALIN_COUNT];
  unsigned long trigReset;
#endif

#ifdef HEARTBEAT
  pin hbPin;
#endif

#ifdef ANALOG_INPUTS
  byte analogPinNum[ANALOGIN_COUNT] = ANALOGIN_PINS;
#endif

const char BT[] PROGMEM = "TestTroller";
const char BTVER[] PROGMEM = "2.0";

//**********************************************************************************
// Setup
//**********************************************************************************

void setup() {
  #if defined BTPD_SUPPORT || defined UI_I2C_LCD || defined TS_I2C_ONEWIRE
    Wire.begin();
  #endif
  
  //Pin initialization (Outputs.pde)
  pinInit();

  #ifdef DIGITAL_INPUTS
    //Digital Input Initialization (Events.pde)
    trigInit();
  #endif

  tempInit();
  
  //User Interface Initialization (UI.pde)
  #ifndef NOUI
    uiInit();
  #endif
}


//**********************************************************************************
// Loop
//**********************************************************************************

void loop() {
  #ifndef NOUI
    uiCore(); //Core UI Code (UI.pde). Note: updateLCD() called from brewCore()
  #endif

  brewCore();
}

void brewCore() {
  #ifdef HEARTBEAT
    heartbeat();
  #endif
  updateLCD();
}

#ifdef HEARTBEAT
unsigned long hbStart = 0;
void heartbeat() {
  if (millis() - hbStart > 750) {
    hbPin.toggle();
    hbStart = millis();
  }
}
#endif
