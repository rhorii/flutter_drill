import 'dart:convert';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drill',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DrillCollectionListPage(),
    );
  }
}

class DrillCollection {
  final String title;
  final List<String> paths;

  DrillCollection({
    required this.title,
    required this.paths,
  });

  factory DrillCollection.fromJson(Map<String, dynamic> json) =>
      DrillCollection(
        title: json['title'],
        paths: json['paths'].cast<String>(),
      );
}

class DrillCollectionListPage extends StatelessWidget {
  const DrillCollectionListPage({super.key});

  Future<List<DrillCollection>> _loadDrillCollections() async {
    const path = 'assets/drill_collections.json';
    final jsonString = await rootBundle.loadString(path);
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => DrillCollection.fromJson(json)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DrillCollection>>(
      future: _loadDrillCollections(),
      builder: (context, snapshot) {
        Widget body;
        if (snapshot.hasData) {
          body = DrillCollectionListView(
            drillCollections: snapshot.data!,
          );
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
            title: const Text('ドリル'),
          ),
          body: body,
        );
      },
    );
  }
}

class DrillCollectionListView extends StatelessWidget {
  final List<DrillCollection> drillCollections;

  const DrillCollectionListView({
    super.key,
    required this.drillCollections,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
            drillCollections[index].title,
            style: const TextStyle(fontSize: 64.0),
          ),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return DrillPage(drillCollection: drillCollections[index]);
              },
            ));
          },
        );
      },
      separatorBuilder: (context, index) => const Divider(),
      itemCount: drillCollections.length,
    );
  }
}

class Drill {
  final String question;
  final String answer;

  Drill({
    required this.question,
    required this.answer,
  });
}

class DrillPage extends StatelessWidget {
  final DrillCollection drillCollection;

  const DrillPage({
    super.key,
    required this.drillCollection,
  });

  Future<List<Drill>> _loadDrills() async {
    List<Drill> result = [];
    for (var path in drillCollection.paths) {
      final csvString = await rootBundle.loadString(path);
      final csv = const CsvToListConverter(shouldParseNumbers: false)
          .convert(csvString);
      final drills =
          csv.map((row) => Drill(question: row[0], answer: row[1])).toList();
      result.addAll(drills);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Drill>>(
      future: _loadDrills(),
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
            title: Text(drillCollection.title),
          ),
          body: body,
        );
      },
    );
  }
}

class DrillView extends StatefulWidget {
  final List<Drill> drills;
  final AudioPlayer? audioPlayer;

  const DrillView(this.drills, {super.key, this.audioPlayer});

  @override
  State<DrillView> createState() => _DrillViewState();
}

class _DrillViewState extends State<DrillView> {
  late final AudioPlayer _player;
  late int _index;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _player = widget.audioPlayer ?? AudioPlayer();
    _index = _randomIndex();
    _controller = TextEditingController();
  }

  int _randomIndex() {
    return Random().nextInt(widget.drills.length);
  }

  Drill _currentDrill() {
    return widget.drills[_index];
  }

  bool _isNumeric(String text) {
    return double.tryParse(text) != null;
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
                _currentDrill().question,
                style: const TextStyle(fontSize: 256.0),
              ),
              Expanded(
                child: _isNumeric(_currentDrill().answer)
                    ? _numericAnswerField()
                    : _defaultAnswerField(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 64.0),
        ElevatedButton(
          onPressed: () async {
            if (_controller.text.isEmpty) {
              return;
            }

            if (_controller.text == _currentDrill().answer) {
              await _player.play(AssetSource('sounds/correct.mp3'));

              setState(() {
                _index = _randomIndex();
                _controller.clear();
              });
            } else {
              _player.play(AssetSource('sounds/incorrect.mp3'));
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

  TextField _defaultAnswerField() {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
      ),
      style: const TextStyle(fontSize: 256.0),
      textAlign: TextAlign.center,
      showCursor: false,
    );
  }

  TextField _numericAnswerField() {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 256.0),
      textAlign: TextAlign.center,
      showCursor: false,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
    );
  }
}
