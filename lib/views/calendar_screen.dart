import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:psicalendar_movil/views/settings_screen.dart' hide ElevatedButton;

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _localeInitialized = false;

  final List<String> weekDays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES', null).then((_) {
      setState(() {
        _localeInitialized = true;
      });
    });
  }

  bool darkMode = false;
  bool showShortDate = false;
  int daysToShow = 7;

  Future<void> _openSettings() async {
    final result = await Navigator.push<Map>(context, MaterialPageRoute(builder: (context) => SettingsScreen()));
    if (result != null) {
      setState(() {
        darkMode = result['darkMode'] ?? false;
        showShortDate = result['showShortDate'] ?? false;
        daysToShow = result['daysToShow'] ?? 7;
      });
      if (result['showSnackBar'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración guardada.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario Semanal'),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Acerca de',
            onPressed: () {
              Navigator.pushNamed(context, '/about');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuración',
            onPressed: _openSettings,
          ),
        ],
      ),
      backgroundColor: darkMode ? Colors.grey[900] : Colors.blue[50],
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('days').snapshots(),
        builder: (context, snapshot) {
          final now = DateTime.now();
          final List<Map<String, dynamic>> emojis = [
            {'icon': '😡', 'label': 'Enojado'},
            {'icon': '😢', 'label': 'Triste'},
            {'icon': '😊', 'label': 'Feliz'},
            {'icon': '😃', 'label': 'Alegre'},
            {'icon': '😐', 'label': 'Normal'},
          ];
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: daysToShow,
            itemBuilder: (context, index) {
              final date = now.subtract(Duration(days: daysToShow - index - 1));
              final dateKey = date.toIso8601String().substring(0, 10);
              final isToday = (daysToShow - index - 1) == 0;
              final isPast = (daysToShow - index - 1) > 0;
              final dateStr = showShortDate
                  ? '${date.day}/${date.month}/${date.year}'
                  : DateFormat('d MMMM yyyy', 'es_ES').format(date);
              QueryDocumentSnapshot<Map<String, dynamic>>? doc;
              try {
                doc = docs.firstWhere((d) => d.id == dateKey);
              } catch (_) {
                doc = null;
              }
              int? emojiIdx;
              bool hasData = false;
              if (doc != null) {
                final data = doc.data();
                if (data['emoji'] != null && data['emoji'] is int) {
                  emojiIdx = data['emoji'] as int?;
                  hasData = true;
                }
              }
              String emojiIcon = '';
              if (hasData && emojiIdx != null && emojiIdx >= 0 && emojiIdx < emojis.length) {
                emojiIcon = emojis[emojiIdx]['icon'];
              }
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  title: Text(
                    dateStr,
                    style: TextStyle(
                      color: isToday
                          ? Colors.blue[900]
                          : isPast
                          ? Colors.blueGrey
                          : Colors.grey,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  leading: hasData && emojiIcon.isNotEmpty
                      ? Text(
                          emojiIcon,
                          style: const TextStyle(fontSize: 28),
                        )
                      : null,
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (isToday || isPast)
                          ? Colors.blue[700]
                          : Colors.grey[400],
                    ),
                    onPressed: (isToday || isPast)
                        ? () async {
                            try {
                              await Navigator.pushNamed(
                                context,
                                '/day',
                                arguments: {'date': date},
                              );
                              // No es necesario setState, StreamBuilder actualiza automáticamente
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error al abrir el día: $e')),
                              );
                            }
                          }
                        : null,
                    child: const Text('Ingresar'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
