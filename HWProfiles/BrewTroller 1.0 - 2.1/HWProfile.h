/*
BrewTroller 1.0 - 2.1 Hardware Configuration
*/

#ifndef BT_HWPROFILE
#define BT_HWPROFILE
  
  #define ENCODER_OLD_CONSTRUCTOR
  #define ENCA_PIN 2
  #define ENCB_PIN 4
  #define ENTER_PIN 11
  #define ENTER_INT 1
  #define ENCA_INT 2

  #define OUTPUT_GPIO
  #define OUT_GPIO_COUNT 15 //15 Outputs
  #define OUT_GPIO_PINS {0, 1, 3, 6, 7, 8, 9, 10, 12, 13, 14, 24, 18, 16, 15}
/*
	0, //HLT
	1, //Mash
	3, //Kettle
	6, //PV1
	7, //PV2
	8, //PV2
	9, //PV3
	10, //PV4
	12, //PV5
	13, //PV6
	14, //PV7
	24, //PV8
	18, //PV9
	16, //PV10
	15 //Alarm
*/

 
  #define ANALOG_INPUTS
  #define ANALOGIN_COUNT 3
  #define ANALOGIN_PINS {0, 1, 2}
 
  
//**********************************************************************************
// OneWire Temperature Sensor Options
//**********************************************************************************
// TS_ONEWIRE: Enables use of OneWire Temperature Sensors (Future logic may
// support alternatives temperature sensor options.)
#define TS_ONEWIRE
#define TS_ONEWIRE_GPIO
#define TEMP_PIN 5

// TS_ONEWIRE_PPWR: Specifies whether parasite power is used for OneWire temperature
// sensors. Parasite power allows sensors to obtain their power from the data line
// but significantly increases the time required to read the temperature (94-750ms
// based on resolution versus 10ms with dedicated power).
#define TS_ONEWIRE_PPWR 1

// TS_ONEWIRE_RES: OneWire Temperature Sensor Resolution (9-bit - 12-bit). Valid
// options are: 9, 10, 11, 12). Unless parasite power is being used the recommended
// setting is 12-bit (for DS18B20 sensors). DS18S20 sensors can only operate at a max
// of 9 bit. When using parasite power decreasing the resolution reduces the 
// temperature conversion time: 
//   12-bit (0.0625C / 0.1125F) = 750ms 
//   11-bit (0.125C  / 0.225F ) = 375ms 
//   10-bit (0.25C   / 0.45F  ) = 188ms 
//    9-bit (0.5C    / 0.9F   ) =  94ms   
#define TS_ONEWIRE_RES 11

// TS_ONEWIRE_FASTREAD: Enables faster reads of temperatures by reading only the first
// 2 bytes of temperature data and ignoring CRC check.
#define TS_ONEWIRE_FASTREAD
//**********************************************************************************

  #define UI_LCD_4BIT
  #define LCD_RS_PIN 17
  #define LCD_ENABLE_PIN 19
  #define LCD_DATA4_PIN 20
  #define LCD_DATA5_PIN 21
  #define LCD_DATA6_PIN 22
  #define LCD_DATA7_PIN 23

#endif
