import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera_windows/camera_windows.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:image/image.dart' as img;

import '../constants.dart';

// get the front camera
Future<CameraDescription> getCamera() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await CameraPlatform.instance.availableCameras();

  // Get the front camera from the list of available cameras.
  return cameras.firstWhere(
      (element) => element.lensDirection == CameraLensDirection.front);
}

class FaceTestWidget extends StatefulWidget {
  const FaceTestWidget(this.testName, {Key? key}) : super(key: key);

  final String
      testName; // name of the test. It consists of the day and number of test.

  @override
  State<FaceTestWidget> createState() => _FaceTestWidgetState();
}

class _FaceTestWidgetState extends State<FaceTestWidget> {
  late int cameraId;
  bool cameraReady = false; // true if camera is ready to be used
  late Size previewSize;
  final Size boxSize = const Size(320, 320);
  final Size previewBoxMax = const Size(900, 500);

  bool hasPicture = false; // true if user has already taken a picture
  String imagePath = ""; // path to the image taken by the user

  String result = "";

  void runModel(String imagePath) async {
    String activity = await requestActivity();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          title: Text("Result"),
          content: SizedBox(
              width: 50,
              height: 50,
              child: Center(child: CircularProgressIndicator())),
        );
      },
    );

    Process python = await Process.start("python", ["predictionscript.py"]);

    const model = "my_model.h5";

    python.stdout.listen((event) {
      String out = String.fromCharCodes(event);
      print(out);
      if (out.contains("Input your model path:")) {
        python.stdin.writeln(model);
      } else if (out.contains("Input your image path:")) {
        python.stdin.writeln(imagePath);
      } else if (out.contains("Depressed")) {
        print("FINAL RESULT: $out");

        result = out;

        if (result.isNotEmpty) {
          saveTestResult(activity);

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                title: const Text("Result"),
                content: Text(result),
                actions: [
                  TextButton(
                    child: const Text("OK"),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    });

    python.stderr.listen((event) {
      print(String.fromCharCodes(event));
    });
  }

  Future<String> requestActivity() async {
    String activity = "";

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("What activity were you doing just now?"),
          content: TextField(
            decoration: const InputDecoration(
              hintText: "Activity",
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              activity = value;
            },
          ),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    return activity;
  }

  void saveTestResult(String activity) async {
    activity = activity.toLowerCase().trim();

    final prefs = await SharedPreferences.getInstance();

    final startDay = DateTime.parse(prefs.getString(startingDayKey) ?? "");

    final todayIndex =
        DateUtils.dateOnly(DateTime.now()).difference(startDay).inDays;

    final stringValues = prefs.getStringList("$valuesKey$todayIndex");
    final values = stringValues == null
        ? []
        : stringValues.map((e) => double.parse(e)).toList();

    final stringActivityValues = prefs.getStringList("$activityValuesKey$activity");
    final activityValues = stringActivityValues == null
        ? []
        : stringActivityValues.map((e) => double.parse(e)).toList();

    final activies = prefs.getStringList(activitiesKey) ?? [];
    if(!activies.contains(activity)){
      activies.add(activity);
    }


    values.add(result.contains("Not Depressed") ? 1.0 : 0.0);
    activityValues.add(result.contains("Not Depressed") ? 1.0 : 0.0);

    prefs.setStringList(
        "$valuesKey$todayIndex", values.map((e) => e.toString()).toList());
    prefs.setStringList("$activityValuesKey$activity", activityValues.map((e) => e.toString()).toList());

    prefs.setStringList(activitiesKey, activies);
  }

  // prepare the camera for use
  void perpareCamera() async {
    if (!cameraReady) {
      final cameraDes = await getCamera();

      cameraId = await CameraPlatform.instance
          .createCamera(cameraDes, ResolutionPreset.max, enableAudio: false);

      final Future<CameraInitializedEvent> initialized =
          CameraPlatform.instance.onCameraInitialized(cameraId).first;

      await CameraPlatform.instance.initializeCamera(
        cameraId,
        imageFormatGroup: ImageFormatGroup.unknown,
      );

      final CameraInitializedEvent event = await initialized;

      setState(() {
        previewSize = Size(
          event.previewWidth,
          event.previewHeight,
        );

        cameraReady = true;
      });

      // getCamera().then((value) {
      //   controller = CameraController(value, ResolutionPreset.medium,
      //       enableAudio: false);
      //   controller.initialize().then((value) {
      //     setState(() {
      //       cameraReady = true;
      //     });
      //   });
      // });
    }
  }

  // get the camera preview, but first prepare the camera if it's not ready yet.
  Widget getCameraPreview() {
    if (cameraReady) {
      Widget preview = CameraPlatform.instance.buildPreview(cameraId);
      return preview;
    }
    perpareCamera();
    return Container(
      color: Colors.black,
    );
  }

  // check if the user has already taken a picture, if so then update hasPicture and imagePath.
  void checkIfHasPicture() async {
    final prefs = await SharedPreferences.getInstance();
    hasPicture = prefs.getBool("$hasPictureKey${widget.testName}") ?? false;

    if (hasPicture) {
      imagePath = prefs.getString(picturePathKey) ?? "";
    }
  }

  // takes a picture and save it.
  void takeAndSavePicture() async {
    final image = await CameraPlatform.instance.takePicture(cameraId);
    // controller.dispose();
    // cameraReady = false;

    final imageImg = img.decodeImage(await image.readAsBytes())!;

    final boxWidthBasedOnImage =
        (imageImg.width * boxSize.width) / previewBoxMax.width;
    final boxHeighthBasedOnImage =
        (imageImg.height * boxSize.height) / previewBoxMax.height;

    final x = (imageImg.width - boxWidthBasedOnImage) ~/ 2;
    final y = (imageImg.height - boxHeighthBasedOnImage) ~/ 2;

    final cropped = img.copyCrop(imageImg, x, y, boxWidthBasedOnImage.toInt(),
        boxHeighthBasedOnImage.toInt());

    final croppedPath = "${image.path.split(".")[0]}_cropped.jpg";

    File(croppedPath).writeAsBytesSync(img.encodeJpg(cropped));

    final prefs = await SharedPreferences.getInstance();
    prefs.setBool("$hasPictureKey${widget.testName}", true);

    // final directory = await getApplicationDocumentsDirectory();
    String path = image.path;
    await image.saveTo(path);
    prefs.setString(picturePathKey, path);
    prefs.setString(croppedPicturePathKey, croppedPath);

    setState(() {
      hasPicture = true;
      imagePath = path;
    });
  }

  // remove the picture.
  void removePicture() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool("$hasPictureKey${widget.testName}", false);

    File file = File(prefs.getString(picturePathKey) ?? "");
    file.delete();
    File croppedFile = File(prefs.getString(croppedPicturePathKey) ?? "");
    croppedFile.delete();

    setState(() {
      hasPicture = false;
      imagePath = "";
      result = "";
    });
  }

  // save the picture and get result.
  void confrimPicture() async {
    final prefs = await SharedPreferences.getInstance();

    final path = prefs.getString(croppedPicturePathKey);

    if (path != null) {
      runModel(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    checkIfHasPicture();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Test"),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade400,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: BoxConstraints(
                    maxHeight: previewBoxMax.height,
                    maxWidth: previewBoxMax.width),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        hasPicture
                            ? Image.file(
                                File(imagePath),
                                scale: 1,
                              )
                            : getCameraPreview(),
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: boxSize.height,
                            minHeight: boxSize.height,
                            maxWidth: boxSize.width,
                            minWidth: boxSize.width,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(
                              color: Colors.black,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                    hasPicture
                        ? Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: FloatingActionButton.extended(
                              onPressed: () {
                                confrimPicture();
                              },
                              icon: Icon(Icons.check),
                              label: Text("Confirm"),
                            ),
                          )
                        : Container(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(0),
                child: Text(
                  "Make sure to put your face inside the black box.",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FloatingActionButton.extended(
                  heroTag: "myheroaca",
                  onPressed: () async {
                    if (hasPicture) {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Retake picture?"),
                              content: const Text(
                                  "Are you sure you want to replace the current picture?"),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text("No")),
                                TextButton(
                                    onPressed: () async {
                                      removePicture();

                                      Navigator.pop(context);
                                    },
                                    child: const Text("Yes")),
                              ],
                            );
                          });
                    } else {
                      try {
                        if (cameraReady) {
                          takeAndSavePicture();
                        } else {
                          perpareCamera();
                        }
                      } catch (e) {
                        print(e);
                      }
                    }
                  },
                  label: Text(hasPicture ? "Retake picture" : "Take picture"),
                  icon: const Icon(Icons.camera_alt),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  void disposeCamera() async {
    if (cameraReady) {
      await CameraPlatform.instance.dispose(cameraId);
    }
  }

  @override
  void dispose() {
    disposeCamera();
    super.dispose();
  }
}

class NoPictureWidget extends StatelessWidget {
  const NoPictureWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt,
            color: Colors.grey.shade400,
            size: 200,
          ),
          Text(
            "No picture taken",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 20),
          ),
        ],
      ),
    );
  }
}
