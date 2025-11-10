// lib/src/login/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthRepository>();
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // gris muy claro como en el mock
      body: SafeArea(
        child: LayoutBuilder(
          builder: (_, c) {
            final maxW = c.maxWidth < 480 ? c.maxWidth : 420.0;
            final pad = c.maxWidth < 380 ? 16.0 : 24.0;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: pad, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),

                      // Logo cuadrado arriba
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/logo.png', // tu icono de Ahorratón
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Título y subtítulo
                      Text(
                        '¡Bienvenido de nuevo!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: w < 380 ? 22 : 26,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1F2937),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Inicia sesión para continuar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // FORM
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _input(
                              controller: _email,
                              label: 'Correo electrónico',
                              icon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Ingresa tu correo';
                                }
                                final ok = RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w+$')
                                    .hasMatch(v.trim());
                                return ok ? null : 'Correo no válido';
                              },
                            ),
                            const SizedBox(height: 12),
                            _input(
                              controller: _password,
                              label: 'Contraseña',
                              icon: Icons.lock_outline,
                              obscure: _obscure,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Ingresa tu contraseña';
                                }
                                if (v.length < 6) {
                                  return 'Mínimo 6 caracteres';
                                }
                                return null;
                              },
                              suffix: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: const Color(0xFF9CA3AF),
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Botón ámbar grande "Iniciar Sesión"
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : () => _submit(auth),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE3A72F), // ámbar
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Iniciar Sesión'),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Divider "O inicia sesión con"
                      Row(
                        children: const [
                          Expanded(
                            child: Divider(color: Color(0xFFE5E7EB), thickness: 1),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'O inicia sesión con',
                              style: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: Color(0xFFE5E7EB), thickness: 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Botón Google (borde gris + icono a la izquierda)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _loading ? null : () => _handleGoogle(auth),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            foregroundColor: const Color(0xFF111827),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/google.png',
                                height: 22,
                                width: 22,
                              ),
                              const SizedBox(width: 10),
                              const Text('Continuar con Google'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Enlace registro
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '¿No tienes cuenta? ',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                          ),
                          InkWell(
                            onTap: () => context.go('/register'),
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                              child: Text(
                                'Regístrate',
                                style: TextStyle(
                                  color: Color(0xFF1976D2), // azul link
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------- HELPERS ----------

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF)),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
      ),
    );
  }

  Future<void> _submit(AuthRepository auth) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await auth.signIn(_email.text.trim(), _password.text);
      // La navegación la resuelves por estado de sesión o router guard.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo iniciar sesión: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogle(AuthRepository auth) async {
    setState(() => _loading = true);
    try {
      await auth.signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error con Google: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
