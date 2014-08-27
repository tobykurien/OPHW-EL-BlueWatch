package za.co.house4hack.h4hwatch.logic

import android.util.SparseBooleanArray

class WatchState {
   public enum Item {
      bluetooth, time
   }
   
   // flags to indicate which Item updates are still running
   var busyBees = new SparseBooleanArray(Item.values.length)
   
   // listener interface to be notified when state changes
   public interface OnStateChangedListener {
      def public void onStateChanged(Item thatChanged)
   }
   
   int bluetooth = 0
   @Property OnStateChangedListener listener = null
   
   // Notify the listener that an item has changed, unless it is still busy
   // with a previous change on that item
   def notifyChanged(Item thatChanged) {
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
      //Log.d("state", "Got frame: " + line);
      var can = line.split(" ");
      
   }
   
   def setBluetooth(int bluetoothState) {
      if (bluetoothState != bluetooth) {
         this.bluetooth = bluetoothState;
         notifyChanged(Item.bluetooth);
      }      
   }
   
   def getBluetooth() {
      return bluetooth
   }
}