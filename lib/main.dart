import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  runApp(MyApp());
}

// Notification channel ID
const notificationChannelId = 'my_foreground';
const notificationId = 888;

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    'MY FOREGROUND SERVICE',
    description: 'This channel is used for important notifications.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'Location Tracking Service',
      initialNotificationContent: 'Initializing...',
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Timer? timer; // Declare timer

  service.on('start').listen((_) {
    timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        flutterLocalNotificationsPlugin.show(
          notificationId,
          'Service Disabled',
          'Please enable location services.',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              notificationChannelId,
              'MY FOREGROUND SERVICE',
              icon: 'ic_bg_service_small',
              ongoing: true,
            ),
          ),
        );
        return;
      }

      // Get current position
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Get current time and format it
        final now = DateTime.now();
        final formattedDate = DateFormat('dd-MM-yyyy').format(now);
        final formattedTime = DateFormat('HH:mm:ss').format(now);
        final time = '$formattedDate $formattedTime';

        // Update notification with current location
        flutterLocalNotificationsPlugin.show(
          notificationId,
          'Location Update',
          'Lat: ${position.latitude}, Lon: ${position.longitude}',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              notificationChannelId,
              'MY FOREGROUND SERVICE',
              icon: 'ic_bg_service_small',
              ongoing: true,
            ),
          ),
        );

        // Store the location data with the current timestamp
        service.invoke('update', {
          'time': time,
          'latitude': position.latitude,
          'longitude': position.longitude
        });
      } catch (e) {
        print('Error retrieving location: $e');
      }
    });
  });

  service.on('stop').listen((_) {
    timer?.cancel(); // Stop the timer
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Location Tracker',
      home: LocationPage(),
    );
  }
}

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  List<Map<String, dynamic>> _locationData = [];
  bool _isTracking = false; // To track if the service is running

  @override
  void initState() {
    super.initState();

    FlutterBackgroundService().on('update').listen((data) {
      if (data!['time'] != null) {
        setState(() {
          _locationData.add({
            'time': data['time'],
            'latitude': data['latitude'],
            'longitude': data['longitude'],
          });
        });
      }
    });
  }

  Future<void> requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      // Permission granted
    } else if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied')),
      );
    } else if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission permanently denied')),
      );
      openAppSettings();
    }
  }

  void _startTracking() {
    _isTracking = true; // Update tracking status
    FlutterBackgroundService().invoke('start'); // Start the service
  }

  void _stopTracking() {
    _isTracking = false; // Update tracking status
    FlutterBackgroundService().invoke('stop'); // Stop the service
    setState(() {
      _locationData.clear(); // Clear the location data
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh location data if needed
            },
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: requestLocationPermission,
            child: const Text('Request Location Permission'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isTracking ? _stopTracking : _startTracking,
            child: Text(_isTracking ? 'Stop Tracking' : 'Start Tracking'),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _locationData.isEmpty
                ? const Center(child: Text('No location data available.'))
                : SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Time')),
                        DataColumn(label: Text('Longitude')),
                        DataColumn(label: Text('Latitude')),
                      ],
                      rows: _locationData.map((data) {
                        return DataRow(cells: [
                          DataCell(Text(data['time'])),
                          DataCell(Text(data['longitude'].toStringAsFixed(6))),
                          DataCell(Text(data['latitude'].toStringAsFixed(6))),
                        ]);
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
