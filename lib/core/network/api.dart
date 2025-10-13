class Api {
  ///-------- api
  static const String baseUrl = "http://api-admin.fixfate.net:38080/";

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
