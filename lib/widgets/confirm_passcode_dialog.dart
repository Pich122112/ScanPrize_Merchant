// import 'package:flutter/material.dart';

// class ConfirmPasscodeDialog extends StatefulWidget {
//   final String firstPasscode;

//   const ConfirmPasscodeDialog({Key? key, required this.firstPasscode})
//     : super(key: key);

//   @override
//   State<ConfirmPasscodeDialog> createState() => _ConfirmPasscodeDialogState();
// }

// class _ConfirmPasscodeDialogState extends State<ConfirmPasscodeDialog> {
//   String? errorMessage;
//   GlobalKey<_CustomPasscodeDialogState> _passcodeKey = GlobalKey();

//   void _resetPasscodeInput() {
//     _passcodeKey.currentState?.resetInput();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         // Prevent back button from closing the dialog
//         return false;
//       },
//       child: CustomPasscodeDialog(
//         key: _passcodeKey,
//         subtitle: 'សូមផ្ទៀងផ្ទាត់លេខសម្ងាត់អ្នកម្តងទៀត',
//         errorMessage: errorMessage,
//         autoCloseOnComplete: false, // Important: prevent auto-closing
//         onCompleted: (String code) async {
//           if (code != widget.firstPasscode) {
//             setState(() {
//               errorMessage = 'លេខសម្ងាត់មិនត្រូវគ្នាសូមបង្កើតម្តងទៀត';
//             });
//             _resetPasscodeInput(); // Clear the input
//           } else {
//             Navigator.of(context).pop(code);
//           }
//         },
//       ),
//     );
//   }
// }