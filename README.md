# NetLearn — Media Pembelajaran Interaktif Jaringan Komputer Berbasis AR & AI

[![Flutter Version](https://img.shields.io/badge/Flutter-%3E%3D3.13.2-02569B?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 1. Informasi Tim
* **Nama Tim**: `Soto Tanpa Kecap`
* **Daftar Anggota Tim**:
  1. `Rafi Ahmad Fauzan` — Peran/Role : Lead Developer / Backend Developer
  2. `Rendy Aditya Pratama` — Peran/Role : UI/UX Designer / Frontend Developer


---

2. Ringkasan Proyek & Produk
* Kategori: Mobile (Android)
* Nama Aplikasi: NetLearn
* Target Pengguna: 
  * Mahasiswa/Siswa yang mempelajari mata kuliah/bidang Jaringan Komputer (Computer Networking).
  * Dosen/Instruktur Jaringan Komputer.

* **Permasalahan yang Diangkat**:
  * Konsep jaringan komputer (topologi, model OSI, packet routing, dan subnetting) bersifat abstrak dan sulit divisualisasikan secara nyata tanpa perangkat laboratorium fisik yang mahal.
  * Mahasiswa sering mengalami kebosanan atau keterbatasan akses simulator jaringan desktop saat belajar secara mandiri.
  * Dosen membutuhkan alat otomatisasi evaluasi dan pendampingan pembelajaran berbasis AI yang adaptif untuk mengukur performa belajar mahasiswa.

* **Deskripsi Solusi**:
  * NetLearn adalah aplikasi *edutech mobile* komprehensif yang mengintegrasikan Augmented Reality (AR) untuk visualisasi perangkat jaringan 3D, Virtual Lab Simulator (Layer 2 & Layer 3) dengan engine terminal interaktif (Ping, Tracert, IPConfig), modul latihan intensif Subnet Drill, serta asisten tutor cerdas NetBot AI dan fitur AI Dosen multi-provider untuk evaluasi pembelajaran otomatis.

---

3. Fitur Utama yang Diimplementasikan

### A. Mahasiswa (Student Experience)
1. **Virtual Lab Simulator (Layer 2 & Layer 3)**:
   * Simulator kanvas interaktif untuk menyusun topologi perangkat (PC, Switch, Router, Server).
   * Konfigurasi IP, Gateway, dan Subnet Mask secara dinamis.
   * Layanan jaringan: DHCP Server dan HTTP Web Server bawaan.
   * Terminal Console CLI Engine: Menjalankan perintah jaringan riil (`ping`, `tracert`, `ipconfig`, `help`).

   * **Automated Mission Checker**: Sistem evaluasi misi praktikum otomatis dengan skor objektif.
   * Ekspor topologi ke format JSON dan gambar diagram PNG (dapat disimpan langsung ke galeri).

2. **Augmented Reality (AR) Hardware Viewer**:
   * Visualisasi interaktif model 3D perangkat jaringan komputer (Router, Switch, Server, Kabel UTP) secara imersif menggunakan kamera ponsel.
3. **Subnet Drill & Gamified Challenge**:
   * Latihan perhitungan subnetting IPv4 interaktif dengan limit waktu (timed drill).
   * Papan peringkat kelas (Leaderboard) untuk memacu motivasi belajar.
4. **Modul Materi Pembelajaran & Video Interaktif**:
   * Pembaca materi terstruktur, panduan praktikum, dokumen manual book PDF, dan video pembelajaran YouTube terintegrasi.
5. **NetBot AI Tutor (Bilingual & Multi-Provider)**:
   * Asisten tanya-jawab konsep jaringan dengan pemahaman konteks modul dan kondisi topologi kanvas.
   * Format teks bersih, bebas simbol berlebih, dan nyaman dibaca mahasiswa.

### B. Dosen (Lecturer Experience)
1. **AI Question Generator & Quiz Creator**:
   * Pembuatan paket kuis otomatis berbasis AI berdasarkan topik atau modul tertentu.
2. **AI Pedagogical Insight & Analytics**:
   * Evaluasi performa kelas dan analisis diagnostik nilai Pretest/Posttest secara instan.
3. **Bilingual Translation Engine**:
   * Penerjemahan materi ajar dan paket soal kuis (Indonesia ↔ English) dengan failover AI.
4. **Manajemen Kelas & Rekap Nilai**:
   * Manajemen modul ajar, penugasan, forum diskusi, serta ekspor rekapitulasi nilai ke format CSV dan PDF.

---

## 🛠️ 4. Teknologi yang Digunakan
* **Framework**: [Flutter](https://flutter.dev/) (Dart SDK `^3.13.2`)
* **State Management & Routing**: 
  * `flutter_riverpod` (`^3.4.3`)
  * `go_router` (`^18.0.2`)
* **Backend, Database & Autentikasi**:
  * [Supabase](https://supabase.com/) (`supabase_flutter: ^2.17.2`) — PostgreSQL Database, Auth, Realtime, Row Level Security (RLS), & Cloud Storage.
* **Environment Variable Management**:
  * `flutter_dotenv` (`^6.0.1`)
* **Augmented Reality & Media**:
  * `ar_flutter_plugin_plus` (`^1.1.3`)
  * `youtube_player_iframe` (`^6.0.2`)
  * `pdfx` (`^2.6.0`) & `pdf` (`^3.13.1`)
  * `audioplayers` (`^6.8.1`)
* **Speech & Audio**:
  * `speech_to_text` (`^7.5.0`)
* **Artificial Intelligence (Multi-Provider AI Gateway)**:
  * **Groq LPU API**: Akses model performa tinggi berlatensi sangat rendah (misal `openai/gpt-oss-20b`).
  * **Google Gemini API**: `google_generative_ai` (`^0.4.7`) untuk penalaran materi edukasi.
  * **OpenRouter API**: Failover provider pihak ketiga guna menjamin *high availability* (anti rate-limit).

---

## 5. Diagram Arsitektur Sistem & Alur Data

```mermaid
graph TD
    subgraph Client ["NetLearn Mobile Client (Flutter)"]
        UI["UI Layer (Material Design 3 & Responsive)"]
        Riverpod["State Management (Riverpod Providers)"]
        VLab["Virtual Lab Engine (L2/L3 Routing & Terminal)"]
        AR["AR Hardware Engine (ARCore/ARKit)"]
        Router["GoRouter Gate & Session Guard"]
    end

    subgraph Backend ["Cloud Backend & Database"]
        SupabaseAuth["Supabase Auth (NIM/NIDN & Password)"]
        Postgres["PostgreSQL Database (RLS Secured)"]
        Storage["Supabase Storage (Materi PDF & Topologi JSON)"]
    end

    subgraph AIGateway ["Resilient Multi-Provider AI Gateway"]
        Groq["Groq Cloud LPU (Primary Tutor & Question Gen)"]
        Gemini["Google Gemini API (Secondary Fallback)"]
        OpenRouter["OpenRouter Gateway (Tertiary Fallback)"]
    end

    UI --> Riverpod
    Riverpod --> Router
    Router --> SupabaseAuth
    Riverpod --> Postgres
    Riverpod --> Storage
    VLab --> Riverpod
    AR --> UI

    Riverpod -->|HTTP Streaming / REST| Groq
    Groq -.->|Failover 429/Error| Gemini
    Gemini -.->|Failover 429/Error| OpenRouter
```

### Alur Data (Data Flow):
1. **Autentikasi**: Mahasiswa/Dosen login menggunakan NIM/NIP. Client memvalidasi kredensial ke Supabase Auth, lalu `GoRouter` mengarahkan ke dashboard yang sesuai berdasarkan peran (role-based redirect).
2. **Virtual Lab Simulation**: Topologi, koneksi kabel, dan konfigurasi IP diproses secara lokal di state memori perangkat. Saat mahasiswa menyelesaikan misi, sistem memvalidasi tabel routing dan konektivitas via Terminal CLI Engine, kemudian mengunggah skor capaian ke Supabase.
3. **AI Assistance (NetBot & Dosen)**: Pertanyaan dikirim bersama konteks modul aktif ke AI Gateway. Gateway secara cerdas memilih provider prioritas (Groq) dan otomatis beralih ke Gemini/OpenRouter jika terjadi batasan kuota (rate-limit).

---

## 6. Panduan Instalasi & Menjalankan Aplikasi

### A. Prasyarat Sistem
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi minimal `3.13.2` atau lebih baru).
* [Android Studio](https://developer.android.com/studio) dengan Android SDK & Emulator (Android 8.0 / API Level 26+ disarankan untuk dukungan ARCore).
* Git terpasang di sistem.

### B. Langkah Instalasi
1. **Clone Repositori**:
   ```bash
   git clone [URL_REPOSITORI_GITHUB_ANDA]
   cd Netlearn-Mobile-App
   ```

2. **Pasang Dependensi**:
   ```bash
   flutter pub get
   ```

3. **Konfigurasi Variabel Lingkungan (`.env`)**:
   Salin template `.env.example` menjadi `.env` di direktori utama:
   * Di Windows (PowerShell):
     ```powershell
     Copy-Item .env.example .env
     ```
   * Di Linux / macOS:
     ```bash
     cp .env.example .env
     ```
   Buka file `.env` dan lengkapi nilainya:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_PUBLISHABLE_KEY=sb_publishable_your_key_here
   GROQ_API_KEY=gsk_your_groq_api_key_here
   GEMINI_API_KEY=your_gemini_api_key_here
   OPENROUTER_API_KEY=sk-or-v1-your_openrouter_api_key_here
   ```

4. **Jalankan Aplikasi**:
   * Jalankan di perangkat Android / Emulator:
     ```bash
     flutter run
     ```
   * Jalankan di browser Google Chrome (Web Preview):
     ```bash
     flutter run -d chrome
     ```

5. **Menjalankan Pengujian Otomatis (Automated Tests)**:
   ```bash
   flutter test
   ```

---

## 7. Akun Demonstrasi (Demo Accounts)

Untuk mempermudah dewan juri dalam menguji seluruh fungsionalitas aplikasi, berikut akun yang dapat digunakan:

| Peran (Role) | Nomor Identitas (NIM / NIDN) | Password | Keterangan Akses |
| :--- | :--- | :--- | :--- |
| **Mahasiswa** | `[MASUKKAN NIM MAHASISWA DEMO]` | `[MASUKKAN PASSWORD]` | Akses Virtual Lab, AR, Subnet Drill, Materi, NetBot AI. |
| **Dosen** | `[MASUKKAN NIP DOSEN DEMO]` | `[MASUKKAN PASSWORD]` | Akses Buat Kuis AI, Analisis Nilai AI, Rekap Nilai, Kelola Kelas. |

---

## 8. Dokumentasi Penggunaan AI

Aplikasi NetLearn memanfaatkan kecerdasan buatan (Artificial Intelligence) pada beberapa komponen inti:

1. **NetBot (AI Tutor Interaktif Mahasiswa)**:
   * **Model / Layanan**: Groq LPU (`openai/gpt-oss-20b`), Google Gemini (`gemini-1.5-flash`), dan OpenRouter.
   * **Implementasi**: Pendamping belajar interaktif yang memahami topik materi yang sedang dibuka dan konfigurasi topologi jaringan pada Virtual Lab. Dilengkapi sistem sanitasi teks otomatis untuk menghilangkan format tebal berlebihan sehingga nyaman dibaca.
2. **AI Question Generator (Dosen)**:
   * **Model / Layanan**: Groq Cloud & Google Gemini.
   * **Implementasi**: Menghasilkan butir soal kuis pilihan ganda beserta kunci jawaban dan opsi pengecoh secara otomatis berdasarkan topik jaringan komputer yang ditentukan dosen.
3. **AI Pedagogical Insight & Analytics**:
   * **Model / Layanan**: Groq Cloud & Google Gemini.
   * **Implementasi**: Menganalisis sebaran nilai Pretest dan Posttest mahasiswa di kelas, lalu merangkum rekomendasi bimbingan pedagogis bagi dosen.
4. **Bilingual Translation Service**:
   * **Model / Layanan**: Groq Cloud / Gemini API.
   * **Implementasi**: Menerjemahkan deskripsi materi dan soal ujian secara akurat antara Bahasa Indonesia dan Bahasa Inggris.

---

## 9. Atribusi Sumber, Aset, & Pihak Ketiga

Seluruh aset, pustaka, dan layanan pihak ketiga yang digunakan dalam pengembangan NetLearn:
* **Framework & Bahasa**: [Flutter](https://flutter.dev/) & [Dart](https://dart.dev/) oleh Google.
* **Backend as a Service**: [Supabase](https://supabase.com/) (Open Source Firebase Alternative).
* **Font Typography**:
  * *Plus Jakarta Sans* oleh Tokotype (Google Fonts, Open Font License).
  * *Inter* oleh Rasmus Andersson (SIL Open Font License).
  * *DM Sans* oleh Colophon Foundry (SIL Open Font License).
* **Ikon Antarmuka**:
  * `CupertinoIcons` & Flutter Material Symbols / Icons.
* **Efek Suara (Audio SFX)**:
  * Sound effects interaksi (connect, error, pop, success) bersumber dari lisensi bebas royalti (Creative Commons Zero / Freesound).
* **Model 3D AR & Marker**:
  * Model 3D perangkat jaringan komputer untuk Augmented Reality bersumber dari lisensi terbuka (Creative Commons Attribution / model mandiri tim).
* **Layanan AI**:
  * [Groq Inc.](https://groq.com/) untuk LPU Inference Engine.
  * [Google AI for Developers](https://ai.google.dev/) untuk Gemini API.
  * [OpenRouter](https://openrouter.ai/) untuk Unified LLM Gateway.

