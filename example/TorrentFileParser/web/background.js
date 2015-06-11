
chrome.app.runtime.onLaunched.addListener(function(launchData) {
  chrome.app.window.create('torrentfileparser.html', {
    'id': '_mainWindow', 'bounds': {'width': 800, 'height': 600 }
  });
});
