#define BUILD 260 
/************* Test Outputs on the Brewtroller ****************
                       Ver 12 - 5/31/2009
                     Bill Clarkson - aka WBC

This program will turn on the outputs to see if they function and you can 
change the time they are on by increasing the "int timer" value which is set
to 1/4 second or 250.  This program has no inputs to control it so be careful
what you have connected to the outputs when using this program.  If you add
or reduce the number of outputs be sure to change "num_pins" value as well.

*/


// Matt:
// All of the pins BrewTroller uses are set in #define statements in BrewTrollerxxxx.pde 
// Because of the issue with the serial port conflicting with some of the outputs you’ll remember we also added an option for remapping the P/V 3&4 outputs.
// You may want to include the same option for those testing so it works with new and old boards. 
// Again, thinking about supporting a variety of users with this test program we might also want to support users using the future MUXBOARDS option.
//  We can strategically reuse a few chunks of BrewTroller to make your program support everyone.


//**********************************************************************************
// P/V 3-4 Serial Fix
//**********************************************************************************
// BrewTroller 1.0 - 2.0 boards share the output pins used for pump/valve outputs
// 3 and 4 with the serial connection used to flash the board with new software. 
// Newer boards use pins xx and xx for P/V 3 & 4 to avoid a conflict that causes
// these outputs to be momentarily switched on during boot up causing unexpected
// results.
// If you are using a newer board or have implemented a fix to connect P/V to the new
// pins, uncomment the following line. 
// Note: This option is not used when MUXBOARDS is enabled.
//
#define PV34REMAP
//**********************************************************************************


//**********************************************************************************
// USEMUX
//**********************************************************************************
// Uncomment one of the following lines to enable MUX'ing of Pump/Valve Outputs
// Note: MUX'ing requires 1-4 expansion boards providing 8-32 pump/valve outputs
// To use the original 11 Pump/valve outputs included in BrewTroller 1.0 - 2.0 leave
// all lines commented
//
//#define MUXBOARDS 1
//#define MUXBOARDS 2
//#define MUXBOARDS 3
//#define MUXBOARDS 4
//**********************************************************************************

#ifdef MUXBOARDS
  #define MUX_LATCH_PIN 12
  #define MUX_CLOCK_PIN 13
  #define MUX_DATA_PIN 14
#else
  #define VALVE1_PIN 6
  #define VALVE2_PIN 7

#ifdef PV34REMAP
  #define VALVE3_PIN 26
  #define VALVE4_PIN 25
#else
  #define VALVE3_PIN 8
  #define VALVE4_PIN 9
#endif

  #define VALVE5_PIN 10
  #define VALVE6_PIN 12
  #define VALVE7_PIN 13
  #define VALVE8_PIN 14
  #define VALVE9_PIN 24
  #define VALVEA_PIN 18
  #define VALVEB_PIN 16
#endif

#define HLTHEAT_PIN 0
#define MASHHEAT_PIN 1
#define KETTLEHEAT_PIN 3
#define STEAMHEAT_PIN 27

//Heat Output Pin Array
byte heatPins[4] = { HLTHEAT_PIN, MASHHEAT_PIN, KETTLEHEAT_PIN, STEAMHEAT_PIN };


int timer = 250;                  // The higher the number, the slower the timing.

// The following line is no longer used...
// int pins[] = { 0, 1, 3, 6, 7, 25, 26, 10, 12, 13, 14, 24, 18, 16, };          // an array of pin numbers

// Let's seperate the valve and heat pins into two arrays: hpins for heat and vpins for valves. Don't forget the new steam heat pin. Also, we can use a byte variable (0-255) to save a tiny bit of SRAM :)
byte num_hpins = 4;                  // the number of pins (i.e. the length of the array)

// Now the number of vpins changes depending on options so:
#ifdef MUXBOARDS
  byte num_vpins = MUXBOARDS * 8;
#else
  byte num_vpins = 11;
#endif

void setup()
{

  // the counter variable is commonly defined as part of the for statement. And, we can again use a byte instead of an int.
  // int i;

  // let's do the heat pins:
  for (byte i = 0; i < num_hpins; i++)   // the array elements are numbered from 0 to num_pins - 1
  pinMode(heatPins[i], OUTPUT);      // set each heat pin as an output

  // the valve setup is done one of two ways. And since the bit math in the setValves function checks each bit individually without a loop I didn't bother with an array of pins...

#ifdef MUXBOARDS
  pinMode(MUX_LATCH_PIN, OUTPUT);
  pinMode(MUX_CLOCK_PIN, OUTPUT);
  pinMode(MUX_DATA_PIN, OUTPUT);
#else
  pinMode(VALVE1_PIN, OUTPUT);
  pinMode(VALVE2_PIN, OUTPUT);
  pinMode(VALVE3_PIN, OUTPUT);
  pinMode(VALVE4_PIN, OUTPUT);
  pinMode(VALVE5_PIN, OUTPUT);
  pinMode(VALVE6_PIN, OUTPUT);
  pinMode(VALVE7_PIN, OUTPUT);
  pinMode(VALVE8_PIN, OUTPUT);
  pinMode(VALVE9_PIN, OUTPUT);
  pinMode(VALVEA_PIN, OUTPUT);
  pinMode(VALVEB_PIN, OUTPUT);
#endif
  pinMode(HLTHEAT_PIN, OUTPUT);
  pinMode(MASHHEAT_PIN, OUTPUT);
  pinMode(KETTLEHEAT_PIN, OUTPUT);
  pinMode(STEAMHEAT_PIN, OUTPUT);
}

void loop()
{
  // int i;  moved into for statement
  // Heat pins first
  for (byte i = 0; i < num_hpins; i++) { // loop through each pin...
    delay(timer);
    digitalWrite(heatPins[i], HIGH);   // turning it on,
    delay(timer);                  // pausing,
    digitalWrite(heatPins[i], LOW);    // and turning it off.
    delay(timer);
    }
    
  // Now the valves. We want to turn each bit on one at a time 000 0000 0001, 000 0000 0010, 000 0000 0100, and so on
  // The easiest way to do that is to take the number 1 and shift it's position over to the left x bytes.
  // For the first output (1) we move it zero positions. For two we move it one to the left.

  for (byte i = 0; i < num_vpins; i++) { //loop through each valve output...
    // Use the setValves() function to support multiple setups
    delay(timer);
    setValves(1 << i);
    delay(timer);
    setValves(0); // All off
    delay(timer);
  }
}




// The following function comes from BrewTroller's util.pde and is used to set the valve outputs pins:

void setValves (unsigned long valveBits) {
#ifdef MUXBOARDS
//New MUX Valve Code
  //ground latchPin and hold low for as long as you are transmitting
  digitalWrite(MUX_LATCH_PIN, 0);
  //clear everything out just in case to prepare shift register for bit shifting
  digitalWrite(MUX_DATA_PIN, 0);
  digitalWrite(MUX_CLOCK_PIN, 0);

  //for each bit in the long myDataOut
  for (byte i = 0; i < 31; i++)  {
    digitalWrite(MUX_CLOCK_PIN, 0);
    //create bitmask to grab the bit associated with our counter i and set data pin accordingly (NOTE: 31 - i causes bits to be sent most significant to least significant)
    if ( valveBits & ((unsigned long)1<<(32 - i)) ) digitalWrite(MUX_DATA_PIN, 1); else  digitalWrite(MUX_DATA_PIN, 0);
    //register shifts bits on upstroke of clock pin  
    digitalWrite(MUX_CLOCK_PIN, 1);
    //zero the data pin after shift to prevent bleed through
    digitalWrite(MUX_DATA_PIN, 0);
  }

  //stop shifting
  digitalWrite(MUX_CLOCK_PIN, 0);
  digitalWrite(MUX_LATCH_PIN, 1);
#else
//Original 11 Valve Code
  if (valveBits & 1) digitalWrite(VALVE1_PIN, HIGH); else digitalWrite(VALVE1_PIN, LOW);
  if (valveBits & 2) digitalWrite(VALVE2_PIN, HIGH); else digitalWrite(VALVE2_PIN, LOW);
  if (valveBits & 4) digitalWrite(VALVE3_PIN, HIGH); else digitalWrite(VALVE3_PIN, LOW);
  if (valveBits & 8) digitalWrite(VALVE4_PIN, HIGH); else digitalWrite(VALVE4_PIN, LOW);
  if (valveBits & 16) digitalWrite(VALVE5_PIN, HIGH); else digitalWrite(VALVE5_PIN, LOW);
  if (valveBits & 32) digitalWrite(VALVE6_PIN, HIGH); else digitalWrite(VALVE6_PIN, LOW);
  if (valveBits & 64) digitalWrite(VALVE7_PIN, HIGH); else digitalWrite(VALVE7_PIN, LOW);
  if (valveBits & 128) digitalWrite(VALVE8_PIN, HIGH); else digitalWrite(VALVE8_PIN, LOW);
  if (valveBits & 256) digitalWrite(VALVE9_PIN, HIGH); else digitalWrite(VALVE9_PIN, LOW);
  if (valveBits & 512) digitalWrite(VALVEA_PIN, HIGH); else digitalWrite(VALVEA_PIN, LOW);
  if (valveBits & 1024) digitalWrite(VALVEB_PIN, HIGH); else digitalWrite(VALVEB_PIN, LOW);
#endif
}
