import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_step2_screen.dart';

const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kOrange = Color(0xFFF59E0B);
const Color kGrayText = Color(0xFF6B7280);
const Color kLightBlue = Color(0xFFF0F9FF);
const Color kInputBorder = Color(0xFFD1D5DB);

class VerifyOtpScreen extends StatefulWidget {
  final String phone;
  final String verificationId;
  final String firstName;
  final String lastName;
  final String password;

  const VerifyOtpScreen({
    super.key,
    required this.phone,
    required this.verificationId,
    required this.firstName,
    required this.lastName,
    required this.password,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final List<TextEditingController> _codeControllers = List.generate(6, (i) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (i) => FocusNode());
  bool _isLoading = false;
  String? _errorMessage;
  int _timeLeft = 60;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_timeLeft > 0 && mounted) {
        setState(() {
          _timeLeft--;
        });
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    for (var c in _codeControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final code = _codeControllers.map((c) => c.text).join();
    
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Veuillez entrer les 6 chiffres';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 🔥 VÉRIFIER LE CODE AVEC FIREBASE
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: code,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        print('✅ Téléphone vérifié avec succès !');
        print('🆔 Firebase UID : ${user.uid}');

        // 🔥 CRÉER LE COMPTE DANS SUPABASE
        try {
          // Créer l'utilisateur dans Supabase Auth avec email/password
          final email = '${user.uid}@facturia.local'; // Email fictif basé sur l'UID Firebase
          
          final authResponse = await Supabase.instance.client.auth.signUp(
            email: email,
            password: widget.password,
          );

          if (authResponse.user != null) {
            // Mettre à jour le profil avec les infos
            await Supabase.instance.client.from('profiles').update({
              'first_name': widget.firstName,
              'last_name': widget.lastName,
              'phone': widget.phone,
            }).eq('id', authResponse.user!.id);

            print('✅ Compte Supabase créé !');

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => RegisterStep2Screen(userId: authResponse.user!.id),
                ),
              );
            }
          }
        } catch (supabaseError) {
          print('⚠️ Erreur Supabase : $supabaseError');
          // Si l'utilisateur existe déjà, on continue quand même
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RegisterStep2Screen(userId: user.uid),
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Code invalide. Réessayez.';
      });
      print('❌ Erreur OTP : $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    try {
      // 🔥 RENVOYER LE CODE AVEC FIREBASE
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phone,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Code renvoyé !')),
          );
          setState(() {
            _timeLeft = 60;
          });
          _startTimer();
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // HEADER BLEU
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 50, 24, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Vérification 📱',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Un code a été envoyé au\n${widget.phone}',
                  style: GoogleFonts.inter(fontSize: 15, color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),

          // CONTENU
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Icon(Icons.sms, size: 60, color: kDarkBlue),
                    const SizedBox(height: 24),
                    Text(
                      'Entrez le code à 6 chiffres',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: kDarkBlue),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'envoyé par SMS',
                      style: GoogleFonts.inter(fontSize: 14, color: kGrayText),
                    ),
                    const SizedBox(height: 32),

                    // Message d'erreur
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.inter(fontSize: 13, color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Champs pour entrer le code
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 45,
                          child: TextField(
                            controller: _codeControllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: kLightBlue,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
                            onChanged: (value) {
                              if (value.isNotEmpty && index < 5) {
                                FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                              } else if (value.isEmpty && index > 0) {
                                FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),

                    // Bouton Vérifier
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kDarkBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Vérifier',
                                style: GoogleFonts.inter(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Renvoyer le code
                    TextButton(
                      onPressed: _timeLeft > 0 ? null : _resendCode,
                      child: Text(
                        _timeLeft > 0
                            ? 'Renvoyer le code dans ${_timeLeft}s'
                            : 'Renvoyer le code',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: _timeLeft > 0 ? kGrayText : kDarkBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}