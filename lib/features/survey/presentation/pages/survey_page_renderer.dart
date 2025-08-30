import 'package:casi/features/survey/presentation/pages/survey_instructions_page.dart';
import 'package:casi/features/survey/presentation/pages/survey_thank_you_page.dart';
import 'package:casi/features/survey/presentation/widgets/numeric_stepper_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:casi/core/theme/app_pallete.dart';
import 'package:casi/core/widgets/primary_button.dart';

import 'package:casi/core/user/cubit/user_cubit.dart';
import 'package:casi/core/user/cubit/user_state.dart';

import 'package:casi/features/survey/presentation/bloc/survey_bloc.dart';
import 'package:casi/features/survey/domain/entities/survey_page.dart';
import 'package:casi/features/survey/domain/entities/input_config.dart';

import 'package:casi/features/survey/presentation/widgets/yes_no_toggle.dart';
import 'package:casi/features/survey/presentation/widgets/segmented_toggle.dart';

class SurveyPageRenderer extends StatefulWidget {
  final VoidCallback exitFlow;
  const SurveyPageRenderer({super.key, required this.exitFlow});

  @override
  State<SurveyPageRenderer> createState() => _SurveyPageRendererState();
}

class _SurveyPageRendererState extends State<SurveyPageRenderer> {
  final bodyKey = GlobalKey<_PageBodyState>();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SurveyBloc, SurveyState>(
      listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
      listener: (context, state) {
        if (state is SurveySubmitted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SurveyThankYouPage(exitFlow: widget.exitFlow),
            ),
          );
        }
        if (state is SurveyError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        if (state is! SurveyLoaded) {
          return const Scaffold(body: SizedBox.shrink());
        }

        final inst = state.instance;
        final tmpl = state.template;
        final index = state.currentIndex.clamp(0, tmpl.order.length - 1);
        final pageId = tmpl.order[index];

        // Resolve page safely, can't use orELse here due to list invariance
        late final SurveyPage page;
        final hasPage = tmpl.pages.any((p) => p.id == pageId);
        page = hasPage
            ? tmpl.pages.firstWhere((p) => p.id == pageId)
            : SurveyPage(id: pageId, kind: '', title: pageId, inputs: const []);

        final Map<String, dynamic> pageAnswers = Map<String, dynamic>.from(
          state.answers[page.id] ?? {},
        );

        return PopScope(
          canPop: false,
          child: Scaffold(
            appBar: AppBar(
              title: Text("${inst.quarterId} Survey"),
              leading: IconButton(
                onPressed: () {
                  if (index > 0) {
                    context.read<SurveyBloc>().add(GoToPageEvent(index - 1));
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              actions: [
                IconButton(
                  tooltip: 'Instructions & Terms',
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SurveyInstructionsPage(
                          exitFlow: () => Navigator.of(context).pop(),
                          returnToIndex: index,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: _PageBody(
                      key: bodyKey,
                      page: page,
                      pageAnswers: pageAnswers,
                      pageIndex: index,
                      totalPages: tmpl.order.length,
                    ),
                  ),
                ),
              ),
            ),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BottomBar(
                    index: index,
                    total: tmpl.order.length,
                    validateCurrentPage: () =>
                        bodyKey.currentState?.validatePage() ?? true,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${index + 1}/${tmpl.order.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PageBody extends StatefulWidget {
  final SurveyPage page;
  final Map<String, dynamic> pageAnswers;
  final int pageIndex;
  final int totalPages;

  const _PageBody({
    super.key,
    required this.page,
    required this.pageAnswers,
    required this.pageIndex,
    required this.totalPages,
  });

  static const double kQuestionGap = 25;
  static const double kLabelToControl = 15;

  @override
  State<_PageBody> createState() => _PageBodyState();
}

class _PageBodyState extends State<_PageBody> {
  final _formKey = GlobalKey<FormState>();

  // Per-input error text. We keep this local because our widgets are custom.
  final Map<String, String?> _errors = {};

  // for slider, local int cache
  final Map<String, int> _liveInts = {};

  @override
  void didUpdateWidget(covariant _PageBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page.id != widget.page.id) {
      _errors.clear(); // keep error UX clean between pages
      _liveInts.clear(); // drop any live slider cache
    }
  }

  void _clearError(String id) {
    if (_errors.containsKey(id)) setState(() => _errors.remove(id));
  }

  bool _evalShowIf(InputConfig question, Map<String, dynamic> answers) {
    if (question.showIf == null || question.showIf!.isEmpty) return true;
    for (final entry in question.showIf!.entries) {
      final ans = answers[entry.key];
      if (ans != entry.value) return false;
    }
    return true;
  }

  bool _evalLockIf(InputConfig question, Map<String, dynamic> answers) {
    if (question.lockIf == null || question.lockIf!.isEmpty) return false;
    for (final entry in question.lockIf!.entries) {
      final ans = answers[entry.key];
      if (ans == entry.value) return true;
    }
    return false;
  }

  /// If the YES/NO (boolean) with id [boolId] is set to NO (false),
  /// reset any numeric dependents on this page to 0 so they don't
  /// keep stale values while locked/hidden.
  void _resetNumericDependentsIfNo({
    required BuildContext context,
    required String boolId,
    required bool? value,
  }) {
    if (value != false) return;
    final bloc = context.read<SurveyBloc>();

    for (final dep in widget.page.inputs) {
      final isNumeric = dep.type == 'int';
      if (!isNumeric) continue;

      final dependsOnLock =
          dep.lockIf != null &&
          dep.lockIf!.entries.any((e) => e.key == boolId && e.value == false);

      // also clear ones that show only when YES (so turning NO hides them)
      final dependsOnShowIf =
          dep.showIf != null &&
          dep.showIf!.entries.any((e) => e.key == boolId && e.value == true);

      if (dependsOnLock || dependsOnShowIf) {
        bloc.add(UpdateAnswerEvent(widget.page.id, dep.id, 0));
        _liveInts.remove(
          dep.id,
        ); //clear any live cache so UI shows 0 immediately
      }
    }
  }

  // helper: is this slider > 0 ?
  bool _isNonZeroSliderValue(Map<String, dynamic> answers, String id) {
    final v = answers[id];
    // if v is null or not a num, treat as 0
    return v is num && v > 0;
  }

  bool validatePage() {
    _errors.clear();

    final answers = widget.pageAnswers;
    final inputs = widget.page.inputs
        .where((question) => _evalShowIf(question, answers))
        .toList();

    // -- YES/NO (always required if present) ------------------------------
    final yesNoCandidates = inputs
        .where(
          (question) => question.type == 'yesno' || question.type == 'boolean',
        )
        .toList();

    final hasYesNo = yesNoCandidates.isNotEmpty;
    final yesNo = hasYesNo ? yesNoCandidates.first : null;
    final bool? yesNoVal = hasYesNo ? (answers[yesNo!.id] as bool?) : null;

    if (hasYesNo && yesNoVal == null) {
      _errors[yesNo!.id] = 'Please choose Yes or No.';
    }

    // -- Sliders on the page ---------------------------------------------
    final sliders = inputs.where((question) => question.type == 'int').toList();

    if (sliders.isNotEmpty) {
      if (!hasYesNo) {
        // Dog Census: at least one slider must be non-zero
        final hasNonZero = sliders.any(
          (question) => _isNonZeroSliderValue(answers, question.id),
        );
        if (!hasNonZero) {
          _errors[sliders.first.id] = 'Please enter a non-zero value.';
        }
      } else if (yesNoVal == true) {
        // Has YES/NO and answer is YES: at least one slider must be > 0
        final hasNonZero = sliders.any(
          (question) => _isNonZeroSliderValue(answers, question.id),
        );
        if (!hasNonZero) {
          _errors[sliders.first.id] = sliders.length > 1
              ? 'Please enter at least one non-zero value in confirmed or suspected.'
              : 'Please enter a non-zero value.';
        }
      } else {
        // Has YES/NO and answer is NO: no requirement
      }
    }

    setState(() {}); // refresh error rendering
    return _errors.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SurveyBloc>();

    // Build only question blocks
    final List<Widget> questionBlocks = [];

    final visible = widget.page.inputs
        .where((c) => _evalShowIf(c, widget.pageAnswers))
        .toList();

    for (final question in widget.page.inputs) {
      if (!_evalShowIf(question, widget.pageAnswers)) continue;

      final locked = _evalLockIf(question, widget.pageAnswers);
      final current = widget.pageAnswers[question.id];

      Widget control;

      String? firstSliderId;
      for (final i in visible) {
        if (i.type == 'int') {
          firstSliderId = i.id;
          break;
        }
      }

      switch (question.type) {
        case 'boolean':
          control = YesNoToggle(
            value: (current is bool) ? current : null,
            onChanged: locked
                ? null
                : (bool? v) {
                    bloc.add(UpdateAnswerEvent(widget.page.id, question.id, v));

                    // if NO, clear dependent numeric sliders on this page
                    _resetNumericDependentsIfNo(
                      context: context,
                      boolId: question.id,
                      value: v,
                    );

                    // Clear errors
                    if (v != null) {
                      _clearError(question.id);
                    }

                    if (v == false && firstSliderId != null) {
                      _clearError(firstSliderId);
                    }
                  },
            errorText: _errors[question.id],
          );
          break;

        case 'enum':
          final opts =
              question.options ?? const ['increasing', 'same', 'decreasing'];
          control = SegmentedToggle<String>(
            value: (current is String && opts.contains(current))
                ? current
                : null,
            options: opts
                .map((s) => SegmentedOption(label: _labelCase(s), value: s))
                .toList(),
            onChanged: locked
                ? null
                : (String? v) => bloc.add(
                    UpdateAnswerEvent(widget.page.id, question.id, v),
                  ),
          );
          break;

        case 'multiline':
          control = TextFormField(
            key: ValueKey('tf_${widget.page.id}_${question.id}'),
            enabled: !locked,
            initialValue: (current is String) ? current : '',
            maxLines: 20,
            decoration: _boxDecoration(),
            onChanged: (v) =>
                bloc.add(UpdateAnswerEvent(widget.page.id, question.id, v)),
          );
          break;

        case 'int':
        default:
          {
            final min = question.min ?? 0;
            final max = question.max ?? 500;

            // read the answered value from the bloc (fallback to min)
            final currentAnswer = (widget.pageAnswers[question.id] is num)
                ? (widget.pageAnswers[question.id] as num).toInt()
                : min;

            // while dragging use the “live” cache; otherwise use the answered value
            final live = _liveInts[question.id] ?? currentAnswer;

            control = NumericStepperSlider(
              key: ValueKey('num_${widget.page.id}_${question.id}'),
              min: min,
              max: max,
              value: live,
              enabled: !locked,
              step: 1,
              errorText: _errors[question.id],
              // FAST: update only local state during drag (no Bloc calls)
              onChanged: (v) {
                setState(() => _liveInts[question.id] = v);
                if (v > 0 && firstSliderId != null) _clearError(firstSliderId);
              },
              // COMMIT: one Bloc update when user releases
              onChangeEnd: (v) {
                _liveInts.remove(
                  question.id,
                ); // we’ve committed it; no need to keep the cache
                bloc.add(UpdateAnswerEvent(widget.page.id, question.id, v));
              },
            );
            break;
          }
      }

      questionBlocks.add(
        _QuestionBlock(
          label: question.label,
          labelToControlGap: _PageBody.kLabelToControl,
          child: control,
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          Text(
            widget.page.title,
            style: const TextStyle(
              color: AppPallete.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          // Questions with equal spacing
          ..._intersperse(
            questionBlocks,
            const SizedBox(height: _PageBody.kQuestionGap),
          ),
        ],
      ),
    );
  }

  String _labelCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  InputDecoration _boxDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppPallete.black.withValues(alpha: .08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white),
      ),
      contentPadding: const EdgeInsets.all(12),
    );
  }

  /// Utility to put a separator between items
  List<Widget> _intersperse(List<Widget> widgets, Widget separator) {
    if (widgets.isEmpty) return [];
    return [
      for (int i = 0; i < widgets.length; i++) ...[
        widgets[i],
        if (i < widgets.length - 1) separator,
      ],
    ];
  }
}

/// A consistent “question” block: label + inner spacing + content.
class _QuestionBlock extends StatelessWidget {
  final String label;
  final Widget child;
  final double labelToControlGap;

  const _QuestionBlock({
    required this.label,
    required this.child,
    this.labelToControlGap = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 18, height: 1.35)),
        SizedBox(height: labelToControlGap),
        child,
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int index;
  final int total;
  final bool Function() validateCurrentPage;

  const _BottomBar({
    required this.index,
    required this.total,
    required this.validateCurrentPage,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = index >= total - 1;
    final bloc = context.read<SurveyBloc>();

    return Row(
      children: [
        Expanded(
          child: PrimaryButton(
            label: isLast ? 'Submit' : 'Next',
            onPressed: () {
              if (!validateCurrentPage()) return;
              if (isLast) {
                final userState = context.read<UserCubit>().state;
                final uid = (userState is UserReady)
                    ? userState.user.uid
                    : null;
                if (uid != null) {
                  bloc.add(
                    SubmitSurveyEvent(uid),
                  ); // listener will route to Thank You when done
                }
              } else {
                // Navigate first, then fire a background draft save
                bloc.add(GoToPageEvent(index + 1));
                final userState = context.read<UserCubit>().state;
                final uid = (userState is UserReady)
                    ? userState.user.uid
                    : null;
                if (uid != null) {
                  context.read<SurveyBloc>().add(SaveDraftEvent(uid));
                }
              }
            },
          ),
        ),
      ],
    );
  }
}
