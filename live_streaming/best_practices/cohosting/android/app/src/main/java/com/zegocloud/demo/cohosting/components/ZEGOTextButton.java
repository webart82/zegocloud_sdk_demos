package com.zegocloud.demo.cohosting.components;

import android.content.Context;
import android.util.AttributeSet;
import android.util.Log;
import android.view.GestureDetector.SimpleOnGestureListener;
import android.view.MotionEvent;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.view.GestureDetectorCompat;

public class ZEGOTextButton extends androidx.appcompat.widget.AppCompatTextView {

    protected GestureDetectorCompat gestureDetectorCompat;
    private long lastClickTime = 0;
    private static final int CLICK_INTERVAL = 200;

    public ZEGOTextButton(@NonNull Context context) {
        super(context);
        initView();
    }

    public ZEGOTextButton(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        initView();
    }

    public ZEGOTextButton(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        initView();
    }

    private static final String TAG = "ZEGOTextButton";
    protected void initView() {
        gestureDetectorCompat = new GestureDetectorCompat(getContext(), new SimpleOnGestureListener() {
            @Override
            public boolean onDown(MotionEvent e) {
                return true;
            }

            @Override
            public boolean onSingleTapConfirmed(MotionEvent e) {
                if (System.currentTimeMillis() - lastClickTime < CLICK_INTERVAL) {
                    return true;
                }
                beforeClick();
                performClick();
                afterClick();
                lastClickTime = System.currentTimeMillis();
                return true;
            }
        });
        Log.d(TAG, "initView() called: " + gestureDetectorCompat);
    }

    protected void afterClick() {

    }

    protected boolean beforeClick() {
        return true;
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        return gestureDetectorCompat.onTouchEvent(event);
    }

}
