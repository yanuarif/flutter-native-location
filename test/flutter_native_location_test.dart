import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_native_location/flutter_native_location.dart';
import 'package:flutter_native_location/src/flutter_native_location_platform_interface.dart';
import 'package:flutter_native_location/src/flutter_native_location_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';


class MockFlutterNativeLocationPlatform
    with MockPlatformInterfaceMixin
    implements FlutterNativeLocationPlatform {
  @override
  Stream<Position> getLocationStream(LocationConfig config) {
    return const Stream.empty();
  }

  @override
  Future<Position?> getLastLocation() {
    throw UnimplementedError();
  }

  @override
  Future<Position?> getCurrentLocation() {
    throw UnimplementedError();
  }
}

void main() {
  final FlutterNativeLocationPlatform initialPlatform =
      FlutterNativeLocationPlatform.instance;

  test('$MethodChannelFlutterNativeLocation is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterNativeLocation>());
  });
}
