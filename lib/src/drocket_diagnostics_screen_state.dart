import 'dart:convert';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import 'drocket_diagnostics_screen.dart';

class DrocketDiagnosticsScreenState extends State<DrocketDiagnosticsScreen> {
  final List<Map<String, Object?>> events = <Map<String, Object?>>[];
  String filter = 'all';
  String? error;

  @override
  void initState() {
    super.initState();
    loadSnapshot();
  }

  Future<void> loadSnapshot() async {
    try {
      final response = await serviceManager.callServiceExtensionOnMainIsolate(
        'ext.d_rocket.diagnostics.snapshot',
      );
      final dynamic rawEvents = response.json?['events'];
      if (rawEvents is List) {
        setState(() {
          events
            ..clear()
            ..addAll(rawEvents.whereType<Map>().map(
                  (event) => event.cast<String, Object?>(),
                ));
        });
      }
    } catch (value) {
      setState(() => error = value.toString());
    }
  }

  Future<void> clearEvents() async {
    await serviceManager.callServiceExtensionOnMainIsolate(
      'ext.d_rocket.diagnostics.clear',
    );
    setState(events.clear);
  }

  @override
  Widget build(BuildContext context) {
    final visible = events.where((event) {
      return filter == 'all' || event['category'] == filter;
    }).toList(growable: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('d_rocket diagnostics'),
        actions: <Widget>[
          DropdownButton<String>(
            value: filter,
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem(value: 'all', child: Text('All')),
              DropdownMenuItem(value: 'rest', child: Text('REST')),
              DropdownMenuItem(value: 'database', child: Text('Database')),
              DropdownMenuItem(value: 'migration', child: Text('Migrations')),
              DropdownMenuItem(value: 'sync', child: Text('Sync')),
              DropdownMenuItem(value: 'realtime', child: Text('Realtime')),
            ],
            onChanged: (value) => setState(() => filter = value ?? 'all'),
          ),
          IconButton(onPressed: loadSnapshot, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: clearEvents,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: error == null
          ? ListView.builder(
              itemCount: visible.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(
                  '${visible[index]['category']} · ${visible[index]['operation']}',
                ),
                subtitle: Text(jsonEncode(visible[index])),
              ),
            )
          : Center(child: Text(error!)),
    );
  }
}
