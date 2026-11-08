import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/localization/language_controller.dart';
import '../../core/progress/posttest_prompt.dart';
import '../../core/progress/progress_refresh.dart';
import '../../core/router/safe_back.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/learning_flow_status_model.dart';
import '../../shared/services/student_service.dart';
import '../../shared/utils/youtube_link.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import '../../shared/widgets/student_bottom_navbar.dart';
import '../classes/class_controller.dart';
import '../materials/student_materials_controller.dart';

/// Reasons the video page cannot be displayed. These are codes rather than
/// sentences so the message can be resolved in the active locale at render
/// time instead of being thrown as Indonesian text.
enum VideoFailure { noSession, notFound, unpublished, locked, noVideo }

class VideoLoadFailure implements Exception {
  final VideoFailure reason;

  const VideoLoadFailure(this.reason);
}

class VideoPage extends ConsumerStatefulWidget {
  final String materialId;

  const VideoPage({super.key, required this.materialId});

  @override
  ConsumerState<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends ConsumerState<VideoPage> {
  YoutubePlayerController? _youtubeController;

  StreamSubscription<YoutubeVideoState>? _positionSubscription;

  // Total runtime in seconds, read from the player once it is ready. Stays 0
  // when the player never reports it, which disables auto-completion and leaves
  // the manual button as the only way to finish.
  double _totalSeconds = 0;

  bool _isLoading = true;
  bool _isSaving = false;
  VideoFailure? _errorReason;

  // Raw localized variants are kept as loaded so that switching the app
  // language rebuilds this page in the new language without refetching.
  String _titleBase = '';
  String _titleEn = '';
  String _titleId = '';
  String _descriptionBase = '';
  String _descriptionEn = '';
  String _descriptionId = '';
  String? _videoId;
  bool _videoCompleted = false;
  bool _materialUnlocked = false;

  // Picks the right variant for [languageCode]. The base column is the
  // Indonesian copy, so it is preferred over the English column when
  // Indonesian is selected instead of showing English text.
  String _pick(
    String languageCode,
    String base,
    String english,
    String indonesian,
  ) {
    if (languageCode == 'id') {
      if (indonesian.isNotEmpty) {
        return indonesian;
      }
      if (base.isNotEmpty) {
        return base;
      }
      return english;
    }

    if (english.isNotEmpty) {
      return english;
    }
    if (base.isNotEmpty) {
      return base;
    }
    return indonesian;
  }

  // Fraction of the video that counts as watched.
  static const double _completionThreshold = 0.9;

  /// `/student` atau `/lecturer` — cabang route tempat halaman ini dibuka.
  ///
  /// Halaman terdaftar di kedua cabang role dengan widget yang sama. Fallback
  /// tombol kembali dan target lonceng harus mengikuti cabang tersebut: aksi
  /// dosen yang mendarat di `/student/**` dipantulkan role guard kembali ke
  /// dashboard, jadi bukan "kembali" yang pengguna rasakan.
  String _routeBase(BuildContext context) {
    final location = GoRouter.of(context).state.matchedLocation;

    return location.startsWith('/lecturer') ? '/lecturer' : '/student';
  }

  /// Dosen menonton video untuk meninjau materi, bukan untuk menyelesaikan
  /// progres belajar: `learning_progress` milik mahasiswa, jadi tombol
  /// "Mark as done" tidak ditampilkan dan posisi putar tidak pernah
  /// menulis progres.
  bool get _isLecturer => _routeBase(context) == '/lecturer';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVideo();
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _youtubeController?.close();
    super.dispose();
  }

  Future<void> _loadVideo() async {
    setState(() {
      _isLoading = true;
      _errorReason = null;
    });

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw const VideoLoadFailure(VideoFailure.noSession);
      }

      final material = await supabase
          .from('materials')
          .select(
            'id, title, title_en, title_id, '
            'description, description_en, description_id, '
            'video_url, video_id, published, lock_status',
          )
          .eq('id', widget.materialId)
          .maybeSingle();

      if (material == null) {
        throw const VideoLoadFailure(VideoFailure.notFound);
      }

      final published = material['published'] == true;
      final lockStatus = material['lock_status']?.toString() ?? 'default';

      if (!published) {
        throw const VideoLoadFailure(VideoFailure.unpublished);
      }

      if (lockStatus == 'locked') {
        throw const VideoLoadFailure(VideoFailure.locked);
      }

      // 'unlocked' (buka paksa dosen, 20261101130000) lewat sama seperti
      // 'default': hanya 'locked' yang memblokir video. Penegakan mark sebagai
      // selesai tetap di server (mark_video_completed via is_material_unlocked).

      final videoId = material['video_id']?.toString().trim();

      final videoUrl = material['video_url']?.toString().trim();

      // Shared with the admin form so the link an admin pastes and the id this page
      // plays are parsed by exactly one set of rules.
      final resolvedVideoId = resolveYoutubeVideoId(
        videoId: videoId,
        videoUrl: videoUrl,
      );

      if (resolvedVideoId == null || resolvedVideoId.isEmpty) {
        throw const VideoLoadFailure(VideoFailure.noVideo);
      }

      final progress = await StudentService.instance.getLearningProgress(
        widget.materialId,
      );

      final completed = progress?.videoCompleted == true;

      final controller = YoutubePlayerController.fromVideoId(
        videoId: resolvedVideoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          enableCaption: true,
          strictRelatedVideos: true,
          playsInline: true,
        ),
      );

      if (!mounted) {
        controller.close();
        return;
      }

      setState(() {
        _youtubeController = controller;
        _titleBase = material['title']?.toString() ?? '';
        _titleEn = material['title_en']?.toString() ?? '';
        _titleId = material['title_id']?.toString() ?? '';
        _descriptionBase = material['description']?.toString() ?? '';
        _descriptionEn = material['description_en']?.toString() ?? '';
        _descriptionId = material['description_id']?.toString() ?? '';
        _videoId = resolvedVideoId;
        _videoCompleted = completed;
        _materialUnlocked = true;
        _isLoading = false;
      });

      await _watchPlayback(controller);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorReason = e is VideoLoadFailure ? e.reason : VideoFailure.noVideo;
      });
    }
  }

  // Marks the video complete once it has been watched far enough, so a student
  // never has to remember to press the button before the next module unlocks.
  Future<void> _watchPlayback(YoutubePlayerController controller) async {
    try {
      _totalSeconds = await controller.duration;
    } catch (_) {
      _totalSeconds = 0;
    }

    // The chip under the title shows the real duration of the player, not
    // `duration_minutes` from the DB (that one is the study-time estimate).
    // Fill it in only once the player has reported a duration; if it never
    // does (e.g. embed blocked), the chip stays hidden instead of showing 0.
    if (mounted) {
      setState(() {});
    }

    _positionSubscription?.cancel();
    _positionSubscription = controller.videoStateStream.listen(
      _onPlaybackPosition,
    );
  }

  void _onPlaybackPosition(YoutubeVideoState state) {
    // Dosen tidak pernah menulis progres dari durasi menonton.
    if (_isLecturer) {
      return;
    }

    if (_videoCompleted ||
        _isSaving ||
        _totalSeconds <= 0 ||
        !_materialUnlocked) {
      return;
    }

    final watchedFraction =
        state.position.inMilliseconds / (_totalSeconds * 1000);

    if (watchedFraction >= _completionThreshold) {
      _markVideoCompleted();
    }
  }

  Future<void> _markVideoCompleted() async {
    // Keamanan ganda: tanpa tombol ini tidak bisa dipanggil di jalur dosen,
    // tapi panggilannya juga tidak boleh lolos lewat jalur lain (stream, dsb).
    if (_isLecturer) {
      return;
    }

    if (_isSaving || _videoCompleted) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Snapshot the flow before the write so the post-test prompt can be tied
      // to the completion that actually unlocked it rather than to any later
      // visit to a finished module. A failed snapshot only costs the prompt.
      final flowBefore = await _readFlowSnapshot();

      final activeClass = await resolveActiveStudentClass(ref);

      await StudentService.instance.markVideoCompleted(
        widget.materialId,
        classId: activeClass?.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _videoCompleted = true;
        _isSaving = false;
      });

      // Completion is decided by the write above, not by the refresh that
      // follows it: a throwing flow read used to show "gagal" over a progress
      // row that had already been stored.
      NlSnackBar.show(
        context,
        AppLocalizations.of(context)!.videoMarkedDone,
        tone: NlSnackTone.success,
      );

      // Completing this video is what unlocks the next module, moves the
      // dashboard percentage, and can unlock the post-test, so every provider
      // that caches a derived lock or completion flag is recomputed here --
      // guarded, because derived state must not fail a stored completion.
      try {
        await _refreshAndPromptPosttest(flowBefore);
      } catch (refreshErr) {
        debugPrint('post-write video flow refresh failed: $refreshErr');
      }
    } catch (e) {
      // The raw cause stays in the log; the UI only gets the neutral line.
      debugPrint('markVideoCompleted failed: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      NlSnackBar.show(
        context,
        AppLocalizations.of(context)!.failedToLoad,
        tone: NlSnackTone.error,
      );
    }
  }

  /// Learning-flow snapshot taken *before* a completion write.
  ///
  /// Returns `null` instead of throwing: the snapshot only feeds the post-test
  /// prompt, so a flow that cannot be read must not turn a successful write
  /// into a failed one.
  Future<LearningFlowStatusModel?> _readFlowSnapshot() async {
    try {
      return await ref.read(studentLearningFlowStatusProvider.future);
    } catch (error) {
      debugPrint('learning flow snapshot failed: $error');
      return null;
    }
  }

  /// Refreshes the flow after a completion write and offers the post-test on
  /// the locked-to-unlocked edge.
  ///
  /// Runs *after* the success snackbar and swallows its own failures: the
  /// progress row is already stored, so a refresh problem (`invalidate` raises
  /// if the container is already gone, a flow read can time out) may cost the
  /// prompt but must never be reported as a failed save.
  Future<void> _refreshAndPromptPosttest(
    LearningFlowStatusModel? flowBefore,
  ) async {
    if (flowBefore == null || !mounted) {
      return;
    }

    try {
      invalidateStudentProgress(ref);

      final flowAfter = await ref.read(studentLearningFlowStatusProvider.future);

      if (!mounted) {
        return;
      }

      await maybePromptPosttest(
        context,
        ref,
        wasUnlocked: flowBefore.posttestUnlocked,
        flow: flowAfter,
      );
    } catch (error) {
      debugPrint('post-write flow refresh failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watched so that changing the app language while this page is open
    // re-resolves the title and description in place.
    final languageCode = ref.watch(languageProvider).languageCode;
    final l10n = AppLocalizations.of(context)!;
    final pickedTitle = _pick(languageCode, _titleBase, _titleEn, _titleId);
    final localizedTitle = pickedTitle.isEmpty
        ? l10n.videoLearning
        : pickedTitle;
    final localizedDescription = _pick(
      languageCode,
      _descriptionBase,
      _descriptionEn,
      _descriptionId,
    );

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: context.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () =>
              goBack(context, fallback: '${_routeBase(context)}/video-list'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          l10n.videoLearning,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.push('${_routeBase(context)}/notifications');
            },
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: _buildBody(localizedTitle, localizedDescription),
      // Navbar bawah hanya untuk mahasiswa: `/lecturer/video/:id` adalah
      // sub-page yang di-push dari dashboard, dan StudentBottomNavbar akan
      // menautkan dosen ke route mahasiswa yang langsung dipantulkan guard.
      bottomNavigationBar:
          GoRouter.of(context).state.matchedLocation.startsWith('/lecturer')
              ? null
              : const StudentBottomNavbar(currentIndex: 0),
    );
  }

  /// Resolves a failure code to a message in the active locale.
  String _messageForFailure(BuildContext context, VideoFailure reason) {
    final l10n = AppLocalizations.of(context)!;

    switch (reason) {
      case VideoFailure.noSession:
        return l10n.failedToLoad;
      case VideoFailure.notFound:
        return l10n.materialNotFound;
      case VideoFailure.unpublished:
        return l10n.materialNotPublished;
      case VideoFailure.locked:
        return l10n.materialLockedMessage;
      case VideoFailure.noVideo:
        return l10n.videoNotAvailable;
    }
  }

  Widget _buildBody(String localizedTitle, String localizedDescription) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorReason != null) {
      return _ErrorView(
        message: _messageForFailure(context, _errorReason!),
        onRetry: _loadVideo,
      );
    }

    if (!_materialUnlocked || _youtubeController == null || _videoId == null) {
      return _ErrorView(
        message: AppLocalizations.of(context)!.videoNotAvailable,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVideo,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _buildPlayer(),
          const SizedBox(height: 22),
          Text(
            'VIDEO PEMBELAJARAN',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(letterSpacing: 1.3),
          ),
          const SizedBox(height: 8),
          Text(
            localizedTitle,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontSize: 22),
          ),
          if (_totalSeconds > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 15,
                  color: context.mutedText,
                ),
                const SizedBox(width: 5),
                Text(
                  // Real player duration, not the material's study-time
                  // estimate (`duration_minutes` lives in the edit form).
                  AppLocalizations.of(context)!
                      .durationMinutes((_totalSeconds / 60).ceil()),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
          if (localizedDescription.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.raisedSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.border),
              ),
              child: Text(
                localizedDescription,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: NetLearnColors.ink, height: 1.6),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _buildCompletionButton(),
          const SizedBox(height: 12),
          if (_videoCompleted) _buildNextStepButton(),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: YoutubePlayer(controller: _youtubeController!),
      ),
    );
  }

  Widget _buildCompletionButton() {
    // Dosen tidak punya progres belajar untuk ditandai — tombolnya tidak
    // dirender sama sekali, bukan sekadar dinonaktifkan (disabled button yang
    // tidak berarti justru membingungkan).
    if (_isLecturer) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: _videoCompleted || _isSaving ? null : _markVideoCompleted,
        icon: _isSaving
            ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                _videoCompleted
                    ? Icons.check_circle_rounded
                    : Icons.check_rounded,
              ),
        label: Text(
          _videoCompleted
              ? AppLocalizations.of(context)!.videoDone
              : AppLocalizations.of(context)!.markVideoDone,
        ),
      ),
    );
  }

  Widget _buildNextStepButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () {
          goBack(context, fallback: '${_routeBase(context)}/video-list');
        },
        icon: const Icon(Icons.arrow_back_rounded),
        label: Text(AppLocalizations.of(context)!.backToMaterial),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorView({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 52,
              color: context.mutedText,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.videoCannotOpen,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(height: 1.5),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onRetry,
                child: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
