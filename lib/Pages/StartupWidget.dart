import 'package:flutter/material.dart';
import 'package:ml_depression/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ml_depression/Pages/HomeWidget.dart';

class StartupWidget extends StatefulWidget {
  const StartupWidget({this.title = "Startup page", Key? key})
      : super(key: key);

  final String title;

  @override
  State<StartupWidget> createState() => _StartupWidgetState();
}

class _StartupWidgetState extends State<StartupWidget> {
  int tests = 0;

  // Number selecting
  final numIcon = Icons.numbers;
  final numTitle = "Number of tests";
  final numDescription =
      "Choose how many times you want to do the test each day.";
  bool errorText = false;
  bool setText = false;

  // Times selecting
  final timeIcon = Icons.watch_later;
  final timeTitle = "Times";
  final timeDescription = "Choose the time for each test.";

  List<TimeOfDay> times = List<TimeOfDay>.generate(
      9, (index) => TimeOfDay(hour: 7 + index * 2, minute: 0));

  bool firstTime = true;

  void loadTimes() async {
    if (firstTime) {
      final prefs = await SharedPreferences.getInstance();

      if (prefs.getBool(didStartupKey) ?? false) {
        setState(() {
          tests = prefs.getInt(numTestsKey) ?? 0;
          setText = true;

          final timesString = prefs.getString(timesKey);
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
                .toList();
          }

          firstTime = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    loadTimes();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(children: [
        Column(
          children: [
            // Number of tests widget
            InkWell(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
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
                          numIcon,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            child: Text(
                              numTitle,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            numDescription,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 75,
                      child: TextField(
                        controller: setText
                            ? TextEditingController(
                                text: tests.toString(),
                              )
                            : null,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: '#',
                          errorText: errorText ? 'Enter 1-9' : null,
                          counterText: "",
                        ),
                        onChanged: (newText) {
                          setState(() {
                            setText = false;
                            if (int.tryParse(newText) == null ||
                                int.tryParse(newText) == 0) {
                              tests = 0;
                              if (!errorText && newText.isNotEmpty) {
                                errorText = true;
                              }
                            } else {
                              tests = int.parse(newText);
                              if (errorText) {
                                errorText = false;
                              }
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(
              thickness: 2,
              height: 0,
            )
          ],
        ),

        // Times of each test widget
        Column(
          children: [
            InkWell(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
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
                          timeIcon,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            child: Text(
                              timeTitle,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            timeDescription,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: List.generate(
                        tests,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Container(
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.grey, width: 2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: InkWell(
                                onTap: () async {
                                  final newTime = await showTimePicker(
                                      context: context,
                                      initialTime: times[index]);

                                  if (newTime != null) {
                                    setState(() {
                                      times[index] = newTime;
                                    });
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(times[index].format(context)),
                                ),
                              )),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const Divider(
              thickness: 2,
              height: 0,
            )
          ],
        ),
        const SizedBox(
          height: 30,
        ),
        FloatingActionButton.extended(
            heroTag: "myheroaca",
            onPressed: () async {
              if (tests > 0) {
                final prefs = await SharedPreferences.getInstance();
                prefs.setBool(didStartupKey, true);
                prefs.setInt(numTestsKey, tests);
                prefs.setString(timesKey, times.toString());

                // save starting day if this is the first time for startup
                if(widget.title != "Settings"){
                prefs.setString(startingDayKey,
                    DateUtils.dateOnly(DateTime.now()).toString());
                }
                
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => HomeWidget(prefs)));
              }
            },
            label: const Text("Save"))
      ]),
    );
  }
}
