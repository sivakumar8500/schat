import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/tickets_screen/src/domain/models/ticket_model.dart';

abstract class TicketsRepository {
  Future<ApiResult<List<TicketModel>>> getTickets();
  Future<ApiResult<void>> createTicket(String title, String description, {String? attachmentPath});
}
