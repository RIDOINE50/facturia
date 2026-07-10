import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);

class KkiapayWebviewScreen extends StatefulWidget {
  final String paymentUrl;
  final String transactionId;

  const KkiapayWebviewScreen({
    super.key,
    required this.paymentUrl,
    required this.transactionId,
  });

  @override
  State<KkiapayWebviewScreen> createState() => _KkiapayWebviewScreenState();
}

class _KkiapayWebviewScreenState extends State<KkiapayWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
            _checkUrlForCallback(url);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            _checkUrlForCallback(url);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkUrlForCallback(String url) {
    // KKiaPay redirige vers une URL avec le statut quand c'est fini
    if (url.contains('status=SUCCESS') || url.contains('transactionId=')) {
      final uri = Uri.parse(url);
      final status = uri.queryParameters['status'] ?? 'SUCCESS';
      
      Navigator.pop(context, {
        'status': status,
        'transactionId': widget.transactionId,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kDarkBlue,
        elevation: 0,
        title: Text(
          'Paiement sécurisé',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context, {'status': 'CANCELLED', 'transactionId': widget.transactionId}),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(color: kDarkBlue),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'status': 'SUCCESS',
                'transactionId': widget.transactionId,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kDarkBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text(
              "J'ai terminé le paiement",
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}