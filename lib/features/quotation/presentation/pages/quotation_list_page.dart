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

class QuotationListPage extends StatefulWidget {
  const QuotationListPage({super.key});

  @override
  State<QuotationListPage> createState() => _QuotationListPageState();
}

class _QuotationListPageState extends State<QuotationListPage> {
  static const _primary = Color(0xFF1B4D3E);
  late AppLocalizations _l10n;
  StreamSubscription<List<QuotationEntity>>? _subscription;
  List<QuotationEntity> _quotations = [];
  bool _isLoading = true;
  String? _printingQuotationKey;

  @override
  void initState() {
    super.initState();
    _l10n = AppLocalizations.of(LanguageService.instance.currentLanguage);
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
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QuotationScreen(existing: entity?.toDomain()),
      ),
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
        return const Color(0xFF2196F3);
      case 1:
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF00897B);
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
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: _primary,
              size: 18,
            ),
          ),
        ),
        title: Text(
          _l10n.quotations,
          style: const TextStyle(
            fontFamily: 'Literata',
            fontWeight: FontWeight.w800,
            color: _primary,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const QuotationSettingsPage(),
                ),
              );
            },
            tooltip: _l10n.quotationSettings,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.settings_rounded,
                color: _primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openQuotation(),
        backgroundColor: _primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          _l10n.newQuotation,
          style: const TextStyle(
            fontFamily: 'Literata',
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
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
                      color: Colors.grey[700],
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
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  color: Colors.white,
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
                                  style: const TextStyle(
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
                              color: Colors.grey[600],
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
                                  color: Colors.grey[500],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '₹${domain.totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
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
                            '${_l10n.validUntil}: ${dateFormat.format(domain.validUntil)}',
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _printingQuotationKey ==
                                '${item.id}_${item.quotationNumber}'
                            ? const Padding(
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
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.print_rounded,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
