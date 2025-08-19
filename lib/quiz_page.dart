// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:driversapp/home_page2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'data_provider.dart';
import 'class_page.dart';
import 'timer_logic.dart'; // Import the timer logic

class QuizPage extends StatefulWidget {
  final String driverNumber;

  const QuizPage(
      {super.key, required this.driverNumber, required String status});

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Map<String, dynamic>> _questions = [];
  List<int> _selectedOptions = [];
  int _currentQuestionIndex = 0;
  int _correctAnswersCount = 0;
  FlutterTts flutterTts = FlutterTts();
  bool _isLoading = false;
  String _reasonForBlocking = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      _initializeQuiz(); // Safe to access Provider here
      _isInitialized = true;
    }
  }

  // void _initializeQuiz() {
  //   final dataProvider = Provider.of<DataProvider>(context, listen: false);
  //   _reasonForBlocking =
  //       dataProvider.profileData?['safetyMetrics']['reasonForBlocking'] ?? '';

  //   if (_reasonForBlocking == 'HOS') {
  //     _questions = _hosQuestions;
  //   } else if (_reasonForBlocking == 'HARSH_BRAKING') {
  //     _questions = _harshBrakingQuestions;
  //   } else if (_reasonForBlocking == 'HARSH_ACCELERATION') {
  //     _questions = _harshAccelerationQuestions;
  //   } else if (_reasonForBlocking == 'OVERSPEEDING') {
  //     _questions = _overSpeedingQuestions;
  //   } else {
  //     _questions = _defaultQuestions;
  //   }

  //   _selectedOptions = List<int>.filled(_questions.length, -1);
  // }

  void _initializeQuiz() {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final safetyMetrics = dataProvider.profileData?['safetyMetrics'];
    _reasonForBlocking = safetyMetrics?['reasonForBlocking'] ?? '';

    if (_reasonForBlocking == 'HOS') {
      _questions = _hosQuestions;
    } else if (_reasonForBlocking == 'HARSH_BRAKING') {
      _questions = _harshBrakingQuestions;
    } else if (_reasonForBlocking == 'HARSH_ACCELERATION') {
      _questions = _harshAccelerationQuestions;
    } else if (_reasonForBlocking == 'OVERSPEEDING') {
      _questions = _overSpeedingQuestions;
    } else {
      _questions = _defaultQuestions;
    }

    _selectedOptions = List<int>.filled(_questions.length, -1);
  }

  void _onOptionSelected(int optionIndex) {
    if (_currentQuestionIndex < _questions.length) {
      setState(() {
        _selectedOptions[_currentQuestionIndex] = optionIndex;
        if (_questions[_currentQuestionIndex]['correctOption'] == optionIndex) {
          _correctAnswersCount++;
        }

        if (_currentQuestionIndex < _questions.length - 1) {
          _currentQuestionIndex++;
        }
      });
    }
  }

  Future<void> _speakCurrentQuestion() async {
    String questionText =
        _questions[_currentQuestionIndex]['questionText'] ?? '';
    List<String> options =
        List<String>.from(_questions[_currentQuestionIndex]['options']);

    // Check the reason for blocking and translate the question accordingly
    String pidginQuestion;
    List<String> pidginOptions;

    if (_reasonForBlocking == 'HOS') {
      pidginQuestion = _translateHOSQuestionToPidgin(questionText);
      pidginOptions =
          options.map((option) => _translateHOSOptionToPidgin(option)).toList();
    } else if (_reasonForBlocking == 'HARSH_BRAKING') {
      pidginQuestion = _translateHarshBrakingQuestionToPidgin(questionText);
      pidginOptions = options
          .map((option) => _translateHarshBrakingOptionToPidgin(option))
          .toList();
    } else if (_reasonForBlocking == 'HARSH_ACCELERATION') {
      pidginQuestion =
          _translateHarshAccelerationQuestionToPidgin(questionText);
      pidginOptions = options
          .map((option) => _translateHarshAccelerationOptionToPidgin(option))
          .toList();
    } else if (_reasonForBlocking == 'OVERSPEEDING') {
      pidginQuestion = _translateOverSpeedingQuestionToPidgin(questionText);
      pidginOptions = options
          .map((option) => _translateOverSpeedingOptionToPidgin(option))
          .toList();
    } else {
      // Use default English if no specific reason for blocking is found
      pidginQuestion = questionText;
      pidginOptions = options;
    }

    // Combine question and options into a single Pidgin string
    String speechText =
        "Question: $pidginQuestion. Options: ${pidginOptions.join(', ')}.";

    // Speak the text in Pidgin English
    await flutterTts.setSpeechRate(0.4);
    await flutterTts.speak(speechText);
  }

  // Helper methods to translate HOS questions and options into Pidgin English
  String _translateHOSQuestionToPidgin(String text) {
    switch (text) {
      case 'What is the maximum continuous driving hours without rest?':
        return 'How many hours you fit drive without stopping?';
      case 'What is the maximum daily driving hour?':
        return 'How many hours you fit drive for one day?';
      case 'What is the duration of weekly rest in 7 rolling days?':
        return 'How many hours you suppose rest every 7 days?';
      case 'What factors cannot contribute to fatigue?':
        return 'Which one no dey cause person to tire?';
      case 'The following are the hidden dangers of driving when fatigued except':
        return 'Which one no be wahala if you dey drive when you don tire?';
      default:
        return text;
    }
  }

  String _translateHOSOptionToPidgin(String text) {
    switch (text) {
      case '2HRS':
        return '2 hours';
      case '3HRS':
        return '3 hours';
      case '4HRS':
        return '4 hours';
      case '12HRS':
        return '12 hours';
      case '14HRS':
        return '14 hours';
      case '8HRS':
        return '8 hours';
      case '24HRS':
        return '24 hours';
      case 'Lack of adequate sleep':
        return 'Sleep wey no reach';
      case 'Intake of certain medicines':
        return 'Some kind medicine wey you take';
      case 'Exercising the body':
        return 'Exercise wey you do for body';
      default:
        return text;
    }
  }

  // Helper methods to translate Harsh Braking questions and options into Pidgin English
  String _translateHarshBrakingQuestionToPidgin(String text) {
    switch (text) {
      case 'How can you avoid harsh breaking?':
        return 'How you fit avoid sudden brake?';
      case 'What should you do if another vehicle is tailgating you?':
        return 'Wetin you go do if person dey follow you for back?';
      case 'Progressive braking will not help to prevent an accident':
        return 'Gradual braking no go fit stop accident?';
      default:
        return text;
    }
  }

  String _translateHarshBrakingOptionToPidgin(String text) {
    switch (text) {
      case 'Keep a safe following distance':
        return 'Give space for front of you';
      case 'Use engine braking when possible by downshifting':
        return 'Use engine brake instead of pressing brake hard';
      case 'All of the above':
        return 'All of them';
      case 'Brake suddenly to create distance':
        return 'Jam brake to give space';
      case 'Change lanes and let the vehicle pass':
        return 'Shift lane make the car pass';
      case 'Speed up to maintain distance':
        return 'Speed up make space dey';
      default:
        return text;
    }
  }

  // Helper methods to translate Harsh Acceleration questions and options into Pidgin English
  String _translateHarshAccelerationQuestionToPidgin(String text) {
    switch (text) {
      case 'When a driver is in a hurry there is a likelihood of harsh acceleration?':
        return 'If driver dey hurry, e fit match accelerator sudden?';
      case 'One of the below is not a reason why harsh acceleration is classified as a bad driving attitude is?':
        return 'Which one no be reason why sudden acceleration na bad habit?';
      case 'Harsh acceleration is preventable by observing the following but':
        return 'You fit avoid sudden acceleration if you follow this but...';
      default:
        return text;
    }
  }

  String _translateHarshAccelerationOptionToPidgin(String text) {
    switch (text) {
      case 'Being aggressive to other road users':
        return 'Waka anyhow with other drivers';
      case 'Keep your foot steady on the pedal':
        return 'Keep leg calm for pedal';
      case 'Use light footwear to feel the pedals':
        return 'Wear light shoe to feel pedal';
      case 'True':
        return 'True';
      case 'False':
        return 'False';
      default:
        return text;
    }
  }

  // Helper methods to translate Over Speeding questions and options into Pidgin English
  String _translateOverSpeedingQuestionToPidgin(String text) {
    switch (text) {
      case 'Which of the following is said to be over Lafarge Africa Plc speed limit?':
        return 'Which one be over Lafarge speed limit?';
      case 'The speed limit sign tells a driver':
        return 'Speed limit sign dey tell driver say...';
      case 'When approaching a busy junction which of the following will you not do':
        return 'If you dey near busy junction, which one you no go do?';
      default:
        return text;
    }
  }

  String _translateOverSpeedingOptionToPidgin(String text) {
    switch (text) {
      case '60Km/Hr':
        return '60 kilometers per hour';
      case '36Km/Hr':
        return '36 kilometers per hour';
      case '79Km/Hr':
        return '79 kilometers per hour';
      case 'All of the above':
        return 'All of dem';
      case 'The recommended speed to drive':
        return 'Speed wey dem recommend make you drive';
      case 'The maximum speed to drive':
        return 'Maximum speed wey you fit drive';
      default:
        return text;
    }
  }

  Future<void> _submitQuiz() async {
    setState(() {
      _isLoading = true;
    });

    int totalQuestions = _questions.length;
    double scorePercentage = (_correctAnswersCount / totalQuestions) * 100;
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final sapId = dataProvider.profileData?['sapId'] ?? '';
    final token = dataProvider.token;

    if (scorePercentage >= 80) {
      final response = await http.post(
        Uri.parse('https://staging-812204315267.us-central1.run.app/quiz/submit'
            ),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
          'app-version': '1.12',
          'app-name': 'drivers app',
        },
        body: jsonEncode(<String, dynamic>{
          'sapId': sapId,
          'score': scorePercentage,
        }),
      );

      debugPrint(response.body);
      debugPrint(_correctAnswersCount.toString());
      debugPrint(totalQuestions.toString());
    }

    setState(() {
      _isLoading = false;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Quiz Result'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You scored ${scorePercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: scorePercentage >= 80 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                scorePercentage >= 80
                    ? 'You will be notified when you are unblocked.'
                    : 'Please take the class again.',
                style: TextStyle(
                  color: scorePercentage >= 80 ? Colors.green : Colors.red,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (scorePercentage >= 80) {
                  _showAcknowledgementDialog();
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClassPage(
                        driverNumber: widget.driverNumber,
                      ),
                    ),
                  );
                }
              },
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Proceed'),
            ),
          ],
        );
      },
    );
  }

  void _showAcknowledgementDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Acknowledgement'),
          content: const Text(
              'Thank you for completing the quiz. Your score has been recorded.'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                setState(() {
                  _isLoading = true;
                });
                await startTimerLogic(context);
                setState(() {
                  _isLoading = false;
                });
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomePage2(),
                  ),
                );
              },
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _questions[_currentQuestionIndex]['questionText'] ?? '',
              style: const TextStyle(fontSize: 18, color: Colors.green),
            ),
            const SizedBox(height: 20),
            if (_questions[_currentQuestionIndex]['image'] != null)
              SizedBox(
                height: 100,
                child: Image.asset(
                  _questions[_currentQuestionIndex]['image'],
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(height: 20),
            ..._questions[_currentQuestionIndex]['options']
                .asMap()
                .entries
                .map((entry) {
              int index = entry.key;
              String option = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: ElevatedButton(
                  onPressed: () => _onOptionSelected(index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _selectedOptions[_currentQuestionIndex] == index
                            ? const Color.fromARGB(255, 25, 90, 27)
                            : const Color.fromARGB(255, 223, 255, 224),
                  ),
                  child: Text(option),
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
            if (_currentQuestionIndex == _questions.length - 1)
              ElevatedButton(
                onPressed: _isLoading ? null : _submitQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Submit',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            const SizedBox(
              height: 15,
            ),
            ElevatedButton(
              onPressed: _speakCurrentQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 10, 39, 11),
              ),
              child: const Text(
                'Read Question',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final List<Map<String, dynamic>> _hosQuestions = [
  {
    'questionText':
        'What is the maximum continuous driving hours without rest?',
    'options': ['2HRS', '3HRS', '4HRS'],
    'correctOption': 2,
  },
  {
    'questionText': 'What is the maximum daily driving hour?',
    'options': ['12HRS', '14HRS', '8HRS'],
    'correctOption': 0,
  },
  {
    'questionText': 'What is the duration of weekly rest in 7 rolling days?',
    'options': ['12HRS', '24HRS', '4HRS'],
    'correctOption': 1,
  },
  {
    'questionText': 'What factors cannot contribute to fatigue?',
    'options': [
      'Lack of adequate sleep',
      'Intake of certain medicines',
      'Exercising the body'
    ],
    'correctOption': 2,
  },
  {
    'questionText':
        'The following are the hidden dangers of driving when fatigued except',
    'options': [
      'Inability to focus',
      'Inability to apply the brakes',
      'Inability to judge distances and speeds'
    ],
    'correctOption': 1,
  },
];

final List<Map<String, dynamic>> _overSpeedingQuestions = [
  {
    'questionText':
        'Which of the following is said to be over Lafarge Africa Plc speed limit?',
    'options': ['60Km/Hr', '36Km/Hr', '79Km/Hr'],
    'correctOption': 2,
  },
  {
    'questionText': 'The speed limit sign tells a driver',
    'options': [
      'All of the above',
      'The recommended speed to drive',
      'The maximum speed to drive'
    ],
    'correctOption': 2,
    'image': 'assets/images/overspeeding.jpg',
  },
  {
    'questionText':
        'When approaching a busy junction which of the following will you not do',
    'options': [
      'Honk at other road users for visibility',
      'Increase your speed to drive pass',
      'Use your hazard light to communicate'
    ],
    'correctOption': 1,
  },
  {
    'questionText': 'Why do you ensure you keep a safe following distance',
    'options': [
      'Other can see you and anticipate your actions',
      'You can see what is ahead of you and have time to plan',
      'All of the above'
    ],
    'correctOption': 2,
  },
  {
    'questionText':
        'The faster you drive the less control you have of the truck',
    'options': ['True', 'False'],
    'correctOption': 0,
  },
  {
    'questionText': 'Why is speeding dangerous?',
    'options': [
      'It takes drivers longer not to react',
      'Speeding vehicles takes longer to stop',
      'Crash energy does not increases exponentially'
    ],
    'correctOption': 1,
  },
];

final List<Map<String, dynamic>> _harshBrakingQuestions = [
  {
    'questionText': 'How can you avoid harsh breaking?',
    'options': [
      'Keep a safe following distance',
      'Use engine braking when possible by downshifting',
      'All of the above'
    ],
    'correctOption': 2,
  },
  {
    'questionText': 'What should you do if another vehicle is tailgating you?',
    'options': [
      'Brake suddenly to create distance',
      'Change lanes and let the vehicle pass',
      'Speed up to maintain distance'
    ],
    'correctOption': 1,
  },
  {
    'questionText': 'Progressive braking will not help to prevent an accident',
    'options': ['True', 'False'],
    'correctOption': 1,
  },
  {
    'questionText':
        'Braking too late will result in a hard stop when a driver fails to do the following but',
    'options': [
      'Plan ahead while driving',
      'Tailgating while driving',
      'Distracted while driving'
    ],
    'correctOption': 0,
  },
  {
    'questionText': 'To avoid the need for harsh braking a driver should',
    'options': [
      'Adjust the speed proactively based on road traffic and weather conditions.',
      'Avoid distractions and stay fully focused on the driving task',
      'All of the above'
    ],
    'correctOption': 2,
  },
];

final List<Map<String, dynamic>> _harshAccelerationQuestions = [
  {
    'questionText':
        'When a driver is in a hurry there is a likelihood of harsh acceleration?',
    'options': ['True', 'False'],
    'correctOption': 0,
  },
  {
    'questionText':
        'One of the below is not a reason why harsh acceleration is classified as a bad driving attitude is?',
    'options': [
      'Leave no room for adjusting to the environment',
      'It consumes fuel',
      'It helps a driver arrive his destination on time'
    ],
    'correctOption': 2,
  },
  {
    'questionText':
        'Harsh acceleration is preventable by observing the following but',
    'options': [
      'Being aggressive to other road users',
      'Keep your foot steady on the pedal',
      'Use light footwear to feel the pedals'
    ],
    'correctOption': 0,
  },
  {
    'questionText':
        'Which of the following in the picture is correct position of the foot to prevent harsh acceleration',
    'options': ['A', 'B'],
    'correctOption': 1,
    'image': 'assets/images/question2.png',
  },
  {
    'questionText':
        'How many points does a driver lose for every harsh acceleration violation',
    'options': ['1 point', '2 point', '3 point'],
    'correctOption': 0,
  },
];

final List<Map<String, dynamic>> _defaultQuestions = [
  {
    'questionText':
        'What is the maximum continuous driving hours without rest?',
    'options': ['2HRS', '3HRS', '4HRS'],
    'correctOption': 2,
  },
  {
    'questionText': 'What is the maximum daily driving hour?',
    'options': ['12HRS', '14HRS', '8HRS'],
    'correctOption': 0,
  },
  {
    'questionText': 'What is the duration of weekly rest in 7 rolling days?',
    'options': ['12HRS', '24HRS', '4HRS'],
    'correctOption': 1,
  },
  {
    'questionText': 'What factors cannot contribute to fatigue?',
    'options': [
      'Lack of adequate sleep',
      'Intake of certain medicines',
      'Exercising the body'
    ],
    'correctOption': 2,
  },
  {
    'questionText':
        'The following are the hidden dangers of driving when fatigued except',
    'options': [
      'Inability to focus',
      'Inability to apply the brakes',
      'Inability to judge distances and speeds'
    ],
    'correctOption': 1,
  },
];
