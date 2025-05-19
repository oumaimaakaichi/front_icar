import 'package:car_mobile/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
class Atelier {
  final int id;
  final String nomCommercial;

  Atelier({required this.id, required this.nomCommercial});

  factory Atelier.fromJson(Map<String, dynamic> json) {
    return Atelier(
      id: json['id'],
      nomCommercial: json['nom_commercial'],
    );
  }
}
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _specialiteController = TextEditingController();
  final _qualificationsController = TextEditingController();
  final _anneeExperienceController = TextEditingController();
  final _responsableDirectController = TextEditingController();
  final _adresseController = TextEditingController();
  final _atelierIdController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  List<Atelier> _ateliers = [];
  int? _selectedAtelierId;

  @override
  void initState() {
    super.initState();
    _fetchAteliers();
  }

  Future<void> _fetchAteliers() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.17:8000/api/ateliers'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _ateliers = data.map((atelier) => Atelier.fromJson(atelier)).toList();
        });
      } else {
        throw Exception('Failed to load ateliers');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading ateliers: ${e.toString()}')),
      );
    }
  }
  Future<http.Response> submitForm() async {
    final url = Uri.parse('http://localhost:8000/api/users/storeM');
    return await http.post(
      url,
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        'nom': _nomController.text,
        'prenom': _prenomController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'specialite': _specialiteController.text,
        'qualifications': _qualificationsController.text,
        'annee_experience': _anneeExperienceController.text,
        'responsable_direct': _responsableDirectController.text,
        'adresse': _adresseController.text,
        'atelier_id': _atelierIdController.text,
        'role': 'technicien',
      },
    );
  }

  void _nextPage() {
    if (_formKey.currentState!.validate()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage = 1);
    }
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage = 0);
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await submitForm();
        final decoded = jsonDecode(response.body);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.statusCode == 200
                  ? "Account created successfully"
                  : "Error: ${decoded['message'] ?? decoded['errors'] ?? 'Creation failed'}",
            ),
            backgroundColor: response.statusCode == 200 ? Colors.green : Colors.red,
          ),
        );

        if (response.statusCode == 200) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentPage + 1) / 2,
              backgroundColor: Colors.grey[300],
              color: Colors.blueGrey[800],
              minHeight: 4,
            ),

            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildPersonalInfoPage(),
                    _buildProfessionalInfoPage(),
                  ],
                ),
              ),
            ),

            // Navigation Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  // Next as text link (only on first page)
                  if (_currentPage == 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: GestureDetector(
                        onTap: _nextPage,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "NEXT",
                              style: TextStyle(
                                color: Colors.blueGrey[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              size: 20,
                              color: Colors.blueGrey[800],
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Back and Sign Up buttons (on second page)
                  if (_currentPage == 1)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _prevPage,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.blueGrey[800]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("BACK",
                                style: TextStyle(color: Colors.blueGrey)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey[800],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Text(
                              "SIGN UP",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  // "Already have an account?" link
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 0),
          Center(
            child: Image.asset('assets/images/13.png', height: 160),
          ),
          const SizedBox(height: 0),
          const Text(
            "   Personal Information",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "         Fill in your basic information to get started",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 20),
          _buildTextField(_nomController, "Last Name", Icons.person),
          const SizedBox(height: 16),
          _buildTextField(_prenomController, "First Name", Icons.person_outline),
          const SizedBox(height: 16),
          _buildTextField(_phoneController, "Phone Number", Icons.phone,
              type: TextInputType.phone),
          const SizedBox(height: 16),
          _buildTextField(_emailController, "Email", Icons.email,
              type: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _buildPasswordField(),
          const SizedBox(height: 16),
          _buildTextField(_adresseController, "Address", Icons.location_on),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 0),
          Center(
            child: Image.asset('assets/images/13.png', height: 180),
          ),
          const SizedBox(height: 0),
          const Text(
            "  Professional Information",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "         Complete your professional information",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 20),
          InputDecorator(
            decoration: InputDecoration(

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blueGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              filled: true,
              fillColor: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedAtelierId,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                iconSize: 24,
                elevation: 16,
                style: TextStyle(color: Colors.blueGrey[800]),
                hint: const Text("Select a workshop"),
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedAtelierId = newValue;
                    _atelierIdController.text = newValue?.toString() ?? ''; // Ajoutez cette ligne
                  });
                },
                items: _ateliers.map<DropdownMenuItem<int>>((Atelier atelier) {
                  return DropdownMenuItem<int>(
                    value: atelier.id,
                    child: Text(atelier.nomCommercial),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(_specialiteController, "Specialty", Icons.work,
              required: false),
          const SizedBox(height: 16),
          _buildTextField(_qualificationsController, "Qualifications", Icons.school,
              required: false),
          const SizedBox(height: 16),
          _buildTextField(_anneeExperienceController, "Years of experience",
              Icons.access_time, type: TextInputType.number, required: false),
          const SizedBox(height: 16),
          _buildTextField(_responsableDirectController, "Direct supervisor",
              Icons.supervisor_account, required: false),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool required = true,
        TextInputType type = TextInputType.text,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // 👈 Radius ici
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // 👈 Radius ici aussi
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // 👈 Et ici
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
        prefixIcon: Icon(icon, color: Colors.blueGrey[800]),
        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (!required) return null;
        if (value == null || value.isEmpty) return "This field is required";
        if (label.contains("Email") && !value.contains('@')) {
          return "Invalid email";
        }
        if (label.contains("Phone") && value.length < 8) {
          return "Invalid phone number";
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: "Password",
        prefixIcon: Icon(Icons.lock, color: Colors.blueGrey[800]),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // 👈 Radius ici
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // 👈 Radius ici aussi
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // 👈 Et ici
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "This field is required";
        if (value.length < 6) return "Minimum 6 characters";
        return null;
      },
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _specialiteController.dispose();
    _qualificationsController.dispose();
    _anneeExperienceController.dispose();
    _responsableDirectController.dispose();
    _adresseController.dispose();
    _atelierIdController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}