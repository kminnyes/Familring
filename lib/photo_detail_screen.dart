import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class PhotoDetailScreen extends StatefulWidget {
  final String photoUrl;
  final String date;

  PhotoDetailScreen({required this.photoUrl, required this.date});

  @override
  _PhotoDetailScreenState createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _flutterTts.setLanguage("ko-KR");
    _flutterTts.setSpeechRate(0.6);
    _flutterTts.setVolume(0.8);
    _flutterTts.setPitch(1.0);
  }

  void _speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.date),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(widget.photoUrl),
            SizedBox(height: 8.0),
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.red),
                SizedBox(width: 8.0),
                Text('2'),
                SizedBox(width: 16.0),
                Icon(Icons.comment, color: Colors.orange),
                SizedBox(width: 8.0),
                Text('1'),
              ],
            ),
            SizedBox(height: 8.0),
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage('image/test_image.jpg'),
                ),
                SizedBox(width: 8.0),
                Text('아빠'),
                SizedBox(width: 8.0),
                Text('멋지다~~^^'),
              ],
            ),
            Expanded(child: Container()),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: '댓글 남기기',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.orange),
                  onPressed: () {
                    // 댓글 작성 기능 추가
                    print("Comment: ${_commentController.text}");
                  },
                ),
                IconButton(
                  icon: Icon(Icons.mic, color: Colors.orange),
                  onPressed: () {
                    // 작성한 댓글을 읽어주는 기능 추가
                    if (_commentController.text.isNotEmpty) {
                      _speak(_commentController.text);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _commentController.dispose();
    super.dispose();
  }
}
