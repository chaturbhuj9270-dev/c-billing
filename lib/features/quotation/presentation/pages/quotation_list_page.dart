import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/ui/glassy_toast.dart';
import '../../data/services/quotation_print_service.dart';
import '../../offline/controllers/quotation_offline_controller.dart';
import '../../offline/entities/quotation_entity.dart';
import 'quotation_screen.dart';
import 'quotation_settings_page.dart';
import 'package:c_billing/common_widgets/app_top_bar.dart';
import 'package:c_billing/common_widgets/glass_bottom_sheet.dart';
import 'package:c_billing/core/theme/app_theme.dart';
import 'package:c_billing/core/ui/desktop_canvas.dart';

/// Lets the desktop shell header open a new quotation.
class QuotationScreenActions {
  static VoidCallback? add;
}

class QuotationListPage extends StatefulWidget {
  final bool isEmbedded;

  const QuotationListPage({super.key, this.isEmbedded = false});

  @override
  State<QuotationListPage> createState() => _QuotationListPageState();
}

class _QuotationListPageState extends State<QuotationListPage> {
  Color get _primary => AppColors.action(context);
  late AppLocalizations _l10n;
  StreamSubscription<List<QuotationEntity>>? _subscription;
  List<QuotationEntity> _quotations = [];
  bool _isLoading = true;
  String? _printingQuotationKey;

  @override
  void initState() {
    super.initState();
    _l10n = AppLocalizations.of(LanguageService.instance.currentLanguage);
    QuotationScreenActions.add = () => _openQuotation();
    _subscription = QuotationOfflineController.instance
        .watchAllQuotations()
        .listen((items) {
          if (!mounted) return;
          setState(() {
            _quotations = items;
            _isLoading = false;
          });
        });
  }

  @override
  void dispose() {
    QuotationScreenActions.add = null;
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _printQuotation(QuotationEntity entity) async {
    final key = '${entity.id}_${entity.quotationNumber}';
    if (_printingQuotationKey != null) return;

    setState(() => _printingQuotationKey = key);
    try {
      await QuotationPrintService.instance.showQuotationPdfPreview(
        context: context,
        quotation: entity.toDomain(),
        localizations: _l10n,
      );
    } finally {
      if (mounted) setState(() => _printingQuotationKey = null);
    }
  }

  Future<void> _openQuotation({QuotationEntity? entity}) async {
    final result = await showAppPage<bool>(
      context,
      QuotationScreen(existing: entity?.toDomain()),
    );
    if (result == true && mounted) {
      GlassyToast.show(
        context,
        entity == null ? _l10n.quotationSaved : _l10n.quotationUpdated,
      );
    }
  }

  Color _typeColor(int type) {
    switch (type) {
      case 0:
        return AppTheme.blue;
      case 1:
        return AppTheme.purple;
      default:
        return AppTheme.teal600;
    }
  }

  String _typeLabel(int type) {
    switch (type) {
      case 0:
        return _l10n.productsOnly;
      case 1:
        return _l10n.eventOnly;
      default:
        return _l10n.eventAndProducts;
    }
  }

  @override
  Widget build(BuildContext context) {
    _l10n = AppLocalizations.of(LanguageService.instance.currentLanguage);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      floatingActionButton:
          widget.isEmbedded && DesktopCanvas.isDesktopPlatform
          ? null
          : FloatingActionButton.extended(
        onPressed: () => _openQuotation(),
        backgroundColor: _primary,
        icon: const Icon(Icons.add_rounded, color: AppTheme.white),
        label: Text(
          _l10n.newQuotation,
          style: const TextStyle(
            fontFamily: 'Literata',
            color: AppTheme.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          if (!widget.isEmbedded)
          AppTopBar(
            title: _l10n.quotations,
            actions: [
              AppTopBar.action(
                icon: Icons.settings_rounded,
                onTap: () {
                  showAppPage(context, const QuotationSettingsPage());
                },
              ),
            ],
          )
          else
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: AppTopBar.action(
                  icon: Icons.settings_rounded,
                  onTap: () {
                    showAppPage(context, const QuotationSettingsPage());
                  },
                ),
              ),
            ),
          Expanded(child: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: _primary),
            )
          : _quotations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.request_quote_rounded,
                    size: 72,
                    color: _primary.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _l10n.noQuotationsFound,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.grey700,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: _quotations.length,
              itemBuilder: (context, index) {
                final item = _quotations[index];
                final domain = item.toDomain();
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  color: AppColors.card(context),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openQuotation(entity: item),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  domain.title,
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: _primary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _typeColor(
                                    item.quotationType,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _typeLabel(item.quotationType),
                                  style: TextStyle(
                                    fontFamily: 'Literata',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _typeColor(item.quotationType),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            domain.customerName,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 13,
                              color: AppTheme.grey600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                domain.quotationNumber,
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontSize: 12,
                                  color: AppTheme.grey,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '₹${domain.totalAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontFamily: 'Literata',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: _primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_l10n.eventOrderDate}: ${dateFormat.format(domain.referenceDate)}',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 11,
                              color: AppTheme.grey,
                            ),
                          ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _printingQuotationKey ==
                                '${item.id}_${item.quotationNumber}'
                            ? Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _primary,
                                    ),
                                  ),
                                ),
                              )
                            : GestureDetector(
                                onTap: () => _printQuotation(item),
                                child: Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.chipFill(context),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.print_rounded,
                                    size: 16,
                                    color: AppTheme.grey600,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
