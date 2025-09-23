import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_repository.dart';

const _kPurpleA = Color(0xFF7C3AED);
const _kPurpleB = Color(0xFF9F67FF);
const _kPurpleC = Color(0xFFE879F9);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
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
            constraints: const BoxConstraints(maxWidth: 980),
            child: Card(
              elevation: 14,
              shadowColor: _kPurpleB.withOpacity(.18),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: SizedBox(
                height: 540,
                child: Row(
                  children: [
                    // IZQUIERDA: FORM
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(36, 36, 36, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Sign Up',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.2,
                              ),
                            ),
                            const SizedBox(height: 26),
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
                                      obscureText: _obscure1,
                                      textInputAction: TextInputAction.next,
                                      decoration: _dec(
                                        context,
                                        'Password',
                                        icon: Icons.lock_rounded,
                                        suffix: IconButton(
                                          onPressed: () => setState(() => _obscure1 = !_obscure1),
                                          icon: Icon(_obscure1
                                              ? Icons.visibility_rounded
                                              : Icons.visibility_off_rounded),
                                        ),
                                      ),
                                      validator: (v) =>
                                          (v != null && v.length >= 6) ? null : 'Mínimo 6 caracteres',
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _confirm,
                                      obscureText: _obscure2,
                                      textInputAction: TextInputAction.done,
                                      decoration: _dec(
                                        context,
                                        'Confirm password',
                                        icon: Icons.lock_outline_rounded,
                                        suffix: IconButton(
                                          onPressed: () => setState(() => _obscure2 = !_obscure2),
                                          icon: Icon(_obscure2
                                              ? Icons.visibility_rounded
                                              : Icons.visibility_off_rounded),
                                        ),
                                      ),
                                      validator: (v) =>
                                          v == _password.text ? null : 'Las contraseñas no coinciden',
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
                                  text: 'SIGN UP',
                                  loading: _loading,
                                  onTap: _loading ? null : () => _submit(auth),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // DERECHA: PANEL BRILLANTE (sin círculos)
                    SizedBox(
                      width: 450,
                      child: _RightPanelShiny(
                        title: 'Welcome!',
                        text: 'Already have an account? Sign in to continue.',
                        ctaText: 'SIGN IN',
                        onTap: () => context.go('/login'),
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
      await auth.signUp(_email.text.trim(), _password.text);
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

/* ===== Reutilizados del login: botón y panel ===== */

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
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_kPurpleA, _kPurpleB, _kPurpleC],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
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
        Align(
          alignment: Alignment.topRight,
          child: Transform.rotate(
            angle: -0.22,
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
