/// Configurações de repositório usadas para atualização OTA.
class AppConfig {
  static const String githubOwner = 'abobicaduco';
  static const String githubRepo = 'mogi-onibus';

  /// JSON de horários servido direto do repositório (atualizado semanalmente).
  static const String schedulesRawUrl =
      'https://raw.githubusercontent.com/$githubOwner/$githubRepo/main/app/assets/schedules.json';

  /// API de releases — usada para avisar sobre nova versão do APK.
  static const String latestReleaseApi =
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';

  static const String releasesPageUrl =
      'https://github.com/$githubOwner/$githubRepo/releases/latest';

  static const String sourceUrl =
      'https://github.com/$githubOwner/$githubRepo';

  static const String fonteOficial =
      'https://mobilidadeservicos.mogidascruzes.sp.gov.br/site/transportes';
}
