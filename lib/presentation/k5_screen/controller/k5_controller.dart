import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pulsedevice/core/global_controller.dart';
import 'package:pulsedevice/core/service/firebase_analytics_service.dart';
import 'package:pulsedevice/core/hiveDb/sport_record.dart';
import 'package:pulsedevice/core/hiveDb/sport_record_list_storage.dart';
import 'package:pulsedevice/core/utils/snackbar_helper.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';
import 'package:pedometer/pedometer.dart';
import 'package:pulsedevice/core/service/gps_distance_tracker.dart';
import '../../../core/app_export.dart';
import '../models/initial_tab_model.dart';
import '../models/k5_model.dart';

/// A controller class for the K5Screen.
///
/// This class manages the state of the K5Screen, including the
/// current k5ModelObj
class K5Controller extends GetxController
    with GetSingleTickerProviderStateMixin, WidgetsBindingObserver {
  Rx<K5Model> k5ModelObj = K5Model().obs;
  final gc = Get.find<GlobalController>();
  late TabController tabviewController;

  /// 0 = 有氧, 1 = 重訓
  Rx<int> tabIndex = 0.obs;

  Rx<InitialTabModel> initialTabModelObj = InitialTabModel().obs;

  /// ✅ 運動事件處理器
  late Function(Map) _sportEventHandler;

  /// 上次運動時長
  RxInt lastHours = 0.obs;
  RxInt lastMinutes = 0.obs;
  RxInt lastSeconds = 0.obs;

  /// 心率、距離、步數的值
  RxInt bpm = 0.obs;
  RxInt distance = 0.obs;
  RxInt steps = 0.obs;
  RxInt calories = 0.obs;

  /// 是否開始運動
  RxBool isStart = false.obs;

  List<SportRecord> records = <SportRecord>[].obs;
  RxInt maxBpm = 0.obs;
  RxInt minBpm = 0.obs;

  /// 快取最後一次 onListening 的即時資料，方便 Resume 時刷新
  Map<String, int> _lastSportCache = {};

  // 🎯 GPS模式相關變數
  final RxBool _isUsingGpsMode = false.obs; // 🔄 改為Rx變量
  GpsDistanceTracker? _gpsTracker;

  // 🚶‍♂️ 計步器相關
  StreamSubscription<StepCount>? _stepCountStream;
  int _initialStepCount = 0;
  int _exerciseSteps = 0;

  // ⏱️ GPS模式時間計算
  DateTime? _gpsStartTime;
  Timer? _gpsTimer;

  // 🔄 設備斷線保障機制
  DateTime? _localStartTime; // 本地計時器開始時間
  Timer? _localTimer; // 本地計時器
  int _localElapsedSeconds = 0; // 本地累計時間
  DateTime? _lastDeviceDataTime; // 最後接收設備數據的時間
  Timer? _disconnectDetectionTimer; // 設備斷線檢測定時器
  bool _deviceDisconnected = false; // 設備是否斷線

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    tabviewController = TabController(vsync: this, length: 2);
    print("初始化監聽藍牙狀態：${gc.blueToolStatus.value}");

    // 📊 記錄運動監測頁面瀏覽事件
    FirebaseAnalyticsService.instance.logViewWorkoutPage();

    // ✅ 初始化運動事件處理器
    _sportEventHandler = _handleSportEvent;

    // ✅ 註冊全局運動事件監聽
    _registerGlobalSportListener();
  }

  // 🎯 提供給UI的getter
  bool get isUsingGpsMode => _isUsingGpsMode.value;

  // 🎯 提供給UI的Rx變量（用於Obx監聽）
  RxBool get isUsingGpsModeRx => _isUsingGpsMode;

  /// 獲取總運動時長（秒）
  int _getTotalSeconds() {
    if (_isUsingGpsMode.value && _gpsStartTime != null) {
      return DateTime.now().difference(_gpsStartTime!).inSeconds;
    }

    // 🔄 如果設備斷線，使用本地計時器時間
    if (_deviceDisconnected && _localStartTime != null) {
      return DateTime.now().difference(_localStartTime!).inSeconds;
    }

    return lastHours.value * 3600 + lastMinutes.value * 60 + lastSeconds.value;
  }

  @override
  void onClose() {
    super.onClose();
    WidgetsBinding.instance.removeObserver(this);

    // ✅ 清理事件處理器
    _unregisterGlobalSportListener();

    // 🎯 清理GPS模式資源
    _cleanupGpsMode();

    // 🔄 清理本地計時器資源
    _cleanupLocalTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // ✅ App 回前景，只刷新資料，監聽器由全局事件系統管理
      /// 若正在運動，把「快取的最後數值」再寫回一次，
      ///    觸發 Rx <=> UI 重新 build
      if (isStart.value && _lastSportCache.isNotEmpty) {
        bpm.value = _lastSportCache['bpm'] ?? bpm.value;
        distance.value = _lastSportCache['distance'] ?? distance.value;
        steps.value = _lastSportCache['steps'] ?? steps.value;
        calories.value = _lastSportCache['cal'] ?? calories.value;

        _updateTimeFields(_lastSportCache['sec'] ?? 0);
      }
    }
  }

  void syncData() async {
    initialTabModelObj.value.listeightysixItemList.value[0].eightysix!.value =
        bpm.value.toString();
    initialTabModelObj.value.listeightysixItemList.value[1].eightysix!.value =
        distance.value.toString();
    initialTabModelObj.value.listeightysixItemList.value[2].eightysix!.value =
        steps.value.toString();

    /// 取得運動資料
    final allRecords = await SportRecordListStorage.getRecords(gc.userId.value);

    // 根據 tabIndex 過濾出對應類型的清單
    List<SportRecord> filtered;
    clearData();
    if (tabIndex.value == 0) {
      filtered = allRecords.where((e) => e.sportType == 'aerobic').toList();
    } else {
      filtered =
          allRecords.where((e) => e.sportType == 'weightTraining').toList();
    }
    if (filtered.isNotEmpty) {
      steps.value = filtered.first.step!;
      bpm.value = filtered.first.bpm!;
      distance.value = filtered.first.distance!;
      lastHours.value = filtered.first.hours!;
      lastMinutes.value = filtered.first.minutes!;
      lastSeconds.value = filtered.first.seconds!;
    }
  }

  /// 註冊全局運動事件監聽
  void _registerGlobalSportListener() {
    print("✅ K5Controller 註冊全局運動事件監聽");
    gc.registerEventHandler(
        NativeEventType.deviceRealSport, _sportEventHandler);
  }

  /// 取消註冊全局運動事件監聽
  void _unregisterGlobalSportListener() {
    print("❌ K5Controller 取消全局運動事件監聽");
    gc.unregisterEventHandler(
        NativeEventType.deviceRealSport, _sportEventHandler);
  }

  /// 處理運動事件
  void _handleSportEvent(Map event) {
    print("=== K5Controller 接收運動事件: $event");

    // ✅ 只有在運動中才處理
    if (!isStart.value) {
      print("⚠️ 運動未開始，忽略運動數據");
      return;
    }

    // 🔄 更新設備數據接收時間
    _lastDeviceDataTime = DateTime.now();

    // 如果之前設備斷線，現在重連了
    if (_deviceDisconnected) {
      _onDeviceReconnected();
    }

    // 取出運動數據
    final Map? sportInfo = event[NativeEventType.deviceRealSport];
    if (sportInfo == null) {
      print("⚠️ 運動數據為空");
      return;
    }

    // 🔄 處理設備時間（優先使用設備時間）
    int? deviceTime = int.tryParse(sportInfo["time"].toString());
    if (deviceTime != null && deviceTime > 0) {
      _updateTimeFields(deviceTime);
      print("📱 使用設備時間: $deviceTime 秒");
    }

    // 處理其他運動數據
    bpm.value = int.tryParse(sportInfo["heartRate"].toString()) ?? 0;
    distance.value = int.tryParse(sportInfo["distance"].toString()) ?? 0;
    steps.value = int.tryParse(sportInfo["step"].toString()) ?? 0;
    calories.value = int.tryParse(sportInfo["calories"].toString()) ?? 0;

    _lastSportCache = {
      'sec': deviceTime ?? _localElapsedSeconds,
      'bpm': bpm.value,
      'distance': distance.value,
      'steps': steps.value,
      'cal': calories.value,
    };

    final model =
        SportRecord(sportType: '', time: DateTime.now(), bpm: bpm.value);
    records.add(model);
  }

  /// 運動頁首次開啟時，主動呼叫 startPage()
  void startPage() {
    syncData();
    // ✅ 監聽器已在 onInit 時通過全局事件系統註冊，不需要重複註冊
    print("✅ 運動頁面載入完成，全局監聽器已就緒");
  }

  void switchMode(int idx) {
    if (isStart.value) {
      if (tabviewController.index != tabIndex.value) {
        tabviewController.animateTo(tabIndex.value);
      }
      return;
    }
    tabIndex.value = idx;
    syncData();
  }

  /// 收到 SDK 給的 totalSeconds 之後，把它拆成時/分/秒並更新 Rx
  void _updateTimeFields(int totalSeconds) {
    // 算出小時、分鐘與秒
    final h = totalSeconds ~/ 3600; // 整除 3600，拿到小時
    final m = (totalSeconds % 3600) ~/ 60; // 先對 3600 取餘再整除 60，拿到分鐘
    final s = totalSeconds % 60; // 取 60 的餘數，拿到秒

    // 更新 Rx
    lastHours.value = h;
    lastMinutes.value = m;
    lastSeconds.value = s;
  }

  void clearData() {
    distance.value = 0;
    steps.value = 0;
    lastHours.value = 0;
    lastMinutes.value = 0;
    lastSeconds.value = 0;

    // 🎯 根據模式設置心率和卡路里
    if (_isUsingGpsMode.value) {
      bpm.value = 0; // GPS模式：心率顯示"---"
      calories.value = 0; // GPS模式：卡路里顯示"---"

      // 重置GPS模式的內部變數
      _initialStepCount = 0;
      _exerciseSteps = 0;
    } else {
      bpm.value = 0; // 設備模式：等待設備數據
      calories.value = 0; // 設備模式：等待設備數據
    }
  }

  // ======================================================
  // 🎯 GPS模式相關方法
  // ======================================================

  /// 清理GPS模式資源
  void _cleanupGpsMode() {
    _gpsTracker?.stopTracking();
    _gpsTracker = null;
    _stepCountStream?.cancel();
    _stepCountStream = null;
    _gpsTimer?.cancel();
    _gpsTimer = null;
    _gpsStartTime = null;
  }

  /// 啟動GPS模式
  Future<void> _startGpsMode() async {
    try {
      print("🗺️ 啟動GPS運動模式");

      // 🗺️ 啟動GPS距離追蹤（核心功能，必須成功）
      _gpsTracker = GpsDistanceTracker();
      _gpsTracker!.setDistanceCallback((distanceInMeters) {
        distance.value = distanceInMeters;
      });
      await _gpsTracker!.startTracking();
      print('✅ GPS距離追蹤啟動成功');

      // 🚶‍♂️ 嘗試啟動計步器（非核心功能，允許失敗）
      try {
        await _startStepCounter();
      } catch (e) {
        print('⚠️ 計步器啟動失敗，但GPS模式繼續運行: $e');
        // 計步器失敗不影響GPS模式
      }

      // ⏱️ 啟動時間計算
      _startGpsTimeCounter();

      // 🎯 設置GPS模式的固定值
      bpm.value = 0; // 心率顯示 "---"
      calories.value = 0; // 卡路里顯示 "---"

      print('🎯 GPS模式啟動成功（GPS距離 + 時間計算 + 計步器嘗試）');
    } catch (e) {
      print('❌ GPS模式啟動失敗: $e');
      if (e.toString().contains('定位')) {
        SnackbarHelper.showBlueSnackbar(message: "GPS定位失敗，請檢查定位權限並移動到開放區域");
      } else {
        SnackbarHelper.showBlueSnackbar(message: "GPS運動模式啟動失敗，請稍後再試");
      }
      rethrow;
    }
  }

  /// 啟動設備模式（原有邏輯）
  Future<void> _startDeviceMode() async {
    print("🔵 啟動設備運動模式");
    gc.isSporting.value = true;
    gc.pauseBackgroundSync();

    final res = await YcProductPlugin()
        .appControlSport(DeviceSportState.start, DeviceSportType.fitness);

    if (res == null || res.statusCode != PluginState.succeed) {
      throw Exception("無法啟動運動，請稍後再試");
    }
  }

  /// 開始計步器
  Future<void> _startStepCounter() async {
    try {
      // 🔍 首先檢查計步器是否可用
      print('🔍 檢查計步器支持狀態...');

      // 🔑 Android需要運動感測器權限，iOS自動獲得
      if (GetPlatform.isAndroid) {
        print('🤖 Android平台，計步器權限將自動請求');
      }

      // 🎯 監聽計步器
      _stepCountStream = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
      );

      print('🚶‍♂️ 計步器啟動成功');
    } catch (e) {
      print('❌ 計步器啟動失敗: $e');
      _handleStepCounterFailure(e);
    }
  }

  /// 處理計步器失敗情況
  void _handleStepCounterFailure(dynamic error) {
    String errorMsg = error.toString();

    if (errorMsg.contains('Step Count is not available')) {
      print('📱 設備不支持計步器功能（可能是模擬器或舊設備）');
      print('💡 GPS運動模式將繼續運行，步數顯示為0');
    } else if (errorMsg.contains('permission')) {
      print('📱 計步器權限被拒絕，步數將顯示為0');
    } else if (errorMsg.contains('PlatformException')) {
      print('📱 計步器平台異常，可能設備不支持或服務未啟用');
    } else {
      print('📱 計步器未知錯誤: $errorMsg');
    }

    // 🎯 設置固定步數為0，確保GPS運動正常進行
    steps.value = 0;
    _exerciseSteps = 0;
    _initialStepCount = 0;
  }

  /// 計步器數據回調
  void _onStepCount(StepCount event) {
    if (_initialStepCount == 0) {
      // 記錄運動開始時的步數
      _initialStepCount = event.steps;
      _exerciseSteps = 0;
    } else {
      // 計算運動期間的步數
      _exerciseSteps = event.steps - _initialStepCount;
      if (_exerciseSteps < 0) _exerciseSteps = 0; // 防止負數
    }

    // 🎯 更新UI顯示
    steps.value = _exerciseSteps;
    print('📊 運動步數更新: ${_exerciseSteps}步');
  }

  /// 計步器錯誤處理
  void _onStepCountError(error) {
    print('❌ 計步器運行時錯誤: $error');
    _handleStepCounterFailure(error);
  }

  /// 開始GPS模式的時間計算
  void _startGpsTimeCounter() {
    _gpsStartTime = DateTime.now();

    // 每秒更新一次時間顯示
    _gpsTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (isStart.value && _gpsStartTime != null) {
        final elapsed = DateTime.now().difference(_gpsStartTime!);
        final totalSeconds = elapsed.inSeconds;

        // 🎯 更新時間顯示
        _updateTimeFields(totalSeconds);
      }
    });

    print('⏱️ GPS時間計算器已啟動');
  }

  // ======================================================
  // 🔄 設備斷線保障機制
  // ======================================================

  /// 啟動本地計時器（作為設備時間的備用）
  void _startLocalTimer() {
    _localStartTime = DateTime.now();
    _localElapsedSeconds = 0;

    _localTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (isStart.value && _localStartTime != null) {
        _localElapsedSeconds =
            DateTime.now().difference(_localStartTime!).inSeconds;

        // 只有在設備斷線時才使用本地時間更新UI
        if (_deviceDisconnected) {
          _updateTimeFields(_localElapsedSeconds);
          print("🔄 使用本地時間: $_localElapsedSeconds 秒");
        }
      }
    });

    print('⏱️ 本地計時器已啟動');
  }

  /// 啟動設備斷線檢測
  void _startDisconnectDetection() {
    _disconnectDetectionTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (isStart.value && _lastDeviceDataTime != null) {
        final timeSinceLastData =
            DateTime.now().difference(_lastDeviceDataTime!);

        // 如果超過5秒沒有收到設備數據，認為設備斷線
        if (timeSinceLastData.inSeconds > 5) {
          if (!_deviceDisconnected) {
            print("⚠️ 檢測到設備斷線，切換到本地時間");
            _onDeviceDisconnected();
          }
        } else {
          // 設備數據正常，如果之前斷線則恢復
          if (_deviceDisconnected) {
            print("✅ 設備數據恢復正常");
            _onDeviceReconnected();
          }
        }
      }
    });

    print('🔍 設備斷線檢測已啟動');
  }

  /// 設備斷線處理
  void _onDeviceDisconnected() {
    _deviceDisconnected = true;
    print("🔄 設備斷線，切換到本地時間繼續計算");
  }

  /// 設備重連處理
  void _onDeviceReconnected() {
    _deviceDisconnected = false;
    print("✅ 設備重連，繼續使用本地時間（避免時間跳躍）");
  }

  /// 清理本地計時器相關資源
  void _cleanupLocalTimer() {
    _localTimer?.cancel();
    _localTimer = null;
    _disconnectDetectionTimer?.cancel();
    _disconnectDetectionTimer = null;
    _localStartTime = null;
    _localElapsedSeconds = 0;
    _lastDeviceDataTime = null;
    _deviceDisconnected = false;
    print('🧹 本地計時器資源已清理');
  }

  /// 把最後一次「運動資料」寫到 Hive
  void _saveExerciseRecordToHive() async {
    final b = bpm.value;
    final d = distance.value;
    final s = steps.value;
    final c = calories.value;
    final h = lastHours.value;
    final m = lastMinutes.value;
    final se = lastSeconds.value;
    var avgBpm = 0;
    var maxBpm = 0;
    var minBpm = 0;
    var sportType = 'aerobic';
    if (tabIndex.value == 0) {
      sportType = 'aerobic';
    } else {
      sportType = 'weightTraining';
    }
    final validBpmRecords = records.where((r) => (r.bpm ?? 0) > 0).toList();
    if (validBpmRecords.isNotEmpty) {
      final bpmValues = validBpmRecords.map((r) => r.bpm!).toList();

      avgBpm = (bpmValues.reduce((a, b) => a + b) / bpmValues.length).toInt();
      maxBpm = bpmValues.reduce((a, b) => a > b ? a : b);
      minBpm = bpmValues.reduce((a, b) => a < b ? a : b);

      print("平均心率: $avgBpm");
      print("最高心率: $maxBpm");
      print("最低心率: $minBpm");
    }

    var record = SportRecord(
      sportType: sportType,
      time: DateTime.now(),
      bpm: b,
      distance: d,
      step: s,
      calories: c,
      hours: h,
      minutes: m,
      seconds: se,
      avgBpm: avgBpm,
      maxBpm: maxBpm,
      minBpm: minBpm,
    );

    print(
        "新增運動紀錄 => 模式: ${_isUsingGpsMode.value ? 'GPS' : '設備'}, 步數: $s, 心率: $b, 距離: $d, 卡路里: $c, 時間: $h:$m:$se");
    records.clear();
    await SportRecordListStorage.addRecords(gc.userId.value, [record]);
    print("新增運動紀錄成功");

    String message = _isUsingGpsMode.value ? "結束GPS運動，已儲存本次記錄" : "結束運動，已儲存本次記錄";
    SnackbarHelper.showBlueSnackbar(message: message);

    /// 結束運動後，重新打開同步定時器（僅設備模式需要）
    if (!_isUsingGpsMode.value) {
      gc.resumeBackgroundSync();
    }
  }

  void goK6Screen(int index) {
    // stopSport();
    Get.toNamed(AppRoutes.k6Screen, arguments: index);
  }

  Future<void> startSport() async {
    if (isStart.value) return;

    // 📊 記錄開始運動按鈕點擊事件
    FirebaseAnalyticsService.instance.logClickStartWorkout(
      workoutType: 'exercise',
    );

    // 🔍 檢查藍牙狀態決定使用哪種模式
    _isUsingGpsMode.value = (gc.blueToolStatus.value != 2);

    try {
      isStart.value = true;
      gc.isSporting.value = true;
      clearData(); // 先把畫面上的上次資料歸零

      // 🔄 無論哪種模式都啟動本地計時器和斷線檢測
      _startLocalTimer();
      _startDisconnectDetection();

      if (_isUsingGpsMode.value) {
        // 📍 GPS模式：藍牙設備未連接
        print("🗺️ 藍牙設備未連接，使用GPS運動模式");
        await _startGpsMode();
      } else {
        // 🔵 設備模式：藍牙設備已連接
        print("🔵 藍牙設備已連接，使用設備運動模式");
        await _startDeviceMode();
      }

      print("✅ 運動開始，模式: ${_isUsingGpsMode.value ? 'GPS' : '設備'}，本地計時器已啟動");
    } catch (e) {
      // 啟動失敗，重置狀態
      isStart.value = false;
      _isUsingGpsMode.value = false;
      _cleanupLocalTimer(); // 清理本地計時器
      print("❌ 運動啟動失敗: $e");

      if (e.toString().contains('定位')) {
        SnackbarHelper.showBlueSnackbar(message: "GPS定位失敗，請檢查定位權限並移動到開放區域");
      } else {
        SnackbarHelper.showBlueSnackbar(message: "無法啟動運動，請稍後再試");
      }
    }
  }

  Future<void> stopSport() async {
    try {
      if (!isStart.value) return;

      // 📊 記錄結束運動按鈕點擊事件
      FirebaseAnalyticsService.instance.logClickEndWorkout(
        workoutType: 'exercise',
        duration: _getTotalSeconds(),
      );

      isStart.value = false;
      gc.isSporting.value = false;

      // 🔄 清理本地計時器資源
      _cleanupLocalTimer();

      if (_isUsingGpsMode.value) {
        // 🗺️ GPS模式停止
        print("🛑 停止GPS運動模式");

        // 獲取最終時間數據
        final totalSeconds = _gpsStartTime != null
            ? DateTime.now().difference(_gpsStartTime!).inSeconds
            : 0;

        // 清理GPS模式資源
        _cleanupGpsMode();

        print(
            '📊 GPS運動結束 - 距離: ${distance.value}m, 步數: ${steps.value}步, 時間: ${totalSeconds}秒');
      } else {
        // 🔵 設備模式停止（原有邏輯）
        print("🛑 停止設備運動模式");
        gc.isSporting.value = false;

        YcProductPlugin()
            .appControlSport(DeviceSportState.stop, DeviceSportType.fitness)
            .timeout(const Duration(seconds: 5), onTimeout: () {
          print("[TIMEOUT] stopSport() 超時，繼續往下執行");
          return;
        });
      }
    } catch (e) {
      print("[ERROR] stopSport() 發生例外：$e");
    }

    // 重置模式標記
    _isUsingGpsMode.value = false;

    _saveExerciseRecordToHive();
  }
}
