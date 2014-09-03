package za.co.house4hack.h4hwatch.activities

import android.content.Intent
import android.view.View
import android.widget.AdapterView
import android.widget.AdapterView.OnItemSelectedListener
import android.widget.ArrayAdapter
import org.xtendroid.app.AndroidActivity
import org.xtendroid.app.OnCreate
import za.co.house4hack.h4hwatch.bluetooth.BluetoothService
import za.co.house4hack.h4hwatch.logic.WatchServiceHelper
import za.co.house4hack.h4hwatch.views.WatchDisplay

import static za.co.house4hack.h4hwatch.logic.WatchServiceHelper.*
import android.view.Menu
import za.co.house4hack.h4hwatch.R
import android.view.MenuItem

@AndroidActivity(R.layout.activity_main) class MainActivity {
   var WatchDisplay watchDisplay
   
   int REQUEST_SETTINGS = 1

   @OnCreate
   def void init() {
      // start watch service
      var intent = new Intent(this, BluetoothService)
      startService(intent)

      clocks.adapter = new ArrayAdapter<String>(this, 
         android.R.layout.simple_spinner_dropdown_item,
         android.R.id.text1,
         WatchServiceHelper.clockModules.map [ it.name ]
      )
      
      clocks.onItemSelectedListener = new OnItemSelectedListener() {
         override onItemSelected(AdapterView<?> arg0, View arg1, int arg2, long arg3) {
            watchDisplay = new WatchDisplay(MainActivity.this,
               WatchServiceHelper.clockModules.get(arg2))
            preview.setImageBitmap(watchDisplay.bitmap)
            WatchServiceHelper.selectedClock = arg2
            if (WatchServiceHelper.getClock.settings > 0) {
               clockSettings.enabled = true
            } else {
               clockSettings.enabled = false
            }
         }
         
         override onNothingSelected(AdapterView<?> arg0) {
         }
      }

      preview.onClickListener = [
         watchDisplay.invalidate
         preview.setImageBitmap(watchDisplay.bitmap)
      ]           
      
      clockSettings.onClickListener = [
         // show settings for selected clock
         var settings = WatchServiceHelper.getClock.settings
         if (settings > 0) {
            var setInt = new Intent(this, ModulePreferences)
            setInt.putExtra(ModulePreferences.EXTRA_XML_ID, settings)
            startActivityForResult(setInt, REQUEST_SETTINGS)
         }
      ]
   }
   
   override protected onActivityResult(int requestCode, int resultCode, Intent data) {
      super.onActivityResult(requestCode, resultCode, data)
      
      if (requestCode == REQUEST_SETTINGS) {
         preview.performClick
      }
   }
   
   override onCreateOptionsMenu(Menu menu) {
      menuInflater.inflate(R.menu.main, menu)
      true
   }
   
   override onOptionsItemSelected(MenuItem item) {
      switch (item.itemId) {
         case R.id.action_bt_connect: reconnectBluetooth
         case R.id.action_exit: disconnectAndExit
         default: super.onOptionsItemSelected(item)
      }
   }
   
   def boolean reconnectBluetooth() {
      var intent = new Intent(this, BluetoothService)
      intent.putExtra(BluetoothService.EXTRA_RECONNECT, true)
      startService(intent)
      
      true
   }
   
   def boolean disconnectAndExit() {
      var intent = new Intent(this, BluetoothService)
      intent.putExtra(BluetoothService.EXTRA_EXIT, true)
      stopService(intent)
      
      finish
      true
   }
   
   
}