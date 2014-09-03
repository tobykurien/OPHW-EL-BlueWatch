package za.co.house4hack.h4hwatch.modules

import android.content.Context
import android.graphics.Canvas

/**
 * Interface for all watch modules
 */
public abstract class WatchModule {
   // all initialization code
   abstract def void init(Context context);
   
   // Return the module name
   abstract def String getName();
   
   // Return the module description
   abstract def String getDescription();

   // Draw the watch display onto the Canvas, sized at 128x64
   abstract def void onDraw(Canvas canvas);
   
   // Respond to the primary action button. Return true to redraw screen
   def boolean onPrimaryAction() { false }
   
   // Respond to the secondary action button. Return true to redraw screen
   def boolean onSecondaryAction() { false }
   
   def int getSettings() {
      return -1;
   }
   
   override toString() {
      getName
   }
}