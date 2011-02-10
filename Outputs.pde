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
#include "Config.h"
#include "Enum.h"

#ifdef USESTEAM
  #define LAST_HEAT_OUTPUT VS_STEAM
#else
  #define LAST_HEAT_OUTPUT VS_KETTLE
#endif

void pinInit() {
  alarmPin.setup(ALARM_PIN, OUTPUT);

  #if MUXBOARDS > 0
    muxLatchPin.setup(MUX_LATCH_PIN, OUTPUT);
    muxDataPin.setup(MUX_DATA_PIN, OUTPUT);
    muxClockPin.setup(MUX_CLOCK_PIN, OUTPUT);
    #ifdef BTBOARD_4
      muxMRPin.setup(MUX_MR_PIN, OUTPUT);
    #else
      muxOEPin.setup(MUX_OE_PIN, OUTPUT);
      muxOEPin.set();
    #endif
  #endif
  #ifdef ONBOARDPV
    valvePin[0].setup(VALVE1_PIN, OUTPUT);
    valvePin[1].setup(VALVE2_PIN, OUTPUT);
    valvePin[2].setup(VALVE3_PIN, OUTPUT);
    valvePin[3].setup(VALVE4_PIN, OUTPUT);
    valvePin[4].setup(VALVE5_PIN, OUTPUT);
    valvePin[5].setup(VALVE6_PIN, OUTPUT);
    valvePin[6].setup(VALVE7_PIN, OUTPUT);
    valvePin[7].setup(VALVE8_PIN, OUTPUT);
    valvePin[8].setup(VALVE9_PIN, OUTPUT);
    valvePin[9].setup(VALVEA_PIN, OUTPUT);
    valvePin[10].setup(VALVEB_PIN, OUTPUT);
  #endif
  
  heatPin[VS_HLT].setup(HLTHEAT_PIN, OUTPUT);
  heatPin[VS_MASH].setup(MASHHEAT_PIN, OUTPUT);
#ifdef HLT_AS_KETTLE
  heatPin[VS_KETTLE].setup(HLTHEAT_PIN, OUTPUT);
#else
  heatPin[VS_KETTLE].setup(KETTLEHEAT_PIN, OUTPUT);
#endif

#ifdef USESTEAM
  heatPin[VS_STEAM].setup(STEAMHEAT_PIN, OUTPUT);
#endif
#ifdef PID_FLOW_CONTROL
  heatPin[VS_PUMP].setup(PWMPUMP_PIN, OUTPUT);
#endif

#ifdef BTBOARD_4
  hbPin.setup(HEARTBEAT_PIN, OUTPUT);
  digInPin[0].setup(DIGIN1_PIN, INPUT);
  digInPin[1].setup(DIGIN2_PIN, INPUT);
  digInPin[2].setup(DIGIN3_PIN, INPUT);
  digInPin[3].setup(DIGIN4_PIN, INPUT);
  digInPin[4].setup(DIGIN5_PIN, INPUT);
#endif
}

void setValves(unsigned long bits) {
  vlvBits = bits;
  #if MUXBOARDS > 0
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

    //Enable outputs
    #ifdef BTBOARD_4
      muxMRPin.set();
    #else
      muxOEPin.clear();    
    #endif
  
  #endif
  #ifdef ONBOARDPV
  //Original 11 Valve Code
  for (byte i = 0; i < 11; i++) { if (vlvBits & (1<<i)) valvePin[i].set(); else valvePin[i].clear(); }
  #endif
}

