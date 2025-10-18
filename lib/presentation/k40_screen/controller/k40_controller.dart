import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pulsedevice/core/global_controller.dart';
import 'package:pulsedevice/core/service/firebase_analytics_service.dart';
import 'package:pulsedevice/core/service/yc_service.dart';
import 'package:pulsedevice/core/hiveDb/user_profile_storage.dart';
import 'package:pulsedevice/core/utils/dialog_utils.dart';
import 'package:pulsedevice/presentation/ios_dialog/controller/ios_controller.dart';
import 'package:pulsedevice/presentation/ios_dialog/ios_dialog.dart';
import 'package:pulsedevice/presentation/k40_screen/models/listpulsering_item_model.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';

import '../../../core/app_export.dart';
import '../models/k40_model.dart';

/// A controller class for the K40Screen.
///
/// This class manages the state of the K40Screen, including the
/// current k40ModelObj
class K40Controller extends GetxController {
  Rx<K40Model> k40ModelObj = K40Model().obs;
  final gc = Get.find<GlobalController>();
  var selectDevice = [].obs;
  final power = "".obs;

  @override
  void onInit() {
    super.onInit();

    // 📊 記錄我的設備頁面瀏覽事件
    FirebaseAnalyticsService.instance.logViewMyDevices();

    loadDevices();
    Future.delayed(const Duration(microseconds: 500), () {
      getBlueToothDeviceInfo();
    });
  }

  @override
  void onReady() {
    super.onReady();
  }

  void loadDevices() async {
    print("laodDevices");

    UserProfileStorage.getDevicesForUser(gc.userId.value).then((devices) {
      print("loading db devices");
      if (devices.isNotEmpty) {
        for (var device in devices) {
          final item = ListpulseringItemModel(
              pulsering: Rx("lbl_pulsering3".tr),
              id: Rx("msg_device_id".tr + " : " + device.deviceIdentifier),
              tf: Rx("msg_bind_time".tr + " : " + device.createdAt),
              pulsering1: Rx(ImageConstant.imgFrame86618),
              power: Rx("msg_power".tr + " : " + power.value));
          k40ModelObj.value.listpulseringItemList.value.add(item);

          selectDevice.add(device);
        }

        k40ModelObj.value.listpulseringItemList.refresh();
      }
    });
  }

  /// 註冊設備頁面
  void goK10Screen() {
    Get.toNamed(AppRoutes.k10Screen);
  }

  /// 路由到戒指資訊頁面
  void goK45Screen(dynamic selectedObject) {
    Get.toNamed(AppRoutes.k45Screen, arguments: selectedObject);
  }

  Future<void> showBlueTooth() async {
    final result = await DialogHelper.showCustomDialog(
        Get.context!, IosDialog(Get.put(IosController())));
    if (result != null && result.isNotEmpty) {}
  }

  Future<void> checkBluetoothPermission() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        bool granted = false;

        if (sdkInt >= 31) {
          final statusScan = await Permission.bluetoothScan.request();
          final statusConnect = await Permission.bluetoothConnect.request();
          granted = statusScan.isGranted && statusConnect.isGranted;
        } else {
          final statusLocation = await Permission.locationWhenInUse.request();
          granted = statusLocation.isGranted;
        }
        if (granted) {
          final state = await YcDeviceService.getBluetoothStateStatic();
          if (state == BluetoothState.on ||
              state == BluetoothState.disconnected ||
              state == BluetoothState.connected) {
            goK10Screen();
          } else {
            showBlueTooth();
          }
        } else {
          Get.snackbar('權限錯誤', '請開啟藍牙相關權限');
          showBlueTooth();
        }
      } else {
        goK10Screen();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> getBlueToothDeviceInfo() async {
    k40ModelObj.value.listpulseringItemList.refresh();
    try {
      bool success = await YcDeviceService.instance.queryDeviceBasicInfo();
      if (success) {
        int? battery = await YcDeviceService.instance.getBatteryLevel();
        if (battery != null) {
          power.value = "$battery %";
          k40ModelObj.value.listpulseringItemList.value[0].power =
              Rx("msg_power".tr + " : " + power.value);
          k40ModelObj.value.listpulseringItemList.refresh();
        }
      }
    } catch (e) {
      power.value = "";
    }
  }
}
