/*
BrewTroller 4.0 Pro Hardware Configuration
*/

#ifndef BT_HWPROFILE
#define BT_HWPROFILE

  #define ENCA_PIN 2
  #define ENCB_PIN 4
  #define ENTER_PIN 5
  
  #define OUTPUT_GPIO
  #define OUT_GPIO_COUNT 5 //15 Outputs
  #define OUT_GPIO_PINS {23, 1, 3, 7, 15}
/*
	23, //HLT
	1, //Mash
	3, //Kettle
	7, //Steam
	15 //Alarm
*/
  
  #define OUTPUT_MUX
  #define OUT_MUX_COUNT 16 //16 Outputs
    
  #define MUX_LATCH_PIN 12
  #define MUX_CLOCK_PIN 13
  #define MUX_DATA_PIN 14
  #define MUX_ENABLE_PIN 6
  #define MUX_ENABLE_LOGIC 1

  #define DIGITAL_INPUTS
  #define DIGITALIN_COUNT 5
  #define DIGITALIN_PINS {18, 19, 20, 21, 22}
  
  #define ANALOG_INPUTS
  #define ANALOGIN_COUNT 4
  #define ANALOGIN_PINS {3, 2, 1, 0}
  
  #define UI_LCD_I2C
  #define UI_LCD_I2CADDR 0x01
  #define UI_DISPLAY_SETUP
  
  #define HEARTBEAT
  #define HEARTBEAT_PIN 0
//**********************************************************************************
// OneWire Temperature Sensor Options
//**********************************************************************************
// TS_ONEWIRE: Enables use of OneWire Temperature Sensors (Future logic may
// support alternatives temperature sensor options.)
#define TS_ONEWIRE
#define TS_ONEWIRE_I2C

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
//#define TS_ONEWIRE_FASTREAD

// DS2482_ADDR: I2C Address of DS2482 OneWire Master (used for TS_OneWire_I2C)
// Should be 0x18, 0x19, 0x1A, 0x1B
#define DS2482_ADDR 0x1B
//**********************************************************************************

#endif
