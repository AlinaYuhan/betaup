// BetaUp — Web Bluetooth Heart Rate Bridge
// Uses non-async requestDevice call to preserve browser user-gesture context.

window.bleHeartRate = {
  _device: null,
  _characteristic: null,

  isSupported: function() {
    return typeof navigator !== 'undefined' && !!navigator.bluetooth;
  },

  // Returns a Promise<boolean>.
  // requestDevice() is called synchronously (before any await) so the
  // browser's user-gesture activation is preserved through the Dart→JS call.
  connect: function(onBpm) {
    var self = this;
    console.log('[BetaUp BLE] connect() called, bluetooth:', !!navigator.bluetooth);

    // Call requestDevice synchronously — user gesture context intact here
    var devicePromise = navigator.bluetooth.requestDevice({
      acceptAllDevices: true,
      optionalServices: ['heart_rate'],
    });

    return devicePromise.then(function(device) {
      console.log('[BetaUp BLE] device selected:', device.name);
      self._device = device;
      return device.gatt.connect();
    }).then(function(server) {
      console.log('[BetaUp BLE] GATT connected');
      return server.getPrimaryService('heart_rate');
    }).then(function(service) {
      console.log('[BetaUp BLE] heart_rate service found');
      return service.getCharacteristic('heart_rate_measurement');
    }).then(function(characteristic) {
      console.log('[BetaUp BLE] characteristic found, subscribing...');
      self._characteristic = characteristic;
      characteristic.addEventListener('characteristicvaluechanged', function(event) {
        var data = event.target.value; // DataView
        var flags = data.getUint8(0);
        var isUint16 = (flags & 0x01) !== 0;
        var bpm = isUint16 ? data.getUint16(1, true) : data.getUint8(1);
        console.log('[BetaUp BLE] bpm:', bpm);
        if (bpm > 0 && onBpm) onBpm(bpm);
      });
      return characteristic.startNotifications();
    }).then(function() {
      console.log('[BetaUp BLE] notifications started ✓');
      return true;
    }).catch(function(err) {
      console.warn('[BetaUp BLE] error:', err.name, err.message);
      self.disconnect();
      return false;
    });
  },

  disconnect: function() {
    try {
      if (this._device && this._device.gatt.connected) {
        this._device.gatt.disconnect();
        console.log('[BetaUp BLE] disconnected');
      }
    } catch(e) {}
    this._device = null;
    this._characteristic = null;
  },
};

console.log('[BetaUp BLE] bridge loaded, bluetooth supported:', !!navigator.bluetooth);
