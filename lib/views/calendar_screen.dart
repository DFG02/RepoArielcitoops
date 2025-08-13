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

  @override
  Widget build(BuildContext context) {
    if (!_localeInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final now = DateTime.now();
    final todayWeekday = now.weekday; // 1 = lunes, 7 = domingo

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario Semanal'),
        backgroundColor: Colors.blue[700],
      ),
      backgroundColor: Colors.blue[50],
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: 7,
        itemBuilder: (context, index) {
          final dayNum = index + 1;
          final isToday = dayNum == todayWeekday;
          final isPast = dayNum < todayWeekday;
          final date = now.subtract(Duration(days: todayWeekday - dayNum));
          final dateStr = DateFormat('d MMMM yyyy', 'es_ES').format(date);

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
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data();
                emojiIdx = data?['emoji'] as int?;
              }
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  title: Text(
                    '${weekDays[index]} $dateStr',
                    style: TextStyle(
                      color: isToday
                          ? Colors.blue[900]
                          : isPast
                          ? Colors.blueGrey
                          : Colors.grey,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  leading: emojiIdx != null
                      ? Text(
                          emojis[emojiIdx]['icon'],
                          style: const TextStyle(fontSize: 28),
                        )
                      : null,
                  trailing: ElevatedButton(
                    onPressed: (isToday || isPast)
                        ? () async {
                            await Navigator.pushNamed(
                              context,
                              '/day',
                              arguments: {'date': date},
                            );
                            setState(() {}); // Refrescar para mostrar cambios
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
        },
      ),
    );
  }
}
