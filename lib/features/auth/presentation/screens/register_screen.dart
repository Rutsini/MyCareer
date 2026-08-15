import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../application/auth_controller.dart';
import '../widgets/auth_card.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).signUp(
          name: _name.text,
          email: _email.text,
          password: _password.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final error = state.hasError ? state.error as AppException? : null;
    return AuthCard(
      title: 'Creá tu cuenta',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
                controller: _name,
                enabled: !state.isLoading,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: Validators.requiredName),
            const SizedBox(height: 16),
            TextFormField(
                controller: _email,
                enabled: !state.isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: Validators.email),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              enabled: !state.isLoading,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                ),
              ),
              validator: Validators.password,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmation,
              enabled: !state.isLoading,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration:
                  const InputDecoration(labelText: 'Confirmar contraseña'),
              validator: (value) =>
                  Validators.passwordConfirmation(value, _password.text),
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              Text(error.message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: state.isLoading ? null : _submit,
              child: state.isLoading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Crear cuenta'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed:
                  state.isLoading ? null : () => context.go(AppRoutes.login),
              child: const Text('Ya tengo una cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
