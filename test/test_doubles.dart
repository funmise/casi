import 'package:bloc_test/bloc_test.dart';
import 'package:casi/core/enums.dart';
import 'package:casi/core/usecase/usecase.dart';
import 'package:casi/core/user/cubit/user_cubit.dart';
import 'package:casi/core/user/cubit/user_state.dart';
import 'package:casi/core/user/domain/entities/clinic.dart';
import 'package:casi/core/user/domain/entities/enrollment.dart';
import 'package:casi/core/user/domain/entities/user_profile.dart';
import 'package:casi/features/enrollment/domain/entities/ethics.dart';
import 'package:casi/features/enrollment/domain/usecases/accept_ethics.dart';
import 'package:casi/features/enrollment/domain/usecases/create_pending_clinic.dart';
import 'package:casi/features/enrollment/domain/usecases/get_active_ethics.dart';
import 'package:casi/features/enrollment/domain/usecases/get_enrollment.dart';
import 'package:casi/features/enrollment/domain/usecases/query_clinics_prefix.dart';
import 'package:casi/features/enrollment/domain/usecases/set_enrollment_clinic.dart';
import 'package:casi/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockEnrollmentBloc extends MockBloc<EnrollmentEvent, EnrollmentState>
    implements EnrollmentBloc {}

class MockUserCubit extends MockCubit<UserState> implements UserCubit {}

class MockQueryClinicsPrefix extends Mock implements QueryClinicsPrefix {}

class MockCreatePendingClinic extends Mock implements CreatePendingClinic {}

class MockSetEnrollmentClinic extends Mock implements SetEnrollmentClinic {}

class MockGetEnrollment extends Mock implements GetEnrollment {}

class MockGetActiveEthics extends Mock implements GetActiveEthics {}

class MockAcceptEthics extends Mock implements AcceptEthics {}

void registerFallbackValues() {
  registerFallbackValue(const SearchClinicsEvent(''));
  registerFallbackValue(EnrollmentInitial());
  registerFallbackValue(ParamsQueryClinic(''));
  registerFallbackValue(ParamsCreateClinic(''));
  registerFallbackValue(ParamsSetClinic(uid: '', clinicId: ''));
  registerFallbackValue(NoParams());
  registerFallbackValue(ParamsAcceptEthics(uid: '', version: ''));
}

Clinic buildClinic({
  String id = 'clinic-123',
  String name = 'Test Clinic',
  String province = 'ON',
  String? city = 'Toronto',
  ClinicStatus status = ClinicStatus.active,
  DateTime? createdAt,
}) =>
    Clinic(
      id: id,
      name: name,
      province: province,
      city: city,
      status: status,
      createdAt: createdAt,
    );

UserProfile buildUserProfile({
  String uid = 'user-123',
  String email = 'test@example.com',
  String name = 'Test User',
}) =>
    UserProfile(
      uid: uid,
      email: email,
      name: name,
      clinicId: 'clinic-123',
      clinicName: 'Test Clinic',
      clinicProvince: 'ON',
      clinicCity: 'Toronto',
      clinicStatus: ClinicStatus.active,
    );

Enrollment buildEnrollment({
  String uid = 'user-123',
  String clinicId = 'clinic-123',
  EnrollmentStatus status = EnrollmentStatus.active,
}) =>
    Enrollment(
      uid: uid,
      clinicId: clinicId,
      status: status,
      ethicsVersion: '2024.01',
      ethicsAcceptedAt: DateTime(2024, 1, 1),
    );

Ethics buildEthics({
  String version = '2024.01',
  String title = 'Sample Ethics',
  String body = 'Body of ethics content',
  DateTime? updatedAt,
}) =>
    Ethics(
      version: version,
      title: title,
      body: body,
      updatedAt: updatedAt ?? DateTime(2024, 1, 1),
    );
