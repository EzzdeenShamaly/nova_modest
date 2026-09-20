import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:image_picker/image_picker.dart';
// Both are already in the tree as image_picker's own dependencies; declaring
// them in pubspec.yaml is what the plugin's README requires to reach the
// Android implementation directly. No new code arrives with them.
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:injectable/injectable.dart';

/// Picks one picture from the device's gallery, already scaled down.
///
/// **Android is not the web**, and the dashboard's experience with
/// `image_picker_for_web` does not carry over:
///
/// * `maxWidth` / `maxHeight` / `imageQuality` are applied **natively on
///   Android** — for JPEG, PNG and WebP — so the resize happens before a single
///   byte reaches Dart. On web those arguments are ignored and the full-size
///   image arrives.
/// * Android's system **Photo Picker** needs no storage permission at all, but
///   it is opt-in below Android 15 through
///   `ImagePickerAndroid.useAndroidPhotoPicker`. Without it the legacy picker
///   runs and can demand a permission this app never declares.
/// * Android can **destroy the activity** while the picker is open, on a device
///   short of memory, and the result is then lost rather than returned. Only
///   Android has this, and only `retrieveLostData` gets it back.
@lazySingleton
class AvatarPicker {
  /// The seam a test hands its own picker through.
  @visibleForTesting
  AvatarPicker(this._picker) {
    _useSystemPhotoPicker();
  }

  /// What `get_it` builds.
  ///
  /// Named for injectable's benefit: with a plain optional parameter the
  /// generator tries to resolve an `ImagePicker` from the container, which
  /// nothing registers, and the app fails on first use rather than at compile
  /// time.
  @factoryMethod
  factory AvatarPicker.live() => AvatarPicker(ImagePicker());

  final ImagePicker _picker;

  /// The avatar is drawn at 64pt at its largest — 192 device pixels on a 3x
  /// phone. 512 leaves room for a bigger frame later without carrying a
  /// portrait-sized file for a disc the size of a fingertip.
  static const double _maxSide = 512;

  /// Visible compression starts below roughly 80 for photographs; 85 is a
  /// common default that keeps a face clean at this size.
  static const int _quality = 85;

  /// The picked image's bytes, or null if the shopper backed out.
  Future<Uint8List?> pick() async {
    final file = await _picker.pickImage(
      // Gallery only: a camera source would need the camera permission, and
      // the app declares none.
      source: ImageSource.gallery,
      maxWidth: _maxSide,
      maxHeight: _maxSide,
      imageQuality: _quality,
    );
    return file?.readAsBytes();
  }

  /// What Android dropped when it killed the activity mid-pick, if anything.
  ///
  /// Called when the profile screen comes back, before drawing. On every other
  /// platform there is nothing to recover and this answers null.
  Future<Uint8List?> recoverLostPick() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final response = await _picker.retrieveLostData();
    if (response.isEmpty || response.file == null) return null;
    return response.file!.readAsBytes();
  }

  void _useSystemPhotoPicker() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final implementation = ImagePickerPlatform.instance;
    if (implementation is ImagePickerAndroid) {
      // No storage permission, and the shopper only ever exposes the one
      // picture they choose.
      implementation.useAndroidPhotoPicker = true;
    }
  }
}
