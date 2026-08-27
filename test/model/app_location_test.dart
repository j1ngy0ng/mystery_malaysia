import 'package:flutter_test/flutter_test.dart';
import 'package:mystery_malaysia/model/active_mission/app_location.dart';

void main() {
  test(
    'recognises Malaysia regions and rejects clearly foreign coordinates',
    () {
      expect(
        const AppLocation(
          latitude: 3.139,
          longitude: 101.6869,
        ).couldBeInMalaysia,
        true,
      );
      expect(
        const AppLocation(
          latitude: 5.9804,
          longitude: 116.0735,
        ).couldBeInMalaysia,
        true,
      );
      expect(
        const AppLocation(
          latitude: 51.5072,
          longitude: -0.1276,
        ).couldBeInMalaysia,
        false,
      );
    },
  );
}
