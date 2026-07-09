import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFF59E0B);
const Color kGreen = Color(0xFF10B981);
const Color kRed = Color(0xFFEF4444);
const Color kGrayText = Color(0xFF6B7280);

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  String _selectedPeriod = '6 mois';
  final List<String> _periods = ['Ce mois', '3 mois', '6 mois'];

  // Données utilisateurs par mois
  List<Map<String, dynamic>> _usersByMonth = [];
  int _totalNewUsers = 0;

  // Données revenus par mois
  List<Map<String, dynamic>> _revenueByMonth = [];
  double _totalRevenue = 0;

  // Répartition géographique
  List<Map<String, dynamic>> _geoData = [];

  // Usage par secteur
  List<Map<String, dynamic>> _sectorData = [];

  // Mode de paiement
  List<Map<String, dynamic>> _paymentData = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  int _getMonthsCount() {
    if (_selectedPeriod == 'Ce mois') return 1;
    if (_selectedPeriod == '3 mois') return 3;
    return 6;
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;
      final monthsCount = _getMonthsCount();
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - monthsCount + 1, 1);

      // 1. Récupérer les profils créés récemment
      final profilesRes = await client
          .from('profiles')
          .select('created_at')
          .gte('created_at', startDate.toIso8601String())
          .order('created_at', ascending: true);

      // 2. Récupérer les factures récentes
      final invoicesRes = await client
          .from('invoices')
          .select('total_amount, created_at')
          .gte('created_at', startDate.toIso8601String())
          .order('created_at', ascending: true);

      // 3. Récupérer les entreprises pour géo et secteur
      final companiesRes = await client
          .from('companies')
          .select('city, sector, mobile_money_operator');

      // 4. Calculer utilisateurs par mois
      _usersByMonth = _groupByMonth(profilesRes, 'created_at');
      _totalNewUsers = profilesRes.length;

      // 5. Calculer revenus par mois
      _revenueByMonth = _groupByMonthRevenue(invoicesRes);
      _totalRevenue = invoicesRes.fold(0.0, (sum, inv) {
        return sum + ((inv['total_amount'] as num?)?.toDouble() ?? 0);
      });

      // 6. Répartition géographique
      _geoData = _countByField(companiesRes, 'city');

      // 7. Usage par secteur
      _sectorData = _countByField(companiesRes, 'sector');

      // 8. Mode de paiement
      _paymentData = _countByField(companiesRes, 'mobile_money_operator');

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Erreur chargement stats : $e');
      setState(() {
        _isLoading = false;
        _error = 'Erreur de chargement : $e';
      });
    }
  }

  List<Map<String, dynamic>> _groupByMonth(List<dynamic> items, String field) {
    final Map<String, int> grouped = {};
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];

    for (final item in items) {
      final dateStr = item[field];
      if (dateStr != null) {
        final date = DateTime.parse(dateStr);
        final key = months[date.month - 1];
        grouped[key] = (grouped[key] ?? 0) + 1;
      }
    }

    return grouped.entries.map((e) => {'month': e.key, 'count': e.value}).toList();
  }

  List<Map<String, dynamic>> _groupByMonthRevenue(List<dynamic> invoices) {
    final Map<String, double> grouped = {};
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];

    for (final inv in invoices) {
      final dateStr = inv['created_at'];
      final amount = (inv['total_amount'] as num?)?.toDouble() ?? 0;
      if (dateStr != null) {
        final date = DateTime.parse(dateStr);
        final key = months[date.month - 1];
        grouped[key] = (grouped[key] ?? 0) + amount;
      }
    }

    return grouped.entries.map((e) => {'month': e.key, 'revenue': e.value}).toList();
  }

  List<Map<String, dynamic>> _countByField(List<dynamic> items, String field) {
    final Map<String, int> counts = {};

    for (final item in items) {
      final value = item[field];
      if (value != null && value.toString().isNotEmpty) {
        final key = value.toString();
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }

    final total = counts.values.fold(0, (a, b) => a + b);
    return counts.entries
        .map((e) => {
              'label': e.key,
              'count': e.value,
              'percent': total > 0 ? (e.value / total * 100).toStringAsFixed(0) : '0'
            })
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kDarkBlue));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: GoogleFonts.inter(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadStats,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(backgroundColor: kDarkBlue, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statistiques avancées', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            Text('Croissance · Géographie · Usage', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh, color: kDarkBlue),
            tooltip: 'Actualiser',
          ),
          const SizedBox(width: 8),
          ..._periods.map((p) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildPeriodButton(p, _selectedPeriod == p),
          )),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Graphiques
            Row(
              children: [
                Expanded(
                  child: _buildChartCard(
                    'Nouveaux utilisateurs / mois',
                    _usersByMonth.isEmpty
                        ? _buildEmptyChart('Aucune donnée')
                        : _buildBarChart(_usersByMonth, 'count', Colors.blue),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildChartCard(
                    'Revenus MRR / mois',
                    _revenueByMonth.isEmpty
                        ? _buildEmptyChart('Aucune donnée')
                        : _buildBarChart(_revenueByMonth, 'revenue', kGreen),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Répartition géographique et Usage
            Row(
              children: [
                Expanded(
                  child: _buildStatsCard(
                    'Répartition géographique',
                    _geoData.isEmpty
                        ? _buildEmptyData('Aucune ville enregistrée')
                        : Column(
                            children: _geoData.take(5).map((item) {
                              final colors = [Colors.blue, kGreen, kOrange, Colors.purple, kGrayText];
                              final index = _geoData.indexOf(item) % colors.length;
                              return _buildStatBar(
                                item['label'],
                                '${item['percent']}%',
                                item['count'],
                                colors[index],
                                double.parse(item['percent']),
                              );
                            }).toList(),
                          ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildStatsCard(
                    'Usage par secteur d\'activité',
                    _sectorData.isEmpty
                        ? _buildEmptyData('Aucun secteur enregistré')
                        : Column(
                            children: _sectorData.take(5).map((item) {
                              final colors = [Colors.blue, kOrange, kGreen, Colors.purple, kGrayText];
                              final index = _sectorData.indexOf(item) % colors.length;
                              return _buildStatBar(
                                item['label'],
                                '${item['percent']}%',
                                item['count'],
                                colors[index],
                                double.parse(item['percent']),
                              );
                            }).toList(),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Mode de paiement
            _buildStatsCard(
              'Mode de paiement favori',
              _paymentData.isEmpty
                  ? _buildEmptyData('Aucun mode de paiement enregistré')
                  : Row(
                      children: _paymentData.take(3).map((item) {
                        final colors = [kOrange, Colors.blue, kGrayText];
                        final index = _paymentData.indexOf(item) % colors.length;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: _buildPaymentStat(
                              item['label'],
                              '${item['percent']}%',
                              colors[index],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() => _selectedPeriod = label);
        _loadStats();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kDarkBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? kDarkBlue : Colors.grey.shade300),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildChartCard(String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 20),
          content,
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 20),
          content,
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      height: 200,
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(message, style: GoogleFonts.inter(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyData(String message) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(message, style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data, String valueKey, Color color) {
  final maxValue = data.fold(0.0, (max, item) {
    final val = (item[valueKey] as num).toDouble();
    return val > max ? val : max;
  });

  return SizedBox(
    height: 220, // Augmenté de 200 à 220
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((item) {
        final value = (item[valueKey] as num).toDouble();
        final height = maxValue > 0 ? (value / maxValue * 140) : 0.0; // Réduit de 160 à 140
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Valeur en haut
                Text(
                  valueKey == 'revenue' ? '${_formatAmount(value)} F' : value.toStringAsFixed(0),
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 2), // Réduit de 4 à 2
                // Barre
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 4), // Réduit de 8 à 4
                // Mois en bas
                Text(
                  item['month'],
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ),
  );
}

  Widget _buildStatBar(String label, String percent, int count, Color color, double widthPercent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, color: Colors.black87))),
              Row(
                children: [
                  Text('$percent', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(width: 10),
                  Text('$count', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widthPercent / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStat(String label, String percent, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(percent, style: GoogleFonts.novaFlat(fontSize: 24, color: color)),
        ],
      ),
    );
  }
}