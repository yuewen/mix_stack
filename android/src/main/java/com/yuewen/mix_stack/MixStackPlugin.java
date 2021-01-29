package com.yuewen.mix_stack;

import androidx.annotation.NonNull;

import com.yuewen.mix_stack.core.MXStackService;
import com.yuewen.mix_stack.interfaces.IMXPage;
import com.yuewen.mix_stack.interfaces.InvokeMethodListener;
import com.yuewen.mix_stack.utils.InvokePipeline;
import com.yuewen.mix_stack.utils.OverlayUtils;

import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * MixStackPlugin
 */
public class MixStackPlugin implements FlutterPlugin, MethodCallHandler {
    private static final String TAG = "MixStackPlugin";
    private MethodChannel channel;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "mix_stack");
        channel.setMethodCallHandler(this);
        InvokePipeline.getInstance().setChannel(channel);
    }

    public static void registerWith(Registrar registrar) {
        MethodChannel channel = new MethodChannel(registrar.messenger(), "mix_stack");
        channel.setMethodCallHandler(new MixStackPlugin());
        InvokePipeline.getInstance().setChannel(channel);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        String method = call.method;
        switch (method) {
            case "enablePanNavigation":
                result.success(null);
                break;
            case "currentOverlayTexture":
                OverlayUtils.getOverlayTexture(call, result);
                break;
            case "configOverlays":
                OverlayUtils.configOverlays(call, result);
                break;
            case "overlayNames":
                OverlayUtils.overlayNames(call, result);
                break;
            case "popNative":
                popNative(call, result);
                break;
            case "overlayInfos":
                OverlayUtils.overlayInfo(call, result);
                break;
            case "updatePages":
                updatePages();
                break;
            default:
                result.notImplemented();
                break;
        }
    }


    /**
     * Has no flutter page will call this method.
     *
     * @param call
     * @param result
     */
    private void popNative(MethodCall call, Result result) {
        IMXPage currentPage = MXStackService.getInstance().getCurrentPage();
        if (currentPage == null) {
            result.success(false);
        } else {
            currentPage.onPopNative();
        }
        result.success(true);
    }

    /**
     * Fix Hot Reload issue in debug status.
     */
    private void updatePages() {
        InvokePipeline.getInstance().invoke("updatePages", null);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (channel != null) {
            channel.setMethodCallHandler(null);
            channel = null;
        }
    }

    public static void invoke(String method, Map<String, Object> query) {
        InvokePipeline.getInstance().invoke(method, query);
    }

    public static void invokeWithListener(String method, Map<String, Object> query, InvokeMethodListener listener) {
        InvokePipeline.getInstance().invokeWithListener(method, query, listener);
    }

}
