// lib/src/login/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthRepository>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // gris claro del mock
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

                      // Logo cuadrado
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
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 18),

                      // Títulos
                      Text(
                        '¡Únete a Ahorratón!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Crea tu cuenta gratis',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // FORM
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            
                            const SizedBox(height: 12),
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
                              obscure: _obscure1,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Ingresa una contraseña';
                                }
                                if (v.length < 6) {
                                  return 'Mínimo 6 caracteres';
                                }
                                return null;
                              },
                              suffix: IconButton(
                                icon: Icon(
                                  _obscure1 ? Icons.visibility : Icons.visibility_off,
                                  color: const Color(0xFF9CA3AF),
                                ),
                                onPressed: () => setState(() => _obscure1 = !_obscure1),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _input(
                              controller: _confirm,
                              label: 'Confirmar contraseña',
                              icon: Icons.lock_outline,
                              obscure: _obscure2,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Confirma tu contraseña';
                                }
                                if (v != _password.text) {
                                  return 'Las contraseñas no coinciden';
                                }
                                return null;
                              },
                              suffix: IconButton(
                                icon: Icon(
                                  _obscure2 ? Icons.visibility : Icons.visibility_off,
                                  color: const Color(0xFF9CA3AF),
                                ),
                                onPressed: () => setState(() => _obscure2 = !_obscure2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Botón ámbar grande con sombra
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE3A72F).withOpacity(.45),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : () => _submit(auth),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE3A72F),
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
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Crear Cuenta'),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Enlace a login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '¿Ya tienes cuenta? ',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                          ),
                          InkWell(
                            onTap: () => context.go('/login'),
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                              child: Text(
                                'Iniciar Sesión',
                                style: TextStyle(
                                  color: Color(0xFF1976D2),
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

  // ---------- INPUT HELPER (estética de tarjeta gris con borde redondeado) ----------
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
        hintStyle: const TextStyle(color: Color(0xFF6B7280)),
        prefixIcon: Icon(icon, color: const Color(0xFF6B7280)),
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
      // Ajusta al nombre real de tu método si difiere:
      await auth.signUp(_email.text.trim(), _password.text);

      // (Opcional) guardar displayName si tu backend/Firebase lo admite:
      // await auth.updateDisplayName(_name.text.trim());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo crear la cuenta: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
