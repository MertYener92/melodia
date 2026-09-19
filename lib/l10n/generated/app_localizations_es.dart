// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navAiMusic => 'AI Música';

  @override
  String get navAiVideo => 'AI Video';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navProfile => 'Perfil';

  @override
  String get createBadge => 'GENERADOR DE CANCIONES IA';

  @override
  String get createTitle => 'Crea Tu Canción';

  @override
  String get createSubtitle =>
      'Convierte tus ideas en canciones originales con IA en segundos.';

  @override
  String get createButton => 'Generar Canción';

  @override
  String get profileTitle => 'Tu perfil';

  @override
  String get profileSongs => 'Canciones';

  @override
  String get profileFavorites => 'Favoritos';

  @override
  String get profileSettings => 'Ajustes';

  @override
  String get profileUpgradePlan => 'Mejorar Plan';

  @override
  String get profileHelpSupport => 'Ayuda y Soporte';

  @override
  String get profileAboutApp => 'Acerca de Melodia Studio';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguagePickerTitle => 'Elegir Idioma';

  @override
  String get settingsLanguageSystemDefault => 'Idioma del Sistema';

  @override
  String get libraryHeroTitle => 'Biblioteca';

  @override
  String get libraryHeroSubtitle => 'Todas tus creaciones, en un solo lugar.';

  @override
  String get libraryQuote =>
      'Las buenas ideas\nsiempre se\nguardan en algún lugar.';

  @override
  String get libraryTagline => 'CREAR  ·  DESCUBRIR  ·  GUARDAR';

  @override
  String get librarySongsTitle => 'Mis Canciones';

  @override
  String get librarySongsSubtitle => 'Todas las canciones que has creado.';

  @override
  String librarySongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones',
      one: '1 canción',
      zero: 'Sin canciones',
    );
    return '$_temp0';
  }

  @override
  String get libraryVideosTitle => 'Mis Videos';

  @override
  String get libraryVideosSubtitle => 'Todos los videos que has creado.';

  @override
  String libraryVideosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos',
      one: '1 video',
      zero: 'Sin videos',
    );
    return '$_temp0';
  }

  @override
  String get libraryFavoritesTitle => 'Favoritos';

  @override
  String get libraryFavoritesSubtitle => 'Contenido que te ha gustado.';

  @override
  String libraryFavoritesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos',
      one: '1 elemento',
      zero: 'Sin elementos',
    );
    return '$_temp0';
  }

  @override
  String get libraryDownloadsTitle => 'Descargas';

  @override
  String get libraryDownloadsSubtitle =>
      'Lo que has guardado en tu dispositivo.';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionLogout => 'Cerrar Sesión';

  @override
  String get dangerZoneTitle => 'ZONA DE PELIGRO';

  @override
  String get deleteAccountConfirmTitle => 'Eliminar tu cuenta permanentemente';

  @override
  String get deleteAccountConfirmBody =>
      'Esta acción no se puede deshacer. Todas tus canciones, clips de video e información de cuenta se eliminarán PERMANENTEMENTE. ¿Seguro que quieres continuar?';

  @override
  String get deleteAccountShort => 'Eliminar Mi Cuenta';

  @override
  String get deleteAccountBody =>
      'Todas tus canciones, clips de video e información de cuenta se eliminarán permanentemente. Esta acción no se puede deshacer.';

  @override
  String get deleteAccountPermanentButton =>
      'Eliminar Mi Cuenta Permanentemente';

  @override
  String get genericUnexpectedError => 'Ocurrió un error inesperado.';

  @override
  String get searchSongsHint => 'Buscar canciones...';

  @override
  String get noSongsFound => 'No se encontraron canciones';

  @override
  String get removeFromFavorites => 'Quitar de favoritos';

  @override
  String get addToFavorites => 'Añadir a favoritos';

  @override
  String get actionRename => 'Renombrar';

  @override
  String get actionShare => 'Compartir';

  @override
  String get shareComingSoonMessage =>
      'La función de compartir estará disponible pronto.';

  @override
  String get actionDownload => 'Descargar';

  @override
  String get downloadComingSoonMessage =>
      'La función de descarga estará disponible pronto.';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get renameSongTitle => 'Renombrar canción';

  @override
  String get actionSave => 'Guardar';

  @override
  String get favoritesEmptyTitle => 'Aún no tienes favoritos';

  @override
  String get favoritesEmptyBody =>
      'Toca el ícono ♥ mientras reproduces una canción o clip.';

  @override
  String get sectionSongs => 'Canciones';

  @override
  String get sectionVideos => 'Videos';

  @override
  String get untitledClip => 'Clip sin título';

  @override
  String get comingSoonTitle => 'Próximamente';

  @override
  String get downloadsComingSoonBody =>
      'Estamos trabajando para que puedas ver aquí las canciones y videos que has descargado a tu dispositivo.';

  @override
  String get aiMusicSubtitle =>
      'Describe la canción que tienes en mente, nosotros nos encargamos del resto.';

  @override
  String get modeAdvancedTitle => 'Avanzado';

  @override
  String get modeAdvancedSubtitle =>
      'Describe la música como lo harías con una persona — su mundo, sentimiento, historia. La IA la convierte en una producción profesional.';

  @override
  String get modeStandardTitle => 'Estándar';

  @override
  String get modeStandardSubtitle =>
      'Elige tú mismo el estilo, ánimo, voz y duración — un formulario rápido y claro que te da el control total mientras creas tu canción en solo unos pasos.';

  @override
  String get modeQuickTitle => 'Rápido';

  @override
  String get modeQuickSubtitle =>
      'Describe tu idea en una frase y deja que la IA haga el resto — género, tempo, estilo vocal y tema lírico se eligen automáticamente por ti.';

  @override
  String get createFormAppBarTitle => 'Crea tu canción';

  @override
  String get createFormHeadline => 'Crea tu próxima canción';

  @override
  String get createFormSubtitle => 'Convierte tus ideas en música con IA';

  @override
  String get describeSongFirst => 'Por favor describe tu canción primero.';

  @override
  String get songReadyMessage => '¡Tu canción está lista! 🎶';

  @override
  String get describeSongLabel => 'Describe tu canción';

  @override
  String get describeSongHint =>
      'Una canción pop romántica sobre noches de verano...';

  @override
  String get labelGenre => 'GÉNERO';

  @override
  String get labelMood => 'ÁNIMO';

  @override
  String get labelVocal => 'VOZ';

  @override
  String get labelSongLength => 'DURACIÓN';

  @override
  String get quickCreateHeadline => 'Describe tu canción en una frase';

  @override
  String get quickCreateSubtitle =>
      'Deja que la IA se encargue del resto — género, tempo, voz, tema lírico, todo automático.';

  @override
  String get quickCreateHint =>
      'Ej: Una canción genial pero un poco oscura para escuchar mientras conduces por la ciudad de noche';

  @override
  String get preparingLabel => 'Preparando...';

  @override
  String get actionCreate => 'Crear';

  @override
  String unexpectedErrorWithDetail(String error) {
    return 'Ocurrió un error inesperado: $error';
  }

  @override
  String get proUpsellTitle => 'Desbloquea Tu Creatividad';

  @override
  String get proUpsellSubtitle => 'Crea más. Crea mejor.';

  @override
  String get planWeeklyTitle => 'Acceso de 7 Días';

  @override
  String get planWeeklySubtitle => 'Acceso ilimitado, facturado semanalmente';

  @override
  String get planYearlyTitle => 'Acceso Anual';

  @override
  String get planYearlyBadge => 'Mejor Valor';

  @override
  String get featureSongsVideos => 'Crea Canciones y Videos Musicales con IA';

  @override
  String get featureVoiceCovers => 'Haz Covers con IA con Tu Propia Voz';

  @override
  String get featurePriorityGeneration => 'Generación Prioritaria';

  @override
  String get featureCommercialLicense => 'Licencia Comercial Incluida';

  @override
  String get ctaContinue => 'Continuar';

  @override
  String get cancelAnytimeNote => 'Cancela cuando quieras.';

  @override
  String get restorePurchasesAction => 'Restaurar compras';

  @override
  String get purchaseSuccessMessage =>
      '¡Tu suscripción está activa! Bienvenido a Pro.';

  @override
  String saveBadge(int percent) {
    return 'Ahorra $percent%';
  }

  @override
  String productsLoadErrorWithDetail(String error) {
    return 'No se pudieron cargar los productos: $error';
  }

  @override
  String purchaseStartErrorWithDetail(String error) {
    return 'No se pudo iniciar la compra: $error';
  }

  @override
  String get loginHeadline => 'Dale vida\na tu música.';

  @override
  String get loginSignInWithApple => 'Continuar con Apple';

  @override
  String get loginOr => 'o';

  @override
  String get loginEmailLabel => 'Correo electrónico';

  @override
  String get loginPasswordLabel => 'Contraseña (mín. 8 caracteres)';

  @override
  String get loginVerificationCodeLabel => 'Código de verificación';

  @override
  String get loginTitleSignIn => 'Inicia sesión para continuar';

  @override
  String get loginTitleSignUp => 'Crea una cuenta nueva';

  @override
  String get loginTitleConfirm => 'Verifica tu correo';

  @override
  String get loginButtonSignIn => 'Iniciar sesión';

  @override
  String get loginButtonSignUp => 'Registrarse';

  @override
  String get loginButtonConfirm => 'Verificar';

  @override
  String get loginNoAccount => '¿No tienes cuenta? Regístrate';

  @override
  String get loginHaveAccount => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String loginAppleSignInFailedWithDetail(String error) {
    return 'Error al iniciar sesión con Apple: $error';
  }

  @override
  String loginConfirmCodeSentTo(String email) {
    return 'Ingresa el código de 6 dígitos enviado a $email.';
  }

  @override
  String get settingsSectionSettings => 'Ajustes';

  @override
  String get settingsSectionSupport => 'Soporte';

  @override
  String get settingsSectionAbout => 'Acerca de';

  @override
  String get settingsSectionAccount => 'Cuenta';

  @override
  String get settingsDisplayLanguage => 'Idioma de la Interfaz';

  @override
  String get settingsHomepagePreference => 'Preferencia de Inicio';

  @override
  String get settingsEmailSupport => 'Soporte por Correo';

  @override
  String get settingsHelpCenter => 'Centro de Ayuda';

  @override
  String get settingsRequestFeature => 'Solicitar una Función';

  @override
  String get settingsUploadVoice => 'Subir Voz';

  @override
  String get settingsShareWithFriends => 'Compartir con Amigos';

  @override
  String get settingsRateIt => 'Calificar';

  @override
  String get settingsTermsPrivacy => 'Términos y Privacidad';

  @override
  String get settingsCopyrightRemoval =>
      'Solicitud de Retiro por Derechos de Autor';

  @override
  String get settingsAboutUs => 'Sobre Nosotros';

  @override
  String get settingsComingSoon => 'Próximamente';

  @override
  String get settingsShareMessage =>
      'Descubre Melodia: ¡crea tus propias canciones con IA!';

  @override
  String get profileEditProfile => 'Editar Perfil';

  @override
  String get profileCompleteTitle => 'Completa tu Perfil';

  @override
  String get profileNoSongsYet => 'Aún no hay canciones publicadas';

  @override
  String get profileBrowseSongs => 'Explora tus canciones';

  @override
  String get profileStepTitle0 => '¿Cómo debemos llamarte?';

  @override
  String get profileStepSubtitle0 => 'Define tu nombre visible';

  @override
  String get profileStepTitle1 => 'Elige una foto de perfil';

  @override
  String get profileStepSubtitle1 => 'Dale un rostro a tu perfil';

  @override
  String get profileStepTitle2 => '¿Qué géneros musicales te gustan?';

  @override
  String get profileStepSubtitle2 => 'Elige de 1 a 5 géneros favoritos';

  @override
  String get profileStepTitle3 => '¿Qué quieres crear en Melodia?';

  @override
  String get profileStepSubtitle3 => 'Personalicemos tus recomendaciones';

  @override
  String get settingsAccountInfo => 'Información de la Cuenta';

  @override
  String get settingsSubscription => 'Suscripción y Pagos';

  @override
  String get settingsCredits => 'Créditos';

  @override
  String profileStepOf(int step) {
    return 'Paso $step de 4';
  }

  @override
  String get settingsSectionMembership => 'Suscripción';

  @override
  String get settingsSectionUsage => 'Uso';

  @override
  String get accountUserId => 'ID de Usuario';

  @override
  String get accountName => 'Nombre';

  @override
  String get accountEmail => 'Correo';

  @override
  String get accountMemberSince => 'Miembro Desde';

  @override
  String get accountCurrentPlan => 'Plan Actual';

  @override
  String get accountTotalSongs => 'Canciones Creadas';

  @override
  String get accountIdCopied => 'ID de usuario copiado';

  @override
  String get accountUnknown => 'Desconocido';

  @override
  String get planFree => 'Plan Gratuito';

  @override
  String get planProWeekly => 'Pro • Semanal';

  @override
  String get planProMonthly => 'Pro • Mensual';

  @override
  String get planProYearly => 'Pro • Anual';

  @override
  String get playerMinimize => 'Minimizar';

  @override
  String get playerMoreActions => 'Más';

  @override
  String get playerAiGenerated => 'Generado con IA';

  @override
  String get playerRemix => 'Remix';

  @override
  String get playerShare => 'Compartir';

  @override
  String get playerPlaylist => 'Playlist';

  @override
  String get playerComment => 'Comentar';

  @override
  String get playerComingSoon => 'Próximamente';

  @override
  String get playerAddFavorite => 'Añadir a favoritos';

  @override
  String get playerRemoveFavorite => 'Quitar de favoritos';

  @override
  String get playerDownload => 'Descargar';

  @override
  String get playerLyrics => 'Letra';

  @override
  String get playerCreateVideo => 'Crear videoclip';

  @override
  String get playerShuffle => 'Aleatorio';

  @override
  String get playerRepeat => 'Repetir';

  @override
  String get playerPrevious => 'Anterior';

  @override
  String get playerNext => 'Siguiente';

  @override
  String get playerPlay => 'Reproducir';

  @override
  String get playerPause => 'Pausar';

  @override
  String get playerNoSong => 'No se está reproduciendo nada';

  @override
  String get remixHint => 'Describe el nuevo estilo…';

  @override
  String get remixCreate => 'Crear remix';

  @override
  String get remixInstrumental => 'Instrumental';

  @override
  String get remixStarted => 'Preparando el remix';

  @override
  String get remixReady => 'Tu remix está listo';

  @override
  String get remixFailed => 'No se pudo crear el remix';

  @override
  String get remixView => 'Ver';

  @override
  String get remixListen => 'Escuchar';

  @override
  String get remixBuyCredits => 'Obtener créditos';

  @override
  String get remixCreditsNeeded =>
      'No tienes créditos suficientes para un remix.';

  @override
  String get remixStyleAcoustic => 'Acústico';

  @override
  String get remixStyleRock => 'Rock';

  @override
  String get remixStyleLofi => 'Lo-fi';

  @override
  String get remixStyleEdm => 'EDM';

  @override
  String get remixStyleJazz => 'Jazz';

  @override
  String get remixStyleOrchestral => 'Orquestal';

  @override
  String get remixStyleRnb => 'R&B';

  @override
  String get remixStyleTrap => 'Trap';

  @override
  String get remixStyle80s => 'Synthwave 80s';

  @override
  String get remixStyleLatin => 'Latino';

  @override
  String get remixStartedDetail => 'Te avisaremos cuando esté listo.';

  @override
  String get remixFailedDetail =>
      'No se gastaron créditos; puedes intentarlo de nuevo.';
}
