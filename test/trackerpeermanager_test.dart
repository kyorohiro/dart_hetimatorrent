import 'package:unittest/unittest.dart' as unit;
import 'dart:async' as async;
import 'dart:typed_data' as type;
import 'package:hetimatorrent/hetimatorrent.dart';
import 'package:hetimacore/hetimacore.dart';

void main() {
  print("---");
  unit.test("compact=0 001", () {
    List<int> infoHash = PeerIdCreator.createPeerid("heti");
    List<int> peerId = PeerIdCreator.createPeerid("heti");

    TrackerPeerManager manager = new TrackerPeerManager(infoHash);
    Map<String, String> parameter = {
      TrackerUrl.KEY_PORT: "8080",
      TrackerUrl.KEY_EVENT: "",
      TrackerUrl.KEY_INFO_HASH: ""+PercentEncode.encode(infoHash),
      TrackerUrl.KEY_PEER_ID: ""+PercentEncode.encode(peerId),
      TrackerUrl.KEY_DOWNLOADED: "0",
      TrackerUrl.KEY_UPLOADED: "0",
      TrackerUrl.KEY_LEFT: "1024",
    };

    {
      TrackerResponse re = manager.createResponse();
      Map<String, Object> responseAsMap = re.createResponse(false);
      unit.expect(responseAsMap[TrackerResponse.KEY_INTERVAL], 60);
      List<Map<String, Object>> peers = responseAsMap[TrackerResponse.KEY_PEERS];
      unit.expect(peers.length, 0);
    }
    {
      TrackerRequest request = new TrackerRequest.fromMap(parameter, "1.2.3.4", [1, 2, 3, 4]);
      manager.update(request);
      TrackerResponse re = manager.createResponse();
      Map<String, Object> responseAsMap = re.createResponse(false);
      unit.expect(responseAsMap[TrackerResponse.KEY_INTERVAL], 60);
      List<Map<String, Object>> peers = responseAsMap[TrackerResponse.KEY_PEERS];
      unit.expect(peers[0][TrackerResponse.KEY_PEER_ID], new type.Uint8List.fromList(peerId));
      unit.expect(peers[0][TrackerResponse.KEY_IP], "1.2.3.4");
      unit.expect(peers[0][TrackerResponse.KEY_PORT], 8080);
    }
    {
      TrackerRequest request = new TrackerRequest.fromMap(parameter, "1.2.3.4", [1, 2, 3, 4]);
      manager.update(request);
      TrackerResponse re = manager.createResponse();
      Map<String, Object> responseAsMap = re.createResponse(false);
      
      //
      //
      re = new TrackerResponse();
      re.initFromMap(responseAsMap);
      unit.expect(responseAsMap[TrackerResponse.KEY_INTERVAL], 60);
      List<Map<String, Object>> peers = responseAsMap[TrackerResponse.KEY_PEERS];
      unit.expect(peers[0][TrackerResponse.KEY_PEER_ID], new type.Uint8List.fromList(peerId));
      unit.expect(peers[0][TrackerResponse.KEY_IP], "1.2.3.4");
      unit.expect(peers[0][TrackerResponse.KEY_PORT], 8080);
    }
  });

  unit.test("compact=1 001", () {
    List<int> infoHash = PeerIdCreator.createPeerid("heti");
    List<int> peerId = PeerIdCreator.createPeerid("heti");

    TrackerPeerManager manager = new TrackerPeerManager(infoHash);
    Map<String, String> parameter = {
      TrackerUrl.KEY_PORT: "8080",
      TrackerUrl.KEY_EVENT: "",
      TrackerUrl.KEY_INFO_HASH: ""+PercentEncode.encode(infoHash),
      TrackerUrl.KEY_PEER_ID: ""+PercentEncode.encode(peerId),
      TrackerUrl.KEY_DOWNLOADED: "0",
      TrackerUrl.KEY_UPLOADED: "0",
      TrackerUrl.KEY_LEFT: "1024",
      TrackerUrl.KEY_COMPACT: "1",
    };

    {
      TrackerResponse re = manager.createResponse();
      Map<String, Object> responseAsMap = re.createResponse(false);
      unit.expect(responseAsMap[TrackerResponse.KEY_INTERVAL], 60);
      List<Map<String, Object>> peers = responseAsMap[TrackerResponse.KEY_PEERS];
      unit.expect(peers.length, 0);
    }
    {
      TrackerRequest request = new TrackerRequest.fromMap(parameter, "1.2.3.4", [1, 2, 3, 4]);
      manager.update(request);
      TrackerResponse re = manager.createResponse();
      Map<String, Object> responseAsMap = re.createResponse(true);
      unit.expect(responseAsMap[TrackerResponse.KEY_INTERVAL], 60);
      type.Uint8List peers = responseAsMap[TrackerResponse.KEY_PEERS];
      unit.expect(peers[0], 1);
      unit.expect(peers[1], 2);
      unit.expect(peers[2], 3);
      unit.expect(peers[3], 4);
      unit.expect(peers[4], 0x1F);
      unit.expect(peers[5], 0x90);
    }
  });
  unit.test("compact=0 002", () {
    List<int> infoHash = PeerIdCreator.createPeerid("heti");
    List<int> peerId01 = PeerIdCreator.createPeerid("heti");
    List<int> peerId02 = PeerIdCreator.createPeerid("heti");

    TrackerPeerManager manager = new TrackerPeerManager(infoHash);
    Map<String, String> parameter001 = {
      TrackerUrl.KEY_PORT: "8080",
      TrackerUrl.KEY_EVENT: ""+TrackerUrl.VALUE_EVENT_STARTED,
      TrackerUrl.KEY_INFO_HASH: ""+PercentEncode.encode(infoHash),
      TrackerUrl.KEY_PEER_ID: ""+PercentEncode.encode(peerId01),
      TrackerUrl.KEY_DOWNLOADED: "0",
      TrackerUrl.KEY_UPLOADED: "0",
      TrackerUrl.KEY_LEFT: "1024",
    };
    Map<String, String> parameter002 = {
      TrackerUrl.KEY_PORT: "8081",
      TrackerUrl.KEY_EVENT: ""+TrackerUrl.VALUE_EVENT_STARTED,
      TrackerUrl.KEY_INFO_HASH: ""+PercentEncode.encode(infoHash),
      TrackerUrl.KEY_PEER_ID: ""+PercentEncode.encode(peerId02),
      TrackerUrl.KEY_DOWNLOADED: "0",
      TrackerUrl.KEY_UPLOADED: "0",
      TrackerUrl.KEY_LEFT: "1024",
    };

    {
      TrackerRequest request1 = new TrackerRequest.fromMap(parameter001, "1.2.3.4", [1, 2, 3, 4]);
      manager.update(request1);
      TrackerRequest request2 = new TrackerRequest.fromMap(parameter002, "2.3.4.5", [2, 3, 4, 5]);
      manager.update(request2);

      TrackerResponse re = manager.createResponse();
      Map<String, Object> responseAsMap = re.createResponse(false);
      unit.expect(responseAsMap[TrackerResponse.KEY_INTERVAL], 60);
      List<Map<String, Object>> peers = responseAsMap[TrackerResponse.KEY_PEERS];

      if(peers[0][TrackerResponse.KEY_IP] == "1.2.3.4") {
        unit.expect(peers[0][TrackerResponse.KEY_PEER_ID], new type.Uint8List.fromList(peerId01));
        unit.expect(peers[0][TrackerResponse.KEY_IP], "1.2.3.4");
        unit.expect(peers[0][TrackerResponse.KEY_PORT], 8080);
        unit.expect(peers[1][TrackerResponse.KEY_PEER_ID], new type.Uint8List.fromList(peerId02));
        unit.expect(peers[1][TrackerResponse.KEY_IP], "2.3.4.5");
        unit.expect(peers[1][TrackerResponse.KEY_PORT], 8081);
      } else {
        
        unit.expect(peers[1][TrackerResponse.KEY_PEER_ID], new type.Uint8List.fromList(peerId01));
        unit.expect(peers[1][TrackerResponse.KEY_IP], "1.2.3.4");
        unit.expect(peers[1][TrackerResponse.KEY_PORT], 8080);
        unit.expect(peers[0][TrackerResponse.KEY_PEER_ID], new type.Uint8List.fromList(peerId02));
        unit.expect(peers[0][TrackerResponse.KEY_IP], "2.3.4.5");
        unit.expect(peers[0][TrackerResponse.KEY_PORT], 8081);
      }
      
    }
  });

}
