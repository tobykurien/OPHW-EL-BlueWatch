/*
 * Copyright (C) 2009 The Android Open Source Project
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package za.co.house4hack.h4hwatch.bluetooth;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.UUID;

import za.co.house4hack.h4hwatch.R;
import za.co.house4hack.h4hwatch.activities.MainActivity;
import za.co.house4hack.h4hwatch.logic.WatchServiceHelper;
import za.co.house4hack.h4hwatch.logic.WatchState;
import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothServerSocket;
import android.bluetooth.BluetoothSocket;
import android.content.Intent;
import android.os.Binder;
import android.os.Bundle;
import android.os.IBinder;
import android.os.Message;
import android.util.Log;

/**
 * This class does all the work for setting up and managing Bluetooth
 * connections with other devices. It has a thread that listens for
 * incoming connections, a thread for connecting with a device, and a
 * thread for performing data transmissions when connected.
 */
public class BluetoothService extends Service {
   // Debugging
   private static final String TAG = "BluetoothService";
   private static final boolean D = true;

   // Name for the SDP record when creating server socket
   private static final String NAME_SECURE = "SerialPort-1";
   private static final String NAME_INSECURE = "SerialPort-1";

   // Unique UUID for this application
   private static final UUID MY_UUID_SECURE = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB");
   private static final UUID MY_UUID_INSECURE = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB");

   // Member fields
   private BluetoothAdapter mAdapter;
   private BluetoothHandler mHandler;
   private AcceptThread mSecureAcceptThread;
   private AcceptThread mInsecureAcceptThread;
   private ConnectThread mConnectThread;
   private ConnectedThread mConnectedThread;
   private int mState;
   
   public WatchState watchState = new WatchState();
   public WatchServiceHelper helper;
   
   // Constants that indicate the current connection state
   public static final int STATE_NONE = 0; // we're doing nothing
   public static final int STATE_LISTEN = 1; // now listening for incoming
                                             // connections
   public static final int STATE_CONNECTING = 2; // now initiating an outgoing
                                                 // connection
   public static final int STATE_CONNECTED = 3; // now connected to a remote
                                                // device
   // Unique Identification Number for the Notification.
   // We use it on Notification start, and to cancel it.
   private int NOTIFICATION = 10;
   private NotificationManager mNM;

   //
   // /**
   // * Constructor. Prepares a new BluetoothChat session.
   // *
   // * @param context
   // * The UI Activity Context
   // * @param handler
   // * A Handler to send messages back to the UI Activity
   // */
   // public BluetoothService(Context context, Handler handler) {
   // mAdapter = BluetoothAdapter.getDefaultAdapter();
   // mState = STATE_NONE;
   // mHandler = handler;
   // }

   // This is the object that receives interactions from clients. See
   // RemoteService for a more complete example.
   private final IBinder mBinder = new LocalBinder();

   @Override
   public IBinder onBind(Intent arg0) {
      if (D) Log.d(TAG, "onBind");
      return mBinder;
   }

   /**
    * Class for clients to access. Because we know this service always runs in
    * the same process as its clients, we don't need to deal with IPC.
    */
   public class LocalBinder extends Binder {
      public BluetoothService getService() {
         return BluetoothService.this;
      }
   }

   /**
    * Set the current state of the chat connection
    * 
    * @param state
    *           An integer defining the current connection state
    */
   private synchronized void setState(int state) {
      if (D) Log.d(TAG, "setState() " + mState + " -> " + state);
      mState = state;

      // Give the new state to the Handler so the UI Activity can update
      //mHandler.obtainMessage(BluetoothHandler.MESSAGE_STATE_CHANGE, state, -1).sendToTarget();
      Message m = new Message();
      m.what = BluetoothHandler.MESSAGE_STATE_CHANGE;
      m.arg1 = state;
      mHandler.handleMessage(m);
   }

   /**
    * Return the current connection state.
    */
   public synchronized int getState() {
      return mState;
   }

   @Override
   public void onCreate() {
      super.onCreate();
      if (D) Log.d(TAG, "onCreate");

      helper = new WatchServiceHelper(this);
      
      mAdapter = BluetoothAdapter.getDefaultAdapter();
      if (mAdapter != null) {
          mState = STATE_NONE;
          mHandler = new BluetoothHandler(this);
          mNM = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);

          start();
      }
   }

   /**
    * Stop all threads
    */
   public void onDestroy() {
      if (D) Log.d(TAG, "onDestroy");
      mNM.cancel(NOTIFICATION);

      if (mConnectThread != null) {
         mConnectThread.cancel();
         mConnectThread = null;
      }

      if (mConnectedThread != null) {
         mConnectedThread.cancel();
         mConnectedThread = null;
      }

      if (mSecureAcceptThread != null) {
         mSecureAcceptThread.cancel();
         mSecureAcceptThread = null;
      }

      if (mInsecureAcceptThread != null) {
         mInsecureAcceptThread.cancel();
         mInsecureAcceptThread = null;
      }
      setState(STATE_NONE);
   }

   public synchronized void start() {
      if (D) Log.d(TAG, "start");
      
      // Cancel any thread attempting to make a connection
      if (mConnectThread != null) {
         mConnectThread.cancel();
         mConnectThread = null;
      }

      // Cancel any thread currently running a connection
      if (mConnectedThread != null) {
         mConnectedThread.cancel();
         mConnectedThread = null;
      }

      setState(STATE_LISTEN);

      // Start the thread to listen on a BluetoothServerSocket
      if (mSecureAcceptThread == null) {
         mSecureAcceptThread = new AcceptThread(true);
         mSecureAcceptThread.start();
      }
      if (mInsecureAcceptThread == null) {
         mInsecureAcceptThread = new AcceptThread(false);
         mInsecureAcceptThread.start();
      }
      
      // display a notification
      showNotification(" bluetooth service started.");
   }

   /**
    * Start the ConnectThread to initiate a connection to a remote device.
    * 
    * @param device
    *           The BluetoothDevice to connect
    * @param secure
    *           Socket Security type - Secure (true) , Insecure (false)
    */
   public synchronized void connect(BluetoothDevice device, boolean secure) {
      if (D) Log.d(TAG, "connect to: " + device);

      // Cancel any thread attempting to make a connection
      if (mState == STATE_CONNECTING) {
         if (mConnectThread != null) {
            mConnectThread.cancel();
            mConnectThread = null;
         }
      }

      // Cancel any thread currently running a connection
      if (mConnectedThread != null) {
         mConnectedThread.cancel();
         mConnectedThread = null;
      }

      // Start the thread to connect with the given device
      mConnectThread = new ConnectThread(device, secure);
      mConnectThread.start();
      setState(STATE_CONNECTING);
   }

   /**
    * Start the ConnectedThread to begin managing a Bluetooth connection
    * 
    * @param socket
    *           The BluetoothSocket on which the connection was made
    * @param device
    *           The BluetoothDevice that has been connected
    */
   public synchronized void connected(BluetoothSocket socket, BluetoothDevice device, final String socketType) {
      if (D) Log.d(TAG, "connected, Socket Type:" + socketType);

      // Cancel the thread that completed the connection
      if (mConnectThread != null) {
         mConnectThread.cancel();
         mConnectThread = null;
      }

      // Cancel any thread currently running a connection
      if (mConnectedThread != null) {
         mConnectedThread.cancel();
         mConnectedThread = null;
      }

      // Cancel the accept thread because we only want to connect to one device
      if (mSecureAcceptThread != null) {
         mSecureAcceptThread.cancel();
         mSecureAcceptThread = null;
      }
      if (mInsecureAcceptThread != null) {
         mInsecureAcceptThread.cancel();
         mInsecureAcceptThread = null;
      }

      // Start the thread to manage the connection and perform transmissions
      mConnectedThread = new ConnectedThread(socket, socketType);
      mConnectedThread.start();

      // Send the name of the connected device back to the UI Activity
      Message msg = mHandler.obtainMessage(BluetoothHandler.MESSAGE_DEVICE_NAME);
      Bundle bundle = new Bundle();
      bundle.putString(BluetoothHandler.DEVICE_NAME, device.getName());
      msg.setData(bundle);
      mHandler.sendMessage(msg);

      setState(STATE_CONNECTED);
   }

   /**
    * Write to the ConnectedThread in an unsynchronized manner
    * 
    * @param out
    *           The bytes to write
    * @see ConnectedThread#write(byte[])
    */
   public void write(byte[] out) {
      // Create temporary object
      ConnectedThread r;
      // Synchronize a copy of the ConnectedThread
      synchronized (this) {
         if (mState != STATE_CONNECTED) return;
         r = mConnectedThread;
      }
      // Perform the write unsynchronized
      r.write(out);
   }

   /**
    * Indicate that the connection attempt failed and notify the UI Activity.
    */
   private void connectionFailed() {
      // Send a failure message back to the Activity
      Message msg = mHandler.obtainMessage(BluetoothHandler.MESSAGE_TOAST);
      Bundle bundle = new Bundle();
      bundle.putString(BluetoothHandler.TOAST, "Unable to connect device");
      msg.setData(bundle);
      mHandler.sendMessage(msg);

      // Start the service over to restart listening mode
      BluetoothService.this.start();
   }

   /**
    * Indicate that the connection was lost and notify the UI Activity.
    */
   private void connectionLost() {
      // Send a failure message back to the Activity
      Message msg = mHandler.obtainMessage(BluetoothHandler.MESSAGE_TOAST);
      Bundle bundle = new Bundle();
      bundle.putString(BluetoothHandler.TOAST, "Device connection was lost");
      msg.setData(bundle);
      mHandler.sendMessage(msg);

      // Start the service over to restart listening mode
      BluetoothService.this.start();
   }

   /**
    * This thread runs while listening for incoming connections. It behaves
    * like a server-side client. It runs until a connection is accepted
    * (or until cancelled).
    */
   private class AcceptThread extends Thread {
      // The local server socket
      private final BluetoothServerSocket mmServerSocket;
      private String mSocketType;

      public AcceptThread(boolean secure) {
         BluetoothServerSocket tmp = null;
         mSocketType = secure ? "Secure" : "Insecure";

         // Create a new listening server socket
         try {
            if (secure) {
               tmp = mAdapter.listenUsingRfcommWithServiceRecord(NAME_SECURE, MY_UUID_SECURE);
            } else {
               tmp = mAdapter.listenUsingInsecureRfcommWithServiceRecord(NAME_INSECURE, MY_UUID_INSECURE);
            }
         } catch (IOException e) {
            Log.e(TAG, "Socket Type: " + mSocketType + "listen() failed", e);
         }
         mmServerSocket = tmp;
      }

      public void run() {
         if (D) Log.d(TAG, "Socket Type: " + mSocketType + "BEGIN mAcceptThread" + this);
         setName("AcceptThread" + mSocketType);

         BluetoothSocket socket = null;

         // Listen to the server socket if we're not connected
         while (mmServerSocket != null && mState != STATE_CONNECTED) {
            try {
               // This is a blocking call and will only return on a
               // successful connection or an exception
               socket = mmServerSocket.accept();
            } catch (IOException e) {
               Log.e(TAG, "Socket Type: " + mSocketType + "accept() failed", e);
               break;
            }

            // If a connection was accepted
            if (socket != null) {
               synchronized (BluetoothService.this) {
                  switch (mState) {
                     case STATE_LISTEN:
                     case STATE_CONNECTING:
                        // Situation normal. Start the connected thread.
                        connected(socket, socket.getRemoteDevice(), mSocketType);
                        Log.d(TAG, "Connected!");
                        break;
                     case STATE_NONE:
                     case STATE_CONNECTED:
                        // Either not ready or already connected. Terminate new
                        // socket.
                        try {
                           socket.close();
                           Log.d(TAG, "Closed socket");
                        } catch (IOException e) {
                           Log.e(TAG, "Could not close unwanted socket", e);
                        }
                        break;
                  }
               }
            }
         }
         if (D) Log.i(TAG, "END mAcceptThread, socket Type: " + mSocketType);

      }

      public void cancel() {
         if (D) Log.d(TAG, "Socket Type" + mSocketType + "cancel " + this);
         try {
            if (mmServerSocket != null) mmServerSocket.close();
         } catch (IOException e) {
            Log.e(TAG, "Socket Type" + mSocketType + "close() of server failed", e);
         }
      }
   }

   /**
    * This thread runs while attempting to make an outgoing connection
    * with a device. It runs straight through; the connection either
    * succeeds or fails.
    */
   private class ConnectThread extends Thread {
      private final BluetoothSocket mmSocket;
      private final BluetoothDevice mmDevice;
      private String mSocketType;

      public ConnectThread(BluetoothDevice device, boolean secure) {
         mmDevice = device;
         BluetoothSocket tmp = null;
         mSocketType = secure ? "Secure" : "Insecure";

         // Get a BluetoothSocket for a connection with the
         // given BluetoothDevice
         try {
            if (secure) {
               tmp = device.createRfcommSocketToServiceRecord(MY_UUID_SECURE);
            } else {
               tmp = device.createInsecureRfcommSocketToServiceRecord(MY_UUID_INSECURE);
            }
         } catch (IOException e) {
            Log.e(TAG, "Socket Type: " + mSocketType + "create() failed", e);
         }
         mmSocket = tmp;
      }

      public void run() {
         Log.i(TAG, "BEGIN mConnectThread SocketType:" + mSocketType);
         setName("ConnectThread" + mSocketType);

         // Always cancel discovery because it will slow down a connection
         mAdapter.cancelDiscovery();

         // Make a connection to the BluetoothSocket
         try {
            // This is a blocking call and will only return on a
            // successful connection or an exception
            mmSocket.connect();
         } catch (IOException e) {
            // Close the socket
            try {
               mmSocket.close();
            } catch (IOException e2) {
               Log.e(TAG, "unable to close() " + mSocketType + " socket during connection failure", e2);
            }
            connectionFailed();
            return;
         }

         // Reset the ConnectThread because we're done
         synchronized (BluetoothService.this) {
            mConnectThread = null;
         }

         // Start the connected thread
         connected(mmSocket, mmDevice, mSocketType);
      }

      public void cancel() {
         try {
            mmSocket.close();
         } catch (IOException e) {
            Log.e(TAG, "close() of connect " + mSocketType + " socket failed", e);
         }
      }
   }

   /**
    * This thread runs during a connection with a remote device.
    * It handles all incoming and outgoing transmissions.
    */
   private class ConnectedThread extends Thread {
      private final BluetoothSocket mmSocket;
      private final InputStream mmInStream;
      private final OutputStream mmOutStream;

      public ConnectedThread(BluetoothSocket socket, String socketType) {
         Log.d(TAG, "create ConnectedThread: " + socketType);
         mmSocket = socket;
         InputStream tmpIn = null;
         OutputStream tmpOut = null;

         // Get the BluetoothSocket input and output streams
         try {
            tmpIn = socket.getInputStream();
            tmpOut = socket.getOutputStream();
         } catch (IOException e) {
            Log.e(TAG, "temp sockets not created", e);
         }

         mmInStream = tmpIn;
         mmOutStream = tmpOut;
      }

      public void run() {
         Log.i(TAG, "BEGIN mConnectedThread");
         byte[] buffer = new byte[1024];
         int bytes;

         // Keep listening to the InputStream while connected
         while (true) {
            try {
               // Read from the InputStream
               bytes = mmInStream.read(buffer);

               // Send the obtained bytes to the UI Activity
               mHandler.handleIncomingData(buffer, bytes); //obtainMessage(BluetoothHandler.MESSAGE_READ, bytes, -1, buffer).sendToTarget();
            } catch (IOException e) {
               Log.e(TAG, "disconnected", e);
               connectionLost();
               // Start the service over to restart listening mode
               BluetoothService.this.start();
               break;
            } catch (Exception e2) {
               Log.e(TAG, "Error reading form device", e2);
            }
         }
      }

      /**
       * Write to the connected OutStream.
       * 
       * @param buffer
       *           The bytes to write
       */
      public void write(byte[] buffer) {
         try {
            mmOutStream.write(buffer);

            // Share the sent message back to the UI Activity
            mHandler.obtainMessage(BluetoothHandler.MESSAGE_WRITE, -1, -1, buffer).sendToTarget();
         } catch (IOException e) {
            Log.e(TAG, "Exception during write", e);
         }
      }

      public void cancel() {
         try {
            mmSocket.close();
         } catch (IOException e) {
            Log.e(TAG, "close() of connect socket failed", e);
         }
      }
   }

   /**
    * Show a notification while this service is running.
    */
   public void showNotification(String text) {
      // In this sample, we'll use the same text for the ticker and the expanded
      // notification
      // CharSequence text = "DroidOrb waiting for accessory"; //
      // getText(R.string.local_service_started);

      // Set the icon, scrolling text and timestamp
      Notification notification = new Notification(R.drawable.ic_launcher, text, System.currentTimeMillis());

      // The PendingIntent to launch our activity if the user selects this
      // notification
      Intent intent = new Intent(this, MainActivity.class);
      intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
      PendingIntent contentIntent = PendingIntent.getActivity(this, 0, intent, 0);

      // Set the info for the views that show in the notification panel.
      notification.setLatestEventInfo(this, getString(R.string.app_name), text, contentIntent);
      notification.flags |= Notification.FLAG_ONGOING_EVENT;

      // Send the notification.
      mNM.notify(NOTIFICATION, notification);
   }
}
