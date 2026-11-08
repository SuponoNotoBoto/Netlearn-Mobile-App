import 'package:flutter/foundation.dart';

@immutable
class LearningFlowStatusModel {
  final bool pretestCompleted;
  final bool module1Completed;
  final bool module2Completed;
  final bool module3Completed;
  final bool module4Completed;
  final bool posttestUnlocked;
  final bool posttestCompleted;

  const LearningFlowStatusModel({
    required this.pretestCompleted,
    required this.module1Completed,
    required this.module2Completed,
    required this.module3Completed,
    required this.module4Completed,
    required this.posttestUnlocked,
    required this.posttestCompleted,
  });

  factory LearningFlowStatusModel.fromMap(Map<String, dynamic> map) {
    return LearningFlowStatusModel(
      pretestCompleted: map['pretest_completed'] == true,
      module1Completed: map['module_1_completed'] == true,
      module2Completed: map['module_2_completed'] == true,
      module3Completed: map['module_3_completed'] == true,
      module4Completed: map['module_4_completed'] == true,
      posttestUnlocked: map['posttest_unlocked'] == true,
      posttestCompleted: map['posttest_completed'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pretest_completed': pretestCompleted,
      'module_1_completed': module1Completed,
      'module_2_completed': module2Completed,
      'module_3_completed': module3Completed,
      'module_4_completed': module4Completed,
      'posttest_unlocked': posttestUnlocked,
      'posttest_completed': posttestCompleted,
    };
  }

  bool isModuleUnlocked(int moduleNumber) {
    switch (moduleNumber) {
      case 1:
        return pretestCompleted;
      case 2:
        return module1Completed;
      case 3:
        return module2Completed;
      case 4:
        return module3Completed;
      default:
        return false;
    }
  }

  bool isModuleCompleted(int moduleNumber) {
    switch (moduleNumber) {
      case 1:
        return module1Completed;
      case 2:
        return module2Completed;
      case 3:
        return module3Completed;
      case 4:
        return module4Completed;
      default:
        return false;
    }
  }
}
