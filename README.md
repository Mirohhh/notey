# notey — Task Management App

A sleek, minimal Flutter task organizer with calendar, deadlines, and smart notifications.

<img width="1920" height="1080" alt="New Project (2)" src="https://github.com/user-attachments/assets/06323d3d-f879-4aa2-bcf9-2ac59e4ef2f4" />


## Features

- 📅 **Interactive Calendar** — Monthly/weekly/daily views with task dot indicators
- ✅ **Full Task Management** — Add, edit, delete, and complete tasks by day
- ⏱ **Start Time & Deadlines** — Set when a task begins and when it must be done
- 🔔 **Smart Notifications** — Get notified when a task starts and before deadlines
- 🎨 **Light & Dark Mode** — Seamless toggle with persistent preference
- 🏷 **Priority Levels** — Low, Medium, High with color-coded visual indicators
- 📱 **Minimal Design** — Clean cards, smooth animations, no visual clutter


## Project Structure

```
lib/
├── main.dart                     # App entry point & theme setup
├── models/
│   └── task.dart                 # Task data model
├── providers/
│   ├── task_provider.dart        # State management (CRUD + persistence)
│   └── theme_provider.dart       # Light/dark mode + theme definitions
├── screens/
│   └── home_screen.dart          # Main calendar + task list screen
├── services/
│   └── notification_service.dart # Local notification scheduling
└── widgets/
    ├── task_card.dart            # Swipeable task card with priority bar
    └── task_form_sheet.dart      # Bottom sheet for add/edit task
```


## Setup & Installation

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Android Studio / Xcode

### Steps

```bash
# 1. Install dependencies
flutter pub get

# 2. Run on device/emulator
flutter run
```

### Android Setup
The `AndroidManifest.xml` is already configured with:
- `POST_NOTIFICATIONS` permission (Android 13+)
- `SCHEDULE_EXACT_ALARM` for precise notification timing
- `RECEIVE_BOOT_COMPLETED` to restore notifications after restart

### iOS Setup
Add to `ios/Runner/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>remote-notification</string>
</array>
```


## Dependencies

| Package | Purpose |
|---------|---------|
| `table_calendar` | Interactive calendar widget |
| `flutter_local_notifications` | Scheduled push notifications |
| `shared_preferences` | Persistent local storage |
| `provider` | State management |
| `timezone` | Correct timezone handling for notifications |
| `intl` | Date formatting |
| `uuid` | Unique task IDs |


## How It Works

### Adding a Task
1. Tap a day on the calendar
2. Press **+ Add Task** (FAB or empty state button)
3. Fill in title, description, priority
4. Optionally set **Start Time** and **Deadline**
5. Configure notification preferences
6. Tap **Add Task** to save

### Notifications
- **Start Time alert**: fires exactly when the task is scheduled to begin
- **Deadline warning**: fires N minutes before (10, 15, 30, 60, 120 min)
- **Deadline alert**: fires exactly at the deadline time

### Editing / Deleting
- **Tap** any task card to open the edit sheet
- **Swipe left** on any card to delete (with confirmation)
- **Tap the circle** on the left to mark complete/incomplete

### Calendar Dot Indicators
- A small dot appears under any day that has tasks
- Tap any day to see its tasks listed below


## Design System

**Accent color**: `#6C63FF` (purple-blue)  
**Font hierarchy**: w700 titles → w600 labels → w400 body  
**Corner radius**: 16px cards, 12px inputs, 20px sheets  
**Light bg**: `#F8F8FC` | **Dark bg**: `#0F0F1A`
