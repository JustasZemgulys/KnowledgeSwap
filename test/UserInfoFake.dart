import 'package:flutter_test/flutter_test.dart';
import 'package:knowledgeswap/models/user_info.dart';
import 'package:mocktail/mocktail.dart';

class UserInfoFake extends Fake implements UserInfo {}

void main() {
  setUpAll(() {
    registerFallbackValue(UserInfoFake());
  });

  // Your tests go here, e.g.
  testWidgets('loginUser success shows navigation', (tester) async {
    // test code
  });

  testWidgets('loginUser success returns and proceeds', (tester) async {
    // test code
  });
}
