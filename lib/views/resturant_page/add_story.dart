import 'dart:io';
import 'package:j_food_updated/constants/constants.dart';
import 'package:j_food_updated/views/resturant_page/restaurant_page.dart';
import 'package:flutter/material.dart';
import 'package:j_food_updated/stubs/fluttertoast_stub.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dotted_border/dotted_border.dart';
import 'package:http_parser/http_parser.dart';
import 'package:video_player/video_player.dart';

class AddStory extends StatefulWidget {
  final String restaurantId;
  final bool isEditing;
  final String? productId;
  final String categoryId;
  final String userId;
  final String status;
  final String restaurantName;
  final String restaurantImage;
  final String restaurantAddress;
  final String deliveryPrice;
  final String storeCloseTime;
  final String storeOpenTime;
  const AddStory({
    super.key,
    required this.restaurantId,
    required this.isEditing,
    this.productId,
    required this.categoryId,
    required this.userId,
    required this.status,
    required this.restaurantName,
    required this.restaurantImage,
    required this.restaurantAddress,
    required this.deliveryPrice,
    required this.storeCloseTime,
    required this.storeOpenTime,
  });

  @override
  State<AddStory> createState() => _AddStoryState();
}

class _AddStoryState extends State<AddStory> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  List<XFile> _media = [];
  String mediaType = "image";
  bool addLoading = false;
  bool photoField = false;
  bool nameField = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  Future<void> _pickMedia() async {
    setState(() {
      photoField = false;
    });
    final ImagePicker _picker = ImagePicker();
    final XFile? selectedFile = await _picker.pickMedia();

    if (selectedFile != null) {
      final String extension = selectedFile.path.split('.').last.toLowerCase();
      setState(() {
        _media.clear();
        _media.add(selectedFile);
        mediaType =
            (extension == "mp4" || extension == "mov") ? "video" : "image";
      });
    }
  }

  Future<void> _submitForm() async {
    setState(() {
      addLoading = true;
    });

    try {
      var uri = Uri.parse('https://hrsps.com/login/api/stories/upload');

      var request = http.MultipartRequest('POST', uri);

      request.fields['caption'] = _nameController.text;

      request.fields['restaurant_id'] = widget.restaurantId.toString();
      request.fields['media_type'] = mediaType;

      for (int i = 0; i < _media.length; i++) {
        print("------------");
        var filePath = _media[i].path;
        var multipartFile = await http.MultipartFile.fromPath('media', filePath,
            contentType: mediaType == "video"
                ? MediaType('video', 'mp4')
                : MediaType('image', 'jpeg'));
        request.files.add(multipartFile);
        print("File exists: ${File(filePath).existsSync()}");
        print("File path: $filePath");
      }

      print('Request Fields:');
      print(request.fields);

      var response = await request.send();
      print(response.statusCode);
      var responseBody = await response.stream.bytesToString();
      print('Response Body: $responseBody');
      if (response.statusCode == 200 || response.statusCode == 201) {
        Fluttertoast.showToast(msg: 'تم الاضافة');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => RestaurantPage(
                  storeId: widget.restaurantId,
                  userId: widget.userId,
                  categoryId: widget.categoryId,
                  status: widget.status,
                  restaurantName: widget.restaurantName,
                  storeCloseTime: widget.storeCloseTime,
                  storeOpenTime: widget.storeOpenTime,
                  restaurantImage: widget.restaurantImage,
                  restaurantAddress: widget.restaurantAddress,
                  deliveryPrice: widget.deliveryPrice)),
          (route) => false,
        );
      } else {
        var responseBody = await response.stream.bytesToString();
        var errorData = jsonDecode(responseBody);
        if (response.statusCode == 422) {
          List errors = errorData['errors'];
          for (var error in errors) {
            if (error['field'] == "name") {
              setState(() {
                nameField = true;
              });
            }
            if (error['field'] == "image") {
              setState(() {
                photoField = true;
              });
              if (error['message'] ==
                  "The image.0 must not be greater than 2048 kilobytes.") {
                Fluttertoast.showToast(
                    msg: "يجب ان تكون الصورة اقل من ٢ ميغا",
                    timeInSecForIosWeb: 4);
              }
            }
          }
        }
        if (errorData["error"] == "Invalid argument supplied for foreach()") {
          setState(() {
            photoField = true;
          });
        }
        print('Failed to submit form: ${response.reasonPhrase}');
        print('Response: $response');
        Fluttertoast.showToast(msg: 'حدث خطأ أثناء إرسال البيانات');
      }
    } catch (e) {
      print('Error: $e');
      Fluttertoast.showToast(msg: 'حدث خطأ أثناء إرسال البيانات');
    } finally {
      setState(() {
        addLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: fourthColor,
      child: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Scaffold(
            backgroundColor: fourthColor,
            body: Padding(
              padding: const EdgeInsets.only(right: 8.0, left: 8, top: 25),
              child: Container(
                height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                top: 20, right: 15, left: 15),
                            child: Text(
                              'اضافة قصة جديدة ',
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                  fontSize: 18,
                                  color: mainColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        nameWidget(),
                        SizedBox(
                          height: 10,
                        ),
                        mediaWidget(),
                        SizedBox(
                          height: 20,
                        ),
                        buttonWidget(),
                        SizedBox(
                          height: 20,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget nameWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8), color: Color(0xffF8F8F8)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "*",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor2),
                        ),
                        SizedBox(
                          width: 2,
                        ),
                        Text(
                          "الكابشن",
                          style: TextStyle(
                              fontSize: 12,
                              color: textColor2,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                      return Container(
                        height: 30,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12)),
                        child: TextFormField(
                          controller: _nameController,
                          obscureText: false,
                          onTap: () {
                            setState(() {
                              nameField = false;
                            });
                          },
                          decoration: InputDecoration(
                            hintStyle: TextStyle(
                                fontSize: 12, color: Color(0xffB1B1B1)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: mainColor, width: 1.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  width: 1.0,
                                  color: !nameField
                                      ? Color(0xffD6D3D3)
                                      : Colors.red,
                                )),
                            hintText: "ادخل الكابشن",
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              SizedBox(
                width: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget mediaWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8), color: Color(0xffF8F8F8)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "*",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor2),
                  ),
                  SizedBox(
                    width: 2,
                  ),
                  Text(
                    "اضافة صورة او فيديو",
                    style: TextStyle(
                        fontSize: 12,
                        color: textColor2,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              DottedBorder(
                strokeWidth: 1,
                dashPattern: [6, 3],
                color: photoField ? Colors.red : Colors.black,
                borderType: BorderType.RRect,
                radius: Radius.circular(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    height: 350,
                    decoration: BoxDecoration(color: Colors.white),
                    child: _media.isEmpty
                        ? InkWell(
                            onTap: _pickMedia,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  "assets/images/add-image.png",
                                  width: 60,
                                  height: 60,
                                ),
                                SizedBox(height: 5),
                                Text(
                                  "اضافة صورة / فيديو",
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(
                                child: mediaType == "image"
                                    ? Image.file(
                                        File(_media[0].path),
                                        fit: BoxFit.cover,
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: VideoPlayerWidget(
                                          file: File(_media[0].path),
                                        ),
                                      ),
                              ),
                              Positioned(
                                left: 0,
                                top: 0,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _media = [];
                                    });
                                  },
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      color: fourthColor,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "x",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buttonWidget() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 5),
        child: MaterialButton(
          onPressed: () {
            if (_nameController.text.isEmpty || _media.isEmpty) {
              if (_nameController.text.isEmpty) {
                setState(() {
                  nameField = true;
                });
              }
              if (_media.isEmpty) {
                setState(() {
                  photoField = true;
                });
              }

              Fluttertoast.showToast(
                  msg: "الرجاء تعبئة الحقول المطلوبة", timeInSecForIosWeb: 3);
            } else {
              _submitForm();
            }
          },
          child: addLoading
              ? Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : Text(
                  'اضافه قصة جديدة',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: mainColor,
        ),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final File file;
  const VideoPlayerWidget({required this.file});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          )
        : Center(child: CircularProgressIndicator());
  }
}
