// import 'package:flutter/material.dart';
// import '../../controller/workout_log_service.dart';

// class AddWorkoutLogScreen extends StatefulWidget {
//   const AddWorkoutLogScreen({super.key});

//   @override
//   State<AddWorkoutLogScreen> createState() => _AddWorkoutLogScreenState();
// }

// class _AddWorkoutLogScreenState extends State<AddWorkoutLogScreen> {
//   final _formKey = GlobalKey<FormState>();

//   final TextEditingController exerciseController = TextEditingController();
//   final TextEditingController setsController = TextEditingController();
//   final TextEditingController repsController = TextEditingController();
//   final TextEditingController weightController = TextEditingController();

//   bool isPr = false;
//   DateTime selectedDate = DateTime.now();
//   bool isSaving = false;

//   @override
//   void dispose() {
//     exerciseController.dispose();
//     setsController.dispose();
//     repsController.dispose();
//     weightController.dispose();
//     super.dispose();
//   }

//   String get formattedDate {
//     return selectedDate.toIso8601String().split('T').first;
//   }

//   Future<void> pickDate() async {
//     final pickedDate = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//     );

//     if (pickedDate == null) return;

//     setState(() {
//       selectedDate = pickedDate;
//     });
//   }

//   Future<void> saveLog() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() {
//       isSaving = true;
//     });

//     try {
//       await WorkoutLogService.addLog(
//         exerciseName: exerciseController.text.trim(),
//         setsCount: int.parse(setsController.text.trim()),
//         repsCount: int.parse(repsController.text.trim()),
//         weight: double.parse(weightController.text.trim()),
//         isPr: isPr,
//         logDate: formattedDate,
//       );

//       if (!mounted) return;

//       Navigator.pop(context, true);
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isSaving = false;
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to save log: $e')),
//       );
//     }
//   }

//   Widget buildTextField({
//     required TextEditingController controller,
//     required String label,
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return TextFormField(
//       controller: controller,
//       keyboardType: keyboardType,
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),
//       validator: (value) {
//         if (value == null || value.trim().isEmpty) {
//           return '$label is required';
//         }

//         return null;
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Add Workout Record'),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               buildTextField(
//                 controller: exerciseController,
//                 label: 'Exercise name',
//               ),
//               const SizedBox(height: 16),
//               buildTextField(
//                 controller: setsController,
//                 label: 'Sets',
//                 keyboardType: TextInputType.number,
//               ),
//               const SizedBox(height: 16),
//               buildTextField(
//                 controller: repsController,
//                 label: 'Reps',
//                 keyboardType: TextInputType.number,
//               ),
//               const SizedBox(height: 16),
//               buildTextField(
//                 controller: weightController,
//                 label: 'Weight (kg)',
//                 keyboardType: TextInputType.number,
//               ),
//               const SizedBox(height: 16),

//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey.shade400),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: SwitchListTile(
//                   contentPadding: EdgeInsets.zero,
//                   title: const Text('Personal Record'),
//                   value: isPr,
//                   onChanged: (value) {
//                     setState(() {
//                       isPr = value;
//                     });
//                   },
//                 ),
//               ),

//               const SizedBox(height: 16),

//               InkWell(
//                 onTap: pickDate,
//                 borderRadius: BorderRadius.circular(12),
//                 child: Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey.shade400),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.calendar_today),
//                       const SizedBox(width: 12),
//                       Text('Date: $formattedDate'),
//                     ],
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 24),

//               SizedBox(
//                 width: double.infinity,
//                 height: 54,
//                 child: ElevatedButton(
//                   onPressed: isSaving ? null : saveLog,
//                   child: Text(isSaving ? 'Saving...' : 'Save Record'),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
