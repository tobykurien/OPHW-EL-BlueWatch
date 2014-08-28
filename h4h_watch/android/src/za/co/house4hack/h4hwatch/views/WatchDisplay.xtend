package za.co.house4hack.h4hwatch.views

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Paint.Align
import android.graphics.Paint.Style
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.util.AttributeSet
import android.util.Log
import android.view.View
import java.text.SimpleDateFormat
import java.util.Date
import za.co.house4hack.h4hwatch.R

class WatchDisplay extends View {
   var Bitmap bitmap
   var Paint paint
   var Paint line
   var timeFormat = new SimpleDateFormat("HH:mm")
   
   new(Context context) {
      super(context)
   }
   
   new(Context context, AttributeSet attrs) {
      super(context, attrs)
   }
   
   new(Context context, AttributeSet attrs, int defStyleAttr) {
      super(context, attrs, defStyleAttr)
   }
   
   override protected onAttachedToWindow() {
      super.onAttachedToWindow()
      var bd = resources.getDrawable(R.drawable.ic_launcher) as BitmapDrawable
      bitmap = bd.bitmap
      
      paint = new Paint
      paint.color = Color.WHITE
      paint.style = Style.FILL
      paint.textSize = 40
      paint.textAlign = Align.CENTER

      line = new Paint
      line.color = Color.WHITE
      line.style = Style.STROKE
   }
   
   override protected onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
      setMeasuredDimension(widthMeasureSpec, heightMeasureSpec * 64 / 128)
   }
   
   override protected onDraw(Canvas canvas) {
      super.onDraw(canvas)
      var date = new Date
      
      canvas.save
      
//      canvas.drawBitmap(bitmap, 
//         new Rect(0, 0, bitmap.width, bitmap.height), 
//         new Rect(0, 0, canvas.width, canvas.height), 
//         paint)

      canvas.drawText(timeFormat.format(date), canvas.width/2, canvas.height/2 + 14, paint)
      canvas.drawRect(0, 0, canvas.width - 1, canvas.height - 1, line)
      
      canvas.restore
   }
   
   def public Bitmap getBitmap() {
      if (paint == null) onAttachedToWindow

      //Define a bitmap with the same size as the view
      var Bitmap returnedBitmap = Bitmap.createBitmap(128, 64, Bitmap.Config.ARGB_8888);
      if (returnedBitmap == null) throw new Exception("Could not create bitmap")
      
      //Bind a canvas to it
      var Canvas canvas = new Canvas(returnedBitmap);
      if (canvas == null) throw new Exception("Could not create canvas")

      //Get the view's background
      var Drawable bgDrawable = getBackground();
      if (bgDrawable!=null) { 
            //has background drawable, then draw it on the canvas
            bgDrawable.draw(canvas);
      } else { 
            //does not have background drawable, then draw black background on the canvas
            canvas.drawColor(Color.BLACK);
      }
      
      // draw the view on the canvas
      draw(canvas);
      
      //return the bitmap
      return returnedBitmap;
   }
}