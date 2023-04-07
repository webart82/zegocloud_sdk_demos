package com.zegocloud.demo.cohosting.components;

import android.content.Context;
import android.graphics.Color;
import android.util.AttributeSet;
import android.util.DisplayMetrics;
import android.view.Gravity;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.ImageView;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.constraintlayout.utils.widget.ImageFilterView;
import com.zegocloud.demo.cohosting.R;
import com.zegocloud.demo.cohosting.utils.Utils;

public class MemberListButton extends FrameLayout {

    private ImageView imageView;
    private ImageFilterView redPoint;

    public MemberListButton(@NonNull Context context) {
        super(context);
        initView();
    }

    public MemberListButton(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        initView();
    }

    public MemberListButton(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        initView();
    }

    public MemberListButton(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
        initView();
    }

    protected void initView() {
        imageView = new ImageView(getContext());
        addView(imageView);
        imageView.setImageResource(R.drawable.audioroom_icon_member);
        redPoint = new ImageFilterView(getContext());
        redPoint.setBackgroundColor(Color.parseColor("#FF0D23"));
        redPoint.setRoundPercent(1.0f);
        DisplayMetrics displayMetrics = getResources().getDisplayMetrics();
        LayoutParams redPointParams = new LayoutParams(Utils.dp2px(8, displayMetrics), Utils.dp2px(8, displayMetrics));
        redPointParams.gravity = Gravity.TOP | Gravity.END;
        addView(redPoint, redPointParams);

        hideRedPoint();
    }

    public void showRedPoint() {
        redPoint.setVisibility(View.VISIBLE);
    }

    public void hideRedPoint() {
        redPoint.setVisibility(View.GONE);
    }
}
