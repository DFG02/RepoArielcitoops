import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    final result = await Navigator.pushNamed(context, '/settings');
    if (result is Map) {
      setState(() {
        darkMode = result['darkMode'] ?? false;
        showShortDate = result['showShortDate'] ?? false;
        daysToShow = result['daysToShow'] ?? 7;
      });
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
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: daysToShow,
        itemBuilder: (context, index) {
          try {
            // Invertir el orden: mostrar primero la fecha más antigua
            final date = now.subtract(Duration(days: daysToShow - index - 1));
            final isToday = (daysToShow - index - 1) == 0;
            final isPast = (daysToShow - index - 1) > 0;
            final dateStr = showShortDate
                ? '${date.day}/${date.month}/${date.year}'
                : DateFormat('d MMMM yyyy', 'es_ES').format(date);

            final dateKey = date.toIso8601String().substring(0, 10);
            final List<Map<String, dynamic>> emojis = [
              {'icon': '😡', 'label': 'Enojado'},
              {'icon': '😢', 'label': 'Triste'},
              {'icon': '😊', 'label': 'Feliz'},
              {'icon': '😃', 'label': 'Alegre'},
              {'icon': '😐', 'label': 'Normal'},
            ];

            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('days')
                  .doc(dateKey)
                  .get(),
              builder: (context, snapshot) {
                int? emojiIdx;
                bool hasData = false;
                if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                  final data = snapshot.data!.data();
                  if (data != null && data['emoji'] != null && data['emoji'] is int) {
                    emojiIdx = data['emoji'] as int?;
                    hasData = true;
                  } else {
                    emojiIdx = null;
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
                      onPressed: (isToday || isPast)
                          ? () async {
                              try {
                                await Navigator.pushNamed(
                                  context,
                                  '/day',
                                  arguments: {'date': date},
                                );
                                setState(() {}); // Refrescar para mostrar cambios
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error al abrir el día: $e')),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (isToday || isPast)
                            ? Colors.blue[700]
                            : Colors.grey[400],
                      ),
                      child: const Text('Ingresar'),
                    ),
                  ),
                );
              },
            );
          } catch (e) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                title: Text('Error: $e'),
                leading: const Icon(Icons.error, color: Colors.red),
              ),
            );
          }
        },
      ),
    );
  }
}
