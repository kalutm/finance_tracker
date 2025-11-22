import 'package:http/http.dart' as http;

import 'network_client.dart';
import 'request.dart';
import 'response.dart';
import 'network_exceptions.dart';

class HttpNetworkClient implements NetworkClient {
  final http.Client client;

  HttpNetworkClient(this.client);

  @override
  Future<ResponseModel> send(RequestModel request) async {
    try {
      http.Response response;

      switch (request.method) {
        case 'GET':
          response = await client.get(
            request.url,
            headers: request.headers,
          );
          break;

        case 'POST':
          response = await client.post(
            request.url,
            headers: request.headers,
            body: request.body,
          );
          break;

        case 'PUT':
          response = await client.put(
            request.url,
            headers: request.headers,
            body: request.body,
          );
          break;

        case 'DELETE':
          response = await client.delete(
            request.url,
            headers: request.headers,
          );
          break;

        default:
          throw NetworkException("Unsupported method ${request.method}");
      }

      return ResponseModel(
        statusCode: response.statusCode,
        headers: response.headers,
        body: response.body,
      );
    } on http.ClientException catch (_) {
      throw NoConnectionException();
    } catch (_) {
      throw NetworkException("Unexpected network error");
    }
  }
}
