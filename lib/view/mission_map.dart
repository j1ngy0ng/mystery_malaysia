import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../model/active_mission/app_location.dart';
import '../controller/services/config/app_config.dart';
import 'app_colors.dart';

class MissionMap extends StatefulWidget {
  const MissionMap({
    required this.currentLocation,
    super.key,
    this.height = 260,
    this.interactive = false,
    this.borderRadius = 28,
  });

  final AppLocation? currentLocation;
  final double height;
  final bool interactive;
  final double borderRadius;

  @override
  State<MissionMap> createState() => _MissionMapState();
}

class _MissionMapState extends State<MissionMap> {
  GoogleMapController? _mapController;

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
    if (current == null) {
      return _LocationLoadingMap(
        height: widget.height,
        borderRadius: widget.borderRadius,
      );
    }
    if (AppConfig.demoMode) {
      return _DemoLocationMap(
        height: widget.height,
        borderRadius: widget.borderRadius,
        interactive: widget.interactive,
        onTap: () => _openInteractiveMap(context),
      );
    }
    final currentPoint = LatLng(current.latitude, current.longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: currentPoint,
                  zoom: 16,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _frameMap();
                },
                markers: {
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
        builder: (_) =>
            _InteractiveMissionMapPage(currentLocation: widget.currentLocation),
      ),
    );
  }

  Future<void> _frameMap() async {
    final controller = _mapController;
    final current = widget.currentLocation;
    if (controller == null || current == null) return;

    final currentPoint = LatLng(current.latitude, current.longitude);
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(currentPoint, 16),
    );
  }
}

class _DemoLocationMap extends StatelessWidget {
  const _DemoLocationMap({
    required this.height,
    required this.borderRadius,
    required this.interactive,
    required this.onTap,
  });

  final double height;
  final double borderRadius;
  final bool interactive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: GestureDetector(
      onTap: interactive ? null : onTap,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _DemoMapPainter()),
            const Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x3348B9F2),
                ),
                child: Padding(
                  padding: EdgeInsets.all(13),
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: AppColors.sky,
                    child: CircleAvatar(
                      radius: 4,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(99)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'UI demo • your location only',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DemoMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFFDDF2E4), BlendMode.src);
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final lane = Paint()
      ..color = const Color(0xFFB7DCC8)
      ..strokeWidth = 4;
    for (var index = 0; index < 5; index++) {
      final y = 45.0 + index * size.height / 5.7;
      canvas.drawLine(Offset(-10, y), Offset(size.width + 10, y - 28), road);
    }
    for (var index = 0; index < 5; index++) {
      final x = 28.0 + index * size.width / 4.5;
      canvas.drawLine(Offset(x, -10), Offset(x - 34, size.height + 10), lane);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LocationLoadingMap extends StatelessWidget {
  const _LocationLoadingMap({required this.height, required this.borderRadius});

  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.paleTeal,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_searching_rounded, size: 36),
          SizedBox(height: 8),
          Text(
            'Finding your location...',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
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
            Text(
              'View my location',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractiveMissionMapPage extends StatelessWidget {
  const _InteractiveMissionMapPage({required this.currentLocation});

  final AppLocation? currentLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My location')),
      body: LayoutBuilder(
        builder: (context, constraints) => MissionMap(
          currentLocation: currentLocation,
          height: constraints.maxHeight,
          borderRadius: 0,
          interactive: true,
        ),
      ),
    );
  }
}
