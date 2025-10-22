import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart' as getx;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:pulsedevice/core/network/api.dart';
import 'package:pulsedevice/core/network/network_info.dart';
import 'package:pulsedevice/core/global_controller.dart';

class ApiService {
  final Dio _dio;
  static final NetworkInfo _networkInfo = NetworkInfo();

  ApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: Api.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          contentType: Headers.jsonContentType,
        )) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // 自動加入 Bearer token
          final token = getx.Get.find<GlobalController>().apiToken;
          if (token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          print('----[API REQUEST]-------------------');
          print('URL: ${options.method} ${options.uri}');
          print('Headers: ${options.headers}');
          print('Body: ${options.data}');
          print('-------------------------------------');

          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('----[API RESPONSE]------------------');
          print('URL: ${response.realUri}');
          print('Status: ${response.statusCode}');
          print('Data: ${response.data}');
          print('-------------------------------------');

          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print('----[API ERROR]---------------------');
          print('Error: ${e.message}');
          print('URL: ${e.requestOptions.uri}');
          print('-------------------------------------');

          return handler.next(e);
        },
      ),
    );
  }

  /// 發送 POST 請求，回傳 JSON Map
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> data,
  ) async {
    final hasConnection = await _networkInfo.isConnected();
    if (!hasConnection) throw NoInternetException('請確認網路連線');

    try {
      final response = await _dio.post(path, data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data;
        } else {
          throw Exception('回應非 JSON 格式');
        }
      } else {
        throw ServerException();
      }
    } on DioException catch (e) {
      throw Exception('Dio 錯誤：${e.message}');
    }
  }

  Future<Map<String, dynamic>> postJsonList(
    String path,
    dynamic data,
  ) async {
    final hasConnection = await _networkInfo.isConnected();
    if (!hasConnection) throw NoInternetException('請確認網路連線');

    try {
      final response = await _dio.post(path, data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data;
        } else {
          throw Exception('回應非 JSON 格式');
        }
      } else {
        throw ServerException();
      }
    } on DioException catch (e) {
      throw Exception('Dio 錯誤：${e.message}');
    }
  }

  Future<Map<String, dynamic>> uploadImage({
    required String path,
    required File imageFile,
    required String phone,
  }) async {
    final hasConnection = await _networkInfo.isConnected();
    if (!hasConnection) throw NoInternetException('請確認網路連線');

    final mimeType =
        lookupMimeType(imageFile.path) ?? 'application/octet-stream';
    final mediaType = MediaType.parse(mimeType);

    final fileName = p.basename(imageFile.path);
    final filePart = await MultipartFile.fromFile(
      imageFile.path,
      filename: fileName,
      contentType: mediaType,
    );

    final formData = FormData.fromMap({
      'file': filePart,
      'phone': phone,
    });

    try {
      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('圖片上傳失敗：${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('上傳錯誤：${e.message}');
    }
  }

  Future<void> sendLog({required String json, required String logType}) async {
    try {
      var params = jsonEncode([
        {
          "userId": getx.Get.find<GlobalController>().apiId.value,
          "logType": logType, //記錄狀態 ERROR、WARN、INFO、DEBUG
          "logData": json
        }
      ]);
      final res = await postJsonList(Api.logset, params);
    } catch (e) {}
  }

  Future<void> getRingSetting() async {
    try {
      final gc = getx.Get.find<GlobalController>();
      final res = await postJson(Api.getRingSetting, {});
      if (res.isNotEmpty) {
        if (res["message"] == "SUCCESS") {
          final data = res["data"];
          if (data != null && data.isNotEmpty) {
            final name = data["name"];
            final settingsValue = data["settingsValue"];
            if (name.toString().contains("戒指")) {
              gc.ringSetting.value = settingsValue.toString();
            }
          }
        }
      }
    } catch (e) {}
  }
}

class ApiAwsService {
  final Dio _dio;
  static final NetworkInfo _networkInfo = NetworkInfo();

  ApiAwsService()
      : _dio = Dio(BaseOptions(
          baseUrl: Api.awsUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          contentType: Headers.jsonContentType,
        )) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // 自動加入 Bearer token
          // final token = getx.Get.find<GlobalController>().apiToken;
          // if (token.isNotEmpty) {
          //   options.headers['Authorization'] = 'Bearer $token';
          // }

          print('----[API REQUEST]-------------------');
          print('URL: ${options.method} ${options.uri}');
          print('Headers: ${options.headers}');
          print('Body: ${options.data}');
          print('-------------------------------------');

          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('----[API RESPONSE]------------------');
          print('URL: ${response.realUri}');
          print('Status: ${response.statusCode}');
          print('Data: ${response.data}');
          print('-------------------------------------');

          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print('----[API ERROR]---------------------');
          print('Error: ${e.message}');
          print('URL: ${e.requestOptions.uri}');
          print('-------------------------------------');

          return handler.next(e);
        },
      ),
    );
  }

  /// 發送 POST 請求，回傳 JSON Map
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> data,
  ) async {
    final hasConnection = await _networkInfo.isConnected();
    if (!hasConnection) throw NoInternetException('請確認網路連線');

    try {
      final response = await _dio.post(path, data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data;
        } else {
          throw Exception('回應非 JSON 格式');
        }
      } else {
        throw ServerException();
      }
    } on DioException catch (e) {
      throw Exception('Dio 錯誤：${e.message}');
    }
  }

  Future<Map<String, dynamic>> postJsonList(
    String path,
    dynamic data,
  ) async {
    final hasConnection = await _networkInfo.isConnected();
    if (!hasConnection) throw NoInternetException('請確認網路連線');

    try {
      final response = await _dio.post(path, data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data;
        } else {
          throw Exception('回應非 JSON 格式');
        }
      } else {
        throw ServerException();
      }
    } on DioException catch (e) {
      throw Exception('Dio 錯誤：${e.message}');
    }
  }
}

class ApiAwsService2 {
  final Dio _dio;
  static final NetworkInfo _networkInfo = NetworkInfo();

  ApiAwsService2()
      : _dio = Dio(BaseOptions(
          baseUrl: Api.awsUrl2,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          contentType: Headers.jsonContentType,
        )) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // 自動加入 Bearer token
          // final token = getx.Get.find<GlobalController>().apiToken;
          // if (token.isNotEmpty) {
          //   options.headers['Authorization'] = 'Bearer $token';
          // }

          print('----[API REQUEST]-------------------');
          print('URL: ${options.method} ${options.uri}');
          print('Headers: ${options.headers}');
          print('Body: ${options.data}');
          print('-------------------------------------');

          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('----[API RESPONSE]------------------');
          print('URL: ${response.realUri}');
          print('Status: ${response.statusCode}');
          print('Data: ${response.data}');
          print('-------------------------------------');

          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print('----[API ERROR]---------------------');
          print('Error: ${e.message}');
          print('URL: ${e.requestOptions.uri}');
          print('-------------------------------------');

          return handler.next(e);
        },
      ),
    );
  }

  /// 發送 POST 請求，回傳 JSON Map
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> data,
  ) async {
    final hasConnection = await _networkInfo.isConnected();
    if (!hasConnection) throw NoInternetException('請確認網路連線');

    try {
      final response = await _dio.post(path, data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data;
        } else {
          throw Exception('回應非 JSON 格式');
        }
      } else {
        throw ServerException();
      }
    } on DioException catch (e) {
      throw Exception('Dio 錯誤：${e.message}');
    }
  }

  Future<Map<String, dynamic>> postJsonList(
    String path,
    dynamic data,
  ) async {
    final hasConnection = await _networkInfo.isConnected();
    if (!hasConnection) throw NoInternetException('請確認網路連線');

    try {
      final response = await _dio.post(path, data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data;
        } else {
          throw Exception('回應非 JSON 格式');
        }
      } else {
        throw ServerException();
      }
    } on DioException catch (e) {
      throw Exception('Dio 錯誤：${e.message}');
    }
  }
}
