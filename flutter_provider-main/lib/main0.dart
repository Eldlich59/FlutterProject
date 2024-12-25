import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

main() {
  runApp(ChangeNotifierProvider(
    create: (_) => CounterProvider(),
    child: MaterialApp(
      home: CounterHome(),
    ),
  ));
}

class CounterProvider extends ChangeNotifier {
  int counter = 0;

  void add() {
    counter++;
    notifyListeners();
  }
}

class CounterHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CounterProvider>(
      builder: (context, myCounter, child) {
        return Scaffold(
          appBar: AppBar(title: Text('Provider Demo')),
          drawer: Drawer(
            child: ElevatedButton(
                onPressed: () {
                  myCounter.counter = 100;
                  Navigator.pop(context);
                },
                child: Text('Change Default Value')),
          ),
          body: Center(
            child: Text(
              myCounter.counter.toString(),
              // Provider.of<CounterProvider>(context, listen: false)
              //     .counter
              //     .toString(),
              // context.watch<CounterProvider>().counter.toString(),
              style: TextStyle(fontSize: 50),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () {
              context.read<CounterProvider>().add();
              // myCounter.add();
              myCounter.counter++;
              // Provider.of<CounterProvider>(context, listen: false).add();
              print(context.read<CounterProvider>().counter);
            },
          ),
        );
      },
    );
  }
}
