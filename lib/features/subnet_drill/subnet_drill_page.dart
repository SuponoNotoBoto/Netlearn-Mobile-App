import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/audio/sfx_service.dart';
import '../../core/router/safe_back.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/nl_topbar.dart';
import '../achievements/achievement_service.dart';
import '../classes/class_controller.dart';
import '../dashboard_student/student_dashboard_controller.dart';
import 'subnet_drill_leaderboard.dart';
import 'subnet_drill_models.dart';

class SubnetDrillPage extends ConsumerStatefulWidget {
  const SubnetDrillPage({super.key});

  @override
  ConsumerState<SubnetDrillPage> createState() => _SubnetDrillPageState();
}

class _SubnetDrillPageState extends ConsumerState<SubnetDrillPage> {
  static const int _gameDuration = 60; // 60 seconds
  int _secondsLeft = _gameDuration;
  Timer? _timer;

  bool _isPlaying = false;
  int _score = 0;
  int _streak = 0;
  int _maxStreak = 0;
  int _correctCount = 0;
  int _totalAnswered = 0;
  int _highScore = 0;

  SubnetDrillQuestion? _currentQuestion;
  String? _selectedOption;
  bool _answeredThisRound = false;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadHighScore() async {
    final user = supabase.auth.currentUser;
    final activeClass = await resolveActiveStudentClass(ref);
    final classId = (activeClass != null && !activeClass.isLegacyFallback) ? activeClass.id : null;

    final userKey = user != null
        ? 'subnet_drill_high_score_${user.id}_${classId ?? "global"}'
        : 'subnet_drill_high_score_guest_${classId ?? "global"}';
    final prefs = await SharedPreferences.getInstance();
    var hs = prefs.getInt(userKey) ?? 0;

    if (mounted) {
      setState(() {
        _highScore = hs;
      });
    }

    if (user != null) {
      try {
        var query = supabase
            .from('subnet_drill_scores')
            .select('score')
            .eq('user_id', user.id);

        if (classId != null && classId.isNotEmpty) {
          query = query.eq('class_id', classId);
        } else {
          query = query.isFilter('class_id', null);
        }

        final row = await query
            .order('score', ascending: false)
            .limit(1)
            .maybeSingle();

        if (row != null && row['score'] != null) {
          final remoteScore = (row['score'] as num).toInt();
          final effective = remoteScore > hs ? remoteScore : hs;
          await prefs.setInt(userKey, effective);
          if (mounted) {
            setState(() {
              _highScore = effective;
            });
          }
        } else {
          // Kelas ini belum memiliki skor tersimpan untuk user ini:
          // Pastikan highscore adalah 0 (reset untuk kelas ini).
          await prefs.setInt(userKey, 0);
          if (mounted) {
            setState(() {
              _highScore = 0;
            });
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _saveHighScore(int score, {String? classId}) async {
    if (score > _highScore) {
      final user = supabase.auth.currentUser;
      final userKey = user != null
          ? 'subnet_drill_high_score_${user.id}_${classId ?? "global"}'
          : 'subnet_drill_high_score_guest_${classId ?? "global"}';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(userKey, score);
      if (mounted) {
        setState(() => _highScore = score);
      }
    }
  }

  void _startGame() {
    SfxService.instance.playPop();
    setState(() {
      _isPlaying = true;
      _secondsLeft = _gameDuration;
      _score = 0;
      _streak = 0;
      _maxStreak = 0;
      _correctCount = 0;
      _totalAnswered = 0;
      _selectedOption = null;
      _answeredThisRound = false;
    });

    _nextQuestion();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        _endGame();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _nextQuestion() {
    final isId = Localizations.localeOf(context).languageCode == 'id';
    setState(() {
      _currentQuestion = SubnetDrillQuestion.generate(isIndonesian: isId);
      _selectedOption = null;
      _answeredThisRound = false;
    });
  }

  void _handleSelectOption(String option) {
    if (_answeredThisRound || !_isPlaying) return;

    final isCorrect = option == _currentQuestion?.correctAnswer;
    setState(() {
      _answeredThisRound = true;
      _selectedOption = option;
      _totalAnswered++;

      if (isCorrect) {
        HapticFeedback.mediumImpact();
        SfxService.instance.playSuccess();
        _correctCount++;
        _streak++;
        if (_streak > _maxStreak) _maxStreak = _streak;

        // Base 10 points * streak multiplier
        double multiplier = 1.0;
        if (_streak >= 10) {
          multiplier = 3.0;
        } else if (_streak >= 5) {
          multiplier = 2.0;
        } else if (_streak >= 3) {
          multiplier = 1.5;
        }
        _score += (10 * multiplier).round();
      } else {
        HapticFeedback.heavyImpact();
        SfxService.instance.playError();
        _streak = 0;
      }
    });

    // Advance to next question after small visual pause
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted && _isPlaying) {
        _nextQuestion();
      }
    });
  }

  Future<void> _endGame() async {
    _timer?.cancel();
    setState(() => _isPlaying = false);

    final activeClass = await resolveActiveStudentClass(ref);
    final classId = (activeClass != null && !activeClass.isLegacyFallback) ? activeClass.id : null;

    await _saveHighScore(_score, classId: classId);

    // Resolve real student name from profiles / studentDashboardProvider
    final user = supabase.auth.currentUser;
    String studentName = 'Mahasiswa';

    if (user != null) {
      final cachedDashboard = ref.read(studentDashboardProvider).value;
      if (cachedDashboard != null && cachedDashboard.userName.trim().isNotEmpty) {
        studentName = cachedDashboard.userName.trim();
      } else {
        try {
          final profile = await supabase
              .from('profiles')
              .select('name')
              .eq('id', user.id)
              .maybeSingle();
          final dbName = profile?['name']?.toString().trim();
          if (dbName != null && dbName.isNotEmpty) {
            studentName = dbName;
          }
        } catch (_) {}
      }
    }

    // Save to class-scoped leaderboard
    await SubnetDrillLeaderboardService.saveScore(
      classId: classId,
      studentId: user?.id ?? 'guest',
      studentName: studentName,
      score: _score,
      maxStreak: _maxStreak,
    );

    // Check achievement unlock: 100+ points unlocks Subnet Master
    if (_score >= 100) {
      if (mounted) {
        AchievementService.unlockBadge(context, 'subnet_master');
      }
    }

    if (mounted) {
      _showGameOverDialog(classId: classId, className: activeClass?.name);
    }
  }

  void _showGameOverDialog({String? classId, String? className}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final accuracy = _totalAnswered > 0 ? ((_correctCount / _totalAnswered) * 100).round() : 0;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? NetLearnColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.military_tech_rounded, color: Color(0xFFFF9800), size: 28),
              const SizedBox(width: 10),
              Text(
                isId ? 'Waktu Habis!' : 'Time\'s Up!',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8C52FF), Color(0xFF6C2CE2)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      isId ? 'SKOR AKHIR' : 'FINAL SCORE',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (_score > _highScore)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD54F),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isId ? 'REKOR BARU! 🏆' : 'NEW HIGH SCORE! 🏆',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    isId ? 'Akurasi' : 'Accuracy',
                    '$accuracy%',
                    Icons.check_circle_outline_rounded,
                    const Color(0xFF4CAF50),
                  ),
                  _buildStatItem(
                    isId ? 'Max Combo' : 'Max Combo',
                    '${_maxStreak}x',
                    Icons.local_fire_department_rounded,
                    const Color(0xFFFF5722),
                  ),
                  _buildStatItem(
                    isId ? 'Benar' : 'Correct',
                    '$_correctCount/$_totalAnswered',
                    Icons.done_all_rounded,
                    const Color(0xFF2196F3),
                  ),
                ],
              ),
              if (_score >= 100) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFA000), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isId
                              ? 'Selamat! Lencana "Subnet Master" telah terbuka!'
                              : 'Congrats! "Subnet Master" badge unlocked!',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.emoji_events_rounded, size: 18, color: Color(0xFFFF9800)),
              label: Text(
                isId ? 'Peringkat' : 'Leaderboard',
                style: const TextStyle(color: Color(0xFFFF9800), fontWeight: FontWeight.w700),
              ),
              onPressed: () => showSubnetDrillLeaderboard(context, classId: classId, className: className),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                goBack(context, fallback: '/student');
              },
              child: Text(isId ? 'Keluar' : 'Exit'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: Text(isId ? 'Main Lagi' : 'Play Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8C52FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _startGame();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF8E8B9D)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final activeClass = ref.watch(activeStudentClassProvider).value;
    final classId = (activeClass != null && !activeClass.isLegacyFallback) ? activeClass.id : null;

    ref.listen(activeStudentClassProvider, (prev, next) {
      if (prev?.value?.id != next.value?.id) {
        _loadHighScore();
      }
    });

    return Scaffold(
      backgroundColor: context.background,
      appBar: NlTopBar(
        title: isId ? 'Speed Subnetting Drill' : 'Speed Subnetting Drill',
        onBack: () => goBack(context, fallback: '/student'),
        actions: IconButton(
          icon: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFB300)),
          tooltip: 'Papan Peringkat',
          onPressed: () => showSubnetDrillLeaderboard(context, classId: classId, className: activeClass?.name),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: _isPlaying
              ? _buildActiveGameView(isDark, isId)
              : _buildStartLobbyView(isDark, isId, classId, activeClass?.name),
        ),
      ),
    );
  }

  Widget _buildStartLobbyView(bool isDark, bool isId, [String? classId, String? className]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8C52FF), Color(0xFF6C2CE2)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8C52FF).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.speed_rounded,
              color: Colors.white,
              size: 56,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isId ? 'Tantangan Hitung Subnet' : 'Subnet Speed Challenge',
            style: TextStyle(
              fontFamily: AppTheme.displayFontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? NetLearnColors.darkText : const Color(0xFF1E1C29),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              isId
                  ? 'Jawab sebanyak mungkin soal Network, Broadcast, dan Usable Host dalam 60 detik! Raih skor 100+ untuk medali Subnet Master.'
                  : 'Answer as many Network, Broadcast, and Usable Host calculations in 60s! Score 100+ to earn the Subnet Master badge.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? NetLearnColors.darkMuted : const Color(0xFF787489),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 28),
          // High Score Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? NetLearnColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? NetLearnColors.darkLine : const Color(0xFFE5E2EE),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFB300), size: 24),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isId ? 'SKOR TERTINGGI' : 'HIGH SCORE',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF8E8B9D)),
                        ),
                        if (className != null && className.trim().isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            '($className)',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: context.accent,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '$_highScore Poin',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: 220,
            height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow_rounded, size: 24),
              label: Text(
                isId ? 'Mulai Drill' : 'Start Drill',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8C52FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              onPressed: _startGame,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFB300), size: 18),
            label: Text(
              isId ? 'Lihat Papan Peringkat' : 'View Leaderboard',
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF6C2CE2)),
            ),
            onPressed: () => showSubnetDrillLeaderboard(context, classId: classId, className: className),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveGameView(bool isDark, bool isId) {
    final q = _currentQuestion;
    if (q == null) return const SizedBox.shrink();

    final timeRatio = _secondsLeft / _gameDuration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Game Header Stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Score
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isId ? 'SKOR' : 'SCORE',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF8E8B9D)),
                ),
                Text(
                  '$_score',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF8C52FF)),
                ),
              ],
            ),
            // Streak Flame
            if (_streak > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5722).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF5722)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF5722), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${_streak}x STREAK',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF5722),
                      ),
                    ),
                  ],
                ),
              ),
            // Timer Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _secondsLeft <= 10 ? const Color(0xFFFFEBEE) : (isDark ? NetLearnColors.darkSurface : const Color(0xFFF3F0FA)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _secondsLeft <= 10 ? const Color(0xFFFF5252) : const Color(0xFF8C52FF).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: _secondsLeft <= 10 ? const Color(0xFFD32F2F) : const Color(0xFF8C52FF),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_secondsLeft s',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _secondsLeft <= 10 ? const Color(0xFFD32F2F) : (isDark ? Colors.white : const Color(0xFF1E1C29)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Countdown Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: timeRatio,
            minHeight: 6,
            backgroundColor: isDark ? NetLearnColors.darkLine : const Color(0xFFEDEAF5),
            valueColor: AlwaysStoppedAnimation<Color>(
              _secondsLeft <= 10 ? const Color(0xFFFF5252) : const Color(0xFF8C52FF),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Question Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: isDark ? NetLearnColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? NetLearnColors.darkLine : const Color(0xFFE5E2EE),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                q.questionText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? NetLearnColors.darkMuted : const Color(0xFF6B667C),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? NetLearnColors.darkApp : const Color(0xFFF3F0FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF8C52FF).withValues(alpha: 0.3)),
                ),
                child: Text(
                  q.ipWithCidr,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: Color(0xFF8C52FF),
                  ),
                ),
              ),
              if (_answeredThisRound) ...[
                const SizedBox(height: 12),
                Text(
                  q.explanation,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _selectedOption == q.correctAnswer ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Spacer(),

        // Options List (4 choices)
        ...q.options.map((opt) {
          final isSelected = opt == _selectedOption;
          final isCorrect = opt == q.correctAnswer;

          Color borderColor = isDark ? NetLearnColors.darkLine : const Color(0xFFE2DEEC);
          Color bgColor = isDark ? NetLearnColors.darkSurface : Colors.white;
          Color textColor = isDark ? NetLearnColors.darkText : const Color(0xFF1E1C29);

          if (_answeredThisRound) {
            if (isCorrect) {
              borderColor = const Color(0xFF4CAF50);
              bgColor = const Color(0xFFE8F5E9);
              textColor = const Color(0xFF1B5E20);
            } else if (isSelected) {
              borderColor = const Color(0xFFFF5252);
              bgColor = const Color(0xFFFFEBEE);
              textColor = const Color(0xFFB71C1C);
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: bgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: borderColor, width: isSelected || (_answeredThisRound && isCorrect) ? 2 : 1),
              ),
              child: InkWell(
                onTap: _answeredThisRound ? null : () => _handleSelectOption(opt),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        opt,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      if (_answeredThisRound && isCorrect)
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 22)
                      else if (_answeredThisRound && isSelected)
                        const Icon(Icons.cancel_rounded, color: Color(0xFFFF5252), size: 22),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
      ],
    );
  }
}

