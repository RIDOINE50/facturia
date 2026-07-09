import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice_data.dart';
import '../services/data_service.dart';
import 'create_invoice_step2.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kGrayText = Color(0xFF6B7280);
const Color kLightBlue = Color(0xFFF0F9FF);
const Color kInputBorder = Color(0xFFD1D5DB);

class CreateInvoiceStep1 extends StatefulWidget {
  const CreateInvoiceStep1({super.key});

  @override
  State<CreateInvoiceStep1> createState() => _CreateInvoiceStep1State();
}

class _CreateInvoiceStep1State extends State<CreateInvoiceStep1> {
  final InvoiceData _invoiceData = InvoiceData();
  List<Map<String, dynamic>> _allClients = [];
  List<Map<String, dynamic>> _filteredClients = [];
  bool _isLoading = true;
  bool _isGeneratingNumber = true;
  String? _selectedClientId;
  final _subjectController = TextEditingController();
  final _clientSearchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _clientSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final results = await Future.wait([
        DataService.getAllClients(user.id),
        DataService.getNextInvoiceNumber(user.id),
      ]);

      setState(() {
        _allClients = results[0] as List<Map<String, dynamic>>;
        _filteredClients = _allClients;
        _invoiceData.invoiceNumber = results[1] as String;
        _isLoading = false;
        _isGeneratingNumber = false;
      });
    } catch (e) {
      print('❌ Erreur chargement données : $e');
      setState(() {
        _isLoading = false;
        _isGeneratingNumber = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _filterClients(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredClients = _allClients;
        _isSearching = false;
      });
    } else {
      setState(() {
        _filteredClients = _allClients.where((client) {
          final name = (client['name'] ?? '').toString().toLowerCase();
          final phone = (client['phone'] ?? '').toString().toLowerCase();
          final email = (client['email'] ?? '').toString().toLowerCase();
          final searchQuery = query.toLowerCase();
          return name.contains(searchQuery) ||
              phone.contains(searchQuery) ||
              email.contains(searchQuery);
        }).toList();
        _isSearching = true;
      });
    }
  }

  void _selectClient(Map<String, dynamic> client) {
    setState(() {
      _selectedClientId = client['id'] as String;
      _invoiceData.clientName = client['name'] as String;
      _clientSearchController.text = client['name'] as String;
      _isSearching = false;
    });
  }

  void _clearClient() {
    setState(() {
      _selectedClientId = null;
      _invoiceData.clientName = '';
      _clientSearchController.clear();
      _filteredClients = _allClients;
    });
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 15)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: kDarkBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _invoiceData.dueDate = picked;
      });
    }
  }

  void _handleNext() {
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un client'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _invoiceData.clientId = _selectedClientId;
    _invoiceData.subject = _subjectController.text;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateInvoiceStep2(invoiceData: _invoiceData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        body: Center(
          child: CircularProgressIndicator(color: kDarkBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: kDarkBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nouvelle facture',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Remplis les informations de base',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: kDarkBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            '1',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Infos',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kDarkBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '2',
                            style: TextStyle(color: kGrayText, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Articles',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: kGrayText,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '3',
                            style: TextStyle(color: kGrayText, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Options',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: kGrayText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contenu
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Client avec recherche
                  Text(
                    'CLIENT',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kGrayText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  if (_allClients.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Aucun client. Ajoutez d\'abord un client dans l\'écran Clients.',
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Champ de recherche
                        TextField(
                          controller: _clientSearchController,
                          onChanged: _filterClients,
                          onTap: () {
                            if (_selectedClientId == null) {
                              setState(() {
                                _isSearching = true;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            hintText: _selectedClientId == null 
                                ? 'Rechercher un client...' 
                                : 'Client sélectionné',
                            hintStyle: GoogleFonts.inter(fontSize: 14, color: kGrayText),
                            prefixIcon: const Icon(Icons.search, color: kGrayText, size: 20),
                            suffixIcon: _selectedClientId != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: kGrayText, size: 20),
                                    onPressed: _clearClient,
                                  )
                                : _clientSearchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, color: kGrayText, size: 20),
                                        onPressed: () {
                                          _clientSearchController.clear();
                                          _filterClients('');
                                        },
                                      )
                                    : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _selectedClientId != null ? kGreen : kInputBorder,
                                width: _selectedClientId != null ? 2 : 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _selectedClientId != null ? kGreen : kInputBorder,
                                width: _selectedClientId != null ? 2 : 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _selectedClientId != null ? kGreen : kDarkBlue,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        
                        // Liste des suggestions
                        if (_isSearching && _selectedClientId == null) ...[
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 300),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kInputBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _filteredClients.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      'Aucun client trouvé',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: kGrayText,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _filteredClients.length,
                                    itemBuilder: (context, index) {
                                      final client = _filteredClients[index];
                                      final name = client['name'] as String;
                                      final phone = client['phone'] as String?;
                                      final email = client['email'] as String?;
                                      
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: kDarkBlue.withOpacity(0.1),
                                          child: Text(
                                            name.substring(0, name.length > 2 ? 2 : 1).toUpperCase(),
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: kDarkBlue,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          name,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        subtitle: Text(
                                          [phone, email].where((e) => e != null && e.isNotEmpty).join(' · '),
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: kGrayText,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: kGrayText,
                                        ),
                                        onTap: () => _selectClient(client),
                                      );
                                    },
                                  ),
                          ),
                        ],
                        
                        // Info si client sélectionné
                        if (_selectedClientId != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: kGreen.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: kGreen, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Client sélectionné : ${_invoiceData.clientName}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: kGreen,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 24),

                  // Section Détails
                  Text(
                    'DÉTAILS DE LA FACTURE',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kGrayText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          'NUMÉRO',
                          _isGeneratingNumber ? 'Génération...' : _invoiceData.invoiceNumber,
                          Icons.description_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                          'DATE',
                          _formatDate(_invoiceData.issueDate),
                          Icons.calendar_today,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // ÉCHÉANCE
                  GestureDetector(
                    onTap: _selectDueDate,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DATE D\'ÉCHÉANCE',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: kGrayText,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kInputBorder),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _invoiceData.dueDate == null
                                      ? 'Choisir une date'
                                      : _formatDate(_invoiceData.dueDate!),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: _invoiceData.dueDate == null ? kGrayText : Colors.black87,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.event,
                                color: _invoiceData.dueDate == null ? kGrayText : kDarkBlue,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 12, color: kGrayText),
                            const SizedBox(width: 4),
                            Text(
                              'Seules les dates futures sont autorisées',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: kGrayText,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OBJET DE LA FACTURE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: kGrayText,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          hintText: 'Ex: Développement site web',
                          hintStyle: GoogleFonts.inter(fontSize: 14, color: kGrayText),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: kInputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: kInputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: kDarkBlue, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bouton Suivant
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _allClients.isEmpty ? null : _handleNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kDarkBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Suivant · Ajouter des articles',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: kGrayText,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kInputBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              Icon(icon, color: kGrayText, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}