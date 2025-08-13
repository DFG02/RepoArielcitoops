import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DayScreen extends StatefulWidget {
  const DayScreen({super.key});

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  final TextEditingController _controller = TextEditingController();
  int? _selectedEmoji;
  bool _hasSaved = false;
  String? _dateKey;
  bool _loading = false;

  final List<Map<String, dynamic>> emojis = [
    {'icon': '😡', 'label': 'Enojado'},
    {'icon': '😢', 'label': 'Triste'},
    {'icon': '😊', 'label': 'Feliz'},
    {'icon': '😃', 'label': 'Alegre'},
    {'icon': '😐', 'label': 'Normal'},
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && args['date'] != null) {
      final date = args['date'] as DateTime;
      _dateKey = date.toIso8601String().substring(0, 10); // yyyy-MM-dd
      _loadFromFirestore();
    }
  }

  Future<void> _loadFromFirestore() async {
    if (_dateKey == null) return;
    setState(() {
      _loading = true;
    });
    final doc = await FirebaseFirestore.instance
        .collection('days')
        .doc(_dateKey)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      _controller.text = data['text'] ?? '';
      _selectedEmoji = data['emoji'];
      _hasSaved = true;
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_dateKey == null) return;
    setState(() {
      _loading = true;
    });
    await FirebaseFirestore.instance.collection('days').doc(_dateKey).set({
      'text': _controller.text,
      'emoji': _selectedEmoji,
    });
    setState(() {
      _hasSaved = true;
      _loading = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Guardado exitosamente.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro del día'),
        backgroundColor: Colors.blue[700],
      ),
      backgroundColor: Colors.blue[50],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '¿Cómo te has sentido últimamente?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    maxLength: 256,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Escribe aquí... (máx. 256 letras)',
                      border: OutlineInputBorder(),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Selecciona un emoji:',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(emojis.length, (i) {
                      final selected = _selectedEmoji == i;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedEmoji = i;
                          });
                        },
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: selected
                                  ? Colors.blue[300]
                                  : Colors.grey[200],
                              child: Text(
                                emojis[i]['icon'],
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  emojis[i]['label'],
                                  style: TextStyle(fontSize: 14),
                                ),
                                if (selected)
                                  const Icon(
                                    Icons.check,
                                    color: Colors.blue,
                                    size: 18,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed:
                        (_selectedEmoji != null &&
                            _controller.text.trim().isNotEmpty)
                        ? _save
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _hasSaved ? 'Guardar Nuevos Cambios' : 'Guardar',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
