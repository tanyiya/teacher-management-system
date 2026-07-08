import 'dart:async';
import 'package:flutter/material.dart';

import '../models/duty_location.dart';
import '../services/duty_location_service.dart';

class DutyLocationProvider extends ChangeNotifier {
  DutyLocationProvider({DutyLocationService? service})
      : _service = service ?? DutyLocationService() {
    _listenLocations();
  }

  final DutyLocationService _service;

  StreamSubscription<List<DutyLocation>>? _locationSub;

  List<DutyLocation> _locations = [];
  bool _isLoading = true;
  String? _error;

  List<DutyLocation> get locations => _locations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<DutyLocation> get activeLocations =>
      _locations.where((location) => location.isActive).toList();

  Future<void> addLocation({required String name, String description = '',}) async {
    try {
      _error = null;

      await _service.addLocation(
        DutyLocation(
          id: '',
          name: name,
          description: description,
          isActive: true,
        ),
      );
    } catch (err) {
      _error = err.toString();
      notifyListeners();
    }
  }

  Future<void> updateLocation(DutyLocation location) async {
    try {
      _error = null;
      await _service.updateLocation(location);
    } catch (err) {
      _error = err.toString();
      notifyListeners();
    }
  }

  Future<void> deactivateLocation(String id) async {
    try {
      _error = null;
      await _service.updateActiveStatus(id, false,);
    } catch (err) {
      _error = err.toString();
      notifyListeners();
    }
  }

  Future<void> activateLocation(String id) async {
    try {
      _error = null;
      await _service.updateActiveStatus(id, true,);
    } catch (err) {
      _error = err.toString();
      notifyListeners();
    }
  }

  void _listenLocations() {
    _locationSub = _service.getLocations().listen(
      (items) {
        _locations = items;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _error = err.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }
}