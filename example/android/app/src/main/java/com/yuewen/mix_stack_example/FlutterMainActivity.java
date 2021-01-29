package com.yuewen.mix_stack_example;

import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;

import androidx.annotation.Nullable;

import com.yuewen.mix_stack.component.MXFlutterActivity;
import com.yuewen.mix_stack.core.MXStackService;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

/*******************************************************
 *
 * Created by julis.wang on 2021/01/20 14:46
 *
 * Description :
 *
 * History   :
 *
 *******************************************************/

public class FlutterMainActivity extends MXFlutterActivity {
    String route; //default

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Intent intent = getIntent();
        if (intent != null) {
            route = intent.getStringExtra("route");
        }

        if (TextUtils.equals(route, "/clear_stack")) {
            initEventChannel();
        }

        if (TextUtils.isEmpty(route)) {
            route = "/test_main";
        }
    }

    @Override
    public String rootRoute() {
        return route;
    }

    // ======== Test clear stack start ========
    private MethodChannel channel;

    private void initEventChannel() {
        if (channel != null) {
            return;
        }
        FlutterEngine flutterEngine = MXStackService.getInstance().getFlutterEngine();
        channel = new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(), "eventChannel");
        channel.setMethodCallHandler((call, result) -> {
            String method = call.method;
            if ("go_to_tab".equals(method)) {
                Intent intent = new Intent(FlutterMainActivity.this, MultipleTabActivity.class);
                intent.putExtra("action", "go_to_tab");
                intent.putExtra("route", route);
                startActivity(intent);
            }
        });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (channel != null) {
            channel.setMethodCallHandler(null);
            channel = null;
        }
    }
    // ======== Test clear stack End ========
}
