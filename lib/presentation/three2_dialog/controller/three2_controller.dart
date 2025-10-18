import 'package:pulsedevice/core/global_controller.dart';
import 'package:pulsedevice/core/hiveDb/user_profile_storage.dart';
import 'package:pulsedevice/core/network/api.dart';
import 'package:pulsedevice/core/network/api_service.dart';
import 'package:pulsedevice/core/service/yc_service.dart';
import 'package:pulsedevice/core/utils/dialog_utils.dart';
import 'package:pulsedevice/core/utils/loading_helper.dart';
import 'package:pulsedevice/core/utils/snackbar_helper.dart';
import '../../../core/app_export.dart';
import '../models/three2_model.dart';

/// A controller class for the Three2Dialog.
///
/// This class manages the state of the Three2Dialog, including the
/// current three2ModelObj
class Three2Controller extends GetxController {
  Rx<Three2Model> three2ModelObj = Three2Model().obs;
  final gc = Get.find<GlobalController>();
  final service = ApiService();
  Future<void> deleteAccount() async {
    var isAccountExist = await UserProfileStorage.exists(gc.userId.value);
    var userId = await PrefUtils().getUserId();
    if (isAccountExist || userId.isNotEmpty) {
      await UserProfileStorage.deleteUserProfile(gc.userId.value);
      gc.userEmail.value = "";
      SnackbarHelper.showBlueSnackbar(message: "snackbar_account_delete".tr);
      blueToolDisconnect();
      callApi().then((value) {
        goLogin();
      });
    } else {
      Get.back();
      SnackbarHelper.showBlueSnackbar(message: "snackbar_no_account_delete".tr);
    }
  }

  Future<void> callApi() async {
    LoadingHelper.show();
    try {
      var resData = await service.postJson(
        Api.delete,
        {
          'userId': gc.apiId.value,
        },
      );
      LoadingHelper.hide();
      if (resData.isNotEmpty) {
        final success = resData["success"];
        if (success == true) {
          DialogHelper.showError("${resData["message"]}", onOk: () {});
        } else {
          DialogHelper.showError("${resData["message"]}");
        }
      }
    } catch (e) {
      LoadingHelper.hide();
    }
  }

  void goLogin() {
    Get.offNamed(AppRoutes.k2Screen);
  }

  /// 斷開藍牙
  Future<void> blueToolDisconnect() async {
    await YcDeviceService.disconnectDeviceStatic();
  }
}
