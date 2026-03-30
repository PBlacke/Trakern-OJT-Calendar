import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/ojt_record.dart';

class OJTCalendar extends StatefulWidget {
  final Function(DateTime) onDaySelected;
  final List<OJTRecord> records;
  const OJTCalendar({super.key, required this.onDaySelected, required this.records});

  @override
  State<OJTCalendar> createState() => _OJTCalendarState();
}

class _OJTCalendarState extends State<OJTCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  OJTRecord? _getRecordForDate(DateTime date) {
    try {
      return widget.records.firstWhere((r) =>
          r.date.year == date.year &&
          r.date.month == date.month &&
          r.date.day == date.day);
    } catch (e) {
      return null;
    }
  }

  Color? _getHoursColor(OJTRecord? record) {
    if (record == null) return null;
    if (record.isAbsent) return Colors.red;
    if (record.totalHours >= 8) return Colors.green;
    if (record.totalHours >= 4) return const Color.fromARGB(255, 255, 192, 1);  // light orange
    return const Color.fromARGB(255, 255, 136, 0);  // dark orange
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime(2024, 1, 1),
      lastDay: DateTime(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
      onDaySelected: (selected, focused) {
        setState(() {
          _selectedDay = selected;
          _focusedDay = focused;
        });
        widget.onDaySelected(selected);
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, date, events) {
          // Only show days that belong to the currently focused month
          if (date.month != _focusedDay.month) {
            return Container();
          }

          final record = _getRecordForDate(date);
          final isSelected = isSameDay(date, _selectedDay);
          final isToday = isSameDay(date, DateTime.now());

          BoxDecoration? decoration;
          if (isSelected) {
            decoration = BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            );
          } else if (isToday) {
            decoration = BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            );
          }

          // Determine what to show below the day number
          Widget? subtitle;
            if (record != null) {
              if (record.isHoliday) {
                subtitle = Text(
                  'Hol',
                  style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                );
              } else if (record.isAbsent) {
                subtitle = Text(
                  'Abs',
                  style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                );
              } else if (record.totalHours > 0) {
                final hoursColor = _getHoursColor(record); // <-- call your method
                subtitle = Text(
                  '${record.totalHours.toStringAsFixed(1)}h',
                  style: TextStyle(fontSize: 10, color: hoursColor, fontWeight: FontWeight.w500),
                );
              }
            }

          return Container(
            decoration: decoration,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  date.day.toString(),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (date.weekday == DateTime.saturday ||
                                date.weekday == DateTime.sunday
                            ? Colors.red
                            : null),
                    fontWeight: isToday ? FontWeight.bold : null,
                  ),
                ),
                if (subtitle != null) subtitle,
              ],
            ),
          );
        },
        outsideBuilder: (context, date, events) {
          return Container(); // hide days outside month
        },
      ),
      calendarStyle: CalendarStyle(
        cellMargin: const EdgeInsets.all(4),
        defaultTextStyle: const TextStyle(fontSize: 12),
        weekendTextStyle: const TextStyle(fontSize: 12, color: Colors.red),
        todayTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        selectedTextStyle: const TextStyle(fontSize: 12, color: Colors.white),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
    );
  }
}