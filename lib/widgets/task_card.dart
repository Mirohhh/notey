import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'task_form_sheet.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final DateTime selectedDay;

  const TaskCard({super.key, required this.task, required this.selectedDay});

  Color _priorityColor() {
    switch (task.priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDone = task.status == TaskStatus.completed;
    final priorityColor = _priorityColor();

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete Task'),
            content: Text('Delete "${task.title}"?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        // Show snackbar immediately — deletion is already optimistic in provider
        final messenger = ScaffoldMessenger.of(context);
        await context.read<TaskProvider>().deleteTask(task.id);
        messenger.showSnackBar(
          SnackBar(
            content: Text('${task.title} deleted'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _showEditSheet(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: priorityColor, width: 4),
            ),
            boxShadow: [
              BoxShadow(
                color: priorityColor.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () =>
                      context.read<TaskProvider>().toggleTaskStatus(task.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isDone ? colorScheme.primary : Colors.transparent,
                      border: Border.all(
                        color: isDone
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: isDone
                        ? const Icon(Icons.check_rounded,
                            size: 14, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          color: isDone
                              ? theme.textTheme.bodySmall?.color
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${task.category.emoji} ${task.category.label}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (task.startTime != null) ...[
                            _TimeBadge(
                              icon: Icons.play_circle_outline_rounded,
                              label: DateFormat('h:mm a')
                                  .format(task.startTime!),
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (task.deadline != null) ...[
                            _TimeBadge(
                              icon: Icons.flag_outlined,
                              label: _deadlineLabel(),
                              color: _deadlineColor(),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Edit icon
                Icon(Icons.chevron_right_rounded,
                    color: colorScheme.onSurface.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _deadlineLabel() {
    if (task.deadline == null) return '';
    final now = DateTime.now();
    final diff = task.deadline!.difference(now);
    if (diff.isNegative) return 'Overdue';
    if (diff.inHours < 1) return 'Due in ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Due in ${diff.inHours}h';
    return DateFormat('MMM d, h:mm a').format(task.deadline!);
  }

  Color _deadlineColor() {
    if (task.deadline == null) return Colors.grey;
    final now = DateTime.now();
    final diff = task.deadline!.difference(now);
    if (diff.isNegative) return Colors.red;
    if (diff.inHours < 2) return Colors.orange;
    return Colors.red.withValues(alpha: 0.7);
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskFormSheet(
        selectedDay: selectedDay,
        existingTask: task,
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TimeBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
