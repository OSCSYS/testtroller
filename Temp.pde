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

#include "HWProfile.h"

#ifdef TS_ONEWIRE
  #ifdef TS_ONEWIRE_GPIO
    #include <OneWire.h>
    OneWire ds(TEMP_PIN);
  #endif
  #ifdef TS_ONEWIRE_I2C
    #include <DS2482.h>
    DS2482 ds(DS2482_ADDR);
  #endif
  //One Wire Bus on 
  
  void tempInit() {
    #ifdef TS_ONEWIRE_I2C
      if (ds.configure(DS2482_CONFIG_APU | DS2482_CONFIG_SPU)) Serial.println("DS2482\tConfigured");
      else Serial.println("DS2482\tConfigure Failed");
    #endif
    ds.reset();
    ds.skip();
    ds.write(0x4E, TS_ONEWIRE_PPWR); //Write to scratchpad
    ds.write(0x4B, TS_ONEWIRE_PPWR); //Default value of TH reg (user byte 1)
    ds.write(0x46, TS_ONEWIRE_PPWR); //Default value of TL reg (user byte 2)
  
    #if TS_ONEWIRE_RES == 12
      ds.write(0x7F, TS_ONEWIRE_PPWR); //Config Reg (12-bit)
    #elif TS_ONEWIRE_RES == 11
      ds.write(0x5F, TS_ONEWIRE_PPWR); //Config Reg (11-bit)
    #elif TS_ONEWIRE_RES == 10
      ds.write(0x3F, TS_ONEWIRE_PPWR); //Config Reg (10-bit)
    #else //Default to 9-bit
      ds.write(0x1F, TS_ONEWIRE_PPWR); //Config Reg (9-bit)
    #endif
  
    ds.reset();
    ds.skip();
    ds.write(0x48, TS_ONEWIRE_PPWR); //Copy scratchpad to EEPROM
  }


  unsigned long convStart;
  
  #if TS_ONEWIRE_RES == 12
    #define CONV_DELAY 750
  #elif TS_ONEWIRE_RES == 11
    #define CONV_DELAY 375
  #elif TS_ONEWIRE_RES == 10
    #define CONV_DELAY 188
  #else //Default to 9-bit
    #define CONV_DELAY 94
  #endif

  boolean tsReady() {
    #if TS_ONEWIRE_PPWR == 0 //Poll if parasite power is disabled
      if (ds.read() == 0xFF) return 1;
    #endif
    return 0;
  }
  
  boolean validAddr(byte* addr) {
    for (byte i = 0; i < 8; i++) if (addr[i]) return 1;
    return 0;
  }
  
  //This function search for an address that is not currently assigned!
  void getDSAddr(byte addrRet[8]){
  //Leaving stub for external functions (serial and setup) that use this function
    byte scanAddr[8];
    ds.reset_search();
    if (!ds.search(scanAddr)) {
      //No Sensor found, Return
      ds.reset_search();
      return;
    }
    for (byte k = 0; k < 8; k++) addrRet[k] = scanAddr[k];
  }
  
  //Returns Int representing hundreths of degree
  #ifdef TS_ONEWIRE_FASTREAD
    int read_temp(byte* addr) {
      long tempOut = 0;
      byte data[9];
      ds.reset();
      ds.select(addr);   
      ds.write(0xBE, TS_ONEWIRE_PPWR); //Read Scratchpad
      for (byte i = 0; i < 16; i++) {
        tempOut |= (ds.read_bit() << i);
      }
    
      if ( addr[0] == 0x10) tempOut = tempOut * 50; //9-bit DS18S20
      else tempOut = tempOut * 25 / 4; //12-bit DS18B20, etc.
      
      #ifdef USEMETRIC
        return int(tempOut);  
      #else
        return int((tempOut * 9 / 5) + 3200);
      #endif
    }
  #else
    int read_temp(byte* addr) {
      long tempOut;
      byte data[9];
      ds.reset();
      ds.select(addr);   
      ds.write(0xBE, TS_ONEWIRE_PPWR); //Read Scratchpad
      for (byte i = 0; i < 9; i++) {
        data[i] = ds.read();
      }
      if (ds.crc8( data, 8) != data[8]) return -32768;
      tempOut = (data[1] << 8) + data[0];

      if ( addr[0] == 0x10) tempOut = tempOut * 50; //9-bit DS18S20
      else tempOut = tempOut * 25 / 4; //12-bit DS18B20, etc.
      #ifdef USEMETRIC
        return int(tempOut);  
      #else
        return int((tempOut * 9 / 5) + 3200);
      #endif
    }
  #endif  
#else
  void tempInit() {}
  void updateTemps() {}
  void getDSAddr(byte addrRet[8]){};
#endif

void convertAll() {
  ds.reset();
  ds.skip();
  ds.write(0x44, TS_ONEWIRE_PPWR); //Start conversion
}
