import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'nl_tap_scale.dart';

/// `.bottom-nav` dari index.css: bar navigasi bawah lima slot.
///
/// ```css
/// .bottom-nav{height:73px;background:#fff;display:flex;align-items:center;
///             justify-content:space-around;border-top:1px solid #eceef2;
///             flex-shrink:0;padding:4px 10px 0;z-index:5}
/// .bottom-nav button{width:60px;display:flex;align-items:center;
///             flex-direction:column;gap:5px;color:#9c9fac;position:relative}
/// .bottom-nav button>span{height:23px}
/// .bottom-nav small{font-size:9px}
/// .bottom-nav .nav-active{color:#543cd1}
/// .nav-active i{position:absolute;width:4px;height:4px;bottom:-7px;
///             border-radius:50%;background:#543cd1}
/// .bottom-nav .center-nav{margin-top:-22px;color:#6c727f;gap:6px}
/// .center-nav>span{width:52px;height:52px!important;display:grid;
///             place-items:center;background:#4e33c8;color:white;
///             border-radius:50%;border:5px solid #f4f5fa;
///             box-sizing:content-box;box-shadow:0 3px 8px #4e33c820}
/// ```
///
/// Widget ini murni presentasi: ia tidak tahu route apa pun, hanya melaporkan
/// indeks yang ditekan lewat [onSelect]. `StudentBottomNavbar` dan
/// `LecturerBottomNavbar` masing-masing memetakan indeks itu ke `context.go()`
/// milik role-nya, sehingga kedua bar bisa berbagi tampilan tanpa pernah
/// berbagi tujuan navigasi.
///
/// Lebar slot memakai `Expanded`, bukan `width:60px` milik CSS. Pada lebar 360dp
/// empat slot tab berbagi sisa ruang, dan `Expanded` membuat label bahasa
/// Indonesia yang panjang ikut menyusut bersama slot-nya alih-alih menimpa
/// tetangganya.
class NlBottomNavBar extends StatelessWidget {
  final List<NlNavDestination> destinations;

  final int currentIndex;

  final ValueChanged<int> onSelect;

  const NlBottomNavBar({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // `background:#fff` + `border-top:1px solid #eceef2`
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(top: BorderSide(color: context.border)),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : NetLearnShadows.navTop,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          // `padding:4px 10px 0` sudah termasuk di dalam `height:73px`, dan
          // `border-top:1px` ikut memotong tinggi itu, jadi tinggi bagian dalam
          // hanya 72px agar tinggi total bar tepat 73px seperti desain.
          padding: const EdgeInsets.only(
            top: NetLearnSpace.s4,
            left: NetLearnSpace.s10,
            right: NetLearnSpace.s10,
          ),
          height: 72,
          child: Row(
            children: [
              for (var index = 0; index < destinations.length; index++)
                destinations[index].isCenter
                    ? _CenterAction(
                        label: destinations[index].label,
                        selected: index == currentIndex,
                        onTap: () => onSelect(index),
                      )
                    : Expanded(
                        child: NlNavItem(
                          label: destinations[index].label,
                          icon: destinations[index].icon,
                          activeIcon: destinations[index].activeIcon,
                          selected: index == currentIndex,
                          onTap: () => onSelect(index),
                        ),
                      ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Satu tujuan navigasi pada [NlBottomNavBar].
///
/// Slot tengah ditandai [isCenter] supaya memakai perlakuan tombol terangkat
/// (`.center-nav`) alih-alih perlakuan tab biasa.
class NlNavDestination {
  final String label;
  final IconData icon;

  /// Ikon saat slot sedang dipilih. Berbeda dari [icon] supaya keadaan aktif
  /// tidak hanya mengandalkan warna.
  final IconData activeIcon;

  final bool isCenter;

  const NlNavDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.isCenter = false,
  });
}

/// Satu tab biasa pada [NlBottomNavBar].
class NlNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final VoidCallback onTap;

  /// `height:23px` milik `.bottom-nav button>span`.
  static const double iconSlotHeight = 23;

  /// `gap:5px` milik `.bottom-nav button`.
  static const double _iconLabelGap = 5;

  /// Lebar titik indikator `.nav-active i`.
  static const double _dotSize = 4;

  /// `bottom:-7px` milik `.nav-active i`.
  static const double _dotOffset = 7;

  const NlNavItem({
    super.key,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final active = context.accent;

    // `.bottom-nav button` = `#9c9fac`, bukan `muted` (`#6c727f`).
    final inactive = isDark
        ? NetLearnColors.darkMuted
        : NetLearnColors.navInactive;

    final color = selected ? active : inactive;

    // `small` = `font-size:9px`
    final labelStyle = TextStyle(
      fontSize: 9,
      color: color,
      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
    );

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      // Aksi ketukan dideklarasikan di node semantik, bukan hanya di `InkWell`.
      // `excludeSemantics: true` di bawah membuang seluruh semantik anak,
      // termasuk aksi `InkWell`, jadi tanpa `onTap` di sini tujuan navigasi
      // jadi tidak bisa diketuk sama sekali oleh TalkBack.
      onTap: onTap,
      // Tanpa ini, `Text` di dalam `InkWell` ikut menyumbang label yang sama
      // dan node hasilnya berbunyi "Dashboard\nDashboard".
      excludeSemantics: true,
      child: NlTapScale(
        scaleDown: 0.92,
        child: InkWell(
          onTap: onTap,
          // `InkSparkle` bawaan Material 3 memuat shader dari aset dan tidak ada di
          // lingkungan `flutter test`, jadi setiap ketukan di bar akan melempar
          // `Asset 'shaders/ink_sparkle.frag' not found`. `InkRipple` memberi umpan
          // balik yang sama tanpa aset shader, dan ini juga bawaan Material pada
          // tema non-Android.

          splashFactory: InkRipple.splashFactory,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: iconSlotHeight,
                child: AnimatedScale(
                  scale: selected ? 1.06 : 1.0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: Icon(selected ? activeIcon : icon, size: 22, color: color),
                ),
              ),

              const SizedBox(height: _iconLabelGap),

              // Titik indikator digambar sebagai Stack di dalam label, bukan
              // sebagai elemen layout, supaya `bottom:-7px` benar-benar menggambar
              // di bawah label tanpa menambah tinggi bar.
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),

                  if (selected)
                    Positioned(
                      bottom: -_dotOffset,
                      child: Container(
                        width: _dotSize,
                        height: _dotSize,
                        decoration: BoxDecoration(
                          color: active,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.center-nav`: tombol tengah yang terangkat keluar dari bar.
class _CenterAction extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// `width:52px;height:52px` milik `.center-nav>span`.
  static const double circleSize = 52;

  /// `border:5px solid` milik `.center-nav>span`.
  static const double ringWidth = 5;

  /// `margin-top:-22px` milik `.center-nav`.
  static const double lift = 22;

  /// Lebar slot tengah di bar. Lebih besar dari lingkarannya supaya label
  /// "AR Scanner" di bawahnya tidak menyentuh tetangganya.
  static const double slotWidth = 82;

  const _CenterAction({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Panjang label dipatok ke satu baris supaya text scale platform tidak
    // mendorong kolom melewati tinggi bar dan memicu overflow.
    final labelStyle = TextStyle(
      fontSize: 9,
      height: 1,
      color: selected
          ? context.accent
          : (isDark ? NetLearnColors.darkMuted : NetLearnColors.muted),
      fontWeight: FontWeight.w800,
    );

    // Ukuran ikon tengah tidak disebut di index.css. Nilainya mengikuti rasio
    // ikon terhadap lingkaran yang sudah dipakai sebelum tahap ini, yaitu
    // 27/56, jadi untuk lingkaran 52px menjadi 25px.
    const double iconSize = 25;

    return SizedBox(
      width: slotWidth,
      child: Transform.translate(
        offset: const Offset(0, -lift),
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          // Lihat catatan `onTap` di [NlNavItem]: aksi harus ada di node
          // semantik karena `excludeSemantics` membuangnya dari `InkWell`.
          onTap: onTap,
          // Sama seperti [NlNavItem]: mencegah label terbaca dua kali.
          excludeSemantics: true,
          child: NlTapScale(
            scaleDown: 0.92,
            child: InkWell(
              // `InkWell`, bukan `GestureDetector`: versi lama tidak bisa
              // difokuskan dari keyboard maupun dijangkau TalkBack.
              onTap: onTap,
              // Lihat catatan `splashFactory` di [NlNavItem].
              splashFactory: InkRipple.splashFactory,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      // `.center-nav>span` = `background:#8c52ff`
                      color: NetLearnColors.primary,
                      shape: BoxShape.circle,
                      // Cincin mengikuti warna bar tepat di belakangnya supaya
                      // terbaca sebagai celah, bukan sebagai warna kedua.
                      // `index.css` menulis `#f4f5fa`; memakai warna bar memberi
                      // hasil visual yang sama di terang dan benar di gelap.
                      border: Border.all(
                        color: context.surface,
                        width: ringWidth,
                      ),
                      // `box-shadow:0 3px 8px #4e33c820`
                      boxShadow: NetLearnShadows.navCenter,
                    ),
                    child: Icon(
                      Icons.view_in_ar_rounded,
                      color: NetLearnColors.white,
                      size: iconSize,
                    ),
                  ),

                  // `gap:6px` milik `.center-nav`
                  const SizedBox(height: NetLearnSpace.s6),

                  // Label dikunci pada skala teks platform. Alasannya nilai, bukan
                  // selera: tinggi isi bar hanya 69px (`height:73px` dikurangi
                  // `padding-top:4px`), sedangkan lingkaran 52px dan jarak 6px
                  // sudah memakai 58px. Pada text scale 1.3 label 9px tumbuh jadi
                  // sekitar 11.7px sehingga kolom jadi 69.7px dan meluber 1px.
                  //
                  // Menghapus kunci ini akan mengembalikan overflow yang sama, dan
                  // menaikkan tinggi bar akan mengubah sisa layout. Label ini
                  // sekunder secara visual -- tombol besarnya yang menentukan --
                  // dan tetap terbaca utuh oleh pembaca layar karena yang dikirim
                  // ke Semantics adalah stringnya, bukan teks yang diskalakan.
                  // Pola yang sama dipakai `NlLanguageRow`.
                  MediaQuery.withNoTextScaling(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: labelStyle,
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
