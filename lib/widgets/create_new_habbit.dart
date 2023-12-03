import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:velocity_x/velocity_x.dart';

class CreateHabbit extends HookWidget {
  const CreateHabbit({super.key, required this.refreshPage});

  final Function refreshPage;

  @override
  Widget build(BuildContext context) {
    final textFieldController1 = useTextEditingController();
    final textFieldController2 = useTextEditingController();
    final textFieldController3 = useTextEditingController();

    final selectedDate = useState<DateTime>(DateTime.now());
    final selectedTime = useState<TimeOfDay>(TimeOfDay.now());

    void selectDate() async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate.value,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );
      if (picked != selectedDate.value && picked != null) {
        selectedDate.value = picked;
      }
    }

    void selectTime() async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: selectedTime.value,
      );
      if (picked != selectedTime.value && picked != null) {
        selectedTime.value = picked;
      }
    }

    void submitHandler() {
      final habbitObj = {
        'name': textFieldController1.text,
        'target': int.parse(textFieldController2.text),
        'dateTime': {
          'minute': selectedTime.value.minute,
          'hour': selectedTime.value.hour,
          'day': selectedDate.value.day,
          'month': selectedDate.value.month,
          'year': selectedDate.value.year,
        },
      };

      final hiveBox = Hive.box('habbits');

      hiveBox.put(textFieldController1.text, habbitObj);

      textFieldController1.clear();
      textFieldController2.clear();
      textFieldController3.clear();

      // Close the dialog
      Navigator.of(context).pop();
    }

    String dateTimeFieldtxt() {
      return '${selectedDate.value.day}-${selectedDate.value.month}-${selectedDate.value.year} ${selectedTime.value.hour}:${selectedTime.value.minute}';
    }

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return Dialog(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: textFieldController1,
                          decoration: const InputDecoration(labelText: 'Habbit Name'),
                        ).p8(),
                        TextFormField(
                          controller: textFieldController2,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Target'),
                        ).p8(),
                        TextField(
                          readOnly: true,
                          controller: textFieldController3,
                          onTap: () {
                            selectDate();
                            selectTime();
                            textFieldController3.text = dateTimeFieldtxt();
                          },
                          decoration: const InputDecoration(
                            labelText: 'Select Date and Time',
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            submitHandler();
                            Future.delayed(const Duration(milliseconds: 50), () {
                              refreshPage();
                            });
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    ).p12(),
                  );
                },
              );
            },
            icon: const Icon(Icons.add_circle_outline, size: 88).centered(),
          ),
          const SizedBox(height: 8),
          "Add New Habbit".text.medium.lg.make(),
        ],
      ),
    );
  }
}
