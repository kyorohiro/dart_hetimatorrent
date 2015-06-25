
chrome.app.runtime.onLaunched.addListener(function(launchData) {
  chrome.app.window.create('01_torrentclient_test.html', {
    'id': '_mainWindow', 'bounds': {'width': 300, 'height': 300 }
  });
});
