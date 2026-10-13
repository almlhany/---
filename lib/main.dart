import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AlarmApp());
}

const kBg = Color(0xFF0D1117);
const kSurface = Color(0xFF161B22);
const kSurfaceAlt = Color(0xFF21262D);
const kBorder = Color(0xFF30363D);
const kPrimary = Color(0xFF1F6FEB);
const kPrimaryLight = Color(0xFF58A6FF);
const kDanger = Color(0xFFCF222E);
const kText = Color(0xFFE6EDF3);
const kMuted = Color(0xFF8B949E);

String two(int n) => n.toString().padLeft(2, '0');

String time12(int h, int m) {
  final hh = h % 12 == 0 ? 12 : h % 12;
  return '$hh:${two(m)}';
}

String period(int h) => h >= 12 ? '\u0645' : '\u0635';

const Map<int, String> kDayShort = {
  6: '\u0633\u0628\u062a',
  7: '\u0623\u062d\u062f',
  1: '\u0627\u062b\u0646\u064a\u0646',
  2: '\u062b\u0644\u0627\u062b\u0627\u0621',
  3: '\u0623\u0631\u0628\u0639\u0627\u0621',
  4: '\u062e\u0645\u064a\u0633',
  5: '\u062c\u0645\u0639\u0629',
};
const List<int> kDayOrder = [6, 7, 1, 2, 3, 4, 5];
const Map<int, String> kDayFull = {
  1: '\u0627\u0644\u0627\u062b\u0646\u064a\u0646',
  2: '\u0627\u0644\u062b\u0644\u0627\u062b\u0627\u0621',
  3: '\u0627\u0644\u0623\u0631\u0628\u0639\u0627\u0621',
  4: '\u0627\u0644\u062e\u0645\u064a\u0633',
  5: '\u0627\u0644\u062c\u0645\u0639\u0629',
  6: '\u0627\u0644\u0633\u0628\u062a',
  7: '\u0627\u0644\u0623\u062d\u062f',
};
const List<String> kMonths = [
  '\u064a\u0646\u0627\u064a\u0631',
  '\u0641\u0628\u0631\u0627\u064a\u0631',
  '\u0645\u0627\u0631\u0633',
  '\u0623\u0628\u0631\u064a\u0644',
  '\u0645\u0627\u064a\u0648',
  '\u064a\u0648\u0646\u064a\u0648',
  '\u064a\u0648\u0644\u064a\u0648',
  '\u0623\u063a\u0633\u0637\u0633',
  '\u0633\u0628\u062a\u0645\u0628\u0631',
  '\u0623\u0643\u062a\u0648\u0628\u0631',
  '\u0646\u0648\u0641\u0645\u0628\u0631',
  '\u062f\u064a\u0633\u0645\u0628\u0631',
];

Widget clockText(int h, int m, double size, double psize, Color c, Color pc) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(time12(h, m),
            style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w300,
                color: c,
                height: 1.1)),
        const SizedBox(width: 6),
        Text(period(h), style: TextStyle(fontSize: psize, color: pc)),
      ],
    ),
  );
}

class Alarm {
  final String id;
  final int hour;
  final int minute;
  final String label;
  final List<int> days;
  bool enabled;

  Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    this.label = '',
    this.days = const [],
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
        'days': days,
        'enabled': enabled,
      };

  factory Alarm.fromJson(Map<String, dynamic> j) => Alarm(
        id: j['id'] as String,
        hour: j['hour'] as int,
        minute: j['minute'] as int,
        label: (j['label'] ?? '') as String,
        days: List<int>.from(j['days'] ?? const []),
        enabled: (j['enabled'] ?? true) as bool,
      );

  String get repeatText {
    if (days.isEmpty) return '\u0645\u0631\u0629 \u0648\u0627\u062d\u062f\u0629';
    if (days.length == 7) return '\u0643\u0644 \u064a\u0648\u0645';
    return kDayOrder.where((d) => days.contains(d)).map((d) => kDayShort[d]).join('\u060c ');
  }

  DateTime? nextTrigger(DateTime from) {
    for (int i = 0; i < 8; i++) {
      final d = DateTime(from.year, from.month, from.day + i, hour, minute);
      if (!d.isAfter(from)) continue;
      if (days.isEmpty || days.contains(d.weekday)) return d;
    }
    return null;
  }
}

class AlarmStore {
  static const String _key = 'alarms_v1';

  static Future<List<Alarm>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Alarm.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<Alarm> alarms) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(alarms.map((a) => a.toJson()).toList()));
    } catch (_) {}
  }
}

class AlarmApp extends StatelessWidget {
  const AlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '\u0627\u0644\u0645\u0646\u0628\u0647',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: kBg,
        colorScheme: const ColorScheme.dark(
          primary: kPrimary,
          secondary: kPrimaryLight,
          surface: kSurface,
          error: kDanger,
        ),
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Alarm> _alarms = [];
  DateTime _now = DateTime.now();
  Timer? _ticker;
  bool _loaded = false;
  bool _ringing = false;
  final Map<String, String> _fired = {};
  DateTime? _snoozeAt;
  Alarm? _snoozeAlarm;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await AlarmStore.load();
    if (!mounted) return;
    setState(() {
      _alarms = list;
      _loaded = true;
    });
  }

  void _save() {
    AlarmStore.save(_alarms);
  }

  void _sort() {
    _alarms.sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
  }

  void _tick() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() => _now = now);
    if (_ringing) return;

    if (_snoozeAt != null && !now.isBefore(_snoozeAt!)) {
      final a = _snoozeAlarm;
      _snoozeAt = null;
      _snoozeAlarm = null;
      if (a != null) {
        _ring(a);
        return;
      }
    }

    for (final a in _alarms) {
      if (!a.enabled) continue;
      if (a.hour != now.hour || a.minute != now.minute) continue;
      if (a.days.isNotEmpty && !a.days.contains(now.weekday)) continue;
      final key = '${now.year}-${now.month}-${now.day}-${now.hour}-${now.minute}';
      if (_fired[a.id] == key) continue;
      _fired[a.id] = key;
      _ring(a);
      return;
    }
  }

  Future<void> _ring(Alarm a) async {
    _ringing = true;
    if (a.days.isEmpty) {
      a.enabled = false;
      _save();
    }
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => RingingPage(alarm: a),
      ),
    );
    _ringing = false;
    if (!mounted) return;
    if (result == 'snooze') {
      _snoozeAlarm = a;
      _snoozeAt = DateTime.now().add(const Duration(minutes: 5));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('\u0633\u064a\u0631\u0646 \u0627\u0644\u0645\u0646\u0628\u0647 \u0645\u062c\u062f\u062f\u064b\u0627 \u0628\u0639\u062f 5 \u062f\u0642\u0627\u0626\u0642')),
      );
    }
    setState(() {});
  }

  Future<void> _openEditor([Alarm? existing]) async {
    final result = await showModalBottomSheet<Alarm>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AlarmEditor(existing: existing),
    );
    if (result == null) return;
    setState(() {
      final i = _alarms.indexWhere((x) => x.id == result.id);
      if (i >= 0) {
        _alarms[i] = result;
      } else {
        _alarms.add(result);
      }
      _sort();
    });
    _save();
  }

  void _delete(Alarm a) {
    setState(() => _alarms.removeWhere((x) => x.id == a.id));
    _save();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('\u062a\u0645 \u062d\u0630\u0641 \u0627\u0644\u0645\u0646\u0628\u0647'),
        action: SnackBarAction(
          label: '\u062a\u0631\u0627\u062c\u0639',
          onPressed: () {
            setState(() {
              _alarms.add(a);
              _sort();
            });
            _save();
          },
        ),
      ),
    );
  }

  String? _nextText() {
    DateTime? best;
    for (final a in _alarms) {
      if (!a.enabled) continue;
      final t = a.nextTrigger(_now);
      if (t != null && (best == null || t.isBefore(best))) best = t;
    }
    if (_snoozeAt != null && (best == null || _snoozeAt!.isBefore(best))) {
      best = _snoozeAt;
    }
    if (best == null) return null;
    final totalMin = (best.difference(_now).inSeconds + 59) ~/ 60;
    if (totalMin <= 0) return '\u0633\u064a\u0631\u0646 \u0627\u0644\u0645\u0646\u0628\u0647 \u0627\u0644\u0622\u0646';
    final days = totalMin ~/ 1440;
    final hours = (totalMin % 1440) ~/ 60;
    final mins = totalMin % 60;
    final parts = <String>[];
    if (days > 0) parts.add('$days \u064a\u0648\u0645');
    if (hours > 0) parts.add('$hours \u0633\u0627\u0639\u0629');
    if (mins > 0) parts.add('$mins \u062f\u0642\u064a\u0642\u0629');
    return '\u0633\u064a\u0631\u0646 \u0627\u0644\u0645\u0646\u0628\u0647 \u0628\u0639\u062f ${parts.join(' \u0648 ')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alarm),
        label: const Text('\u0645\u0646\u0628\u0647 \u062c\u062f\u064a\u062f'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: !_loaded
                  ? const Center(child: CircularProgressIndicator())
                  : _alarms.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          itemCount: _alarms.length,
                          itemBuilder: (_, i) => _buildTile(_alarms[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final next = _nextText();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(time12(_now.hour, _now.minute),
                    style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w300,
                        color: kText,
                        height: 1)),
                const SizedBox(width: 8),
                Text(two(_now.second),
                    style: const TextStyle(fontSize: 24, color: kMuted)),
                const SizedBox(width: 8),
                Text(period(_now.hour),
                    style: const TextStyle(
                        fontSize: 22,
                        color: kPrimaryLight,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${kDayFull[_now.weekday]} ${_now.day} ${kMonths[_now.month - 1]} ${_now.year}',
            style: const TextStyle(fontSize: 16, color: kMuted),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: next == null ? kSurface : kPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: next == null ? kBorder : kPrimary.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(next == null ? Icons.alarm_off : Icons.alarm_on,
                    size: 20, color: next == null ? kMuted : kPrimaryLight),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    next ?? '\u0644\u0627 \u064a\u0648\u062c\u062f \u0645\u0646\u0628\u0647 \u0645\u0641\u0639\u0651\u0644',
                    style: TextStyle(
                        fontSize: 15, color: next == null ? kMuted : kText),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.alarm_add, size: 56, color: kMuted),
            SizedBox(height: 16),
            Text('\u0644\u0627 \u062a\u0648\u062c\u062f \u0645\u0646\u0628\u0647\u0627\u062a \u0628\u0639\u062f',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600, color: kText)),
            SizedBox(height: 8),
            Text('\u0627\u0636\u063a\u0637 \u00ab\u0645\u0646\u0628\u0647 \u062c\u062f\u064a\u062f\u00bb \u0644\u0625\u0636\u0627\u0641\u0629 \u0623\u0648\u0644 \u0645\u0646\u0628\u0647.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: kMuted)),
          ],
        ),
      ),
    );
  }

  Widget _dismissBg(Alignment align) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: align,
      decoration: BoxDecoration(
          color: kDanger, borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.delete_outline, color: Colors.white),
    );
  }

  Widget _buildTile(Alarm a) {
    final subtitle =
        a.label.isEmpty ? a.repeatText : '${a.label} \u2022 ${a.repeatText}';
    return Dismissible(
      key: ValueKey(a.id),
      background: _dismissBg(Alignment.centerRight),
      secondaryBackground: _dismissBg(Alignment.centerLeft),
      onDismissed: (_) => _delete(a),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openEditor(a),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      clockText(a.hour, a.minute, 36, 16,
                          a.enabled ? kText : kMuted,
                          a.enabled ? kPrimaryLight : kMuted),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, color: kMuted)),
                    ],
                  ),
                ),
                Switch(
                  value: a.enabled,
                  activeColor: Colors.white,
                  activeTrackColor: kPrimary,
                  onChanged: (v) {
                    setState(() => a.enabled = v);
                    _save();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AlarmEditor extends StatefulWidget {
  final Alarm? existing;
  const AlarmEditor({super.key, this.existing});

  @override
  State<AlarmEditor> createState() => _AlarmEditorState();
}

class _AlarmEditorState extends State<AlarmEditor> {
  late TimeOfDay _time;
  late TextEditingController _label;
  late Set<int> _days;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final now = DateTime.now();
    _time = e != null
        ? TimeOfDay(hour: e.hour, minute: e.minute)
        : TimeOfDay(hour: now.hour, minute: now.minute);
    _label = TextEditingController(text: e == null ? '' : e.label);
    _days = Set<int>.from(e == null ? <int>[] : e.days);
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  void _submit() {
    final e = widget.existing;
    final days = _days.toList()..sort();
    Navigator.of(context).pop(
      Alarm(
        id: e == null ? DateTime.now().microsecondsSinceEpoch.toString() : e.id,
        hour: _time.hour,
        minute: _time.minute,
        label: _label.text.trim(),
        days: days,
        enabled: true,
      ),
    );
  }

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c),
      );

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? '\u062a\u0639\u062f\u064a\u0644 \u0627\u0644\u0645\u0646\u0628\u0647' : '\u0645\u0646\u0628\u0647 \u062c\u062f\u064a\u062f',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w600, color: kText)),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: kSurfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kBorder),
                ),
                child: Center(
                    child: clockText(
                        _time.hour, _time.minute, 56, 20, kText, kPrimaryLight)),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text('\u0627\u0636\u063a\u0637 \u0639\u0644\u0649 \u0627\u0644\u0648\u0642\u062a \u0644\u062a\u063a\u064a\u064a\u0631\u0647',
                  style: TextStyle(fontSize: 13, color: kMuted)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _label,
              maxLength: 40,
              style: const TextStyle(color: kText),
              decoration: InputDecoration(
                labelText: '\u0627\u0633\u0645 \u0627\u0644\u0645\u0646\u0628\u0647 (\u0627\u062e\u062a\u064a\u0627\u0631\u064a)',
                labelStyle: const TextStyle(color: kMuted),
                counterText: '',
                filled: true,
                fillColor: kSurfaceAlt,
                border: _border(kBorder),
                enabledBorder: _border(kBorder),
                focusedBorder: _border(kPrimary),
              ),
            ),
            const SizedBox(height: 16),
            const Text('\u0627\u0644\u062a\u0643\u0631\u0627\u0631', style: TextStyle(fontSize: 15, color: kMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kDayOrder.map((d) {
                final selected = _days.contains(d);
                return FilterChip(
                  label: Text(kDayShort[d] ?? ''),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: kPrimary,
                  backgroundColor: kSurfaceAlt,
                  side: BorderSide(color: selected ? kPrimary : kBorder),
                  labelStyle: TextStyle(color: selected ? Colors.white : kText),
                  onSelected: (v) => setState(() {
                    if (v) {
                      _days.add(d);
                    } else {
                      _days.remove(d);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            Text(_days.isEmpty ? '\u0628\u062f\u0648\u0646 \u0627\u062e\u062a\u064a\u0627\u0631: \u064a\u0631\u0646 \u0645\u0631\u0629 \u0648\u0627\u062d\u062f\u0629 \u0641\u0642\u0637.' : '',
                style: const TextStyle(fontSize: 13, color: kMuted)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kText,
                      side: const BorderSide(color: kBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('\u0625\u0644\u063a\u0627\u0621'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('\u062d\u0641\u0638 \u0627\u0644\u0645\u0646\u0628\u0647'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RingingPage extends StatefulWidget {
  final Alarm alarm;
  const RingingPage({super.key, required this.alarm});

  @override
  State<RingingPage> createState() => _RingingPageState();
}

class _RingingPageState extends State<RingingPage>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _pulse;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _beep();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _seconds++;
      if (_seconds >= 120) {
        if (mounted) Navigator.of(context).pop('stop');
        return;
      }
      _beep();
    });
  }

  void _beep() {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.vibrate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.alarm;
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1.08).animate(
                    CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kPrimary.withOpacity(0.18),
                      border: Border.all(color: kPrimary, width: 2),
                    ),
                    child: const Icon(Icons.alarm, size: 56, color: kPrimaryLight),
                  ),
                ),
                const SizedBox(height: 32),
                clockText(a.hour, a.minute, 80, 24, kText, kPrimaryLight),
                const SizedBox(height: 8),
                Text(a.label.isEmpty ? '\u062d\u0627\u0646 \u0648\u0642\u062a \u0627\u0644\u0645\u0646\u0628\u0647' : a.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: kText)),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop('stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kDanger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('\u0625\u064a\u0642\u0627\u0641'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop('snooze'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kText,
                      side: const BorderSide(color: kBorder),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text('\u063a\u0641\u0648\u0629 5 \u062f\u0642\u0627\u0626\u0642'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}