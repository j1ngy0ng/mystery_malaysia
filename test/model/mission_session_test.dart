import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/model/active_mission/mission_session.dart';

void main() {
  test('parses a saved mission as ready to start', () {
    expect(missionStatusFromJson('ready'), MissionStatus.ready);
  });
}
