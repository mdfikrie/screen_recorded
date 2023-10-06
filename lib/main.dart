import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

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
  Process? process;
  var ffmpegPath = "";
  var outputFile = "";

  Future<String> copyFFmpegFromAssets() async {
    final dir = await getTemporaryDirectory();
    if (Platform.isMacOS) {
      final path = '${dir.path}/ffmpeg';
      if (await File(path).exists() == false) {
        print("file belum ada");
        final data = await rootBundle.load('assets/macos/ffmpeg');
        final buffer = data.buffer.asUint8List();
        final file = await File(path).writeAsBytes(buffer);
        await Process.run('chmod', ['+x', file.path]);
        ffmpegPath = file.path;
      } else {
        ffmpegPath = path;
      }
      setState(() {});
      return ffmpegPath;
    } else {
      final path = '${dir.path}/ffmpeg.exe';
      if (File(path).exists() == false) {
        final data = await rootBundle.load('assets/ffmpeg/ffmpeg.exe');
        final buffer = data.buffer.asUint8List();
        final file = await File(path).writeAsBytes(buffer);
        ffmpegPath = file.path;
      } else {
        ffmpegPath = path;
      }
      setState(() {});
      return ffmpegPath;
    }
  }

  Future<void> startRecording({required String fileName}) async {
    if (Platform.isMacOS) {
      final directory = await getTemporaryDirectory();
      final customPath = directory.path + "/recording";
      try {
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
      ffmpegPath = await copyFFmpegFromAssets();
      print(ffmpegPath);
      try {
        if (process != null) {
          await process?.exitCode;
        }
        var fileName = DateTime.now().microsecondsSinceEpoch;
        outputFile = File('${Directory.current.path}/$fileName.mp4').path;
        final arguments = [
          '-f',
          'gdigrab',
          '-framerate',
          '1',
          '-i',
          'desktop',
          '-c:v',
          'libx264',
          '-preset',
          'ultrafast',
          "-profile:v",
          "high",
          "-crf",
          "35", // Nilai antara 18 (kualitas tinggi) hingga 28 (kualitas rendah). Default adalah 23.
          "-pix_fmt",
          "yuv420p",
          outputFile,
        ];

        print(outputFile);

        process = await Process.start(ffmpegPath, arguments);

        // Mendengarkan STDOUT
        process!.stdout.transform(utf8.decoder).listen((data) {
          print('STDOUT: $data');
        });

        // Mendengarkan STDERR
        process!.stderr.transform(utf8.decoder).listen((data) {
          print('STDERR: $data');
        });

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
        compressVideo();
      } catch (e) {
        print('Failed to stop recording: $e');
      }
      // process!.stdin.writeln('q');
    } else {
      try {
        process!.stdin.writeln('q');
        await Future.delayed(Duration(seconds: 2));
        print("data akan di compress");
        compressVideo();
        print('Recording stopped');
      } catch (e) {
        print('Error stopping recording: $e');
      }
    }
  }

  Future<void> compressVideo() async {
    try {
      if (Platform.isMacOS) {
        ffmpegPath = await copyFFmpegFromAssets();
        print(ffmpegPath);
        final directory = await getTemporaryDirectory();
        final customPath = directory.path + "/recording/output1.mp4";
        videoPathList.forEach((element) async {
          element;
          var arguments = [
            "-i",
            element as String,
            "-c:v",
            "libx264",
            "-profile:v",
            "high",
            "-crf",
            "35", // Nilai antara 18 (kualitas tinggi) hingga 28 (kualitas rendah). Default adalah 23.
            "-pix_fmt",
            "yuv420p",
            customPath,
          ];

          var process = await Process.start(ffmpegPath, arguments);
          process.stdout.transform(utf8.decoder).listen((data) {
            print('STDOUT: $data');
          });

          // Mendengarkan STDERR
          process.stderr.transform(utf8.decoder).listen((data) {
            print('STDERR: $data');
          });
          int result = await process.exitCode;
          if (result == 0) {
            print("Kompresi berhasil!");
            if (await File(element).exists() == true) {
              File(element).delete();
            }
          } else {
            print("Terjadi kesalahan saat kompresi.");
          }
        });
      } else {
        ffmpegPath = await copyFFmpegFromAssets();
        var fileOutput = outputFile = File(
                '${Directory.current.path}/${DateFormat('dd-M-y').format(DateTime.now())}.${DateTime.now().millisecondsSinceEpoch}.mp4')
            .path;
        ;
        var arguments = [
          "-i",
          outputFile,
          "-c:v",
          "libx264",
          "-profile:v",
          "high",
          "-crf",
          "35", // Nilai antara 18 (kualitas tinggi) hingga 28 (kualitas rendah). Default adalah 23.
          "-pix_fmt",
          "yuv420p",
          fileOutput
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
        int result = await process!.exitCode;
        if (result == 0) {
          print("Kompresi berhasil!");
          if (await File(outputFile).exists() == true) {
            File(outputFile).delete();
          }
        } else {
          print("Terjadi kesalahan saat kompresi.");
        }
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
          children: [
            Text(
              ffmpegPath,
              textAlign: TextAlign.center,
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
