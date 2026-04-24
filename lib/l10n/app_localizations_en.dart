// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => '01-Planner';

  @override
  String get today => 'Today';

  @override
  String get calendar => 'Calendar';

  @override
  String get habits => 'Habits';

  @override
  String get goals => 'Goals';

  @override
  String get settings => 'Settings';

  @override
  String get addTask => 'Add Task';

  @override
  String get addEvent => 'Add Event';

  @override
  String get addHabit => 'Add Habit';

  @override
  String get addGoal => 'Add Goal';

  @override
  String get editTask => 'Edit Task';

  @override
  String get editEvent => 'Edit Event';

  @override
  String get editHabit => 'Edit Habit';

  @override
  String get editGoal => 'Edit Goal';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get title => 'Title';

  @override
  String get description => 'Description';

  @override
  String get location => 'Location';

  @override
  String get notes => 'Notes';

  @override
  String get dueDate => 'Due Date';

  @override
  String get dueTime => 'Due Time';

  @override
  String get noDueDate => 'No due date';

  @override
  String get startDate => 'Start';

  @override
  String get endDate => 'End';

  @override
  String get priority => 'Priority';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get reminder => 'Reminder';

  @override
  String get reminderEnabled => 'Reminder enabled';

  @override
  String get reminderLeadMinutes => 'Minutes before';

  @override
  String get recurrence => 'Recurrence';

  @override
  String get recurrenceNone => 'None';

  @override
  String get recurrenceDaily => 'Daily';

  @override
  String get recurrenceWeekly => 'Weekly';

  @override
  String get recurrenceMonthly => 'Monthly';

  @override
  String get frequency => 'Frequency';

  @override
  String get frequencyDaily => 'Every day';

  @override
  String get frequencySpecificDays => 'Specific days';

  @override
  String get monday => 'Mon';

  @override
  String get tuesday => 'Tue';

  @override
  String get wednesday => 'Wed';

  @override
  String get thursday => 'Thu';

  @override
  String get friday => 'Fri';

  @override
  String get saturday => 'Sat';

  @override
  String get sunday => 'Sun';

  @override
  String get streak => 'Streak';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: 'No streak',
    );
    return '$_temp0';
  }

  @override
  String get progress => 'Progress';

  @override
  String get language => 'Language';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get noTasks => 'No tasks yet';

  @override
  String get noEvents => 'No events';

  @override
  String get noHabits => 'No habits yet';

  @override
  String get noGoals => 'No goals yet';

  @override
  String get markDone => 'Mark done';

  @override
  String get markUndone => 'Mark undone';

  @override
  String get linkToGoal => 'Link to goal';

  @override
  String get noGoal => 'No goal';

  @override
  String get targetDate => 'Target date';

  @override
  String get subtasks => 'Sub-tasks';

  @override
  String get addSubtask => 'Add sub-task';

  @override
  String get tasksToday => 'Tasks today';

  @override
  String get eventsToday => 'Events today';

  @override
  String get selectDate => 'Select date';

  @override
  String get selectTime => 'Select time';

  @override
  String get permissionsNotifications => 'Notifications';

  @override
  String get permissionGranted => 'Granted';

  @override
  String get permissionDenied => 'Denied — tap to request';

  @override
  String get confirmDelete => 'Delete this item?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get completed => 'Completed';

  @override
  String get active => 'Active';

  @override
  String get archived => 'Archived';

  @override
  String get archive => 'Archive';

  @override
  String get inbox => 'Inbox';

  @override
  String get timeline => 'Timeline';

  @override
  String get ai => 'AI';

  @override
  String get duration => 'Duration';

  @override
  String get startTime => 'Start time';

  @override
  String get icon => 'Icon';

  @override
  String get color => 'Color';

  @override
  String get reschedule => 'Reschedule';

  @override
  String get moveToInbox => 'Move to Inbox';

  @override
  String get organize => 'Organize';

  @override
  String get when => 'When?';

  @override
  String get newTaskHeader => 'New Task';

  @override
  String get newTaskWhat => 'What?';

  @override
  String get newTaskTitleHint => 'Name this task';

  @override
  String get newTaskContinue => 'Continue';

  @override
  String get inboxEmptyTitle => 'Your Unstructured Thoughts';

  @override
  String get inboxEmptyMessage =>
      'Capture tasks and thoughts as they come. Move them to your timeline when you\'re ready to schedule.';

  @override
  String get newInboxTask => 'New Inbox Task';

  @override
  String get aiAssistant => 'AI Assistant';

  @override
  String get aiAssistantHint => 'Configure local LLM for AI-assisted planning';

  @override
  String get aiBaseUrl => 'Base URL';

  @override
  String get aiModel => 'Model';

  @override
  String get aiEnabled => 'Enable AI';

  @override
  String get aiTestConnection => 'Test connection';

  @override
  String get aiConnectionOk => 'Connected successfully';

  @override
  String get aiConnectionFailed => 'Connection failed — check host and model';

  @override
  String get aiUnavailable => 'AI unavailable — check AI settings or network';

  @override
  String get aiDisabledHint =>
      'Enable AI in Settings → AI Assistant to start planning';

  @override
  String get aiUsageHint =>
      'Point the base URL at an OpenAI-compatible server (LM Studio / Ollama). The model name must match what the server exposes.';

  @override
  String get aiGreeting => 'Hi there!';

  @override
  String get aiGreetingQuestion => 'What do you need to accomplish today?';

  @override
  String get aiSuggestionsLabel => 'Try one of these';

  @override
  String get aiSuggestPlanDay => 'Plan my day';

  @override
  String get aiSuggestStartHabit => 'Help me start a new habit';

  @override
  String get aiSuggestItinerary => 'Create a weekend itinerary';

  @override
  String get aiSuggestBrainstorm => 'Brainstorm a project';

  @override
  String get aiInputHint => 'Tell me your plans…';

  @override
  String get newChat => 'New chat';

  @override
  String get renameChat => 'Rename chat';

  @override
  String aiCreatedTask(String title) {
    return 'Added task: $title';
  }

  @override
  String aiCreatedEvent(String title) {
    return 'Added event: $title';
  }

  @override
  String aiCreatedHabit(String name) {
    return 'Added habit: $name';
  }

  @override
  String aiCreatedGoal(String title) {
    return 'Added goal: $title';
  }

  @override
  String aiUpdatedTask(String title) {
    return 'Updated task: $title';
  }

  @override
  String aiDeletedTask(String title) {
    return 'Deleted task: $title';
  }

  @override
  String aiToggledTask(String title) {
    return 'Toggled task: $title';
  }

  @override
  String aiUpdatedEvent(String title) {
    return 'Updated event: $title';
  }

  @override
  String aiDeletedEvent(String title) {
    return 'Deleted event: $title';
  }

  @override
  String aiUpdatedHabit(String name) {
    return 'Updated habit: $name';
  }

  @override
  String aiDeletedHabit(String name) {
    return 'Deleted habit: $name';
  }

  @override
  String aiToggledHabit(String name) {
    return 'Toggled habit: $name';
  }

  @override
  String aiUpdatedGoal(String title) {
    return 'Updated goal: $title';
  }

  @override
  String aiDeletedGoal(String title) {
    return 'Deleted goal: $title';
  }

  @override
  String aiArchivedGoal(String title) {
    return 'Archived goal: $title';
  }

  @override
  String get aiNotFound => 'Couldn\'t find that item — could you clarify?';

  @override
  String aiCreatedPlan(int goals, int habits, int tasks) {
    return 'Plan: $goals goal(s) in Settings→Goals, $habits habit(s) on Timeline, $tasks task(s) on Timeline/Inbox';
  }

  @override
  String get startListening => 'Speak to type';

  @override
  String get stopListening => 'Stop listening';

  @override
  String get speechUnavailable =>
      'Speech recognition unavailable — check microphone permission';

  @override
  String get submit => 'Submit';

  @override
  String get convertChatToPlan => '✨ Convert chat to plan';

  @override
  String get reviewPlan => 'Review plan';

  @override
  String planGoalsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count goals',
      one: '1 goal',
      zero: 'no goals',
    );
    return '$_temp0';
  }

  @override
  String planHabitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count habits',
      one: '1 habit',
      zero: 'no habits',
    );
    return '$_temp0';
  }

  @override
  String planTasksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
      zero: 'no tasks',
    );
    return '$_temp0';
  }

  @override
  String commitItems(int count) {
    return 'Commit $count items';
  }

  @override
  String get emptyPlan => 'Nothing to commit';

  @override
  String get generateSubtasksAI => '✨ Generate with AI';

  @override
  String get linkExistingTasks => 'Link existing';

  @override
  String linkCount(int count) {
    return 'Link $count';
  }

  @override
  String get noUnlinkedTasks => 'No unlinked tasks available';

  @override
  String get todayStat => 'Today';

  @override
  String get inboxStat => 'Inbox';

  @override
  String get doneStat => 'Done';

  @override
  String get preferences => 'Preferences';

  @override
  String get notificationsAndAlerts => 'Notifications & Alerts';

  @override
  String get customization => 'Customization';

  @override
  String get advanced => 'Advanced';

  @override
  String get appColor => 'App color';

  @override
  String get appColorHint =>
      'Customize the app\'s theme to match your style. This will not change the color of existing tasks.';

  @override
  String get layout => 'Layout';

  @override
  String get layoutFull => 'Full';

  @override
  String get layoutSimplified => 'Simplified';

  @override
  String get layoutMinimal => 'Minimal';

  @override
  String get layoutHint =>
      'Simplified and Minimal layouts hide some elements to reduce distraction.';

  @override
  String get alertsIntro =>
      'Alerts remind you about upcoming tasks, so you don\'t forget about them. Set up default alerts and adjust them for individual tasks.';

  @override
  String get enabledOnThisDevice => 'Enabled on this device';

  @override
  String get alarms => 'Alarms';

  @override
  String get alarmsHint =>
      'Go to your device\'s alarm settings to allow or prevent this app from scheduling time-sensitive actions.';

  @override
  String get defaultAlerts => 'Default alerts';

  @override
  String get atStartOfTask => 'At start of task';

  @override
  String minutesBeforeStart(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n min before start',
      one: '1 min before start',
    );
    return '$_temp0';
  }

  @override
  String get addNewAlert => '+ Add new alert';

  @override
  String get firstDayOfWeek => 'First Day of the Week';

  @override
  String get languageHint =>
      'You can change the app language in the system settings or here.';

  @override
  String get resetApp => 'Reset App';

  @override
  String get resetAppWarning =>
      'Resetting the app will permanently erase all settings and tasks. This action is irreversible!';

  @override
  String get confirmReset => 'Reset app?';

  @override
  String get goalReminders => 'Goal reminders';

  @override
  String get goalPulsesTitle => 'Periodic goal check-in';

  @override
  String get goalPulsesSubtitle =>
      'Sends a reminder about your active goals every ~3 hours during the day (9, 12, 15, 18, 21).';

  @override
  String get onbSkip => 'Skip';

  @override
  String get onbNext => 'Next';

  @override
  String get onbGetStarted => 'Get started';

  @override
  String get onbWelcomeTitle => 'Welcome to 01-Planner';

  @override
  String get onbWelcomeBody =>
      'A day planner that mixes a beautiful timeline with an AI assistant that actually understands you.';

  @override
  String get onbTimelineTitle => 'Plan your day on a timeline';

  @override
  String get onbTimelineBody =>
      'Time-block tasks, catch conflicts, and see everything at a glance. The + button is always a tap away.';

  @override
  String get onbGoalsTitle => 'Turn goals into real progress';

  @override
  String get onbGoalsBody =>
      'Break a goal into scheduled sub-tasks. Get periodic check-ins so nothing stalls.';

  @override
  String get onbAiTitle => 'Let the AI draft the work';

  @override
  String get onbAiBody =>
      'Chat in plain language (Arabic or English). Tap Convert to plan and review every item before it lands.';

  @override
  String get noPlansToday => 'No plans for this day';

  @override
  String gapFreeMessage(String gap) {
    return '$gap free. Anything you\'d like to add?';
  }

  @override
  String get timelineConflictTitle => 'Time conflict';

  @override
  String get timelineConflictBody => 'This time overlaps with:';

  @override
  String get saveAnyway => 'Save anyway';

  @override
  String get moveToNextFree => 'Move to next free slot';

  @override
  String get noFreeSlotFound =>
      'Couldn\'t find a free slot in the next 30 days';

  @override
  String get availableHours => 'Available hours';

  @override
  String get weekendDays => 'Weekend days';

  @override
  String get planGenerating => 'Generating plan — you can leave the app…';

  @override
  String get riseAndShine => 'Rise and Shine';

  @override
  String get windDown => 'Wind Down';

  @override
  String get youveGot => 'You\'ve got';

  @override
  String tilNext(String target) {
    return '\'til $target';
  }

  @override
  String get nextItem => 'kickoff';

  @override
  String conflictsWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Conflicts with $count items',
      one: 'Conflicts with 1 item',
    );
    return '$_temp0';
  }

  @override
  String get findNextFree => 'Find next free';

  @override
  String get quickAddHint => 'Quick-add with AI';

  @override
  String get dailyPlan => 'Daily plan';

  @override
  String get generatePlan => 'Generate plan';

  @override
  String get proposedPlan => 'Proposed plan';

  @override
  String get acceptPlan => 'Accept';

  @override
  String get rejectPlan => 'Reject';

  @override
  String get wakeTime => 'Wake';

  @override
  String get sleepTime => 'Sleep';

  @override
  String get inboxBannerMessage =>
      'Unscheduled tasks appear in the Inbox. Tap one to schedule it on the timeline.';

  @override
  String get iconWork => 'Work';

  @override
  String get iconGym => 'Gym';

  @override
  String get iconCall => 'Call';

  @override
  String get iconHome => 'Home';

  @override
  String get iconShop => 'Shopping';

  @override
  String get iconStudy => 'Study';

  @override
  String get iconFood => 'Food';

  @override
  String get iconTravel => 'Travel';

  @override
  String get iconHealth => 'Health';

  @override
  String get iconMeet => 'Meeting';

  @override
  String get iconRead => 'Reading';

  @override
  String get iconIdea => 'Idea';
}
