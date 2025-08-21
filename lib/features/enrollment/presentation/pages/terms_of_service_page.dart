// lib/features/enrollment/presentation/pages/terms_of_service_page.dart
import 'package:casi/core/user/cubit/user_cubit.dart';
import 'package:casi/core/user/cubit/user_state.dart';
import 'package:casi/core/pages/temp_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:casi/core/theme/app_pallete.dart';
import 'package:casi/core/widgets/loader.dart';
import 'package:casi/core/widgets/primary_button.dart';
import 'package:casi/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:casi/features/enrollment/presentation/bloc/enrollment_bloc.dart';

class TermsOfServicePage extends StatefulWidget {
  const TermsOfServicePage({super.key});

  @override
  State<TermsOfServicePage> createState() => _TermsOfServicePageState();
}

class _TermsOfServicePageState extends State<TermsOfServicePage> {
  final _scroll = ScrollController();
  bool _atBottom = false;

  @override
  void initState() {
    super.initState();
    context.read<EnrollmentBloc>().add(const LoadEthicsEvent());

    // Update when the user actually scrolls.
    _scroll.addListener(_updateAtBottom);
  }

  @override
  void dispose() {
    _scroll.removeListener(_updateAtBottom);
    _scroll.dispose();
    super.dispose();
  }

  void _updateAtBottom() {
    if (!_scroll.hasClients) return;
    final m = _scroll.position;

    // If there's nothing to scroll (maxScrollExtent <= 0), treat as "at bottom".
    final atBottom =
        m.maxScrollExtent <= 0 || m.pixels >= (m.maxScrollExtent - 8.0);

    if (_atBottom != atBottom) {
      setState(() => _atBottom = atBottom);
    }
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
    return Scaffold(
      body: BlocConsumer<EnrollmentBloc, EnrollmentState>(
        listener: (context, state) {
          if (state is EnrollmentError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is EthicsAccepted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const TempDashboard()),
              (route) => route.isFirst,
            );
          }
        },
        builder: (context, state) {
          if (state is EnrollmentLoading || state is EnrollmentInitial) {
            return const Loader();
          }
          if (state is! EthicsLoaded) {
            return const SizedBox.shrink();
          }

          final e = state.ethics;

          // IMPORTANT: once EthicsLoaded is on screen, do a post-frame check.
          // This catches the "no scroll" case and flips the UI to show Submit.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _updateAtBottom();
          });

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: AppPallete.white,
                            ),
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'AGREEMENT',
                            style: TextStyle(color: AppPallete.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Bounded card
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppPallete.black.withOpacity(.12),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
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
                                      e.title,
                                      style: const TextStyle(
                                        color: AppPallete.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Last updated on ${e.updatedAt.month}/${e.updatedAt.day}/${e.updatedAt.year}',
                                      style: const TextStyle(
                                        color: AppPallete.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, color: Colors.white24),

                              // Scrollable body
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Scrollbar(
                                    controller: _scroll,
                                    child: SingleChildScrollView(
                                      controller: _scroll,
                                      child: Text(
                                        e.body,
                                        style: const TextStyle(
                                          color: AppPallete.white,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (!_atBottom)
                        PrimaryButton(
                          label: 'Scroll to Bottom',
                          onPressed: () async {
                            if (_scroll.hasClients) {
                              await _scroll.animateTo(
                                _scroll.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                              );
                            }
                            // Force a re-check even if there was nothing to scroll.
                            _updateAtBottom();
                          },
                        )
                      else ...[
                        PrimaryButton(
                          label: 'Accept & Continue',
                          onPressed: _accept,
                        ),
                        const SizedBox(height: 8),
                        PrimaryButton(
                          label: 'Scroll to Top',
                          onPressed: () async {
                            if (_scroll.hasClients) {
                              await _scroll.animateTo(
                                0,
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOut,
                              );
                            }
                            _updateAtBottom();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
