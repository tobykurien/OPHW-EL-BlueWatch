package za.co.house4hack.h4hwatch.modules

import android.graphics.Canvas

/**
 * Interface for all watch modules
 */
interface WatchModule {
   // Return the module name
   def String getName();
   
   // Return the module description
   def String getDescription();

   // Draw the watch display onto the Canvas, sized at 128x64
   def void onDraw(Canvas canvas);
   
   // Respond to the primary action button
   def void onPrimaryAction();
   
   // Respond to the secondary action button
   def void onSecondaryAction();
}