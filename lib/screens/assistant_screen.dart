import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/ai_service.dart';
import 'dashboard_screen.dart';
const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFF59E0B);
const Color kGreen = Color(0xFF10B981);
const Color kGrayText = Color(0xFF6B7280);

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  Map<String, dynamic>? _usage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _checkUsage();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkUsage() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final usage = await AIService.checkUsage(userId);
      setState(() => _usage = usage);
    }
  }

  Future<void> _loadHistory() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final history = await AIService.getHistory(userId, limit: 20);
    
    setState(() {
      _messages.clear();
      for (final conv in history.reversed) {
        _messages.add({
          'role': 'user',
          'content': conv['question'],
          'date': conv['created_at'],
        });
        _messages.add({
          'role': 'assistant',
          'content': conv['answer'],
          'date': conv['created_at'],
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
  if (!_scrollController.hasClients) return;
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });
}

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final usage = await AIService.checkUsage(userId);
    if (!usage['canUse']) {
      _showLimitDialog(usage);
      return;
    }

    setState(() {
      _messages.add({
        'role': 'user',
        'content': text,
        'date': DateTime.now().toIso8601String(),
      });
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    final conversationHistory = _messages.map((m) => {
      'role': m['role'] as String,
      'content': m['content'] as String,
    }).toList();

    final answer = await AIService.askQuestion(
      userId,
      text,
      conversationHistory: conversationHistory,
    );

    setState(() {
      _messages.add({
        'role': 'assistant',
        'content': answer,
        'date': DateTime.now().toIso8601String(),
      });
      _isLoading = false;
    });

    _scrollToBottom();
    _checkUsage();
  }

  void _showLimitDialog(Map<String, dynamic> usage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: kOrange),
            const SizedBox(width: 8),
            Text('Limite atteinte', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu as utilisé ${usage['used']}/${usage['limit']} messages ce mois-ci.',
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 16),
            Text(
              '💡 Passe au plan Starter (100 messages) ou Pro (illimité) pour continuer.',
              style: GoogleFonts.inter(fontSize: 13, color: kGrayText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: kDarkBlue, foregroundColor: Colors.white),
            child: const Text('Voir les plans'),
          ),
        ],
      ),
    );
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Effacer l\'historique ?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: const Text('Toutes tes conversations seront supprimées définitivement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final userId = Supabase.instance.client.auth.currentUser?.id;
              if (userId != null) {
                await AIService.clearHistory(userId);
                setState(() => _messages.clear());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: kDarkBlue,
        elevation: 0,
         leading: IconButton(
  icon: const Icon(Icons.arrow_back, color: Colors.white),
  onPressed: () {
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    } else {
      // Importe DashboardScreen en haut du fichier
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  },
),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assistant IA',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (_usage != null)
                  Text(
                    _usage!['limit'] == -1
                        ? 'Plan Pro · Illimité'
                        : '${_usage!['used']}/${_usage!['limit']} messages',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _clearHistory,
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'Effacer l\'historique',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildMessageBubble(msg);
                    },
                  ),
          ),

          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kDarkBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: kDarkBlue,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'L\'assistant réfléchit...',
                    style: GoogleFonts.inter(fontSize: 13, color: kGrayText),
                  ),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Pose ta question...',
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: kDarkBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kDarkBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: kDarkBlue, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            'Bonjour ! 👋',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Je suis ton assistant IA. Pose-moi n\'importe quelle question !',
            style: GoogleFonts.inter(fontSize: 14, color: kGrayText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSuggestion('C\'est quoi la TVA au Bénin ?'),
              _buildSuggestion('Comment rédiger une facture ?'),
              _buildSuggestion('Conseils pour mon business'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestion(String text) {
    return InkWell(
      onTap: () {
        _controller.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kDarkBlue.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(fontSize: 12, color: kDarkBlue),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isUser = msg['role'] == 'user';
    final content = msg['content'] as String;
    final date = msg['date'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kDarkBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.smart_toy, color: kDarkBlue, size: 16),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? kDarkBlue : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isUser ? Colors.white : Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  if (date != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _formatDate(date),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isUser ? Colors.white.withOpacity(0.7) : kGrayText,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.person, color: kOrange, size: 16),
            ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return '${date.day}/${date.month}/${date.year} ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
  }
}