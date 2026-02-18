import 'package:flutter/material.dart';

class LocationCard extends StatelessWidget {
  final VoidCallback? onDiveNow;
  const LocationCard({super.key, this.onDiveNow});

  @override
  Widget build(BuildContext context) {
    const String googleApiKey = "YOUR_GOOGLE_MAPS_API_KEY";
    
    // Koordinat Jawa (Center)
    const double lat = -7.1;
    const double lng = 110.0;
    
    const String mapUrl = 
      "https://maps.googleapis.com/maps/api/staticmap?"
      "center=$lat,$lng"
      "&zoom=5"
      "&size=600x300"
      "&maptype=roadmap"
      "&markers=color:red%7Clabel:A%7C$lat,$lng"
      "&key=$googleApiKey";

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

          // IMAGE MAPS
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.network(
                mapUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.map_outlined, size: 40, color: Colors.grey),
                        SizedBox(height: 5),
                        Text(
                          "Peta Memuat...", 
                          style: TextStyle(color: Colors.grey, fontSize: 12)
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // DESCRIPTION
          Padding(
            padding: const EdgeInsets.all(20),
            child: const Text(
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
                onPressed: onDiveNow, // Callback dipanggil di sini
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
          Padding(
            padding: const EdgeInsets.all(10),
          ),
        ],
      ),
    );
  }
}