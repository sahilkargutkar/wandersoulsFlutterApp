import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_souls/src/features/auth/data/model1/register_request.dart';

void main() {
  test('RegisterRequest serializes expected signup payload', () {
    final request = RegisterRequest(
      id: 'user-1',
      userName: 'testuser',
      email: 'test@example.com',
      phoneNumber: '1234567890',
      password: 'secret123',
      name: 'Test User',
      profilePicture: '',
      defaultCurrency: 'USD',
      preferences: {
        'language': 'en',
        'country': 'India',
        'phone': '1234567890',
        'travelPreferences': 'Adventure Travel,Food Tourism',
      },
      createdBy: 'System',
      createdAt: '2026-05-18T00:00:00.000Z',
      isActive: true,
      modifiedBy: 'System',
      modifiedOn: '2026-05-18T00:00:00.000Z',
    );

    expect(request.toJson(), {
      'id': 'user-1',
      'userName': 'testuser',
      'email': 'test@example.com',
      'phoneNumber': '1234567890',
      'passwordHash': 'secret123',
      'name': 'Test User',
      'profilePicture': '',
      'defaultCurrency': 'USD',
      'preferences': {
        'language': 'en',
        'country': 'India',
        'phone': '1234567890',
        'travelPreferences': 'Adventure Travel,Food Tourism',
      },
      'createdBy': 'System',
      'createdAt': '2026-05-18T00:00:00.000Z',
      'isActive': true,
      'modifiedBy': 'System',
      'modifiedOn': '2026-05-18T00:00:00.000Z',
    });
  });
}
