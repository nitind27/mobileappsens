import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/custom_button.dart';

class EmployeeLocationScreen extends ConsumerStatefulWidget {
  const EmployeeLocationScreen({super.key});

  @override
  ConsumerState<EmployeeLocationScreen> createState() => _EmployeeLocationScreenState();
}

class _EmployeeLocationScreenState extends ConsumerState<EmployeeLocationScreen> {
  GoogleMapController? _mapController;
  final LatLng _initialPosition = const LatLng(21.189025, 72.836520);

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(locationTrackingProvider);
    final user = ref.watch(authProvider).user;
    final historyAsync = ref.watch(locationHistoryProvider(user?.employeeId ?? 1));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Authorized Location Sharing'),
      ),
      body: Column(
        children: [
          // Transparent Consent & Status Control Box
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? AppColors.surfaceDark : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: trackingState.isTrackingActive ? AppColors.success : AppColors.textMutedLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          trackingState.isTrackingActive ? 'SHARING ACTIVE' : 'SHARING PAUSED / STOPPED',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: trackingState.isTrackingActive ? AppColors.success : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Session: ${trackingState.currentSessionId != null ? "#${trackingState.currentSessionId}" : "Inactive"}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  trackingState.isTrackingActive
                    ? 'Your live location is being shared with dispatchers for assigned customer route optimization.'
                    : 'Location sharing is turned off. Start sharing when beginning field collection visits.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 14),
                CustomButton(
                  text: trackingState.isTrackingActive ? 'Stop / Pause Location Sharing' : 'Start Authorized Location Sharing',
                  icon: trackingState.isTrackingActive ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                  backgroundColor: trackingState.isTrackingActive ? AppColors.danger : AppColors.success,
                  onPressed: () {
                    if (trackingState.isTrackingActive) {
                      ref.read(locationTrackingProvider.notifier).stopTracking();
                    } else {
                      ref.read(locationTrackingProvider.notifier).startTrackingWithConsent();
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Google Map with Breadcrumb Route Polyline
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Map Error: $err')),
              data: (breadcrumbs) {
                final polylinePoints = breadcrumbs.map((b) => LatLng(b.latitude, b.longitude)).toList();

                final polylines = <Polyline>{
                  if (polylinePoints.isNotEmpty)
                    Polyline(
                      polylineId: const PolylineId('route_history'),
                      points: polylinePoints,
                      color: AppColors.electricBlue,
                      width: 5,
                    ),
                };

                final markers = <Marker>{};
                if (breadcrumbs.isNotEmpty) {
                  final latest = breadcrumbs.last;
                  markers.add(
                    Marker(
                      markerId: const MarkerId('current_pos'),
                      position: LatLng(latest.latitude, latest.longitude),
                      infoWindow: InfoWindow(
                        title: 'Current Position',
                        snippet: 'Recorded: ${latest.recordedAt}',
                      ),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                    ),
                  );
                }

                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: polylinePoints.isNotEmpty ? polylinePoints.last : _initialPosition,
                    zoom: 14.0,
                  ),
                  polylines: polylines,
                  markers: markers,
                  myLocationEnabled: true,
                  zoomControlsEnabled: false,
                  onMapCreated: (ctrl) {
                    _mapController = ctrl;
                    if (polylinePoints.isNotEmpty) {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(polylinePoints.last, 14.0),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
