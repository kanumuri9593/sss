import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigation Helper
///
/// Provides convenient methods for navigation using go_router
class NavigationHelper {
  /// Navigate to home
  static void goHome(BuildContext context) {
    context.go('/');
  }

  /// Navigate to container detail
  static void goToContainer(BuildContext context, String containerId) {
    context.push('/containers/$containerId');
  }

  /// Navigate to create container
  static void goToCreateContainer(BuildContext context, {String? editContainerId}) {
    if (editContainerId != null) {
      context.push('/containers/create?edit=$editContainerId');
    } else {
      context.push('/containers/create');
    }
  }

  /// Navigate to create item
  static void goToCreateItem(BuildContext context, String containerId) {
    context.push('/containers/$containerId/items/create');
  }

  /// Navigate to search
  static void goToSearch(BuildContext context, {String? query}) {
    if (query != null) {
      context.push('/search?q=$query');
    } else {
      context.push('/search');
    }
  }

  /// Navigate to QR scanner
  static void goToScanner(BuildContext context) {
    context.push('/scan');
  }

  /// Navigate to QR detail
  static void goToQRDetail(BuildContext context, String qrId) {
    context.push('/qr/$qrId');
  }

  /// Navigate to NFC detail
  static void goToNFCDetail(BuildContext context, String nfcId) {
    context.push('/nfc/$nfcId');
  }

  /// Navigate to profile
  static void goToProfile(BuildContext context) {
    context.push('/profile');
  }

  /// Navigate to settings
  static void goToSettings(BuildContext context) {
    context.push('/settings');
  }

  /// Go back
  static void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  /// Go back with result
  static void goBackWithResult<T>(BuildContext context, T result) {
    if (context.canPop()) {
      context.pop(result);
    } else {
      context.go('/');
    }
  }
}
