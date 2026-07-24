import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../screens/place_detail_screen.dart';

class VerticalPlaceCard extends StatelessWidget {
  final PlaceModel place;

  const VerticalPlaceCard({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    // 🛠️ THAY ĐỔI: Lấy tấm ảnh đầu tiên làm Thumbnail thay vì ngẫu nhiên
    final thumbnailImage = place.imgPaths.isNotEmpty 
        ? place.imgPaths.first 
        : 'assets/images/placeholder.png'; // Ảnh dự phòng nếu danh sách rỗng

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PlaceDetailScreen(place: place)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), 
              blurRadius: 10, 
              offset: const Offset(0, 4)
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. THUMBNAIL
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  thumbnailImage, // 🛠️ Gắn biến thumbnail vào đây
                  height: 140, 
                  width: double.infinity,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  loadingBuilder: (content, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      height: 140,
                      child: Center(child: CircularProgressIndicator(color: Colors.redAccent,)),
                    );
                  },

                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    height: 140,
                    child: Center(child: Icon(Icons.broken_image, size:40, color: Colors.grey)),
                  ),
                ),
              ),
            ),
            
            // 2. NỘI DUNG THÔNG TIN
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE - SUBTITLE 
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50)
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // DESCRIPTION 
                  Text(
                    place.shortDes,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  
                  // ĐỊA CHỈ & GIÁ TIỀN 
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Address
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                place.location,
                                style: const TextStyle(color: Colors.grey, height: 1.2),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Price 
                      // Container(
                      //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      //   decoration: BoxDecoration(
                      //     color: Colors.transparent,
                      //     borderRadius: BorderRadius.circular(20),
                      //     border: Border.all(color: Colors.black87, width: 1), 
                      //   ),
                      //   child: Text(
                      //     place.price,
                      //     style: const TextStyle(
                      //       color: Colors.black87, 
                      //       fontWeight: FontWeight.bold
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}