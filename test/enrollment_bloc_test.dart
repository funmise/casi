import 'package:bloc_test/bloc_test.dart';
import 'package:casi/core/error/failures.dart';
import 'package:casi/core/user/domain/entities/clinic.dart';
import 'package:casi/features/enrollment/domain/usecases/query_clinics_prefix.dart';
import 'package:casi/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'test_doubles.dart';

void main() {
  late MockQueryClinicsPrefix queryClinics;
  late MockCreatePendingClinic createClinic;
  late MockSetEnrollmentClinic setClinic;
  late MockGetEnrollment getEnrollment;
  late MockGetActiveEthics getActiveEthics;
  late MockAcceptEthics acceptEthics;
  late EnrollmentBloc bloc;

  final clinic = buildClinic();
  final enrollment = buildEnrollment();
  final ethics = buildEthics();
  final failure = Failure('something-went-wrong');

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    queryClinics = MockQueryClinicsPrefix();
    createClinic = MockCreatePendingClinic();
    setClinic = MockSetEnrollmentClinic();
    getEnrollment = MockGetEnrollment();
    getActiveEthics = MockGetActiveEthics();
    acceptEthics = MockAcceptEthics();

    bloc = EnrollmentBloc(
      queryClinics: queryClinics,
      createClinic: createClinic,
      setClinic: setClinic,
      getEnrollment: getEnrollment,
      getActiveEthics: getActiveEthics,
      acceptEthics: acceptEthics,
    );
  });

  group('EnrollmentBloc', () {
    blocTest<EnrollmentBloc, EnrollmentState>(
      'given LoadEnrollmentEvent when repository succeeds then emits loading then loaded',
      build: () {
        when(
          () => getEnrollment(any()),
        ).thenAnswer((_) async => Right(enrollment));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadEnrollmentEvent(enrollment.uid)),
      expect: () => [EnrollmentLoading(), EnrollmentLoaded(enrollment)],
      verify: (_) => verify(() => getEnrollment(enrollment.uid)).called(1),
    );

    blocTest<EnrollmentBloc, EnrollmentState>(
      'given LoadEnrollmentEvent when repository fails then emits loading then error',
      build: () {
        when(() => getEnrollment(any())).thenAnswer((_) async => Left(failure));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadEnrollmentEvent('user-404')),
      expect: () => [EnrollmentLoading(), EnrollmentError(failure.message)],
    );

    blocTest<EnrollmentBloc, EnrollmentState>(
      'given SearchClinicsEvent with empty query when event added then emits empty results immediately',
      build: () {
        return bloc;
      },
      act: (bloc) => bloc.add(const SearchClinicsEvent('   ')),
      wait: const Duration(milliseconds: 150),
      expect: () => [const ClinicSearchSuccess([], '')],
    );

    blocTest<EnrollmentBloc, EnrollmentState>(
      'given SearchClinicsEvent when query succeeds then emits debounced search results with lowercase query',
      build: () {
        when(
          () => queryClinics(any()),
        ).thenAnswer((_) async => Right(<Clinic>[clinic]));
        return bloc;
      },
      act: (bloc) => bloc.add(SearchClinicsEvent(clinic.name)),
      wait: const Duration(milliseconds: 150),
      expect: () => [
        ClinicSearchSuccess(<Clinic>[clinic], clinic.name.toLowerCase()),
      ],
      verify: (_) {
        verify(
          () => queryClinics(
            any(
              that: predicate<ParamsQueryClinic>(
                (p) => p.query == clinic.name && p.limit == null,
              ),
            ),
          ),
        ).called(1);
      },
    );

    blocTest<EnrollmentBloc, EnrollmentState>(
      'given CreateClinicEvent when repository succeeds then emits loading then clinic created',
      build: () {
        when(() => createClinic(any())).thenAnswer((_) async => Right(clinic));
        return bloc;
      },
      act: (bloc) => bloc.add(CreateClinicEvent(name: clinic.name)),
      expect: () => [EnrollmentLoading(), ClinicCreated(clinic)],
      verify: (_) => verify(() => createClinic(any())).called(1),
    );

    blocTest<EnrollmentBloc, EnrollmentState>(
      'given CreateClinicEvent when repository fails then emits loading then error',
      build: () {
        when(() => createClinic(any())).thenAnswer((_) async => Left(failure));
        return bloc;
      },
      act: (bloc) => bloc.add(CreateClinicEvent(name: clinic.name)),
      expect: () => [EnrollmentLoading(), EnrollmentError(failure.message)],
    );

    blocTest<EnrollmentBloc, EnrollmentState>(
      'given SetClinicEvent when repository succeeds then emits loading then clinic set success',
      build: () {
        when(() => setClinic(any())).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(
        SetClinicEvent(uid: enrollment.uid, clinicId: enrollment.clinicId),
      ),
      expect: () => [EnrollmentLoading(), ClinicSetSuccess()],
      verify: (_) => verify(() => setClinic(any())).called(1),
    );

    blocTest<EnrollmentBloc, EnrollmentState>(
      'given LoadEthicsEvent when repository succeeds then emits loading then ethics loaded',
      build: () {
        when(
          () => getActiveEthics(any()),
        ).thenAnswer((_) async => Right(ethics));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadEthicsEvent()),
      expect: () => [EnrollmentLoading(), EthicsLoaded(ethics)],
    );

    blocTest<EnrollmentBloc, EnrollmentState>(
      'given AcceptEthicsEvent when repository fails then emits loading then error',
      build: () {
        when(() => acceptEthics(any())).thenAnswer((_) async => Left(failure));
        return bloc;
      },
      act: (bloc) => bloc.add(
        AcceptEthicsEvent(uid: enrollment.uid, version: ethics.version),
      ),
      expect: () => [EnrollmentLoading(), EnrollmentError(failure.message)],
    );
  });
}
