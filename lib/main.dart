import 'dart:math';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drill',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DrillPage(),
    );
  }
}

class DrillPage extends StatelessWidget {
  const DrillPage({Key? key}) : super(key: key);

  Future<List<List<String>>> _loadDrill() async {
    final csv = await rootBundle.loadString('assets/drill.csv');
    return const CsvToListConverter(shouldParseNumbers: false).convert(csv);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<List<String>>>(
      future: _loadDrill(),
      builder: (context, snapshot) {
        Widget body;
        if (snapshot.hasData) {
          body = DrillView(snapshot.data!);
        } else if (snapshot.hasError) {
          body = Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else {
          body = const Center(
            child: CircularProgressIndicator(),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Drill'),
          ),
          body: body,
        );
      },
    );
  }
}

class DrillView extends StatefulWidget {
  final List<List<String>> drill;
  const DrillView(this.drill, {Key? key}) : super(key: key);

  @override
  State<DrillView> createState() => _DrillViewState();
}

class _DrillViewState extends State<DrillView> {
  late int _index;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _index = _randomIndex();
    _controller = TextEditingController();
  }

  int _randomIndex() {
    return Random().nextInt(widget.drill.length);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                widget.drill[_index][0],
                style: const TextStyle(fontSize: 256.0),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 256.0),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 64.0),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isEmpty) {
              return;
            }

            if (_controller.text == widget.drill[_index][1]) {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    content: const Text(
                      'せいかい',
                      style: TextStyle(fontSize: 128.0),
                    ),
                    contentPadding: const EdgeInsets.all(48.0),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _index = _randomIndex();
                            _controller.clear();
                          });
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'つぎへ',
                          style: TextStyle(fontSize: 64.0),
                        ),
                      )
                    ],
                  );
                },
              );
            } else {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    content: const Text(
                      'まちがい',
                      style: TextStyle(fontSize: 128.0),
                    ),
                    contentPadding: const EdgeInsets.all(48.0),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _controller.clear();
                          });
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'やりなおす',
                          style: TextStyle(fontSize: 64.0),
                        ),
                      ),
                    ],
                  );
                },
              );
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(32.0),
          ),
          child: const Text(
            'こたえあわせ',
            style: TextStyle(fontSize: 64.0),
          ),
        ),
      ],
    );
  }
}
