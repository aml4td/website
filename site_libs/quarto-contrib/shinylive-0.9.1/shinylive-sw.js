// Shinylive 0.9.1
// Copyright 2024 Posit, PBC
var __require = /* @__PURE__ */ ((x2) => typeof require !== "undefined" ? require : typeof Proxy !== "undefined" ? new Proxy(x2, {
  get: (a2, b) => (typeof require !== "undefined" ? require : a2)[b]
}) : x2)(function(x2) {
  if (typeof require !== "undefined")
    return require.apply(this, arguments);
  throw Error('Dynamic require of "' + x2 + '" is not supported');
});

// src/assets/shinylive-inject-socket.txt
var shinylive_inject_socket_default = '// src/messageportwebsocket.ts\nvar MessagePortWebSocket = class extends EventTarget {\n  constructor(port) {\n    super();\n    this.readyState = 0;\n    this.addEventListener("open", (e) => {\n      if (this.onopen) {\n        this.onopen(e);\n      }\n    });\n    this.addEventListener("message", (e) => {\n      if (this.onmessage) {\n        this.onmessage(e);\n      }\n    });\n    this.addEventListener("error", (e) => {\n      if (this.onerror) {\n        this.onerror(e);\n      }\n    });\n    this.addEventListener("close", (e) => {\n      if (this.onclose) {\n        this.onclose(e);\n      }\n    });\n    this._port = port;\n    port.addEventListener("message", this._onMessage.bind(this));\n    port.start();\n  }\n  // Call on the server side of the connection, to tell the client that\n  // the connection has been established.\n  accept() {\n    if (this.readyState !== 0) {\n      return;\n    }\n    this.readyState = 1;\n    this._port.postMessage({ type: "open" });\n  }\n  send(data) {\n    if (this.readyState === 0) {\n      throw new DOMException(\n        "Can\'t send messages while WebSocket is in CONNECTING state",\n        "InvalidStateError"\n      );\n    }\n    if (this.readyState > 1) {\n      return;\n    }\n    this._port.postMessage({ type: "message", value: { data } });\n  }\n  close(code, reason) {\n    if (this.readyState > 1) {\n      return;\n    }\n    this.readyState = 2;\n    this._port.postMessage({ type: "close", value: { code, reason } });\n    this.readyState = 3;\n    this.dispatchEvent(new CloseEvent("close", { code, reason }));\n  }\n  _onMessage(e) {\n    const event = e.data;\n    switch (event.type) {\n      case "open":\n        if (this.readyState === 0) {\n          this.readyState = 1;\n          this.dispatchEvent(new Event("open"));\n          return;\n        }\n        break;\n      case "message":\n        if (this.readyState === 1) {\n          this.dispatchEvent(new MessageEvent("message", { ...event.value }));\n          return;\n        }\n        break;\n      case "close":\n        if (this.readyState < 3) {\n          this.readyState = 3;\n          this.dispatchEvent(new CloseEvent("close", { ...event.value }));\n          return;\n        }\n        break;\n    }\n    this._reportError(\n      `Unexpected event \'${event.type}\' while in readyState ${this.readyState}`,\n      1002\n    );\n  }\n  _reportError(message, code) {\n    this.dispatchEvent(new ErrorEvent("error", { message }));\n    if (typeof code === "number") {\n      this.close(code, message);\n    }\n  }\n};\n\n// src/shinylive-inject-socket.ts\nwindow.Shiny.createSocket = function() {\n  const channel = new MessageChannel();\n  window.parent.postMessage(\n    {\n      type: "openChannel",\n      // Infer app name from path: "/foo/app_abc123/"" => "app_abc123"\n      appName: window.location.pathname.replace(\n        new RegExp(".*/([^/]+)/$"),\n        "$1"\n      ),\n      path: "/websocket/"\n    },\n    "*",\n    [channel.port2]\n  );\n  return new MessagePortWebSocket(channel.port1);\n};\n';

// src/utils.ts
function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
function dirname(path) {
  if (path === "/" || path === "") {
    return "";
  }
  return path.replace(/[/]?[^/]+[/]?$/, "");
}
function uint8ArrayToString(buf) {
  let result = "";
  for (let i = 0; i < buf.length; i++) {
    result += String.fromCharCode(buf[i]);
  }
  return result;
}

// node_modules/webr/dist/webr.mjs
var sn = Object.create;
var Zr = Object.defineProperty;
var nn = Object.getOwnPropertyDescriptor;
var on = Object.getOwnPropertyNames;
var an = Object.getPrototypeOf;
var ln = Object.prototype.hasOwnProperty;
var B = ((s) => typeof __require < "u" ? __require : typeof Proxy < "u" ? new Proxy(s, { get: (e, t) => (typeof __require < "u" ? __require : e)[t] }) : s)(function(s) {
  if (typeof __require < "u")
    return __require.apply(this, arguments);
  throw new Error('Dynamic require of "' + s + '" is not supported');
});
var S = (s, e) => () => (e || s((e = { exports: {} }).exports, e), e.exports);
var cn = (s, e, t, r) => {
  if (e && typeof e == "object" || typeof e == "function")
    for (let n of on(e))
      !ln.call(s, n) && n !== t && Zr(s, n, { get: () => e[n], enumerable: !(r = nn(e, n)) || r.enumerable });
  return s;
};
var oe = (s, e, t) => (t = s != null ? sn(an(s)) : {}, cn(e || !s || !s.__esModule ? Zr(t, "default", { value: s, enumerable: true }) : t, s));
var fr = (s, e, t) => {
  if (!e.has(s))
    throw TypeError("Cannot " + t);
};
var a = (s, e, t) => (fr(s, e, "read from private field"), t ? t.call(s) : e.get(s));
var u = (s, e, t) => {
  if (e.has(s))
    throw TypeError("Cannot add the same private member more than once");
  e instanceof WeakSet ? e.add(s) : e.set(s, t);
};
var d = (s, e, t, r) => (fr(s, e, "write to private field"), r ? r.call(s, t) : e.set(s, t), t);
var E = (s, e, t) => (fr(s, e, "access private method"), t);
var He = S((C) => {
  "use strict";
  Object.defineProperty(C, "__esModule", { value: true });
  C.getUint64 = C.getInt64 = C.setInt64 = C.setUint64 = C.UINT32_MAX = void 0;
  C.UINT32_MAX = 4294967295;
  function fn(s, e, t) {
    let r = t / 4294967296, n = t;
    s.setUint32(e, r), s.setUint32(e + 4, n);
  }
  C.setUint64 = fn;
  function Rn(s, e, t) {
    let r = Math.floor(t / 4294967296), n = t;
    s.setUint32(e, r), s.setUint32(e + 4, n);
  }
  C.setInt64 = Rn;
  function mn(s, e) {
    let t = s.getInt32(e), r = s.getUint32(e + 4);
    return t * 4294967296 + r;
  }
  C.getInt64 = mn;
  function gn(s, e) {
    let t = s.getUint32(e), r = s.getUint32(e + 4);
    return t * 4294967296 + r;
  }
  C.getUint64 = gn;
});
var Ot = S((M) => {
  "use strict";
  var _r, Sr, kr;
  Object.defineProperty(M, "__esModule", { value: true });
  M.utf8DecodeTD = M.TEXT_DECODER_THRESHOLD = M.utf8DecodeJs = M.utf8EncodeTE = M.TEXT_ENCODER_THRESHOLD = M.utf8EncodeJs = M.utf8Count = void 0;
  var ps = He(), At = (typeof process > "u" || ((_r = process == null ? void 0 : process.env) === null || _r === void 0 ? void 0 : _r.TEXT_ENCODING) !== "never") && typeof TextEncoder < "u" && typeof TextDecoder < "u";
  function bn(s) {
    let e = s.length, t = 0, r = 0;
    for (; r < e; ) {
      let n = s.charCodeAt(r++);
      if (n & 4294967168)
        if (!(n & 4294965248))
          t += 2;
        else {
          if (n >= 55296 && n <= 56319 && r < e) {
            let o = s.charCodeAt(r);
            (o & 64512) === 56320 && (++r, n = ((n & 1023) << 10) + (o & 1023) + 65536);
          }
          n & 4294901760 ? t += 4 : t += 3;
        }
      else {
        t++;
        continue;
      }
    }
    return t;
  }
  M.utf8Count = bn;
  function wn(s, e, t) {
    let r = s.length, n = t, o = 0;
    for (; o < r; ) {
      let i = s.charCodeAt(o++);
      if (i & 4294967168)
        if (!(i & 4294965248))
          e[n++] = i >> 6 & 31 | 192;
        else {
          if (i >= 55296 && i <= 56319 && o < r) {
            let l = s.charCodeAt(o);
            (l & 64512) === 56320 && (++o, i = ((i & 1023) << 10) + (l & 1023) + 65536);
          }
          i & 4294901760 ? (e[n++] = i >> 18 & 7 | 240, e[n++] = i >> 12 & 63 | 128, e[n++] = i >> 6 & 63 | 128) : (e[n++] = i >> 12 & 15 | 224, e[n++] = i >> 6 & 63 | 128);
        }
      else {
        e[n++] = i;
        continue;
      }
      e[n++] = i & 63 | 128;
    }
  }
  M.utf8EncodeJs = wn;
  var ze = At ? new TextEncoder() : void 0;
  M.TEXT_ENCODER_THRESHOLD = At ? typeof process < "u" && ((Sr = process == null ? void 0 : process.env) === null || Sr === void 0 ? void 0 : Sr.TEXT_ENCODING) !== "force" ? 200 : 0 : ps.UINT32_MAX;
  function xn(s, e, t) {
    e.set(ze.encode(s), t);
  }
  function vn(s, e, t) {
    ze.encodeInto(s, e.subarray(t));
  }
  M.utf8EncodeTE = ze != null && ze.encodeInto ? vn : xn;
  var En = 4096;
  function Pn(s, e, t) {
    let r = e, n = r + t, o = [], i = "";
    for (; r < n; ) {
      let l = s[r++];
      if (!(l & 128))
        o.push(l);
      else if ((l & 224) === 192) {
        let p = s[r++] & 63;
        o.push((l & 31) << 6 | p);
      } else if ((l & 240) === 224) {
        let p = s[r++] & 63, D = s[r++] & 63;
        o.push((l & 31) << 12 | p << 6 | D);
      } else if ((l & 248) === 240) {
        let p = s[r++] & 63, D = s[r++] & 63, b = s[r++] & 63, j = (l & 7) << 18 | p << 12 | D << 6 | b;
        j > 65535 && (j -= 65536, o.push(j >>> 10 & 1023 | 55296), j = 56320 | j & 1023), o.push(j);
      } else
        o.push(l);
      o.length >= En && (i += String.fromCharCode(...o), o.length = 0);
    }
    return o.length > 0 && (i += String.fromCharCode(...o)), i;
  }
  M.utf8DecodeJs = Pn;
  var Tn = At ? new TextDecoder() : null;
  M.TEXT_DECODER_THRESHOLD = At ? typeof process < "u" && ((kr = process == null ? void 0 : process.env) === null || kr === void 0 ? void 0 : kr.TEXT_DECODER) !== "force" ? 200 : 0 : ps.UINT32_MAX;
  function _n(s, e, t) {
    let r = s.subarray(e, e + t);
    return Tn.decode(r);
  }
  M.utf8DecodeTD = _n;
});
var Dr = S((It) => {
  "use strict";
  Object.defineProperty(It, "__esModule", { value: true });
  It.ExtData = void 0;
  var Mr = class {
    constructor(e, t) {
      this.type = e, this.data = t;
    }
  };
  It.ExtData = Mr;
});
var Ct = S((Ut) => {
  "use strict";
  Object.defineProperty(Ut, "__esModule", { value: true });
  Ut.DecodeError = void 0;
  var we = class extends Error {
    constructor(e) {
      super(e);
      let t = Object.create(we.prototype);
      Object.setPrototypeOf(this, t), Object.defineProperty(this, "name", { configurable: true, enumerable: false, value: we.name });
    }
  };
  Ut.DecodeError = we;
});
var Wr = S((_) => {
  "use strict";
  Object.defineProperty(_, "__esModule", { value: true });
  _.timestampExtension = _.decodeTimestampExtension = _.decodeTimestampToTimeSpec = _.encodeTimestampExtension = _.encodeDateToTimeSpec = _.encodeTimeSpecToTimestamp = _.EXT_TIMESTAMP = void 0;
  var Sn = Ct(), ds = He();
  _.EXT_TIMESTAMP = -1;
  var kn = 4294967296 - 1, Mn = 17179869184 - 1;
  function hs({ sec: s, nsec: e }) {
    if (s >= 0 && e >= 0 && s <= Mn)
      if (e === 0 && s <= kn) {
        let t = new Uint8Array(4);
        return new DataView(t.buffer).setUint32(0, s), t;
      } else {
        let t = s / 4294967296, r = s & 4294967295, n = new Uint8Array(8), o = new DataView(n.buffer);
        return o.setUint32(0, e << 2 | t & 3), o.setUint32(4, r), n;
      }
    else {
      let t = new Uint8Array(12), r = new DataView(t.buffer);
      return r.setUint32(0, e), (0, ds.setInt64)(r, 4, s), t;
    }
  }
  _.encodeTimeSpecToTimestamp = hs;
  function ys(s) {
    let e = s.getTime(), t = Math.floor(e / 1e3), r = (e - t * 1e3) * 1e6, n = Math.floor(r / 1e9);
    return { sec: t + n, nsec: r - n * 1e9 };
  }
  _.encodeDateToTimeSpec = ys;
  function fs(s) {
    if (s instanceof Date) {
      let e = ys(s);
      return hs(e);
    } else
      return null;
  }
  _.encodeTimestampExtension = fs;
  function Rs(s) {
    let e = new DataView(s.buffer, s.byteOffset, s.byteLength);
    switch (s.byteLength) {
      case 4:
        return { sec: e.getUint32(0), nsec: 0 };
      case 8: {
        let t = e.getUint32(0), r = e.getUint32(4), n = (t & 3) * 4294967296 + r, o = t >>> 2;
        return { sec: n, nsec: o };
      }
      case 12: {
        let t = (0, ds.getInt64)(e, 4), r = e.getUint32(0);
        return { sec: t, nsec: r };
      }
      default:
        throw new Sn.DecodeError(`Unrecognized data size for timestamp (expected 4, 8, or 12): ${s.length}`);
    }
  }
  _.decodeTimestampToTimeSpec = Rs;
  function ms(s) {
    let e = Rs(s);
    return new Date(e.sec * 1e3 + e.nsec / 1e6);
  }
  _.decodeTimestampExtension = ms;
  _.timestampExtension = { type: _.EXT_TIMESTAMP, encode: fs, decode: ms };
});
var Bt = S((Nt) => {
  "use strict";
  Object.defineProperty(Nt, "__esModule", { value: true });
  Nt.ExtensionCodec = void 0;
  var jt = Dr(), Dn = Wr(), Xe = class {
    constructor() {
      this.builtInEncoders = [], this.builtInDecoders = [], this.encoders = [], this.decoders = [], this.register(Dn.timestampExtension);
    }
    register({ type: e, encode: t, decode: r }) {
      if (e >= 0)
        this.encoders[e] = t, this.decoders[e] = r;
      else {
        let n = 1 + e;
        this.builtInEncoders[n] = t, this.builtInDecoders[n] = r;
      }
    }
    tryToEncode(e, t) {
      for (let r = 0; r < this.builtInEncoders.length; r++) {
        let n = this.builtInEncoders[r];
        if (n != null) {
          let o = n(e, t);
          if (o != null) {
            let i = -1 - r;
            return new jt.ExtData(i, o);
          }
        }
      }
      for (let r = 0; r < this.encoders.length; r++) {
        let n = this.encoders[r];
        if (n != null) {
          let o = n(e, t);
          if (o != null) {
            let i = r;
            return new jt.ExtData(i, o);
          }
        }
      }
      return e instanceof jt.ExtData ? e : null;
    }
    decode(e, t, r) {
      let n = t < 0 ? this.builtInDecoders[-1 - t] : this.decoders[t];
      return n ? n(e, t, r) : new jt.ExtData(t, e);
    }
  };
  Nt.ExtensionCodec = Xe;
  Xe.defaultCodec = new Xe();
});
var Ar = S((xe) => {
  "use strict";
  Object.defineProperty(xe, "__esModule", { value: true });
  xe.createDataView = xe.ensureUint8Array = void 0;
  function gs(s) {
    return s instanceof Uint8Array ? s : ArrayBuffer.isView(s) ? new Uint8Array(s.buffer, s.byteOffset, s.byteLength) : s instanceof ArrayBuffer ? new Uint8Array(s) : Uint8Array.from(s);
  }
  xe.ensureUint8Array = gs;
  function Wn(s) {
    if (s instanceof ArrayBuffer)
      return new DataView(s);
    let e = gs(s);
    return new DataView(e.buffer, e.byteOffset, e.byteLength);
  }
  xe.createDataView = Wn;
});
var Ir = S((J) => {
  "use strict";
  Object.defineProperty(J, "__esModule", { value: true });
  J.Encoder = J.DEFAULT_INITIAL_BUFFER_SIZE = J.DEFAULT_MAX_DEPTH = void 0;
  var Ge = Ot(), An = Bt(), bs = He(), On = Ar();
  J.DEFAULT_MAX_DEPTH = 100;
  J.DEFAULT_INITIAL_BUFFER_SIZE = 2048;
  var Or = class {
    constructor(e = An.ExtensionCodec.defaultCodec, t = void 0, r = J.DEFAULT_MAX_DEPTH, n = J.DEFAULT_INITIAL_BUFFER_SIZE, o = false, i = false, l = false, p = false) {
      this.extensionCodec = e, this.context = t, this.maxDepth = r, this.initialBufferSize = n, this.sortKeys = o, this.forceFloat32 = i, this.ignoreUndefined = l, this.forceIntegerToFloat = p, this.pos = 0, this.view = new DataView(new ArrayBuffer(this.initialBufferSize)), this.bytes = new Uint8Array(this.view.buffer);
    }
    reinitializeState() {
      this.pos = 0;
    }
    encodeSharedRef(e) {
      return this.reinitializeState(), this.doEncode(e, 1), this.bytes.subarray(0, this.pos);
    }
    encode(e) {
      return this.reinitializeState(), this.doEncode(e, 1), this.bytes.slice(0, this.pos);
    }
    doEncode(e, t) {
      if (t > this.maxDepth)
        throw new Error(`Too deep objects in depth ${t}`);
      e == null ? this.encodeNil() : typeof e == "boolean" ? this.encodeBoolean(e) : typeof e == "number" ? this.encodeNumber(e) : typeof e == "string" ? this.encodeString(e) : this.encodeObject(e, t);
    }
    ensureBufferSizeToWrite(e) {
      let t = this.pos + e;
      this.view.byteLength < t && this.resizeBuffer(t * 2);
    }
    resizeBuffer(e) {
      let t = new ArrayBuffer(e), r = new Uint8Array(t), n = new DataView(t);
      r.set(this.bytes), this.view = n, this.bytes = r;
    }
    encodeNil() {
      this.writeU8(192);
    }
    encodeBoolean(e) {
      e === false ? this.writeU8(194) : this.writeU8(195);
    }
    encodeNumber(e) {
      Number.isSafeInteger(e) && !this.forceIntegerToFloat ? e >= 0 ? e < 128 ? this.writeU8(e) : e < 256 ? (this.writeU8(204), this.writeU8(e)) : e < 65536 ? (this.writeU8(205), this.writeU16(e)) : e < 4294967296 ? (this.writeU8(206), this.writeU32(e)) : (this.writeU8(207), this.writeU64(e)) : e >= -32 ? this.writeU8(224 | e + 32) : e >= -128 ? (this.writeU8(208), this.writeI8(e)) : e >= -32768 ? (this.writeU8(209), this.writeI16(e)) : e >= -2147483648 ? (this.writeU8(210), this.writeI32(e)) : (this.writeU8(211), this.writeI64(e)) : this.forceFloat32 ? (this.writeU8(202), this.writeF32(e)) : (this.writeU8(203), this.writeF64(e));
    }
    writeStringHeader(e) {
      if (e < 32)
        this.writeU8(160 + e);
      else if (e < 256)
        this.writeU8(217), this.writeU8(e);
      else if (e < 65536)
        this.writeU8(218), this.writeU16(e);
      else if (e < 4294967296)
        this.writeU8(219), this.writeU32(e);
      else
        throw new Error(`Too long string: ${e} bytes in UTF-8`);
    }
    encodeString(e) {
      if (e.length > Ge.TEXT_ENCODER_THRESHOLD) {
        let n = (0, Ge.utf8Count)(e);
        this.ensureBufferSizeToWrite(5 + n), this.writeStringHeader(n), (0, Ge.utf8EncodeTE)(e, this.bytes, this.pos), this.pos += n;
      } else {
        let n = (0, Ge.utf8Count)(e);
        this.ensureBufferSizeToWrite(5 + n), this.writeStringHeader(n), (0, Ge.utf8EncodeJs)(e, this.bytes, this.pos), this.pos += n;
      }
    }
    encodeObject(e, t) {
      let r = this.extensionCodec.tryToEncode(e, this.context);
      if (r != null)
        this.encodeExtension(r);
      else if (Array.isArray(e))
        this.encodeArray(e, t);
      else if (ArrayBuffer.isView(e))
        this.encodeBinary(e);
      else if (typeof e == "object")
        this.encodeMap(e, t);
      else
        throw new Error(`Unrecognized object: ${Object.prototype.toString.apply(e)}`);
    }
    encodeBinary(e) {
      let t = e.byteLength;
      if (t < 256)
        this.writeU8(196), this.writeU8(t);
      else if (t < 65536)
        this.writeU8(197), this.writeU16(t);
      else if (t < 4294967296)
        this.writeU8(198), this.writeU32(t);
      else
        throw new Error(`Too large binary: ${t}`);
      let r = (0, On.ensureUint8Array)(e);
      this.writeU8a(r);
    }
    encodeArray(e, t) {
      let r = e.length;
      if (r < 16)
        this.writeU8(144 + r);
      else if (r < 65536)
        this.writeU8(220), this.writeU16(r);
      else if (r < 4294967296)
        this.writeU8(221), this.writeU32(r);
      else
        throw new Error(`Too large array: ${r}`);
      for (let n of e)
        this.doEncode(n, t + 1);
    }
    countWithoutUndefined(e, t) {
      let r = 0;
      for (let n of t)
        e[n] !== void 0 && r++;
      return r;
    }
    encodeMap(e, t) {
      let r = Object.keys(e);
      this.sortKeys && r.sort();
      let n = this.ignoreUndefined ? this.countWithoutUndefined(e, r) : r.length;
      if (n < 16)
        this.writeU8(128 + n);
      else if (n < 65536)
        this.writeU8(222), this.writeU16(n);
      else if (n < 4294967296)
        this.writeU8(223), this.writeU32(n);
      else
        throw new Error(`Too large map object: ${n}`);
      for (let o of r) {
        let i = e[o];
        this.ignoreUndefined && i === void 0 || (this.encodeString(o), this.doEncode(i, t + 1));
      }
    }
    encodeExtension(e) {
      let t = e.data.length;
      if (t === 1)
        this.writeU8(212);
      else if (t === 2)
        this.writeU8(213);
      else if (t === 4)
        this.writeU8(214);
      else if (t === 8)
        this.writeU8(215);
      else if (t === 16)
        this.writeU8(216);
      else if (t < 256)
        this.writeU8(199), this.writeU8(t);
      else if (t < 65536)
        this.writeU8(200), this.writeU16(t);
      else if (t < 4294967296)
        this.writeU8(201), this.writeU32(t);
      else
        throw new Error(`Too large extension object: ${t}`);
      this.writeI8(e.type), this.writeU8a(e.data);
    }
    writeU8(e) {
      this.ensureBufferSizeToWrite(1), this.view.setUint8(this.pos, e), this.pos++;
    }
    writeU8a(e) {
      let t = e.length;
      this.ensureBufferSizeToWrite(t), this.bytes.set(e, this.pos), this.pos += t;
    }
    writeI8(e) {
      this.ensureBufferSizeToWrite(1), this.view.setInt8(this.pos, e), this.pos++;
    }
    writeU16(e) {
      this.ensureBufferSizeToWrite(2), this.view.setUint16(this.pos, e), this.pos += 2;
    }
    writeI16(e) {
      this.ensureBufferSizeToWrite(2), this.view.setInt16(this.pos, e), this.pos += 2;
    }
    writeU32(e) {
      this.ensureBufferSizeToWrite(4), this.view.setUint32(this.pos, e), this.pos += 4;
    }
    writeI32(e) {
      this.ensureBufferSizeToWrite(4), this.view.setInt32(this.pos, e), this.pos += 4;
    }
    writeF32(e) {
      this.ensureBufferSizeToWrite(4), this.view.setFloat32(this.pos, e), this.pos += 4;
    }
    writeF64(e) {
      this.ensureBufferSizeToWrite(8), this.view.setFloat64(this.pos, e), this.pos += 8;
    }
    writeU64(e) {
      this.ensureBufferSizeToWrite(8), (0, bs.setUint64)(this.view, this.pos, e), this.pos += 8;
    }
    writeI64(e) {
      this.ensureBufferSizeToWrite(8), (0, bs.setInt64)(this.view, this.pos, e), this.pos += 8;
    }
  };
  J.Encoder = Or;
});
var ws = S((Lt) => {
  "use strict";
  Object.defineProperty(Lt, "__esModule", { value: true });
  Lt.encode = void 0;
  var In = Ir(), Un = {};
  function Cn(s, e = Un) {
    return new In.Encoder(e.extensionCodec, e.context, e.maxDepth, e.initialBufferSize, e.sortKeys, e.forceFloat32, e.ignoreUndefined, e.forceIntegerToFloat).encodeSharedRef(s);
  }
  Lt.encode = Cn;
});
var xs = S((Ft) => {
  "use strict";
  Object.defineProperty(Ft, "__esModule", { value: true });
  Ft.prettyByte = void 0;
  function jn(s) {
    return `${s < 0 ? "-" : ""}0x${Math.abs(s).toString(16).padStart(2, "0")}`;
  }
  Ft.prettyByte = jn;
});
var vs = S((qt) => {
  "use strict";
  Object.defineProperty(qt, "__esModule", { value: true });
  qt.CachedKeyDecoder = void 0;
  var Nn = Ot(), Bn = 16, Ln = 16, Ur = class {
    constructor(e = Bn, t = Ln) {
      this.maxKeyLength = e, this.maxLengthPerKey = t, this.hit = 0, this.miss = 0, this.caches = [];
      for (let r = 0; r < this.maxKeyLength; r++)
        this.caches.push([]);
    }
    canBeCached(e) {
      return e > 0 && e <= this.maxKeyLength;
    }
    find(e, t, r) {
      let n = this.caches[r - 1];
      e:
        for (let o of n) {
          let i = o.bytes;
          for (let l = 0; l < r; l++)
            if (i[l] !== e[t + l])
              continue e;
          return o.str;
        }
      return null;
    }
    store(e, t) {
      let r = this.caches[e.length - 1], n = { bytes: e, str: t };
      r.length >= this.maxLengthPerKey ? r[Math.random() * r.length | 0] = n : r.push(n);
    }
    decode(e, t, r) {
      let n = this.find(e, t, r);
      if (n != null)
        return this.hit++, n;
      this.miss++;
      let o = (0, Nn.utf8DecodeJs)(e, t, r), i = Uint8Array.prototype.slice.call(e, t, t + r);
      return this.store(i, o), o;
    }
  };
  qt.CachedKeyDecoder = Ur;
});
var Vt = S((Q) => {
  "use strict";
  Object.defineProperty(Q, "__esModule", { value: true });
  Q.Decoder = Q.DataViewIndexOutOfBoundsError = void 0;
  var Cr = xs(), Fn = Bt(), ce = He(), jr = Ot(), Nr = Ar(), qn = vs(), K = Ct(), Vn = (s) => {
    let e = typeof s;
    return e === "string" || e === "number";
  }, $e = -1, Lr = new DataView(new ArrayBuffer(0)), Jn = new Uint8Array(Lr.buffer);
  Q.DataViewIndexOutOfBoundsError = (() => {
    try {
      Lr.getInt8(0);
    } catch (s) {
      return s.constructor;
    }
    throw new Error("never reached");
  })();
  var Es = new Q.DataViewIndexOutOfBoundsError("Insufficient data"), Hn = new qn.CachedKeyDecoder(), Br = class {
    constructor(e = Fn.ExtensionCodec.defaultCodec, t = void 0, r = ce.UINT32_MAX, n = ce.UINT32_MAX, o = ce.UINT32_MAX, i = ce.UINT32_MAX, l = ce.UINT32_MAX, p = Hn) {
      this.extensionCodec = e, this.context = t, this.maxStrLength = r, this.maxBinLength = n, this.maxArrayLength = o, this.maxMapLength = i, this.maxExtLength = l, this.keyDecoder = p, this.totalPos = 0, this.pos = 0, this.view = Lr, this.bytes = Jn, this.headByte = $e, this.stack = [];
    }
    reinitializeState() {
      this.totalPos = 0, this.headByte = $e, this.stack.length = 0;
    }
    setBuffer(e) {
      this.bytes = (0, Nr.ensureUint8Array)(e), this.view = (0, Nr.createDataView)(this.bytes), this.pos = 0;
    }
    appendBuffer(e) {
      if (this.headByte === $e && !this.hasRemaining(1))
        this.setBuffer(e);
      else {
        let t = this.bytes.subarray(this.pos), r = (0, Nr.ensureUint8Array)(e), n = new Uint8Array(t.length + r.length);
        n.set(t), n.set(r, t.length), this.setBuffer(n);
      }
    }
    hasRemaining(e) {
      return this.view.byteLength - this.pos >= e;
    }
    createExtraByteError(e) {
      let { view: t, pos: r } = this;
      return new RangeError(`Extra ${t.byteLength - r} of ${t.byteLength} byte(s) found at buffer[${e}]`);
    }
    decode(e) {
      this.reinitializeState(), this.setBuffer(e);
      let t = this.doDecodeSync();
      if (this.hasRemaining(1))
        throw this.createExtraByteError(this.pos);
      return t;
    }
    *decodeMulti(e) {
      for (this.reinitializeState(), this.setBuffer(e); this.hasRemaining(1); )
        yield this.doDecodeSync();
    }
    async decodeAsync(e) {
      let t = false, r;
      for await (let l of e) {
        if (t)
          throw this.createExtraByteError(this.totalPos);
        this.appendBuffer(l);
        try {
          r = this.doDecodeSync(), t = true;
        } catch (p) {
          if (!(p instanceof Q.DataViewIndexOutOfBoundsError))
            throw p;
        }
        this.totalPos += this.pos;
      }
      if (t) {
        if (this.hasRemaining(1))
          throw this.createExtraByteError(this.totalPos);
        return r;
      }
      let { headByte: n, pos: o, totalPos: i } = this;
      throw new RangeError(`Insufficient data in parsing ${(0, Cr.prettyByte)(n)} at ${i} (${o} in the current buffer)`);
    }
    decodeArrayStream(e) {
      return this.decodeMultiAsync(e, true);
    }
    decodeStream(e) {
      return this.decodeMultiAsync(e, false);
    }
    async *decodeMultiAsync(e, t) {
      let r = t, n = -1;
      for await (let o of e) {
        if (t && n === 0)
          throw this.createExtraByteError(this.totalPos);
        this.appendBuffer(o), r && (n = this.readArraySize(), r = false, this.complete());
        try {
          for (; yield this.doDecodeSync(), --n !== 0; )
            ;
        } catch (i) {
          if (!(i instanceof Q.DataViewIndexOutOfBoundsError))
            throw i;
        }
        this.totalPos += this.pos;
      }
    }
    doDecodeSync() {
      e:
        for (; ; ) {
          let e = this.readHeadByte(), t;
          if (e >= 224)
            t = e - 256;
          else if (e < 192)
            if (e < 128)
              t = e;
            else if (e < 144) {
              let n = e - 128;
              if (n !== 0) {
                this.pushMapState(n), this.complete();
                continue e;
              } else
                t = {};
            } else if (e < 160) {
              let n = e - 144;
              if (n !== 0) {
                this.pushArrayState(n), this.complete();
                continue e;
              } else
                t = [];
            } else {
              let n = e - 160;
              t = this.decodeUtf8String(n, 0);
            }
          else if (e === 192)
            t = null;
          else if (e === 194)
            t = false;
          else if (e === 195)
            t = true;
          else if (e === 202)
            t = this.readF32();
          else if (e === 203)
            t = this.readF64();
          else if (e === 204)
            t = this.readU8();
          else if (e === 205)
            t = this.readU16();
          else if (e === 206)
            t = this.readU32();
          else if (e === 207)
            t = this.readU64();
          else if (e === 208)
            t = this.readI8();
          else if (e === 209)
            t = this.readI16();
          else if (e === 210)
            t = this.readI32();
          else if (e === 211)
            t = this.readI64();
          else if (e === 217) {
            let n = this.lookU8();
            t = this.decodeUtf8String(n, 1);
          } else if (e === 218) {
            let n = this.lookU16();
            t = this.decodeUtf8String(n, 2);
          } else if (e === 219) {
            let n = this.lookU32();
            t = this.decodeUtf8String(n, 4);
          } else if (e === 220) {
            let n = this.readU16();
            if (n !== 0) {
              this.pushArrayState(n), this.complete();
              continue e;
            } else
              t = [];
          } else if (e === 221) {
            let n = this.readU32();
            if (n !== 0) {
              this.pushArrayState(n), this.complete();
              continue e;
            } else
              t = [];
          } else if (e === 222) {
            let n = this.readU16();
            if (n !== 0) {
              this.pushMapState(n), this.complete();
              continue e;
            } else
              t = {};
          } else if (e === 223) {
            let n = this.readU32();
            if (n !== 0) {
              this.pushMapState(n), this.complete();
              continue e;
            } else
              t = {};
          } else if (e === 196) {
            let n = this.lookU8();
            t = this.decodeBinary(n, 1);
          } else if (e === 197) {
            let n = this.lookU16();
            t = this.decodeBinary(n, 2);
          } else if (e === 198) {
            let n = this.lookU32();
            t = this.decodeBinary(n, 4);
          } else if (e === 212)
            t = this.decodeExtension(1, 0);
          else if (e === 213)
            t = this.decodeExtension(2, 0);
          else if (e === 214)
            t = this.decodeExtension(4, 0);
          else if (e === 215)
            t = this.decodeExtension(8, 0);
          else if (e === 216)
            t = this.decodeExtension(16, 0);
          else if (e === 199) {
            let n = this.lookU8();
            t = this.decodeExtension(n, 1);
          } else if (e === 200) {
            let n = this.lookU16();
            t = this.decodeExtension(n, 2);
          } else if (e === 201) {
            let n = this.lookU32();
            t = this.decodeExtension(n, 4);
          } else
            throw new K.DecodeError(`Unrecognized type byte: ${(0, Cr.prettyByte)(e)}`);
          this.complete();
          let r = this.stack;
          for (; r.length > 0; ) {
            let n = r[r.length - 1];
            if (n.type === 0)
              if (n.array[n.position] = t, n.position++, n.position === n.size)
                r.pop(), t = n.array;
              else
                continue e;
            else if (n.type === 1) {
              if (!Vn(t))
                throw new K.DecodeError("The type of key must be string or number but " + typeof t);
              if (t === "__proto__")
                throw new K.DecodeError("The key __proto__ is not allowed");
              n.key = t, n.type = 2;
              continue e;
            } else if (n.map[n.key] = t, n.readCount++, n.readCount === n.size)
              r.pop(), t = n.map;
            else {
              n.key = null, n.type = 1;
              continue e;
            }
          }
          return t;
        }
    }
    readHeadByte() {
      return this.headByte === $e && (this.headByte = this.readU8()), this.headByte;
    }
    complete() {
      this.headByte = $e;
    }
    readArraySize() {
      let e = this.readHeadByte();
      switch (e) {
        case 220:
          return this.readU16();
        case 221:
          return this.readU32();
        default: {
          if (e < 160)
            return e - 144;
          throw new K.DecodeError(`Unrecognized array type byte: ${(0, Cr.prettyByte)(e)}`);
        }
      }
    }
    pushMapState(e) {
      if (e > this.maxMapLength)
        throw new K.DecodeError(`Max length exceeded: map length (${e}) > maxMapLengthLength (${this.maxMapLength})`);
      this.stack.push({ type: 1, size: e, key: null, readCount: 0, map: {} });
    }
    pushArrayState(e) {
      if (e > this.maxArrayLength)
        throw new K.DecodeError(`Max length exceeded: array length (${e}) > maxArrayLength (${this.maxArrayLength})`);
      this.stack.push({ type: 0, size: e, array: new Array(e), position: 0 });
    }
    decodeUtf8String(e, t) {
      var r;
      if (e > this.maxStrLength)
        throw new K.DecodeError(`Max length exceeded: UTF-8 byte length (${e}) > maxStrLength (${this.maxStrLength})`);
      if (this.bytes.byteLength < this.pos + t + e)
        throw Es;
      let n = this.pos + t, o;
      return this.stateIsMapKey() && (!((r = this.keyDecoder) === null || r === void 0) && r.canBeCached(e)) ? o = this.keyDecoder.decode(this.bytes, n, e) : e > jr.TEXT_DECODER_THRESHOLD ? o = (0, jr.utf8DecodeTD)(this.bytes, n, e) : o = (0, jr.utf8DecodeJs)(this.bytes, n, e), this.pos += t + e, o;
    }
    stateIsMapKey() {
      return this.stack.length > 0 ? this.stack[this.stack.length - 1].type === 1 : false;
    }
    decodeBinary(e, t) {
      if (e > this.maxBinLength)
        throw new K.DecodeError(`Max length exceeded: bin length (${e}) > maxBinLength (${this.maxBinLength})`);
      if (!this.hasRemaining(e + t))
        throw Es;
      let r = this.pos + t, n = this.bytes.subarray(r, r + e);
      return this.pos += t + e, n;
    }
    decodeExtension(e, t) {
      if (e > this.maxExtLength)
        throw new K.DecodeError(`Max length exceeded: ext length (${e}) > maxExtLength (${this.maxExtLength})`);
      let r = this.view.getInt8(this.pos + t), n = this.decodeBinary(e, t + 1);
      return this.extensionCodec.decode(n, r, this.context);
    }
    lookU8() {
      return this.view.getUint8(this.pos);
    }
    lookU16() {
      return this.view.getUint16(this.pos);
    }
    lookU32() {
      return this.view.getUint32(this.pos);
    }
    readU8() {
      let e = this.view.getUint8(this.pos);
      return this.pos++, e;
    }
    readI8() {
      let e = this.view.getInt8(this.pos);
      return this.pos++, e;
    }
    readU16() {
      let e = this.view.getUint16(this.pos);
      return this.pos += 2, e;
    }
    readI16() {
      let e = this.view.getInt16(this.pos);
      return this.pos += 2, e;
    }
    readU32() {
      let e = this.view.getUint32(this.pos);
      return this.pos += 4, e;
    }
    readI32() {
      let e = this.view.getInt32(this.pos);
      return this.pos += 4, e;
    }
    readU64() {
      let e = (0, ce.getUint64)(this.view, this.pos);
      return this.pos += 8, e;
    }
    readI64() {
      let e = (0, ce.getInt64)(this.view, this.pos);
      return this.pos += 8, e;
    }
    readF32() {
      let e = this.view.getFloat32(this.pos);
      return this.pos += 4, e;
    }
    readF64() {
      let e = this.view.getFloat64(this.pos);
      return this.pos += 8, e;
    }
  };
  Q.Decoder = Br;
});
var Fr = S((H) => {
  "use strict";
  Object.defineProperty(H, "__esModule", { value: true });
  H.decodeMulti = H.decode = H.defaultDecodeOptions = void 0;
  var Ps = Vt();
  H.defaultDecodeOptions = {};
  function zn(s, e = H.defaultDecodeOptions) {
    return new Ps.Decoder(e.extensionCodec, e.context, e.maxStrLength, e.maxBinLength, e.maxArrayLength, e.maxMapLength, e.maxExtLength).decode(s);
  }
  H.decode = zn;
  function Xn(s, e = H.defaultDecodeOptions) {
    return new Ps.Decoder(e.extensionCodec, e.context, e.maxStrLength, e.maxBinLength, e.maxArrayLength, e.maxMapLength, e.maxExtLength).decodeMulti(s);
  }
  H.decodeMulti = Xn;
});
var Ss = S((re) => {
  "use strict";
  Object.defineProperty(re, "__esModule", { value: true });
  re.ensureAsyncIterable = re.asyncIterableFromStream = re.isAsyncIterable = void 0;
  function Ts(s) {
    return s[Symbol.asyncIterator] != null;
  }
  re.isAsyncIterable = Ts;
  function Gn(s) {
    if (s == null)
      throw new Error("Assertion Failure: value must not be null nor undefined");
  }
  async function* _s(s) {
    let e = s.getReader();
    try {
      for (; ; ) {
        let { done: t, value: r } = await e.read();
        if (t)
          return;
        Gn(r), yield r;
      }
    } finally {
      e.releaseLock();
    }
  }
  re.asyncIterableFromStream = _s;
  function $n(s) {
    return Ts(s) ? s : _s(s);
  }
  re.ensureAsyncIterable = $n;
});
var Ms = S((z) => {
  "use strict";
  Object.defineProperty(z, "__esModule", { value: true });
  z.decodeStream = z.decodeMultiStream = z.decodeArrayStream = z.decodeAsync = void 0;
  var qr = Vt(), Vr = Ss(), Jt = Fr();
  async function Kn(s, e = Jt.defaultDecodeOptions) {
    let t = (0, Vr.ensureAsyncIterable)(s);
    return new qr.Decoder(e.extensionCodec, e.context, e.maxStrLength, e.maxBinLength, e.maxArrayLength, e.maxMapLength, e.maxExtLength).decodeAsync(t);
  }
  z.decodeAsync = Kn;
  function Qn(s, e = Jt.defaultDecodeOptions) {
    let t = (0, Vr.ensureAsyncIterable)(s);
    return new qr.Decoder(e.extensionCodec, e.context, e.maxStrLength, e.maxBinLength, e.maxArrayLength, e.maxMapLength, e.maxExtLength).decodeArrayStream(t);
  }
  z.decodeArrayStream = Qn;
  function ks(s, e = Jt.defaultDecodeOptions) {
    let t = (0, Vr.ensureAsyncIterable)(s);
    return new qr.Decoder(e.extensionCodec, e.context, e.maxStrLength, e.maxBinLength, e.maxArrayLength, e.maxMapLength, e.maxExtLength).decodeStream(t);
  }
  z.decodeMultiStream = ks;
  function Zn(s, e = Jt.defaultDecodeOptions) {
    return ks(s, e);
  }
  z.decodeStream = Zn;
});
var zt = S((h) => {
  "use strict";
  Object.defineProperty(h, "__esModule", { value: true });
  h.decodeTimestampExtension = h.encodeTimestampExtension = h.decodeTimestampToTimeSpec = h.encodeTimeSpecToTimestamp = h.encodeDateToTimeSpec = h.EXT_TIMESTAMP = h.ExtData = h.ExtensionCodec = h.Encoder = h.DataViewIndexOutOfBoundsError = h.DecodeError = h.Decoder = h.decodeStream = h.decodeMultiStream = h.decodeArrayStream = h.decodeAsync = h.decodeMulti = h.decode = h.encode = void 0;
  var Yn = ws();
  Object.defineProperty(h, "encode", { enumerable: true, get: function() {
    return Yn.encode;
  } });
  var Ds = Fr();
  Object.defineProperty(h, "decode", { enumerable: true, get: function() {
    return Ds.decode;
  } });
  Object.defineProperty(h, "decodeMulti", { enumerable: true, get: function() {
    return Ds.decodeMulti;
  } });
  var Ht = Ms();
  Object.defineProperty(h, "decodeAsync", { enumerable: true, get: function() {
    return Ht.decodeAsync;
  } });
  Object.defineProperty(h, "decodeArrayStream", { enumerable: true, get: function() {
    return Ht.decodeArrayStream;
  } });
  Object.defineProperty(h, "decodeMultiStream", { enumerable: true, get: function() {
    return Ht.decodeMultiStream;
  } });
  Object.defineProperty(h, "decodeStream", { enumerable: true, get: function() {
    return Ht.decodeStream;
  } });
  var Ws = Vt();
  Object.defineProperty(h, "Decoder", { enumerable: true, get: function() {
    return Ws.Decoder;
  } });
  Object.defineProperty(h, "DataViewIndexOutOfBoundsError", { enumerable: true, get: function() {
    return Ws.DataViewIndexOutOfBoundsError;
  } });
  var eo = Ct();
  Object.defineProperty(h, "DecodeError", { enumerable: true, get: function() {
    return eo.DecodeError;
  } });
  var to = Ir();
  Object.defineProperty(h, "Encoder", { enumerable: true, get: function() {
    return to.Encoder;
  } });
  var ro = Bt();
  Object.defineProperty(h, "ExtensionCodec", { enumerable: true, get: function() {
    return ro.ExtensionCodec;
  } });
  var so = Dr();
  Object.defineProperty(h, "ExtData", { enumerable: true, get: function() {
    return so.ExtData;
  } });
  var ve = Wr();
  Object.defineProperty(h, "EXT_TIMESTAMP", { enumerable: true, get: function() {
    return ve.EXT_TIMESTAMP;
  } });
  Object.defineProperty(h, "encodeDateToTimeSpec", { enumerable: true, get: function() {
    return ve.encodeDateToTimeSpec;
  } });
  Object.defineProperty(h, "encodeTimeSpecToTimestamp", { enumerable: true, get: function() {
    return ve.encodeTimeSpecToTimestamp;
  } });
  Object.defineProperty(h, "decodeTimestampToTimeSpec", { enumerable: true, get: function() {
    return ve.decodeTimestampToTimeSpec;
  } });
  Object.defineProperty(h, "encodeTimestampExtension", { enumerable: true, get: function() {
    return ve.encodeTimestampExtension;
  } });
  Object.defineProperty(h, "decodeTimestampExtension", { enumerable: true, get: function() {
    return ve.decodeTimestampExtension;
  } });
});
var I = class extends Error {
  constructor(e) {
    super(e), this.name = this.constructor.name, Object.setPrototypeOf(this, new.target.prototype);
  }
};
var A = class extends I {
};
var P = class extends I {
};
var m = typeof process < "u" && process.release && process.release.name === "node";
var Rr;
if (globalThis.document)
  Rr = (s) => new Promise((e, t) => {
    let r = document.createElement("script");
    r.src = s, r.onload = () => e(), r.onerror = t, document.head.appendChild(r);
  });
else if (globalThis.importScripts)
  Rr = async (s) => {
    try {
      globalThis.importScripts(s);
    } catch (e) {
      if (e instanceof TypeError)
        await Promise.resolve().then(() => oe(B(s)));
      else
        throw e;
    }
  };
else if (m)
  Rr = async (s) => {
    let e = (await Promise.resolve().then(() => oe(B("path")))).default;
    await Promise.resolve().then(() => oe(B(e.resolve(s))));
  };
else
  throw new I("Cannot determine runtime environment");
var c = {};
function es(s) {
  Object.keys(s).forEach((e) => c._free(s[e]));
}
var N = { null: 0, symbol: 1, pairlist: 2, closure: 3, environment: 4, promise: 5, call: 6, special: 7, builtin: 8, string: 9, logical: 10, integer: 13, double: 14, complex: 15, character: 16, dots: 17, any: 18, list: 19, expression: 20, bytecode: 21, pointer: 22, weakref: 23, raw: 24, s4: 25, new: 30, free: 31, function: 99 };
function mr(s) {
  return !!s && typeof s == "object" && Object.keys(N).includes(s.type);
}
function Ce(s) {
  return !!s && typeof s == "object" && "re" in s && "im" in s;
}
function je(s) {
  return c._Rf_protect(L(s)), s;
}
function w(s, e) {
  return c._Rf_protect(L(s)), ++e.n, s;
}
function ts(s) {
  let e = c._malloc(4);
  return c._R_ProtectWithIndex(L(s), e), { loc: c.getValue(e, "i32"), ptr: e };
}
function rs(s) {
  c._Rf_unprotect(1), c._free(s.ptr);
}
function ss(s, e) {
  return c._R_Reprotect(L(s), e.loc), s;
}
function T(s) {
  c._Rf_unprotect(s);
}
function gr(s, e, t) {
  c._Rf_defineVar(L(e), L(t), L(s));
}
function br(s, e) {
  let t = {}, r = { n: 0 };
  try {
    let n = new Be(e);
    w(n, r), t.code = c.allocateUTF8(s);
    let o = c._R_ParseEvalString(t.code, n.ptr);
    return y.wrap(o);
  } finally {
    es(t), T(r.n);
  }
}
function Ne(s, e) {
  return c.getWasmTableEntry(c.GOT.ffi_safe_eval.value)(L(s), L(e));
}
var un = /* @__PURE__ */ new WeakMap();
function ns(s, e) {
  return un.set(s, e), s;
}
function L(s) {
  return Tt(s) ? s.ptr : s;
}
function le(s, e) {
  if (c._TYPEOF(s.ptr) !== N[e])
    throw new Error(`Unexpected object type "${s.type()}" when expecting type "${e}"`);
}
function as(s) {
  if (mr(s))
    return new (is(s.type))(s);
  if (s && typeof s == "object" && "type" in s && s.type === "null")
    return new Pt();
  if (s === null)
    return new Y({ type: "logical", names: null, values: [null] });
  if (typeof s == "boolean")
    return new Y(s);
  if (typeof s == "number")
    return new fe(s);
  if (typeof s == "string")
    return new F(s);
  if (Ce(s))
    return new Fe(s);
  if (ArrayBuffer.isView(s) || s instanceof ArrayBuffer)
    return new qe(s);
  if (Array.isArray(s))
    return dn(s);
  if (typeof s == "object")
    return ee.fromObject(s);
  throw new Error("Robj construction for this JS object is not yet supported");
}
function dn(s) {
  let e = { n: 0 };
  if (s.every((r) => r && typeof r == "object" && !Tt(r) && !Ce(r))) {
    let r = s, n = r.every((i) => Object.keys(i).filter((l) => !Object.keys(r[0]).includes(l)).length === 0 && Object.keys(r[0]).filter((l) => !Object.keys(i).includes(l)).length === 0), o = r.every((i) => Object.values(i).every((l) => cs(l) || ls(l)));
    if (n && o)
      return ee.fromD3(r);
  }
  if (s.every((r) => typeof r == "boolean" || r === null))
    return new Y(s);
  if (s.every((r) => typeof r == "number" || r === null))
    return new fe(s);
  if (s.every((r) => typeof r == "string" || r === null))
    return new F(s);
  try {
    let r = new q([new U("c"), ...s]);
    return w(r, e), r.eval();
  } finally {
    T(e.n);
  }
}
var x = class {
  constructor(e) {
    this.ptr = e;
  }
  type() {
    let e = c._TYPEOF(this.ptr);
    return Object.keys(N).find((r) => N[r] === e);
  }
};
var Re;
var vt;
var ae = class extends x {
  constructor(t) {
    if (!(t instanceof x))
      return as(t);
    super(t.ptr);
    u(this, Re);
  }
  static wrap(t) {
    let r = c._TYPEOF(t), n = Object.keys(N)[Object.values(N).indexOf(r)];
    return new (is(n))(new x(t));
  }
  get [Symbol.toStringTag]() {
    return `RObject:${this.type()}`;
  }
  static getPersistentObject(t) {
    return k[t];
  }
  getPropertyValue(t) {
    return this[t];
  }
  inspect() {
    br(".Internal(inspect(x))", { x: this });
  }
  isNull() {
    return c._TYPEOF(this.ptr) === N.null;
  }
  isNa() {
    try {
      let t = br("is.na(x)", { x: this });
      return je(t), t.toBoolean();
    } finally {
      T(1);
    }
  }
  isUnbound() {
    return this.ptr === k.unboundValue.ptr;
  }
  attrs() {
    return ie.wrap(c._ATTRIB(this.ptr));
  }
  class() {
    let t = { n: 0 }, r = new q([new U("class"), this]);
    w(r, t);
    try {
      return r.eval();
    } finally {
      T(t.n);
    }
  }
  setNames(t) {
    let r;
    if (t === null)
      r = k.null;
    else if (Array.isArray(t) && t.every((n) => typeof n == "string" || n === null))
      r = new F(t);
    else
      throw new Error("Argument to setNames must be null or an Array of strings or null");
    return c._Rf_setAttrib(this.ptr, k.namesSymbol.ptr, r.ptr), this;
  }
  names() {
    let t = F.wrap(c._Rf_getAttrib(this.ptr, k.namesSymbol.ptr));
    return t.isNull() ? null : t.toArray();
  }
  includes(t) {
    let r = this.names();
    return r && r.includes(t);
  }
  toJs(t = { depth: 0 }, r = 1) {
    throw new Error("This R object cannot be converted to JS");
  }
  subset(t) {
    return E(this, Re, vt).call(this, t, k.bracketSymbol.ptr);
  }
  get(t) {
    return E(this, Re, vt).call(this, t, k.bracket2Symbol.ptr);
  }
  getDollar(t) {
    return E(this, Re, vt).call(this, t, k.dollarSymbol.ptr);
  }
  pluck(...t) {
    let r = ts(k.null);
    try {
      let n = (i, l) => {
        let p = i.get(l);
        return ss(p, r);
      }, o = t.reduce(n, this);
      return o.isNull() ? void 0 : o;
    } finally {
      rs(r);
    }
  }
  set(t, r) {
    let n = { n: 0 };
    try {
      let o = new ae(t);
      w(o, n);
      let i = new ae(r);
      w(i, n);
      let l = new U("[[<-"), p = c._Rf_lang4(l.ptr, this.ptr, o.ptr, i.ptr);
      return w(p, n), ae.wrap(Ne(p, k.baseEnv));
    } finally {
      T(n.n);
    }
  }
  static getMethods(t) {
    let r = /* @__PURE__ */ new Set(), n = t;
    do
      Object.getOwnPropertyNames(n).map((o) => r.add(o));
    while (n = Object.getPrototypeOf(n));
    return [...r.keys()].filter((o) => typeof t[o] == "function");
  }
};
var y = ae;
Re = /* @__PURE__ */ new WeakSet(), vt = function(t, r) {
  let n = { n: 0 };
  try {
    let o = new ae(t);
    w(o, n);
    let i = c._Rf_lang3(r, this.ptr, o.ptr);
    return w(i, n), ae.wrap(Ne(i, k.baseEnv));
  } finally {
    T(n.n);
  }
};
var Pt = class extends y {
  constructor() {
    return super(new x(c.getValue(c._R_NilValue, "*"))), this;
  }
  toJs() {
    return { type: "null" };
  }
};
var U = class extends y {
  constructor(e) {
    if (e instanceof x) {
      le(e, "symbol"), super(e);
      return;
    }
    let t = c.allocateUTF8(e);
    try {
      super(new x(c._Rf_install(t)));
    } finally {
      c._free(t);
    }
  }
  toJs() {
    let e = this.toObject();
    return { type: "symbol", printname: e.printname, symvalue: e.symvalue, internal: e.internal };
  }
  toObject() {
    return { printname: this.printname().isUnbound() ? null : this.printname().toString(), symvalue: this.symvalue().isUnbound() ? null : this.symvalue().ptr, internal: this.internal().isNull() ? null : this.internal().ptr };
  }
  toString() {
    return this.printname().toString();
  }
  printname() {
    return Je.wrap(c._PRINTNAME(this.ptr));
  }
  symvalue() {
    return y.wrap(c._SYMVALUE(this.ptr));
  }
  internal() {
    return y.wrap(c._INTERNAL(this.ptr));
  }
};
var ie = class extends y {
  constructor(e) {
    if (e instanceof x)
      return le(e, "pairlist"), super(e), this;
    let t = { n: 0 };
    try {
      let { names: r, values: n } = me(e), o = ie.wrap(c._Rf_allocList(n.length));
      w(o, t);
      for (let [i, l] = [0, o]; !l.isNull(); [i, l] = [i + 1, l.cdr()])
        l.setcar(new y(n[i]));
      o.setNames(r), super(o);
    } finally {
      T(t.n);
    }
  }
  get length() {
    return this.toArray().length;
  }
  toArray(e = { depth: 1 }) {
    return this.toJs(e).values;
  }
  toObject({ allowDuplicateKey: e = true, allowEmptyKey: t = false, depth: r = -1 } = {}) {
    let n = this.entries({ depth: r }), o = n.map(([i]) => i);
    if (!e && new Set(o).size !== o.length)
      throw new Error("Duplicate key when converting pairlist without allowDuplicateKey enabled");
    if (!t && o.some((i) => !i))
      throw new Error("Empty or null key when converting pairlist without allowEmptyKey enabled");
    return Object.fromEntries(n.filter((i, l) => n.findIndex((p) => p[0] === i[0]) === l));
  }
  entries(e = { depth: 1 }) {
    let t = this.toJs(e);
    return t.values.map((r, n) => [t.names ? t.names[n] : null, r]);
  }
  toJs(e = { depth: 0 }, t = 1) {
    let r = [], n = false, o = [];
    for (let l = this; !l.isNull(); l = l.cdr()) {
      let p = l.tag();
      p.isNull() ? r.push("") : (n = true, r.push(p.toString())), e.depth && t >= e.depth ? o.push(l.car()) : o.push(l.car().toJs(e, t + 1));
    }
    return { type: "pairlist", names: n ? r : null, values: o };
  }
  includes(e) {
    return e in this.toObject();
  }
  setcar(e) {
    c._SETCAR(this.ptr, e.ptr);
  }
  car() {
    return y.wrap(c._CAR(this.ptr));
  }
  cdr() {
    return y.wrap(c._CDR(this.ptr));
  }
  tag() {
    return y.wrap(c._TAG(this.ptr));
  }
};
var q = class extends y {
  constructor(e) {
    if (e instanceof x)
      return le(e, "call"), super(e), this;
    let t = { n: 0 };
    try {
      let { values: r } = me(e), n = r.map((i) => w(new y(i), t)), o = q.wrap(c._Rf_allocVector(N.call, r.length));
      w(o, t);
      for (let [i, l] = [0, o]; !l.isNull(); [i, l] = [i + 1, l.cdr()])
        l.setcar(n[i]);
      super(o);
    } finally {
      T(t.n);
    }
  }
  setcar(e) {
    c._SETCAR(this.ptr, e.ptr);
  }
  car() {
    return y.wrap(c._CAR(this.ptr));
  }
  cdr() {
    return y.wrap(c._CDR(this.ptr));
  }
  eval() {
    return c.webr.evalR(this, { env: k.baseEnv });
  }
  capture(e = {}) {
    return c.webr.captureR(this, e);
  }
  deparse() {
    let e = { n: 0 };
    try {
      let t = c._Rf_lang2(new U("deparse1").ptr, c._Rf_lang2(new U("quote").ptr, this.ptr));
      w(t, e);
      let r = F.wrap(Ne(t, k.baseEnv));
      return w(r, e), r.toString();
    } finally {
      T(e.n);
    }
  }
};
var Ve = class extends y {
  constructor(e, t = null) {
    if (e instanceof x) {
      if (le(e, "list"), super(e), t) {
        if (t.length !== this.length)
          throw new Error("Can't construct named `RList`. Supplied `names` must be the same length as the list.");
        this.setNames(t);
      }
      return this;
    }
    let r = { n: 0 };
    try {
      let n = me(e), o = c._Rf_allocVector(N.list, n.values.length);
      w(o, r), n.values.forEach((l, p) => {
        c._SET_VECTOR_ELT(o, p, new y(l).ptr);
      });
      let i = t || n.names;
      if (i && i.length !== n.values.length)
        throw new Error("Can't construct named `RList`. Supplied `names` must be the same length as the list.");
      y.wrap(o).setNames(i), super(new x(o));
    } finally {
      T(r.n);
    }
  }
  get length() {
    return c._LENGTH(this.ptr);
  }
  isDataFrame() {
    let e = ie.wrap(c._ATTRIB(this.ptr)).get("class");
    return !e.isNull() && e.toArray().includes("data.frame");
  }
  toArray(e = { depth: 1 }) {
    return this.toJs(e).values;
  }
  toObject({ allowDuplicateKey: e = true, allowEmptyKey: t = false, depth: r = -1 } = {}) {
    let n = this.entries({ depth: r }), o = n.map(([i]) => i);
    if (!e && new Set(o).size !== o.length)
      throw new Error("Duplicate key when converting list without allowDuplicateKey enabled");
    if (!t && o.some((i) => !i))
      throw new Error("Empty or null key when converting list without allowEmptyKey enabled");
    return Object.fromEntries(n.filter((i, l) => n.findIndex((p) => p[0] === i[0]) === l));
  }
  toD3() {
    if (!this.isDataFrame())
      throw new Error("Can't convert R list object to D3 format. Object must be of class 'data.frame'.");
    return this.entries().reduce((t, r) => (r[1].forEach((n, o) => t[o] = Object.assign(t[o] || {}, { [r[0]]: n })), t), []);
  }
  entries(e = { depth: -1 }) {
    let t = this.toJs(e);
    return this.isDataFrame() && e.depth < 0 && (t.values = t.values.map((r) => r.toArray())), t.values.map((r, n) => [t.names ? t.names[n] : null, r]);
  }
  toJs(e = { depth: 0 }, t = 1) {
    return { type: "list", names: this.names(), values: [...Array(this.length).keys()].map((r) => e.depth && t >= e.depth ? this.get(r + 1) : this.get(r + 1).toJs(e, t + 1)) };
  }
};
var ee = class extends Ve {
  constructor(e) {
    if (e instanceof x) {
      if (super(e), !this.isDataFrame())
        throw new Error("Can't construct `RDataFrame`. Supplied R object is not a `data.frame`.");
      return this;
    }
    return ee.fromObject(e);
  }
  static fromObject(e) {
    let { names: t, values: r } = me(e), n = { n: 0 };
    try {
      let o = !!t && t.length > 0 && t.every((l) => l), i = r.length > 0 && r.every((l) => Array.isArray(l) || ArrayBuffer.isView(l) || l instanceof ArrayBuffer);
      if (o && i) {
        let l = r, p = l.every((b) => b.length === l[0].length), D = l.every((b) => cs(b[0]) || ls(b[0]));
        if (p && D) {
          let b = new Ve({ type: "list", names: t, values: l.map((rn) => as(rn)) });
          w(b, n);
          let j = new q([new U("as.data.frame"), b]);
          return w(j, n), new ee(j.eval());
        }
      }
    } finally {
      T(n.n);
    }
    throw new Error("Can't construct `data.frame`. Source object is not eligible.");
  }
  static fromD3(e) {
    return this.fromObject(Object.fromEntries(Object.keys(e[0]).map((t) => [t, e.map((r) => r[t])])));
  }
};
var ye = class extends y {
  exec(...e) {
    let t = { n: 0 };
    try {
      let r = new q([this, ...e]);
      return w(r, t), r.eval();
    } finally {
      T(t.n);
    }
  }
  capture(e = {}, ...t) {
    let r = { n: 0 };
    try {
      let n = new q([this, ...t]);
      return w(n, r), n.capture(e);
    } finally {
      T(r.n);
    }
  }
};
var Je = class extends y {
  constructor(e) {
    if (e instanceof x) {
      le(e, "string"), super(e);
      return;
    }
    let t = c.allocateUTF8(e);
    try {
      super(new x(c._Rf_mkChar(t)));
    } finally {
      c._free(t);
    }
  }
  toString() {
    return c.UTF8ToString(c._R_CHAR(this.ptr));
  }
  toJs() {
    return { type: "string", value: this.toString() };
  }
};
var Be = class extends y {
  constructor(e = {}) {
    if (e instanceof x)
      return le(e, "environment"), super(e), this;
    let t = 0;
    try {
      let { names: r, values: n } = me(e), o = je(c._R_NewEnv(k.globalEnv.ptr, 0, 0));
      ++t, n.forEach((i, l) => {
        let p = r ? r[l] : null;
        if (!p)
          throw new Error("Can't create object in new environment with empty symbol name");
        let D = new U(p), b = je(new y(i));
        try {
          gr(o, D, b);
        } finally {
          T(1);
        }
      }), super(new x(o));
    } finally {
      T(t);
    }
  }
  ls(e = false, t = true) {
    return F.wrap(c._R_lsInternal3(this.ptr, Number(e), Number(t))).toArray();
  }
  bind(e, t) {
    let r = new U(e), n = je(new y(t));
    try {
      gr(this, r, n);
    } finally {
      T(1);
    }
  }
  names() {
    return this.ls(true, true);
  }
  frame() {
    return y.wrap(c._FRAME(this.ptr));
  }
  subset(e) {
    if (typeof e == "number")
      throw new Error("Object of type environment is not subsettable");
    return this.getDollar(e);
  }
  toObject({ depth: e = -1 } = {}) {
    let t = this.names();
    return Object.fromEntries([...Array(t.length).keys()].map((r) => {
      let n = this.getDollar(t[r]);
      return [t[r], e < 0 ? n : n.toJs({ depth: e })];
    }));
  }
  toJs(e = { depth: 0 }, t = 1) {
    let r = this.names(), n = [...Array(r.length).keys()].map((o) => e.depth && t >= e.depth ? this.getDollar(r[o]) : this.getDollar(r[o]).toJs(e, t + 1));
    return { type: "environment", names: r, values: n };
  }
};
var te = class extends y {
  constructor(e, t, r) {
    if (e instanceof x)
      return le(e, t), super(e), this;
    let n = { n: 0 };
    try {
      let { names: o, values: i } = me(e), l = c._Rf_allocVector(N[t], i.length);
      w(l, n), i.forEach(r(l)), y.wrap(l).setNames(o), super(new x(l));
    } finally {
      T(n.n);
    }
  }
  get length() {
    return c._LENGTH(this.ptr);
  }
  get(e) {
    return super.get(e);
  }
  subset(e) {
    return super.subset(e);
  }
  getDollar() {
    throw new Error("$ operator is invalid for atomic vectors");
  }
  detectMissing() {
    let e = { n: 0 };
    try {
      let t = c._Rf_lang2(new U("is.na").ptr, this.ptr);
      w(t, e);
      let r = Y.wrap(Ne(t, k.baseEnv));
      w(r, e);
      let n = r.toTypedArray();
      return Array.from(n).map((o) => !!o);
    } finally {
      T(e.n);
    }
  }
  toArray() {
    let e = this.toTypedArray();
    return this.detectMissing().map((t, r) => t ? null : e[r]);
  }
  toObject({ allowDuplicateKey: e = true, allowEmptyKey: t = false } = {}) {
    let r = this.entries(), n = r.map(([o]) => o);
    if (!e && new Set(n).size !== n.length)
      throw new Error("Duplicate key when converting atomic vector without allowDuplicateKey enabled");
    if (!t && n.some((o) => !o))
      throw new Error("Empty or null key when converting atomic vector without allowEmptyKey enabled");
    return Object.fromEntries(r.filter((o, i) => r.findIndex((l) => l[0] === o[0]) === i));
  }
  entries() {
    let e = this.toArray(), t = this.names();
    return e.map((r, n) => [t ? t[n] : null, r]);
  }
  toJs() {
    return { type: this.type(), names: this.names(), values: this.toArray() };
  }
};
var _t;
var wr = class extends te {
  constructor(e) {
    super(e, "logical", a(wr, _t));
  }
  getBoolean(e) {
    return this.get(e).toArray()[0];
  }
  toBoolean() {
    if (this.length !== 1)
      throw new Error("Can't convert atomic vector of length > 1 to a scalar JS value");
    let e = this.getBoolean(1);
    if (e === null)
      throw new Error("Can't convert missing value `NA` to a JS boolean");
    return e;
  }
  toTypedArray() {
    return new Int32Array(c.HEAP32.subarray(c._LOGICAL(this.ptr) / 4, c._LOGICAL(this.ptr) / 4 + this.length));
  }
  toArray() {
    let e = this.toTypedArray();
    return this.detectMissing().map((t, r) => t ? null : !!e[r]);
  }
};
var Y = wr;
_t = /* @__PURE__ */ new WeakMap(), u(Y, _t, (e) => {
  let t = c._LOGICAL(e), r = c.getValue(c._R_NaInt, "i32");
  return (n, o) => {
    c.setValue(t + 4 * o, n === null ? r : !!n, "i32");
  };
});
var St;
var xr = class extends te {
  constructor(e) {
    super(e, "integer", a(xr, St));
  }
  getNumber(e) {
    return this.get(e).toArray()[0];
  }
  toNumber() {
    if (this.length !== 1)
      throw new Error("Can't convert atomic vector of length > 1 to a scalar JS value");
    let e = this.getNumber(1);
    if (e === null)
      throw new Error("Can't convert missing value `NA` to a JS number");
    return e;
  }
  toTypedArray() {
    return new Int32Array(c.HEAP32.subarray(c._INTEGER(this.ptr) / 4, c._INTEGER(this.ptr) / 4 + this.length));
  }
};
var Et = xr;
St = /* @__PURE__ */ new WeakMap(), u(Et, St, (e) => {
  let t = c._INTEGER(e), r = c.getValue(c._R_NaInt, "i32");
  return (n, o) => {
    c.setValue(t + 4 * o, n === null ? r : Math.round(Number(n)), "i32");
  };
});
var kt;
var vr = class extends te {
  constructor(e) {
    super(e, "double", a(vr, kt));
  }
  getNumber(e) {
    return this.get(e).toArray()[0];
  }
  toNumber() {
    if (this.length !== 1)
      throw new Error("Can't convert atomic vector of length > 1 to a scalar JS value");
    let e = this.getNumber(1);
    if (e === null)
      throw new Error("Can't convert missing value `NA` to a JS number");
    return e;
  }
  toTypedArray() {
    return new Float64Array(c.HEAPF64.subarray(c._REAL(this.ptr) / 8, c._REAL(this.ptr) / 8 + this.length));
  }
};
var fe = vr;
kt = /* @__PURE__ */ new WeakMap(), u(fe, kt, (e) => {
  let t = c._REAL(e), r = c.getValue(c._R_NaReal, "double");
  return (n, o) => {
    c.setValue(t + 8 * o, n === null ? r : n, "double");
  };
});
var Mt;
var Er = class extends te {
  constructor(e) {
    super(e, "complex", a(Er, Mt));
  }
  getComplex(e) {
    return this.get(e).toArray()[0];
  }
  toComplex() {
    if (this.length !== 1)
      throw new Error("Can't convert atomic vector of length > 1 to a scalar JS value");
    let e = this.getComplex(1);
    if (e === null)
      throw new Error("Can't convert missing value `NA` to a JS object");
    return e;
  }
  toTypedArray() {
    return new Float64Array(c.HEAPF64.subarray(c._COMPLEX(this.ptr) / 8, c._COMPLEX(this.ptr) / 8 + 2 * this.length));
  }
  toArray() {
    let e = this.toTypedArray();
    return this.detectMissing().map((t, r) => t ? null : { re: e[2 * r], im: e[2 * r + 1] });
  }
};
var Fe = Er;
Mt = /* @__PURE__ */ new WeakMap(), u(Fe, Mt, (e) => {
  let t = c._COMPLEX(e), r = c.getValue(c._R_NaReal, "double");
  return (n, o) => {
    c.setValue(t + 8 * (2 * o), n === null ? r : n.re, "double"), c.setValue(t + 8 * (2 * o + 1), n === null ? r : n.im, "double");
  };
});
var Dt;
var Pr = class extends te {
  constructor(e) {
    super(e, "character", a(Pr, Dt));
  }
  getString(e) {
    return this.get(e).toArray()[0];
  }
  toString() {
    if (this.length !== 1)
      throw new Error("Can't convert atomic vector of length > 1 to a scalar JS value");
    let e = this.getString(1);
    if (e === null)
      throw new Error("Can't convert missing value `NA` to a JS string");
    return e;
  }
  toTypedArray() {
    return new Uint32Array(c.HEAPU32.subarray(c._STRING_PTR(this.ptr) / 4, c._STRING_PTR(this.ptr) / 4 + this.length));
  }
  toArray() {
    return this.detectMissing().map((e, t) => e ? null : c.UTF8ToString(c._R_CHAR(c._STRING_ELT(this.ptr, t))));
  }
};
var F = Pr;
Dt = /* @__PURE__ */ new WeakMap(), u(F, Dt, (e) => (t, r) => {
  t === null ? c._SET_STRING_ELT(e, r, k.naString.ptr) : c._SET_STRING_ELT(e, r, new Je(t).ptr);
});
var Wt;
var Tr = class extends te {
  constructor(e) {
    e instanceof ArrayBuffer && (e = new Uint8Array(e)), super(e, "raw", a(Tr, Wt));
  }
  getNumber(e) {
    return this.get(e).toArray()[0];
  }
  toNumber() {
    if (this.length !== 1)
      throw new Error("Can't convert atomic vector of length > 1 to a scalar JS value");
    let e = this.getNumber(1);
    if (e === null)
      throw new Error("Can't convert missing value `NA` to a JS number");
    return e;
  }
  toTypedArray() {
    return new Uint8Array(c.HEAPU8.subarray(c._RAW(this.ptr), c._RAW(this.ptr) + this.length));
  }
};
var qe = Tr;
Wt = /* @__PURE__ */ new WeakMap(), u(qe, Wt, (e) => {
  let t = c._RAW(e);
  return (r, n) => {
    c.setValue(t + n, Number(r), "i8");
  };
});
function me(s) {
  return mr(s) ? s : Array.isArray(s) || ArrayBuffer.isView(s) ? { names: null, values: s } : s && typeof s == "object" && !Ce(s) ? { names: Object.keys(s), values: Object.values(s) } : { names: null, values: [s] };
}
function is(s) {
  let e = { object: y, null: Pt, symbol: U, pairlist: ie, closure: ye, environment: Be, call: q, special: ye, builtin: ye, string: Je, logical: Y, integer: Et, double: fe, complex: Fe, character: F, list: Ve, raw: qe, function: ye, dataframe: ee };
  return s in e ? e[s] : y;
}
function Tt(s) {
  return s instanceof y;
}
function ls(s) {
  let e = ["logical", "integer", "double", "complex", "character"];
  return Tt(s) && e.includes(s.type()) || Tt(s) && s.isNa();
}
function cs(s) {
  return s === null || typeof s == "number" || typeof s == "boolean" || typeof s == "string" || Ce(s);
}
var k;
var Os = oe(zt());
var no = new TextEncoder();
var X;
var G;
var Ke;
var Jr;
X = /* @__PURE__ */ new WeakMap(), G = /* @__PURE__ */ new WeakMap(), Ke = /* @__PURE__ */ new WeakSet(), Jr = function() {
  a(this, X).push(new Promise((e) => {
    a(this, G).push(e);
  }));
};
function Qe(s, e, t) {
  return Us({ type: "response", data: { uuid: s, resp: e } }, t);
}
function Us(s, e) {
  return e && ns(s, e), s;
}
var Te;
var Ze;
Te = /* @__PURE__ */ new WeakMap(), Ze = /* @__PURE__ */ new WeakMap();
var Bs = oe(zt());
var lo = new TextDecoder("utf-8");
var _e;
var Se;
var Ye;
var et;
var ke;
_e = /* @__PURE__ */ new WeakMap(), Se = /* @__PURE__ */ new WeakMap(), Ye = /* @__PURE__ */ new WeakMap(), et = /* @__PURE__ */ new WeakMap(), ke = /* @__PURE__ */ new WeakMap();
var zr = new Int32Array(new ArrayBuffer(4));
m && (globalThis.Worker = B("worker_threads").Worker);
var Me;
var Zt;
var Vs;
var rt;
Me = /* @__PURE__ */ new WeakMap(), Zt = /* @__PURE__ */ new WeakSet(), Vs = function(t) {
  m ? (t.on("message", (r) => {
    a(this, rt).call(this, t, r);
  }), t.on("error", (r) => {
    console.error(r), this.reject(new A("An error occurred initialising the webR SharedBufferChannel worker."));
  })) : (t.onmessage = (r) => a(this, rt).call(this, t, r.data), t.onerror = (r) => {
    console.error(r), this.reject(new A("An error occurred initialising the webR SharedBufferChannel worker."));
  });
}, rt = /* @__PURE__ */ new WeakMap();
var ue;
var st;
var pe;
var nt;
ue = /* @__PURE__ */ new WeakMap(), st = /* @__PURE__ */ new WeakMap(), pe = /* @__PURE__ */ new WeakMap(), nt = /* @__PURE__ */ new WeakMap();
var sr = oe(zt());
m && (globalThis.Worker = B("worker_threads").Worker);
var De;
var de;
var We;
var er;
var Js;
var tr;
var Hs;
var rr;
var zs;
var ot;
De = /* @__PURE__ */ new WeakMap(), de = /* @__PURE__ */ new WeakMap(), We = /* @__PURE__ */ new WeakMap(), er = /* @__PURE__ */ new WeakSet(), Js = async function(t) {
  d(this, de, await navigator.serviceWorker.register(t)), await navigator.serviceWorker.ready, window.addEventListener("beforeunload", () => {
    var n;
    (n = a(this, de)) == null || n.unregister();
  });
  let r = await new Promise((n) => {
    navigator.serviceWorker.addEventListener("message", function o(i) {
      i.data.type === "registration-successful" && (navigator.serviceWorker.removeEventListener("message", o), n(i.data.clientId));
    }), this.activeRegistration().postMessage({ type: "register-client-main" });
  });
  return navigator.serviceWorker.addEventListener("message", (n) => {
    E(this, tr, Hs).call(this, n);
  }), r;
}, tr = /* @__PURE__ */ new WeakSet(), Hs = async function(t) {
  if (t.data.type === "request") {
    let r = t.data.data, n = a(this, De).get(r);
    if (!n)
      throw new P("Request not found during service worker XHR request");
    switch (a(this, De).delete(r), n.type) {
      case "read": {
        let o = await this.inputQueue.get();
        this.activeRegistration().postMessage({ type: "wasm-webr-fetch-response", uuid: r, response: Qe(r, o) });
        break;
      }
      case "interrupt": {
        let o = a(this, We);
        this.activeRegistration().postMessage({ type: "wasm-webr-fetch-response", uuid: r, response: Qe(r, o) }), this.inputQueue.reset(), d(this, We, false);
        break;
      }
      default:
        throw new P(`Unsupported request type '${n.type}'.`);
    }
    return;
  }
}, rr = /* @__PURE__ */ new WeakSet(), zs = function(t) {
  m ? (t.on("message", (r) => {
    a(this, ot).call(this, t, r);
  }), t.on("error", (r) => {
    console.error(r), this.reject(new A("An error occurred initialising the webR ServiceWorkerChannel worker."));
  })) : (t.onmessage = (r) => a(this, ot).call(this, t, r.data), t.onerror = (r) => {
    console.error(r), this.reject(new A("An error occurred initialising the webR ServiceWorkerChannel worker."));
  });
}, ot = /* @__PURE__ */ new WeakMap();
var Ae;
var at;
var it;
var lt;
var ct;
var ut;
Ae = /* @__PURE__ */ new WeakMap(), at = /* @__PURE__ */ new WeakMap(), it = /* @__PURE__ */ new WeakMap(), lt = /* @__PURE__ */ new WeakMap(), ct = /* @__PURE__ */ new WeakMap(), ut = /* @__PURE__ */ new WeakMap();
m && (globalThis.Worker = B("worker_threads").Worker);
var Oe;
var nr;
var Xs;
var dt;
Oe = /* @__PURE__ */ new WeakMap(), nr = /* @__PURE__ */ new WeakSet(), Xs = function(t) {
  m ? (t.on("message", (r) => {
    a(this, dt).call(this, t, r);
  }), t.on("error", (r) => {
    console.error(r), this.reject(new A("An error occurred initialising the webR PostMessageChannel worker."));
  })) : (t.onmessage = (r) => a(this, dt).call(this, t, r.data), t.onerror = (r) => {
    console.error(r), this.reject(new A("An error occurred initialising the webR PostMessageChannel worker."));
  });
}, dt = /* @__PURE__ */ new WeakMap();
var Ie;
var Ue;
var ht;
var he;
var or;
Ie = /* @__PURE__ */ new WeakMap(), Ue = /* @__PURE__ */ new WeakMap(), ht = /* @__PURE__ */ new WeakMap(), he = /* @__PURE__ */ new WeakMap(), or = /* @__PURE__ */ new WeakMap();
var O = { Automatic: 0, SharedArrayBuffer: 1, ServiceWorker: 2, PostMessage: 3 };
var $s = m ? __dirname + "/" : "https://webr.r-wasm.org/v0.4.2/";
var Ks = "https://repo.r-wasm.org";
var Kr = "0.4.2";
var yt;
var ft;
var Rt;
var mt;
var gt;
var ar;
var ir;
var lr;
var cr;
var ur;
var pr;
var Ys;
yt = /* @__PURE__ */ new WeakMap(), ft = /* @__PURE__ */ new WeakMap(), Rt = /* @__PURE__ */ new WeakMap(), mt = /* @__PURE__ */ new WeakMap(), gt = /* @__PURE__ */ new WeakMap(), ar = /* @__PURE__ */ new WeakMap(), ir = /* @__PURE__ */ new WeakMap(), lr = /* @__PURE__ */ new WeakMap(), cr = /* @__PURE__ */ new WeakMap(), ur = /* @__PURE__ */ new WeakMap(), pr = /* @__PURE__ */ new WeakSet(), Ys = async function() {
  for (; ; ) {
    let e = await this.webR.read();
    switch (e.type) {
      case "stdout":
        a(this, yt).call(this, e.data);
        break;
      case "stderr":
        a(this, ft).call(this, e.data);
        break;
      case "prompt":
        a(this, Rt).call(this, e.data);
        break;
      case "canvas":
        e.data.event === "canvasImage" ? a(this, mt).call(this, e.data.image) : e.data.event === "canvasNewPage" && a(this, gt).call(this);
        break;
      case "closed":
        return;
      default:
        console.warn(`Unhandled output type for webR Console: ${e.type}.`);
    }
  }
};
var yo = { FONTCONFIG_PATH: "/etc/fonts", R_HOME: "/usr/lib/R", R_ENABLE_JIT: "0", WEBR: "1", WEBR_VERSION: Kr };
var en = { RArgs: [], REnv: yo, baseUrl: $s, serviceWorkerUrl: "", repoUrl: Ks, homedir: "/home/web_user", interactive: true, channelType: O.Automatic, createLazyFilesystem: true };
var R;
var bt;
var yr;
var tn;
R = /* @__PURE__ */ new WeakMap(), bt = /* @__PURE__ */ new WeakMap(), yr = /* @__PURE__ */ new WeakSet(), tn = async function() {
  for (; ; ) {
    let e = await a(this, R).readSystem();
    switch (e.type) {
      case "setTimeoutWasm":
        setTimeout((t, r) => {
          this.invokeWasmFunction(t, ...r);
        }, e.data.delay, e.data.ptr, e.data.args);
        break;
      case "console.log":
        console.log(e.data);
        break;
      case "console.warn":
        console.warn(e.data);
        break;
      case "console.error":
        console.error(e.data);
        break;
      case "close":
        a(this, R).close();
        break;
      default:
        throw new I("Unknown system message type `" + e.type + "`");
    }
  }
};
var g;
var f;
var wt;
g = /* @__PURE__ */ new WeakMap(), f = /* @__PURE__ */ new WeakMap(), wt = /* @__PURE__ */ new WeakMap();

// src/messageporthttp.ts
async function fetchASGI(client, resource, init, filter = (bodyChunk) => bodyChunk) {
  if (typeof resource === "string" || typeof init !== "undefined") {
    resource = new Request(resource, init);
  }
  const channel = new MessageChannel();
  const clientPort = channel.port1;
  client.postMessage(
    {
      type: "makeRequest",
      scope: reqToASGI(resource)
    },
    [channel.port2]
  );
  const blob = await resource.blob();
  if (!blob.size) {
    clientPort.postMessage({
      type: "http.request",
      more_body: false
    });
  } else {
    const reader = blob.stream().getReader();
    try {
      while (true) {
        const { value: theChunk, done } = await reader.read();
        clientPort.postMessage({
          type: "http.request",
          body: theChunk,
          more_body: !done
        });
        if (done) {
          break;
        }
      }
    } finally {
      reader.releaseLock();
    }
  }
  return new Promise((resolve) => {
    let streamController;
    const readableStream = new ReadableStream({
      start(controller) {
        streamController = controller;
      },
      cancel(reason) {
      }
    });
    let response;
    clientPort.addEventListener("message", (event) => {
      const msg = event.data;
      if (msg.type === "http.response.start") {
        response = asgiToRes(msg, readableStream);
        resolve(response);
      } else if (msg.type === "http.response.body") {
        if (msg.body) {
          streamController.enqueue(filter(msg.body, response));
        }
        if (!msg.more_body) {
          streamController.close();
          clientPort.close();
        }
      } else {
        throw new Error("Unexpected event type from clientPort: " + msg.type);
      }
    });
    clientPort.start();
  });
}
function headersToASGI(headers) {
  const result = [];
  for (const [key, value] of headers.entries()) {
    result.push([key, value]);
  }
  return result;
}
function reqToASGI(req) {
  const url = new URL(req.url);
  return {
    type: "http",
    asgi: {
      version: "3.0",
      spec_version: "2.1"
    },
    http_version: "1.1",
    method: req.method,
    scheme: url.protocol.replace(/:$/, ""),
    path: url.pathname,
    query_string: url.search.replace(/^\?/, ""),
    root_path: "",
    headers: headersToASGI(req.headers)
  };
}
function asgiToRes(res, body) {
  return new Response(body, {
    headers: res.headers,
    status: res.status
  });
}

// src/shinylive-sw.ts
var useCaching = false;
var cacheName = "::shinyliveServiceworker";
var version = "v9";
function addCoiHeaders(resp) {
  const headers = new Headers(resp.headers);
  headers.set("Cross-Origin-Embedder-Policy", "credentialless");
  headers.set("Cross-Origin-Resource-Policy", "cross-origin");
  headers.set("Cross-Origin-Opener-Policy", "same-origin");
  return new Response(resp.body, {
    status: resp.status,
    statusText: resp.statusText,
    headers
  });
}
self.addEventListener("install", (event) => {
  event.waitUntil(
    Promise.all([self.skipWaiting(), caches.open(version + cacheName)])
  );
});
self.addEventListener("activate", function(event) {
  event.waitUntil(
    (async () => {
      await self.clients.claim();
      const keys = await caches.keys();
      return Promise.all(
        keys.filter(function(key) {
          return key.indexOf(version + cacheName) !== 0;
        }).map(function(key) {
          return caches.delete(key);
        })
      );
    })()
  );
});
self.addEventListener("fetch", function(event) {
  const request = event.request;
  const url = new URL(request.url);
  if (self.location.origin !== url.origin)
    return;
  if (url.pathname == "/esbuild")
    return;
  const base_path = dirname(self.location.pathname);
  if (url.pathname == `${base_path}/shinylive-inject-socket.js`) {
    event.respondWith(
      new Response(shinylive_inject_socket_default, {
        headers: { "Content-Type": "text/javascript" },
        status: 200
      })
    );
    return;
  }
  const coiRequested = url.searchParams.get("coi") === "1" || request.referrer.includes("coi=1");
  const appPathRegex = /.*\/(app_[^/]+\/)/;
  const m_appPath = appPathRegex.exec(url.pathname);
  if (m_appPath) {
    event.respondWith(
      (async () => {
        let pollCount = 5;
        while (!apps[m_appPath[1]]) {
          if (pollCount == 0) {
            return new Response(
              `Couldn't find parent page for ${url}. This may be because the Service Worker has updated. Try reloading the page.`,
              {
                status: 404
              }
            );
          }
          console.log("App URL not registered. Waiting 50ms.");
          await sleep(50);
          pollCount--;
        }
        url.pathname = url.pathname.replace(appPathRegex, "/");
        const isAppRoot = url.pathname === "/";
        const filter = isAppRoot ? injectSocketFilter : identityFilter;
        const blob = await request.blob();
        const resp = await fetchASGI(
          apps[m_appPath[1]],
          new Request(url.toString(), {
            method: request.method,
            headers: request.headers,
            body: request.method === "GET" || request.method === "HEAD" ? void 0 : blob,
            credentials: request.credentials,
            cache: request.cache,
            redirect: request.redirect,
            referrer: request.referrer
          }),
          void 0,
          filter
        );
        if (coiRequested) {
          return addCoiHeaders(resp);
        } else {
          return resp;
        }
      })()
    );
    return;
  }
  if (request.method !== "GET") {
    return;
  }
  if (useCaching) {
    event.respondWith(
      (async () => {
        const cachedResponse = await caches.match(request);
        if (cachedResponse) {
          return cachedResponse;
        }
        try {
          const networkResponse = addCoiHeaders(await fetch(request));
          const baseUrl = self.location.origin + dirname(self.location.pathname);
          if (request.url.startsWith(baseUrl + "/shinylive/") || request.url === baseUrl + "/favicon.ico") {
            const cache = await caches.open(version + cacheName);
            await cache.put(request, networkResponse.clone());
          }
          return networkResponse;
        } catch {
          return new Response("Failed to find in cache, or fetch.", {
            status: 404
          });
        }
      })()
    );
    return;
  }
  if (coiRequested) {
    event.respondWith(
      (async () => {
        const resp = await fetch(request);
        return addCoiHeaders(resp);
      })()
    );
  }
});
var apps = {};
(async () => {
  const allClients = await self.clients.matchAll();
  for (const client of allClients) {
    client.postMessage({
      type: "serviceworkerStart"
    });
  }
})();
self.addEventListener("message", (event) => {
  const msg = event.data;
  if (msg.type === "configureProxyPath") {
    const path = msg.path;
    const port = event.ports[0];
    apps[path] = port;
  }
});
function identityFilter(bodyChunk, response) {
  return bodyChunk;
}
function injectSocketFilter(bodyChunk, response) {
  const contentType = response.headers.get("content-type");
  if (contentType && /^text\/html(;|$)/.test(contentType)) {
    const bodyChunkStr = uint8ArrayToString(bodyChunk);
    const base_path = dirname(self.location.pathname);
    const newStr = bodyChunkStr.replace(
      /<\/head>/,
      `<script src="${base_path}/shinylive-inject-socket.js" type="module"><\/script>
</head>`
    );
    const newChunk = Uint8Array.from(
      newStr.split("").map((s) => s.charCodeAt(0))
    );
    return newChunk;
  }
  return bodyChunk;
}
