import 'dart:convert';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
// import 'package:environment_sensors/environment_sensors.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';

String latitudedata = "";
String longitudedata = "";
List userdata = [];
bool isButtonEnabled = false;
bool isConnected = false;
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
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

  // bool _tempAvailable = false;
  // bool _humidityAvailable = false;
  // bool _lightAvailable = false;
  // bool _pressureAvailable = false;
  // final environmentSensors = EnvironmentSensors();

  @override
  void initState() {
    super.initState();
    askPerm();
    checkForConn();
    // initPlatformState();
    getCurrentLocation();
    usernameController.addListener(printLatestValue);
  }

  checkForConn() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('Connected');
        isConnected = true;
      }
    } on SocketException catch (_) {
      print('not connected');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("No Internet Connection"),
            content: const Text("To use the app you need internet connection"),
            actions: <Widget>[
              FlatButton(
                child: const Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop();
                  checkForConn();
                },
              )
            ],
          );
        },
      );
      isConnected = false;
    }
  }

  //ask user all permissions
  askPerm() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.sensors,
    ].request();
    print(statuses[Permission.location]);
  }

  // Future<void> initPlatformState() async {
  //   bool tempAvailable;
  //   bool humidityAvailable;
  //   bool lightAvailable;
  //   bool pressureAvailable;

  //   tempAvailable = await environmentSensors
  //       .getSensorAvailable(SensorType.AmbientTemperature);
  //   humidityAvailable =
  //       await environmentSensors.getSensorAvailable(SensorType.Humidity);
  //   lightAvailable =
  //       await environmentSensors.getSensorAvailable(SensorType.Light);
  //   pressureAvailable =
  //       await environmentSensors.getSensorAvailable(SensorType.Pressure);

  //   setState(() {
  //     _tempAvailable = tempAvailable;
  //     _humidityAvailable = humidityAvailable;
  //     _lightAvailable = lightAvailable;
  //     _pressureAvailable = pressureAvailable;
  //   });
  // }

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

  void printLatestValue() {
    if (usernameController.text.trim().isEmpty) {
      setState(() {
        isButtonEnabled = false;
      });
    } else if (usernameController.text.length < 3) {
      isButtonEnabled = false;
    } else {
      setState(() {
        isButtonEnabled = true;
      });
    }
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
            onSubmitted: null,
            onChanged: (val) {
              printLatestValue();
            },
            textAlign: TextAlign.center,
            controller: usernameController,
          ),
          ElevatedButton(
            onPressed: () {
              if (isButtonEnabled == true) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SecondRoute(username: usernameController.text)),
                );
                Vibration.vibrate(duration: 100);
                postRequest();
              } else {
                //show an alert dialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Error"),
                      content: Text("Name should be alteast 3 characters"),
                      actions: <Widget>[
                        FlatButton(
                          child: Text("Close"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        )
                      ],
                    );
                  },
                );
                Vibration.vibrate(duration: 500);
              }
            },
            child: const Text("Accept"),
          ),
          // Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          //   (_tempAvailable)
          //       ? StreamBuilder<double>(
          //           stream: environmentSensors.humidity,
          //           builder: (context, snapshot) {
          //             if (!snapshot.hasData) return CircularProgressIndicator();
          //             return Text(
          //                 'The Current Humidity is: ${snapshot.data!.toStringAsFixed(2)}%');
          //           })
          //       : Text('No relative humidity sensor found'),
          //   (_humidityAvailable)
          //       ? StreamBuilder<double>(
          //           stream: environmentSensors.temperature,
          //           builder: (context, snapshot) {
          //             if (!snapshot.hasData) return CircularProgressIndicator();
          //             return Text(
          //                 'The Current Temperature is: ${snapshot.data!.toStringAsFixed(2)}');
          //           })
          //       : Text('No temperature sensor found'),
          //   (_lightAvailable)
          //       ? StreamBuilder<double>(
          //           stream: environmentSensors.light,
          //           builder: (context, snapshot) {
          //             if (!snapshot.hasData) return CircularProgressIndicator();
          //             return Text(
          //                 'The Current Light is: ${snapshot.data!.toStringAsFixed(2)}');
          //           })
          //       : Text('No light sensor found'),
          //   (_pressureAvailable)
          //       ? StreamBuilder<double>(
          //           stream: environmentSensors.pressure,
          //           builder: (context, snapshot) {
          //             if (!snapshot.hasData) return CircularProgressIndicator();
          //             return Text(
          //                 'The Current Pressure is: ${snapshot.data!.toStringAsFixed(2)}');
          //           })
          //       : Text('No pressure sensure found'),
          // ]),
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

  double accelerometerValueX = 0.0;
  double accelerometerValueY = 0.0;
  double accelerometerValueZ = 0.0;
  String username;

  @override
  void initState() {
    super.initState();
    userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      accelerometerValueX = double.parse(event.x.toStringAsFixed(3));
      accelerometerValueY = double.parse(event.y.toStringAsFixed(3));
      accelerometerValueZ = double.parse(event.z.toStringAsFixed(3));
    });
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
    // runs every 5 second
    Timer.periodic(const Duration(seconds: 5), (timer) {
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
          backgroundColor: Colors.green.shade200,
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                Text(
                  "You are now " + username,
                  style: TextStyle(fontSize: 30),
                ),
                StreamBuilder<AccelerometerEvent>(
                  stream: accelerometerEvents,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return CircularProgressIndicator();
                    return Text(
                        'This is your speed in the represtented directions: \n x: ${snapshot.data!.x.toStringAsFixed(2)} \n y: ${snapshot.data!.y.toStringAsFixed(2)} \n z: ${snapshot.data!.z.toStringAsFixed(2)}');
                  },
                ),
                FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  label: const Text('Change Name'),
                  icon: const Icon(Icons.change_circle),
                  backgroundColor: Colors.green[200],
                ),
                getTextWidgets(userdata),
                // ElevatedButton(
                //     onPressed: getCurrentUsersAndLocation,
                //     child: const Text("Reshare Location")),
              ],
            ),
          ),
        ));
  }

  getTextWidgets(List responseData) {
    List<Widget> widgets = [];
    for (var i = 0; i < responseData.length; i++) {
      widgets.add(Column(children: [
        Text(
            "\n" +
                "User: " +
                responseData[i]['username'].toString() +
                "\nLatitude: " +
                responseData[i]['latitude'].toString() +
                "\nLongitude: " +
                responseData[i]['longitude'].toString() +
                "\n",
            style: TextStyle(fontSize: 20)),
        Icon(Icons.location_pin, color: Colors.green[200], size: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MapSample(
                      latitudedata: responseData[i]['latitude'],
                      longitudedata: responseData[i]['longitude'])),
            );
            Vibration.vibrate(duration: 100);
          },
          child: Text("Map"),
          style: ElevatedButton.styleFrom(
            primary: Colors.green[200],
            onPrimary: Colors.white,
            shadowColor: Colors.black,
            elevation: 5,
          ),
        )
      ]));
    }
    return Column(children: widgets);
  }
}

class MapSample extends StatefulWidget {
  MapSample({Key? key, required this.latitudedata, required this.longitudedata})
      : super(key: key);
  String latitudedata;
  String longitudedata;

  @override
  State<MapSample> createState() =>
      MapSampleState(latitudedata: latitudedata, longitudedata: longitudedata);
}

class MapSampleState extends State<MapSample> {
  MapSampleState({required this.latitudedata, required this.longitudedata});
  Completer<GoogleMapController> _controller = Completer();

  String latitudedata;
  String longitudedata;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  changeusertarget() {
    CameraPosition user = CameraPosition(
        bearing: 192.8334901395799,
        target: LatLng(double.parse(latitudedata), double.parse(longitudedata)),
        tilt: 59.440717697143555,
        zoom: 19.151926040649414);

    return user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: _kGooglePlex,
        zoomControlsEnabled: false,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: {
          Marker(
              markerId: MarkerId("user"),
              position: LatLng(
                  double.parse(latitudedata), double.parse(longitudedata)),
              infoWindow: InfoWindow(title: "the selected user"))
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: goToUserPosition,
        label: const Text('SEE POSITION'),
        icon: const Icon(Icons.location_pin),
        backgroundColor: Colors.green[200],
      ),
    );
  }

  Future<void> goToUserPosition() async {
    final GoogleMapController controller = await _controller.future;
    controller
        .animateCamera(CameraUpdate.newCameraPosition(changeusertarget()));
    Vibration.vibrate(duration: 500);
  }
}
