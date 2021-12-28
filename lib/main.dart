import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

String latitudedata = "";
String longitudedata = "";
List userdata = [];
void main() {
  runApp(const MaterialApp(
    title: 'Navigation Basics',
    home: FirstRoute(),
    debugShowCheckedModeBanner: false,
  ));
}

class FirstRoute extends StatefulWidget {
  const FirstRoute({Key? key}) : super(key: key);

  @override
  _FirstRoute createState() => _FirstRoute();
}

class _FirstRoute extends State<FirstRoute> {
  final usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  getCurrentLocation() async {
    String url = "https://mobile-app-ucll.herokuapp.com/users";
    final response = await http.get(Uri.parse(url));
    List responseData = json.decode(response.body);

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);

    setState(() {
      latitudedata = '${position.latitude}';
      longitudedata = '${position.longitude}';
      userdata = responseData;
    });
  }

  Future<http.Response> postRequest() {
    return http.post(
      Uri.parse('https://mobile-app-ucll.herokuapp.com/adduserwithlocation'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': usernameController.text,
        'latitude': latitudedata,
        'longitude': longitudedata
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('// Home //'),
        backgroundColor: Colors.green.shade200,
        centerTitle: true,
      ),
      body: Container(
        child: Column(children: [
          const Text("Welcome to the tracking app",
              style: TextStyle(fontSize: 20)),
          const SizedBox(height: 60),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Enter your name',
            ),
            textAlign: TextAlign.center,
            controller: usernameController,
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        SecondRoute(username: usernameController.text)),
              );
              Vibration.vibrate(duration: 100);
              postRequest();
            },
            child: const Text("Accept"),
          )
        ]),
        margin: const EdgeInsets.all(20),
      ),
    );
  }
}

class SecondRoute extends StatefulWidget {
  const SecondRoute({Key? key, required this.username}) : super(key: key);

  final String username;

  @override
  _SecondRoute createState() => _SecondRoute(username: username);
}

class _SecondRoute extends State<SecondRoute> {
  _SecondRoute({required this.username});

  String username;

  @override
  void initState() {
    super.initState();
    getCurrentUsersAndLocation();
    refreshList();
  }

  Future<http.Response> postRequest() {
    return http.post(
      Uri.parse('https://mobile-app-ucll.herokuapp.com/adduserwithlocation'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'latitude': latitudedata,
        'longitude': longitudedata
      }),
    );
  }

  getCurrentUsersAndLocation() async {
    String url = "https://mobile-app-ucll.herokuapp.com/users";
    final response = await http.get(Uri.parse(url));
    List responseData = json.decode(response.body);

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);

    setState(() {
      latitudedata = '${position.latitude}';
      longitudedata = '${position.longitude}';
      userdata = responseData;
    });
  }

  refreshList() {
    // runs every 10 second
    Timer.periodic(new Duration(seconds: 5), (timer) {
      getCurrentUsersAndLocation();
      postRequest();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("// Trackers //"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            Text("You are now " + username),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Vibration.vibrate(duration: 500);
              },
              child: const Text("Change Name"),
            ),
            getTextWidgets(userdata),
            ElevatedButton(
                onPressed: getCurrentUsersAndLocation,
                child: const Text("Reshare Location")),
          ],
        ),
      ),
    );
  }

  getTextWidgets(List responseData) {
    List<Widget> widgets = [];
    for (var i = 0; i < responseData.length; i++) {
      widgets.add(Column(children: [
        Text("\n" +
            "User: " +
            responseData[i]['username'].toString() +
            "\nLatitude: " +
            responseData[i]['latitude'].toString() +
            "\nLongitude: " +
            responseData[i]['longitude'].toString() +
            "\n"),
        ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SpecificMapRoute(
                        username: responseData[i]['username'],
                        latitude: responseData[i]['latitude'],
                        longitude: responseData[i]['longitude'])),
              );
            },
            child: const Text("Map"))
      ]));
    }
    return Column(children: widgets);
  }
}

class SpecificMapRoute extends StatefulWidget {
  const SpecificMapRoute(
      {Key? key,
      required this.username,
      required this.latitude,
      required this.longitude})
      : super(key: key);

  final String username;
  final String latitude;
  final String longitude;
  @override
  _SpecificMapRoute createState() => _SpecificMapRoute(
      username: username, latitude: latitude, longitude: longitude);
}

class _SpecificMapRoute extends State<SpecificMapRoute> {
  _SpecificMapRoute(
      {required this.username,
      required this.latitude,
      required this.longitude});

  String username;
  String latitude;
  String longitude;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("// User is here //"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            Text("User: " +
                username +
                " is here" +
                "\n" +
                latitude +
                "\n" +
                longitude),
          ],
        ),
      ),
    );
  }
}
