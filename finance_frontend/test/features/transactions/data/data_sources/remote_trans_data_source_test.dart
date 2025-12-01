import 'package:finance_frontend/core/network/request.dart';
import 'package:finance_frontend/core/provider/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/test_container.dart';

void main() {
  late MockSecureStorageService mockStorage;
  late MockNetworkClient mockNetwork;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(
      RequestModel(
        method: 'GET',
        url: Uri.parse('http://fake.com/transactions'),
      ),
    );
  });

  setUp(() {
    mockStorage = MockSecureStorageService();
    mockNetwork = MockNetworkClient();

    container = createTestContainer(
      overrides: [
        networkClientProvider.overrideWithValue(mockNetwork),
        secureStorageProvider.overrideWithValue(mockStorage),
        baseUrlProvider.overrideWithValue('http://fake.com'),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    reset(mockNetwork);
    reset(mockStorage);
  });

  
}
