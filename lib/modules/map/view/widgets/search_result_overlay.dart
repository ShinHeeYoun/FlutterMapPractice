import 'package:flutter/material.dart';
import '../../model/place_model.dart';

class SearchResultOverlay extends StatelessWidget {
  final bool isSearching;
  final bool hasSearched;
  final List<PlaceModel> searchResults;
  final Function(PlaceModel) onPlaceSelected;

  const SearchResultOverlay({
    super.key,
    required this.isSearching,
    required this.hasSearched,
    required this.searchResults,
    required this.onPlaceSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasSearched && !isSearching) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8.0),
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (isSearching) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    if (searchResults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            '검색 결과가 없습니다',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: searchResults.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final place = searchResults[index];

        return ListTile(
          title: Text(
            place.placeName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(place.addressName),
          trailing: place.distanceText.isNotEmpty
              ? Text(
                  place.distanceText,
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : null,
          onTap: () => onPlaceSelected(place),
        );
      },
    );
  }
}
