import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import "package:path/path.dart" as p;
import 'package:video_compress/video_compress.dart';

const screenRecordingChannel =
    MethodChannel("com.time_tracker/screen_recording");

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Screen Recording'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var isPlay = false;
  var videoPathList = [];
  Future<void> startRecording({required String fileName}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final customPath = directory.path + "/recording";
      final path = await screenRecordingChannel.invokeMethod('startRecording', {
        "file_name": fileName,
        "path": customPath,
      });
      videoPathList = path as List;
      print('Recording started and will be saved to: $path');
    } catch (e) {
      print('Failed to start recording: $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      await screenRecordingChannel.invokeMethod('stopRecording');
      print('Recording stopped');
    } catch (e) {
      print('Failed to stop recording: $e');
    }
  }

  Future<void> compressVideo() async {
    try {
      // videoPathList.forEach((element) async {
        // var inputName = p.basename(element);
        // var outputName = "compress-$inputName";
        // var outputPath = element.toString().replaceAll(inputName, outputName);
        // final result = await screenRecordingChannel.invokeMethod(
        //     "compressVideo", {"input_url": element, "output_url": outputPath});
        // print(result);
        final path = "/Users/user/Library/Containers/com.example.screenRecorded/Data/Documents/recording/16959725489622.mp4";
        MediaInfo? mediaInfo = await VideoCompress.compressVideo(
          path,
          quality: VideoQuality.Res960x540Quality,
          deleteOrigin: false, // It's false by default
          frameRate: 5,
          includeAudio: false,
        );
        if(mediaInfo!=null){
          print(mediaInfo.filesize);
          print(mediaInfo.path);
        }
      // });
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              isPlay == true
                  ? "Video recording running.."
                  : "Video recording paused.",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: () {
              compressVideo();
            },
            child: Icon(Icons.compress),
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () async {
              if (isPlay == false) {
                var date = DateTime.now();
                startRecording(
                    fileName: date.millisecondsSinceEpoch.toString());
                setState(() {
                  isPlay = true;
                });
              } else {
                stopRecording();
                setState(() {
                  isPlay = false;
                });
              }
            },
            child: isPlay == false
                ? const Icon(Icons.play_arrow)
                : Icon(Icons.pause_outlined),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
