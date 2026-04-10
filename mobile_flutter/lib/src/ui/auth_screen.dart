import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../session/app_session.dart';
import 'common.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  bool _registerMode = false;
  bool _isSubmitting = false;
  String _error = "";

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = "";
      _isSubmitting = true;
    });

    final session = SessionScope.of(context);
    try {
      if (_registerMode) {
        final name = _registerNameController.text.trim();
        final email = _registerEmailController.text.trim();
        final password = _registerPasswordController.text;

        if (name.isEmpty || email.isEmpty || password.isEmpty) {
          throw const ApiException("Complete every field before continuing.");
        }
        if (password.length < 8) {
          throw const ApiException("Password must be at least 8 characters.");
        }

        await session.register(
          name: name,
          email: email,
          password: password,
          role: UserRole.climber,
        );
      } else {
        final email = _loginEmailController.text.trim();
        final password = _loginPasswordController.text;

        if (email.isEmpty || password.isEmpty) {
          throw const ApiException("Email and password are required.");
        }

        await session.login(email: email, password: password);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = "Unexpected error. Try again.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = _registerMode
        ? "Build a role-based account."
        : "Mobile climbing intel synced to Java APIs.";
    final helper = _registerMode
        ? "Registration still goes through Spring Boot, JWT, and MySQL. Flutter only replaces the mobile UI layer."
        : "This Flutter client talks to the same backend as the current React app, with role-aware mobile navigation for climbers and coaches.";

    return BetaUpScaffold(
      title: "BetaUp",
      subtitle: _registerMode ? "Create account" : "Sign in",
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel("BetaUp Mobile"),
                    const SizedBox(height: 14),
                    Text(headline, style: theme.textTheme.displaySmall),
                    const SizedBox(height: 14),
                    Text(helper, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 20),
                    const Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        StatusChip(label: "JWT auth"),
                        StatusChip(label: "Role routing", color: Color(0xFF5ED9A6)),
                        StatusChip(label: "Java backend", color: Color(0xFFFFB26D)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text("Sign in"),
                            selected: !_registerMode,
                            onSelected: (_) {
                              setState(() {
                                _registerMode = false;
                                _error = "";
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text("Register"),
                            selected: _registerMode,
                            onSelected: (_) {
                              setState(() {
                                _registerMode = true;
                                _error = "";
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_registerMode) ...[
                      TextField(
                        controller: _registerNameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: "Name",
                          hintText: "Alex Summit",
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _registerEmailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          hintText: "alex@betaup.local",
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _registerPasswordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: "Password",
                          hintText: "At least 8 characters",
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: _loginEmailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          hintText: "coach@betaup.local",
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _loginPasswordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: "Password",
                          hintText: "Enter your password",
                        ),
                      ),
                    ],
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0x33FF7B7B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0x55FF7B7B)),
                        ),
                        child: Text(_error, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: Text(
                        _isSubmitting
                            ? (_registerMode ? "Creating account..." : "Signing in...")
                            : (_registerMode ? "Create account" : "Sign in"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
