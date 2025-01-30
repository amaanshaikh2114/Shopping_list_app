import 'dart:convert'; // used for json object

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>(); // in general mostly used with forms
  var _enteredName = '';
  var _enteredQuantity = 1;
  var _selectedCategory = categories[Categories.vegetables];
  var _isSending = false;

  void _saveItem() async {
    // Future object going to be received
    // executes the validator functions for all TextFormField in a Form
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isSending = true;
      });
      // Replace 1st url with your Firebase realtime database url
      final url = Uri.https('flutter-your-realtime-firebase-url.firebaseio.com',
          'shopping-list.json');

      // the package http being used to pass info using url and waiting for Future object 'response'
      // Could also chain then() fn to the http.post() method
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(
          {
            'name': _enteredName,
            'quantity': _enteredQuantity,
            'category': _selectedCategory!.title,
          },
        ),
      );

      final Map<String, dynamic> resData = json.decode(response.body);

      if (!context.mounted) {
        return;
      }

      // print(response.body);
      // print(response.statusCode);
      // If status codes > 400 -> error codes indicating some error

      // Json returned as response converted to Map has key 'name' with unique ID
      // I/flutter ( 8712): {"name":"-OHctEqnnqSB-GdzQA8g"}
      // I/flutter ( 8712): 200

      Navigator.of(context).pop(
        GroceryItem(
          id: resData['name'], // Refer above comment
          name: _enteredName,
          quantity: _enteredQuantity,
          category: _selectedCategory!,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add a new item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // instead of TextField widget used in expense tracker app as it contains features from mthe form widget
              TextFormField(
                maxLength: 50,
                decoration: InputDecoration(
                  label: Text('Name'),
                ),
                validator: (value) {
                  // value is the text entered in field
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length <= 1 ||
                      value.trim().length > 50) {
                    return 'Must be between 1 and 50 characters.';
                  }
                  return null;
                },
                onSaved: (value) {
                  // value is the text entered in field
                  _enteredName = value!;
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        label: Text('Quantity'),
                      ),
                      initialValue: _enteredQuantity.toString(),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            int.tryParse(value)! <= 0) {
                          // asserting int.tryParse(value) isn't null
                          return 'Must be a valid, positive number.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        // parse gives an error if it fails to convert the given string to int while tryParse yields null
                        // if it fails to convert the given string to int. Here we can use parse as tryParse has been used
                        // in validation to check that only integer values are entered.
                        _enteredQuantity = int.parse(value!);
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _selectedCategory,
                      items: [
                        // .entries used to convert a map to an iterable(list) of key, value pairs of a map
                        for (final category in categories.entries)
                          DropdownMenuItem(
                            // Category object being assigned as value
                            value: category.value,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  color: category.value.color,
                                ),
                                SizedBox(width: 12),
                                // Category.title being used which is a value of key, value pair of categories map
                                Text(category.value.title),
                              ],
                            ),
                          ),
                      ],
                      // no need for OnSaved as as _selectedCategory is being handled manually using setState
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 12,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    // using ternary (?) to set onPressed = null to disable the button once the item has
                    // been added and HTTP request has been sent to add the data in the Firebase backend
                    onPressed: _isSending
                        ? null
                        : () {
                            _formKey.currentState!.reset();
                          },
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: _isSending ? null : _saveItem,
                    child: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(),
                          )
                        : const Text('Add item'),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
