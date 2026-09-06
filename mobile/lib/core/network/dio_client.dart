import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'api_endpoints.dart';
import 'package:image_picker/image_picker.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio dio;

  factory DioClient() {
    return _instance;
  }

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120),
        followRedirects: true,
        maxRedirects: 5,
        validateStatus: (status) => status != null && status >= 200 && status < 400,
      ),
    );

    dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 90,
    ));
  }

  Future<Response> uploadVerification(XFile documentImage, XFile? selfieImage, {Function(int, int)? onProgress}) async {
    dio.options.baseUrl = ApiEndpoints.baseUrl;
    final Map<String, dynamic> data = {
      'document_image': MultipartFile.fromBytes(
        await documentImage.readAsBytes(),
        filename: documentImage.name.isNotEmpty ? documentImage.name : 'document.jpg',
      )
    };
    
    if (selfieImage != null) {
      data['selfie_image'] = MultipartFile.fromBytes(
        await selfieImage.readAsBytes(),
        filename: selfieImage.name.isNotEmpty ? selfieImage.name : 'selfie.jpg',
      );
    }
    
    final formData = FormData.fromMap(data);

    return await dio.post(
      ApiEndpoints.verify,
      data: formData,
      onSendProgress: onProgress,
    );
  }
}
