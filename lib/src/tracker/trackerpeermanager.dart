part of hetima;

class TrackerPeerManager {
  List<int> _managdInfoHash = new List();
  List<int> get managedInfoHash => _managdInfoHash;
  int interval = 60;
  int max = 200;

  TrackerPeerManager(List<int> infoHash) {
    _managdInfoHash = infoHash.toList();
  }

  bool isManagedInfoHash(List<int> infoHash) {
    if (infoHash == null) {
      return false;
    }
    if (_managdInfoHash.length != infoHash.length) {
      return false;
    }
    for (int i = 0; i < _managdInfoHash.length; i++) {
      if (infoHash[i] != _managdInfoHash[i]) {
        return false;
      }
    }
    return true;
  }

  ShuffleLinkedList<PeerAddress> managedPeerAddress = new ShuffleLinkedList();
  void update(TrackerRequest request) {
    if (!isManagedInfoHash(request.infoHash)) {
      return;
    }
    managedPeerAddress.addLast(new PeerAddress(request.peerId, request.address, request.ip, request.port));
    if (managedPeerAddress.length > max) {
      managedPeerAddress.removeHead();
    }
  }

  TrackerResponse createResponse() {
    TrackerResponse response = new TrackerResponse();
    response.interval = this.interval;
    managedPeerAddress.shuffle();
    for (int i = 0; i < 50 && i < managedPeerAddress.length; i++) {
      response.peers.add(managedPeerAddress.getShuffled(i));
    }
    return response;
  }
}
