import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/map_provider.dart';
import '../../providers/den_provider.dart';
import '../../providers/auth_provider.dart';
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
    final quickMessages = ref.watch(quickMessagesProvider).value ?? [];
    
    final inviteCode = userProfile?.activeDenId != null 
        ? ref.watch(denInviteCodeProvider(userProfile!.activeDenId!))
        : const AsyncValue<String?>.data(null);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'LIVE MAP',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 2),
        ).animate().fade().scale(),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.textPrimary),
            onPressed: () => _showQuickMessageInput(),
          ),
          const SizedBox(width: Spacing.s),
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
                  onTap: () => _zoomToMember(m),
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
                  
                  // Message Overlays
                  ...quickMessages.map((msg) => _buildMessageOverlay(msg, memberList)),

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
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success),
                          ).animate(onPlay: (c) => c.repeat()).fade(duration: 1.seconds),
                          const SizedBox(width: Spacing.s),
                          Text('${memberList.length} IN CIRCLE', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          inviteCode.when(
                            data: (code) => GestureDetector(
                              onTap: () => _showInviteDialog(code ?? ''),
                              child: Text('CODE: ${code ?? '...'}', style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ),
                            loading: () => const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2)),
                            error: (e, _) => const Text('ERR'),
                          ),
                        ],
                      ),
                    ).animate().fade().slideY(begin: -0.2),
                  ),

                  // SOS Button
                  Positioned(
                    bottom: 220,
                    right: Spacing.m,
                    child: FloatingActionButton(
                      heroTag: 'sos_map',
                      backgroundColor: AppColors.error,
                      onPressed: () => _confirmSOS(),
                      child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 30),
                    ).animate(onPlay: (c) => c.repeat()).shimmer(delay: 2.seconds),
                  ),

                  // Bottom Member List
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.m),
                        itemCount: memberList.length,
                        itemBuilder: (context, index) {
                          final member = memberList[index];
                          return _buildMemberMiniCard(member, userProfile?.uid == member.uid, userProfile);
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

  Widget _buildMessageOverlay(dynamic msg, List<UserModel> members) {
    try {
      final sender = members.firstWhere((m) => m.uid == msg.senderId);
      if (sender.latitude == null || _mapController == null) return const SizedBox.shrink();

      return FutureBuilder<ScreenCoordinate>(
        future: _mapController!.getScreenCoordinate(LatLng(sender.latitude!, sender.longitude!)),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final coord = snapshot.data!;
          
          return Positioned(
            left: coord.x.toDouble() - 50,
            top: coord.y.toDouble() - 60,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              borderRadius: 15,
              child: Text(
                msg.content,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ).animate().fade().slideY(begin: 0.5),
          );
        },
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildMemberMiniCard(UserModel member, bool isSelf, UserModel? currentUser) {
    return GestureDetector(
      onTap: () => _zoomToMember(member),
      child: Padding(
        padding: const EdgeInsets.only(right: Spacing.s),
        child: GlassCard(
          padding: const EdgeInsets.all(Spacing.s),
          borderRadius: 15,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isSelf ? AppColors.primary : AppColors.surface,
                child: Text(member.username.isNotEmpty ? member.username[0].toUpperCase() : '?', style: const TextStyle(fontSize: 14)),
              ),
              const SizedBox(height: 4),
              Text(isSelf ? 'Me' : member.username, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              Text('${_getDistanceString(member, currentUser)}km', style: const TextStyle(fontSize: 8, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  void _zoomToMember(UserModel member) {
    if (member.latitude != null && member.longitude != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(member.latitude!, member.longitude!), 18),
      );
    }
  }

  void _showQuickMessageInput() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: GlassCard(
          padding: const EdgeInsets.all(Spacing.l),
          borderRadius: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('SEND QUICK MESSAGE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
              const Text('Max 3 words, expires in 15s', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              const SizedBox(height: Spacing.m),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 20,
                decoration: const InputDecoration(hintText: 'e.g. On my way!'),
              ),
              const SizedBox(height: Spacing.m),
              GlassButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    ref.read(mapControllerProvider.notifier).sendQuickMessage(controller.text);
                    Navigator.pop(context);
                  }
                },
                text: 'SEND',
              ),
            ],
          ),
        ),
      ),
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

}
