import 'dart:io';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/core/security/secure_attachment_service.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_endpoints.dart';
import 'package:schat/features/tickets_screen/src/domain/models/ticket_model.dart';
import 'package:schat/features/tickets_screen/src/domain/repositories/tickets_repository.dart';

@Injectable(as: TicketsRepository)
class TicketsRepositoryImpl implements TicketsRepository {
  final ApiService _apiService;

  TicketsRepositoryImpl(this._apiService);

  @override
  Future<ApiResult<List<TicketModel>>> getTickets() async {
    return _apiService.get<List<TicketModel>>(
      CommonEndpoints.getTickets,
      mapper: (json) {
        if (json is List) {
          return json.map((e) {
            final map = Map<String, dynamic>.from(e as Map);
            String? attachment = map['attachmentPath']?.toString() ??
                map['attachment_path']?.toString() ??
                map['imageUrl']?.toString() ??
                map['image_url']?.toString();
            if (attachment != null && attachment.isNotEmpty) {
              map['attachmentPath'] = SecureAttachmentService.resolveFullUrl(attachment);
            }
            return TicketModel.fromJson(map);
          }).toList();
        }
        return [];
      },
    );
  }

  @override
  Future<ApiResult<void>> createTicket(String title, String description, {String? attachmentPath}) async {
    if (attachmentPath != null && attachmentPath.isNotEmpty) {
      if (attachmentPath.startsWith('http://') || attachmentPath.startsWith('https://')) {
        return _apiService.post(
          CommonEndpoints.createTicket,
          data: {
            'title': title,
            'description': description,
            'attachmentPath': attachmentPath,
          },
        );
      }

      final file = File(attachmentPath);
      if (await file.exists()) {
        String uploadFilePath = file.path;
        String fileName = file.path.split('/').last.split('\\').last;

        if (fileName.toLowerCase().endsWith('.enc')) {
          try {
            final normal = await getIt<SecureAttachmentService>().prepareNormalFileForUpload(
              filePath: file.path,
              fileName: fileName,
            );
            uploadFilePath = normal.filePath;
            fileName = normal.fileName;
          } catch (_) {}
        }

        final formData = FormData.fromMap({
          'title': title,
          'description': description,
          'file': await MultipartFile.fromFile(
            uploadFilePath,
            filename: fileName,
          ),
        });

        return _apiService.post(
          CommonEndpoints.createTicket,
          data: formData,
        );
      }
    }

    return _apiService.post(
      CommonEndpoints.createTicket,
      data: {
        'title': title,
        'description': description,
      },
    );
  }
}
