void trigInit() {
  for (byte i = 0; i < 5; i++) { triggers[i] = 0; }
  digInPin[0].attachPCInt(CHANGE, trig0ISR);
  digInPin[1].attachPCInt(CHANGE, trig1ISR);
  digInPin[2].attachPCInt(CHANGE, trig2ISR);
  digInPin[3].attachPCInt(CHANGE, trig3ISR);
  digInPin[4].attachPCInt(CHANGE, trig4ISR);
}

void trig0ISR() { triggers[0] = 1; }
void trig1ISR() { triggers[1] = 1; }
void trig2ISR() { triggers[2] = 1; }
void trig3ISR() { triggers[3] = 1; }
void trig4ISR() { triggers[4] = 1; }
