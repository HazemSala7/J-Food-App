import 'dart:convert';

import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:j_food_updated/constants/constants.dart';

class HomeOrderDetailsScreen extends StatefulWidget {
  final int orderId;
  final String status;
  final String checkoutType;

  const HomeOrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.status,
    required this.checkoutType,
  });

  @override
  State<HomeOrderDetailsScreen> createState() => _HomeOrderDetailsScreenState();
}

class _HomeOrderDetailsScreenState extends State<HomeOrderDetailsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? order;
  bool isLoading = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _fetchOrderDetails();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrderDetails() async {
    final url = Uri.parse(
      'https://hrsps.com/login/api/show-order-data/${widget.orderId}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseMap = json.decode(response.body);
        setState(() {
          order = responseMap['order'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _statusText(String status, String checkoutType) {
    switch (status) {
      case 'pending':
        return 'قيد المعالجة';
      case 'in_progress':
        return 'قيد التجهيز';
      case 'ready_for_delivery':
        return checkoutType == 'pickup' ? 'جاهز للاستلام' : 'جاهز للتوصيل';
      case 'in_delivery':
        return checkoutType == 'pickup' ? 'تم الاستلام' : 'في التوصيل';
      case 'delivered':
        return 'تم التوصيل';
      case 'canceled':
        return 'تم إلغاؤه';
      default:
        return 'غير معروف';
    }
  }

  IconData _statusIcon(String status, String checkoutType) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'in_progress':
        return Icons.restaurant_rounded;
      case 'ready_for_delivery':
        return checkoutType == 'pickup'
            ? Icons.storefront_rounded
            : Icons.check_circle_outline_rounded;
      case 'in_delivery':
        return checkoutType == 'pickup'
            ? Icons.shopping_bag_rounded
            : Icons.delivery_dining_rounded;
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'canceled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _checkoutTypeText(String checkoutType) {
    return checkoutType == 'pickup' ? 'استلام من المطعم' : 'توصيل';
  }

  int _getStatusStep(String status) {
    switch (status) {
      case 'pending':
        return 0;
      case 'in_progress':
        return 1;
      case 'ready_for_delivery':
        return 2;
      case 'in_delivery':
        return 3;
      case 'delivered':
        return 4;
      default:
        return 0;
    }
  }

  List<_StepInfo> _getSteps(String checkoutType) {
    return [
      _StepInfo('قيد المعالجة', Icons.hourglass_top_rounded),
      _StepInfo('قيد التجهيز', Icons.restaurant_rounded),
      _StepInfo(
        checkoutType == 'pickup' ? 'جاهز للاستلام' : 'جاهز للتوصيل',
        checkoutType == 'pickup'
            ? Icons.storefront_rounded
            : Icons.check_circle_outline_rounded,
      ),
      _StepInfo(
        checkoutType == 'pickup' ? 'تم الاستلام' : 'في التوصيل',
        checkoutType == 'pickup'
            ? Icons.shopping_bag_rounded
            : Icons.delivery_dining_rounded,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStatus = (order?['status'] ?? widget.status).toString();
    final effectiveCheckoutType =
        (order?['checkout_type'] ?? widget.checkoutType).toString();

    return Scaffold(
      backgroundColor: const Color(0xffF5F5F7),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: mainColor),
            )
          : order == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 48, color: mainColor.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'تعذر تحميل الطلب',
                        style: TextStyle(
                          color: thirdColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    _buildGradientHeader(
                      effectiveStatus,
                      effectiveCheckoutType,
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: Column(
                          children: [
                            // Status stepper overlapping the header
                            Transform.translate(
                              offset: const Offset(0, -24),
                              child: _buildStatusStepper(
                                effectiveStatus,
                                effectiveCheckoutType,
                              ),
                            ),
                            _buildRestaurantCard(),
                            const SizedBox(height: 14),
                            _buildSummaryCard(
                                checkoutType: effectiveCheckoutType),
                            const SizedBox(height: 14),
                            _buildItemsCard(),
                            if ((order?['notes'] ?? '')
                                .toString()
                                .trim()
                                .isNotEmpty) ...[
                              const SizedBox(height: 14),
                              _buildNotesCard(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildGradientHeader(String status, String checkoutType) {
    final restaurant = (order?['restaurant'] as Map<String, dynamic>?) ?? {};
    final String orderNumber = (order?['id'] ?? '').toString();

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: mainColor,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_forward_ios,
              color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'تفاصيل الطلب',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                mainColor,
                mainColor.withOpacity(0.88),
                const Color(0xffB83634),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: 40,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
              Positioned(
                right: 60,
                bottom: 50,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 110, 20, 60),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: FancyShimmerImage(
                                imageUrl:
                                    (restaurant['image'] ?? '').toString(),
                                width: 52,
                                height: 52,
                                errorWidget: Image.asset(
                                  'assets/images/logo2.png',
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (restaurant['name'] ?? 'المطعم').toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'طلب #$orderNumber',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusStepper(String status, String checkoutType) {
    final int currentStep = _getStatusStep(status);
    final List<_StepInfo> steps = _getSteps(checkoutType);
    final bool isCanceled = status == 'canceled';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: isCanceled
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel_rounded, color: Colors.red[400], size: 24),
                const SizedBox(width: 8),
                Text(
                  'تم إلغاء الطلب',
                  style: TextStyle(
                    color: Colors.red[400],
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Row(
                  children: List.generate(steps.length * 2 - 1, (index) {
                    if (index.isOdd) {
                      // Connector line
                      final int stepBefore = index ~/ 2;
                      final bool active = stepBefore < currentStep;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: active
                                  ? mainColor
                                  : const Color(0xffE0E0E0),
                            ),
                          ),
                        ),
                      );
                    } else {
                      // Step circle
                      final int stepIndex = index ~/ 2;
                      final bool active = stepIndex <= currentStep;
                      final bool isCurrent = stepIndex == currentStep;
                      return AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final double scale = isCurrent
                              ? 1.0 + (_pulseController.value * 0.1)
                              : 1.0;
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: active
                                    ? mainColor
                                    : Colors.white,
                                border: Border.all(
                                  color: active
                                      ? mainColor
                                      : const Color(0xffD0D0D0),
                                  width: active ? 0 : 1.5,
                                ),
                                boxShadow: isCurrent
                                    ? [
                                        BoxShadow(
                                          color: mainColor.withOpacity(0.35),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Icon(
                                steps[stepIndex].icon,
                                size: 19,
                                color: active
                                    ? Colors.white
                                    : const Color(0xff999999),
                              ),
                            ),
                          );
                        },
                      );
                    }
                  }),
                ),
                const SizedBox(height: 10),
                // Status labels under each step
                Row(
                  children: steps.asMap().entries.map((entry) {
                    final int stepIndex = entry.key;
                    final bool active = stepIndex <= currentStep;
                    return Expanded(
                      child: Text(
                        entry.value.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w600,
                          color: active ? mainColor : const Color(0xff888888),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }

  Widget _buildRestaurantCard() {
    final restaurant = (order?['restaurant'] as Map<String, dynamic>?) ?? {};
    final String address = (restaurant['address'] ?? '').toString();

    if (address.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.location_on_rounded, color: mainColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'عنوان المطعم',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: thirdColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff2D2D2D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({required String checkoutType}) {
    final String orderDate = (order?['updated_at'] ?? '').toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: mainColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.receipt_long_rounded,
                    color: mainColor, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'ملخص الطلب',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                  color: Color(0xff2D2D2D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _summaryRow(
            'رقم الطلب',
            '#${(order?['id'] ?? '').toString()}',
            Icons.tag_rounded,
          ),
          _buildDivider(),
          _summaryRow(
            'عدد الأصناف',
            (order?['items_length'] ?? 0).toString(),
            Icons.shopping_basket_rounded,
          ),
          _buildDivider(),
          _summaryRow(
            'طريقة الاستلام',
            _checkoutTypeText(checkoutType),
            checkoutType == 'pickup'
                ? Icons.storefront_rounded
                : Icons.delivery_dining_rounded,
          ),
          _buildDivider(),
          _summaryTotalRow(
            'المجموع',
            '${(order?['total'] ?? 0).toString()} ₪',
          ),
          if (orderDate.isNotEmpty) ...[
            _buildDivider(),
            _summaryRow(
              'آخر تحديث',
              orderDate.contains('T')
                  ? orderDate.split('T').first
                  : orderDate,
              Icons.access_time_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(
        height: 1,
        color: const Color(0xffE8E8E8).withOpacity(0.8),
      ),
    );
  }

  Widget _summaryRow(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: thirdColor.withOpacity(0.5)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: thirdColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xff2D2D2D),
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _summaryTotalRow(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: mainColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.payments_rounded, size: 18, color: mainColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: mainColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: mainColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    final List<dynamic> items =
        (order?['order_details'] as List<dynamic>?) ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: mainColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.fastfood_rounded,
                    color: mainColor, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'المنتجات',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                  color: Color(0xff2D2D2D),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: mainColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${items.length} صنف',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: mainColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'لا توجد منتجات',
                  style: TextStyle(
                      color: thirdColor, fontWeight: FontWeight.w600),
                ),
              ),
            )
          else
            ListView.separated(
              itemCount: items.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index] as Map<String, dynamic>;
                final product =
                    (item['product'] as Map<String, dynamic>?) ??
                    <String, dynamic>{};

                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xffF9F9FB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: const Color(0xffE8E8E8),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: mainColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          (product['name'] ?? 'منتج').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: Color(0xff2D2D2D),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: mainColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'x${(item['qty'] ?? 1).toString()}',
                          style: TextStyle(
                            color: mainColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xffFFF3CD),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.sticky_note_2_rounded,
                    color: Color(0xffE6A817), size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'ملاحظات الطلب',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                  color: Color(0xff2D2D2D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xffFFFBF0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xffE6A817).withOpacity(0.2)),
            ),
            child: Text(
              (order?['notes'] ?? '').toString(),
              style: TextStyle(
                color: thirdColor,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepInfo {
  final String label;
  final IconData icon;
  _StepInfo(this.label, this.icon);
}
