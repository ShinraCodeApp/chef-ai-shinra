import 'package:flutter/foundation.dart' show kIsWeb;

// Backend corriendo local (ver D:\Claude\Chef Ai By ShinraCode\backend).
// - Web (flutter run/build -d chrome): localhost funciona directo, es la misma PC.
// - APK instalado en un celular real: localhost apuntaría al celular mismo, no a
//   esta PC — hay que usar la IP de la red local (el celular debe estar en el
//   mismo WiFi y el puerto 3010 debe estar abierto en el Firewall de Windows).
const String _lanIp = '192.168.1.37';

final String kApiBaseUrl =
    kIsWeb ? 'http://localhost:3010' : 'http://$_lanIp:3010';
