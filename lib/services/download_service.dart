// 条件付きimport: Web では download_service_web.dart、それ以外は stub を使用
export 'download_service_stub.dart'
    if (dart.library.html) 'download_service_web.dart';
