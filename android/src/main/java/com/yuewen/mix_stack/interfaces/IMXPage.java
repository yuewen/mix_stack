package com.yuewen.mix_stack.interfaces;

/*******************************************************
 *
 * Created by julis.wang on 2020/08/11 10:33
 *
 * Description :
 * History   :
 *
 *******************************************************/

public interface IMXPage {
    /**
     * Every flutter page must have a route which tells flutter which page will show.
     * <p>
     * It implements in {@link com.yuewen.mix_stack.component.MXFlutterFragment} and
     * {@link com.yuewen.mix_stack.component.MXFlutterActivity},and called by
     * {@link com.yuewen.mix_stack.core.MXPageManager#setCurrentShowPage(Object)}
     *
     * @return the init root.
     */
    String rootRoute();


    /**
     * Has no flutter page will call this method.
     * Default implement is finish current Activity.
     */
    void onPopNative();
}
