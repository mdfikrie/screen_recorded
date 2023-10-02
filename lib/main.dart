import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell.dart';
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
  Process? ffmpegProcess;
  final shell = Shell();
  final ffmpegPath =
      r'C:\Users\dzulfikri\Downloads\Compressed\ffmpeg-1\bin\ffmpeg.exe';
  Process? process;

  Future<void> startRecording({required String fileName}) async {
    if (Platform.isMacOS) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final customPath = directory.path + "/recording";
        final path =
            await screenRecordingChannel.invokeMethod('startRecording', {
          "file_name": fileName,
          "path": customPath,
        });
        videoPathList = path as List;
        print('Recording started and will be saved to: $path');
      } catch (e) {
        print('Failed to start recording: $e');
      }
    } else {
      try {
        if (process != null) {
          await process?.exitCode;
        }
        // final arguments =
        //     '-f gdigrab -framerate 30 -i desktop -c:v libx264 -preset ultrafast output.mkv';
        // await shell.run('$ffmpegPath $arguments');
        final ffmpegPath =
            'C:\\Users\\dzulfikri\\Downloads\\Compressed\\ffmpeg-1\\bin\\ffmpeg.exe';
        final arguments = [
          '-f',
          'gdigrab',
          '-framerate',
          '30',
          '-i',
          'desktop',
          '-c:v',
          'libx264',
          '-preset',
          'ultrafast',
          'output.mp4'
        ];

        process = await Process.start(ffmpegPath, arguments);

        // Mendengarkan STDOUT
        process!.stdout.transform(utf8.decoder).listen((data) {
          print('STDOUT: $data');
        });

        // Mendengarkan STDERR
        process!.stderr.transform(utf8.decoder).listen((data) {
          print('STDERR: $data');
        });
        await Future.delayed(Duration(seconds: 5));

        // Menunggu proses untuk selesai dan mendapatkan exit code
        // final exitCode = await process!.exitCode;
        // print('Exit code: $exitCode');
        print('Recording started');
      } catch (e) {
        print('Error starting recording: $e');
      }
    }
  }

  Future<void> stopRecording() async {
    if (Platform.isMacOS) {
      try {
        await screenRecordingChannel.invokeMethod('stopRecording');
        print('Recording stopped');
      } catch (e) {
        print('Failed to stop recording: $e');
      }
    } else {
      try {
        // await Process.run('taskkill', ['/PID', pid.toString(), '/F']);
        // final arguments =
        //     "-i output.mkv -c:v libx264 -profile:v high -pix_fmt yuv420p output.mp4";
        // await shell.kill();
        // shell.run('$ffmpegPath $arguments');
        // await shell.run("taskkill /f /im ffmpeg.exe");
        process!.stdin.writeln('q');

        print('Recording stopped');
      } catch (e) {
        print('Error stopping recording: $e');
      }
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
      final path =
          "/Users/user/Library/Containers/com.example.screenRecorded/Data/Documents/recording/16959725489622.mp4";
      MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        path,
        quality: VideoQuality.Res960x540Quality,
        deleteOrigin: false, // It's false by default
        frameRate: 5,
        includeAudio: false,
      );
      if (mediaInfo != null) {
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
        child: Text(
          isPlay == true
              ? "Video recording running.."
              : "Video recording paused.",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // FloatingActionButton(
          //   onPressed: () {
          //     installFFMPEG();
          //   },
          //   child: Icon(Icons.install_desktop),
          // ),
          // SizedBox(width: 10),
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
