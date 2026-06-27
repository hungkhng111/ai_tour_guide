import 'package:flutter/material.dart';
// 📦 Import các thư viện cốt lõi của Firebase đám mây
import 'package:firebase_core/firebase_core.dart';
// 🛠️ Import file cấu hình tự động tạo ra bởi FlutterFire CLI
import 'firebase_options.dart';
// 🗂️ Import cấu trúc dữ liệu Model mà chúng ta đã tách ra file riêng
import 'screens/ai_chat_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
// Ham main - Diem khoi chay dau tien va bat buoc cua ung dung flutter
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const AITourGuideApp());
}

// Class goc (Root Widget) cau hinh nen tang cho ung dung
// Thiet lap Ten ung dung, mau sac va thiet lap giao dien dau tien khi mo app
class AITourGuideApp extends StatelessWidget {
  const AITourGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Tour Guide',
      debugShowCheckedModeBanner: false, // An dong chu Debug trong ung dung
      theme: ThemeData(
        // Cau hinh bang mau chu dao (Teal lam mau goc)
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          primary: Colors.teal,
          secondary: Colors.amber,
        ),
        useMaterial3: true,
      ),
      home: const MainNavigationShell(), // Chi dinh man hinh chinh khi mo app len
    );
  }
}

// Khung dieu huong chinh (Shell) chua thanh Menu ben duoi (Bottom Navigation Bar)
// Class nay quan ly viec fixed thanh Menu ben duoi va thay doi man hinh phia tren
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}
// Noi xu ly logic va trang thai state cua thanh menu dieu huong
class _MainNavigationShellState extends State<MainNavigationShell> {
  // Bien luu tru vi tri hien tai trong Navbar [0: trang chu, 1: ai chat, 2: profile]
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AIChatScreen(),
    const ProfileScreen(),
  ];

  static const List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Khám phá'),
    BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'AI Chat'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              selectedItemColor: Colors.teal,
              unselectedItemColor: Colors.grey,
              items: _navItems,
            ),
    );
  } // build
}
