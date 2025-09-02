import 'package:casi/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Uri wecahnUri = Uri.parse(
      'https://www.wecahn.ca/wecahn-networks/companion-animal-surveillance-initiative',
    );

    final body = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.4);

    final linkStyle = body?.copyWith(
      decoration: TextDecoration.underline,
      decorationColor: AppPallete.secondary.withAlpha(200),
      color: AppPallete.secondary.withAlpha(200),
      fontWeight: FontWeight.w600,
    );
    final subhead = body?.copyWith(fontWeight: FontWeight.w600);

    return Scaffold(
      appBar: AppBar(title: const Text('Contact')),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          ContextMenuController.removeAny();
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: body,
                      children: [
                        const TextSpan(
                          text:
                              'Thank you again for your participation. Communications regarding '
                              'the Surveillance initiative, including reports, infographics and '
                              'highlights, will be communicated through the ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        // clickable “WeCAHN website”
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: InkWell(
                            onTap: () => launchUrl(
                              wecahnUri,
                              mode: LaunchMode.externalApplication,
                            ),
                            child: Text('WeCAHN website', style: linkStyle),
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text("For questions, email:", style: body),

                  const SizedBox(height: 24),

                  // --- Lead ---
                  Text(
                    "The Surveillance Initiative:",
                    textAlign: TextAlign.center,
                    style: subhead,
                  ),
                  const SizedBox(height: 12),
                  const _EmailRow(email: "compan.surv@usask.ca"),

                  const SizedBox(height: 24),

                  // --- Initiative ---
                  Text(
                    "The Surveillance Lead:",
                    textAlign: TextAlign.center,
                    style: subhead,
                  ),
                  const SizedBox(height: 12),
                  const _EmailRow(email: "tasha.epp@usask.ca"),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailRow extends StatelessWidget {
  final String email;
  const _EmailRow({required this.email});

  Future<void> _composeEmail(BuildContext context) async {
    // Cache anything derived from context BEFORE the await:
    final messenger = ScaffoldMessenger.maybeOf(context);

    final uri = Uri(scheme: 'mailto', path: email);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok) {
      // simulator / no mail client → graceful fallback
      await Clipboard.setData(ClipboardData(text: email));
      messenger?.showSnackBar(
        const SnackBar(content: Text("Couldn't open mail app. Email copied.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _composeEmail(context),
          child: const Icon(Icons.mail, color: AppPallete.white),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: SelectionArea(child: Text(email, style: style)),
        ),
      ],
    );
  }
}
