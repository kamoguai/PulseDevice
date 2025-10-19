import 'package:pulsedevice/core/global_controller.dart';
import 'package:pulsedevice/core/hiveDb/device_profile.dart';
import 'package:pulsedevice/core/service/yc_service.dart';
import 'package:pulsedevice/core/utils/dialog_utils.dart';
import 'package:pulsedevice/presentation/two4_dialog/controller/two4_controller.dart';
import 'package:pulsedevice/presentation/two4_dialog/two4_dialog.dart';
import '../../../core/app_export.dart';
import '../models/k45_model.dart';

/// A controller class for the K45Screen.
///
/// This class manages the state of the K45Screen, including the
/// current k45ModelObj
class K45Controller extends GetxController {
  Rx<K45Model> k45ModelObj = K45Model().obs;
  final device = Get.arguments as DeviceProfile;
  final gc = Get.find<GlobalController>();
  var power = ''.obs;
  var deviceId = ''.obs;
  var createdAt = ''.obs;
  @override
  void onInit() {
    super.onInit();
    getBlueToothDeviceInfo();
  }

  Future<void> getBlueToothDeviceInfo() async {
    bool success = await YcDeviceService.instance.queryDeviceBasicInfo();
    if (success) {
      int? battery = await YcDeviceService.instance.getBatteryLevel();
      if (battery != null) {
        power.value = "$battery %";
        gc.blueToolStatus.value = 2;
        initBlueTooth();
      }
    }
    deviceId.value = '${device.macAddress}';
    createdAt.value = '${device.createdAt}';
  }

  Future<void> initBlueTooth() async {
    if (gc.isSqfliteInit.value == false) {
      gc.initFunc();
    }
  }

  Future<void> showDelete() async {
    await DialogHelper.showCustomDialog(
      Get.context!,
      Two4Dialog(
        Get.put(Two4Controller(device.macAddress)),
      ),
    );
  }
}
