import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main(List<String> args) {
  runApp(
    ChangeNotifierProvider(
      create: (context) => MySettings(),
      child: const MaterialApp(home: MyApp()),
    ),
  );
}

class MySettings extends ChangeNotifier {
  String text = 'Done';
  Color color = Colors.red;

  void changeText() {
    if (text == 'Helooo') {
      text = 'World';
    } else {
      text = 'Helooo';
    }
    notifyListeners();
  }

  set newColor(Color newColor) {
    color = newColor;
    notifyListeners();
  }

  void changeColor(Color newColor) {
    if (color == Colors.red) {
      color = Colors.blue;
    } else {
      color = Colors.red;
    }
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MySettings>(builder: (context, mySettings, child) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Provider Example'),
          backgroundColor: mySettings.color,
        ),
        drawer: Drawer(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: () {
                      mySettings.changeColor(Colors.red);
                      Navigator.pop(context);
                    },
                    child: const Text('Change Color')),
                ElevatedButton(
                    onPressed: () {
                      mySettings.changeText();
                      Navigator.pop(context);
                    },
                    child: const Text('Change Text')),
                ElevatedButton(
                    onPressed: () {
                      mySettings.newColor = Colors.green;
                      Navigator.pop(context);
                    },
                    child: const Text('Change Color to Green')),
              ],
            ),
          ),
        ),
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: () {
                    mySettings.changeText();
                  },
                  child: const Text('Change Text')),
              Text(mySettings.text),
            ],
          ),
        ),
      );
    });
  }
}
