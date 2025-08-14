import 'package:shared_preferences/shared_preferences.dart';
	// ...existing code...
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
	const SettingsScreen({super.key});

	@override
	State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
	@override
	void initState() {
		super.initState();
		_loadPrefs();
	}

	Future<void> _loadPrefs() async {
		final prefs = await SharedPreferences.getInstance();
		setState(() {
			darkMode = prefs.getBool('darkMode') ?? false;
			showShortDate = prefs.getBool('showShortDate') ?? false;
			daysToShow = prefs.getInt('daysToShow') ?? 7;
		});
	}

	Future<void> _savePrefs() async {
		final prefs = await SharedPreferences.getInstance();
		await prefs.setBool('darkMode', darkMode);
		await prefs.setBool('showShortDate', showShortDate);
		await prefs.setInt('daysToShow', daysToShow);
	}
	Future<void> _deleteAllData() async {
		try {
			final daysCollection = FirebaseFirestore.instance.collection('days');
			final snapshot = await daysCollection.get();
			for (var doc in snapshot.docs) {
				await doc.reference.delete();
			}
			if (mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(content: Text('Todos los datos han sido borrados.')),
				);
			}
		} catch (e) {
			if (mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(content: Text('Error al borrar datos: $e')),
				);
			}
		}
	}
	bool darkMode = false;
	bool showShortDate = false;
	int daysToShow = 7;

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Configuración')),
			body: Padding(
				padding: const EdgeInsets.all(24.0),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
														children: [
						SwitchListTile(
							title: const Text('Modo noche'),
							value: darkMode,
							onChanged: (val) {
								setState(() => darkMode = val);
							},
						),
						SwitchListTile(
							title: const Text('Mostrar solo fecha (D/M/A)'),
							value: showShortDate,
							onChanged: (val) {
								setState(() => showShortDate = val);
							},
						),
						const SizedBox(height: 24),
						Text('Ver solo los últimos días:', style: TextStyle(fontSize: 16)),
						DropdownButton<int>(
							value: daysToShow,
							items: [3, 5, 7, 10]
									.map((e) => DropdownMenuItem(value: e, child: Text('$e días')))
									.toList(),
							onChanged: (val) {
								if (val != null) setState(() => daysToShow = val);
							},
						),
						const SizedBox(height: 24),
									ElevatedButton(
																													onPressed: () async {
																														await _savePrefs();
																														Navigator.pop(context, {
																															'darkMode': darkMode,
																															'showShortDate': showShortDate,
																															'daysToShow': daysToShow,
																															'showSnackBar': true,
																														});
																													},
														child: const Text('Guardar configuración'),
									),
												const SizedBox(height: 24),
												ElevatedButton(
													style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
													onPressed: () async {
														final confirm = await showDialog<bool>(
															context: context,
															builder: (context) => AlertDialog(
																title: const Text('¿Borrar todos los datos?'),
																content: const Text('Esta acción eliminará todos los registros de la app y la base de datos. ¿Estás seguro?'),
																actions: [
																	TextButton(
																		onPressed: () => Navigator.pop(context, false),
																		child: const Text('Cancelar'),
																	),
																	TextButton(
																		onPressed: () => Navigator.pop(context, true),
																		child: const Text('Borrar'),
																	),
																],
															),
														);
														if (confirm == true) {
															await _deleteAllData();
														}
													},
													child: const Text('Borrar todos los datos'),
												),
					],
				),
			),
		);
	}
}
