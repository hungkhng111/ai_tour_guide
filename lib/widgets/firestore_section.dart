import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../repositories/place_repository.dart';
import '../widgets/scrollable_card_list.dart';

class FirestoreSection extends StatelessWidget {
  final String title;
  final String collectionName;
  final String errorMessage;

  const FirestoreSection({
    super.key,
    required this.title,
    required this.collectionName,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<PlaceModel>>(
          future: PlaceRepository.getPlaces(collectionName),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(errorMessage, style: const TextStyle(color: Colors.red)),
              );
            }
            final items = snapshot.data ?? [];
            return ScrollableCardsList(items: items);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}