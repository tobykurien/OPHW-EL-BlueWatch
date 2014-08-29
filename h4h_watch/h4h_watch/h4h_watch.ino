#include <Wire.h>
#include <MultiLCD.h>
#include <SoftwareSerial.h>

//----- OLED instance
LCD_SSD1306 lcd; /* for SSD1306 OLED module */

//----- BT instance
SoftwareSerial BTSerial(2, 3); //Connect HC-06, RX, TX

//----- Hardware buttons
int BUTTON1 = 5;
int button1State = HIGH;

int BUTTON2 = 7;
int button2State = HIGH;

int BUTTON3 = 8;
int button3State = HIGH;

//----- Hardware LED
int LED1 = 6;

//----- Bluetooth commands
const byte CMD_FRAME_BUFFER = 0x1;

const byte STATE_IDLE = 0x1;
const byte STATE_READING = 0x2;

byte state = STATE_IDLE;
int stateFbCounter = 0; // counter for reading frame buffer data
long lastBtRead = 0;
const int BT_TIMEOUT_SECS = 10;

//----- Display frame buffer
const int FRAME_BUFFER_SIZE = SSD1306_LCDWIDTH * SSD1306_LCDHEIGHT / 8;
static byte frame_buf[FRAME_BUFFER_SIZE];

const int DISPLAY_TIMEOUT_SECS = 10;
long display_timeout = millis();
boolean display_awake = true;

void setup() {
  lcd.begin();
  
  pinMode(BUTTON1, INPUT_PULLUP);
  pinMode(BUTTON2, INPUT_PULLUP);
  pinMode(BUTTON3, INPUT_PULLUP);
  pinMode(LED1, OUTPUT);
  
  BTSerial.begin(9600); // set the data rate for the BT port
  Serial.begin(9600); 

  // clear frame buffer
  for (int i=0; i < FRAME_BUFFER_SIZE; i++) {
    frame_buf[i] = 0x0;
  }
  
  drawWelcome();
  requestFrameBuffer();
}

void loop() {
  handleButtons();
  handleBluetooth();
  handleDisplayTimeout();
  delay(10);
}

void handleButtons() {
  boolean transition = false;
  
  if (digitalRead(BUTTON1) == LOW && button1State == HIGH) {
    // transition
    button1State = LOW;
    transition = true;
    digitalWrite(LED1, HIGH);
  }

  if (digitalRead(BUTTON1) == HIGH && button1State == LOW) {
    // transition
    button1State = HIGH;
    transition = true;
    digitalWrite(LED1, LOW);
    if (display_awake) BTSerial.write("BUTTON1\n");
  }

  if (digitalRead(BUTTON2) == LOW && button2State == HIGH) {
    // transition
    transition = true;
    button2State = LOW;
  }

  if (digitalRead(BUTTON2) == HIGH && button2State == LOW) {
    // transition
    transition = true;
    button2State = HIGH;
    if (display_awake) BTSerial.write("BUTTON2\n");
  }

  if (digitalRead(BUTTON3) == LOW && button3State == HIGH) {
    // transition
    transition = true;
    button3State = LOW;
  }

  if (digitalRead(BUTTON3) == HIGH && button3State == LOW) {
    // transition
    transition = true;
    button3State = HIGH;
    if (display_awake) BTSerial.write("BUTTON3\n");
  }

  if (transition) {
    if (button1State == LOW || button2State == LOW || button3State == LOW) {
      lcd.invertDisplay(1);      
      if (!display_awake) requestFrameBuffer();
    } else {
      lcd.invertDisplay(0);
    }
    wakeDisplay();
  }
}

void handleBluetooth() {
  if (millis()/1000 - lastBtRead > BT_TIMEOUT_SECS) {
    state = STATE_IDLE;
  }
  
  while (BTSerial.available()) {
    byte c = BTSerial.read();
    if (state == STATE_IDLE && c == CMD_FRAME_BUFFER) {
      // start reading frame buffer data
      state = STATE_READING;
      stateFbCounter = 0;
    } else if (state == STATE_READING) {
      frame_buf[stateFbCounter++] = c;
      if (stateFbCounter >= FRAME_BUFFER_SIZE) {
        // done reading frame buffer
        state = STATE_IDLE;
        wakeDisplay();
        drawFrameBuffer();
      }
    }
  }
}

void requestFrameBuffer() {
  lastBtRead = millis()/1000;
  // send a request to the watch for a frame buffer to display
  BTSerial.write("FRAME_BUFFER\n");
}

void handleDisplayTimeout() {
  if (display_awake == true && (millis()/1000 - display_timeout) > DISPLAY_TIMEOUT_SECS) {
    lcd.clear();
    display_awake = false;
  }
}

void wakeDisplay() {
  display_timeout = millis() / 1000;
  display_awake = true;
}

void drawWelcome() {
  lcd.clear();

  lcd.setCursor(0, 0);
  lcd.setFont(FONT_SIZE_SMALL);
  lcd.print("House4Hack Watch");
  lcd.setCursor(0, 1);
  lcd.print("v0.01-alpha");
  lcd.setCursor(0, 2);
  lcd.print("");
  lcd.setCursor(0, 3);
  lcd.print("Load app and");
  lcd.setCursor(0, 4);
  lcd.print("connect to start");
}

void drawFrameBuffer() {
/*
  for (int page=0; page < 16; page++)
    for (int x=0; x < 128; x++)
      lcd.draw8x8(&frame_buf[0], x*(page+1), page);
*/
    lcd.ssd1306_command(SSD1306_SETLOWCOLUMN | 0x0);  // low col = 0
    lcd.ssd1306_command(SSD1306_SETHIGHCOLUMN | 0x0);  // hi col = 0
    lcd.ssd1306_command(SSD1306_SETSTARTLINE | 0x0); // line #0

    // save I2C bitrate
    uint8_t twbrbackup = TWBR;
    TWBR = 18; // upgrade to 400KHz!

    byte *p = frame_buf;
    byte x = 0;
    byte y = 0;
    byte width = 128;
    byte height = 64;

    height >>= 3;
    width >>= 3;
    y >>= 3;
    for (byte i = 0; i < height; i++) {
      // send a bunch of data in one xmission
        lcd.ssd1306_command(0xB0 + i + y);//set page address
        lcd.ssd1306_command(x & 0xf);//set lower column address
        lcd.ssd1306_command(0x10 | (x >> 4));//set higher column address

        for(byte j = 0; j < 8; j++){
            Wire.beginTransmission(SSD1306_I2C_ADDRESS);
            Wire.write(0x40);
            for (byte k = 0; k < width; k++, p++) {
                Wire.write(*p);
            }
            Wire.endTransmission();
        }
    }
    TWBR = twbrbackup;  
}

