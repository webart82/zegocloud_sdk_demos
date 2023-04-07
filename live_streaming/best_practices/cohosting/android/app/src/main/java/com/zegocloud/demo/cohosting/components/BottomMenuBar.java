package com.zegocloud.demo.cohosting.components;

import android.content.Context;
import android.util.AttributeSet;
import android.view.Gravity;
import android.widget.LinearLayout;
import androidx.annotation.Nullable;
import com.zegocloud.demo.cohosting.utils.Utils;

public class BottomMenuBar extends LinearLayout {

    private MemberListButton memberListButton;
    private MemberListView memberListView;

    public BottomMenuBar(Context context) {
        super(context);
        initView();
    }

    public BottomMenuBar(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        initView();
    }

    public BottomMenuBar(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        initView();
    }

    public BottomMenuBar(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
        initView();
    }

    private void initView() {
        setOrientation(LinearLayout.HORIZONTAL);
        setLayoutParams(new LayoutParams(-1, -2));
        setGravity(Gravity.END);

        memberListButton = new MemberListButton(getContext());
        memberListButton.setOnClickListener(v -> {
            memberListView = new MemberListView(getContext());
            memberListView.show();
        });
        addView(memberListButton, generateChildLayoutParams());
    }

    private LayoutParams generateChildLayoutParams() {
        int size = Utils.dp2px(36f, getResources().getDisplayMetrics());
        int marginTop = Utils.dp2px(10f, getResources().getDisplayMetrics());
        int marginBottom = Utils.dp2px(16f, getResources().getDisplayMetrics());
        int marginEnd = Utils.dp2px(8, getResources().getDisplayMetrics());
        LayoutParams layoutParams = new LayoutParams(size, size);
        layoutParams.topMargin = marginTop;
        layoutParams.bottomMargin = marginBottom;
        layoutParams.rightMargin = marginEnd;
        return layoutParams;
    }
}
