import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'01-Planner'**
  String get appTitle;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @habits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get habits;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTask;

  /// No description provided for @addEvent.
  ///
  /// In en, this message translates to:
  /// **'Add Event'**
  String get addEvent;

  /// No description provided for @addHabit.
  ///
  /// In en, this message translates to:
  /// **'Add Habit'**
  String get addHabit;

  /// No description provided for @addGoal.
  ///
  /// In en, this message translates to:
  /// **'Add Goal'**
  String get addGoal;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTask;

  /// No description provided for @editEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get editEvent;

  /// No description provided for @editHabit.
  ///
  /// In en, this message translates to:
  /// **'Edit Habit'**
  String get editHabit;

  /// No description provided for @editGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit Goal'**
  String get editGoal;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @dueTime.
  ///
  /// In en, this message translates to:
  /// **'Due Time'**
  String get dueTime;

  /// No description provided for @noDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get noDueDate;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get endDate;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @reminderEnabled.
  ///
  /// In en, this message translates to:
  /// **'Reminder enabled'**
  String get reminderEnabled;

  /// No description provided for @reminderLeadMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes before'**
  String get reminderLeadMinutes;

  /// No description provided for @recurrence.
  ///
  /// In en, this message translates to:
  /// **'Recurrence'**
  String get recurrence;

  /// No description provided for @recurrenceNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get recurrenceNone;

  /// No description provided for @recurrenceDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get recurrenceDaily;

  /// No description provided for @recurrenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get recurrenceWeekly;

  /// No description provided for @recurrenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get recurrenceMonthly;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @frequencyDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get frequencyDaily;

  /// No description provided for @frequencySpecificDays.
  ///
  /// In en, this message translates to:
  /// **'Specific days'**
  String get frequencySpecificDays;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sunday;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No streak} =1{1 day} other{{count} days}}'**
  String streakDays(int count);

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @noTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get noTasks;

  /// No description provided for @noEvents.
  ///
  /// In en, this message translates to:
  /// **'No events'**
  String get noEvents;

  /// No description provided for @noHabits.
  ///
  /// In en, this message translates to:
  /// **'No habits yet'**
  String get noHabits;

  /// No description provided for @noGoals.
  ///
  /// In en, this message translates to:
  /// **'No goals yet'**
  String get noGoals;

  /// No description provided for @markDone.
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get markDone;

  /// No description provided for @markUndone.
  ///
  /// In en, this message translates to:
  /// **'Mark undone'**
  String get markUndone;

  /// No description provided for @linkToGoal.
  ///
  /// In en, this message translates to:
  /// **'Link to goal'**
  String get linkToGoal;

  /// No description provided for @noGoal.
  ///
  /// In en, this message translates to:
  /// **'No goal'**
  String get noGoal;

  /// No description provided for @targetDate.
  ///
  /// In en, this message translates to:
  /// **'Target date'**
  String get targetDate;

  /// No description provided for @subtasks.
  ///
  /// In en, this message translates to:
  /// **'Sub-tasks'**
  String get subtasks;

  /// No description provided for @addSubtask.
  ///
  /// In en, this message translates to:
  /// **'Add sub-task'**
  String get addSubtask;

  /// No description provided for @tasksToday.
  ///
  /// In en, this message translates to:
  /// **'Tasks today'**
  String get tasksToday;

  /// No description provided for @eventsToday.
  ///
  /// In en, this message translates to:
  /// **'Events today'**
  String get eventsToday;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTime;

  /// No description provided for @permissionsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get permissionsNotifications;

  /// No description provided for @permissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get permissionGranted;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied — tap to request'**
  String get permissionDenied;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete this item?'**
  String get confirmDelete;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @inbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inbox;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @ai.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get ai;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startTime;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @reschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get reschedule;

  /// No description provided for @moveToInbox.
  ///
  /// In en, this message translates to:
  /// **'Move to Inbox'**
  String get moveToInbox;

  /// No description provided for @organize.
  ///
  /// In en, this message translates to:
  /// **'Organize'**
  String get organize;

  /// No description provided for @when.
  ///
  /// In en, this message translates to:
  /// **'When?'**
  String get when;

  /// No description provided for @newTaskHeader.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get newTaskHeader;

  /// No description provided for @newTaskWhat.
  ///
  /// In en, this message translates to:
  /// **'What?'**
  String get newTaskWhat;

  /// No description provided for @newTaskTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Name this task'**
  String get newTaskTitleHint;

  /// No description provided for @newTaskContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get newTaskContinue;

  /// No description provided for @inboxEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Unstructured Thoughts'**
  String get inboxEmptyTitle;

  /// No description provided for @inboxEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Capture tasks and thoughts as they come. Move them to your timeline when you\'re ready to schedule.'**
  String get inboxEmptyMessage;

  /// No description provided for @newInboxTask.
  ///
  /// In en, this message translates to:
  /// **'New Inbox Task'**
  String get newInboxTask;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @aiAssistantHint.
  ///
  /// In en, this message translates to:
  /// **'Configure local LLM for AI-assisted planning'**
  String get aiAssistantHint;

  /// No description provided for @aiBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get aiBaseUrl;

  /// No description provided for @aiModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get aiModel;

  /// No description provided for @aiEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable AI'**
  String get aiEnabled;

  /// No description provided for @aiTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get aiTestConnection;

  /// No description provided for @aiConnectionOk.
  ///
  /// In en, this message translates to:
  /// **'Connected successfully'**
  String get aiConnectionOk;

  /// No description provided for @aiConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed — check host and model'**
  String get aiConnectionFailed;

  /// No description provided for @aiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'AI unavailable — check AI settings or network'**
  String get aiUnavailable;

  /// No description provided for @aiDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'Enable AI in Settings → AI Assistant to start planning'**
  String get aiDisabledHint;

  /// No description provided for @aiUsageHint.
  ///
  /// In en, this message translates to:
  /// **'Point the base URL at an OpenAI-compatible server (LM Studio / Ollama). The model name must match what the server exposes.'**
  String get aiUsageHint;

  /// No description provided for @aiGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi there!'**
  String get aiGreeting;

  /// No description provided for @aiGreetingQuestion.
  ///
  /// In en, this message translates to:
  /// **'What do you need to accomplish today?'**
  String get aiGreetingQuestion;

  /// No description provided for @aiSuggestionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Try one of these'**
  String get aiSuggestionsLabel;

  /// No description provided for @aiSuggestPlanDay.
  ///
  /// In en, this message translates to:
  /// **'Plan my day'**
  String get aiSuggestPlanDay;

  /// No description provided for @aiSuggestStartHabit.
  ///
  /// In en, this message translates to:
  /// **'Help me start a new habit'**
  String get aiSuggestStartHabit;

  /// No description provided for @aiSuggestItinerary.
  ///
  /// In en, this message translates to:
  /// **'Create a weekend itinerary'**
  String get aiSuggestItinerary;

  /// No description provided for @aiSuggestBrainstorm.
  ///
  /// In en, this message translates to:
  /// **'Brainstorm a project'**
  String get aiSuggestBrainstorm;

  /// No description provided for @aiInputHint.
  ///
  /// In en, this message translates to:
  /// **'Tell me your plans…'**
  String get aiInputHint;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get newChat;

  /// No description provided for @renameChat.
  ///
  /// In en, this message translates to:
  /// **'Rename chat'**
  String get renameChat;

  /// No description provided for @aiCreatedTask.
  ///
  /// In en, this message translates to:
  /// **'Added task: {title}'**
  String aiCreatedTask(String title);

  /// No description provided for @aiCreatedEvent.
  ///
  /// In en, this message translates to:
  /// **'Added event: {title}'**
  String aiCreatedEvent(String title);

  /// No description provided for @aiCreatedHabit.
  ///
  /// In en, this message translates to:
  /// **'Added habit: {name}'**
  String aiCreatedHabit(String name);

  /// No description provided for @aiCreatedGoal.
  ///
  /// In en, this message translates to:
  /// **'Added goal: {title}'**
  String aiCreatedGoal(String title);

  /// No description provided for @aiUpdatedTask.
  ///
  /// In en, this message translates to:
  /// **'Updated task: {title}'**
  String aiUpdatedTask(String title);

  /// No description provided for @aiDeletedTask.
  ///
  /// In en, this message translates to:
  /// **'Deleted task: {title}'**
  String aiDeletedTask(String title);

  /// No description provided for @aiToggledTask.
  ///
  /// In en, this message translates to:
  /// **'Toggled task: {title}'**
  String aiToggledTask(String title);

  /// No description provided for @aiUpdatedEvent.
  ///
  /// In en, this message translates to:
  /// **'Updated event: {title}'**
  String aiUpdatedEvent(String title);

  /// No description provided for @aiDeletedEvent.
  ///
  /// In en, this message translates to:
  /// **'Deleted event: {title}'**
  String aiDeletedEvent(String title);

  /// No description provided for @aiUpdatedHabit.
  ///
  /// In en, this message translates to:
  /// **'Updated habit: {name}'**
  String aiUpdatedHabit(String name);

  /// No description provided for @aiDeletedHabit.
  ///
  /// In en, this message translates to:
  /// **'Deleted habit: {name}'**
  String aiDeletedHabit(String name);

  /// No description provided for @aiToggledHabit.
  ///
  /// In en, this message translates to:
  /// **'Toggled habit: {name}'**
  String aiToggledHabit(String name);

  /// No description provided for @aiUpdatedGoal.
  ///
  /// In en, this message translates to:
  /// **'Updated goal: {title}'**
  String aiUpdatedGoal(String title);

  /// No description provided for @aiDeletedGoal.
  ///
  /// In en, this message translates to:
  /// **'Deleted goal: {title}'**
  String aiDeletedGoal(String title);

  /// No description provided for @aiArchivedGoal.
  ///
  /// In en, this message translates to:
  /// **'Archived goal: {title}'**
  String aiArchivedGoal(String title);

  /// No description provided for @aiNotFound.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find that item — could you clarify?'**
  String get aiNotFound;

  /// No description provided for @aiCreatedPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan: {goals} goal(s) in Settings→Goals, {habits} habit(s) on Timeline, {tasks} task(s) on Timeline/Inbox'**
  String aiCreatedPlan(int goals, int habits, int tasks);

  /// No description provided for @startListening.
  ///
  /// In en, this message translates to:
  /// **'Speak to type'**
  String get startListening;

  /// No description provided for @stopListening.
  ///
  /// In en, this message translates to:
  /// **'Stop listening'**
  String get stopListening;

  /// No description provided for @speechUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition unavailable — check microphone permission'**
  String get speechUnavailable;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @convertChatToPlan.
  ///
  /// In en, this message translates to:
  /// **'✨ Convert chat to plan'**
  String get convertChatToPlan;

  /// No description provided for @reviewPlan.
  ///
  /// In en, this message translates to:
  /// **'Review plan'**
  String get reviewPlan;

  /// No description provided for @planGoalsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no goals} =1{1 goal} other{{count} goals}}'**
  String planGoalsCount(int count);

  /// No description provided for @planHabitsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no habits} =1{1 habit} other{{count} habits}}'**
  String planHabitsCount(int count);

  /// No description provided for @planTasksCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no tasks} =1{1 task} other{{count} tasks}}'**
  String planTasksCount(int count);

  /// No description provided for @commitItems.
  ///
  /// In en, this message translates to:
  /// **'Commit {count} items'**
  String commitItems(int count);

  /// No description provided for @emptyPlan.
  ///
  /// In en, this message translates to:
  /// **'Nothing to commit'**
  String get emptyPlan;

  /// No description provided for @generateSubtasksAI.
  ///
  /// In en, this message translates to:
  /// **'✨ Generate with AI'**
  String get generateSubtasksAI;

  /// No description provided for @linkExistingTasks.
  ///
  /// In en, this message translates to:
  /// **'Link existing'**
  String get linkExistingTasks;

  /// No description provided for @linkCount.
  ///
  /// In en, this message translates to:
  /// **'Link {count}'**
  String linkCount(int count);

  /// No description provided for @noUnlinkedTasks.
  ///
  /// In en, this message translates to:
  /// **'No unlinked tasks available'**
  String get noUnlinkedTasks;

  /// No description provided for @todayStat.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayStat;

  /// No description provided for @inboxStat.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inboxStat;

  /// No description provided for @doneStat.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneStat;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @notificationsAndAlerts.
  ///
  /// In en, this message translates to:
  /// **'Notifications & Alerts'**
  String get notificationsAndAlerts;

  /// No description provided for @customization.
  ///
  /// In en, this message translates to:
  /// **'Customization'**
  String get customization;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @appColor.
  ///
  /// In en, this message translates to:
  /// **'App color'**
  String get appColor;

  /// No description provided for @appColorHint.
  ///
  /// In en, this message translates to:
  /// **'Customize the app\'s theme to match your style. This will not change the color of existing tasks.'**
  String get appColorHint;

  /// No description provided for @layout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get layout;

  /// No description provided for @layoutFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get layoutFull;

  /// No description provided for @layoutSimplified.
  ///
  /// In en, this message translates to:
  /// **'Simplified'**
  String get layoutSimplified;

  /// No description provided for @layoutMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get layoutMinimal;

  /// No description provided for @layoutHint.
  ///
  /// In en, this message translates to:
  /// **'Simplified and Minimal layouts hide some elements to reduce distraction.'**
  String get layoutHint;

  /// No description provided for @alertsIntro.
  ///
  /// In en, this message translates to:
  /// **'Alerts remind you about upcoming tasks, so you don\'t forget about them. Set up default alerts and adjust them for individual tasks.'**
  String get alertsIntro;

  /// No description provided for @enabledOnThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Enabled on this device'**
  String get enabledOnThisDevice;

  /// No description provided for @alarms.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get alarms;

  /// No description provided for @alarmsHint.
  ///
  /// In en, this message translates to:
  /// **'Go to your device\'s alarm settings to allow or prevent this app from scheduling time-sensitive actions.'**
  String get alarmsHint;

  /// No description provided for @defaultAlerts.
  ///
  /// In en, this message translates to:
  /// **'Default alerts'**
  String get defaultAlerts;

  /// No description provided for @atStartOfTask.
  ///
  /// In en, this message translates to:
  /// **'At start of task'**
  String get atStartOfTask;

  /// No description provided for @minutesBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 min before start} other{{n} min before start}}'**
  String minutesBeforeStart(int n);

  /// No description provided for @addNewAlert.
  ///
  /// In en, this message translates to:
  /// **'+ Add new alert'**
  String get addNewAlert;

  /// No description provided for @firstDayOfWeek.
  ///
  /// In en, this message translates to:
  /// **'First Day of the Week'**
  String get firstDayOfWeek;

  /// No description provided for @languageHint.
  ///
  /// In en, this message translates to:
  /// **'You can change the app language in the system settings or here.'**
  String get languageHint;

  /// No description provided for @resetApp.
  ///
  /// In en, this message translates to:
  /// **'Reset App'**
  String get resetApp;

  /// No description provided for @resetAppWarning.
  ///
  /// In en, this message translates to:
  /// **'Resetting the app will permanently erase all settings and tasks. This action is irreversible!'**
  String get resetAppWarning;

  /// No description provided for @confirmReset.
  ///
  /// In en, this message translates to:
  /// **'Reset app?'**
  String get confirmReset;

  /// No description provided for @goalReminders.
  ///
  /// In en, this message translates to:
  /// **'Goal reminders'**
  String get goalReminders;

  /// No description provided for @goalPulsesTitle.
  ///
  /// In en, this message translates to:
  /// **'Periodic goal check-in'**
  String get goalPulsesTitle;

  /// No description provided for @goalPulsesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sends a reminder about your active goals every ~3 hours during the day (9, 12, 15, 18, 21).'**
  String get goalPulsesSubtitle;

  /// No description provided for @onbSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onbSkip;

  /// No description provided for @onbNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onbNext;

  /// No description provided for @onbGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onbGetStarted;

  /// No description provided for @onbWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to 01-Planner'**
  String get onbWelcomeTitle;

  /// No description provided for @onbWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'A day planner that mixes a beautiful timeline with an AI assistant that actually understands you.'**
  String get onbWelcomeBody;

  /// No description provided for @onbTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan your day on a timeline'**
  String get onbTimelineTitle;

  /// No description provided for @onbTimelineBody.
  ///
  /// In en, this message translates to:
  /// **'Time-block tasks, catch conflicts, and see everything at a glance. The + button is always a tap away.'**
  String get onbTimelineBody;

  /// No description provided for @onbGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn goals into real progress'**
  String get onbGoalsTitle;

  /// No description provided for @onbGoalsBody.
  ///
  /// In en, this message translates to:
  /// **'Break a goal into scheduled sub-tasks. Get periodic check-ins so nothing stalls.'**
  String get onbGoalsBody;

  /// No description provided for @onbAiTitle.
  ///
  /// In en, this message translates to:
  /// **'Let the AI draft the work'**
  String get onbAiTitle;

  /// No description provided for @onbAiBody.
  ///
  /// In en, this message translates to:
  /// **'Chat in plain language (Arabic or English). Tap Convert to plan and review every item before it lands.'**
  String get onbAiBody;

  /// No description provided for @noPlansToday.
  ///
  /// In en, this message translates to:
  /// **'No plans for this day'**
  String get noPlansToday;

  /// No description provided for @gapFreeMessage.
  ///
  /// In en, this message translates to:
  /// **'{gap} free. Anything you\'d like to add?'**
  String gapFreeMessage(String gap);

  /// No description provided for @timelineConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Time conflict'**
  String get timelineConflictTitle;

  /// No description provided for @timelineConflictBody.
  ///
  /// In en, this message translates to:
  /// **'This time overlaps with:'**
  String get timelineConflictBody;

  /// No description provided for @saveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Save anyway'**
  String get saveAnyway;

  /// No description provided for @moveToNextFree.
  ///
  /// In en, this message translates to:
  /// **'Move to next free slot'**
  String get moveToNextFree;

  /// No description provided for @noFreeSlotFound.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find a free slot in the next 30 days'**
  String get noFreeSlotFound;

  /// No description provided for @availableHours.
  ///
  /// In en, this message translates to:
  /// **'Available hours'**
  String get availableHours;

  /// No description provided for @weekendDays.
  ///
  /// In en, this message translates to:
  /// **'Weekend days'**
  String get weekendDays;

  /// No description provided for @planGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating plan — you can leave the app…'**
  String get planGenerating;

  /// No description provided for @riseAndShine.
  ///
  /// In en, this message translates to:
  /// **'Rise and Shine'**
  String get riseAndShine;

  /// No description provided for @windDown.
  ///
  /// In en, this message translates to:
  /// **'Wind Down'**
  String get windDown;

  /// No description provided for @youveGot.
  ///
  /// In en, this message translates to:
  /// **'You\'ve got'**
  String get youveGot;

  /// No description provided for @tilNext.
  ///
  /// In en, this message translates to:
  /// **'\'til {target}'**
  String tilNext(String target);

  /// No description provided for @nextItem.
  ///
  /// In en, this message translates to:
  /// **'kickoff'**
  String get nextItem;

  /// No description provided for @conflictsWith.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Conflicts with 1 item} other{Conflicts with {count} items}}'**
  String conflictsWith(int count);

  /// No description provided for @findNextFree.
  ///
  /// In en, this message translates to:
  /// **'Find next free'**
  String get findNextFree;

  /// No description provided for @quickAddHint.
  ///
  /// In en, this message translates to:
  /// **'Quick-add with AI'**
  String get quickAddHint;

  /// No description provided for @dailyPlan.
  ///
  /// In en, this message translates to:
  /// **'Daily plan'**
  String get dailyPlan;

  /// No description provided for @generatePlan.
  ///
  /// In en, this message translates to:
  /// **'Generate plan'**
  String get generatePlan;

  /// No description provided for @proposedPlan.
  ///
  /// In en, this message translates to:
  /// **'Proposed plan'**
  String get proposedPlan;

  /// No description provided for @acceptPlan.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptPlan;

  /// No description provided for @rejectPlan.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectPlan;

  /// No description provided for @wakeTime.
  ///
  /// In en, this message translates to:
  /// **'Wake'**
  String get wakeTime;

  /// No description provided for @sleepTime.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleepTime;

  /// No description provided for @inboxBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'Unscheduled tasks appear in the Inbox. Tap one to schedule it on the timeline.'**
  String get inboxBannerMessage;

  /// No description provided for @iconWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get iconWork;

  /// No description provided for @iconGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get iconGym;

  /// No description provided for @iconCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get iconCall;

  /// No description provided for @iconHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get iconHome;

  /// No description provided for @iconShop.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get iconShop;

  /// No description provided for @iconStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get iconStudy;

  /// No description provided for @iconFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get iconFood;

  /// No description provided for @iconTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get iconTravel;

  /// No description provided for @iconHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get iconHealth;

  /// No description provided for @iconMeet.
  ///
  /// In en, this message translates to:
  /// **'Meeting'**
  String get iconMeet;

  /// No description provided for @iconRead.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get iconRead;

  /// No description provided for @iconIdea.
  ///
  /// In en, this message translates to:
  /// **'Idea'**
  String get iconIdea;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
