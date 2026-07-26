import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/active_mission/app_location.dart';
import '../theme/app_colors.dart';

class MissionMap extends StatefulWidget {
  const MissionMap({
    required this.focus,
    super.key,
    this.currentLocation,
    this.height = 260,
    this.mysteryRadiusMetres = 150,
    this.interactive = false,
    this.borderRadius = 28,
  });

  final AppLocation focus;
  final AppLocation? currentLocation;
  final double height;
  final double mysteryRadiusMetres;
  final bool interactive;
  final double borderRadius;

  @override
  State<MissionMap> createState() => _MissionMapState();
}

class _MissionMapState extends State<MissionMap> {
  GoogleMapController? _mapController;

  LatLng get _focus => LatLng(widget.focus.latitude, widget.focus.longitude);

  @override
  void didUpdateWidget(covariant MissionMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLocation != widget.currentLocation) {
      _frameMap();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.currentLocation;
    final currentPoint = current == null
        ? null
        : LatLng(current.latitude, current.longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: _focus, zoom: 15),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _frameMap();
                },
                circles: {
                  Circle(
                    circleId: const CircleId('mystery-zone'),
                    center: _focus,
                    radius: widget.mysteryRadiusMetres,
                    fillColor: AppColors.mango.withValues(alpha: .24),
                    strokeColor: AppColors.hibiscus,
                    strokeWidth: 3,
                  ),
                },
                markers: {
                  if (currentPoint != null)
                    Marker(
                      markerId: const MarkerId('traveller'),
                      position: currentPoint,
                      infoWindow: const InfoWindow(title: 'You are here'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure,
                      ),
                    ),
                },
                compassEnabled: widget.interactive,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                rotateGesturesEnabled: false,
                scrollGesturesEnabled: widget.interactive,
                tiltGesturesEnabled: widget.interactive,
                zoomGesturesEnabled: widget.interactive,
                zoomControlsEnabled: false,
              ),
            ),
            if (!widget.interactive)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(onTap: () => _openInteractiveMap(context)),
                ),
              ),
            if (!widget.interactive)
              const Positioned(
                top: 12,
                right: 12,
                child: IgnorePointer(child: _ExploreMapLabel()),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInteractiveMap(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _InteractiveMissionMapPage(
          focus: widget.focus,
          currentLocation: widget.currentLocation,
          mysteryRadiusMetres: widget.mysteryRadiusMetres,
        ),
      ),
    );
  }

  Future<void> _frameMap() async {
    final controller = _mapController;
    final current = widget.currentLocation;
    if (controller == null) return;
    if (current == null) {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(_focus, 15));
      return;
    }

    final currentPoint = LatLng(current.latitude, current.longitude);
    final southWest = LatLng(
      currentPoint.latitude < _focus.latitude
          ? currentPoint.latitude
          : _focus.latitude,
      currentPoint.longitude < _focus.longitude
          ? currentPoint.longitude
          : _focus.longitude,
    );
    final northEast = LatLng(
      currentPoint.latitude > _focus.latitude
          ? currentPoint.latitude
          : _focus.latitude,
      currentPoint.longitude > _focus.longitude
          ? currentPoint.longitude
          : _focus.longitude,
    );

    if (southWest == northEast) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(currentPoint, 16),
      );
      return;
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: southWest, northeast: northEast),
        64,
      ),
    );
  }
}

class _ExploreMapLabel extends StatelessWidget {
  const _ExploreMapLabel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: Color(0x24000000), blurRadius: 10)],
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.open_in_full_rounded, size: 17),
            SizedBox(width: 6),
            Text('Explore map', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _InteractiveMissionMapPage extends StatelessWidget {
  const _InteractiveMissionMapPage({
    required this.focus,
    required this.currentLocation,
    required this.mysteryRadiusMetres,
  });

  final AppLocation focus;
  final AppLocation? currentLocation;
  final double mysteryRadiusMetres;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mystery map')),
      body: LayoutBuilder(
        builder: (context, constraints) => MissionMap(
          focus: focus,
          currentLocation: currentLocation,
          mysteryRadiusMetres: mysteryRadiusMetres,
          height: constraints.maxHeight,
          borderRadius: 0,
          interactive: true,
        ),
      ),
    );
  }
}
