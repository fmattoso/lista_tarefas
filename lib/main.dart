import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Tarefas',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            onPrimary: Colors.yellow,
            primary: Colors.blue,
          ),
        ),
      ),
      home: const MyHomePage(title: 'Lista de Tarefas'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController toDoController = TextEditingController();
  List _toDoList = [];
  late Map<String, dynamic> _lastRemoved;
  late int _lastRemovedPos;

  @override
  void initState() {
    super.initState();
    _readData().then((data) => {
          setState(() {
            if (data != null) {
              _toDoList = jsonDecode(data);
            }
          })
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        // mainAxisAlignment: MainAxisAlignment.,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(16.0, 2.0, 16.0, 2.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: toDoController,
                    decoration: const InputDecoration(
                      labelText: 'Nova Tarefa',
                    ),
                  ),
                ),
                ElevatedButton(
                  child: const Text("ADD"),
                  onPressed: _addToDo,
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8.0),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem),
              onRefresh: _refresh,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addToDo() {
    Map<String, dynamic> newToDo = Map();
    newToDo['title'] = toDoController.text;
    newToDo['ok'] = false;
    setState(() {
      toDoController.text = '';
      _toDoList.add(newToDo);
    });
    _saveData();
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      background: Container(
          color: Colors.red,
          child: const Align(
            alignment: Alignment(-0.9, 0.0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          )),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]['title']),
        value: _toDoList[index]['ok'],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]['ok'] ? Icons.check : Icons.error),
        ),
        onChanged: (bool? checked) {
          setState(() {
            if (checked != null && checked) {
              _toDoList[index]['ok'] = true;
            } else {
              _toDoList[index]['ok'] = false;
            }
          });
          _saveData();
        },
      ),
      onDismissed: (direction) {
        _lastRemoved = Map.from(_toDoList[index]);
        _lastRemovedPos = index;
        setState(() {
          _toDoList.removeAt(index);
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          _saveData();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Tarefa "${_lastRemoved['title']}" removida!'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
          ));
        });
      },
    );
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b) {
        if (a['ok'] && !b['ok']) {
          return 1;
        } else if (!a['ok'] && b['ok']) {
          return -1;
        } else {
          return 0;
        }
      });
      _saveData();
    });
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = jsonEncode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String?> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
