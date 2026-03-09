import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:task_organizer/models/task.dart';
import 'package:task_organizer/providers/task_provider.dart';
import 'package:task_organizer/widgets/task_card.dart';

class MockTaskProvider extends Mock implements TaskProvider {}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(TaskCategory.other);
  });

  late MockTaskProvider mockProvider;

  setUp(() {
    mockProvider = MockTaskProvider();
  });

  Widget createTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<TaskProvider>.value(
          value: mockProvider,
          child: child,
        ),
      ),
    );
  }

  testWidgets('TaskCard renders task details correctly', (tester) async {
    final task = Task(
      id: '1',
      title: 'Buy Groceries',
      category: TaskCategory.shopping,
      priority: TaskPriority.high,
      date: DateTime.now(),
    );

    await tester.pumpWidget(createTestableWidget(
      TaskCard(task: task, selectedDay: task.date),
    ));

    expect(find.text('Buy Groceries'), findsOneWidget);
    expect(find.text('${TaskCategory.shopping.emoji} ${TaskCategory.shopping.label}'), findsOneWidget);
  });

  testWidgets('Tapping checkbox calls toggleTaskStatus', (tester) async {
    final task = Task(
      id: '1',
      title: 'Buy Groceries',
      date: DateTime.now(),
    );

    when(() => mockProvider.toggleTaskStatus(any())).thenAnswer((_) async {});

    await tester.pumpWidget(createTestableWidget(
      TaskCard(task: task, selectedDay: task.date),
    ));

    final checkbox = find.byType(AnimatedContainer).first;
    await tester.tap(checkbox);
    
    verify(() => mockProvider.toggleTaskStatus(task.id)).called(1);
  });

  testWidgets('Dismissing task card calls deleteTask', (tester) async {
    final task = Task(
      id: '1',
      title: 'Buy Groceries',
      date: DateTime.now(),
    );

    when(() => mockProvider.deleteTask(any())).thenAnswer((_) async {});

    await tester.pumpWidget(createTestableWidget(
      TaskCard(task: task, selectedDay: task.date),
    ));

    // Swipe to delete
    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();

    // Verify dialog appears
    expect(find.text('Delete Task'), findsOneWidget);
    
    // Tap Delete button in dialog
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    verify(() => mockProvider.deleteTask(task.id)).called(1);
  });
}
