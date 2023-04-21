package com.zegocloud.demo.cohosting;

import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import com.zegocloud.demo.cohosting.databinding.ActivityLoginBinding;
import com.zegocloud.demo.cohosting.internal.invitation.common.ConnectCallback;
import java.util.Random;

public class LoginActivity extends AppCompatActivity {

    private ActivityLoginBinding binding;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityLoginBinding.inflate(getLayoutInflater());

        String userID = generateUserID();
        String userName = userID + "_" + Build.MANUFACTURER.toLowerCase();
        binding.liveLoginId.getEditText().setText(userID);
        binding.liveLoginName.getEditText().setText(userName);

        binding.liveLoginBtn.setOnClickListener(v -> {
            signInZEGOSDK(userID, userName, (errorCode, message) -> {
                if (errorCode == 0) {
                    Intent intent = new Intent(LoginActivity.this, MainActivity.class);
                    startActivity(intent);
                }
            });

        });

        initZEGOSDK();
    }

    private void initZEGOSDK() {
        ZEGOSDKManager.getInstance().initSDK(getApplication(), ZEGOSDKKeyCenter.appID, ZEGOSDKKeyCenter.appSign);
    }

    private void signInZEGOSDK(String userID, String userName, ConnectCallback callback) {
        ZEGOSDKManager.getInstance().connectUser(userID, userName, callback);
    }


    private static String generateUserID() {
        StringBuilder builder = new StringBuilder();
        Random random = new Random();
        while (builder.length() < 6) {
            int nextInt = random.nextInt(10);
            if (builder.length() == 0 && nextInt == 0) {
                continue;
            }
            builder.append(nextInt);
        }
        return builder.toString();
    }
}