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


#include <EEPROM.h>

void testLCD(byte testNum, byte numTests) {
  clearLCD();
  lcdSetCustChar_P(0, BMP0);
  lcdSetCustChar_P(1, BMP1);
  lcdSetCustChar_P(2, BMP2);
  lcdSetCustChar_P(3, BMP3);
  lcdSetCustChar_P(4, BMP4);
  lcdSetCustChar_P(5, BMP5);
  lcdSetCustChar_P(6, BMP6);
  lcdSetCustChar_P(7, BMP7);

  printLCD_P(3, 0, PSTR("Test   /  : LCD"));
  printLCDLPad(3, 5, itoa(testNum, buf, 10), 2, '0');
  printLCDLPad(3, 8, itoa(numTests, buf, 10), 2, '0');

 for (byte pos = 0; pos < 3; pos++) printLCD_P(pos, 0, PSTR(">"));
 for (byte pos = 0; pos < 3; pos++) printLCD_P(pos, 19, PSTR("<"));
 for (byte pos = 1; pos < 19; pos = pos + 3) {
    lcdWriteCustChar(0, pos + 1, 0);
    lcdWriteCustChar(0, pos + 2, 1);
    lcdWriteCustChar(1, pos, 2); 
    lcdWriteCustChar(1, pos + 1, 3); 
    lcdWriteCustChar(1, pos + 2, 4); 
    lcdWriteCustChar(2, pos, 5); 
    lcdWriteCustChar(2, pos + 1, 6); 
    lcdWriteCustChar(2, pos + 2, 7); 
  }
  while(!enterStatus) delay(100);
  enterStatus = 0;
}

void testEncoder(byte testNum, byte numTests) {
  clearLCD();
  printLCDLPad(0, 1, "", 19, '-');
  printLCD_P(0, 10, PSTR("|"));
  printLCD_P(3, 0, PSTR("Test   /  : Encoder"));
  printLCDLPad(3, 5, itoa(testNum, buf, 10), 2, '0');
  printLCDLPad(3, 8, itoa(numTests, buf, 10), 2, '0');
  encMin = 1;
  encMax = 19;
  encCount = 10;
  byte lastCount = encCount + 1;
  while(!enterStatus) {
    if (lastCount != encCount) {
      lastCount = encCount;
      printLCDLPad(1, 1, " ", 19, ' ');
      printLCD_P(1, lastCount, PSTR("^"));
    }
    delay(1);
  }
  enterStatus = 0;
}

#if defined(__AVR_ATmega1284P__) || defined(__AVR_ATmega1284__)
  #define EEPROM_BLOCK_SIZE 256
#else
  #define EEPROM_BLOCK_SIZE 128
#endif

void testEEPROM(byte testNum, byte numTests) {
  lcdSetCustChar_P(0, CHK);
  clearLCD();
  printLCD_P(3, 0, PSTR("Test   /  : EEPROM"));
  printLCDLPad(3, 5, itoa(testNum, buf, 10), 2, '0');
  printLCDLPad(3, 8, itoa(numTests, buf, 10), 2, '0');
  
  for (byte block = 0; block < 16; block++) {
    printLCD_P(1, block + 2, PSTR("W"));
    for (int pos = 0; pos < EEPROM_BLOCK_SIZE; pos++) EEPROM.write(block * EEPROM_BLOCK_SIZE + pos, pos);
    printLCD_P(1, block + 2, PSTR("V"));
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
  }
  while(!enterStatus) delay(100);
  enterStatus = 0;
}

void testOutputs(byte testNum, byte numTests) {
  clearLCD();
  printLCD_P(3, 0, PSTR("Test   /  : Outputs"));
  printLCDLPad(3, 5, itoa(testNum, buf, 10), 2, '0');
  printLCDLPad(3, 8, itoa(numTests, buf, 10), 2, '0');
  
  printLCDCenter(1, 0, "HLT Heat", 20);
  digitalWrite(HLTHEAT_PIN, HIGH);
  delay(1000);
  digitalWrite(HLTHEAT_PIN, LOW);

  printLCDCenter(1, 0, "Mash Heat", 20);
  digitalWrite(MASHHEAT_PIN, HIGH);
  delay(1000);
  digitalWrite(MASHHEAT_PIN, LOW);

  printLCDCenter(1, 0, "Kettle Heat", 20);
  digitalWrite(KETTLEHEAT_PIN, HIGH);
  delay(1000);
  digitalWrite(KETTLEHEAT_PIN, LOW);

#ifdef USESTEAM
  printLCDCenter(1, 0, "Steam Heat", 20);
  digitalWrite(STEAMHEAT_PIN, HIGH);
  delay(1000);
  digitalWrite(STEAMHEAT_PIN, LOW);
#endif

  printLCDCenter(1, 0, "", 20);
  printLCD_P(1, 6, PSTR("Valve"));
  for(byte valve = 0; valve < 32; valve++) {
    printLCDLPad(1, 12, itoa(valve + 1, buf, 10), 2, '0');
    setValves((unsigned long)1<<valve);
    delay(1000);
  }
  setValves(0);

  printLCDCenter(1, 0, "Alarm", 20);
  digitalWrite(ALARM_PIN, HIGH);
  delay(1000);
  digitalWrite(ALARM_PIN, LOW);
  
}

void testOneWire(byte testNum, byte numTests) {
  clearLCD();
  printLCD_P(3, 0, PSTR("Test   /  : OneWire"));
  printLCDLPad(3, 5, itoa(testNum, buf, 10), 2, '0');
  printLCDLPad(3, 8, itoa(numTests, buf, 10), 2, '0');
  byte addr[8];
  getDSAddr(addr);
  printLCD_P(0, 0, PSTR("Found Address:"));
  for (byte i=0; i<8; i++) printLCDLPad(1,i*2+2,itoa(addr[i], buf, 16), 2, '0');  

  #ifdef USEMETRIC
    printLCD_P(2, 13, PSTR("C"));
  #else
    printLCD_P(2, 13, PSTR("F"));  
  #endif

  convertAll();
  unsigned long convertTime = millis();
  
  while(!enterStatus) {
    if (millis() - convertTime > 750) {
      float temp = read_temp(addr);
      ftoa(temp, buf, 2);
      printLCDLPad(2, 7, buf, 6, ' ');
      convertAll();
      convertTime = millis();
    }
  }
  enterStatus = 0;

  
}

void testVSensor(byte testNum, byte numTests) {
  clearLCD();
  printLCD_P(3, 0, PSTR("Test   /  : VSensors"));
  printLCDLPad(3, 5, itoa(testNum, buf, 10), 2, '0');
  printLCDLPad(3, 8, itoa(numTests, buf, 10), 2, '0');
  printLCD_P(0, 0, PSTR("HLT"));
  printLCD_P(1, 0, PSTR("Mash"));
  printLCD_P(0, 9, PSTR("Kettle"));
  printLCD_P(1, 10, PSTR("Steam"));
  unsigned long lastRead;
  while(!enterStatus) {
    if (millis() - lastRead > 500) {
      float v = 5.0 / 1024 * analogRead(HLTVOL_APIN);
      ftoa(v, buf, 1);
      printLCDLPad(0, 4, buf, 3, ' ');
    
      v = 5.0 / 1024 * analogRead(MASHVOL_APIN);
      ftoa(v, buf, 1);
      printLCDLPad(1, 5, buf, 3, ' ');
    
      v = 5.0 / 1024 * analogRead(KETTLEVOL_APIN);
      ftoa(v, buf, 1);
      printLCDLPad(0, 16, buf, 3, ' ');
    
      v = 5.0 / 1024 * analogRead(STEAMPRESS_APIN);
      ftoa(v, buf, 1);
      printLCDLPad(1, 16, buf, 3, ' ');
      lastRead = millis();
    }  
  }
  enterStatus = 0;
}

void testTimer(byte testNum, byte numTests) {
  clearLCD();
  printLCD_P(3, 0, PSTR("Test   /  : Timer"));
  printLCDLPad(3, 5, itoa(testNum, buf, 10), 2, '0');
  printLCDLPad(3, 8, itoa(numTests, buf, 10), 2, '0');
  for(byte count = 11; count > 0; count--) {
    printLCDLPad(1, 9, itoa(count - 1, buf, 10), 2, '0');
    delay(1000);
  }
}

void testComplete() {
  clearLCD();
  printLCD_P(3, 0, PSTR("Tests Complete."));
  while(!enterStatus) delay(100);
  enterStatus = 0;  
}

void manTestValves () {
  encMin = 0;

#ifdef ONBOARDPV
  encMax = 11;
#else
  encMax = MUXBOARDS * 8;
#endif

  //The left most bit being displayed (Set to MAX + 1 to force redraw)
  byte firstBit = encMax + 1;
  encCount = 0;
  byte lastCount = 1;

  clearLCD();
  printLCD_P(0, 0, PSTR("Manual Valve Testing"));
  printLCD_P(3, 15, PSTR("EXIT"));
  
  while(1) {
    if (encCount != lastCount) {
      lastCount = encCount;
      
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
    
    if (enterStatus == 1) {
      enterStatus = 0;
      if (lastCount == encMax) return;
      setValves(vlvBits ^ ((unsigned long)1<<lastCount));
      for (byte i = firstBit; i < min(encMax, firstBit + 18); i++) if (vlvBits & ((unsigned long)1<<i)) printLCD_P(1, i - firstBit + 1, PSTR("1")); else printLCD_P(1, i - firstBit + 1, PSTR("0"));
    } else if (enterStatus == 2) {
      enterStatus = 0;
      return;
    }
  }

}
