import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sanskrit_racitatiion_project/verse_page/verses_model.dart';
import 'package:sanskrit_racitatiion_project/verse_page/hamburger_button.dart';

class GitaVersePage extends StatefulWidget {
  final Verse verse;
  const GitaVersePage({super.key, required this.verse});

  @override
  _GitaVersePageState createState() => _GitaVersePageState();
}

class _GitaVersePageState extends State<GitaVersePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  List<String> _selectedViews = ['All'];
  final List<String> _viewOptions = ['All', 'Verse', 'Synonyms', 'Translation', 'Purport', 'sanskrit_text'];

  String _selectedAudio = 'Audio 1';
  final Map<String, String> _audioFiles = {
    'Audio 1': 'v1.mp3',
    'Audio 2': 'v2.mp3',
    'Audio 3': 'v3.mp3',
    'Audio 4': 'v4.mp3',
  };

  @override
  void initState() {
    super.initState();
    _audioPlayer.setSource(AssetSource(_audioFiles[_selectedAudio]!));
    _audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d));
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
    _audioPlayer.onPlayerComplete.listen((_) => setState(() {
      isPlaying = false;
      _position = Duration.zero;
    }));
  }

  void _setAudioSource() {
    _audioPlayer.setSource(AssetSource(_audioFiles[_selectedAudio]!));
  }

  void _playAudio() async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
    setState(() => isPlaying = !isPlaying);
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verse ${widget.verse.id}', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurpleAccent,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          HamburgerButton(
            selectedViews: _selectedViews,
            viewOptions: _viewOptions,
            onViewSelected: (value) {
              setState(() {
                if (value == 'All') {
                  _selectedViews = ['All']; // Reset to only 'All'
                } else {
                  if (_selectedViews.contains('All')) _selectedViews.remove('All');
                  if (_selectedViews.contains(value)) {
                    _selectedViews.remove(value);
                  } else {
                    _selectedViews.add(value);
                  }
                }
              });
            },
          ),


        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_selectedViews.contains('All') || _selectedViews.contains('Verse'))
                ...widget.verse.lines.map((line) => _buildLine(parseLine(line))).toList(),

              if (_selectedViews.contains('All') || _selectedViews.contains('sanskrit_text'))
                _buildSection2('sanskrit text', widget.verse.textSanskrit),

              _buildAudioControls(),

              if (_selectedViews.contains('All') || _selectedViews.contains('Synonyms'))
                _buildSection('Synonyms', widget.verse.textSynonyms),

              if (_selectedViews.contains('All') || _selectedViews.contains('Translation'))
                _buildSection('Translation', widget.verse.textTranslation),

              if (_selectedViews.contains('All') || _selectedViews.contains('Purport'))
                _buildSection('Purport', widget.verse.textPurport),


            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(content, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
  Widget _buildSection2(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Text(content, style: TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildAudioControls() {
    return Column(
      children: [
        DropdownButton<String>(
          value: _selectedAudio,
          onChanged: (newValue) => setState(() {
            _selectedAudio = newValue!;
            _setAudioSource();
          }),
          items: _audioFiles.keys.map((audio) => DropdownMenuItem(value: audio, child: Text(audio))).toList(),
        ),
        IconButton(
          onPressed: _playAudio,
          icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.deepPurpleAccent, size: 40.0),
        ),
        Slider(
          min: 0,
          max: _duration.inSeconds.toDouble(),
          value: _position.inSeconds.toDouble(),
          onChanged: (value) async => await _audioPlayer.seek(Duration(seconds: value.toInt())),
          activeColor: Colors.deepPurpleAccent,
          inactiveColor: Colors.grey,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatTime(_position)),
            Text(_formatTime(_duration)),
          ],
        ),
      ],
    );
  }
}

List<Map<String, String>> parseLine(String line) {
  List<Map<String, String>> result = []; // Explicitly define the list type
  List<String> words = line.split(';');

  for (String word in words) {
    List<String> parts = word.split('—'); // Split Sanskrit and translation
    if (parts.length == 2) {
      result.add({
        "sanskrit": parts[0].trim(),
        "translation": parts[1].trim()
      });
    }
  }
  return result;
}


Widget _buildLine(List<Map<String, String>> phrases) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8.0,
        runSpacing: 4.0,
        children: phrases.map((phrase) => Column(
          children: [
            Text(phrase['sanskrit'] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            Text(phrase['translation'] ?? '', style: TextStyle(fontSize: 8, fontStyle: FontStyle.italic, color: Colors.grey), textAlign: TextAlign.center),
          ],
        )).toList(),
      ),
      SizedBox(height: 12.0),
    ],
  );
}
