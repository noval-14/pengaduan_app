import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationPickerOSM extends StatefulWidget {
  const LocationPickerOSM({super.key});

  @override
  State<LocationPickerOSM> createState() => _LocationPickerOSMState();
}

class _LocationPickerOSMState extends State<LocationPickerOSM> {
  LatLng currentLatLng = LatLng(-6.200000, 106.816666);

  String address = "Ambil lokasi...";

  final mapController = MapController();

  Future<void> getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("GPS belum aktif"),
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Izin lokasi ditolak permanen",
            ),
          ),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String lokasiText = "Lokasi tidak ditemukan";

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        lokasiText = "${placemarks.first.street}, ${placemarks.first.locality}";
      } catch (e) {
        debugPrint("ERROR GEOCODING: $e");
      }

      setState(() {
        currentLatLng = LatLng(
          position.latitude,
          position.longitude,
        );

        address = lokasiText;
      });

      mapController.move(currentLatLng, 16);
    } catch (e) {
      debugPrint("ERROR LOCATION: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Gagal mengambil lokasi",
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pilih Lokasi")),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Text(address),
          ),
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: currentLatLng,
                initialZoom: 14,
                onTap: (tapPosition, point) async {
                  try {
                    String lokasiText = "Lokasi dipilih";

                    try {
                      List<Placemark> placemarks =
                          await placemarkFromCoordinates(
                        point.latitude,
                        point.longitude,
                      );

                      lokasiText =
                          "${placemarks.first.street}, ${placemarks.first.locality}";
                    } catch (e) {
                      debugPrint("ERROR GEOCODING TAP: $e");
                    }

                    setState(() {
                      currentLatLng = point;
                      address = lokasiText;
                    });
                  } catch (e) {
                    debugPrint(e.toString());
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.pengaduan.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentLatLng,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  "lat": currentLatLng.latitude,
                  "lng": currentLatLng.longitude,
                  "address": address,
                });
              },
              child: const Text("Gunakan Lokasi Ini"),
            ),
          )
        ],
      ),
    );
  }
}
