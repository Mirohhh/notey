import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'task_form_sheet.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final DateTime selectedDay;

  const TaskCard({super.key, required this.task, required this.selectedDay});

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  late TaskPriority _priority;
  late TaskStatus _status;
  late String _title;
  late String _description;
  late TaskCategory _category;
  late DateTime? _startTime;
  late DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _updateFromTask();
  }

  @override
  void didUpdateWidget(TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id ||
        oldWidget.task.title != widget.task.title ||
        oldWidget.task.description != widget.task.description ||
        oldWidget.task.status != widget.task.status ||
        oldWidget.task.priority != widget.task.priority ||
        oldWidget.task.category != widget.task.category ||
        oldWidget.task.startTime != widget.task.startTime ||
        oldWidget.task.deadline != widget.task.deadline) {
      _updateFromTask();
    }
  }

  void _updateFromTask() {
    _priority = widget.task.priority;
    _status = widget.task.status;
    _title = widget.task.title;
    _description = widget.task.description;
    _category = widget.task.category;
    _startTime = widget.task.startTime;
    _deadline = widget.task.deadline;
  }

  Color _priorityColor() {
    switch (_priority) {
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
    final isDone = _status == TaskStatus.completed;
    final priorityColor = _priorityColor();

    return Dismissible(
      key: Key(widget.task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.15),
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
            content: Text('Delete "$_title"?'),
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
        final messenger = ScaffoldMessenger.of(context);
        final provider = context.read<TaskProvider>();
        final deletedTask = widget.task;

        messenger.showSnackBar(
          SnackBar(
            content: Text('$deletedTask.title deleted'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => provider.undoDelete(deletedTask),
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );

        try {
          await provider.deleteTask(deletedTask.id);
        } catch (e) {
          messenger.showSnackBar(
            SnackBar(content: Text('Failed to delete $deletedTask.title')),
          );
        }
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
                color: priorityColor.withOpacity(0.05),
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
                      context.read<TaskProvider>().toggleTaskStatus(widget.task.id),
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
                            : colorScheme.onSurface.withOpacity(0.3),
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
                        _title,
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
                              color: colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_category.emoji} ${_category.label}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _description,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (_startTime != null) ...[
                            _TimeBadge(
                              icon: Icons.play_circle_outline_rounded,
                              label: DateFormat('h:mm a')
                                  .format(_startTime!),
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (_deadline != null) ...[
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
                    color: colorScheme.onSurface.withOpacity(0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _deadlineLabel() {
    if (_deadline == null) return '';
    final now = DateTime.now();
    final diff = _deadline!.difference(now);
    if (diff.isNegative) return 'Overdue';
    if (diff.inHours < 1) return 'Due in ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Due in ${diff.inHours}h';
    return DateFormat('MMM d, h:mm a').format(_deadline!);
  }

  Color _deadlineColor() {
    if (_deadline == null) return Colors.grey;
    final now = DateTime.now();
    final diff = _deadline!.difference(now);
    if (diff.isNegative) return Colors.red;
    if (diff.inHours < 2) return Colors.orange;
    return Colors.green.withOpacity(0.7);
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
        selectedDay: widget.selectedDay,
        existingTask: widget.task,
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
        color: color.withOpacity(0.1),
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
