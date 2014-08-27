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

//----- Display frame buffer
const int FRAME_BUFFER_SIZE = SSD1306_LCDWIDTH * SSD1306_LCDHEIGHT / 8;
static byte frame_buf[FRAME_BUFFER_SIZE];

void setup()
{
  lcd.begin();
  
  pinMode(BUTTON1, INPUT_PULLUP);
  pinMode(BUTTON2, INPUT_PULLUP);
  pinMode(BUTTON3, INPUT_PULLUP);
  pinMode(LED1, OUTPUT);
  
  BTSerial.begin(9600); // set the data rate for the BT port
  Serial.begin(9600); 

  // clear frame buffer
  for (int i=0; i < FRAME_BUFFER_SIZE; i++) {
    frame_buf[i] = 0xFF;
  }
  
  drawWelcome();
}

void loop()
{
  if (digitalRead(BUTTON1) == HIGH && button1State == LOW) {
    // transition
    Serial.write("Button 1 released\r\n");

    lcd.invertDisplay(0);
    lcd.clear();
    drawFrameBuffer();

    button1State = HIGH;
    digitalWrite(LED1, LOW);
  }
  
  if (digitalRead(BUTTON1) == LOW && button1State == HIGH) {
    // transition
    Serial.write("Button 1 pressed\r\n");

    lcd.invertDisplay(1);
    
    button1State = LOW;
    digitalWrite(LED1, HIGH);
  }

  if (digitalRead(BUTTON2) == LOW && button2State == HIGH) {
    // transition
    Serial.write("Button 2 down\r\n");
  }

  if (digitalRead(BUTTON3) == LOW && button3State == HIGH) {
    // transition
    Serial.write("Button 3 down\r\n");
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
        drawFrameBuffer();
      }
    }
  }

  delay(10);
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

void drawText() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.setFont(FONT_SIZE_SMALL);
  lcd.print("Hello, world!");

  lcd.setCursor(0, 1);
  lcd.setFont(FONT_SIZE_MEDIUM);
  lcd.print("Hello, world!");

  lcd.setCursor(0, 3);
  lcd.setFont(FONT_SIZE_SMALL);
  lcd.printLong(12345678);

  lcd.setCursor(64, 3);
  lcd.setFont(FONT_SIZE_MEDIUM);
  lcd.printLong(12345678);

  lcd.setCursor(0, 4);
  lcd.setFont(FONT_SIZE_LARGE);
  lcd.printLong(12345678);

  lcd.setCursor(0, 6);
  lcd.setFont(FONT_SIZE_XLARGE);
  lcd.printLong(12345678);
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

void demo() {
  drawText();
  delay(1000);
}
