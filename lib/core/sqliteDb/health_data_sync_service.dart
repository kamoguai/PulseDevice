// services/health_data_sync_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:pulsedevice/core/app_export.dart';
import 'package:pulsedevice/core/hiveDb/alert_record.dart';
import 'package:pulsedevice/core/hiveDb/alert_record_list_storage.dart';
import 'package:pulsedevice/core/hiveDb/blood_oxygen_setting_storage.dart';
import 'package:pulsedevice/core/hiveDb/body_temperature_setting_storage.dart';
import 'package:pulsedevice/core/hiveDb/heart_rate_setting_storage.dart';
import 'package:pulsedevice/core/hiveDb/pressure_setting.dart';
import 'package:pulsedevice/core/hiveDb/pressure_setting_storage.dart';
import 'package:pulsedevice/core/network/api_service.dart';
import 'package:pulsedevice/core/service/yc_service.dart';
import 'package:pulsedevice/core/sqliteDb/blood_pressure_data_service.dart';
import 'package:pulsedevice/core/sqliteDb/combined_data_service.dart';
import 'package:pulsedevice/core/sqliteDb/heart_rate_data_service.dart';
import 'package:pulsedevice/core/sqliteDb/invasive_comprehensive_data_service.dart';
import 'package:pulsedevice/core/sqliteDb/pressure_data_service.dart';
import 'package:pulsedevice/core/sqliteDb/sleep_data_service.dart';
import 'package:pulsedevice/core/sqliteDb/step_data_service.dart';
import 'package:pulsedevice/core/utils/date_time_utils.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';
import 'package:pulsedevice/core/sqliteDb/app_database.dart';

class HealthDataSyncService {
  final AppDatabase _db;

  String? _userId;

  String? get userId => _userId;
  void setUserId(String id) => _userId = id;

  ApiService apiService = ApiService();

  HealthDataSyncService(
    this._db,
  );
  AppDatabase getInstance() {
    return _db;
  }

  List<int> healthDataTypes = [
    HealthDataType.step,
    HealthDataType.sleep,
    HealthDataType.heartRate,
    HealthDataType.bloodPressure,
    HealthDataType.combinedData,
    HealthDataType.invasiveComprehensiveData
  ];

  ///------ 同步裝置健康數據到db ------
  Future<void> fetchAndStoreData() async {
    final ycDeviceService = YcDeviceService.instance;
    if (_userId == null) {
      print('❌ 無 userId，取消同步');
      return;
    }
    try {
      for (final dataType in healthDataTypes) {
        final result = await ycDeviceService.queryDeviceHealthData(dataType);
        final list = result ?? [];
        if (list.isNotEmpty) {
          switch (dataType) {
            case HealthDataType.step:
              final stepService = StepDataService(_db);
              if (list.last is StepDataInfo) {
                final sdkList = list.cast<StepDataInfo>();
                final listJson = sdkList
                    .map((e) => parseSdkDataString(e.toString()))
                    .toList();
                final wrapperdJson = {
                  "步數數據": listJson,
                };
                String jsonStr = jsonEncode(wrapperdJson);

                printLongText("步數數據：$jsonStr");
                await stepService.syncStepData(
                    userId: _userId!, sdkData: sdkList);
                print("步數數據寫入成功");
                //// 寫入成功後刪除戒指數據
                await deleteDeviceData(HealthDataType.step);
              }
              break;
            case HealthDataType.sleep:
              final sleepService = SleepDataService(_db);
              if (list.last is SleepDataInfo) {
                final sdkList = list.cast<SleepDataInfo>();
                final listJson = sdkList
                    .map((e) => parseSdkDataString(e.toString()))
                    .toList();
                final wrapperdJson = {
                  "睡眠數據": listJson,
                };

                String jsonStr = jsonEncode(wrapperdJson);

                printLongText("睡眠數據：$jsonStr");
                await sleepService.syncSleepData(
                    userId: _userId!, sdkData: sdkList);

                print("睡眠數據寫入成功");
                //// 寫入成功後刪除戒指數據
                await deleteDeviceData(HealthDataType.sleep);
              }

              break;
            case HealthDataType.heartRate:
              final heartRateService = HeartRateDataService(_db);
              if (list.last is HeartRateDataInfo) {
                final sdkList = list.cast<HeartRateDataInfo>();
                final listJson = sdkList
                    .map((e) => parseSdkDataString(e.toString()))
                    .toList();
                final wrapperdJson = {
                  "心率數據": listJson,
                };

                String jsonStr = jsonEncode(wrapperdJson);

                printLongText("心率數據：$jsonStr");
                await heartRateService.syncHeartRateData(
                    userId: _userId!,
                    sdkData:
                        sdkList); // await heartRateService.insertHeartRateDataIfNotExists(companion);
                print("心率數據寫入成功");
                //// 寫入成功後刪除戒指數據
                await deleteDeviceData(HealthDataType.heartRate);
              }

              break;
            case HealthDataType.bloodPressure:
              final bloodPressureService = BloodPressureDataService(_db);
              if (list.last is BloodPressureDataInfo) {
                final sdkList = list.cast<BloodPressureDataInfo>();
                final listJson = sdkList
                    .map((e) => parseSdkDataString(e.toString()))
                    .toList();
                final wrapperdJson = {
                  "血壓數據": listJson,
                };

                String jsonStr = jsonEncode(wrapperdJson);

                printLongText("血壓數據：$jsonStr");
                await bloodPressureService.syncBloodPressureData(
                    userId: _userId!,
                    sdkData:
                        sdkList); // await bloodPressureService.insertBloodPressureDataIfNotExists(companion);
                print("血壓數據寫入成功");
                //// 寫入成功後刪除戒指數據
                await deleteDeviceData(HealthDataType.bloodPressure);
              }

              break;
            case HealthDataType.combinedData:
              final combinedDataService = CombinedDataService(_db);
              if (list.last is CombinedDataDataInfo) {
                final sdkList = list.cast<CombinedDataDataInfo>();
                final listJson = sdkList
                    .map((e) => parseSdkDataString(e.toString()))
                    .toList();
                final wrapperdJson = {
                  "合併數據": listJson,
                };

                String jsonStr = jsonEncode(wrapperdJson);

                printLongText("合併數據：$jsonStr");
                await combinedDataService.syncCombinedData(
                    userId: _userId!,
                    sdkData:
                        sdkList); // await combinedDataService.insertCombinedDataIfNotExists(companion);
                print("合併數據寫入成功");
                //// 寫入成功後刪除戒指數據
                await deleteDeviceData(HealthDataType.combinedData);
              }

              break;
            case HealthDataType.invasiveComprehensiveData:
              final invasiveComprehensiveDataService =
                  InvasiveComprehensiveDataService(_db);
              if (list.last is InvasiveComprehensiveDataInfo) {
                final sdkList = list.cast<InvasiveComprehensiveDataInfo>();
                print("入侵綜合數據：$sdkList");
                await invasiveComprehensiveDataService
                    .syncInvasiveComprehensiveData(
                        userId: _userId!,
                        sdkData:
                            sdkList); // await invasiveComprehensiveDataService.insertInvasiveComprehensiveDataIfNotExists(companion);
                print("入侵綜合數據寫入成功");
              }
              break;
          }
        }
      }
    } catch (e) {
      // 錯誤處理，例如記錄日誌
      print('資料同步錯誤: $e');
    }
  }

  /// 同步健康數據到告警
  Future<void> syncHealthData() async {
    final heartService = HeartRateDataService(_db);
    final combinedService = CombinedDataService(_db);

    final heartSettings =
        await HeartRateSettingStorage.getUserProfile(_userId!);
    final bloodSettings =
        await BloodOxygenSettingStorage.getUserProfile(_userId!);
    final tempSettings =
        await BodyTemperatureSettingStorage.getUserProfile(_userId!);
    final pressureSettings =
        await PressureSettingStorage.getUserProfile(_userId!);
    final heartList = await heartService.getByUser(_userId!);
    final combinedList = await combinedService.getByUser(_userId!);
    List<AlertRecord> alertList = [];
    if (heartSettings?.alertEnabled == true) {
      // ✅ 心率資料
      for (var dic in heartList) {
        final dt =
            DateTime.fromMillisecondsSinceEpoch(dic.startTimeStamp * 1000);
        if (dic.heartRate > heartSettings!.highThreshold) {
          alertList.add(AlertRecord(
            label: 'lbl155'.tr,
            type: 'heart_rate_high',
            time: dt,
            value: heartSettings.highThreshold.toString(),
            unit: 'lbl161'.tr,
            synced: false,
          ));
        } else if (dic.heartRate < heartSettings.lowThreshold) {
          alertList.add(AlertRecord(
            label: 'lbl155_1'.tr,
            type: 'heart_rate_low',
            time: dt,
            value: heartSettings.lowThreshold.toString(),
            unit: 'lbl161'.tr,
            synced: false,
          ));
        }
      }
    }

    if (bloodSettings?.alertEnabled == true) {
      // ✅ 血氧資料
      for (var dic in combinedList) {
        if (dic.bloodOxygen < bloodSettings!.lowThreshold) {
          alertList.add(AlertRecord(
            label: 'lbl156'.tr,
            type: 'blood_oxygen_low',
            time:
                DateTime.fromMillisecondsSinceEpoch(dic.startTimeStamp * 1000),
            value: bloodSettings.lowThreshold.toString(),
            unit: '%',
            synced: false,
          ));
        }
      }
    }

    if (tempSettings?.alertEnabled == true) {
      // ✅ 體溫資料
      for (var dic in combinedList) {
        final dt =
            DateTime.fromMillisecondsSinceEpoch(dic.startTimeStamp * 1000);
        if (dic.temperature > double.parse(tempSettings!.highThreshold)) {
          alertList.add(AlertRecord(
            label: 'lbl1841_1'.tr,
            type: 'temperature_high',
            time: dt,
            value: double.parse(tempSettings.highThreshold).toString(),
            unit: 'lbl_c'.tr,
            synced: false,
          ));
        } else if (dic.temperature < double.parse(tempSettings.lowThreshold)) {
          alertList.add(AlertRecord(
            label: 'lbl185_1'.tr,
            type: 'temperature_low',
            time: dt,
            value: double.parse(tempSettings.lowThreshold).toString(),
            unit: 'lbl_c'.tr,
            synced: false,
          ));
        }
      }
    }

    if (pressureSettings?.alertEnabled == true) {
      final pressureList = await PressureDataService(_db).getByUser(_userId!);
      for (var dic in pressureList) {
        final dt =
            DateTime.fromMillisecondsSinceEpoch(dic.startTimeStamp * 1000);
        if (dic.totalStressScore > pressureSettings!.highThreshold) {
          alertList.add(AlertRecord(
            label: 'lbl217_1'.tr,
            type: 'pressure_high',
            time: dt,
            value: dic.totalStressScore.toString(),
            unit: '',
            synced: false,
          ));
        }
      }
    }

    if (alertList.isEmpty) return;

    await AlertRecordListStorage.addRecords(_userId!, alertList);
  }

  Future<Map<String, dynamic>> getAnalysisHealthData() async {
    final stepService = StepDataService(_db);
    final sleepService = SleepDataService(_db);
    final heartService = HeartRateDataService(_db);
    final combinedService = CombinedDataService(_db);
    if (_userId == null) {
      _userId = await PrefUtils().getUserId();
    }
    final stepList = await stepService.getStepDataByUser(_userId!);
    final sleepList = await sleepService.getSleepDataByUser(_userId!);
    final heartList = await heartService.getByUser(_userId!);
    final combinedList = await combinedService.getByUser(_userId!);
    if (heartList.isEmpty ||
        stepList.isEmpty ||
        combinedList.isEmpty ||
        sleepList.isEmpty) return {};

    stepList.sort((a, b) => a.startTimeStamp.compareTo(b.startTimeStamp));
    heartList.sort((a, b) => a.startTimeStamp.compareTo(b.startTimeStamp));
    combinedList.sort((a, b) => a.startTimeStamp.compareTo(b.startTimeStamp));

    final stepLast = stepList.last;
    final heartLast = heartList.last;
    final combinedLast = combinedList.last;
    int stepCount = sumLastDayValues<StepDataData>(
        list: stepList,
        startTimeGetter: (e) => e.startTimeStamp,
        valueGetter: (e) => e.step);
    int stepDistance = sumLastDayValues<StepDataData>(
        list: stepList,
        startTimeGetter: (e) => e.startTimeStamp,
        valueGetter: (e) => e.distance);
    final calories = sumLastDayValues<StepDataData>(
        list: stepList,
        startTimeGetter: (e) => e.startTimeStamp,
        valueGetter: (e) => e.calories);
    String stepDuration =
        DateTimeUtils.getTimeDifferenceString(stepLast.endTimeStamp);
    final heartRate = heartLast.heartRate;
    String heartDuration =
        DateTimeUtils.getTimeDifferenceString(heartLast.startTimeStamp);
    String combinedDuration =
        DateTimeUtils.getTimeDifferenceString(combinedLast.startTimeStamp);
    final bloodOxygen = combinedLast.bloodOxygen;
    final t = combinedLast.temperature;
    var temperature = t;

    final loadDataTime = DateTimeUtils.formatMaxTimestamp(
        stepLast.startTimeStamp,
        heartLast.startTimeStamp,
        combinedLast.startTimeStamp);

    ///-----
    final heartSettings =
        await HeartRateSettingStorage.getUserProfile(_userId!);
    final bloodSettings =
        await BloodOxygenSettingStorage.getUserProfile(userId!);
    final tempSettings =
        await BodyTemperatureSettingStorage.getUserProfile(userId!);
    var heartAlert = false;
    var bloodAlert = false;
    var tempAlert = false;
    if (heartRate <= heartSettings!.lowThreshold ||
        heartRate >= heartSettings.highThreshold) {
      heartAlert = true;
    }
    if (bloodOxygen <= bloodSettings!.lowThreshold) {
      bloodAlert = true;
    }
    if (temperature <= double.parse(tempSettings!.lowThreshold) ||
        temperature >= double.parse(tempSettings!.highThreshold)) {
      tempAlert = true;
    }

    ///------
    var analysis = {
      "stepCount": stepCount,
      "stepDistance": stepDistance,
      "stepDuration": stepDuration,
      "calories": calories,
      "heartRate": heartRate,
      "heartDuration": heartDuration,
      "heartAlert": heartAlert,
      "bloodOxygen": bloodOxygen,
      "bloodAlert": bloodAlert,
      "combinedDuration": combinedDuration,
      "temperature": temperature,
      "tempAlert": tempAlert,
      "loadDataTime": loadDataTime
    };

    if (sleepList.isNotEmpty) {
      sleepList.sort((a, b) => a.startTimeStamp.compareTo(b.startTimeStamp));

      final sleepLast = sleepList.last;
      final sleepTotalSecond = calculateLastDayTotalSeconds<SleepDataData>(
          list: sleepList,
          startTimeGetter: (e) => e.startTimeStamp,
          endTimeGetter: (e) => e.endTimeStamp);
      final sleepTime = (sleepTotalSecond / 3600).toStringAsFixed(1);
      String sleepDuration =
          DateTimeUtils.getTimeDifferenceString(sleepLast.endTimeStamp);

      analysis.addAll({
        "sleepTime": sleepTime,
        "sleepDuration": sleepDuration,
      });
    }
    return analysis;
  }

  Future<void> deleteDeviceData(int type) async {
    final ycDeviceService = YcDeviceService.instance;
    final res = await ycDeviceService.deleteDeviceHealthData(type);
    if (res) {
      printLongText("刪除健康數據成功");
    }
  }

  void printLongText(String text) {
    const int chunkSize = 800;
    for (var i = 0; i < text.length; i += chunkSize) {
      final chunk = text.substring(
          i, i + chunkSize > text.length ? text.length : i + chunkSize);
      print(chunk);
    }
  }

  Map<String, dynamic> parseSdkDataString(String str) {
    final isCommaSeparated = str.contains(',');

    // 根據格式選擇分隔字串
    final segments = isCommaSeparated
        ? str.replaceAll('\n', '').replaceAll(']', '').trim().split(',')
        : str.trim().split('\n');

    final map = <String, dynamic>{};

    for (var segment in segments) {
      final normalized = segment.replaceAll('=', ':'); // 支援 = 和 : 分隔
      final kv = normalized.split(':');

      if (kv.length >= 2) {
        final key = kv[0].trim();
        final value = kv.sublist(1).join(':').trim();

        if (key == 'startTimeStamp' || key == 'endTimeStamp') {
          final ts = int.tryParse(value);
          if (ts != null) {
            final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
            map[key] = dt.format(pattern: 'yyyy-MM-dd HH:mm:ss');
          } else {
            map[key] = value;
          }
        } else {
          map[key] = value;
        }
      }
    }

    return map;
  }

  int calculateLastDayTotalSeconds<T>({
    required List<T> list,
    required int Function(T item) startTimeGetter,
    required int Function(T item) endTimeGetter,
  }) {
    if (list.isEmpty) return 0;

    // 1. 排序
    list.sort((a, b) => startTimeGetter(a).compareTo(startTimeGetter(b)));

    // 2. 取得最後一筆的 yyyy-MM-dd 字串
    final lastDate =
        DateTime.fromMillisecondsSinceEpoch(startTimeGetter(list.last) * 1000)
            .toIso8601String()
            .substring(0, 10); // yyyy-MM-dd

    // 3. 過濾出當日資料
    final sameDayList = list.where((e) {
      final date =
          DateTime.fromMillisecondsSinceEpoch(startTimeGetter(e) * 1000)
              .toIso8601String()
              .substring(0, 10);
      return date == lastDate;
    });

    // 4. 加總秒數
    final totalSeconds = sameDayList.fold<int>(
      0,
      (sum, item) => sum + (endTimeGetter(item) - startTimeGetter(item)),
    );

    return totalSeconds;
  }

  int sumLastDayValues<T>({
    required List<T> list,
    required int Function(T item) startTimeGetter,
    required int Function(T item) valueGetter,
  }) {
    if (list.isEmpty) return 0;

    // 1. 排序
    list.sort((a, b) => startTimeGetter(a).compareTo(startTimeGetter(b)));

    // 2. 取得最後一天日期（yyyy-MM-dd）
    final lastDate =
        DateTime.fromMillisecondsSinceEpoch(startTimeGetter(list.last) * 1000)
            .toIso8601String()
            .substring(0, 10);

    // 3. 過濾出同一天資料
    final sameDayList = list.where((e) {
      final dateStr =
          DateTime.fromMillisecondsSinceEpoch(startTimeGetter(e) * 1000)
              .toIso8601String()
              .substring(0, 10);
      return dateStr == lastDate;
    });

    // 4. 加總該欄位
    return sameDayList.fold<int>(0, (sum, item) => sum + valueGetter(item));
  }
}
