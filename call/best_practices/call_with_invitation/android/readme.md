see https://docs.zegocloud.com/article/15663

# Implement call invitation 


This doc will introduce how to implement the call invitation feature in the calling scenario. 


## Prerequisites

Before you begin, make sure you complete the following:

- Complete SDK integration and basic calling functions by referring to [Quick start\|_blank](!Quick_start_Integrate_Implementation).
- Download the [demo\|_blank](https://github.com/ZEGOCLOUD/zegocloud_sdk_demos/blob/main/call/advanced_features/call_with_invitation/android/) that comes with this doc.
- Subscribe to the **In-app Chat** service.
![/Pics/InappChat/ActivateZIMinConsole2.png](https://storage.zego.im/sdk-doc/Pics/InappChat/ActivateZIMinConsole2.png)

## Preview the effect

You can achieve the following effect with the [demo\|_blank](https://github.com/ZEGOCLOUD/zegocloud_sdk_demos/blob/main/call/advanced_features/call_with_invitation/android/) provided in this doc: 

|Home Page|Incoming Call Dialog|Waiting Page|Calling Page|
|--- | --- | --- |--- |
|<img src="/Pics/zegocloud/call/home_page.jpg" width=80%>|<img src="/Pics/zegocloud/call/incoming_call.jpg" width=80%>|<img src="/Pics/zegocloud/call/waiting_page.jpg" width=80%>|<img src="/Pics/zegocloud/call/calling_page.jpg" width=80%>|



## Understand the tech

Implementation of the call invitation is based on the [Call invitation (signaling)\|_blank](!zim-Call_Invitation) feature provided by the `in-app chat (hereafter referred to as ZIM SDK)`, which provides the capability of call invitation, allowing you to send, cancel, accept, and refuse a call invitation.

The process of call invitation implemented based on this is as follows: (taking "Alice calls Bob, Bob accepts and connects the call" as an example)

![](https://mermaid.ink/img/pako:eNp1ks1uwyAQhF9lxdk9xEcOkdI4qqr-RKrVS8SFwjZBscHF2FIV5d2LwbSNbPuEh9lvB9gLEUYioaTFrw61wELxo-U10-C_hlunhGq4drCplMCp3MrzCngLZfE0s4m2RztsH3YP--3z_r2AMmizoHwRdG8-mI5yyAFwt17H3kBB8Kp61L1yY76oR0voNmOJyUZKvkDJR4pvD4PF6G0ycaeMfkOBqkeZskXfhLoRAhs3of7PdmO5ybZaoKQTxvuYZov2v2yvxiGYARwqMp-VQuv8JQe60keSkRptzZX083AZqhhxJ6yREeqXktszI0xfvY93zpTfWhDqbIcZ6RrJXZodQj951f6qO6mcscmJ4e8lDl2YvYz4Jz4Yk-quP-XD1k4?type=png)

Here is a brief overview of the solution:

1. The caller can send a call invitation to a specific user by calling the `callInvite` method and waiting for the callee's response.
    - When the callee accepts the call invitation, the caller will receive a callback notification via `onCallInvitationAccepted`.
    - When the callee rejects the call invitation, the caller will receive a callback notification via `onCallInvitationRejected`.
    - When the callee does not respond within the timeout period, the caller will receive a callback notification via `onCallInviteesAnsweredTimeout`.
    - The caller can call `callCancel` to cancel the call invitation during the waiting period.

2. When the callee receives a call invitation, the callee will receive a callback notification via the `onCallInvitationReceived` and can choose to accept, reject, or not respond to the call.
    - If the callee wants to accept the call invitation, call the `callAccept` method.
    - If the callee wants to reject the call invitation, call the `callReject` method.
    - When the caller rejects the call invitation, the callee will receive a callback notification via `onCallInvitationCancelled`.
    - When the callee does not respond within the timeout period, the caller will receive a callback notification via `onCallInvitationTimeout`.
3. If the callee accepts the invitation, the call will begin.

Later in this document, the complete call process will be described in detail.

<details class="zg-primary">
    <summary>SDK related interfaces and class definitions</summary>

[Method\|_blank](https://docs.zegocloud.com/article/api?doc=zim_API~java_android~class~ZIM#call-invite)



```java
void callInvite(List<String> invitees, ZIMCallInviteConfig config, ZIMCallInvitationSentCallback callback);

void callCancel(List<String> invitees, String callID, ZIMCallCancelConfig config, ZIMCallCancelSentCallback callback);

void callAccept(String callID, ZIMCallAcceptConfig config, ZIMCallAcceptanceSentCallback callback);

void callReject(String callID, ZIMCallRejectConfig config, ZIMCallRejectionSentCallback callback);
```

[Callback\|_blank](https://docs.zegocloud.com/article/api?doc=zim_API~java_android~class~ZIMEventHandler#on-call-invitation-received)

```java
public void onCallInvitationReceived(ZIM zim, ZIMCallInvitationReceivedInfo info, String callID) {}

public void onCallInvitationCancelled(ZIM zim, ZIMCallInvitationCancelledInfo info, String callID) {}

public void onCallInvitationAccepted(ZIM zim, ZIMCallInvitationAcceptedInfo info, String callID) {}

public void onCallInvitationRejected(ZIM zim, ZIMCallInvitationRejectedInfo info, String callID) {}

public void onCallInvitationTimeout(ZIM zim, String callID) {}

public void onCallInviteesAnsweredTimeout(ZIM zim, ArrayList<String> invitees, String callID) {}
```

</details>

## Implementation

### Integrate and start to use the ZIM SDK

If you have not used the ZIM SDK before, you can read the following section:

<details class="zg-primary">
    <summary>1. Import the ZIM SDK</summary>

To import the ZIM SDK, do the following:

1. Set up repositories.

    - If your Android Gradle Plugin is **v7.1.0 or later**: go to the root directory of your project, open the `settings.gradle` file, and add the following line to the `dependencyResolutionManagement`:

        ```groovy
        ...
        dependencyResolutionManagement {
            repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
            repositories {
                maven { url 'https://storage.zego.im/maven' }
                mavenCentral()
                google()
            }
        }
        ```

        <div class="mk-warning">

        If you can not find the above fields in `settings.gradle`, it's probably because your Android Gradle Plugin version is lower than v7.1.0.

        For more details, see [Android Gradle Plugin Release Note v7.1.0\|_blank](https://developer.android.com/studio/past-releases/past-agp-releases/agp-7-1-0-release-notes#settings-gradle).
        </div>

    - If your Android Gradle Plugin is **earlier than 7.1.0**: go to the root directory of your project, open the `build.gradle` file, and add the following line to the `allprojects`:

        ```groovy
        ...
        allprojects {
            repositories {
                maven { url 'https://storage.zego.im/maven' }
                mavenCentral()
                google()
            }
        }
        ```

2. Declare dependencies:

    Go to the `app` directory, open the `build.gradle` file, and add the following line to the `dependencies`. (**x.y.z** is the SDK version number, to obtain the latest version number, see [Release Notes\|_blank](!zim-SDKs/Change_Log).

    ```groovy
    ...
    dependencies {
        ...
        implementation 'im.zego:zim:x.y.z'
    }
    ```
</details>

<details class="zg-primary">
    <summary>2. Create and manage SDK instances</summary>

After successful integration, you can use the Zim SDK like this: 

```java
import im.zego.zim.ZIM
```

Creating a ZIM instance is the very first step, an instance corresponds to a user logging in to the system as a client.
```java
ZIMAppConfig appConfig = new ZIMAppConfig();
appConfig.appID = yourAppID;
appConfig.appSign = yourAppSign;
zim = ZIM.create(appConfig, application);
```

</details>


Later on, we will provide you with detailed instructions on how to use the ZIM SDK to develop the call invitation feature. 


### Manage multiple SDKs more easily

In most cases, you need to use multiple SDKs together. For example, in the call invitation scenario described in this doc, you need to use the `zim sdk` to implement the call invitation feature, and then use the `zego_express_engine sdk` to implement the calling feature.

If your app has direct calls to SDKs everywhere, it can make the code difficult to manage and troubleshoot. To make your app code more organized, we recommend the following way to manage these SDKs:


1. Create a wrapper layer for each SDK so that you can reuse the code to the greatest extent possible.

Create a `ZIMService` class for the `zim sdk`, which manages the interaction with the SDK and stores the necessary data. Please refer to the complete code in [ZIMService.java\|_blank](https://github.com/ZEGOCLOUD/zegocloud_sdk_demos/blob/main/call/advanced_features/call_with_invitation/android/app/src/main/java/com/zegocloud/demo/callwithinvitation/internal/ZIMService.java).
```java
public class ZIMService {
    private ZIM zim;
    
    // ...

    public void initSDK(Application application, long appID, String appSign) {
        if (zim != null) {
            return;
        }
        ZIMAppConfig zimAppConfig = new ZIMAppConfig();
        zimAppConfig.appID = appID;
        zimAppConfig.appSign = appSign;
        zim = ZIM.create(zimAppConfig, application);
        if (zim != null) {
            zim.setEventHandler(new ZIMEventHandler() {
               
               // ...

            });
        }
    }
}
```


Similarly, create an `ExpressService` class for the `zego_express_engine sdk`, which manages the interaction with the SDK and stores the necessary data. Please refer to the complete code in [ExpressService.java\|_blank](https://github.com/ZEGOCLOUD/zegocloud_sdk_demos/blob/main/call/advanced_features/call_with_invitation/android/app/src/main/java/com/zegocloud/demo/callwithinvitation/internal/ExpressService.java).

```java
public class ExpressService {
    private ZegoExpressEngine express;

    // ...
    public void initSDK(Application application, long appID, String appSign) {
        if (engine != null) {
            return;
        }
        
        ZegoEngineProfile profile = new ZegoEngineProfile();
        profile.appID = appID;
        profile.appSign = appSign;
        profile.scenario = ZegoScenario.DEFAULT;
        profile.application = application;
        
        express = ZegoExpressEngine.createEngine(profile, new IZegoEventHandler() {
            // ...
        });
    }
}
```

With the service, you can add methods to the service whenever you need to use any SDK interface.


<details class="zg-primary">
    <summary>E.g., easily add the connectUser method to the ZIMService when you need to implement login</summary>

```java
public class ZIMService {
    // ...
    public void connectUser(String userID, String userName, ZIMLoggedInCallback callback) {
        if (zim == null) {
            return;
        }
        ZIMUserInfo zimUserInfo = new ZIMUserInfo();
        zimUserInfo.userID = userID;
        zimUserInfo.userName = userName;
        zim.login(zimUserInfo, new ZIMLoggedInCallback() {
            @Override
            public void onLoggedIn(ZIMError errorInfo) {
                // ...
            }
        });
    }
}
```

</details>

2. After completing the service encapsulation, you can further simplify the code by creating a `ZEGOSDKManager` to manage these services, as shown below. Please refer to the complete code in [ZEGOSDKManager.java\|_blank](https://github.com/ZEGOCLOUD/zegocloud_sdk_demos/blob/main/call/advanced_features/call_with_invitation/android/app/src/main/java/com/zegocloud/demo/callwithinvitation/ZEGOSDKManager.java#L25).

```java
public class ZEGOSDKManager {
    public ExpressService expressService = new ExpressService();
    public ZIMService zimService = new ZIMService();
    
    private static final class Holder {
        private static final ZEGOSDKManager INSTANCE = new ZEGOSDKManager();
    }

    public static ZEGOSDKManager getInstance() {
        return Holder.INSTANCE;
    }

    public void initSDK(Application application, long appID, String appSign) {
        expressService.initSDK(application, appID, appSign);
        zimService.initSDK(application, appID, appSign);
    }
}
```


In this way, you have implemented a singleton class that manages the SDK services you need. From now on, you can get an instance of this class anywhere in your project and use it to execute SDK-related logic, such as:



- When the app starts up: call `ZEGOSDKManager.getInstance().initSDK(application,appID,appSign);` 
- When starting a call: call `ZEGOSDKManager.getInstance().joinExpressRoom(roomID,callback);`
- When ending a call: call `ZEGOSDKManager.getInstance().leaveExpressRoom();`

Later, we will introduce how to add call invitation feature based on this. 


### Send a call invitation

1. Pass extension information

When the caller initiates a call, not only specifying the callee, but also passing on information to the callee is allowed, such as whether to initiate a video call or an audio-only call.

The `ZIMCallInviteConfig` parameter of the `callInvite` method allows for passing a string type of extended information `extendedData`. This extended information will be passed to the callee. You can use this method to allow the caller to pass any information to the callee. 

In the example demo of this solution, you will use the `CallInviteExtendedData` type to define the `extendedData` of the call invitation, and you need to convert it to a string in JSON format and pass it to the callee when initiating the call. (See [complete source code\|_blank](https://github.com/ZEGOCLOUD/zegocloud_sdk_demos/blob/main/call/advanced_features/call_with_invitation/android/app/src/main/java/com/zegocloud/demo/callwithinvitation/call/internal/CallInviteExtendedData.java)). The `CallInviteExtendedData` includes the call type and the name of the caller.

```java
public class CallInviteExtendedData {
    public String type;
    public String callerUserName;
    public static final String TYPE_VIDEO_CALL = "video_call";
    public static final String TYPE_VOICE_CALL = "voice_call";
}
```

> Note: The caller needs to check the `errorInfo` in `onCallInvitationSent` to determine if the call is successful and handle exception cases such as call failure due to network disconnection on the caller's phone.


2. Implement call waiting page

As a caller, after initiating the call, you will enter the call waiting page, where you can listen to the status changes of the call. See [complete source code\|_blank](https://github.com/ZEGOCLOUD/zegocloud_sdk_demos/blob/main/call/advanced_features/call_with_invitation/android/app/src/main/java/com/zegocloud/demo/callwithinvitation/call/CallWaitingActivity.java) for details. The key code is as follows:

```java
public class CallWaitingActivity extends AppCompatActivity {
    private InvitationListener listener = new InvitationListener() {
       // ...
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // ...
        ZEGOSDKManager.getInstance().addInvitationListener(listener);
        // ...
    }
}
```

- When the callee accepts the call invitation, you will enter the calling page and the call starts.


```java
public class CallWaitingActivity extends AppCompatActivity {
    // ...
    private InvitationListener listener = new InvitationListener() {
        @Override
        public void onOutgoingCallInvitationAccepted(String callID, String invitee, String extendedData) {
            ZEGOSDKManager.getInstance().joinExpressRoom(callID, new IZegoRoomLoginCallback() {
                @Override
                public void onRoomLoginResult(int errorCode, JSONObject extendedData) {
                    if (errorCode == 0) {
                        finishAndExit();
                        CallingActivity.startActivity(CallWaitingActivity.this, callInviteInfo);
                    } else {
                        ToastUtil.show(CallWaitingActivity.this, "joinexpressRoom failed :" + errorCode);
                    }
                }
            });
        }
        // ...
    }
    // ...
}
```


- When the callee refuses the call invitation, you will return to the previous page and the call ends. Similarly, when the callee doesn't respond within the timeout, the call ends and returns to the previous page.

```java
public class CallWaitingActivity extends AppCompatActivity {
    // ...
    private InvitationListener listener = new InvitationListener() {
        @Override
        public void onOutgoingCallInvitationRejected(String callID, String invitee, String extendedData) {
            ToastUtil.show(CallWaitingActivity.this,"reject by user, extendedData:" + extendedData);
            finishAndExit();
        }

        @Override
        public void onOutgoingCallInvitationTimeout(String callID, ArrayList<String> invitees) {
            ToastUtil.show(CallWaitingActivity.this,"call invitation timeout");
            finishAndExit();
        }
        // ...
    }
    // ...
}
```


- After initiating a call, the caller can cancel the call at any time by calling the `callCancel` method. 
> In the `callCancel` method, you are required to pass a `callID`. `callID` is a unique identifier for a call invitation that can be obtained from the `ZIMCallInvitationSentCallback` parameter of the `callInvite` method.

```java
public class CallWaitingActivity extends AppCompatActivity {
    // ...
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // ...
        binding.outgoingCallCancelButton.setOnClickListener(v -> {
            ZEGOSDKManager.getInstance()
                .cancelInvite(callInviteInfo.calleeUserID, callInviteInfo.callID, new ZIMCallCancelSentCallback() {
                    @Override
                    public void onCallCancelSent(String callID, ArrayList<String> errorInvitees, ZIMError errorInfo) {
                        if (errorInfo.getCode() == ZIMErrorCode.SUCCESS) {
                            finishAndExit();
                        } else {
                            ToastUtil.show(CallWaitingActivity.this, "cancel invite failed :" + errorInfo.getCode());
                        }
                    }
                });
        });
        // ...
    }
    // ...
}
```



<details class="zg-primary">
    <summary>SDK related interfaces and class definitions</summary>

`callInvite`:

```java
void callInvite(List<String> invitees, ZIMCallInviteConfig config, ZIMCallInvitationSentCallback callback);
```

`ZIMCallInviteConfig`:
```java
public class ZIMCallInviteConfig {
    public int timeout = 90;
    public String extendedData = "";
    public ZIMPushConfig pushConfig;
    public ZIMCallInviteConfig() {}
}
```

`ZIMCallInvitationSentCallback`:
```java
public interface ZIMCallInvitationSentCallback {
    void onCallInvitationSent(String callID, ZIMCallInvitationSentInfo info, ZIMError errorInfo);
}
```

`ZIMCallInvitationSentInfo` inside the `ZIMCallInvitationSentCallback`:

```java
public class ZIMCallInvitationSentInfo {
    public int timeout;
    public ArrayList<ZIMCallUserInfo> errorInvitees;
    public ZIMCallInvitationSentInfo() {}
}
```
</details>


### Respond to call invitation 

When the callee receives a call invitation, they will receive the callback notification via `onCallInvitationReceived`. 

1. To accept or reject the call invite, the callee can call the `callAccept` or `callReject` method.

2. The callee can obtain the `extendedData` passed by the caller in `ZIMCallInvitationReceivedInfo`.

3. When the callee accepts or rejects the call invitation, they can use the `config` parameter in the interface to pass additional information to the caller, such as the reason for rejection being due to user rejection or a busy signal.


> The callee needs to check the `errorInfo` in `callback` to determine if the response is successful when calling the methods to accept or reject the call invite, and handle exception cases such as response failure due to network disconnection on the callee's phone.


**Next, we will use the demo code to illustrate how to implement this part of the functionality.**

1. When the callee receives a call invitation:

- If the callee is not in the busy state: the `IncomingCallDialog` will be triggered to let the callee decide whether to accept or reject the call.
- If the callee is in the busy state: the invitation will be automatically rejected, and the caller will be informed that the callee is in the busy state.

For details, see [complete source code\|_blank](https://github.com/ZEGOCLOUD/zegocloud_sdk_demos/blob/main/call/advanced_features/call_with_invitation/android/app/src/main/java/com/zegocloud/demo/callwithinvitation/call/CallBackgroundService.java#L31). The key code is as follows:

```java
public void onIncomingCallInvitationReceived(String callID, String userID, String extendedData) {
    if (ZEGOSDKManager.getInstance().isBusy()) {
        ZEGOSDKManager.getInstance().autoRejectCallInviteCauseBusy(callID, new ZIMCallRejectionSentCallback() {
            @Override
            public void onCallRejectionSent(String callID, ZIMError errorInfo) {
                ToastUtil.show(getApplicationContext(), "busy");
            }
        });
        return;
    }
    ZEGOSDKManager.getInstance().setBusy(true);

    CallInviteExtendedData callInviteExtendedData = CallInviteExtendedData.parseExtendedData(extendedData);
    CallInviteInfo callInviteInfo = new CallInviteInfo();
    callInviteInfo.callID = callID;
    callInviteInfo.callerUserID = userID;
    callInviteInfo.callerUserName = callInviteExtendedData.callerUserName;
    callInviteInfo.calleeUserID = ZEGOSDKManager.getInstance().expressService.getUserInfo().userID;
    callInviteInfo.callType = callInviteExtendedData.type;
    callInviteInfo.isOutgoingCall = false;

    Intent intent = new Intent(getApplicationContext(), IncomingCallDialog.class);
    intent.putExtra("callInviteInfo", callInviteInfo);
    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
    startActivity(intent);
}
```

2. When the callee wants to accept the call invite: after the `IncomingCallDialog` pops up, when the **accept button** is clicked, `callAccept` method will be called and will enter the `CallingPage`.

For details, see [complete source code\|_blank](https://github.com/ZEGOCLOUD/zegocloud_sdk_demos/blob/main/call/advanced_features/call_with_invitation/android/app/src/main/java/com/zegocloud/demo/callwithinvitation/call/IncomingCallDialog.java#L100). The key code is as follows:

```java
public class IncomingCallDialog extends AppCompatActivity {
    // ...
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // ...
        binding.dialogCallAccept.setOnClickListener(v -> {
            ZEGOSDKManager.getInstance().callAccept(callInviteInfo.callID, new ZIMCallAcceptanceSentCallback() {
                @Override
                public void onCallAcceptanceSent(String callID, ZIMError errorInfo) {
                    if (errorInfo.getCode() == ZIMErrorCode.SUCCESS) {
                        ZEGOSDKManager.getInstance().joinExpressRoom(callID, new IZegoRoomLoginCallback() {
                            @Override
                            public void onRoomLoginResult(int errorCode, JSONObject extendedData) {
                                if (errorCode == 0) {
                                    finish();
                                    CallingActivity.startActivity(IncomingCallDialog.this, callInviteInfo);
                                } else {
                                    ToastUtil.show(IncomingCallDialog.this, "joinExpressRoom failed :" + errorCode);
                                }
                            }
                        });
                    } else {
                        ToastUtil.show(IncomingCallDialog.this, "callAccept failed :" + errorInfo.getCode());
                    }
                }
            });
        });
        // ...
    }
    // ...
}
```

3. When the callee wants to reject the call invite: after the `IncomingCallDialog` pops up, when the **reject button** is clicked, `callReject` method will be called.

For details, see [complete source code\|_blank](https://github.com/ZEGOCLOUD/zegocloud_sdk_demos/blob/main/call/advanced_features/call_with_invitation/android/app/src/main/java/com/zegocloud/demo/callwithinvitation/call/IncomingCallDialog.java#L123). The key code is as follows:


```java
public class IncomingCallDialog extends AppCompatActivity {
    // ...
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // ...
            binding.dialogCallDecline.setOnClickListener(v -> {
                ZEGOSDKManager.getInstance().callReject(callInviteInfo.callID, new ZIMCallRejectionSentCallback() {
                    @Override
                    public void onCallRejectionSent(String callID, ZIMError errorInfo) {
                        if (errorInfo.getCode() == ZIMErrorCode.SUCCESS) {
                        } else {
                            ToastUtil.show(IncomingCallDialog.this, "callReject failed :" + errorInfo.getCode());
                        }
                        finish();
                    }
                });
            });
        // ...
    }
    // ...
}
```

4. When the callee doesn't respond: after the `IncomingCallDialog` pops up, if the call invitation times out due to the callee's lack of response, the `IncomingCallDialog` needs to disappear.

For details, see [complete source code\|_blank](https://github.com/ZEGOCLOUD/zegocloud_sdk_demos/blob/main/call/advanced_features/call_with_invitation/android/app/src/main/java/com/zegocloud/demo/callwithinvitation/call/IncomingCallDialog.java). The key code is as follows:


```java
public class IncomingCallDialog extends AppCompatActivity {
    // ...
    private InvitationListener listener = new InvitationListener() {
        // ...
        @Override
        public void onIncomingCallInvitationTimeout(String inviter) {
            finish();
        }
        // ...
    }
    // ...
}
```


<details class="zg-primary">
    <summary>SDK related interfaces and class definitions</summary>

`onCallInvitationReceived`:

```java
public void onCallInvitationReceived(ZIM zim, ZIMCallInvitationReceivedInfo info, String callID) {}
```

`ZIMCallInvitationReceivedInfo` inside the `onCallInvitationReceived`:
```java
public class ZIMCallInvitationReceivedInfo {
    public int timeout;
    public String inviter;
    public String extendedData;

    public ZIMCallInvitationReceivedInfo() {}
}
```

Interfaces used to accept and reject the call invite:

```java
void callAccept(String callID, ZIMCallAcceptConfig config, ZIMCallAcceptanceSentCallback callback);
void callReject(String callID, ZIMCallRejectConfig config, ZIMCallRejectionSentCallback callback);

class ZIMCallRejectConfig {
    public String extendedData = "";
    public ZIMCallRejectConfig() {}
}

class ZIMCallAcceptConfig {
    public String extendedData = "";
    public ZIMCallAcceptConfig() {}
}

interface ZIMCallAcceptanceSentCallback {
    void onCallAcceptanceSent(String callID, ZIMError errorInfo);
}

interface ZIMCallRejectionSentCallback {
    void onCallRejectionSent(String callID, ZIMError errorInfo);
}
```
</details>

### Implement busy state 

Finally, you also need to check the user's busy status, similar to the busy signal logic when making a phone call.

> A busy signal refers to the situation where, when you try to dial a phone number, the target phone is being connected by other users, so you cannot connect with the target phone. In this case, you usually hear a busy tone or see a busy line prompt.

In general, **being called, calling, and being in a call** are defined as **busy states**. In the busy state, you can only handle the current call invitation or call, and cannot accept or send other call invitations. The state transition diagram is as follows:

![](https://mermaid.ink/img/pako:eNp9kcsKgzAQRX9FZlXB_oCLLvqCLrpyUSjZDGbUUJNIjBQR_71R0arYZpWZOfcyjwZizQlCSHL9jjM01mPKc-9qiCKLlpgaEjcVaylUesI83zFYhMeqrHvYZ-APeJd_oLAOcfQ8-gF_wQ1o1ZO33x9mlhvVeXujfKYYDSbxqvZ3-hWwVZ68F_MthBCAJCNRcLf9puMY2IwkMQjdl6N5MWCqdRxWVke1iiG0pqIAqoI7g7PA1KCEMMG8nLIXLqw2I0l9dB9O3F86gALVU-tR134Awk2rrA?type=png)

In the example demo, you can use `ZEGOSDKManager` to manage the user's busy status:


1. When transitioning between states, set the busy status to `ZEGOSDKManager`.
```java
ZEGOSDKManager.getInstance().setBusy(isBusy);
```


2. Then, when receiving a call invitation, check whether the callee is in a busy state. If so, reject the call invitation directly and inform the caller that the call was rejected due to being busy.

For details, see [complete source code\|_blank](https://github.com/ZEGOCLOUD/zegocloud_sdk_demos/blob/main/call/advanced_features/call_with_invitation/android/app/src/main/java/com/zegocloud/demo/callwithinvitation/internal/ZIMService.java#L211). The key code is as follows:

```java
public void autoRejectCallInviteCauseBusy(String callID, ZIMCallRejectionSentCallback callback) {
    ZIMCallRejectConfig config = new ZIMCallRejectConfig();
    config.extendedData = "busy";
    zim.callReject(callID, config, new ZIMCallRejectionSentCallback() {
        @Override
        public void onCallRejectionSent(String callID, ZIMError errorInfo) {
            LogUtil.d(
                "onCallRejectionSent() called with: callID = [" + callID + "], errorInfo = [" + errorInfo.code + "(+" + errorInfo.message + "]");
            if (callback != null) {
                callback.onCallRejectionSent(callID, errorInfo);
            }
        }
    });
}
```



### Start the call 

After the callee accepts the call invitation, the caller will receive the callback notification via `onCallInvitationAccepted`, and both parties can start the call. 
You can refer to the implementation of the call page in [Quick start\|_blank](!ExpressVideoSDK-Quick_start_Integrate_Implementation), or you can directly refer to the demo's [sample code\|_blank](https://github.com/ZEGOCLOUD/zegocloud_sdk_demos/blob/main/call/advanced_features/call_with_invitation/android/app/src/main/java/com/zegocloud/demo/callwithinvitation/call/CallingActivity.java) included in this doc.

> In this demo, we use `callID` as the `roomID` for `zego_express_sdk`.
> For information on `roomID`, refer to [Key concepts\|_blank](!ExpressVideoSDK-VideoCall_Reference_KeyConcepts).


## Conclusion

Congratulations! Hereby you have completed the development of the call invitation feature. 

If you have any suggestions or comments, feel free to share them with us via [Discord\|_blank](https://discord.gg/EtNRATttyp). We value your feedback.
