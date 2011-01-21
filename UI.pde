/*
   Copyright (C) 2009, 2010 Matt Reba, Jermeiah Dillingham

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

#include "Config.h"
#include "Enum.h"
#include <encoder2.h>
#include <EEPROM.h>

//*****************************************************************************************************************************
// UI COMPILE OPTIONS
//*****************************************************************************************************************************

//**********************************************************************************
// ENCODER TYPE
//**********************************************************************************
// You must uncomment one and only one of the following ENCODER_ definitions
// Use ENCODER_ALPS for ALPS and Panasonic Encoders
// Use ENCODER_CUI for older CUI encoders
//
#define ENCODER_TYPE ALPS
//#define ENCODER_TYPE CUI
//**********************************************************************************

//*****************************************************************************************************************************
// Begin UI Code
//*****************************************************************************************************************************


//**********************************************************************************
// UI Definitions
//**********************************************************************************
#define SCREEN_LCD 0
#define SCREEN_EEPROM 1
#define SCREEN_OUTPUTS 2
#define SCREEN_ONEWIRE 3
#define SCREEN_VOLUME 4
#define SCREEN_TIMER 5
#define SCREEN_MANUALPV 6
#define SCREEN_COMPLETE 7

#define SCREEN_MIN SCREEN_LCD
#define SCREEN_MAX SCREEN_COMPLETE

//**********************************************************************************
// UI Custom LCD Chars
//**********************************************************************************
const byte CHARFIELD[] PROGMEM = {B11111, B00000, B00000, B00000, B00000, B00000, B00000, B00000};
const byte CHARCURSOR[] PROGMEM = {B11111, B11111, B00000, B00000, B00000, B00000, B00000, B00000};
const byte CHARSEL[] PROGMEM = {B10001, B11111, B00000, B00000, B00000, B00000, B00000, B00000};
const byte BMP0[] PROGMEM = {B00000, B00000, B00000, B00000, B00011, B01111, B11111, B11111};
const byte BMP1[] PROGMEM = {B00000, B00000, B00000, B00000, B11100, B11110, B11111, B11111};
const byte BMP2[] PROGMEM = {B00001, B00011, B00111, B01111, B00001, B00011, B01111, B11111};
const byte BMP3[] PROGMEM = {B11111, B11111, B10001, B00011, B01111, B11111, B11111, B11111};
const byte BMP4[] PROGMEM = {B01111, B01110, B01100, B00001, B01111, B00111, B00011, B11101};
const byte BMP5[] PROGMEM = {B11111, B00111, B00111, B11111, B11111, B11111, B11110, B11001};
const byte BMP6[] PROGMEM = {B11111, B11111, B11110, B11101, B11011, B00111, B11111, B11111};
const byte UNLOCK_ICON[] PROGMEM = {B00110, B01001, B01001, B01000, B01111, B01111, B01111, B00000};
const byte PROG_ICON[] PROGMEM = {B00001, B11101, B10101, B11101, B10001, B10001, B00001, B11111};
const byte BELL[] PROGMEM = {B00100, B01110, B01110, B01110, B11111, B00000, B00100, B00000};
const byte CHK[] PROGMEM = {B00001, B00001, B00010, B00010, B10100, B10100, B01000, B01000};

//**********************************************************************************
// UI Globals
//**********************************************************************************
byte activeScreen;
boolean screenLock;
unsigned long timerLastPrint;

byte addr[8];
unsigned long convertTime;
unsigned long lastRead;

//**********************************************************************************
// uiInit:  One time intialization of all UI logic
//**********************************************************************************
void uiInit() {
  initLCD();
  lcdSetCustChar_P(7, UNLOCK_ICON);
  #ifdef BTBOARD_4
    Encoder.begin(ENCODER_TYPE, false, ENTER_PIN, ENCA_PIN, ENCB_PIN);
  #else
    Encoder.begin(ENCODER_TYPE, false, ENTER_PIN, ENCA_PIN, ENCB_PIN, ENTER_INT, ENCA_INT);
  #endif
  
  activeScreen = SCREEN_MIN;
  screenInit(activeScreen);
  unlockUI();
}

//**********************************************************************************
// unlockUI:  Unlock active screen to select another
//**********************************************************************************
void unlockUI() {
  Encoder.setMin(SCREEN_MIN);
  Encoder.setMax(SCREEN_MAX);
  Encoder.setCount(activeScreen);
  screenLock = 0;
  //Reinit screen to show unlock icon hide parts not visible while locked
  screenInit(activeScreen);
}

void lockUI() {
  screenLock = 1;
  //Recall screenInit to setup encoder and other functions available only when locked
  screenInit(activeScreen);
}

//**********************************************************************************
// screenCore: Called in main loop to handle all UI functions
//**********************************************************************************
void uiCore() {
  if (!screenLock) {
    int encValue = Encoder.change();
    if (encValue >= 0) {
      activeScreen = encValue;
      screenInit(activeScreen);
    }
  }
  screenEnter(activeScreen);
  screenRefresh(activeScreen);
}

//**********************************************************************************
// screenInit: Initialize active screen
//**********************************************************************************
void screenInit(byte screen) {
  clearLCD();
  
  if (screen == SCREEN_LCD) {
    //Screen Init: Home
    lcdSetCustChar_P(0, BMP0);
    lcdSetCustChar_P(1, BMP1);
    lcdSetCustChar_P(2, BMP2);
    lcdSetCustChar_P(3, BMP3);
    lcdSetCustChar_P(4, BMP4);
    lcdSetCustChar_P(5, BMP5);
    lcdSetCustChar_P(6, BMP6);
    printLCD_P(3, 0, PSTR("Test   /  : LCD"));
    printLCDLPad(3, 5, itoa(screen + 1, buf, 10), 2, '0');
    printLCDLPad(3, 8, itoa(SCREEN_MAX, buf, 10), 2, '0');
  
    for (byte pos = 0; pos < 3; pos++) printLCD_P(pos, 0, PSTR(">"));
    for (byte pos = 0; pos < 3; pos++) printLCD_P(pos, 19, PSTR("<"));
    for (byte pos = 1; pos < 19; pos = pos + 3) {
      lcdWriteCustChar(0, pos + 1, 0);
      lcdWriteCustChar(0, pos + 2, 1);
      lcdWriteCustChar(1, pos, 2); 
      lcdWriteCustChar(1, pos + 1, 3); 
      lcdWriteCustChar(1, pos + 2, 255); 
      lcdWriteCustChar(2, pos, 4); 
      lcdWriteCustChar(2, pos + 1, 5); 
      lcdWriteCustChar(2, pos + 2, 6); 
    }
  } else if (screen == SCREEN_EEPROM) {
    lcdSetCustChar_P(0, CHK);
    printLCD_P(3, 0, PSTR("Test   /  : EEPROM"));
    printLCDLPad(3, 5, itoa(screen + 1, buf, 10), 2, '0');
    printLCDLPad(3, 8, itoa(SCREEN_MAX, buf, 10), 2, '0');
    
    if (screenLock) {
      for (byte block = 0; block < 16; block++) {
        printLCD_P(1, block + 2, PSTR("W"));
        updateLCD();
        for (int pos = 0; pos < EEPROM_BLOCK_SIZE; pos++) EEPROM.write(block * EEPROM_BLOCK_SIZE + pos, pos);
        printLCD_P(1, block + 2, PSTR("V"));
        updateLCD();
        boolean failed = 0;
        for (int pos = 0; pos < EEPROM_BLOCK_SIZE; pos++) {
          if (EEPROM.read(block * EEPROM_BLOCK_SIZE + pos) != pos){
            failed = 1;
            break;
          }
          EEPROM.write(block * EEPROM_BLOCK_SIZE + pos, 0);
        }
        if (failed) printLCD_P(1, block + 2, PSTR("X"));
        else lcdWriteCustChar(1, block + 2, 0);
        updateLCD();
      }
    }
  } else if (screen == SCREEN_OUTPUTS) {
    printLCD_P(3, 0, PSTR("Test   /  : Outputs"));
    printLCDLPad(3, 5, itoa(screen + 1, buf, 10), 2, '0');
    printLCDLPad(3, 8, itoa(SCREEN_MAX, buf, 10), 2, '0');
    
    if (screenLock) {
      printLCDCenter(1, 0, "HLT Heat", 20);
      updateLCD();
      digitalWrite(HLTHEAT_PIN, HIGH);
      delay(500);
      digitalWrite(HLTHEAT_PIN, LOW);
    
      printLCDCenter(1, 0, "Mash Heat", 20);
      updateLCD();
      digitalWrite(MASHHEAT_PIN, HIGH);
      delay(500);
      digitalWrite(MASHHEAT_PIN, LOW);
    
      printLCDCenter(1, 0, "Kettle Heat", 20);
      updateLCD();
      digitalWrite(KETTLEHEAT_PIN, HIGH);
      delay(500);
      digitalWrite(KETTLEHEAT_PIN, LOW);
    
    #ifdef USESTEAM
      printLCDCenter(1, 0, "Steam Heat", 20);
      updateLCD();
      digitalWrite(STEAMHEAT_PIN, HIGH);
      delay(500);
      digitalWrite(STEAMHEAT_PIN, LOW);
    #endif
    
      printLCDCenter(1, 0, "", 20);
      printLCD_P(1, 6, PSTR("Valve"));
      for(byte valve = 0; valve < NUM_VALVES; valve++) {
        printLCDLPad(1, 12, itoa(valve + 1, buf, 10), 2, '0');
        updateLCD();
        setValves((unsigned long)1<<valve);
        delay(500);
      }
      setValves(0);
    
      printLCDCenter(1, 0, "Alarm", 20);
      updateLCD();
      digitalWrite(ALARM_PIN, HIGH);
      delay(500);
      digitalWrite(ALARM_PIN, LOW);
    }
  } else if (screen == SCREEN_ONEWIRE) {
    printLCD_P(3, 0, PSTR("Test   /  : OneWire"));
    printLCDLPad(3, 5, itoa(screen + 1, buf, 10), 2, '0');
    printLCDLPad(3, 8, itoa(SCREEN_MAX, buf, 10), 2, '0');
    
    getDSAddr(addr);
    printLCD_P(0, 0, PSTR("Found Address:"));
    for (byte i=0; i<8; i++) printLCDLPad(1,i*2+2,itoa(addr[i], buf, 16), 2, '0');  
    
    #ifdef USEMETRIC
      printLCD_P(2, 13, PSTR("C"));
    #else
      printLCD_P(2, 13, PSTR("F"));  
    #endif
    convertAll();
    convertTime = millis();
  } else if (screen == SCREEN_VOLUME) {
    printLCD_P(3, 0, PSTR("Test   /  : VSensors"));
    printLCDLPad(3, 5, itoa(screen + 1, buf, 10), 2, '0');
    printLCDLPad(3, 8, itoa(SCREEN_MAX, buf, 10), 2, '0');
    printLCD_P(0, 0, PSTR("HLT"));
    printLCD_P(1, 0, PSTR("Mash"));
    printLCD_P(0, 9, PSTR("Kettle"));
    printLCD_P(1, 10, PSTR("Steam"));
  } else if (screen == SCREEN_TIMER) {
    printLCD_P(3, 0, PSTR("Test   /  : Timer"));
    printLCDLPad(3, 5, itoa(screen + 1, buf, 10), 2, '0');
    printLCDLPad(3, 8, itoa(SCREEN_MAX, buf, 10), 2, '0');
    if (screenLock) {
      for(byte count = 11; count > 0; count--) {
        printLCDLPad(1, 9, itoa(count - 1, buf, 10), 2, '0');
        updateLCD();
        delay(1000);
      }
    }
  } else if (screen == SCREEN_MANUALPV) {
    printLCD_P(3, 0, PSTR("Test   /  : ManualPV"));
    printLCDLPad(3, 5, itoa(screen + 1, buf, 10), 2, '0');
    printLCDLPad(3, 8, itoa(SCREEN_MAX, buf, 10), 2, '0');
    
    if (screenLock) {
      #ifdef ONBOARDPV
        byte encMax = 11;
      #else
        byte encMax = MUXBOARDS * 8;
      #endif

      Encoder.setMin(0);
      Encoder.setMax(encMax);
    
      //The left most bit being displayed (Set to MAX + 1 to force redraw)
      byte firstBit = encMax + 1;
      Encoder.setCount(0);
      byte lastCount = 1;
      clearLCD();
      printLCD_P(0, 0, PSTR("Manual Valve Testing"));
      printLCD_P(3, 15, PSTR("EXIT"));
      
      while(1) {
        if (Encoder.getCount() != lastCount) {
          lastCount = Encoder.getCount();
          
          if (lastCount < firstBit || lastCount > firstBit + 17) {
            if (lastCount < firstBit) firstBit = lastCount; else if (lastCount < encMax ) firstBit = lastCount - 17;
            for (byte i = firstBit; i < min(encMax, firstBit + 18); i++) if (vlvBits & ((unsigned long)1<<i)) printLCD_P(1, i - firstBit + 1, PSTR("1")); else printLCD_P(1, i - firstBit + 1, PSTR("0"));
          }
    
          for (byte i = firstBit; i < min(encMax, firstBit + 18); i++) {
            if (i < 9) itoa(i + 1, buf, 10); else buf[0] = i + 56;
            buf[1] = '\0';
            printLCD(2, i - firstBit + 1, buf);
          }
    
          if (firstBit > 0) printLCD_P(2, 0, PSTR("<")); else printLCD_P(2, 0, PSTR(" "));
          if (firstBit + 18 < encMax) printLCD_P(2, 19, PSTR(">")); else printLCD_P(2, 19, PSTR(" "));
          if (lastCount == encMax) {
            printLCD_P(3, 14, PSTR(">"));
            printLCD_P(3, 19, PSTR("<"));
          } else {
            printLCD_P(3, 14, PSTR(" "));
            printLCD_P(3, 19, PSTR(" "));
            printLCD_P(2, lastCount - firstBit + 1, PSTR("^"));
          }
        }
        
        if (Encoder.ok()) {
          if (lastCount == encMax) {
            setValves(0);
            activeScreen = SCREEN_COMPLETE;
            screenInit(activeScreen);
            return;
          }
          setValves(vlvBits ^ ((unsigned long)1<<lastCount));
          for (byte i = firstBit; i < min(encMax, firstBit + 18); i++) if (vlvBits & ((unsigned long)1<<i)) printLCD_P(1, i - firstBit + 1, PSTR("1")); else printLCD_P(1, i - firstBit + 1, PSTR("0"));
        }
        updateLCD();
      }  
    }
  } else if (screen == SCREEN_COMPLETE) {
    printLCD_P(3, 0, PSTR("Tests Complete."));
  }

  //Write Unlock symbol to upper right corner
  if (!screenLock) lcdWriteCustChar(0, 19, 7);
}

//**********************************************************************************
// screenRefresh:  Refresh active screen
//**********************************************************************************
void screenRefresh(byte screen) {
  if (screen == SCREEN_LCD) {
  } else if (screen == SCREEN_EEPROM) {
  } else if (screen == SCREEN_OUTPUTS) {
  } else if (screen == SCREEN_ONEWIRE) {
    if (millis() - convertTime > 750) {
      int temp = read_temp(addr);
      vftoa(temp, buf, 2);
      printLCDLPad(2, 7, buf, 6, ' ');
      convertAll();
      convertTime = millis();
    }
  } else if (screen == SCREEN_VOLUME) {
    if (millis() - lastRead > 500) {
      unsigned int v = 50 * (unsigned int) analogRead(HLTVOL_APIN) / 1024 ;
      vftoa(v, buf, 1);
      printLCDLPad(0, 4, buf, 3, ' ');
      
      v = 50 * (unsigned int) analogRead(MASHVOL_APIN) / 1024 ;
      vftoa(v, buf, 1);
      printLCDLPad(1, 5, buf, 3, ' ');
      
      v = 50 * (unsigned int) analogRead(KETTLEVOL_APIN) / 1024 ;
      vftoa(v, buf, 1);
      printLCDLPad(0, 16, buf, 3, ' ');
      
      v = 50 * (unsigned int) analogRead(STEAMPRESS_APIN) / 1024 ;
      vftoa(v, buf, 1);
      printLCDLPad(1, 16, buf, 3, ' ');
      lastRead = millis();
    }  
  } else if (screen == SCREEN_TIMER) {
    
  } else if (screen == SCREEN_MANUALPV) {
    
  } else if (screen == SCREEN_COMPLETE) {
  }
}


//**********************************************************************************
// screenEnter:  Check enterStatus and handle based on screenLock and activeScreen
//**********************************************************************************
void screenEnter(byte screen) {
  if (Encoder.cancel()) {
    //Unlock screens
    unlockUI();
  } else if (Encoder.ok()) {
    if (!screenLock) lockUI();
    else {
      if (screen == SCREEN_LCD) {
        activeScreen = SCREEN_EEPROM;
        screenInit(activeScreen);
      } else if (screen == SCREEN_EEPROM) {
        activeScreen = SCREEN_OUTPUTS;
        screenInit(activeScreen);
      } else if (screen == SCREEN_OUTPUTS) {
        activeScreen = SCREEN_ONEWIRE;
        screenInit(activeScreen);
      } else if (screen == SCREEN_ONEWIRE) {
        activeScreen = SCREEN_VOLUME;
        screenInit(activeScreen);
      } else if (screen == SCREEN_VOLUME) {
        activeScreen = SCREEN_TIMER;
        screenInit(activeScreen);
      } else if (screen == SCREEN_TIMER) {
        activeScreen = SCREEN_MANUALPV;
        screenInit(activeScreen);
      } else if (screen == SCREEN_MANUALPV) {
      } else if (screen == SCREEN_COMPLETE) {
        unlockUI();
      }
    }
  }
}


