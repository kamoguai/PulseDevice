import 'package:pulsedevice/core/global_controller.dart' show GlobalController;
import 'package:pulsedevice/core/hiveDb/listen_setting.dart';
import 'package:pulsedevice/core/hiveDb/listen_setting_storage.dart';
import 'package:pulsedevice/core/service/yc_service.dart';
import 'package:pulsedevice/presentation/two10_screen/models/two10_model.dart';

import '../../../core/app_export.dart';

/// A controller class for the Two10Screen.
///
/// This class manages the state of the Two10Screen, including the
/// current Two10ModelObj
class Two10Controller extends GetxController {
  Rx<Two10Model> Two10ModelObj = Two10Model().obs;
  final gc = Get.find<GlobalController>();
  final isSelectedSwitch = false.obs;
  // 壓力過高門檻
  var times = 60.obs;
  var timeMin = 1.obs;
  var timeMax = 60.obs;
  late ListenSetting profile;

  @override
  void onInit() {
    super.onInit();
    getData();
  }

  void saveData() async {
    profile = ListenSetting(
      times: times.value.toInt(),
    );
    ListenSettingStorage.saveUserProfile(gc.userId.value, profile);

    ///設定裝置偵測時間
    YcDeviceService.setListeningTime(times.value.toInt());
  }

  void getData() async {
    var data = await ListenSettingStorage.getUserProfile(gc.userId.value);

    if (data != null) {
      times.value = data.times!;
    }
  }
}
