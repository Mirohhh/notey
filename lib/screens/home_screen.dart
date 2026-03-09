import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    // Initial data load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TaskProvider>();
      provider.loadDay(_selectedDay);
      provider.loadMonthCounts(_focusedDay.year, _focusedDay.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final taskProvider = context.watch<TaskProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final selectedTasks = taskProvider.dayTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('notey',
            style: TextStyle(
                fontFamily: 'NotoSans',
                // fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                fontSize: 26)),
        actions: [
          TextButton(
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _focusedDay = now;
                _selectedDay = now;
              });
              taskProvider.loadDay(now);
              taskProvider.loadMonthCounts(now.year, now.month);
            },
            child: Text(
              'Today',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: themeProvider.toggleTheme,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                themeProvider.isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                key: ValueKey(themeProvider.isDark),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              calendarFormat: _calendarFormat,
              // Use DB counts for dot indicators — no full task load needed
              eventLoader: (day) {
                final key = DateTime(day.year, day.month, day.day);
                final count = taskProvider.monthCounts[key] ?? 0;
                return List.filled(count.clamp(0, 3), '');
              },
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
                taskProvider.loadDay(selected);
              },
              onFormatChanged: (format) =>
                  setState(() => _calendarFormat = format),
              onPageChanged: (focused) {
                setState(() => _focusedDay = focused);
                taskProvider.loadMonthCounts(focused.year, focused.month);
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                selectedDecoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                markerDecoration: const BoxDecoration(
                  color: Color.fromARGB(255, 218, 0, 62),
                  shape: BoxShape.circle,
                ),
                weekendTextStyle:
                    TextStyle(color: colorScheme.primary.withOpacity(0.7)),
                defaultTextStyle:
                    TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
              headerStyle: HeaderStyle(
                formatButtonDecoration: BoxDecoration(
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.4),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                formatButtonTextStyle: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 12,
                ),
                titleTextStyle: TextStyle(
                  color: theme.textTheme.titleMedium?.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                leftChevronIcon: Icon(Icons.chevron_left_rounded,
                    color: theme.textTheme.bodyMedium?.color),
                rightChevronIcon: Icon(Icons.chevron_right_rounded,
                    color: theme.textTheme.bodyMedium?.color),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                weekendStyle: TextStyle(
                  color: colorScheme.primary.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Category filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  emoji: '✨',
                  selected: taskProvider.activeFilter == null,
                  onTap: () => taskProvider.setFilter(null),
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 8),
                ...TaskCategory.values.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: c.label,
                        emoji: c.emoji,
                        selected: taskProvider.activeFilter == c,
                        onTap: () => taskProvider.setFilter(
                            taskProvider.activeFilter == c ? null : c),
                        colorScheme: colorScheme,
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Task list header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSameDay(_selectedDay, DateTime.now())
                            ? 'Today'
                            : DateFormat('EEEE').format(_selectedDay),
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        DateFormat('MMMM d, yyyy').format(_selectedDay),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _TaskCountBadge(
                    count: selectedTasks.length, colorScheme: colorScheme),
              ],
            ),
          ),

          // Tasks
          Expanded(
            child: selectedTasks.isEmpty
                ? _EmptyState(onAdd: () => _showAddTask(context))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: selectedTasks.length,
                    itemBuilder: (_, i) => TaskCard(
                      task: selectedTasks[i],
                      selectedDay: _selectedDay,
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTask(context),
        // label: const Text(
        //   'Add Task',
        //   style: TextStyle(fontWeight: FontWeight.w600),
        // ),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddTask(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskFormSheet(selectedDay: _selectedDay),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _FilterChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary
              : colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCountBadge extends StatelessWidget {
  final int count;
  final ColorScheme colorScheme;

  const _TaskCountBadge({required this.count, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count ${count == 1 ? 'task' : 'tasks'}',
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 40,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text('No tasks for this day',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.textTheme.bodySmall?.color)),
          const SizedBox(height: 8),
          Text('Tap + to add your first task',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Task'),
          ),
        ],
      ),
    );
  }
}
