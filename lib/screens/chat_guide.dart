import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../const/api_config.dart';
import '../widgets/glass_container.dart';

class ChatGuideScreen extends StatefulWidget {
  final String? recognizedArtifact;

  const ChatGuideScreen({super.key, this.recognizedArtifact});

  @override
  State<ChatGuideScreen> createState() => _ChatGuideScreenState();
}

class _ChatGuideScreenState extends State<ChatGuideScreen> {
  String _selectedLanguage = 'English';

  final Map<String, String> _ttsLanguages = {
    'English': 'en-US',
    'Sinhala': 'si-LK',
  };

  final Map<String, String> _backendLangCodes = {
    'English': 'en',
    'Sinhala': 'si',
  };

  bool _isLoading = false;
  bool _hasShownImage = false;

  static final String _backendUrl = '${ApiConfig().baseUrl}/api/chat';

  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _initTts();

    if (widget.recognizedArtifact != null && widget.recognizedArtifact!.trim().isNotEmpty) {
      triggerDetectedSiteChat(widget.recognizedArtifact!);
    } else {
      _sendInitialGreeting();
    }
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");


    await _flutterTts.setSpeechRate(0.45);


    await _flutterTts.setPitch(1.15);


    try {
      List<dynamic> voices = await _flutterTts.getVoices;
      for (var voice in voices) {
        String voiceName = voice["name"].toString();
        if (voiceName.contains("Samantha") || voiceName.contains("Karen") || voiceName.contains("en-us-x-sfg")) {
          await _flutterTts.setVoice({"name": voice["name"], "locale": voice["locale"]});
          break;
        }
      }
    } catch (e) {
      debugPrint("Voice setting error: $e");
    }

    // 🌟 iOS Silent Mode Bypass
    await _flutterTts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker
      ],
      IosTextToSpeechAudioMode.defaultMode,
    );

    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });

    _flutterTts.setErrorHandler((msg) {
      debugPrint("TTS ERROR: $msg");
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  Future<void> _speak(String text) async {
    String cleanText = text.replaceAll(RegExp(r'\*|\#'), '');
    await _flutterTts.stop();
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
    const String greetingText = 'Welcome! I am your AI Heritage Guide. What historical site or artifact would you like to learn about today?';
    setState(() {
      _messages.add({
        'role': 'ai',
        'text': greetingText,
      });
    });
    _speak(greetingText);
  }

  Future<void> triggerDetectedSiteChat(String detectedSiteName) async {
    setState(() {
      _messages.add({
        'role': 'user',
        'text': "I am looking at $detectedSiteName. Can you tell me about it?"
      });
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': "Tell me the historical significance of $detectedSiteName.",
          'artifact_name': detectedSiteName,
          'target_lang_code': _backendLangCodes[_selectedLanguage] ?? 'en'
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _messages.add({
            'role': 'ai',
            'text': data['reply'] ?? "I found some information about this site.",

            'imageUrl': _hasShownImage ? null : data['image_url'],
          });
          _isLoading = false;


          if (data['image_url'] != null && data['image_url'].toString().isNotEmpty) {
            _hasShownImage = true;
          }
        });

        _scrollToBottom();
        _speak(data['reply'] ?? "");
      } else {
        throw Exception("API Error");
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'ai',
          'text': "My connection to the historical archives was interrupted.",
        });
        _isLoading = false;
      });
      _scrollToBottom();
    }
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
      final bool hasArtifact = widget.recognizedArtifact != null && widget.recognizedArtifact!.trim().isNotEmpty;
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': text,
          'artifact_name': hasArtifact ? widget.recognizedArtifact : null,
          'target_lang_code': _backendLangCodes[_selectedLanguage] ?? 'en'
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['reply'] ?? "No response from archives.";

        setState(() {
          _messages.add({
            'role': 'ai',
            'text': aiText,

            'imageUrl': _hasShownImage ? null : data['image_url']
          });
          _isLoading = false;

          if (data['image_url'] != null && data['image_url'].toString().isNotEmpty) {
            _hasShownImage = true;
          }
        });

        _scrollToBottom();
        _speak(aiText);

      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
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
          // 🌟 Back arrow එකේ පාට වෙනස් කිරීම
          iconTheme: const IconThemeData(
            color: Colors.orange,
            size: 28, // ටිකක් ලොකුවට පැහැදිලිව පේන්න
          ),

          // 🌟 Title එක ලස්සන කිරීම (පාට, ප්‍රමාණය, අකුරු වල ඝනකම සහ පරතරය)
          title: const Text(
              'Digital Guide',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.orange,
                letterSpacing: 1.2, // අකුරු අතර පොඩි ඉඩක් තියනවා ලස්සන වෙන්න
              )
          ),

          centerTitle: false, // Title එක වම් පැත්තට බරව තියෙන්න දෙනවා (Modern Look)
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
                  final message = _messages[index];
                  final isUser = message['role'] == 'user';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isUser) ...[
                          const CircleAvatar(
                            radius: 18,
                            backgroundImage: AssetImage('assets/guide_portrait.png'),
                            backgroundColor: Colors.transparent,
                          ),
                          const SizedBox(width: 8),
                        ],
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    message['text'],
                                    style: TextStyle(
                                      color: isUser ? const Color(0xFF2A2118) : const Color(0xFFFDEDD4),
                                      fontSize: 15,
                                      height: 1.4,
                                    )
                                ),
                                if (!isUser && message['imageUrl'] != null && message['imageUrl'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      message['imageUrl'],
                                      width: 250,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const SizedBox(
                                          height: 150,
                                          width: 250,
                                          child: Center(
                                            child: CircularProgressIndicator(color: Colors.orange),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ]
                              ],
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