import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:flutter/scheduler.dart';
import 'package:velocity_x/velocity_x.dart';
// import 'package:bitrec/model/sample_view.dart';

class TaskCalender extends StatefulWidget {
  const TaskCalender({super.key});

  @override
  State<TaskCalender> createState() => _TaskCalenderState();
}

class _TaskCalenderState extends State<TaskCalender> {
  final CalendarController _calendarController = CalendarController();
  final GlobalKey _globalKey = GlobalKey();
  List<DateTime> blackoutDates = <DateTime>[];

  final List<String> _subjectCollection = <String>[];
  final List<Color> _colorCollection = <Color>[];

  final List<DateTime> _blackoutDates = <DateTime>[];

  bool showLeadingAndTrailingDates = true;
  bool showDatePickerButton = true;
  bool allowViewNavigation = true;
  bool showCurrentTimeIndicator = true;

  ViewNavigationMode viewNavigationMode = ViewNavigationMode.snap;
  String viewNavigationModeString = 'snap';
  bool showWeekNumber = false;
  String numberOfDaysString = 'default';
  int numberOfDays = -1;

  /// Creates the required appointment details as a list.
  void addAppointmentDetails() {
    _subjectCollection.add('General Meeting');
    _subjectCollection.add('Plan Execution');
    _subjectCollection.add('Project Plan');
    _subjectCollection.add('Consulting');
    _subjectCollection.add('Support');
    _subjectCollection.add('Development Meeting');
    _subjectCollection.add('Scrum');
    _subjectCollection.add('Project Completion');
    _subjectCollection.add('Release updates');
    _subjectCollection.add('Performance Check');

    _colorCollection.add(const Color(0xFF0F8644));
    _colorCollection.add(const Color(0xFF8B1FA9));
    _colorCollection.add(const Color(0xFFD20100));
    _colorCollection.add(const Color(0xFFFC571D));
    _colorCollection.add(const Color(0xFF36B37B));
    _colorCollection.add(const Color(0xFF01A1EF));
    _colorCollection.add(const Color(0xFF3D4FB5));
    _colorCollection.add(const Color(0xFFE47C73));
    _colorCollection.add(const Color(0xFF636363));
    _colorCollection.add(const Color(0xFF0A8043));
  }

  final _MeetingDataSource _events = _MeetingDataSource(<_Meeting>[]);
  final DateTime _minDate = DateTime.now().subtract(const Duration(days: 365 ~/ 2)), _maxDate = DateTime.now().add(const Duration(days: 365 ~/ 2));

  Widget scheduleViewBuilder(BuildContext buildContext, ScheduleViewMonthHeaderDetails details) {
    final String monthName = _getMonthDate(details.date.month);
    return Text(
      '$monthName ${details.date.year}',
      style: const TextStyle(fontSize: 18),
    );
  }

  final List<String> viewNavigationModeList = <String>['snap', 'none'].toList();
  final List<String> numberOfDaysList = <String>['default', '1 day', '2 days', '3 days', '4 days', '5 days', '6 days', '7 days'].toList();

  final List<CalendarView> _allowedViews = <CalendarView>[
    CalendarView.day,
    CalendarView.week,
    CalendarView.workWeek,
    CalendarView.timelineDay,
    CalendarView.timelineWeek,
    CalendarView.timelineWorkWeek,
    CalendarView.month,
    CalendarView.schedule
  ];

  /// Allows/Restrict switching to previous/next views through swipe interaction
  void onViewNavigationModeChange(String value) {
    viewNavigationModeString = value;
    if (value == 'snap') {
      viewNavigationMode = ViewNavigationMode.snap;
    } else if (value == 'none') {
      viewNavigationMode = ViewNavigationMode.none;
    }
    setState(() {
      /// update the view navigation mode changes
    });
  }

  @override
  void initState() {
    _calendarController.view = CalendarView.week;
    addAppointmentDetails();
    super.initState();
  }

  /// The method called whenever the calendar view navigated to previous/next
  /// view or switched to different calendar view, based on the view changed
  /// details new appointment collection added to the calendar
  void _onViewChanged(ViewChangedDetails visibleDatesChangedDetails) {
    final List<_Meeting> appointment = <_Meeting>[];

    _events.appointments.clear();
    final Random random = Random();
    final List<DateTime> blockedDates = <DateTime>[];
    if (_calendarController.view == CalendarView.month || _calendarController.view == CalendarView.timelineMonth) {
      for (int i = 0; i < 5; i++) {
        blockedDates.add(visibleDatesChangedDetails.visibleDates[random.nextInt(visibleDatesChangedDetails.visibleDates.length)]);
      }
    }

    SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
      setState(() {
        if (_calendarController.view == CalendarView.month || _calendarController.view == CalendarView.timelineMonth) {
          blackoutDates = blockedDates;
        } else {
          blackoutDates.clear();
        }
      });
    });

    /// Creates new appointment collection based on
    /// the visible dates in calendar.
    if (_calendarController.view != CalendarView.schedule) {
      for (int i = 0; i < visibleDatesChangedDetails.visibleDates.length; i++) {
        final DateTime date = visibleDatesChangedDetails.visibleDates[i];
        if (blockedDates.isNotEmpty && blockedDates.contains(date)) {
          continue;
        }
        final int count = 1 + random.nextInt(3);
        for (int j = 0; j < count; j++) {
          final DateTime startDate = DateTime(date.year, date.month, date.day, 8 + random.nextInt(8));
          appointment.add(_Meeting(
            _subjectCollection[random.nextInt(7)],
            startDate,
            startDate.add(Duration(hours: random.nextInt(3))),
            _colorCollection[random.nextInt(9)],
            false,
          ));
        }
      }
    } else {
      final DateTime rangeStartDate = DateTime.now().add(const Duration(days: -(365 ~/ 2)));
      final DateTime rangeEndDate = DateTime.now().add(const Duration(days: 365));
      for (DateTime i = rangeStartDate; i.isBefore(rangeEndDate); i = i.add(const Duration(days: 1))) {
        final DateTime date = i;
        final int count = 1 + random.nextInt(3);
        for (int j = 0; j < count; j++) {
          final DateTime startDate = DateTime(date.year, date.month, date.day, 8 + random.nextInt(8));
          appointment.add(_Meeting(
            _subjectCollection[random.nextInt(7)],
            startDate,
            startDate.add(Duration(hours: random.nextInt(3))),
            _colorCollection[random.nextInt(9)],
            false,
          ));
        }
      }
    }

    for (int i = 0; i < appointment.length; i++) {
      _events.appointments.add(appointment[i]);
    }

    /// Resets the newly created appointment collection to render
    /// the appointments on the visible dates.
    _events.notifyListeners(CalendarDataSourceAction.reset, appointment);
  }

  /// Allows to switching the days count customization in calendar.
  void customNumberOfDaysInView(String value) {
    numberOfDaysString = value;
    if (value == 'default') {
      numberOfDays = -1;
    } else if (value == '1 day') {
      numberOfDays = 1;
    } else if (value == '2 days') {
      numberOfDays = 2;
    } else if (value == '3 days') {
      numberOfDays = 3;
    } else if (value == '4 days') {
      numberOfDays = 4;
    } else if (value == '5 days') {
      numberOfDays = 5;
    } else if (value == '6 days') {
      numberOfDays = 6;
    } else if (value == '7 days') {
      numberOfDays = 7;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final Widget calendar = Theme(
      key: _globalKey,
      data: ThemeData.dark(),
      child: _getGettingStartedCalendar(
        _calendarController,
        _events,
        _onViewChanged,
        _minDate,
        _maxDate,
        scheduleViewBuilder,
      ),
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        child: const Icon(Icons.graphic_eq),
        onPressed: () {
          modalSheet(
            context,
            numberOfDaysString: numberOfDaysString,
            allowViewNavigation: allowViewNavigation,
            showDatePickerButton: showDatePickerButton,
            showLeadingAndTrailingDates: showLeadingAndTrailingDates,
            showCurrentTimeIndicator: showCurrentTimeIndicator,
            showWeekNumber: showWeekNumber,
            viewNavigationModeString: viewNavigationModeString,
            viewNavigationModeList: viewNavigationModeList,
            onViewNavigationModeChange: onViewNavigationModeChange,
            numberOfDaysList: numberOfDaysList,
            customNumberOfDaysInView: customNumberOfDaysInView,
            setState: setState,
          );
        },
      ),
      body: calendar,
    );
  }

  /// Returns the calendar widget based on the properties passed.
  SfCalendar _getGettingStartedCalendar(
      [CalendarController? calendarController,
      CalendarDataSource? calendarDataSource,
      ViewChangedCallback? viewChangedCallback,
      DateTime? minDate,
      DateTime? maxDate,
      dynamic scheduleViewBuilder]) {
    return SfCalendar(
      controller: calendarController,
      dataSource: calendarDataSource,
      allowedViews: _allowedViews,
      scheduleViewMonthHeaderBuilder: scheduleViewBuilder,
      showDatePickerButton: showDatePickerButton,
      allowViewNavigation: allowViewNavigation,
      showCurrentTimeIndicator: showCurrentTimeIndicator,
      onViewChanged: viewChangedCallback,
      blackoutDates: _blackoutDates,
      minDate: minDate,
      maxDate: maxDate,
      monthViewSettings: MonthViewSettings(
        appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
        showTrailingAndLeadingDates: showLeadingAndTrailingDates,
      ),
      blackoutDatesTextStyle: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red),
      timeSlotViewSettings: TimeSlotViewSettings(numberOfDaysInView: numberOfDays, minimumAppointmentDuration: const Duration(minutes: 60)),
      viewNavigationMode: viewNavigationMode,
      showWeekNumber: showWeekNumber,
    );
  }
}

/// Returns the month name based on the month value passed from date.
String _getMonthDate(int month) {
  if (month == 01) {
    return 'January';
  } else if (month == 02) {
    return 'February';
  } else if (month == 03) {
    return 'March';
  } else if (month == 04) {
    return 'April';
  } else if (month == 05) {
    return 'May';
  } else if (month == 06) {
    return 'June';
  } else if (month == 07) {
    return 'July';
  } else if (month == 08) {
    return 'August';
  } else if (month == 09) {
    return 'September';
  } else if (month == 10) {
    return 'October';
  } else if (month == 11) {
    return 'November';
  } else {
    return 'December';
  }
}

/// Returns the builder for schedule view.
Widget scheduleViewBuilder(BuildContext buildContext, ScheduleViewMonthHeaderDetails details) {
  final String monthName = _getMonthDate(details.date.month);
  return Stack(
    children: <Widget>[
      Image(image: ExactAssetImage('images/$monthName.png'), fit: BoxFit.cover, width: details.bounds.width, height: details.bounds.height),
      Positioned(
        left: 55,
        right: 0,
        top: 20,
        bottom: 0,
        child: Text(
          '$monthName ${details.date.year}',
          style: const TextStyle(fontSize: 18),
        ),
      )
    ],
  );
}

/// An object to set the appointment collection data source to collection, which
/// used to map the custom appointment data to the calendar appointment, and
/// allows to add, remove or reset the appointment collection.
class _MeetingDataSource extends CalendarDataSource<_Meeting> {
  _MeetingDataSource(this.source);

  List<_Meeting> source;

  @override
  List<dynamic> get appointments => source;

  @override
  DateTime getStartTime(int index) {
    return source[index].from;
  }

  @override
  DateTime getEndTime(int index) {
    return source[index].to;
  }

  @override
  bool isAllDay(int index) {
    return source[index].isAllDay;
  }

  @override
  String getSubject(int index) {
    return source[index].eventName;
  }

  @override
  Color getColor(int index) {
    return source[index].background;
  }

  @override
  _Meeting convertAppointmentToObject(_Meeting eventName, Appointment appointment) {
    return _Meeting(appointment.subject, appointment.startTime, appointment.endTime, appointment.color, appointment.isAllDay);
  }
}

/// Custom business object class which contains properties to hold the detailed
/// information about the event data which will be rendered in calendar.
class _Meeting {
  _Meeting(this.eventName, this.from, this.to, this.background, this.isAllDay);

  String eventName;
  DateTime from;
  DateTime to;
  Color background;
  bool isAllDay;
}

void modalSheet(
  BuildContext context, {
  required bool showWeekNumber,
  required bool allowViewNavigation,
  required bool showDatePickerButton,
  required bool showCurrentTimeIndicator,
  required bool showLeadingAndTrailingDates,
  required String numberOfDaysString,
  required String viewNavigationModeString,
  required List<String> viewNavigationModeList,
  required List<String> numberOfDaysList,
  required void Function(String) onViewNavigationModeChange,
  required void Function(String) customNumberOfDaysInView,
  required void Function(void Function()) setState,
}) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter stateSetter) {
          return ListView(
            shrinkWrap: true,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text('Allow view navigation', softWrap: false),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: Transform.scale(
                        scale: 0.8,
                        child: CupertinoSwitch(
                          value: allowViewNavigation,
                          onChanged: (bool value) {
                            setState(() {
                              allowViewNavigation = value;
                              stateSetter(() {});
                            });
                          },
                        )),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text('Show date picker button', softWrap: false),
                  Container(
                    padding: EdgeInsets.zero,
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: Transform.scale(
                          scale: 0.8,
                          child: CupertinoSwitch(
                            value: showDatePickerButton,
                            onChanged: (bool value) {
                              setState(() {
                                showDatePickerButton = value;
                                stateSetter(() {});
                              });
                            },
                          )),
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Expanded(
                    child: Text('Show trailing and leading dates', softWrap: false),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Transform.scale(
                        scale: 0.8,
                        child: CupertinoSwitch(
                          value: showLeadingAndTrailingDates,
                          onChanged: (bool value) {
                            setState(() {
                              showLeadingAndTrailingDates = value;
                              stateSetter(() {});
                            });
                          },
                        )),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Expanded(child: Text('Show current time indicator', softWrap: false)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Transform.scale(
                        scale: 0.8,
                        child: CupertinoSwitch(
                          value: showCurrentTimeIndicator,
                          onChanged: (bool value) {
                            setState(() {
                              showCurrentTimeIndicator = value;
                              stateSetter(() {});
                            });
                          },
                        )),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Expanded(child: Text('Show week number', softWrap: false)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Transform.scale(
                        scale: 0.8,
                        child: CupertinoSwitch(
                          value: showWeekNumber,
                          onChanged: (bool value) {
                            setState(() {
                              showWeekNumber = value;
                              stateSetter(() {});
                            });
                          },
                        )),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  const Expanded(flex: 6, child: Text('View navigation mode', softWrap: false)),
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.only(left: 60),
                      alignment: Alignment.bottomLeft,
                      child: DropdownButton<String>(
                          focusColor: Colors.transparent,
                          underline: Container(color: const Color(0xFFBDBDBD), height: 1),
                          value: viewNavigationModeString,
                          items: viewNavigationModeList.map((String value) {
                            return DropdownMenuItem<String>(value: value, child: Text(value, textAlign: TextAlign.center));
                          }).toList(),
                          onChanged: (dynamic value) {
                            setState(() {
                              onViewNavigationModeChange(value);
                              stateSetter(() {});
                            });
                          }),
                    ),
                  )
                ],
              ),
              Row(
                children: <Widget>[
                  const Expanded(flex: 6, child: Text('Number of days', softWrap: false)),
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.only(left: 60),
                      alignment: Alignment.bottomLeft,
                      child: DropdownButton<String>(
                        focusColor: Colors.transparent,
                        underline: Container(color: const Color(0xFFBDBDBD), height: 1),
                        value: numberOfDaysString,
                        items: numberOfDaysList.map((String value) {
                          return DropdownMenuItem<String>(value: value, child: Text(value, textAlign: TextAlign.center));
                        }).toList(),
                        onChanged: (dynamic value) {
                          setState(() {
                            customNumberOfDaysInView(value);
                            stateSetter(() {});
                          });
                        },
                      ),
                    ),
                  )
                ],
              )
            ],
          ).p20();
        },
      );
    },
  );
}
