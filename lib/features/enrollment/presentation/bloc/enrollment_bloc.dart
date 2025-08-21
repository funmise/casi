import 'package:casi/core/user/domain/entities/clinic.dart';
import 'package:casi/core/user/domain/entities/enrollment.dart';
import 'package:casi/features/enrollment/domain/entities/ethics.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:casi/core/usecase/usecase.dart';
import 'package:casi/features/enrollment/domain/usecases/query_clinics_prefix.dart';
import 'package:casi/features/enrollment/domain/usecases/create_pending_clinic.dart';
import 'package:casi/features/enrollment/domain/usecases/set_enrollment_clinic.dart';
import 'package:casi/features/enrollment/domain/usecases/get_enrollment.dart';
import 'package:casi/features/enrollment/domain/usecases/get_active_ethics.dart';
import 'package:casi/features/enrollment/domain/usecases/accept_ethics.dart';

part 'enrollment_event.dart';
part 'enrollment_state.dart';

class EnrollmentBloc extends Bloc<EnrollmentEvent, EnrollmentState> {
  final QueryClinicsPrefix _queryClinics;
  final CreatePendingClinic _createClinic;
  final SetEnrollmentClinic _setClinic;
  final GetEnrollment _getEnrollment;
  final GetActiveEthics _getActiveEthics;
  final AcceptEthics _acceptEthics;

  EnrollmentBloc({
    required QueryClinicsPrefix queryClinics,
    required CreatePendingClinic createClinic,
    required SetEnrollmentClinic setClinic,
    required GetEnrollment getEnrollment,
    required GetActiveEthics getActiveEthics,
    required AcceptEthics acceptEthics,
  }) : _queryClinics = queryClinics,
       _createClinic = createClinic,
       _setClinic = setClinic,
       _getEnrollment = getEnrollment,
       _getActiveEthics = getActiveEthics,
       _acceptEthics = acceptEthics,
       super(EnrollmentInitial()) {
    on<LoadEnrollmentEvent>(_onLoadEnrollment);

    on<SearchClinicsEvent>(
      _onSearchClinics,
      transformer: _debounceRestartable(const Duration(milliseconds: 100)),
    );

    on<CreateClinicEvent>(_onCreateClinic);
    on<SetClinicEvent>(_onSetClinic);
    on<LoadEthicsEvent>(_onLoadEthics);
    on<AcceptEthicsEvent>(_onAcceptEthics);
  }

  // Debounce, then switch to the latest handler (cancels previous searches)
  EventTransformer<E> _debounceRestartable<E>(Duration d) {
    return (events, mapper) => events.debounce(d).switchMap(mapper);
  }

  Future<void> _onLoadEnrollment(
    LoadEnrollmentEvent e,
    Emitter<EnrollmentState> emit,
  ) async {
    emit(EnrollmentLoading());
    final res = await _getEnrollment(e.uid);
    res.fold(
      (l) => emit(EnrollmentError(l.message)),
      (r) => emit(EnrollmentLoaded(r)),
    );
  }

  Future<void> _onSearchClinics(
    SearchClinicsEvent e,
    Emitter<EnrollmentState> emit,
  ) async {
    final q = e.query.trim();
    if (q.isEmpty) {
      emit(const ClinicSearchSuccess([], ''));
      return;
    }
    final lower = q.toLowerCase();
    final res = await _queryClinics(ParamsQueryClinic(q, limit: e.limit));
    res.fold(
      (l) => emit(EnrollmentError(l.message)),
      (r) => emit(ClinicSearchSuccess(r, lower)),
    );
  }

  Future<void> _onCreateClinic(
    CreateClinicEvent e,
    Emitter<EnrollmentState> emit,
  ) async {
    emit(EnrollmentLoading());
    final res = await _createClinic(
      ParamsCreateClinic(e.name, province: e.province, city: e.city),
    );
    res.fold(
      (l) => emit(EnrollmentError(l.message)),
      (r) => emit(ClinicCreated(r)),
    );
  }

  Future<void> _onSetClinic(
    SetClinicEvent e,
    Emitter<EnrollmentState> emit,
  ) async {
    emit(EnrollmentLoading());
    final res = await _setClinic(
      ParamsSetClinic(
        uid: e.uid,
        clinicId: e.clinicId,
        avgDogsPerWeek: e.avgDogsPerWeek,
      ),
    );
    res.fold(
      (l) => emit(EnrollmentError(l.message)),
      (r) => emit(ClinicSetSuccess()),
    );
  }

  Future<void> _onLoadEthics(
    LoadEthicsEvent e,
    Emitter<EnrollmentState> emit,
  ) async {
    emit(EnrollmentLoading());
    final res = await _getActiveEthics(NoParams());
    res.fold(
      (l) => emit(EnrollmentError(l.message)),
      (r) => emit(EthicsLoaded(r)),
    );
  }

  Future<void> _onAcceptEthics(
    AcceptEthicsEvent e,
    Emitter<EnrollmentState> emit,
  ) async {
    emit(EnrollmentLoading());
    final res = await _acceptEthics(
      ParamsAcceptEthics(uid: e.uid, version: e.version),
    );
    res.fold(
      (l) => emit(EnrollmentError(l.message)),
      (_) => emit(EthicsAccepted()),
    );
  }
}
