import 'package:flutter/material.dart';
import '../widgets/firestore_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tour Guide', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal.withValues(alpha: 0.1),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vị trí & Thời tiết
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1534088568595-a066f410bcda?q=80&w=600&auto=format&fit=crop',
                  ),
                  fit: BoxFit.cover,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text('VỊ TRÍ CỦA TÔI', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                  SizedBox(height: 4),
                  Text('Thành Phố Hồ Chí Minh', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w500)),
                  SizedBox(height: 2),
                  Text('34°', style: TextStyle(color: Colors.white, fontSize: 76, fontWeight: FontWeight.w200, height: 1.1)),
                  SizedBox(height: 2),
                  Text('Có mây', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                  SizedBox(height: 4),
                  Text('C:35°  T:27°', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),

            const FirestoreSection(
              title: 'Hoạt động nổi bật',
              collectionName: 'activities',
              errorMessage: 'Không thể tải dữ liệu hoạt động.',
            ),

            const FirestoreSection(
              title: 'Địa điểm thu hút',
              collectionName: 'attractions',
              errorMessage: 'Không thể tải dữ liệu địa điểm.',
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}