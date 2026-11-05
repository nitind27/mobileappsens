import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/location_provider.dart';
import '../../widgets/status_badge.dart';

class AdminLiveMapScreen extends ConsumerStatefulWidget {
  const AdminLiveMapScreen({super.key});

  @override
  ConsumerState<AdminLiveMapScreen> createState() => _AdminLiveMapScreenState();
}

class _AdminLiveMapScreenState extends ConsumerState<AdminLiveMapScreen> {
  GoogleMapController? _mapController;
  final LatLng _initialCenter = const LatLng(21.189025, 72.836520); // Surat Operations Center
  int? _selectedEmployeeId;

  @override
  Widget build(BuildContext context) {
    final liveEmployeesAsync = ref.watch(liveEmployeesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Workforce Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh GPS Pings',
            onPressed: () => ref.refresh(liveEmployeesProvider),
          ),
        ],
      ),
      body: liveEmployeesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Map Error: $err')),
        data: (employees) {
          final markers = <Marker>{};

          for (final emp in employees) {
            final lat = double.tryParse(emp['latitude']?.toString() ?? '');
            final lng = double.tryParse(emp['longitude']?.toString() ?? '');

            if (lat != null && lng != null) {
              markers.add(
                Marker(
                  markerId: MarkerId('emp_${emp['employee_id']}'),
                  position: LatLng(lat, lng),
                  infoWindow: InfoWindow(
                    title: emp['full_name'],
                    snippet: 'Status: ${emp['current_status']} • Battery: ${emp['battery_level'] ?? 85}%',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    emp['current_status'] == 'in_field'
                        ? BitmapDescriptor.hueGreen
                        : BitmapDescriptor.hueAzure,
                  ),
                  onTap: () {
                    setState(() => _selectedEmployeeId = emp['employee_id']);
                  },
                ),
              );
            }
          }

          return Stack(
            children: [
              // Google Maps View
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _initialCenter,
                  zoom: 13.0,
                ),
                markers: markers,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
                onMapCreated: (ctrl) => _mapController = ctrl,
              ),

              // Active Sharing Notice Card on Top
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark.withOpacity(0.95) : Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorderLight),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${employees.length} Authorized agents sharing live location',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Employee Selector Cards
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: employees.length,
                    itemBuilder: (ctx, idx) {
                      final emp = employees[idx];
                      final isSelected = _selectedEmployeeId == emp['employee_id'];
                      final lat = double.tryParse(emp['latitude']?.toString() ?? '0.0') ?? 0.0;
                      final lng = double.tryParse(emp['longitude']?.toString() ?? '0.0') ?? 0.0;

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedEmployeeId = emp['employee_id']);
                          if (lat != 0.0 && lng != 0.0 && _mapController != null) {
                            _mapController!.animateCamera(
                              CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15),
                            );
                          }
                        },
                        child: Container(
                          width: 250,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.electricBlue : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    emp['full_name'],
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  StatusBadge(label: emp['current_status']),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.battery_charging_full, size: 14, color: AppColors.success),
                                  const SizedBox(width: 4),
                                  Text('${emp['battery_level'] ?? 85}%', style: const TextStyle(fontSize: 11)),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.access_time, size: 14, color: AppColors.textMutedLight),
                                  const SizedBox(width: 4),
                                  Text('${emp['recorded_at'] ?? "Just now"}', style: const TextStyle(fontSize: 11)),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (emp['phone'] != null)
                                    InkWell(
                                      onTap: () => launchUrl(Uri.parse('tel:${emp['phone']}')),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4),
                                        child: Icon(Icons.phone, size: 18, color: AppColors.electricBlue),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
