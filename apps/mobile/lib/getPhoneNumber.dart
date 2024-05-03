import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'getPermissions.dart';

String generateUserKey() {
  var uuid = Uuid();
  return uuid.v4(); // Generate a version 4 (random) UUID
}

class GetPhoneNumber extends StatefulWidget {
  @override
  State<GetPhoneNumber> createState() => _GetPhoneNumberState();
}

class _GetPhoneNumberState extends State<GetPhoneNumber> {
  TextEditingController controller = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String initialCountry = 'IN';
  bool buttonEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            image: DecorationImage(
          image: AssetImage("assets/background/main.png"),
          fit: BoxFit.cover,
        )),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.125),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 85),
                    Image.asset(
                      "assets/icon/icon.png",
                      height: 140,
                    ),
                    Text("D I S C O N N E C T",
                        style: GoogleFonts.getFont('Lexend',
                            fontWeight: FontWeight.w700, fontSize: 23)),
                    SizedBox(height: 59),
                    Container(
                      // padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      width: MediaQuery.of(context).size.width * 0.75,
                      decoration: BoxDecoration(
                          // border: Border.all(width: 1, color: Colors.black),
                          // borderRadius: BorderRadius.circular(15),
                          ),
                      child: Column(
                        children: [
                          IntlPhoneField(
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 20),
                                counter: Offstage(),
                                labelText: '  Phone Number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Colors.red, width: 3.0),
                                  // borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Colors.black, width: 2.0),
                                  borderRadius: BorderRadius.circular(12.0),
                                )),
                            initialCountryCode: initialCountry,
                            showDropdownIcon: true,
                            dropdownIconPosition: IconPosition.leading,
                            onChanged: (phone) {
                              setState(() {
                                // buttonEnabled = phone.number.length >= 10;
                                buttonEnabled =
                                    phone.completeNumber.length >= 10;
                              });
                            },
                            controller: controller,
                          ),
                          SizedBox(height: 20),
                          _buildTextField(
                            label: 'Name',
                            controller: nameController,
                            keyboardType: TextInputType.text,
                          ),
                          SizedBox(width: 20),
                        ],
                      ),
                    ),
                    SizedBox(height: 18),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.75,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: buttonEnabled
                            ? () async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                prefs.setString('phoneNumber', controller.text);
                                String? userKey = generateUserKey();
                                // String? phoneNumber = controller.text;
                                // SharedPreferences prefs =
                                //     await SharedPreferences.getInstance();
                                // userKey = prefs.setString('userKey', userkey);

                                await firestore
                                    .collection('users')
                                    .doc(userKey)
                                    .set({
                                  'name': nameController.text,
                                  'phoneNumber': controller.text,
                                });

                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (context) => GetPermissions()),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            )),
                        child: Text(
                          'Submit',
                          style: GoogleFonts.getFont('Kanit',
                              fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                    Spacer(),
                    TextButton(
                        onPressed: (() => {}),
                        child: Text("Terms & Conditions",
                            // style: TextStyle(color: Colors.grey),
                            style: GoogleFonts.getFont('JetBrains Mono',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.grey)))
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 3.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black, width: 2.0),
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }
}
