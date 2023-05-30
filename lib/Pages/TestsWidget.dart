// import 'package:flutter/material.dart';
// import 'package:ml_depression/Pages/FaceTestWidget.dart';

// class TestsWidget extends StatelessWidget {
//   const TestsWidget({Key? key}) : super(key: key);

//   final items = const [
//     Item("Selfie", "Take a picture of yourself.", false,
//         Icons.face_retouching_natural, FaceTestWidget()),
//     Item("Text", "Describe an image.", true, Icons.text_snippet,
//         FaceTestWidget()),
//     Item("Voice recognistion", "Speak about a given topic.", false, Icons.mic,
//         FaceTestWidget()),
//     Item("Questions", "Answer some questions.", false,
//         Icons.question_mark_rounded, FaceTestWidget()),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Test"),
//       ),
//       body: Column(
//         children:
//             List.generate(items.length, (index) => ItemWidget(items[index])),
//       ),
//     );
//   }
// }

// class ItemWidget extends StatelessWidget {
//   const ItemWidget(this.item, {Key? key}) : super(key: key);

//   final Item item;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         InkWell(
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => item.page,
//               ),
//             );
//           },
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Container(
//                   margin: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: item.state ? Colors.green : Colors.red,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Icon(
//                       item.icon,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 4.0),
//                         child: Text(
//                           item.title,
//                           style: const TextStyle(
//                               fontSize: 16, fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                       Text(
//                         item.description,
//                         style: TextStyle(
//                             fontSize: 12, color: Colors.grey.shade600),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         const Divider(
//           thickness: 2,
//           height: 0,
//         )
//       ],
//     );
//   }
// }

// class Item {
//   const Item(this.title, this.description, this.state, this.icon, this.page);

//   final String title;
//   final String description;
//   final bool
//       state; // TODO: change state to double, and use it for depression level percent of this test
//   final IconData icon;
//   final Widget page;
// }
