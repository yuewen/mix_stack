import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_stack/src/pages.dart';
import 'package:mix_stack/src/helper.dart';

void main() {
  group("Pages Command", () {
    final command = PagesCommand();
    //Use this to make sure notify called
    int notifyCount = 0;
    command.addListener(() {
      notifyCount += 1;
    });
    test("Update Pages", () async {
      final current = 'test?addr=1';
      final pgs = ['test?addr=1', 'test?addr=2'];
      notifyCount = 0;
      command.update(pgs, current);
      expect(command.type, PagesCommandType.update);
      expect(command.currentPage, current);
      expect(command.pages, pgs);
      expect(notifyCount, 1);
    });

    test("Update Info", () async {
      final info = PageContainerInfo({'left': 1.0, 'top': 2.0, 'right': 3.0, 'bottom': 4.0});
      notifyCount = 0;
      command.updateInfo('test?addr=1', info);
      expect(command.type, PagesCommandType.updateInfo);
      expect(command.containerInfo!.insets, info.insets);
      expect(notifyCount, 1);
    });

    test('PopPage', () async {
      notifyCount = 0;
      command.popPage('test?addr=1');
      expect(command.type, PagesCommandType.pop);
      expect(notifyCount, 1);
    });

    test('Page Event', () async {
      notifyCount = 0;
      command.pageEvent('test?addr=1', 'hello', {});
      expect(command.type, PagesCommandType.event);
      expect(notifyCount, 1);
    });

    test('Check Page Exist', () async {
      final pgs = ['test?addr=1', 'test?addr=2'];
      final current = 'test?addr=1';
      command.update(pgs, current);
      notifyCount = 0;
      bool result = command.exist(current.address);
      expect(result, true);
      expect(notifyCount, 0);
    });
    test('Page Navigator Stack Length', () async {
      notifyCount = 0;
      void updateInfo() {
        final a = PageInfo([]);
        command.pageNavInfo = a;
      }

      command.addListener(updateInfo);
      final target = 'test?addr=1';
      final info = command.pageNavigatorInfo(target);
      expect(command.type, PagesCommandType.query);
      expect(notifyCount, 1);
      expect(info!.history.length, 0);
      command.removeListener(updateInfo);
    });
  });

  group('Pages Widget', () {
    final command = PagesCommand();
    final eventQuery = {'a': 1};
    final eventCallback = (query) {
      expect(eventQuery, query);
    };
    late Function removeCallback;
    NavigatorState? navigator;
    late PageContainer container;
    testWidgets('Widget', (WidgetTester tester) async {
      final pages = Pages(
          command: command,
          routeForPath: (BuildContext context, String path) {
            return MaterialPageRoute(
              settings: RouteSettings(name: path),
              builder: (context) {
                expect(PageContainer.of(context) != null, true);
                navigator = Navigator.of(context);
                container = PageContainer.of(context);
                removeCallback = container.addListener('hello', eventCallback);
                print('----');
                print(navigator);
                return Container();
              },
            );
          });
      final app = MaterialApp(home: Scaffold(body: pages));
      command.updateInfo('/1?addr=1', PageContainerInfo({'left': 4.0, 'top': 3.0, 'right': 2.0, 'bottom': 1.0}));
      await tester.pumpWidget(app);
      command.update(['/1?addr=1'], '/1?addr=1');
      await tester.pump(Duration(milliseconds: 100));
      expect(find.descendant(of: find.byType(Pages), matching: find.byType(Stack)), findsOneWidget);
      command.popPage('/1?addr=1');
      expect(command.popResult, false);
      navigator!.pushNamed('/2');
      print(navigator);
      await tester.pump(Duration(seconds: 1));
      command.popPage('/1?addr=1');
      expect(command.popResult, true);
      final info = command.pageNavigatorInfo('/1?addr=1')!;
      expect(info.history, ['/1']);
      final containerInfo = PageContainerInfo({'left': 1.0, 'top': 2.0, 'right': 3.0, 'bottom': 4.0});
      command.updateInfo('/1?addr=1', containerInfo);
      command.pageEvent('test?addr=1', 'hello', eventQuery);
      expect(command.type, PagesCommandType.event);
      expect(command.eventName, 'hello');
      expect(command.eventQuery, eventQuery);
      container.removeListener('hello', eventCallback);
      removeCallback();
    });
  });
}
