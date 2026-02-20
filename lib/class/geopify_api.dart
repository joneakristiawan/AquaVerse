import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationCard extends StatelessWidget {
  final VoidCallback? onDiveNow;
  const LocationCard({super.key, this.onDiveNow});

  @override
  Widget build(BuildContext context) {
    const String geoapifyKey = "34dcc910df0748b9a7eca66e295c9b83"; 
    final centerPoint = const LatLng(-6.588602071286718, 106.88239683534755);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE3F2FD), 
            Color(0xFF29B6F6), 
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER: Lokasi
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: const [
                Icon(Icons.location_on, color: Color(0xFF2C3E50), size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Lokasi: Wilayah Perairan Jawa",
                    style: TextStyle(
                      fontFamily: "Montserrat",
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // INTERACTIVE MAP PAKE FLUTTER_MAP & HERO ANIMATION
          Container(
            height: 150,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                ),
              ],
            ),
            // HERO WIDGET
            child: Hero(
              tag: 'map-animation-tag', // Tag ini harus sama persis di kedua halaman
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: centerPoint,
                        initialZoom: 5.0, 
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate, 
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: "https://maps.geoapify.com/v1/tile/osm-carto/{z}/{x}/{y}.png?apiKey=$geoapifyKey",
                          userAgentPackageName: 'com.aquaverse.app', 
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: centerPoint,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    // TOMBOL FULLSCREEN DI POJOK KANAN ATAS
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            )
                          ]
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: IconButton(
                            icon: const Icon(Icons.fullscreen, color: Colors.black87),
                            onPressed: () {
                              // Navigasi dengan animasi default yang disetir Hero
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullScreenMapPage(
                                    centerPoint: centerPoint,
                                    geoapifyKey: geoapifyKey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // DESCRIPTION
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "Laut yang mengelilingi Pulau Jawa di utara, Samudra Hindia di selatan, Selat Sunda di barat, dan Selat Bali serta Madura di timur.",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF455A64),
                height: 1.4,
              ),
            ),
          ),

          // BUTTON: SELAM SEKARANG
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onDiveNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 205, 239, 255), 
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Selam Sekarang",
                  style: TextStyle(
                    fontSize: 20,
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.bold,
                    fontFamily: "Montserrat",
                  ),
                ),
              ),
            ),
          ),

          // STATS
          const Padding(
            padding: EdgeInsets.all(10),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// HALAMAN PETA FULLSCREEN
// ==========================================
class FullScreenMapPage extends StatelessWidget {
  final LatLng centerPoint;
  final String geoapifyKey;

  const FullScreenMapPage({
    super.key,
    required this.centerPoint,
    required this.geoapifyKey,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Hero(
            tag: 'map-animation-tag', 
            child: FlutterMap(
              options: MapOptions(
                initialCenter: centerPoint,
                initialZoom: 6.0, 
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate, 
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://maps.geoapify.com/v1/tile/osm-carto/{z}/{x}/{y}.png?apiKey=$geoapifyKey",
                  userAgentPackageName: 'com.aquaverse.app', 
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: centerPoint,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 50, 
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // TOMBOL BACK NGAMBANG DI KIRI ATAS
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black87, size: 28),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}