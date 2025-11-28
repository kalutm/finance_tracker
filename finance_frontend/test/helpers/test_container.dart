// test/helpers/test_container.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

ProviderContainer createTestContainer({
  List<Override> overrides = const [],
}) {
  return ProviderContainer(
    overrides: overrides,
  );
}
