import 'dart:async';

import 'package:casi/core/user/cubit/user_cubit.dart';
import 'package:casi/core/user/cubit/user_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'package:casi/core/theme/app_pallete.dart';
import 'package:casi/core/widgets/primary_button.dart';
import 'package:casi/core/widgets/primary_text_field.dart';
import 'package:casi/core/user/domain/entities/clinic.dart';
import 'package:casi/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'terms_of_service_page.dart';
import 'package:country_state_city/country_state_city.dart' as csc;
import 'package:casi/core/utils/ca_geo.dart';

class VerifyClinicPage extends StatefulWidget {
  const VerifyClinicPage({super.key});

  @override
  State<VerifyClinicPage> createState() => _VerifyClinicPageState();
}

class _VerifyClinicPageState extends State<VerifyClinicPage> {
  // form
  final _formKey = GlobalKey<FormState>();

  // visible inputs typeahead refs
  final _clinicSuggestionsCtrl = SuggestionsController<Clinic>();
  TextEditingController? _clinicTypeaheadCtrl;
  FocusNode? _clinicTypeaheadFocus;
  String get _clinicName => _clinicTypeaheadCtrl?.text.trim() ?? '';

  final _provinceSuggestionsCtrl = SuggestionsController<String>();
  TextEditingController? _provinceTypeaheadCtrl;
  FocusNode? _provinceTypeaheadFocus;
  String get _provinceName => _provinceTypeaheadCtrl?.text.trim() ?? '';

  final _citySuggestionsCtrl = SuggestionsController<String>();
  TextEditingController? _cityTypeaheadCtrl;
  FocusNode? _cityTypeaheadFocus;
  String get _cityName => _cityTypeaheadCtrl?.text.trim() ?? '';

  Clinic? _selectedClinic;
  String? _selectedProvinceCode;
  final Map<String, List<String>> _citiesCache = {};

  //  lock fields
  bool get _isLocked => _selectedClinic != null;
  Timer? _resolveTimer;
  bool _wiredClinicListener = false;
  bool _wiredProvinceListener = false;
  bool _wiredCityFocusListener = false;
  bool get _hasClinicText =>
      (_clinicTypeaheadCtrl?.text.trim().isNotEmpty ?? false);

  // scrolling + anchors
  final _scrollCtrl = ScrollController();
  final _clinicKey = GlobalKey();
  final _provinceKey = GlobalKey();
  final _cityKey = GlobalKey();

  // scroll for typeahaead
  void _animateToKey(GlobalKey key, {double alignment = 0.0}) {
    // Run after current frame and after keyboard starts animating
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx == null) return;
      final renderObject = ctx.findRenderObject();
      if (renderObject is! RenderBox) return;

      final viewport = RenderAbstractViewport.of(renderObject);

      // alignment: 0.0 = top, 1.0 = bottom
      final target = viewport.getOffsetToReveal(renderObject, alignment).offset;

      // Leave a little headroom
      final double padding = 12.0;

      // Clamp
      final position = _scrollCtrl.position;
      final clamped = target - padding;
      final to = clamped.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );

      // Animate to final position
      _scrollCtrl.animateTo(
        to,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    // Close suggestions popup if open
    _clinicSuggestionsCtrl.close();
    _provinceSuggestionsCtrl.close();
    _citySuggestionsCtrl.close();
    _resolveTimer?.cancel();
    super.dispose();
  }

  bool get _provinceTextInvalid {
    if (_isLocked) return false; // locked province can't be invalid
    final t = (_provinceTypeaheadCtrl?.text.trim() ?? '');
    return t.isNotEmpty && codeForProvinceName(t) == null;
  }

  Future<Clinic?> _resolveClinicByExactName(String name) async {
    final query = name.trim();
    if (query.isEmpty) return null;

    final bloc = context.read<EnrollmentBloc>();
    final querylower = query.toLowerCase();
    bloc.add(SearchClinicsEvent(query));

    try {
      final state = await bloc.stream
          .where((s) => s is ClinicSearchSuccess)
          .cast<ClinicSearchSuccess>()
          .firstWhere((s) => s.queryLower == querylower)
          .timeout(const Duration(milliseconds: 900));

      // find exact (case-insensitive) match; return null if none
      for (final c in state.results) {
        if (c.name.toLowerCase() == querylower) return c;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Schedule a resolve after a brief pause
  void _scheduleResolveExact(String text) {
    final query = text.trim();

    // If empty: cancel any pending resolve, unlock, and bail
    if (query.isEmpty) {
      _resolveTimer?.cancel();
      if (_selectedClinic != null) {
        setState(() => _selectedClinic = null);
      }
      _provinceTypeaheadFocus?.canRequestFocus = true;
      _cityTypeaheadFocus?.canRequestFocus = true;
      return;
    }

    // Debounce: cancel any previous timer so only the latest keystroke wins.
    _resolveTimer?.cancel();

    _resolveTimer = Timer(const Duration(milliseconds: 250), () async {
      // If already locked to the same name (case-insensitive), do nothing.
      final queryLower = query.toLowerCase();
      if (_selectedClinic != null &&
          _selectedClinic!.name.toLowerCase() == queryLower) {
        return;
      }

      final match = await _resolveClinicByExactName(query);
      if (!mounted) return;

      if (match != null) {
        _lockToClinic(match); // lock + fill fields
      } else if (_selectedClinic != null) {
        setState(() => _selectedClinic = null); // unlock
        // unlock focus for province/city
        _provinceTypeaheadFocus?.canRequestFocus = true;
        _cityTypeaheadFocus?.canRequestFocus = true;
      }
    });
  }

  void _lockToClinic(Clinic c) {
    setState(() {
      _selectedClinic = c;
      _selectedProvinceCode = c.province;
    });

    _clinicTypeaheadCtrl?.text = c.name;
    _clinicTypeaheadCtrl?.selection = TextSelection.collapsed(
      offset: c.name.length,
    );
    _provinceTypeaheadCtrl?.text = nameForProvinceCode(c.province);
    _cityTypeaheadCtrl?.text = (c.city ?? '');

    /// Clear focus & block further requests
    FocusManager.instance.primaryFocus?.unfocus();

    _provinceTypeaheadFocus
      ?..unfocus()
      ..canRequestFocus = false;
    _cityTypeaheadFocus
      ?..unfocus()
      ..canRequestFocus = false;

    // Close any overlays
    _clinicSuggestionsCtrl.close();
    _provinceSuggestionsCtrl.close();
    _citySuggestionsCtrl.close();
  }

  Future<List<Clinic>> _suggestClinics(String queryText) async {
    final q = queryText.trim();
    if (q.isEmpty) return const <Clinic>[];

    final lower = q.toLowerCase();
    final bloc = context.read<EnrollmentBloc>();

    // fire the search into the BLoC
    bloc.add(SearchClinicsEvent(q));

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

  Future<List<String>> _suggestProvinces(String queryText) async {
    final s = queryText.trim().toLowerCase();
    final all = kProvinceCodeToName.values.toList();
    if (s.isEmpty) return all;
    return all.where((n) => n.toLowerCase().startsWith(s)).toList();
  }

  Future<List<String>> _suggestCities(String queryText) async {
    final code =
        _selectedProvinceCode ??
        codeForProvinceName(_provinceTypeaheadCtrl?.text);
    if (code == null || code.isEmpty) return const [];
    final search = queryText.trim().toLowerCase();

    final cached = _citiesCache[code];
    final List<String> cities;
    if (cached != null) {
      cities = cached;
    } else {
      final raw = await csc.getStateCities('CA', code);
      cities = raw.map((c) => c.name).where((n) => n.isNotEmpty).toList()
        ..sort((a, b) => a.compareTo(b));
      _citiesCache[code] = cities;
    }
    if (search.isEmpty) return cities.toList();
    return cities.where((n) => n.toLowerCase().startsWith(search)).toList();
  }

  void _onPickClinic(Clinic c) {
    setState(() {
      _selectedClinic = c;
      _selectedProvinceCode = c.province;
    });

    // reflect chosen text in the internal builder controller as well
    final ctrl = _clinicTypeaheadCtrl;
    if (ctrl != null) {
      ctrl.text = c.name;
      _provinceTypeaheadCtrl?.text = nameForProvinceCode(c.province);
      _cityTypeaheadCtrl?.text = (c.city ?? '');
      ctrl.selection = TextSelection.collapsed(offset: c.name.length);
    }

    _clinicSuggestionsCtrl.close();
  }

  void _submit() {
    // Close any open overlays/keyboard
    FocusScope.of(context).unfocus();
    _clinicSuggestionsCtrl.close();
    _provinceSuggestionsCtrl.close();
    _citySuggestionsCtrl.close();

    // Block submit if the clinic name is empty.
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      // focus the first invalid field
      if ((_clinicTypeaheadCtrl?.text.trim().isEmpty ?? true)) {
        _clinicTypeaheadFocus?.requestFocus();
      } else if (_provinceTextInvalid) {
        _provinceTypeaheadFocus
          ?..canRequestFocus = true
          ..requestFocus();
      } else {
        // fallback if something else failed
        _clinicTypeaheadFocus?.requestFocus();
      }
      return;
    }

    final userState = context.read<UserCubit>().state as UserReady;
    final uid = userState.user.uid;

    // resolve code if user typed province name but didn’t select

    final provinceCode = _provinceName.isEmpty
        ? null
        : codeForProvinceName(_provinceName);

    final city = _cityName.isEmpty ? null : _cityTypeaheadCtrl!.text.trim();

    if (_selectedClinic != null) {
      context.read<EnrollmentBloc>().add(
        SetClinicEvent(uid: uid, clinicId: _selectedClinic!.id),
      );
    } else {
      // create pending first, then set enrollment clinic (handled in listener)
      context.read<EnrollmentBloc>().add(
        CreateClinicEvent(
          name: _clinicName,
          province: provinceCode,
          city: city,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EnrollmentBloc, EnrollmentState>(
      listener: (context, state) {
        if (state is EnrollmentError) {
          if (state.message == 'enrollment-not-found') {
            return;
          }
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }

        if (state is ClinicCreated) {
          final userState = context.read<UserCubit>().state as UserReady;
          final uid = userState.user.uid;
          context.read<EnrollmentBloc>().add(
            SetClinicEvent(uid: uid, clinicId: state.clinic.id),
          );
        }

        if (state is ClinicSetSuccess) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const TermsOfServicePage()));
        }
      },
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            // tap anywhere outside → dismiss keyboard + suggestions
            FocusScope.of(context).unfocus();
            _clinicSuggestionsCtrl.close();
          },
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                    key: _formKey,
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
                          style: TextStyle(
                            color: AppPallete.white,
                            fontSize: 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // ===== TypeAhead (BLoC-powered) =====
                        TypeAheadField<Clinic>(
                          // avoid double debouncing; BLoC already debounces
                          debounceDuration: Duration.zero,

                          suggestionsCallback: _suggestClinics,

                          // input builder
                          builder: (context, controller, focusNode) {
                            _clinicTypeaheadCtrl ??= controller;
                            _clinicTypeaheadFocus ??= focusNode;

                            if (!_wiredClinicListener) {
                              _wiredClinicListener = true;

                              // One listener to drive both behaviors:
                              controller.addListener(() {
                                _scheduleResolveExact(
                                  controller.text,
                                ); // live auto-resolve + lock/unlock
                              });

                              // auto-scroll: focus → slight delay → animate
                              focusNode.addListener(() {
                                if (focusNode.hasFocus) {
                                  Future.delayed(
                                    const Duration(milliseconds: 800),
                                    () => _animateToKey(_clinicKey),
                                  );
                                }
                              });
                            }

                            return PrimaryTextField(
                              key: _clinicKey,
                              controller: controller,
                              focusNode: focusNode,
                              hint: 'Clinic Name',
                              textInputAction: TextInputAction.search,
                              suffix: const Icon(
                                Icons.search,
                                color: AppPallete.white,
                              ),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (v) {
                                final name = (v ?? '').trim();
                                if (name.isEmpty) {
                                  return 'Clinic name is required';
                                }
                                return null;
                              },
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
                              'You are creating: "$_clinicName"',
                              style: const TextStyle(color: AppPallete.white),
                            ),
                          ),

                          suggestionsController: _clinicSuggestionsCtrl,
                          decorationBuilder: (context, child) => Material(
                            color: AppPallete.black.withValues(alpha: .9),
                            borderRadius: BorderRadius.circular(12),
                            child: child,
                          ),
                          constraints: const BoxConstraints(
                            maxHeight: 280,
                            minWidth: 432,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // --- Province (TypeAhead of full names; we keep CODE separately) ---
                        IgnorePointer(
                          ignoring: _isLocked,
                          child: TypeAheadField<String>(
                            suggestionsCallback: _isLocked
                                ? (_) async => const []
                                : _suggestProvinces,
                            builder: (context, controller, focusNode) {
                              _provinceTypeaheadCtrl ??= controller;
                              _provinceTypeaheadFocus ??= focusNode;

                              if (!_wiredProvinceListener) {
                                _wiredProvinceListener = true;
                                controller.addListener(() {
                                  if (_isLocked) return;
                                  final code = codeForProvinceName(
                                    controller.text.trim(),
                                  );
                                  if (code != _selectedProvinceCode) {
                                    setState(
                                      () => _selectedProvinceCode = code,
                                    );
                                    _cityTypeaheadCtrl?.clear();
                                    _citySuggestionsCtrl.close();
                                    _citySuggestionsCtrl.refresh();
                                  }
                                });

                                // auto-scroll: focus → slight delay → animate
                                focusNode.addListener(() {
                                  if (focusNode.hasFocus) {
                                    Future.delayed(
                                      const Duration(milliseconds: 800),
                                      () => _animateToKey(_provinceKey),
                                    );
                                  }
                                });
                              }
                              return PrimaryTextField(
                                key: _provinceKey,
                                controller: controller,
                                focusNode: focusNode,
                                hint: 'Province (optional)',
                                textInputAction: TextInputAction.next,
                                enabled: !_isLocked, // <-- lock visual + input
                                readOnly: _isLocked,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                validator: (v) {
                                  if (_isLocked) {
                                    return null; // locked = always valid
                                  }
                                  final t = (v ?? '').trim();
                                  if (t.isEmpty) return null; // optional
                                  return codeForProvinceName(t) == null
                                      ? 'Please choose a valid province/territory'
                                      : null;
                                },
                              );
                            },
                            itemBuilder: (context, String name) => ListTile(
                              title: Text(
                                name,
                                style: const TextStyle(color: AppPallete.white),
                              ),
                            ),
                            onSelected: (String name) {
                              setState(() {
                                _selectedProvinceCode = codeForProvinceName(
                                  name,
                                );
                              });
                              // keep text in the field
                              _provinceTypeaheadCtrl?.text = name;
                              // clear city when province changes
                              _cityTypeaheadCtrl?.clear();
                              _citySuggestionsCtrl.close();
                              _citySuggestionsCtrl.refresh();
                            },

                            emptyBuilder: (context) => _isLocked
                                ? const SizedBox.shrink()
                                : ListTile(
                                    title: const Text(
                                      'No matches',
                                      style: TextStyle(color: AppPallete.white),
                                    ),
                                    subtitle: Text(
                                      'You are creating: "$_provinceName"',
                                      style: const TextStyle(
                                        color: AppPallete.white,
                                      ),
                                    ),
                                  ),

                            suggestionsController: _provinceSuggestionsCtrl,
                            decorationBuilder: (context, child) => Material(
                              color: AppPallete.black.withValues(alpha: .9),
                              borderRadius: BorderRadius.circular(12),
                              child: child,
                            ),
                            constraints: const BoxConstraints(
                              maxHeight: 280,
                              minWidth: 432,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // --- City (TypeAhead backed by package; free text allowed) ---
                        IgnorePointer(
                          ignoring: _isLocked,
                          child: TypeAheadField<String>(
                            suggestionsCallback: _isLocked
                                ? (_) async => const []
                                : _suggestCities,
                            builder: (context, controller, focusNode) {
                              _cityTypeaheadCtrl ??= controller;
                              _cityTypeaheadFocus ??= focusNode;

                              if (!_wiredCityFocusListener) {
                                _wiredCityFocusListener = true;

                                // scroll on focus (delayed for keyboard)
                                focusNode.addListener(() {
                                  if (focusNode.hasFocus) {
                                    Future.delayed(
                                      const Duration(milliseconds: 800),
                                      () => _animateToKey(_cityKey),
                                    );
                                  }
                                });
                              }

                              return PrimaryTextField(
                                key: _cityKey,
                                controller: controller,
                                focusNode: focusNode,
                                hint: 'City (optional)',
                                textInputAction: TextInputAction.done,
                                enabled: !_isLocked, // <-- lock visual + input
                                readOnly: _isLocked,
                              );
                            },

                            itemBuilder: (context, String city) => ListTile(
                              title: Text(
                                city,
                                style: const TextStyle(color: AppPallete.white),
                              ),
                            ),

                            onSelected: (String city) {
                              _cityTypeaheadCtrl?.text =
                                  city; // free text still allowed
                            },

                            emptyBuilder: (context) => _isLocked
                                ? const SizedBox.shrink()
                                : ListTile(
                                    title: const Text(
                                      'No matches',
                                      style: TextStyle(color: AppPallete.white),
                                    ),
                                    subtitle: Text(
                                      'You are creating: "$_cityName"',
                                      style: const TextStyle(
                                        color: AppPallete.white,
                                      ),
                                    ),
                                  ),

                            suggestionsController: _citySuggestionsCtrl,
                            decorationBuilder: (context, child) => Material(
                              color: AppPallete.black.withValues(alpha: .9),
                              borderRadius: BorderRadius.circular(12),
                              child: child,
                            ),
                            constraints: const BoxConstraints(
                              maxHeight: 280,
                              minWidth: 0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 5),

                        if (_hasClinicText && _isLocked)
                          const Row(
                            children: [
                              Icon(
                                Icons.lock,
                                size: 16,
                                color: AppPallete.white,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Using an existing clinic from database. Province/City are locked. Pick a unique name if those fields require change.',
                                  style: TextStyle(color: AppPallete.white),
                                ),
                              ),
                            ],
                          )
                        else
                          const SizedBox.shrink(),

                        const SizedBox(height: 50),

                        PrimaryButton(label: 'Submit', onPressed: _submit),
                      ],
                    ),
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
