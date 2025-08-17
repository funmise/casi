import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'package:casi/core/theme/app_pallete.dart';
import 'package:casi/core/widgets/primary_button.dart';
import 'package:casi/core/widgets/primary_text_field.dart';
import 'package:casi/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:casi/features/enrollment/domain/entities/clinic.dart';
import 'package:casi/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'terms_of_service_page.dart';

class VerifyClinicPage extends StatefulWidget {
  const VerifyClinicPage({super.key});

  @override
  State<VerifyClinicPage> createState() => _VerifyClinicPageState();
}

class _VerifyClinicPageState extends State<VerifyClinicPage> {
  // visible inputs
  final _clinicCtrl = TextEditingController();
  final _avgDogsCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  // typeahead refs (handy for syncing text)
  final _suggestionsCtrl = SuggestionsController<Clinic>();
  TextEditingController? _typeaheadCtrl;
  FocusNode? _typeaheadFocus;

  Clinic? _selectedClinic;

  @override
  void dispose() {
    _clinicCtrl.dispose();
    _avgDogsCtrl.dispose();
    _provinceCtrl.dispose();
    _cityCtrl.dispose();
    // Close suggestions popup if open
    _suggestionsCtrl.close();
    super.dispose();
  }

  Future<List<Clinic>> _suggestFromBloc(String pattern) async {
    final q = pattern.trim();
    if (q.isEmpty) return const <Clinic>[];

    final lower = q.toLowerCase();
    final bloc = context.read<EnrollmentBloc>();

    // fire the debounced search into the BLoC
    bloc.add(SearchClinicsEvent(q, limit: 10));

    // wait for the next ClinicSearchSuccess that matches this query
    List<Clinic> results = const <Clinic>[];
    try {
      final state = await bloc.stream
          .where((s) => s is ClinicSearchSuccess)
          .cast<ClinicSearchSuccess>()
          .firstWhere((s) => s.queryLower == lower)
          .timeout(const Duration(milliseconds: 900));
      results = state.results;
    } on TimeoutException {
      // if we time out, try to use the *current* state if it matches
      final st = bloc.state;
      if (st is ClinicSearchSuccess && st.queryLower == lower) {
        results = st.results;
      }
    } catch (_) {
      // swallow and return empty—UI will show "No matches"
    }
    return results;
  }

  void _onPickClinic(Clinic c) {
    setState(() {
      _selectedClinic = c;
      _clinicCtrl.text = c.name;
      _provinceCtrl.text = c.province ?? '';
      _cityCtrl.text = c.city ?? '';
    });

    // reflect chosen text in the internal builder controller as well
    final ctrl = _typeaheadCtrl;
    if (ctrl != null) {
      ctrl.text = c.name;
      ctrl.selection = TextSelection.collapsed(offset: c.name.length);
    }

    _suggestionsCtrl.close();
  }

  void _submit() {
    // Close any open overlays/keyboard
    FocusScope.of(context).unfocus();
    _suggestionsCtrl.close();

    final auth = context.read<AuthBloc>().state as AuthAuthenticated;
    final uid = auth.user.id;

    final avg = int.tryParse(
      _avgDogsCtrl.text.trim().isEmpty ? '0' : _avgDogsCtrl.text,
    );

    if (_selectedClinic != null) {
      context.read<EnrollmentBloc>().add(
        SetClinicEvent(
          uid: uid,
          clinicId: _selectedClinic!.id,
          avgDogsPerWeek: avg == 0 ? null : avg,
        ),
      );
    } else {
      // create pending first, then set enrollment clinic (handled in listener)
      context.read<EnrollmentBloc>().add(
        CreateClinicEvent(
          name: _clinicCtrl.text.trim(),
          province: _provinceCtrl.text.trim().isEmpty
              ? null
              : _provinceCtrl.text.trim(),
          city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EnrollmentBloc, EnrollmentState>(
      listener: (context, state) {
        if (state is ClinicCreated) {
          final auth = context.read<AuthBloc>().state as AuthAuthenticated;
          final uid = auth.user.id;
          context.read<EnrollmentBloc>().add(
            SetClinicEvent(
              uid: uid,
              clinicId: state.clinic.id,
              avgDogsPerWeek: int.tryParse(
                _avgDogsCtrl.text.trim().isEmpty ? '0' : _avgDogsCtrl.text,
              ),
            ),
          );
        }

        if (state is EnrollmentError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }

        if (state is ClinicSetSuccess) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
          );
        }
      },
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            // tap anywhere outside → dismiss keyboard + suggestions
            FocusScope.of(context).unfocus();
            _suggestionsCtrl.close();
          },
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      const Text(
                        'Verify Your Clinic',
                        style: TextStyle(
                          color: AppPallete.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Image.asset('assets/images/clinic.png', height: 180),

                      const SizedBox(height: 24),
                      const Text(
                        "Enter your clinic's info below to verify your account",
                        style: TextStyle(color: AppPallete.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // ===== TypeAhead (BLoC-powered) =====
                      TypeAheadField<Clinic>(
                        // avoid double debouncing; BLoC already debounces
                        debounceDuration: Duration.zero,

                        suggestionsCallback: _suggestFromBloc,

                        // input builder (reuse PrimaryTextField)
                        builder: (context, controller, focusNode) {
                          _typeaheadCtrl ??= controller;
                          _typeaheadFocus ??= focusNode;

                          // keep external controller in sync for "create pending"
                          if (controller.text != _clinicCtrl.text) {
                            controller.value = TextEditingValue(
                              text: _clinicCtrl.text,
                              selection: TextSelection.collapsed(
                                offset: _clinicCtrl.text.length,
                              ),
                            );
                          }
                          controller.addListener(() {
                            // typing invalidates previous selection
                            if (_selectedClinic != null &&
                                _selectedClinic!.name != controller.text) {
                              setState(() => _selectedClinic = null);
                            }
                            _clinicCtrl.text = controller.text;
                          });

                          return PrimaryTextField(
                            controller: controller,
                            focusNode: focusNode,
                            hint: 'Clinic Name',
                            textInputAction: TextInputAction.search,
                            suffix: const Icon(
                              Icons.search,
                              color: AppPallete.white,
                            ),
                          );
                        },

                        itemBuilder: (context, Clinic c) => ListTile(
                          title: Text(
                            c.name,
                            style: const TextStyle(color: AppPallete.white),
                          ),
                          subtitle: Text(
                            [
                              c.city,
                              c.province,
                            ].where((e) => (e ?? '').isNotEmpty).join(', '),
                            style: const TextStyle(color: AppPallete.white),
                          ),
                        ),

                        onSelected: _onPickClinic,

                        emptyBuilder: (context) => ListTile(
                          title: const Text(
                            'No matches',
                            style: TextStyle(color: AppPallete.white),
                          ),
                          subtitle: Text(
                            'Press Submit to create "${_clinicCtrl.text}"',
                            style: const TextStyle(color: AppPallete.white),
                          ),
                        ),

                        suggestionsController: _suggestionsCtrl,
                        decorationBuilder: (context, child) => Material(
                          color: AppPallete.black.withOpacity(.9),
                          borderRadius: BorderRadius.circular(12),
                          child: child,
                        ),
                        constraints: const BoxConstraints(
                          maxHeight: 280,
                          minWidth: 432,
                        ),
                      ),
                      const SizedBox(height: 16),

                      PrimaryTextField(
                        controller: _provinceCtrl,
                        hint: 'Province (optional)',
                      ),
                      const SizedBox(height: 12),

                      PrimaryTextField(
                        controller: _cityCtrl,
                        hint: 'City (optional)',
                      ),
                      const SizedBox(height: 12),

                      PrimaryTextField(
                        controller: _avgDogsCtrl,
                        hint: 'Average number of Dogs Seen Per Week (optional)',
                        keyboardType: TextInputType.number,
                        suffix: const Icon(Icons.pets, color: AppPallete.white),
                      ),
                      const SizedBox(height: 20),

                      PrimaryButton(label: 'Submit', onPressed: _submit),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
