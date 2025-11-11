class Api {
  ///-------- api
  static const String baseUrl = "http://api-admin.fixfate.net:38080/";
  // static const String baseUrl = "http://60.250.109.71:38080/";

  static const String login = "login";
  static const String register = "register";
  static const String sms = "getSMSCode";
  static const String avatar = "uploadAvatar";
  static const String userProfile = "getUserProfile";
  static const String updateUserProfile = "updateUserProfile";
  static const String bindDevice = "bindDevice";
  static const String sethealthRecord = "sethealthRecord";
  static const String measurementSet = "measurementSettings/set";
  static const String measurementGet = "measurementSettings/get";
  static const String updatePWD = "user/updatePWD";
  static const String delete = "user/delete";
  static const String sendFirebase = "sendFirebase";
  static const String logset = "log/set";
  static const String logget = "log/get";
  static const String familyShare = "family/share";
  static const String familyBiding = "family/bind";
  static const String familyList = "family/list";
  static const String familyDelete = "family/delete";
  static const String notifyList = "notity/List";
  static const String notifyListSum = "notity/List/sum";
  static const String healthRecordList = "healthRecord/list";
  static const String smsVerify = "forgetPassword/valiCode";
  static const String forgetPasswordSet = "forgetPassword/set";
  static const String reminderInfoSet = "reminderInfo/set";
  static const String reminderInfoGet = "reminderInfo/get";
  static const String sleepSet = "userSleep/set";
  static const String seleepGet = "userSleep/get";
  static const String gpsSet = "gpslog/set";
  static const String getRingSetting = "getPulseRingSetting";
  static const String userFoodRecords = "userFoodRecords/gpt/set";
  static const String getNewSleep = "userSleep/get/new";

  ///取得體脂秤認領數據
  static const String getBodyTemp = "bodyComposition/temp/get";

  ///設定體脂秤認領數據
  static const String setBodyTemp = "bodyComposition/temp/set";

  ///認領取得設定體脂秤
  static const String getClaimSetting = "claim/get";

  ///認領設定體脂秤
  static const String setClaimSetting = "claim/set";

  ///體脂秤所有數據寫入
  static const String setBodyComposition = "bodyComposition/set";

  ///-------- 體脂機廠商api
  static const String ppUrl = "https://uniquehealth.lefuenergy.com";
  static const String getppToken = "/openapi/user/refreshToken";
  static const String getppBodyData =
      "/openapi-bodydata/bodyData/V1_7_1/getAcLfBodyData8";

  ///-------- aws api 正式機
  static const String awsUrl =
      "https://4dyojbdrcb.execute-api.us-east-1.amazonaws.com/prod/";
  static const String awsUrl2 =
      "https://mraofolcb5.execute-api.us-east-1.amazonaws.com/prod/";

  static const String socketUrl =
      "wss://ssubii43ya.execute-api.us-east-1.amazonaws.com/prod";

  ///-------- aws api 測試機
  // static const String awsUrl =
  //     "https://ti9u7loe46.execute-api.us-east-1.amazonaws.com/dev/";
  // static const String awsUrl2 =
  //     "https://mraofolcb5.execute-api.us-east-1.amazonaws.com/prod/";

  // static const String socketUrl =
  //     "wss://t0m6tkob0i.execute-api.us-east-1.amazonaws.com/dev";

  static const String chatHistory = "chat-history";
  static const String getPressure = "stress/analyze";
}
