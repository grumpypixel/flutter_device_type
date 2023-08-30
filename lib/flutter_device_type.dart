library flutter_device_type;

import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

class Device {
  Device({
    required this.isAndroid,
    required this.isIos,
    required this.isPhone,
    required this.isTablet,
    required this.isIphoneX,
    required this.hasNotch,
    required this.isWeb,
  });

  final bool isAndroid;
  final bool isIos;
  final bool isPhone;
  final bool isTablet;
  final bool isIphoneX;
  final bool hasNotch;
  final bool isWeb;

  factory Device.get() {
    if (_device == null) {
      _device = _createDevice();
    }
    return _device!;
  }

  static Device _createDevice() {
    if (onMetricsChanged == null) {
      onMetricsChanged =
          WidgetsBinding.instance.platformDispatcher.onMetricsChanged;

      WidgetsBinding.instance.platformDispatcher.onMetricsChanged = () {
        _device = null;

        size = _view.physicalSize;
        width = size.width;
        height = size.height;
        screenWidth = width / devicePixelRatio;
        screenHeight = height / devicePixelRatio;
        screenSize = Size(screenWidth, screenHeight);

        onMetricsChanged!();
      };
    }

    bool isTablet;
    bool isPhone;

    if (devicePixelRatio < 2 && (width >= 1000 || height >= 1000)) {
      isTablet = true;
      isPhone = false;
    } else if (devicePixelRatio == 2 && (width >= 1920 || height >= 1920)) {
      isTablet = true;
      isPhone = false;
    } else {
      isTablet = false;
      isPhone = true;
    }

    // Recalculate for Android Tablet using device inches
    bool isAndroid = !kIsWeb && Platform.isAndroid;
    if (isAndroid) {
      final adjustedWidth = _calcWidth / devicePixelRatio;
      final adjustedHeight = _calcHeight / devicePixelRatio;
      final diagonalSizeInches =
          (sqrt(pow(adjustedWidth, 2) + pow(adjustedHeight, 2))) / _ppi;
      if (diagonalSizeInches >= 7) {
        isTablet = true;
        isPhone = false;
      } else {
        isTablet = false;
        isPhone = true;
      }
    }

    bool isIos = !kIsWeb && Platform.isIOS;
    var isIphoneX = false;
    var hasNotch = false;

    // Logical resolutions: https://www.ios-resolution.com
    // Apple devices with notch: https://apple.fandom.com/wiki/Notch
    if (isIos &&
        isPhone &&
        // iPhone x, xs, 11 pro, 12 mini, 13 mini
        ((screenHeight == 812 && screenWidth == 375) ||
            // iPhone 12, 12 pro, 13, 13 pro, 14
            (screenHeight == 844 && screenWidth == 390) ||
            // iPhone 14 pro
            (screenHeight == 852 && screenWidth == 393) ||
            // iPhone xr, xs max, 11, 11 pro max
            (screenHeight == 896 && screenWidth == 414) ||
            // iPhone 12 pro max, 13 pro max, 14 plus
            (screenHeight == 926 && screenWidth == 428) ||
            // iPhone 14 pro max
            (screenHeight == 932 && screenWidth == 430))) {
      isIphoneX = true;
      hasNotch = true;
    }

    if (_hasTopOrBottomPadding) {
      hasNotch = true;
    }

    return _device = Device(
      isTablet: isTablet,
      isPhone: isPhone,
      isAndroid: isAndroid,
      isIos: isIos,
      isIphoneX: isIphoneX,
      hasNotch: hasNotch,
      isWeb: kIsWeb,
    );
  }

  /// Helper method to do a rudimentary check whether the device is a phone,
  /// or a bigger device based on the given [Size].
  static bool isDevicePhone(Size deviceSize) => deviceSize.shortestSide < 550;

  static double devicePixelRatio = _view.devicePixelRatio;
  static Size size = _view.physicalSize;
  static double width = size.width;
  static double height = size.height;
  static double screenWidth = width / devicePixelRatio;
  static double screenHeight = height / devicePixelRatio;
  static Size screenSize = Size(screenWidth, screenHeight);
  static Function? onMetricsChanged;

  static Device? _device;

  static double get _calcWidth => width > height
      ? width + (_viewPadding.left + _viewPadding.right) * width / height
      : width + _viewPadding.left + _viewPadding.right;

  static double get _calcHeight =>
      height + (_viewPadding.top + _viewPadding.bottom);

  static bool get _hasTopOrBottomPadding =>
      _viewPadding.top > 0 || _viewPadding.bottom > 0;

  static int get _ppi => !kIsWeb && Platform.isAndroid
      ? 160
      : !kIsWeb && Platform.isIOS
          ? 150
          : 96;

  static FlutterView get _view => PlatformDispatcher.instance.views.first;

  static ViewPadding get _viewPadding => _view.viewPadding;
}
