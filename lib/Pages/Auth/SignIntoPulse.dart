import 'package:flutter/material.dart';
import 'package:picturebook/Pages/Auth/Login_Page.dart';
// import 'package:picturebook/Pages/QrCodes/QrCode_For_SignIn.dart';
// import 'package:easy_localization/easy_localization.dart';

class SignIn_to_Pulse extends StatefulWidget {
  const SignIn_to_Pulse({super.key});

  @override
  State<SignIn_to_Pulse> createState() => _SignIn_to_PulseState();
}

class _SignIn_to_PulseState extends State<SignIn_to_Pulse> {
  String number = '';
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => Login_Page()));
        },
        child: Icon(Icons.logout),
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Image.asset(
                'assets/images/login.png',
                width: MediaQuery.of(context).size.width * 0.8,
              ),
            ),
            ElevatedButton(
                onPressed: () {
                  // Navigator.of(context).push(
                  //   MaterialPageRoute(
                  //     builder: (context) => QrcodeForSignin(),
                  //   ),
                  // );
                },
                child: const  Text('scan qr code to connect with pc')),
          ],
        ),
      ),
    ));
  }
}
