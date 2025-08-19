import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'data_provider.dart';
import 'quiz_page.dart';
import 'theme_provider.dart';

class ClassPage extends StatefulWidget {
  final String driverNumber;

  const ClassPage({super.key, required this.driverNumber});

  @override
  _ClassPageState createState() => _ClassPageState();
}

class _ClassPageState extends State<ClassPage> {
  late VideoPlayerController _videoPlayerController;
  bool _isVideoEnded = false;
  bool _visitedQuizPage = false;
  List<String> videoPaths = [];
  int currentVideoIndex = 0;

  @override
  void initState() {
    super.initState();

    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final reasonForBlocking =
        dataProvider.profileData?['safetyMetrics']['reasonForBlocking'] ?? '';

    // Define video paths based on reason for blocking
    switch (reasonForBlocking) {
      case 'HOS':
        videoPaths = ['assets/lesson1.mp4'];
        break;
      case 'HARSH_BRAKING':
        videoPaths = ['assets/lesson33.mp4'];
        break;
      case 'HARSH_ACCELERATION':
        videoPaths = ['assets/lesson33.mp4'];
        break;
      case 'OVERSPEEDING':
        // Two videos will be played sequentially
        videoPaths = ['assets/lesson411.mp4', 'assets/lesson412.mp4'];
        break;
      default:
        videoPaths = ['assets/lesson1.mp4'];
    }

    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    _videoPlayerController =
        VideoPlayerController.asset(videoPaths[currentVideoIndex])
          ..initialize().then((_) {
            setState(() {});
            _videoPlayerController.play();
          setState(() {});
          _videoPlayerController.play();
          ScreenUtil.init(
            context, // Corrected this line
            designSize: const Size(360, 690),
          );
        });

    _videoPlayerController.addListener(() {
      if (_videoPlayerController.value.position ==
          _videoPlayerController.value.duration) {
        _playNextVideo();
      }
    });
  }

  void _playNextVideo() {
    // Check if there are more videos to play
    if (currentVideoIndex < videoPaths.length - 1) {
      currentVideoIndex++;
      _videoPlayerController.dispose(); // Dispose of the current controller
      _initializeVideoPlayer(); // Initialize the next video
    } else {
      setState(() {
        _isVideoEnded = true; // All videos have been played
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Lessons',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: themeProvider.isDarkMode ? Colors.green : Colors.green,
      ),
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.green,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 35.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (_videoPlayerController.value.isInitialized)
                FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: AspectRatio(
                      aspectRatio: _videoPlayerController.value.aspectRatio,
                      child: VideoPlayer(_videoPlayerController),
                    ),
                  ),
                ),
              VideoProgressIndicator(
                _videoPlayerController,
                allowScrubbing: false,
              ),
              _buildVideoControlBar(context),
              if (_isVideoEnded && !_visitedQuizPage)
                ElevatedButton(
                  onPressed: () async {
                    _visitedQuizPage = true;
                    await Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizPage(
                          driverNumber: widget.driverNumber,
                          status: 'status',
                        ),
                      ),
                    );
                    setState(() {
                      _visitedQuizPage = false;
                    });
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: themeProvider.isDarkMode
                        ? Colors.grey[800]
                        : const Color.fromARGB(225, 22, 133, 40),
                  ),
                  child: Text(
                    'Quiz',
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Video Control Bar Widget
  Widget _buildVideoControlBar(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.play_arrow),
          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          onPressed: () {
            _videoPlayerController.play();
          },
        ),
        IconButton(
          icon: const Icon(Icons.pause),
          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          onPressed: () {
            _videoPlayerController.pause();
          },
        ),
        IconButton(
          icon: const Icon(Icons.replay_10),
          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          onPressed: () {
            final position = _videoPlayerController.value.position;
            _videoPlayerController
                .seekTo(position - const Duration(seconds: 10));
          },
        ),
      ],
    );
  }
}
