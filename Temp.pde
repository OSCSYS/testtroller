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


#include <OneWire.h>
//One Wire Bus on 
OneWire ds(TEMP_PIN);

void getDSAddr(byte addrRet[8]){
  ds.reset_search();

  if (!ds.search(addrRet)) {
    //No Sensor found, Return
    ds.reset_search();
    return;
  }
  return;
}

void convertAll() {
  ds.reset();
  ds.skip();
  ds.write(0x44,1);         // start conversion, with parasite power on at the end
}

float read_temp(byte* addr) {
  float temp;
  int rawtemp;
  byte data[12];
  ds.reset();
  ds.select(addr);   
  ds.write(0xBE);         // Read Scratchpad
  for (byte i = 0; i < 9; i++) data[i] = ds.read();
  if ( OneWire::crc8( data, 8) != data[8]) return -1;
  
  rawtemp = (data[1] << 8) + data[0];
  if ( addr[0] != 0x28) temp = (float)rawtemp * 0.5; else temp = (float)rawtemp * 0.0625;
  #ifdef USEMETRIC
    return temp;  
  #else
    return (temp * 1.8) + 32.0;
  #endif
}
