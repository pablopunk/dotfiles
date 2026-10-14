import type { NevermindExtension } from './nevermind-extension-api'

// The host camera view does not expose a mirror option, so use a sandboxed
// camera webview and mirror only the preview (not the underlying stream).
const cameraHtml = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  html, body { margin: 0; width: 100%; height: 100%; background: #111; overflow: hidden; }
  body { display: grid; place-items: center; color: #ddd; font: 14px system-ui, sans-serif; outline: none; }
  video { width: 100%; height: 100%; object-fit: contain; transform: scaleX(-1); }
  #status { position: absolute; padding: 16px; text-align: center; background: #111; }
  #status:empty { display: none; }
</style>
</head>
<body tabindex="0">
  <video id="feed" autoplay playsinline muted></video>
  <div id="status" role="status" aria-live="polite">Starting camera…</div>
<script>
(() => {
  const feed = document.getElementById('feed');
  const status = document.getElementById('status');
  let stream = null;
  let deviceId = null;
  let changing = false;
  const stop = () => {
    if (stream) stream.getTracks().forEach(track => track.stop());
    stream = null;
    feed.srcObject = null;
  };
  async function start(nextId) {
    if (changing) return;
    changing = true;
    status.textContent = 'Starting camera…';
    stop();
    try {
      stream = await navigator.mediaDevices.getUserMedia({
        audio: false,
        video: nextId ? { deviceId: { exact: nextId } } : true
      });
      deviceId = stream.getVideoTracks()[0]?.getSettings().deviceId || nextId || null;
      feed.srcObject = stream;
      await feed.play();
      status.textContent = '';
    } catch (error) {
      status.textContent = 'Camera unavailable. Check Nevermind camera permission and that no other app is using the camera.';
    } finally {
      changing = false;
    }
  }
  async function switchCamera() {
    if (changing) return;
    try {
      const devices = (await navigator.mediaDevices.enumerateDevices()).filter(d => d.kind === 'videoinput');
      if (devices.length < 2) return;
      const current = devices.findIndex(d => d.deviceId === deviceId);
      await start(devices[(current + 1) % devices.length].deviceId);
    } catch (error) {
      status.textContent = 'Could not list cameras. Check camera permission.';
    }
  }
  window.addEventListener('keydown', event => {
    if (event.key === 'Enter' && !event.repeat) {
      event.preventDefault();
      switchCamera();
    }
  });
  window.addEventListener('pagehide', stop);
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) stop();
    else if (!stream) start(deviceId);
  });
  document.body.focus();
  start(null);
})();
</script>
</body>
</html>`

export default {
  id: 'camera.view',
  title: 'Camera',
  capabilities: ['camera'],
  commands: [{
    id: 'open-camera',
    actionId: 'camera:open',
    title: 'Open Camera',
    subtitle: 'Mirrored webcam feed; press Enter to switch cameras',
    icon: 'camera',
    run(ctx) {
      return ctx.ui.webview({
        title: 'Webcam Feed',
        size: 'large',
        html: cameraHtml,
        webviewPermissions: ['autoplay', 'camera'],
      })
    },
  }],
} satisfies NevermindExtension