import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pulsedevice/core/global_controller.dart';
import 'package:pulsedevice/core/network/api.dart';
import 'package:pulsedevice/core/network/api_service.dart';
import 'package:pulsedevice/core/service/firebase_analytics_service.dart';
import 'package:pulsedevice/core/sqliteDb/app_database.dart';
import 'package:pulsedevice/core/utils/date_time_utils.dart';
import 'package:pulsedevice/core/utils/loading_helper.dart';
import 'package:pulsedevice/presentation/k73_screen/models/k73_model.dart';
import 'package:pulsedevice/presentation/k82_page/models/k82_model.dart';
import 'package:pulsedevice/presentation/k82_page/models/list_item_model.dart';
import 'package:pulsedevice/presentation/k87_bottomsheet/controller/k87_controller.dart';
import 'package:pulsedevice/presentation/k87_bottomsheet/k87_bottomsheet.dart';
import 'package:pulsedevice/presentation/k88_bottomsheet/controller/k88_controller.dart';
import 'package:pulsedevice/presentation/k88_bottomsheet/k88_bottomsheet.dart';
import 'package:pulsedevice/presentation/one7_bottomsheet/controller/one7_controller.dart';
import 'package:pulsedevice/presentation/one7_bottomsheet/one7_bottomsheet.dart';
import 'package:pulsedevice/widgets/sleep_bar_chart.dart';

class K82Controller extends GetxController with WidgetsBindingObserver {
  final gc = Get.find<GlobalController>();
  final k82ModelObj = K82Model().obs;
  ApiService apiService = ApiService();
  final userId = ''.obs;
  RxInt currentIndex = 0.obs; // 預設日
  RxInt recordIndex = 0.obs; // 預設報警記錄
  RxString formattedRange = ''.obs;
  List<String> timeTabs = ['lbl229'.tr, 'lbl230'.tr, 'lbl231'.tr];
  List<String> recordTabs = ['lbl238'.tr, 'lbl239'.tr];
  Rx<DateTime> currentDate = DateTime.now().obs;
  final isAlert = false.obs;
  final sleepVal = ''.obs;
  final loadDataTime = ''.obs;
  final deep = ''.obs;
  final light = ''.obs;
  final rem = ''.obs;
  final awake = ''.obs;
  final deepCount = 0.obs;
  final lightCount = 0.obs;
  final remCount = 0.obs;
  final awakeCount = 0.obs;
  final segmentStartText = ''.obs;
  final segmentEndText = ''.obs;
  final sleepSegments = <SleepSegment>[].obs;
  final sleepData = <SleepDataData>[].obs;
  final sleepApiData = <SleepData>[].obs;
  final sleepApiDetailData = <SleepDetailData>[].obs;

  // 模擬資料
  final List<FlSpot> weeklyData = [
    FlSpot(0, 0),
  ].obs;

  final List<FlSpot> monthlyData = [
    FlSpot(0, 0),
  ].obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LoadingHelper.show();

      /// 修正：預設顯示昨日
      if (currentIndex.value == 0) {
        final today = DateTime.now();
        final yestoday = today.subtract(Duration(days: 1));
        currentDate.value = yestoday;
      }
      // 修正：預設顯示當前日期所在週的週一
      if (currentIndex.value == 1) {
        final today = DateTime.now();
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        currentDate.value = weekStart;
      }

      updateDateRange(currentIndex.value);
      LoadingHelper.hide();

      // 📊 GA4 事件已由 K76Controller 統一管理，此處不再自動記錄
      // _logPageViewEvent();
    });
  }

  @override
  void onClose() {
    super.onClose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      updateDateRange(currentIndex.value);
    }
  }

  /// 輸入日期讀取數據
  Future<void> loadDataByDate(DateTime date, {bool isLoading = true}) async {
    userId.value = gc.userId.value;
    final range = DateTimeUtils.getRangeByIndex(date, currentIndex.value);
    final start = range['start']!;
    final end = range['end']!;

    try {
      if (isLoading) {
        LoadingHelper.show();
      }
      final payload = {
        "startTime": start.format(pattern: 'yyyy-MM-dd'),
        "endTime": end.format(pattern: 'yyyy-MM-dd'),
        "userID":
            gc.familyId.value.isEmpty ? gc.apiId.value : gc.familyId.value,
        "type": "sleep"
      };
      final res = await apiService.postJson(Api.healthRecordList, payload);
      final details = await apiService.postJson(Api.seleepGet, payload);
      if (isLoading) {
        LoadingHelper.hide();
      }

      ///如果detail response為空,則用原本的api數據
      if (res.isNotEmpty && res["message"] == "SUCCESS") {
        final data = res["data"];
        if (data == null || data["rateData"] is! List) {
          return;
        }
        clearData();
        final rateData = data["rateData"];
        List<SleepData> parsed = [];
        if (rateData is List) {
          parsed = rateData.map((e) => SleepData.fromJson(e)).toList();
        }

        parsed.sort((a, b) => a.startTimestamp.compareTo(b.startTimestamp));
        final lastData = parsed.last;
        loadDataTime.value =
            DateTimeUtils.getTimeDifferenceString(lastData.startTimestamp);
        int totalSleepSeconds = parsed.fold<int>(
          0,
          (sum, item) => sum + (item.endTimestamp - item.startTimestamp),
        );
        sleepVal.value =
            (totalSleepSeconds / 3600).toStringAsFixed(1); // 單位小時顯示

        final deepSleepSeconds = parsed.fold<int>(
          0,
          (sum, item) => sum + int.parse(item.deep),
        );
        final lightSleepSeconds = parsed.fold<int>(
          0,
          (sum, item) => sum + int.parse(item.light),
        );

        final remSleepSeconds = parsed.fold<int>(
          0,
          (sum, item) => sum + int.parse(item.rem),
        );

        final awakSleepSeconds = parsed.fold<int>(
          0,
          (sum, item) => sum + int.parse(item.awake),
        );

        deep.value = DateTimeUtils.formatSecondsToHourDecimal(deepSleepSeconds);
        light.value =
            DateTimeUtils.formatSecondsToHourDecimal(lightSleepSeconds);
        rem.value = DateTimeUtils.formatSecondsToHourDecimal(remSleepSeconds);
        awake.value =
            DateTimeUtils.formatSecondsToHourDecimal(awakSleepSeconds);

        deepCount.value = parsed.where((e) => e.deep.isNotEmpty).length;
        lightCount.value = parsed.where((e) => e.light.isNotEmpty).length;
        remCount.value = parsed.where((e) => e.rem.isNotEmpty).length;

        /// 排除awake為0的資料，因為戒指不一定會有給資料
        awakeCount.value =
            parsed.where((e) => e.awake.isNotEmpty && e.awake != '0').length;

        /// 如果detail response有資料，則用detail api數據畫圖
        if (details.isNotEmpty &&
            details["message"] == "SUCCESS" &&
            details["data"].length > 0) {
          final data = details["data"];
          List<SleepDetailData> parsedDetail = [];
          if (data is List) {
            parsedDetail =
                data.map((e) => SleepDetailData.fromJson(e)).toList();
          }

          deepCount.value =
              parsedDetail.where((e) => e.sleepType == 241).length;
          lightCount.value =
              parsedDetail.where((e) => e.sleepType == 242).length;
          remCount.value = parsedDetail.where((e) => e.sleepType == 243).length;
          awakeCount.value =
              parsedDetail.where((e) => e.sleepType == 244).length;
          //   /// 直接將detail數據轉為橫條圖
          for (var dic in parsedDetail) {
            switch (dic.sleepType) {
              case 241:
                sleepSegments.add(SleepSegment(
                  stage: SleepStage.deep,
                  duration: Duration(seconds: dic.duration),
                ));
                break;
              case 242:
                sleepSegments.add(SleepSegment(
                  stage: SleepStage.light,
                  duration: Duration(seconds: dic.duration),
                ));
                break;
              case 243:
                sleepSegments.add(SleepSegment(
                  stage: SleepStage.rem,
                  duration: Duration(seconds: dic.duration),
                ));
                break;
              case 244:
                sleepSegments.add(SleepSegment(
                  stage: SleepStage.awake,
                  duration: Duration(seconds: dic.duration),
                ));
                break;
            }
          }
        } else {
          for (var data in parsed) {
            final stageDurations = {
              SleepStage.deep: int.tryParse(data.deep) ?? 0,
              SleepStage.light: int.tryParse(data.light) ?? 0,
              SleepStage.rem: int.tryParse(data.rem) ?? 0,
              SleepStage.awake: int.tryParse(data.awake) ?? 0,
            };

            stageDurations.forEach((stage, seconds) {
              if (seconds > 0) {
                final minutes = (seconds / 60).ceil(); // 四捨五入成分鐘
                sleepSegments.add(SleepSegment(
                  stage: stage,
                  duration: Duration(minutes: minutes),
                ));
              }
            });
          }
        }

        switch (currentIndex.value) {
          case 0:
            final earliestStart = parsed
                .map((e) => e.startTimestamp)
                .reduce((a, b) => a < b ? a : b);
            final latestEnd = parsed
                .map((e) => e.endTimestamp)
                .reduce((a, b) => a > b ? a : b);

            segmentStartText.value =
                DateTime.fromMillisecondsSinceEpoch(earliestStart * 1000)
                        .format(pattern: "HH:mm") +
                    '入睡';
            segmentEndText.value =
                DateTime.fromMillisecondsSinceEpoch(latestEnd * 1000)
                        .format(pattern: "HH:mm") +
                    '清醒';
            break;
          case 1:
          case 2:
            segmentStartText.value = DateTime.fromMillisecondsSinceEpoch(
                    parsed.first.startTimestamp * 1000)
                .format(pattern: "d日");
            segmentEndText.value = DateTime.fromMillisecondsSinceEpoch(
                    parsed.last.endTimestamp * 1000)
                .format(pattern: "d日");
            break;
        }
        parsed.sort((a, b) => b.startTimestamp.compareTo(a.startTimestamp));

        /// 歷史紀錄
        final list = parsed.map((m) {
          final date =
              DateTime.fromMillisecondsSinceEpoch(m.endTimestamp * 1000);

          return ListHistoryItemModel(
            unit: Rx(''),
            value: Rx(DateTimeUtils.getDurationFormattedString(
                m.startTimestamp, m.endTimestamp)),
            time: Rx(date),
          );
        }).toList();
        k82ModelObj.value.listItemList2.value = list;

        /// 圖表
        sleepApiData.assignAll(parsed);
      }
    } catch (e) {
      print("getFamilyData Error: $e");
    }
  }
  // Future<void> loadDataByDate(DateTime date, {bool isLoading = true}) async {
  //   userId.value = gc.userId.value;

  //   List<SleepDataData> res = [];
  //   List<SleepDetailDataData> detailRes = [];
  //   sleepSegments.value = [];
  //   if (currentIndex.value == 0) {
  //     res = await gc.sleepDataService.getDaily(userId.value, date);
  //     detailRes = await gc.sleepDataService.getDailyDetails(userId.value, date);
  //   } else if (currentIndex.value == 1) {
  //     res = await gc.sleepDataService.getWeekly(userId.value, date);
  //     detailRes =
  //         await gc.sleepDataService.getWeeklyDetails(userId.value, date);
  //   } else if (currentIndex.value == 2) {
  //     res = await gc.sleepDataService.getMonthly(userId.value, date);
  //     detailRes =
  //         await gc.sleepDataService.getMonthlyDetials(userId.value, date);
  //   }

  //   if (res.isEmpty) {
  //     clearData();
  //     return;
  //   }

  //   res.sort((a, b) => a.startTimeStamp.compareTo(b.startTimeStamp));
  //   print("sleep datas res -> ${res.length} ; ${res.toString()}");
  //   detailRes.sort((a, b) => a.startTimeStamp.compareTo(b.startTimeStamp));
  //   final lastData = res.last;
  //   loadDataTime.value =
  //       DateTimeUtils.getTimeDifferenceString(lastData.startTimeStamp);
  //   int totalSleepSeconds = res.fold<int>(
  //     0,
  //     (sum, item) => sum + (item.endTimeStamp - item.startTimeStamp),
  //   );
  //   sleepVal.value = (totalSleepSeconds / 3600).toStringAsFixed(1); // 單位小時顯示

  //   final deepSleepSeconds = res.fold<int>(
  //     0,
  //     (sum, item) => sum + item.deepSleepSeconds,
  //   );
  //   final lightSleepSeconds = res.fold<int>(
  //     0,
  //     (sum, item) => sum + item.lightSleepSeconds,
  //   );

  //   final remSleepSeconds = res.fold<int>(
  //     0,
  //     (sum, item) => sum + item.remSleepSeconds,
  //   );

  //   deep.value = DateTimeUtils.formatSecondsToHourDecimal(deepSleepSeconds);
  //   light.value = DateTimeUtils.formatSecondsToHourDecimal(lightSleepSeconds);
  //   rem.value = DateTimeUtils.formatSecondsToHourDecimal(remSleepSeconds);

  //   deepCount.value = detailRes.where((e) => e.sleepType == 241).length;
  //   lightCount.value = detailRes.where((e) => e.sleepType == 242).length;
  //   remCount.value = detailRes.where((e) => e.sleepType == 243).length;
  //   awakeCount.value = detailRes.where((e) => e.sleepType == 244).length;
  //   int totalDuration244 = detailRes
  //       .where((e) => e.sleepType == 244)
  //       .fold(0, (sum, e) => sum + e.duration);
  //   awake.value = DateTimeUtils.formatSecondsToHourDecimal(totalDuration244);

  //   /// 直接將detail數據轉為橫條圖
  //   for (var dic in detailRes) {
  //     switch (dic.sleepType) {
  //       case 241:
  //         sleepSegments.add(SleepSegment(
  //           stage: SleepStage.deep,
  //           duration: Duration(seconds: dic.duration),
  //         ));
  //         break;
  //       case 242:
  //         sleepSegments.add(SleepSegment(
  //           stage: SleepStage.light,
  //           duration: Duration(seconds: dic.duration),
  //         ));
  //         break;
  //       case 243:
  //         sleepSegments.add(SleepSegment(
  //           stage: SleepStage.rem,
  //           duration: Duration(seconds: dic.duration),
  //         ));
  //         break;
  //       case 244:
  //         sleepSegments.add(SleepSegment(
  //           stage: SleepStage.awake,
  //           duration: Duration(seconds: dic.duration),
  //         ));
  //         break;
  //     }
  //   }

  //   switch (currentIndex.value) {
  //     case 0:
  //       final earliestStart =
  //           res.map((e) => e.startTimeStamp).reduce((a, b) => a < b ? a : b);
  //       final latestEnd =
  //           res.map((e) => e.endTimeStamp).reduce((a, b) => a > b ? a : b);

  //       segmentStartText.value =
  //           DateTime.fromMillisecondsSinceEpoch(earliestStart * 1000)
  //                   .format(pattern: "HH:mm") +
  //               '入睡';
  //       segmentEndText.value =
  //           DateTime.fromMillisecondsSinceEpoch(latestEnd * 1000)
  //                   .format(pattern: "HH:mm") +
  //               '清醒';
  //       break;
  //     case 1:
  //     case 2:
  //       segmentStartText.value =
  //           DateTime.fromMillisecondsSinceEpoch(res.first.startTimeStamp * 1000)
  //               .format(pattern: "d日");
  //       segmentEndText.value =
  //           DateTime.fromMillisecondsSinceEpoch(res.last.endTimeStamp * 1000)
  //               .format(pattern: "d日");
  //       break;
  //   }

  //   /// 歷史紀錄
  //   final list = res.map((m) {
  //     final date = DateTime.fromMillisecondsSinceEpoch(m.endTimeStamp * 1000);

  //     return ListHistoryItemModel(
  //       unit: Rx(''),
  //       value: Rx(DateTimeUtils.getDurationFormattedString(
  //           m.startTimeStamp, m.endTimeStamp)),
  //       time: Rx(date),
  //     );
  //   }).toList();
  //   k82ModelObj.value.listItemList2.value = list;

  //   /// 圖表
  //   sleepData.assignAll(res);
  // }

  Future<void> updateDateRange(int index, {bool isLoading = true}) async {
    if (index == 0) {
      formattedRange.value =
          "${currentDate.value.format(pattern: 'M月d日, EEEE', locale: 'zh_CN')}";
      loadDataByDate(currentDate.value, isLoading: isLoading);
    } else if (index == 1) {
      // 修正：計算週一到週日的範圍
      final startOfWeek = currentDate.value
          .subtract(Duration(days: currentDate.value.weekday - 1));
      final endOfWeek = startOfWeek.add(Duration(days: 6));
      formattedRange.value =
          '${startOfWeek.format(pattern: 'M月d日')} ～ ${endOfWeek.format(pattern: 'M月d日')}';
      loadDataByDate(currentDate.value, isLoading: isLoading);
    } else {
      formattedRange.value =
          "${currentDate.value.year}年 ${currentDate.value.month}月";
      loadDataByDate(currentDate.value, isLoading: isLoading);
    }
  }

  void prevDateRange(int index) {
    if (index == 0) {
      currentDate.value = currentDate.value.subtract(const Duration(days: 1));
    } else if (index == 1) {
      // 修正：移動到上一週的週一
      final currentWeekStart = currentDate.value
          .subtract(Duration(days: currentDate.value.weekday - 1));
      final prevWeekStart = currentWeekStart.subtract(Duration(days: 7));
      currentDate.value = prevWeekStart;
    } else {
      currentDate.value = DateTime(
        currentDate.value.year,
        currentDate.value.month - 1,
        currentDate.value.day,
      );
    }
    updateDateRange(index);
  }

  void nextDateRange(int index) {
    if (index == 0) {
      currentDate.value = currentDate.value.add(const Duration(days: 1));
    } else if (index == 1) {
      // 修正：移動到下一週的週一
      final currentWeekStart = currentDate.value
          .subtract(Duration(days: currentDate.value.weekday - 1));
      final nextWeekStart = currentWeekStart.add(Duration(days: 7));
      currentDate.value = nextWeekStart;
    } else {
      currentDate.value = DateTime(
        currentDate.value.year,
        currentDate.value.month + 1,
        currentDate.value.day,
      );
    }
    updateDateRange(index);
  }

  //----- 日期選擇器
  Future<void> datePicker(int index) async {
    switch (index) {
      case 0:
        await selectDayDate();
        break;
      case 1:
        await selectWeekDate();
        break;
      case 2:
        await selectMothDate();
        break;
    }
  }

  Future<void> selectDayDate() async {
    final controller = Get.put(K87Controller());
    controller.setInitialDate(currentDate.value);
    await showModalBottomSheet(
      context: Get.context!,
      builder: (_) => K87Bottomsheet(
        onConfirm: (int year, int month, int day) {
          final selected = DateTime(year, month, day);
          currentDate.value = selected;
          updateDateRange(0, isLoading: false);
        },
      ),
    );
  }

  Future<void> selectWeekDate() async {
    final controller = Get.put(K88Controller());

    // 修正：設定初始日期為當前選擇週的週一
    final currentWeekStart = currentDate.value
        .subtract(Duration(days: currentDate.value.weekday - 1));
    controller.setInitialDate(currentWeekStart);

    await showModalBottomSheet(
      context: Get.context!,
      builder: (_) => K88Bottomsheet(
        onConfirm: (int year, int month, int day) {
          final selected = DateTime(year, month, day);
          // 修正：自動調整到該日期所在週的週一
          final weekStart =
              selected.subtract(Duration(days: selected.weekday - 1));
          currentDate.value = weekStart;
          updateDateRange(1, isLoading: false);
        },
      ),
    );
  }

  Future<void> selectMothDate() async {
    final controller = Get.put(One7Controller());
    // 設定初始值（同步顯示）
    controller.year.value = currentDate.value.year;
    controller.month.value = currentDate.value.month;
    await showModalBottomSheet(
      context: Get.context!,
      builder: (_) => One7Bottomsheet(
        onConfirm: (int year, int month) {
          final selected = DateTime(year, month, 1);
          currentDate.value = selected;
          updateDateRange(2, isLoading: false);
        },
      ),
    );
  }

  Map<String, int> getDailySleepDurationByType241(
      List<SleepDetailDataData> list) {
    final Map<String, int> dailyDurationMap = {};

    for (var item in list) {
      if (item.sleepType == 241) {
        final key = "${item.sleepStartTimeStamp}";
        dailyDurationMap.update(key, (value) => value + item.duration,
            ifAbsent: () => item.duration);
      }
    }

    return dailyDurationMap;
  }

  void clearData() {
    sleepData.clear();
    sleepApiData.clear();
    sleepSegments.clear();
    sleepVal.value = '';
    loadDataTime.value = '';
    deep.value = '';
    light.value = '';
    rem.value = '';
    awake.value = '';
    isAlert.value = false;

    deepCount.value = 0;
    lightCount.value = 0;
    remCount.value = 0;
    awakeCount.value = 0;
    segmentStartText.value = '';
    segmentEndText.value = '';
    sleepSegments.clear();

    k82ModelObj.value.listItemList2.value.clear(); // 歷史紀錄
    k82ModelObj.value.listItemList2.refresh();
  }

  /// 將sleepData & sleepDetail 轉換為 SleepSegment
  List<SleepSegment> buildSleepSegments({
    required List<SleepDataData> sleepDataList,
    required List<SleepDetailDataData> sleepDetailList,
  }) {
    final List<SleepSegment> segments = [];

    for (final data in sleepDataList) {
      if (data.deepSleepSeconds > 0) {
        segments.add(SleepSegment(
          stage: SleepStage.deep,
          duration: Duration(seconds: data.deepSleepSeconds),
        ));
      }

      if (data.lightSleepSeconds > 0) {
        segments.add(SleepSegment(
          stage: SleepStage.light,
          duration: Duration(seconds: data.lightSleepSeconds),
        ));
      }

      if (data.remSleepSeconds > 0) {
        segments.add(SleepSegment(
          stage: SleepStage.rem,
          duration: Duration(seconds: data.remSleepSeconds),
        ));
      }

      // 找到對應的 detail 項目
      final awakeDetails = sleepDetailList.where((detail) =>
              detail.sleepStartTimeStamp == data.startTimeStamp &&
              detail.sleepType == 244 // awake type
          );

      final awakeDuration =
          awakeDetails.fold<int>(0, (sum, d) => sum + d.duration);

      if (awakeDuration > 0) {
        segments.add(SleepSegment(
          stage: SleepStage.awake,
          duration: Duration(seconds: awakeDuration),
        ));
      }
    }

    return segments;
  }

  /// 記錄頁面訪問事件
  void _logPageViewEvent() {
    FirebaseAnalyticsService.instance.logViewSleepPage(
      sleepValue: sleepVal.value.isNotEmpty ? sleepVal.value : null,
      parameters: {
        'load_time': loadDataTime.value,
        'time_range_index': currentIndex.value,
        'deep_sleep': deep.value,
        'light_sleep': light.value,
        'rem_sleep': rem.value,
        'awake_time': awake.value,
      },
    );
  }
}
