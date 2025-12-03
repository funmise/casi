import 'dart:async';

import 'package:casi/core/user/cubit/user_state.dart';
import 'package:casi/core/user/cubit/user_cubit.dart';
import 'package:casi/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:casi/features/enrollment/presentation/pages/terms_of_service_page.dart';
import 'package:casi/features/enrollment/presentation/pages/verify_clinic_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:casi/core/widgets/primary_text_field.dart';

import 'test_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockEnrollmentBloc enrollmentBloc;
  late MockUserCubit userCubit;
  late StreamController<EnrollmentState> enrollmentController;
  late List<EnrollmentEvent> dispatchedEvents;

  final user = buildUserProfile();
  final clinic = buildClinic(
    name: 'Locked Clinic',
    province: 'AB',
    city: 'Calgary',
  );
  Future<void> tapSubmit(WidgetTester tester) async {
    final submitFinder = find.text('Submit');
    await tester.ensureVisible(submitFinder);
    await tester.tap(submitFinder);
    // one frame; timers need a longer pump later
    await tester.pump();
  }

  setUpAll(registerFallbackValues);

  setUp(() {
    enrollmentBloc = MockEnrollmentBloc();
    userCubit = MockUserCubit();
    enrollmentController = StreamController<EnrollmentState>.broadcast();
    dispatchedEvents = [];

    when(
      () => enrollmentBloc.stream,
    ).thenAnswer((_) => enrollmentController.stream);
    when(() => enrollmentBloc.state).thenReturn(EnrollmentInitial());
    when(() => enrollmentBloc.add(any())).thenAnswer((invocation) {
      final event = invocation.positionalArguments.first as EnrollmentEvent;
      dispatchedEvents.add(event);
    });
    when(() => enrollmentBloc.close()).thenAnswer((_) async {});

    final ready = UserReady(user);
    when(() => userCubit.state).thenReturn(ready);
    when(() => userCubit.stream).thenAnswer((_) => Stream.value(ready));
    when(() => userCubit.close()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await enrollmentController.close();
  });

  Finder byHint(String hint) => find.byWidgetPredicate(
    (widget) => widget is PrimaryTextField && widget.hint == hint,
  );

  Widget buildSubject() => MultiBlocProvider(
    providers: [
      BlocProvider<EnrollmentBloc>.value(value: enrollmentBloc),
      BlocProvider<UserCubit>.value(value: userCubit),
    ],
    child: const MaterialApp(home: VerifyClinicPage()),
  );

  testWidgets(
    'given empty clinic name when submitting then shows validation message',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      await tapSubmit(tester);

      expect(find.text('Clinic name is required'), findsOneWidget);

      // Let any debounce/focus timers (≈800–900 ms) complete.
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'given new clinic name when submit tapped then dispatches create clinic event with typed values',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(byHint('Clinic Name'), 'Fresh Clinic');

      // Let the first debounce timer fire.
      await tester.pump(const Duration(seconds: 1));

      await tapSubmit(tester);

      final createEvent = dispatchedEvents.whereType<CreateClinicEvent>().first;
      expect(createEvent.name, 'Fresh Clinic');
      expect(createEvent.province, isNull);
      expect(createEvent.city, isNull);

      // Flush any timers scheduled during resolve-by-exact-name / focus changes.
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'given clinic search matches existing clinic when name resolves then province and city inputs lock',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(byHint('Clinic Name'), clinic.name);
      await tester.pump(const Duration(milliseconds: 300));

      enrollmentController.add(
        ClinicSearchSuccess([clinic], clinic.name.toLowerCase()),
      );

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(); // one extra frame

      final province = tester.widget<PrimaryTextField>(
        byHint('Province (optional)'),
      );
      final city = tester.widget<PrimaryTextField>(byHint('City (optional)'));

      expect(province.enabled, isFalse);
      expect(city.enabled, isFalse);
      expect(province.readOnly, isTrue);
      expect(city.readOnly, isTrue);

      // Flush any remaining debounce/focus timers (~800–900 ms).
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'given clinic set success emitted when listening then navigates to terms of service page',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      enrollmentController.add(ClinicSetSuccess());

      // Let the bloc listener react and perform navigation.
      await tester.pump(); // process the event & first frame
      await tester.pump(const Duration(milliseconds: 300)); // any transition

      expect(find.byType(TermsOfServicePage), findsOneWidget);

      // As with other tests, flush any one-shot timers so the test ends cleanly.
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
