#include <SPI.h>
#include <boards.h>
#include <RBL_nRF8001.h>

int Relay = 3;
int stayON = 2000;  // TODO : Adjust


void setup() {
  pinMode(Relay, OUTPUT);
  
  //ble_set_pins(3, 2);  // Default pins set to 6 and 7 for REQN and RDYN
  ble_set_name("SNG-Door");
  ble_begin();
  
  Serial.begin(57600); 
  Serial.println("Start...");
}

void loop() {
  ble_do_events();
  
  if (ble_available()) {
    while(ble_available()) {
      // Read out command
      byte data0 = ble_read();
      byte data1 = ble_read();
      byte data2 = ble_read();
      
      if (data0 == 0x00 && data1 == 0x02 && data2 == 0x01) {        
        digitalWrite(Relay, HIGH);   //Turn off relay
        delay(stayON);
        digitalWrite(Relay, LOW);    //Turn on relay
        
        sendData('O');
      } else {
        sendData('W');
      }
    }
  }
  
  delay(1000);
}

void sendData(char code) {
  if (ble_connected()) {
    ble_write(code);
    if (code == 'O') Serial.println("Data Sent: Door is open");
    else Serial.println("Data Sent: Wrong cmd");
  }
}
