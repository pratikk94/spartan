import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spartan/firebase_options.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class User {
  final String name;
  final DateTime date;
  final bool paymentDone;
  final int enrollmentDays;
  final bool personalTraining;
  final String imageUrl;
  final String phoneNumber;

  User(
      this.name,
      this.date,
      this.paymentDone,
      this.enrollmentDays,
      this.personalTraining,
      this.imageUrl,
      this.phoneNumber,
      );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ScreenUtilInit( designSize: Size(360, 640),child: MyHomePage()),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String userName = '';
  DateTime selectedDate = DateTime.now();
  bool paymentDone = false;
  int enrollmentDays = 1;
  bool personalTraining = false;
  File? selectedImage;
  String phoneNumber = '';
  List<User> userList = [];

  @override
  void initState() {

    // Fetch users from Realtime Database

    _fetchUsers();
    super.initState();
  }

  int _calculateEnrollmentDays(DateTime enrollmentDate) {
    DateTime today = DateTime.now();
    return today.difference(enrollmentDate).inDays;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _fetchUsers() async {
    DatabaseReference databaseReference =
    FirebaseDatabase.instance.reference().child('users');

    try {
      // Use .once() to get a DatabaseEvent
      DatabaseEvent snapshot = await databaseReference.once();
      userList.clear();
      Map<dynamic, dynamic> values =
          (snapshot.snapshot.value as Map<dynamic, dynamic>?) ?? {};

      values.forEach((key, value) {
        User user = User(
            value['name'],
            DateTime.parse(value['date']),
            value['paymentDone'],
            value['enrollmentDays'],
            value['personalTraining'],
            value['imageUrl'],
            value['phoneNumber']);
        userList.add(user);
      });
      userList.sort((a, b) {
        int differenceA = _calculateEnrollmentDays(a.date) - a.enrollmentDays;
        int differenceB = _calculateEnrollmentDays(b.date) - b.enrollmentDays;

        return differenceB.compareTo(differenceA); // Sort in descending order
      });
      setState(() {});
    } catch (error) {
      // print('Error fetching users: $error');
    }
  }

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        selectedImage = File(pickedFile.path);
      } else {
        // print('No image selected.');
      }
    });
  }

  void _showBottomSheet() {
    bool isPersonalTrainingSelected = false;
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Capture User Information'),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Name'),
                    onChanged: (value) {
                      setState(() {
                        userName = value;
                      });
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Phone Number'),
                    onChanged: (value) {
                      setState(() {
                        phoneNumber = value;
                      });
                    },
                  ),
                  Row(
                    children: [
                      const Text('Select Date:'),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _selectDate(context),
                        child: const Text('Select Date'),
                      ),
                    ],
                  ),
                  Text('Selected Date: ${selectedDate.toLocal()}'),
                  Row(
                    children: [
                      const Text('Payment Done:'),
                      Radio(
                        value: true,
                        groupValue: isPersonalTrainingSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            isPersonalTrainingSelected = value!;
                          });
                        },
                      ),
                      const Text('Yes'),
                      Radio(
                        value: false,
                        groupValue: paymentDone,
                        onChanged: (value) {
                          setState(() {
                            paymentDone = value as bool;
                          });
                        },
                      ),
                      const Text('No'),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Enrollment Duration:'),
                      DropdownButton<int>(
                        value: enrollmentDays,
                        onChanged: (value) {
                          setState(() {
                            enrollmentDays = value!;
                          });
                        },
                        items: [1, 3, 7, 14, 30]
                            .map<DropdownMenuItem<int>>((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(value.toString()),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Personal Training:'),
                      Radio(
                        value: true,
                        groupValue: personalTraining,
                        onChanged: (value) {
                          setState(() {
                            personalTraining = value as bool;
                          });
                        },
                      ),
                      const Text('Yes'),
                      Radio(
                        value: false,
                        groupValue: personalTraining,
                        onChanged: (value) {
                          setState(() {
                            personalTraining = value as bool;
                          });
                        },
                      ),
                      const Text('No'),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Select Image:'),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _selectImage(),
                        child: const Text('Select Image'),
                      ),
                      selectedImage != null
                          ? Image.file(selectedImage!, height: 50)
                          : const Text('No image selected.'),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedImage != null) {
                        // Upload image to Firebase Storage
                        String imageUrl = await _uploadImage(selectedImage!);

                        // Push data to Firebase Realtime Database
                        _pushDataToFirebase(
                          userName,
                          selectedDate,
                          paymentDone,
                          enrollmentDays,
                          personalTraining,
                          imageUrl,
                          phoneNumber,
                        );
                      }
                      _fetchUsers();
                      Navigator.pop(context);
                    },
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ));
      },
    );
  }

  Future<String> _uploadImage(File image) async {
    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference storageReference = storage
          .ref()
          .child('user_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      UploadTask uploadTask = storageReference.putFile(image);
      await uploadTask.whenComplete(() => null);

      // Get the download URL of the uploaded image
      String imageUrl = await storageReference.getDownloadURL();
      return imageUrl;
    } catch (e) {
      // print('Error uploading image: $e');
      return '';
    }
  }

  void _pushDataToFirebase(
      String name,
      DateTime date,
      bool paymentDone,
      int enrollmentDays,
      bool personalTraining,
      String imageUrl,
      String phoneNumber,
      ) {
    // TODO: Implement Firebase Realtime Database logic
    // You can use Firebase Database APIs to push data to the database.
    // Example:
    DatabaseReference databaseReference = FirebaseDatabase.instance.reference();
    databaseReference.child('users').push().set({
      'name': name,
      'date': date.toIso8601String(),
      'paymentDone': paymentDone,
      'enrollmentDays': enrollmentDays,
      'personalTraining': personalTraining,
      'imageUrl': imageUrl,
      'phoneNumber': phoneNumber,
    });
  }

  Future<void> _launchSMS(String phoneNumber, String userName) async {
    String smsUrl =
        'sms:$phoneNumber?body=Hello $userName! This is a test SMS from Flutter.';
    await launch(smsUrl);
  }

  Future<void> _launchWhatsApp(String phoneNumber, String userName) async {
    String whatsappLink =
        'https://wa.me/$phoneNumber/?text=${Uri.encodeComponent('Hello $userName! This is a test message from Flutter.')}';
    await launch(whatsappLink);
  }

  void _showUserDetailsModal(User user) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User Details'),
                  // Display user's photo
                  Center(
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(user.imageUrl),
                      radius: 60.0,
                    ),
                  ),
                  ListTile(
                    title: Text('Name: ${user.name}'),
                    subtitle: Text('Enrolled on: ${user.date.toLocal()}'),
                    trailing: IconButton(
                      icon: Icon(Icons.message),
                      onPressed: () {
                        _launchSMS(user.phoneNumber, user.name);
                      },
                    ),
                  ),
                  ListTile(
                    title: Text(
                        'Days Since Enrollment: ${_calculateEnrollmentDays(user.date)}'),
                    subtitle: Text('Payment Done: ${user.paymentDone}'),
                    trailing: IconButton(
                      icon: Icon(Icons.whatshot),
                      onPressed: () {
                        _launchWhatsApp(user.phoneNumber, user.name);
                      },
                    ),
                  ),
                  ListTile(
                    title: Text('Enrollment Days: ${user.enrollmentDays}'),
                  ),
                  ListTile(
                    title: Text('Personal Training: ${user.personalTraining}'),
                  ),
                  ListTile(
                    title: Text('Phone Number: ${user.phoneNumber}'),
                  ),
                  // Add other details as needed
                ],
              ),
            ));
      },
    );
  }

  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    double screenWidth = ScreenUtil().screenWidth;

    // Determine if the phone is folded (less than a certain width)
    bool isFolded = screenWidth < 600; // Adjust this threshold as needed

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spartan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showBottomSheet();
            },
          ),
        ],
      ),
      body: isFolded
          ? _buildListOnly()
          : _buildListAndInfo(), // Display one or both panes based on screen width
    );

  }
  Widget _buildListOnly() {
    return ListView.builder(
      itemCount: userList.length,
      itemBuilder: (BuildContext context, int index) {
        User user = userList[index];
        int daysSinceEnrollment = _calculateEnrollmentDays(user.date);

        // Calculate the difference between days enrolled and today's date
        int difference = daysSinceEnrollment - user.enrollmentDays;

        // Determine the background color based on the condition
        Color backgroundColor =
        difference > 0 ? Colors.red : Colors.green;

        return Card(
          margin: EdgeInsets.all(8.0),
          color: backgroundColor,
          child: ListTile(
            onTap: () {
              _showUserDetailsModal(user);
            },
            selected: index == selectedIndex,
            title: Text(user.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enrolled on: ${user.date.toLocal()}'),
                Text('Days Since Enrollment: $daysSinceEnrollment'),
                Text('Payment Done: ${user.paymentDone}'),
                Text('Enrollment Days: ${user.enrollmentDays}'),
                Text('Personal Training: ${user.personalTraining}'),
                Text('Difference: $difference days'),
              ],
            ),
            leading: CircleAvatar(
              backgroundImage: NetworkImage(user.imageUrl),
              radius: 30.0,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.message),
                  onPressed: () {
                    _launchSMS(user.phoneNumber, user.name);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.whatshot),
                  onPressed: () {
                    _launchWhatsApp(user.phoneNumber, user.name);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildListAndInfo() {
    return Row(
      children: [
        // Left Pane (List)
        Expanded(
          flex: 1,
          child: ListView.builder(
            itemCount: userList.length,

            itemBuilder: (BuildContext context, int index) {
              User user = userList[index];
              int daysSinceEnrollment = _calculateEnrollmentDays(user.date);

              // Calculate the difference between days enrolled and today's date
              int difference = daysSinceEnrollment - user.enrollmentDays;

              // Determine the background color based on the condition
              Color backgroundColor =
              difference > 0 ? Colors.red : Colors.green;

              return Card(
                margin: EdgeInsets.all(8.0),
                color: backgroundColor,
                child: ListTile(
                  onTap: () {
                    //_showUserDetailsModal(user);
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  selected: index == selectedIndex,
                  title: Text(user.name),
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user.imageUrl),
                    radius: 30.0,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.message),
                        onPressed: () {
                          _launchSMS(user.phoneNumber, user.name);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.whatshot),
                        onPressed: () {
                          _launchWhatsApp(user.phoneNumber, user.name);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Right Panel (Information)
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.grey[200],
            child: Center(
              child: selectedIndex >= 0
                  ? SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User Details'),
                        // Display user's photo
                        Center(
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(userList[selectedIndex].imageUrl),
                            radius: 60.0,
                          ),
                        ),
                        ListTile(
                          title: Text('Name: ${userList[selectedIndex].name}'),
                          subtitle: Text('Enrolled on: ${userList[selectedIndex].date.toLocal()}'),
                          trailing: IconButton(
                            icon: Icon(Icons.message),
                            onPressed: () {
                              _launchSMS(userList[selectedIndex].phoneNumber, userList[selectedIndex].name);
                            },
                          ),
                        ),
                        ListTile(
                          title: Text(
                              'Days Since Enrollment: ${_calculateEnrollmentDays(userList[selectedIndex].date)}'),
                          subtitle: Text('Payment Done: ${userList[selectedIndex].paymentDone}'),
                          trailing: IconButton(
                            icon: Icon(Icons.whatshot),
                            onPressed: () {
                              _launchWhatsApp(userList[selectedIndex].phoneNumber, userList[selectedIndex].name);
                            },
                          ),
                        ),
                        ListTile(
                          title: Text('Enrollment Days: ${userList[selectedIndex].enrollmentDays}'),
                        ),
                        ListTile(
                          title: Text('Personal Training: ${userList[selectedIndex].personalTraining}'),
                        ),
                        ListTile(
                          title: Text('Phone Number: ${userList[selectedIndex].phoneNumber}'),
                        ),
                        // Add other details as needed
                      ],
                    ),
                  ))
                  : Text("Select an item from the list"),
            ),
          ),
        ),
      ],
    );
  }
}
