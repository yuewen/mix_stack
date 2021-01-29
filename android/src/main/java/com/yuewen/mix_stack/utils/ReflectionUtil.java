package com.yuewen.mix_stack.utils;

import java.lang.reflect.Field;
import java.lang.reflect.Method;

/*******************************************************
 *
 * Created by julis.wang on 2020/09/01 16:05
 *
 * Description :
 * History   :
 *
 *******************************************************/

public final class ReflectionUtil {

    public static Field getField(Class clazz, String fieldName) {
        try {
            Field f = clazz.getDeclaredField(fieldName);
            f.setAccessible(true);
            return f;
        } catch (NoSuchFieldException var3) {
            return null;
        }
    }

    public static Object getValue(Field field, Object obj) {
        try {
            return field.get(obj);
        } catch (IllegalAccessException var3) {
            return null;
        }
    }

    public static void setValue(Field field, Object obj, Object value) {
        try {
            field.set(obj, value);
        } catch (IllegalAccessException var4) {
        }

    }

    public static Method getMethod(Class clazz, String methodName) {
        Method[] methods = clazz.getMethods();
        Method[] var3 = methods;
        int var4 = methods.length;

        for (int var5 = 0; var5 < var4; ++var5) {
            Method method = var3[var5];
            if (method.getName().equals(methodName)) {
                method.setAccessible(true);
                return method;
            }
        }

        return null;
    }

    public static void invokeMethod(Object object, Method method, Object... args) {
        try {
            if (method == null) {
                return;
            }

            method.invoke(object, args);
        } catch (Exception var4) {
        }

    }
}
