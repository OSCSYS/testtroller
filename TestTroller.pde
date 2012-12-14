#define BUILD 997
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
#include "UI_LCD.h"

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

//Create the appropriate 'LCD' object for the hardware configuration (4-Bit GPIO, I2C)
#if defined UI_LCD_4BIT
  #include <LiquidCrystalFP.h>
  
  #ifndef UI_DISPLAY_SETUP
    LCD4Bit LCD(LCD_RS_PIN, LCD_ENABLE_PIN, LCD_DATA4_PIN, LCD_DATA5_PIN, LCD_DATA6_PIN, LCD_DATA7_PIN);
  #else
    LCD4Bit LCD(LCD_RS_PIN, LCD_ENABLE_PIN, LCD_DATA4_PIN, LCD_DATA5_PIN, LCD_DATA6_PIN, LCD_DATA7_PIN, LCD_BRIGHT_PIN, LCD_CONTRAST_PIN);
  #endif
  
#elif defined UI_LCD_I2C
  LCDI2C LCD(UI_LCD_I2CADDR);
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
  Serial.begin(115200);
  Serial.println("TestTroller");
  #if defined UI_I2C_LCD || defined TS_ONEWIRE_I2C
    Serial.println("I2C\tBegin");
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
  uiInit();
}


//**********************************************************************************
// Loop
//**********************************************************************************

void loop() {
  uiCore(); //Core UI Code (UI.pde). Note: updateLCD() called from brewCore()
  brewCore();
}

void brewCore() {
  #ifdef HEARTBEAT
    heartbeat();
  #endif
  LCD.update();
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
