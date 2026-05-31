import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'home_screen.dart'; 
// import 'seller_main_screen.dart'; // No longer needed as we go to Home -> Profile

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Logic Variables
  bool isLogin = true; 
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Password Validation State
  bool _hasLetter = false;
  bool _hasNumber = false;
  bool _hasSpecial = false;
  bool _hasMinLength = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    
    // --- 1. AUTO-LOGIN CHECK ---
    // Check if user is already logged in when screen opens
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Use addPostFrameCallback to navigate after the widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen())
        );
      });
    }

    // Listen to password changes to update the checklist
    _passwordController.addListener(() {
      final text = _passwordController.text;
      setState(() {
        _hasLetter = text.contains(RegExp(r'[a-zA-Z]'));
        _hasNumber = text.contains(RegExp(r'[0-9]'));
        _hasSpecial = text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
        _hasMinLength = text.length >= 8;
      });
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitAuthForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (isLogin) {
        // --- LOGIN LOGIC ---
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        // --- 2. UNIFIED NAVIGATION ---
        // Send everyone to Home. Seller will find their dashboard in Profile Tab.
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen())
          );
        }

      } else {
        // --- SIGN UP LOGIC ---
        
        // 1. Check Password Strength
        if (!(_hasLetter && _hasNumber && _hasSpecial && _hasMinLength)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please meet all password requirements."))
          );
          setState(() => _isLoading = false);
          return;
        }

        // 2. Create User in Auth
        UserCredential userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        // 3. Update Auth Display Name
        String fullName = "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}";
        await userCred.user?.updateDisplayName(fullName);

        // 4. Save to Firestore
        await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'fullName': fullName,
          'email': _emailController.text.trim(),
          'phone': '', 
          'role': 'buyer',
          'coins': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 5. Navigate to Home
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen())
          );
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(isLogin ? "Welcome back!" : "Profile Completed!"))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper: Update password strength state
  void _updatePasswordStrength(String value) {
    setState(() {
      _hasLetter = value.contains(RegExp(r'[a-zA-Z]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));
      _hasSpecial = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _hasMinLength = value.length >= 8;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white, 
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0.85, 0.03),
                end: Alignment(0.20, 1.00),
                colors: [Color(0xFF335D61), Color(0xFF6FB2A6)],
              ),
            ),
            child: Stack(
              children: [
                // Background Pattern
                Positioned(
                  left: -69,
                  top: 100,
                  child: Opacity(
                    opacity: 0.15,
                    child: Image.asset("assets/LoginLogo.png", width: 514, height: 506, fit: BoxFit.cover, errorBuilder: (c,e,s)=>const SizedBox()),
                  ),
                ),

                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          
                          // Logo
                          Image.asset(
                            "assets/LogoSplash.png", 
                            width: 127, 
                            height: 34,
                            errorBuilder: (c,e,s) => const Text("SKELVA", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          ),

                          const SizedBox(height: 30),

                          // MAIN WHITE CARD
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                
                                // Toggle Switch (Login / Sign Up)
                                Container(
                                  height: 40,
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Row(
                                    children: [
                                      _buildTab("Log In", true),
                                      _buildTab("Sign Up", false),
                                    ],
                                  ),
                                ),

                                // Header Text
                                Center(
                                  child: Text(
                                    isLogin ? "Welcome Back" : "Complete your info",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF335D61),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // --- SIGN UP FIELDS ---
                                if (!isLogin) ...[
                                  _buildLabel("First Name"),
                                  _buildTextField(controller: _firstNameController, hint: "Ahmad"),
                                  const SizedBox(height: 16),

                                  _buildLabel("Last Name"),
                                  _buildTextField(controller: _lastNameController, hint: "Albabyabanabanu"),
                                  const SizedBox(height: 16),
                                ],

                                // --- COMMON FIELDS ---
                                _buildLabel("Email Address"),
                                _buildTextField(
                                  controller: _emailController, 
                                  hint: "ahmadalbab@gmail.com", 
                                  inputType: TextInputType.emailAddress
                                ),
                                const SizedBox(height: 16),

                                // --- PASSWORD FIELD ---
                                _buildLabel("Password"),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  onChanged: (value) => _updatePasswordStrength(value), 
                                  decoration: InputDecoration(
                                    hintText: "••••••••",
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF335D61), width: 1.5)),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                ),

                                // --- PASSWORD CHECKLIST ---
                                if (!isLogin) ...[
                                  const SizedBox(height: 16),
                                  _buildCheckItem("One letter (a-z)", _hasLetter),
                                  _buildCheckItem("One number (0-9)", _hasNumber),
                                  _buildCheckItem("One special character", _hasSpecial),
                                  _buildCheckItem("8 characters minimum", _hasMinLength),
                                  const SizedBox(height: 20),
                                  const Text(
                                    "By selecting Next, i agree to Skelva terms of service, Payment Terms of Service & Privacy Policy.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ] else ...[
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {},
                                      child: const Text("Forget Password?", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    ),
                                  )
                                ],

                                const SizedBox(height: 24),

                                // --- BUTTON ---
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _submitAuthForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEF963B), 
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                      elevation: 0,
                                    ),
                                    child: _isLoading 
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : Text(isLogin ? "Log In" : "Next", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ),

                                // Social Login
                                if (isLogin) ...[
                                  const SizedBox(height: 20),
                                  const Center(child: Text("Or", style: TextStyle(fontSize: 12, color: Colors.grey))),
                                  const SizedBox(height: 20),
                                  Center(
                                    child: Image.asset("assets/google1.png", width: 40, height: 40, errorBuilder: (c,e,s)=>const Icon(Icons.g_mobiledata, size: 40)),
                                  ),
                                ]
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF335D61))),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, TextInputType? inputType}) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF335D61), width: 1.5)),
      ),
    );
  }

  Widget _buildCheckItem(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(isValid ? Icons.check_circle : Icons.check_circle_outline, color: isValid ? const Color(0xFF2E7D32) : Colors.grey, size: 16),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 11, color: isValid ? const Color(0xFF2E7D32) : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isLoginTab) {
    bool isSelected = (isLogin == isLoginTab);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isLogin = isLoginTab),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(color: isSelected ? const Color(0xFF183742) : Colors.transparent, borderRadius: BorderRadius.circular(100)),
          child: Text(title, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF183742), fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }
}