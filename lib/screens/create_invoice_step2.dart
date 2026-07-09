import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice_data.dart';
import '../services/data_service.dart';
import 'create_invoice_step3.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kGreen = Color(0xFF10B981);
const Color kOrange = Color(0xFFF59E0B);
const Color kRed = Color(0xFFEF4444);
const Color kGrayText = Color(0xFF6B7280);
const Color kLightBlue = Color(0xFFF0F9FF);
const Color kInputBorder = Color(0xFFD1D5DB);

class CreateInvoiceStep2 extends StatefulWidget {
  final InvoiceData invoiceData;

  const CreateInvoiceStep2({super.key, required this.invoiceData});

  @override
  State<CreateInvoiceStep2> createState() => _CreateInvoiceStep2State();
}

class _CreateInvoiceStep2State extends State<CreateInvoiceStep2> {
  List<Map<String, dynamic>> _allServices = [];
  List<Map<String, dynamic>> _filteredServices = [];
  bool _isLoading = true;
  final Map<String, int> _quantities = {};
  final _serviceSearchController = TextEditingController();
  bool _isSearching = false;
  bool _isAddingCustom = false;

  // Contrôleurs pour article libre
  final _customDescController = TextEditingController();
  final _customQtyController = TextEditingController(text: '1');
  final _customPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _serviceSearchController.dispose();
    _customDescController.dispose();
    _customQtyController.dispose();
    _customPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final services = await DataService.getAllServices(user.id);
      
      for (var service in services) {
        _quantities[service['id']] = 1;
      }
      
      setState(() {
        _allServices = services;
        _filteredServices = services;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement services : $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  void _filterServices(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredServices = _allServices;
        _isSearching = false;
      });
    } else {
      setState(() {
        _filteredServices = _allServices.where((service) {
          final name = (service['name'] ?? '').toString().toLowerCase();
          final description = (service['description'] ?? '').toString().toLowerCase();
          final searchQuery = query.toLowerCase();
          return name.contains(searchQuery) || description.contains(searchQuery);
        }).toList();
        _isSearching = true;
      });
    }
  }

  void _updateQuantity(String serviceId, int delta) {
    setState(() {
      final current = _quantities[serviceId] ?? 1;
      final newValue = current + delta;
      if (newValue >= 1) {
        _quantities[serviceId] = newValue;
      }
    });
  }

  void _addServiceToInvoice(Map<String, dynamic> service) {
    final serviceId = service['id'] as String;
    final name = service['name'] as String;
    final price = (service['unit_price'] as num).toDouble();
    final quantity = _quantities[serviceId] ?? 1;

    setState(() {
      widget.invoiceData.items.add(InvoiceItem(
        description: name,
        quantity: quantity,
        unitPrice: price,
      ));
      _quantities[serviceId] = 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$quantity × "$name" ajouté${quantity > 1 ? 's' : ''}'),
        backgroundColor: kGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addCustomItem() {
    final description = _customDescController.text.trim();
    final quantity = int.tryParse(_customQtyController.text) ?? 1;
    final price = double.tryParse(_customPriceController.text) ?? 0;

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une description'),
          backgroundColor: kRed,
        ),
      );
      return;
    }

    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un prix valide'),
          backgroundColor: kRed,
        ),
      );
      return;
    }

    setState(() {
      widget.invoiceData.items.add(InvoiceItem(
        description: description,
        quantity: quantity,
        unitPrice: price,
      ));
      _isAddingCustom = false;
      _customDescController.clear();
      _customQtyController.text = '1';
      _customPriceController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Article personnalisé ajouté'),
        backgroundColor: kGreen,
      ),
    );
  }

  void _removeItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Supprimer cet article ?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'L\'article "${widget.invoiceData.items[index].description}" sera retiré de la facture.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                widget.invoiceData.items.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Article supprimé'),
                  backgroundColor: kRed,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _editItem(int index) {
    final item = widget.invoiceData.items[index];
    final descController = TextEditingController(text: item.description);
    final qtyController = TextEditingController(text: item.quantity.toString());
    final priceController = TextEditingController(text: item.unitPrice.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Modifier l\'article',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantité'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Prix unit. (FCFA)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final newDesc = descController.text.trim();
              final newQty = int.tryParse(qtyController.text) ?? 1;
              final newPrice = double.tryParse(priceController.text) ?? 0;

              if (newDesc.isEmpty || newPrice <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez remplir tous les champs correctement'),
                    backgroundColor: kRed,
                  ),
                );
                return;
              }

              setState(() {
                widget.invoiceData.items[index] = InvoiceItem(
                  description: newDesc,
                  quantity: newQty,
                  unitPrice: newPrice,
                );
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Article modifié'),
                  backgroundColor: kGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kDarkBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enregistrer'),
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
              'Choisis tes services et quantités',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        actions: [
          // Badge compteur d'articles
          if (widget.invoiceData.items.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.invoiceData.items.length}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
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
                        child: const Icon(Icons.check, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Infos',
                        style: GoogleFonts.inter(fontSize: 13, color: kGrayText),
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
                        decoration: const BoxDecoration(
                          color: kDarkBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            '2',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Articles',
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
                            '3',
                            style: TextStyle(color: kGrayText, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Options',
                        style: GoogleFonts.inter(fontSize: 13, color: kGrayText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contenu principal
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kDarkBlue))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ==========================================
                        // SECTION 1 : ARTICLES AJOUTÉS
                        // ==========================================
                        if (widget.invoiceData.items.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  kGreen.withOpacity(0.1),
                                  kGreen.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kGreen.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: kGreen,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.check_circle, color: Colors.white, size: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'ARTICLES AJOUTÉS',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: kGreen,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: kGreen,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${widget.invoiceData.items.length}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...List.generate(widget.invoiceData.items.length, (index) {
                                  final item = widget.invoiceData.items[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: kDarkBlue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: kDarkBlue,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.description,
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${item.quantity} × ${_formatAmount(item.unitPrice)} F = ${_formatAmount(item.totalPrice)} F',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: kGrayText,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: kDarkBlue, size: 18),
                                          onPressed: () => _editItem(index),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: kRed, size: 18),
                                          onPressed: () => _removeItem(index),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // ==========================================
                        // SECTION 2 : BOUTONS D'AJOUT
                        // ==========================================
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isAddingCustom = !_isAddingCustom;
                                    _isSearching = false;
                                  });
                                },
                                icon: Icon(
                                  _isAddingCustom ? Icons.close : Icons.edit_note,
                                  size: 18,
                                ),
                                label: Text(
                                  _isAddingCustom ? 'Fermer' : 'Article libre',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isAddingCustom ? kRed : kOrange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isSearching = !_isSearching;
                                    _isAddingCustom = false;
                                    if (_isSearching) {
                                      _serviceSearchController.clear();
                                      _filteredServices = _allServices;
                                    }
                                  });
                                },
                                icon: Icon(
                                  _isSearching ? Icons.close : Icons.search,
                                  size: 18,
                                ),
                                label: Text(
                                  _isSearching ? 'Fermer' : 'Rechercher',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isSearching ? kRed : kDarkBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ==========================================
                        // FORMULAIRE ARTICLE LIBRE
                        // ==========================================
                        if (_isAddingCustom) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kOrange, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: kOrange.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.edit_note, color: kOrange, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Nouvel article personnalisé',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: kOrange,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'DESCRIPTION *',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: kGrayText,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _customDescController,
                                  decoration: InputDecoration(
                                    hintText: 'Ex: Conception logo...',
                                    hintStyle: GoogleFonts.inter(fontSize: 14, color: kGrayText),
                                    filled: true,
                                    fillColor: kLightBlue,
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
                                      borderSide: const BorderSide(color: kOrange, width: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'QUANTITÉ',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: kGrayText,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          TextField(
                                            controller: _customQtyController,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              hintText: '1',
                                              hintStyle: GoogleFonts.inter(fontSize: 14, color: kGrayText),
                                              filled: true,
                                              fillColor: kLightBlue,
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
                                                borderSide: const BorderSide(color: kOrange, width: 2),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'PRIX UNITAIRE (FCFA) *',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: kGrayText,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          TextField(
                                            controller: _customPriceController,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              hintText: '50000',
                                              hintStyle: GoogleFonts.inter(fontSize: 14, color: kGrayText),
                                              filled: true,
                                              fillColor: kLightBlue,
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
                                                borderSide: const BorderSide(color: kOrange, width: 2),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _addCustomItem,
                                    icon: const Icon(Icons.add_circle, size: 18),
                                    label: Text(
                                      'Ajouter l\'article',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ==========================================
                        // BARRE DE RECHERCHE SERVICES
                        // ==========================================
                        if (_isSearching) ...[
                          TextField(
                            controller: _serviceSearchController,
                            onChanged: _filterServices,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Rechercher un service...',
                              hintStyle: GoogleFonts.inter(fontSize: 14, color: kGrayText),
                              prefixIcon: const Icon(Icons.search, color: kGrayText, size: 20),
                              suffixIcon: _serviceSearchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: kGrayText),
                                      onPressed: () {
                                        _serviceSearchController.clear();
                                        _filterServices('');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: kDarkBlue, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: kDarkBlue, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: kDarkBlue, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${_filteredServices.length} service${_filteredServices.length > 1 ? 's' : ''} trouvé${_filteredServices.length > 1 ? 's' : ''}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: kGrayText,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // ==========================================
                        // LISTE DES SERVICES
                        // ==========================================
                        if (!_isAddingCustom) ...[
                          if (!_isSearching) ...[
                            Text(
                              'MON CATALOGUE DE SERVICES',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kGrayText,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ajustez la quantité puis cliquez sur "Ajouter"',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: kGrayText,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          if (_filteredServices.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                    _isSearching ? 'Aucun service trouvé' : 'Aucun service enregistré',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: kGrayText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isSearching
                                        ? 'Essayez un autre terme de recherche'
                                        : 'Ajoutez des services dans l\'écran "Services"',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: kGrayText,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...List.generate(_filteredServices.length, (index) {
                              final service = _filteredServices[index];
                              final serviceId = service['id'] as String;
                              final name = service['name'] as String;
                              final price = (service['unit_price'] as num).toDouble();
                              final quantity = _quantities[serviceId] ?? 1;
                              final total = price * quantity;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                kDarkBlue.withOpacity(0.15),
                                                kDarkBlue.withOpacity(0.05),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.inventory_2, color: kDarkBlue, size: 22),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${_formatAmount(price)} FCFA / unité',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: kGrayText,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove, size: 18),
                                                onPressed: () => _updateQuantity(serviceId, -1),
                                                padding: const EdgeInsets.all(8),
                                                constraints: const BoxConstraints(),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                                child: Text(
                                                  '$quantity',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add, size: 18),
                                                onPressed: () => _updateQuantity(serviceId, 1),
                                                padding: const EdgeInsets.all(8),
                                                constraints: const BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'Total :',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: kGrayText,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${_formatAmount(total)} FCFA',
                                                style: GoogleFonts.inter(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: kGreen,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton.icon(
                                          onPressed: () => _addServiceToInvoice(service),
                                          icon: const Icon(Icons.add_circle, size: 18),
                                          label: Text(
                                            'Ajouter',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: kDarkBlue,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            elevation: 0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),

          // ==========================================
          // BARRE DE TOTAL (sticky bottom)
          // ==========================================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kDarkBlue, kDarkBlue.withOpacity(0.9)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: kDarkBlue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sous-total',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                    ),
                    Text(
                      '${_formatAmount(widget.invoiceData.subtotal)} FCFA',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TVA (désactivée)',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                    ),
                    Text(
                      '—',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL TTC',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${_formatAmount(widget.invoiceData.totalAmount)} FCFA',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: widget.invoiceData.items.isEmpty
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateInvoiceStep3(invoiceData: widget.invoiceData),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: kDarkBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Suivant · Options',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}