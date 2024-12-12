// main.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as networkRequest;
import 'dart:convert';

void main() {
  runApp(const MyApplication());
}

class UserModel {
  final int userId;
  String fullName;
  String userAlias;
  String userEmail;

  UserModel(
      {required this.userId,
      required this.fullName,
      required this.userAlias,
      required this.userEmail});

  factory UserModel.fromJson(Map<String, dynamic> jsonData) {
    return UserModel(
      userId: jsonData['id'],
      fullName: jsonData['name'],
      userAlias: jsonData['username'],
      userEmail: jsonData['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'name': fullName,
      'username': userAlias,
      'email': userEmail,
    };
  }
}

class MyApplication extends StatelessWidget {
  const MyApplication({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Management System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const UserListScreen(),
    );
  }
}

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<UserModel> userList = [];
  bool isDataLoading = true;

  @override
  void initState() {
    super.initState();
    retrieveUsers();
  }

  // Fetch Users (Read Operation)
  Future<void> retrieveUsers() async {
    try {
      final serverResponse = await networkRequest
          .get(Uri.parse('https://jsonplaceholder.typicode.com/users'));

      if (serverResponse.statusCode == 200) {
        List<dynamic> responseBody = json.decode(serverResponse.body);
        setState(() {
          userList =
              responseBody.map((dynamic entry) => UserModel.fromJson(entry)).toList();
          isDataLoading = false;
        });
      } else {
        setState(() {
          isDataLoading = false;
        });
        displayErrorDialog('Failed to retrieve users');
      }
    } catch (error) {
      setState(() {
        isDataLoading = false;
      });
      displayErrorDialog('Error: ${error.toString()}');
    }
  }

  // Create User
  Future<void> addUser(UserModel newUser) async {
    try {
      final postResponse = await networkRequest.post(
        Uri.parse('https://jsonplaceholder.typicode.com/users'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(newUser.toJson()),
      );

      if (postResponse.statusCode == 201) {
        setState(() {
          userList.add(newUser);
        });
        Navigator.pop(context);
      } else {
        displayErrorDialog('Failed to add user');
      }
    } catch (error) {
      displayErrorDialog('Error: ${error.toString()}');
    }
  }

  // Update User
  Future<void> modifyUser(UserModel modifiedUser) async {
    try {
      final putResponse = await networkRequest.put(
        Uri.parse(
            'https://jsonplaceholder.typicode.com/users/${modifiedUser.userId}'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(modifiedUser.toJson()),
      );

      if (putResponse.statusCode == 200) {
        setState(() {
          int userIndex =
              userList.indexWhere((user) => user.userId == modifiedUser.userId);
          if (userIndex != -1) {
            userList[userIndex] = modifiedUser;
          }
        });
        Navigator.pop(context);
      } else {
        displayErrorDialog('Failed to modify user');
      }
    } catch (error) {
      displayErrorDialog('Error: ${error.toString()}');
    }
  }

  // Delete User
  Future<void> removeUser(int id) async {
    try {
      final deleteResponse = await networkRequest.delete(
          Uri.parse('https://jsonplaceholder.typicode.com/users/$id'));

      if (deleteResponse.statusCode == 200) {
        setState(() {
          userList.removeWhere((user) => user.userId == id);
        });
      } else {
        displayErrorDialog('Failed to remove user');
      }
    } catch (error) {
      displayErrorDialog('Error: ${error.toString()}');
    }
  }

  // Show Error Dialog
  void displayErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(errorMessage),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  // Show Create/Edit User Dialog
  void showUserDialog({UserModel? currentUser}) {
    final fullNameController =
        TextEditingController(text: currentUser?.fullName ?? '');
    final aliasController =
        TextEditingController(text: currentUser?.userAlias ?? '');
    final emailController =
        TextEditingController(text: currentUser?.userEmail ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(currentUser == null ? 'Add User' : 'Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fullNameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: aliasController,
              decoration: const InputDecoration(labelText: 'Alias'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: Text(currentUser == null ? 'Add' : 'Save'),
            onPressed: () {
              final newUser = UserModel(
                userId: currentUser?.userId ?? DateTime.now().millisecondsSinceEpoch,
                fullName: fullNameController.text,
                userAlias: aliasController.text,
                userEmail: emailController.text,
              );

              if (currentUser == null) {
                addUser(newUser);
              } else {
                modifyUser(newUser);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Add User"),
              onPressed: () => showUserDialog(),
            ),
          ],
        ),
        body: isDataLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: userList.length,
                itemBuilder: (ctx, index) {
                  final user = userList[index];
                  return ListTile(
                    title: Text(user.fullName),
                    subtitle: Text(user.userEmail),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => showUserDialog(currentUser: user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => removeUser(user.userId),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
