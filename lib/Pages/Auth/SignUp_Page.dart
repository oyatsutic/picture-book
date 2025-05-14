// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:picturebook/Services/getData.dart';
// import 'package:picturebook/globaldata.dart';
import 'Login_Page.dart';
// import 'package:open_mail/open_mail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturebook/providers/auth_provider.dart';

class SignUp_Page extends ConsumerStatefulWidget {
  const SignUp_Page({super.key});

  @override
  ConsumerState<SignUp_Page> createState() => _SignUp_Page();
}

class _SignUp_Page extends ConsumerState<SignUp_Page> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController = TextEditingController();
  bool notvisible = true;
  bool notVisiblePassword = true;
  Icon passwordIcon = const Icon(Icons.visibility);

  void passwordVisibility() {
    if (notVisiblePassword) {
      passwordIcon = const Icon(Icons.visibility);
    } else {
      passwordIcon = const Icon(Icons.visibility_off);
    }
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != passwordConfirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Passwords do not match'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(emailController.text.toString().trim())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'Please enter a valid email address.',
          textAlign: TextAlign.center,
        ),
        backgroundColor: Color.fromARGB(255, 39, 38, 37),
      ));
      return;
    }

    try {
      await ref.read(authStateProvider.notifier).register(
            emailController.text.toString().trim(),
            passwordController.text.toString().trim(),
            nameController.text.toString().trim(),
          );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Login_Page()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Stack(
            children: [
              Positioned(
                top: MediaQuery.of(context).size.width * 0.3,
                child: Opacity(
                  opacity: 0.5,
                  child: Image.asset(
                    'assets/images/login.png',
                    width: MediaQuery.of(context).size.width,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
              Column(
                children: [
                  const SizedBox(height: 80),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10),
                    child: Column(
                      children: [
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                decoration: const InputDecoration(
                                  icon: Icon(
                                    Icons.alternate_email_outlined,
                                    color: Colors.grey,
                                  ),
                                  labelText: "email",
                                ),
                                controller: emailController,
                              ),
                              TextFormField(
                                decoration: const InputDecoration(
                                  icon: Icon(
                                    Icons.account_circle,
                                    color: Colors.grey,
                                  ),
                                  labelText: "name",
                                ),
                                controller: nameController,
                              ),
                              TextFormField(
                                style: TextStyle(letterSpacing: notvisible ? 2 : 1),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Password cannot be empty";
                                  } else if (value.length <= 5) {
                                    return "Password must be more than 6 characters";
                                  }
                                  return null;
                                },
                                obscureText: notvisible,
                                decoration: InputDecoration(
                                  icon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: Colors.grey,
                                  ),
                                  labelText: "password",
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        notvisible = !notvisible;
                                        notVisiblePassword = !notVisiblePassword;
                                        passwordVisibility();
                                      });
                                    },
                                    icon: passwordIcon,
                                  ),
                                ),
                                controller: passwordController,
                              ),
                              TextFormField(
                                style: TextStyle(letterSpacing: notvisible ? 2 : 1),
                                obscureText: notvisible,
                                decoration: InputDecoration(
                                  icon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: Colors.grey,
                                  ),
                                  labelText: "password confirm",
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        notvisible = !notvisible;
                                        notVisiblePassword = !notVisiblePassword;
                                        passwordVisibility();
                                      });
                                    },
                                    icon: passwordIcon,
                                  ),
                                ),
                                controller: passwordConfirmController,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 13),
                        ElevatedButton(
                          onPressed: authState.isLoading ? null : register,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                            backgroundColor: const Color.fromARGB(255, 247, 250, 249),
                            foregroundColor: const Color.fromARGB(255, 0, 168, 154),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Center(
                            child: authState.isLoading
                                ? const CircularProgressIndicator()
                                : const Text(
                                    "register",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Join us before?",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const Login_Page()),
                                );
                              },
                              child: const Text(
                                "login",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
