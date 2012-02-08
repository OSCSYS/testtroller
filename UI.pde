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

#include "HWProfile.h"
#include <encoder.h>
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
#define SCREEN_HOME 0
#define SCREEN_LCD 1
#define SCREEN_EEPROM 2
#define SCREEN_OUTPUTS 3
#define SCREEN_ONEWIRE 4
#define SCREEN_VOLUME 5
#define SCREEN_TRIGGERS 6
#define SCREEN_MANUALPV 7
#define SCREEN_TIMER 8
#define SCREEN_COMPLETE 9

#define SCREEN_MIN SCREEN_HOME
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

const byte BTLOGO0[] PROGMEM = {B00000, B00000, B00000, B11111, B10001, B10001, B11111, B00001};
const byte BTLOGO1[] PROGMEM = {B00000, B00000, B00000, B00000, B00000, B00011, B01100, B01111};
const byte BTLOGO2[] PROGMEM = {B00000, B00000, B00000, B00000, B00000, B11100, B00011, B11111};
const byte BTLOGO3[] PROGMEM = {B00100, B01100, B01111, B00111, B00100, B01100, B01111, B00111};
const byte BTLOGO4[] PROGMEM = {B00010, B00011, B11111, B11110, B00010, B00011, B11111, B11110};

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
  LCD.init();
  LCD.setCustChar_P(7, UNLOCK_ICON);
  
  #ifndef ENCODER_I2C
    #ifndef ENCODER_OLD_CONSTRUCTOR
      Encoder.begin(ENCODER_TYPE, ENTER_PIN, ENCA_PIN, ENCB_PIN);
    #else
      Encoder.begin(ENCODER_TYPE, ENTER_PIN, ENCA_PIN, ENCB_PIN, ENTER_INT, ENCA_INT);
    #endif
  #else
     Encoder.begin(ENCODER_I2CADDR);
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
  LCD.clear();
  
  if (screen == SCREEN_HOME) {
    char buildNum[5];
    LCD.setCustChar_P(0, BTLOGO0);
    LCD.setCustChar_P(1, BTLOGO1);
    LCD.setCustChar_P(2, BTLOGO2);
    LCD.setCustChar_P(3, BTLOGO3);
    LCD.setCustChar_P(4, BTLOGO4);
    LCD.writeCustChar(0, 0, 0);
    LCD.writeCustChar(0, 1, 1);
    LCD.writeCustChar(0, 2, 2);
    LCD.writeCustChar(1, 1, 3);
    LCD.writeCustChar(1, 2, 4);
    LCD.print_P(1, 4, BT);
    LCD.print_P(1, 16, BTVER);
    LCD.print_P(2, 4, PSTR("Build"));
    LCD.lPad(2, 10, itoa(BUILD, buildNum, 10), 4, '0');
    LCD.print_P(3, 0, PSTR("www.brewtroller.com"));
  } else if (screen == SCREEN_LCD) {
    char testNum[2];
    //Screen Init: Home
    LCD.setCustChar_P(0, BMP0);
    LCD.setCustChar_P(1, BMP1);
    LCD.setCustChar_P(2, BMP2);
    LCD.setCustChar_P(3, BMP3);
    LCD.setCustChar_P(4, BMP4);
    LCD.setCustChar_P(5, BMP5);
    LCD.setCustChar_P(6, BMP6);
    LCD.print_P(3, 0, PSTR("Test   /  : LCD"));
    LCD.lPad(3, 5, itoa(screen + 1, testNum, 10), 2, '0');
    LCD.lPad(3, 8, itoa(SCREEN_MAX, testNum, 10), 2, '0');
  
    for (byte pos = 0; pos < 3; pos++) LCD.print_P(pos, 0, PSTR(">"));
    for (byte pos = 0; pos < 3; pos++) LCD.print_P(pos, 19, PSTR("<"));
    for (byte pos = 1; pos < 19; pos = pos + 3) {
      LCD.writeCustChar(0, pos + 1, 0);
      LCD.writeCustChar(0, pos + 2, 1);
      LCD.writeCustChar(1, pos, 2); 
      LCD.writeCustChar(1, pos + 1, 3); 
      LCD.writeCustChar(1, pos + 2, 255); 
      LCD.writeCustChar(2, pos, 4); 
      LCD.writeCustChar(2, pos + 1, 5); 
      LCD.writeCustChar(2, pos + 2, 6); 
    }
  } else if (screen == SCREEN_EEPROM) {
    char testNum[2];
    LCD.setCustChar_P(0, CHK);
    LCD.print_P(3, 0, PSTR("Test   /  : EEPROM"));
    LCD.lPad(3, 5, itoa(screen + 1, testNum, 10), 2, '0');
    LCD.lPad(3, 8, itoa(SCREEN_MAX, testNum, 10), 2, '0');
    
    if (screenLock) {
      for (byte block = 0; block < 16; block++) {
        LCD.print_P(1, block + 2, PSTR("W"));
        LCD.update();
        for (int pos = 0; pos < EEPROM_BLOCK_SIZE; pos++) EEPROM.write(block * EEPROM_BLOCK_SIZE + pos, pos);
        LCD.print_P(1, block + 2, PSTR("V"));
        LCD.update();
        boolean failed = 0;
        for (int pos = 0; pos < EEPROM_BLOCK_SIZE; pos++) {
          if (EEPROM.read(block * EEPROM_BLOCK_SIZE + pos) != pos){
            failed = 1;
            break;
          }
          EEPROM.write(block * EEPROM_BLOCK_SIZE + pos, 0);
        }
        if (failed) LCD.print_P(1, block + 2, PSTR("X"));
        else LCD.writeCustChar(1, block + 2, 0);
        LCD.update();
      }
    }
  } else if (screen == SCREEN_OUTPUTS) {
    char testNum[2];
    LCD.print_P(3, 0, PSTR("Test   /  : Outputs"));
    LCD.lPad(3, 5, itoa(screen + 1, testNum, 10), 2, '0');
    LCD.lPad(3, 8, itoa(SCREEN_MAX, testNum, 10), 2, '0');
    
    if (screenLock) {
      #ifdef OUTPUT_GPIO
        for (byte i = 0; i < OUT_GPIO_COUNT; i++) {
          char title[21];
          char index[4];
          strcpy(title, "GPIO OUTPUT ");
          strcat(title, itoa(i + 1, index, 10));
          LCD.center(1, 0, title, 20);
          LCD.update();
          gpioPin[i].set();
          delay(500);
          gpioPin[i].clear();
          delay(125);
        }
      #endif
      #ifdef OUTPUT_MUX
        for (byte i = 0; i < OUT_MUX_COUNT; i++) {
          char title[21];
          char index[4];
          strcpy(title, "MUX OUTPUT ");
          strcat(title, itoa(i + 1, index, 10));
          LCD.center(1, 0, title, 20);
          LCD.update();
          setMUX((unsigned long)1<<i);
          delay(500);
          setMUX(0);
          delay(125);
        }
      #endif
      Serial.println("Done with output UI init");
    }
  } else if (screen == SCREEN_ONEWIRE) {
    char testNum[2];
    LCD.print_P(0, 0, PSTR("Found Address:"));
    LCD.print_P(3, 0, PSTR("Test   /  : OneWire"));
    LCD.lPad(3, 5, itoa(screen + 1, testNum, 10), 2, '0');
    LCD.lPad(3, 8, itoa(SCREEN_MAX, testNum, 10), 2, '0');
    
    #ifdef USEMETRIC
      LCD.print_P(2, 13, PSTR("C"));
    #else
      LCD.print_P(2, 13, PSTR("F"));  
    #endif
    convertAll();
    convertTime = millis();
  } else if (screen == SCREEN_VOLUME) {
    char testNum[2];
    LCD.print_P(3, 0, PSTR("Test   /  : ADC"));
    LCD.lPad(3, 5, itoa(screen + 1, testNum, 10), 2, '0');
    LCD.lPad(3, 8, itoa(SCREEN_MAX, testNum, 10), 2, '0');
    for (byte i = 0; i < ANALOGIN_COUNT; i++) {
      char index[5];
      itoa (i + 1, index, 10);
      strcat(index, ":");
      if (i < 3) LCD.print(i, 0, index);
      else LCD.print(i - 3, 10, index);
    }
  } else if (screen == SCREEN_TIMER) {
    char testNum[2];
    LCD.print_P(3, 0, PSTR("Test   /  : Timer"));
    LCD.lPad(3, 5, itoa(screen + 1, testNum, 10), 2, '0');
    LCD.lPad(3, 8, itoa(SCREEN_MAX, testNum, 10), 2, '0');
    if (screenLock) {
      for(byte count = 11; count > 0; count--) {
        char timerNum[3];
        LCD.lPad(1, 9, itoa(count - 1, timerNum, 10), 2, '0');
        LCD.update();
        delay(1000);
      }
    }
  } else if (screen == SCREEN_MANUALPV) {
    char testNum[2];
    LCD.print_P(3, 0, PSTR("Test   /  : Manual"));
    LCD.lPad(3, 5, itoa(screen + 1, testNum, 10), 2, '0');
    LCD.lPad(3, 8, itoa(SCREEN_MAX, testNum, 10), 2, '0');
    
    if (screenLock) {
      byte encMax = 1;
      #ifdef OUTPUT_GPIO
        encMax += OUT_GPIO_COUNT;
      #endif
      #ifdef OUTPUT_MUX
        encMax += OUT_MUX_COUNT;
      #endif
      
      Encoder.setMin(0);
      Encoder.setMax(encMax);
    
      menu outMenu(3, encMax);
      
      while(1) {
        byte menuNum = 0;
        outMenu.setItem_P(PSTR("Exit"), 255);

        #ifdef OUTPUT_GPIO
          for (byte i = 0; i < OUT_GPIO_COUNT; i++) {
            char index[4];
            outMenu.setItem("GPIO Output ", menuNum);
            outMenu.appendItem(itoa(i + 1, index, 10), menuNum);
            if (gpioPin[i].get()) outMenu.appendItem(": On", menuNum);
            else outMenu.appendItem(": Off", menuNum);
            menuNum++;
          }
        #endif
        #ifdef OUTPUT_MUX
          for (byte i = 0; i < OUT_MUX_COUNT; i++) {
            char index[4];
            outMenu.setItem("MUX Output ", menuNum);
            outMenu.appendItem(itoa(i + 1, index, 10), menuNum);
            if (vlvBits & ((unsigned long) 1 << i)) outMenu.appendItem(": On", menuNum);
            else outMenu.appendItem(": Off", menuNum);
            menuNum++;
          }
        #endif
        byte lastOption = scrollMenu("Manual Output Test", &outMenu);

        #ifdef OUTPUT_GPIO
          if (lastOption < OUT_GPIO_COUNT) gpioPin[lastOption].toggle();
          #ifdef OUTPUT_MUX
            else if (lastOption >= OUT_GPIO_COUNT && lastOption < OUT_GPIO_COUNT + OUT_MUX_COUNT) setMUX(vlvBits ^ ((unsigned long) 1 << (lastOption - OUT_GPIO_COUNT)));
          #endif
        #else
          #ifdef OUTPUT_MUX
            if (lastOption < OUT_MUX_COUNT) setMUX(vlvBits ^ ((unsigned long) 1 << (lastOption - OUT_GPIO_COUNT)));
          #endif        
        #endif
        
        if (lastOption == 255) {
          activeScreen++;
          screenInit(activeScreen);
          return;
        }
      }
    }
  } else if (screen == SCREEN_TRIGGERS) {
    char testNum[2];
    LCD.print_P(3, 0, PSTR("Test   /  : Digital Ins"));
    LCD.lPad(3, 5, itoa(screen + 1, testNum, 10), 2, '0');
    LCD.lPad(3, 8, itoa(SCREEN_MAX, testNum, 10), 2, '0');
#ifdef DIGITAL_INPUTS
    for (byte i = 0; i < DIGITALIN_COUNT; i++) {
      char index[10];
      itoa (i + 1, index, 10);
      strcat(index, ": WAIT");
      if (i < 3) LCD.print(i, 0, index);
      else LCD.print(i - 3, 10, index);
    }
    for (byte i = 0; i < DIGITALIN_COUNT; i++) { triggers[i] = 0; }
#endif
  } else if (screen == SCREEN_COMPLETE) {
    LCD.print_P(3, 0, PSTR("Tests Complete."));
  }

  //Write Unlock symbol to upper right corner
  if (!screenLock) LCD.writeCustChar(0, 19, 7);
}

byte lastAddr[8] = {0, 0, 0, 0, 0, 0, 0, 0};

//**********************************************************************************
// screenRefresh:  Refresh active screen
//**********************************************************************************
void screenRefresh(byte screen) {
  if (screen == SCREEN_HOME) {
  } else if (screen == SCREEN_LCD) {
  } else if (screen == SCREEN_EEPROM) {
  } else if (screen == SCREEN_OUTPUTS) {
          Serial.println("Output UI refresh");
  } else if (screen == SCREEN_ONEWIRE) {
    if (millis() - convertTime > 750) {
      char addrHex[3];
      memset(addr,0,8);
      getDSAddr(addr);
      for (byte i=0; i<8; i++) LCD.lPad(1,i*2+2,itoa(addr[i], addrHex, 16), 2, '0');  
      char tText[7] = {""};
      if (memcmp(addr, lastAddr, 8)) {
        //Toss first read
        memcpy(lastAddr, addr, 8);
      } else {
        int temp = read_temp(addr);
        if (temp != -32768) {
          vftoa(temp, tText, 2);
          Serial.print("DS18B20\t");
          for (byte i = 0; i < 8; i++) {
            Serial.print(addr[i]>>4, HEX);
            Serial.print(addr[i]&0x0F, HEX);
          }
          Serial.print("\t");
          Serial.print(tText);
          Serial.println("F");
        }
      }
      LCD.lPad(2, 7, tText, 6, ' ');
      convertAll();
      convertTime = millis();
    }
  } else if (screen == SCREEN_VOLUME) {
    if (millis() - lastRead > 500) {
      for (byte i = 0; i < ANALOGIN_COUNT; i++) {
        char value[4];
        unsigned int v = 50 * (unsigned int) analogRead(analogPinNum[i]) / 1024 ;
        vftoa(v, value, 1);
        if (i < 3) LCD.lPad(i, 3, value, 3, ' ');
        else LCD.lPad(i - 3, 13, value, 3, ' ');
      }
      lastRead = millis();
    }  
  } else if (screen == SCREEN_TIMER) {
    
  } else if (screen == SCREEN_MANUALPV) {
    
  } else if (screen == SCREEN_TRIGGERS) {
    #ifdef DIGITAL_INPUTS
    if (millis() - trigReset > 3000) {
      for (byte i = 0; i < DIGITALIN_COUNT; i++) triggers[i] = 0;
      trigReset = millis();
    }
    for (byte i = 0; i < DIGITALIN_COUNT; i++) {
      char value[5];
      if (triggers[i]) strcpy (value, "TRIG");
      else strcpy (value, "WAIT");
      if (i < 3) LCD.print(i, 3, value);
      else LCD.print(i - 3, 13, value);
    }
    #endif
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
      if (screen == SCREEN_HOME) {
	#ifdef UI_DISPLAY_SETUP
	        adjustLCD();
        	unlockUI();
	#endif
      } else if (screen == SCREEN_COMPLETE) {
        unlockUI();
      } else {
        activeScreen++;
        screenInit(activeScreen);
      }
    }
  }
}

#ifdef UI_DISPLAY_SETUP
  void adjustLCD() {
    byte cursorPos = 0; //0 = brightness, 1 = contrast, 2 = cancel, 3 = save
    boolean cursorState = 0; //0 = Unselected, 1 = Selected

    Encoder.setMin(0);
    Encoder.setCount(0);
    Encoder.setMax(3);
    
    LCD.clear();
    LCD.print_P(0,0,PSTR("Adjust LCD"));
    LCD.print_P(1, 1, PSTR("Brightness:"));
    LCD.print_P(2, 3, PSTR("Contrast:"));
    LCD.print_P(3, 1, PSTR("Cancel"));
    LCD.print_P(3, 15, PSTR("Save"));
    byte bright = LCD.getBright();
    byte contrast = LCD.getContrast();
    byte origBright = bright;
    byte origContrast = contrast;
    boolean redraw = 1;
    while(1) {
      int encValue;
      if (redraw) {
        redraw = 0;
        encValue = Encoder.getCount();
      }
      else encValue = Encoder.change();
      if (encValue >= 0) {
        if (cursorState) {
          if (cursorPos == 0) { 
            bright = encValue;
            LCD.setBright(bright);
          } else if (cursorPos == 1) {
            contrast = encValue;
            LCD.setContrast(contrast);
          }
        } else {
          cursorPos = encValue;
          LCD.print_P(1, 12, PSTR(" "));
          LCD.print_P(1, 16, PSTR(" "));
          LCD.print_P(2, 12, PSTR(" "));
          LCD.print_P(2, 16, PSTR(" "));
          LCD.print_P(3, 0, PSTR(" "));
          LCD.print_P(3, 7, PSTR(" "));
          LCD.print_P(3, 14, PSTR(" "));
          LCD.print_P(3, 19, PSTR(" "));
          if (cursorPos == 0) {
            LCD.print_P(1, 12, PSTR(">"));
            LCD.print_P(1, 16, PSTR("<"));
          } else if (cursorPos == 1) {
            LCD.print_P(2, 12, PSTR(">"));
            LCD.print_P(2, 16, PSTR("<"));
          } else if (cursorPos == 2) {
            LCD.print_P(3, 0, PSTR(">"));
            LCD.print_P(3, 7, PSTR("<"));
          } else if (cursorPos == 3) {
            LCD.print_P(3, 14, PSTR(">"));
            LCD.print_P(3, 19, PSTR("<"));
          }
        }
        char buf[4];
        LCD.lPad(1, 13, itoa(bright, buf, 10), 3, ' ');
        LCD.lPad(2, 13, itoa(contrast, buf, 10), 3, ' ');
      }
      if (Encoder.ok()) {
        if (cursorPos == 2) {
          LCD.setBright(origBright);
          LCD.setContrast(origContrast);
          return;
        }
        else if (cursorPos == 3) {
          LCD.saveConfig();
          return;
        }
        cursorState = cursorState ^ 1;
        if (cursorState) {
          Encoder.setMin(0);
          Encoder.setMax(255);
          if (cursorPos == 0) Encoder.setCount(bright);
          else if (cursorPos == 1) Encoder.setCount(contrast);
        } else {
          Encoder.setMin(0);
          Encoder.setMax(3);
          Encoder.setCount(cursorPos);
        }
      } else if (Encoder.cancel()) return;
      brewCore();
    }
  }
#endif //#ifdef UI_DISPLAY_SETUP

byte scrollMenu(char sTitle[], menu *objMenu) {
  Encoder.setMin(0);
  Encoder.setMax(objMenu->getItemCount() - 1);
  //Force refresh in case selected value was set
  Encoder.setCount(objMenu->getSelected());
  boolean redraw = 1;
  
  while(1) {
    int encValue;
    if (redraw) encValue = Encoder.getCount();
    else encValue = Encoder.change();
    if (encValue >= 0) {
      objMenu->setSelected(Encoder.getCount());
      if (objMenu->refreshDisp() || redraw) drawMenu(sTitle, objMenu);
      for (byte i = 0; i < 3; i++) LCD.print(i + 1, 0, " ");
      LCD.print(objMenu->getCursor() + 1, 0, ">");
    }
    redraw = 0;
    //If Enter
    if (Encoder.ok()) {
      return objMenu->getValue();
    } else if (Encoder.cancel()) {
      return 255;
    }
    brewCore();
  }
}

void drawMenu(char sTitle[], menu *objMenu) {
  char row[21];
  LCD.clear();
  if (sTitle != NULL) LCD.print(0, 0, sTitle);

  for (byte i = 0; i < 3; i++) {
    objMenu->getVisibleRow(i, row);
    LCD.print(i + 1, 1, row);
  }
  LCD.print(objMenu->getCursor() + 1, 0, ">");
}
