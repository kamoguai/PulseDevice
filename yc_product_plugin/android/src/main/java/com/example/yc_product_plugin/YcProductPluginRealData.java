package com.example.yc_product_plugin;

import android.os.Handler;
import android.util.Log;

import com.yucheng.ycbtsdk.Constants;
import com.yucheng.ycbtsdk.YCBTClient;
import com.yucheng.ycbtsdk.response.BleRealDataResponse;

import java.util.HashMap;

import io.flutter.plugin.common.EventChannel;

public class YcProductPluginRealData {

    /**
     * 监听实时数据
     *
     * @param handler
     * @param eventSink
     */
    public static void setupDeviceRealDataObserver(
            Handler handler,
            EventChannel.EventSink eventSink) {

        YCBTClient.appRegisterRealDataCallBack(new BleRealDataResponse() {
            @Override
            public void onRealDataResponse(int i, HashMap hashMap) {
                Log.d("LHY","sportMap1:"+hashMap);
                int dataType = i; // (int) hashMap.get("dataType");

                switch (dataType) {

                    case Constants.DATATYPE.Real_UploadSport: // 实时计步
                        if (hashMap != null) {

                            Integer step = (Integer) hashMap.get("sportStep");
                            Integer distance = (Integer)hashMap.get("sportDistance");
                            Integer calories = (Integer)hashMap.get("sportCalorie");

                            HashMap stepInfo = new HashMap();
                            stepInfo.put("step", step);
                            stepInfo.put("distance", distance);
                            stepInfo.put("calories", calories);

                            HashMap stepMap = new HashMap();
                            stepMap.put(
                                    YcProductPluginFlutterType.NativeEventType.deviceRealStep,
                                    stepInfo
                            );

                            handler.post(new Runnable() {
                                @Override
                                public void run() {
                                    eventSink.success(stepMap);
                                }
                            });
                        }
                        break;
                    case Constants.DATATYPE.Real_UploadHeart: // 实时心率
                        if (hashMap != null) {
                            Integer heartValue = (Integer) hashMap.get("heartValue");

                            HashMap heartMap = new HashMap();
                            heartMap.put(YcProductPluginFlutterType.NativeEventType.deviceRealHeartRate, heartValue);

                            handler.post(new Runnable() {
                                @Override
                                public void run() {
                                    eventSink.success(heartMap);
                                }
                            });
                        }

                        break;

                    case Constants.DATATYPE.Real_UploadBloodOxygen:
                        if (hashMap != null) {

                            Integer bloodOxygenValue = (Integer) hashMap.get("bloodOxygenValue");

                            HashMap bloodOxygenMap = new HashMap();
                            bloodOxygenMap.put(YcProductPluginFlutterType.NativeEventType.deviceRealBloodOxygen, bloodOxygenValue);

                            handler.post(new Runnable() {
                                @Override
                                public void run() {
                                    eventSink.success(bloodOxygenMap);
                                }
                            });
                        }
                        break;

                    case Constants.DATATYPE.Real_UploadBlood:
                        if (hashMap != null) {

//                            Log.e("TAG", "onRealDataResponse: + " + hashMap );

                            Integer sbp = (Integer) hashMap.get("bloodSBP");
                            Integer dbp = (Integer) hashMap.get("bloodDBP");

//                            Integer hrv = (Integer) hashMap.get("hrv");
//                            if(hrv!=0x0F){
//                                HashMap hrvMap = new HashMap();
//                                hrvMap.put(
//                                    YcProductPluginFlutterType.NativeEventType.deviceRealHRV,
//                                    hrv
//                            );
//
//                            handler.post(new Runnable() {
//                                @Override
//                                public void run() {
//                                    eventSink.success(hrvMap);
//                                }
//                            });
//                            return;
        //                    }

                            HashMap bpInfo = new HashMap();
                            bpInfo.put("systolicBloodPressure", sbp);
                            bpInfo.put("diastolicBloodPressure", dbp);

                            HashMap bloodPressureMap = new HashMap();
                            bloodPressureMap.put(
                                    YcProductPluginFlutterType.NativeEventType.deviceRealBloodPressure,
                                    bpInfo
                            );

                            handler.post(new Runnable() {
                                @Override
                                public void run() {
                                    eventSink.success(bloodPressureMap);
                                }
                            });
                        }
                        break;

                    case Constants.DATATYPE.Real_UploadComprehensive:

                        if (hashMap != null) {
                            Integer tempFloat = (Integer) hashMap.get("tempFloat");
                            Integer tempInteger = (Integer) hashMap.get("tempInteger");

                            Integer bloodSugar = (Integer) hashMap.get("bloodSugar");
                            String bloodGlucose = bloodSugar/10 + "";

                            if(bloodSugar != 0x0F && bloodSugar != 0){
                                HashMap bloodGlucoseMap = new HashMap();
                                bloodGlucoseMap.put(YcProductPluginFlutterType.NativeEventType.deviceRealBloodGlucose, bloodGlucose);
    
                                handler.post(new Runnable() {
                                    @Override
                                    public void run() {
                                        eventSink.success(bloodGlucoseMap);
                                    }
                                });
                                return;
                            }

                            if (tempFloat == 0x0F) {
                                return;
                            }

                            String temperature = tempInteger + "." + tempFloat;
                            HashMap temperatureMap = new HashMap();
                            temperatureMap.put(YcProductPluginFlutterType.NativeEventType.deviceRealTemperature, temperature);

                            handler.post(new Runnable() {
                                @Override
                                public void run() {
                                    eventSink.success(temperatureMap);
                                }
                            });
                        }
                        break;
                    
                        // 压力
                    case Constants.DATATYPE.Real_UploadBodyData:
                        if(hashMap != null){
                            int pressureInteger = (int) hashMap.get("pressureInteger");
                            int pressureFloat = (int) hashMap.get("pressureFloat");

                            if (pressureFloat == 0x0F) {
                                return;
                            }

                            String pressure = pressureInteger + "." + pressureFloat;
                            HashMap pressureMap = new HashMap();
                            pressureMap.put(YcProductPluginFlutterType.NativeEventType.deviceRealPressure, pressure);

                            handler.post(new Runnable() {
                                @Override
                                public void run() {
                                    eventSink.success(pressureMap);
                                }
                            });
                        }

                        
                        break;

                        // 运动模式
                    case Constants.DATATYPE.Real_UploadOGA:
                    Log.d("LHY","sportMap2:"+hashMap);
                        if (hashMap != null) {
                           Log.d("LHY","sportMap3:"+hashMap);
                            Integer time = (Integer)hashMap.get("recordTime");
                            Integer heartRate = (Integer)hashMap.get("heartRate");
                            Integer step = (Integer)hashMap.get("sportsRealSteps");
                            Integer distance = (Integer)hashMap.get("sportsRealDistance");
                            Integer calories = (Integer)hashMap.get("sportsRealCalories");
                            //最大摄氧量
                            Integer maximalOxygenIntake = (int) hashMap.get("maximalOxygenIntake");


                            HashMap sportInfo = new HashMap();
                            sportInfo.put("time", time);
                            sportInfo.put("heartRate", heartRate);
                            sportInfo.put("step", step);
                            sportInfo.put("distance", distance);
                            sportInfo.put("calories", calories);

                            sportInfo.put("vo2max",maximalOxygenIntake);

                            // if(maximalOxygenIntake != 0 && time == 0){
                            //     HashMap sportMap = new HashMap();
                            //     sportMap.put(YcProductPluginFlutterType.NativeEventType.deviceRealVo2max, maximalOxygenIntake);
                            //     handler.post(new Runnable() {
                            //         @Override
                            //         public void run() {
                            //             eventSink.success(sportMap);
                            //         }
                            //     });
                            //     return;
                            // }

                            HashMap sportMap = new HashMap();
                            sportMap.put(YcProductPluginFlutterType.NativeEventType.deviceRealSport, sportInfo);

                            handler.post(new Runnable() {
                                @Override
                                public void run() {
                                    eventSink.success(sportMap);
                                }
                            });
                        }
                        break;


                    default:
                        break;
                }

                Log.e("Flutter", "onRealDataResponse: " + hashMap + "," + i);
            }
        });
    }
}
