import 'package:car_mobile/login.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SignUpClientPage extends StatefulWidget {
  @override
  _SignUpClientPageState createState() => _SignUpClientPageState();
}

class _SignUpClientPageState extends State<SignUpClientPage> {
  final _formKey = GlobalKey<FormState>();
  final Dio dio = Dio(BaseOptions(
    baseUrl: 'http://10.172.211.216:8000/api',
    headers: {'Accept': 'application/json'},
  ));

  String nom = '';
  String prenom = '';
  String email = '';
  String phone = '';
  String adresse = '';
  String password = '';
  String confirmPassword = '';
  String code = '';

  bool codeSent = false;
  bool loading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  Future<void> sendCode() async {
    if (email.isEmpty) {
      Fluttertoast.showToast(msg: 'Veuillez entrer votre email');
      return;
    }

    try {
      setState(() => loading = true);
      final response = await dio.post('/send-code', data: {'email': email});

      final message = response.data is Map
          ? response.data['message'] ?? 'Code envoyé avec succès'
          : 'Code envoyé avec succès';

      Fluttertoast.showToast(msg: message);
      setState(() => codeSent = true);
    } catch (e) {
      String errorMessage = 'Erreur lors de l\'envoi du code';
      if (e is DioException) {
        errorMessage = e.response?.data is Map
            ? e.response?.data['message'] ?? e.response?.data['error'] ?? e.message ?? errorMessage
            : e.message ?? errorMessage;
      }
      Fluttertoast.showToast(msg: errorMessage);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> registerClient() async {
    if (!_formKey.currentState!.validate()) return;

    if (password != confirmPassword) {
      Fluttertoast.showToast(msg: 'Les mots de passe ne correspondent pas');
      return;
    }

    if (code.isEmpty) {
      Fluttertoast.showToast(msg: 'Veuillez entrer le code de vérification');
      return;
    }

    try {
      setState(() => loading = true);
      final response = await dio.post('/register-client', data: {
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'phone': phone,
        'adresse': adresse,
        'password': password,
        'password_confirmation': confirmPassword,
        'code': code,
      });

      final message = response.data is Map
          ? response.data['message'] ?? 'Compte créé avec succès!'
          : 'Compte créé avec succès!';

      Fluttertoast.showToast(msg: message);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      String errorMessage = 'Erreur lors de la création du compte';
      if (e is DioException) {
        if (e.response?.statusCode == 422) {
          final errors = e.response?.data is Map ? e.response?.data['errors'] : null;
          if (errors != null && errors is Map) {
            errorMessage = errors.values.first.first ?? errorMessage;
          }
        } else {
          errorMessage = e.response?.data is Map
              ? e.response?.data['error'] ?? e.response?.data['message'] ?? e.message ?? errorMessage
              : e.message ?? errorMessage;
        }
      }
      Fluttertoast.showToast(msg: errorMessage);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        centerTitle: true,

        backgroundColor: Colors.transparent
        ,
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Image d'en-tête
                Image.asset(
                  'assets/images/13.png', // Remplacez par votre propre image
                  height: 210,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 0),

                buildInput('Nom',
                  icon: Icons.person_outline,
                  onChanged: (v) => nom = v,
                ),

                buildInput('Prénom',
                  icon: Icons.person_outline,
                  onChanged: (v) => prenom = v,
                ),

                buildInput('Email',
                  icon: Icons.email_outlined,
                  onChanged: (v) => email = v,
                  keyboard: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ce champ est requis';
                    if (!v.contains('@')) return 'Email invalide';
                    return null;
                  },
                ),

                buildInput('Téléphone',
                  icon: Icons.phone_outlined,
                  onChanged: (v) => phone = v,
                  keyboard: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ce champ est requis';
                    if (v.length < 8) return 'Numéro trop court';
                    return null;
                  },
                ),

                buildInput('Adresse',
                  icon: Icons.home_outlined,
                  onChanged: (v) => adresse = v,
                ),

                buildInput('Mot de passe',
                  icon: Icons.lock_outline,
                  onChanged: (v) => password = v,
                  obscure: !_passwordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ce champ est requis';
                    if (v.length < 6) return 'Minimum 6 caractères';
                    return null;
                  },
                ),

                buildInput('Confirmer mot de passe',
                  icon: Icons.lock_outline,
                  onChanged: (v) => confirmPassword = v,
                  obscure: !_confirmPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _confirmPasswordVisible = !_confirmPasswordVisible;
                      });
                    },
                  ),
                  validator: (v) {
                    if (v != password) return 'Les mots de passe ne correspondent pas';
                    return null;
                  },
                ),

                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 3.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? ",
                          style: TextStyle(color: Colors.grey)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        child: Text(
                          "Sign in",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: loading ? null : sendCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: loading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_outlined, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Envoyer le code de vérification',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],

                  ),

                ),

                if (codeSent) ...[
                  const SizedBox(height: 20),

                  buildInput('Code de vérification',
                    icon: Icons.verified_user_outlined,
                    onChanged: (v) => code = v,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Code requis';
                      if (v.length != 4) return 'Code doit avoir 4 chiffres';
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: loading ? null : registerClient,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: loading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Créer le compte',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInput(
      String label, {
        required IconData icon,
        required Function(String) onChanged,
        TextInputType keyboard = TextInputType.text,
        bool obscure = false,
        Widget? suffixIcon,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue.shade400),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        ),
        onChanged: onChanged,
        validator: validator ??
                (value) => (value == null || value.isEmpty) ? 'Ce champ est requis' : null,
      ),
    );
  }
}