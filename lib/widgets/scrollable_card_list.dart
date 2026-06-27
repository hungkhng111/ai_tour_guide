import 'package:flutter/material.dart';
import 'product_card.dart';
import '../models/place_model.dart';

class ScrollableCardsList extends StatefulWidget {
  final List<PlaceModel> items;
  const ScrollableCardsList({super.key, required this.items});

  @override
  State<ScrollableCardsList> createState() => _ScrollableCardsListState();
}

class _ScrollableCardsListState extends State<ScrollableCardsList> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftArrow = false;
  bool _showRightArrow = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScrollPosition);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollPosition());
  }

  void _checkScrollPosition() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;

    setState(() {
      _showLeftArrow = current > 5 && maxScroll > 0;
      _showRightArrow = current < (maxScroll - 5) && maxScroll > 0;
    });
  }

  void _scrollForward() {
    final target = _scrollController.offset + 172;
    _scrollController.animateTo(
      target > _scrollController.position.maxScrollExtent ? _scrollController.position.maxScrollExtent : target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollBackward() {
    final target = _scrollController.offset - 172;
    _scrollController.animateTo(
      target < 0 ? 0 : target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkScrollPosition);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 220,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final data = widget.items[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ProductCard(
                  title: data.title,
                  rating: data.rating,
                  tags: data.tags,
                  imageUrl: data.imageUrl,
                ),
              );
            },
          ),
        ),

        if (_showLeftArrow)
          Positioned(
            left: 8,
            top: 75,
            child: _buildArrowButton(Icons.arrow_back_ios_new, _scrollBackward),
          ),

        if (_showRightArrow)
          Positioned(
            right: 8,
            top: 75,
            child: _buildArrowButton(Icons.arrow_forward_ios, _scrollForward),
          ),
      ],
    );
  }

  Widget _buildArrowButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 2)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.teal, size: 18),
        onPressed: onPressed,
      ),
    );
  }
}