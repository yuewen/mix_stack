package com.yuewen.mix_stack_example.componet;


import com.yuewen.mix_stack.core.MXStackService;

import io.flutter.app.FlutterApplication;


/*******************************************************
 *
 * Created by julis.wang on 2020/08/11 13:40
 *
 * Description :
 * History   :
 *
 *******************************************************/

public class MainApplication extends FlutterApplication {
    @Override
    public void onCreate() {
        super.onCreate();
        MXStackService.init(this);

        //for example
        MXStackService.getInstance().getFlutterEngine().getPlugins().add(new NativeRouterPlugin(this));
    }
}










