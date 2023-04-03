package com.zegocloud.demo.cohosting.utils;

import android.util.Log;

public class LogUtil {

    public static boolean PRINT_LOGCAT = true;
    private static final String TAG = "LogUtil";

    public static boolean isDebug() {
        return PRINT_LOGCAT;
    }

    public static void setDebug(boolean debug) {
        PRINT_LOGCAT = debug;
    }

    public static void d(String message) {
        if (PRINT_LOGCAT) {
            Log.d(TAG, message);
        }
    }
}
