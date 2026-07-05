// Protocole série Xiaomi/Ninebot (familles texte clair : M365/1S/Pro/ES).
// Trame : 5A A5 <len> <dst> <src> <cmd> <payload...> <checksum LE 16 bits>
// len couvre dst..payload ; checksum = complément à un de la somme de len..payload.

export const HEADER = [0x5a, 0xa5];

export const ADDR = { app: 0x3d, esc: 0x20, bms: 0x22, ble: 0x21 };
export const CMD = { read: 0x01, write: 0x03 };

export const REG = {
  serialNumber: 0x10,   // 14 octets ASCII
  firmware: 0x1a,       // 2 octets
  batteryPercent: 0x32, // 2 octets
  batteryVoltage: 0x34, // 2 octets /100 V
  speed: 0xb5,          // 2 octets signés /1000 km/h
  totalMileage: 0x29,   // 4 octets /1000 km
  controllerTemp: 0x3e, // 2 octets /10 °C
  region: 0x72,         // 1 octet
  speedLimit: 0x74,     // 2 octets km/h
  cruise: 0x7c,         // 1 octet
  tailLight: 0x7d,      // 1 octet
};

export const REGIONS = [
  { value: 0x00, name: "Global / Déverrouillé", flag: "🌍", note: "Vitesse max selon le matériel." },
  { value: 0x01, name: "États-Unis", flag: "🇺🇸", note: "Plafond typique 32 km/h." },
  { value: 0x02, name: "Europe (25 km/h)", flag: "🇪🇺", note: "Plafond légal 25 km/h." },
  { value: 0x03, name: "Chine (25 km/h)", flag: "🇨🇳", note: "Plafond légal 25 km/h." },
];

function checksum16(bytes) {
  let sum = 0;
  for (const b of bytes) sum = (sum + b) & 0xffffffff;
  return (~sum) & 0xffff;
}

export function buildFrame(dst, src, cmd, payload) {
  const body = [dst, src, cmd, ...payload];
  const len = body.length & 0xff;
  const checksummed = [len, ...body];
  const ck = checksum16(checksummed);
  return Uint8Array.from([...HEADER, ...checksummed, ck & 0xff, (ck >> 8) & 0xff]);
}

export function readRequest(register, length, dst = ADDR.esc) {
  return buildFrame(dst, ADDR.app, CMD.read, [register, length]);
}

export function writeRequest(register, bytes, dst = ADDR.esc) {
  return buildFrame(dst, ADDR.app, CMD.write, [register, ...bytes]);
}

// Parse une trame complète en tête de buffer. Renvoie {frame, consumed} ou null.
export function parse(buf) {
  if (buf.length < 8) return null;
  if (buf[0] !== HEADER[0] || buf[1] !== HEADER[1]) return null;
  const len = buf[2];
  const total = 2 + 1 + len + 2;
  if (buf.length < total) return null;
  const checksummed = buf.slice(2, 3 + len);
  const expected = checksum16(checksummed);
  const actual = buf[3 + len] | (buf[3 + len + 1] << 8);
  if (expected !== actual) return null;
  const frame = {
    dst: buf[3],
    src: buf[4],
    cmd: buf[5],
    register: buf[6],
    payload: buf.slice(7, 3 + len),
  };
  return { frame, consumed: total };
}

export const le16 = (p) => (p.length >= 2 ? p[0] | (p[1] << 8) : null);
export const le16s = (p) => {
  const v = le16(p);
  return v == null ? null : (v > 0x7fff ? v - 0x10000 : v);
};
export const le32 = (p) =>
  p.length >= 4 ? (p[0] | (p[1] << 8) | (p[2] << 16) | (p[3] << 24)) >>> 0 : null;
