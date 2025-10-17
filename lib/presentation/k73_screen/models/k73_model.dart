import 'package:pulsedevice/presentation/k73_screen/models/family_item_model.dart';

import '../../../core/app_export.dart';
import 'listview_item_model.dart';

/// This class defines the variables used in the [k73_screen],
/// and is typically used to hold data that is passed between different parts of the application.

// ignore_for_file: must_be_immutable
class K73Model {
  Rx<List<ListViewItemModel>> listviewItemList = Rx([
    ListViewItemModel(
      icon: ImageConstant.imgSolidHeartbeat.obs,
      isAlert: false.obs,
      loadTime: "lbl_1".tr.obs,
      label: "lbl171".tr.obs,
      value: "".obs,
      unit: "lbl177".tr.obs,
    ),
    ListViewItemModel(
        icon: ImageConstant.imgIcon.obs,
        isAlert: false.obs,
        loadTime: "lbl_1".tr.obs,
        label: "lbl172_1".tr.obs,
        value: "".obs,
        unit: "".obs),
    ListViewItemModel(
      icon: ImageConstant.imgIconWhiteA700.obs,
      isAlert: false.obs,
      loadTime: "lbl_1".tr.obs,
      label: "lbl173_1".tr.obs,
      value: "".obs,
      unit: "lbl_c".tr.obs,
    ),
    ListViewItemModel(
        icon: ImageConstant.imgIcon1.obs,
        isAlert: false.obs,
        label: "lbl217".tr.obs,
        loadTime: "lbl_1".tr.obs,
        value: "".obs,
        unit: "".obs),
    ListViewItemModel(
      icon: ImageConstant.imgIconWhiteA70040x40.obs,
      isAlert: false.obs,
      loadTime: "lbl_1".tr.obs,
      label: "lbl218".tr.obs,
      value: "".obs,
      unit: "lbl187".tr.obs,
    ),
    ListViewItemModel(
        icon: ImageConstant.iconSleep.obs,
        isAlert: false.obs,
        loadTime: "lbl_1".tr.obs,
        label: "lbl219".tr.obs,
        value: "".obs,
        unit: "lbl189".tr.obs),
    ListViewItemModel(
      icon: ImageConstant.imgFrame87029.obs,
      isAlert: false.obs,
      loadTime: "lbl_1".tr.obs,
      label: "lbl220".tr.obs,
      value: "".obs,
      unit: "lbl_kcal".tr.obs,
    ),
    ListViewItemModel(
        isAlert: false.obs,
        loadTime: "lbl_1".tr.obs,
        icon: ImageConstant.imgIcon40x40.obs,
        label: "lbl221".tr.obs,
        value: "".obs,
        unit: "lbl193".tr.obs),
  ]);

  Rx<List<FamilyItemModel>> familyItemList = Rx([]);
}

class CaloriesData {
  final int startTimestamp;
  final String calories;

  CaloriesData({required this.startTimestamp, required this.calories});

  factory CaloriesData.fromJson(Map<String, dynamic> json) {
    return CaloriesData(
      startTimestamp: json['starttimestamp'],
      calories: json['calories'] ?? '0',
    );
  }
}

class SleepData {
  final int startTimestamp;
  final int endTimestamp;
  final String sleep;
  final String light;
  final String rem;
  final String deep;
  final String awake;

  SleepData({
    required this.startTimestamp,
    required this.endTimestamp,
    required this.sleep,
    required this.light,
    required this.rem,
    required this.deep,
    required this.awake,
  });

  factory SleepData.fromJson(Map<String, dynamic> json) {
    return SleepData(
      startTimestamp: json['starttimestamp'],
      endTimestamp: json['endtimestamp'],
      sleep: json['sleep'] ?? '0',
      light: json['light'] ?? '0',
      rem: json['rem'] ?? '0',
      deep: json['deep'] ?? '0',
      awake: json['awake'] ?? '0',
    );
  }
}

class SleepDetailData {
  final String userID;
  final int startTimestamp;
  final int duration;
  final int sleepType;
  final String typeName;

  SleepDetailData({
    required this.userID,
    required this.startTimestamp,
    required this.duration,
    required this.sleepType,
    required this.typeName,
  });

  factory SleepDetailData.fromJson(Map<String, dynamic> json) {
    return SleepDetailData(
      userID: json['userId'],
      startTimestamp: json['start_time_stamp'],
      duration: json['duration'],
      sleepType: json['sleepType'],
      typeName: json['typeName'],
    );
  }
}

class StepData {
  final int startTimestamp;
  final String step;

  StepData({required this.startTimestamp, required this.step});

  factory StepData.fromJson(Map<String, dynamic> json) {
    return StepData(
      startTimestamp: json['starttimestamp'],
      step: json['step'] ?? '0',
    );
  }
}

class TemperatureData {
  final int startTimestamp;
  final String temperature;
  final String? type;

  TemperatureData({
    required this.startTimestamp,
    required this.temperature,
    this.type,
  });

  factory TemperatureData.fromJson(Map<String, dynamic> json) {
    return TemperatureData(
      startTimestamp: json['starttimestamp'],
      temperature: json['temperature'] ?? '0',
      type: json['type'] ?? '0',
    );
  }
}

class RateData {
  final int startTimestamp;
  final String heartrate;
  final String? type;

  RateData({
    required this.startTimestamp,
    required this.heartrate,
    this.type,
  });

  factory RateData.fromJson(Map<String, dynamic> json) {
    return RateData(
      startTimestamp: json['starttimestamp'],
      heartrate: json['heartrate'] ?? '0',
      type: json['type'] ?? '0',
    );
  }
}

class OxygenData {
  final int startTimestamp;
  final String bloodoxygen;
  final String? type;

  OxygenData({
    required this.startTimestamp,
    required this.bloodoxygen,
    this.type,
  });

  factory OxygenData.fromJson(Map<String, dynamic> json) {
    return OxygenData(
      startTimestamp: json['starttimestamp'],
      bloodoxygen: json['bloodoxygen'] ?? '0',
      type: json['type'] ?? '0',
    );
  }
}

class DistanceData {
  final int startTimestamp;
  final String distance;

  DistanceData({required this.startTimestamp, required this.distance});

  factory DistanceData.fromJson(Map<String, dynamic> json) {
    return DistanceData(
      startTimestamp: json['starttimestamp'],
      distance: json['distance'] ?? '0',
    );
  }
}

class HealthDataSet {
  final List<CaloriesData> caloriesData;
  final List<SleepData> sleepData;
  final List<StepData> stepData;
  final List<TemperatureData> temperatureData;
  final List<RateData> rateData;
  final List<OxygenData> oxygenData;
  final List<DistanceData> distanceData;
  final List<PressureData> pressureData;

  HealthDataSet({
    required this.caloriesData,
    required this.sleepData,
    required this.stepData,
    required this.temperatureData,
    required this.rateData,
    required this.oxygenData,
    required this.distanceData,
    required this.pressureData,
  });

  factory HealthDataSet.fromJson(Map<String, dynamic> json) {
    return HealthDataSet(
      caloriesData: (json['caloriesData'] as List<dynamic>)
          .map((e) => CaloriesData.fromJson(e))
          .toList(),
      sleepData: (json['sleepData'] as List<dynamic>)
          .map((e) => SleepData.fromJson(e))
          .toList(),
      stepData: (json['stepData'] as List<dynamic>)
          .map((e) => StepData.fromJson(e))
          .toList(),
      temperatureData: (json['temperatureData'] as List<dynamic>)
          .map((e) => TemperatureData.fromJson(e))
          .toList(),
      rateData: (json['rateData'] as List<dynamic>)
          .map((e) => RateData.fromJson(e))
          .toList(),
      oxygenData: (json['oxygenData'] as List<dynamic>)
          .map((e) => OxygenData.fromJson(e))
          .toList(),
      distanceData: (json['distanceData'] as List<dynamic>)
          .map((e) => DistanceData.fromJson(e))
          .toList(),
      pressureData: (json['pressureData'] as List<dynamic>)
          .map((e) => PressureData.fromJson(e))
          .toList(),
    );
  }
}

class PressureData {
  final int startTimestamp;
  final int totalStressScore;
  final String? type;
  PressureData(
      {required this.startTimestamp,
      required this.totalStressScore,
      this.type});

  factory PressureData.fromJson(Map<String, dynamic> json) {
    print("pressure json : ${json}");
    return PressureData(
      startTimestamp: json['starttimestamp'],
      totalStressScore: double.parse(json['distance'].toString()).toInt(),
      type: json['type'],
    );
  }
}
