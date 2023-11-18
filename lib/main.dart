import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

Future<Position> determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}

Future<http.StreamedResponse> postData(
  String comment,
  double latitude,
  double longitude,
  String photo_path,
) async {
  var uri = Uri.https('flutter-sandbox.free.beeceptor.com', 'upload_photo/');
  var request = http.MultipartRequest('POST', uri)
    ..fields['comment'] = comment
    ..fields['latitude'] = comment
    ..fields['longitude'] = comment
    ..files.add(await http.MultipartFile.fromPath('photo', photo_path,
        contentType: MediaType('image', 'jpeg')));
  var response = await request.send();
  return response;
}

main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: PhotoTaskPage(
        title: 'Photo task',
        camera: firstCamera,
      ),
    ),
  );
}

class PhotoTaskPage extends StatefulWidget {
  const PhotoTaskPage({
    super.key,
    required this.title,
    required this.camera,
  });

  final String title;
  final CameraDescription camera;

  @override
  State<PhotoTaskPage> createState() => _PhotoTaskPageState();
}

class _PhotoTaskPageState extends State<PhotoTaskPage> {
  late CameraController _cameraController;
  late Future<void> _initializeCameraControllerFuture;
  final textFieldController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    textFieldController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _cameraController = CameraController(
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeCameraControllerFuture = _cameraController.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: SizedBox(
              width: 300,
              height: 300,
              child: CameraPreview(_cameraController),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: TextField(
              controller: textFieldController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter a comment',
              ),
            ),
          ),
          TextButton(
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
              backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
            ),
            onPressed: () async {
              var pos = await determinePosition();
              // Take the Picture in a try / catch block. If anything goes wrong,
              // catch the error.
              try {
                // Ensure that the camera is initialized.
                await _initializeCameraControllerFuture;
                // Attempt to take a picture and then get the location
                // where the image file is saved.
                final image = await _cameraController.takePicture();
                final res = await postData(textFieldController.text,
                    pos.latitude, pos.longitude, image.path);
                print(res);
                print(res.statusCode);
                final resp_text = await res.stream.bytesToString();
                print(resp_text);
              } catch (e) {
                // If an error occurs, log the error to the console.
                print(e);
              }
            },
            child: const Text('Post a photo, comment and loc.'),
          ),
        ]),
      ),
    );
  }
}
