import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class TaskFormSheet extends StatefulWidget {
  final DateTime selectedDay;
  final Task? existingTask;

  const TaskFormSheet({
    super.key,
    required this.selectedDay,
    this.existingTask,
  });

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _startTime;
  DateTime? _deadline;
  TaskPriority _priority = TaskPriority.medium;
  TaskCategory _category = TaskCategory.other;
  bool _notifyOnStart = true;
  bool _notifyBeforeDeadline = true;
  int _notifyMinutesBefore = 30;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    if (task != null) {
      _titleController.text = task.title;
      _descController.text = task.description;
      _startTime = task.startTime;
      _deadline = task.deadline;
      _priority = task.priority;
      _category = task.category;
      _notifyOnStart = task.notifyOnStart;
      _notifyBeforeDeadline = task.notifyBeforeDeadline;
      _notifyMinutesBefore = task.notifyMinutesBefore;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: widget.selectedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;
    final dt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startTime = dt;
      } else {
        _deadline = dt;
      }
    });
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Snapshot everything before any await
    final navigator = Navigator.of(context);
    final provider = context.read<TaskProvider>();
    final title = _titleController.text.trim();
    final description = _descController.text.trim();
    final selectedDay = widget.selectedDay;
    final startTime = _startTime;
    final deadline = _deadline;
    final priority = _priority;
    final category = _category;
    final notifyOnStart = _notifyOnStart;
    final notifyBeforeDeadline = _notifyBeforeDeadline;
    final notifyMinutesBefore = _notifyMinutesBefore;
    final existingTask = widget.existingTask;

    // Close the sheet immediately — don't wait for DB
    navigator.pop();

    // Do the work after the sheet is gone
    try {
      if (existingTask != null) {
        await provider.updateTask(existingTask.copyWith(
          title: title,
          description: description,
          date: selectedDay,
          startTime: startTime,
          deadline: deadline,
          priority: priority,
          category: category,
          notifyOnStart: notifyOnStart,
          notifyBeforeDeadline: notifyBeforeDeadline,
          notifyMinutesBefore: notifyMinutesBefore,
        ));
      } else {
        await provider.addTask(
          title: title,
          description: description,
          date: selectedDay,
          startTime: startTime,
          deadline: deadline,
          priority: priority,
          category: category,
          notifyOnStart: notifyOnStart,
          notifyBeforeDeadline: notifyBeforeDeadline,
          notifyMinutesBefore: notifyMinutesBefore,
        );
      }
    } catch (e) {
      debugPrint('Failed to save task: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.existingTask != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      snap: true,
      snapSizes: const [0.75, 0.95],
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: ListView(
          controller: scrollController,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEditing ? 'Edit Task' : 'New Task',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 20),

            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Task title',
                prefixIcon: Icon(Icons.task_alt_rounded),
              ),
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                hintText: 'Description (optional)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),

            // Priority
            Text(
              'Priority',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: TaskPriority.values.map((p) {
                final selected = _priority == p;
                final labels = ['Low', 'Medium', 'High'];
                final colors = [Colors.green, Colors.orange, Colors.red];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? colors[p.index].withValues(alpha: 0.15)
                              : colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? colors[p.index]
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.circle,
                                size: 10, color: colors[p.index]),
                            const SizedBox(height: 4),
                            Text(
                              labels[p.index],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? colors[p.index]
                                    : theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Category
            Text(
              'Category',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TaskCategory.values.map((c) {
                final selected = _category == c;
                return GestureDetector(
                  onTap: () => setState(() => _category = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? colorScheme.primary.withValues(alpha: 0.12)
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.1),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(c.emoji,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          c.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? colorScheme.primary
                                : theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Time pickers
            Row(
              children: [
                Expanded(
                  child: _TimePickerButton(
                    label: 'Start Time',
                    icon: Icons.play_circle_outline_rounded,
                    time: _startTime,
                    onTap: () => _pickDateTime(true),
                    onClear: () => setState(() => _startTime = null),
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimePickerButton(
                    label: 'Deadline',
                    icon: Icons.flag_outlined,
                    time: _deadline,
                    onTap: () => _pickDateTime(false),
                    onClear: () => setState(() => _deadline = null),
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Notifications
            Text(
              'Notifications',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            _NotifTile(
              label: 'Notify when task starts',
              value: _notifyOnStart,
              onChanged: (v) => setState(() => _notifyOnStart = v),
            ),
            _NotifTile(
              label: 'Notify before deadline',
              value: _notifyBeforeDeadline,
              onChanged: (v) => setState(() => _notifyBeforeDeadline = v),
            ),
            if (_notifyBeforeDeadline) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Notify', style: theme.textTheme.bodyMedium),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: _notifyMinutesBefore,
                    underline: const SizedBox(),
                    items: [10, 15, 30, 60, 120].map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(
                          m < 60 ? '$m min' : '${m ~/ 60} hr',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) =>
                        setState(() => _notifyMinutesBefore = v ?? 30),
                  ),
                  Text(' before deadline',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            ],
            const SizedBox(height: 28),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  isEditing ? 'Update Task' : 'Add Task',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? time;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final Color color;

  const _TimePickerButton({
    required this.label,
    required this.icon,
    required this.time,
    required this.onTap,
    required this.onClear,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTime = time != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: hasTime
              ? color.withValues(alpha: 0.08)
              : theme.inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasTime ? color.withValues(alpha: 0.4) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: hasTime ? color : theme.iconTheme.color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontSize: 10)),
                  Text(
                    hasTime
                        ? DateFormat('MMM d, h:mm a').format(time!)
                        : 'Set',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: hasTime
                          ? color
                          : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            if (hasTime)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 14, color: color),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotifTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium)),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }
}
