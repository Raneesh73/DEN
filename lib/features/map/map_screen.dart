import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/map_provider.dart';
import '../../providers/den_provider.dart';
import '../../providers/auth_provider.dart';
import '../settings/settings_screen.dart';
import '../../core/app_colors.dart';
import '../../core/spacing_constants.dart';
import '../../widgets/glass_widgets.dart';
import '../../models/user_model.dart';
import '../../utils/haversine.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  bool _isInitialLocationSet = false;
  String? _darkMapStyle;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapControllerProvider.notifier).initLocationTracking();
    });
  }

  Future<void> _loadMapStyle() async {
    _darkMapStyle = '''
    [
      {"elementType": "geometry", "stylers": [{"color": "#212121"}]},
      {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
      {"elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
      {"elementType": "labels.text.stroke", "stylers": [{"color": "#212121"}]},
      {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#757575"}]},
      {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0F2537"}]}
    ]
    ''';
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(denMembersProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final permissionState = ref.watch(mapControllerProvider);
    
    final inviteCode = userProfile?.denId != null 
        ? ref.watch(denInviteCodeProvider(userProfile!.denId!))
        : const AsyncValue<String?>.data(null);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'DEN',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 2),
        ).animate().fade().scale(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Spacing.s),
            child: CircleAvatar(
              backgroundColor: AppColors.surface,
              child: IconButton(
                icon: const Icon(Icons.settings, color: AppColors.textPrimary, size: 20),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
            ),
          ),
        ],
      ),
      body: permissionState.when(
        data: (state) {
          if (state == MapPermissionState.denied || state == MapPermissionState.permanentlyDenied) {
            return _buildPermissionDeniedUI(state);
          }

          if (state == MapPermissionState.initial) {
             return const Center(child: CircularProgressIndicator());
          }

          return members.when(
            data: (memberList) {
              final markers = memberList.where((m) => m.latitude != null && m.longitude != null).map((m) {
                final isSelf = m.uid == userProfile?.uid;
                return Marker(
                  markerId: MarkerId(m.uid),
                  position: LatLng(m.latitude!, m.longitude!),
                  infoWindow: InfoWindow(
                    title: isSelf ? '${m.name} (Me)' : m.name,
                    snippet: 'Last updated: ${m.lastUpdated != null ? _formatTime(m.lastUpdated!) : 'Unknown'}',
                  ),
                  icon: isSelf 
                    ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)
                    : BitmapDescriptor.defaultMarker,
                );
              }).toSet();

              if (!_isInitialLocationSet && userProfile?.latitude != null) {
                _isInitialLocationSet = true;
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(userProfile!.latitude!, userProfile.longitude!),
                    15,
                  ),
                );
              }

              return Stack(
                children: [
                  Positioned.fill(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(userProfile?.latitude ?? 40.7128, userProfile?.longitude ?? -74.0060),
                        zoom: userProfile?.latitude != null ? 15 : 2,
                      ),
                      onMapCreated: _onMapCreated,
                      style: _darkMapStyle,
                      markers: markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      mapToolbarEnabled: false,
                      zoomControlsEnabled: false,
                    ),
                  ),
                  
                  // Top Floating Stats
                  Positioned(
                    top: 100,
                    left: Spacing.m,
                    right: Spacing.m,
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: Spacing.m, vertical: Spacing.s),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success),
                          ).animate(onPlay: (c) => c.repeat()).fade(duration: 1.seconds),
                          const SizedBox(width: Spacing.s),
                          Text('${memberList.length} ACTIVE', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          inviteCode.when(
                            data: (code) => GestureDetector(
                              onTap: () => _showInviteDialog(code ?? ''),
                              child: Text('INVITE: ${code ?? '...'}', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                            ),
                            loading: () => const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                            error: (e, _) => const Text('ERR'),
                          ),
                        ],
                      ),
                    ).animate().fade().slideY(begin: -0.2),
                  ),

                  // SOS Button
                  Positioned(
                    bottom: 200,
                    right: Spacing.m,
                    child: FloatingActionButton(
                      heroTag: 'sos',
                      backgroundColor: AppColors.error,
                      onPressed: () => _confirmSOS(),
                      child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 30),
                    ).animate(onPlay: (c) => c.repeat()).shimmer(delay: 2.seconds),
                  ),

                  // Den United Overlay
                  if (ref.watch(denUnitedProvider))
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        child: Center(
                          child: GlassCard(
                            padding: const EdgeInsets.all(Spacing.xl),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🎉', style: TextStyle(fontSize: 60)),
                                const SizedBox(height: Spacing.m),
                                Text(
                                  'DEN UNITED',
                                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4),
                                ),
                                const Text('Everyone is safe and together.'),
                              ],
                            ),
                          ).animate().scale().fadeIn(),
                        ),
                      ),
                    ),

                  // Bottom Member List Scroll
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, AppColors.background.withValues(alpha: 0.8)],
                        ),
                      ),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.m, vertical: Spacing.l),
                        itemCount: memberList.length,
                        itemBuilder: (context, index) {
                          final member = memberList[index];
                          return _buildMemberCard(member, userProfile?.uid == member.uid, index, userProfile);
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error loading members: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Map Error: $e')),
      ),
    );
  }

  Widget _buildMemberCard(UserModel member, bool isSelf, int index, UserModel? currentUser) {
    return Padding(
      padding: const EdgeInsets.only(right: Spacing.m),
      child: GlassCard(
        padding: const EdgeInsets.all(Spacing.m),
        borderRadius: 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isSelf ? AppColors.primary : AppColors.surface,
                  child: Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?'),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.s),
            Text(
              isSelf ? 'Me' : member.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_getDistanceString(member, currentUser)} km',
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ).animate().fade().scale(delay: 100.ms * index),
    );
  }

  String _getDistanceString(UserModel member, UserModel? currentUser) {
    if (currentUser == null || currentUser.latitude == null || member.latitude == null) return '0.0';
    final distance = Haversine.calculateDistance(
      currentUser.latitude!,
      currentUser.longitude!,
      member.latitude!,
      member.longitude!,
    );
    return (distance / 1000).toStringAsFixed(1);
  }

  Widget _buildPermissionDeniedUI(MapPermissionState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.l),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: Spacing.m),
            Text('ACCESS REQUIRED', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Spacing.s),
            Text(
              state == MapPermissionState.permanentlyDenied
                ? 'Please enable location in system settings.'
                : 'DEN needs location access to function.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.l),
            GlassButton(
              onPressed: () => state == MapPermissionState.permanentlyDenied
                ? Geolocator.openAppSettings()
                : ref.read(mapControllerProvider.notifier).initLocationTracking(),
              text: state == MapPermissionState.permanentlyDenied ? 'SETTINGS' : 'GRANT',
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('INVITE CODE'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4, color: AppColors.primary),
            ),
            const SizedBox(height: Spacing.m),
            const Text('Share this code with your circle.', textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
        ],
      ),
    );
  }

  void _confirmSOS() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('SEND SOS?'),
        content: const Text('This will alert everyone in your circle with your live location.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              ref.read(mapControllerProvider.notifier).sendSOS();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SOS Alert Sent!'), backgroundColor: AppColors.error),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('SEND ALERT'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
