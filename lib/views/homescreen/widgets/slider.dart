import 'dart:ui';
import 'package:j_food_updated/constants/constants.dart';
import 'package:j_food_updated/models/slider_model.dart';
import 'package:j_food_updated/server/functions/functions.dart';
import 'package:j_food_updated/views/storescreen/store_provider/store_provider.dart';
import 'package:j_food_updated/views/storescreen/store_screen.dart';
import 'package:flutter/material.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:j_food_updated/stubs/fluttertoast_stub.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class StackedSlider extends StatefulWidget {
  final List<SliderClass> sliders;
  final bool noDelivery;
  final Function(int) changeTab;
  StackedSlider(
      {required this.sliders,
      required this.noDelivery,
      required this.changeTab});

  @override
  _StackedSliderState createState() => _StackedSliderState();
}

class _StackedSliderState extends State<StackedSlider> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.sliders.isEmpty)
          const Center(
            child: Text(
              'No images available',
              style: TextStyle(fontSize: 16),
            ),
          )
        else
          CarouselSlider.builder(
            carouselController: _carouselController,
            itemCount: widget.sliders.length,
            itemBuilder: (context, index, realIndex) {
              final slider = widget.sliders[index];

              return GestureDetector(
                onTap: () async {
                  if (slider.type == "link" && slider.link != null) {
                    final Uri uri = Uri.parse(slider.link!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    } else {
                      Fluttertoast.showToast(msg: "لا يمكن فتح الرابط");
                    }
                  } else if (slider.data != null) {
                    NavigatorFunction(
                        context,
                        ChangeNotifierProvider(
                          create: (_) => StoreProvider()
                            ..fetchStoreDetails(slider.data!.id.toString()),
                          child: StoreScreen(
                            open: slider.data!.active,
                            store_cover_image: slider.data!.coverImage,
                            store_address: slider.data!.address,
                            store_id: slider.data!.id.toString(),
                            category_id: slider.data!.categoryId,
                            category_name: "",
                            store_image: slider.data!.image,
                            store_name: slider.data!.name,
                            noDelivery: widget.noDelivery,
                            changeTab: widget.changeTab,
                          ),
                        ));
                  } else {
                    Fluttertoast.showToast(msg: "لا توجد بيانات لهذا المتجر");
                  }
                },
                child: _buildStackedItem(widget.sliders, index),
              );
            },
            options: CarouselOptions(
              height: MediaQuery.of(context).size.height * 0.25,
              enlargeCenterPage: true,
              viewportFraction: 0.8,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        const SizedBox(height: 10),
        if (widget.sliders.isNotEmpty) _buildDotIndicator(),
      ],
    );
  }

  Widget _buildStackedItem(List<SliderClass> sliders, int index) {
    final isCurrentIndex = index == _currentIndex;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FancyShimmerImage(
            imageUrl: sliders[index].url,
            boxFit: BoxFit.fill,
            shimmerBaseColor: Colors.grey[300]!,
            shimmerHighlightColor: Colors.grey[100]!,
          ),
          if (!isCurrentIndex)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.sliders.asMap().entries.map((entry) {
        return GestureDetector(
          onTap: () => _carouselController.animateToPage(entry.key),
          child: Container(
            width: _currentIndex == entry.key ? 16 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _currentIndex == entry.key
                  ? secondColor
                  : const Color(0xffFFC509),
            ),
          ),
        );
      }).toList(),
    );
  }
}
