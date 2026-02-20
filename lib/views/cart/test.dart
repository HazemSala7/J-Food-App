// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:mkhymi/controller/cartcontroller.dart';
// import 'package:place_picker/place_picker.dart';

// import '../../resources/size_config.dart';

// class TestScreen extends StatefulWidget {
//   const TestScreen({super.key, required this.total});

//   final String total;

//   @override
//   _TestScreenState createState() => _TestScreenState();
// }

// class _TestScreenState extends State<TestScreen> {
//   CartController cartController = Get.put(CartController());
//   final GlobalKey<FormState> _contactKey = GlobalKey();
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _surePhoneController = TextEditingController();
//   final TextEditingController _cityController = TextEditingController();
//   final TextEditingController _noteController = TextEditingController();
//   final TextEditingController _nearByController = TextEditingController();
//   final TextEditingController _nameController = TextEditingController();
//   TextEditingController _locationController = TextEditingController();
//   double? late;
//   double? long;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('تاكيد الطلب'.tr),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(10),
//         child: Form(
//           key: _contactKey,
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 8),
//                   child: TextFormField(
//                     controller: _phoneController,
//                     keyboardType: TextInputType.phone,
//                     validator: (val) {
//                       if (val!.isEmpty) {
//                         return 'ادخل رقم الهاتف';
//                       }
//                       return null;
//                     },
//                     decoration: const InputDecoration(
//                       hintText: 'رقم التواصل',
//                       labelText: 'رقم التواصل',
//                       contentPadding: EdgeInsets.zero,
//                       suffixIcon: Icon(
//                         Icons.phone,
//                       ),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 8),
//                   child: TextFormField(
//                     controller: _surePhoneController,
//                     keyboardType: TextInputType.phone,
//                     validator: (val) {
//                       if (val!.isEmpty) {
//                         return 'تأكيد رقم الهاتف';
//                       }
//                       return null;
//                     },
//                     decoration: const InputDecoration(
//                       hintText: 'تأكيد رقم التواصل',
//                       labelText: 'تأكيد رقم التواصل',
//                       contentPadding: EdgeInsets.zero,
//                       suffixIcon: Icon(
//                         Icons.phone,
//                       ),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 8),
//                   child: TextFormField(
//                     controller: _nameController,
//                     keyboardType: TextInputType.text,
//                     validator: (val) {
//                       if (val!.isEmpty) {
//                         return 'ادخل الاسم';
//                       }
//                       return null;
//                     },
//                     decoration: const InputDecoration(
//                       hintText: 'الاسم ',
//                       labelText: 'الاسم ',
//                       contentPadding: EdgeInsets.zero,
//                       suffixIcon: Icon(
//                         Icons.person,
//                       ),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 8),
//                   child: TextFormField(
//                     controller: _cityController,
//                     keyboardType: TextInputType.text,
//                     validator: (val) {
//                       if (val!.isEmpty) {
//                         return 'ادخل المدينه';
//                       }
//                       return null;
//                     },
//                     decoration: const InputDecoration(
//                       hintText: 'المدينه ',
//                       labelText: 'المدينه ',
//                       contentPadding: EdgeInsets.zero,
//                       suffixIcon: Icon(
//                         Icons.location_city,
//                       ),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 8),
//                   child: TextFormField(
//                     controller: _noteController,
//                     keyboardType: TextInputType.text,
//                     validator: (val) {
//                       if (val!.isEmpty) {
//                         return 'ادخل ملاحظه';
//                       }
//                       return null;
//                     },
//                     decoration: const InputDecoration(
//                       hintText: 'ملاحظه ',
//                       labelText: 'ملاحظه ',
//                       contentPadding: EdgeInsets.zero,
//                       suffixIcon: Icon(
//                         Icons.location_city,
//                       ),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 8),
//                   child: TextFormField(
//                     controller: _nearByController,
//                     keyboardType: TextInputType.text,
//                     validator: (val) {
//                       if (val!.isEmpty) {
//                         return 'ادخل القرب من ';
//                       }
//                       return null;
//                     },
//                     decoration: const InputDecoration(
//                       hintText: 'بالقرب من ',
//                       labelText: 'بالقرب من ',
//                       contentPadding: EdgeInsets.zero,
//                       suffixIcon: Icon(
//                         Icons.location_city,
//                       ),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 8),
//                   child: TextFormField(
//                     onTap: () async {
//                       LocationResult result = await Navigator.of(context).push(
//                         MaterialPageRoute(
//                           builder: (context) => PlacePicker(
//                             'AIzaSyC86lWEI5fMklifz509ZmHUyGpj1AuplUA',
//                             defaultLocation: const LatLng(26.8206, 30.8025),
//                           ),
//                         ),
//                       );
//                       print(result.latLng!.latitude);
//                       print(result.latLng!.longitude);

//                       print('Location is inside Egypt');
//                       setState(() {
//                         _locationController = TextEditingController(
//                             text: result.formattedAddress.toString());
//                         late = result.latLng!.latitude;
//                         long = result.latLng!.longitude;
//                       });
//                     },
//                     controller: _locationController,
//                     validator: (val) {
//                       if (val!.isEmpty) {
//                         return 'اختار الموقع الي تريده';
//                       }
//                       return null;
//                     },
//                     readOnly: true,
//                     decoration: const InputDecoration(
//                       hintText: 'الموقع',
//                       labelText: 'الموقع',
//                       contentPadding: EdgeInsets.zero,
//                       suffixIcon: Icon(
//                         Icons.location_on,
//                         color: Colors.red,
//                       ),
//                     ),
//                   ),
//                 ),
//                 MaterialButton(
//                   onPressed: () {
//                     if (_contactKey.currentState!.validate()) {
//                       cartController.order(
//                           city: _cityController.text,
//                           area: _nearByController.text,
//                           address: _locationController.text,
//                           total: widget.total.toString(),
//                           long: long.toString(),
//                           late: late.toString(),
//                           mobile: _phoneController.text,
//                           note: _noteController.text,
//                           cartList: cartController.CartList);
//                     }
//                   },
//                   child: Container(
//                     padding: const EdgeInsets.all(8),
//                     width: Get.width - 50,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(25),
//                       color: Colors.deepOrange.withOpacity(.8),
//                     ),
//                     child: Center(
//                       child: Text(
//                         'اطلب الآن'.tr,
//                         style: const TextStyle(
//                             fontFamily: 'ArbFONTS',
//                             fontSize: 18,
//                             fontWeight: FontWeight.w800,
//                             color: Colors.white),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
