package com.zegocloud.demo.callwithinvitation.components;

import android.content.Context;
import android.graphics.drawable.StateListDrawable;
import android.util.AttributeSet;
import android.view.GestureDetector.SimpleOnGestureListener;
import android.view.MotionEvent;

import androidx.annotation.DrawableRes;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.core.view.GestureDetectorCompat;

public class CallImageButton extends androidx.appcompat.widget.AppCompatImageView {

    protected GestureDetectorCompat gestureDetectorCompat;
    private long lastClickTime = 0;
    private static final int CLICK_INTERVAL = 200;

    public CallImageButton(@NonNull Context context) {
        super(context);
        initView();
    }

    public CallImageButton(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        initView();
    }

    public CallImageButton(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        initView();
    }

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


    public void setImageResource(@DrawableRes int open, @DrawableRes int close) {
        StateListDrawable sld = new StateListDrawable();
        sld.addState(new int[]{android.R.attr.state_activated}, ContextCompat.getDrawable(getContext(), open));
        sld.addState(new int[]{}, ContextCompat.getDrawable(getContext(), close));
        setImageDrawable(sld);
    }

    public void open() {
        setActivated(true);
    }

    public void close() {
        setActivated(false);
    }

    public void setState(boolean state) {
        setActivated(state);
    }

    public boolean isOpen() {
        return isActivated();
    }

    public void toggle() {
        boolean open = isOpen();
        setState(!open);
    }
}
