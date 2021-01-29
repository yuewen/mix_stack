package com.yuewen.mix_stack.model;

import android.view.View;

import com.yuewen.mix_stack.core.PageOverlayConfig;
import com.yuewen.mix_stack.utils.CommonUtils;

import java.util.ArrayList;
import java.util.List;

/*******************************************************
 *
 * Created by julis.wang on 2020/09/22 11:18
 *
 * Description :
 * History   :
 *
 *******************************************************/

public class AreaInsetsConfig {
    private List<String> leftIgnoreNames;
    private List<String> topIgnoreNames;
    private List<String> rightIgnoreNames;
    private List<String> bottomIgnoreNames;

    public AreaInsetsConfig() {
        leftIgnoreNames = new ArrayList<>();
        topIgnoreNames = new ArrayList<>();
        rightIgnoreNames = new ArrayList<>();
        bottomIgnoreNames = new ArrayList<>();
    }

    public void setLeftIgnoreNames(List<String> leftIgnoreNames) {
        this.leftIgnoreNames = leftIgnoreNames;
    }

    public void setTopIgnoreNames(List<String> topIgnoreNames) {
        this.topIgnoreNames = topIgnoreNames;
    }

    public void setRightIgnoreNames(List<String> rightIgnoreNames) {
        this.rightIgnoreNames = rightIgnoreNames;
    }

    public void setBottomIgnoreNames(List<String> bottomIgnoreNames) {
        this.bottomIgnoreNames = bottomIgnoreNames;
    }

    public void addLeftIgnoreNames(String leftIgnoreName) {
        leftIgnoreNames.add(leftIgnoreName);
    }

    public void addTopIgnoreNames(String topIgnoreName) {
        topIgnoreNames.add(topIgnoreName);
    }

    public void addRightIgnoreNames(String rightIgnoreName) {
        rightIgnoreNames.add(rightIgnoreName);
    }

    public void addBottomIgnoreNames(String bottomIgnoreName) {
        bottomIgnoreNames.add(bottomIgnoreName);
    }

    public MXViewConfig.InsetInfo areaInsetsForOverlayHandler(PageOverlayConfig config) {
        MXViewConfig.InsetInfo containerInsetInfo = new MXViewConfig.InsetInfo();
        float topInset = 0;
        float leftInset = 0;
        int rightViewCount = 0;
        int bottomViewCount = 0;
        float rightInset = Float.MAX_VALUE;
        float bottomInset = Float.MAX_VALUE;

        for (String name : leftIgnoreNames) {
            View view = config.overlayView(name);
            if (view.getVisibility() == View.VISIBLE) {
                leftInset = Math.max(view.getX(), leftInset);
            }
        }

        for (String name : topIgnoreNames) {
            View view = config.overlayView(name);
            if (view.getVisibility() == View.VISIBLE) {
                topInset = Math.max(view.getY(), topInset);
            }
        }

        for (String name : rightIgnoreNames) {
            View view = config.overlayView(name);
            if (view.getVisibility() == View.VISIBLE) {
                rightInset = Math.min(view.getX(), rightInset);
                rightViewCount++;
            }
        }

        for (String name : bottomIgnoreNames) {
            View view = config.overlayView(name);
            if (view.getVisibility() == View.VISIBLE) {
                bottomInset = Math.min(view.getY(), bottomInset);
                bottomViewCount++;
            }
        }
        rightInset = rightViewCount == 0 ? 0 : CommonUtils.getActivityWidth() - rightInset;
        bottomInset = bottomViewCount == 0 ? 0 : CommonUtils.getActivityContentViewHeight() - bottomInset;

        containerInsetInfo.left = CommonUtils.px2dip(leftInset);
        containerInsetInfo.top = CommonUtils.px2dip(topInset);
        containerInsetInfo.right = CommonUtils.px2dip(rightInset);
        containerInsetInfo.bottom = CommonUtils.px2dip(bottomInset);
        return containerInsetInfo;
    }
}

