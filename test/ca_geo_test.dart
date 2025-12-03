import 'package:casi/core/utils/ca_geo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('codeForProvinceName', () {
    test(
      'given known province name when requesting code then returns matching short code',
      () {
        expect(codeForProvinceName('Alberta'), equals('AB'));
        expect(codeForProvinceName('british columbia'), equals('BC'));
      },
    );

    test(
      'given unknown province name when requesting code then returns null',
      () {
        expect(codeForProvinceName('Atlantis'), isNull);
        expect(codeForProvinceName(''), isNull);
      },
    );
  });

  group('nameForProvinceCode', () {
    test(
      'given known code when requesting name then returns full province name',
      () {
        expect(nameForProvinceCode('AB'), equals('Alberta'));
        expect(nameForProvinceCode('SK'), equals('Saskatchewan'));
      },
    );

    test(
      'given unknown code when requesting name then returns original code',
      () {
        expect(nameForProvinceCode('ON'), equals('ON'));
        expect(nameForProvinceCode(null), equals(''));
      },
    );
  });
}
