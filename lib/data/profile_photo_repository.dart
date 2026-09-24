
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/api_service.dart';


/// Uploads the caller's own profile photo. No userId is sent — the
/// backend derives identity from the JWT already attached by
/// ApiClient's interceptor, matching @AuthenticationPrincipal on the
/// Spring Boot side. There is no client-side way to accidentally (or
/// maliciously) target a different user's photo with this call.
class ProfilePhotoRepository {
  const ProfilePhotoRepository(this._apiService);

  final ApiService _apiService;

  Future<String> uploadProfilePhoto(File compressedImageFile) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        compressedImageFile.path,
        // Explicit content type — matches the server's Content-Type
        // whitelist check exactly, rather than letting Dio guess from
        // the file extension.
        contentType: DioMediaType('image', 'jpeg'),
      ),
    });

    // ApiService.post already unwraps the {success, message, data}
    // envelope and attaches the Authorization header via ApiClient's
    // interceptor — same path every other authenticated call in the
    // app uses, no special-casing needed for multipart.
    return _apiService.post<String>(
      '/api/v1/users/me/profile-photo',
      data: formData,
      fromJson: (json) => json as String,
    );
  }
}