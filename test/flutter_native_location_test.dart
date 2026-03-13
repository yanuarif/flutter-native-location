import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_native_location/flutter_native_location.dart';
import 'package:flutter_native_location/src/flutter_native_location_platform_interface.dart';
import 'package:flutter_native_location/src/flutter_native_location_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter_native_location/src/models/position.dart';

class MockFlutterNativeLocationPlatform
    with MockPlatformInterfaceMixin
    implements FlutterNativeLocationPlatform {
  @override
  Future<Position?> getLastLocation() {
    // TODO: implement getLastLocation
    throw UnimplementedError();
  }

  @override
  Future<TrackingState> getTrackingState() {
    // TODO: implement getTrackingState
    throw UnimplementedError();
  }

  @override
  // TODO: implement locationStream
  Stream<Position> get locationStream => throw UnimplementedError();

  @override
  Future<void> pauseTracking() {
    // TODO: implement pauseTracking
    throw UnimplementedError();
  }

  @override
  Future<String> requestPermission() {
    // TODO: implement requestPermission
    throw UnimplementedError();
  }

  @override
  Future<void> resumeTracking() {
    // TODO: implement resumeTracking
    throw UnimplementedError();
  }

  @override
  Future<void> startTracking(LocationConfig config) {
    // TODO: implement startTracking
    throw UnimplementedError();
  }

  @override
  Future<void> stopTracking() {
    // TODO: implement stopTracking
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
