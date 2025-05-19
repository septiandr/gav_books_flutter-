import 'package:flutter/material.dart';
import 'package:gav_books_flutter/pages/home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GAV Books',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: BookListPage(),
    );
  }
}
