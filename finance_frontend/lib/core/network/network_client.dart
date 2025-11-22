import 'package:finance_frontend/core/network/request.dart';
import 'package:finance_frontend/core/network/response.dart';

abstract class NetworkClient {
  Future<ResponseModel> send(RequestModel request);
}
