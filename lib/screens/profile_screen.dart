import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  SizedBox(height: 12),
                  Text('Nguyễn Văn Khách', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Du khách tự túc', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  ProfileMenuTile(icon: Icons.edit, title: 'Chỉnh sửa thông tin cá nhân', onTap: () {}),
                  ProfileMenuTile(icon: Icons.favorite, title: 'Địa điểm ưa thích', onTap: () {}),
                  ProfileMenuTile(icon: Icons.palette, title: 'Giao diện (Sáng / Tối)', onTap: () {}),
                  ProfileMenuTile(icon: Icons.info, title: 'Về ứng dụng (About)', onTap: () {}),
                  const Divider(),
                  ProfileMenuTile(icon: Icons.logout, title: 'Đăng xuất tài khoản', color: Colors.red, onTap: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final VoidCallback onTap;

  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.teal),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}