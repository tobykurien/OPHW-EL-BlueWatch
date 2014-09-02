package za.co.house4hack.h4hwatch.bluetooth;

import java.io.ByteArrayOutputStream;

import za.co.house4hack.h4hwatch.activities.MainActivity;
import android.os.Handler;
import android.os.Message;
import android.util.Log;

public class BluetoothHandler extends Handler {
   // Debugging
   private static final String TAG = "BluetoothHandler";
   private static final boolean D = true;

   // Key names received from the BluetoothService Handler
   public static final String DEVICE_NAME = "device_name";
   public static final String TOAST = "toast";

   // Message types sent from the BluetoothService Handler
   public static final int MESSAGE_STATE_CHANGE = 1;
   public static final int MESSAGE_READ = 2;
   public static final int MESSAGE_WRITE = 3;
   public static final int MESSAGE_DEVICE_NAME = 4;
   public static final int MESSAGE_TOAST = 5;

   protected BluetoothService mService;

   // Name of the connected device
   private String mConnectedDeviceName = null;
   private byte[] stream = new byte[1024];
   private int streamPointer = 0;

   public BluetoothHandler(BluetoothService context) {
      this.mService = context;
   }

   @Override
   public void handleMessage(final Message msg) {
      new Thread() {
         @Override
         public void run() {
            switch (msg.what) {
               case MESSAGE_STATE_CHANGE:
                  if (D) Log.i(TAG, "MESSAGE_STATE_CHANGE: " + msg.arg1);
                  mService.watchState.setBluetooth(msg.arg1);
                  break;
               case MESSAGE_WRITE:
                  byte[] writeBuf = (byte[]) msg.obj;
                  // construct a string from the buffer
                  String writeMessage = new String(writeBuf);
                  // if (D) Toast.makeText(mService, writeMessage,
                  // Toast.LENGTH_SHORT).show();
                  break;
               case MESSAGE_READ:
                  byte[] readBuf = (byte[]) msg.obj;
                  handleIncomingData(readBuf, msg.arg1);
                  break;
               case MESSAGE_DEVICE_NAME:
                  // save the connected device's name
                  mConnectedDeviceName = msg.getData().getString(DEVICE_NAME);
                  break;
               case MESSAGE_TOAST:
                   if (D) Log.i(TAG, "TOAST: " + msg.getData().getString(TOAST));
                  // Toast.makeText(mService, msg.getData().getString(TOAST),
                  // Toast.LENGTH_SHORT).show();
                  if ("Device connection was lost".equals(msg.getData().getString(TOAST))) {
                     mService.watchState.setBluetooth(BluetoothService.STATE_NONE);
                     // reconnect
                     //if (MainActivity.instance != null) MainActivity.instance.connectWatch();
                  }
                  break;
            }
         }
      }.start();

   }

   /**
    * Sends a message.
    * 
    * @param message
    *           A string of text to send.
    */
   private void sendBluetooth(byte[] message) {
      // Check that we're actually connected before trying anything
      if (mService.getState() != BluetoothService.STATE_CONNECTED) { return; }

      // Check that there's actually something to send
      if (message.length > 0) {
         // Get the message bytes and tell the BluetoothChatService to write
         mService.write(message);
      }
   }

   Thread processData = new Thread() {
      public void run() {
         byte[] data = new byte[stream.length];
         int length = 0;
         byte[] remainder = null;
         
         while (true) {
            synchronized (stream) {
               // copy unprocessed data into our data buffer
               for (int i = 0; i < streamPointer; i++)
                  data[i] = stream[i];
               length = streamPointer;
               streamPointer = 0; // consume the data
            }

            if (length > 0) {
               // we have data
               int i = 0;
               // extract a complete packet
               byte[] canFrames = new byte[data.length*2];

               if (remainder != null) {
                  for (int j = 0; j < remainder.length; j++) {
                     canFrames[i++] = remainder[j];
                  }
               }

               for (int j=0; j < length; j++) {
                  canFrames[i++] = data[j];
               }
               
               
               ByteArrayOutputStream os = new ByteArrayOutputStream();
               for (int j = 0; j < i; j++) {
                  if (canFrames[j] != '\n') {
                     os.write(canFrames[j]);
                  } else {
                     String sLine = os.toString().trim();
                     os.reset();
                     mService.watchState.processFrame(sLine);
                  }
               }
               
               if(os.size()>0){
            	   remainder = os.toByteArray();
               }else {
            	   remainder = null;
               }
            }
         }
      }
   };

   /**
    * For speed, let's handle data directly without going through Handler
    * messages
    * 
    * @param bytes
    */
   public void handleIncomingData(byte[] buffer, int bytes) {
      synchronized (stream) {
         if (streamPointer + bytes >= stream.length) {
            //Log.e(TAG, "Input buffer overflow, data discarded");
            return;
         }

         for (int i = streamPointer; i < streamPointer + bytes; i++) {
            stream[i] = buffer[i - streamPointer];
         }
         streamPointer += bytes;
      }

      if (!processData.isAlive()) {
         processData.start();
      }
   }

}
