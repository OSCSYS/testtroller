#ifdef TRIGGERS
void trigInit() {
  for (byte i = 0; i < 5; i++) { triggers[i] = 0; }
  digInPin[0].attachPCInt(RISING, trig0ISR);
  digInPin[1].attachPCInt(RISING, trig1ISR);
  digInPin[2].attachPCInt(RISING, trig2ISR);
  digInPin[3].attachPCInt(RISING, trig3ISR);
  digInPin[4].attachPCInt(RISING, trig4ISR);
}

void trig0ISR() { triggers[0] = 1; trigReset = millis(); }
void trig1ISR() { triggers[1] = 1; trigReset = millis(); }
void trig2ISR() { triggers[2] = 1; trigReset = millis(); }
void trig3ISR() { triggers[3] = 1; trigReset = millis(); }
void trig4ISR() { triggers[4] = 1; trigReset = millis(); }
#endif
