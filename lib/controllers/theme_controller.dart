import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  var isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadTheme(); // Tải trạng thái đã lưu khi controller được khởi tạo
  }

  void toggleTheme(bool isDark) async {
    isDarkMode.value = isDark;
    
    // GetX hỗ trợ đổi theme trực tiếp rất tiện lợi
    Get.changeThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
    
    // Lưu lại lựa chọn của người dùng
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', isDark);
  }

  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool('isDarkMode') ?? false;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }
}