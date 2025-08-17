part of 'enrollment_bloc.dart';

@immutable
sealed class EnrollmentState extends Equatable {
  const EnrollmentState();
  @override
  List<Object?> get props => [];
}

class EnrollmentInitial extends EnrollmentState {}

class EnrollmentLoading extends EnrollmentState {}

class EnrollmentError extends EnrollmentState {
  final String message;
  const EnrollmentError(this.message);
  @override
  List<Object?> get props => [message];
}

class EnrollmentLoaded extends EnrollmentState {
  final Enrollment enrollment;
  const EnrollmentLoaded(this.enrollment);
  @override
  List<Object?> get props => [enrollment];
}

class ClinicSearchSuccess extends EnrollmentState {
  final List<Clinic> results;
  final String queryLower;
  const ClinicSearchSuccess(this.results, this.queryLower);
  @override
  List<Object?> get props => [results];
}

class ClinicCreated extends EnrollmentState {
  final Clinic clinic;
  const ClinicCreated(this.clinic);
  @override
  List<Object?> get props => [clinic];
}

class ClinicSetSuccess extends EnrollmentState {}

class EthicsLoaded extends EnrollmentState {
  final Ethics ethics;
  const EthicsLoaded(this.ethics);
  @override
  List<Object?> get props => [ethics];
}

class EthicsAccepted extends EnrollmentState {}
