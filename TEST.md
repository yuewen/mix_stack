# 测试指南

## Flutter 测试

```shell
#生成数据
flutter test --coverage

#生成 HTML 可视化页面
genhtml coverage/lcov.info -o coverage/html

#打开可视化页面
open ./coverage/html/index.html
```
