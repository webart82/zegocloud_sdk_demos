// Get your AppID, AppSign, and serverSecret from ZEGOCLOUD Console
// [My Projects -> AppID] : https://console.zegocloud.com/project
const appID = 252984006;
const appSign = '7328c93dfd9c7cf300818cde931c661b545bfc098fce80c722fdbd8d1a3b262a';
const serverSecret = '16435f3bdb307f3020b3f9e4259a29f0';

/// The serverSecret is only required when you need to use this demo to build a Flutter web platform.
/// The web platform requires token authentication due to security issues. To enable you to quickly experience it,
/// this demo uses client-side code to generate tokens for authentication, which requires the use of serverSecret.
/// In a real project, you need to generate tokens on the server side and distribute them to the client,
/// so as to effectively protect the security of your app.