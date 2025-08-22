part of 'enrollment_bloc.dart';

@immutable
sealed class EnrollmentEvent extends Equatable {
  const EnrollmentEvent();
  @override
  List<Object?> get props => [];
}

class LoadEnrollmentEvent extends EnrollmentEvent {
  final String uid;
  const LoadEnrollmentEvent(this.uid);
  @override
  List<Object?> get props => [uid];
}

class SearchClinicsEvent extends EnrollmentEvent {
  final String query;
  final int? limit;
  const SearchClinicsEvent(this.query, {this.limit});
  @override
  List<Object?> get props => [query, limit];
}

class CreateClinicEvent extends EnrollmentEvent {
  final String name;
  final String? province;
  final String? city;
  const CreateClinicEvent({required this.name, this.province, this.city});
  @override
  List<Object?> get props => [name, province, city];
}

class SetClinicEvent extends EnrollmentEvent {
  final String uid;
  final String clinicId;
  const SetClinicEvent({required this.uid, required this.clinicId});
  @override
  List<Object?> get props => [uid, clinicId];
}

class LoadEthicsEvent extends EnrollmentEvent {
  const LoadEthicsEvent();
}

class AcceptEthicsEvent extends EnrollmentEvent {
  final String uid;
  final String version;
  const AcceptEthicsEvent({required this.uid, required this.version});
  @override
  List<Object?> get props => [uid, version];
}
