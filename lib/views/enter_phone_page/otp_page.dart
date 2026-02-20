// import 'dart:convert';
// import 'package:j_food_updated/resources/api-const.dart';
// import 'package:j_food_updated/views/homescreen/homescreen.dart';
// import 'package:http/http.dart' as http;
// import 'package:j_food_updated/constants/constants.dart';
// import 'package:flutter/material.dart';
// import 'package:j_food_updated/stubs/fluttertoast_stub.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:async';

// class OtpVerificationPage extends StatefulWidget {
//   final String phoneNumber;
//   final String code;
//   final int verifyId;
//   const OtpVerificationPage(
//       {required this.phoneNumber, required this.code, required this.verifyId});

//   @override
//   _OtpVerificationPageState createState() => _OtpVerificationPageState();
// }

// class _OtpVerificationPageState extends State<OtpVerificationPage> {
//   List<String> otpDigits = ["", "", "", "", "", ""]; // To store entered digits
//   int currentIndex = 0; // To track the current input position
//   bool loading = false;
//   int _resendTimeout = 300;
//   Timer? _resendTimer;
//   bool canResend = false;
//   String currentCode = "";
//   bool attempts = false;
//   int attemptCount = 0; // To track the number of resend attempts

//   @override
//   void initState() {
//     super.initState();
//     currentCode = widget.code;

//     startResendTimer(); // Start the countdown when page is loaded
//   }

//   @override
//   void dispose() {
//     _resendTimer?.cancel(); // Cancel the timer when the page is disposed
//     super.dispose();
//   }

//   // Function to start the resend timer
//   void startResendTimer() {
//     setState(() {
//       canResend = false;
//     });

//     _resendTimer = Timer.periodic(Duration(seconds: 1), (timer) {
//       setState(() {
//         if (_resendTimeout > 0) {
//           _resendTimeout--;
//         } else {
//           canResend = true;
//           _resendTimer?.cancel();
//         }
//       });
//     });
//   }

//   Future<void> _resendOtp() async {
//     if (!canResend) return;

//     String? newCode = await sendSms("972${widget.phoneNumber.substring(4)}");
//     if (newCode != null) {
//       setState(() {
//         attempts = true;
//         currentCode = newCode;
//         attemptCount++; // Increment the attempt count
//       });
//       Fluttertoast.showToast(
//         msg: "تم ارسال رمز جديد",
//         timeInSecForIosWeb: 3,
//       );
//       startResendTimer(); // Restart the timer with the new attempt count
//     }
//   }

//   Future<String?> sendSms(String phoneNumber) async {
//     setState(() {
//       loading = true;
//     });
//     final url = Uri.parse(AppLink.sendSms);

//     final Map<String, String> body = {
//       'phone_number': "$phoneNumber",
//     };

//     try {
//       final response = await http.post(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode(body),
//       );

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final Map<String, dynamic> responseData = jsonDecode(response.body);
//         String? code = responseData['code']?.toString();
//         return code;
//       } else {
//         // Extract the message to get the wait time
//         final responseData = jsonDecode(response.body);
//         if (responseData['message'] != null) {
//           String message = responseData['message'];
//           Fluttertoast.showToast(msg: message, timeInSecForIosWeb: 3);

//           // Extract the wait time from the message
//           final waitTimeMatch = RegExp(r'(\d+)').firstMatch(message);
//           if (waitTimeMatch != null) {
//             // Convert the wait time to seconds
//             int waitTime = int.parse(waitTimeMatch.group(0)!) * 60;
//             setState(() {
//               _resendTimeout = waitTime;
//               canResend = false;
//             });
//             startResendTimer();
//           }
//         }
//         Fluttertoast.showToast(
//             msg: "حدثت مشكلة اثناء ارسال الرسالة", timeInSecForIosWeb: 3);
//         throw Exception(
//             'Failed to send SMS. Status code: ${response.statusCode}');
//       }
//     } catch (e) {
//       // Fluttertoast.showToast(
//       //     msg: "حدثت مشكلة اثناء الاتصال بالانترنت", timeInSecForIosWeb: 3);
//       throw Exception('Error occurred: $e');
//     } finally {
//       setState(() {
//         loading = false;
//       });
//     }
//   }

//   // Function to handle digit input
//   void _handleDigitInput(String digit) {
//     if (currentIndex < 6) {
//       setState(() {
//         otpDigits[currentIndex] = digit;
//         currentIndex++;
//       });
//     }
//     if (currentIndex == 6) {
//       _submitOtp(); // Submit OTP when all digits are entered
//     }
//   }

//   // Function to delete the last entered digit
//   void _deleteDigit() {
//     if (currentIndex > 0) {
//       setState(() {
//         currentIndex--;
//         otpDigits[currentIndex] = "";
//       });
//     }
//   }

//   // Build OTP box
//   Widget _buildOtpBox(int index) {
//     return Container(
//       width: 40,
//       height: 40,
//       decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(width: 2, color: Colors.yellow)),
//       alignment: Alignment.center,
//       child: Text(
//         otpDigits[index],
//         style: TextStyle(
//           fontSize: 24,
//           fontWeight: FontWeight.bold,
//           color: Colors.black,
//         ),
//       ),
//     );
//   }

//   // Function to build the backspace button
//   Widget _buildBackspaceButton(bool isSmallScreen) {
//     return Container(
//       width: 90,
//       height: 60,
//       alignment: Alignment.center,
//       decoration: BoxDecoration(
//         color: Colors.yellow,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: MaterialButton(
//         onPressed: _deleteDigit,
//         height: 60,
//         child: Icon(
//           Icons.backspace,
//           color: Colors.black,
//           size: isSmallScreen ? 22 : 28,
//         ),
//       ),
//     );
//   }

//   // Function to build the keypad as a GridView
//   Widget _buildKeyPad(bool isSmallScreen) {
//     final List<String> digits = [
//       '1',
//       '2',
//       '3',
//       '4',
//       '5',
//       '6',
//       '7',
//       '8',
//       '9',
//       '',
//       '0',
//       '⌫',
//     ];

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 40),
//       child: Directionality(
//         textDirection: TextDirection.ltr,
//         child: GridView.builder(
//           shrinkWrap: true,
//           physics: NeverScrollableScrollPhysics(),
//           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 3,
//             childAspectRatio: 1.5,
//             mainAxisSpacing: 10,
//             crossAxisSpacing: 10,
//           ),
//           itemCount: digits.length,
//           itemBuilder: (context, index) {
//             String digit = digits[index];
//             if (digit.isEmpty) {
//               return _buildEmptyKey(isSmallScreen);
//             } else if (digit == '⌫') {
//               return _buildBackspaceButton(isSmallScreen);
//             } else {
//               return _buildKeyPadButton(digit);
//             }
//           },
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

//   Widget _buildResendText() {
//     return loading
//         ? Center(
//             child: CircularProgressIndicator(),
//           )
//         : GestureDetector(
//             onTap: canResend ? _resendOtp : null,
//             child: Text(
//               canResend
//                   ? "اعادة ارسال"
//                   : "يمكنك اعادة ارسال بعد $_resendTimeout ثانية",
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: canResend ? Colors.yellow : Colors.white,
//               ),
//             ),
//           );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 380;

//     return Container(
//       color: Colors.white,
//       child: SafeArea(
//         child: Scaffold(
//           backgroundColor: mainColor, // Purple background color
//           appBar: AppBar(
//             centerTitle: true,
//             title: Text("رمز التحقق", style: TextStyle(color: mainColor)),
//             backgroundColor: Colors.white,
//             leading: IconButton(
//               icon: Icon(Icons.arrow_back, color: mainColor),
//               onPressed: () => Navigator.of(context).pop(),
//             ),
//             iconTheme: IconThemeData(color: mainColor),
//           ),
//           body: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     children: [
//                       SizedBox(height: isSmallScreen ? 20 : 30),
//                       Image.asset(
//                         "assets/images/pin-code.png",
//                         width: isSmallScreen ? 90 : 120,
//                         height: isSmallScreen ? 90 : 120,
//                       ),
//                       SizedBox(height: isSmallScreen ? 12 : 20),
//                       Text(
//                         "تم ارسال رمز مكون من 6 ارقام الى الرقم",
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                       SizedBox(height: 10),
//                       Text(
//                         "972${widget.phoneNumber.substring(4)}",
//                         style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                             decoration: TextDecoration.underline,
//                             decorationColor: Colors.white),
//                       ),
//                       SizedBox(height: isSmallScreen ? 25 : 40),

//                       // OTP input fields as containers
//                       Directionality(
//                         textDirection: TextDirection.ltr,
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 20),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceAround,
//                             children: List.generate(
//                                 6, (index) => _buildOtpBox(index)),
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: isSmallScreen ? 25 : 40),
//                       _buildResendText(),
//                       SizedBox(height: 30),
//                       _buildKeyPad(isSmallScreen),
//                       SizedBox(height: 30),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildKeyPadButton(String digit) {
//     return GestureDetector(
//       onTap: () => _handleDigitInput(digit),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Center(
//           child: Text(
//             digit,
//             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _submitOtp() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String enteredOtp = otpDigits.join("");
//     if (enteredOtp == currentCode) {
//       prefs.setBool('has_entered_phone_number', true);
//       prefs.setString('phone_number', widget.phoneNumber.substring(3));

//       await _sendVerifyIdApi();

//       // Navigate with flip animation
//       Navigator.of(context).pushAndRemoveUntil(
//         PageRouteBuilder(
//           transitionDuration: Duration(milliseconds: 800),
//           reverseTransitionDuration: Duration(milliseconds: 800),
//           pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
//           transitionsBuilder: (context, animation, secondaryAnimation, child) {
//             const begin = 0.0;
//             const end = 1.0;
//             final rotation = Tween(begin: begin, end: end).animate(animation);

//             return AnimatedBuilder(
//               animation: rotation,
//               builder: (context, child) {
//                 final isUnderHalfway = rotation.value < 0.5;

//                 final angle = rotation.value * 3.14;
//                 final transform = Matrix4.identity()
//                   ..setEntry(3, 2, 0.001)
//                   ..rotateY(isUnderHalfway ? angle : (3.14 - angle));

//                 return Transform(
//                   transform: transform,
//                   alignment: Alignment.center,
//                   child: isUnderHalfway ? child : HomeScreen(),
//                 );
//               },
//               child: child,
//             );
//           },
//         ),
//         (route) => false,
//       );

//       Fluttertoast.showToast(
//         msg: "الرقم الذي ادخلته صحيح شكرا لك",
//         timeInSecForIosWeb: 3,
//       );
//     } else {
//       Fluttertoast.showToast(
//         msg: "الرقم الذي ادخلته خاطئ يرجى المحاولة مرة اخرى",
//         timeInSecForIosWeb: 3,
//       );
//     }
//   }

//   Future<void> _sendVerifyIdApi() async {
//     final url = Uri.parse(AppLink.updatePhoneStatus);
//     await http.post(
//       url,
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'veri_id': widget.verifyId.toString(),
//       }),
//     );
//   }
// }
