import {
  REG, REGIONS, readRequest, writeRequest, parse, le16, le16s, le32,
} from "./protocol.js";

// Service Nordic UART utilisé par le pont BLE des M365/Ninebot.
const UART_SERVICE = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
const UART_RX = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"; // écriture
const UART_TX = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"; // notification

const state = {};
let device = null;
let rxChar = null;
let txChar = null;
let rxBuffer = [];
let pollTimer = null;

const $ = (id) => document.getElementById(id);
const log = (msg) => {
  const el = $("log");
  const t = new Date().toLocaleTimeString();
  el.textContent = `[${t}] ${msg}\n` + el.textContent;
};

function supportsBluetooth() {
  return typeof navigator !== "undefined" && !!navigator.bluetooth;
}

async function connect() {
  if (!supportsBluetooth()) {
    showNoBluetooth();
    return;
  }
  try {
    log("Sélection de l'appareil…");
    device = await navigator.bluetooth.requestDevice({
      acceptAllDevices: true,
      optionalServices: [UART_SERVICE],
    });
    device.addEventListener("gattserverdisconnected", onDisconnected);
    log(`Connexion à ${device.name || "appareil"}…`);
    const server = await device.gatt.connect();
    const service = await server.getPrimaryService(UART_SERVICE);
    rxChar = await service.getCharacteristic(UART_RX);
    txChar = await service.getCharacteristic(UART_TX);
    await txChar.startNotifications();
    txChar.addEventListener("characteristicvaluechanged", onNotify);
    log("Connecté. Lecture des infos…");
    showConnected();
    initialReads();
    pollTimer = setInterval(refreshTelemetry, 1000);
  } catch (e) {
    log("Erreur : " + e.message);
  }
}

function onDisconnected() {
  clearInterval(pollTimer);
  rxChar = txChar = null;
  log("Déconnecté.");
  showDisconnected();
}

function disconnect() {
  clearInterval(pollTimer);
  if (device && device.gatt.connected) device.gatt.disconnect();
}

async function send(frame) {
  if (!rxChar) return;
  try {
    await rxChar.writeValueWithoutResponse(frame);
  } catch {
    try { await rxChar.writeValue(frame); } catch (e) { log("Écriture échouée: " + e.message); }
  }
}

const read = (reg, len) => send(readRequest(reg, len));
const write = (reg, bytes) => send(writeRequest(reg, bytes));

function initialReads() {
  read(REG.serialNumber, 14);
  read(REG.firmware, 2);
  read(REG.region, 1);
  read(REG.speedLimit, 2);
  refreshTelemetry();
}

function refreshTelemetry() {
  read(REG.batteryPercent, 2);
  read(REG.batteryVoltage, 2);
  read(REG.speed, 2);
  read(REG.totalMileage, 4);
  read(REG.controllerTemp, 2);
}

function onNotify(event) {
  const v = event.target.value;
  for (let i = 0; i < v.byteLength; i++) rxBuffer.push(v.getUint8(i));
  let res;
  while ((res = parse(rxBuffer))) {
    apply(res.frame);
    rxBuffer = rxBuffer.slice(res.consumed);
  }
  if (rxBuffer.length > 512) rxBuffer = [];
}

function apply(frame) {
  const p = frame.payload;
  switch (frame.register) {
    case REG.serialNumber:
      state.serial = new TextDecoder().decode(Uint8Array.from(p)).replace(/[^\x20-\x7e]/g, "").trim();
      break;
    case REG.firmware: {
      const v = le16(p);
      if (v != null) state.firmware = `${(v >> 8) & 0xf}.${(v >> 4) & 0xf}.${v & 0xf}`;
      break;
    }
    case REG.batteryPercent: { const v = le16(p); if (v != null) state.battery = v; break; }
    case REG.batteryVoltage: { const v = le16(p); if (v != null) state.voltage = v / 100; break; }
    case REG.speed: { const v = le16s(p); if (v != null) state.speed = Math.abs(v / 1000); break; }
    case REG.totalMileage: { const v = le32(p); if (v != null) state.total = v / 1000; break; }
    case REG.controllerTemp: { const v = le16s(p); if (v != null) state.temp = Math.round(v / 10); break; }
    case REG.region: { if (p.length) state.region = p[0]; break; }
    case REG.speedLimit: { const v = le16(p); if (v != null) state.speedLimit = v; break; }
  }
  render();
}

function setRegion(value) {
  const r = REGIONS.find((x) => x.value === value);
  log(`Écriture région → ${r ? r.name : value}`);
  write(REG.region, [value]);
  read(REG.region, 1);
}

function setSpeedLimit(kmh) {
  const v = Math.max(1, Math.min(kmh, 100));
  log(`Écriture vitesse max → ${v} km/h`);
  write(REG.speedLimit, [v & 0xff, (v >> 8) & 0xff]);
  read(REG.speedLimit, 2);
}

// --- UI ---

function render() {
  $("speed").textContent = state.speed != null ? state.speed.toFixed(1) : "--";
  $("battery").textContent = state.battery != null ? state.battery + " %" : "--";
  $("voltage").textContent = state.voltage != null ? state.voltage.toFixed(1) + " V" : "--";
  $("total").textContent = state.total != null ? state.total.toFixed(1) + " km" : "--";
  $("temp").textContent = state.temp != null ? state.temp + " °C" : "--";
  $("serial").textContent = state.serial || "—";
  $("firmware").textContent = state.firmware || "—";
  const r = REGIONS.find((x) => x.value === state.region);
  $("region").textContent = r ? `${r.flag} ${r.name}` : "—";
  if (state.speedLimit != null) $("limitCurrent").textContent = `Actuel : ${state.speedLimit} km/h`;
  document.querySelectorAll(".region-btn").forEach((b) => {
    b.classList.toggle("active", Number(b.dataset.value) === state.region);
  });
}

function showConnected() {
  $("scan-screen").hidden = true;
  $("app-screen").hidden = false;
}
function showDisconnected() {
  $("app-screen").hidden = true;
  $("scan-screen").hidden = false;
}
function showNoBluetooth() {
  $("nobt").hidden = false;
  $("connect-btn").hidden = true;
}

function buildRegionButtons() {
  const wrap = $("regions");
  REGIONS.forEach((r) => {
    const btn = document.createElement("button");
    btn.className = "region-btn";
    btn.dataset.value = r.value;
    btn.innerHTML = `<span class="flag">${r.flag}</span><span><strong>${r.name}</strong><br><small>${r.note}</small></span>`;
    btn.onclick = () => {
      if (confirm(`Changer la région vers « ${r.name} » ?\n${r.note}`)) setRegion(r.value);
    };
    wrap.appendChild(btn);
  });
}

function init() {
  buildRegionButtons();
  $("connect-btn").onclick = connect;
  $("disconnect-btn").onclick = disconnect;
  const slider = $("limit-slider");
  const label = $("limit-label");
  slider.oninput = () => { label.textContent = slider.value + " km/h"; };
  $("apply-limit").onclick = () => {
    if (!$("ack").checked) { alert("Coche d'abord la case de responsabilité."); return; }
    setSpeedLimit(Number(slider.value));
  };
  $("cruise").onchange = (e) => { if ($("ack").checked) write(REG.cruise, [e.target.checked ? 1 : 0]); };
  $("tail").onchange = (e) => { if ($("ack").checked) write(REG.tailLight, [e.target.checked ? 1 : 0]); };
  if (!supportsBluetooth()) showNoBluetooth();
}

document.addEventListener("DOMContentLoaded", init);
