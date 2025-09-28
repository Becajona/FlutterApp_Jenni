import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_repository.dart';

const _kPurpleA = Color(0xFF7C3AED); // electric purple
const _kPurpleB = Color(0xFF9F67FF); // bright violet
const _kPurpleC = Color(0xFFE879F9); // fuchsia highlight

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  InputDecoration _dec(BuildContext context, String label,
      {IconData? icon, Widget? suffix}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: cs.surfaceVariant.withOpacity(.35),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: _kPurpleB, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final auth = context.read<AuthRepository>();
    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget loginForm() => Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Sign In',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.2,
              ),
            ),
            const SizedBox(height: 18),
            const _SocialRow(),
            const SizedBox(height: 10),
            Text(
              'or use your email password',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(.65),
              ),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _dec(context, 'Email',
                          icon: Icons.alternate_email_rounded),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Ingresa tu email';
                        final ok = RegExp(r'^\S+@\S+\.\S+$').hasMatch(v.trim());
                        return ok ? null : 'Formato no válido';
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      decoration: _dec(
                        context,
                        'Password',
                        icon: Icons.lock_rounded,
                        suffix: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
                      onFieldSubmitted: (_) => _submit(auth),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: _GradientBtn(
                  text: 'SIGN IN',
                  loading: _loading,
                  onTap: _loading ? null : () => _submit(auth),
                ),
              ),
            ),
            // Mostrar botón SIGN UP en móvil
            if (isMobile) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/register'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _kPurpleA.withOpacity(.9), width: 1.3),
                    foregroundColor: _kPurpleA,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: _kPurpleA.withOpacity(.06),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .6),
                  ),
                  child: const Text('SIGN UP'),
                ),
              ),
            ],
          ],
        );

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.surface, cs.surface, _kPurpleA.withOpacity(.05)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 980,
            ),
            child: Card(
              elevation: 14,
              shadowColor: _kPurpleB.withOpacity(.18),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: isMobile
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.9,
                        child: loginForm(),
                      ),
                    )
                  : SizedBox(
                      height: 540,
                      child: Row(
                        children: [
                          // IZQUIERDA: FORM
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(36, 36, 36, 28),
                              child: loginForm(),
                            ),
                          ),
                          // DERECHA: PANEL MORADO BRILLANTE (sin círculos)
                          SizedBox(
                            width: 450,
                            child: _RightPanelShiny(
                              title: 'Hello, Friend!',
                              text:
                                  'Register with your personal details to use all of app features.',
                              ctaText: 'SIGN UP',
                              onTap: () => context.go('/register'),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AuthRepository auth) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await auth.signIn(_email.text.trim(), _password.text);
    } catch (e) {
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: cs.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

/* ====== Helpers visuales ====== */

class _SocialRow extends StatelessWidget {
  const _SocialRow();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = context.read<AuthRepository>();

    Future<void> _handleGoogleSignIn() async {
      try {
        await auth.signInWithGoogle();
        // El navegador se maneja automáticamente por el estado de autenticación
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }

    Widget btn(IconData icon, {VoidCallback? onTap}) => GestureDetector(
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 18),
          ),
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        btn(Icons.g_mobiledata_rounded, onTap: _handleGoogleSignIn),
        const SizedBox(width: 12),
        btn(Icons.facebook_rounded),
        const SizedBox(width: 12),
        btn(Icons.apple_rounded),
        const SizedBox(width: 12),
        btn(Icons.link_rounded),
      ],
    );
  }
}

/// Botón con gradiente morado brillante
class _GradientBtn extends StatelessWidget {
  const _GradientBtn({required this.text, this.onTap, this.loading = false});
  final String text;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: disabled
            ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade300])
            : const LinearGradient(
                colors: [_kPurpleA, _kPurpleB, _kPurpleC],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: _kPurpleB.withOpacity(.35),
                  blurRadius: 24,
                  spreadRadius: 1,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: .2),
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(text),
      ),
    );
  }
}

/// Panel morado limpio/brillante (sin círculos invasivos)
class _RightPanelShiny extends StatelessWidget {
  const _RightPanelShiny({
    required this.title,
    required this.text,
    required this.ctaText,
    required this.onTap,
  });

  final String title;
  final String text;
  final String ctaText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradiente principal
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_kPurpleA, _kPurpleB, _kPurpleC],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Highlight radial (brillo)
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.white.withOpacity(.18), Colors.transparent],
                center: const Alignment(-.2, -.8),
                radius: .9,
              ),
            ),
          ),
        ),
        // Banda diagonal translúcida
        Align(
          alignment: Alignment.topRight,
          child: Transform.rotate(
            angle: -0.22, // ~ -12.5°
            child: Container(
              width: 260,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.09),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
        // Contenido
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 44, 40, 32),
          child: DefaultTextStyle(
            style: theme.textTheme.bodyMedium!.copyWith(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(.96),
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(.9), width: 1.3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: Colors.white.withOpacity(.06),
                    ),
                    child: Text(
                      ctaText,
                      style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
