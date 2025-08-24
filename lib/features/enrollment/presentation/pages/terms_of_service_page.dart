import 'dart:async';
import 'package:casi/core/user/cubit/user_cubit.dart';
import 'package:casi/core/user/cubit/user_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:casi/core/theme/app_pallete.dart';
import 'package:casi/core/widgets/loader.dart';
import 'package:casi/core/widgets/primary_button.dart';
import 'package:casi/features/enrollment/presentation/bloc/enrollment_bloc.dart';

class TermsOfServicePage extends StatefulWidget {
  const TermsOfServicePage({super.key});

  @override
  State<TermsOfServicePage> createState() => _TermsOfServicePageState();
}

class _TermsOfServicePageState extends State<TermsOfServicePage> {
  final ScrollController _strollControl = ScrollController();

  // px from the end counts as bottom
  static const double _nearBottomTolerance = 48.0;
  static const Duration _debounceDur = Duration(milliseconds: 80);
  bool _isNearBottom = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    context.read<EnrollmentBloc>().add(const LoadEthicsEvent());
    _strollControl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _strollControl.removeListener(_onScroll);
    _strollControl.dispose();
    super.dispose();
  }

  // Robust near-bottom detector with clamping + debounce
  void _onScroll() {
    if (!_strollControl.hasClients) return;

    final pos = _strollControl.position;
    final double max = pos.maxScrollExtent;
    // Clamp to ignore iOS elastic overscroll
    final double px = pos.pixels.clamp(0.0, max);

    // If there's nothing to scroll, treat as “at bottom”
    final bool nearBottom = max <= 0 || px >= (max - _nearBottomTolerance);

    if (nearBottom != _isNearBottom) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(_debounceDur, () {
        if (!mounted || !_strollControl.hasClients) return;
        final double max2 = _strollControl.position.maxScrollExtent;
        final double px2 = _strollControl.position.pixels.clamp(0.0, max2);
        final bool nearBottom2 =
            max2 <= 0 || px2 >= (max2 - _nearBottomTolerance);
        if (nearBottom2 != _isNearBottom) {
          setState(() => _isNearBottom = nearBottom2);
        }
      });
    }
  }

  Future<void> _scrollToBottom() async {
    if (!_strollControl.hasClients) return;
    await _strollControl.animateTo(
      _strollControl.position.maxScrollExtent,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _scrollToTop() async {
    if (!_strollControl.hasClients) return;
    await _strollControl.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _accept() {
    final userState = context.read<UserCubit>().state;
    if (userState is! UserReady) return;

    final st = context.read<EnrollmentBloc>().state;
    if (st is EthicsLoaded) {
      context.read<EnrollmentBloc>().add(
        AcceptEthicsEvent(uid: userState.user.uid, version: st.ethics.version),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const physics = ClampingScrollPhysics(); // reduce iOS bounce

    return Scaffold(
      appBar: AppBar(title: const Text('AGREEMENT')),

      body: BlocConsumer<EnrollmentBloc, EnrollmentState>(
        listener: (context, state) {
          if (state is EnrollmentError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is EnrollmentLoading || state is EnrollmentInitial) {
            return const Loader();
          }
          if (state is! EthicsLoaded) {
            return const SizedBox.shrink();
          }

          final ethics = state.ethics;

          // If content is short, mark as near-bottom right away.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _onScroll();
          });

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      // ---- Card with title/updatedAt and scrollable body ----
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppPallete.black.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Title + updatedAt
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ethics.title,
                                      style: const TextStyle(
                                        color: AppPallete.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Last updated on ${ethics.updatedAt.month}/${ethics.updatedAt.day}/${ethics.updatedAt.year}',
                                      style: const TextStyle(
                                        color: AppPallete.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, color: Colors.white24),

                              // Scrollable Ethics body
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Scrollbar(
                                    controller: _strollControl,
                                    child: ListView(
                                      controller: _strollControl,
                                      physics: physics,
                                      padding: const EdgeInsets.only(
                                        bottom: 120,
                                      ),
                                      children: [
                                        Text(
                                          ethics.body,
                                          style: const TextStyle(
                                            color: AppPallete.white,
                                            height: 1.35,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              label: _isNearBottom ? 'Scroll to Top' : 'Scroll to Bottom',
              onPressed: _isNearBottom ? _scrollToTop : _scrollToBottom,
            ),
            const SizedBox(height: 8),

            Visibility(
              visible: _isNearBottom,
              maintainState: true,
              maintainAnimation: true,
              maintainSize:
                  true, // <- keeps exact height to prevent layout shift i.e flapping
              child: PrimaryButton(
                label: 'Accept & Continue',
                onPressed: _accept,
                backgroundColor: const Color.fromARGB(225, 22, 143, 255),
                textColor: AppPallete.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
