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


BrewTroller - Open Source Brewing Computer
Software Lead: Matt Reba (matt_AT_brewtroller_DOT_com)
Hardware Lead: Jeremiah Dillingham (jeremiah_AT_brewtroller_DOT_com)

Documentation, Forums and more information available at http://www.brewtroller.com
*/

#ifndef UILCD_H
  #define UILCD_H

  #include "HWProfile.h"
  #include <Wire.h>
  #include <LiquidCrystalFP.h>
  #include <stdlib.h> // for malloc and free
  #include <EEPROM.h>

  void* operator new(size_t size) { return malloc(size); }
  void operator delete(void* ptr) { free(ptr); }


  //*****************************************************************************************************************************
  // 4-Bit GPIO LCD Class
  //*****************************************************************************************************************************
  
  //**********************************************************************************
  // LCD Timing Fix
  //**********************************************************************************
  // Some LCDs seem to have issues with displaying garbled characters but introducing
  // a delay seems to help or resolve completely. You may comment out the following
  // lines to remove this delay between a print of each character.
  //
  //#define LCD_DELAY_CURSOR 60
  //#define LCD_DELAY_CHAR 60
  //**********************************************************************************
  
  class LCD4Bit
  {
    public:
      #ifndef UI_DISPLAY_SETUP
        LCD4Bit(byte rs, byte enable, byte d4, byte d5, byte d6, byte d7) {
          _lcd = new LiquidCrystal(rs, enable, d4, d5, d6, d7);
        }
      #else
        LCD4Bit(byte rs, byte enable, byte d4, byte d5, byte d6, byte d7, byte b, byte c) {
          _lcd = new LiquidCrystal(rs, enable, d4, d5, d6, d7);
          brightPin = b;
          contrastPin = c;
        }
      #endif
      
      void init(){
        _lcd->begin(20, 4);
        #ifdef UI_DISPLAY_SETUP
          TCCR2B = 0x01;
          pinMode(brightPin, OUTPUT);
          pinMode(contrastPin, OUTPUT);
          setBright(loadLCDBright());
          setContrast(loadLCDContrast());
        #endif
      }
      
      void update() {      }
      
      void print(byte iRow, byte iCol, char sText[]){
        _lcd->setCursor(iCol, iRow);
        #ifdef LCD_DELAY_CURSOR
          delayMicroseconds(LCD_DELAY_CURSOR);
        #endif
        int i = 0;
        while (sText[i] != 0)  {
          _lcd->print(sText[i++]);
          #ifdef LCD_DELAY_CHAR
            delayMicroseconds(LCD_DELAY_CHAR);
          #endif
        }
      }  
      
      //Version of PrintLCD reading from PROGMEM
      void print_P(byte iRow, byte iCol, const char *sText){
        _lcd->setCursor(iCol, iRow);
        while (pgm_read_byte(sText) != 0) {
          _lcd->print(pgm_read_byte(sText++)); 
          #ifdef LCD_DELAY_CHAR
            delayMicroseconds(LCD_DELAY_CHAR);
          #endif
        }
      } 
      
      void clear(){ 
        _lcd->begin(20, 4);
      }
      
      void center(byte iRow, byte iCol, char sText[], byte fieldWidth){
        rPad(iRow, iCol, "", fieldWidth, ' ');
        if (strlen(sText) < fieldWidth) _lcd->setCursor(iCol + ((fieldWidth - strlen(sText)) / 2), iRow);
        else _lcd->setCursor(iCol, iRow);
        #ifdef LCD_DELAY_CURSOR
          delayMicroseconds(LCD_DELAY_CURSOR);
        #endif
      
        int i = 0;
        while (sText[i] != 0)  {
          _lcd->print(sText[i++]);
          #ifdef LCD_DELAY_CHAR
            delayMicroseconds(LCD_DELAY_CHAR);
          #endif
        }
      
      } 
      
      char lPad(byte iRow, byte iCol, char sText[], byte length, char pad) {
        _lcd->setCursor(iCol, iRow);
        #ifdef LCD_DELAY_CURSOR
          delayMicroseconds(LCD_DELAY_CURSOR);
        #endif
        if (strlen(sText) < length) {
          for (byte i=0; i < length-strlen(sText); i++) {
            _lcd->print(pad);
            #ifdef LCD_DELAY_CHAR
              delayMicroseconds(LCD_DELAY_CHAR);
            #endif
          }
        }
        
        int i = 0;
        while (sText[i] != 0)  {
          _lcd->print(sText[i++]);
          #ifdef LCD_DELAY_CHAR
            delayMicroseconds(LCD_DELAY_CHAR);
          #endif
        }
      
      }  
      
      char rPad(byte iRow, byte iCol, char sText[], byte length, char pad) {
        _lcd->setCursor(iCol, iRow);
        #ifdef LCD_DELAY_CURSOR
          delayMicroseconds(LCD_DELAY_CURSOR);
        #endif
      
        int i = 0;
        while (sText[i] != 0)  {
          _lcd->print(sText[i++]);
          #ifdef LCD_DELAY_CHAR
            delayMicroseconds(LCD_DELAY_CHAR);
          #endif
        }
        
        if (strlen(sText) < length) {
          for (byte i=0; i < length-strlen(sText) ; i++) {
            _lcd->print(pad);
            #ifdef LCD_DELAY_CHAR
              delayMicroseconds(LCD_DELAY_CHAR);
            #endif
          }
        }
      }  
      
      void setCustChar_P(byte slot, const byte *charDef) {
        _lcd->command(64 | (slot << 3));
        for (byte i = 0; i < 8; i++) {
          _lcd->write(pgm_read_byte(charDef++));
          #ifdef LCD_DELAY_CHAR
            delayMicroseconds(LCD_DELAY_CHAR);
          #endif
        }
        _lcd->command(B10000000);
      }
      
      void writeCustChar(byte iRow, byte iCol, byte slot) {
        _lcd->setCursor(iCol, iRow);
        #ifdef LCD_DELAY_CURSOR
          delayMicroseconds(LCD_DELAY_CURSOR);
        #endif
        _lcd->write(slot);
      }

      #ifdef UI_DISPLAY_SETUP      
        void setBright(byte val) {
          analogWrite(brightPin, 255 - val);
          bright = val;
        }
        
        void setContrast(byte val) {
          analogWrite(contrastPin, val);
          contrast = val;
        }

        void saveConfig(void) {
          saveLCDBright(bright);
          saveLCDContrast(contrast);
        }
        
        byte getBright(void) {
          return bright;
        }
        
        byte getContrast(void) {
          return contrast;
        }
      #endif
    private:
      LiquidCrystal * _lcd;
      
      #ifdef UI_DISPLAY_SETUP
        byte brightPin, contrastPin;
        byte bright, contrast;
        void saveLCDBright(byte val) { }
        void saveLCDContrast(byte val) { }
        byte loadLCDBright() { return LCD_DEFAULT_BRIGHTNESS; }
        byte loadLCDContrast() { return LCD_DEFAULT_CONTRAST; }
      #endif
  };




//*****************************************************************************************************************************
// I2C LCD Class
//*****************************************************************************************************************************
  class LCDI2C
  {
    public:
      LCDI2C(byte addr) {
        i2cLCDAddr = addr;
      }
      
      void init(){
        delay(1000);
        Wire.begin();
        fastWrite = (i2cLcdGetVersion() > 968 ? 1 : 0);
      }
      
      void print(byte iRow, byte iCol, char sText[]){
        byte pos = iRow * 20 + iCol;
        memcpy((byte*)&screen[pos], sText, min(strlen(sText), 80-pos));
      }  
      
      //Version of PrintLCD reading from PROGMEM
      void print_P(byte iRow, byte iCol, const char *sText){
        byte pos = iRow * 20 + iCol;
        memcpy_P((byte*)&screen[pos], sText, min(strlen_P(sText), 80-pos));
      } 
      
      void clear() {
        memset(screen, ' ', 80);
        i2cLcdClear();
      }
      
      void center(byte iRow, byte iCol, char sText[], byte fieldWidth){
        byte sLen = strlen(sText);
        byte textStart = (fieldWidth - sLen) / 2;
        char s[21];
        memset(s, ' ', fieldWidth);
        memcpy(s + textStart, sText, sLen);
        s[fieldWidth] = '\0';
        print(iRow, iCol, s);
      }
        
      char lPad(byte iRow, byte iCol, char sText[], byte length, char pad) {
        char s[21];
        byte sLen = strlen(sText);
        byte textStart = length - sLen;
        memset(s, pad, textStart);
        memcpy(s + textStart, sText, sLen);
        s[length] = 0;
        print(iRow, iCol, s);
      }  
      
      char rPad(byte iRow, byte iCol, char sText[], byte length, char pad) {
        char s[21];
        byte sLen = strlen(sText);
        memcpy(s, sText, sLen);
        memset(s + sLen, pad, length - sLen);
        s[length] = 0;
        print(iRow, iCol, s);
      }  
      
      void setCustChar_P(byte slot, const byte *charDef) {
        i2cLcdSetCustChar_P(slot, charDef);
      }
      
      void writeCustChar(byte iRow, byte iCol, byte slot) {
        screen[iRow * 20 + iCol] = slot;
      }
      
      void update() {
        for (byte row = 0; row < 4; row++) {
          if (fastWrite) i2cLcdSetCursor(0, row);
          for (byte col = 0; col < 20; col++) {
            if (fastWrite) i2cLcdWriteByte(screen[row * 20 + col]);
            else i2cLcdWriteCustChar(col, row, screen[row * 20 + col]);
          }
        }
      }
      
      void setBright(byte val) {
        i2cSetBright(val);
      }
      
      void setContrast(byte val) {
        i2cSetContrast(val);
      }
      
      void saveConfig(void) {
        i2cSaveConfig();
      }
      
      byte getBright(void) {
        return i2cGetBright();
      }
      
      byte getContrast(void) {
        return i2cGetContrast();
      }
      
    private:
      byte screen[80];
      uint8_t i2cLCDAddr;
      boolean fastWrite;

      uint8_t i2cLcdBegin(byte iCols, byte iRows) {
        Wire.beginTransmission(i2cLCDAddr);
        Wire.send(0x01);
        Wire.send(iCols);
        Wire.send(iRows);
        return Wire.endTransmission();
      }
      
      uint8_t i2cLcdClear() {
        Wire.beginTransmission(i2cLCDAddr);
        Wire.send(0x02);
        return Wire.endTransmission();
      }
      
      uint8_t i2cLcdSetCursor(byte iCol, byte iRow) {
        Wire.beginTransmission(i2cLCDAddr);
        Wire.send(0x03);
        Wire.send(iCol);
        Wire.send(iRow);
        return Wire.endTransmission();
      }
      
      uint8_t i2cLcdPrint(byte iCol, byte iRow, char s[]) {
        Wire.beginTransmission(i2cLCDAddr);
        Wire.send(0x04);
        Wire.send(iCol);
        Wire.send(iRow);
        char *p = s;
        while (*p) {
          Wire.send(*p++);
        }
        return Wire.endTransmission();
      }
      
      uint8_t i2cLcdWrite(byte iCol, byte iRow, byte len, char s[]) {
        Wire.beginTransmission(i2cLCDAddr);
        Wire.send(0x14);
        Wire.send(iCol);
        Wire.send(iRow);
        Wire.send(len);
        for (byte i = 0; i < len; i++) Wire.send(s[i]);
        return Wire.endTransmission();
      }
      
      uint8_t i2cLcdWriteByte(char s) {
        Wire.beginTransmission(i2cLCDAddr);
        Wire.send(0x15);
        Wire.send(s);
        return Wire.endTransmission();
      }
      
      uint8_t i2cLcdSetCustChar_P(byte slot, const byte *charDef) {
        Wire.beginTransmission(i2cLCDAddr);
        Wire.send(0x05);
        Wire.send(slot);
        for (byte i = 0; i < 8; i++) {
          Wire.send(pgm_read_byte(charDef++));
        }
        return Wire.endTransmission();
      }
      
      uint8_t i2cLcdWriteCustChar(byte iCol, byte iRow, byte c) {
        Wire.beginTransmission(i2cLCDAddr);
        Wire.send(0x06);
        Wire.send(iCol);
        Wire.send(iRow);
        Wire.send(c);
        return Wire.endTransmission();
      }
      
      uint8_t i2cSetBright(byte val) {
        Wire.beginTransmission(i2cLCDAddr);
        Wire.send(0x07);
        Wire.send(val);
        return Wire.endTransmission();
      }
      
      uint8_t i2cSetContrast(byte val) {
        Wire.beginTransmission(i2cLCDAddr);
        Wire.send(0x08);
        Wire.send(val);
        return Wire.endTransmission();
      }
      
      uint8_t i2cGetBright(void) {
        Wire.beginTransmission(i2cLCDAddr);
        Wire.send(0x09);
        Wire.endTransmission();
        Wire.requestFrom(i2cLCDAddr, (uint8_t) 1);
        while(Wire.available())
        {
          return Wire.receive();
        }
      }
      
      uint8_t i2cGetContrast(void) {
        Wire.beginTransmission(i2cLCDAddr);
        Wire.send(0x0A);
        Wire.endTransmission();
        Wire.requestFrom(i2cLCDAddr, (uint8_t) 1);
        while(Wire.available())
        {
          return Wire.receive();
        }
      }
      
      uint8_t i2cSaveConfig(void) {
        Wire.beginTransmission(i2cLCDAddr);
        Wire.send(0x0B);
        return Wire.endTransmission();
      }
      
      uint8_t i2cLoadConfig(void) {
        Wire.beginTransmission(i2cLCDAddr);
        Wire.send(0x0C);
        return Wire.endTransmission();
      }
      
      int i2cLcdGetVersion(void) {
        //This command may not be implemented in which case bogus values are returned
        //Executing the command twice after other differing requests will validate the result
	int retValue[2];
        for (byte pass = 0; pass < 2; pass++) {
          if (pass) i2cGetBright();
          else i2cGetContrast();
          
          uint8_t * p = (uint8_t *) &retValue[pass];
          Wire.beginTransmission(i2cLCDAddr);
          Wire.send(0x16);
          Wire.endTransmission();
          Wire.requestFrom(i2cLCDAddr, (uint8_t) 2);
          while (Wire.available()) {
            *(p++) = Wire.receive();
          }
        }
        if (retValue[0] == retValue[1]) return retValue[0];
        else return 0;
      }
  };
#endif
