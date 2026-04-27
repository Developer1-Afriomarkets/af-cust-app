///
/// Map Location Screen
/// Allows users to pick a delivery location on Google Maps.
/// Previously used google_maps_place_picker which is incompatible with modern AGP.
/// Now uses plain google_maps_flutter with a simplified UI.
///

import 'dart:async';

import 'package:afriomarkets_cust_app/other_config.dart';
import 'package:flutter/material.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';

import 'package:afriomarkets_cust_app/custom/toast_component.dart';
import 'package:afriomarkets_cust_app/repositories/address_repository.dart';
import 'package:afriomarkets_cust_app/l10n/app_localizations.dart';

class MapLocation extends StatefulWidget {
  MapLocation({Key? key, required this.address}) : super(key: key);
  final dynamic address;

  @override
  State<MapLocation> createState() => MapLocationState();
}

class MapLocationState extends State<MapLocation>
    with SingleTickerProviderStateMixin {
  LatLng? _selectedPosition;
  static LatLng kInitialPosition =
      LatLng(51.52034098371205, -0.12637399200000668); // London, default

  GoogleMapController? _controller;
  Set<Marker> _markers = {};

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _controller = controller;
    try {
      String value = await DefaultAssetBundle.of(context)
          .loadString('assets/map_style.json');
      _controller!.setMapStyle(value);
    } catch (_) {}
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    if (widget.address.location_available) {
      setInitialLocation();
    } else {
      setDummyInitialLocation();
    }
  }

  setInitialLocation() {
    kInitialPosition = LatLng(widget.address.lat, widget.address.lang);
    _selectedPosition = kInitialPosition;
    _updateMarker();
    setState(() {});
  }

  setDummyInitialLocation() {
    kInitialPosition = LatLng(51.52034098371205, -0.12637399200000668);
    setState(() {});
  }

  _updateMarker() {
    if (_selectedPosition != null) {
      _markers = {
        Marker(
          markerId: MarkerId('selected'),
          position: _selectedPosition!,
          infoWindow: InfoWindow(title: 'Delivery Location'),
        ),
      };
    }
  }

  onTapPickHere() async {
    if (_selectedPosition == null) {
      ToastComponent.showDialog("Location not selected", context);
      return;
    }

    var addressUpdateLocationResponse = await AddressRepository()
        .getAddressUpdateLocationResponse(widget.address.id,
            _selectedPosition!.latitude, _selectedPosition!.longitude);

    if (!mounted) return;

    if (addressUpdateLocationResponse.result == false) {
      ToastComponent.showDialog(
          addressUpdateLocationResponse.message ?? "", context);
      return;
    }

    ToastComponent.showDialog(
        addressUpdateLocationResponse.message ?? "", context);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!
              .map_location_screen_your_delivery_location,
          style: TextStyle(color: MyTheme.font_grey, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: MyTheme.dark_grey),
        elevation: 1,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: kInitialPosition,
              zoom: 15,
            ),
            markers: _markers,
            onTap: (LatLng position) {
              setState(() {
                _selectedPosition = position;
                _updateMarker();
              });
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          // Bottom bar with pick button
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedPosition != null
                          ? "Lat: ${_selectedPosition!.latitude.toStringAsFixed(4)}, Lng: ${_selectedPosition!.longitude.toStringAsFixed(4)}"
                          : AppLocalizations.of(context)!
                              .map_location_screen_calculating,
                      style:
                          TextStyle(color: MyTheme.medium_grey, fontSize: 13),
                      maxLines: 2,
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyTheme.accent_color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: onTapPickHere,
                    child: Text(
                      AppLocalizations.of(context)!
                          .map_location_screen_pick_here,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
