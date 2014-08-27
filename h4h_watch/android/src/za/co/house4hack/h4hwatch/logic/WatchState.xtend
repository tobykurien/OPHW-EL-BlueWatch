package za.co.house4hack.h4hwatch.logic

import android.util.Log
import android.util.SparseBooleanArray

class WatchState {
   public enum Item {
      bluetooth, time, frameBuffer, button1, button2, button3
   }
   
   // flags to indicate which Item updates are still running
   var busyBees = new SparseBooleanArray(WatchState.Item.values.length)
   
   // listener interface to be notified when state changes
   public interface OnStateChangedListener {
      def public void onStateChanged(WatchState.Item thatChanged)
   }
   
   int bluetooth = 0
   @Property WatchState.OnStateChangedListener listener = null
   
   // Notify the listener that an item has changed, unless it is still busy
   // with a previous change on that item
   def notifyChanged(WatchState.Item thatChanged) {
      if (listener == null)
         return; // nothing to do

      if (busyBees.get(thatChanged.ordinal())) {
         // previous update still busy so skip
         return;
      }

      new Thread() {
         override run() {
            // run the update in a background thread
            synchronized (thatChanged) {
               busyBees.put(thatChanged.ordinal(), true);
               listener.onStateChanged(thatChanged);
               busyBees.put(thatChanged.ordinal(), false);
            }
         }
      }.start();      
   }
   
   /**
    * Process a frame coming in from bluetooth
    */
   def public void processFrame(String line) {
      Log.d("state", "Got frame: " + line);
      if (line != null && line.length > 0) {
         switch (line) {
            case "FRAME_BUFFER": notifyChanged(WatchState.Item.frameBuffer) 
            case "BUTTON1": notifyChanged(WatchState.Item.button1) 
            case "BUTTON2": notifyChanged(WatchState.Item.button2) 
            case "BUTTON3": notifyChanged(WatchState.Item.button3) 
         } 
      } 
   }
   
   def setBluetooth(int bluetoothState) {
      if (bluetoothState != bluetooth) {
         this.bluetooth = bluetoothState;
         notifyChanged(WatchState.Item.bluetooth);
      }      
   }
   
   def getBluetooth() {
      return bluetooth
   }
}