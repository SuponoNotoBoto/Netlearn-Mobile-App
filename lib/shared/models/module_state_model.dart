import 'package:flutter/foundation.dart';

enum ModuleStatus {
  completed,
  locked,
  inProgress,
  notStarted,
}

@immutable
class ModuleStateModel {
  final String materialId;
  final int orderIndex;
  final bool completed;
  final bool unlocked;
  final ModuleStatus status;

  const ModuleStateModel({
    required this.materialId,
    required this.orderIndex,
    required this.completed,
    required this.unlocked,
    required this.status,
  });

  factory ModuleStateModel.fromMap(
      Map<String, dynamic> map,
      ) {
    final statusText =
        map['status']?.toString() ?? 'not_started';

    return ModuleStateModel(
      materialId:
      map['material_id']?.toString() ?? '',
      orderIndex:
      int.tryParse(
        map['order_index']?.toString() ?? '',
      ) ??
          0,
      completed:
      map['completed'] == true,
      unlocked:
      map['unlocked'] == true,
      status:
      _statusFromString(statusText),
    );
  }

  static ModuleStatus _statusFromString(
      String value,
      ) {
    switch (value) {
      case 'completed':
        return ModuleStatus.completed;

      case 'locked':
        return ModuleStatus.locked;

      case 'in_progress':
        return ModuleStatus.inProgress;

      case 'not_started':
      default:
        return ModuleStatus.notStarted;
    }
  }

  bool get isLocked =>
      status == ModuleStatus.locked;

  bool get isCompleted =>
      status == ModuleStatus.completed;

  bool get isInProgress =>
      status == ModuleStatus.inProgress;
}