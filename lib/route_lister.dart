import 'package:flutter/material.dart';

class RouteLister extends StatelessWidget {
  final List<Map<String, dynamic>> orderedCoords;

  const RouteLister(
      {super.key,
      required this.orderedCoords,
      required ScrollController? scrollController});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center, // Listeyi yatayda ortalıyoruz
      child: Container(
        width:
            MediaQuery.of(context).size.width * 0.65, 
        height: MediaQuery.of(context).size.height * 0.6 -
            MediaQuery.of(context).size.height *
                0.2, 
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(
                color: Colors.purple, width: 3), 
            left: BorderSide(
                color: Colors.purple, width: 3), 
            right: BorderSide(
                color: Colors.purple, width: 3),
          ),
          borderRadius: BorderRadius.circular(15), 
        ),
        child: SingleChildScrollView(
          child: Column(
            children: orderedCoords.map((location) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text(
                    location['name'] ?? "Konum Yok",
                    textAlign: TextAlign.center, 
                  ),
                  subtitle: Text(
                    "ID: ${location['coord_id']}, "
                    "Order: ${location['order']}, "
                    "Lat: ${location['latitude']}, "
                    "Lon: ${location['longitude']}",
                    textAlign:
                        TextAlign.center, 
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
