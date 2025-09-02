import 'dart:async';
import 'package:casi/features/survey/presentation/pages/survey_page_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:casi/core/widgets/primary_button.dart';
import 'package:casi/core/widgets/loader.dart';
import 'package:casi/core/theme/app_pallete.dart';
import 'package:casi/features/survey/presentation/bloc/survey_bloc.dart';

class SurveyInstructionsPage extends StatefulWidget {
  final VoidCallback exitFlow;

  /// If not null, this screen was opened as a detour from SurveyPageRenderer.
  /// Continue will pop back to the renderer and restore this page index.
  final int? returnToIndex;
  const SurveyInstructionsPage({
    super.key,
    required this.exitFlow,
    this.returnToIndex,
  });

  @override
  State<SurveyInstructionsPage> createState() => _SurveyInstructionsPageState();
}

class _SurveyInstructionsPageState extends State<SurveyInstructionsPage> {
  final ScrollController _ctrl = ScrollController();
  static const double _nearBottomTolerance = 48;
  static const Duration _debounceDur = Duration(milliseconds: 80);
  bool _isNearBottom = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.removeListener(_onScroll);
    _ctrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_ctrl.hasClients) return;
    final pos = _ctrl.position;
    final max = pos.maxScrollExtent;
    final px = pos.pixels.clamp(0.0, max);
    final near = max <= 0 || px >= (max - _nearBottomTolerance);
    if (near != _isNearBottom) {
      _debounce?.cancel();
      _debounce = Timer(_debounceDur, () {
        if (!mounted || !_ctrl.hasClients) return;
        final px2 = _ctrl.position.pixels.clamp(
          0.0,
          _ctrl.position.maxScrollExtent,
        );
        final near2 =
            _ctrl.position.maxScrollExtent <= 0 ||
            px2 >= (_ctrl.position.maxScrollExtent - _nearBottomTolerance);
        if (near2 != _isNearBottom) {
          setState(() => _isNearBottom = near2);
        }
      });
    }
  }

  Future<void> _scrollToBottom() async {
    if (!_ctrl.hasClients) return;
    await _ctrl.animateTo(
      _ctrl.position.maxScrollExtent,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _scrollToTop() async {
    if (!_ctrl.hasClients) return;
    await _ctrl.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _continue() {
    // If we were opened from the survey page, return to the same index.
    final ret = widget.returnToIndex;
    if (ret != null) {
      context.read<SurveyBloc>().add(GoToPageEvent(ret));
      Navigator.of(context).pop(); // Go back to SurveyPageRenderer
      return;
    }

    // Go to first page and push the renderer.
    context.read<SurveyBloc>().add(const GoToPageEvent(0));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurveyPageRenderer(exitFlow: widget.exitFlow),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instructions & Terms'),
        leading: BackButton(onPressed: widget.exitFlow),
      ),
      body: BlocBuilder<SurveyBloc, SurveyState>(
        builder: (context, state) {
          if (state is SurveyLoading || state is SurveyInitial) {
            return const Loader();
          }
          if (state is SurveyError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: AppPallete.white),
              ),
            );
          }
          if (state is! SurveyLoaded) return const SizedBox.shrink();

          // Use template subtitle as header; real copy can be a page before q0.
          final tmpl = state.template;

          WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppPallete.black.withValues(alpha: .09),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                      tmpl.title,
                                      style: const TextStyle(
                                        color: AppPallete.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      tmpl.subtitle,
                                      style: const TextStyle(
                                        color: AppPallete.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, color: Colors.white24),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: ListView(
                                    controller: _ctrl,
                                    padding: const EdgeInsets.only(bottom: 120),
                                    children: const [
                                      Text(
                                        "Please review these instructions and terms. "
                                        "When you reach the end, the Continue button will appear.",
                                        style: TextStyle(
                                          height: 1.35,
                                          fontSize: 16,
                                        ),
                                      ),

                                      SizedBox(height: 16),

                                      Text(
                                        "INSTRUCTIONS",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      Text(
                                        "This survey is available each quarter. You are asked to report"
                                        " on the reporting quarter, which is always the previous quarter. "
                                        " For example, if you are completing the survey in April - June"
                                        " (Quarter 2), your answers should describe January - March (Quarter 1)."
                                        " The reporting quarter is always shown in the app bar at the top of the"
                                        " screen during the survey (e.g., Q1 2025).",

                                        style: TextStyle(
                                          height: 1.35,
                                          fontSize: 16,
                                        ),
                                      ),

                                      SizedBox(height: 16),

                                      Text(
                                        "You will be asked a series of questions asking whether you think"
                                        " the frequency of YOUR diagnosis of a syndrome or specific pathogen"
                                        " is increasing, decreasing or stable. Each time this is asked, the"
                                        " question is asking about the frequency of diagnosis, in the reporting quarter"
                                        " this year, compared with the same time period (quarter) last year. "
                                        "For example, if you diagnosed 5 cases of a disease this quarter (Jan - Mar 2025)"
                                        " and only 2 cases in the same quarter last year (Jan - Mar 2024), you would select Increasing.",

                                        style: TextStyle(
                                          height: 1.35,
                                          fontSize: 16,
                                        ),
                                      ),

                                      SizedBox(height: 16),

                                      Text(
                                        "Pathogen/Disease Surveillance Case Definitions",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      Text(
                                        "Echinococcus spp.(multilocularis, granulosus)",
                                        style: TextStyle(
                                          height: 1.35,
                                          fontSize: 16,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AppPallete.white,
                                        ),
                                      ),

                                      Text(
                                        "Any urban, rural or free-roaming dog residing in the provinces of BC, AB,"
                                        " SK, or MB with a positive fecal coproantigen ELISA or PCR test result for"
                                        " Echinococcus multilocularis or E. granulosus regardless of clinical signs."
                                        " In the absence of laboratory testing, cases can be considered suspect based"
                                        " solely on clinical presentation.",
                                        style: TextStyle(
                                          height: 1.35,
                                          fontSize: 16,
                                          decorationColor: AppPallete.white,
                                        ),
                                      ),

                                      SizedBox(height: 16),

                                      Text(
                                        "MRSA/MRSP or other antibiotic resistant pathogens",
                                        style: TextStyle(
                                          height: 1.35,
                                          fontSize: 16,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AppPallete.white,
                                        ),
                                      ),

                                      Text(
                                        "Any urban, rural or free-roaming dog residing in the provinces of BC, AB,"
                                        " SK, or MB with a positive MRSA/MRSP result or other pathogen with resistance"
                                        " to one or more antibiotic(s) on culture and sensitivity testing regardless of"
                                        " clinical signs. In the absence of laboratory testing, cases can be considered"
                                        " suspect based solely on clinical presentation or lack of response to treatment.",
                                        style: TextStyle(
                                          height: 1.35,
                                          fontSize: 16,
                                          decorationColor: AppPallete.white,
                                        ),
                                      ),

                                      SizedBox(height: 16),

                                      Text(
                                        "Enteric pathogens (Salmonella spp. Campylobacter spp., E.coli)",
                                        style: TextStyle(
                                          height: 1.35,
                                          fontSize: 16,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AppPallete.white,
                                        ),
                                      ),

                                      Text(
                                        "Any urban, rural or free-roaming dog residing in the provinces of BC, AB,"
                                        " SK, or MB and a positive PCR test or fecal culture for Salmonella spp.,"
                                        " Campylobacter spp., and/or E.coli regardless of clinical signs. In the"
                                        " absence of laboratory testing, cases can be considered suspect based"
                                        " solely on clinical presentation.",
                                        style: TextStyle(
                                          height: 1.35,
                                          fontSize: 16,
                                          decorationColor: AppPallete.white,
                                        ),
                                      ),

                                      SizedBox(height: 16),

                                      Text(
                                        "Borrelia burgdorferi or other vector-borne pathogens",
                                        style: TextStyle(
                                          height: 1.35,
                                          fontSize: 16,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AppPallete.white,
                                        ),
                                      ),

                                      Text(
                                        "Any urban, rural or free-roaming dog residing in the provinces of BC, AB,"
                                        " SK, or MB with a positive in-clinic 4Dx SNAP test or laboratory confirmed"
                                        " positive for Lyme disease (Borrelia burgdorferi) or other vector-borne"
                                        " diseases (i.e. Anaplasma, Erhlichia, etc) regardless of clinical signs."
                                        " In the absence of laboratory testing, cases can be considered suspect based"
                                        " solely on clinical presentation.",
                                        style: TextStyle(
                                          height: 1.35,
                                          fontSize: 16,
                                          decorationColor: AppPallete.white,
                                        ),
                                      ),

                                      SizedBox(height: 16),

                                      Text(
                                        "Leptospira spp",
                                        style: TextStyle(
                                          height: 1.35,
                                          fontSize: 16,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AppPallete.white,
                                        ),
                                      ),

                                      Text(
                                        "Any urban, rural or free-roaming dog residing in the provinces of BC, AB,"
                                        " SK, or MB with a positive PCR assay result from any clinical specimen or"
                                        " a confirmatory MAT titer or a 4-fold rise in MAT titer in an unvaccinated"
                                        " dog or a dog vaccinated ≥ 2 months prior to sample collection. In the absence"
                                        " of laboratory testing, cases can be considered suspect based solely on clinical presentation.",
                                        style: TextStyle(
                                          height: 1.35,
                                          fontSize: 16,
                                          decorationColor: AppPallete.white,
                                        ),
                                      ),

                                      SizedBox(height: 16),

                                      Text(
                                        "Brucella canis",
                                        style: TextStyle(
                                          height: 1.35,
                                          fontSize: 16,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AppPallete.white,
                                        ),
                                      ),

                                      Text(
                                        "Any urban, rural or free-roaming dog residing in the provinces of BC, AB,"
                                        " SK, or MB that is serological positive using RSAT and/or AGID, or isolation"
                                        " of the pathogen regardless of clinical signs. In the absence of laboratory"
                                        " testing, cases can be considered suspect based solely on clinical presentation.",
                                        style: TextStyle(
                                          height: 1.35,
                                          fontSize: 16,
                                          decorationColor: AppPallete.white,
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
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<SurveyBloc, SurveyState>(
        builder: (context, state) {
          if (state is SurveyLoading || state is SurveyInitial) {
            return const SizedBox.shrink();
          }

          return SafeArea(
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
                  maintainSize: true,
                  maintainState: true,
                  maintainAnimation: true,
                  child: PrimaryButton(
                    label: 'Continue',
                    onPressed: _continue,
                    backgroundColor: const Color.fromARGB(225, 22, 143, 255),
                    textColor: AppPallete.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
