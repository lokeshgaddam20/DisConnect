import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BleController extends GetxController {
  FlutterBlue ble = FlutterBlue.instance;

  // Function to scan nearby BLE devices
  Future<void> scanDevices() async {
    if (await Permission.bluetoothScan.request().isGranted) {
      if (await Permission.bluetoothConnect.request().isGranted) {
        ble.startScan(timeout: Duration(seconds: 15));
      }
    }
  }

  // Function to connect to a BLE device
  Future<void> connectToDevice(BluetoothDevice device) async {
    if (await Permission.bluetoothConnect.request().isGranted) {
      await device.connect(timeout: Duration(seconds: 15));
      device.state.listen((isConnected) {
        if (isConnected == BluetoothDeviceState.connecting) {
          print("Device connecting to: ${device.name}");
        } else if (isConnected == BluetoothDeviceState.connected) {
          print("Device connected: ${device.name}");
        } else {
          print("Device Disconnected");
        }
      });
    }
  }

  // Function to stop scanning for BLE devices
  void stopScan() {
    ble.stopScan();
  }

  // Function to disconnect from a BLE device
  Future<void> disconnectDevice(BluetoothDevice device) async {
    await device.disconnect();
  }

  // Stream to get scan results
  Stream<List<ScanResult>> get scanResults => ble.scanResults;
}
