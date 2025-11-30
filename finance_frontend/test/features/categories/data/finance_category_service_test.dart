import 'dart:convert';

import 'package:finance_frontend/core/network/request.dart';
import 'package:finance_frontend/core/network/response.dart';
import 'package:finance_frontend/core/provider/providers.dart';
import 'package:finance_frontend/features/categories/domain/entities/dtos/category_create.dart';
import 'package:finance_frontend/features/categories/domain/exceptions/category_exceptions.dart';
import 'package:finance_frontend/features/categories/domain/entities/category.dart';
import 'package:finance_frontend/features/categories/domain/entities/category_type_enum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../helpers/Categories/create_fake_Category_create.dart';
import '../../../helpers/categories/create_fake_category.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/test_container.dart';

void main() {
  late MockSecureStorageService mockStorage;
  late MockNetworkClient mockNetwork;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(
      RequestModel(method: 'GET', url: Uri.parse('http://fake.com/categories')),
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

  group('FinanceCategoryService - network integration & caching', () {
    test('getUserCategories - success returns list and emits cache', () async {
      // Arrange
      final body = jsonEncode({
        'total': 3,
        'categories': [
          fakeCategoryJson(id: 1, name: 'Food', type: CategoryType.INCOME),
          fakeCategoryJson(id: 2, name: 'Transport', type: CategoryType.EXPENSE),
          fakeCategoryJson(id: 3, name: 'Travel', type: CategoryType.EXPENSE),
        ],
      });

      final response = ResponseModel(statusCode: 200, headers: {}, body: body);

      when(
        () => mockStorage.readString(key: 'access_token'),
      ).thenAnswer((_) async => 'fake_access_token');

      when(() => mockNetwork.send(any())).thenAnswer((_) async => response);
      final svc = container.read(categoryServiceProvider);

      // subscribe to stream before triggering
      final emitted = <List<FinanceCategory>>[];
      final sub = svc.categoriesStream.listen(emitted.add);

      // Act
      final list = await svc.getUserCategories();

      // Assert
      expect(list.length, 3);
      await Future<void>.delayed(Duration.zero);
      expect(emitted.isNotEmpty, true);
      expect(emitted.last.length, 3);

      // verify interactions
      verify(() => mockStorage.readString(key: 'access_token')).called(1);
      verify(
        () => mockNetwork.send(
          any(
            that: isA<RequestModel>()
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.url.toString(), 'url', contains('/categories')),
          ),
        ),
      ).called(1);

      verifyNoMoreInteractions(mockStorage);
      verifyNoMoreInteractions(mockNetwork);

      await sub.cancel();
    });

    test('getUserCategories - non-200 -> throws CouldnotFetchCategorys', () async {
      when(
        () => mockStorage.readString(key: 'access_token'),
      ).thenAnswer((_) async => 'fake_access_token');

      when(() => mockNetwork.send(any())).thenAnswer(
        (_) async =>
            ResponseModel(statusCode: 400, headers: {}, body: jsonEncode({})),
      );

      final svc = container.read(categoryServiceProvider);

      await expectLater(
        svc.getUserCategories(),
        throwsA(isA<CouldnotFetchCategories>()),
      );

      // verify interactions
      verify(() => mockStorage.readString(key: 'access_token')).called(1);
      verify(() => mockNetwork.send(any())).called(1);
      verifyNoMoreInteractions(mockNetwork);
    });

    test('getUserCategories - network throws exception -> rethrows', () async {
      when(
        () => mockStorage.readString(key: 'access_token'),
      ).thenAnswer((_) async => 'fake_access_token');
      when(() => mockNetwork.send(any())).thenThrow(Exception('network down'));
      final svc = container.read(categoryServiceProvider);

      await expectLater(svc.getUserCategories(), throwsA(isA<Exception>()));

      verify(() => mockNetwork.send(any())).called(1);
    });

    test(
      'createCategory - success returns created and updates stream & cache',
      () async {
        final create = fakeCategoryCreate();

        final respBody = jsonEncode(
          fakeCategoryJson(id: 1, name: 'Food', type: CategoryType.EXPENSE),
        );
        final response = ResponseModel(
          statusCode: 201,
          headers: {},
          body: respBody,
        );

        when(
          () => mockStorage.readString(key: 'access_token'),
        ).thenAnswer((_) async => 'fake_access_token');
        when(() => mockNetwork.send(any())).thenAnswer((_) async => response);

        final svc = container.read(categoryServiceProvider);

        final emitted = <List<FinanceCategory>>[];
        final sub = svc.categoriesStream.listen(emitted.add);

        final created = await svc.createCategory(create);

        expect(created.id, '1');

        await Future<void>.delayed(Duration.zero); // allow emission
        expect(emitted.isNotEmpty, true);
        expect(emitted.last.any((a) => a.id == '1'), true);

        // verify the HTTP request happened
        verify(
          () => mockNetwork.send(
            any(
              that: isA<RequestModel>().having(
                (r) => r.method,
                'method',
                'POST',
              ),
            ),
          ),
        ).called(1);

        // also verify storage call before asserting no more interactions
        verify(() => mockStorage.readString(key: 'access_token')).called(1);

        verifyNoMoreInteractions(mockNetwork);
        verifyNoMoreInteractions(mockStorage);

        await sub.cancel();
      },
    );

    test('createCategory - 400 returns CouldnotCreateCategory', () async {
      final create = CategoryCreate(
        name: 'Travel',
        type: CategoryType.EXPENSE,
      );

      when(
        () => mockStorage.readString(key: 'access_token'),
      ).thenAnswer((_) async => 'fake_access_token');
      when(() => mockNetwork.send(any())).thenAnswer(
        (_) async =>
            ResponseModel(statusCode: 400, headers: {}, body: jsonEncode({})),
      );
      final svc = container.read(categoryServiceProvider);
      await expectLater(
        svc.createCategory(create),
        throwsA(isA<CouldnotCreateCategory>()),
      );

      verify(() => mockNetwork.send(any())).called(1);
      verifyNoMoreInteractions(mockNetwork);
    });

    test('deactivateCategory - subscribe-first approach', () async {
      // Arrange
      when(
        () => mockStorage.readString(key: 'access_token'),
      ).thenAnswer((_) async => 'fake_access_token');

      when(() => mockNetwork.send(any())).thenAnswer((invocation) async {
        final req = invocation.positionalArguments[0] as RequestModel;
        if (req.method == 'POST') {
          return ResponseModel(
            statusCode: 201,
            headers: {},
            body: jsonEncode(fakeCategoryJson(id: 1)),
          );
        } else if (req.method == 'PATCH') {
          return ResponseModel(
            statusCode: 200,
            headers: {},
            body: jsonEncode(fakeCategoryJson(id: 1, active: false)),
          );
        }
        return ResponseModel(
          statusCode: 200,
          headers: {},
          body: jsonEncode({'categories': []}),
        );
      });

      final svc = container.read(categoryServiceProvider);

      final emitted = <List<FinanceCategory>>[];
      final sub = svc.categoriesStream.listen(emitted.add);

      final created = await svc.createCategory(
        CategoryCreate(name: 'A', type: CategoryType.EXPENSE),
      );
      expect(created.id, '1');

      final deactivated = await svc.deactivateCategory('1');
      expect(deactivated.active, false);

      // allow microtask to run and emit
      await Future<void>.delayed(Duration.zero);

      expect(emitted.isNotEmpty, true);
      expect(emitted.last.any((a) => a.id == '1' && a.active == false), true);

      await sub.cancel();
      verify(() => mockNetwork.send(any())).called(greaterThanOrEqualTo(2));
    });

    test(
      'deleteCategory - success removes from cache and emits update',
      () async {
        // Arrange: seed cache with one Category via createCategory
        when(
          () => mockStorage.readString(key: 'access_token'),
        ).thenAnswer((_) async => 'fake_access_token');

        when(() => mockNetwork.send(any())).thenAnswer((invocation) async {
          final req = invocation.positionalArguments[0] as RequestModel;
          if (req.method == 'POST') {
            return ResponseModel(
              statusCode: 201,
              headers: {},
              body: jsonEncode(fakeCategoryJson(id: 42)),
            );
          } else if (req.method == 'DELETE') {
            return ResponseModel(statusCode: 204, headers: {}, body: '');
          }
          return ResponseModel(
            statusCode: 200,
            headers: {},
            body: jsonEncode({'Categories': []}),
          );
        });
        final svc = container.read(categoryServiceProvider);

        final emitted = <List<FinanceCategory>>[];
        final sub = svc.categoriesStream.listen(emitted.add);

        final created = await svc.createCategory(
          CategoryCreate(name: 'Seed', type: CategoryType.EXPENSE, ),
        );
        expect(created.id, '42');

        // Act: delete
        await svc.deleteCategory('42');

        // Wait for stream emission
        await Future<void>.delayed(Duration.zero);
        final last =
            emitted.isNotEmpty ? emitted.last : await svc.categoriesStream.first;
        expect(
          last.any((a) => a.id == '42'),
          false,
          reason: 'deleted Category should be removed from cache',
        );

        await sub.cancel();
      },
    );

    test(
      'deleteCategory - 400 returns CannotDeleteCategoryWithTransactions',
      () async {
        when(
          () => mockStorage.readString(key: 'access_token'),
        ).thenAnswer((_) async => 'fake_access_token');
        when(() => mockNetwork.send(any())).thenAnswer(
          (_) async => ResponseModel(
            statusCode: 400,
            headers: {},
            body: jsonEncode({'detail': {}}),
          ),
        );

        final svc = container.read(categoryServiceProvider);

        await expectLater(
          svc.deleteCategory('1'),
          throwsA(isA<CannotDeleteCategoryWithTransactions>()),
        );

        verify(() => mockNetwork.send(any())).called(1);
      },
    );

    test(
      'concurrent getUserCategories calls lead to multiple network calls but no crash',
      () async {
        when(
          () => mockStorage.readString(key: 'access_token'),
        ).thenAnswer((_) async => 'fake_access_token');

        when(() => mockNetwork.send(any())).thenAnswer((_) async {
          final body = jsonEncode({
            'total': 1,
            'Categories': [fakeCategoryJson(id: 7)],
          });
          return ResponseModel(statusCode: 200, headers: {}, body: body);
        });
        final svc = container.read(categoryServiceProvider);

        // Call twice concurrently
        await Future.wait([svc.getUserCategories(), svc.getUserCategories()]);

        // network should have been called at least twice
        verify(() => mockNetwork.send(any())).called(greaterThanOrEqualTo(2));
      },
    );

    test(
      'token missing -> still attempts network call but response handling occurs',
      () async {
        // token null
        when(
          () => mockStorage.readString(key: 'access_token'),
        ).thenAnswer((_) async => null);

        when(() => mockNetwork.send(any())).thenAnswer(
          (_) async =>
              ResponseModel(statusCode: 401, headers: {}, body: jsonEncode({})),
        );

        final svc = container.read(categoryServiceProvider);
        await expectLater(
          svc.getUserCategories(),
          throwsA(isA<CouldnotFetchCategories>()),
        );

        verify(() => mockStorage.readString(key: 'access_token')).called(1);
        verify(() => mockNetwork.send(any())).called(1);
      },
    );
    
  });
}
