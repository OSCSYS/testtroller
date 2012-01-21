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

void pinInit() {
  #ifdef OUTPUT_GPIO
    {
      byte gpioPinNums[OUT_GPIO_COUNT] = OUT_GPIO_PINS;
      for (byte i = 0; i < OUT_GPIO_COUNT; i++) gpioPin[i].setup(gpioPinNums[i], OUTPUT);
    }
  #endif
  
  #ifdef OUTPUT_MUX
    muxLatchPin.setup(MUX_LATCH_PIN, OUTPUT);
    muxDataPin.setup(MUX_DATA_PIN, OUTPUT);
    muxClockPin.setup(MUX_CLOCK_PIN, OUTPUT);
    #if defined MUX_MR_PIN
      muxENPin.setup(MUX_MR_PIN, OUTPUT);
    #elif defined MUX_OE_PIN
      muxENPin.setup(MUX_OE_PIN, OUTPUT);
      muxENPin.set();
    #endif
  #endif
  
  #ifdef HEARTBEAT
    hbPin.setup(HEARTBEAT_PIN, OUTPUT);
  #endif
  
  #ifdef DIGITAL_INPUTS
    {
      byte gpioPinNums[DIGITALIN_COUNT] = DIGITALIN_PINS;
      for (byte i = 0; i < DIGITALIN_COUNT; i++) digitalInPin[i].setup(gpioPinNums[i], INPUT);
    }
  #endif
}

#ifdef OUTPUT_MUX
  void setMUX(unsigned long bits) {
    vlvBits = bits;
    //MUX Valve Code
      //ground latchPin and hold low for as long as you are transmitting
      muxLatchPin.clear();
      //clear everything out just in case to prepare shift register for bit shifting
      muxDataPin.clear();
      muxClockPin.clear();
    
      //for each bit in the long myDataOut
      for (byte i = 0; i < 32; i++)  {
        muxClockPin.clear();
        //create bitmask to grab the bit associated with our counter i and set data pin accordingly (NOTE: 32 - i causes bits to be sent most significant to least significant)
        if ( vlvBits & ((unsigned long)1<<(31 - i)) ) muxDataPin.set(); else muxDataPin.clear();
        //register shifts bits on upstroke of clock pin  
        muxClockPin.set();
        //zero the data pin after shift to prevent bleed through
        muxDataPin.clear();
      }
    
      //stop shifting
      muxClockPin.clear();
      muxLatchPin.set();
      delayMicroseconds(10);
      muxLatchPin.clear();
      
      //Enable outputs
      muxENPin.set(MUX_ENABLE_LOGIC);
  }
#endif


