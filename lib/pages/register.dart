import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:test_notification_app/core/form_validators.dart';
import 'package:test_notification_app/services/services.dart';

// register page
class Register extends HookWidget {
  const Register({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final firstNameController = useTextEditingController();
    final lastNameController = useTextEditingController();
    final emailController = useTextEditingController();
    final genderController = useTextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              SizedBox(height: 20),
              TextFormField(
                controller: firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  hintText: 'Enter your name',
                ),
                keyboardType: TextInputType.name,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))
                ],
                validator: FormValidators.nameValidator,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  hintText: 'Enter your last name',
                ),
                keyboardType: TextInputType.name,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))
                ],
                validator: FormValidators.nameValidator,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: FormValidators.emailValidator,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Gender',
                  hintText: 'Select your gender',
                ),
                validator: FormValidators.genderValidator,
                items: GenderEnum.values
                    .map((e) => e.name)
                    .map((gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v == null || v.isEmpty) return;
                  genderController.text = v;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  _submit(
                    formKey,
                    firstNameController.text,
                    lastNameController.text,
                    emailController.text,
                    GenderEnum.values.firstWhere(
                      (e) => e.name == genderController.text,
                    ),
                    context,
                  );
                },
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(
    GlobalKey<FormState> formKey,
    String firstName,
    String lastName,
    String email,
    GenderEnum gender,
    BuildContext context,
  ) async {
    loggerService.debug(
      'Registering user, params: $firstName, $lastName, $email, $gender',
    );
    final result = await userService.registerUser(
      email,
      firstName,
      lastName,
      gender,
    );

    loggerService.debug('Registration result: $result');
  }
}
