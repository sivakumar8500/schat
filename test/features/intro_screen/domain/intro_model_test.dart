import 'package:flutter_test/flutter_test.dart';
import 'package:schat/features/intro_screen/src/domain/intro_model.dart';

void main() {
  group('IntroModel Unit Tests', () {
    test('IntroModel instantiates correctly with id', () {
      const model = IntroModel(id: 'test_id');

      expect(model.id, 'test_id');
    });

    test('IntroModel copyWith updates fields correctly', () {
      const model = IntroModel(id: 'test_id');
      final updatedModel = model.copyWith(id: 'new_id');

      expect(updatedModel.id, 'new_id');
      expect(model.id, 'test_id'); // Ensure original is unchanged
    });
  });
}
