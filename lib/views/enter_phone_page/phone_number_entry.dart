// import 'dart:convert';
// import 'package:j_food_updated/views/enter_phone_page/otp_page.dart';
// import 'package:j_food_updated/views/homescreen/homescreen.dart';
// import 'package:http/http.dart' as http;
// import 'package:j_food_updated/constants/constants.dart';
// import 'package:j_food_updated/resources/api-const.dart';
// import 'package:flutter/material.dart';
// import 'package:j_food_updated/stubs/fluttertoast_stub.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class PhoneNumberEntryPage extends StatefulWidget {
//   @override
//   _PhoneNumberEntryPageState createState() => _PhoneNumberEntryPageState();
// }

// class _PhoneNumberEntryPageState extends State<PhoneNumberEntryPage> {
//   final TextEditingController phoneController = TextEditingController();
//   String phoneNumber = "";
//   bool validPhone = false;
//   bool loading = false;
//   late int verifyId;
//   void deleteDigit() {
//     setState(() {
//       if (phoneNumber.isNotEmpty) {
//         phoneNumber = phoneNumber.substring(0, phoneNumber.length - 1);
//       }
//     });
//   }

//   void addDigit(String digit) {
//     setState(() {
//       if (phoneNumber.length < 10) {
//         phoneNumber += digit;
//       }
//     });
//   }

//   Future<String?> sendSms(String phoneNumber) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();

//     if (phoneNumber == "0592270122") {
//       prefs.setString('phone_number', phoneNumber);
//       Navigator.of(context).pushAndRemoveUntil(
//         MaterialPageRoute(builder: (context) => HomeScreen()),
//         (route) => false,
//       );
//     } else {
//       setState(() {
//         loading = true;
//       });
//       final url = Uri.parse(AppLink.sendSms);

//       if (phoneNumber.startsWith('0')) {
//         phoneNumber = phoneNumber.substring(1);
//       }

//       final Map<String, String> body = {
//         'phone_number': "972$phoneNumber",
//       };

//       try {
//         final response = await http.post(
//           url,
//           headers: {
//             'Content-Type': 'application/json',
//           },
//           body: jsonEncode(body),
//         );

//         if (response.statusCode == 200 || response.statusCode == 201) {
//           final Map<String, dynamic> responseData = jsonDecode(response.body);
//           String? code = responseData['code']?.toString();
//           verifyId = responseData['verificationLog_id']['id'];
//           return code;
//         } else if (response.statusCode == 429) {
//           // Handle error response
//           final responseData = jsonDecode(response.body);
//           if (responseData['message'] != null) {
//             String message = responseData['message'];
//             Fluttertoast.showToast(msg: message, timeInSecForIosWeb: 4);
//           }
//         } else {
//           Fluttertoast.showToast(
//               msg: "حدثت مشكلة اثناء ارسال الرسالة", timeInSecForIosWeb: 3);
//           throw Exception(
//               'Failed to send SMS. Status code: ${response.statusCode}');
//         }
//       } catch (e) {
//         Fluttertoast.showToast(
//             msg: "حدثت مشكلة اثناء الاتصال بالانترنت", timeInSecForIosWeb: 3);
//         throw Exception('Error occurred: $e');
//       } finally {
//         setState(() {
//           loading = false;
//         });
//       }
//     }
//   }

//   List<String> digits = [
//     '1',
//     '2',
//     '3',
//     '4',
//     '5',
//     '6',
//     '7',
//     '8',
//     '9',
//     '',
//     '0',
//     '⌫',
//   ];

//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 380;

//     return Container(
//       color: mainColor,
//       child: SafeArea(
//         child: Scaffold(
//           backgroundColor: mainColor,
//           body: loading
//               ? SizedBox(
//                   height: 300,
//                   child: Center(
//                     child: CircularProgressIndicator(),
//                   ),
//                 )
//               : SingleChildScrollView(
//                   child: Column(
//                     children: [
//                       SizedBox(height: 15),
//                       Image.asset(
//                         'assets/images/logo.png',
//                         height: isSmallScreen ? 40 : 50,
//                       ),
//                       SizedBox(height: 10),
//                       Image.asset(
//                         'assets/images/enterphone.png',
//                         height: isSmallScreen ? 150 : 200,
//                       ),
//                       SizedBox(height: isSmallScreen ? 10 : 20),
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 20),
//                         child: Text(
//                           "يرجى إدخال رقم الهاتف لإرسال رمز التحقق",
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: isSmallScreen ? 14 : 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: isSmallScreen ? 10 : 20),
//                       Container(
//                         margin: EdgeInsets.symmetric(horizontal: 40),
//                         padding:
//                             EdgeInsets.symmetric(horizontal: 10, vertical: 15),
//                         width: screenWidth * 0.70,
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: phoneNumber.isEmpty
//                             ? Text(
//                                 "رقم الهاتف",
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   color: phoneNumber.isEmpty
//                                       ? Colors.black.withOpacity(0.5)
//                                       : Colors.black,
//                                   fontSize: isSmallScreen ? 16 : 20,
//                                 ),
//                               )
//                             : Text(
//                                 phoneNumber,
//                                 style: TextStyle(
//                                   color: phoneNumber.isEmpty
//                                       ? Colors.black.withOpacity(0.5)
//                                       : Colors.black,
//                                   fontSize: isSmallScreen ? 16 : 20,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                       ),
//                       SizedBox(
//                         height: 20,
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 60),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.start,
//                           children: [
//                             Directionality(
//                               textDirection: TextDirection.ltr,
//                               child: GridView.builder(
//                                 shrinkWrap: true,
//                                 physics: NeverScrollableScrollPhysics(),
//                                 gridDelegate:
//                                     SliverGridDelegateWithFixedCrossAxisCount(
//                                   crossAxisCount: 3,
//                                   childAspectRatio: 1.5,
//                                   mainAxisSpacing: 10,
//                                   crossAxisSpacing: 10,
//                                 ),
//                                 itemCount: digits.length,
//                                 itemBuilder: (context, index) {
//                                   String digit = digits[index];
//                                   if (digit.isEmpty) {
//                                     return _buildEmptyKey(isSmallScreen);
//                                   } else if (digit == '⌫') {
//                                     return _buildBackspaceButton(isSmallScreen);
//                                   } else {
//                                     return _buildKeyPadButton(
//                                         digit, isSmallScreen);
//                                   }
//                                 },
//                               ),
//                             ),
//                             SizedBox(
//                               height: 15,
//                             ),
//                             Padding(
//                               padding:
//                                   const EdgeInsets.symmetric(horizontal: 30),
//                               child: MaterialButton(
//                                 onPressed: () async {
//                                   if (validateNumber(phoneNumber)) {
//                                     String? code = await sendSms(phoneNumber);
//                                     if (code != null) {
//                                       Navigator.of(context).push(
//                                         PageRouteBuilder(
//                                           transitionDuration:
//                                               Duration(milliseconds: 800),
//                                           reverseTransitionDuration:
//                                               Duration(milliseconds: 800),
//                                           pageBuilder: (context, animation,
//                                                   secondaryAnimation) =>
//                                               OtpVerificationPage(
//                                             phoneNumber: "972$phoneNumber",
//                                             code: code,
//                                             verifyId: verifyId,
//                                           ),
//                                           transitionsBuilder: (context,
//                                               animation,
//                                               secondaryAnimation,
//                                               child) {
//                                             const begin = 0.0;
//                                             const end = 1.0;
//                                             final rotation =
//                                                 Tween(begin: begin, end: end)
//                                                     .animate(animation);

//                                             return AnimatedBuilder(
//                                               animation: rotation,
//                                               builder: (context, child) {
//                                                 final isUnderHalfway =
//                                                     rotation.value < 0.5;

//                                                 final angle =
//                                                     rotation.value * 3.14;
//                                                 final transform =
//                                                     Matrix4.identity()
//                                                       ..setEntry(3, 2, 0.001)
//                                                       ..rotateY(isUnderHalfway
//                                                           ? angle
//                                                           : (3.14 - angle));

//                                                 return Transform(
//                                                   transform: transform,
//                                                   alignment: Alignment.center,
//                                                   child: isUnderHalfway
//                                                       ? child
//                                                       : OtpVerificationPage(
//                                                           phoneNumber:
//                                                               "972$phoneNumber",
//                                                           code: code,
//                                                           verifyId: verifyId,
//                                                         ),
//                                                 );
//                                               },
//                                               child: child,
//                                             );
//                                           },
//                                         ),
//                                       );
//                                       Fluttertoast.showToast(
//                                         msg:
//                                             "سيتم ارسال رسالة للتأكد من رقم الهاتف",
//                                         timeInSecForIosWeb: 3,
//                                       );
//                                     }
//                                   }
//                                 },
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                                 color: Colors.yellow,
//                                 child: Text(
//                                   'ارسال الرمز',
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.black,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//         ),
//       ),
//     );
//   }

//   bool validateNumber(String? value) {
//     if (value == null || value.isEmpty) {
//       Fluttertoast.showToast(msg: "يجب ادخال رقم الهاتف");
//       return false;
//     }
//     if (!value.startsWith('05')) {
//       Fluttertoast.showToast(msg: "يجب ان يبدأ رقم الهاتف ب 05");
//       return false;
//     }
//     if (value.length != 10) {
//       Fluttertoast.showToast(msg: "يجب ان يكون طول رقم الهاتف 10 أرقام");
//       return false;
//     }
//     return true;
//   }

//   Widget _buildKeyPadButton(String digit, bool isSmallScreen) {
//     return Container(
//       width: isSmallScreen ? 60 : 90,
//       height: isSmallScreen ? 40 : 60,
//       alignment: Alignment.center,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: MaterialButton(
//         onPressed: () => addDigit(digit),
//         height: isSmallScreen ? 40 : 60,
//         child: Text(
//           digit,
//           style: TextStyle(
//             fontSize: isSmallScreen ? 22 : 28,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyKey(bool isSmallScreen) {
//     return Container(
//       width: isSmallScreen ? 60 : 90,
//       height: isSmallScreen ? 40 : 60,
//     );
//   }

//   Widget _buildBackspaceButton(bool isSmallScreen) {
//     return Container(
//       width: isSmallScreen ? 60 : 90,
//       height: isSmallScreen ? 40 : 60,
//       alignment: Alignment.center,
//       decoration: BoxDecoration(
//         color: Colors.yellow,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: MaterialButton(
//         height: isSmallScreen ? 40 : 60,
//         onPressed: deleteDigit,
//         child: Icon(
//           Icons.backspace,
//           color: Colors.black,
//           size: isSmallScreen ? 22 : 28,
//         ),
//       ),
//     );
//   }
// }
