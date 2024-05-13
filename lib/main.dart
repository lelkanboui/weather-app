import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  String _weatherInfo = 'Enter a city name and press search';
  String _iconCode = '';  // Pour stocker le code de l'icône météo
  double _temperature = 0;  // Pour stocker la température

  void _fetchWeather(String cityName) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=0237cf359e1e121ac57e652514f9dda6&units=metric&lang=fr'), // Remplacez 'YOUR_API_KEY' par votre clé API.
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          _weatherInfo = data['weather'][0]['description'];
          _iconCode = data['weather'][0]['icon'];
          _temperature = (data['main']['temp'] as num).toDouble();
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              decoration: const InputDecoration(
                hintText: 'Enter a city name',
              ),
              onChanged: (value) {
                _cityName = value;
              },
            ),
            ElevatedButton(
              onPressed: () => _fetchWeather(_cityName),
              child: const Text('Submit'),
            ),
            Text(_weatherInfo),
            if (_iconCode.isNotEmpty)
              Image.network('http://openweathermap.org/img/w/$_iconCode.png'),
            Text('${_temperature.toStringAsFixed(1)} °C'),
          ],
        ),
      ),
    );
  }
}
