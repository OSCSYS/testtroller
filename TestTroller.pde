#define BUILD 685
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
#include "Config.h"
#include "Enum.h"
#include <pin.h>

//**********************************************************************************
// Compile Time Logic
//**********************************************************************************

// Disable On board pump/valve outputs for BT Board 3.0 and older boards using steam
// Set MUXBOARDS 0 for boards without on board or MUX Pump/valve outputs
#if (defined BTBOARD_3 || defined BTBOARD_4) && !defined MUXBOARDS
  #define MUXBOARDS 2
#endif

#if !defined BTBOARD_3 && !defined BTBOARD_4 && !defined USESTEAM && !defined MUXBOARDS
  #define ONBOARDPV
#else
  #if !defined MUXBOARDS
    #define MUXBOARDS 0
  #endif
#endif

//Enable Serial on BTBOARD_22+ boards or if DEBUG is set
#if !defined BTBOARD_1
  #define USESERIAL
#endif

//Enable Mash Avergaing Logic if any Mash_AVG_AUXx options were enabled
#if defined MASH_AVG_AUX1 || defined MASH_AVG_AUX2 || defined MASH_AVG_AUX3
  #define MASH_AVG
#endif

//Use I2C LCD for BTBoard_4
#ifdef BTBOARD_4
  #define UI_LCD_I2C
  #define HEARTBEAT
  #define TRIGGERS
#endif

//Select OneWire Comm Type
#ifdef TS_ONEWIRE
  #ifdef BTBOARD_4
    #define TS_ONEWIRE_I2C //BTBOARD_4 uses I2C if OneWire support is used
  #else
    #ifndef TS_ONEWIRE_I2C
      #define TS_ONEWIRE_GPIO //Previous boards use GPIO unless explicitly configured for I2C
    #endif
  #endif
#endif

#if defined(__AVR_ATmega1284P__) || defined(__AVR_ATmega1284__)
  #define EEPROM_BLOCK_SIZE 256
#else
  #define EEPROM_BLOCK_SIZE 128
#endif

//Heat Output Pin Array
pin heatPin[4], alarmPin;

#ifdef ONBOARDPV
  pin valvePin[11];
#endif

#if MUXBOARDS > 0
  pin muxLatchPin, muxDataPin, muxClockPin;
  #ifdef BTBOARD_4
    pin muxMRPin;
  #else
    pin muxOEPin;
  #endif
#endif

#ifdef BTBOARD_4
  pin digInPin[6];
  pin hbPin;
#endif

//Volume Sensor Pin Array
byte vSensor[3] = { HLTVOL_APIN, MASHVOL_APIN, KETTLEVOL_APIN};

//Shared buffers
char buf[20];

unsigned long vlvBits;

const char BT[] PROGMEM = "TestTroller";
const char BTVER[] PROGMEM = "2.0";


boolean triggers[5];

//**********************************************************************************
// Setup
//**********************************************************************************

void setup() {
  #if defined BTPD_SUPPORT || defined UI_I2C_LCD || defined TS_I2C_ONEWIRE
    Wire.begin();
  #endif
  
  //Pin initialization (Outputs.pde)
  pinInit();

#ifdef TRIGGERS
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
