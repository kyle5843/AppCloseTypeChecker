# AppCloseTypeChecker

This tool will help you to trace the leave type by users, and trace the oom rate with your own action stack info.
The AppCloseTypeChecker is base on facebook's oom reduce logic with Swift 5.

https://engineering.fb.com/ios/reducing-fooms-in-the-facebook-ios-app/
![image](https://github.com/kyle5843/AppCloseTypeChecker/blob/master/167fdc7e846ed493.png)

You should import your own crash detector and report system to complete the tool.

In my test, AppUpgrade and OSUpgrade won't shutdown the app when you are using, so I skip those two checking.
And FOOM case also includes the ANR case, because the system notification call back won't trigger if your main thread is busy.

