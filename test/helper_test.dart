import 'package:flutter_test/flutter_test.dart';
import 'package:mix_stack/src/helper.dart';

void main() {
  test("Addr", () {
    expect('/test_blue?addr=456'.address, '456');
    expect('randomStr1231rfs'.address, null);
  });

  test("Path", () {
    expect('/test_blue?addr=456'.path, '/test_blue');
    expect('randomStr1231rfs'.path, null);
  });
}
