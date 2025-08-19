import 'package:fpdart/fpdart.dart';
import 'package:casi/core/error/exceptions.dart';
import 'package:casi/core/error/failures.dart';
import 'package:casi/core/user/domain/entities/clinic.dart';
import 'package:casi/core/user/domain/entities/enrollment.dart';
import 'package:casi/features/enrollment/domain/entities/ethics.dart';
import 'package:casi/features/enrollment/domain/repositories/enrollment_repository.dart';
import 'package:casi/features/enrollment/data/data_sources/enrollment_remote_data_source.dart';

class EnrollmentRepositoryImpl implements EnrollmentRepository {
  final EnrollmentRemoteDataSource remote;
  EnrollmentRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, List<Clinic>>> queryClinicsPrefix(
    String q, {
    int? limit,
  }) async {
    try {
      final clinics = await remote.queryClinicsPrefix(q, limit: limit);
      return right(clinics);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, Clinic>> createPendingClinic(
    String name, {
    String? province,
    String? city,
  }) async {
    try {
      final clinic = await remote.createPendingClinic(
        name,
        province: province,
        city: city,
      );
      return right(clinic);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> setEnrollmentClinic({
    required String uid,
    required String clinicId,
    int? avgDogsPerWeek,
  }) async {
    try {
      await remote.setEnrollmentClinic(
        uid: uid,
        clinicId: clinicId,
        avgDogsPerWeek: avgDogsPerWeek,
      );
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, Enrollment>> getEnrollment(String uid) async {
    try {
      final enrollment = await remote.getEnrollment(uid);
      return right(enrollment);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, Ethics>> getActiveEthics() async {
    try {
      final ethics = await remote.getActiveEthics();
      return right(ethics);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> acceptEthics({
    required String uid,
    required String version,
  }) async {
    try {
      await remote.acceptEthics(uid: uid, version: version);
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
