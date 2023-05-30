import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ml_depression/Pages/FaceTestWidget.dart';
import 'package:ml_depression/Pages/ReportWidget.dart';
import 'package:ml_depression/Pages/StartupWidget.dart';
import 'package:ml_depression/Pages/TestsWidget.dart';
import 'package:ml_depression/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget(this.prefs, {Key? key}) : super(key: key);

  final SharedPreferences prefs;

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  int segments = 5;
  int todayIndex = 0;
  List<int> segemntsPerDay =
      List.generate(14, (index) => 5); // segments for each day
  List<List<double>> values = List.generate(14, (index) => []);
  List<TimeOfDay> times = [];
  Map<String, List<double>> activityValues = {};

  bool canDoTest = true;
  bool doneTests = false;
  String clockText = "";

  final maxSmallCircleSize = 150.0;

  void load() {
    segments = widget.prefs.getInt(numTestsKey) ?? segments;

    final startDay =
        DateTime.parse(widget.prefs.getString(startingDayKey) ?? "");

    todayIndex = DateUtils.dateOnly(DateTime.now()).difference(startDay).inDays;

    for (int i = 0; i < 14; i++) {
      segemntsPerDay[i] =
          widget.prefs.getInt("$segmentsPerDayKey$i") ?? segments;

      final stringValues = widget.prefs.getStringList("$valuesKey$i");
      values[i] = stringValues == null
          ? values[i]
          : stringValues.map((e) => double.parse(e)).toList();
    }

    segemntsPerDay[todayIndex] = segments;
    widget.prefs.setInt("$segmentsPerDayKey$todayIndex", segments);

    final timesString = widget.prefs.getString(timesKey);
    if (timesString != null && timesString.isNotEmpty) {
      times = timesString
          .replaceAll("[", "")
          .replaceAll("]", "")
          .replaceAll("TimeOfDay(", "")
          .replaceAll(")", "")
          .split(", ")
          .map((String e) => TimeOfDay(
              hour: int.parse(e.split(":")[0]),
              minute: int.parse(e.split(":")[1])))
          .toList()
          .getRange(0, segments)
          .toList();
    }

    final activities = widget.prefs.getStringList(activitiesKey) ?? [];
    for (var a in activities) {
      final aValues = widget.prefs.getStringList("$activityValuesKey$a") ?? [];
      activityValues[a] = aValues
          .map((e) => double.parse(e))
          .toList();
    }



    getTime();
  }

  double getDoubleTime(TimeOfDay timeOfDay) {
    return timeOfDay.hour.toDouble() + (timeOfDay.minute.toDouble() / 60.0);
  }

  TimeOfDay fromDoubleTime(double time) {
    return TimeOfDay(
        hour: time.floor(), minute: ((time - time.floor()) * 60).toInt());
  }

  void getTime() {
    if (todayIndex == 13 && values[todayIndex].length == segments) {
      canDoTest = false;
      doneTests = true;
      clockText = "You have completed all tests!";
      return;
    }

    final sorter = ((a, b) => getDoubleTime(a).compareTo(getDoubleTime(b)));

    final now = TimeOfDay.now();

    int prevIndex;

    if (times.contains(now)) {
      times.sort(sorter);
      final index = times.indexOf(now);

      prevIndex = index;
    } else {
      times.add(now);
      times.sort(sorter);
      final index = times.indexOf(now);
      times.remove(now);

      prevIndex = index - 1;
    }

    if (values[todayIndex].length > prevIndex) {
      canDoTest = false;
      if (prevIndex >= times.length - 1) {
        clockText = "You have done all tests for today.";
      } else {
        clockText = "Upcoming test on ${times[prevIndex + 1].format(context)}";
      }
    } else {
      canDoTest = true;
      clockText =
          "${times[values[todayIndex].length].format(context)} test is open.";
    }
  }

  @override
  Widget build(BuildContext context) {
    load();

    print("BUILDING THE BUILDE");

    MediaQueryData queryData = MediaQuery.of(context);
    final screenWidth = queryData.size.width;
    // final screenHeight = queryData.size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text("ML Depression"),
        // actions: [
        //   IconButton(
        //     onPressed: () {
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(
        //           builder: (context) => const StartupWidget(
        //             title: "Settings",
        //           ),
        //         ),
        //       );
        //     },
        //     icon: const Icon(Icons.settings),
        //   )
        // ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                  width: 250,
                  height: 250,
                  child: Stack(alignment: Alignment.center, children: [
                    CircleProgress(segments, values[todayIndex]),
                    Text(
                      "${values[todayIndex].length} / $segments",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  ])),
              Hero(
                tag: "alldays",
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(
                    width:
                        min((screenWidth - 20) + 40, maxSmallCircleSize * 7 + 40),
                    child: Card(
                      margin: const EdgeInsets.all(0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 25.0),
                            child: Text(
                              "All days ",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          ...List.generate(
                            2,
                            (index) => Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List<Widget>.generate(
                                7,
                                (innerIndex) {
                                  return SizedBox(
                                    width: min((screenWidth - 20) / 7,
                                        maxSmallCircleSize),
                                    height: min((screenWidth - 20) / 7,
                                        maxSmallCircleSize),
                                    child: Container(
                                        decoration:
                                            todayIndex == innerIndex + (index * 7)
                                                ? BoxDecoration(
                                                    border: Border.all(
                                                      color: Colors.blue,
                                                      width: 3,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(10),
                                                  )
                                                : null,
                                        child: CircleProgress(
                                          segemntsPerDay[
                                              innerIndex + (index * 7)],
                                          values[innerIndex + (index * 7)],
                                          borderThickness: 0.25,
                                          dividerThickness: 5,
                                        )),
                                  );
                                },
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
                child: Text(
                  clockText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: doneTests
                    ? FloatingActionButton.extended(
                        heroTag: "myheroaca",
                        onPressed:() {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReportWidget(segments, segemntsPerDay, values, times, activityValues, screenWidth),
                                  ),
                                );
                              },
                        label: const Text(
                          "Open report",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        icon: const Icon(Icons.text_snippet, size: 24),
                      )
                    : FloatingActionButton.extended(
                        heroTag: "myheroaca",
                        backgroundColor: canDoTest ? Colors.blue : Colors.grey,
                        onPressed: canDoTest
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FaceTestWidget(
                                        "$todayIndex ${values[todayIndex].length}"),
                                  ),
                                ).then((value) {
                                  setState(() {
                                    load();
                                  });
                                });
                              }
                            : null,
                        label: const Text(
                          "Start test",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow, size: 24),
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// This widget represents a circular progress bar, that is divided into segments.
class CircleProgress extends StatelessWidget {
  const CircleProgress(this.segment, this.percents,
      {Key? key,
      this.circleRadius = 0.7,
      this.borderThickness = 0.2,
      this.dividerThickness = 10})
      : super(key: key);

  static CircleProgress getRandom({bool mode = false, bool on = true}) {
    if (mode) {
      if (on) {
        return CircleProgress(
            5, List<double>.generate(5, (index) => Random().nextDouble()),
            borderThickness: 0.4, dividerThickness: 1);
      }
      return const CircleProgress(5, [],
          borderThickness: 0.4, dividerThickness: 1);
    }
    return CircleProgress(
        5,
        List<double>.generate(
            Random().nextInt(5), (index) => Random().nextDouble()));
  }

  // Number of segments.
  final int segment;

  // Percent of each segment.
  final List<double> percents;

  // Determines size of the circle.
  final double circleRadius;

  // Thickness of the border. 1 = border covers the whole circle.
  final double borderThickness;

  final double dividerThickness;

  @override
  Widget build(BuildContext context) {
    return SfRadialGauge(
      axes: [
        // Create primary radial axis
        RadialAxis(
          minimum: 0,
          maximum: segment.toDouble(),
          interval: 1,
          showLabels: false,
          showTicks: false,
          startAngle: 270,
          endAngle: 270,
          radiusFactor: circleRadius,
          axisLineStyle: AxisLineStyle(
            thickness: borderThickness,
            color: const Color.fromARGB(30, 0, 169, 181),
            thicknessUnit: GaugeSizeUnit.factor,
          ),
          ranges: [
            GaugeRange(
              startValue: 0,
              endValue: segment.toDouble(),
              color: Colors.blueGrey,
              startWidth: 0.04,
              endWidth: 0.04,
              sizeUnit: GaugeSizeUnit.factor,
            ),
          ],
          pointers: List<GaugePointer>.generate(
            percents.length,
            (index) => RangePointer(
              value: (percents.length - index).toDouble(),
              width: borderThickness,
              sizeUnit: GaugeSizeUnit.factor,
              pointerOffset: 0,
              color: HSVColor.fromAHSV(
                      1, percents[percents.length - 1 - index] * 100, 1, 1)
                  .toColor(),
            ),
          ),
        ),
        // Create secondary radial axis for segmented line
        RadialAxis(
          minimum: 0,
          maximum: segment.toDouble(),
          interval: 1,
          showLabels: false,
          showTicks: true,
          showAxisLine: false,
          offsetUnit: GaugeSizeUnit.factor,
          minorTicksPerInterval: 0,
          startAngle: 270,
          endAngle: 270,
          radiusFactor: circleRadius,
          majorTickStyle: MajorTickStyle(
              length: borderThickness,
              lengthUnit: GaugeSizeUnit.factor,
              thickness: dividerThickness.toDouble(),
              color: Colors.white),
        )
      ],
    );
  }
}
