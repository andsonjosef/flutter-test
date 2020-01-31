import 'dart:async';

import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'First App',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'First App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String value = "Pressione o botão para scanear";
  Future _scanQR() async {
    try {
      String qrResult = await BarcodeScanner.scan();
      setState(() {
        value = qrResult;
      });
    } on PlatformException catch (ex) {
      if (ex.code == BarcodeScanner.CameraAccessDenied) {
        setState(() {
          value = "Sem permissão para usar a câmera";
        });
      } else {
        setState(() {
          value = "Erro desconhecido $ex";
        });
      }
    } on FormatException {
      setState(() {
        value = "O scaner foi fechado antes de scanear";
      });
    } catch (ex) {
      setState(() {
        value = "Erro desconhecidor $ex";
      });
    }
  }

  bool scanning = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  BluetoothDevice device;
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<ScanResult> dta = [];

  startStop() {
    dta.forEach((f) => print(f.device.id));

    if (scanning) {
      flutterBlue.stopScan();
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("you have ${dta.length} devices"),
      ));
    } else {
      flutterBlue.startScan(timeout: Duration(seconds: 4));
    }
    setState(() {
      scanning = !scanning;
    });
  }

  conect(selectedDevice) async {
    device = selectedDevice;
    print(device.id);
    await device.connect();

    List<BluetoothService> services = await device.discoverServices();
    services.forEach((service) async {
      var characteristics = service.characteristics;
      for (BluetoothCharacteristic c in characteristics) {
        List<int> value = await c.read();
        print(value);
        await c.write([0x12, 0x34]);
        
      }
      

// Writes to a characteristic
    });
// Disconnect from device
    // device.disconnect();
  }

  Future _scanBluetooh() async {
    List<String> lista = [];
    print('>>>>>>>>>>>>>>>>>>>>>>>>>>');
    flutterBlue.scan(timeout: Duration(seconds: 10)).listen((scanResult) {
      device = scanResult.device;
      device = scanResult.device;
      print('${device.name} found! rssi: ${scanResult.rssi}');

      if (device.name != "") {
        print("entrou");

        lista.add(device.name);
      }
    });
    lista.forEach((f) => print(f));

// Stop scanning
    flutterBlue.stopScan();

    setState(() {
      // value = qrResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          FlatButton(
            child: Text(
              scanning ? "Stop Scanning" : "Start Scanning",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            onPressed: () {
              startStop();
            },
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.display1,
                  ),
                ),
                RaisedButton(
                    onPressed: _scanQR, child: Icon(Icons.settings_overscan))
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ScanResult>>(
              stream: FlutterBlue.instance.scanResults,
              initialData: [],
              builder: (c, snapshot) {
                dta = snapshot.data;
                return ListView.builder(
                  itemCount: snapshot.data.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Icon(Icons.wb_sunny),
                      title: Text(
                          snapshot.data[index].device.name.toString() != ''
                              ? snapshot.data[index].device.name.toString()
                              : snapshot.data[index].device.id.toString()),
                      trailing: Icon(Icons.keyboard_arrow_right),
                      onTap: () {
                        conect(snapshot.data[index].device);
                      },
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
