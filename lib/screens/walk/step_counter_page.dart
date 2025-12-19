import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class StepCounterPage extends StatefulWidget {
  @override
  _StepCounterPageState createState() => _StepCounterPageState();
}

class _StepCounterPageState extends State<StepCounterPage> {
  late Stream<StepCount> _stepCountStream;
  String _steps = '0';
  String _status = '대기 중';
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    setState(() {
      _status = '권한 확인 중...';
    });

    // Android 10 (API 29) 이상에서만 ACTIVITY_RECOGNITION 권한 필요
    PermissionStatus status = await Permission.activityRecognition.request();

    if (status.isGranted) {
      _initPedometer();
    } else if (status.isDenied) {
      setState(() {
        _status = '권한이 거부되었습니다';
        _permissionDenied = true;
      });
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _status = '설정에서 권한을 허용해주세요';
        _permissionDenied = true;
      });
    }
  }

  void _initPedometer() {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(_onStepCount).onError(_onStepCountError);

    setState(() {
      _status = '측정 중';
    });
  }

  void _onStepCount(StepCount event) {
    print('걸음 수: ${event.steps}'); // 디버깅용
    setState(() {
      _steps = event.steps.toString();
    });
  }

  void _onStepCountError(error) {
    print('에러: $error'); // 디버깅용
    setState(() {
      _status = '센서 오류: $error';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('만보기'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '오늘의 걸음 수',
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
            SizedBox(height: 20),
            Text(
              _steps,
              style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '걸음',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 40),
            Text(
              _status,
              style: TextStyle(fontSize: 16, color: Colors.blue),
            ),
            if (_permissionDenied) ...[
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  openAppSettings(); // 설정 화면으로 이동
                },
                child: Text('설정에서 권한 허용하기'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}