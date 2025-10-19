import 'package:flutter/material.dart';
import 'package:pulsedevice/core/global_controller.dart';
import 'package:pulsedevice/core/hiveDb/user_profile_storage.dart';
import 'package:pulsedevice/core/service/yc_service.dart';
import 'package:pulsedevice/core/utils/snackbar_helper.dart';
import '../../../core/app_export.dart';
import '../models/two4_model.dart';

/// A controller class for the Two4Dialog.
///
/// This class manages the state of the Two4Dialog, including the
/// current two4ModelObj
class Two4Controller extends GetxController {
  Rx<Two4Model> two4ModelObj = Two4Model().obs;
  final gc = Get.find<GlobalController>();
  final String macAddress;
  Two4Controller(this.macAddress);
  @override
  void onInit() {
    super.onInit();
  }

  Future<void> blueToolDisconnect() async {
    await YcDeviceService.disconnectDeviceStatic();
    SnackbarHelper.showBlueSnackbar(
        title: 'snackbar_title'.tr,
        message: 'snackbar_bluetooth_disconnect'.tr);

    Future.delayed(const Duration(milliseconds: 500), () {
      UserProfileStorage.removeDevice(
          userId: gc.userId.value, macAddress: macAddress);
      goHomePage();
    });
  }

  void goHomePage() {
    Get.offNamedUntil(
        AppRoutes.homePage, ModalRoute.withName(AppRoutes.one2Screen));
  }
}
