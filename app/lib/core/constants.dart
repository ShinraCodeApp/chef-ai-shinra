// Backend en producción (Render), conectado a Postgres en Neon.
// Funciona desde cualquier red (WiFi o datos móviles), no solo en la red local.
// Para probar contra un backend local: --dart-define=API_BASE_URL=http://localhost:3099
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://chef-ai-shinra.onrender.com',
);
