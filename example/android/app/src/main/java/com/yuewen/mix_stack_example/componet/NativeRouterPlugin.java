package com.yuewen.mix_stack_example.componet;

import android.app.Application;
import android.content.Intent;
import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.NonNull;

import com.yuewen.mix_stack_example.FlutterMainActivity;
import com.yuewen.mix_stack_example.MoreFunctionActivity;
import com.yuewen.mix_stack_example.MultipleTabActivity;
import com.yuewen.mix_stack_example.NativeActivity;

import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/*******************************************************
 *
 * Created by julis.wang on 2021/01/20 14:11
 *
 * Description : For example, in your project may use own router.
 *
 * History   :
 *
 *******************************************************/

public class NativeRouterPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
    private Application context;

    public NativeRouterPlugin(Application context) {
        this.context = context;
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        MethodChannel channel = new MethodChannel(binding.getBinaryMessenger(), "goto_native_channel");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {

    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        String method = call.method;
        if ("go".equals(method)) {
            Map arguments = (Map) call.arguments;
            String route = (String) arguments.get("route");
            jumpNativePage(route);
        }
    }

    private void jumpNativePage(String route) {
        if (TextUtils.isEmpty(route)) {
            return;
        }

        Intent intent;
        switch (route) {
            case "/simple_flutter_page":
                intent = new Intent(context, FlutterMainActivity.class);
                break;
            case "/native":
                intent = new Intent(context, NativeActivity.class);
                break;
            case "/tab":
            case "/clear_stack":
                intent = new Intent(context, MultipleTabActivity.class);
                break;
            case "/popup_window":
            case "/area_inset":
                intent = new Intent(context, MoreFunctionActivity.class);
                break;
            default:
                Log.d("MixStack", "Not found route:" + route);
                return;
        }

        intent.putExtra("route", route);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        context.startActivity(intent);
    }
}
