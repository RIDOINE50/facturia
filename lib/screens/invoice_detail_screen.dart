import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});
  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  String _testResult = "Appuie sur le bouton";

  Future<void> _testUrls() async {
    print('🔍 DÉBUT DU TEST');
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _testResult = "❌ Pas connecté");
      return;
    }

    print('🔍 User ID: ${user.id}');

    final response = await Supabase.instance.client
        .from('profiles')
        .select('logo_url, signature_url, stamp_url')
        .eq('id', user.id)
        .maybeSingle();

    print('🔍 Réponse complète: $response');

    setState(() {
      _testResult = "Logo: ${response?['logo_url']}\nSignature: ${response?['signature_url']}\nCachet: ${response?['stamp_url']}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TEST')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_testResult, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testUrls,
              child: const Text('TESTER'),
            ),
          ],
        ),
      ),
    );
  }
}