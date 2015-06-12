library helper.portmap;

import 'dart:async' as async;
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimanet/hetimanet_chrome.dart';


/**
 * app parts
 */
class PortMapHelper {
  String appid = "";
  String localAddress = "0.0.0.0";
  String _externalAddress = "0.0.0.0";
  int basePort = 18085;
  int localPort = 18085;
  int _externalPort = 18085;
  int get externalPort => _externalPort;

  PortMapHelper(String appid) {
    this.appid = appid;
  }
  async.StreamController<String> _controllerUpdateGlobalPort = new async.StreamController.broadcast();
  async.Stream<String> get onUpdateGlobalPort => _controllerUpdateGlobalPort.stream;

  async.StreamController<String> _controllerUpdateGlobalIp = new async.StreamController.broadcast();
  async.Stream<String> get onUpdateGlobalIp => _controllerUpdateGlobalIp.stream;

  async.StreamController<String> _controllerUpdateLocalIp = new async.StreamController.broadcast();
  async.Stream<String> get onUpdateLocalIp => _controllerUpdateLocalIp.stream;

  void startPortMap() {
    _externalPort = basePort;
    UpnpDeviceSearcher.createInstance(new HetiSocketBuilderChrome()).then((UpnpDeviceSearcher searcher) {
      searcher.searchWanPPPDevice().then((int e) {
        if (searcher.deviceInfoList.length <= 0) {
          return;
        }
        UpnpDeviceInfo info = searcher.deviceInfoList.first;
        UpnpPPPDevice pppDevice = new UpnpPPPDevice(info);
        pppDevice.requestGetExternalIPAddress().then((UpnpGetExternalIPAddressResponse res) {
          _controllerUpdateGlobalIp.add(res.externalIp);
        });
        int baseExternalPort = _externalPort + 50;
        tryAddPortMap() {
          pppDevice
              .requestAddPortMapping(_externalPort, UpnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_TCP, localPort, localAddress, UpnpPPPDevice.VALUE_ENABLE, "hetim(${appid})", 0)
              .then((UpnpAddPortMappingResponse res) {
            if (200 == res.resultCode) {
              _controllerUpdateGlobalPort.add("${_externalPort}");
              searcher.close();
              return;
            }
            if (500 == res.resultCode) {
              _externalPort++;
              if (_externalPort < baseExternalPort) {
                tryAddPortMap();
              }
            }
          }).catchError((e) {
            searcher.close();
          });
        }
        tryAddPortMap();
      }).catchError((e) {
        searcher.close();
      });
    });
  }

  void deleteAllPortMap() {
    UpnpDeviceSearcher.createInstance(new HetiSocketBuilderChrome()).then((UpnpDeviceSearcher searcher) {
      searcher.searchWanPPPDevice().then((int e) {
        if (searcher.deviceInfoList.length <= 0) {
          return;
        }
        int index = 0;
        List<int> deletePortList = [];
        deletePortMap(UpnpPPPDevice pppDevice) {
          for (int port in deletePortList) {
            pppDevice.requestDeletePortMapping(port, UpnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_TCP);
          }
          new async.Future.delayed(new Duration(seconds: 5), () {
            searcher.close();
          });
        }
        tryGetPortMapInfo() {
          UpnpDeviceInfo info = searcher.deviceInfoList.first;
          UpnpPPPDevice pppDevice = new UpnpPPPDevice(info);
          pppDevice.requestGetGenericPortMapping(index++).then((UpnpGetGenericPortMappingResponse res) {
            if (res.resultCode != 200) {
              deletePortMap(pppDevice);
              return;
            }
            String description = res.getValue(UpnpGetGenericPortMappingResponse.KEY_NewPortMappingDescription, "");
            String port = res.getValue(UpnpGetGenericPortMappingResponse.KEY_NewExternalPort, "");
            String ip = res.getValue(UpnpGetGenericPortMappingResponse.KEY_NewInternalClient, "");
            if (description == "hetim(${appid})") {
              int portAsNum = int.parse(port);
              deletePortList.add(portAsNum);
            }
            if (port.replaceAll(" |\t|\r|\n", "") == "" && ip.replaceAll(" |\t|\r|\n", "") == "") {
              deletePortMap(pppDevice);
              return;
            }
            tryGetPortMapInfo();
          }).catchError((e) {
            searcher.close();
          });
        }
        tryGetPortMapInfo();
      });
    });
  }

  async.Future<int> startGetLocalIp() {
    async.Completer<int> completer = new async.Completer();
    (new HetiSocketBuilderChrome()).getNetworkInterfaces().then((List<HetiNetworkInterface> l) {
      // search 24
      for (HetiNetworkInterface i in l) {
        if (i.prefixLength == 24 && !i.address.startsWith("127")) {
          _controllerUpdateLocalIp.add(i.address);
          localAddress = i.address;
          completer.complete(0);
          return;
        }
      }
      //
      for (HetiNetworkInterface i in l) {
        if (i.prefixLength == 64) {
          _controllerUpdateLocalIp.add(i.address);
          localAddress = i.address;
          completer.complete(0);
          return;
        }
      }
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }
}
