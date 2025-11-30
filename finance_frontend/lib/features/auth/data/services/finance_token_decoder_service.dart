import 'package:finance_frontend/features/auth/domain/services/token_decoder_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class FinanceTokenDecoderService implements TokenDecoderService{
  final JwtDecoder decoder;
  FinanceTokenDecoderService(this.decoder);
  @override
  bool isExpired(String token) {
    return JwtDecoder.isExpired(token);
  }
}