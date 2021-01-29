package com.yuewen.mix_stack.core;

import android.view.View;
import android.view.animation.AlphaAnimation;
import android.view.animation.Animation;

import com.yuewen.mix_stack.model.AreaInsetsConfig;
import com.yuewen.mix_stack.model.MXViewConfig;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/*******************************************************
 *
 * Created by julis.wang on 2020/08/19 14:34
 *
 * Description :
 * Sometimes, if we have some interface elements on the Flutter page that need to be attached
 * to a tab-like native interface, the Flutter elements need to know the corresponding
 * native interface information for the layout.
 *
 * At this point, MixStack can be used to obtain the information of the corresponding interface,
 * which can be properly delayed to avoid the medium situation of native interface animation.
 *
 *
 *
 * History   :
 *
 *******************************************************/

public abstract class PageOverlayConfig {
    private static final int DEFAULT_DURATION = 200;

    public Map<String, View> overlayViewsForNames(List<String> overlayNames) {
        Map<String, View> nameViews = new HashMap<>();
        for (String name : overlayNames) {
            nameViews.put(name, overlayView(name));
        }
        return nameViews;
    }

    public void configOverlay(Map<String, MXViewConfig> overlayNamesConfig) {
        Set<String> keys = overlayNamesConfig.keySet();
        for (String key : keys) {
            final MXViewConfig config = overlayNamesConfig.get(key);
            final View view = overlayView(key);
            if (config == null) {
                continue;
            }
            if (config.isNeedsAnimation()) {
                final float viewAlpha = view.getAlpha();
                final float configAlpha = config.getAlpha();

                final AlphaAnimation alphaAnimation = new AlphaAnimation(viewAlpha, configAlpha);
                alphaAnimation.setDuration(DEFAULT_DURATION);
                alphaAnimation.setRepeatCount(0);
                view.startAnimation(alphaAnimation);
                alphaAnimation.setAnimationListener(new Animation.AnimationListener() {
                    @Override
                    public void onAnimationStart(Animation animation) {
                        if (viewAlpha < configAlpha) {
                            view.setAlpha(config.getAlpha());
                        }
                    }

                    @Override
                    public void onAnimationEnd(Animation animation) {
                        view.setAlpha(config.getAlpha());
                    }

                    @Override
                    public void onAnimationRepeat(Animation animation) {

                    }
                });
            } else {
                view.setAlpha(config.getAlpha());
            }
            view.setVisibility(config.isHidden() ? View.INVISIBLE : View.VISIBLE);
        }
    }

    public abstract List<String> overlayNames();

    public abstract View overlayView(String viewName);

    public abstract AreaInsetsConfig ignoreAreaInsetsConfig();


}
