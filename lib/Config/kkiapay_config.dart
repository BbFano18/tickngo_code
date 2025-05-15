class KkiapayConfig {
  // Clés de test (Sandbox)
  static const String SANDBOX_PUBLIC_KEY = "424553af8d6a69b2e50839a0a6a3eb5e2fc112ec";
  static const String SANDBOX_PRIVATE_KEY = "sk_36b81a3083924f93861a4cd5791dd8be4a8e21d4b33eccf4a7adacb2e8393ffe";
  
  // URL de base
  static const String SANDBOX_URL = "https://api-sandbox.kkiapay.me";
  static const String PRODUCTION_URL = "https://api.kkiapay.me";
  
  // URL du widget
  static const String SANDBOX_WIDGET_URL = "https://widget-sandbox.kkiapay.me";
  static const String PRODUCTION_WIDGET_URL = "https://widget.kkiapay.me";
  
  // Paramètres par défaut
  static const bool IS_SANDBOX = true;
  static const String SUCCESS_CALLBACK = "https://tickngo.com/payment/success";
  static const String CANCEL_CALLBACK = "https://tickngo.com/payment/cancel";
  
  // Timeout des requêtes (en secondes)
  static const int REQUEST_TIMEOUT = 30;
} 