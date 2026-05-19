class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:3000';
  static const String mobilePrefix = '/api/mobile';

  static const String login = '$mobilePrefix/login';
  static const String menu = '$mobilePrefix/menu';
  static const String lokasi = '$mobilePrefix/lokasi';
  static const String dataTerakhir = '$mobilePrefix/data-terakhir';
  static const String info = '$mobilePrefix/info';

  static const String loggers = '/api/loggers';
  static const String logKontrol = '/api/log-kontrol';
  static const String deformasi = '/api/deformasi';
  static const String sensorData = '/api/sensor-data';
  static const String prismaData = '/api/prisma-data';
  static const String configAdr = '/api/config-adr';
  static const String prismConfig = '/api/prism-config';
  static const String scheduling = '/api/scheduling';
  static const String powerRts = '/api/power-rts';
  static const String analisa = '/api/analisa';
  static const String rekapData = '/api/rekap-data';

  static const String kontolStart = '/api/kontrol/start';
  static const String kontrolPower = '/api/kontrol/power';
  static const String kontrolStop = '/api/kontrol/stop';
  static const String kontrolSelesai = '/api/kontrol/selesai';
  static const String kontrolVerifyAccess = '/api/kontrol/verify-access';

  static const String masterLokasi = '/api/lokasi';
  static const String masterUsers = '/api/users';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
