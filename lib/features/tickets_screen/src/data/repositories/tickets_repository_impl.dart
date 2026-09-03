import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/network/api_service.dart';
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
          return json.map((e) => TicketModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        }
        return [];
      },
    );
  }

  @override
  Future<ApiResult<void>> createTicket(String title, String description, {String? attachmentPath}) async {
    // If multipart form data is needed for attachment in the future, we could handle it here.
    return _apiService.post(
      CommonEndpoints.createTicket,
      data: {
        'title': title,
        'description': description,
      },
    );
  }
}
