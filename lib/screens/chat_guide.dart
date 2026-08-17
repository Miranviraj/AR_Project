import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../const/api_config.dart';
import '../widgets/glass_container.dart';

class ChatGuideScreen extends StatefulWidget {
  final String recognizedArtifact;
  const ChatGuideScreen({super.key, required this.recognizedArtifact});

  @override
  State<ChatGuideScreen> createState() => _ChatGuideScreenState();
}

class _ChatGuideScreenState extends State<ChatGuideScreen> {
  String _selectedLanguage = 'English';

  // Maps UI dropdown to TTS engine languages
  final Map<String, String> _ttsLanguages = {
    'English': 'en-US',
    'Sinhala': 'si-LK',
  };

  // Maps UI dropdown to the Pivot Language codes your Python backend expects
  final Map<String, String> _backendLangCodes = {
    'English': 'en',
    'Sinhala': 'si',
  };

  // ⚠️ CHANGE THIS TO YOUR LAPTOP'S IPV4 ADDRESS!
  // If using Android Emulator, use 'http://10.0.2.2:8000/api/chat'
  static final String _backendUrl = '${ApiConfig().baseUrl}/api/chat';

  // Voice Engine
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    // Simulate the first greeting
    _sendInitialGreeting();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  Future<void> _speak(String text) async {
    String cleanText = text.replaceAll(RegExp(r'\*|\#'), '');
    setState(() => _isSpeaking = true);
    await _flutterTts.speak(cleanText);
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() => _isSpeaking = false);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  void _sendInitialGreeting() {
    setState(() {
      _messages.add({
        'role': 'ai',
        'text': 'Welcome! I see you are exploring the ${widget.recognizedArtifact}. What would you like to know about it?'
      });
    });
    _speak('Welcome! I see you are exploring the ${widget.recognizedArtifact}. What would you like to know about it?');
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _stopSpeaking();

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });

    _scrollToBottom();
    _textController.clear();

    try {
      String contextPrompt = "Regarding the ${widget.recognizedArtifact}: $text";

      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': contextPrompt,
          'target_lang_code': _backendLangCodes[_selectedLanguage] ?? 'en'
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['reply'] ?? "No response from archives.";

        setState(() {
          _messages.add({'role': 'ai', 'text': aiText});
          _isLoading = false;
        });

        _scrollToBottom();
        _speak(aiText);

      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      print("BACKEND ERROR: $e");

      setState(() {
        _messages.add({
          'role': 'ai',
          'text': 'Cannot connect to the local AI server. Make sure Python FastAPI is running.'
        });
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Digital Guide', style: TextStyle(fontSize: 16)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            DropdownButton<String>(
              value: _selectedLanguage,
              dropdownColor: const Color(0xFF3A2E24),
              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              underline: const SizedBox(),
              icon: const Icon(Icons.language, color: Colors.orange),
              items: _ttsLanguages.keys.map((String lang) {
                return DropdownMenuItem(value: lang, child: Text(lang));
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLanguage = newValue;
                    _flutterTts.setLanguage(_ttsLanguages[newValue]!);
                  });
                }
              },
            ),
            IconButton(
              icon: Icon(_isSpeaking ? Icons.volume_up : Icons.volume_off, color: Colors.orange),
              onPressed: () => _isSpeaking ? _stopSpeaking() : null,
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final isUser = _messages[index]['role'] == 'user';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // 🌟 INJECT YOUR CUSTOM SKETCH HERE
                        if (!isUser) ...[
                          const CircleAvatar(
                            radius: 18,
                            backgroundImage: AssetImage('assets/guide_portrait.jpg'),
                            backgroundColor: Colors.transparent,
                          ),
                          const SizedBox(width: 8),
                        ],

                        // Chat Bubble
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: isUser ? Colors.orange : const Color(0xFF3A2E24),
                                borderRadius: BorderRadius.circular(16).copyWith(
                                  bottomRight: isUser ? const Radius.circular(0) : null,
                                  bottomLeft: !isUser ? const Radius.circular(0) : null,
                                ),
                                border: isUser ? null : Border.all(color: Colors.orange.withOpacity(0.3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                            ),
                            child: Text(
                                _messages[index]['text'],
                                style: TextStyle(
                                  color: isUser ? const Color(0xFF2A2118) : const Color(0xFFFDEDD4),
                                  fontSize: 15,
                                  height: 1.4,
                                )
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(color: Colors.orange),
              ),

            GlassContainer(
              padding: const EdgeInsets.all(12).copyWith(
                  bottom: MediaQuery.of(context).padding.bottom + 12
              ),
              borderRadius: BorderRadius.zero,
              color: Colors.black.withOpacity(0.3),
              border: const Border(top: BorderSide(color: Colors.white12)),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ask about the ruins...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF2A2118),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onSubmitted: (value) => _sendMessage(value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.black87),
                      onPressed: () => _sendMessage(_textController.text),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}