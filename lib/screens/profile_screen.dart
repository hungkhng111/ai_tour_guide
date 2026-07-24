import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../screens/detail_profile_screen.dart';
import '../screens/fav_place_screen.dart';
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ của tôi'),
        centerTitle: true,
      ),
      body: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final session = snapshot.hasData ? snapshot.data!.session : null;
          final isLoggedIn = session != null;

          // TRÁO ĐỔI GIAO DIỆN DỰA VÀO TRẠNG THÁI ĐĂNG NHẬP
          return isLoggedIn 
              ? _buildAuthenticatedUI(context, session.user) 
              : _buildUnauthenticatedUI();
        },
      ),
    );
  }

  // Giao dien chua dang nhap
  Widget _buildUnauthenticatedUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_circle, size: 100, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            const Text(
              'Chưa đăng nhập',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đăng nhập đi bạn...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => AuthService().signInWithGoogle(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              icon: const Icon(Icons.login),
              label: const Text('Đăng nhập bằng Google', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  // Giao dien da dang nhap su dung realtime streambuider
  Widget _buildAuthenticatedUI(BuildContext context, User user) {
    // 🟢 BỌC BẰNG STREAMBUILDER ĐỂ LẮNG NGHE BẢNG PROFILES THỜI GIAN THỰC
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('id', user.id),
      builder: (context, snapshot) {
        // 1. Trạng thái chờ dữ liệu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.teal));
        }

        // 2. Rút trích dữ liệu từ Snapshot (bảng profiles) thay vì Google
        final profileData = (snapshot.hasData && snapshot.data!.isNotEmpty) 
            ? snapshot.data!.first 
            : {};

        final avatarUrl = profileData['avatar_url'] as String?;
        final fullName = profileData['full_name'] as String? ?? 'Khách vô danh';
        final email = user.email ?? 'Chưa cập nhật email';

        // 3. Hiển thị Giao diện (Giữ nguyên thiết kế cũ của bạn)
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // THẺ THÔNG TIN CÁ NHÂN
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.teal.shade100,
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null 
                          ? const Icon(Icons.person, size: 40, color: Colors.teal) 
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mừng bạn trở lại $fullName',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // DANH SÁCH TÍNH NĂNG (MOCKUP)
            _buildListTile(
              context,
              Icons.person_pin_rounded,
              'Thông tin cá nhân',
              'Hãy là chính mình',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileDetailScreen()),
                );
              },
            ),        
            _buildListTile(
              context,
              Icons.settings,
              'Cài đặt ứng dụng',
              'Tùy chỉnh giao diện theo ý bạn',
              onTap:() {
                Navigator.push(
                  context,
                  // Change to another screen
                  MaterialPageRoute(builder: (context) => const ProfileDetailScreen()),              
                );
              },
            ),
            _buildListTile(
              context,
              Icons.favorite_border,
              'Địa điểm yêu thích',
              'Quán ruột của bạn',
              onTap:() {
                Navigator.push(
                  context,
                  // Change to another screen
                  MaterialPageRoute(builder: (context) => const FavoritePlacesScreen()),              
                );
              },
            ),
            _buildListTile(
              context,
              Icons.info_outline,
              'Về ứng dụng',
              'Phiên bản 1.0.0 (Prototype)',
              onTap:() {
                Navigator.push(
                  context,
                  // Change to another screen
                  MaterialPageRoute(builder: (context) => const ProfileDetailScreen()),              
                );
              },
            ),                

            const SizedBox(height: 32),

            // NÚT ĐĂNG XUẤT
            OutlinedButton.icon(
              onPressed: () => AuthService().signOut(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  // Hàm tiện ích để vẽ các dòng menu
  Widget _buildListTile(BuildContext context, IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.teal),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}