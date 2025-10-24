import 'dart:async';
import 'package:get/get.dart';
import 'package:pulsedevice/core/global_controller.dart';
import 'package:pulsedevice/core/hiveDb/device_profile.dart';
import 'package:pulsedevice/core/hiveDb/user_profile_storage.dart';
import 'package:pulsedevice/core/utils/snackbar_helper.dart';
import 'package:pulsedevice/routes/app_routes.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';

/// YC 設備服務 - 統一管理藍牙設備相關操作
class YcDeviceService {
  // 單例實例
  static YcDeviceService? _instance;

  // 私有構造函數
  YcDeviceService._internal();

  // 獲取實例
  static YcDeviceService get instance {
    _instance ??= YcDeviceService._internal();
    return _instance!;
  }

  // factory 構造函數
  factory YcDeviceService() => instance;

  // 藍牙狀態回調
  Function(int)? onBluetoothStatusChanged;
  Function(bool)? onConnectionStatusChanged;
  Function(bool)? onDataReadyChanged;

  // 內部狀態
  bool _isInitialized = false;
  bool _isListening = false;
  int _currentBluetoothStatus = 0;
  bool _isConnected = false;
  bool _isDataReady = false;

  // 重連機制相關
  Timer? _reconnectTimer;
  bool _isReconnectEnabled = false;
  static const int reconnectInterval = 30; // 30秒

  /// 初始化服務
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      YcProductPlugin().initPlugin(isReconnectEnable: true, isLogEnable: true);
      _setupEventListening();
      _isInitialized = true;
      print("✅ YcDeviceService 初始化成功");
      return true;
    } catch (e) {
      print("❌ YcDeviceService 初始化失敗: $e");
      return false;
    }
  }

  /// 設置事件監聽（內部方法）
  void _setupEventListening() {
    if (_isListening) return;

    YcProductPlugin().onListening((event) {
      print("=== YcDeviceService 收到事件: $event");
      _handleDeviceEvent(event);
    });
    _isListening = true;
    print("✅ YcDeviceService 事件監聽已設置");
  }

  /// 內部事件處理
  void _handleDeviceEvent(Map event) {
    try {
      // 處理藍牙狀態變化
      if (event.containsKey(NativeEventType.bluetoothStateChange)) {
        int newStatus = event[NativeEventType.bluetoothStateChange];
        _handleBluetoothStateChange(newStatus);
      }

      // 🔄 新增：處理運動事件並分發到GlobalController
      if (event.containsKey(NativeEventType.deviceRealSport)) {
        print("🏃 YcDeviceService 收到運動事件，分發到GlobalController");
        // 獲取GlobalController實例並分發事件
        try {
          final gc = Get.find<GlobalController>();
          gc.distributeEvent(event);
          print("✅ YcDeviceService 運動事件分發成功");
        } catch (e) {
          print("❌ YcDeviceService 運動事件分發失敗: $e");
        }
      }

      // 🔄 新增：處理其他設備事件（如需要）
      // 可以在這裡添加其他事件類型的處理邏輯
    } catch (e) {
      print("❌ YcDeviceService 事件處理失敗: $e");
    }
  }

  /// 內部藍牙狀態處理
  void _handleBluetoothStateChange(int newStatus) {
    print("🔵 YcDeviceService 處理藍牙狀態變化: $newStatus");

    _currentBluetoothStatus = newStatus;

    switch (newStatus) {
      case 2: // 已連接
        _isConnected = true;
        onBluetoothStatusChanged?.call(newStatus);
        onConnectionStatusChanged?.call(true);
        print("✅ 設備已連接");
        break;

      case 0: // 斷開
      case 3: // 連接中
      case 4: // 連接失敗
        _isConnected = false;
        _isDataReady = false;
        onBluetoothStatusChanged?.call(newStatus);
        onConnectionStatusChanged?.call(false);
        onDataReadyChanged?.call(false);
        print("❌ 設備連接狀態改變: $newStatus");
        break;
    }
  }

  /// 設置藍牙狀態回調
  void setBluetoothStatusCallback(Function(int) callback) {
    onBluetoothStatusChanged = callback;
  }

  /// 設置連接狀態回調
  void setConnectionStatusCallback(Function(bool) callback) {
    onConnectionStatusChanged = callback;
  }

  /// 設置數據準備狀態回調
  void setDataReadyCallback(Function(bool) callback) {
    onDataReadyChanged = callback;
  }

  /// 獲取當前藍牙狀態
  int get currentBluetoothStatus => _currentBluetoothStatus;

  /// 獲取連接狀態
  bool get isConnected => _isConnected;

  /// 獲取數據準備狀態
  bool get isDataReady => _isDataReady;

  /// 設置數據準備狀態
  void setDataReady(bool ready) {
    _isDataReady = ready;
    onDataReadyChanged?.call(ready);
  }

  /// 查詢設備基本資訊
  Future<bool> queryDeviceBasicInfo() async {
    try {
      PluginResponse<DeviceBasicInfo>? deviceBasicInfo =
          await YcProductPlugin().queryDeviceBasicInfo();

      if (deviceBasicInfo != null && deviceBasicInfo.statusCode == 0) {
        // 檢查電量
        if (deviceBasicInfo.data.batteryPower < 20) {
          print("⚠️ 設備電量低於 20%");
        }

        // 設置數據準備完成
        setDataReady(true);
        return true;
      }
      return false;
    } catch (e) {
      print("❌ 查詢設備資訊失敗: $e");
      return false;
    }
  }

  /// 獲取設備電量
  Future<int?> getBatteryLevel() async {
    try {
      PluginResponse<DeviceBasicInfo>? deviceBasicInfo =
          await YcProductPlugin().queryDeviceBasicInfo();

      if (deviceBasicInfo != null && deviceBasicInfo.statusCode == 0) {
        return deviceBasicInfo.data.batteryPower;
      }
      return null;
    } catch (e) {
      print("❌ 獲取電量失敗: $e");
      return null;
    }
  }

  /// 查詢設備型號
  Future<String?> getDeviceModel() async {
    try {
      PluginResponse<String>? res = await YcProductPlugin().queryDeviceModel();
      if (res != null && res.statusCode == PluginState.succeed) {
        return res.data;
      }
      return null;
    } catch (e) {
      print("❌ 查詢設備型號失敗: $e");
      return null;
    }
  }

  /// 開始運動
  Future<bool> startSport(int sportType) async {
    try {
      var res = await YcProductPlugin()
          .appControlSport(DeviceSportState.start, sportType);
      bool success = res != null && res.statusCode == PluginState.succeed;
      if (success) {
        print("✅ 開始運動成功: $sportType");
      } else {
        print("❌ 開始運動失敗: $sportType");
      }
      return success;
    } catch (e) {
      print("❌ 開始運動異常: $e");
      return false;
    }
  }

  /// 停止運動
  Future<bool> stopSport(int sportType) async {
    try {
      var res = await YcProductPlugin()
          .appControlSport(DeviceSportState.stop, sportType);
      bool success = res != null && res.statusCode == PluginState.succeed;
      if (success) {
        print("✅ 停止運動成功: $sportType");
      } else {
        print("❌ 停止運動失敗: $sportType");
      }
      return success;
    } catch (e) {
      print("❌ 停止運動異常: $e");
      return false;
    }
  }

  /// 設定健康監測模式
  Future<bool> setHealthMonitoring(bool enable, int interval) async {
    try {
      var res = await YcProductPlugin()
          .setDeviceHealthMonitoringMode(isEnable: enable, interval: interval);
      bool success = res != null && res.statusCode == PluginState.succeed;
      if (success) {
        print("✅ 設定健康監測成功: enable=$enable, interval=$interval");
      } else {
        print("❌ 設定健康監測失敗: enable=$enable, interval=$interval");
      }
      return success;
    } catch (e) {
      print("❌ 設定健康監測異常: $e");
      return false;
    }
  }

  // ======================================================
  // 🎯 新增：藍牙連接管理功能
  // ======================================================

  /// 獲取藍牙狀態
  Future<int?> getBluetoothState() async {
    try {
      final state = await YcProductPlugin().getBluetoothState();
      print("📱 藍牙狀態: $state");
      return state;
    } catch (e) {
      print("❌ 獲取藍牙狀態失敗: $e");
      return null;
    }
  }

  /// 掃描設備
  Future<List<BluetoothDevice>?> scanDevice({int time = 3}) async {
    try {
      final devices = await YcProductPlugin().scanDevice(time: time);
      if (devices != null) {
        print("🔍 掃描到 ${devices.length} 個設備");
      } else {
        print("❌ 掃描設備失敗");
      }
      return devices;
    } catch (e) {
      print("❌ 掃描設備異常: $e");
      return null;
    }
  }

  /// 連接設備
  Future<bool> connectDevice(BluetoothDevice device) async {
    try {
      final result = await YcProductPlugin().connectDevice(device);
      if (result == true) {
        print("✅ 設備連接成功: ${device.name}");
      } else {
        print("❌ 設備連接失敗: ${device.name}");
      }
      return result == true;
    } catch (e) {
      print("❌ 設備連接異常: $e");
      return false;
    }
  }

  /// 斷開設備
  Future<bool> disconnectDevice() async {
    try {
      await YcProductPlugin().disconnectDevice();
      print("✅ 設備斷開成功");
      return true;
    } catch (e) {
      print("❌ 設備斷開失敗: $e");
      return false;
    }
  }

  /// 設定重連功能
  Future<bool> setReconnectEnabled({required bool isReconnectEnable}) async {
    try {
      await YcProductPlugin()
          .setReconnectEnabled(isReconnectEnable: isReconnectEnable);
      print("✅ 重連設定成功: $isReconnectEnable");
      return true;
    } catch (e) {
      print("❌ 重連設定失敗: $e");
      return false;
    }
  }

  /// 重置配對
  Future<bool> resetBond() async {
    try {
      await YcProductPlugin().resetBond();
      print("✅ 重置配對成功");
      return true;
    } catch (e) {
      print("❌ 重置配對失敗: $e");
      return false;
    }
  }

  // ======================================================
  // 🎯 新增：數據管理功能
  // ======================================================

  /// 清除設備排程
  Future<bool> clearQueue() async {
    try {
      YcProductPlugin().clearQueue();
      print("✅ 清除設備排程成功");
      return true;
    } catch (e) {
      print("❌ 清除設備排程失敗: $e");
      return false;
    }
  }

  /// 刪除設備健康數據
  Future<bool> deleteDeviceHealthData(int dataType) async {
    try {
      final res = await YcProductPlugin().deleteDeviceHealthData(dataType);
      bool success = res != null && res.statusCode == PluginState.succeed;
      if (success) {
        print("✅ 刪除健康數據成功: $dataType");
      } else {
        print("❌ 刪除健康數據失敗: $dataType");
      }
      return success;
    } catch (e) {
      print("❌ 刪除健康數據異常: $e");
      return false;
    }
  }

  /// 查詢設備健康數據
  Future<List<dynamic>?> queryDeviceHealthData(int dataType) async {
    try {
      final result = await YcProductPlugin().queryDeviceHealthData(dataType);
      if (result?.statusCode == PluginState.succeed) {
        final list = result?.data ?? [];
        print("✅ 查詢健康數據成功: $dataType, 數量: ${list.length}");
        return list;
      } else {
        print("❌ 查詢健康數據失敗: $dataType");
        return null;
      }
    } catch (e) {
      print("❌ 查詢健康數據異常: $e");
      return null;
    }
  }

  /// 清除所有藍牙數據
  Future<bool> clearAllBluetoothData() async {
    try {
      // 清除健康數據
      await deleteDeviceHealthData(HealthDataType.step);
      await deleteDeviceHealthData(HealthDataType.sleep);
      await deleteDeviceHealthData(HealthDataType.heartRate);
      await deleteDeviceHealthData(HealthDataType.bloodPressure);
      await deleteDeviceHealthData(HealthDataType.combinedData);

      print("✅ 清除所有藍牙數據成功");
      return true;
    } catch (e) {
      print("❌ 清除所有藍牙數據失敗: $e");
      return false;
    }
  }

  // ======================================================
  // 🎯 保留原有靜態方法，向後兼容
  // ======================================================

  /// 開始跑步（向後兼容）
  static void startRunStep() async {
    await instance.startSport(DeviceSportType.run);
  }

  /// 停止跑步（向後兼容）
  static void stopRunStep() async {
    await instance.stopSport(DeviceSportType.run);
  }

  /// 設定監聽時間（向後兼容）
  static void setListeningTime(int interval) async {
    await instance.setHealthMonitoring(true, interval);
  }

  /// 查詢設備型號（向後兼容）
  static void queryDeviewModel() async {
    String? model = await instance.getDeviceModel();
    if (model != null) {
      SnackbarHelper.showBlueSnackbar(message: model);
    }
  }

  // ======================================================
  // 🎯 新增：向後兼容的靜態方法
  // ======================================================

  /// 獲取藍牙狀態（向後兼容）
  static Future<int?> getBluetoothStateStatic() async {
    return await instance.getBluetoothState();
  }

  /// 掃描設備（向後兼容）
  static Future<List<BluetoothDevice>?> scanDeviceStatic({int time = 3}) async {
    return await instance.scanDevice(time: time);
  }

  /// 連接設備（向後兼容）
  static Future<bool> connectDeviceStatic(BluetoothDevice device) async {
    return await instance.connectDevice(device);
  }

  /// 斷開設備（向後兼容）
  static Future<bool> disconnectDeviceStatic() async {
    return await instance.disconnectDevice();
  }

  /// 設定重連功能（向後兼容）
  static Future<bool> setReconnectEnabledStatic(
      {required bool isReconnectEnable}) async {
    return await instance.setReconnectEnabled(
        isReconnectEnable: isReconnectEnable);
  }

  /// 重置配對（向後兼容）
  static Future<bool> resetBondStatic() async {
    return await instance.resetBond();
  }

  /// 清除設備排程（向後兼容）
  static Future<bool> clearQueueStatic() async {
    return await instance.clearQueue();
  }

  /// 刪除設備健康數據（向後兼容）
  static Future<bool> deleteDeviceHealthDataStatic(int dataType) async {
    return await instance.deleteDeviceHealthData(dataType);
  }

  /// 查詢設備健康數據（向後兼容）
  static Future<List<dynamic>?> queryDeviceHealthDataStatic(
      int dataType) async {
    return await instance.queryDeviceHealthData(dataType);
  }

  /// 清除所有藍牙數據（向後兼容）
  static Future<bool> clearAllBluetoothDataStatic() async {
    return await instance.clearAllBluetoothData();
  }

  // ======================================================
  // 🎯 重連機制功能
  // ======================================================

  /// 啟動重連機制
  void startReconnectMechanism() {
    if (_isReconnectEnabled) {
      print("ℹ️ 重連機制已經在運行中");
      return;
    }

    // 檢查是否有綁定設備
    if (!_hasBoundDevice()) {
      print("❌ 沒有綁定設備，不啟動重連機制");
      return;
    }

    _isReconnectEnabled = true;
    _reconnectTimer =
        Timer.periodic(Duration(seconds: reconnectInterval), (timer) {
      _checkAndReconnect();
    });

    print("✅ 重連機制已啟動，每 ${reconnectInterval} 秒檢查一次");
  }

  /// 停止重連機制
  void stopReconnectMechanism() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _isReconnectEnabled = false;
    print("🛑 重連機制已停止");
  }

  /// 檢查是否有綁定設備
  bool _hasBoundDevice() {
    try {
      // 從 GlobalController 獲取當前用戶ID
      if (Get.isRegistered<GlobalController>()) {
        final globalController = Get.find<GlobalController>();
        final userId = globalController.userId.value;

        if (userId.isEmpty) {
          return false;
        }

        // 檢查用戶是否有綁定的設備
        final userProfile = UserProfileStorage.getUserProfile(userId);
        return userProfile?.devices?.isNotEmpty ?? false;
      }
      return false;
    } catch (e) {
      print("❌ 檢查綁定設備時發生錯誤: $e");
      return false;
    }
  }

  /// 檢查並重連
  void _checkAndReconnect() {
    try {
      // 1. 檢查當前頁面
      if (_shouldSkipReconnect()) {
        return;
      }

      // 2. 檢查設備連接狀態
      if (_isConnected) {
        return; // 已連接，不需要重連
      }

      // 3. 嘗試重連
      _attemptReconnect();
    } catch (e) {
      print("❌ 檢查重連時發生錯誤: $e");
    }
  }

  /// 檢查是否應該跳過重連
  bool _shouldSkipReconnect() {
    try {
      String currentRoute = Get.currentRoute;

      // 在這些頁面不進行重連
      List<String> skipRoutes = [
        AppRoutes.appNavigationScreen,
        AppRoutes.k0Screen,
        AppRoutes.k1Screen,
        AppRoutes.k2Screen,
        AppRoutes.oneScreen,
        AppRoutes.k10Screen,
        AppRoutes.one2Screen,
        AppRoutes.one3Screen,
        AppRoutes.two3Screen,
        AppRoutes.k40Screen,
        AppRoutes.k45Screen,
        AppRoutes.one9Screen,
        AppRoutes.initialRoute,
        AppRoutes.fourScreen,
        AppRoutes.k14Screen,
      ];

      bool shouldSkip = skipRoutes.contains(currentRoute);
      if (shouldSkip) {
        print("ℹ️ 當前頁面 $currentRoute 跳過重連");
      }
      return shouldSkip;
    } catch (e) {
      print("❌ 檢查頁面路由時發生錯誤: $e");
      return false;
    }
  }

  /// 嘗試重連
  Future<void> _attemptReconnect() async {
    try {
      print("🔄 開始嘗試重連...");

      // 1. 獲取綁定的設備信息
      DeviceProfile? deviceProfile = await _getBoundDeviceProfile();
      if (deviceProfile == null) {
        print("❌ 沒有找到綁定的設備信息");
        return;
      }

      // 2. 轉換為 BluetoothDevice
      BluetoothDevice device = _convertToBluetoothDevice(deviceProfile);

      // 3. 重置配對
      await resetBond();

      // 4. 嘗試連接
      bool success = await connectDevice(device);

      if (success) {
        print("✅ 重連成功");
        // 觸發連接成功回調
        onConnectionStatusChanged?.call(true);
      } else {
        print("❌ 重連失敗");
      }
    } catch (e) {
      print("❌ 重連過程中發生錯誤: $e");
    }
  }

  /// 獲取綁定的設備信息
  Future<DeviceProfile?> _getBoundDeviceProfile() async {
    try {
      if (Get.isRegistered<GlobalController>()) {
        final globalController = Get.find<GlobalController>();
        final userId = globalController.userId.value;

        if (userId.isEmpty) {
          return null;
        }

        // 獲取用戶的設備列表
        final devices = await UserProfileStorage.getDevicesForUser(userId);

        if (devices.isNotEmpty) {
          // 返回第一個設備（可以根據需要調整邏輯）
          return devices.first;
        }
      }
      return null;
    } catch (e) {
      print("❌ 獲取綁定設備信息時發生錯誤: $e");
      return null;
    }
  }

  /// 將 DeviceProfile 轉換為 BluetoothDevice
  BluetoothDevice _convertToBluetoothDevice(DeviceProfile profile) {
    final Map<String, dynamic> json = {
      "macAddress": profile.macAddress,
      "deviceIdentifier": profile.deviceIdentifier,
      "name": profile.name,
      "rssiValue": profile.rssiValue,
      "firmwareVersion": profile.firmwareVersion,
      "deviceSize": profile.deviceSize,
      "deviceColor": profile.deviceColor,
      "imageIndex": profile.imageIndex,
      "deviceModel": profile.deviceModel,
    };

    return BluetoothDevice.formJson(json);
  }

  /// 獲取重連狀態
  bool get isReconnectEnabled => _isReconnectEnabled;

  /// 清理資源
  void dispose() {
    // 停止重連機制
    stopReconnectMechanism();

    YcProductPlugin().cancelListening();
    _isListening = false;
    _isInitialized = false;
    onBluetoothStatusChanged = null;
    onConnectionStatusChanged = null;
    onDataReadyChanged = null;
    print("✅ YcDeviceService 已清理");
  }
}
