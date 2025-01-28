package com.luckyd.im.utils

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.*
import android.util.AttributeSet
import android.view.View

class RoundedBorderView : View {

    private val borderWidth = 8f // Adjust this value as needed
    private val cornerRadius = 12f // Adjust this value as needed
    private val borderColor = Color.RED // Adjust this value as needed
    private val holeColor = Color.TRANSPARENT // Color for the hole

    private val borderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = borderWidth
        color = borderColor
    }

    private val holePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
        color = holeColor
    }

    private val path = Path()

    constructor(context: Context) : super(context)
    constructor(context: Context, attrs: AttributeSet?) : super(context, attrs)
    constructor(context: Context, attrs: AttributeSet?, defStyleAttr: Int) : super(context, attrs, defStyleAttr)

    @SuppressLint("DrawAllocation")
    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        // Calculate the dimensions of the outer rounded rectangle
        val outerRect = RectF(
            borderWidth / 2,
            borderWidth / 2,
            width.toFloat() - borderWidth / 2,
            height.toFloat() - borderWidth / 2
        )

        // Calculate the dimensions of the inner hole (inside the border)
        val holeRect = RectF(
            borderWidth * 2,
            borderWidth * 2,
            width.toFloat() - borderWidth * 2,
            height.toFloat() - borderWidth * 2
        )

        // Clear the path and add the outer rounded rectangle
        path.reset()
        path.addRoundRect(outerRect, cornerRadius, cornerRadius, Path.Direction.CW)

        // Draw the outer rounded rectangle
        canvas.drawPath(path, borderPaint)

        // Fill the inner hole with the hole color to make it transparent
        canvas.drawRoundRect(holeRect, cornerRadius, cornerRadius, holePaint)
    }
}

