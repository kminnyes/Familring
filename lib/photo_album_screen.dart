import 'package:flutter/material.dart';

class PhotoAlbumScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('홈'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Text(
          '사진첩',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}