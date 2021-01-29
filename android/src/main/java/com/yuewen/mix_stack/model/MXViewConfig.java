package com.yuewen.mix_stack.model;

import android.os.Build;

import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

/*******************************************************
 *
 * Created by julis.wang on 2020/08/14 11:05
 *
 * Description :
 * History   :
 *
 *******************************************************/

public class MXViewConfig {
    private boolean hidden;
    private float alpha;
    private boolean needsAnimation;

    public MXViewConfig(boolean hidden, float alpha, boolean needsAnimation) {
        this.hidden = hidden;
        this.alpha = alpha;
        this.needsAnimation = needsAnimation;
    }

    public MXViewConfig(boolean hidden, float alpha) {
        this(hidden, alpha, false);
    }

    public boolean isHidden() {
        return hidden;
    }

    public float getAlpha() {
        return alpha;
    }

    public boolean isNeedsAnimation() {
        return needsAnimation;
    }

    public static class InsetInfo {
        public float left;
        public float top;
        public float right;
        public float bottom;

        public Map<String, Float> toMap() {
            Map<String, Float> map = new HashMap<>();
            map.put("left", left);
            map.put("right", right);
            map.put("top", top);
            map.put("bottom", bottom);
            return map;
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            InsetInfo insetInfo = (InsetInfo) o;
            return Float.compare(insetInfo.left, left) == 0
                    && Float.compare(insetInfo.top, top) == 0
                    && Float.compare(insetInfo.right, right) == 0
                    && Float.compare(insetInfo.bottom, bottom) == 0;
        }

        @Override
        public int hashCode() {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                return Objects.hash(left, top, right, bottom);
            }
            return 0;
        }
    }
}
