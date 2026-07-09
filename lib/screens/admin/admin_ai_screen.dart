import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/ai_admin_service.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFF59E0B);
const Color kGreen = Color(0xFF10B981);
const Color kGrayText = Color(0xFF6B7280);

class AdminAIScreen extends StatefulWidget {
  const AdminAIScreen({super.key});

  @override
  State<AdminAIScreen> createState() => _AdminAIScreenState();
}

class _AdminAIScreenState extends State<AdminAIScreen> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
  setState(() => _isLoading = true);

  try {
    final results = await Future.wait([
      AIAdminService.getAIStats(),
      AIAdminService.getAllConversations(limit: 50),
    ]);

    if (!mounted) return; // ← AJOUTÉ : vérifie que le widget existe toujours

    setState(() {
      _stats = results[0] as Map<String, dynamic>;
      _conversations = results[1] as List<Map<String, dynamic>>;
      _isLoading = false;
    });
  } catch (e) {
    print('❌ Erreur chargement données IA : $e');
    if (!mounted) return; // ← AJOUTÉ
    
    setState(() => _isLoading = false);
  }
}

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: kDarkBlue,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Supervision IA', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Statistiques et conversations', style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withOpacity(0.8))),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kDarkBlue))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Messages ce mois', '${_stats?['messagesThisMonth'] ?? 0}', Icons.chat, kDarkBlue)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Coût total', '${_formatAmount(_stats?['totalCost'] ?? 0)} F', Icons.attach_money, kOrange)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Total messages', '${_stats?['totalMessages'] ?? 0}', Icons.message, kGreen)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Utilisateurs', '${_stats?['uniqueUsers'] ?? 0}', Icons.people, const Color(0xFF8B5CF6))),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text('SUJETS FRÉQUENTS CE MOIS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: kGrayText, letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        children: [
                          ...(_stats?['topics'] as Map<String, dynamic>? ?? {}).entries.map((entry) {
                            final topic = entry.key;
                            final count = entry.value as int;
                            final total = (_stats?['messagesThisMonth'] ?? 1) as int;
                            final percentage = total > 0 ? (count / total * 100).round() : 0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(flex: 2, child: Text(topic, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87))),
                                  Expanded(flex: 3, child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: percentage / 100, backgroundColor: Colors.grey.shade200, color: kDarkBlue, minHeight: 8))),
                                  const SizedBox(width: 12),
                                  Text('$percentage%', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: kDarkBlue)),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('CONVERSATIONS RÉCENTES', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: kGrayText, letterSpacing: 0.5)),
                        TextButton(onPressed: _loadData, child: Text('Actualiser', style: GoogleFonts.inter(fontSize: 12, color: kDarkBlue, fontWeight: FontWeight.w600))),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_conversations.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                        child: Column(children: [
                          const Icon(Icons.chat_bubble_outline, size: 48, color: kGrayText),
                          const SizedBox(height: 12),
                          Text('Aucune conversation pour le moment', style: GoogleFonts.inter(fontSize: 14, color: kGrayText, fontWeight: FontWeight.w500)),
                        ]),
                      )
                    else
                      ..._conversations.map((conv) {
                        final profiles = conv['profiles'] as Map<String, dynamic>?;
                        final userName = profiles != null ? '${profiles['first_name'] ?? ''} ${profiles['last_name'] ?? ''}'.trim() : 'Utilisateur';
                        final userEmail = profiles?['email'] ?? '';
                        final question = conv['question'] ?? '';
                        final answer = conv['answer'] ?? '';
                        final date = conv['created_at'] ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => _showConversationDetail(conv),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(width: 40, height: 40, decoration: BoxDecoration(color: kDarkBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.person, color: kDarkBlue, size: 20)),
                                      const SizedBox(width: 12),
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(userName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                                        Text(userEmail, style: GoogleFonts.inter(fontSize: 11, color: kGrayText)),
                                      ])),
                                      Text(_formatDate(date), style: GoogleFonts.inter(fontSize: 11, color: kGrayText)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Q: $question', style: GoogleFonts.inter(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 8),
                                      Text('R: ${answer.length > 100 ? '${answer.substring(0, 100)}...' : answer}', style: GoogleFonts.inter(fontSize: 12, color: kGrayText), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    ]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(label, style: GoogleFonts.inter(fontSize: 11, color: kGrayText))]),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  void _showConversationDetail(Map<String, dynamic> conv) {
    final profiles = conv['profiles'] as Map<String, dynamic>?;
    final userName = profiles != null ? '${profiles['first_name'] ?? ''} ${profiles['last_name'] ?? ''}'.trim() : 'Utilisateur';
    final userEmail = profiles?['email'] ?? '';
    final question = conv['question'] ?? '';
    final answer = conv['answer'] ?? '';
    final date = conv['created_at'] ?? '';
    final tokensUsed = conv['tokens_used'] ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(userName, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(userEmail, style: GoogleFonts.inter(fontSize: 12, color: kGrayText)),
        ]),
        content: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kDarkBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Question', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: kDarkBlue)),
                const SizedBox(height: 4),
                Text(question, style: GoogleFonts.inter(fontSize: 13, color: Colors.black87)),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Réponse', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: kGreen)),
                const SizedBox(height: 4),
                Text(answer, style: GoogleFonts.inter(fontSize: 13, color: Colors.black87)),
              ]),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Text('Date: ', style: GoogleFonts.inter(fontSize: 11, color: kGrayText)),
              Text(_formatDate(date), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
              const Spacer(),
              Text('Tokens: $tokensUsed', style: GoogleFonts.inter(fontSize: 11, color: kGrayText)),
            ]),
          ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'À l\'instant';
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}