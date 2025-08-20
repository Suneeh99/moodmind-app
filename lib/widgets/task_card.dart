import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../utils/app_theme.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getIconColor(),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getIcon(),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.isCompleted 
                ? TextDecoration.lineThrough 
                : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.timeString,
              style: TextStyle(
                color: Colors.grey.shade600,
                decoration: task.isCompleted 
                    ? TextDecoration.lineThrough 
                    : null,
              ),
            ),
            if (task.pointsAwarded > 0)
              Text(
                '+${task.pointsAwarded} MM Points',
                style: TextStyle(
                  color: Colors.green.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: _buildTrailing(),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (task.status) {
      case TaskStatus.completed:
        return Colors.green.shade50;
      case TaskStatus.failed:
        return Colors.red.shade50;
      case TaskStatus.overdue:
        return Colors.orange.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  Color _getBorderColor() {
    switch (task.status) {
      case TaskStatus.completed:
        return Colors.green.shade200;
      case TaskStatus.failed:
        return Colors.red.shade200;
      case TaskStatus.overdue:
        return Colors.orange.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getIconColor() {
    switch (task.status) {
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.failed:
        return Colors.red;
      case TaskStatus.overdue:
        return Colors.orange;
      default:
        return AppTheme.primaryBlue;
    }
  }

  IconData _getIcon() {
    switch (task.status) {
      case TaskStatus.completed:
        return Icons.check;
      case TaskStatus.failed:
        return Icons.close;
      case TaskStatus.overdue:
        return Icons.schedule;
      default:
        return Icons.schedule;
    }
  }

  Widget? _buildTrailing() {
    if (task.requiresVerification && !task.isCompleted) {
      return Icon(
        Icons.camera_alt,
        color: Colors.grey.shade400,
      );
    }
    
    if (task.isCompleted && task.pointsAwarded > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '+${task.pointsAwarded}',
          style: TextStyle(
            color: Colors.green.shade700,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    return null;
  }
}
