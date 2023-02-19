import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  runApp(MyApp());
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (_) => Home());
    case 'browser':
      return MaterialPageRoute(
          builder: (_) => DevicesListScreen(deviceType: DeviceType.browser));
    case 'advertiser':
      return MaterialPageRoute(
          builder: (_) => DevicesListScreen(deviceType: DeviceType.advertiser));
    case 'SOS':
      return MaterialPageRoute(
          builder: (_) => FuncListScreen(funcTypes: funcType.SOS));
    case 'announcements':
      return MaterialPageRoute(
          builder: (_) => Announcements());
    default:
      return MaterialPageRoute(
          builder: (_) => Scaffold(
                body: Center(
                    child: Text('No route defined for ${settings.name}')),
              ));
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: generateRoute,
      initialRoute: '/',
    );
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, 'SOS');
              },
              child: Container(
                color: Color.fromARGB(255, 1, 103, 107),
                child: Center(
                    child: Text(
                  'SOS',
                  style: TextStyle(color: Colors.white, fontSize: 40),
                )),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, 'announcements');
              },
              child: Container(
                color: Color.fromARGB(255, 1, 103, 107),
                child: Center(
                    child: Text(
                  'Announcements',
                  style: TextStyle(color: Colors.white, fontSize: 40),
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


 

enum DeviceType { advertiser, browser }
enum ButtonType { advertiser, browser , SOS, announcements}

enum funcType { SOS, announcements }

class DevicesListScreen extends StatefulWidget {
  const DevicesListScreen({required this.deviceType });
  // const DevicesListScreen({required this.deviceType});

  final DeviceType deviceType;
  // final DeviceType deviceType;

  @override
  _DevicesListScreenState createState() => _DevicesListScreenState();
}

class FuncListScreen extends StatefulWidget {
  const FuncListScreen({required this.funcTypes });
  // const DevicesListScreen({required this.deviceType});

  final funcType funcTypes;
  // final DeviceType deviceType;

  @override
  _FuncListScreenState createState() => _FuncListScreenState();
}

class _DevicesListScreenState extends State<DevicesListScreen> {
  List<Device> devices = [];
  List<Device> connectedDevices = [];
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<List<String>> items;
  late NearbyService nearbyService;
  late StreamSubscription subscription;
  late StreamSubscription receivedDataSubscription;

  bool isInit = false;

  @override
  void initState() {
    super.initState();
    items = _prefs.then((SharedPreferences prefs) {
      return prefs.getStringList('items') ?? [""];
    });
    init();
  }

  @override
  void dispose() {
    subscription.cancel();
    receivedDataSubscription.cancel();
    nearbyService.stopBrowsingForPeers();
    nearbyService.stopAdvertisingPeer();
    super.dispose();
  }

  Future<void> addItems(String msg) async {
    final SharedPreferences prefs = await _prefs;
    
    final List<String> _items = (prefs.getStringList('_items') ?? [""]);
    _items.add(msg);

    setState(() {
      items = prefs.setStringList('_items', _items).then((bool success) {
        return _items;
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(""),
        ),
        backgroundColor: Colors.white,
        body: ListView.builder(
            itemCount: getItemCount(),
            itemBuilder: (context, index) {
              final device = widget.deviceType == DeviceType.advertiser
                  ? connectedDevices[index]
                  : devices[index];
              return Container(
                margin: EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: GestureDetector(
                          onTap: () => _onTabItemListener(device),
                          child: Column(
                            children: [
                              Text(device.deviceName),
                              Text(
                                getStateName(device.state),
                                style: TextStyle(
                                    color: getStateColor(device.state)),
                              ),
                            ],
                            crossAxisAlignment: CrossAxisAlignment.start,
                          ),
                        )),
                        // Request connect
                        GestureDetector(
                          onTap: () => _onButtonClicked(device),
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 8.0),
                            padding: EdgeInsets.all(8.0),
                            height: 35,
                            width: 100,
                            color: getButtonColor(device.state),
                            child: Center(
                              child: Text(
                                getButtonStateName(device.state),
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 8.0,
                    ),
                    Divider(
                      height: 1,
                      color: Colors.grey,
                    )
                  ],
                ),
              );
            }));
  }

  String getStateName(SessionState state) {
    switch (state) {
      case SessionState.notConnected:
        return "disconnected";
      case SessionState.connecting:
        return "waiting";
      default:
        return "connected";
    }
  }

  String getButtonStateName(SessionState state) {
    switch (state) {
      case SessionState.notConnected:
      case SessionState.connecting:
        return "Connect";
      default:
        return "Disconnect";
    }
  }

  Color getStateColor(SessionState state) {
    switch (state) {
      case SessionState.notConnected:
        return Colors.black;
      case SessionState.connecting:
        return Colors.grey;
      default:
        return Color.fromARGB(255, 32,42,68);
    }
  }

  Color getButtonColor(SessionState state) {
    switch (state) {
      case SessionState.notConnected:
      case SessionState.connecting:
        return Color.fromARGB(255, 32,42,68);
      default:
        return Color.fromARGB(255, 1, 103, 107);
    }
  }

  _onTabItemListener(Device device) {
    if (device.state == SessionState.connected) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            final myController = TextEditingController();
            return AlertDialog(
              title: Text("Send message"),
              content: TextField(controller: myController),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text("Send"),
                  onPressed: () {
                    addItems(myController.text);
                    items = _prefs.then((SharedPreferences prefs) {
                    nearbyService.sendMessage(
                    device.deviceId, myController.text);
                    myController.text = '';
                    return prefs.getStringList('items') ?? [""];
                      });
                    //  myController.text = '';
                  },
                )
              ],
            );
          });
    }
  }

  int getItemCount() {
    if (widget.deviceType == DeviceType.advertiser) {
      return connectedDevices.length;
    } else {
      return devices.length;
    }
  }

  _onButtonClicked(Device device) {
    switch (device.state) {
      case SessionState.notConnected:
        nearbyService.invitePeer(
          deviceID: device.deviceId,
          deviceName: device.deviceName,
        );
        break;
      case SessionState.connected:
        nearbyService.disconnectPeer(deviceID: device.deviceId);
        break;
      case SessionState.connecting:
        break;
    }
  }

  void init() async {
    nearbyService = NearbyService();
    String? devInfo = '';
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      devInfo = androidInfo.model;
    }
    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      devInfo = iosInfo.localizedModel;
    }
    await nearbyService.init(
        serviceType: 'mpconn',
        deviceName: devInfo,
        strategy: Strategy.P2P_CLUSTER,
        callback: (isRunning) async {
          if (isRunning) {
            print(widget.deviceType);
            if (widget.deviceType == DeviceType.browser) {
              print("HERE1");
              await nearbyService.stopBrowsingForPeers();
              await Future.delayed(Duration(microseconds: 200));
              await nearbyService.startBrowsingForPeers();
            } else {
              print("HERE2");
              await nearbyService.stopAdvertisingPeer();
              await nearbyService.stopBrowsingForPeers();
              await Future.delayed(Duration(microseconds: 200));
              await nearbyService.startAdvertisingPeer();
              await nearbyService.startBrowsingForPeers();
            }
          }
        });
    subscription =
        nearbyService.stateChangedSubscription(callback: (devicesList) {
      devicesList.forEach((element) {
        print(
            " deviceId: ${element.deviceId} | deviceName: ${element.deviceName} | state: ${element.state}");

        if (Platform.isAndroid) {
          if (element.state == SessionState.connected) {
            nearbyService.stopBrowsingForPeers();
          } else {
            nearbyService.startBrowsingForPeers();
          }
        }
      });

      setState(() {
        devices.clear();
        devices.addAll(devicesList);
        connectedDevices.clear();
        connectedDevices.addAll(devicesList
            .where((d) => d.state == SessionState.connected)
            .toList());
      });
    });

    receivedDataSubscription =
        nearbyService.dataReceivedSubscription(callback: (data) {
      print("dataReceivedSubscription: ${jsonEncode(data)}");
      addItems(jsonEncode(data));
      showToast(jsonEncode(data),
          context: context,
          axis: Axis.horizontal,
          alignment: Alignment.center,
          position: StyledToastPosition.bottom);
    });
  }
}






class _FuncListScreenState extends State<FuncListScreen> {
  List<Device> devices = [];
  List<Device> connectedDevices = [];
  late NearbyService nearbyService;
  late StreamSubscription subscription;
  late StreamSubscription receivedDataSubscription;

  bool isInit = false;

  @override
  void initState() {
    super.initState();
    // init();
  }

  @override
  void dispose() {
    subscription.cancel();
    receivedDataSubscription.cancel();
    nearbyService.stopBrowsingForPeers();
    nearbyService.stopAdvertisingPeer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

  return Scaffold(
      appBar: AppBar(
          title: Text(""),
      ),
      body: Column(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, 'browser');
              },
              child: Container(
                color: Color.fromARGB(255, 1, 103, 107),
                child: Center(
                    child: Text(
                  'View SOS',
                  style: TextStyle(color: Colors.white, fontSize: 40),
                )),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, 'advertiser');
              },
              child: Container(
                color: Color.fromARGB(255, 32,42,68),
                child: Center(
                    child: Text(
                  'Send SOS Message',
                  style: TextStyle(color: Colors.white, fontSize: 40),
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class Announcements extends StatelessWidget{


@override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Sent and Received SOS!')),
        body: DividerExample(),
      ),
    );
  }
}

class DividerExample extends StatelessWidget {

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<List<String>> items = _prefs.then((SharedPreferences prefs) {
      return prefs.getStringList('_items') ?? [""];
    });
  

  @override
  Widget build(BuildContext context) {
print("BUILDING LIST");
    return FutureBuilder<List<String>>(
      future: items,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          print(snapshot.data);
          return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: snapshot.data?.length ?? 0,
                  itemBuilder: (BuildContext context, int index) {
                  return Text( snapshot.data?.elementAt(index) ?? "");
                  }
                );
        }
        else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }
        // By default, show a loading spinner.
        return const CircularProgressIndicator();
      }
    );
  }

}




