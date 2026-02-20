import 'package:j_food_updated/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:j_food_updated/views/setting/widgets/setting_item.dart';
import '../../component/forward_button.dart';
import '../../component/setting_switch.dart';
import '../../resources/color_manger.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool isDarkMode = true;
  bool muteNotification = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: mainColor,
      child: SafeArea(
        child: Scaffold(
          body: Container(
            height: double.infinity,
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          Icons.arrow_back,
                          color: ColorManager.black,
                        )),
                    const SizedBox(
                      width: 20,
                    ),
                    Text(
                      "Settings",
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: ColorManager.black),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  "Account",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: ColorManager.black),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Image.asset('assets/images/img.png', width: 70, height: 70),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Guest',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: ColorManager.black),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '01157446858',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          )
                        ],
                      ),
                      const Spacer(),
                      ForwardButton(
                        onTap: () {},
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  "Settings",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: ColorManager.black),
                ),
                const SizedBox(height: 20),
                SettingItem(
                  title: "Contact",
                  icon: Ionicons.person,
                  bgColor: ColorManager.primary,
                  iconColor: ColorManager.white,
                  value: "",
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                SettingItem(
                  title: "Language",
                  icon: Ionicons.earth,
                  bgColor: Colors.orange.shade100,
                  iconColor: Colors.orange,
                  value: "Arabic",
                  onTap: () {
                    // showDialog(
                    //   barrierColor: Colors.grey.withOpacity(0.7),
                    //   context: context,
                    //   builder: (BuildContext context) {
                    //     return AlertDialog(
                    //       backgroundColor: ColorManager.primary,
                    //       title: Image.asset(
                    //         'assets/images/logo.png',
                    //         height: 50,
                    //       ),
                    //       shape: RoundedRectangleBorder(
                    //           borderRadius: BorderRadius.circular(16)),
                    //       content: Column(
                    //         mainAxisSize: MainAxisSize.min,
                    //         mainAxisAlignment: MainAxisAlignment.center,
                    //         children: [
                    //           Text(
                    //             'Choose Language'.tr,
                    //             style: TextStyle(
                    //                 fontWeight: FontWeight.w800,
                    //                 color: ColorManager.black),
                    //           ),
                    //           const SizedBox(
                    //             height: 16,
                    //           ),
                    //         ],
                    //       ),
                    //       actions: [
                    //         Column(
                    //           crossAxisAlignment: CrossAxisAlignment.center,
                    //           mainAxisAlignment: MainAxisAlignment.center,
                    //           children: [
                    //             InkWell(
                    //               onTap: () {
                    //                 Get.updateLocale(const Locale('en'));
                    //                 box.write('lange', 'en');
                    //                 Get.back();
                    //               },
                    //               child: Container(
                    //                   width:
                    //                       MediaQuery.of(context).size.width / 2,
                    //                   alignment: Alignment.center,
                    //                   padding: const EdgeInsets.symmetric(
                    //                       vertical: 12),
                    //                   decoration: ShapeDecoration(
                    //                     gradient: LinearGradient(colors: [
                    //                       ColorManager.primary,
                    //                       ColorManager.secondary,
                    //                     ]),
                    //                     shape: const RoundedRectangleBorder(
                    //                       borderRadius: BorderRadius.all(
                    //                           Radius.circular(10)),
                    //                     ),
                    //                   ),
                    //                   child: Text(
                    //                     'English',
                    //                     style: TextStyle(
                    //                         fontWeight: FontWeight.w900,
                    //                         color: ColorManager.black,
                    //                         fontSize: 20),
                    //                   )),
                    //             ),
                    //             const SizedBox(
                    //               height: 10,
                    //             ),
                    //             InkWell(
                    //               onTap: () {
                    //                 Get.updateLocale(const Locale('ar'));
                    //                 box.write('lange', 'ar');
                    //                 Get.back();
                    //               },
                    //               child: Container(
                    //                   width:
                    //                       MediaQuery.of(context).size.width / 2,
                    //                   alignment: Alignment.center,
                    //                   padding: const EdgeInsets.symmetric(
                    //                       vertical: 12),
                    //                   decoration: ShapeDecoration(
                    //                     gradient: LinearGradient(colors: [
                    //                       ColorManager.primary,
                    //                       ColorManager.secondary,
                    //                     ]),
                    //                     shape: const RoundedRectangleBorder(
                    //                       borderRadius: BorderRadius.all(
                    //                           Radius.circular(10)),
                    //                     ),
                    //                   ),
                    //                   child: Text(
                    //                     'العربية',
                    //                     style: TextStyle(
                    //                         fontWeight: FontWeight.w900,
                    //                         color: ColorManager.black,
                    //                         fontSize: 20),
                    //                   )),
                    //             ),
                    //           ],
                    //         ),
                    //       ],
                    //     );
                    //   },
                    // );
                  },
                ),
                const SizedBox(height: 20),
                SettingSwitch(
                  title: "Notifications",
                  icon: Ionicons.notifications,
                  bgColor: Colors.blue.shade100,
                  iconColor: Colors.blue,
                  value: muteNotification,
                  onTap: (value) async {
                    setState(() {
                      muteNotification = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                SettingSwitch(
                  title: "Dark Mode",
                  icon: Ionicons.cloudy_night,
                  bgColor: Colors.purple.shade100,
                  iconColor: Colors.purple,
                  value: isDarkMode,
                  onTap: (value) {
                    setState(() {
                      isDarkMode = value;
                    });
      
                    // Restart.restartApp();
                  },
                ),
                const SizedBox(height: 20),
                SettingItem(
                  title: "Help",
                  icon: Ionicons.help,
                  bgColor: Colors.red.shade100,
                  iconColor: Colors.red,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
