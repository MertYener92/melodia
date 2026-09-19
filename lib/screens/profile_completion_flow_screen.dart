import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/song_library.dart';
import '../services/suno_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chip_multi_group.dart';
import '../widgets/gradient_button.dart';
import '../widgets/premium_back_button.dart';
import '../widgets/app_notice.dart';

/// Madde 10/11: "Complete your profile" — 3-4 adımlık, kısa ve eğlenceli
/// bir onboarding. Bir registration formu gibi GÖRÜNMEMELİ -- her adım
/// tek bir soru + seçim + "Devam Et" mantığında, PageView ile geçiş
/// yapıyor. Her adım tamamlandığında ANINDA backend'e kaydediliyor
/// (SongLibrary.updateProfileStep) -- madde 11: kullanıcı yarıda çıksa
/// bile ilerleme kaybolmuyor, bir dahaki açılışta _initialStep'ten devam
/// eder.
///
/// create_form_screen.dart'taki tür/mood seçenekleriyle AYNI kelime
/// dağarcığı kullanılıyor (Pop/Rock/... vb.) -- yeni bir tür sözlüğü
/// icat edilmedi.
class ProfileCompletionFlowScreen extends StatefulWidget {
  const ProfileCompletionFlowScreen({
    super.key,
    required this.library,
    required this.service,
    required this.initialStep,
  });

  final SongLibrary library;
  final SunoApiService service;

  /// Kullanıcının daha önce bıraktığı yerden devam etmesi için.
  final int initialStep;

  @override
  State<ProfileCompletionFlowScreen> createState() => _ProfileCompletionFlowScreenState();
}

class _ProfileCompletionFlowScreenState extends State<ProfileCompletionFlowScreen> {
  static const _genreOptions = ['Pop', 'Rock', 'Hip-Hop', 'EDM', 'R&B', 'Acoustic'];
  static const _goalOptions = [
    'Sözlü şarkılar',
    'Enstrümantal müzik',
    'Müzik videosu',
    'Sadece deneyip görmek',
  ];

  late final PageController _pageController;
  late int _pageIndex;
  final _nameController = TextEditingController();
  final Set<String> _selectedGenres = {};
  String? _selectedGoal;
  Uint8List? _avatarBytes;
  bool _saving = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.initialStep.clamp(0, 3);
    _pageController = PageController(initialPage: _pageIndex);
    _nameController.text = widget.library.displayNameOverride ?? '';
    _selectedGenres.addAll(widget.library.favoriteGenres);
    _selectedGoal = widget.library.creationGoal;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _avatarBytes = bytes);
  }

  Future<void> _goNext() async {
    setState(() => _saving = true);
    try {
      switch (_pageIndex) {
        case 0:
          final name = _nameController.text.trim();
          if (name.isEmpty) {
            setState(() => _saving = false);
            return;
          }
          await widget.library.updateProfileStep(displayName: name, profileStep: 1);
          break;
        case 1:
          if (_avatarBytes != null) {
            final upload = await widget.service.getAvatarUploadUrl();
            await widget.service.uploadAvatarBytes(upload.uploadUrl, _avatarBytes!);
            await widget.library.updateProfileStep(avatarKey: upload.key, profileStep: 2);
          } else {
            await widget.library.updateProfileStep(profileStep: 2);
          }
          break;
        case 2:
          await widget.library.updateProfileStep(
            favoriteGenres: _selectedGenres.toList(),
            profileStep: 3,
          );
          break;
        case 3:
          await widget.library.updateProfileStep(
            creationGoal: _selectedGoal,
            profileStep: 4,
          );
          setState(() {
            _saving = false;
            _done = true;
          });
          return;
      }
      setState(() {
        _pageIndex += 1;
        _saving = false;
      });
      await _pageController.animateToPage(
        _pageIndex,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    } on SunoApiException catch (e) {
      setState(() => _saving = false);
      if (!mounted) return;
      AppNotice.show(context, e.message, type: NoticeType.error);
    } catch (e) {
      setState(() => _saving = false);
      if (!mounted) return;
      debugPrint('Profil kaydedilemedi: $e');
      AppNotice.show(context, 'Kaydedilemedi. Lütfen tekrar dene.', type: NoticeType.error);
    }
  }

  bool get _canContinue {
    switch (_pageIndex) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 2:
        return _selectedGenres.isNotEmpty;
      case 3:
        return _selectedGoal != null;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGlow),
        child: SafeArea(
          child: _done ? _buildSuccess() : _buildFlow(),
        ),
      ),
    );
  }

  Widget _buildFlow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: [
          Row(
            children: [
              const PremiumBackButton(),
              const SizedBox(width: 14),
              Expanded(child: _StepProgressBar(current: _pageIndex, total: 4)),
              const SizedBox(width: 14),
              // Sayaç: içinde bulunulan adım vurgulu, toplam sönük.
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${_pageIndex + 1}',
                      style: const TextStyle(
                        fontFamily: AppFonts.rounded,
                        fontFamilyFallback: AppFonts.roundedFallback,
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(
                      text: ' / 4',
                      style: TextStyle(
                        fontFamily: AppFonts.rounded,
                        fontFamilyFallback: AppFonts.roundedFallback,
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StepBody(
                  question: 'Sana nasıl hitap edelim?',
                  child: TextField(
                    controller: _nameController,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
                    decoration: const InputDecoration(hintText: 'Görünen adın'),
                  ),
                ),
                _StepBody(
                  question: 'Bir profil fotoğrafı seç',
                  child: Center(
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceElevated,
                          border: Border.all(color: AppColors.border),
                          image: _avatarBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(_avatarBytes!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _avatarBytes == null
                            ? const Icon(Icons.add_a_photo_rounded, color: AppColors.textSecondary, size: 30)
                            : null,
                      ),
                    ),
                  ),
                ),
                _StepBody(
                  question: 'Hangi müzik türlerini seviyorsun?',
                  child: ChipMultiGroup(
                    options: _genreOptions,
                    selected: _selectedGenres,
                    maxSelection: 5,
                    onToggle: (v) => setState(() {
                      if (_selectedGenres.contains(v)) {
                        _selectedGenres.remove(v);
                      } else {
                        _selectedGenres.add(v);
                      }
                    }),
                  ),
                ),
                _StepBody(
                  question: 'Melodia\'da ne oluşturmak istiyorsun?',
                  child: ChipMultiGroup(
                    options: _goalOptions,
                    selected: {if (_selectedGoal != null) _selectedGoal!},
                    maxSelection: 1,
                    onToggle: (v) => setState(() => _selectedGoal = v),
                  ),
                ),
              ],
            ),
          ),
          GradientButton(
            label: _pageIndex == 3 ? 'Bitir' : 'Devam Et',
            isLoading: _saving,
            onPressed: _canContinue ? _goNext : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 42),
          ),
          const SizedBox(height: 20),
          const Text(
            'Profilin tamamlandı',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: 'Profile Dön',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({required this.question, required this.child});

  final String question;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        child,
      ],
    );
  }
}


/// Adım göstergesi: tek bir sürekli çubuk yerine adım SAYISI kadar ayrı
/// parça. Tamamlanan parçalar marka gradyanıyla (mor -> pembe) doluyor,
/// içinde bulunulan parça ayrıca hafif bir ışıma taşıyor; sıradakiler
/// sönük kalıyor. Böylece kullanıcı "4 adımın kaçındayım" sorusunu
/// yüzdeyi okumadan, tek bakışta görüyor.
class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({required this.current, required this.total});

  /// 0 tabanlı, içinde bulunulan adım.
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              height: 5,
              decoration: BoxDecoration(
                gradient: i <= current ? AppColors.primaryGradient : null,
                color: i <= current ? null : AppColors.border,
                borderRadius: BorderRadius.circular(999),
                boxShadow: i == current
                    ? [
                        BoxShadow(
                          color: AppColors.purple.withValues(alpha: 0.55),
                          blurRadius: 9,
                          spreadRadius: -1,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
