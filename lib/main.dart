import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Weather Search'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  String _cityName = '';
  String _weatherInfo = "Entrez le nom d'une ville et cliquez sur le bouton";
  String _iconCode = '';
  double _temperature = 0;
  bool _isCelsius = true;
  List<String> _favoriteCities = [];
  List<Map<String, dynamic>> _hourlyWeather = [];
  List<Map<String, dynamic>> _weeklyWeather = [];
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    var initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = IOSInitializationSettings();
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _fetchWeather(String cityName) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=0237cf359e1e121ac57e652514f9dda6&units=${_isCelsius ? 'metric' : 'imperial'}&lang=fr'),
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          _weatherInfo = data['weather'][0]['description'];
          _iconCode = data['weather'][0]['icon'];
          _temperature = (data['main']['temp'] as num).toDouble();
        });
        _checkForSevereWeather(data['weather'][0]['main']);
        _fetchHourlyWeather(data['coord']['lat'], data['coord']['lon']);
        _fetchWeeklyWeather(data['coord']['lat'], data['coord']['lon']);
      } else {
        setState(() {
          _weatherInfo = 'Failed to fetch weather data.';
        });
      }
    } catch (e) {
      setState(() {
        _weatherInfo = 'Failed to fetch weather data: $e';
      });
    }
  }

  void _checkForSevereWeather(String weatherMain) {
    if (weatherMain == 'Thunderstorm' || weatherMain == 'Rain') {
      _showNotification(weatherMain);
    }
  }

  Future<void> _showNotification(String weatherMain) async {
    var androidDetails = AndroidNotificationDetails(
        'channelId', 'channelName', 'channelDescription',
        importance: Importance.high);
    var iOSDetails = IOSNotificationDetails();
    var generalNotificationDetails =
        NotificationDetails(android: androidDetails, iOS: iOSDetails);

    await flutterLocalNotificationsPlugin.show(
        0,
        'Alerte météo',
        'Il y a des risques de $weatherMain dans votre zone.',
        generalNotificationDetails,
        payload: 'Severe Weather');
  }

  void _fetchWeatherForCurrentLocation() async {
    Position position = await _determinePosition();
    _fetchWeatherByCoordinates(position.latitude, position.longitude);
  }

  void _fetchWeatherByCoordinates(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=0237cf359e1e121ac57e652514f9dda6&units=${_isCelsius ? 'metric' : 'imperial'}&lang=fr'),
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          _weatherInfo = data['weather'][0]['description'];
          _iconCode = data['weather'][0]['icon'];
          _temperature = (data['main']['temp'] as num).toDouble();
        });
        _checkForSevereWeather(data['weather'][0]['main']);
        _fetchHourlyWeather(lat, lon);
        _fetchWeeklyWeather(lat, lon);
      } else {
        setState(() {
          _weatherInfo = 'Failed to fetch weather data.';
        });
      }
    } catch (e) {
      setState(() {
        _weatherInfo = 'Failed to fetch weather data: $e';
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _fetchHourlyWeather(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=0237cf359e1e121ac57e652514f9dda6&units=${_isCelsius ? 'metric' : 'imperial'}&lang=fr'),
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          _hourlyWeather = (data['list'] as List)
              .map((item) => {
                    'time': item['dt_txt'],
                    'temp': (item['main']['temp'] as num).toDouble(),
                    'description': item['weather'][0]['description'],
                    'icon': item['weather'][0]['icon']
                  })
              .toList();
        });
      } else {
        setState(() {
          _weatherInfo = 'Failed to fetch hourly weather data.';
        });
      }
    } catch (e) {
      setState(() {
        _weatherInfo = 'Failed to fetch hourly weather data: $e';
      });
    }
  }

  void _fetchWeeklyWeather(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.openweathermap.org/data/2.5/onecall?lat=$lat&lon=$lon&exclude=hourly,minutely&appid=0237cf359e1e121ac57e652514f9dda6&units=${_isCelsius ? 'metric' : 'imperial'}&lang=fr'),
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          _weeklyWeather = (data['daily'] as List)
              .map((item) => {
                    'day': DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000),
                    'temp': (item['temp']['day'] as num).toDouble(),
                    'description': item['weather'][0]['description'],
                    'icon': item['weather'][0]['icon']
                  })
              .toList();
        });
      } else {
        setState(() {
          _weatherInfo = 'Failed to fetch weekly weather data.';
        });
      }
    } catch (e) {
      setState(() {
        _weatherInfo = 'Failed to fetch weekly weather data: $e';
      });
    }
  }

  void _toggleTemperatureUnit() {
    setState(() {
      _isCelsius = !_isCelsius;
      if (_cityName.isNotEmpty) {
        _fetchWeather(_cityName);
      }
    });
  }

  void _addFavoriteCity() {
    if (_cityName.isNotEmpty && !_favoriteCities.contains(_cityName)) {
      setState(() {
        _favoriteCities.add(_cityName);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Row(
            children: [
              Text('°C'),
              Switch(
                value: !_isCelsius,
                onChanged: (value) {
                  _toggleTemperatureUnit();
                },
              ),
              Text('°F'),
            ],
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextField(
                  decoration: InputDecoration(
                    hintText: "Entrez le nom d'une ville",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(10),
                  ),
                  onChanged: (value) {
                    _cityName = value;
                  },
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _fetchWeather(_cityName),
                  child: Text('Rechercher'),
                ),
                ElevatedButton(
                  onPressed: _fetchWeatherForCurrentLocation,
                  child: Text('Utiliser ma position actuelle'),
                ),
                SizedBox(height: 20),
                Text(
                  _weatherInfo,
                  style: TextStyle(fontSize: 20),
                ),
                if (_iconCode.isNotEmpty)
                  Image.network('http://openweathermap.org/img/w/$_iconCode.png'),
                Text(
                  '${_temperature.toStringAsFixed(1)} ${_isCelsius ? '°C' : '°F'}',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addFavoriteCity,
                  child: Text('Ajouter aux favoris'),
                ),
                if (_favoriteCities.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Villes favorites:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ..._favoriteCities.map((city) => Text(city, style: TextStyle(fontSize: 16))),
                      ],
                    ),
                  ),
                if (_hourlyWeather.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Météo heure par heure:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ..._hourlyWeather.map((hourly) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hourly['time'], style: TextStyle(fontSize: 14)),
                            Text('${hourly['temp']} ${_isCelsius ? '°C' : '°F'}', style: TextStyle(fontSize: 14)),
                            Text(hourly['description'], style: TextStyle(fontSize: 14)),
                            Image.network('http://openweathermap.org/img/w/${hourly['icon']}.png'),
                            SizedBox(height: 10),
                          ],
                        )).toList(),
                      ],
                    ),
                  ),
                if (_weeklyWeather.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Météo de la semaine:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ..._weeklyWeather.map((daily) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${daily['day'].weekday}, ${daily['day'].month}/${daily['day'].day}', style: TextStyle(fontSize: 14)),
                            Text('${daily['temp']} ${_isCelsius ? '°C' : '°F'}', style: TextStyle(fontSize: 14)),
                            Text(daily['description'], style: TextStyle(fontSize: 14)),
                            Image.network('http://openweathermap.org/img/w/${daily['icon']}.png'),
                            SizedBox(height: 10),
                          ],
                        )).toList(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
