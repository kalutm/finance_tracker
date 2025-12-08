// sms_service.dart
//
// Drop this file into your project (suggested path):
// lib/features/transactions/services/sms_service.dart
//
// Real-time listener + Inbox fallback integrated.
// See comments for usage.

import 'dart:async';
import 'dart:convert';
import 'package:finance_frontend/features/accounts/domain/entities/account.dart';
import 'package:finance_frontend/features/accounts/domain/entities/account_type_enum.dart';
import 'package:finance_frontend/features/accounts/domain/entities/dtos/account_create.dart';
import 'package:finance_frontend/features/accounts/domain/service/account_service.dart';
import 'package:finance_frontend/features/auth/domain/services/secure_storage_service.dart';
import 'package:finance_frontend/features/transactions/domain/entities/transaction_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony_fix/telephony.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

// Import your project's transaction service + DTOs
import 'package:finance_frontend/features/transactions/domain/service/transaction_service.dart';
import 'package:finance_frontend/features/transactions/data/model/dtos/transaction_create.dart';

/// Minimal parsed transaction model used inside this service
class ParsedTransaction {
  final String id; // internal uuid
  final String amount;
  final String merchant; // empty if unknown
  final bool debit; // true = expense, false = income
  final DateTime occuredAt;
  final String source; // e.g., 'cbe_sms' | 'telebirr_sms'
  String? transactionRef; // e.g., CL55OHQFK3 or FT2534... - used for dedupe
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
/// smsService.onParsedTransaction = (parsed) async { return true; };
/// smsService.start();
class SmsService {
  final Telephony _telephony = Telephony.instance;
  final TransactionService transactionService;
  final AccountService accountService;
  final SecureStorageService secureStorageService;
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

  // in-memory cache of seen keys (fast check to avoid races)
  final Set<String> _seenCache = {};

  // small guard so we persist seen keys less often (debounce)
  Timer? _persistSeenTimer;

  // config keys
  static const _kSeenTxKey = 'sms_seen_tx_refs_v1';
  static const _kLastInboxSyncKey = 'sms_last_inbox_sync_v1';

  // cbe and telebirr id's
  String? cbeId;
  String? teleId;

  SmsService({
    required this.transactionService,
    required this.accountService,
    required this.secureStorageService,
    Duration dedupeRetention = const Duration(days: 7),
  }) : _dedupeRetention = dedupeRetention;

  /// Call once during app init (async)
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // warm in-memory cache from persisted map
    try {
      final mapStr = _prefs.getString(_kSeenTxKey);
      if (mapStr != null) {
        final Map<String, dynamic> map = jsonDecode(mapStr) as Map<String, dynamic>;
        _seenCache.addAll(map.keys);
      }
    } catch (_) {
      // ignore
    }

    await _createSetUpAccounts();
    await _fetchCbeAndTelebirrIds();
    // cleanup old entries if any
    _cleanupOldSeenTxRefs();
    // attempt to flush retry queue when connectivity changes to online
    _connectivity.onConnectivityChanged.listen((results) {
      // newer connectivity_plus returns ConnectivityResult (single) — but some APIs may differ
      try {
        final hasConnection = results.any((c) => c == ConnectivityResult.mobile) ||
            results.any((c) => c == ConnectivityResult.wifi) ||
            results.any((c) => c == ConnectivityResult.ethernet);
        if (hasConnection) {
          _flushRetryQueue();
        }
      } catch (_) {
        // in case results is List<ConnectivityResult> (older/newer plugin variations), handle that
          final iter = results as Iterable;
          final has = iter.any((r) => r != ConnectivityResult.none);
          if (has) _flushRetryQueue();
      }
    });
  }

  Stream<ParsedTransaction> get parsedStream => _parsedStreamCtrl.stream;

  // corrected: fetch stored ids from secure storage (and keep them if present)
  Future<void> _fetchCbeAndTelebirrIds() async {
    try {
      final cbId = await secureStorageService.readString(key: "cbe_account_id");
      final teId = await secureStorageService.readString(
        key: "tele_account_id",
      );
      if (cbId != null && cbId.isNotEmpty) {
        cbeId = cbId;
      }
      if (teId != null && teId.isNotEmpty) {
        teleId = teId;
      }
      debugPrint('SmsService: fetched stored ids cbe=$cbeId tele=$teleId');
    } catch (e) {
      debugPrint('SmsService: failed to fetch stored ids: $e');
    }
  }

  Future<void> _createSetUpAccounts() async {
    try {
      // get latest snapshot of accounts (await first/last event; choose appropriate for your stream)
      final accounts = await accountService.accountsStream.first;

      // Try to find existing accounts
      final existingCbe = accounts.firstWhere(
        (a) => a.name.toLowerCase() == "cbe",
        orElse:
            () => Account(
                  id: "",
                  balance: "",
                  name: "",
                  type: AccountType.values.first,
                  currency: "",
                  active: false,
                  createdAt: DateTime.now(),
                ),
      );
      final existingTele = accounts.firstWhere(
        (a) => a.name.toLowerCase() == "telebirr",
        orElse:
            () => Account(
                  id: "",
                  balance: "",
                  name: "",
                  type: AccountType.values.first,
                  currency: "",
                  active: false,
                  createdAt: DateTime.now(),
                ),
      );

      if (existingCbe.id.isNotEmpty) {
        cbeId = existingCbe.id;
        // persist if not already saved
        await secureStorageService.saveString(
          key: "cbe_account_id",
          value: existingCbe.id,
        );
      }
      if (existingTele.id.isNotEmpty) {
        teleId = existingTele.id;
        await secureStorageService.saveString(
          key: "tele_account_id",
          value: existingTele.id,
        );
      }

      // If either missing, create them
      if (existingCbe.id.isEmpty) {
        final cbeAccount = await accountService.createAccount(
          AccountCreate(name: "CBE", type: AccountType.BANK, currency: "ETB"),
        );
        cbeId = cbeAccount.id;
        await secureStorageService.saveString(
          key: "cbe_account_id",
          value: cbeId!,
        );
      }

      if (existingTele.id.isEmpty) {
        final telebirrAccount = await accountService.createAccount(
          AccountCreate(
            name: "telebirr",
            type: AccountType.WALLET,
            currency: "ETB",
          ),
        );
        teleId = telebirrAccount.id;
        await secureStorageService.saveString(
          key: "tele_account_id",
          value: teleId!,
        );
      }

      debugPrint('SmsService: accounts ready cbe=$cbeId tele=$teleId');
    } catch (e, st) {
      debugPrint('SmsService: _createSetUpAccounts failed: $e\n$st');
    }
  }

  /// Start listening to incoming SMS. Should be called after init().
  /// Note: on Android you must add RECEIVE_SMS/READ_SMS permission to AndroidManifest and configure background.
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
        // Defensive: message.date may be int (ms since epoch) or null
        final smsDate = _smsMessageDateToDateTime(message);
        _handleSms(message.body ?? '', smsDate);
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
    _persistSeenTimer?.cancel();
  }

  // -------------------------
  // Inbox fallback: public API
  // Call this when app resumes or on user pull-to-refresh.
  // -------------------------
  Future<void> syncInboxOnResume({int limit = 50}) async {
    try {
      final granted = await _telephony.requestPhoneAndSmsPermissions;
      if (granted != true) {
        debugPrint(
          'SmsService: SMS permission not granted - cannot sync inbox',
        );
        return;
      }

      // fetch last sync millis (defaults to 0 to process all messages once)
      final lastSyncMillis = _prefs.getInt(_kLastInboxSyncKey) ?? 0;
      debugPrint('SmsService: syncInboxOnResume (lastSync=$lastSyncMillis)');

      // fetch inbox messages
      final List<SmsMessage> inbox = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      );

      if (inbox.isEmpty) {
        debugPrint('SmsService: inbox empty');
        // update last sync timestamp if none (avoid scanning repeatedly)
        await _prefs.setInt(
          _kLastInboxSyncKey,
          DateTime.now().millisecondsSinceEpoch,
        );
        return;
      }

      // convert/normalize date values and sort ascending (oldest first)
      final List<_MsgWrapper> wrapped =
          inbox.map((m) {
            final millis = _smsMessageDateToMillis(m);
            return _MsgWrapper(msg: m, dateMillis: millis);
          }).toList();

      wrapped.sort((a, b) => a.dateMillis.compareTo(b.dateMillis));

      int newestProcessed = lastSyncMillis;
      int processedCount = 0;

      final List<String> unparsedSamples = [];

      for (final w in wrapped) {
        if (w.dateMillis <= lastSyncMillis) continue; // already processed previously

        final body = w.msg.body ?? '';
        final smsDate = DateTime.fromMillisecondsSinceEpoch(w.dateMillis);

        final parsed = _parseForBanks(body, smsDate);
        if (parsed == null) {
          if (unparsedSamples.length < 10) {
            unparsedSamples.add('date:${smsDate.toIso8601String()} addr:${w.msg.address} body:$body');
          }
          continue; // not a transaction message
        }

        final dedupeKey = _dedupeKeyFor(parsed);

        // fast in-memory check + reserve the key to prevent race conditions
        if (_seenCache.contains(dedupeKey)) {
          debugPrint('SmsService: inbox duplicate (cache) ignored (key=$dedupeKey)');
          if (w.dateMillis > newestProcessed) newestProcessed = w.dateMillis;
          continue;
        }
        // reserve immediately (persist will follow in _markSeen)
        _seenCache.add(dedupeKey);

        // attempt to create (same behavior as realtime: mark seen regardless,
        // and queue on failure)
        final sent = await _attemptCreate(parsed);
        if (sent) {
          await _markSeen(dedupeKey);
          processedCount++;
        } else {
          _retryQueue.add(parsed);
          // mark seen to avoid repeated duplicate attempts from same SMS
          await _markSeen(dedupeKey);
          debugPrint(
            'SmsService: inbox message queued for retry (${parsed.id})',
          );
        }

        if (w.dateMillis > newestProcessed) newestProcessed = w.dateMillis;
      }

      if (unparsedSamples.isNotEmpty) {
        debugPrint('SmsService: sample unparsed messages (first ${unparsedSamples.length}):');
        for (final s in unparsedSamples) debugPrint(s);
      }

      // persist newest processed timestamp so we only process newer messages later
      await _prefs.setInt(_kLastInboxSyncKey, newestProcessed);

      debugPrint(
        'SmsService: sync complete. processed=$processedCount, newestProcessed=$newestProcessed',
      );
    } catch (e, st) {
      debugPrint('SmsService: syncInboxOnResume failed: $e\n$st');
    }
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

    // fast in-memory check + reserve the key to prevent race conditions
    if (_seenCache.contains(dedupeKey)) {
      debugPrint('SmsService: duplicate SMS ignored (cache) (key=$dedupeKey)');
      return;
    }
    // reserve immediately (persist will follow in _markSeen)
    _seenCache.add(dedupeKey);

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
    if (conn.any((c) => c == ConnectivityResult.none)) {
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
  String _cleanAmount(String raw) {
    final cleaned = raw.replaceAll(',', '').replaceAll('ETB', '').trim();
    return cleaned;
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
    final raw = '${p.source}::${p.amount}::${p.merchant}::$minuteTs';
    return base64.encode(utf8.encode(raw));
  }


  Future<void> _markSeen(String key) async {
    try {
      // fast in-memory add (prevents races)
      _seenCache.add(key);

      // Persist lazily (debounce writes to prefs)
      _persistSeenTimer?.cancel();
      _persistSeenTimer = Timer(const Duration(seconds: 2), () async {
        try {
          final mapStr = _prefs.getString(_kSeenTxKey);
          final Map<String, dynamic> map =
              mapStr == null ? <String, dynamic>{} : jsonDecode(mapStr) as Map<String, dynamic>;
          final nowIso = DateTime.now().toIso8601String();
          for (final k in _seenCache) {
            if (!map.containsKey(k)) {
              map[k] = nowIso;
            }
          }
          await _prefs.setString(_kSeenTxKey, jsonEncode(map));
        } catch (e) {
          debugPrint('SmsService: _markSeen persist failed: $e');
        }
      });
    } catch (e) {
      debugPrint('SmsService: _markSeen error: $e');
    }
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
    final accountId = p.source == "cbe_sms" ? cbeId : teleId;
    if (accountId == null || accountId.isEmpty) {
      // Defensive: if ids are not ready, throw or return a DTO that your service can handle.
      // I recommend throwing so the failure is visible and retries will happen later.
      throw StateError(
        'SmsService: accountId for ${p.source} is not available yet',
      );
    }

    return TransactionCreate(
      amount: p.amount,
      occuredAt: p.occuredAt,
      accountId: accountId,
      currency: "ETB",
      merchant: p.merchant,
      type: p.debit ? TransactionType.EXPENSE : TransactionType.INCOME,
    );
  }

  // -------------------------
  // Utilities
  // -------------------------
  // Convert SmsMessage.date to millis defensively
  int _smsMessageDateToMillis(SmsMessage m) {
    try {
      final dynamic d = m.date;
      if (d == null) return DateTime.now().millisecondsSinceEpoch;
      if (d is int) return d;
      if (d is String) {
        // try parse numeric string
        final parsed = int.tryParse(d);
        if (parsed != null) return parsed;
        // otherwise try parse date string
        final dt = DateTime.tryParse(d);
        if (dt != null) return dt.millisecondsSinceEpoch;
      }
    } catch (_) {}
    return DateTime.now().millisecondsSinceEpoch;
  }

  // Convert to DateTime with fallback
  DateTime _smsMessageDateToDateTime(SmsMessage m) {
    final millis = _smsMessageDateToMillis(m);
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
}

/// Small wrapper for sorting inbox messages
class _MsgWrapper {
  final SmsMessage msg;
  final int dateMillis;
  _MsgWrapper({required this.msg, required this.dateMillis});
}

