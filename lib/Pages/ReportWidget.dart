import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ml_depression/Pages/HomeWidget.dart';

class ReportWidget extends StatelessWidget {
  const ReportWidget(this.segments, this.segemntsPerDay, this.values,
      this.times, this.activityValues, this.screenWidth,
      {Key? key})
      : super(key: key);

  final int segments;
  final List<int> segemntsPerDay;
  final List<List<double>> values;
  final List<TimeOfDay> times;
  final Map<String, List<double>> activityValues;

  final double screenWidth;

  final maxSmallCircleSize = 150.0;

  List<StatsData> getStats() {
    double overall = 0;
    double lowest = 1;
    double highest = 0;

    for (var list in values) {
      final thisRate = list.reduce((a, b) => a + b) / list.length;

      overall += thisRate;

      if (thisRate < lowest) {
        lowest = thisRate;
      }

      if (thisRate > highest) {
        highest = thisRate;
      }
    }

    overall /= values.length;

    overall = 1 - overall;

    return [
      StatsData(Icons.percent,
          "Overall depression rate: %${(overall * 100).toStringAsFixed(1)}"),
      StatsData(Icons.arrow_downward,
          "Lowest depression rate on a day: %${lowest * 100}"),
      StatsData(Icons.arrow_upward,
          "Highest depression rate on a day: %${highest * 100}"),
    ];
  }

  List<StatsData> getAdvices(BuildContext context) {
    double overall = 0;

    List<double> timesRates = List.generate(segments, (index) => 0.0);

    for (var list in values) {
      final thisRate = list.reduce((a, b) => a + b) / list.length;

      overall += thisRate;

      for (int i = 0; i < timesRates.length; i++) {
        timesRates[i] += list[i];
      }
    }

    for (int i = 0; i < segments; i++) {
      timesRates[i] /= 14;
      timesRates[i] = 1 - timesRates[i];
    }

    Map<String, double> activityRate = {};

    for (var act in activityValues.keys) {
      activityRate[act] = activityValues[act]!.reduce((a, b) => a + b) /
          activityValues[act]!.length;
      activityRate[act] = 1 - activityRate[act]!;
    }

    overall /= values.length;

    overall = 1 - overall;

    final List<StatsData> advices = [];

    if (overall <= 0.35) {
      advices.add(const StatsData(Icons.sentiment_satisfied_alt,
          "Your depression rate is normal. You mostly aren't depressed."));
    } else if (overall <= 0.65) {
      advices.add(const StatsData(Icons.sentiment_neutral,
          "Your depression rate is a bit above normal. You may be a bit depressed, but still not to a dangerous rate."));
    } else {
      advices.add(const StatsData(Icons.sentiment_very_dissatisfied,
          "Your depression rate is high. You may have depression, and should seek professional help."));
    }

    final lowestIndex =
        timesRates.indexOf(timesRates.reduce((a, b) => min(a, b)));
    final highestIndex =
        timesRates.indexOf(timesRates.reduce((a, b) => max(a, b)));

    advices.add(StatsData(Icons.sunny,
        "Your depression rate is lowest at ${times[lowestIndex].format(context)}. You should think about what is special about this time, and apply it to the rest of your day."));
    advices.add(StatsData(Icons.thunderstorm,
        "Your depression rate is highest at ${times[highestIndex].format(context)}. You should think about what is it the makes your depression rate raise on this specific time of the day, and try to avoide it as much as possible."));

    final lowest =
        getLowestActivity(Map.from(activityValues), Map.from(activityRate));
    final highest =
        getHighestActivity(Map.from(activityValues), Map.from(activityRate));

    if (lowest != null) {
      advices.add(lowest);
    }

    if (highest != null) {
      advices.add(highest);
    }

    return advices;
  }

  StatsData? getLowestActivity(Map actValues, Map actRates) {
    if (actValues.isEmpty) {
      return null;
    }

    String lowestActivity = "";
    double lowestRate = 1;

    for (var a in actRates.keys) {
      if (actRates[a] < lowestRate) {
        lowestRate = actRates[a];
        lowestActivity = a;
      }
    }

    if (actValues[lowestActivity]!.length > 4) {
      return StatsData(Icons.sentiment_satisfied_alt_outlined,
          "You're least depressed when doing $lowestActivity. You should try to do it more often.");
    } else {
      actValues.remove(lowestActivity);
      actRates.remove(lowestActivity);
      return getLowestActivity(actValues, actRates);
    }
  }

  StatsData? getHighestActivity(Map actValues, Map actRates) {
    if (actValues.isEmpty) {
      return null;
    }

    String highestActivity = "";
    double highestRate = 0;

    for (var a in actRates.keys) {
      if (actRates[a] > highestRate) {
        highestRate = actRates[a];
        highestActivity = a;
      }
    }

    if (actValues[highestActivity]!.length > 4) {
      return StatsData(Icons.sentiment_dissatisfied_outlined,
          "You're most depressed when doing $highestActivity. You should try to do it less if possible.");
    } else {
      actValues.remove(highestActivity);
      actRates.remove(highestActivity);
      return getHighestActivity(actValues, actRates);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report"),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Hero(
                  tag: "alldays",
                  flightShuttleBuilder: (
                    BuildContext flightContext,
                    Animation<double> animation,
                    HeroFlightDirection flightDirection,
                    BuildContext fromHeroContext,
                    BuildContext toHeroContext,
                  ) {
                    return SingleChildScrollView(
                      child: fromHeroContext.widget,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: SizedBox(
                      width: min(
                          (screenWidth - 20) + 40, maxSmallCircleSize * 7 + 40),
                      child: Card(
                        margin: const EdgeInsets.all(20),
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
                                      child: CircleProgress(
                                        segemntsPerDay[
                                            innerIndex + (index * 7)],
                                        values[innerIndex + (index * 7)],
                                        borderThickness: 0.25,
                                        dividerThickness: 5,
                                      ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(
                    width: min(
                        (screenWidth - 20) + 40, maxSmallCircleSize * 7 + 40),
                    child: Card(
                      margin: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 25.0),
                            child: Text(
                              "Stats ",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          ...getStats()
                              .map(
                                (e) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: StatsWidget(e),
                                ),
                              )
                              .toList(),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(
                    width: min(
                        (screenWidth - 20) + 40, maxSmallCircleSize * 7 + 40),
                    child: Card(
                      margin: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 25.0),
                            child: Text(
                              "Advices ",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          ...getAdvices(context)
                              .map(
                                (e) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: StatsWidget(e),
                                ),
                              )
                              .toList(),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatsData {
  final IconData icon;
  final String text;

  const StatsData(this.icon, this.text);
}

class StatsWidget extends StatelessWidget {
  const StatsWidget(this.statsData, {Key? key}) : super(key: key);

  final statsData;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              statsData.icon,
              color: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: Text(
            statsData.text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
}
