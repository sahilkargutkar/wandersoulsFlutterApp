import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';
import 'package:wonder_souls/src/config/model/failure.dart';
import 'package:wonder_souls/src/config/model/success.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/trip_wizard/trip_wizard_cubit.dart';
import 'package:wonder_souls/src/features/trips/presentation/cubit/trip_wizard/trip_wizard_state.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService mockApiService;
  late TripWizardCubit cubit;

  final testPlace = PlaceModel(
    name: 'Paris',
    placeId: 'paris-123',
    description: 'City of light',
    address: 'Paris, France',
    types: ['city'],
  );

  setUpAll(() {
    registerFallbackValue((dynamic x) => x);
  });

  setUp(() {
    mockApiService = MockApiService();
    
    // Set up locator override
    if (sl.isRegistered<ApiService>()) {
      sl.unregister<ApiService>();
    }
    sl.registerSingleton<ApiService>(mockApiService);
    
    cubit = TripWizardCubit();
  });

  tearDown(() {
    cubit.close();
  });

  group('TripWizardCubit Initialization & Steps', () {
    test('initial state is correct', () {
      expect(cubit.state, const TripWizardState());
      expect(cubit.state.status, TripWizardStatus.initial);
    });

    test('init sets destination and step 0', () {
      cubit.init(testPlace);
      expect(cubit.state.destination, testPlace);
      expect(cubit.state.currentStep, 0);
      expect(cubit.state.name, 'Trip to Paris');
    });

    test('navigation nextStep, previousStep, and goToStep', () {
      cubit.init(testPlace);
      expect(cubit.state.currentStep, 0);

      cubit.nextStep();
      expect(cubit.state.currentStep, 1);

      cubit.goToStep(5);
      expect(cubit.state.currentStep, 5);

      cubit.previousStep();
      expect(cubit.state.currentStep, 4);

      // Bounds checking
      cubit.goToStep(-1); // should ignore
      expect(cubit.state.currentStep, 4);

      cubit.goToStep(9); // should ignore
      expect(cubit.state.currentStep, 4);
    });
  });

  group('TripWizardCubit Field Modifiers', () {
    test('setName and setDescription', () {
      cubit.setName('Summer Vacation');
      cubit.setDescription('Family trip to Europe');
      expect(cubit.state.name, 'Summer Vacation');
      expect(cubit.state.description, 'Family trip to Europe');
    });

    test('setIsPublic and setPartyType', () {
      cubit.setIsPublic(false);
      cubit.setPartyType('couple');
      expect(cubit.state.isPublic, false);
      expect(cubit.state.partyType, 'couple');
    });

    test('setDates', () {
      final start = DateTime(2026, 8, 20);
      final end = DateTime(2026, 8, 27);
      cubit.setDates(start, end);
      expect(cubit.state.startDate, start);
      expect(cubit.state.endDate, end);
    });

    test('toggleInterest adds and removes interests', () {
      expect(cubit.state.interests, isEmpty);

      cubit.toggleInterest('Museums');
      expect(cubit.state.interests, ['Museums']);

      cubit.toggleInterest('Food');
      expect(cubit.state.interests, ['Museums', 'Food']);

      cubit.toggleInterest('Museums');
      expect(cubit.state.interests, ['Food']);
    });

    test('setBudgetLevel and setBudgetDetails', () {
      cubit.setBudgetLevel('moderate');
      cubit.setBudgetDetails(
        currency: 'EUR',
        totalEstimated: 1500,
        transportation: 400,
        accommodation: 600,
        food: 300,
        activities: 200,
      );

      expect(cubit.state.budgetLevel, 'moderate');
      expect(cubit.state.currency, 'EUR');
      expect(cubit.state.totalEstimated, 1500.0);
      expect(cubit.state.transportationBudget, 400.0);
      expect(cubit.state.accommodationBudget, 600.0);
      expect(cubit.state.foodBudget, 300.0);
      expect(cubit.state.activitiesBudget, 200.0);
    });

    test('addCollaborator and removeCollaborator', () {
      expect(cubit.state.collaborators, isEmpty);

      cubit.addCollaborator('test@example.com');
      expect(cubit.state.collaborators, [
        {'userEmail': 'test@example.com', 'permissionLevel': 'editor'}
      ]);

      cubit.addCollaborator('another@example.com');
      expect(cubit.state.collaborators.length, 2);

      cubit.removeCollaborator('test@example.com');
      expect(cubit.state.collaborators, [
        {'userEmail': 'another@example.com', 'permissionLevel': 'editor'}
      ]);
    });
  });

  group('TripWizardCubit generateItinerary', () {
    test('generateItinerary parses enveloped response on API success', () async {
      final envelopedResponse = {
        'data': {
          'itinerary': [
            {
              'day': 1,
              'activities': [
                {'name': 'Eiffel Tower', 'time': '10:00 AM'}
              ]
            }
          ]
        }
      };

      when(() => mockApiService.post<dynamic>(
            any(),
            data: any(named: 'data'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => Success<dynamic>(envelopedResponse));

      cubit.init(testPlace);
      
      final future = cubit.generateItinerary();

      // Check loading state transitions
      expect(cubit.state.status, TripWizardStatus.generatingItinerary);
      expect(cubit.state.currentStep, 7);

      await future;

      expect(cubit.state.status, TripWizardStatus.itineraryReady);
      expect(cubit.state.currentStep, 8);
      expect(cubit.state.generatedItinerary, envelopedResponse['data']);
    });

    test('generateItinerary parses direct response on API success', () async {
      final directResponse = {
        'itinerary': [
          {
            'day': 1,
            'activities': [
              {'name': 'Louvre Museum', 'time': '02:00 PM'}
            ]
          }
        ]
      };

      when(() => mockApiService.post<dynamic>(
            any(),
            data: any(named: 'data'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => Success<dynamic>(directResponse));

      cubit.init(testPlace);
      
      await cubit.generateItinerary();

      expect(cubit.state.status, TripWizardStatus.itineraryReady);
      expect(cubit.state.currentStep, 8);
      expect(cubit.state.generatedItinerary, directResponse);
    });

    test('generateItinerary transitions to failure on API failure', () async {
      when(() => mockApiService.post<dynamic>(
            any(),
            data: any(named: 'data'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((_) async => const Failure<dynamic>(message: 'Failed to create trip'));

      cubit.init(testPlace);
      
      await cubit.generateItinerary();

      expect(cubit.state.status, TripWizardStatus.failure);
      expect(cubit.state.errorMessage, 'Failed to create trip');
      expect(cubit.state.currentStep, 6);
    });

    test('generateItinerary transitions to failure on Exception', () async {
      when(() => mockApiService.post<dynamic>(
            any(),
            data: any(named: 'data'),
            fromJson: any(named: 'fromJson'),
          )).thenThrow(Exception('Network error'));

      cubit.init(testPlace);
      
      await cubit.generateItinerary();

      expect(cubit.state.status, TripWizardStatus.failure);
      expect(cubit.state.errorMessage, contains('Network error'));
      expect(cubit.state.currentStep, 6);
    });
  });

  group('TripWizardCubit saveTrip', () {
    test('saveTrip transitions to loading and then success', () async {
      final future = cubit.saveTrip();

      expect(cubit.state.status, TripWizardStatus.loading);

      await future;

      expect(cubit.state.status, TripWizardStatus.success);
    });
  });
}
