// sms_service.dart
//
// Drop this file into your project (suggested path):
// lib/features/transactions/services/sms_service.dart
//
// What it does:
// - Requests SMS permissions
// - Listens to incoming SMS (telephony)
// - Parses CBE + Telebirr messages using regexes
// - Emits parsed transactions via a Stream and an optional callback for UI confirmation
// - Performs deduplication using SharedPreferences (persists seen tx refs for N days)
// - Calls your TransactionService.createTransaction(...) to create the transaction remotely
// - Keeps a tiny in-memory retry queue for failed sends
//
// TODO: adapt the toTransactionCreate() helper to match your TransactionCreate DTO fields

import 'dart:async';
import 'dart:convert';
import 'package:telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

// Import your project's transaction service + DTOs
import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_create.dart';

/// Minimal parsed transaction model used inside this service
class ParsedTransaction {
  final String id; // internal uuid
  final double amount;
  final String merchant; // empty if unknown
  final bool debit; // true = expense, false = income
  final DateTime occuredAt;
  final String source; // e.g., 'cbe_sms' | 'telebirr_sms'
  final String?
  transactionRef; // e.g., CL55OHQFK3 or FT2534... - used for dedupe
  final String rawText;

  ParsedTransaction({
    required this.id,
    required this.amount,
    required this.merchant,
    required this.debit,
    required this.occuredAt,
    required this.source,
    this.transactionRef,
    required this.rawText,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'merchant': merchant,
      'debit': debit,
      'occuredAt': occuredAt.toIso8601String(),
      'source': source,
      'transactionRef': transactionRef,
      'rawText': rawText,
    };
  }
}

/// SMSService public API
///
/// Usage:
/// final smsService = SmsService(transactionService: yourTransactionService);
/// await smsService.init();
/// smsService.onParsedTransaction = (parsed) async {
///   // optional: show review dialog to user; return true to proceed with creation
///   return true;
/// };
/// smsService.start();
class SmsService {
  final Telephony _telephony = Telephony.instance;
  final TransactionService transactionService;
  final Duration _dedupeRetention; // how long to keep seen tx refs
  final Connectivity _connectivity = Connectivity();

  // Stream of parsed transactions (before creation)
  final StreamController<ParsedTransaction> _parsedStreamCtrl =
      StreamController.broadcast();

  // Optional callback for UI to confirm creation. If provided, awaited before sending.
  Future<bool> Function(ParsedTransaction parsed)? onParsedTransaction;

  // internal
  late SharedPreferences _prefs;
  bool _listening = false;
  final _uuid = Uuid();

  // in-memory retry queue
  final List<ParsedTransaction> _retryQueue = [];

  // config keys
  static const _kSeenTxKey = 'sms_seen_tx_refs_v1';

  SmsService({
    required this.transactionService,
    Duration dedupeRetention = const Duration(days: 7),
  }) : _dedupeRetention = dedupeRetention;

  /// Call once during app init (async)
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // cleanup old entries if any
    _cleanupOldSeenTxRefs();
    // attempt to flush retry queue when connectivity changes to online
    _connectivity.onConnectivityChanged.listen((results) {
      final hasConnection =
          results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);

      if (hasConnection) {
        _flushRetryQueue();
      }
    });
  }

  Stream<ParsedTransaction> get parsedStream => _parsedStreamCtrl.stream;

  /// Start listening to incoming SMS. Should be called after init().
  /// Note: on Android you must add RECEIVE_SMS permission to AndroidManifest and configure background.
  Future<void> start({bool listenInBackground = true}) async {
    if (_listening) return;
    final granted = await _telephony.requestPhoneAndSmsPermissions;
    if (granted != true) {
      debugPrint('SmsService: SMS permission not granted');
      return;
    }

    // The telephony plugin supports listenInBackground: true with additional setup.
    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        _handleSms(message.body ?? '', DateTime.now());
      },
      listenInBackground: listenInBackground,
    );

    _listening = true;
    debugPrint('SmsService: started (listenInBackground=$listenInBackground)');
  }

  /// Stop listening
  Future<void> stop() async {
    if (!_listening) return;
    // telephony plugin does not currently expose a dedicated stop method.
    // Workaround: you can set a flag and ignore events, but we'll just mark _listening false.
    _listening = false;
    debugPrint('SmsService: stopped');
  }

  void dispose() {
    if (!_parsedStreamCtrl.isClosed) _parsedStreamCtrl.close();
  }

  // -------------------------
  // Internal flow
  // -------------------------
  Future<void> _handleSms(String raw, DateTime smsDate) async {
    if (!_listening) return;

    final text = raw.trim();
    if (text.isEmpty) return;

    // parse for supported banks
    final parsed = _parseForBanks(text, smsDate);
    if (parsed == null) {
      debugPrint('SmsService: could not parse SMS: $text');
      return;
    }

    // dedupe using transactionRef if available; otherwise use a computed hash
    final dedupeKey = _dedupeKeyFor(parsed);
    if (await _isSeen(dedupeKey)) {
      debugPrint('SmsService: duplicate SMS ignored (key=$dedupeKey)');
      return;
    }

    // emit parsed for UI or logs
    _parsedStreamCtrl.add(parsed);

    // if UI callback exists, wait for confirmation (e.g., show dialog)
    if (onParsedTransaction != null) {
      bool shouldProceed = false;
      try {
        shouldProceed = await onParsedTransaction!(parsed);
      } catch (_) {
        shouldProceed = false;
      }
      if (!shouldProceed) {
        debugPrint(
          'SmsService: creation aborted by UI callback for ${parsed.id}',
        );
        return;
      }
    }

    // attempt to send immediately; on failure push to retry queue
    final sent = await _attemptCreate(parsed);
    if (sent) {
      await _markSeen(dedupeKey);
    } else {
      _retryQueue.add(parsed);
      // still mark seen to avoid duplicated attempts from duplicate messages (e.g., telebirr double messages)
      await _markSeen(dedupeKey);
      debugPrint('SmsService: queued for retry (${parsed.id})');
    }
  }

  // Attempt to create via TransactionService; returns true on success.
  Future<bool> _attemptCreate(ParsedTransaction parsed) async {
    // If offline, bail out early
    final conn = await _connectivity.checkConnectivity();
    if (conn == ConnectivityResult.none) {
      debugPrint('SmsService: offline — will retry later');
      return false;
    }

    try {
      final txCreate = _toTransactionCreate(parsed);
      await transactionService.createTransaction(txCreate);
      debugPrint('SmsService: transaction created remotely (${parsed.id})');
      return true;
    } catch (e, st) {
      debugPrint('SmsService: createTransaction failed: $e\n$st');
      return false;
    }
  }

  /// Flush in-memory retry queue: try to resend items (called on connectivity change)
  Future<void> _flushRetryQueue() async {
    if (_retryQueue.isEmpty) return;
    debugPrint('SmsService: flushing retry queue (${_retryQueue.length})');
    final pending = List<ParsedTransaction>.from(_retryQueue);
    for (final p in pending) {
      final ok = await _attemptCreate(p);
      if (ok) {
        _retryQueue.remove(p);
        final key = _dedupeKeyFor(p);
        await _markSeen(key);
      }
    }
  }

  // -------------------------
  // Parsing logic (banks)
  // -------------------------
  ParsedTransaction? _parseForBanks(String body, DateTime smsDate) {
    // try CBE first
    final cbe = _parseCbe(body, smsDate);
    if (cbe != null) return cbe;

    // then Telebirr
    final tele = _parseTelebirr(body, smsDate);
    if (tele != null) return tele;

    return null;
  }

  // Parses CBE sample formats you provided
  ParsedTransaction? _parseCbe(String body, DateTime smsDate) {
    final lower = body.toLowerCase();

    // transactionRef - many messages include FT... or TT... id in the url or text
    final refMatch = RegExp(
      r'\b(FT|TT)\w+\b',
      caseSensitive: false,
    ).firstMatch(body);
    final ref = refMatch?.group(0);

    // CBE: "You have transfered ETB 115.00 to Mussie Belay on 07/12/2025 at 13:54:08"
    final transferRegex = RegExp(
      r'transfer(?:ed|ed)?\s+etb\s*([0-9,]+(?:\.\d+)?)\s+to\s+([A-Za-z0-9 .,\-()]+?)\s+on\s+([0-9/:\s]+)',
      caseSensitive: false,
    );
    final mTransfer = transferRegex.firstMatch(body);
    if (mTransfer != null) {
      final amt = _cleanAmount(mTransfer.group(1)!);
      final merchant = mTransfer.group(2)!.trim();
      final dateStr = mTransfer.group(3)!.trim();
      final dt = _tryParseDate(dateStr, smsDate);
      return ParsedTransaction(
        id: _uuid.v4(),
        amount: amt,
        merchant: merchant,
        debit: true,
        occuredAt: dt,
        source: 'cbe_sms',
        transactionRef: ref,
        rawText: body,
      );
    }

    // CBE credit messages: "has been Credited with ETB 50.00 from Natnael Tigstu"
    final creditRegex = RegExp(
      r'credited\s+with\s+etb\s*([0-9,]+(?:\.\d+)?)(?:\s+from\s+([A-Za-z0-9 .,\-()]+))?',
      caseSensitive: false,
    );
    final mCredit = creditRegex.firstMatch(body);
    if (mCredit != null) {
      final amt = _cleanAmount(mCredit.group(1)!);
      final merchant = (mCredit.group(2) ?? '').trim();
      return ParsedTransaction(
        id: _uuid.v4(),
        amount: amt,
        merchant: merchant,
        debit: false,
        occuredAt: smsDate,
        source: 'cbe_sms',
        transactionRef: ref,
        rawText: body,
      );
    }

    // generic debited: "has been debited with ETB2,000.00" or "has been debited with ETB 210.00"
    final debitedRegex = RegExp(
      r'debited\s+with\s+etb\s*([0-9,]+(?:\.\d+)?)',
      caseSensitive: false,
    );
    final mDeb = debitedRegex.firstMatch(body);
    if (mDeb != null) {
      final amt = _cleanAmount(mDeb.group(1)!);
      return ParsedTransaction(
        id: _uuid.v4(),
        amount: amt,
        merchant: '', // unknown
        debit: true,
        occuredAt: smsDate,
        source: 'cbe_sms',
        transactionRef: ref,
        rawText: body,
      );
    }

    return null;
  }

  // Parses Telebirr formats you provided
  ParsedTransaction? _parseTelebirr(String body, DateTime smsDate) {
    final lower = body.toLowerCase();

    // transaction number e.g., CL55OHQFK3
    final txRefMatch = RegExp(r'\b[A-Z0-9]{6,}\b').firstMatch(body);
    final txRef = txRefMatch?.group(0);

    // paid for goods: "You have paid ETB 217.01 for goods purchased from 506167 - QUEENS SUPER MARKET PLC 4 KILO Branch on 05/12/2025 20:20:15."
    final paidRegex = RegExp(
      r'you have paid\s+etb\s*([0-9,]+(?:\.\d+)?)\s+for\s+goods(?:.*?from\s+([A-Za-z0-9 .,\-()]+?))?\s+on\s+([0-9/:\s]+)',
      caseSensitive: false,
    );
    final mPaid = paidRegex.firstMatch(body);
    if (mPaid != null) {
      final amt = _cleanAmount(mPaid.group(1)!);
      final merchant = (mPaid.group(2) ?? '').trim();
      final dateStr = mPaid.group(3)!.trim();
      final dt = _tryParseDate(dateStr, smsDate);
      return ParsedTransaction(
        id: _uuid.v4(),
        amount: amt,
        merchant: merchant,
        debit: true,
        occuredAt: dt,
        source: 'telebirr_sms',
        transactionRef: txRef,
        rawText: body,
      );
    }

    // transferred: "You have transferred ETB 105.00 to Tesfa Mergia (2519****6334) on 03/12/2025 15:07:16."
    final transferRegex = RegExp(
      r'you have transferred\s+etb\s*([0-9,]+(?:\.\d+)?)\s+to\s+([A-Za-z0-9 .,\-()]+?)\s+on\s+([0-9/:\s]+)',
      caseSensitive: false,
    );
    final mTrans = transferRegex.firstMatch(body);
    if (mTrans != null) {
      final amt = _cleanAmount(mTrans.group(1)!);
      final merchant = mTrans.group(2)!.trim();
      final dateStr = mTrans.group(3)!.trim();
      final dt = _tryParseDate(dateStr, smsDate);
      return ParsedTransaction(
        id: _uuid.v4(),
        amount: amt,
        merchant: merchant,
        debit: true,
        occuredAt: dt,
        source: 'telebirr_sms',
        transactionRef: txRef,
        rawText: body,
      );
    }

    // received: "You have received ETB 160.00 from mokenene teganu(2519****3371) on 29/11/2025 20:07:37."
    final receivedRegex = RegExp(
      r'you have received\s+etb\s*([0-9,]+(?:\.\d+)?)\s+from\s+([A-Za-z0-9 .,\-()]+?)\s+on\s+([0-9/:\s]+)',
      caseSensitive: false,
    );
    final mRecv = receivedRegex.firstMatch(body);
    if (mRecv != null) {
      final amt = _cleanAmount(mRecv.group(1)!);
      final merchant = mRecv.group(2)!.trim();
      final dateStr = mRecv.group(3)!.trim();
      final dt = _tryParseDate(dateStr, smsDate);
      return ParsedTransaction(
        id: _uuid.v4(),
        amount: amt,
        merchant: merchant,
        debit: false,
        occuredAt: dt,
        source: 'telebirr_sms',
        transactionRef: txRef,
        rawText: body,
      );
    }

    // recharge/airtime: "You have recharged ETB 5.00 airtime for 945606894" or "You have received ETB 5.00 airtime from 251945606894"
    final rechargeRegex = RegExp(
      r'(recharged|received)\s+etb\s*([0-9,]+(?:\.\d+)?)\s+airtime(?:.*?for\s+([0-9]+))?',
      caseSensitive: false,
    );
    final mRecharge = rechargeRegex.firstMatch(body);
    if (mRecharge != null) {
      final amt = _cleanAmount(mRecharge.group(2)!);
      final merchant = 'telebirr'; // airtime recharge merchant
      final debit =
          (mRecharge.group(1)!.toLowerCase() == 'recharged'); // usually debit
      return ParsedTransaction(
        id: _uuid.v4(),
        amount: amt,
        merchant: merchant,
        debit: debit,
        occuredAt: smsDate,
        source: 'telebirr_sms',
        transactionRef: txRef,
        rawText: body,
      );
    }

    return null;
  }

  // -------------------------
  // Helpers
  // -------------------------
  double _cleanAmount(String raw) {
    final cleaned = raw.replaceAll(',', '').replaceAll('ETB', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  DateTime _tryParseDate(String candidate, DateTime fallback) {
    // The messages use format dd/MM/yyyy hh:mm:ss (from your examples)
    try {
      // Normalize separators and pad where necessary
      final normalized = candidate.replaceAll(RegExp(r'\s+'), ' ').trim();
      // Try pattern dd/MM/yyyy HH:mm:ss
      final parts = normalized.split(' ');
      if (parts.length >= 2) {
        final datePart = parts[0];
        final timePart = parts[1];
        final dateParts = datePart.split('/');
        final timeParts = timePart.split(':');
        if (dateParts.length == 3 && timeParts.length >= 2) {
          final d = int.parse(dateParts[0]);
          final m = int.parse(dateParts[1]);
          final y = int.parse(dateParts[2]);
          final hh = int.parse(timeParts[0]);
          final mm = int.parse(timeParts[1]);
          final ss = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;
          return DateTime(y, m, d, hh, mm, ss);
        }
      }
    } catch (_) {}
    return fallback;
  }

  String _dedupeKeyFor(ParsedTransaction p) {
    // prefer transactionRef if available (stable id sent by provider)
    if (p.transactionRef != null && p.transactionRef!.isNotEmpty) {
      return '${p.source}::ref::${p.transactionRef}';
    }
    // otherwise compute a hash of amount+merchant+date (date truncated to minute)
    final minuteTs =
        DateTime(
          p.occuredAt.year,
          p.occuredAt.month,
          p.occuredAt.day,
          p.occuredAt.hour,
          p.occuredAt.minute,
        ).toIso8601String();
    final raw = '${p.source}::${p.amount}::${p.merchant}::${minuteTs}';
    return base64.encode(utf8.encode(raw));
  }

  Future<bool> _isSeen(String key) async {
    final mapStr = _prefs.getString(_kSeenTxKey);
    if (mapStr == null) return false;
    try {
      final Map<String, dynamic> map =
          jsonDecode(mapStr) as Map<String, dynamic>;
      if (!map.containsKey(key)) return false;
      final ts = DateTime.parse(map[key] as String);
      final expired = DateTime.now().difference(ts) > _dedupeRetention;
      if (expired) {
        // lazy cleanup
        map.remove(key);
        await _prefs.setString(_kSeenTxKey, jsonEncode(map));
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _markSeen(String key) async {
    try {
      final mapStr = _prefs.getString(_kSeenTxKey);
      final Map<String, dynamic> map =
          mapStr == null
              ? <String, dynamic>{}
              : jsonDecode(mapStr) as Map<String, dynamic>;
      map[key] = DateTime.now().toIso8601String();
      await _prefs.setString(_kSeenTxKey, jsonEncode(map));
    } catch (_) {}
  }

  // cleanup old entries
  void _cleanupOldSeenTxRefs() {
    try {
      final mapStr = _prefs.getString(_kSeenTxKey);
      if (mapStr == null) return;
      final Map<String, dynamic> map =
          jsonDecode(mapStr) as Map<String, dynamic>;
      final now = DateTime.now();
      final keysToRemove = <String>[];
      map.forEach((k, v) {
        try {
          final ts = DateTime.parse(v as String);
          if (now.difference(ts) > _dedupeRetention) keysToRemove.add(k);
        } catch (_) {}
      });
      for (final k in keysToRemove) map.remove(k);
      _prefs.setString(_kSeenTxKey, jsonEncode(map));
    } catch (_) {}
  }

  // -------------------------
  // Mapping to your TransactionCreate DTO
  // -------------------------
  TransactionCreate _toTransactionCreate(ParsedTransaction p) {
    // NOTE: adapt this to your TransactionCreate constructor fields.
    //
    // Typical fields your DTO probably needs:
    // - amount (string or double)
    // - description or merchant
    // - occuredAt / timestamp
    // - accountId (if multiple accounts exist; you may pick default)
    // - currency (e.g., 'ETB')
    //
    // Example (replace to match your actual DTO):
    //
    // return TransactionCreate(
    //   amount: p.amount.toString(),
    //   description: p.merchant.isEmpty ? 'SMS transaction' : p.merchant,
    //   occuredAt: p.occuredAt.toIso8601String(),
    //   accountId: "<your_account_id_here>", // you need to provide default
    //   currency: 'ETB',
    //   type: p.debit ? 'expense' : 'income',
    // );
    //
    // ---- FALLBACK: if your DTO takes a Map or named fields differ, change here ----
    //
    throw UnimplementedError(
      'Adapt _toTransactionCreate() to match your TransactionCreate DTO. See comments in file.',
    );
  }
}
