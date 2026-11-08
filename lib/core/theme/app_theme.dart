import 'package:flutter/material.dart';

/// Token warna dan tipografi diambil langsung dari index.css (desain Figma Make
/// terbaru), bukan dari palet hijau yang dipakai versi desain sebelumnya.
///
/// Dua nama lama â€” `forest` (hijau tua) dan `mint` (hijau muda) â€” sengaja
/// dipertahankan sebagai alias yang menunjuk ke token ungu yang baru, supaya
/// tidak ada file yang langsung rusak saat palet ditukar. Halaman yang masih
/// memakai alias tersebut diganti ke nama semantik saat masing-masing fiturnya
/// dirapikan, dan aliasnya dihapus di tahap terakhir.
class NetLearnColors {
  NetLearnColors._();

  // ---------------------------------------------------------------------
  // Brand â€” `--primary:#543cd1` dan gradient hero `115deg,#1e126b,#4e33c8`
  // ---------------------------------------------------------------------

  /// Warna aksi utama: tombol, ikon aktif, angka statistik.
  /// Warna aksi utama: tombol, ikon aktif, angka statistik (`--primary-action` / `--color-purple-500` = `#8C52FF`).
  static const primary = Color(0xFF8C52FF);
  static const purple50 = Color(0xFFF6F4FD);
  static const purple100 = Color(0xFFECE6FF);
  static const purple500 = Color(0xFF8C52FF);
  static const lavender300 = Color(0xFFA6B1E1);
  static const pink300 = Color(0xFFFFB6C1);
  static const neutral900 = Color(0xFF1D1C21);
  static const neutral500 = Color(0xFF75747E);
  static const neutral200 = Color(0xFFF2EFFE);
  static const cardBannerBg = Color(0xFFECE6FF);
  static const statusAttendance = Color(0xFFA6B1E1);
  static const statusPending = Color(0xFFFFB6C1);

  /// Ujung gelap gradient hero (`#1e126b`).
  static const primaryDeep = Color(0xFF1E126B);

  /// Ujung terang gradient hero (`#4e33c8`), juga warna status bar di atas hero.
  static const primaryMid = Color(0xFF4E33C8);

  /// Status bar yang menempel ke hero: `--on-purple` = `#25177d`.
  static const primaryStatusBar = Color(0xFF25177D);

  /// Ujung terang track progres (`#8a70ea`).
  static const primarySoft = Color(0xFF8A70EA);

  /// Teks brand sekunder yang masih harus terbaca di atas putih
  /// (`.eyebrow` = `#8b78b6`, dinaikkan agar lolos WCAG AA).
  static const primaryMuted = Color(0xFF6B57C4);

  /// Isian tombol sekunder (`.button.secondary` = `#f0ecfb`).
  static const primaryTint = Color(0xFFECE6FF);

  /// Latar.tile ungu muda: avatar, nomor modul, chip
  /// (`.module-number` = `#f3e8ff`, `.unified-avatar` = `#e6ddff`).
  static const primaryTintSoft = Color(0xFFE9E3FB);

  /// Warna huruf di dalam [primaryTintSoft] (`.module-number` = `#885bc8`).
  static const primaryOnTint = Color(0xFF6243AD);

  /// Aksen terang untuk teks di atas gradient (`.brand-dot` = `#b7abff`).
  static const primaryBright = Color(0xFFB7ABFF);

  // ---------------------------------------------------------------------
  // Teks dan avatar di atas gradien hero
  //
  // Nilai di sini hanya dipakai di dalam [NetLearnGradients.hero], jadi tidak
  // punya pasangan dark: permukaannya selalu gradient ungu, bukan surface yang
  // mengikuti tema.
  // ---------------------------------------------------------------------

  /// Label kecil di atas sapaan (`.greeting p` = `#c9c1ee`).
  static const heroSurfaceLabel = Color(0xFFC9C1EE);

  /// Baris pendukung di bawah nama (`.greeting>div>span` = `#d4cdf2`).
  static const heroSurfaceBody = Color(0xFFD4CDF2);

  /// Latar lingkaran avatar di hero (`.avatar` = `#e6dcff`).
  ///
  /// Berbeda dengan [primaryTintSoft] (`#e9e3fb`) yang dipakai avatar profil di
  /// atas permukaan putih, jadi keduanya sengaja terpisah.
  static const heroAvatarBg = Color(0xFFE6DCFF);

  /// Warna huruf avatar di hero (`.avatar` = `#6040ad`).
  static const heroAvatarFg = Color(0xFF6040AD);

  // ---------------------------------------------------------------------
  // Netral
  // ---------------------------------------------------------------------

  static const white = Color(0xFFFFFFFF);

  /// Latar halaman (`.phone` = `#f4f5fa`).
  static const appBg = Color(0xFFF6F4FD);

  /// Teks utama (`body` = `#1a1d26`).
  static const ink = Color(0xFF1D1C21);

  /// Teks sekunder (`--muted` = `#6c727f`).
  static const muted = Color(0xFF75747E);

  /// Garis rambut kartu dan pemisah (`--border` = `#eceef2`).
  static const line = Color(0xFFF2EFFE);

  /// Border isian yang sedikit lebih tegas (`.field input` = `#e3e4ec`).
  static const lineDark = Color(0xFFE3E4EC);

  /// Latar badge netral (`.badge` = `#f0f1f5`).
  static const neutralBg = Color(0xFFF2EFFE);

  /// Teks badge netral (`.badge` = `#9297a4`).
  static const neutralText = Color(0xFF7B8091);

  // ---------------------------------------------------------------------
  // Permukaan panel dan penanda
  // ---------------------------------------------------------------------

  /// Latar kotak nomor modul (`.module-number` = `#f3e8ff`).
  static const moduleNumberBg = Color(0xFFF3E8FF);

  /// Warna angka di dalam [moduleNumberBg] (`.module-number` = `#885bc8`).
  static const moduleNumberFg = Color(0xFF885BC8);

  /// Penanda modul terkunci (`.muted-number` = `#f1f2f7`).
  static const mutedNumberBg = Color(0xFFF1F2F7);

  /// Teks penanda modul terkunci (`.muted-number` = `#a4a7b4`).
  static const mutedNumberFg = Color(0xFFA4A7B4);

  /// Latar panel ringkasan progres (`.progress-summary` = `#efecfc`).
  static const progressPanelBg = Color(0xFFEFECFC);

  /// Garis panel ringkasan progres
  /// (`.progress-summary` = `border:1px solid #e5e0f8`).
  static const progressPanelBorder = Color(0xFFE5E0F8);

  /// Aksen blok ilustrasi kartu materi (`.material-art` = `#7f67cf`).
  ///
  /// not verified: `index.css` tidak punya pasangan `.dark-theme` untuk
  /// `.material-art`, tapi blok itu memakai gradient terang yang sama di kedua
  /// tema, jadi warnanya tidak pernah mengikuti tema.
  static const materialArtFg = Color(0xFF7F67CF);

  /// Angka besar di dalam blok ilustrasi (`.material-art>span` = `#d4c9f2`).
  ///
  /// not verified: sama seperti [materialArtFg], tidak ada pasangan gelap di
  /// `index.css` dan gradiennya tidak berubah di mode gelap.
  static const materialArtNumber = Color(0xFFD4C9F2);

  /// Latar track progres yang belum terisi (`.progress-track` = `#e4def5`).
  static const progressTrackBg = Color(0xFFE4DEF5);

  /// Latar segmented control (`.tabs` = `#eaeaf3`).
  static const tabsBg = Color(0xFFEAEAF3);

  // ---------------------------------------------------------------------
  // Label kecil
  //
  // `index.css` memakai abu-lavender yang lebih gelap dari `--muted`
  // (`#6c727f`) untuk label kecil, jadi keempatnya dipisah dari [muted].
  //
  // not verified: tidak ada aturan `.dark-theme` untuk keempat class ini,
  // jadi mode gelap memakai [darkMuted].
  // ---------------------------------------------------------------------

  /// Ikon kecil di samping judul section (`.small-icon` = `#9d92cb`).
  static const sectionIcon = Color(0xFF9D92CB);

  /// Label di panel ringkasan progres (`.progress-summary span` = `#6c6290`).
  static const progressSummaryLabel = Color(0xFF6C6290);

  /// Baris bawah panel progres (`.progress-summary p` = `#78718e`).
  static const progressSummaryCaption = Color(0xFF78718E);

  /// Label kecil pada baris modul (`.module-row small` = `#8d91a0`).
  static const moduleRowEyebrow = Color(0xFF8D91A0);

  // ---------------------------------------------------------------------
  // Kontrol
  // ---------------------------------------------------------------------

  /// Track sakelar tema dalam keadaan mati (`.theme-switch` = `#dcdce7`).
  ///
  /// not verified: `index.css` tidak punya aturan `.dark-theme .theme-switch`,
  /// jadi mode gelap memakai [darkLine].
  static const themeSwitchOff = Color(0xFFDCDCE7);

  // ---------------------------------------------------------------------
  // Navigasi
  // ---------------------------------------------------------------------

  /// Ikon dan label tab yang tidak dipilih
  /// (`.bottom-nav button` = `#9c9fac`).
  ///
  /// Berbeda dari [muted] (`#6c727f`): nilai desain lebih pucat supaya tab aktif
  /// dan tidak aktif tidak terlihat sama beratnya.
  ///
  /// not verified: `index.css` tidak punya aturan `.dark-theme` untuk
  /// `.bottom-nav button`, jadi mode gelap memakai [darkMuted].
  static const navInactive = Color(0xFF9C9FAC);

  /// Segmen terpilih pada segmented control dalam mode gelap
  /// (`.dark-theme .tabs .selected` = `#34304e`).
  static const tabsSelectedDark = Color(0xFF34304E);

  /// Titik indikator aktif pada avatar di dalam gradien
  /// (`.avatar>span` = `#54cf99`).
  ///
  /// Selalu hijau di kedua tema karena avatar selalu berada di atas gradient
  /// ungu, bukan di atas permukaan.
  static const heroOnlineDot = Color(0xFF54CF99);

  /// Cincin di sekitar titik indikator (`.avatar>span` = `border:2px solid #4230b4`).
  static const heroOnlineDotRing = Color(0xFF4230B4);

  // ---------------------------------------------------------------------
  // Status
  // ---------------------------------------------------------------------

  /// Aksen bahaya (`.revoke-button`, `.unified-logout` = `#eb5757`).
  static const danger = Color(0xFFEB5757);

  /// Latar bahaya (`.unified-logout:hover` = `#fff3f3`).
  static const dangerBg = Color(0xFFFFF3F3);

  /// Teks bahaya; dinaikkan dari `#eb5757` agar tetap â‰¥ 4.5:1 di atas [dangerBg].
  static const dangerText = Color(0xFFD14343);

  /// Latar peringatan (`.warning` = `#fff4de`).
  static const warningBg = Color(0xFFFFF4DE);

  /// Teks peringatan (`.warning` = `#967022`).
  static const warningText = Color(0xFF8A671C);

  /// Sukses (`.badge.success` text = `#28856a`, `.is-active` = `#35a47d`).
  static const success = Color(0xFF28856A);

  /// Warna angka "benar" pada kartu skor (`.score-stats b` = `#43a084`).
  static const successBright = Color(0xFF35A47D);

  /// Warna angka "salah" pada kartu skor (`#d9778c`).
  static const warningAccent = Color(0xFFD9778C);

  // ---------------------------------------------------------------------
  // Notifikasi
  //
  // Frame Figma "Notifikasi Announcement" (`16:1063`) memberi kartu pengumuman
  // yang belum dibaca gayanya sendiri (`#fbfaff` di atas garis `#dad3f6`).
  // `index.css` tidak memuat aturan `.notification-card`, jadi kedua warna itu
  // tidak punya pasangan token lama.
  // ---------------------------------------------------------------------

  /// Latar kartu pengumuman yang belum dibaca (`16:1117` = `#fbfaff`).
  static const notificationUnreadBg = Color(0xFFFBFAFF);

  /// Garis kartu pengumuman yang belum dibaca (`16:1117` = `#dad3f6`).
  static const notificationUnreadBorder = Color(0xFFDAD3F6);

  // ---------------------------------------------------------------------
  // Skor dan hasil
  // ---------------------------------------------------------------------

  /// Cincin skor yang belum terisi (`.score` = `border:8px solid #eae5f9`).
  ///
  /// not verified: `index.css` tidak punya aturan `.dark-theme .score`, jadi
  /// mode gelap memakai [darkRaised] (`#1d2030`), sama seperti
  /// `.dark-theme .progress-summary`.
  static const scoreRingTrack = Color(0xFFEAE5F9);

  /// Arc skor yang sudah terisi
  /// (`.score` = `border-top-color`, `border-right-color`, dan
  /// `border-bottom-color` = `#7656d3`).
  ///
  /// Sengaja lebih terang dari `primary` (`#543cd1`).
  ///
  /// not verified: `index.css` tidak punya aturan `.dark-theme .score`, jadi
  /// mode gelap memakai [primaryDark] (`#b9a3ff`).
  static const scoreRingActive = Color(0xFF7656D3);

  /// Angka jawaban benar pada strip skor (`.score-stats b` = `#43a084`).
  ///
  /// Berbeda dari [successBright] (`#35a47d`) yang dipakai untuk status di luar
  /// kartu skor dan tidak diubah pada tahap ini.
  ///
  /// not verified: `index.css` tidak punya aturan `.dark-theme .score-stats`,
  /// jadi mode gelap memakai `NetLearnStatusColors.dark.positiveText`
  /// (`#75dbb0`).
  static const scoreCorrect = Color(0xFF43A084);

  // ---------------------------------------------------------------------
  // Dark â€” `.dark-theme`
  // ---------------------------------------------------------------------

  static const darkApp = Color(0xFF0D0E12);
  static const darkSurface = Color(0xFF161820);

  /// Tab, chip, dan opsi di dark mode (`#1d2030`).
  static const darkRaised = Color(0xFF1D2030);

  static const darkText = Color(0xFFF1F3F9);
  static const darkMuted = Color(0xFFA4ABBA);
  static const darkLine = Color(0xFF262936);

  /// Kotak nomor modul di mode gelap
  /// (`.dark-theme .module-number` = `#2d2440`).
  static const darkModuleNumberBg = Color(0xFF2D2440);

  /// Angka nomor modul di mode gelap
  /// (`.dark-theme .module-number` = `#c1a3ef`).
  static const darkModuleNumberFg = Color(0xFFC1A3EF);

  /// Penanda modul terkunci di mode gelap
  /// (`.dark-theme .muted-number` = `#20232e`).
  static const darkMutedNumberBg = Color(0xFF20232E);

  /// Teks penanda modul terkunci di mode gelap
  /// (`.dark-theme .muted-number` = `#8b94aa`).
  static const darkMutedNumberFg = Color(0xFF8B94AA);

  /// Track progres yang belum terisi di mode gelap
  /// (`.dark-theme .progress-track` = `#292438`).
  ///
  /// Tidak sama dengan [darkRaised] (`#1d2030`) yang dipakai tab dan opsi.
  static const darkProgressTrackBg = Color(0xFF292438);

  /// Aksen brand di dark mode (`.dark-theme .unified-stats b` = `#b9a3ff`).
  static const primaryDark = Color(0xFFB9A3FF);

  /// Teks di atas permukaan ungu di dark mode (`#d0c2ff`).
  static const primaryDarkSoft = Color(0xFFD0C2FF);

  /// Latar tombol sekunder di dark mode (`#242035`).
  static const primaryDarkTint = Color(0xFF242035);

  /// Latar kartu pengumuman belum dibaca di mode gelap.
  ///
  /// not verified: frame `16:1063` tidak punya varian gelap. Nilainya diturunkan
  /// dari [primaryDarkTint] supaya tint ungunya tetap terlihat di atas
  /// [darkSurface], bukan dari aturan `.dark-theme` yang tidak ada.
  static const notificationUnreadBgDark = Color(0xFF232036);

  /// Garis kartu pengumuman belum dibaca di mode gelap.
  static const notificationUnreadBorderDark = Color(0xFF4B3E96);

  static const darkCoralText = Color(0xFFF09A93);
  static const darkCoralBorder = Color(0xFFC2554E);

  // ---------------------------------------------------------------------
  // Legacy â€” alias ke token di atas, dihapus di tahap akhir
  // ---------------------------------------------------------------------

  static const forest = primary;
  static const forestDark = primaryDeep;
  static const forestSoft = primaryMuted;
  static const mint = primaryTintSoft;
  static const mintLight = primaryTint;
  static const mintActive = primaryDark;
  static const offWhite = appBg;
  static const coral = danger;
  static const coralLight = dangerBg;
  static const coralText = dangerText;
  static const sand = warningBg;
  static const sandText = warningText;

  /// Bayangan tidak pernah netral di desain: selalu bernuansa ungu.
  static const shadowTint = Color(0x1F543CD1);
}

/// Gradient yang diambil apa adanya dari index.css.
class NetLearnGradients {
  NetLearnGradients._();

  /// `linear-gradient(115deg,#1e126b,#4e33c8)` â€” hero dashboard dan profil.
  /// Sudut 138° diambil dari Figma `Dashboard Dosen 2` (86:337) — beda 23°
  /// dari 115° lama, jadi hero miring ke kanan-bawah alih-alih kiri-bawah.
  static const hero = LinearGradient(
    colors: [NetLearnColors.primaryDeep, NetLearnColors.primaryMid],
    begin: Alignment(-0.747, -0.664),
    end: Alignment(0.747, 0.664),
  );

  /// `linear-gradient(90deg,#8a70ea,#543cd1)` â€” isi track progres.
  static const progress = LinearGradient(
    colors: [NetLearnColors.primarySoft, NetLearnColors.primary],
  );

  /// `linear-gradient(120deg,#eae4ff,#f3f0ff)` â€” blok ilustrasi kartu materi.
  static const materialArt = LinearGradient(
    colors: [Color(0xFFEAE4FF), Color(0xFFF3F0FF)],
  );
}

/// Enam warna lingkaran ikon pada shortcut grid
/// (`.circle.purple`, `.blue`, `.orange`, `.pink`, `.green`, `.cyan`).
class NetLearnAccents {
  NetLearnAccents._();

  static const purple = Color(0xFF8C52FF);
  static const blue = Color(0xFF6C9EFF);
  static const orange = Color(0xFFFFB067);
  static const pink = Color(0xFFFF8FB1);
  static const green = Color(0xFF58C9A5);
  static const cyan = Color(0xFF63C5DA);

  /// Urutan yang dipakai grid shortcut.
  static const grid = [purple, blue, orange, pink, green, cyan];

  /// Pasangan warna ikon + latar tint untuk baris menu profil
  /// (`.blue-tint`, `.indigo-tint`, `.green-tint`, `.purple-tint`, `.orange-tint`).
  ///
  /// Index dibaca langsung oleh baris menu profil. Orange sempat diexclude dari
  /// list ini — komentarnya khawatir menyisipkan di tengah akan menggeser warna
  /// yang sudah terpakai — tapi mahasiswa profil meminta index 4 untuk baris
  /// "Riwayat Assessment", jadi pasangan orange di-append di ujung agar tidak
  /// ada index yang bergeser.
  static const tintBackgrounds = <Color>[
    Color(0xFFEBF3FE), // blue-tint
    Color(0xFFEAE8FC), // indigo-tint
    Color(0xFFE8F8F2), // green-tint
    Color(0xFFF0EEFC), // purple-tint
    Color(0xFFFFF3EB), // orange-tint
  ];

  static const tintForegrounds = <Color>[
    Color(0xFF4F85C4),
    NetLearnColors.primary,
    Color(0xFF309778),
    Color(0xFF7E65C4),
    Color(0xFFC78046),
  ];

  /// `.orange-tint` (`#fff3eb` / `#c78046`) kini ada di [tintBackgrounds] dan
  /// [tintForegrounds] (indeks terakhir). Konstanta ini dipertahankan untuk
  /// pemakaian lain yang tidak lewat indeks.

  /// not verified: `index.css` tidak punya pasangan `.dark-theme` untuk
  /// `.orange-tint`, jadi mode gelap memakai `darkRaised` dan `primaryDarkSoft`.
  static const orangeTintBackground = Color(0xFFFFF3EB);
  static const orangeTintForeground = Color(0xFFC78046);
}

class NetLearnRadius {
  NetLearnRadius._();

  static const field = 10.0;

  /// Radius kartu (`--card` = `16px`).
  static const card = 16.0;

  /// Panel besar: kartu progres, header profil (`.unified-profile-hero`).
  static const cardLg = 20.0;

  /// Tombol (`.button` = `12px`).
  static const button = 12.0;

  /// Lencana status (`.badge` = `6px`).
  static const badge = 6.0;

  /// Persis radius yang dipakai untuk kartu maupun pil.
  static const pill = 20.0;

  /// Ubah ke `999` untuk membuat lingkaran penuh (`.circle`).
  static const circle = 999.0;

  /// Padded shape terkecil: chip identitas dan kartu ringkasan
  /// (`.unified-identity`, `.nidn-badge` = `7px`).
  static const xs = 7.0;

  /// Tombol segmented, kotak nomor opsi, dan kotak nomor soal
  /// (`.tabs button`, `.option>span`, `.pagination button`, `.answer-line`
  /// = `8px`).
  static const sm = 8.0;

  /// Lingkaran dekorasi kecil (`.tip>span` = `9px`).
  static const chip = 9.0;

  /// Kotak nomor modul (`.module-number` = `11px`).
  static const moduleNumber = 11.0;

  /// Panel ringkasan progres (`.progress-summary` = `14px`).
  static const progressPanel = 14.0;

  /// Tombol keluar (`.unified-logout` = `24px`).
  static const logout = 24.0;

  /// Tombol aksi dokumen (`.document-actions button` = `25px`).
  static const action = 25.0;

  // Design System Token Specs (design.md):
  /// `--radius-pill`: `100px` (CTA buttons, tab indicators, pill dropdowns).
  static const radiusPill = 100.0;

  /// `--radius-lg`: `24px` (Main banner & Academic Overview card).
  static const radiusLg = 24.0;

  /// `--radius-md`: `16px` (Quick Access grid buttons, sub-modules).
  static const radiusMd = 16.0;

  /// `--radius-sm`: `12px` (Input elements, small badges).
  static const radiusSm = 12.0;
}

class NetLearnSpace {
  NetLearnSpace._();
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;

  // 8pt Spacing Rhythm (design.md):
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;

  // Nilai di bawah ditambahkan pada tahap fondasi design token. Semuanya
  // diambil dari nilai literal yang ada di index.css, bukan dipilih ulang.

  /// Tinggi track progres dan padding strip statistik
  /// (`.progress-track` = `5px`, `.unified-stats` = `padding:19px 5px`).
  static const s5 = 5.0;

  /// Jarak label statistik ke angkanya dan jarak lingkaran ke label pada
  /// tombol tengah navigasi
  /// (`.unified-stats span` = `margin-top:6px`, `.center-nav` = `gap:6px`).
  static const s6 = 6.0;

  /// Jarak label ke field (`.field` = `gap:7px`).
  static const s7 = 7.0;
  /// Jarak antar baris modul, jarak atas judul tile, dan jarak track progres
  /// (`.module-list` = `gap:9px`, `.shortcut strong` = `margin-top:9px`,
  /// `.progress-track` = `margin:9px 0`).
  static const s9 = 9.0;

  /// Jarak antar tombol aksi dan padding horizontal bar bawah
  /// (`.document-actions` = `gap:10px`, `.unified-menu-row` = `gap:10px`,
  /// `.bottom-nav` = `padding:4px 10px 0`).
  static const s10 = 10.0;

  /// Jarak kotak nomor modul ke teks (`.module-row` = `gap:11px`).
  static const s11 = 11.0;

  /// Jarak bawah judul section dan jarak antar opsi jawaban
  /// (`.section-heading` = `margin-bottom:13px`, `.option` = `gap:13px`).
  static const s13 = 13.0;

  /// Padding panel progres dan padding atas hero
  /// (`.progress-summary` = `padding:12px 14px`,
  /// `.hero` = `padding:14px 24px 32px`).
  static const s14 = 14.0;

  /// Padding baris pilihan jawaban, daftar nomor soal, dan daftar pengaturan
  /// (`.option` = `padding:15px`, `.pagination` = `margin-top:15px`,
  /// `.settings-list` = `padding:5px 15px`).
  static const s15 = 15.0;

  /// Padding baris menu profil, panel metrik, dan baris pengaturan
  /// (`.unified-menu-row` = `padding:17px 0`, `.metrics` = `padding:17px`,
  /// `.settings-list button` = `padding:17px 0`).
  static const s17 = 17.0;

  /// Padding blok diagram dan strip statistik
  /// (`.diagram` = `padding:19px 8px`, `.unified-stats` = `padding:19px 5px`).
  static const s19 = 19.0;

  /// Padding reader sticky, panel konten, dan header profil
  /// (`.reader-sticky` = `padding:12px 22px`, `.content` = `padding:22px 22px 28px`,
  /// `.unified-profile-hero` = `padding:22px`).
  static const s22 = 22.0;

  /// Padding konten dashboard (`.home-content` = `padding:25px 24px 22px`).
  static const s25 = 25.0;

  /// Lebar maksimum kolom bacaan.
  ///
  /// Bukan token desain: `index.css` tidak pernah menentukan lebar kolom teks
  /// karena `.phone` di desain Figma selalu 390px dan tidak pernah melebar.
  /// Aplikasi Flutter benar-benar melebar di tablet, jadi tanpa batas ini satu
  /// paragraf reader bisa selebar 900px -- ukuran baris yang tidak terbaca.
  ///
  /// Dipakai sebagai batas atas (bukan lebar tetap) lewat `ConstrainedBox`,
  /// sehingga 360dp dan 430dp tetap memakai lebar penuh dan tidak ikut ter-zoom.
  static const readingMeasure = 600.0;

  /// Lebar maksimum kolom isian dan soal.
  ///
  /// Sama seperti [readingMeasure], ini bukan token desain: `.phone` di Figma
  /// selalu 390px. Nilainya lebih kecil daripada [readingMeasure] karena baris
  /// pilihan jawaban punya kotak huruf 29px di sebelah kirinya, jadi lebar
  /// teksnya sudah berkurang satu kotak huruf sebelum baris penuh dihitung.
  static const formMeasure = 520.0;
}

/// Bayangan yang diambil apa adanya dari index.css.
///
/// Setiap warna di CSS sudah transparan (`#543cd114` berarti alpha `0x14`), jadi
/// warna di sini menyimpan alphanya sendiri dan tidak perlu `withValues` saat
/// dipakai.
class NetLearnShadows {
  NetLearnShadows._();

  /// Tombol utama (`.button` = `0 4px 10px #543cd114`).
  static const List<BoxShadow> button = [
    BoxShadow(
      color: Color(0x14543CD1),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  /// Segmen terpilih (`.tabs .selected` = `0 2px 5px #2920520b`).
  static const List<BoxShadow> tabsSelected = [
    BoxShadow(
      color: Color(0x0B292052),
      blurRadius: 5,
      offset: Offset(0, 2),
    ),
  ];

  /// Pil bahasa terpilih (`.unified-language .selected` = `0 1px 4px #28203f12`).
  static const List<BoxShadow> pillSelected = [
    BoxShadow(
      color: Color(0x1228203F),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  /// Tombol tengah bar navigasi (`.center-nav>span` = `0 3px 8px #4e33c820`).
  static const List<BoxShadow> navCenter = [
    BoxShadow(
      color: Color(0x204E33C8),
      blurRadius: 8,
      offset: Offset(0, 3),
    ),
  ];

  /// Kolom pencarian melayang (`.floating-search` = `0 5px 20px #24144c0c`).
  static const List<BoxShadow> search = [
    BoxShadow(
      color: Color(0x0C24144C),
      blurRadius: 20,
      offset: Offset(0, 5),
    ),
  ];

  /// Halaman PDF (`.pdf-page`, `.rendered-pdf` = `0 3px 8px #27233d0c`).
  static const List<BoxShadow> pdfPage = [
    BoxShadow(
      color: Color(0x0C27233D),
      blurRadius: 8,
      offset: Offset(0, 3),
    ),
  ];

  /// Tile shortcut saat disentuh (`.shortcut:hover` = `0 5px 12px #3829770a`).
  /// `--shadow-soft-sm`: `0 4px 12px rgba(140, 82, 255, 0.04)` (Quick access cards).
  static const List<BoxShadow> softSm = [
    BoxShadow(
      color: Color(0x0A8C52FF),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// `--shadow-soft-md`: `0 8px 24px rgba(140, 82, 255, 0.06)` (Main banner & primary containers).
  static const List<BoxShadow> softMd = [
    BoxShadow(
      color: Color(0x0F8C52FF),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  /// `--shadow-nav-top`: `0 -4px 16px rgba(29, 28, 33, 0.03)` (Bottom navigation bar).
  static const List<BoxShadow> navTop = [
    BoxShadow(
      color: Color(0x081D1C21),
      blurRadius: 16,
      offset: Offset(0, -4),
    ),
  ];

  /// Tile shortcut saat disentuh (`.shortcut:hover` = `0 5px 12px #3829770a`).
  static const List<BoxShadow> shortcutHover = [
    BoxShadow(
      color: Color(0x0A382977),
      blurRadius: 12,
      offset: Offset(0, 5),
    ),
  ];
}

/// Empat status pill, persis pola status-pill/badge di desain Figma â€”
/// bukan skema warna baru.
enum NetLearnStatusTone { positive, pending, neutral, danger }

class NetLearnStatusColors extends ThemeExtension<NetLearnStatusColors> {
  final Color positiveBg, positiveText;
  final Color pendingBg, pendingText;
  final Color neutralBg, neutralText;
  final Color dangerBg, dangerText;

  const NetLearnStatusColors({
    required this.positiveBg,
    required this.positiveText,
    required this.pendingBg,
    required this.pendingText,
    required this.neutralBg,
    required this.neutralText,
    required this.dangerBg,
    required this.dangerText,
  });

  static const light = NetLearnStatusColors(
    positiveBg: Color(0xFFE8F6EF),
    positiveText: NetLearnColors.success,
    pendingBg: NetLearnColors.warningBg,
    pendingText: NetLearnColors.warningText,
    neutralBg: NetLearnColors.neutralBg,
    neutralText: NetLearnColors.muted,
    dangerBg: NetLearnColors.dangerBg,
    dangerText: NetLearnColors.dangerText,
  );

  static const dark = NetLearnStatusColors(
    positiveBg: Color(0xFF17372C),
    positiveText: Color(0xFF75DBB0),
    pendingBg: Color(0xFF342B18),
    pendingText: Color(0xFFE5C990),
    neutralBg: Color(0xFF252938),
    neutralText: Color(0xFFB6BBCA),
    dangerBg: Color(0xFF2A1A1A),
    dangerText: NetLearnColors.darkCoralText,
  );

  @override
  NetLearnStatusColors copyWith() => this;

  @override
  NetLearnStatusColors lerp(ThemeExtension<NetLearnStatusColors>? other, double t) {
    return this;
  }
}

/// Safe lookup for the status colour pairing.
///
/// The app always builds its scaffolds from [AppTheme.light] / [AppTheme.dark],
/// which both carry [NetLearnStatusColors] — but widget tests that pump pages
/// inside a bare `MaterialApp` (no app theme) do not, and a bare `!` lookup
/// there crashed `AuthField` during build. Unknown theme → the light pairing,
/// which is simply the less surprising default on a default theme.
extension NetLearnStatusColorsX on ThemeData {
  NetLearnStatusColors get statusColors =>
      extension<NetLearnStatusColors>() ?? NetLearnStatusColors.light;
}

/// Empat pasangan warna feedback snackbar (success/error/warning/info), satu
/// tema masing-masing.
///
/// Berdiri sendiri dari [NetLearnStatusColors] karena pill status memakai
/// pasangan yang lebih terang di atas surface kartu, sedangkan snackbar punya
/// latar buruannya sendiri sehingga kontras fg-nya diukur terhadap bg snackbar
/// (semua kombinasi di bawah ≥ 4.5:1). Tidak ada teks putih di atas bg terang.
///
/// `lerp` mengembalikan `this` dengan alasan yang sama dengan
/// [NetLearnStatusColors]: transisi tema dosen/mahasiswa dan antar tema
/// terang–gelap terjadi lewat ganti `ThemeData` penuh, bukan animasi lerp
/// antar ekstensi — jadi palet festif tidak sengaja dicampur
/// ungu-kuning-hijau di tengah animasi.
class NetLearnFeedbackColors extends ThemeExtension<NetLearnFeedbackColors> {
  final Color successBg, successFg, successBorder;
  final Color errorBg, errorFg, errorBorder;
  final Color warningBg, warningFg, warningBorder;
  final Color infoBg, infoFg, infoBorder;

  const NetLearnFeedbackColors({
    required this.successBg,
    required this.successFg,
    required this.successBorder,
    required this.errorBg,
    required this.errorFg,
    required this.errorBorder,
    required this.warningBg,
    required this.warningFg,
    required this.warningBorder,
    required this.infoBg,
    required this.infoFg,
    required this.infoBorder,
  });

  static const light = NetLearnFeedbackColors(
    successBg: Color(0xFFE8F6F0),
    successFg: Color(0xFF1F6B55),
    successBorder: Color(0xFFB9E2D2),
    errorBg: Color(0xFFFEF0F0),
    errorFg: Color(0xFFB93A3A),
    errorBorder: Color(0xFFF3C9C9),
    warningBg: Color(0xFFFFF6E3),
    warningFg: Color(0xFF7A5B12),
    warningBorder: Color(0xFFEFD9A6),
    infoBg: Color(0xFFF1EDFD),
    infoFg: Color(0xFF5138C4),
    infoBorder: Color(0xFFD6CCF8),
  );

  static const dark = NetLearnFeedbackColors(
    successBg: Color(0xFF17342B),
    successFg: Color(0xFF7FD9B8),
    successBorder: Color(0xFF2B5A4A),
    errorBg: Color(0xFF3A2022),
    errorFg: Color(0xFFFF9C9C),
    errorBorder: Color(0xFF6B3438),
    warningBg: Color(0xFF352A15),
    warningFg: Color(0xFFF0C878),
    warningBorder: Color(0xFF6A5326),
    infoBg: Color(0xFF262038),
    infoFg: Color(0xFFC0B2FF),
    infoBorder: Color(0xFF453A78),
  );

  @override
  NetLearnFeedbackColors copyWith() => this;

  @override
  NetLearnFeedbackColors lerp(ThemeExtension<NetLearnFeedbackColors>? other, double t) {
    return this;
  }
}

/// Lima gaya teks yang tidak punya slot di [TextTheme] Material.
///
/// `TextTheme` hanya menerima slot miliknya sendiri, jadi gaya yang memang ada
/// di desain tidak bisa masuk ke sana tanpa menimpa slot yang sudah dipakai
/// halaman lain. Ekstensi ini menambahkannya sebagai role terpisah dan tidak
/// menyentuh satu pun slot lama.
///
/// Widget membacanya lewat `context.sectionHeadingStyle` dan sejenisnya; setiap
/// fallback ke `TextTheme` terdekat supaya widget tetap tampil kalau tema dibuat
/// tanpa ekstensi ini.
class NetLearnTextStyles extends ThemeExtension<NetLearnTextStyles> {
  /// `.section-heading h2` = 16px / weight 800 / `letter-spacing:-.4px`.
  final TextStyle sectionHeading;

  /// `.badge` = 8px / weight 600.
  final TextStyle badgeLabel;

  /// `.section-heading>button`, `.link` = 10px / weight 600 / `#543cd1`.
  final TextStyle linkSmall;

  /// `.document-actions button` = 10px / weight 700.
  final TextStyle documentAction;

  /// `small` = 11px.
  final TextStyle labelCaption;

  const NetLearnTextStyles({
    required this.sectionHeading,
    required this.badgeLabel,
    required this.linkSmall,
    required this.documentAction,
    required this.labelCaption,
  });

  static const light = NetLearnTextStyles(
    sectionHeading: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontWeight: FontWeight.w800,
      fontSize: 16,
      height: 1.3,
      letterSpacing: -0.025 * 16,
      color: NetLearnColors.ink,
    ),
    badgeLabel: TextStyle(
      fontFamily: 'DMSans',
      fontWeight: FontWeight.w600,
      fontSize: 8,
      color: NetLearnColors.muted,
    ),
    linkSmall: TextStyle(
      fontFamily: 'DMSans',
      fontWeight: FontWeight.w600,
      fontSize: 10,
      color: NetLearnColors.primary,
    ),
    documentAction: TextStyle(
      fontFamily: 'DMSans',
      fontWeight: FontWeight.w700,
      fontSize: 10,
    ),
    labelCaption: TextStyle(
      fontFamily: 'DMSans',
      fontWeight: FontWeight.w400,
      fontSize: 11,
      height: 1.5,
      color: NetLearnColors.muted,
    ),
  );

  static const dark = NetLearnTextStyles(
    sectionHeading: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontWeight: FontWeight.w800,
      fontSize: 16,
      height: 1.3,
      letterSpacing: -0.025 * 16,
      color: NetLearnColors.darkText,
    ),
    badgeLabel: TextStyle(
      fontFamily: 'DMSans',
      fontWeight: FontWeight.w600,
      fontSize: 8,
      color: NetLearnColors.darkMuted,
    ),
    linkSmall: TextStyle(
      fontFamily: 'DMSans',
      fontWeight: FontWeight.w600,
      fontSize: 10,
      color: NetLearnColors.primaryDark,
    ),
    documentAction: TextStyle(
      fontFamily: 'DMSans',
      fontWeight: FontWeight.w700,
      fontSize: 10,
    ),
    labelCaption: TextStyle(
      fontFamily: 'DMSans',
      fontWeight: FontWeight.w400,
      fontSize: 11,
      height: 1.5,
      color: NetLearnColors.darkMuted,
    ),
  );

  @override
  NetLearnTextStyles copyWith() => this;

  @override
  NetLearnTextStyles lerp(ThemeExtension<NetLearnTextStyles>? other, double t) {
    return this;
  }
}

class AppTheme {
  AppTheme._();

  /// `index.css` memakai DM Sans untuk body dan Plus Jakarta Sans untuk
  /// heading, brand, avatar, dan angka besar.
  static const fontFamily = 'DMSans';

  /// Dipakai widget yang membentuk teks sendiri di luar `textTheme`, misalnya
  /// huruf avatar pada header profil.
  static const displayFontFamily = 'PlusJakartaSans';

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      // Angka besar pada strip statistik: `.unified-stats b` = 23px / w800 / -0.8px
      displayMedium: TextStyle(
        fontFamily: displayFontFamily,
        fontWeight: FontWeight.w800,
        fontSize: 23,
        height: 1.4,
        letterSpacing: -0.035 * 23,
        color: primary,
      ),
      // `.login-hero h1`: 34px / weight 800
      displaySmall: TextStyle(
        fontFamily: displayFontFamily,
        fontWeight: FontWeight.w800,
        fontSize: 34,
        height: 1.1,
        letterSpacing: -0.035 * 34,
        color: primary,
      ),
      // `.greeting h1`: 25px / weight 800 / -0.8px
      headlineMedium: TextStyle(
        fontFamily: displayFontFamily,
        fontWeight: FontWeight.w800,
        fontSize: 25,
        height: 1.25,
        letterSpacing: -0.032 * 25,
        color: primary,
      ),
      // `h2`: 18px / weight 800 / -0.45px
      headlineSmall: TextStyle(
        fontFamily: displayFontFamily,
        fontWeight: FontWeight.w800,
        fontSize: 18,
        height: 1.3,
        letterSpacing: -0.025 * 18,
        color: primary,
      ),
      // `.compact h1`: 15px / weight 800
      titleLarge: TextStyle(
        fontFamily: displayFontFamily,
        fontWeight: FontWeight.w800,
        fontSize: 15,
        height: 1.3,
        letterSpacing: -0.025 * 15,
        color: primary,
      ),
      // `h3`: 14px / weight 700
      titleMedium: TextStyle(
        fontFamily: displayFontFamily,
        fontWeight: FontWeight.w700,
        fontSize: 14,
        height: 1.45,
        color: primary,
      ),
      titleSmall: TextStyle(
        fontFamily: displayFontFamily,
        fontWeight: FontWeight.w700,
        fontSize: 12,
        color: primary,
      ),
      // `p`: 13px / line-height 1.65
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 12,
        height: 1.6,
        color: secondary,
      ),
      // `.field` label: 11px / weight 600
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 11,
        height: 1.4,
        color: primary,
      ),
      // `small`: 10-11px
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 10,
        height: 1.5,
        color: secondary,
      ),
      // `.button`: 12px / weight 700
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      // `.eyebrow`: 9-10px / weight 700 / tracking lebar
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w700,
        fontSize: 10,
        letterSpacing: 0.12 * 10,
        color: NetLearnColors.primaryMuted,
      ),
    );
  }

  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: NetLearnColors.appBg,
    fontFamily: fontFamily,
    colorScheme: const ColorScheme.light(
      primary: NetLearnColors.primary,
      onPrimary: NetLearnColors.white,
      primaryContainer: NetLearnColors.primaryTint,
      onPrimaryContainer: NetLearnColors.primaryDeep,
      secondary: NetLearnColors.primaryTint,
      onSecondary: NetLearnColors.primary,
      surface: NetLearnColors.white,
      onSurface: NetLearnColors.ink,
      onSurfaceVariant: NetLearnColors.muted,
      surfaceContainerHighest: NetLearnColors.primaryTint,
      outline: NetLearnColors.line,
      error: NetLearnColors.danger,
    ),
    textTheme: _textTheme(NetLearnColors.ink, NetLearnColors.muted),
    extensions: const [
      NetLearnStatusColors.light,
      NetLearnTextStyles.light,
      NetLearnFeedbackColors.light,
    ],
    dividerColor: NetLearnColors.line,
    cardTheme: CardThemeData(
      color: NetLearnColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        side: const BorderSide(color: NetLearnColors.line),
      ),
    ),
    iconTheme: const IconThemeData(color: NetLearnColors.muted, size: 20),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NetLearnColors.white,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      hintStyle: const TextStyle(color: NetLearnColors.neutralText, fontSize: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NetLearnRadius.field),
        borderSide: const BorderSide(color: NetLearnColors.lineDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NetLearnRadius.field),
        borderSide: const BorderSide(color: NetLearnColors.lineDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NetLearnRadius.field),
        borderSide: const BorderSide(color: NetLearnColors.primary, width: 1.5),
      ),
    ),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: NetLearnColors.darkApp,
    fontFamily: fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: NetLearnColors.primaryDark,
      onPrimary: NetLearnColors.darkApp,
      primaryContainer: NetLearnColors.primaryDarkTint,
      onPrimaryContainer: NetLearnColors.primaryDarkSoft,
      secondary: NetLearnColors.primaryDarkTint,
      onSecondary: NetLearnColors.primaryDarkSoft,
      surface: NetLearnColors.darkSurface,
      onSurface: NetLearnColors.darkText,
      onSurfaceVariant: NetLearnColors.darkMuted,
      surfaceContainerHighest: NetLearnColors.darkRaised,
      outline: NetLearnColors.darkLine,
      error: NetLearnColors.danger,
    ),
    textTheme: _textTheme(NetLearnColors.darkText, NetLearnColors.darkMuted),
    extensions: const [
      NetLearnStatusColors.dark,
      NetLearnTextStyles.dark,
      NetLearnFeedbackColors.dark,
    ],
    dividerColor: NetLearnColors.darkLine,
    cardTheme: CardThemeData(
      color: NetLearnColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        side: const BorderSide(color: NetLearnColors.darkLine),
      ),
    ),
    iconTheme: const IconThemeData(color: NetLearnColors.darkMuted, size: 20),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NetLearnColors.darkSurface,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NetLearnRadius.field),
        borderSide: const BorderSide(color: NetLearnColors.darkLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NetLearnRadius.field),
        borderSide: const BorderSide(color: NetLearnColors.darkLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NetLearnRadius.field),
        borderSide: const BorderSide(color: NetLearnColors.primaryDark, width: 1.5),
      ),
    ),
  );
}

/// Gaya angka besar pada kartu statistik, panel progres, dan kartu skor.
///
/// `index.css` memberi empat ukuran berbeda untuk angka utama: `.metrics b`
/// 17px, `.progress-summary b` 19px, `.unified-stats b` 23px, dan `.score b`
/// 40px. Semuanya sebelumnya memakai satu slot `displayMedium` yang 23px, jadi
/// tiga di antaranya meleset depending pada halaman. Kelas ini memisahkannya
/// tanpa mengubah satu pun slot `TextTheme` yang sudah dipakai halaman lain.
///
/// Warna sengaja TIDAK ditulis di sini. Angka besar selalu berwarna aksen atau
/// warna teks, dan keduanya harus mengikuti tema, jadi widget memanggil
/// `.copyWith(color: context.accent)` atau `context.onSurface` saat memakainya.
/// Jangan `context.surface`: angka besar berdiri di atas page background dan
/// di mode terang `surface` adalah putih, sama seperti latarnya.
class NetLearnDisplay {
  NetLearnDisplay._();

  /// Family angka besar di desain: Plus Jakarta Sans (`h1,h2,h3,.brand`).
  static const String family = AppTheme.displayFontFamily;

  /// `.metrics b` = 17px / weight 800.
  static const TextStyle metric = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w800,
    fontSize: 17,
  );

  /// `.progress-summary b` = 19px / weight 800.
  static const TextStyle progress = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w800,
    fontSize: 19,
  );

  /// `.unified-stats b` = 23px / weight 800 / `letter-spacing:-.8px`.
  static const TextStyle stat = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w800,
    fontSize: 23,
    height: 1.4,
    letterSpacing: -0.035 * 23,
  );

  /// `.score b` = 40px / weight 800 / `letter-spacing:-2px`.
  static const TextStyle score = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w800,
    fontSize: 40,
    letterSpacing: -2,
  );

  /// `.score>span` = 11px.
  ///
  /// Warna `index.css` (`#9292a3`) tidak punya pasangan dark, jadi warnanya
  /// diserahkan ke pemanggil lewat `context.mutedText`.
  static const TextStyle scoreCaption = TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 11,
  );
}

/// Token fokus, dari `index.css`.
///
/// CSS memakai `outline`, yang tidak punya padanan langsung di Material, jadi
/// kelas ini menyimpan angkanya supaya widget yang butuh cincin fokus bisa
/// menggambarnya sendiri tanpa menulis angka baru.
class NetLearnFocus {
  NetLearnFocus._();

  /// `button:focus-visible` = `outline:2px solid #543cd1`.
  static const double ringWidth = 2.0;

  /// `outline-offset:4px` global pada
  /// `button,input,textarea,select`.
  static const double offset = 4.0;

  /// `.unified-menu-row:focus-visible` dan `.unified-language button:focus-visible`
  /// memakai `outline-offset:2px`.
  static const double compactOffset = 2.0;

  /// Isi fokus Material. CSS tidak punya aturan `hover`/`focus` terpisah untuk
  /// Material, jadi nilainya diturunkan dari warna aksen agar otomatis mengikuti
  /// tema.
  ///
  /// BELUM dipasang ke `ThemeData.focusColor` dan `ThemeData.hoverColor` pada
  /// tahap fondasi token: keduanya ikut diterapkan ke seluruh kontrol Material yang
  /// sudah ada, jadi memasangnya akan mengubah tampilan layar lama tanpa sengaja.
  /// Pasangan ini disimpan untuk tahap aksesibilitas.
  static const double fillAlpha = 0.12;
  static const double hoverAlpha = 0.04;
}

/// Theme-aware stand-ins for the light-only palette tokens.
///
/// The widgets used to reference `NetLearnColors.white`, `appBg`, `line` and
/// `muted` directly, which meant a surface stayed white no matter the theme
/// while the text followed it. Turning on dark mode therefore produced pale
/// text on a white background instead of a dark screen. Reading these roles off
/// the active color scheme keeps the background and the text in step, and
/// resolves to exactly the same values the light scheme already used.
extension NetLearnSurfaceColors on BuildContext {
  ColorScheme get _scheme => Theme.of(this).colorScheme;

  /// Page background, the colour behind the cards.
  Color get background => Theme.of(this).scaffoldBackgroundColor;

  /// Card, panel and sheet background.
  Color get surface => _scheme.surface;

  /// Hairline separators and card outlines.
  Color get border => _scheme.outline;

  /// Secondary label and helper text.
  Color get mutedText => _scheme.onSurfaceVariant;

  /// Pill and progress-track background.
  Color get raisedSurface => _scheme.surfaceContainerHighest;

  /// Accent used for icons and active states.
  Color get accent => _scheme.primary;

  /// Latar lembut di belakang aksen: lingkaran ikon, chip, pil status
  /// (`.circle` = `#f3e8ff`, `.button.secondary` = `#f0ecfb`).
  ///
  /// Terpisah dari [raisedSurface] karena yang satu untuk track progres dan yang
  /// ini untuk dekorasi.
  Color get accentTint => _scheme.primaryContainer;

  /// Aksen terang untuk teks di atas permukaan [accentTint].
  Color get onAccentTint => _scheme.onPrimaryContainer;

  /// Teks utama di atas permukaan [surface] (`body` = `#1a1d26`).
  ///
  /// Teks utama tidak boleh memakai [surface]: di mode terang keduanya hampir
  /// sama, jadi teks putih di atas kartu putih tidak langsung terlihat.
  Color get onSurface => _scheme.onSurface;

  /// Palet feedback snackbar per tone ([NetLearnFeedbackColors]).
  ///
  /// Fallback ke pasangan terang dengan alasan yang sama dengan
  /// `statusColors`: widget test yang pump halaman di dalam `MaterialApp`
  /// polos tidak membawa ekstensi tema, dan lookup `!` di sana akan crash
  /// saat build.
  NetLearnFeedbackColors get feedback => Theme.of(this)
          .extension<NetLearnFeedbackColors>() ??
      NetLearnFeedbackColors.light;
}

/// Gaya teks role dari [NetLearnTextStyles], dibaca lewat context.
///
/// Tiap getter jatuh ke slot [TextTheme] terdekat kalau tema dibuat tanpa
/// ekstensi, jadi widget tidak pernah menemukan `null` dan tidak perlu cabang
/// tambahan di setiap call site.
extension NetLearnTextRoles on BuildContext {
  NetLearnTextStyles? get _roles => Theme.of(this).extension<NetLearnTextStyles>();

  /// `.section-heading h2` = 16px / weight 800.
  TextStyle? get sectionHeadingStyle =>
      _roles?.sectionHeading ?? Theme.of(this).textTheme.titleLarge;

  /// `.badge` = 8px / weight 600.
  TextStyle? get badgeLabelStyle =>
      _roles?.badgeLabel ?? Theme.of(this).textTheme.bodySmall;

  /// `.section-heading>button`, `.link` = 10px / weight 600.
  TextStyle? get linkSmallStyle =>
      _roles?.linkSmall ?? Theme.of(this).textTheme.bodySmall;

  /// `.document-actions button` = 10px / weight 700.
  TextStyle? get documentActionStyle =>
      _roles?.documentAction ?? Theme.of(this).textTheme.labelLarge;

  /// `small` = 11px.
  TextStyle? get labelCaptionStyle =>
      _roles?.labelCaption ?? Theme.of(this).textTheme.bodyMedium;
}