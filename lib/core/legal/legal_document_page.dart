import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_store_config.dart';
import '../theme/app_theme.dart';
import '../../common_widgets/app_top_bar.dart';

class LegalDocumentPage extends StatelessWidget {
  final String title;
  final String body;
  final String? webUrl;

  const LegalDocumentPage({
    super.key,
    required this.title,
    required this.body,
    this.webUrl,
  });

  Future<void> _openWeb() async {
    final raw = webUrl;
    if (raw == null || raw.isEmpty) return;
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Column(
        children: [
          AppTopBar(title: title, subtitle: AppStoreConfig.appName),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (webUrl != null) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _openWeb,
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: const Text('Open on web'),
                      ),
                    ),
                  ],
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Text(
                      body,
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 13.5,
                        height: 1.45,
                        color: AppColors.primaryText(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
