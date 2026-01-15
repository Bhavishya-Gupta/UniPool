import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  var _isLogin = true; // Toggle between Login and Signup
  var _enteredEmail = '';
  var _enteredPassword = '';
  var _enteredName = '';
  final _formKey = GlobalKey<FormState>();

  void _submit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;
    _formKey.currentState!.save();

    try {
      if (_isLogin) {
        // Log user in
        await _auth.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
      } else {
        // Sign user up
        final userCred = await _auth.createUserWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
        
        // Save extra user data to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCred.user!.uid)
            .set({
          'name': _enteredName,
          'email': _enteredEmail,
        });
      }
    } on FirebaseAuthException catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Authentication failed')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_isLogin ? 'UniPool Login' : 'Create Account', 
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  if (!_isLogin)
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (value) => value!.isEmpty ? 'Enter a name' : null,
                      onSaved: (value) => _enteredName = value!,
                    ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email Address'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => !value!.contains('@') ? 'Enter valid email' : null,
                    onSaved: (value) => _enteredEmail = value!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) => value!.length < 6 ? 'Password too short' : null,
                    onSaved: (value) => _enteredPassword = value!,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _submit,
                    child: Text(_isLogin ? 'Login' : 'Signup'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                      });
                    },
                    child: Text(_isLogin ? 'Create new account' : 'I already have an account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}