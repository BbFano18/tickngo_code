import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';

class KKiapayWidget extends StatefulWidget {
  final String apiKey;
  final double amount;
  final String reason;
  final String phone;
  final String name;
  final bool isSandbox;
  final Function(Map<String, dynamic>) onPaymentSuccess;
  final Function(String) onPaymentError;
  final Function() onPaymentClosed;

  const KKiapayWidget({
    Key? key,
    required this.apiKey,
    required this.amount,
    required this.reason,
    this.phone = '',
    this.name = '',
    this.isSandbox = true,
    required this.onPaymentSuccess,
    required this.onPaymentError,
    required this.onPaymentClosed,
  }) : super(key: key);

  @override
  State<KKiapayWidget> createState() => _KKiapayWidgetState();
}

class _KKiapayWidgetState extends State<KKiapayWidget> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'PaymentSuccess',
        onMessageReceived: (message) {
          widget.onPaymentSuccess(jsonDecode(message.message));
        },
      )
      ..addJavaScriptChannel(
        'PaymentFailed',
        onMessageReceived: (message) {
          widget.onPaymentError(message.message);
        },
      )
      ..addJavaScriptChannel(
        'PaymentClosed',
        onMessageReceived: (message) {
          widget.onPaymentClosed();
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (request.url.contains("error")) {
              widget.onPaymentError("Erreur de réseau");
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(_buildHtml());
  }

  String _sanitize(String input) => input.replaceAll('"', '\\"');

  String _buildHtml() {
    final amount = widget.amount.toStringAsFixed(0);
    final key = _sanitize(widget.apiKey);
    final reason = _sanitize(widget.reason);
    final phone = _sanitize(widget.phone);
    final name = _sanitize(widget.name);
    final sandbox = widget.isSandbox ? 'true' : 'false';

    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <script src="https://cdn.kkiapay.me/k.js"></script>
      <style>
        body {
          margin: 0;
          padding: 0;
          display: flex;
          justify-content: center;
          align-items: center;
          height: 100vh;
          background-color: rgba(30, 30, 35, 0.9);
          font-family: 'Poppins', sans-serif;
        }
        #payment-button {
          padding: 16px 30px;
          background-color: #6a1b9a;
          color: white;
          border: none;
          border-radius: 12px;
          font-size: 16px;
          font-weight: 600;
          cursor: pointer;
          transition: background-color 0.3s;
        }
        #payment-button:hover {
          background-color: #9c27b0;
        }
      </style>
    </head>
    <body>
      <button id="payment-button">Payer $amount CFA</button>
      <script>
        window.onload = function() {
          document.getElementById('payment-button').click();
        };
        document.getElementById('payment-button').addEventListener('click', function() {
          openKkiapayWidget({
            amount: $amount,
            key: "424553af8d6a69b2e50839a0a6a3eb5e2fc112ec",
            sandbox: true,
            theme: "purple",
            reason: "Payement de ticket",
            phone: "+22990190325",
            data: {
              ticket_type: "event_ticket",
              app_name: "TicknGo"
            }
          });
        });
        window.addEventListener('kkiapay-payment-success', function(e) {
          PaymentSuccess.postMessage(JSON.stringify(e.detail));
        });
        window.addEventListener('kkiapay-payment-failed', function(e) {
          PaymentFailed.postMessage('Le paiement a échoué');
        });
        window.addEventListener('kkiapay-widget-closed', function() {
          PaymentClosed.postMessage('');
        });
      </script>
    </body>
    </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _isLoading
                ? Container(color: Colors.white)
                : WebViewWidget(controller: _controller),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            ),
        ],
      ),
    );
  }
}
