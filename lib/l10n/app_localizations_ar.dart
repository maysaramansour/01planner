// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => '01-Planner';

  @override
  String get today => 'اليوم';

  @override
  String get calendar => 'التقويم';

  @override
  String get habits => 'العادات';

  @override
  String get goals => 'الأهداف';

  @override
  String get settings => 'الإعدادات';

  @override
  String get addTask => 'إضافة مهمة';

  @override
  String get addEvent => 'إضافة حدث';

  @override
  String get addHabit => 'إضافة عادة';

  @override
  String get addGoal => 'إضافة هدف';

  @override
  String get editTask => 'تعديل المهمة';

  @override
  String get editEvent => 'تعديل الحدث';

  @override
  String get editHabit => 'تعديل العادة';

  @override
  String get editGoal => 'تعديل الهدف';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get title => 'العنوان';

  @override
  String get description => 'الوصف';

  @override
  String get location => 'المكان';

  @override
  String get notes => 'ملاحظات';

  @override
  String get dueDate => 'تاريخ الاستحقاق';

  @override
  String get dueTime => 'وقت الاستحقاق';

  @override
  String get noDueDate => 'بدون تاريخ';

  @override
  String get startDate => 'البداية';

  @override
  String get endDate => 'النهاية';

  @override
  String get priority => 'الأولوية';

  @override
  String get priorityLow => 'منخفضة';

  @override
  String get priorityMedium => 'متوسطة';

  @override
  String get priorityHigh => 'عالية';

  @override
  String get reminder => 'تذكير';

  @override
  String get reminderEnabled => 'تفعيل التذكير';

  @override
  String get reminderLeadMinutes => 'دقائق قبل الموعد';

  @override
  String get recurrence => 'التكرار';

  @override
  String get recurrenceNone => 'بدون';

  @override
  String get recurrenceDaily => 'يومياً';

  @override
  String get recurrenceWeekly => 'أسبوعياً';

  @override
  String get recurrenceMonthly => 'شهرياً';

  @override
  String get frequency => 'التكرار';

  @override
  String get frequencyDaily => 'كل يوم';

  @override
  String get frequencySpecificDays => 'أيام محددة';

  @override
  String get monday => 'إثن';

  @override
  String get tuesday => 'ثلا';

  @override
  String get wednesday => 'أرب';

  @override
  String get thursday => 'خمي';

  @override
  String get friday => 'جمع';

  @override
  String get saturday => 'سبت';

  @override
  String get sunday => 'أحد';

  @override
  String get streak => 'التتابع';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يوماً',
      few: '$count أيام',
      two: 'يومان',
      one: 'يوم واحد',
      zero: 'بدون تتابع',
    );
    return '$_temp0';
  }

  @override
  String get progress => 'التقدّم';

  @override
  String get language => 'اللغة';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get noTasks => 'لا توجد مهام';

  @override
  String get noEvents => 'لا توجد أحداث';

  @override
  String get noHabits => 'لا توجد عادات';

  @override
  String get noGoals => 'لا توجد أهداف';

  @override
  String get markDone => 'تم الإنجاز';

  @override
  String get markUndone => 'إلغاء الإنجاز';

  @override
  String get linkToGoal => 'ربط بهدف';

  @override
  String get noGoal => 'بدون هدف';

  @override
  String get targetDate => 'تاريخ الهدف';

  @override
  String get subtasks => 'المهام الفرعية';

  @override
  String get addSubtask => 'إضافة مهمة فرعية';

  @override
  String get tasksToday => 'مهام اليوم';

  @override
  String get eventsToday => 'أحداث اليوم';

  @override
  String get selectDate => 'اختر التاريخ';

  @override
  String get selectTime => 'اختر الوقت';

  @override
  String get permissionsNotifications => 'الإشعارات';

  @override
  String get permissionGranted => 'مفعّلة';

  @override
  String get permissionDenied => 'غير مفعّلة — اضغط للطلب';

  @override
  String get confirmDelete => 'حذف هذا العنصر؟';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get completed => 'مكتمل';

  @override
  String get active => 'نشط';

  @override
  String get archived => 'مؤرشف';

  @override
  String get archive => 'أرشفة';

  @override
  String get inbox => 'الوارد';

  @override
  String get timeline => 'الجدول';

  @override
  String get ai => 'المساعد';

  @override
  String get duration => 'المدة';

  @override
  String get startTime => 'وقت البدء';

  @override
  String get icon => 'الأيقونة';

  @override
  String get color => 'اللون';

  @override
  String get reschedule => 'إعادة الجدولة';

  @override
  String get moveToInbox => 'نقل إلى الوارد';

  @override
  String get organize => 'التنظيم';

  @override
  String get when => 'متى؟';

  @override
  String get newTaskHeader => 'مهمة جديدة';

  @override
  String get newTaskWhat => 'ماذا؟';

  @override
  String get newTaskTitleHint => 'اسم المهمة';

  @override
  String get newTaskContinue => 'متابعة';

  @override
  String get inboxEmptyTitle => 'أفكارك غير المنظّمة';

  @override
  String get inboxEmptyMessage =>
      'التقط المهام والأفكار حين تأتيك، وانقلها إلى الجدول حين تكون جاهزاً لجدولتها.';

  @override
  String get newInboxTask => 'مهمة وارد جديدة';

  @override
  String get aiAssistant => 'المساعد الذكي';

  @override
  String get aiAssistantHint =>
      'اضبط نموذج اللغة المحلي للتخطيط بمساعدة الذكاء الاصطناعي';

  @override
  String get aiBaseUrl => 'عنوان الخادم';

  @override
  String get aiModel => 'النموذج';

  @override
  String get aiEnabled => 'تفعيل المساعد الذكي';

  @override
  String get aiTestConnection => 'اختبار الاتصال';

  @override
  String get aiConnectionOk => 'تم الاتصال بنجاح';

  @override
  String get aiConnectionFailed => 'فشل الاتصال — تحقّق من العنوان والنموذج';

  @override
  String get aiUnavailable => 'المساعد غير متاح — تحقّق من الإعدادات أو الشبكة';

  @override
  String get aiDisabledHint => 'فعّل المساعد الذكي من الإعدادات لبدء التخطيط';

  @override
  String get aiUsageHint =>
      'وجّه العنوان إلى خادم متوافق مع واجهة OpenAI (مثل LM Studio أو Ollama) — يجب أن يطابق اسم النموذج ما يوفّره الخادم.';

  @override
  String get aiGreeting => 'مرحباً!';

  @override
  String get aiGreetingQuestion => 'ماذا تريد أن تُنجز اليوم؟';

  @override
  String get aiSuggestionsLabel => 'جرّب أحد هذه';

  @override
  String get aiSuggestPlanDay => 'خطّط يومي';

  @override
  String get aiSuggestStartHabit => 'ساعدني في بدء عادة جديدة';

  @override
  String get aiSuggestItinerary => 'أنشئ خطة لعطلة الأسبوع';

  @override
  String get aiSuggestBrainstorm => 'عصف ذهني لمشروع';

  @override
  String get aiInputHint => 'أخبرني بخططك…';

  @override
  String get newChat => 'محادثة جديدة';

  @override
  String get renameChat => 'إعادة تسمية المحادثة';

  @override
  String aiCreatedTask(String title) {
    return 'تمت إضافة المهمة: $title';
  }

  @override
  String aiCreatedEvent(String title) {
    return 'تمت إضافة الحدث: $title';
  }

  @override
  String aiCreatedHabit(String name) {
    return 'تمت إضافة العادة: $name';
  }

  @override
  String aiCreatedGoal(String title) {
    return 'تمت إضافة الهدف: $title';
  }

  @override
  String aiUpdatedTask(String title) {
    return 'تم تحديث المهمة: $title';
  }

  @override
  String aiDeletedTask(String title) {
    return 'تم حذف المهمة: $title';
  }

  @override
  String aiToggledTask(String title) {
    return 'تم تبديل حالة المهمة: $title';
  }

  @override
  String aiUpdatedEvent(String title) {
    return 'تم تحديث الحدث: $title';
  }

  @override
  String aiDeletedEvent(String title) {
    return 'تم حذف الحدث: $title';
  }

  @override
  String aiUpdatedHabit(String name) {
    return 'تم تحديث العادة: $name';
  }

  @override
  String aiDeletedHabit(String name) {
    return 'تم حذف العادة: $name';
  }

  @override
  String aiToggledHabit(String name) {
    return 'تم تبديل حالة العادة: $name';
  }

  @override
  String aiUpdatedGoal(String title) {
    return 'تم تحديث الهدف: $title';
  }

  @override
  String aiDeletedGoal(String title) {
    return 'تم حذف الهدف: $title';
  }

  @override
  String aiArchivedGoal(String title) {
    return 'تم أرشفة الهدف: $title';
  }

  @override
  String get aiNotFound => 'لم أجد هذا العنصر — هل يمكنك التوضيح؟';

  @override
  String aiCreatedPlan(int goals, int habits, int tasks) {
    return 'الخطة: $goals هدف في الإعدادات←الأهداف، $habits عادة على الجدول، $tasks مهمة على الجدول/الوارد';
  }

  @override
  String get startListening => 'اضغط للتحدث';

  @override
  String get stopListening => 'إيقاف الاستماع';

  @override
  String get speechUnavailable =>
      'التعرف على الكلام غير متاح — تحقق من إذن الميكروفون';

  @override
  String get submit => 'إرسال';

  @override
  String get convertChatToPlan => '✨ حوّل المحادثة إلى خطة';

  @override
  String get reviewPlan => 'مراجعة الخطة';

  @override
  String planGoalsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count هدف',
      many: '$count هدفاً',
      few: '$count أهداف',
      two: 'هدفان',
      one: 'هدف واحد',
      zero: 'بدون أهداف',
    );
    return '$_temp0';
  }

  @override
  String planHabitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عادة',
      many: '$count عادة',
      few: '$count عادات',
      two: 'عادتان',
      one: 'عادة واحدة',
      zero: 'بدون عادات',
    );
    return '$_temp0';
  }

  @override
  String planTasksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مهمة',
      many: '$count مهمة',
      few: '$count مهام',
      two: 'مهمتان',
      one: 'مهمة واحدة',
      zero: 'بدون مهام',
    );
    return '$_temp0';
  }

  @override
  String commitItems(int count) {
    return 'أضف $count عنصراً';
  }

  @override
  String get emptyPlan => 'لا يوجد ما يُضاف';

  @override
  String get generateSubtasksAI => '✨ توليد بالذكاء الاصطناعي';

  @override
  String get linkExistingTasks => 'ربط مهام موجودة';

  @override
  String linkCount(int count) {
    return 'ربط $count';
  }

  @override
  String get noUnlinkedTasks => 'لا توجد مهام غير مرتبطة';

  @override
  String get todayStat => 'اليوم';

  @override
  String get inboxStat => 'الوارد';

  @override
  String get doneStat => 'منجز';

  @override
  String get preferences => 'التفضيلات';

  @override
  String get notificationsAndAlerts => 'الإشعارات والتنبيهات';

  @override
  String get customization => 'التخصيص';

  @override
  String get advanced => 'متقدّم';

  @override
  String get appColor => 'لون التطبيق';

  @override
  String get appColorHint =>
      'خصّص لون التطبيق ليناسب ذوقك. لن يؤثّر ذلك على ألوان المهام الحالية.';

  @override
  String get layout => 'التخطيط';

  @override
  String get layoutFull => 'كامل';

  @override
  String get layoutSimplified => 'مبسّط';

  @override
  String get layoutMinimal => 'أدنى';

  @override
  String get layoutHint =>
      'يُخفي التخطيطان المبسّط والأدنى بعض التفاصيل لتقليل التشتّت.';

  @override
  String get alertsIntro =>
      'التنبيهات تذكّرك بالمهام القادمة حتى لا تنساها. اضبط تنبيهات افتراضية وعدّلها لكل مهمة.';

  @override
  String get enabledOnThisDevice => 'مُفعّل على هذا الجهاز';

  @override
  String get alarms => 'المنبّهات';

  @override
  String get alarmsHint =>
      'انتقل إلى إعدادات المنبّهات في جهازك للسماح أو منع التطبيق من جدولة الإجراءات الحسّاسة للوقت.';

  @override
  String get defaultAlerts => 'التنبيهات الافتراضية';

  @override
  String get atStartOfTask => 'عند بدء المهمة';

  @override
  String minutesBeforeStart(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'قبل $n دقيقة من البدء',
      many: 'قبل $n دقيقة من البدء',
      few: 'قبل $n دقائق من البدء',
      two: 'قبل دقيقتين من البدء',
      one: 'قبل دقيقة من البدء',
    );
    return '$_temp0';
  }

  @override
  String get addNewAlert => '+ إضافة تنبيه جديد';

  @override
  String get firstDayOfWeek => 'أول يوم في الأسبوع';

  @override
  String get languageHint =>
      'يمكنك تغيير لغة التطبيق من إعدادات النظام أو من هنا.';

  @override
  String get resetApp => 'إعادة تعيين التطبيق';

  @override
  String get resetAppWarning =>
      'إعادة تعيين التطبيق ستمحو كافة الإعدادات والمهام بشكل دائم. هذا الإجراء لا يمكن التراجع عنه!';

  @override
  String get confirmReset => 'إعادة تعيين التطبيق؟';

  @override
  String get goalReminders => 'تذكيرات الأهداف';

  @override
  String get goalPulsesTitle => 'تذكير دوري بالأهداف';

  @override
  String get goalPulsesSubtitle =>
      'يرسل تذكيراً بأهدافك النشطة كل 3 ساعات تقريباً خلال النهار (9، 12، 15، 18، 21).';

  @override
  String get onbSkip => 'تخطّي';

  @override
  String get onbNext => 'التالي';

  @override
  String get onbGetStarted => 'لنبدأ';

  @override
  String get onbWelcomeTitle => 'أهلاً بك في 01-Planner';

  @override
  String get onbWelcomeBody =>
      'منظّم يومي يجمع بين خط زمني أنيق ومساعد ذكي يفهمك فعلاً.';

  @override
  String get onbTimelineTitle => 'خطّط يومك على الخط الزمني';

  @override
  String get onbTimelineBody =>
      'اجعل المهام زمنية، تفادى التداخلات، وشاهد يومك بلمحة. زر + دائماً في متناولك.';

  @override
  String get onbGoalsTitle => 'حوّل أهدافك إلى تقدّم حقيقي';

  @override
  String get onbGoalsBody =>
      'قسّم الهدف إلى مهام فرعية مجدولة، واحصل على تذكيرات دورية كي لا يتوقّف شيء.';

  @override
  String get onbAiTitle => 'دع المساعد يصيغ الخطة';

  @override
  String get onbAiBody =>
      'تحدّث بلغتك (عربي أو إنجليزي)، ثمّ اضغط (حوّل إلى خطة) وراجع كل عنصر قبل إضافته.';

  @override
  String get noPlansToday => 'لا خطط في هذا اليوم';

  @override
  String gapFreeMessage(String gap) {
    return '$gap متاحة. تود إضافة شيء؟';
  }

  @override
  String get timelineConflictTitle => 'تعارض في الوقت';

  @override
  String get timelineConflictBody => 'يتعارض هذا الوقت مع:';

  @override
  String get saveAnyway => 'حفظ بأي حال';

  @override
  String get moveToNextFree => 'انقل إلى أقرب وقت متاح';

  @override
  String get noFreeSlotFound => 'تعذّر إيجاد وقت متاح خلال الـ30 يوماً القادمة';

  @override
  String get availableHours => 'ساعات التوفّر';

  @override
  String get weekendDays => 'أيام عطلة الأسبوع';

  @override
  String get planGenerating => 'جارٍ إنشاء الخطة — يمكنك إغلاق التطبيق…';

  @override
  String get riseAndShine => 'بداية اليوم';

  @override
  String get windDown => 'نهاية اليوم';

  @override
  String get youveGot => 'لديك';

  @override
  String tilNext(String target) {
    return 'حتى $target';
  }

  @override
  String get nextItem => 'الانطلاق';

  @override
  String conflictsWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يتعارض مع $count عنصر',
      many: 'يتعارض مع $count عنصراً',
      few: 'يتعارض مع $count عناصر',
      two: 'يتعارض مع عنصرين',
      one: 'يتعارض مع عنصر واحد',
    );
    return '$_temp0';
  }

  @override
  String get findNextFree => 'اختر أقرب وقت متاح';

  @override
  String get quickAddHint => 'إضافة سريعة بالذكاء الاصطناعي';

  @override
  String get dailyPlan => 'خطة اليوم';

  @override
  String get generatePlan => 'إنشاء خطة';

  @override
  String get proposedPlan => 'الخطة المقترحة';

  @override
  String get acceptPlan => 'قبول';

  @override
  String get rejectPlan => 'رفض';

  @override
  String get wakeTime => 'الاستيقاظ';

  @override
  String get sleepTime => 'النوم';

  @override
  String get inboxBannerMessage => 'المهام غير المجدولة تظهر في الوارد.';

  @override
  String get iconWork => 'عمل';

  @override
  String get iconGym => 'رياضة';

  @override
  String get iconCall => 'مكالمة';

  @override
  String get iconHome => 'منزل';

  @override
  String get iconShop => 'تسوق';

  @override
  String get iconStudy => 'دراسة';

  @override
  String get iconFood => 'طعام';

  @override
  String get iconTravel => 'سفر';

  @override
  String get iconHealth => 'صحة';

  @override
  String get iconMeet => 'اجتماع';

  @override
  String get iconRead => 'قراءة';

  @override
  String get iconIdea => 'فكرة';
}
