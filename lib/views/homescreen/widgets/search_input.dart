import 'package:flutter/material.dart';

class SearchInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback onFilterTap;

  const SearchInput({
    Key? key,
    required this.controller,
    this.onChanged,
    required this.onFilterTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onFilterTap,
            child: Image.asset(
              "assets/images/filter2.png",
              width: 40,
              height: 40,
            ),
          ),
          SizedBox(width: 5),
          Expanded(
            child: Card(
              elevation: 3,
              shadowColor: Color(0xffEFEFEF),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'ابحث عن الوجبة او المطعم',
                  hintStyle: TextStyle(
                    color: Color(0xffEFEFEF),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Color(0xffEFEFEF),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.transparent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
