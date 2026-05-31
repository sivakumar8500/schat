import 'package:flutter_test/flutter_test.dart';
import 'package:schat/features/dashboard_screen/src/domain/dashboard_model.dart';

void main() {
  group('DashboardModel Unit Tests', () {
    test('DashboardModel instantiates correctly with id', () {
      const model = DashboardModel(id: 'dash_1');

      expect(model.id, 'dash_1');
    });

    test('DashboardModel copyWith updates fields correctly', () {
      const model = DashboardModel(id: 'dash_1');
      final updatedModel = model.copyWith(id: 'dash_2');

      expect(updatedModel.id, 'dash_2');
      expect(model.id, 'dash_1'); // Ensure original is unchanged
    });
  });
}
