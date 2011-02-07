#ifndef BT_ENUM
#define BT_ENUM

#include "Config.h"

//Pin and Interrupt Definitions
#ifdef BTBOARD_4
  #define ENCA_PIN 2
  #define ENCB_PIN 4
  #define ENTER_PIN 5
#else
  #define ENCA_PIN 2
  #define ENCB_PIN 4
  #define ENTER_PIN 11
  #define ENTER_INT 1
  #define ENCA_INT 2
#endif

#ifndef BTBOARD_4
  #define TEMP_PIN 5
#endif

#define ALARM_PIN 15

//P/V Ouput Defines
#if defined BTBOARD_3 || defined BTBOARD_4
  #define MUX_LATCH_PIN 12
  #define MUX_CLOCK_PIN 13
  #define MUX_DATA_PIN 14
  
  #ifdef BTBOARD_4
    #define MUX_MR_PIN 6
  #else
    #define MUX_OE_PIN 10
  #endif
#endif

#if defined BTBOARD_1 || defined BTBOARD_22
  #define VALVE1_PIN 6 //Pin 4
  #define VALVE2_PIN 7 //Pin 3
  
  #ifdef BTBOARD_22
    #define VALVE3_PIN 25
    #define VALVE4_PIN 26
  #else
    #define VALVE3_PIN 8 //Pin 6
    #define VALVE4_PIN 9 //Pin 7
  #endif
  
  #define VALVE5_PIN 10 //Pin 8
  #define VALVE6_PIN 12 //Pin 7
  #define VALVE7_PIN 13 //Pin 10
  #define VALVE8_PIN 14 //Pin 9
  #define VALVE9_PIN 24 //Pin 12
  #define VALVEA_PIN 18 //Pin 11
  #define VALVEB_PIN 16 //Pin 14
#endif

#ifdef BTBOARD_4
  #define HLTHEAT_PIN 23
  #define MASHHEAT_PIN 1
  #define KETTLEHEAT_PIN 3
  #define STEAMHEAT_PIN 7
  #define PWMPUMP_PIN 7
#else
  #define HLTHEAT_PIN 0
  #define MASHHEAT_PIN 1
  #define KETTLEHEAT_PIN 3
  #define STEAMHEAT_PIN 6
  #define PWMPUMP_PIN 6
#endif

#ifdef BTBOARD_4
  #define HEARTBEAT_PIN 0
  #define DIGIN1_PIN 18
  #define DIGIN2_PIN 19
  #define DIGIN3_PIN 20
  #define DIGIN4_PIN 21
  #define DIGIN5_PIN 22
#endif

//Reverse pin swap on 2.x boards
#ifdef BTBOARD_22
  #define HLTVOL_APIN 2
  #define KETTLEVOL_APIN 0
#else
  #define HLTVOL_APIN 0
  #define KETTLEVOL_APIN 2
#endif

#define MASHVOL_APIN 1
#define STEAMPRESS_APIN 3

#endif

#define VS_HLT 0
#define VS_MASH 1
#define VS_KETTLE 2
#define VS_STEAM 3
#define VS_PUMP 3
