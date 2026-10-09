
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const VoiceLabApp());
}

const audioChannel = MethodChannel('voice_changer/audio');

class VoiceLabApp extends StatelessWidget {
  const VoiceLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voice Lab',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0B14),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const VoiceLabHome(),
    );
  }
}

class VoiceLabHome extends StatefulWidget {
  const VoiceLabHome({super.key});

  @override
  State<VoiceLabHome> createState() => _VoiceLabHomeState();
}

class _VoiceLabHomeState extends State<VoiceLabHome> {
  bool enabled = false;
  bool loading = false;
  double pitch = 1.0;
  double echo = 0.0;
  double bass = 0.0;
  String status = 'พร้อมใช้งาน';

  Future<void> toggleAudio() async {
    if (loading) return;

    setState(() {
      loading = true;
    });

    try {
      if (enabled) {
        await audioChannel.invokeMethod('stopAudio');
        if (!mounted) return;
        setState(() {
          enabled = false;
          status = 'ปิดเอฟเฟกต์แล้ว';
        });
      } else {
        await audioChannel.invokeMethod('startAudio', {
          'pitch': pitch,
          'echo': echo,
          'bass': bass,
        });
        if (!mounted) return;
        setState(() {
          enabled = true;
          status = 'กำลังใช้ไมโครโฟน';
        });
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        status = e.message ?? 'เปิดระบบเสียงไม่สำเร็จ';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        status = 'ระบบเสียงยังไม่พร้อม';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> updateEffects() async {
    if (!enabled) return;

    try {
      await audioChannel.invokeMethod('setEffects', {
        'pitch': pitch,
        'echo': echo,
        'bass': bass,
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() {
        status = 'อัปเดตเอฟเฟกต์ไม่สำเร็จ';
      });
    }
  }

  Widget effectSlider({
    required String title,
    required String description,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151522),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: const Color(0xFFB9A0FF)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(description,
                        style: const TextStyle(
                            color: Color(0xFF9292A8), fontSize: 12)),
                  ],
                ),
              ),
              Text(display,
                  style: const TextStyle(
                      color: Color(0xFFC4B5FD),
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            onChanged: (v) {
              setState(() {
                onChanged(v);
              });
              updateEffects();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.graphic_eq,
                      color: Colors.white, size: 27),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('VOICE LAB',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              fontSize: 19)),
                      Text('OFFLINE VOICE EFFECTS',
                          style: TextStyle(
                              color: Color(0xFF88889F),
                              fontSize: 10,
                              letterSpacing: 1.4)),
                    ],
                  ),
                ),
                const Icon(Icons.tune, color: Color(0xFFAAA0D5)),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF211A3D), Color(0xFF111B31)],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFF6552A0).withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('VOICE CONTROL',
                            style: TextStyle(
                                fontSize: 12,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: enabled
                              ? const Color(0xFF14532D)
                              : Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          enabled ? 'ACTIVE' : 'STANDBY',
                          style: TextStyle(
                            fontSize: 10,
                            color: enabled
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFB6B6C8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 112,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(29, (i) {
                        final heights = [
                          12.0, 23.0, 17.0, 36.0, 25.0, 48.0, 30.0,
                          58.0, 40.0, 25.0, 51.0, 68.0, 38.0, 54.0,
                          29.0, 44.0, 62.0, 32.0, 47.0, 25.0, 55.0,
                          36.0, 19.0, 42.0, 28.0, 50.0, 33.0, 18.0, 12.0
                        ];
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 4,
                          height: enabled ? heights[i] : heights[i] * 0.35,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: enabled
                                  ? const [
                                      Color(0xFF60A5FA),
                                      Color(0xFFB794F6),
                                    ]
                                  : const [
                                      Color(0xFF45415F),
                                      Color(0xFF29263D),
                                    ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 22),
                  GestureDetector(
                    onTap: toggleAudio,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: enabled
                              ? const [Color(0xFF22C55E), Color(0xFF0F766E)]
                              : const [Color(0xFF9B72F2), Color(0xFF4F46E5)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (enabled
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFF8B5CF6))
                                .withOpacity(0.28),
                            blurRadius: 25,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: loading
                            ? const SizedBox(
                                width: 27,
                                height: 27,
                                child: CircularProgressIndicator(
                                    strokeWidth: 3, color: Colors.white),
                              )
                            : Icon(
                                enabled ? Icons.stop_rounded : Icons.power_settings_new,
                                color: Colors.white,
                                size: 38,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    enabled ? 'แตะเพื่อปิดเอฟเฟกต์' : 'แตะเพื่อเริ่มใช้งาน',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFFA5A5BC)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text('SOUND EFFECTS',
                style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 1.7,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            effectSlider(
              title: 'Pitch',
              description: 'ปรับโทนเสียงสูง–ต่ำ',
              icon: Icons.multitrack_audio,
              value: pitch,
              min: 0.7,
              max: 1.5,
              display: '${pitch.toStringAsFixed(2)}x',
              onChanged: (v) => pitch = v,
            ),
            const SizedBox(height: 12),
            effectSlider(
              title: 'Echo',
              description: 'เพิ่มเสียงสะท้อน',
              icon: Icons.waves,
              value: echo,
              min: 0,
              max: 1,
              display: '${(echo * 100).round()}%',
              onChanged: (v) => echo = v,
            ),
            const SizedBox(height: 12),
            effectSlider(
              title: 'Bass',
              description: 'เพิ่มน้ำหนักเสียงทุ้ม',
              icon: Icons.graphic_eq,
              value: bass,
              min: 0,
              max: 1,
              display: '${(bass * 100).round()}%',
              onChanged: (v) => bass = v,
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF151522),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: Color(0xFFA78BFA), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'เอฟเฟกต์ทำงานภายในแอป ต้องอนุญาตให้ใช้ไมโครโฟนก่อน และไม่ได้เปลี่ยนเสียงไมโครโฟนใน Discord หรือเกมอื่นโดยอัตโนมัติ',
                      style: TextStyle(
                          color: Color(0xFFAAAABD),
                          height: 1.5,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
