import 'package:fleeting_monitoring_app/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  @override
  void dispose() {
   
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor:Colors.blueAccent,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '17:10',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.signal_cellular_alt, color: Colors.white),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: SizedBox(
                height: 150,
                child: Image.asset('assets/car.jpg', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 10),

            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text('OR', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(height: 20),

                    authProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildSocialButton(
                          context: context,
                          icon: Icons.g_mobiledata,
                          text: 'Continue with Google',
                          color: Colors.redAccent,
                        ),

                    const SizedBox(height: 50),
                    const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: 'By signing up, you agree to our '),
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ', acknowledge our '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(
                            text:
                                ', and confirm that you\'re over 18. We may send promotions...',
                          ),
                        ],
                      ),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required IconData icon,
    required String text,
    Color? color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(icon, color: color ?? Colors.black),
        label: Text(text, style: const TextStyle(color: Colors.black)),
        onPressed: () async {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          final success = await authProvider.signInWithGoogle();

          if (success) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            final error = authProvider.errorMessage ?? 'Google sign-in failed';
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error)));
          }
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
