import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/localization/language_controller.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/utils/youtube_link.dart';
import '../../shared/widgets/nl_empty_state.dart';
import '../../shared/widgets/nl_skeleton.dart';
import '../../shared/widgets/nl_topbar.dart';
import '../classes/class_controller.dart';
import '../classes/class_models.dart';
import '../materials/student_materials_controller.dart';

SupabaseClient? _videoSupabaseOrNull() {
  try {
    return supabase;
  } catch (_) {
    return null;
  }
}

/// Fetch published learning videos scoped to the active class and role.
///
/// - Pada kelas nyata (`!isLegacyFallback`): selalu hanya membaca materi milik
///   kelas tersebut dan TIDAK PERNAH jatuh kembali ke materi template global
///   NetLearn (`class_id IS NULL`), termasuk ketika kelas belum memiliki video.
/// - Pada kelas kustom (modul tanpa `template_module_number`): hanya menampilkan
///   materi yang benar-benar memiliki tautan video valid, sesuai jumlah video
///   yang dimasukkan dosen di materi (tanpa kartu modul kosong).
/// - Pada kelas template / fallback legacy: satu kartu representatif per modul
///   inti (Modul 1–4), sesuai desain template NetLearn.
final videoListProvider = FutureProvider.autoDispose<List<VideoListItem>>((ref) async {
  // Watch active class selectors upfront so switching class updates this list.
  ref.watch(activeStudentClassIdProvider);
  ref.watch(activeLecturerClassIdProvider);

  final client = _videoSupabaseOrNull();
  String? role;
  final currentUser = client?.auth.currentUser;
  if (client != null && currentUser != null) {
    try {
      final profile = await client
          .from('profiles')
          .select('role')
          .eq('id', currentUser.id)
          .maybeSingle();
      role = profile?['role']?.toString();
    } catch (_) {}
  }

  final isLecturer = role == 'lecturer' || role == 'admin';
  final String? activeClassId;
  final bool isLegacyFallback;

  if (isLecturer) {
    final activeClass = await resolveActiveLecturerClass(ref);
    activeClassId = activeClass?.id;
    isLegacyFallback = activeClass == null || activeClass.isLegacyFallback;
  } else {
    final activeClass = await resolveActiveStudentClass(ref);
    activeClassId = activeClass?.id;
    isLegacyFallback = activeClass == null || activeClass.isLegacyFallback;
  }

  if (activeClassId != null && !isLegacyFallback) {
    final modRows = await supabase
        .from('class_modules')
        .select(
          'id, class_id, position, title, title_en, title_id, '
          'description, description_en, description_id, status, '
          'template_module_number',
        )
        .eq('class_id', activeClassId)
        .order('position');

    final classModules = (modRows as List)
        .map((r) => ClassModule.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();

    final hasTemplateModules = classModules.any(
      (m) => m.templateModuleNumber != null && m.templateModuleNumber! > 0,
    );
    final isCustomClass = !hasTemplateModules;

    final response = await supabase
        .from('materials')
        .select(
          'id, module_id, module_number, title, title_en, title_id, '
          'order_index, video_url, video_id',
        )
        .eq('class_id', activeClassId)
        .eq('published', true)
        .order('module_number')
        .order('order_index')
        .order('id');

    return buildVideoListItems(
      response as List,
      classModules: classModules,
      onlyWithVideo: isCustomClass,
      includeMultiplePerModule: isCustomClass,
      filterDraftModules: !isLecturer,
    );
  }

  final response = await supabase
      .from('materials')
      .select(
        'id, module_id, module_number, title, title_en, title_id, '
        'order_index, video_url, video_id',
      )
      .eq('published', true)
      .isFilter('class_id', null)
      .order('module_number')
      .order('order_index')
      .order('id');

  // Baris sudah terurut `module_number, order_index` dari database —
  // penyusunan kartu modul bergantung pada urutan ini (material pertama
  // tiap modul menjadi pilihan "material pertama").
  return buildVideoListItems(response as List);
});

class _SortableVideoEntry {
  final int sortModulePosition;
  final int orderIndex;
  final VideoListItem item;

  const _SortableVideoEntry({
    required this.sortModulePosition,
    required this.orderIndex,
    required this.item,
  });
}

/// Memetakan baris `materials` menjadi daftar [VideoListItem].
///
/// Fungsi murni — tanpa Supabase, tanpa Flutter — supaya pemilihan video pada
/// kelas kustom maupun template dapat diuji secara offline.
///
/// - Mode kelas kustom ([onlyWithVideo] = true, [includeMultiplePerModule] = true):
///   hanya menampilkan materi yang benar-benar memiliki tautan video YouTube
///   valid, sesuai seluruh video yang dimasukkan dosen pada materi. Modul atau
///   materi yang hanya berisi bacaan/PDF tidak memunculkan kartu "Video belum tersedia".
/// - Mode template / fallback legacy ([onlyWithVideo] = false, [includeMultiplePerModule] = false):
///   satu kartu per modul inti (`withVideo ?? anyMaterial`), mempertahankan tata
///   letak empat kartu template NetLearn.
List<VideoListItem> buildVideoListItems(
  List<dynamic> rows, {
  List<ClassModule> classModules = const <ClassModule>[],
  bool onlyWithVideo = false,
  bool includeMultiplePerModule = false,
  bool filterDraftModules = false,
}) {
  final moduleById = <String, ClassModule>{
    for (final cm in classModules) cm.id: cm,
  };

  ClassModule? findModuleByNumber(int number) {
    if (number < 1) return null;
    for (final cm in classModules) {
      if (resolveClassModuleNumber(cm) == number || cm.position == number) {
        return cm;
      }
    }
    return null;
  }

  final entries = <_SortableVideoEntry>[];

  for (final dynamic raw in rows) {
    final map = Map<String, dynamic>.from(raw as Map);
    final id = map['id']?.toString() ?? '';
    if (id.isEmpty) {
      continue;
    }

    final rawModuleId = map['module_id']?.toString().trim();
    final hasExplicitModuleId = rawModuleId != null && rawModuleId.isNotEmpty;
    final rawModuleNumber = (map['module_number'] as num?)?.toInt() ?? 0;

    final ClassModule? linkedModule = hasExplicitModuleId
        ? moduleById[rawModuleId]
        : findModuleByNumber(rawModuleNumber);

    if (filterDraftModules) {
      if (hasExplicitModuleId) {
        if (linkedModule == null || !linkedModule.isPublished) {
          continue;
        }
      } else if (linkedModule != null && !linkedModule.isPublished) {
        continue;
      }
    }

    final resolvedModuleNumber = linkedModule != null
        ? resolveClassModuleNumber(linkedModule)
        : rawModuleNumber;

    final effectiveModuleNumber = resolvedModuleNumber >= 1
        ? resolvedModuleNumber
        : (onlyWithVideo ? 1 : 0);

    // Di mode template/legacy hanya modul inti bernomor >= 1 yang muncul;
    // di kelas kustom video yang valid tetap tampil meski module_number 0/null.
    if (effectiveModuleNumber < 1) {
      continue;
    }

    final videoId = map['video_id']?.toString().trim() ?? '';
    final videoUrl = map['video_url']?.toString().trim() ?? '';
    final youtubeId =
        resolveYoutubeVideoId(videoId: videoId, videoUrl: videoUrl);

    if (onlyWithVideo && (youtubeId == null || youtubeId.isEmpty)) {
      continue;
    }

    final orderIndex = (map['order_index'] as num?)?.toInt() ?? 0;
    final sortPosition = linkedModule?.position ?? effectiveModuleNumber;

    entries.add(
      _SortableVideoEntry(
        sortModulePosition: sortPosition,
        orderIndex: orderIndex,
        item: VideoListItem(
          id: id,
          title: map['title']?.toString() ?? '',
          titleEn: map['title_en']?.toString() ?? '',
          titleId: map['title_id']?.toString() ?? '',
          moduleNumber: effectiveModuleNumber,
          youtubeVideoId: youtubeId,
        ),
      ),
    );
  }

  entries.sort((a, b) {
    final posCmp = a.sortModulePosition.compareTo(b.sortModulePosition);
    if (posCmp != 0) return posCmp;
    final modCmp = a.item.moduleNumber.compareTo(b.item.moduleNumber);
    if (modCmp != 0) return modCmp;
    final ordCmp = a.orderIndex.compareTo(b.orderIndex);
    if (ordCmp != 0) return ordCmp;
    return a.item.id.compareTo(b.item.id);
  });

  if (includeMultiplePerModule) {
    return [for (final entry in entries) entry.item];
  }

  // Modul -> material ber-video pertama.
  final withVideo = <int, VideoListItem>{};
  // Modul -> material pertama apa pun adanya (fallback kartu "belum tersedia").
  final anyMaterial = <int, VideoListItem>{};

  for (final entry in entries) {
    final item = entry.item;
    final moduleNumber = item.moduleNumber;
    if (item.youtubeVideoId != null && !withVideo.containsKey(moduleNumber)) {
      withVideo[moduleNumber] = item;
    }
    anyMaterial.putIfAbsent(moduleNumber, () => item);
  }

  final moduleNumbers = <int>{...withVideo.keys, ...anyMaterial.keys}.toList()
    ..sort();

  return [
    for (final moduleNumber in moduleNumbers)
      withVideo[moduleNumber] ?? anyMaterial[moduleNumber]!,
  ];
}

/// One card in the Learning Video list — always represents one module
/// (Modul 1–4). `youtubeVideoId` null berarti modulnya tidak punya tautan
/// video yang bisa dimainkan, dan kartu tidak boleh dinavigasi.
class VideoListItem {
  final String id;
  final String title;
  final String titleEn;
  final String titleId;
  final int moduleNumber;
  final String? youtubeVideoId;

  const VideoListItem({
    required this.id,
    required this.title,
    required this.titleEn,
    required this.titleId,
    required this.moduleNumber,
    this.youtubeVideoId,
  });

  String localizedTitle(String languageCode) {
    if (languageCode == 'id') {
      return titleId.isNotEmpty ? titleId : title;
    }
    return titleEn.isNotEmpty ? titleEn : title;
  }
}

/// The Learning Video list page — one card per core module, ordered by
/// module number. Both students and lecturers can access this page.
class VideoListPage extends ConsumerWidget {
  const VideoListPage({super.key});

  /// `/student` atau `/lecturer`, diambil dari matched location saat ini.
  ///
  /// Halaman ini terdaftar di kedua cabang role dengan widget yang sama, jadi
  /// tautan sisanya (notifikasi, pemutar video) harus mengikuti cabang yang
  /// sedang aktif — mendorong dosen ke `/student/video/...` membuat role guard
  /// memantulkannya kembali ke dashboard.
  static String? _areaBase(BuildContext context) {
    final location = GoRouter.of(context).state.matchedLocation;

    if (location == '/student/video-list' ||
        location.startsWith('/student/video-list/')) {
      return '/student';
    }

    if (location == '/lecturer/video-list' ||
        location.startsWith('/lecturer/video-list/')) {
      return '/lecturer';
    }

    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final videosAsync = ref.watch(videoListProvider);

    return Scaffold(
      backgroundColor: context.background,
      appBar: NlTopBar(
        title: l10n.learningVideo,
        onBack: () => context.pop(),
      ),
      body: RefreshIndicator(
        color: context.accent,
        onRefresh: () async {
          ref.invalidate(videoListProvider);
          await ref.read(videoListProvider.future);
        },
        child: videosAsync.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: const [
              NlSkeletonList(itemCount: 4),
            ],
          ),
          error: (error, stackTrace) => _ErrorView(
            onRetry: () => ref.invalidate(videoListProvider),
          ),
          data: (videos) {
            if (videos.isEmpty) {
              return NlEmptyState(
                icon: Icons.video_library_outlined,
                title: l10n.noVideoAvailable,
                message: l10n.noVideoAvailableMessage,
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // Header section — circle icon + title + subtitle.
                _HeaderSection(
                  moduleCount: {for (final v in videos) v.moduleNumber}.length,
                ),
                const SizedBox(height: 20),

                // Video list grouped by module.
                for (final video in videos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _VideoCard(
                      video: video,
                      // Modul tanpa tautan video yang bisa dimainkan tidak
                      // boleh dinavigasi: VideoPage hanya memainkan YouTube
                      // yang resolusi id-nya berhasil, jadi `onTap` diset
                      // null dan badge yang berbicara.
                      onTap: video.youtubeVideoId == null
                          ? null
                          : () {
                              // The player route follows the role branch this
                              // page was opened from. The route itself is
                              // identical on both branches (same VideoPage),
                              // but pushing a lecturer onto
                              // `/student/video/...` makes the role guard
                              // bounce them back to the dashboard.
                              final base = _areaBase(context);

                              if (base == null) {
                                return;
                              }

                              context.push('$base/video/${video.id}');
                            },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final int moduleCount;

  const _HeaderSection({required this.moduleCount});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            // `.circle.purple` dari index.css.
            color: NetLearnAccents.purple,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.videocam_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.learningVideo,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.videoListSubtitle(moduleCount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.mutedText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VideoCard extends ConsumerWidget {
  final VideoListItem video;

  /// Null saat video tidak tersedia — `InkWell.onTap` menerima null juga,
  /// jadi ripple dan navigasi sama sekali tidak terjadi.
  final VoidCallback? onTap;

  const _VideoCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final languageCode = ref.watch(languageProvider).languageCode;
    final title = video.localizedTitle(languageCode);
    final available = video.youtubeVideoId != null;

    return Semantics(
      button: available,
      label: '${l10n.moduleEyebrow(
        video.moduleNumber.toString().padLeft(2, '0'),
      ).toUpperCase()}, $title, '
          '${available ? l10n.videoLinkAvailable : l10n.videoLinkUnavailable}',
      child: ExcludeSemantics(
        child: Material(
          color: context.surface,
          borderRadius: BorderRadius.circular(NetLearnRadius.card),
          // Thumbnail 16:9 menempel ke tepi kartu; clip antiAlias membuat
          // sudut atasnya simetris dengan radius kartu — pola yang sama dengan
          // `_ModuleCard` di halaman Materials.
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(NetLearnRadius.card),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(NetLearnRadius.card),
                border: Border.all(color: context.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VideoThumbnail(
                    moduleNumber: video.moduleNumber,
                    youtubeVideoId: video.youtubeVideoId,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(NetLearnSpace.s15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.moduleEyebrow(
                            video.moduleNumber.toString().padLeft(2, '0'),
                          ).toUpperCase(),
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(height: NetLearnSpace.s6),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 16,
                            height: 1.3,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: NetLearnSpace.s12),
                        Row(
                          children: [
                            Icon(
                              Icons.videocam_outlined,
                              size: 14,
                              color: context.mutedText,
                            ),
                            const SizedBox(width: NetLearnSpace.s8),
                            Expanded(
                              child: Text(
                                l10n.videoListWatchVideo,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: context.mutedText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: NetLearnSpace.s12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _InfoBadge(
                              label: available
                                  ? l10n.videoLinkAvailable
                                  : l10n.videoLinkUnavailable,
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: available
                                  ? context.accent
                                  : context.mutedText,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thumbnail 16:9 dari `LearningVideos.tsx`:
///
/// 1. lapisan dasar selalu ilustrasi `.material-art` (gradien + ikon video +
///    nomor modul besar) — kalau thumbnail resmi gagal dimuat, inilah
///    yang tampil;
/// 2. di atasnya gambar `i.ytimg.com/vi/<id>/hqdefault.jpg` yang id ``ya
///    diresolusi dari kolom `video_id`/`video_url` yang tersimpan — bukan data
///    baru, hanya URL thumbnail resmi YouTube);
/// 3. lingkaran ungu Play hanya tampil ketika gambar itu dipakai.
class _VideoThumbnail extends StatefulWidget {
  final int moduleNumber;
  final String? youtubeVideoId;

  const _VideoThumbnail({
    required this.moduleNumber,
    required this.youtubeVideoId,
  });

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  bool _thumbnailFailed = false;

  @override
  Widget build(BuildContext context) {
    final youtubeId = widget.youtubeVideoId;
    final showThumbnail = youtubeId != null && !_thumbnailFailed;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Lapisan dasar = `.material-art`, gaya identik `_ModuleArt`:
          // gradien sama, ikon 44px, nomor modul 54px weight 800.
          Container(
            decoration: const BoxDecoration(
              gradient: NetLearnGradients.materialArt,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  Icons.videocam_outlined,
                  size: 44,
                  color: NetLearnColors.materialArtFg,
                ),
                Text(
                  widget.moduleNumber.toString().padLeft(2, '0'),
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: AppTheme.displayFontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 54,
                    height: 1,
                    color: NetLearnColors.materialArtNumber,
                  ),
                ),
              ],
            ),
          ),
          if (showThumbnail)
            Image.network(
              'https://i.ytimg.com/vi/$youtubeId/hqdefault.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Flag tidak boleh diset langsung di sini (mid-build);
                // jadwalkan rebuild satu frame setelahnya sehingga overlay
                // Play ikut hilang bersama gambarnya.
                if (!_thumbnailFailed) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _thumbnailFailed == false) {
                      setState(() => _thumbnailFailed = true);
                    }
                  });
                }

                return const SizedBox.shrink();
              },
            ),
          if (showThumbnail)
            Center(
              // `.circle.purple` 40px + ikon Play putih 20px.
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: NetLearnAccents.purple,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// `.badge` netral: latar `#f0f1f5` (gelap: `#252938`), teks muted, radius 6px.
///
/// [StatusBadge] selalu membawa ikon status; badge video ini teks pola, jadi
/// dibangun di sini dengan token yang sama (warna yang dibaca dari theme
/// extension agar varian gelap otomatis benar).
class _InfoBadge extends StatelessWidget {
  final String label;

  const _InfoBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = theme.extension<NetLearnStatusColors>();

    return Container(
      // `.badge` — padding 5px 7px, radius 6px, teks 9px weight 600.
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: statusColors?.neutralBg ?? NetLearnColors.neutralBg,
        borderRadius: BorderRadius.circular(NetLearnRadius.badge),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: statusColors?.neutralText ?? NetLearnColors.muted,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 46,
              color: context.mutedText,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.failedToLoad,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
