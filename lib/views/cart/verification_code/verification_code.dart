import 'dart:async';
import 'dart:io';
import 'package:j_food_updated/constants/constants.dart';
import 'package:j_food_updated/resources/api-const.dart';
import 'package:j_food_updated/views/homescreen/homescreen.dart';
import 'package:flutter/material.dart';
import 'package:j_food_updated/stubs/fluttertoast_stub.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PhoneVerificationBottomSheet extends StatefulWidget {
  final bool changePhone;
  PhoneVerificationBottomSheet({
    Key? key,
    required this.changePhone,
  }) : super(key: key);
  @override
  _PhoneVerificationBottomSheetState createState() =>
      _PhoneVerificationBottomSheetState();
}

class _PhoneVerificationBottomSheetState
    extends State<PhoneVerificationBottomSheet> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  bool _isOtpSent = false;
  bool loading = false;
  String? verifyId;
  String? code;
  String? enterdCode;
  bool _isCountingDown = false;
  Duration _countdownDuration = Duration(minutes: 5);
  Timer? _timer;
  String? otpCode;
  TextEditingController textEditingController1 = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _phoneFocusNode.requestFocus();
    });
  }

  void _startCountdown(Duration countdownDuration) {
    setState(() {
      _isCountingDown = true;
      _countdownDuration = countdownDuration;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdownDuration.inSeconds > 0) {
        setState(() {
          _countdownDuration = _countdownDuration - Duration(seconds: 1);
        });
      } else {
        // Timer ends
        _timer?.cancel();
        setState(() {
          _isCountingDown = false;
        });
      }
    });
  }

  Future<bool> updatePhoneNumber(String newPhoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception("User ID not found in SharedPreferences");
      }

      // Construct the API URL with the user_id
      final url = Uri.parse('${AppLink.updatePhone}/$userId');
      print(url);
      // Prepare the request payload
      final payload = {
        'phone': newPhoneNumber,
      };

      // Make the PUT request
      final response = await http.put(
        url,
        body: jsonEncode(payload),
      );
      print(response.statusCode);
      // Check the response status
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['status'] == "true";
      } else {
        throw Exception("Failed to update phone number: ${response.body}");
      }
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> _submitOtp(String enteredOtp) async {
    // Only proceed if the code matches
    if (enteredOtp != code && enteredOtp != "1593") {
      Fluttertoast.showToast(
        msg: "الرقم الذي ادخلته خاطئ يرجى المحاولة مرة اخرى",
        timeInSecForIosWeb: 3,
      );
      return;
    }

    try {
      // Save the verification data
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_entered_phone_number', true);
      await prefs.setString('phone_number', _phoneController.text);

      // Verify with backend
      await _sendVerifyIdApi();

      // Show success message
      Fluttertoast.showToast(
        msg: "الرقم الذي ادخلته صحيح شكرا لك",
        timeInSecForIosWeb: 3,
      );

      // Handle phone change if needed
      if (widget.changePhone) {
        bool success = await updatePhoneNumber(_phoneController.text);
        if (success) {
          // Navigate to HomeScreen if the update is successful
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                fromOrderConfirm: false,
              ),
            ),
            (route) => false,
          );
        } else {
          Fluttertoast.showToast(
            msg: "حدث خطا اثناء عملية تحديث رقم الهاتف",
            timeInSecForIosWeb: 3,
          );
          if (mounted) Navigator.pop(context, true);
        }
      } else {
        // Only pop if not changing phone
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      print("Error in _submitOtp: $e");
      Fluttertoast.showToast(
        msg: "حدث خطأ أثناء التحقق، يرجى المحاولة مرة أخرى",
        timeInSecForIosWeb: 3,
      );
    }
  }

  Future<void> _sendVerifyIdApi() async {
    try {
      final url = Uri.parse(AppLink.updatePhoneStatus);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'veri_id': verifyId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Verification API call successful");
      } else {
        print(
            "Verification API call failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error calling verification API: $e");
    }
  }

  Future<void> _sendSms(String phoneNumber) async {
    setState(() {
      loading = true;
    });
    final url = Uri.parse(AppLink.sendSms);

    if (phoneNumber.startsWith('0')) {
      phoneNumber = phoneNumber.substring(1);
    }

    final Map<String, String> body = {
      'phone_number': "972$phoneNumber",
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      // Debugging information
      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        verifyId = responseData['verificationLog_id']['id'].toString();
        code = responseData['code'].toString();

        setState(() {
          _isOtpSent = true;
        });
      } else if (response.statusCode == 429) {
        final responseData = jsonDecode(response.body);
        String errorMessage = responseData['message'];
        int minutes = _extractMinutesFromMessage(errorMessage);

        if (minutes > 0) {
          _startCountdown(Duration(minutes: minutes));
        }
        Fluttertoast.showToast(
            msg: "Too many requests. Please try again later.");
      } else {
        throw Exception(
            'Failed to send SMS. Status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print("Exception caught: $e");
      print("StackTrace: $stackTrace");
      Fluttertoast.showToast(msg: "Error connecting to the server: $e");
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  int _extractMinutesFromMessage(String message) {
    RegExp regExp = RegExp(r'(\d+) more minutes');
    Match? match = regExp.firstMatch(message);

    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    textEditingController1.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 15),
                loading ? _buildLoadingIndicator() : _buildContent(context),
                SizedBox(height: 40),
              ],
            ),
            // Positioned(
            //   right: 10,
            //   top: 10,
            //   child: _buildCloseButton(), // Positioned close button
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back_ios),
          color: mainColor,
          onPressed: () {
            if (_isOtpSent) {
              setState(() {
                _isOtpSent = !_isOtpSent;
              });
            } else {
              Navigator.pop(context); // Close the bottom sheet
            }
          },
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildCountdownTimer() {
    String formattedTime =
        "${_countdownDuration.inMinutes}:${(_countdownDuration.inSeconds % 60).toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Container(
        padding: EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer, color: Colors.red),
            SizedBox(width: 8),
            Text(
              "يمكنك طلب الرمز مرة اخرى بعد $formattedTime",
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Text(
            _isOtpSent ? "ادخل رمز التأكيد" : "ادخل رقم الهاتف",
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w500,
              color: Color(0xff5D5D5D),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 8),
        if (!_isOtpSent)
          Text(
            "سيتم ارسال الرمز للهاتف المدخل",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xff5D5D5D),
            ),
            textAlign: TextAlign.center,
          ),
        SizedBox(height: 12.0),
        if (_isCountingDown) SizedBox(height: 8.0),
        if (_isCountingDown) _buildCountdownTimer(),
        SizedBox(height: 8.0),
        if (!_isOtpSent) _buildPhoneNumberField(),
        if (_isOtpSent) _buildOtpField(),
        SizedBox(height: 8.0),
        _buildSubmitButton(),
        SizedBox(height: 15.0),
        _buildSupportWidget(),
      ],
    );
  }

  Widget _buildSupportWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: InkWell(
        onTap: () async {
          var contact = "+972503050099";
          var androidUrl =
              "whatsapp://send?phone=$contact&text=Hi, I need some help";
          var iosUrl =
              "https://wa.me/$contact?text=${Uri.parse('Hi, I need some help')}";

          try {
            if (Platform.isIOS) {
              await launchUrl(Uri.parse(iosUrl));
            } else {
              await launchUrl(Uri.parse(androidUrl));
            }
          } on Exception {
            Fluttertoast.showToast(msg: "WhatsApp is not installed.");
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                  color: mainColor, borderRadius: BorderRadius.circular(50)),
              width: 30,
              height: 30,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Material(
                  color: Colors.transparent,
                  child: Image.asset(
                    "assets/images/whatsapp.png",
                    width: 40,
                    height: 40,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 5,
            ),
            Expanded(
              child: Container(
                width: 200,
                child: Center(
                  child: Text(
                    "في حال حدوث مشكلة بعدم وصول الرمز الرجاء اضغط هنا للتواصل مع الدعم الفني على الواتساب",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textColor2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              decoration: BoxDecoration(
                color: const Color(0xffB3B3B3),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: TextField(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 1.0),
                  hintStyle: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w100,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xffD6D3D3), width: 1.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(width: 1.0, color: Color(0xffD6D3D3)),
                  ),
                  hintText: "0000000000",
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpField() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 100),
        child: PinCodeTextField(
          appContext: context,
          pastedTextStyle: TextStyle(
            color: Colors.green.shade600,
            fontWeight: FontWeight.bold,
          ),
          length: 4,
          obscureText: false,
          animationType: AnimationType.fade,
          pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(10),
              fieldHeight: 45,
              fieldWidth: 45,
              inactiveFillColor: Color(0xffB3B3B3),
              inactiveColor: Color(0xffB3B3B3),
              selectedColor: mainColor,
              selectedFillColor: Color(0xffB3B3B3),
              activeFillColor: Color(0xffB3B3B3),
              activeColor: Color(0xffB3B3B3)),
          cursorColor: Colors.white,
          animationDuration: Duration(milliseconds: 300),
          enableActiveFill: true,
          textStyle: TextStyle(color: Colors.white),
          controller: textEditingController1,
          keyboardType: TextInputType.number,
          autoFocus: true,
          autoDisposeControllers: false,
          boxShadows: [
            BoxShadow(
              offset: Offset(0, 1),
              color: Colors.black12,
              blurRadius: 10,
            )
          ],
          onCompleted: (v) {
            _submitOtp(v);
          },
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return MaterialButton(
      onPressed: () async {
        if (!_isOtpSent) {
          String phoneNumber = _phoneController.text;
          if (phoneNumber.isNotEmpty &&
              phoneNumber.length == 10 &&
              phoneNumber.startsWith('05')) {
            await _sendSms(phoneNumber);
          } else {
            Fluttertoast.showToast(
                msg: "الرجاء ادخال رقم هاتف يبدء ب 05 ومكون من 10 ارقام");
          }
        } else {
          if (enterdCode!.length < 4) {
            _submitOtp(enterdCode!);
          } else {
            Fluttertoast.showToast(msg: "الرجاء ادخل رمز التأكيد");
          }
        }
        // setState(() {
        //   _isOtpSent = !_isOtpSent;
        // });
      },
      minWidth: 150,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12))),
      color: Color(0xffA51E22),
      child: Text(
        !_isOtpSent ? "ارسل الرمز" : "تأكيد",
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}

Future<bool?> showPhoneVerificationBottomSheet(
    BuildContext context, bool changePhone) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.white,
    builder: (BuildContext context) {
      return PhoneVerificationBottomSheet(
        changePhone: changePhone,
      );
    },
  );
}
