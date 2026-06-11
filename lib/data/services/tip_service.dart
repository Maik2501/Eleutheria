import 'dart:async';
import 'dart:developer' as dev;

import 'package:in_app_purchase/in_app_purchase.dart';

/// Trinkgeld-Käufe ("Spende einen Kaffee") über StoreKit — die App-Store-
/// konforme Ablösung des PayPal-Links (Apple 3.1.1, siehe Audit A3).
///
/// Alle Produkte sind Consumables ohne Gegenleistung außer Dank; die App
/// speichert nichts über Käufe (kein Server-Log, kein Privacy-Label-Eintrag
/// nötig — die Abwicklung liegt komplett bei Apple).
class TipService {
  TipService();

  /// Produkt-IDs wie in App Store Connect angelegt (konsumierbar).
  static const productIds = <String>{
    'de.maikpickl.eleutheria.tip_small',
    'de.maikpickl.eleutheria.tip_medium',
    'de.maikpickl.eleutheria.tip_large',
  };

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  /// Von der Settings-Karte gesetzt, um nach erfolgreichem Kauf zu danken.
  /// Käufe können auch verzögert ankommen (App-Neustart, Ask-to-Buy) —
  /// dann verpufft der Dank einfach, die Transaktion wird trotzdem
  /// abgeschlossen.
  void Function()? onThanks;

  /// Globaler Listener — muss früh im App-Leben starten: StoreKit liefert
  /// unabgeschlossene Transaktionen beim Start erneut, und ohne
  /// completePurchase hängen sie für immer in der Queue.
  void init() {
    _sub ??= _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) {
        dev.log('purchase stream error: $e', name: 'TipService');
      },
    );
  }

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      if (p.status == PurchaseStatus.purchased) {
        onThanks?.call();
      }
      if (p.pendingCompletePurchase) {
        unawaited(_iap.completePurchase(p));
      }
    }
  }

  /// Lädt die Produkte mit lokalisierten Store-Preisen, sortiert nach Preis.
  /// Leere Liste, wenn der Store nicht verfügbar ist oder die Produkte
  /// (noch) nicht in App Store Connect existieren — die UI blendet die
  /// Karte dann aus, genau wie früher beim leeren PayPal-Link.
  Future<List<ProductDetails>> loadProducts() async {
    try {
      if (!await _iap.isAvailable()) return const [];
      final response = await _iap.queryProductDetails(productIds);
      if (response.notFoundIDs.isNotEmpty) {
        dev.log(
          'tip products not found: ${response.notFoundIDs}',
          name: 'TipService',
        );
      }
      return response.productDetails.toList()
        ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    } catch (e) {
      dev.log('loadProducts failed: $e', name: 'TipService');
      return const [];
    }
  }

  Future<void> buy(ProductDetails product) async {
    await _iap.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
