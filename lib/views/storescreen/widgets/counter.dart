import 'package:flutter/material.dart';

class CounterItem extends StatefulWidget {
  const CounterItem({Key? key}) : super(key: key);

  @override
  State<CounterItem> createState() => _CounterItemState();
}

class _CounterItemState extends State<CounterItem> {
  @override
  Widget build(BuildContext context) {
    return Card(
        color: Colors.white,
        child: SizedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.remove,
                  color: Colors.black,
                ),
                onPressed: () {
                  // controller.updateCounter(-1);
                },
              ),
              Text(
                "1",
                style: const TextStyle(
                  color: Colors.black,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add,
                  color: Colors.black,
                ),
                onPressed: () {
                  // controller.updateCounter(1);
                },
              ),
            ],
          ),
        ));
  }
}
