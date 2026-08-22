import 'package:flutter/material.dart';
import 'dart:ui'; // 🌟 BackdropFilter එකට ඕනේ

class InfoCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onPlayAudio;
  final bool isPlaying;

  const InfoCard({
    Key? key,
    required this.title,
    required this.description,
    required this.onPlayAudio,
    required this.isPlaying,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20), // 🌟 ලස්සන රවුම් මුලු
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // 🌟 Glass/Blur Effect එක
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4), // 🌟 කළු පාටට හුරු වීදුරු පෙනුම
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.orange.withOpacity(0.3), // 🌟 තැඹිලි පාට මායිමක්
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title and Play Button Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.orange, // 🌟 Title එක ඔයා කැමති තැඹිලි පාටින්!
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  // 🌟 Audio Play Button
                  GestureDetector(
                    onTap: onPlayAudio,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Description Text
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.5, // 🌟 කියවන්න ලේසි වෙන්න ලයින් අතර ඉඩ
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}