import 'package:flutter/material.dart';
import '../models/seed_event_status.dart';
import '../models/seed_plant_result.dart';
import '../services/seed_event_service.dart';

class SeedEventProvider extends ChangeNotifier {
  final SeedEventService service;

  SeedEventStatus? status;
  bool isLoading = false;

  SeedEventProvider(this.service);

  Future<void> loadStatus() async {
    status = await service.getStatus();
    notifyListeners();
  }

  Future<SeedPlantResult> plantSeed() async {
    isLoading = true;
    notifyListeners();

    final result = await service.plantSeed();
    await loadStatus();

    isLoading = false;
    notifyListeners();

    return result;
  }
}

