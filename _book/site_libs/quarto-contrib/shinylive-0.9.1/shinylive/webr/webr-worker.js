"use strict";
var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __commonJS = (cb, mod) => function __require() {
  return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));
var __accessCheck = (obj, member, msg) => {
  if (!member.has(obj))
    throw TypeError("Cannot " + msg);
};
var __privateGet = (obj, member, getter) => {
  __accessCheck(obj, member, "read from private field");
  return getter ? getter.call(obj) : member.get(obj);
};
var __privateAdd = (obj, member, value) => {
  if (member.has(obj))
    throw TypeError("Cannot add the same private member more than once");
  member instanceof WeakSet ? member.add(obj) : member.set(obj, value);
};
var __privateSet = (obj, member, value, setter) => {
  __accessCheck(obj, member, "write to private field");
  setter ? setter.call(obj, value) : member.set(obj, value);
  return value;
};
var __privateWrapper = (obj, member, setter, getter) => ({
  set _(value) {
    __privateSet(obj, member, value, setter);
  },
  get _() {
    return __privateGet(obj, member, getter);
  }
});
var __privateMethod = (obj, member, method) => {
  __accessCheck(obj, member, "access private method");
  return method;
};

// node_modules/@msgpack/msgpack/dist/utils/int.js
var require_int = __commonJS({
  "node_modules/@msgpack/msgpack/dist/utils/int.js"(exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    exports.getUint64 = exports.getInt64 = exports.setInt64 = exports.setUint64 = exports.UINT32_MAX = void 0;
    exports.UINT32_MAX = 4294967295;
    function setUint64(view, offset, value) {
      const high = value / 4294967296;
      const low = value;
      view.setUint32(offset, high);
      view.setUint32(offset + 4, low);
    }
    exports.setUint64 = setUint64;
    function setInt64(view, offset, value) {
      const high = Math.floor(value / 4294967296);
      const low = value;
      view.setUint32(offset, high);
      view.setUint32(offset + 4, low);
    }
    exports.setInt64 = setInt64;
    function getInt64(view, offset) {
      const high = view.getInt32(offset);
      const low = view.getUint32(offset + 4);
      return high * 4294967296 + low;
    }
    exports.getInt64 = getInt64;
    function getUint64(view, offset) {
      const high = view.getUint32(offset);
      const low = view.getUint32(offset + 4);
      return high * 4294967296 + low;
    }
    exports.getUint64 = getUint64;
  }
});

// node_modules/@msgpack/msgpack/dist/utils/utf8.js
var require_utf8 = __commonJS({
  "node_modules/@msgpack/msgpack/dist/utils/utf8.js"(exports) {
    "use strict";
    var _a;
    var _b;
    var _c;
    Object.defineProperty(exports, "__esModule", { value: true });
    exports.utf8DecodeTD = exports.TEXT_DECODER_THRESHOLD = exports.utf8DecodeJs = exports.utf8EncodeTE = exports.TEXT_ENCODER_THRESHOLD = exports.utf8EncodeJs = exports.utf8Count = void 0;
    var int_1 = require_int();
    var TEXT_ENCODING_AVAILABLE = (typeof process === "undefined" || ((_a = process === null || process === void 0 ? void 0 : process.env) === null || _a === void 0 ? void 0 : _a["TEXT_ENCODING"]) !== "never") && typeof TextEncoder !== "undefined" && typeof TextDecoder !== "undefined";
    function utf8Count(str) {
      const strLength = str.length;
      let byteLength = 0;
      let pos = 0;
      while (pos < strLength) {
        let value = str.charCodeAt(pos++);
        if ((value & 4294967168) === 0) {
          byteLength++;
          continue;
        } else if ((value & 4294965248) === 0) {
          byteLength += 2;
        } else {
          if (value >= 55296 && value <= 56319) {
            if (pos < strLength) {
              const extra = str.charCodeAt(pos);
              if ((extra & 64512) === 56320) {
                ++pos;
                value = ((value & 1023) << 10) + (extra & 1023) + 65536;
              }
            }
          }
          if ((value & 4294901760) === 0) {
            byteLength += 3;
          } else {
            byteLength += 4;
          }
        }
      }
      return byteLength;
    }
    exports.utf8Count = utf8Count;
    function utf8EncodeJs(str, output, outputOffset) {
      const strLength = str.length;
      let offset = outputOffset;
      let pos = 0;
      while (pos < strLength) {
        let value = str.charCodeAt(pos++);
        if ((value & 4294967168) === 0) {
          output[offset++] = value;
          continue;
        } else if ((value & 4294965248) === 0) {
          output[offset++] = value >> 6 & 31 | 192;
        } else {
          if (value >= 55296 && value <= 56319) {
            if (pos < strLength) {
              const extra = str.charCodeAt(pos);
              if ((extra & 64512) === 56320) {
                ++pos;
                value = ((value & 1023) << 10) + (extra & 1023) + 65536;
              }
            }
          }
          if ((value & 4294901760) === 0) {
            output[offset++] = value >> 12 & 15 | 224;
            output[offset++] = value >> 6 & 63 | 128;
          } else {
            output[offset++] = value >> 18 & 7 | 240;
            output[offset++] = value >> 12 & 63 | 128;
            output[offset++] = value >> 6 & 63 | 128;
          }
        }
        output[offset++] = value & 63 | 128;
      }
    }
    exports.utf8EncodeJs = utf8EncodeJs;
    var sharedTextEncoder = TEXT_ENCODING_AVAILABLE ? new TextEncoder() : void 0;
    exports.TEXT_ENCODER_THRESHOLD = !TEXT_ENCODING_AVAILABLE ? int_1.UINT32_MAX : typeof process !== "undefined" && ((_b = process === null || process === void 0 ? void 0 : process.env) === null || _b === void 0 ? void 0 : _b["TEXT_ENCODING"]) !== "force" ? 200 : 0;
    function utf8EncodeTEencode(str, output, outputOffset) {
      output.set(sharedTextEncoder.encode(str), outputOffset);
    }
    function utf8EncodeTEencodeInto(str, output, outputOffset) {
      sharedTextEncoder.encodeInto(str, output.subarray(outputOffset));
    }
    exports.utf8EncodeTE = (sharedTextEncoder === null || sharedTextEncoder === void 0 ? void 0 : sharedTextEncoder.encodeInto) ? utf8EncodeTEencodeInto : utf8EncodeTEencode;
    var CHUNK_SIZE = 4096;
    function utf8DecodeJs(bytes, inputOffset, byteLength) {
      let offset = inputOffset;
      const end = offset + byteLength;
      const units = [];
      let result = "";
      while (offset < end) {
        const byte1 = bytes[offset++];
        if ((byte1 & 128) === 0) {
          units.push(byte1);
        } else if ((byte1 & 224) === 192) {
          const byte2 = bytes[offset++] & 63;
          units.push((byte1 & 31) << 6 | byte2);
        } else if ((byte1 & 240) === 224) {
          const byte2 = bytes[offset++] & 63;
          const byte3 = bytes[offset++] & 63;
          units.push((byte1 & 31) << 12 | byte2 << 6 | byte3);
        } else if ((byte1 & 248) === 240) {
          const byte2 = bytes[offset++] & 63;
          const byte3 = bytes[offset++] & 63;
          const byte4 = bytes[offset++] & 63;
          let unit = (byte1 & 7) << 18 | byte2 << 12 | byte3 << 6 | byte4;
          if (unit > 65535) {
            unit -= 65536;
            units.push(unit >>> 10 & 1023 | 55296);
            unit = 56320 | unit & 1023;
          }
          units.push(unit);
        } else {
          units.push(byte1);
        }
        if (units.length >= CHUNK_SIZE) {
          result += String.fromCharCode(...units);
          units.length = 0;
        }
      }
      if (units.length > 0) {
        result += String.fromCharCode(...units);
      }
      return result;
    }
    exports.utf8DecodeJs = utf8DecodeJs;
    var sharedTextDecoder = TEXT_ENCODING_AVAILABLE ? new TextDecoder() : null;
    exports.TEXT_DECODER_THRESHOLD = !TEXT_ENCODING_AVAILABLE ? int_1.UINT32_MAX : typeof process !== "undefined" && ((_c = process === null || process === void 0 ? void 0 : process.env) === null || _c === void 0 ? void 0 : _c["TEXT_DECODER"]) !== "force" ? 200 : 0;
    function utf8DecodeTD(bytes, inputOffset, byteLength) {
      const stringBytes = bytes.subarray(inputOffset, inputOffset + byteLength);
      return sharedTextDecoder.decode(stringBytes);
    }
    exports.utf8DecodeTD = utf8DecodeTD;
  }
});

// node_modules/@msgpack/msgpack/dist/ExtData.js
var require_ExtData = __commonJS({
  "node_modules/@msgpack/msgpack/dist/ExtData.js"(exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    exports.ExtData = void 0;
    var ExtData = class {
      constructor(type, data) {
        this.type = type;
        this.data = data;
      }
    };
    exports.ExtData = ExtData;
  }
});

// node_modules/@msgpack/msgpack/dist/DecodeError.js
var require_DecodeError = __commonJS({
  "node_modules/@msgpack/msgpack/dist/DecodeError.js"(exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    exports.DecodeError = void 0;
    var DecodeError = class extends Error {
      constructor(message) {
        super(message);
        const proto = Object.create(DecodeError.prototype);
        Object.setPrototypeOf(this, proto);
        Object.defineProperty(this, "name", {
          configurable: true,
          enumerable: false,
          value: DecodeError.name
        });
      }
    };
    exports.DecodeError = DecodeError;
  }
});

// node_modules/@msgpack/msgpack/dist/timestamp.js
var require_timestamp = __commonJS({
  "node_modules/@msgpack/msgpack/dist/timestamp.js"(exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    exports.timestampExtension = exports.decodeTimestampExtension = exports.decodeTimestampToTimeSpec = exports.encodeTimestampExtension = exports.encodeDateToTimeSpec = exports.encodeTimeSpecToTimestamp = exports.EXT_TIMESTAMP = void 0;
    var DecodeError_1 = require_DecodeError();
    var int_1 = require_int();
    exports.EXT_TIMESTAMP = -1;
    var TIMESTAMP32_MAX_SEC = 4294967296 - 1;
    var TIMESTAMP64_MAX_SEC = 17179869184 - 1;
    function encodeTimeSpecToTimestamp({ sec, nsec }) {
      if (sec >= 0 && nsec >= 0 && sec <= TIMESTAMP64_MAX_SEC) {
        if (nsec === 0 && sec <= TIMESTAMP32_MAX_SEC) {
          const rv = new Uint8Array(4);
          const view = new DataView(rv.buffer);
          view.setUint32(0, sec);
          return rv;
        } else {
          const secHigh = sec / 4294967296;
          const secLow = sec & 4294967295;
          const rv = new Uint8Array(8);
          const view = new DataView(rv.buffer);
          view.setUint32(0, nsec << 2 | secHigh & 3);
          view.setUint32(4, secLow);
          return rv;
        }
      } else {
        const rv = new Uint8Array(12);
        const view = new DataView(rv.buffer);
        view.setUint32(0, nsec);
        (0, int_1.setInt64)(view, 4, sec);
        return rv;
      }
    }
    exports.encodeTimeSpecToTimestamp = encodeTimeSpecToTimestamp;
    function encodeDateToTimeSpec(date) {
      const msec = date.getTime();
      const sec = Math.floor(msec / 1e3);
      const nsec = (msec - sec * 1e3) * 1e6;
      const nsecInSec = Math.floor(nsec / 1e9);
      return {
        sec: sec + nsecInSec,
        nsec: nsec - nsecInSec * 1e9
      };
    }
    exports.encodeDateToTimeSpec = encodeDateToTimeSpec;
    function encodeTimestampExtension(object) {
      if (object instanceof Date) {
        const timeSpec = encodeDateToTimeSpec(object);
        return encodeTimeSpecToTimestamp(timeSpec);
      } else {
        return null;
      }
    }
    exports.encodeTimestampExtension = encodeTimestampExtension;
    function decodeTimestampToTimeSpec(data) {
      const view = new DataView(data.buffer, data.byteOffset, data.byteLength);
      switch (data.byteLength) {
        case 4: {
          const sec = view.getUint32(0);
          const nsec = 0;
          return { sec, nsec };
        }
        case 8: {
          const nsec30AndSecHigh2 = view.getUint32(0);
          const secLow32 = view.getUint32(4);
          const sec = (nsec30AndSecHigh2 & 3) * 4294967296 + secLow32;
          const nsec = nsec30AndSecHigh2 >>> 2;
          return { sec, nsec };
        }
        case 12: {
          const sec = (0, int_1.getInt64)(view, 4);
          const nsec = view.getUint32(0);
          return { sec, nsec };
        }
        default:
          throw new DecodeError_1.DecodeError(`Unrecognized data size for timestamp (expected 4, 8, or 12): ${data.length}`);
      }
    }
    exports.decodeTimestampToTimeSpec = decodeTimestampToTimeSpec;
    function decodeTimestampExtension(data) {
      const timeSpec = decodeTimestampToTimeSpec(data);
      return new Date(timeSpec.sec * 1e3 + timeSpec.nsec / 1e6);
    }
    exports.decodeTimestampExtension = decodeTimestampExtension;
    exports.timestampExtension = {
      type: exports.EXT_TIMESTAMP,
      encode: encodeTimestampExtension,
      decode: decodeTimestampExtension
    };
  }
});

// node_modules/@msgpack/msgpack/dist/ExtensionCodec.js
var require_ExtensionCodec = __commonJS({
  "node_modules/@msgpack/msgpack/dist/ExtensionCodec.js"(exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    exports.ExtensionCodec = void 0;
    var ExtData_1 = require_ExtData();
    var timestamp_1 = require_timestamp();
    var ExtensionCodec = class {
      constructor() {
        this.builtInEncoders = [];
        this.builtInDecoders = [];
        this.encoders = [];
        this.decoders = [];
        this.register(timestamp_1.timestampExtension);
      }
      register({ type, encode: encode3, decode: decode3 }) {
        if (type >= 0) {
          this.encoders[type] = encode3;
          this.decoders[type] = decode3;
        } else {
          const index = 1 + type;
          this.builtInEncoders[index] = encode3;
          this.builtInDecoders[index] = decode3;
        }
      }
      tryToEncode(object, context) {
        for (let i = 0; i < this.builtInEncoders.length; i++) {
          const encodeExt = this.builtInEncoders[i];
          if (encodeExt != null) {
            const data = encodeExt(object, context);
            if (data != null) {
              const type = -1 - i;
              return new ExtData_1.ExtData(type, data);
            }
          }
        }
        for (let i = 0; i < this.encoders.length; i++) {
          const encodeExt = this.encoders[i];
          if (encodeExt != null) {
            const data = encodeExt(object, context);
            if (data != null) {
              const type = i;
              return new ExtData_1.ExtData(type, data);
            }
          }
        }
        if (object instanceof ExtData_1.ExtData) {
          return object;
        }
        return null;
      }
      decode(data, type, context) {
        const decodeExt = type < 0 ? this.builtInDecoders[-1 - type] : this.decoders[type];
        if (decodeExt) {
          return decodeExt(data, type, context);
        } else {
          return new ExtData_1.ExtData(type, data);
        }
      }
    };
    exports.ExtensionCodec = ExtensionCodec;
    ExtensionCodec.defaultCodec = new ExtensionCodec();
  }
});

// node_modules/@msgpack/msgpack/dist/utils/typedArrays.js
var require_typedArrays = __commonJS({
  "node_modules/@msgpack/msgpack/dist/utils/typedArrays.js"(exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    exports.createDataView = exports.ensureUint8Array = void 0;
    function ensureUint8Array(buffer) {
      if (buffer instanceof Uint8Array) {
        return buffer;
      } else if (ArrayBuffer.isView(buffer)) {
        return new Uint8Array(buffer.buffer, buffer.byteOffset, buffer.byteLength);
      } else if (buffer instanceof ArrayBuffer) {
        return new Uint8Array(buffer);
      } else {
        return Uint8Array.from(buffer);
      }
    }
    exports.ensureUint8Array = ensureUint8Array;
    function createDataView(buffer) {
      if (buffer instanceof ArrayBuffer) {
        return new DataView(buffer);
      }
      const bufferView = ensureUint8Array(buffer);
      return new DataView(bufferView.buffer, bufferView.byteOffset, bufferView.byteLength);
    }
    exports.createDataView = createDataView;
  }
});

// node_modules/@msgpack/msgpack/dist/Encoder.js
var require_Encoder = __commonJS({
  "node_modules/@msgpack/msgpack/dist/Encoder.js"(exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    exports.Encoder = exports.DEFAULT_INITIAL_BUFFER_SIZE = exports.DEFAULT_MAX_DEPTH = void 0;
    var utf8_1 = require_utf8();
    var ExtensionCodec_1 = require_ExtensionCodec();
    var int_1 = require_int();
    var typedArrays_1 = require_typedArrays();
    exports.DEFAULT_MAX_DEPTH = 100;
    exports.DEFAULT_INITIAL_BUFFER_SIZE = 2048;
    var Encoder = class {
      constructor(extensionCodec = ExtensionCodec_1.ExtensionCodec.defaultCodec, context = void 0, maxDepth = exports.DEFAULT_MAX_DEPTH, initialBufferSize = exports.DEFAULT_INITIAL_BUFFER_SIZE, sortKeys = false, forceFloat32 = false, ignoreUndefined = false, forceIntegerToFloat = false) {
        this.extensionCodec = extensionCodec;
        this.context = context;
        this.maxDepth = maxDepth;
        this.initialBufferSize = initialBufferSize;
        this.sortKeys = sortKeys;
        this.forceFloat32 = forceFloat32;
        this.ignoreUndefined = ignoreUndefined;
        this.forceIntegerToFloat = forceIntegerToFloat;
        this.pos = 0;
        this.view = new DataView(new ArrayBuffer(this.initialBufferSize));
        this.bytes = new Uint8Array(this.view.buffer);
      }
      reinitializeState() {
        this.pos = 0;
      }
      /**
       * This is almost equivalent to {@link Encoder#encode}, but it returns an reference of the encoder's internal buffer and thus much faster than {@link Encoder#encode}.
       *
       * @returns Encodes the object and returns a shared reference the encoder's internal buffer.
       */
      encodeSharedRef(object) {
        this.reinitializeState();
        this.doEncode(object, 1);
        return this.bytes.subarray(0, this.pos);
      }
      /**
       * @returns Encodes the object and returns a copy of the encoder's internal buffer.
       */
      encode(object) {
        this.reinitializeState();
        this.doEncode(object, 1);
        return this.bytes.slice(0, this.pos);
      }
      doEncode(object, depth) {
        if (depth > this.maxDepth) {
          throw new Error(`Too deep objects in depth ${depth}`);
        }
        if (object == null) {
          this.encodeNil();
        } else if (typeof object === "boolean") {
          this.encodeBoolean(object);
        } else if (typeof object === "number") {
          this.encodeNumber(object);
        } else if (typeof object === "string") {
          this.encodeString(object);
        } else {
          this.encodeObject(object, depth);
        }
      }
      ensureBufferSizeToWrite(sizeToWrite) {
        const requiredSize = this.pos + sizeToWrite;
        if (this.view.byteLength < requiredSize) {
          this.resizeBuffer(requiredSize * 2);
        }
      }
      resizeBuffer(newSize) {
        const newBuffer = new ArrayBuffer(newSize);
        const newBytes = new Uint8Array(newBuffer);
        const newView = new DataView(newBuffer);
        newBytes.set(this.bytes);
        this.view = newView;
        this.bytes = newBytes;
      }
      encodeNil() {
        this.writeU8(192);
      }
      encodeBoolean(object) {
        if (object === false) {
          this.writeU8(194);
        } else {
          this.writeU8(195);
        }
      }
      encodeNumber(object) {
        if (Number.isSafeInteger(object) && !this.forceIntegerToFloat) {
          if (object >= 0) {
            if (object < 128) {
              this.writeU8(object);
            } else if (object < 256) {
              this.writeU8(204);
              this.writeU8(object);
            } else if (object < 65536) {
              this.writeU8(205);
              this.writeU16(object);
            } else if (object < 4294967296) {
              this.writeU8(206);
              this.writeU32(object);
            } else {
              this.writeU8(207);
              this.writeU64(object);
            }
          } else {
            if (object >= -32) {
              this.writeU8(224 | object + 32);
            } else if (object >= -128) {
              this.writeU8(208);
              this.writeI8(object);
            } else if (object >= -32768) {
              this.writeU8(209);
              this.writeI16(object);
            } else if (object >= -2147483648) {
              this.writeU8(210);
              this.writeI32(object);
            } else {
              this.writeU8(211);
              this.writeI64(object);
            }
          }
        } else {
          if (this.forceFloat32) {
            this.writeU8(202);
            this.writeF32(object);
          } else {
            this.writeU8(203);
            this.writeF64(object);
          }
        }
      }
      writeStringHeader(byteLength) {
        if (byteLength < 32) {
          this.writeU8(160 + byteLength);
        } else if (byteLength < 256) {
          this.writeU8(217);
          this.writeU8(byteLength);
        } else if (byteLength < 65536) {
          this.writeU8(218);
          this.writeU16(byteLength);
        } else if (byteLength < 4294967296) {
          this.writeU8(219);
          this.writeU32(byteLength);
        } else {
          throw new Error(`Too long string: ${byteLength} bytes in UTF-8`);
        }
      }
      encodeString(object) {
        const maxHeaderSize = 1 + 4;
        const strLength = object.length;
        if (strLength > utf8_1.TEXT_ENCODER_THRESHOLD) {
          const byteLength = (0, utf8_1.utf8Count)(object);
          this.ensureBufferSizeToWrite(maxHeaderSize + byteLength);
          this.writeStringHeader(byteLength);
          (0, utf8_1.utf8EncodeTE)(object, this.bytes, this.pos);
          this.pos += byteLength;
        } else {
          const byteLength = (0, utf8_1.utf8Count)(object);
          this.ensureBufferSizeToWrite(maxHeaderSize + byteLength);
          this.writeStringHeader(byteLength);
          (0, utf8_1.utf8EncodeJs)(object, this.bytes, this.pos);
          this.pos += byteLength;
        }
      }
      encodeObject(object, depth) {
        const ext = this.extensionCodec.tryToEncode(object, this.context);
        if (ext != null) {
          this.encodeExtension(ext);
        } else if (Array.isArray(object)) {
          this.encodeArray(object, depth);
        } else if (ArrayBuffer.isView(object)) {
          this.encodeBinary(object);
        } else if (typeof object === "object") {
          this.encodeMap(object, depth);
        } else {
          throw new Error(`Unrecognized object: ${Object.prototype.toString.apply(object)}`);
        }
      }
      encodeBinary(object) {
        const size = object.byteLength;
        if (size < 256) {
          this.writeU8(196);
          this.writeU8(size);
        } else if (size < 65536) {
          this.writeU8(197);
          this.writeU16(size);
        } else if (size < 4294967296) {
          this.writeU8(198);
          this.writeU32(size);
        } else {
          throw new Error(`Too large binary: ${size}`);
        }
        const bytes = (0, typedArrays_1.ensureUint8Array)(object);
        this.writeU8a(bytes);
      }
      encodeArray(object, depth) {
        const size = object.length;
        if (size < 16) {
          this.writeU8(144 + size);
        } else if (size < 65536) {
          this.writeU8(220);
          this.writeU16(size);
        } else if (size < 4294967296) {
          this.writeU8(221);
          this.writeU32(size);
        } else {
          throw new Error(`Too large array: ${size}`);
        }
        for (const item of object) {
          this.doEncode(item, depth + 1);
        }
      }
      countWithoutUndefined(object, keys) {
        let count = 0;
        for (const key of keys) {
          if (object[key] !== void 0) {
            count++;
          }
        }
        return count;
      }
      encodeMap(object, depth) {
        const keys = Object.keys(object);
        if (this.sortKeys) {
          keys.sort();
        }
        const size = this.ignoreUndefined ? this.countWithoutUndefined(object, keys) : keys.length;
        if (size < 16) {
          this.writeU8(128 + size);
        } else if (size < 65536) {
          this.writeU8(222);
          this.writeU16(size);
        } else if (size < 4294967296) {
          this.writeU8(223);
          this.writeU32(size);
        } else {
          throw new Error(`Too large map object: ${size}`);
        }
        for (const key of keys) {
          const value = object[key];
          if (!(this.ignoreUndefined && value === void 0)) {
            this.encodeString(key);
            this.doEncode(value, depth + 1);
          }
        }
      }
      encodeExtension(ext) {
        const size = ext.data.length;
        if (size === 1) {
          this.writeU8(212);
        } else if (size === 2) {
          this.writeU8(213);
        } else if (size === 4) {
          this.writeU8(214);
        } else if (size === 8) {
          this.writeU8(215);
        } else if (size === 16) {
          this.writeU8(216);
        } else if (size < 256) {
          this.writeU8(199);
          this.writeU8(size);
        } else if (size < 65536) {
          this.writeU8(200);
          this.writeU16(size);
        } else if (size < 4294967296) {
          this.writeU8(201);
          this.writeU32(size);
        } else {
          throw new Error(`Too large extension object: ${size}`);
        }
        this.writeI8(ext.type);
        this.writeU8a(ext.data);
      }
      writeU8(value) {
        this.ensureBufferSizeToWrite(1);
        this.view.setUint8(this.pos, value);
        this.pos++;
      }
      writeU8a(values) {
        const size = values.length;
        this.ensureBufferSizeToWrite(size);
        this.bytes.set(values, this.pos);
        this.pos += size;
      }
      writeI8(value) {
        this.ensureBufferSizeToWrite(1);
        this.view.setInt8(this.pos, value);
        this.pos++;
      }
      writeU16(value) {
        this.ensureBufferSizeToWrite(2);
        this.view.setUint16(this.pos, value);
        this.pos += 2;
      }
      writeI16(value) {
        this.ensureBufferSizeToWrite(2);
        this.view.setInt16(this.pos, value);
        this.pos += 2;
      }
      writeU32(value) {
        this.ensureBufferSizeToWrite(4);
        this.view.setUint32(this.pos, value);
        this.pos += 4;
      }
      writeI32(value) {
        this.ensureBufferSizeToWrite(4);
        this.view.setInt32(this.pos, value);
        this.pos += 4;
      }
      writeF32(value) {
        this.ensureBufferSizeToWrite(4);
        this.view.setFloat32(this.pos, value);
        this.pos += 4;
      }
      writeF64(value) {
        this.ensureBufferSizeToWrite(8);
        this.view.setFloat64(this.pos, value);
        this.pos += 8;
      }
      writeU64(value) {
        this.ensureBufferSizeToWrite(8);
        (0, int_1.setUint64)(this.view, this.pos, value);
        this.pos += 8;
      }
      writeI64(value) {
        this.ensureBufferSizeToWrite(8);
        (0, int_1.setInt64)(this.view, this.pos, value);
        this.pos += 8;
      }
    };
    exports.Encoder = Encoder;
  }
});

// node_modules/@msgpack/msgpack/dist/encode.js
var require_encode = __commonJS({
  "node_modules/@msgpack/msgpack/dist/encode.js"(exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    exports.encode = void 0;
    var Encoder_1 = require_Encoder();
    var defaultEncodeOptions = {};
    function encode3(value, options = defaultEncodeOptions) {
      const encoder2 = new Encoder_1.Encoder(options.extensionCodec, options.context, options.maxDepth, options.initialBufferSize, options.sortKeys, options.forceFloat32, options.ignoreUndefined, options.forceIntegerToFloat);
      return encoder2.encodeSharedRef(value);
    }
    exports.encode = encode3;
  }
});

// node_modules/@msgpack/msgpack/dist/utils/prettyByte.js
var require_prettyByte = __commonJS({
  "node_modules/@msgpack/msgpack/dist/utils/prettyByte.js"(exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    exports.prettyByte = void 0;
    function prettyByte(byte) {
      return `${byte < 0 ? "-" : ""}0x${Math.abs(byte).toString(16).padStart(2, "0")}`;
    }
    exports.prettyByte = prettyByte;
  }
});

// node_modules/@msgpack/msgpack/dist/CachedKeyDecoder.js
var require_CachedKeyDecoder = __commonJS({
  "node_modules/@msgpack/msgpack/dist/CachedKeyDecoder.js"(exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    exports.CachedKeyDecoder = void 0;
    var utf8_1 = require_utf8();
    var DEFAULT_MAX_KEY_LENGTH = 16;
    var DEFAULT_MAX_LENGTH_PER_KEY = 16;
    var CachedKeyDecoder = class {
      constructor(maxKeyLength = DEFAULT_MAX_KEY_LENGTH, maxLengthPerKey = DEFAULT_MAX_LENGTH_PER_KEY) {
        this.maxKeyLength = maxKeyLength;
        this.maxLengthPerKey = maxLengthPerKey;
        this.hit = 0;
        this.miss = 0;
        this.caches = [];
        for (let i = 0; i < this.maxKeyLength; i++) {
          this.caches.push([]);
        }
      }
      canBeCached(byteLength) {
        return byteLength > 0 && byteLength <= this.maxKeyLength;
      }
      find(bytes, inputOffset, byteLength) {
        const records = this.caches[byteLength - 1];
        FIND_CHUNK:
          for (const record of records) {
            const recordBytes = record.bytes;
            for (let j = 0; j < byteLength; j++) {
              if (recordBytes[j] !== bytes[inputOffset + j]) {
                continue FIND_CHUNK;
              }
            }
            return record.str;
          }
        return null;
      }
      store(bytes, value) {
        const records = this.caches[bytes.length - 1];
        const record = { bytes, str: value };
        if (records.length >= this.maxLengthPerKey) {
          records[Math.random() * records.length | 0] = record;
        } else {
          records.push(record);
        }
      }
      decode(bytes, inputOffset, byteLength) {
        const cachedValue = this.find(bytes, inputOffset, byteLength);
        if (cachedValue != null) {
          this.hit++;
          return cachedValue;
        }
        this.miss++;
        const str = (0, utf8_1.utf8DecodeJs)(bytes, inputOffset, byteLength);
        const slicedCopyOfBytes = Uint8Array.prototype.slice.call(bytes, inputOffset, inputOffset + byteLength);
        this.store(slicedCopyOfBytes, str);
        return str;
      }
    };
    exports.CachedKeyDecoder = CachedKeyDecoder;
  }
});

// node_modules/@msgpack/msgpack/dist/Decoder.js
var require_Decoder = __commonJS({
  "node_modules/@msgpack/msgpack/dist/Decoder.js"(exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    exports.Decoder = exports.DataViewIndexOutOfBoundsError = void 0;
    var prettyByte_1 = require_prettyByte();
    var ExtensionCodec_1 = require_ExtensionCodec();
    var int_1 = require_int();
    var utf8_1 = require_utf8();
    var typedArrays_1 = require_typedArrays();
    var CachedKeyDecoder_1 = require_CachedKeyDecoder();
    var DecodeError_1 = require_DecodeError();
    var isValidMapKeyType = (key) => {
      const keyType = typeof key;
      return keyType === "string" || keyType === "number";
    };
    var HEAD_BYTE_REQUIRED = -1;
    var EMPTY_VIEW = new DataView(new ArrayBuffer(0));
    var EMPTY_BYTES = new Uint8Array(EMPTY_VIEW.buffer);
    exports.DataViewIndexOutOfBoundsError = (() => {
      try {
        EMPTY_VIEW.getInt8(0);
      } catch (e) {
        return e.constructor;
      }
      throw new Error("never reached");
    })();
    var MORE_DATA = new exports.DataViewIndexOutOfBoundsError("Insufficient data");
    var sharedCachedKeyDecoder = new CachedKeyDecoder_1.CachedKeyDecoder();
    var Decoder = class {
      constructor(extensionCodec = ExtensionCodec_1.ExtensionCodec.defaultCodec, context = void 0, maxStrLength = int_1.UINT32_MAX, maxBinLength = int_1.UINT32_MAX, maxArrayLength = int_1.UINT32_MAX, maxMapLength = int_1.UINT32_MAX, maxExtLength = int_1.UINT32_MAX, keyDecoder = sharedCachedKeyDecoder) {
        this.extensionCodec = extensionCodec;
        this.context = context;
        this.maxStrLength = maxStrLength;
        this.maxBinLength = maxBinLength;
        this.maxArrayLength = maxArrayLength;
        this.maxMapLength = maxMapLength;
        this.maxExtLength = maxExtLength;
        this.keyDecoder = keyDecoder;
        this.totalPos = 0;
        this.pos = 0;
        this.view = EMPTY_VIEW;
        this.bytes = EMPTY_BYTES;
        this.headByte = HEAD_BYTE_REQUIRED;
        this.stack = [];
      }
      reinitializeState() {
        this.totalPos = 0;
        this.headByte = HEAD_BYTE_REQUIRED;
        this.stack.length = 0;
      }
      setBuffer(buffer) {
        this.bytes = (0, typedArrays_1.ensureUint8Array)(buffer);
        this.view = (0, typedArrays_1.createDataView)(this.bytes);
        this.pos = 0;
      }
      appendBuffer(buffer) {
        if (this.headByte === HEAD_BYTE_REQUIRED && !this.hasRemaining(1)) {
          this.setBuffer(buffer);
        } else {
          const remainingData = this.bytes.subarray(this.pos);
          const newData = (0, typedArrays_1.ensureUint8Array)(buffer);
          const newBuffer = new Uint8Array(remainingData.length + newData.length);
          newBuffer.set(remainingData);
          newBuffer.set(newData, remainingData.length);
          this.setBuffer(newBuffer);
        }
      }
      hasRemaining(size) {
        return this.view.byteLength - this.pos >= size;
      }
      createExtraByteError(posToShow) {
        const { view, pos } = this;
        return new RangeError(`Extra ${view.byteLength - pos} of ${view.byteLength} byte(s) found at buffer[${posToShow}]`);
      }
      /**
       * @throws {@link DecodeError}
       * @throws {@link RangeError}
       */
      decode(buffer) {
        this.reinitializeState();
        this.setBuffer(buffer);
        const object = this.doDecodeSync();
        if (this.hasRemaining(1)) {
          throw this.createExtraByteError(this.pos);
        }
        return object;
      }
      *decodeMulti(buffer) {
        this.reinitializeState();
        this.setBuffer(buffer);
        while (this.hasRemaining(1)) {
          yield this.doDecodeSync();
        }
      }
      async decodeAsync(stream) {
        let decoded = false;
        let object;
        for await (const buffer of stream) {
          if (decoded) {
            throw this.createExtraByteError(this.totalPos);
          }
          this.appendBuffer(buffer);
          try {
            object = this.doDecodeSync();
            decoded = true;
          } catch (e) {
            if (!(e instanceof exports.DataViewIndexOutOfBoundsError)) {
              throw e;
            }
          }
          this.totalPos += this.pos;
        }
        if (decoded) {
          if (this.hasRemaining(1)) {
            throw this.createExtraByteError(this.totalPos);
          }
          return object;
        }
        const { headByte, pos, totalPos } = this;
        throw new RangeError(`Insufficient data in parsing ${(0, prettyByte_1.prettyByte)(headByte)} at ${totalPos} (${pos} in the current buffer)`);
      }
      decodeArrayStream(stream) {
        return this.decodeMultiAsync(stream, true);
      }
      decodeStream(stream) {
        return this.decodeMultiAsync(stream, false);
      }
      async *decodeMultiAsync(stream, isArray) {
        let isArrayHeaderRequired = isArray;
        let arrayItemsLeft = -1;
        for await (const buffer of stream) {
          if (isArray && arrayItemsLeft === 0) {
            throw this.createExtraByteError(this.totalPos);
          }
          this.appendBuffer(buffer);
          if (isArrayHeaderRequired) {
            arrayItemsLeft = this.readArraySize();
            isArrayHeaderRequired = false;
            this.complete();
          }
          try {
            while (true) {
              yield this.doDecodeSync();
              if (--arrayItemsLeft === 0) {
                break;
              }
            }
          } catch (e) {
            if (!(e instanceof exports.DataViewIndexOutOfBoundsError)) {
              throw e;
            }
          }
          this.totalPos += this.pos;
        }
      }
      doDecodeSync() {
        DECODE:
          while (true) {
            const headByte = this.readHeadByte();
            let object;
            if (headByte >= 224) {
              object = headByte - 256;
            } else if (headByte < 192) {
              if (headByte < 128) {
                object = headByte;
              } else if (headByte < 144) {
                const size = headByte - 128;
                if (size !== 0) {
                  this.pushMapState(size);
                  this.complete();
                  continue DECODE;
                } else {
                  object = {};
                }
              } else if (headByte < 160) {
                const size = headByte - 144;
                if (size !== 0) {
                  this.pushArrayState(size);
                  this.complete();
                  continue DECODE;
                } else {
                  object = [];
                }
              } else {
                const byteLength = headByte - 160;
                object = this.decodeUtf8String(byteLength, 0);
              }
            } else if (headByte === 192) {
              object = null;
            } else if (headByte === 194) {
              object = false;
            } else if (headByte === 195) {
              object = true;
            } else if (headByte === 202) {
              object = this.readF32();
            } else if (headByte === 203) {
              object = this.readF64();
            } else if (headByte === 204) {
              object = this.readU8();
            } else if (headByte === 205) {
              object = this.readU16();
            } else if (headByte === 206) {
              object = this.readU32();
            } else if (headByte === 207) {
              object = this.readU64();
            } else if (headByte === 208) {
              object = this.readI8();
            } else if (headByte === 209) {
              object = this.readI16();
            } else if (headByte === 210) {
              object = this.readI32();
            } else if (headByte === 211) {
              object = this.readI64();
            } else if (headByte === 217) {
              const byteLength = this.lookU8();
              object = this.decodeUtf8String(byteLength, 1);
            } else if (headByte === 218) {
              const byteLength = this.lookU16();
              object = this.decodeUtf8String(byteLength, 2);
            } else if (headByte === 219) {
              const byteLength = this.lookU32();
              object = this.decodeUtf8String(byteLength, 4);
            } else if (headByte === 220) {
              const size = this.readU16();
              if (size !== 0) {
                this.pushArrayState(size);
                this.complete();
                continue DECODE;
              } else {
                object = [];
              }
            } else if (headByte === 221) {
              const size = this.readU32();
              if (size !== 0) {
                this.pushArrayState(size);
                this.complete();
                continue DECODE;
              } else {
                object = [];
              }
            } else if (headByte === 222) {
              const size = this.readU16();
              if (size !== 0) {
                this.pushMapState(size);
                this.complete();
                continue DECODE;
              } else {
                object = {};
              }
            } else if (headByte === 223) {
              const size = this.readU32();
              if (size !== 0) {
                this.pushMapState(size);
                this.complete();
                continue DECODE;
              } else {
                object = {};
              }
            } else if (headByte === 196) {
              const size = this.lookU8();
              object = this.decodeBinary(size, 1);
            } else if (headByte === 197) {
              const size = this.lookU16();
              object = this.decodeBinary(size, 2);
            } else if (headByte === 198) {
              const size = this.lookU32();
              object = this.decodeBinary(size, 4);
            } else if (headByte === 212) {
              object = this.decodeExtension(1, 0);
            } else if (headByte === 213) {
              object = this.decodeExtension(2, 0);
            } else if (headByte === 214) {
              object = this.decodeExtension(4, 0);
            } else if (headByte === 215) {
              object = this.decodeExtension(8, 0);
            } else if (headByte === 216) {
              object = this.decodeExtension(16, 0);
            } else if (headByte === 199) {
              const size = this.lookU8();
              object = this.decodeExtension(size, 1);
            } else if (headByte === 200) {
              const size = this.lookU16();
              object = this.decodeExtension(size, 2);
            } else if (headByte === 201) {
              const size = this.lookU32();
              object = this.decodeExtension(size, 4);
            } else {
              throw new DecodeError_1.DecodeError(`Unrecognized type byte: ${(0, prettyByte_1.prettyByte)(headByte)}`);
            }
            this.complete();
            const stack = this.stack;
            while (stack.length > 0) {
              const state = stack[stack.length - 1];
              if (state.type === 0) {
                state.array[state.position] = object;
                state.position++;
                if (state.position === state.size) {
                  stack.pop();
                  object = state.array;
                } else {
                  continue DECODE;
                }
              } else if (state.type === 1) {
                if (!isValidMapKeyType(object)) {
                  throw new DecodeError_1.DecodeError("The type of key must be string or number but " + typeof object);
                }
                if (object === "__proto__") {
                  throw new DecodeError_1.DecodeError("The key __proto__ is not allowed");
                }
                state.key = object;
                state.type = 2;
                continue DECODE;
              } else {
                state.map[state.key] = object;
                state.readCount++;
                if (state.readCount === state.size) {
                  stack.pop();
                  object = state.map;
                } else {
                  state.key = null;
                  state.type = 1;
                  continue DECODE;
                }
              }
            }
            return object;
          }
      }
      readHeadByte() {
        if (this.headByte === HEAD_BYTE_REQUIRED) {
          this.headByte = this.readU8();
        }
        return this.headByte;
      }
      complete() {
        this.headByte = HEAD_BYTE_REQUIRED;
      }
      readArraySize() {
        const headByte = this.readHeadByte();
        switch (headByte) {
          case 220:
            return this.readU16();
          case 221:
            return this.readU32();
          default: {
            if (headByte < 160) {
              return headByte - 144;
            } else {
              throw new DecodeError_1.DecodeError(`Unrecognized array type byte: ${(0, prettyByte_1.prettyByte)(headByte)}`);
            }
          }
        }
      }
      pushMapState(size) {
        if (size > this.maxMapLength) {
          throw new DecodeError_1.DecodeError(`Max length exceeded: map length (${size}) > maxMapLengthLength (${this.maxMapLength})`);
        }
        this.stack.push({
          type: 1,
          size,
          key: null,
          readCount: 0,
          map: {}
        });
      }
      pushArrayState(size) {
        if (size > this.maxArrayLength) {
          throw new DecodeError_1.DecodeError(`Max length exceeded: array length (${size}) > maxArrayLength (${this.maxArrayLength})`);
        }
        this.stack.push({
          type: 0,
          size,
          array: new Array(size),
          position: 0
        });
      }
      decodeUtf8String(byteLength, headerOffset) {
        var _a;
        if (byteLength > this.maxStrLength) {
          throw new DecodeError_1.DecodeError(`Max length exceeded: UTF-8 byte length (${byteLength}) > maxStrLength (${this.maxStrLength})`);
        }
        if (this.bytes.byteLength < this.pos + headerOffset + byteLength) {
          throw MORE_DATA;
        }
        const offset = this.pos + headerOffset;
        let object;
        if (this.stateIsMapKey() && ((_a = this.keyDecoder) === null || _a === void 0 ? void 0 : _a.canBeCached(byteLength))) {
          object = this.keyDecoder.decode(this.bytes, offset, byteLength);
        } else if (byteLength > utf8_1.TEXT_DECODER_THRESHOLD) {
          object = (0, utf8_1.utf8DecodeTD)(this.bytes, offset, byteLength);
        } else {
          object = (0, utf8_1.utf8DecodeJs)(this.bytes, offset, byteLength);
        }
        this.pos += headerOffset + byteLength;
        return object;
      }
      stateIsMapKey() {
        if (this.stack.length > 0) {
          const state = this.stack[this.stack.length - 1];
          return state.type === 1;
        }
        return false;
      }
      decodeBinary(byteLength, headOffset) {
        if (byteLength > this.maxBinLength) {
          throw new DecodeError_1.DecodeError(`Max length exceeded: bin length (${byteLength}) > maxBinLength (${this.maxBinLength})`);
        }
        if (!this.hasRemaining(byteLength + headOffset)) {
          throw MORE_DATA;
        }
        const offset = this.pos + headOffset;
        const object = this.bytes.subarray(offset, offset + byteLength);
        this.pos += headOffset + byteLength;
        return object;
      }
      decodeExtension(size, headOffset) {
        if (size > this.maxExtLength) {
          throw new DecodeError_1.DecodeError(`Max length exceeded: ext length (${size}) > maxExtLength (${this.maxExtLength})`);
        }
        const extType = this.view.getInt8(this.pos + headOffset);
        const data = this.decodeBinary(
          size,
          headOffset + 1
          /* extType */
        );
        return this.extensionCodec.decode(data, extType, this.context);
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
        const value = this.view.getUint8(this.pos);
        this.pos++;
        return value;
      }
      readI8() {
        const value = this.view.getInt8(this.pos);
        this.pos++;
        return value;
      }
      readU16() {
        const value = this.view.getUint16(this.pos);
        this.pos += 2;
        return value;
      }
      readI16() {
        const value = this.view.getInt16(this.pos);
        this.pos += 2;
        return value;
      }
      readU32() {
        const value = this.view.getUint32(this.pos);
        this.pos += 4;
        return value;
      }
      readI32() {
        const value = this.view.getInt32(this.pos);
        this.pos += 4;
        return value;
      }
      readU64() {
        const value = (0, int_1.getUint64)(this.view, this.pos);
        this.pos += 8;
        return value;
      }
      readI64() {
        const value = (0, int_1.getInt64)(this.view, this.pos);
        this.pos += 8;
        return value;
      }
      readF32() {
        const value = this.view.getFloat32(this.pos);
        this.pos += 4;
        return value;
      }
      readF64() {
        const value = this.view.getFloat64(this.pos);
        this.pos += 8;
        return value;
      }
    };
    exports.Decoder = Decoder;
  }
});

// node_modules/@msgpack/msgpack/dist/decode.js
var require_decode = __commonJS({
  "node_modules/@msgpack/msgpack/dist/decode.js"(exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    exports.decodeMulti = exports.decode = exports.defaultDecodeOptions = void 0;
    var Decoder_1 = require_Decoder();
    exports.defaultDecodeOptions = {};
    function decode3(buffer, options = exports.defaultDecodeOptions) {
      const decoder2 = new Decoder_1.Decoder(options.extensionCodec, options.context, options.maxStrLength, options.maxBinLength, options.maxArrayLength, options.maxMapLength, options.maxExtLength);
      return decoder2.decode(buffer);
    }
    exports.decode = decode3;
    function decodeMulti(buffer, options = exports.defaultDecodeOptions) {
      const decoder2 = new Decoder_1.Decoder(options.extensionCodec, options.context, options.maxStrLength, options.maxBinLength, options.maxArrayLength, options.maxMapLength, options.maxExtLength);
      return decoder2.decodeMulti(buffer);
    }
    exports.decodeMulti = decodeMulti;
  }
});

// node_modules/@msgpack/msgpack/dist/utils/stream.js
var require_stream = __commonJS({
  "node_modules/@msgpack/msgpack/dist/utils/stream.js"(exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    exports.ensureAsyncIterable = exports.asyncIterableFromStream = exports.isAsyncIterable = void 0;
    function isAsyncIterable(object) {
      return object[Symbol.asyncIterator] != null;
    }
    exports.isAsyncIterable = isAsyncIterable;
    function assertNonNull(value) {
      if (value == null) {
        throw new Error("Assertion Failure: value must not be null nor undefined");
      }
    }
    async function* asyncIterableFromStream(stream) {
      const reader = stream.getReader();
      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) {
            return;
          }
          assertNonNull(value);
          yield value;
        }
      } finally {
        reader.releaseLock();
      }
    }
    exports.asyncIterableFromStream = asyncIterableFromStream;
    function ensureAsyncIterable(streamLike) {
      if (isAsyncIterable(streamLike)) {
        return streamLike;
      } else {
        return asyncIterableFromStream(streamLike);
      }
    }
    exports.ensureAsyncIterable = ensureAsyncIterable;
  }
});

// node_modules/@msgpack/msgpack/dist/decodeAsync.js
var require_decodeAsync = __commonJS({
  "node_modules/@msgpack/msgpack/dist/decodeAsync.js"(exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    exports.decodeStream = exports.decodeMultiStream = exports.decodeArrayStream = exports.decodeAsync = void 0;
    var Decoder_1 = require_Decoder();
    var stream_1 = require_stream();
    var decode_1 = require_decode();
    async function decodeAsync(streamLike, options = decode_1.defaultDecodeOptions) {
      const stream = (0, stream_1.ensureAsyncIterable)(streamLike);
      const decoder2 = new Decoder_1.Decoder(options.extensionCodec, options.context, options.maxStrLength, options.maxBinLength, options.maxArrayLength, options.maxMapLength, options.maxExtLength);
      return decoder2.decodeAsync(stream);
    }
    exports.decodeAsync = decodeAsync;
    function decodeArrayStream(streamLike, options = decode_1.defaultDecodeOptions) {
      const stream = (0, stream_1.ensureAsyncIterable)(streamLike);
      const decoder2 = new Decoder_1.Decoder(options.extensionCodec, options.context, options.maxStrLength, options.maxBinLength, options.maxArrayLength, options.maxMapLength, options.maxExtLength);
      return decoder2.decodeArrayStream(stream);
    }
    exports.decodeArrayStream = decodeArrayStream;
    function decodeMultiStream(streamLike, options = decode_1.defaultDecodeOptions) {
      const stream = (0, stream_1.ensureAsyncIterable)(streamLike);
      const decoder2 = new Decoder_1.Decoder(options.extensionCodec, options.context, options.maxStrLength, options.maxBinLength, options.maxArrayLength, options.maxMapLength, options.maxExtLength);
      return decoder2.decodeStream(stream);
    }
    exports.decodeMultiStream = decodeMultiStream;
    function decodeStream(streamLike, options = decode_1.defaultDecodeOptions) {
      return decodeMultiStream(streamLike, options);
    }
    exports.decodeStream = decodeStream;
  }
});

// node_modules/@msgpack/msgpack/dist/index.js
var require_dist = __commonJS({
  "node_modules/@msgpack/msgpack/dist/index.js"(exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    exports.decodeTimestampExtension = exports.encodeTimestampExtension = exports.decodeTimestampToTimeSpec = exports.encodeTimeSpecToTimestamp = exports.encodeDateToTimeSpec = exports.EXT_TIMESTAMP = exports.ExtData = exports.ExtensionCodec = exports.Encoder = exports.DataViewIndexOutOfBoundsError = exports.DecodeError = exports.Decoder = exports.decodeStream = exports.decodeMultiStream = exports.decodeArrayStream = exports.decodeAsync = exports.decodeMulti = exports.decode = exports.encode = void 0;
    var encode_1 = require_encode();
    Object.defineProperty(exports, "encode", { enumerable: true, get: function() {
      return encode_1.encode;
    } });
    var decode_1 = require_decode();
    Object.defineProperty(exports, "decode", { enumerable: true, get: function() {
      return decode_1.decode;
    } });
    Object.defineProperty(exports, "decodeMulti", { enumerable: true, get: function() {
      return decode_1.decodeMulti;
    } });
    var decodeAsync_1 = require_decodeAsync();
    Object.defineProperty(exports, "decodeAsync", { enumerable: true, get: function() {
      return decodeAsync_1.decodeAsync;
    } });
    Object.defineProperty(exports, "decodeArrayStream", { enumerable: true, get: function() {
      return decodeAsync_1.decodeArrayStream;
    } });
    Object.defineProperty(exports, "decodeMultiStream", { enumerable: true, get: function() {
      return decodeAsync_1.decodeMultiStream;
    } });
    Object.defineProperty(exports, "decodeStream", { enumerable: true, get: function() {
      return decodeAsync_1.decodeStream;
    } });
    var Decoder_1 = require_Decoder();
    Object.defineProperty(exports, "Decoder", { enumerable: true, get: function() {
      return Decoder_1.Decoder;
    } });
    Object.defineProperty(exports, "DataViewIndexOutOfBoundsError", { enumerable: true, get: function() {
      return Decoder_1.DataViewIndexOutOfBoundsError;
    } });
    var DecodeError_1 = require_DecodeError();
    Object.defineProperty(exports, "DecodeError", { enumerable: true, get: function() {
      return DecodeError_1.DecodeError;
    } });
    var Encoder_1 = require_Encoder();
    Object.defineProperty(exports, "Encoder", { enumerable: true, get: function() {
      return Encoder_1.Encoder;
    } });
    var ExtensionCodec_1 = require_ExtensionCodec();
    Object.defineProperty(exports, "ExtensionCodec", { enumerable: true, get: function() {
      return ExtensionCodec_1.ExtensionCodec;
    } });
    var ExtData_1 = require_ExtData();
    Object.defineProperty(exports, "ExtData", { enumerable: true, get: function() {
      return ExtData_1.ExtData;
    } });
    var timestamp_1 = require_timestamp();
    Object.defineProperty(exports, "EXT_TIMESTAMP", { enumerable: true, get: function() {
      return timestamp_1.EXT_TIMESTAMP;
    } });
    Object.defineProperty(exports, "encodeDateToTimeSpec", { enumerable: true, get: function() {
      return timestamp_1.encodeDateToTimeSpec;
    } });
    Object.defineProperty(exports, "encodeTimeSpecToTimestamp", { enumerable: true, get: function() {
      return timestamp_1.encodeTimeSpecToTimestamp;
    } });
    Object.defineProperty(exports, "decodeTimestampToTimeSpec", { enumerable: true, get: function() {
      return timestamp_1.decodeTimestampToTimeSpec;
    } });
    Object.defineProperty(exports, "encodeTimestampExtension", { enumerable: true, get: function() {
      return timestamp_1.encodeTimestampExtension;
    } });
    Object.defineProperty(exports, "decodeTimestampExtension", { enumerable: true, get: function() {
      return timestamp_1.decodeTimestampExtension;
    } });
  }
});

// node_modules/xmlhttprequest-ssl/lib/XMLHttpRequest.js
var require_XMLHttpRequest = __commonJS({
  "node_modules/xmlhttprequest-ssl/lib/XMLHttpRequest.js"(exports, module2) {
    var fs = require("fs");
    var Url = require("url");
    var spawn = require("child_process").spawn;
    module2.exports = XMLHttpRequest2;
    XMLHttpRequest2.XMLHttpRequest = XMLHttpRequest2;
    function XMLHttpRequest2(opts) {
      "use strict";
      opts = opts || {};
      var self = this;
      var http = require("http");
      var https = require("https");
      var request;
      var response;
      var settings = {};
      var disableHeaderCheck = false;
      var defaultHeaders = {
        "User-Agent": "node-XMLHttpRequest",
        "Accept": "*/*"
      };
      var headers = Object.assign({}, defaultHeaders);
      var forbiddenRequestHeaders = [
        "accept-charset",
        "accept-encoding",
        "access-control-request-headers",
        "access-control-request-method",
        "connection",
        "content-length",
        "content-transfer-encoding",
        "cookie",
        "cookie2",
        "date",
        "expect",
        "host",
        "keep-alive",
        "origin",
        "referer",
        "te",
        "trailer",
        "transfer-encoding",
        "upgrade",
        "via"
      ];
      var forbiddenRequestMethods = [
        "TRACE",
        "TRACK",
        "CONNECT"
      ];
      var sendFlag = false;
      var errorFlag = false;
      var abortedFlag = false;
      var listeners = {};
      this.UNSENT = 0;
      this.OPENED = 1;
      this.HEADERS_RECEIVED = 2;
      this.LOADING = 3;
      this.DONE = 4;
      this.readyState = this.UNSENT;
      this.onreadystatechange = null;
      this.responseText = "";
      this.responseXML = "";
      this.response = Buffer.alloc(0);
      this.status = null;
      this.statusText = null;
      var isAllowedHttpHeader = function(header) {
        return disableHeaderCheck || header && forbiddenRequestHeaders.indexOf(header.toLowerCase()) === -1;
      };
      var isAllowedHttpMethod = function(method) {
        return method && forbiddenRequestMethods.indexOf(method) === -1;
      };
      this.open = function(method, url, async, user, password) {
        this.abort();
        errorFlag = false;
        abortedFlag = false;
        if (!isAllowedHttpMethod(method)) {
          throw new Error("SecurityError: Request method not allowed");
        }
        settings = {
          "method": method,
          "url": url.toString(),
          "async": typeof async !== "boolean" ? true : async,
          "user": user || null,
          "password": password || null
        };
        setState(this.OPENED);
      };
      this.setDisableHeaderCheck = function(state) {
        disableHeaderCheck = state;
      };
      this.setRequestHeader = function(header, value) {
        if (this.readyState != this.OPENED) {
          throw new Error("INVALID_STATE_ERR: setRequestHeader can only be called when state is OPEN");
        }
        if (!isAllowedHttpHeader(header)) {
          console.warn('Refused to set unsafe header "' + header + '"');
          return false;
        }
        if (sendFlag) {
          throw new Error("INVALID_STATE_ERR: send flag is true");
        }
        headers[header] = value;
        return true;
      };
      this.getResponseHeader = function(header) {
        if (typeof header === "string" && this.readyState > this.OPENED && response.headers[header.toLowerCase()] && !errorFlag) {
          return response.headers[header.toLowerCase()];
        }
        return null;
      };
      this.getAllResponseHeaders = function() {
        if (this.readyState < this.HEADERS_RECEIVED || errorFlag) {
          return "";
        }
        var result = "";
        for (var i in response.headers) {
          if (i !== "set-cookie" && i !== "set-cookie2") {
            result += i + ": " + response.headers[i] + "\r\n";
          }
        }
        return result.substr(0, result.length - 2);
      };
      this.getRequestHeader = function(name) {
        if (typeof name === "string" && headers[name]) {
          return headers[name];
        }
        return "";
      };
      this.send = function(data) {
        if (this.readyState != this.OPENED) {
          throw new Error("INVALID_STATE_ERR: connection must be opened before send() is called");
        }
        if (sendFlag) {
          throw new Error("INVALID_STATE_ERR: send has already been called");
        }
        var ssl = false, local = false;
        var url = Url.parse(settings.url);
        var host;
        switch (url.protocol) {
          case "https:":
            ssl = true;
          case "http:":
            host = url.hostname;
            break;
          case "file:":
            local = true;
            break;
          case void 0:
          case "":
            host = "localhost";
            break;
          default:
            throw new Error("Protocol not supported.");
        }
        if (local) {
          if (settings.method !== "GET") {
            throw new Error("XMLHttpRequest: Only GET method is supported");
          }
          if (settings.async) {
            fs.readFile(unescape(url.pathname), function(error, data2) {
              if (error) {
                self.handleError(error, error.errno || -1);
              } else {
                self.status = 200;
                self.responseText = data2.toString("utf8");
                self.response = data2;
                setState(self.DONE);
              }
            });
          } else {
            try {
              this.response = fs.readFileSync(unescape(url.pathname));
              this.responseText = this.response.toString("utf8");
              this.status = 200;
              setState(self.DONE);
            } catch (e) {
              this.handleError(e, e.errno || -1);
            }
          }
          return;
        }
        var port = url.port || (ssl ? 443 : 80);
        var uri = url.pathname + (url.search ? url.search : "");
        headers["Host"] = host;
        if (!(ssl && port === 443 || port === 80)) {
          headers["Host"] += ":" + url.port;
        }
        if (settings.user) {
          if (typeof settings.password == "undefined") {
            settings.password = "";
          }
          var authBuf = new Buffer(settings.user + ":" + settings.password);
          headers["Authorization"] = "Basic " + authBuf.toString("base64");
        }
        if (settings.method === "GET" || settings.method === "HEAD") {
          data = null;
        } else if (data) {
          headers["Content-Length"] = Buffer.isBuffer(data) ? data.length : Buffer.byteLength(data);
          if (!headers["Content-Type"]) {
            headers["Content-Type"] = "text/plain;charset=UTF-8";
          }
        } else if (settings.method === "POST") {
          headers["Content-Length"] = 0;
        }
        var agent = opts.agent || false;
        var options = {
          host,
          port,
          path: uri,
          method: settings.method,
          headers,
          agent
        };
        if (ssl) {
          options.pfx = opts.pfx;
          options.key = opts.key;
          options.passphrase = opts.passphrase;
          options.cert = opts.cert;
          options.ca = opts.ca;
          options.ciphers = opts.ciphers;
          options.rejectUnauthorized = opts.rejectUnauthorized === false ? false : true;
        }
        errorFlag = false;
        if (settings.async) {
          var doRequest = ssl ? https.request : http.request;
          sendFlag = true;
          self.dispatchEvent("readystatechange");
          var responseHandler = function(resp2) {
            response = resp2;
            if (response.statusCode === 302 || response.statusCode === 303 || response.statusCode === 307) {
              settings.url = response.headers.location;
              var url2 = Url.parse(settings.url);
              host = url2.hostname;
              var newOptions = {
                hostname: url2.hostname,
                port: url2.port,
                path: url2.path,
                method: response.statusCode === 303 ? "GET" : settings.method,
                headers
              };
              if (ssl) {
                newOptions.pfx = opts.pfx;
                newOptions.key = opts.key;
                newOptions.passphrase = opts.passphrase;
                newOptions.cert = opts.cert;
                newOptions.ca = opts.ca;
                newOptions.ciphers = opts.ciphers;
                newOptions.rejectUnauthorized = opts.rejectUnauthorized === false ? false : true;
              }
              request = doRequest(newOptions, responseHandler).on("error", errorHandler);
              request.end();
              return;
            }
            setState(self.HEADERS_RECEIVED);
            self.status = response.statusCode;
            response.on("data", function(chunk) {
              if (chunk) {
                var data2 = Buffer.from(chunk);
                self.response = Buffer.concat([self.response, data2]);
              }
              if (sendFlag) {
                setState(self.LOADING);
              }
            });
            response.on("end", function() {
              if (sendFlag) {
                sendFlag = false;
                setState(self.DONE);
                self.responseText = self.response.toString("utf8");
              }
            });
            response.on("error", function(error) {
              self.handleError(error);
            });
          };
          var errorHandler = function(error) {
            self.handleError(error);
          };
          request = doRequest(options, responseHandler).on("error", errorHandler);
          if (opts.autoUnref) {
            request.on("socket", (socket) => {
              socket.unref();
            });
          }
          if (data) {
            request.write(data);
          }
          request.end();
          self.dispatchEvent("loadstart");
        } else {
          var contentFile = ".node-xmlhttprequest-content-" + process.pid;
          var syncFile = ".node-xmlhttprequest-sync-" + process.pid;
          fs.writeFileSync(syncFile, "", "utf8");
          var execString = "var http = require('http'), https = require('https'), fs = require('fs');var doRequest = http" + (ssl ? "s" : "") + ".request;var options = " + JSON.stringify(options) + ";var responseText = '';var responseData = Buffer.alloc(0);var req = doRequest(options, function(response) {response.on('data', function(chunk) {  var data = Buffer.from(chunk);  responseText += data.toString('utf8');  responseData = Buffer.concat([responseData, data]);});response.on('end', function() {fs.writeFileSync('" + contentFile + "', JSON.stringify({err: null, data: {statusCode: response.statusCode, headers: response.headers, text: responseText, data: responseData.toString('base64')}}), 'utf8');fs.unlinkSync('" + syncFile + "');});response.on('error', function(error) {fs.writeFileSync('" + contentFile + "', 'NODE-XMLHTTPREQUEST-ERROR:' + JSON.stringify(error), 'utf8');fs.unlinkSync('" + syncFile + "');});}).on('error', function(error) {fs.writeFileSync('" + contentFile + "', 'NODE-XMLHTTPREQUEST-ERROR:' + JSON.stringify(error), 'utf8');fs.unlinkSync('" + syncFile + "');});" + (data ? "req.write('" + JSON.stringify(data).slice(1, -1).replace(/'/g, "\\'") + "');" : "") + "req.end();";
          var syncProc = spawn(process.argv[0], ["-e", execString]);
          var statusText;
          while (fs.existsSync(syncFile)) {
          }
          self.responseText = fs.readFileSync(contentFile, "utf8");
          syncProc.stdin.end();
          fs.unlinkSync(contentFile);
          if (self.responseText.match(/^NODE-XMLHTTPREQUEST-ERROR:/)) {
            var errorObj = JSON.parse(self.responseText.replace(/^NODE-XMLHTTPREQUEST-ERROR:/, ""));
            self.handleError(errorObj, 503);
          } else {
            self.status = self.responseText.replace(/^NODE-XMLHTTPREQUEST-STATUS:([0-9]*),.*/, "$1");
            var resp = JSON.parse(self.responseText.replace(/^NODE-XMLHTTPREQUEST-STATUS:[0-9]*,(.*)/, "$1"));
            response = {
              statusCode: self.status,
              headers: resp.data.headers
            };
            self.responseText = resp.data.text;
            self.response = Buffer.from(resp.data.data, "base64");
            setState(self.DONE, true);
          }
        }
      };
      this.handleError = function(error, status) {
        this.status = status || 0;
        this.statusText = error;
        this.responseText = error.stack;
        errorFlag = true;
        setState(this.DONE);
      };
      this.abort = function() {
        if (request) {
          request.abort();
          request = null;
        }
        headers = Object.assign({}, defaultHeaders);
        this.responseText = "";
        this.responseXML = "";
        this.response = Buffer.alloc(0);
        errorFlag = abortedFlag = true;
        if (this.readyState !== this.UNSENT && (this.readyState !== this.OPENED || sendFlag) && this.readyState !== this.DONE) {
          sendFlag = false;
          setState(this.DONE);
        }
        this.readyState = this.UNSENT;
      };
      this.addEventListener = function(event, callback) {
        if (!(event in listeners)) {
          listeners[event] = [];
        }
        listeners[event].push(callback);
      };
      this.removeEventListener = function(event, callback) {
        if (event in listeners) {
          listeners[event] = listeners[event].filter(function(ev) {
            return ev !== callback;
          });
        }
      };
      this.dispatchEvent = function(event) {
        if (typeof self["on" + event] === "function") {
          if (this.readyState === this.DONE && settings.async)
            setTimeout(function() {
              self["on" + event]();
            }, 0);
          else
            self["on" + event]();
        }
        if (event in listeners) {
          for (let i = 0, len = listeners[event].length; i < len; i++) {
            if (this.readyState === this.DONE)
              setTimeout(function() {
                listeners[event][i].call(self);
              }, 0);
            else
              listeners[event][i].call(self);
          }
        }
      };
      var setState = function(state) {
        if (self.readyState === state || self.readyState === self.UNSENT && abortedFlag)
          return;
        self.readyState = state;
        if (settings.async || self.readyState < self.OPENED || self.readyState === self.DONE) {
          self.dispatchEvent("readystatechange");
        }
        if (self.readyState === self.DONE) {
          let fire;
          if (abortedFlag)
            fire = "abort";
          else if (errorFlag)
            fire = "error";
          else
            fire = "load";
          self.dispatchEvent(fire);
          self.dispatchEvent("loadend");
        }
      };
    }
  }
});

// webR/error.ts
var WebRError = class extends Error {
  constructor(msg) {
    super(msg);
    this.name = this.constructor.name;
    Object.setPrototypeOf(this, new.target.prototype);
  }
};
var WebRWorkerError = class extends WebRError {
};
var WebRChannelError = class extends WebRError {
};

// webR/compat.ts
var IN_NODE = typeof process !== "undefined" && process.release && process.release.name === "node";
var loadScript;
if (globalThis.document) {
  loadScript = (url) => new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = url;
    script.onload = () => resolve();
    script.onerror = reject;
    document.head.appendChild(script);
  });
} else if (globalThis.importScripts) {
  loadScript = async (url) => {
    try {
      globalThis.importScripts(url);
    } catch (e) {
      if (e instanceof TypeError) {
        await Promise.resolve().then(() => __toESM(require(url)));
      } else {
        throw e;
      }
    }
  };
} else if (IN_NODE) {
  loadScript = async (url) => {
    const nodePathMod = (await Promise.resolve().then(() => __toESM(require("path")))).default;
    await Promise.resolve().then(() => __toESM(require(nodePathMod.resolve(url))));
  };
} else {
  throw new WebRError("Cannot determine runtime environment");
}

// webR/emscripten.ts
var Module2 = {};
function dictEmFree(dict) {
  Object.keys(dict).forEach((key) => Module2._free(dict[key]));
}

// webR/robj.ts
var RTypeMap = {
  null: 0,
  symbol: 1,
  pairlist: 2,
  closure: 3,
  environment: 4,
  promise: 5,
  call: 6,
  special: 7,
  builtin: 8,
  string: 9,
  logical: 10,
  integer: 13,
  double: 14,
  complex: 15,
  character: 16,
  dots: 17,
  any: 18,
  list: 19,
  expression: 20,
  bytecode: 21,
  pointer: 22,
  weakref: 23,
  raw: 24,
  s4: 25,
  new: 30,
  free: 31,
  function: 99
};
function isWebRDataJs(value) {
  return !!value && typeof value === "object" && Object.keys(RTypeMap).includes(value.type);
}
function isComplex(value) {
  return !!value && typeof value === "object" && "re" in value && "im" in value;
}

// webR/utils-r.ts
function protect(x) {
  Module2._Rf_protect(handlePtr(x));
  return x;
}
function protectInc(x, prot) {
  Module2._Rf_protect(handlePtr(x));
  ++prot.n;
  return x;
}
function protectWithIndex(x) {
  const pLoc = Module2._malloc(4);
  Module2._R_ProtectWithIndex(handlePtr(x), pLoc);
  const loc = Module2.getValue(pLoc, "i32");
  return { loc, ptr: pLoc };
}
function unprotectIndex(index) {
  Module2._Rf_unprotect(1);
  Module2._free(index.ptr);
}
function reprotect(x, index) {
  Module2._R_Reprotect(handlePtr(x), index.loc);
  return x;
}
function unprotect(n) {
  Module2._Rf_unprotect(n);
}
function envPoke(env, sym, value) {
  Module2._Rf_defineVar(handlePtr(sym), handlePtr(value), handlePtr(env));
}
function parseEvalBare(code, env) {
  const strings2 = {};
  const prot = { n: 0 };
  try {
    const envObj = new REnvironment(env);
    protectInc(envObj, prot);
    strings2.code = Module2.allocateUTF8(code);
    const out = Module2._R_ParseEvalString(strings2.code, envObj.ptr);
    return RObject.wrap(out);
  } finally {
    dictEmFree(strings2);
    unprotect(prot.n);
  }
}
var UnwindProtectException = class extends Error {
  constructor(message, cont) {
    super(message);
    this.name = "UnwindProtectException";
    this.cont = cont;
  }
};
function safeEval(call, env) {
  return Module2.getWasmTableEntry(Module2.GOT.ffi_safe_eval.value)(
    handlePtr(call),
    handlePtr(env)
  );
}

// webR/chan/task-common.ts
var SZ_BUF_DOESNT_FIT = 0;
var SZ_BUF_FITS_IDX = 1;
var SZ_BUF_SIZE_IDX = 0;
var transferCache = /* @__PURE__ */ new WeakMap();
function transfer(obj, transfers) {
  transferCache.set(obj, transfers);
  return obj;
}
function isUUID(x) {
  return typeof x === "string" && x.length === UUID_LENGTH;
}
var UUID_LENGTH = 63;
function generateUUID() {
  const result = Array.from({ length: 4 }, randomSegment).join("-");
  if (result.length !== UUID_LENGTH) {
    throw new Error("comlink internal error: UUID has the wrong length");
  }
  return result;
}
function randomSegment() {
  let result = Math.floor(Math.random() * Number.MAX_SAFE_INTEGER).toString(16);
  const pad = 15 - result.length;
  if (pad > 0) {
    result = Array.from({ length: pad }, () => 0).join("") + result;
  }
  return result;
}

// webR/robj-worker.ts
function handlePtr(x) {
  if (isRObject(x)) {
    return x.ptr;
  } else {
    return x;
  }
}
function assertRType(obj, type) {
  if (Module2._TYPEOF(obj.ptr) !== RTypeMap[type]) {
    throw new Error(`Unexpected object type "${obj.type()}" when expecting type "${type}"`);
  }
}
var shelters = /* @__PURE__ */ new Map();
function keep(shelter, x) {
  const ptr = handlePtr(x);
  Module2._R_PreserveObject(ptr);
  if (shelter === void 0) {
    return;
  }
  if (isUUID(shelter)) {
    shelters.get(shelter).push(ptr);
    return;
  }
  throw new Error("Unexpected shelter type " + typeof shelter);
}
function destroy(shelter, x) {
  const ptr = handlePtr(x);
  Module2._R_ReleaseObject(ptr);
  const objs2 = shelters.get(shelter);
  const loc = objs2.indexOf(ptr);
  if (loc < 0) {
    throw new Error("Can't find object in shelter.");
  }
  objs2.splice(loc, 1);
}
function purge(shelter) {
  const ptrs = shelters.get(shelter);
  for (const ptr of ptrs) {
    try {
      Module2._R_ReleaseObject(ptr);
    } catch (e) {
      console.error(e);
    }
  }
  shelters.set(shelter, []);
}
function newObjectFromData(obj) {
  if (isWebRDataJs(obj)) {
    return new (getRWorkerClass(obj.type))(obj);
  }
  if (obj && typeof obj === "object" && "type" in obj && obj.type === "null") {
    return new RNull();
  }
  if (obj === null) {
    return new RLogical({ type: "logical", names: null, values: [null] });
  }
  if (typeof obj === "boolean") {
    return new RLogical(obj);
  }
  if (typeof obj === "number") {
    return new RDouble(obj);
  }
  if (typeof obj === "string") {
    return new RCharacter(obj);
  }
  if (isComplex(obj)) {
    return new RComplex(obj);
  }
  if (ArrayBuffer.isView(obj) || obj instanceof ArrayBuffer) {
    return new RRaw(obj);
  }
  if (Array.isArray(obj)) {
    return newObjectFromArray(obj);
  }
  if (typeof obj === "object") {
    return RDataFrame.fromObject(obj);
  }
  throw new Error("Robj construction for this JS object is not yet supported");
}
function newObjectFromArray(arr) {
  const prot = { n: 0 };
  const hasObjects = arr.every((v) => v && typeof v === "object" && !isRObject(v) && !isComplex(v));
  if (hasObjects) {
    const _arr = arr;
    const isConsistent = _arr.every((a) => {
      return Object.keys(a).filter((k) => !Object.keys(_arr[0]).includes(k)).length === 0 && Object.keys(_arr[0]).filter((k) => !Object.keys(a).includes(k)).length === 0;
    });
    const isAtomic = _arr.every((a) => Object.values(a).every((v) => {
      return isAtomicType(v) || isRVectorAtomic(v);
    }));
    if (isConsistent && isAtomic) {
      return RDataFrame.fromD3(_arr);
    }
  }
  if (arr.every((v) => typeof v === "boolean" || v === null)) {
    return new RLogical(arr);
  }
  if (arr.every((v) => typeof v === "number" || v === null)) {
    return new RDouble(arr);
  }
  if (arr.every((v) => typeof v === "string" || v === null)) {
    return new RCharacter(arr);
  }
  try {
    const call = new RCall([new RSymbol("c"), ...arr]);
    protectInc(call, prot);
    return call.eval();
  } finally {
    unprotect(prot.n);
  }
}
var RObjectBase = class {
  constructor(ptr) {
    this.ptr = ptr;
  }
  type() {
    const typeNumber = Module2._TYPEOF(this.ptr);
    const type = Object.keys(RTypeMap).find(
      (typeName) => RTypeMap[typeName] === typeNumber
    );
    return type;
  }
};
var _slice, slice_fn;
var _RObject = class extends RObjectBase {
  constructor(data) {
    if (!(data instanceof RObjectBase)) {
      return newObjectFromData(data);
    }
    super(data.ptr);
    __privateAdd(this, _slice);
  }
  static wrap(ptr) {
    const typeNumber = Module2._TYPEOF(ptr);
    const type = Object.keys(RTypeMap)[Object.values(RTypeMap).indexOf(typeNumber)];
    return new (getRWorkerClass(type))(new RObjectBase(ptr));
  }
  get [Symbol.toStringTag]() {
    return `RObject:${this.type()}`;
  }
  /** @internal */
  static getPersistentObject(prop) {
    return objs[prop];
  }
  /** @internal */
  getPropertyValue(prop) {
    return this[prop];
  }
  inspect() {
    parseEvalBare(".Internal(inspect(x))", { x: this });
  }
  isNull() {
    return Module2._TYPEOF(this.ptr) === RTypeMap.null;
  }
  isNa() {
    try {
      const result = parseEvalBare("is.na(x)", { x: this });
      protect(result);
      return result.toBoolean();
    } finally {
      unprotect(1);
    }
  }
  isUnbound() {
    return this.ptr === objs.unboundValue.ptr;
  }
  attrs() {
    return RPairlist.wrap(Module2._ATTRIB(this.ptr));
  }
  class() {
    const prot = { n: 0 };
    const classCall = new RCall([new RSymbol("class"), this]);
    protectInc(classCall, prot);
    try {
      return classCall.eval();
    } finally {
      unprotect(prot.n);
    }
  }
  setNames(values) {
    let namesObj;
    if (values === null) {
      namesObj = objs.null;
    } else if (Array.isArray(values) && values.every((v) => typeof v === "string" || v === null)) {
      namesObj = new RCharacter(values);
    } else {
      throw new Error("Argument to setNames must be null or an Array of strings or null");
    }
    Module2._Rf_setAttrib(this.ptr, objs.namesSymbol.ptr, namesObj.ptr);
    return this;
  }
  names() {
    const names = RCharacter.wrap(Module2._Rf_getAttrib(this.ptr, objs.namesSymbol.ptr));
    if (names.isNull()) {
      return null;
    } else {
      return names.toArray();
    }
  }
  includes(name) {
    const names = this.names();
    return names && names.includes(name);
  }
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  toJs(options = { depth: 0 }, depth = 1) {
    throw new Error("This R object cannot be converted to JS");
  }
  subset(prop) {
    return __privateMethod(this, _slice, slice_fn).call(this, prop, objs.bracketSymbol.ptr);
  }
  get(prop) {
    return __privateMethod(this, _slice, slice_fn).call(this, prop, objs.bracket2Symbol.ptr);
  }
  getDollar(prop) {
    return __privateMethod(this, _slice, slice_fn).call(this, prop, objs.dollarSymbol.ptr);
  }
  pluck(...path) {
    const index = protectWithIndex(objs.null);
    try {
      const getter = (obj, prop) => {
        const out = obj.get(prop);
        return reprotect(out, index);
      };
      const result = path.reduce(getter, this);
      return result.isNull() ? void 0 : result;
    } finally {
      unprotectIndex(index);
    }
  }
  set(prop, value) {
    const prot = { n: 0 };
    try {
      const idx = new _RObject(prop);
      protectInc(idx, prot);
      const valueObj = new _RObject(value);
      protectInc(valueObj, prot);
      const assign2 = new RSymbol("[[<-");
      const call = Module2._Rf_lang4(assign2.ptr, this.ptr, idx.ptr, valueObj.ptr);
      protectInc(call, prot);
      return _RObject.wrap(safeEval(call, objs.baseEnv));
    } finally {
      unprotect(prot.n);
    }
  }
  /** @internal */
  static getMethods(obj) {
    const props = /* @__PURE__ */ new Set();
    let cur = obj;
    do {
      Object.getOwnPropertyNames(cur).map((p) => props.add(p));
    } while (cur = Object.getPrototypeOf(cur));
    return [...props.keys()].filter((i) => typeof obj[i] === "function");
  }
};
var RObject = _RObject;
_slice = new WeakSet();
slice_fn = function(prop, op) {
  const prot = { n: 0 };
  try {
    const idx = new _RObject(prop);
    protectInc(idx, prot);
    const call = Module2._Rf_lang3(op, this.ptr, idx.ptr);
    protectInc(call, prot);
    return _RObject.wrap(safeEval(call, objs.baseEnv));
  } finally {
    unprotect(prot.n);
  }
};
var RNull = class extends RObject {
  constructor() {
    super(new RObjectBase(Module2.getValue(Module2._R_NilValue, "*")));
    return this;
  }
  toJs() {
    return { type: "null" };
  }
};
var RSymbol = class extends RObject {
  // Note that symbols don't need to be protected. This also means
  // that allocating symbols in loops with random data is probably a
  // bad idea because this leaks memory.
  constructor(x) {
    if (x instanceof RObjectBase) {
      assertRType(x, "symbol");
      super(x);
      return;
    }
    const name = Module2.allocateUTF8(x);
    try {
      super(new RObjectBase(Module2._Rf_install(name)));
    } finally {
      Module2._free(name);
    }
  }
  toJs() {
    const obj = this.toObject();
    return {
      type: "symbol",
      printname: obj.printname,
      symvalue: obj.symvalue,
      internal: obj.internal
    };
  }
  toObject() {
    return {
      printname: this.printname().isUnbound() ? null : this.printname().toString(),
      symvalue: this.symvalue().isUnbound() ? null : this.symvalue().ptr,
      internal: this.internal().isNull() ? null : this.internal().ptr
    };
  }
  toString() {
    return this.printname().toString();
  }
  printname() {
    return RString.wrap(Module2._PRINTNAME(this.ptr));
  }
  symvalue() {
    return RObject.wrap(Module2._SYMVALUE(this.ptr));
  }
  internal() {
    return RObject.wrap(Module2._INTERNAL(this.ptr));
  }
};
var RPairlist = class extends RObject {
  constructor(val) {
    if (val instanceof RObjectBase) {
      assertRType(val, "pairlist");
      super(val);
      return this;
    }
    const prot = { n: 0 };
    try {
      const { names, values } = toWebRData(val);
      const list = RPairlist.wrap(Module2._Rf_allocList(values.length));
      protectInc(list, prot);
      for (let [i, next] = [0, list]; !next.isNull(); [i, next] = [i + 1, next.cdr()]) {
        next.setcar(new RObject(values[i]));
      }
      list.setNames(names);
      super(list);
    } finally {
      unprotect(prot.n);
    }
  }
  get length() {
    return this.toArray().length;
  }
  toArray(options = { depth: 1 }) {
    return this.toJs(options).values;
  }
  toObject({
    allowDuplicateKey = true,
    allowEmptyKey = false,
    depth = -1
  } = {}) {
    const entries = this.entries({ depth });
    const keys = entries.map(([k]) => k);
    if (!allowDuplicateKey && new Set(keys).size !== keys.length) {
      throw new Error("Duplicate key when converting pairlist without allowDuplicateKey enabled");
    }
    if (!allowEmptyKey && keys.some((k) => !k)) {
      throw new Error("Empty or null key when converting pairlist without allowEmptyKey enabled");
    }
    return Object.fromEntries(
      entries.filter((u, idx) => entries.findIndex((v) => v[0] === u[0]) === idx)
    );
  }
  entries(options = { depth: 1 }) {
    const obj = this.toJs(options);
    return obj.values.map((v, i) => [obj.names ? obj.names[i] : null, v]);
  }
  toJs(options = { depth: 0 }, depth = 1) {
    const namesArray = [];
    let hasNames = false;
    const values = [];
    for (let next = this; !next.isNull(); next = next.cdr()) {
      const symbol = next.tag();
      if (symbol.isNull()) {
        namesArray.push("");
      } else {
        hasNames = true;
        namesArray.push(symbol.toString());
      }
      if (options.depth && depth >= options.depth) {
        values.push(next.car());
      } else {
        values.push(next.car().toJs(options, depth + 1));
      }
    }
    const names = hasNames ? namesArray : null;
    return { type: "pairlist", names, values };
  }
  includes(name) {
    return name in this.toObject();
  }
  setcar(obj) {
    Module2._SETCAR(this.ptr, obj.ptr);
  }
  car() {
    return RObject.wrap(Module2._CAR(this.ptr));
  }
  cdr() {
    return RObject.wrap(Module2._CDR(this.ptr));
  }
  tag() {
    return RObject.wrap(Module2._TAG(this.ptr));
  }
};
var RCall = class extends RObject {
  constructor(val) {
    if (val instanceof RObjectBase) {
      assertRType(val, "call");
      super(val);
      return this;
    }
    const prot = { n: 0 };
    try {
      const { values } = toWebRData(val);
      const objs2 = values.map((value) => protectInc(new RObject(value), prot));
      const call = RCall.wrap(Module2._Rf_allocVector(RTypeMap.call, values.length));
      protectInc(call, prot);
      for (let [i, next] = [0, call]; !next.isNull(); [i, next] = [i + 1, next.cdr()]) {
        next.setcar(objs2[i]);
      }
      super(call);
    } finally {
      unprotect(prot.n);
    }
  }
  setcar(obj) {
    Module2._SETCAR(this.ptr, obj.ptr);
  }
  car() {
    return RObject.wrap(Module2._CAR(this.ptr));
  }
  cdr() {
    return RObject.wrap(Module2._CDR(this.ptr));
  }
  eval() {
    return Module2.webr.evalR(this, { env: objs.baseEnv });
  }
  capture(options = {}) {
    return Module2.webr.captureR(this, options);
  }
  deparse() {
    const prot = { n: 0 };
    try {
      const call = Module2._Rf_lang2(
        new RSymbol("deparse1").ptr,
        Module2._Rf_lang2(new RSymbol("quote").ptr, this.ptr)
      );
      protectInc(call, prot);
      const val = RCharacter.wrap(safeEval(call, objs.baseEnv));
      protectInc(val, prot);
      return val.toString();
    } finally {
      unprotect(prot.n);
    }
  }
};
var RList = class extends RObject {
  constructor(val, names = null) {
    if (val instanceof RObjectBase) {
      assertRType(val, "list");
      super(val);
      if (names) {
        if (names.length !== this.length) {
          throw new Error(
            "Can't construct named `RList`. Supplied `names` must be the same length as the list."
          );
        }
        this.setNames(names);
      }
      return this;
    }
    const prot = { n: 0 };
    try {
      const data = toWebRData(val);
      const ptr = Module2._Rf_allocVector(RTypeMap.list, data.values.length);
      protectInc(ptr, prot);
      data.values.forEach((v, i) => {
        Module2._SET_VECTOR_ELT(ptr, i, new RObject(v).ptr);
      });
      const _names = names ? names : data.names;
      if (_names && _names.length !== data.values.length) {
        throw new Error(
          "Can't construct named `RList`. Supplied `names` must be the same length as the list."
        );
      }
      RObject.wrap(ptr).setNames(_names);
      super(new RObjectBase(ptr));
    } finally {
      unprotect(prot.n);
    }
  }
  get length() {
    return Module2._LENGTH(this.ptr);
  }
  isDataFrame() {
    const classes = RPairlist.wrap(Module2._ATTRIB(this.ptr)).get("class");
    return !classes.isNull() && classes.toArray().includes("data.frame");
  }
  toArray(options = { depth: 1 }) {
    return this.toJs(options).values;
  }
  toObject({
    allowDuplicateKey = true,
    allowEmptyKey = false,
    depth = -1
  } = {}) {
    const entries = this.entries({ depth });
    const keys = entries.map(([k]) => k);
    if (!allowDuplicateKey && new Set(keys).size !== keys.length) {
      throw new Error("Duplicate key when converting list without allowDuplicateKey enabled");
    }
    if (!allowEmptyKey && keys.some((k) => !k)) {
      throw new Error("Empty or null key when converting list without allowEmptyKey enabled");
    }
    return Object.fromEntries(
      entries.filter((u, idx) => entries.findIndex((v) => v[0] === u[0]) === idx)
    );
  }
  toD3() {
    if (!this.isDataFrame()) {
      throw new Error(
        "Can't convert R list object to D3 format. Object must be of class 'data.frame'."
      );
    }
    const entries = this.entries();
    return entries.reduce((a, entry) => {
      entry[1].forEach((v, j) => a[j] = Object.assign(a[j] || {}, { [entry[0]]: v }));
      return a;
    }, []);
  }
  entries(options = { depth: -1 }) {
    const obj = this.toJs(options);
    if (this.isDataFrame() && options.depth < 0) {
      obj.values = obj.values.map((v) => v.toArray());
    }
    return obj.values.map((v, i) => [obj.names ? obj.names[i] : null, v]);
  }
  toJs(options = { depth: 0 }, depth = 1) {
    return {
      type: "list",
      names: this.names(),
      values: [...Array(this.length).keys()].map((i) => {
        if (options.depth && depth >= options.depth) {
          return this.get(i + 1);
        } else {
          return this.get(i + 1).toJs(options, depth + 1);
        }
      })
    };
  }
};
var RDataFrame = class extends RList {
  constructor(val) {
    if (val instanceof RObjectBase) {
      super(val);
      if (!this.isDataFrame()) {
        throw new Error("Can't construct `RDataFrame`. Supplied R object is not a `data.frame`.");
      }
      return this;
    }
    return RDataFrame.fromObject(val);
  }
  static fromObject(obj) {
    const { names, values } = toWebRData(obj);
    const prot = { n: 0 };
    try {
      const hasNames = !!names && names.length > 0 && names.every((v) => v);
      const hasArrays = values.length > 0 && values.every((v) => {
        return Array.isArray(v) || ArrayBuffer.isView(v) || v instanceof ArrayBuffer;
      });
      if (hasNames && hasArrays) {
        const _values = values;
        const isConsistentLength = _values.every((a) => a.length === _values[0].length);
        const isAtomic = _values.every((a) => {
          return isAtomicType(a[0]) || isRVectorAtomic(a[0]);
        });
        if (isConsistentLength && isAtomic) {
          const listObj = new RList({
            type: "list",
            names,
            values: _values.map((a) => newObjectFromData(a))
          });
          protectInc(listObj, prot);
          const asDataFrame = new RCall([new RSymbol("as.data.frame"), listObj]);
          protectInc(asDataFrame, prot);
          return new RDataFrame(asDataFrame.eval());
        }
      }
    } finally {
      unprotect(prot.n);
    }
    throw new Error("Can't construct `data.frame`. Source object is not eligible.");
  }
  static fromD3(arr) {
    return this.fromObject(
      Object.fromEntries(Object.keys(arr[0]).map((k) => [k, arr.map((v) => v[k])]))
    );
  }
};
var RFunction = class extends RObject {
  exec(...args) {
    const prot = { n: 0 };
    try {
      const call = new RCall([this, ...args]);
      protectInc(call, prot);
      return call.eval();
    } finally {
      unprotect(prot.n);
    }
  }
  capture(options = {}, ...args) {
    const prot = { n: 0 };
    try {
      const call = new RCall([this, ...args]);
      protectInc(call, prot);
      return call.capture(options);
    } finally {
      unprotect(prot.n);
    }
  }
};
var RString = class extends RObject {
  // Unlike symbols, strings are not cached and must thus be protected
  constructor(x) {
    if (x instanceof RObjectBase) {
      assertRType(x, "string");
      super(x);
      return;
    }
    const name = Module2.allocateUTF8(x);
    try {
      super(new RObjectBase(Module2._Rf_mkChar(name)));
    } finally {
      Module2._free(name);
    }
  }
  toString() {
    return Module2.UTF8ToString(Module2._R_CHAR(this.ptr));
  }
  toJs() {
    return {
      type: "string",
      value: this.toString()
    };
  }
};
var REnvironment = class extends RObject {
  constructor(val = {}) {
    if (val instanceof RObjectBase) {
      assertRType(val, "environment");
      super(val);
      return this;
    }
    let nProt = 0;
    try {
      const { names, values } = toWebRData(val);
      const ptr = protect(Module2._R_NewEnv(objs.globalEnv.ptr, 0, 0));
      ++nProt;
      values.forEach((v, i) => {
        const name = names ? names[i] : null;
        if (!name) {
          throw new Error("Can't create object in new environment with empty symbol name");
        }
        const sym = new RSymbol(name);
        const vObj = protect(new RObject(v));
        try {
          envPoke(ptr, sym, vObj);
        } finally {
          unprotect(1);
        }
      });
      super(new RObjectBase(ptr));
    } finally {
      unprotect(nProt);
    }
  }
  ls(all = false, sorted = true) {
    const ls = RCharacter.wrap(Module2._R_lsInternal3(this.ptr, Number(all), Number(sorted)));
    return ls.toArray();
  }
  bind(name, value) {
    const sym = new RSymbol(name);
    const valueObj = protect(new RObject(value));
    try {
      envPoke(this, sym, valueObj);
    } finally {
      unprotect(1);
    }
  }
  names() {
    return this.ls(true, true);
  }
  frame() {
    return RObject.wrap(Module2._FRAME(this.ptr));
  }
  subset(prop) {
    if (typeof prop === "number") {
      throw new Error("Object of type environment is not subsettable");
    }
    return this.getDollar(prop);
  }
  toObject({ depth = -1 } = {}) {
    const symbols = this.names();
    return Object.fromEntries(
      [...Array(symbols.length).keys()].map((i) => {
        const value = this.getDollar(symbols[i]);
        return [symbols[i], depth < 0 ? value : value.toJs({ depth })];
      })
    );
  }
  toJs(options = { depth: 0 }, depth = 1) {
    const names = this.names();
    const values = [...Array(names.length).keys()].map((i) => {
      if (options.depth && depth >= options.depth) {
        return this.getDollar(names[i]);
      } else {
        return this.getDollar(names[i]).toJs(options, depth + 1);
      }
    });
    return {
      type: "environment",
      names,
      values
    };
  }
};
var RVectorAtomic = class extends RObject {
  constructor(val, kind, newSetter) {
    if (val instanceof RObjectBase) {
      assertRType(val, kind);
      super(val);
      return this;
    }
    const prot = { n: 0 };
    try {
      const { names, values } = toWebRData(val);
      const ptr = Module2._Rf_allocVector(RTypeMap[kind], values.length);
      protectInc(ptr, prot);
      values.forEach(newSetter(ptr));
      RObject.wrap(ptr).setNames(names);
      super(new RObjectBase(ptr));
    } finally {
      unprotect(prot.n);
    }
  }
  get length() {
    return Module2._LENGTH(this.ptr);
  }
  get(prop) {
    return super.get(prop);
  }
  subset(prop) {
    return super.subset(prop);
  }
  getDollar() {
    throw new Error("$ operator is invalid for atomic vectors");
  }
  detectMissing() {
    const prot = { n: 0 };
    try {
      const call = Module2._Rf_lang2(new RSymbol("is.na").ptr, this.ptr);
      protectInc(call, prot);
      const val = RLogical.wrap(safeEval(call, objs.baseEnv));
      protectInc(val, prot);
      const ret = val.toTypedArray();
      return Array.from(ret).map((elt) => Boolean(elt));
    } finally {
      unprotect(prot.n);
    }
  }
  toArray() {
    const arr = this.toTypedArray();
    return this.detectMissing().map((m, idx) => m ? null : arr[idx]);
  }
  toObject({ allowDuplicateKey = true, allowEmptyKey = false } = {}) {
    const entries = this.entries();
    const keys = entries.map(([k]) => k);
    if (!allowDuplicateKey && new Set(keys).size !== keys.length) {
      throw new Error(
        "Duplicate key when converting atomic vector without allowDuplicateKey enabled"
      );
    }
    if (!allowEmptyKey && keys.some((k) => !k)) {
      throw new Error(
        "Empty or null key when converting atomic vector without allowEmptyKey enabled"
      );
    }
    return Object.fromEntries(
      entries.filter((u, idx) => entries.findIndex((v) => v[0] === u[0]) === idx)
    );
  }
  entries() {
    const values = this.toArray();
    const names = this.names();
    return values.map((v, i) => [names ? names[i] : null, v]);
  }
  toJs() {
    return {
      type: this.type(),
      names: this.names(),
      values: this.toArray()
    };
  }
};
var _newSetter;
var _RLogical = class extends RVectorAtomic {
  constructor(val) {
    super(val, "logical", __privateGet(_RLogical, _newSetter));
  }
  getBoolean(idx) {
    return this.get(idx).toArray()[0];
  }
  toBoolean() {
    if (this.length !== 1) {
      throw new Error("Can't convert atomic vector of length > 1 to a scalar JS value");
    }
    const val = this.getBoolean(1);
    if (val === null) {
      throw new Error("Can't convert missing value `NA` to a JS boolean");
    }
    return val;
  }
  toTypedArray() {
    return new Int32Array(
      Module2.HEAP32.subarray(
        Module2._LOGICAL(this.ptr) / 4,
        Module2._LOGICAL(this.ptr) / 4 + this.length
      )
    );
  }
  toArray() {
    const arr = this.toTypedArray();
    return this.detectMissing().map((m, idx) => m ? null : Boolean(arr[idx]));
  }
};
var RLogical = _RLogical;
_newSetter = new WeakMap();
__privateAdd(RLogical, _newSetter, (ptr) => {
  const data = Module2._LOGICAL(ptr);
  const naLogical = Module2.getValue(Module2._R_NaInt, "i32");
  return (v, i) => {
    Module2.setValue(data + 4 * i, v === null ? naLogical : Boolean(v), "i32");
  };
});
var _newSetter2;
var _RInteger = class extends RVectorAtomic {
  constructor(val) {
    super(val, "integer", __privateGet(_RInteger, _newSetter2));
  }
  getNumber(idx) {
    return this.get(idx).toArray()[0];
  }
  toNumber() {
    if (this.length !== 1) {
      throw new Error("Can't convert atomic vector of length > 1 to a scalar JS value");
    }
    const val = this.getNumber(1);
    if (val === null) {
      throw new Error("Can't convert missing value `NA` to a JS number");
    }
    return val;
  }
  toTypedArray() {
    return new Int32Array(
      Module2.HEAP32.subarray(
        Module2._INTEGER(this.ptr) / 4,
        Module2._INTEGER(this.ptr) / 4 + this.length
      )
    );
  }
};
var RInteger = _RInteger;
_newSetter2 = new WeakMap();
__privateAdd(RInteger, _newSetter2, (ptr) => {
  const data = Module2._INTEGER(ptr);
  const naInteger = Module2.getValue(Module2._R_NaInt, "i32");
  return (v, i) => {
    Module2.setValue(data + 4 * i, v === null ? naInteger : Math.round(Number(v)), "i32");
  };
});
var _newSetter3;
var _RDouble = class extends RVectorAtomic {
  constructor(val) {
    super(val, "double", __privateGet(_RDouble, _newSetter3));
  }
  getNumber(idx) {
    return this.get(idx).toArray()[0];
  }
  toNumber() {
    if (this.length !== 1) {
      throw new Error("Can't convert atomic vector of length > 1 to a scalar JS value");
    }
    const val = this.getNumber(1);
    if (val === null) {
      throw new Error("Can't convert missing value `NA` to a JS number");
    }
    return val;
  }
  toTypedArray() {
    return new Float64Array(
      Module2.HEAPF64.subarray(Module2._REAL(this.ptr) / 8, Module2._REAL(this.ptr) / 8 + this.length)
    );
  }
};
var RDouble = _RDouble;
_newSetter3 = new WeakMap();
__privateAdd(RDouble, _newSetter3, (ptr) => {
  const data = Module2._REAL(ptr);
  const naDouble = Module2.getValue(Module2._R_NaReal, "double");
  return (v, i) => {
    Module2.setValue(data + 8 * i, v === null ? naDouble : v, "double");
  };
});
var _newSetter4;
var _RComplex = class extends RVectorAtomic {
  constructor(val) {
    super(val, "complex", __privateGet(_RComplex, _newSetter4));
  }
  getComplex(idx) {
    return this.get(idx).toArray()[0];
  }
  toComplex() {
    if (this.length !== 1) {
      throw new Error("Can't convert atomic vector of length > 1 to a scalar JS value");
    }
    const val = this.getComplex(1);
    if (val === null) {
      throw new Error("Can't convert missing value `NA` to a JS object");
    }
    return val;
  }
  toTypedArray() {
    return new Float64Array(
      Module2.HEAPF64.subarray(
        Module2._COMPLEX(this.ptr) / 8,
        Module2._COMPLEX(this.ptr) / 8 + 2 * this.length
      )
    );
  }
  toArray() {
    const arr = this.toTypedArray();
    return this.detectMissing().map(
      (m, idx) => m ? null : { re: arr[2 * idx], im: arr[2 * idx + 1] }
    );
  }
};
var RComplex = _RComplex;
_newSetter4 = new WeakMap();
__privateAdd(RComplex, _newSetter4, (ptr) => {
  const data = Module2._COMPLEX(ptr);
  const naDouble = Module2.getValue(Module2._R_NaReal, "double");
  return (v, i) => {
    Module2.setValue(data + 8 * (2 * i), v === null ? naDouble : v.re, "double");
    Module2.setValue(data + 8 * (2 * i + 1), v === null ? naDouble : v.im, "double");
  };
});
var _newSetter5;
var _RCharacter = class extends RVectorAtomic {
  constructor(val) {
    super(val, "character", __privateGet(_RCharacter, _newSetter5));
  }
  getString(idx) {
    return this.get(idx).toArray()[0];
  }
  toString() {
    if (this.length !== 1) {
      throw new Error("Can't convert atomic vector of length > 1 to a scalar JS value");
    }
    const val = this.getString(1);
    if (val === null) {
      throw new Error("Can't convert missing value `NA` to a JS string");
    }
    return val;
  }
  toTypedArray() {
    return new Uint32Array(
      Module2.HEAPU32.subarray(
        Module2._STRING_PTR(this.ptr) / 4,
        Module2._STRING_PTR(this.ptr) / 4 + this.length
      )
    );
  }
  toArray() {
    return this.detectMissing().map(
      (m, idx) => m ? null : Module2.UTF8ToString(Module2._R_CHAR(Module2._STRING_ELT(this.ptr, idx)))
    );
  }
};
var RCharacter = _RCharacter;
_newSetter5 = new WeakMap();
__privateAdd(RCharacter, _newSetter5, (ptr) => {
  return (v, i) => {
    if (v === null) {
      Module2._SET_STRING_ELT(ptr, i, objs.naString.ptr);
    } else {
      Module2._SET_STRING_ELT(ptr, i, new RString(v).ptr);
    }
  };
});
var _newSetter6;
var _RRaw = class extends RVectorAtomic {
  constructor(val) {
    if (val instanceof ArrayBuffer) {
      val = new Uint8Array(val);
    }
    super(val, "raw", __privateGet(_RRaw, _newSetter6));
  }
  getNumber(idx) {
    return this.get(idx).toArray()[0];
  }
  toNumber() {
    if (this.length !== 1) {
      throw new Error("Can't convert atomic vector of length > 1 to a scalar JS value");
    }
    const val = this.getNumber(1);
    if (val === null) {
      throw new Error("Can't convert missing value `NA` to a JS number");
    }
    return val;
  }
  toTypedArray() {
    return new Uint8Array(
      Module2.HEAPU8.subarray(Module2._RAW(this.ptr), Module2._RAW(this.ptr) + this.length)
    );
  }
};
var RRaw = _RRaw;
_newSetter6 = new WeakMap();
__privateAdd(RRaw, _newSetter6, (ptr) => {
  const data = Module2._RAW(ptr);
  return (v, i) => {
    Module2.setValue(data + i, Number(v), "i8");
  };
});
function toWebRData(jsObj) {
  if (isWebRDataJs(jsObj)) {
    return jsObj;
  } else if (Array.isArray(jsObj) || ArrayBuffer.isView(jsObj)) {
    return { names: null, values: jsObj };
  } else if (jsObj && typeof jsObj === "object" && !isComplex(jsObj)) {
    return {
      names: Object.keys(jsObj),
      values: Object.values(jsObj)
    };
  }
  return { names: null, values: [jsObj] };
}
function getRWorkerClass(type) {
  const typeClasses = {
    object: RObject,
    null: RNull,
    symbol: RSymbol,
    pairlist: RPairlist,
    closure: RFunction,
    environment: REnvironment,
    call: RCall,
    special: RFunction,
    builtin: RFunction,
    string: RString,
    logical: RLogical,
    integer: RInteger,
    double: RDouble,
    complex: RComplex,
    character: RCharacter,
    list: RList,
    raw: RRaw,
    function: RFunction,
    dataframe: RDataFrame
  };
  if (type in typeClasses) {
    return typeClasses[type];
  }
  return RObject;
}
function isRObject(value) {
  return value instanceof RObject;
}
function isRVectorAtomic(value) {
  const atomicRTypes = ["logical", "integer", "double", "complex", "character"];
  return isRObject(value) && atomicRTypes.includes(value.type()) || isRObject(value) && value.isNa();
}
function isAtomicType(value) {
  return value === null || typeof value === "number" || typeof value === "boolean" || typeof value === "string" || isComplex(value);
}
var objs;
function initPersistentObjects() {
  objs = {
    baseEnv: REnvironment.wrap(Module2.getValue(Module2._R_BaseEnv, "*")),
    bracket2Symbol: RSymbol.wrap(Module2.getValue(Module2._R_Bracket2Symbol, "*")),
    bracketSymbol: RSymbol.wrap(Module2.getValue(Module2._R_BracketSymbol, "*")),
    dollarSymbol: RSymbol.wrap(Module2.getValue(Module2._R_DollarSymbol, "*")),
    emptyEnv: REnvironment.wrap(Module2.getValue(Module2._R_EmptyEnv, "*")),
    false: RLogical.wrap(Module2.getValue(Module2._R_FalseValue, "*")),
    globalEnv: REnvironment.wrap(Module2.getValue(Module2._R_GlobalEnv, "*")),
    na: RLogical.wrap(Module2.getValue(Module2._R_LogicalNAValue, "*")),
    namesSymbol: RSymbol.wrap(Module2.getValue(Module2._R_NamesSymbol, "*")),
    naString: RObject.wrap(Module2.getValue(Module2._R_NaString, "*")),
    null: RNull.wrap(Module2.getValue(Module2._R_NilValue, "*")),
    true: RLogical.wrap(Module2.getValue(Module2._R_TrueValue, "*")),
    unboundValue: RObject.wrap(Module2.getValue(Module2._R_UnboundValue, "*"))
  };
}

// webR/utils.ts
function promiseHandles() {
  const out = {
    resolve: () => {
      return;
    },
    reject: () => {
      return;
    },
    promise: Promise.resolve()
  };
  const promise = new Promise((resolve, reject) => {
    out.resolve = resolve;
    out.reject = reject;
  });
  out.promise = promise;
  return out;
}
function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
function replaceInObject(obj, test, replacer, ...replacerArgs) {
  if (obj === null || obj === void 0 || isImageBitmap(obj)) {
    return obj;
  }
  if (obj instanceof ArrayBuffer) {
    return new Uint8Array(obj);
  }
  if (test(obj)) {
    return replacer(obj, ...replacerArgs);
  }
  if (Array.isArray(obj) || ArrayBuffer.isView(obj)) {
    return obj.map(
      (v) => replaceInObject(v, test, replacer, ...replacerArgs)
    );
  }
  if (obj instanceof RObjectBase) {
    return obj;
  }
  if (typeof obj === "object") {
    return Object.fromEntries(
      Object.entries(obj).map(([k, v]) => [k, replaceInObject(v, test, replacer, ...replacerArgs)])
    );
  }
  return obj;
}
function newCrossOriginWorker(url, cb) {
  const req = new XMLHttpRequest();
  req.open("get", url, true);
  req.onload = () => {
    const worker = new Worker(URL.createObjectURL(new Blob([req.responseText])));
    cb(worker);
  };
  req.send();
}
function isCrossOrigin(urlString) {
  if (IN_NODE)
    return false;
  const url1 = new URL(location.href);
  const url2 = new URL(urlString, location.origin);
  if (url1.host === url2.host && url1.port === url2.port && url1.protocol === url2.protocol) {
    return false;
  }
  return true;
}
function isImageBitmap(value) {
  return typeof ImageBitmap !== "undefined" && value instanceof ImageBitmap;
}
function throwUnreachable(context) {
  let msg = "Reached the unreachable";
  msg = msg + (context ? ": " + context : ".");
  throw new WebRError(msg);
}

// webR/chan/task-main.ts
var import_msgpack = __toESM(require_dist());
var encoder = new TextEncoder();
async function syncResponse(endpoint, data, response) {
  try {
    let { taskId, sizeBuffer, dataBuffer, signalBuffer } = data;
    const bytes = (0, import_msgpack.encode)(response);
    const fits = bytes.length <= dataBuffer.length;
    Atomics.store(sizeBuffer, SZ_BUF_SIZE_IDX, bytes.length);
    Atomics.store(sizeBuffer, SZ_BUF_FITS_IDX, +fits);
    if (!fits) {
      const [uuid, dataPromise] = requestResponseMessage(endpoint);
      dataBuffer.set(encoder.encode(uuid));
      await signalRequester(signalBuffer, taskId);
      dataBuffer = (await dataPromise).dataBuffer;
    }
    dataBuffer.set(bytes);
    Atomics.store(sizeBuffer, SZ_BUF_FITS_IDX, 1);
    await signalRequester(signalBuffer, taskId);
  } catch (e) {
    console.warn(e);
  }
}
function requestResponseMessage(ep) {
  const id = generateUUID();
  return [
    id,
    new Promise((resolve) => {
      if (IN_NODE) {
        ep.once("message", (message) => {
          if (!message.id || message.id !== id) {
            return;
          }
          resolve(message);
        });
      } else {
        ep.addEventListener("message", function l(ev) {
          if (!ev.data || !ev.data.id || ev.data.id !== id) {
            return;
          }
          ep.removeEventListener("message", l);
          resolve(ev.data);
        });
      }
      if (ep.start) {
        ep.start();
      }
    })
  ];
}
async function signalRequester(signalBuffer, taskId) {
  const index = (taskId >> 1) % 32;
  let sleepTime = 1;
  while (Atomics.compareExchange(signalBuffer, index + 1, 0, taskId) !== 0) {
    await sleep(sleepTime);
    if (sleepTime < 32) {
      sleepTime *= 2;
    }
  }
  Atomics.or(signalBuffer, 0, 1 << index);
  Atomics.notify(signalBuffer, 0);
}

// webR/chan/queue.ts
var _promises, _resolvers, _add, add_fn;
var AsyncQueue = class {
  constructor() {
    __privateAdd(this, _add);
    __privateAdd(this, _promises, void 0);
    __privateAdd(this, _resolvers, void 0);
    __privateSet(this, _resolvers, []);
    __privateSet(this, _promises, []);
  }
  reset() {
    __privateSet(this, _resolvers, []);
    __privateSet(this, _promises, []);
  }
  put(t) {
    if (!__privateGet(this, _resolvers).length) {
      __privateMethod(this, _add, add_fn).call(this);
    }
    const resolve = __privateGet(this, _resolvers).shift();
    resolve(t);
  }
  async get() {
    if (!__privateGet(this, _promises).length) {
      __privateMethod(this, _add, add_fn).call(this);
    }
    const promise = __privateGet(this, _promises).shift();
    return promise;
  }
  isEmpty() {
    return !__privateGet(this, _promises).length;
  }
  isBlocked() {
    return !!__privateGet(this, _resolvers).length;
  }
  get length() {
    return __privateGet(this, _promises).length - __privateGet(this, _resolvers).length;
  }
};
_promises = new WeakMap();
_resolvers = new WeakMap();
_add = new WeakSet();
add_fn = function() {
  __privateGet(this, _promises).push(
    new Promise((resolve) => {
      __privateGet(this, _resolvers).push(resolve);
    })
  );
};

// webR/chan/message.ts
function newRequest(msg, transferables) {
  return newRequestResponseMessage(
    {
      type: "request",
      data: {
        uuid: generateUUID(),
        msg
      }
    },
    transferables
  );
}
function newResponse(uuid, resp, transferables) {
  return newRequestResponseMessage(
    {
      type: "response",
      data: {
        uuid,
        resp
      }
    },
    transferables
  );
}
function newRequestResponseMessage(msg, transferables) {
  if (transferables) {
    transfer(msg, transferables);
  }
  return msg;
}
function newSyncRequest(msg, data) {
  return {
    type: "sync-request",
    data: { msg, reqData: data }
  };
}

// webR/payload.ts
function webRPayloadAsError(payload) {
  const e = new WebRWorkerError(payload.obj.message);
  if (payload.obj.name !== "Error") {
    e.name = payload.obj.name;
  }
  e.stack = payload.obj.stack;
  return e;
}
function isWebRPayload(value) {
  return !!value && typeof value === "object" && "payloadType" in value && "obj" in value;
}
function isWebRPayloadPtr(value) {
  return isWebRPayload(value) && value.payloadType === "ptr";
}

// webR/chan/channel.ts
var _parked, _closed;
var ChannelMain = class {
  constructor() {
    this.inputQueue = new AsyncQueue();
    this.outputQueue = new AsyncQueue();
    this.systemQueue = new AsyncQueue();
    __privateAdd(this, _parked, /* @__PURE__ */ new Map());
    __privateAdd(this, _closed, false);
  }
  async read() {
    return await this.outputQueue.get();
  }
  async flush() {
    const msg = [];
    while (!this.outputQueue.isEmpty()) {
      msg.push(await this.read());
    }
    return msg;
  }
  async readSystem() {
    return await this.systemQueue.get();
  }
  write(msg) {
    if (__privateGet(this, _closed)) {
      throw new WebRChannelError("The webR communication channel has been closed.");
    }
    this.inputQueue.put(msg);
  }
  async request(msg, transferables) {
    const req = newRequest(msg, transferables);
    const { resolve, reject, promise } = promiseHandles();
    __privateGet(this, _parked).set(req.data.uuid, { resolve, reject });
    this.write(req);
    return promise;
  }
  putClosedMessage() {
    __privateSet(this, _closed, true);
    this.outputQueue.put({ type: "closed" });
  }
  resolveResponse(msg) {
    const uuid = msg.data.uuid;
    const handles = __privateGet(this, _parked).get(uuid);
    if (handles) {
      const payload = msg.data.resp;
      __privateGet(this, _parked).delete(uuid);
      if (payload.payloadType === "err") {
        handles.reject(webRPayloadAsError(payload));
      } else {
        handles.resolve(payload);
      }
    } else {
      console.warn("Can't find request.");
    }
  }
};
_parked = new WeakMap();
_closed = new WeakMap();

// webR/chan/task-worker.ts
var import_msgpack2 = __toESM(require_dist());
var decoder = new TextDecoder("utf-8");
var _scheduled, _resolved, _result, _exception, _syncGen;
var SyncTask = class {
  constructor(endpoint, msg, transfers = []) {
    __privateAdd(this, _scheduled, false);
    __privateAdd(this, _resolved, void 0);
    __privateAdd(this, _result, void 0);
    __privateAdd(this, _exception, void 0);
    __privateAdd(this, _syncGen, void 0);
    this.syncifier = new _Syncifier();
    this.endpoint = endpoint;
    this.msg = msg;
    this.transfers = transfers;
    __privateSet(this, _resolved, false);
  }
  scheduleSync() {
    if (__privateGet(this, _scheduled)) {
      return;
    }
    __privateSet(this, _scheduled, true);
    this.syncifier.scheduleTask(this);
    __privateSet(this, _syncGen, this.doSync());
    __privateGet(this, _syncGen).next();
    return this;
  }
  poll() {
    if (!__privateGet(this, _scheduled)) {
      throw new Error("Task not synchronously scheduled");
    }
    const { done, value } = __privateGet(this, _syncGen).next();
    if (!done) {
      return false;
    }
    __privateSet(this, _resolved, true);
    __privateSet(this, _result, value);
    return true;
  }
  *doSync() {
    const { endpoint, msg, transfers } = this;
    const sizeBuffer = new Int32Array(new SharedArrayBuffer(8));
    const signalBuffer = this.signalBuffer;
    const taskId = this.taskId;
    let dataBuffer = acquireDataBuffer(UUID_LENGTH);
    const syncMsg = newSyncRequest(msg, {
      sizeBuffer,
      dataBuffer,
      signalBuffer,
      taskId
    });
    endpoint.postMessage(syncMsg, transfers);
    yield;
    if (Atomics.load(sizeBuffer, SZ_BUF_FITS_IDX) === SZ_BUF_DOESNT_FIT) {
      const id = decoder.decode(dataBuffer.slice(0, UUID_LENGTH));
      releaseDataBuffer(dataBuffer);
      const size2 = Atomics.load(sizeBuffer, SZ_BUF_SIZE_IDX);
      dataBuffer = acquireDataBuffer(size2);
      endpoint.postMessage({ id, dataBuffer });
      yield;
    }
    const size = Atomics.load(sizeBuffer, SZ_BUF_SIZE_IDX);
    return (0, import_msgpack2.decode)(dataBuffer.slice(0, size));
  }
  get result() {
    if (__privateGet(this, _exception)) {
      throw __privateGet(this, _exception);
    }
    if (__privateGet(this, _resolved)) {
      return __privateGet(this, _result);
    }
    throw new Error("Not ready.");
  }
  syncify() {
    this.scheduleSync();
    this.syncifier.syncifyTask(this);
    return this.result;
  }
};
_scheduled = new WeakMap();
_resolved = new WeakMap();
_result = new WeakMap();
_exception = new WeakMap();
_syncGen = new WeakMap();
var _Syncifier = class {
  constructor() {
    this.nextTaskId = new Int32Array([1]);
    this.signalBuffer = new Int32Array(new SharedArrayBuffer(32 * 4 + 4));
    this.tasks = /* @__PURE__ */ new Map();
  }
  scheduleTask(task) {
    task.taskId = this.nextTaskId[0];
    this.nextTaskId[0] += 2;
    task.signalBuffer = this.signalBuffer;
    this.tasks.set(task.taskId, task);
  }
  waitOnSignalBuffer() {
    const timeout = 50;
    for (; ; ) {
      const status = Atomics.wait(this.signalBuffer, 0, 0, timeout);
      switch (status) {
        case "ok":
        case "not-equal":
          return;
        case "timed-out":
          if (interruptBuffer[0] !== 0) {
            handleInterrupt();
          }
          break;
        default:
          throw new Error("Unreachable");
      }
    }
  }
  *tasksIdsToWakeup() {
    const flag = Atomics.load(this.signalBuffer, 0);
    for (let i = 0; i < 32; i++) {
      const bit = 1 << i;
      if (flag & bit) {
        Atomics.and(this.signalBuffer, 0, ~bit);
        const wokenTask = Atomics.exchange(this.signalBuffer, i + 1, 0);
        yield wokenTask;
      }
    }
  }
  pollTasks(task) {
    let result = false;
    for (const wokenTaskId of this.tasksIdsToWakeup()) {
      const wokenTask = this.tasks.get(wokenTaskId);
      if (!wokenTask) {
        throw new Error(`Assertion error: unknown taskId ${wokenTaskId}.`);
      }
      if (wokenTask.poll()) {
        this.tasks.delete(wokenTaskId);
        if (wokenTask === task) {
          result = true;
        }
      }
    }
    return result;
  }
  syncifyTask(task) {
    for (; ; ) {
      this.waitOnSignalBuffer();
      if (this.pollTasks(task)) {
        return;
      }
    }
  }
};
var dataBuffers = [];
function acquireDataBuffer(size) {
  const powerof2 = Math.ceil(Math.log2(size));
  if (!dataBuffers[powerof2]) {
    dataBuffers[powerof2] = [];
  }
  const result = dataBuffers[powerof2].pop();
  if (result) {
    result.fill(0);
    return result;
  }
  return new Uint8Array(new SharedArrayBuffer(2 ** powerof2));
}
function releaseDataBuffer(buffer) {
  const powerof2 = Math.ceil(Math.log2(buffer.byteLength));
  dataBuffers[powerof2].push(buffer);
}
var interruptBuffer = new Int32Array(new ArrayBuffer(4));
var handleInterrupt = () => {
  interruptBuffer[0] = 0;
  throw new Error("Interrupted!");
};
function setInterruptHandler(handler) {
  handleInterrupt = handler;
}
function setInterruptBuffer(buffer) {
  interruptBuffer = new Int32Array(buffer);
}

// webR/chan/channel-shared.ts
if (IN_NODE) {
  globalThis.Worker = require("worker_threads").Worker;
}
var _interruptBuffer, _handleEventsFromWorker, handleEventsFromWorker_fn, _onMessageFromWorker;
var SharedBufferChannelMain = class extends ChannelMain {
  constructor(config) {
    super();
    __privateAdd(this, _handleEventsFromWorker);
    __privateAdd(this, _interruptBuffer, void 0);
    this.close = () => {
      return;
    };
    __privateAdd(this, _onMessageFromWorker, async (worker, message) => {
      if (!message || !message.type) {
        return;
      }
      switch (message.type) {
        case "resolve":
          __privateSet(this, _interruptBuffer, new Int32Array(message.data));
          this.resolve();
          return;
        case "response":
          this.resolveResponse(message);
          return;
        case "system":
          this.systemQueue.put(message.data);
          return;
        default:
          this.outputQueue.put(message);
          return;
        case "sync-request": {
          const msg = message;
          const payload = msg.data.msg;
          const reqData = msg.data.reqData;
          switch (payload.type) {
            case "read": {
              const response = await this.inputQueue.get();
              await syncResponse(worker, reqData, response);
              break;
            }
            default:
              throw new WebRChannelError(`Unsupported request type '${payload.type}'.`);
          }
          return;
        }
        case "request":
          throw new WebRChannelError(
            "Can't send messages of type 'request' from a worker. Please Use 'sync-request' instead."
          );
      }
    });
    ({ resolve: this.resolve, reject: this.reject, promise: this.initialised } = promiseHandles());
    const initWorker = (worker) => {
      __privateMethod(this, _handleEventsFromWorker, handleEventsFromWorker_fn).call(this, worker);
      this.close = () => {
        worker.terminate();
        this.putClosedMessage();
      };
      const msg = {
        type: "init",
        data: { config, channelType: ChannelType.SharedArrayBuffer }
      };
      worker.postMessage(msg);
    };
    if (isCrossOrigin(config.baseUrl)) {
      newCrossOriginWorker(
        `${config.baseUrl}webr-worker.js`,
        (worker) => initWorker(worker)
      );
    } else {
      const worker = new Worker(`${config.baseUrl}webr-worker.js`);
      initWorker(worker);
    }
  }
  interrupt() {
    if (!__privateGet(this, _interruptBuffer)) {
      throw new WebRChannelError("Failed attempt to interrupt before initialising interruptBuffer");
    }
    this.inputQueue.reset();
    __privateGet(this, _interruptBuffer)[0] = 1;
  }
};
_interruptBuffer = new WeakMap();
_handleEventsFromWorker = new WeakSet();
handleEventsFromWorker_fn = function(worker) {
  if (IN_NODE) {
    worker.on("message", (message) => {
      void __privateGet(this, _onMessageFromWorker).call(this, worker, message);
    });
    worker.on("error", (ev) => {
      console.error(ev);
      this.reject(new WebRWorkerError(
        "An error occurred initialising the webR SharedBufferChannel worker."
      ));
    });
  } else {
    worker.onmessage = (ev) => __privateGet(this, _onMessageFromWorker).call(this, worker, ev.data);
    worker.onerror = (ev) => {
      console.error(ev);
      this.reject(new WebRWorkerError(
        "An error occurred initialising the webR SharedBufferChannel worker."
      ));
    };
  }
};
_onMessageFromWorker = new WeakMap();
var _ep, _dispatch, _interruptBuffer2, _interrupt;
var SharedBufferChannelWorker = class {
  constructor() {
    __privateAdd(this, _ep, void 0);
    __privateAdd(this, _dispatch, () => 0);
    __privateAdd(this, _interruptBuffer2, new Int32Array(new SharedArrayBuffer(4)));
    __privateAdd(this, _interrupt, () => {
      return;
    });
    this.onMessageFromMainThread = () => {
      return;
    };
    __privateSet(this, _ep, IN_NODE ? require("worker_threads").parentPort : globalThis);
    setInterruptBuffer(__privateGet(this, _interruptBuffer2).buffer);
    setInterruptHandler(() => this.handleInterrupt());
  }
  resolve() {
    this.write({ type: "resolve", data: __privateGet(this, _interruptBuffer2).buffer });
  }
  write(msg, transfer2) {
    __privateGet(this, _ep).postMessage(msg, transfer2);
  }
  writeSystem(msg, transfer2) {
    __privateGet(this, _ep).postMessage({ type: "system", data: msg }, transfer2);
  }
  read() {
    const msg = { type: "read" };
    const task = new SyncTask(__privateGet(this, _ep), msg);
    return task.syncify();
  }
  inputOrDispatch() {
    for (; ; ) {
      const msg = this.read();
      if (msg.type === "stdin") {
        return Module2.allocateUTF8(msg.data);
      }
      __privateGet(this, _dispatch).call(this, msg);
    }
  }
  run(args) {
    try {
      Module2.callMain(args);
    } catch (e) {
      if (e instanceof WebAssembly.RuntimeError) {
        this.writeSystem({ type: "console.error", data: e.message });
        this.writeSystem({
          type: "console.error",
          data: "An unrecoverable WebAssembly error has occurred, the webR worker will be closed."
        });
        this.writeSystem({ type: "close" });
      }
      throw e;
    }
  }
  setInterrupt(interrupt) {
    __privateSet(this, _interrupt, interrupt);
  }
  handleInterrupt() {
    if (__privateGet(this, _interruptBuffer2)[0] !== 0) {
      __privateGet(this, _interruptBuffer2)[0] = 0;
      __privateGet(this, _interrupt).call(this);
    }
  }
  setDispatchHandler(dispatch2) {
    __privateSet(this, _dispatch, dispatch2);
  }
};
_ep = new WeakMap();
_dispatch = new WeakMap();
_interruptBuffer2 = new WeakMap();
_interrupt = new WeakMap();

// webR/chan/channel-service.ts
var import_msgpack3 = __toESM(require_dist());
if (IN_NODE) {
  globalThis.Worker = require("worker_threads").Worker;
}
var _syncMessageCache, _registration, _interrupted, _registerServiceWorker, registerServiceWorker_fn, _onMessageFromServiceWorker, onMessageFromServiceWorker_fn, _handleEventsFromWorker2, handleEventsFromWorker_fn2, _onMessageFromWorker2;
var ServiceWorkerChannelMain = class extends ChannelMain {
  constructor(config) {
    super();
    __privateAdd(this, _registerServiceWorker);
    __privateAdd(this, _onMessageFromServiceWorker);
    __privateAdd(this, _handleEventsFromWorker2);
    this.close = () => {
      return;
    };
    __privateAdd(this, _syncMessageCache, /* @__PURE__ */ new Map());
    __privateAdd(this, _registration, void 0);
    __privateAdd(this, _interrupted, false);
    __privateAdd(this, _onMessageFromWorker2, (worker, message) => {
      if (!message || !message.type) {
        return;
      }
      switch (message.type) {
        case "resolve":
          this.resolve();
          return;
        case "response":
          this.resolveResponse(message);
          return;
        case "system":
          this.systemQueue.put(message.data);
          return;
        default:
          this.outputQueue.put(message);
          return;
        case "sync-request": {
          const request = message.data;
          __privateGet(this, _syncMessageCache).set(request.data.uuid, request.data.msg);
          return;
        }
        case "request":
          throw new WebRChannelError(
            "Can't send messages of type 'request' from a worker.Use service worker fetch request instead."
          );
      }
    });
    ({ resolve: this.resolve, reject: this.reject, promise: this.initialised } = promiseHandles());
    console.warn(
      "The ServiceWorker communication channel is deprecated and will be removed in a future version of webR. Consider using the PostMessage channel instead. If blocking input is required (for example, `browser()`) the SharedArrayBuffer channel should be used. See https://docs.r-wasm.org/webr/latest/serving.html for further information."
    );
    const initWorker = (worker) => {
      __privateMethod(this, _handleEventsFromWorker2, handleEventsFromWorker_fn2).call(this, worker);
      this.close = () => {
        worker.terminate();
        this.putClosedMessage();
      };
      void __privateMethod(this, _registerServiceWorker, registerServiceWorker_fn).call(this, `${config.serviceWorkerUrl}webr-serviceworker.js`).then(
        (clientId) => {
          const msg = {
            type: "init",
            data: {
              config,
              channelType: ChannelType.ServiceWorker,
              clientId,
              location: window.location.href
            }
          };
          worker.postMessage(msg);
        }
      );
    };
    if (isCrossOrigin(config.serviceWorkerUrl)) {
      newCrossOriginWorker(
        `${config.serviceWorkerUrl}webr-worker.js`,
        (worker) => initWorker(worker)
      );
    } else {
      const worker = new Worker(`${config.serviceWorkerUrl}webr-worker.js`);
      initWorker(worker);
    }
  }
  activeRegistration() {
    var _a;
    if (!((_a = __privateGet(this, _registration)) == null ? void 0 : _a.active)) {
      throw new WebRChannelError("Attempted to obtain a non-existent active registration.");
    }
    return __privateGet(this, _registration).active;
  }
  interrupt() {
    __privateSet(this, _interrupted, true);
  }
};
_syncMessageCache = new WeakMap();
_registration = new WeakMap();
_interrupted = new WeakMap();
_registerServiceWorker = new WeakSet();
registerServiceWorker_fn = async function(url) {
  __privateSet(this, _registration, await navigator.serviceWorker.register(url));
  await navigator.serviceWorker.ready;
  window.addEventListener("beforeunload", () => {
    var _a;
    void ((_a = __privateGet(this, _registration)) == null ? void 0 : _a.unregister());
  });
  const clientId = await new Promise((resolve) => {
    navigator.serviceWorker.addEventListener(
      "message",
      function listener(event) {
        if (event.data.type === "registration-successful") {
          navigator.serviceWorker.removeEventListener("message", listener);
          resolve(event.data.clientId);
        }
      }
    );
    this.activeRegistration().postMessage({ type: "register-client-main" });
  });
  navigator.serviceWorker.addEventListener("message", (event) => {
    void __privateMethod(this, _onMessageFromServiceWorker, onMessageFromServiceWorker_fn).call(this, event);
  });
  return clientId;
};
_onMessageFromServiceWorker = new WeakSet();
onMessageFromServiceWorker_fn = async function(event) {
  if (event.data.type === "request") {
    const uuid = event.data.data;
    const message = __privateGet(this, _syncMessageCache).get(uuid);
    if (!message) {
      throw new WebRChannelError("Request not found during service worker XHR request");
    }
    __privateGet(this, _syncMessageCache).delete(uuid);
    switch (message.type) {
      case "read": {
        const response = await this.inputQueue.get();
        this.activeRegistration().postMessage({
          type: "wasm-webr-fetch-response",
          uuid,
          response: newResponse(uuid, response)
        });
        break;
      }
      case "interrupt": {
        const response = __privateGet(this, _interrupted);
        this.activeRegistration().postMessage({
          type: "wasm-webr-fetch-response",
          uuid,
          response: newResponse(uuid, response)
        });
        this.inputQueue.reset();
        __privateSet(this, _interrupted, false);
        break;
      }
      default:
        throw new WebRChannelError(`Unsupported request type '${message.type}'.`);
    }
    return;
  }
};
_handleEventsFromWorker2 = new WeakSet();
handleEventsFromWorker_fn2 = function(worker) {
  if (IN_NODE) {
    worker.on("message", (message) => {
      __privateGet(this, _onMessageFromWorker2).call(this, worker, message);
    });
    worker.on("error", (ev) => {
      console.error(ev);
      this.reject(new WebRWorkerError(
        "An error occurred initialising the webR ServiceWorkerChannel worker."
      ));
    });
  } else {
    worker.onmessage = (ev) => __privateGet(this, _onMessageFromWorker2).call(this, worker, ev.data);
    worker.onerror = (ev) => {
      console.error(ev);
      this.reject(new WebRWorkerError(
        "An error occurred initialising the webR ServiceWorkerChannel worker."
      ));
    };
  }
};
_onMessageFromWorker2 = new WeakMap();
var _ep2, _mainThreadId, _location, _lastInterruptReq, _dispatch2, _interrupt2;
var ServiceWorkerChannelWorker = class {
  constructor(data) {
    __privateAdd(this, _ep2, void 0);
    __privateAdd(this, _mainThreadId, void 0);
    __privateAdd(this, _location, void 0);
    __privateAdd(this, _lastInterruptReq, Date.now());
    __privateAdd(this, _dispatch2, () => 0);
    __privateAdd(this, _interrupt2, () => {
      return;
    });
    this.onMessageFromMainThread = () => {
      return;
    };
    if (!data.clientId || !data.location) {
      throw new WebRChannelError("Can't start service worker channel");
    }
    __privateSet(this, _mainThreadId, data.clientId);
    __privateSet(this, _location, data.location);
    __privateSet(this, _ep2, IN_NODE ? require("worker_threads").parentPort : globalThis);
  }
  resolve() {
    this.write({ type: "resolve" });
  }
  write(msg, transfer2) {
    __privateGet(this, _ep2).postMessage(msg, transfer2);
  }
  writeSystem(msg, transfer2) {
    __privateGet(this, _ep2).postMessage({ type: "system", data: msg }, transfer2);
  }
  syncRequest(message) {
    const request = newRequest(message);
    this.write({ type: "sync-request", data: request });
    let retryCount = 0;
    for (; ; ) {
      try {
        const url = new URL("__wasm__/webr-fetch-request/", __privateGet(this, _location));
        const xhr = new XMLHttpRequest();
        xhr.timeout = 6e4;
        xhr.responseType = "arraybuffer";
        xhr.open("POST", url, false);
        const fetchReqBody = {
          clientId: __privateGet(this, _mainThreadId),
          uuid: request.data.uuid
        };
        xhr.send((0, import_msgpack3.encode)(fetchReqBody));
        return (0, import_msgpack3.decode)(xhr.response);
      } catch (e) {
        if (e instanceof DOMException && retryCount++ < 1e3) {
          console.log("Service worker request failed - resending request");
        } else {
          throw e;
        }
      }
    }
  }
  read() {
    const response = this.syncRequest({ type: "read" });
    return response.data.resp;
  }
  inputOrDispatch() {
    for (; ; ) {
      const msg = this.read();
      if (msg.type === "stdin") {
        return Module2.allocateUTF8(msg.data);
      }
      __privateGet(this, _dispatch2).call(this, msg);
    }
  }
  run(args) {
    try {
      Module2.callMain(args);
    } catch (e) {
      if (e instanceof WebAssembly.RuntimeError) {
        this.writeSystem({ type: "console.error", data: e.message });
        this.writeSystem({
          type: "console.error",
          data: "An unrecoverable WebAssembly error has occurred, the webR worker will be closed."
        });
        this.writeSystem({ type: "close" });
      }
      throw e;
    }
  }
  setInterrupt(interrupt) {
    __privateSet(this, _interrupt2, interrupt);
  }
  handleInterrupt() {
    if (Date.now() > __privateGet(this, _lastInterruptReq) + 1e3) {
      __privateSet(this, _lastInterruptReq, Date.now());
      const response = this.syncRequest({ type: "interrupt" });
      const interrupted = response.data.resp;
      if (interrupted) {
        __privateGet(this, _interrupt2).call(this);
      }
    }
  }
  setDispatchHandler(dispatch2) {
    __privateSet(this, _dispatch2, dispatch2);
  }
};
_ep2 = new WeakMap();
_mainThreadId = new WeakMap();
_location = new WeakMap();
_lastInterruptReq = new WeakMap();
_dispatch2 = new WeakMap();
_interrupt2 = new WeakMap();

// webR/chan/channel-postmessage.ts
if (IN_NODE) {
  globalThis.Worker = require("worker_threads").Worker;
}
var _worker, _handleEventsFromWorker3, handleEventsFromWorker_fn3, _onMessageFromWorker3;
var PostMessageChannelMain = class extends ChannelMain {
  constructor(config) {
    super();
    __privateAdd(this, _handleEventsFromWorker3);
    this.close = () => {
      return;
    };
    __privateAdd(this, _worker, void 0);
    __privateAdd(this, _onMessageFromWorker3, async (worker, message) => {
      if (!message || !message.type) {
        return;
      }
      switch (message.type) {
        case "resolve":
          this.resolve();
          return;
        case "response":
          this.resolveResponse(message);
          return;
        case "system":
          this.systemQueue.put(message.data);
          return;
        default:
          this.outputQueue.put(message);
          return;
        case "request": {
          const msg = message;
          const payload = msg.data.msg;
          switch (payload.type) {
            case "read": {
              const input = await this.inputQueue.get();
              if (__privateGet(this, _worker)) {
                const response = newResponse(msg.data.uuid, input);
                __privateGet(this, _worker).postMessage(response);
              }
              break;
            }
            default:
              throw new WebRChannelError(`Unsupported request type '${payload.type}'.`);
          }
          return;
        }
        case "sync-request":
          throw new WebRChannelError(
            "Can't send messages of type 'sync-request' in PostMessage mode. Use 'request' instead."
          );
      }
    });
    ({ resolve: this.resolve, reject: this.reject, promise: this.initialised } = promiseHandles());
    const initWorker = (worker) => {
      __privateSet(this, _worker, worker);
      __privateMethod(this, _handleEventsFromWorker3, handleEventsFromWorker_fn3).call(this, worker);
      this.close = () => {
        worker.terminate();
        this.putClosedMessage();
      };
      const msg = {
        type: "init",
        data: { config, channelType: ChannelType.PostMessage }
      };
      worker.postMessage(msg);
    };
    if (isCrossOrigin(config.baseUrl)) {
      newCrossOriginWorker(
        `${config.baseUrl}webr-worker.js`,
        (worker) => initWorker(worker)
      );
    } else {
      const worker = new Worker(`${config.baseUrl}webr-worker.js`);
      initWorker(worker);
    }
  }
  interrupt() {
    console.error("Interrupting R execution is not available when using the PostMessage channel");
  }
};
_worker = new WeakMap();
_handleEventsFromWorker3 = new WeakSet();
handleEventsFromWorker_fn3 = function(worker) {
  if (IN_NODE) {
    worker.on("message", (message) => {
      void __privateGet(this, _onMessageFromWorker3).call(this, worker, message);
    });
    worker.on("error", (ev) => {
      console.error(ev);
      this.reject(new WebRWorkerError(
        "An error occurred initialising the webR PostMessageChannel worker."
      ));
    });
  } else {
    worker.onmessage = (ev) => __privateGet(this, _onMessageFromWorker3).call(this, worker, ev.data);
    worker.onerror = (ev) => {
      console.error(ev);
      this.reject(new WebRWorkerError(
        "An error occurred initialising the webR PostMessageChannel worker."
      ));
    };
  }
};
_onMessageFromWorker3 = new WeakMap();
var _ep3, _parked2, _dispatch3, _promptDepth, _asyncREPL;
var PostMessageChannelWorker = class {
  constructor() {
    __privateAdd(this, _ep3, void 0);
    __privateAdd(this, _parked2, /* @__PURE__ */ new Map());
    __privateAdd(this, _dispatch3, () => 0);
    __privateAdd(this, _promptDepth, 0);
    /*
     * This is a fallback REPL for webR running in PostMessage mode. The prompt
     * section of R's R_ReplDLLdo1 returns empty with -1, which allows this
     * fallback REPL to yield to the event loop with await.
     *
     * The drawback of this approach is that nested REPLs do not work, such as
     * readline, browser or menu. Attempting to use a nested REPL prints an error
     * to the JS console.
     *
     * R/Wasm errors during execution are caught and the REPL is restarted at the
     * top level. Any other JS errors are re-thrown.
     */
    __privateAdd(this, _asyncREPL, async () => {
      for (; ; ) {
        try {
          __privateSet(this, _promptDepth, 0);
          const msg = await this.request({ type: "read" });
          if (msg.type === "stdin") {
            const str = Module.allocateUTF8(msg.data);
            Module._strcpy(Module._DLLbuf, str);
            Module.setValue(Module._DLLbufp, Module._DLLbuf, "*");
            Module._free(str);
            try {
              while (Module._R_ReplDLLdo1() > 0)
                ;
            } catch (e) {
              if (e instanceof WebAssembly.Exception) {
                Module._R_ReplDLLinit();
                Module._R_ReplDLLdo1();
              } else {
                throw e;
              }
            }
          } else {
            __privateGet(this, _dispatch3).call(this, msg);
          }
        } catch (e) {
          if (e instanceof WebAssembly.RuntimeError) {
            this.writeSystem({ type: "console.error", data: e.message });
            this.writeSystem({
              type: "console.error",
              data: "An unrecoverable WebAssembly error has occurred, the webR worker will be closed."
            });
            this.writeSystem({ type: "close" });
          }
          if (!(e instanceof WebAssembly.Exception)) {
            throw e;
          }
        }
      }
    });
    __privateSet(this, _ep3, IN_NODE ? require("worker_threads").parentPort : globalThis);
  }
  resolve() {
    this.write({ type: "resolve" });
  }
  write(msg, transfer2) {
    __privateGet(this, _ep3).postMessage(msg, transfer2);
  }
  writeSystem(msg, transfer2) {
    __privateGet(this, _ep3).postMessage({ type: "system", data: msg }, transfer2);
  }
  read() {
    throw new WebRChannelError(
      "Unable to synchronously read when using the `PostMessage` channel."
    );
  }
  inputOrDispatch() {
    if (__privateGet(this, _promptDepth) > 0) {
      __privateSet(this, _promptDepth, 0);
      const msg = Module.allocateUTF8OnStack(
        "Can't block for input when using the PostMessage communication channel."
      );
      Module._Rf_error(msg);
    }
    __privateWrapper(this, _promptDepth)._++;
    return 0;
  }
  run(_args) {
    const args = _args || [];
    args.unshift("R");
    const argc = args.length;
    const argv = Module._malloc(4 * (argc + 1));
    args.forEach((arg, idx) => {
      const argvPtr = argv + 4 * idx;
      const argPtr = Module.allocateUTF8(arg);
      Module.setValue(argvPtr, argPtr, "*");
    });
    this.writeSystem({
      type: "console.warn",
      data: "WebR is using `PostMessage` communication channel, nested R REPLs are not available."
    });
    Module._Rf_initialize_R(argc, argv);
    Module._setup_Rmainloop();
    Module._R_ReplDLLinit();
    Module._R_ReplDLLdo1();
    void __privateGet(this, _asyncREPL).call(this);
  }
  setDispatchHandler(dispatch2) {
    __privateSet(this, _dispatch3, dispatch2);
  }
  async request(msg, transferables) {
    const req = newRequest(msg, transferables);
    const { resolve, promise: prom } = promiseHandles();
    __privateGet(this, _parked2).set(req.data.uuid, resolve);
    this.write(req);
    return prom;
  }
  setInterrupt() {
    return;
  }
  handleInterrupt() {
    return;
  }
  onMessageFromMainThread(message) {
    const msg = message;
    const uuid = msg.data.uuid;
    const resolve = __privateGet(this, _parked2).get(uuid);
    if (resolve) {
      __privateGet(this, _parked2).delete(uuid);
      resolve(msg.data.resp);
    } else {
      console.warn("Can't find request.");
    }
  }
};
_ep3 = new WeakMap();
_parked2 = new WeakMap();
_dispatch3 = new WeakMap();
_promptDepth = new WeakMap();
_asyncREPL = new WeakMap();

// webR/chan/channel-common.ts
var ChannelType = {
  Automatic: 0,
  SharedArrayBuffer: 1,
  ServiceWorker: 2,
  PostMessage: 3
};
function newChannelWorker(msg) {
  switch (msg.data.channelType) {
    case ChannelType.SharedArrayBuffer:
      return new SharedBufferChannelWorker();
    case ChannelType.ServiceWorker:
      return new ServiceWorkerChannelWorker(msg.data);
    case ChannelType.PostMessage:
      return new PostMessageChannelWorker();
    default:
      throw new WebRChannelError("Unknown worker channel type received");
  }
}

// node_modules/pako/dist/pako.esm.mjs
var Z_FIXED$1 = 4;
var Z_BINARY = 0;
var Z_TEXT = 1;
var Z_UNKNOWN$1 = 2;
function zero$1(buf) {
  let len = buf.length;
  while (--len >= 0) {
    buf[len] = 0;
  }
}
var STORED_BLOCK = 0;
var STATIC_TREES = 1;
var DYN_TREES = 2;
var MIN_MATCH$1 = 3;
var MAX_MATCH$1 = 258;
var LENGTH_CODES$1 = 29;
var LITERALS$1 = 256;
var L_CODES$1 = LITERALS$1 + 1 + LENGTH_CODES$1;
var D_CODES$1 = 30;
var BL_CODES$1 = 19;
var HEAP_SIZE$1 = 2 * L_CODES$1 + 1;
var MAX_BITS$1 = 15;
var Buf_size = 16;
var MAX_BL_BITS = 7;
var END_BLOCK = 256;
var REP_3_6 = 16;
var REPZ_3_10 = 17;
var REPZ_11_138 = 18;
var extra_lbits = (
  /* extra bits for each length code */
  new Uint8Array([0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0])
);
var extra_dbits = (
  /* extra bits for each distance code */
  new Uint8Array([0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13])
);
var extra_blbits = (
  /* extra bits for each bit length code */
  new Uint8Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 7])
);
var bl_order = new Uint8Array([16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15]);
var DIST_CODE_LEN = 512;
var static_ltree = new Array((L_CODES$1 + 2) * 2);
zero$1(static_ltree);
var static_dtree = new Array(D_CODES$1 * 2);
zero$1(static_dtree);
var _dist_code = new Array(DIST_CODE_LEN);
zero$1(_dist_code);
var _length_code = new Array(MAX_MATCH$1 - MIN_MATCH$1 + 1);
zero$1(_length_code);
var base_length = new Array(LENGTH_CODES$1);
zero$1(base_length);
var base_dist = new Array(D_CODES$1);
zero$1(base_dist);
function StaticTreeDesc(static_tree, extra_bits, extra_base, elems, max_length) {
  this.static_tree = static_tree;
  this.extra_bits = extra_bits;
  this.extra_base = extra_base;
  this.elems = elems;
  this.max_length = max_length;
  this.has_stree = static_tree && static_tree.length;
}
var static_l_desc;
var static_d_desc;
var static_bl_desc;
function TreeDesc(dyn_tree, stat_desc) {
  this.dyn_tree = dyn_tree;
  this.max_code = 0;
  this.stat_desc = stat_desc;
}
var d_code = (dist) => {
  return dist < 256 ? _dist_code[dist] : _dist_code[256 + (dist >>> 7)];
};
var put_short = (s, w) => {
  s.pending_buf[s.pending++] = w & 255;
  s.pending_buf[s.pending++] = w >>> 8 & 255;
};
var send_bits = (s, value, length) => {
  if (s.bi_valid > Buf_size - length) {
    s.bi_buf |= value << s.bi_valid & 65535;
    put_short(s, s.bi_buf);
    s.bi_buf = value >> Buf_size - s.bi_valid;
    s.bi_valid += length - Buf_size;
  } else {
    s.bi_buf |= value << s.bi_valid & 65535;
    s.bi_valid += length;
  }
};
var send_code = (s, c, tree) => {
  send_bits(
    s,
    tree[c * 2],
    tree[c * 2 + 1]
    /*.Len*/
  );
};
var bi_reverse = (code, len) => {
  let res = 0;
  do {
    res |= code & 1;
    code >>>= 1;
    res <<= 1;
  } while (--len > 0);
  return res >>> 1;
};
var bi_flush = (s) => {
  if (s.bi_valid === 16) {
    put_short(s, s.bi_buf);
    s.bi_buf = 0;
    s.bi_valid = 0;
  } else if (s.bi_valid >= 8) {
    s.pending_buf[s.pending++] = s.bi_buf & 255;
    s.bi_buf >>= 8;
    s.bi_valid -= 8;
  }
};
var gen_bitlen = (s, desc) => {
  const tree = desc.dyn_tree;
  const max_code = desc.max_code;
  const stree = desc.stat_desc.static_tree;
  const has_stree = desc.stat_desc.has_stree;
  const extra = desc.stat_desc.extra_bits;
  const base = desc.stat_desc.extra_base;
  const max_length = desc.stat_desc.max_length;
  let h;
  let n, m;
  let bits;
  let xbits;
  let f;
  let overflow = 0;
  for (bits = 0; bits <= MAX_BITS$1; bits++) {
    s.bl_count[bits] = 0;
  }
  tree[s.heap[s.heap_max] * 2 + 1] = 0;
  for (h = s.heap_max + 1; h < HEAP_SIZE$1; h++) {
    n = s.heap[h];
    bits = tree[tree[n * 2 + 1] * 2 + 1] + 1;
    if (bits > max_length) {
      bits = max_length;
      overflow++;
    }
    tree[n * 2 + 1] = bits;
    if (n > max_code) {
      continue;
    }
    s.bl_count[bits]++;
    xbits = 0;
    if (n >= base) {
      xbits = extra[n - base];
    }
    f = tree[n * 2];
    s.opt_len += f * (bits + xbits);
    if (has_stree) {
      s.static_len += f * (stree[n * 2 + 1] + xbits);
    }
  }
  if (overflow === 0) {
    return;
  }
  do {
    bits = max_length - 1;
    while (s.bl_count[bits] === 0) {
      bits--;
    }
    s.bl_count[bits]--;
    s.bl_count[bits + 1] += 2;
    s.bl_count[max_length]--;
    overflow -= 2;
  } while (overflow > 0);
  for (bits = max_length; bits !== 0; bits--) {
    n = s.bl_count[bits];
    while (n !== 0) {
      m = s.heap[--h];
      if (m > max_code) {
        continue;
      }
      if (tree[m * 2 + 1] !== bits) {
        s.opt_len += (bits - tree[m * 2 + 1]) * tree[m * 2];
        tree[m * 2 + 1] = bits;
      }
      n--;
    }
  }
};
var gen_codes = (tree, max_code, bl_count) => {
  const next_code = new Array(MAX_BITS$1 + 1);
  let code = 0;
  let bits;
  let n;
  for (bits = 1; bits <= MAX_BITS$1; bits++) {
    code = code + bl_count[bits - 1] << 1;
    next_code[bits] = code;
  }
  for (n = 0; n <= max_code; n++) {
    let len = tree[n * 2 + 1];
    if (len === 0) {
      continue;
    }
    tree[n * 2] = bi_reverse(next_code[len]++, len);
  }
};
var tr_static_init = () => {
  let n;
  let bits;
  let length;
  let code;
  let dist;
  const bl_count = new Array(MAX_BITS$1 + 1);
  length = 0;
  for (code = 0; code < LENGTH_CODES$1 - 1; code++) {
    base_length[code] = length;
    for (n = 0; n < 1 << extra_lbits[code]; n++) {
      _length_code[length++] = code;
    }
  }
  _length_code[length - 1] = code;
  dist = 0;
  for (code = 0; code < 16; code++) {
    base_dist[code] = dist;
    for (n = 0; n < 1 << extra_dbits[code]; n++) {
      _dist_code[dist++] = code;
    }
  }
  dist >>= 7;
  for (; code < D_CODES$1; code++) {
    base_dist[code] = dist << 7;
    for (n = 0; n < 1 << extra_dbits[code] - 7; n++) {
      _dist_code[256 + dist++] = code;
    }
  }
  for (bits = 0; bits <= MAX_BITS$1; bits++) {
    bl_count[bits] = 0;
  }
  n = 0;
  while (n <= 143) {
    static_ltree[n * 2 + 1] = 8;
    n++;
    bl_count[8]++;
  }
  while (n <= 255) {
    static_ltree[n * 2 + 1] = 9;
    n++;
    bl_count[9]++;
  }
  while (n <= 279) {
    static_ltree[n * 2 + 1] = 7;
    n++;
    bl_count[7]++;
  }
  while (n <= 287) {
    static_ltree[n * 2 + 1] = 8;
    n++;
    bl_count[8]++;
  }
  gen_codes(static_ltree, L_CODES$1 + 1, bl_count);
  for (n = 0; n < D_CODES$1; n++) {
    static_dtree[n * 2 + 1] = 5;
    static_dtree[n * 2] = bi_reverse(n, 5);
  }
  static_l_desc = new StaticTreeDesc(static_ltree, extra_lbits, LITERALS$1 + 1, L_CODES$1, MAX_BITS$1);
  static_d_desc = new StaticTreeDesc(static_dtree, extra_dbits, 0, D_CODES$1, MAX_BITS$1);
  static_bl_desc = new StaticTreeDesc(new Array(0), extra_blbits, 0, BL_CODES$1, MAX_BL_BITS);
};
var init_block = (s) => {
  let n;
  for (n = 0; n < L_CODES$1; n++) {
    s.dyn_ltree[n * 2] = 0;
  }
  for (n = 0; n < D_CODES$1; n++) {
    s.dyn_dtree[n * 2] = 0;
  }
  for (n = 0; n < BL_CODES$1; n++) {
    s.bl_tree[n * 2] = 0;
  }
  s.dyn_ltree[END_BLOCK * 2] = 1;
  s.opt_len = s.static_len = 0;
  s.sym_next = s.matches = 0;
};
var bi_windup = (s) => {
  if (s.bi_valid > 8) {
    put_short(s, s.bi_buf);
  } else if (s.bi_valid > 0) {
    s.pending_buf[s.pending++] = s.bi_buf;
  }
  s.bi_buf = 0;
  s.bi_valid = 0;
};
var smaller = (tree, n, m, depth) => {
  const _n2 = n * 2;
  const _m2 = m * 2;
  return tree[_n2] < tree[_m2] || tree[_n2] === tree[_m2] && depth[n] <= depth[m];
};
var pqdownheap = (s, tree, k) => {
  const v = s.heap[k];
  let j = k << 1;
  while (j <= s.heap_len) {
    if (j < s.heap_len && smaller(tree, s.heap[j + 1], s.heap[j], s.depth)) {
      j++;
    }
    if (smaller(tree, v, s.heap[j], s.depth)) {
      break;
    }
    s.heap[k] = s.heap[j];
    k = j;
    j <<= 1;
  }
  s.heap[k] = v;
};
var compress_block = (s, ltree, dtree) => {
  let dist;
  let lc;
  let sx = 0;
  let code;
  let extra;
  if (s.sym_next !== 0) {
    do {
      dist = s.pending_buf[s.sym_buf + sx++] & 255;
      dist += (s.pending_buf[s.sym_buf + sx++] & 255) << 8;
      lc = s.pending_buf[s.sym_buf + sx++];
      if (dist === 0) {
        send_code(s, lc, ltree);
      } else {
        code = _length_code[lc];
        send_code(s, code + LITERALS$1 + 1, ltree);
        extra = extra_lbits[code];
        if (extra !== 0) {
          lc -= base_length[code];
          send_bits(s, lc, extra);
        }
        dist--;
        code = d_code(dist);
        send_code(s, code, dtree);
        extra = extra_dbits[code];
        if (extra !== 0) {
          dist -= base_dist[code];
          send_bits(s, dist, extra);
        }
      }
    } while (sx < s.sym_next);
  }
  send_code(s, END_BLOCK, ltree);
};
var build_tree = (s, desc) => {
  const tree = desc.dyn_tree;
  const stree = desc.stat_desc.static_tree;
  const has_stree = desc.stat_desc.has_stree;
  const elems = desc.stat_desc.elems;
  let n, m;
  let max_code = -1;
  let node;
  s.heap_len = 0;
  s.heap_max = HEAP_SIZE$1;
  for (n = 0; n < elems; n++) {
    if (tree[n * 2] !== 0) {
      s.heap[++s.heap_len] = max_code = n;
      s.depth[n] = 0;
    } else {
      tree[n * 2 + 1] = 0;
    }
  }
  while (s.heap_len < 2) {
    node = s.heap[++s.heap_len] = max_code < 2 ? ++max_code : 0;
    tree[node * 2] = 1;
    s.depth[node] = 0;
    s.opt_len--;
    if (has_stree) {
      s.static_len -= stree[node * 2 + 1];
    }
  }
  desc.max_code = max_code;
  for (n = s.heap_len >> 1; n >= 1; n--) {
    pqdownheap(s, tree, n);
  }
  node = elems;
  do {
    n = s.heap[
      1
      /*SMALLEST*/
    ];
    s.heap[
      1
      /*SMALLEST*/
    ] = s.heap[s.heap_len--];
    pqdownheap(
      s,
      tree,
      1
      /*SMALLEST*/
    );
    m = s.heap[
      1
      /*SMALLEST*/
    ];
    s.heap[--s.heap_max] = n;
    s.heap[--s.heap_max] = m;
    tree[node * 2] = tree[n * 2] + tree[m * 2];
    s.depth[node] = (s.depth[n] >= s.depth[m] ? s.depth[n] : s.depth[m]) + 1;
    tree[n * 2 + 1] = tree[m * 2 + 1] = node;
    s.heap[
      1
      /*SMALLEST*/
    ] = node++;
    pqdownheap(
      s,
      tree,
      1
      /*SMALLEST*/
    );
  } while (s.heap_len >= 2);
  s.heap[--s.heap_max] = s.heap[
    1
    /*SMALLEST*/
  ];
  gen_bitlen(s, desc);
  gen_codes(tree, max_code, s.bl_count);
};
var scan_tree = (s, tree, max_code) => {
  let n;
  let prevlen = -1;
  let curlen;
  let nextlen = tree[0 * 2 + 1];
  let count = 0;
  let max_count = 7;
  let min_count = 4;
  if (nextlen === 0) {
    max_count = 138;
    min_count = 3;
  }
  tree[(max_code + 1) * 2 + 1] = 65535;
  for (n = 0; n <= max_code; n++) {
    curlen = nextlen;
    nextlen = tree[(n + 1) * 2 + 1];
    if (++count < max_count && curlen === nextlen) {
      continue;
    } else if (count < min_count) {
      s.bl_tree[curlen * 2] += count;
    } else if (curlen !== 0) {
      if (curlen !== prevlen) {
        s.bl_tree[curlen * 2]++;
      }
      s.bl_tree[REP_3_6 * 2]++;
    } else if (count <= 10) {
      s.bl_tree[REPZ_3_10 * 2]++;
    } else {
      s.bl_tree[REPZ_11_138 * 2]++;
    }
    count = 0;
    prevlen = curlen;
    if (nextlen === 0) {
      max_count = 138;
      min_count = 3;
    } else if (curlen === nextlen) {
      max_count = 6;
      min_count = 3;
    } else {
      max_count = 7;
      min_count = 4;
    }
  }
};
var send_tree = (s, tree, max_code) => {
  let n;
  let prevlen = -1;
  let curlen;
  let nextlen = tree[0 * 2 + 1];
  let count = 0;
  let max_count = 7;
  let min_count = 4;
  if (nextlen === 0) {
    max_count = 138;
    min_count = 3;
  }
  for (n = 0; n <= max_code; n++) {
    curlen = nextlen;
    nextlen = tree[(n + 1) * 2 + 1];
    if (++count < max_count && curlen === nextlen) {
      continue;
    } else if (count < min_count) {
      do {
        send_code(s, curlen, s.bl_tree);
      } while (--count !== 0);
    } else if (curlen !== 0) {
      if (curlen !== prevlen) {
        send_code(s, curlen, s.bl_tree);
        count--;
      }
      send_code(s, REP_3_6, s.bl_tree);
      send_bits(s, count - 3, 2);
    } else if (count <= 10) {
      send_code(s, REPZ_3_10, s.bl_tree);
      send_bits(s, count - 3, 3);
    } else {
      send_code(s, REPZ_11_138, s.bl_tree);
      send_bits(s, count - 11, 7);
    }
    count = 0;
    prevlen = curlen;
    if (nextlen === 0) {
      max_count = 138;
      min_count = 3;
    } else if (curlen === nextlen) {
      max_count = 6;
      min_count = 3;
    } else {
      max_count = 7;
      min_count = 4;
    }
  }
};
var build_bl_tree = (s) => {
  let max_blindex;
  scan_tree(s, s.dyn_ltree, s.l_desc.max_code);
  scan_tree(s, s.dyn_dtree, s.d_desc.max_code);
  build_tree(s, s.bl_desc);
  for (max_blindex = BL_CODES$1 - 1; max_blindex >= 3; max_blindex--) {
    if (s.bl_tree[bl_order[max_blindex] * 2 + 1] !== 0) {
      break;
    }
  }
  s.opt_len += 3 * (max_blindex + 1) + 5 + 5 + 4;
  return max_blindex;
};
var send_all_trees = (s, lcodes, dcodes, blcodes) => {
  let rank2;
  send_bits(s, lcodes - 257, 5);
  send_bits(s, dcodes - 1, 5);
  send_bits(s, blcodes - 4, 4);
  for (rank2 = 0; rank2 < blcodes; rank2++) {
    send_bits(s, s.bl_tree[bl_order[rank2] * 2 + 1], 3);
  }
  send_tree(s, s.dyn_ltree, lcodes - 1);
  send_tree(s, s.dyn_dtree, dcodes - 1);
};
var detect_data_type = (s) => {
  let block_mask = 4093624447;
  let n;
  for (n = 0; n <= 31; n++, block_mask >>>= 1) {
    if (block_mask & 1 && s.dyn_ltree[n * 2] !== 0) {
      return Z_BINARY;
    }
  }
  if (s.dyn_ltree[9 * 2] !== 0 || s.dyn_ltree[10 * 2] !== 0 || s.dyn_ltree[13 * 2] !== 0) {
    return Z_TEXT;
  }
  for (n = 32; n < LITERALS$1; n++) {
    if (s.dyn_ltree[n * 2] !== 0) {
      return Z_TEXT;
    }
  }
  return Z_BINARY;
};
var static_init_done = false;
var _tr_init$1 = (s) => {
  if (!static_init_done) {
    tr_static_init();
    static_init_done = true;
  }
  s.l_desc = new TreeDesc(s.dyn_ltree, static_l_desc);
  s.d_desc = new TreeDesc(s.dyn_dtree, static_d_desc);
  s.bl_desc = new TreeDesc(s.bl_tree, static_bl_desc);
  s.bi_buf = 0;
  s.bi_valid = 0;
  init_block(s);
};
var _tr_stored_block$1 = (s, buf, stored_len, last) => {
  send_bits(s, (STORED_BLOCK << 1) + (last ? 1 : 0), 3);
  bi_windup(s);
  put_short(s, stored_len);
  put_short(s, ~stored_len);
  if (stored_len) {
    s.pending_buf.set(s.window.subarray(buf, buf + stored_len), s.pending);
  }
  s.pending += stored_len;
};
var _tr_align$1 = (s) => {
  send_bits(s, STATIC_TREES << 1, 3);
  send_code(s, END_BLOCK, static_ltree);
  bi_flush(s);
};
var _tr_flush_block$1 = (s, buf, stored_len, last) => {
  let opt_lenb, static_lenb;
  let max_blindex = 0;
  if (s.level > 0) {
    if (s.strm.data_type === Z_UNKNOWN$1) {
      s.strm.data_type = detect_data_type(s);
    }
    build_tree(s, s.l_desc);
    build_tree(s, s.d_desc);
    max_blindex = build_bl_tree(s);
    opt_lenb = s.opt_len + 3 + 7 >>> 3;
    static_lenb = s.static_len + 3 + 7 >>> 3;
    if (static_lenb <= opt_lenb) {
      opt_lenb = static_lenb;
    }
  } else {
    opt_lenb = static_lenb = stored_len + 5;
  }
  if (stored_len + 4 <= opt_lenb && buf !== -1) {
    _tr_stored_block$1(s, buf, stored_len, last);
  } else if (s.strategy === Z_FIXED$1 || static_lenb === opt_lenb) {
    send_bits(s, (STATIC_TREES << 1) + (last ? 1 : 0), 3);
    compress_block(s, static_ltree, static_dtree);
  } else {
    send_bits(s, (DYN_TREES << 1) + (last ? 1 : 0), 3);
    send_all_trees(s, s.l_desc.max_code + 1, s.d_desc.max_code + 1, max_blindex + 1);
    compress_block(s, s.dyn_ltree, s.dyn_dtree);
  }
  init_block(s);
  if (last) {
    bi_windup(s);
  }
};
var _tr_tally$1 = (s, dist, lc) => {
  s.pending_buf[s.sym_buf + s.sym_next++] = dist;
  s.pending_buf[s.sym_buf + s.sym_next++] = dist >> 8;
  s.pending_buf[s.sym_buf + s.sym_next++] = lc;
  if (dist === 0) {
    s.dyn_ltree[lc * 2]++;
  } else {
    s.matches++;
    dist--;
    s.dyn_ltree[(_length_code[lc] + LITERALS$1 + 1) * 2]++;
    s.dyn_dtree[d_code(dist) * 2]++;
  }
  return s.sym_next === s.sym_end;
};
var _tr_init_1 = _tr_init$1;
var _tr_stored_block_1 = _tr_stored_block$1;
var _tr_flush_block_1 = _tr_flush_block$1;
var _tr_tally_1 = _tr_tally$1;
var _tr_align_1 = _tr_align$1;
var trees = {
  _tr_init: _tr_init_1,
  _tr_stored_block: _tr_stored_block_1,
  _tr_flush_block: _tr_flush_block_1,
  _tr_tally: _tr_tally_1,
  _tr_align: _tr_align_1
};
var adler32 = (adler, buf, len, pos) => {
  let s1 = adler & 65535 | 0, s2 = adler >>> 16 & 65535 | 0, n = 0;
  while (len !== 0) {
    n = len > 2e3 ? 2e3 : len;
    len -= n;
    do {
      s1 = s1 + buf[pos++] | 0;
      s2 = s2 + s1 | 0;
    } while (--n);
    s1 %= 65521;
    s2 %= 65521;
  }
  return s1 | s2 << 16 | 0;
};
var adler32_1 = adler32;
var makeTable = () => {
  let c, table = [];
  for (var n = 0; n < 256; n++) {
    c = n;
    for (var k = 0; k < 8; k++) {
      c = c & 1 ? 3988292384 ^ c >>> 1 : c >>> 1;
    }
    table[n] = c;
  }
  return table;
};
var crcTable = new Uint32Array(makeTable());
var crc32 = (crc, buf, len, pos) => {
  const t = crcTable;
  const end = pos + len;
  crc ^= -1;
  for (let i = pos; i < end; i++) {
    crc = crc >>> 8 ^ t[(crc ^ buf[i]) & 255];
  }
  return crc ^ -1;
};
var crc32_1 = crc32;
var messages = {
  2: "need dictionary",
  /* Z_NEED_DICT       2  */
  1: "stream end",
  /* Z_STREAM_END      1  */
  0: "",
  /* Z_OK              0  */
  "-1": "file error",
  /* Z_ERRNO         (-1) */
  "-2": "stream error",
  /* Z_STREAM_ERROR  (-2) */
  "-3": "data error",
  /* Z_DATA_ERROR    (-3) */
  "-4": "insufficient memory",
  /* Z_MEM_ERROR     (-4) */
  "-5": "buffer error",
  /* Z_BUF_ERROR     (-5) */
  "-6": "incompatible version"
  /* Z_VERSION_ERROR (-6) */
};
var constants$2 = {
  /* Allowed flush values; see deflate() and inflate() below for details */
  Z_NO_FLUSH: 0,
  Z_PARTIAL_FLUSH: 1,
  Z_SYNC_FLUSH: 2,
  Z_FULL_FLUSH: 3,
  Z_FINISH: 4,
  Z_BLOCK: 5,
  Z_TREES: 6,
  /* Return codes for the compression/decompression functions. Negative values
  * are errors, positive values are used for special but normal events.
  */
  Z_OK: 0,
  Z_STREAM_END: 1,
  Z_NEED_DICT: 2,
  Z_ERRNO: -1,
  Z_STREAM_ERROR: -2,
  Z_DATA_ERROR: -3,
  Z_MEM_ERROR: -4,
  Z_BUF_ERROR: -5,
  //Z_VERSION_ERROR: -6,
  /* compression levels */
  Z_NO_COMPRESSION: 0,
  Z_BEST_SPEED: 1,
  Z_BEST_COMPRESSION: 9,
  Z_DEFAULT_COMPRESSION: -1,
  Z_FILTERED: 1,
  Z_HUFFMAN_ONLY: 2,
  Z_RLE: 3,
  Z_FIXED: 4,
  Z_DEFAULT_STRATEGY: 0,
  /* Possible values of the data_type field (though see inflate()) */
  Z_BINARY: 0,
  Z_TEXT: 1,
  //Z_ASCII:                1, // = Z_TEXT (deprecated)
  Z_UNKNOWN: 2,
  /* The deflate compression method */
  Z_DEFLATED: 8
  //Z_NULL:                 null // Use -1 or null inline, depending on var type
};
var { _tr_init, _tr_stored_block, _tr_flush_block, _tr_tally, _tr_align } = trees;
var {
  Z_NO_FLUSH: Z_NO_FLUSH$2,
  Z_PARTIAL_FLUSH,
  Z_FULL_FLUSH: Z_FULL_FLUSH$1,
  Z_FINISH: Z_FINISH$3,
  Z_BLOCK: Z_BLOCK$1,
  Z_OK: Z_OK$3,
  Z_STREAM_END: Z_STREAM_END$3,
  Z_STREAM_ERROR: Z_STREAM_ERROR$2,
  Z_DATA_ERROR: Z_DATA_ERROR$2,
  Z_BUF_ERROR: Z_BUF_ERROR$1,
  Z_DEFAULT_COMPRESSION: Z_DEFAULT_COMPRESSION$1,
  Z_FILTERED,
  Z_HUFFMAN_ONLY,
  Z_RLE,
  Z_FIXED,
  Z_DEFAULT_STRATEGY: Z_DEFAULT_STRATEGY$1,
  Z_UNKNOWN,
  Z_DEFLATED: Z_DEFLATED$2
} = constants$2;
var MAX_MEM_LEVEL = 9;
var MAX_WBITS$1 = 15;
var DEF_MEM_LEVEL = 8;
var LENGTH_CODES = 29;
var LITERALS = 256;
var L_CODES = LITERALS + 1 + LENGTH_CODES;
var D_CODES = 30;
var BL_CODES = 19;
var HEAP_SIZE = 2 * L_CODES + 1;
var MAX_BITS = 15;
var MIN_MATCH = 3;
var MAX_MATCH = 258;
var MIN_LOOKAHEAD = MAX_MATCH + MIN_MATCH + 1;
var PRESET_DICT = 32;
var INIT_STATE = 42;
var GZIP_STATE = 57;
var EXTRA_STATE = 69;
var NAME_STATE = 73;
var COMMENT_STATE = 91;
var HCRC_STATE = 103;
var BUSY_STATE = 113;
var FINISH_STATE = 666;
var BS_NEED_MORE = 1;
var BS_BLOCK_DONE = 2;
var BS_FINISH_STARTED = 3;
var BS_FINISH_DONE = 4;
var OS_CODE = 3;
var err = (strm, errorCode) => {
  strm.msg = messages[errorCode];
  return errorCode;
};
var rank = (f) => {
  return f * 2 - (f > 4 ? 9 : 0);
};
var zero = (buf) => {
  let len = buf.length;
  while (--len >= 0) {
    buf[len] = 0;
  }
};
var slide_hash = (s) => {
  let n, m;
  let p;
  let wsize = s.w_size;
  n = s.hash_size;
  p = n;
  do {
    m = s.head[--p];
    s.head[p] = m >= wsize ? m - wsize : 0;
  } while (--n);
  n = wsize;
  p = n;
  do {
    m = s.prev[--p];
    s.prev[p] = m >= wsize ? m - wsize : 0;
  } while (--n);
};
var HASH_ZLIB = (s, prev, data) => (prev << s.hash_shift ^ data) & s.hash_mask;
var HASH = HASH_ZLIB;
var flush_pending = (strm) => {
  const s = strm.state;
  let len = s.pending;
  if (len > strm.avail_out) {
    len = strm.avail_out;
  }
  if (len === 0) {
    return;
  }
  strm.output.set(s.pending_buf.subarray(s.pending_out, s.pending_out + len), strm.next_out);
  strm.next_out += len;
  s.pending_out += len;
  strm.total_out += len;
  strm.avail_out -= len;
  s.pending -= len;
  if (s.pending === 0) {
    s.pending_out = 0;
  }
};
var flush_block_only = (s, last) => {
  _tr_flush_block(s, s.block_start >= 0 ? s.block_start : -1, s.strstart - s.block_start, last);
  s.block_start = s.strstart;
  flush_pending(s.strm);
};
var put_byte = (s, b) => {
  s.pending_buf[s.pending++] = b;
};
var putShortMSB = (s, b) => {
  s.pending_buf[s.pending++] = b >>> 8 & 255;
  s.pending_buf[s.pending++] = b & 255;
};
var read_buf = (strm, buf, start, size) => {
  let len = strm.avail_in;
  if (len > size) {
    len = size;
  }
  if (len === 0) {
    return 0;
  }
  strm.avail_in -= len;
  buf.set(strm.input.subarray(strm.next_in, strm.next_in + len), start);
  if (strm.state.wrap === 1) {
    strm.adler = adler32_1(strm.adler, buf, len, start);
  } else if (strm.state.wrap === 2) {
    strm.adler = crc32_1(strm.adler, buf, len, start);
  }
  strm.next_in += len;
  strm.total_in += len;
  return len;
};
var longest_match = (s, cur_match) => {
  let chain_length = s.max_chain_length;
  let scan = s.strstart;
  let match;
  let len;
  let best_len = s.prev_length;
  let nice_match = s.nice_match;
  const limit = s.strstart > s.w_size - MIN_LOOKAHEAD ? s.strstart - (s.w_size - MIN_LOOKAHEAD) : 0;
  const _win = s.window;
  const wmask = s.w_mask;
  const prev = s.prev;
  const strend = s.strstart + MAX_MATCH;
  let scan_end1 = _win[scan + best_len - 1];
  let scan_end = _win[scan + best_len];
  if (s.prev_length >= s.good_match) {
    chain_length >>= 2;
  }
  if (nice_match > s.lookahead) {
    nice_match = s.lookahead;
  }
  do {
    match = cur_match;
    if (_win[match + best_len] !== scan_end || _win[match + best_len - 1] !== scan_end1 || _win[match] !== _win[scan] || _win[++match] !== _win[scan + 1]) {
      continue;
    }
    scan += 2;
    match++;
    do {
    } while (_win[++scan] === _win[++match] && _win[++scan] === _win[++match] && _win[++scan] === _win[++match] && _win[++scan] === _win[++match] && _win[++scan] === _win[++match] && _win[++scan] === _win[++match] && _win[++scan] === _win[++match] && _win[++scan] === _win[++match] && scan < strend);
    len = MAX_MATCH - (strend - scan);
    scan = strend - MAX_MATCH;
    if (len > best_len) {
      s.match_start = cur_match;
      best_len = len;
      if (len >= nice_match) {
        break;
      }
      scan_end1 = _win[scan + best_len - 1];
      scan_end = _win[scan + best_len];
    }
  } while ((cur_match = prev[cur_match & wmask]) > limit && --chain_length !== 0);
  if (best_len <= s.lookahead) {
    return best_len;
  }
  return s.lookahead;
};
var fill_window = (s) => {
  const _w_size = s.w_size;
  let n, more, str;
  do {
    more = s.window_size - s.lookahead - s.strstart;
    if (s.strstart >= _w_size + (_w_size - MIN_LOOKAHEAD)) {
      s.window.set(s.window.subarray(_w_size, _w_size + _w_size - more), 0);
      s.match_start -= _w_size;
      s.strstart -= _w_size;
      s.block_start -= _w_size;
      if (s.insert > s.strstart) {
        s.insert = s.strstart;
      }
      slide_hash(s);
      more += _w_size;
    }
    if (s.strm.avail_in === 0) {
      break;
    }
    n = read_buf(s.strm, s.window, s.strstart + s.lookahead, more);
    s.lookahead += n;
    if (s.lookahead + s.insert >= MIN_MATCH) {
      str = s.strstart - s.insert;
      s.ins_h = s.window[str];
      s.ins_h = HASH(s, s.ins_h, s.window[str + 1]);
      while (s.insert) {
        s.ins_h = HASH(s, s.ins_h, s.window[str + MIN_MATCH - 1]);
        s.prev[str & s.w_mask] = s.head[s.ins_h];
        s.head[s.ins_h] = str;
        str++;
        s.insert--;
        if (s.lookahead + s.insert < MIN_MATCH) {
          break;
        }
      }
    }
  } while (s.lookahead < MIN_LOOKAHEAD && s.strm.avail_in !== 0);
};
var deflate_stored = (s, flush) => {
  let min_block = s.pending_buf_size - 5 > s.w_size ? s.w_size : s.pending_buf_size - 5;
  let len, left, have, last = 0;
  let used = s.strm.avail_in;
  do {
    len = 65535;
    have = s.bi_valid + 42 >> 3;
    if (s.strm.avail_out < have) {
      break;
    }
    have = s.strm.avail_out - have;
    left = s.strstart - s.block_start;
    if (len > left + s.strm.avail_in) {
      len = left + s.strm.avail_in;
    }
    if (len > have) {
      len = have;
    }
    if (len < min_block && (len === 0 && flush !== Z_FINISH$3 || flush === Z_NO_FLUSH$2 || len !== left + s.strm.avail_in)) {
      break;
    }
    last = flush === Z_FINISH$3 && len === left + s.strm.avail_in ? 1 : 0;
    _tr_stored_block(s, 0, 0, last);
    s.pending_buf[s.pending - 4] = len;
    s.pending_buf[s.pending - 3] = len >> 8;
    s.pending_buf[s.pending - 2] = ~len;
    s.pending_buf[s.pending - 1] = ~len >> 8;
    flush_pending(s.strm);
    if (left) {
      if (left > len) {
        left = len;
      }
      s.strm.output.set(s.window.subarray(s.block_start, s.block_start + left), s.strm.next_out);
      s.strm.next_out += left;
      s.strm.avail_out -= left;
      s.strm.total_out += left;
      s.block_start += left;
      len -= left;
    }
    if (len) {
      read_buf(s.strm, s.strm.output, s.strm.next_out, len);
      s.strm.next_out += len;
      s.strm.avail_out -= len;
      s.strm.total_out += len;
    }
  } while (last === 0);
  used -= s.strm.avail_in;
  if (used) {
    if (used >= s.w_size) {
      s.matches = 2;
      s.window.set(s.strm.input.subarray(s.strm.next_in - s.w_size, s.strm.next_in), 0);
      s.strstart = s.w_size;
      s.insert = s.strstart;
    } else {
      if (s.window_size - s.strstart <= used) {
        s.strstart -= s.w_size;
        s.window.set(s.window.subarray(s.w_size, s.w_size + s.strstart), 0);
        if (s.matches < 2) {
          s.matches++;
        }
        if (s.insert > s.strstart) {
          s.insert = s.strstart;
        }
      }
      s.window.set(s.strm.input.subarray(s.strm.next_in - used, s.strm.next_in), s.strstart);
      s.strstart += used;
      s.insert += used > s.w_size - s.insert ? s.w_size - s.insert : used;
    }
    s.block_start = s.strstart;
  }
  if (s.high_water < s.strstart) {
    s.high_water = s.strstart;
  }
  if (last) {
    return BS_FINISH_DONE;
  }
  if (flush !== Z_NO_FLUSH$2 && flush !== Z_FINISH$3 && s.strm.avail_in === 0 && s.strstart === s.block_start) {
    return BS_BLOCK_DONE;
  }
  have = s.window_size - s.strstart;
  if (s.strm.avail_in > have && s.block_start >= s.w_size) {
    s.block_start -= s.w_size;
    s.strstart -= s.w_size;
    s.window.set(s.window.subarray(s.w_size, s.w_size + s.strstart), 0);
    if (s.matches < 2) {
      s.matches++;
    }
    have += s.w_size;
    if (s.insert > s.strstart) {
      s.insert = s.strstart;
    }
  }
  if (have > s.strm.avail_in) {
    have = s.strm.avail_in;
  }
  if (have) {
    read_buf(s.strm, s.window, s.strstart, have);
    s.strstart += have;
    s.insert += have > s.w_size - s.insert ? s.w_size - s.insert : have;
  }
  if (s.high_water < s.strstart) {
    s.high_water = s.strstart;
  }
  have = s.bi_valid + 42 >> 3;
  have = s.pending_buf_size - have > 65535 ? 65535 : s.pending_buf_size - have;
  min_block = have > s.w_size ? s.w_size : have;
  left = s.strstart - s.block_start;
  if (left >= min_block || (left || flush === Z_FINISH$3) && flush !== Z_NO_FLUSH$2 && s.strm.avail_in === 0 && left <= have) {
    len = left > have ? have : left;
    last = flush === Z_FINISH$3 && s.strm.avail_in === 0 && len === left ? 1 : 0;
    _tr_stored_block(s, s.block_start, len, last);
    s.block_start += len;
    flush_pending(s.strm);
  }
  return last ? BS_FINISH_STARTED : BS_NEED_MORE;
};
var deflate_fast = (s, flush) => {
  let hash_head;
  let bflush;
  for (; ; ) {
    if (s.lookahead < MIN_LOOKAHEAD) {
      fill_window(s);
      if (s.lookahead < MIN_LOOKAHEAD && flush === Z_NO_FLUSH$2) {
        return BS_NEED_MORE;
      }
      if (s.lookahead === 0) {
        break;
      }
    }
    hash_head = 0;
    if (s.lookahead >= MIN_MATCH) {
      s.ins_h = HASH(s, s.ins_h, s.window[s.strstart + MIN_MATCH - 1]);
      hash_head = s.prev[s.strstart & s.w_mask] = s.head[s.ins_h];
      s.head[s.ins_h] = s.strstart;
    }
    if (hash_head !== 0 && s.strstart - hash_head <= s.w_size - MIN_LOOKAHEAD) {
      s.match_length = longest_match(s, hash_head);
    }
    if (s.match_length >= MIN_MATCH) {
      bflush = _tr_tally(s, s.strstart - s.match_start, s.match_length - MIN_MATCH);
      s.lookahead -= s.match_length;
      if (s.match_length <= s.max_lazy_match && s.lookahead >= MIN_MATCH) {
        s.match_length--;
        do {
          s.strstart++;
          s.ins_h = HASH(s, s.ins_h, s.window[s.strstart + MIN_MATCH - 1]);
          hash_head = s.prev[s.strstart & s.w_mask] = s.head[s.ins_h];
          s.head[s.ins_h] = s.strstart;
        } while (--s.match_length !== 0);
        s.strstart++;
      } else {
        s.strstart += s.match_length;
        s.match_length = 0;
        s.ins_h = s.window[s.strstart];
        s.ins_h = HASH(s, s.ins_h, s.window[s.strstart + 1]);
      }
    } else {
      bflush = _tr_tally(s, 0, s.window[s.strstart]);
      s.lookahead--;
      s.strstart++;
    }
    if (bflush) {
      flush_block_only(s, false);
      if (s.strm.avail_out === 0) {
        return BS_NEED_MORE;
      }
    }
  }
  s.insert = s.strstart < MIN_MATCH - 1 ? s.strstart : MIN_MATCH - 1;
  if (flush === Z_FINISH$3) {
    flush_block_only(s, true);
    if (s.strm.avail_out === 0) {
      return BS_FINISH_STARTED;
    }
    return BS_FINISH_DONE;
  }
  if (s.sym_next) {
    flush_block_only(s, false);
    if (s.strm.avail_out === 0) {
      return BS_NEED_MORE;
    }
  }
  return BS_BLOCK_DONE;
};
var deflate_slow = (s, flush) => {
  let hash_head;
  let bflush;
  let max_insert;
  for (; ; ) {
    if (s.lookahead < MIN_LOOKAHEAD) {
      fill_window(s);
      if (s.lookahead < MIN_LOOKAHEAD && flush === Z_NO_FLUSH$2) {
        return BS_NEED_MORE;
      }
      if (s.lookahead === 0) {
        break;
      }
    }
    hash_head = 0;
    if (s.lookahead >= MIN_MATCH) {
      s.ins_h = HASH(s, s.ins_h, s.window[s.strstart + MIN_MATCH - 1]);
      hash_head = s.prev[s.strstart & s.w_mask] = s.head[s.ins_h];
      s.head[s.ins_h] = s.strstart;
    }
    s.prev_length = s.match_length;
    s.prev_match = s.match_start;
    s.match_length = MIN_MATCH - 1;
    if (hash_head !== 0 && s.prev_length < s.max_lazy_match && s.strstart - hash_head <= s.w_size - MIN_LOOKAHEAD) {
      s.match_length = longest_match(s, hash_head);
      if (s.match_length <= 5 && (s.strategy === Z_FILTERED || s.match_length === MIN_MATCH && s.strstart - s.match_start > 4096)) {
        s.match_length = MIN_MATCH - 1;
      }
    }
    if (s.prev_length >= MIN_MATCH && s.match_length <= s.prev_length) {
      max_insert = s.strstart + s.lookahead - MIN_MATCH;
      bflush = _tr_tally(s, s.strstart - 1 - s.prev_match, s.prev_length - MIN_MATCH);
      s.lookahead -= s.prev_length - 1;
      s.prev_length -= 2;
      do {
        if (++s.strstart <= max_insert) {
          s.ins_h = HASH(s, s.ins_h, s.window[s.strstart + MIN_MATCH - 1]);
          hash_head = s.prev[s.strstart & s.w_mask] = s.head[s.ins_h];
          s.head[s.ins_h] = s.strstart;
        }
      } while (--s.prev_length !== 0);
      s.match_available = 0;
      s.match_length = MIN_MATCH - 1;
      s.strstart++;
      if (bflush) {
        flush_block_only(s, false);
        if (s.strm.avail_out === 0) {
          return BS_NEED_MORE;
        }
      }
    } else if (s.match_available) {
      bflush = _tr_tally(s, 0, s.window[s.strstart - 1]);
      if (bflush) {
        flush_block_only(s, false);
      }
      s.strstart++;
      s.lookahead--;
      if (s.strm.avail_out === 0) {
        return BS_NEED_MORE;
      }
    } else {
      s.match_available = 1;
      s.strstart++;
      s.lookahead--;
    }
  }
  if (s.match_available) {
    bflush = _tr_tally(s, 0, s.window[s.strstart - 1]);
    s.match_available = 0;
  }
  s.insert = s.strstart < MIN_MATCH - 1 ? s.strstart : MIN_MATCH - 1;
  if (flush === Z_FINISH$3) {
    flush_block_only(s, true);
    if (s.strm.avail_out === 0) {
      return BS_FINISH_STARTED;
    }
    return BS_FINISH_DONE;
  }
  if (s.sym_next) {
    flush_block_only(s, false);
    if (s.strm.avail_out === 0) {
      return BS_NEED_MORE;
    }
  }
  return BS_BLOCK_DONE;
};
var deflate_rle = (s, flush) => {
  let bflush;
  let prev;
  let scan, strend;
  const _win = s.window;
  for (; ; ) {
    if (s.lookahead <= MAX_MATCH) {
      fill_window(s);
      if (s.lookahead <= MAX_MATCH && flush === Z_NO_FLUSH$2) {
        return BS_NEED_MORE;
      }
      if (s.lookahead === 0) {
        break;
      }
    }
    s.match_length = 0;
    if (s.lookahead >= MIN_MATCH && s.strstart > 0) {
      scan = s.strstart - 1;
      prev = _win[scan];
      if (prev === _win[++scan] && prev === _win[++scan] && prev === _win[++scan]) {
        strend = s.strstart + MAX_MATCH;
        do {
        } while (prev === _win[++scan] && prev === _win[++scan] && prev === _win[++scan] && prev === _win[++scan] && prev === _win[++scan] && prev === _win[++scan] && prev === _win[++scan] && prev === _win[++scan] && scan < strend);
        s.match_length = MAX_MATCH - (strend - scan);
        if (s.match_length > s.lookahead) {
          s.match_length = s.lookahead;
        }
      }
    }
    if (s.match_length >= MIN_MATCH) {
      bflush = _tr_tally(s, 1, s.match_length - MIN_MATCH);
      s.lookahead -= s.match_length;
      s.strstart += s.match_length;
      s.match_length = 0;
    } else {
      bflush = _tr_tally(s, 0, s.window[s.strstart]);
      s.lookahead--;
      s.strstart++;
    }
    if (bflush) {
      flush_block_only(s, false);
      if (s.strm.avail_out === 0) {
        return BS_NEED_MORE;
      }
    }
  }
  s.insert = 0;
  if (flush === Z_FINISH$3) {
    flush_block_only(s, true);
    if (s.strm.avail_out === 0) {
      return BS_FINISH_STARTED;
    }
    return BS_FINISH_DONE;
  }
  if (s.sym_next) {
    flush_block_only(s, false);
    if (s.strm.avail_out === 0) {
      return BS_NEED_MORE;
    }
  }
  return BS_BLOCK_DONE;
};
var deflate_huff = (s, flush) => {
  let bflush;
  for (; ; ) {
    if (s.lookahead === 0) {
      fill_window(s);
      if (s.lookahead === 0) {
        if (flush === Z_NO_FLUSH$2) {
          return BS_NEED_MORE;
        }
        break;
      }
    }
    s.match_length = 0;
    bflush = _tr_tally(s, 0, s.window[s.strstart]);
    s.lookahead--;
    s.strstart++;
    if (bflush) {
      flush_block_only(s, false);
      if (s.strm.avail_out === 0) {
        return BS_NEED_MORE;
      }
    }
  }
  s.insert = 0;
  if (flush === Z_FINISH$3) {
    flush_block_only(s, true);
    if (s.strm.avail_out === 0) {
      return BS_FINISH_STARTED;
    }
    return BS_FINISH_DONE;
  }
  if (s.sym_next) {
    flush_block_only(s, false);
    if (s.strm.avail_out === 0) {
      return BS_NEED_MORE;
    }
  }
  return BS_BLOCK_DONE;
};
function Config(good_length, max_lazy, nice_length, max_chain, func) {
  this.good_length = good_length;
  this.max_lazy = max_lazy;
  this.nice_length = nice_length;
  this.max_chain = max_chain;
  this.func = func;
}
var configuration_table = [
  /*      good lazy nice chain */
  new Config(0, 0, 0, 0, deflate_stored),
  /* 0 store only */
  new Config(4, 4, 8, 4, deflate_fast),
  /* 1 max speed, no lazy matches */
  new Config(4, 5, 16, 8, deflate_fast),
  /* 2 */
  new Config(4, 6, 32, 32, deflate_fast),
  /* 3 */
  new Config(4, 4, 16, 16, deflate_slow),
  /* 4 lazy matches */
  new Config(8, 16, 32, 32, deflate_slow),
  /* 5 */
  new Config(8, 16, 128, 128, deflate_slow),
  /* 6 */
  new Config(8, 32, 128, 256, deflate_slow),
  /* 7 */
  new Config(32, 128, 258, 1024, deflate_slow),
  /* 8 */
  new Config(32, 258, 258, 4096, deflate_slow)
  /* 9 max compression */
];
var lm_init = (s) => {
  s.window_size = 2 * s.w_size;
  zero(s.head);
  s.max_lazy_match = configuration_table[s.level].max_lazy;
  s.good_match = configuration_table[s.level].good_length;
  s.nice_match = configuration_table[s.level].nice_length;
  s.max_chain_length = configuration_table[s.level].max_chain;
  s.strstart = 0;
  s.block_start = 0;
  s.lookahead = 0;
  s.insert = 0;
  s.match_length = s.prev_length = MIN_MATCH - 1;
  s.match_available = 0;
  s.ins_h = 0;
};
function DeflateState() {
  this.strm = null;
  this.status = 0;
  this.pending_buf = null;
  this.pending_buf_size = 0;
  this.pending_out = 0;
  this.pending = 0;
  this.wrap = 0;
  this.gzhead = null;
  this.gzindex = 0;
  this.method = Z_DEFLATED$2;
  this.last_flush = -1;
  this.w_size = 0;
  this.w_bits = 0;
  this.w_mask = 0;
  this.window = null;
  this.window_size = 0;
  this.prev = null;
  this.head = null;
  this.ins_h = 0;
  this.hash_size = 0;
  this.hash_bits = 0;
  this.hash_mask = 0;
  this.hash_shift = 0;
  this.block_start = 0;
  this.match_length = 0;
  this.prev_match = 0;
  this.match_available = 0;
  this.strstart = 0;
  this.match_start = 0;
  this.lookahead = 0;
  this.prev_length = 0;
  this.max_chain_length = 0;
  this.max_lazy_match = 0;
  this.level = 0;
  this.strategy = 0;
  this.good_match = 0;
  this.nice_match = 0;
  this.dyn_ltree = new Uint16Array(HEAP_SIZE * 2);
  this.dyn_dtree = new Uint16Array((2 * D_CODES + 1) * 2);
  this.bl_tree = new Uint16Array((2 * BL_CODES + 1) * 2);
  zero(this.dyn_ltree);
  zero(this.dyn_dtree);
  zero(this.bl_tree);
  this.l_desc = null;
  this.d_desc = null;
  this.bl_desc = null;
  this.bl_count = new Uint16Array(MAX_BITS + 1);
  this.heap = new Uint16Array(2 * L_CODES + 1);
  zero(this.heap);
  this.heap_len = 0;
  this.heap_max = 0;
  this.depth = new Uint16Array(2 * L_CODES + 1);
  zero(this.depth);
  this.sym_buf = 0;
  this.lit_bufsize = 0;
  this.sym_next = 0;
  this.sym_end = 0;
  this.opt_len = 0;
  this.static_len = 0;
  this.matches = 0;
  this.insert = 0;
  this.bi_buf = 0;
  this.bi_valid = 0;
}
var deflateStateCheck = (strm) => {
  if (!strm) {
    return 1;
  }
  const s = strm.state;
  if (!s || s.strm !== strm || s.status !== INIT_STATE && //#ifdef GZIP
  s.status !== GZIP_STATE && //#endif
  s.status !== EXTRA_STATE && s.status !== NAME_STATE && s.status !== COMMENT_STATE && s.status !== HCRC_STATE && s.status !== BUSY_STATE && s.status !== FINISH_STATE) {
    return 1;
  }
  return 0;
};
var deflateResetKeep = (strm) => {
  if (deflateStateCheck(strm)) {
    return err(strm, Z_STREAM_ERROR$2);
  }
  strm.total_in = strm.total_out = 0;
  strm.data_type = Z_UNKNOWN;
  const s = strm.state;
  s.pending = 0;
  s.pending_out = 0;
  if (s.wrap < 0) {
    s.wrap = -s.wrap;
  }
  s.status = //#ifdef GZIP
  s.wrap === 2 ? GZIP_STATE : (
    //#endif
    s.wrap ? INIT_STATE : BUSY_STATE
  );
  strm.adler = s.wrap === 2 ? 0 : 1;
  s.last_flush = -2;
  _tr_init(s);
  return Z_OK$3;
};
var deflateReset = (strm) => {
  const ret = deflateResetKeep(strm);
  if (ret === Z_OK$3) {
    lm_init(strm.state);
  }
  return ret;
};
var deflateSetHeader = (strm, head) => {
  if (deflateStateCheck(strm) || strm.state.wrap !== 2) {
    return Z_STREAM_ERROR$2;
  }
  strm.state.gzhead = head;
  return Z_OK$3;
};
var deflateInit2 = (strm, level, method, windowBits, memLevel, strategy) => {
  if (!strm) {
    return Z_STREAM_ERROR$2;
  }
  let wrap = 1;
  if (level === Z_DEFAULT_COMPRESSION$1) {
    level = 6;
  }
  if (windowBits < 0) {
    wrap = 0;
    windowBits = -windowBits;
  } else if (windowBits > 15) {
    wrap = 2;
    windowBits -= 16;
  }
  if (memLevel < 1 || memLevel > MAX_MEM_LEVEL || method !== Z_DEFLATED$2 || windowBits < 8 || windowBits > 15 || level < 0 || level > 9 || strategy < 0 || strategy > Z_FIXED || windowBits === 8 && wrap !== 1) {
    return err(strm, Z_STREAM_ERROR$2);
  }
  if (windowBits === 8) {
    windowBits = 9;
  }
  const s = new DeflateState();
  strm.state = s;
  s.strm = strm;
  s.status = INIT_STATE;
  s.wrap = wrap;
  s.gzhead = null;
  s.w_bits = windowBits;
  s.w_size = 1 << s.w_bits;
  s.w_mask = s.w_size - 1;
  s.hash_bits = memLevel + 7;
  s.hash_size = 1 << s.hash_bits;
  s.hash_mask = s.hash_size - 1;
  s.hash_shift = ~~((s.hash_bits + MIN_MATCH - 1) / MIN_MATCH);
  s.window = new Uint8Array(s.w_size * 2);
  s.head = new Uint16Array(s.hash_size);
  s.prev = new Uint16Array(s.w_size);
  s.lit_bufsize = 1 << memLevel + 6;
  s.pending_buf_size = s.lit_bufsize * 4;
  s.pending_buf = new Uint8Array(s.pending_buf_size);
  s.sym_buf = s.lit_bufsize;
  s.sym_end = (s.lit_bufsize - 1) * 3;
  s.level = level;
  s.strategy = strategy;
  s.method = method;
  return deflateReset(strm);
};
var deflateInit = (strm, level) => {
  return deflateInit2(strm, level, Z_DEFLATED$2, MAX_WBITS$1, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY$1);
};
var deflate$2 = (strm, flush) => {
  if (deflateStateCheck(strm) || flush > Z_BLOCK$1 || flush < 0) {
    return strm ? err(strm, Z_STREAM_ERROR$2) : Z_STREAM_ERROR$2;
  }
  const s = strm.state;
  if (!strm.output || strm.avail_in !== 0 && !strm.input || s.status === FINISH_STATE && flush !== Z_FINISH$3) {
    return err(strm, strm.avail_out === 0 ? Z_BUF_ERROR$1 : Z_STREAM_ERROR$2);
  }
  const old_flush = s.last_flush;
  s.last_flush = flush;
  if (s.pending !== 0) {
    flush_pending(strm);
    if (strm.avail_out === 0) {
      s.last_flush = -1;
      return Z_OK$3;
    }
  } else if (strm.avail_in === 0 && rank(flush) <= rank(old_flush) && flush !== Z_FINISH$3) {
    return err(strm, Z_BUF_ERROR$1);
  }
  if (s.status === FINISH_STATE && strm.avail_in !== 0) {
    return err(strm, Z_BUF_ERROR$1);
  }
  if (s.status === INIT_STATE && s.wrap === 0) {
    s.status = BUSY_STATE;
  }
  if (s.status === INIT_STATE) {
    let header = Z_DEFLATED$2 + (s.w_bits - 8 << 4) << 8;
    let level_flags = -1;
    if (s.strategy >= Z_HUFFMAN_ONLY || s.level < 2) {
      level_flags = 0;
    } else if (s.level < 6) {
      level_flags = 1;
    } else if (s.level === 6) {
      level_flags = 2;
    } else {
      level_flags = 3;
    }
    header |= level_flags << 6;
    if (s.strstart !== 0) {
      header |= PRESET_DICT;
    }
    header += 31 - header % 31;
    putShortMSB(s, header);
    if (s.strstart !== 0) {
      putShortMSB(s, strm.adler >>> 16);
      putShortMSB(s, strm.adler & 65535);
    }
    strm.adler = 1;
    s.status = BUSY_STATE;
    flush_pending(strm);
    if (s.pending !== 0) {
      s.last_flush = -1;
      return Z_OK$3;
    }
  }
  if (s.status === GZIP_STATE) {
    strm.adler = 0;
    put_byte(s, 31);
    put_byte(s, 139);
    put_byte(s, 8);
    if (!s.gzhead) {
      put_byte(s, 0);
      put_byte(s, 0);
      put_byte(s, 0);
      put_byte(s, 0);
      put_byte(s, 0);
      put_byte(s, s.level === 9 ? 2 : s.strategy >= Z_HUFFMAN_ONLY || s.level < 2 ? 4 : 0);
      put_byte(s, OS_CODE);
      s.status = BUSY_STATE;
      flush_pending(strm);
      if (s.pending !== 0) {
        s.last_flush = -1;
        return Z_OK$3;
      }
    } else {
      put_byte(
        s,
        (s.gzhead.text ? 1 : 0) + (s.gzhead.hcrc ? 2 : 0) + (!s.gzhead.extra ? 0 : 4) + (!s.gzhead.name ? 0 : 8) + (!s.gzhead.comment ? 0 : 16)
      );
      put_byte(s, s.gzhead.time & 255);
      put_byte(s, s.gzhead.time >> 8 & 255);
      put_byte(s, s.gzhead.time >> 16 & 255);
      put_byte(s, s.gzhead.time >> 24 & 255);
      put_byte(s, s.level === 9 ? 2 : s.strategy >= Z_HUFFMAN_ONLY || s.level < 2 ? 4 : 0);
      put_byte(s, s.gzhead.os & 255);
      if (s.gzhead.extra && s.gzhead.extra.length) {
        put_byte(s, s.gzhead.extra.length & 255);
        put_byte(s, s.gzhead.extra.length >> 8 & 255);
      }
      if (s.gzhead.hcrc) {
        strm.adler = crc32_1(strm.adler, s.pending_buf, s.pending, 0);
      }
      s.gzindex = 0;
      s.status = EXTRA_STATE;
    }
  }
  if (s.status === EXTRA_STATE) {
    if (s.gzhead.extra) {
      let beg = s.pending;
      let left = (s.gzhead.extra.length & 65535) - s.gzindex;
      while (s.pending + left > s.pending_buf_size) {
        let copy = s.pending_buf_size - s.pending;
        s.pending_buf.set(s.gzhead.extra.subarray(s.gzindex, s.gzindex + copy), s.pending);
        s.pending = s.pending_buf_size;
        if (s.gzhead.hcrc && s.pending > beg) {
          strm.adler = crc32_1(strm.adler, s.pending_buf, s.pending - beg, beg);
        }
        s.gzindex += copy;
        flush_pending(strm);
        if (s.pending !== 0) {
          s.last_flush = -1;
          return Z_OK$3;
        }
        beg = 0;
        left -= copy;
      }
      let gzhead_extra = new Uint8Array(s.gzhead.extra);
      s.pending_buf.set(gzhead_extra.subarray(s.gzindex, s.gzindex + left), s.pending);
      s.pending += left;
      if (s.gzhead.hcrc && s.pending > beg) {
        strm.adler = crc32_1(strm.adler, s.pending_buf, s.pending - beg, beg);
      }
      s.gzindex = 0;
    }
    s.status = NAME_STATE;
  }
  if (s.status === NAME_STATE) {
    if (s.gzhead.name) {
      let beg = s.pending;
      let val;
      do {
        if (s.pending === s.pending_buf_size) {
          if (s.gzhead.hcrc && s.pending > beg) {
            strm.adler = crc32_1(strm.adler, s.pending_buf, s.pending - beg, beg);
          }
          flush_pending(strm);
          if (s.pending !== 0) {
            s.last_flush = -1;
            return Z_OK$3;
          }
          beg = 0;
        }
        if (s.gzindex < s.gzhead.name.length) {
          val = s.gzhead.name.charCodeAt(s.gzindex++) & 255;
        } else {
          val = 0;
        }
        put_byte(s, val);
      } while (val !== 0);
      if (s.gzhead.hcrc && s.pending > beg) {
        strm.adler = crc32_1(strm.adler, s.pending_buf, s.pending - beg, beg);
      }
      s.gzindex = 0;
    }
    s.status = COMMENT_STATE;
  }
  if (s.status === COMMENT_STATE) {
    if (s.gzhead.comment) {
      let beg = s.pending;
      let val;
      do {
        if (s.pending === s.pending_buf_size) {
          if (s.gzhead.hcrc && s.pending > beg) {
            strm.adler = crc32_1(strm.adler, s.pending_buf, s.pending - beg, beg);
          }
          flush_pending(strm);
          if (s.pending !== 0) {
            s.last_flush = -1;
            return Z_OK$3;
          }
          beg = 0;
        }
        if (s.gzindex < s.gzhead.comment.length) {
          val = s.gzhead.comment.charCodeAt(s.gzindex++) & 255;
        } else {
          val = 0;
        }
        put_byte(s, val);
      } while (val !== 0);
      if (s.gzhead.hcrc && s.pending > beg) {
        strm.adler = crc32_1(strm.adler, s.pending_buf, s.pending - beg, beg);
      }
    }
    s.status = HCRC_STATE;
  }
  if (s.status === HCRC_STATE) {
    if (s.gzhead.hcrc) {
      if (s.pending + 2 > s.pending_buf_size) {
        flush_pending(strm);
        if (s.pending !== 0) {
          s.last_flush = -1;
          return Z_OK$3;
        }
      }
      put_byte(s, strm.adler & 255);
      put_byte(s, strm.adler >> 8 & 255);
      strm.adler = 0;
    }
    s.status = BUSY_STATE;
    flush_pending(strm);
    if (s.pending !== 0) {
      s.last_flush = -1;
      return Z_OK$3;
    }
  }
  if (strm.avail_in !== 0 || s.lookahead !== 0 || flush !== Z_NO_FLUSH$2 && s.status !== FINISH_STATE) {
    let bstate = s.level === 0 ? deflate_stored(s, flush) : s.strategy === Z_HUFFMAN_ONLY ? deflate_huff(s, flush) : s.strategy === Z_RLE ? deflate_rle(s, flush) : configuration_table[s.level].func(s, flush);
    if (bstate === BS_FINISH_STARTED || bstate === BS_FINISH_DONE) {
      s.status = FINISH_STATE;
    }
    if (bstate === BS_NEED_MORE || bstate === BS_FINISH_STARTED) {
      if (strm.avail_out === 0) {
        s.last_flush = -1;
      }
      return Z_OK$3;
    }
    if (bstate === BS_BLOCK_DONE) {
      if (flush === Z_PARTIAL_FLUSH) {
        _tr_align(s);
      } else if (flush !== Z_BLOCK$1) {
        _tr_stored_block(s, 0, 0, false);
        if (flush === Z_FULL_FLUSH$1) {
          zero(s.head);
          if (s.lookahead === 0) {
            s.strstart = 0;
            s.block_start = 0;
            s.insert = 0;
          }
        }
      }
      flush_pending(strm);
      if (strm.avail_out === 0) {
        s.last_flush = -1;
        return Z_OK$3;
      }
    }
  }
  if (flush !== Z_FINISH$3) {
    return Z_OK$3;
  }
  if (s.wrap <= 0) {
    return Z_STREAM_END$3;
  }
  if (s.wrap === 2) {
    put_byte(s, strm.adler & 255);
    put_byte(s, strm.adler >> 8 & 255);
    put_byte(s, strm.adler >> 16 & 255);
    put_byte(s, strm.adler >> 24 & 255);
    put_byte(s, strm.total_in & 255);
    put_byte(s, strm.total_in >> 8 & 255);
    put_byte(s, strm.total_in >> 16 & 255);
    put_byte(s, strm.total_in >> 24 & 255);
  } else {
    putShortMSB(s, strm.adler >>> 16);
    putShortMSB(s, strm.adler & 65535);
  }
  flush_pending(strm);
  if (s.wrap > 0) {
    s.wrap = -s.wrap;
  }
  return s.pending !== 0 ? Z_OK$3 : Z_STREAM_END$3;
};
var deflateEnd = (strm) => {
  if (deflateStateCheck(strm)) {
    return Z_STREAM_ERROR$2;
  }
  const status = strm.state.status;
  strm.state = null;
  return status === BUSY_STATE ? err(strm, Z_DATA_ERROR$2) : Z_OK$3;
};
var deflateSetDictionary = (strm, dictionary) => {
  let dictLength = dictionary.length;
  if (deflateStateCheck(strm)) {
    return Z_STREAM_ERROR$2;
  }
  const s = strm.state;
  const wrap = s.wrap;
  if (wrap === 2 || wrap === 1 && s.status !== INIT_STATE || s.lookahead) {
    return Z_STREAM_ERROR$2;
  }
  if (wrap === 1) {
    strm.adler = adler32_1(strm.adler, dictionary, dictLength, 0);
  }
  s.wrap = 0;
  if (dictLength >= s.w_size) {
    if (wrap === 0) {
      zero(s.head);
      s.strstart = 0;
      s.block_start = 0;
      s.insert = 0;
    }
    let tmpDict = new Uint8Array(s.w_size);
    tmpDict.set(dictionary.subarray(dictLength - s.w_size, dictLength), 0);
    dictionary = tmpDict;
    dictLength = s.w_size;
  }
  const avail = strm.avail_in;
  const next = strm.next_in;
  const input = strm.input;
  strm.avail_in = dictLength;
  strm.next_in = 0;
  strm.input = dictionary;
  fill_window(s);
  while (s.lookahead >= MIN_MATCH) {
    let str = s.strstart;
    let n = s.lookahead - (MIN_MATCH - 1);
    do {
      s.ins_h = HASH(s, s.ins_h, s.window[str + MIN_MATCH - 1]);
      s.prev[str & s.w_mask] = s.head[s.ins_h];
      s.head[s.ins_h] = str;
      str++;
    } while (--n);
    s.strstart = str;
    s.lookahead = MIN_MATCH - 1;
    fill_window(s);
  }
  s.strstart += s.lookahead;
  s.block_start = s.strstart;
  s.insert = s.lookahead;
  s.lookahead = 0;
  s.match_length = s.prev_length = MIN_MATCH - 1;
  s.match_available = 0;
  strm.next_in = next;
  strm.input = input;
  strm.avail_in = avail;
  s.wrap = wrap;
  return Z_OK$3;
};
var deflateInit_1 = deflateInit;
var deflateInit2_1 = deflateInit2;
var deflateReset_1 = deflateReset;
var deflateResetKeep_1 = deflateResetKeep;
var deflateSetHeader_1 = deflateSetHeader;
var deflate_2$1 = deflate$2;
var deflateEnd_1 = deflateEnd;
var deflateSetDictionary_1 = deflateSetDictionary;
var deflateInfo = "pako deflate (from Nodeca project)";
var deflate_1$2 = {
  deflateInit: deflateInit_1,
  deflateInit2: deflateInit2_1,
  deflateReset: deflateReset_1,
  deflateResetKeep: deflateResetKeep_1,
  deflateSetHeader: deflateSetHeader_1,
  deflate: deflate_2$1,
  deflateEnd: deflateEnd_1,
  deflateSetDictionary: deflateSetDictionary_1,
  deflateInfo
};
var _has = (obj, key) => {
  return Object.prototype.hasOwnProperty.call(obj, key);
};
var assign = function(obj) {
  const sources = Array.prototype.slice.call(arguments, 1);
  while (sources.length) {
    const source = sources.shift();
    if (!source) {
      continue;
    }
    if (typeof source !== "object") {
      throw new TypeError(source + "must be non-object");
    }
    for (const p in source) {
      if (_has(source, p)) {
        obj[p] = source[p];
      }
    }
  }
  return obj;
};
var flattenChunks = (chunks) => {
  let len = 0;
  for (let i = 0, l = chunks.length; i < l; i++) {
    len += chunks[i].length;
  }
  const result = new Uint8Array(len);
  for (let i = 0, pos = 0, l = chunks.length; i < l; i++) {
    let chunk = chunks[i];
    result.set(chunk, pos);
    pos += chunk.length;
  }
  return result;
};
var common = {
  assign,
  flattenChunks
};
var STR_APPLY_UIA_OK = true;
try {
  String.fromCharCode.apply(null, new Uint8Array(1));
} catch (__) {
  STR_APPLY_UIA_OK = false;
}
var _utf8len = new Uint8Array(256);
for (let q = 0; q < 256; q++) {
  _utf8len[q] = q >= 252 ? 6 : q >= 248 ? 5 : q >= 240 ? 4 : q >= 224 ? 3 : q >= 192 ? 2 : 1;
}
_utf8len[254] = _utf8len[254] = 1;
var string2buf = (str) => {
  if (typeof TextEncoder === "function" && TextEncoder.prototype.encode) {
    return new TextEncoder().encode(str);
  }
  let buf, c, c2, m_pos, i, str_len = str.length, buf_len = 0;
  for (m_pos = 0; m_pos < str_len; m_pos++) {
    c = str.charCodeAt(m_pos);
    if ((c & 64512) === 55296 && m_pos + 1 < str_len) {
      c2 = str.charCodeAt(m_pos + 1);
      if ((c2 & 64512) === 56320) {
        c = 65536 + (c - 55296 << 10) + (c2 - 56320);
        m_pos++;
      }
    }
    buf_len += c < 128 ? 1 : c < 2048 ? 2 : c < 65536 ? 3 : 4;
  }
  buf = new Uint8Array(buf_len);
  for (i = 0, m_pos = 0; i < buf_len; m_pos++) {
    c = str.charCodeAt(m_pos);
    if ((c & 64512) === 55296 && m_pos + 1 < str_len) {
      c2 = str.charCodeAt(m_pos + 1);
      if ((c2 & 64512) === 56320) {
        c = 65536 + (c - 55296 << 10) + (c2 - 56320);
        m_pos++;
      }
    }
    if (c < 128) {
      buf[i++] = c;
    } else if (c < 2048) {
      buf[i++] = 192 | c >>> 6;
      buf[i++] = 128 | c & 63;
    } else if (c < 65536) {
      buf[i++] = 224 | c >>> 12;
      buf[i++] = 128 | c >>> 6 & 63;
      buf[i++] = 128 | c & 63;
    } else {
      buf[i++] = 240 | c >>> 18;
      buf[i++] = 128 | c >>> 12 & 63;
      buf[i++] = 128 | c >>> 6 & 63;
      buf[i++] = 128 | c & 63;
    }
  }
  return buf;
};
var buf2binstring = (buf, len) => {
  if (len < 65534) {
    if (buf.subarray && STR_APPLY_UIA_OK) {
      return String.fromCharCode.apply(null, buf.length === len ? buf : buf.subarray(0, len));
    }
  }
  let result = "";
  for (let i = 0; i < len; i++) {
    result += String.fromCharCode(buf[i]);
  }
  return result;
};
var buf2string = (buf, max) => {
  const len = max || buf.length;
  if (typeof TextDecoder === "function" && TextDecoder.prototype.decode) {
    return new TextDecoder().decode(buf.subarray(0, max));
  }
  let i, out;
  const utf16buf = new Array(len * 2);
  for (out = 0, i = 0; i < len; ) {
    let c = buf[i++];
    if (c < 128) {
      utf16buf[out++] = c;
      continue;
    }
    let c_len = _utf8len[c];
    if (c_len > 4) {
      utf16buf[out++] = 65533;
      i += c_len - 1;
      continue;
    }
    c &= c_len === 2 ? 31 : c_len === 3 ? 15 : 7;
    while (c_len > 1 && i < len) {
      c = c << 6 | buf[i++] & 63;
      c_len--;
    }
    if (c_len > 1) {
      utf16buf[out++] = 65533;
      continue;
    }
    if (c < 65536) {
      utf16buf[out++] = c;
    } else {
      c -= 65536;
      utf16buf[out++] = 55296 | c >> 10 & 1023;
      utf16buf[out++] = 56320 | c & 1023;
    }
  }
  return buf2binstring(utf16buf, out);
};
var utf8border = (buf, max) => {
  max = max || buf.length;
  if (max > buf.length) {
    max = buf.length;
  }
  let pos = max - 1;
  while (pos >= 0 && (buf[pos] & 192) === 128) {
    pos--;
  }
  if (pos < 0) {
    return max;
  }
  if (pos === 0) {
    return max;
  }
  return pos + _utf8len[buf[pos]] > max ? pos : max;
};
var strings = {
  string2buf,
  buf2string,
  utf8border
};
function ZStream() {
  this.input = null;
  this.next_in = 0;
  this.avail_in = 0;
  this.total_in = 0;
  this.output = null;
  this.next_out = 0;
  this.avail_out = 0;
  this.total_out = 0;
  this.msg = "";
  this.state = null;
  this.data_type = 2;
  this.adler = 0;
}
var zstream = ZStream;
var toString$1 = Object.prototype.toString;
var {
  Z_NO_FLUSH: Z_NO_FLUSH$1,
  Z_SYNC_FLUSH,
  Z_FULL_FLUSH,
  Z_FINISH: Z_FINISH$2,
  Z_OK: Z_OK$2,
  Z_STREAM_END: Z_STREAM_END$2,
  Z_DEFAULT_COMPRESSION,
  Z_DEFAULT_STRATEGY,
  Z_DEFLATED: Z_DEFLATED$1
} = constants$2;
function Deflate$1(options) {
  this.options = common.assign({
    level: Z_DEFAULT_COMPRESSION,
    method: Z_DEFLATED$1,
    chunkSize: 16384,
    windowBits: 15,
    memLevel: 8,
    strategy: Z_DEFAULT_STRATEGY
  }, options || {});
  let opt = this.options;
  if (opt.raw && opt.windowBits > 0) {
    opt.windowBits = -opt.windowBits;
  } else if (opt.gzip && opt.windowBits > 0 && opt.windowBits < 16) {
    opt.windowBits += 16;
  }
  this.err = 0;
  this.msg = "";
  this.ended = false;
  this.chunks = [];
  this.strm = new zstream();
  this.strm.avail_out = 0;
  let status = deflate_1$2.deflateInit2(
    this.strm,
    opt.level,
    opt.method,
    opt.windowBits,
    opt.memLevel,
    opt.strategy
  );
  if (status !== Z_OK$2) {
    throw new Error(messages[status]);
  }
  if (opt.header) {
    deflate_1$2.deflateSetHeader(this.strm, opt.header);
  }
  if (opt.dictionary) {
    let dict;
    if (typeof opt.dictionary === "string") {
      dict = strings.string2buf(opt.dictionary);
    } else if (toString$1.call(opt.dictionary) === "[object ArrayBuffer]") {
      dict = new Uint8Array(opt.dictionary);
    } else {
      dict = opt.dictionary;
    }
    status = deflate_1$2.deflateSetDictionary(this.strm, dict);
    if (status !== Z_OK$2) {
      throw new Error(messages[status]);
    }
    this._dict_set = true;
  }
}
Deflate$1.prototype.push = function(data, flush_mode) {
  const strm = this.strm;
  const chunkSize = this.options.chunkSize;
  let status, _flush_mode;
  if (this.ended) {
    return false;
  }
  if (flush_mode === ~~flush_mode)
    _flush_mode = flush_mode;
  else
    _flush_mode = flush_mode === true ? Z_FINISH$2 : Z_NO_FLUSH$1;
  if (typeof data === "string") {
    strm.input = strings.string2buf(data);
  } else if (toString$1.call(data) === "[object ArrayBuffer]") {
    strm.input = new Uint8Array(data);
  } else {
    strm.input = data;
  }
  strm.next_in = 0;
  strm.avail_in = strm.input.length;
  for (; ; ) {
    if (strm.avail_out === 0) {
      strm.output = new Uint8Array(chunkSize);
      strm.next_out = 0;
      strm.avail_out = chunkSize;
    }
    if ((_flush_mode === Z_SYNC_FLUSH || _flush_mode === Z_FULL_FLUSH) && strm.avail_out <= 6) {
      this.onData(strm.output.subarray(0, strm.next_out));
      strm.avail_out = 0;
      continue;
    }
    status = deflate_1$2.deflate(strm, _flush_mode);
    if (status === Z_STREAM_END$2) {
      if (strm.next_out > 0) {
        this.onData(strm.output.subarray(0, strm.next_out));
      }
      status = deflate_1$2.deflateEnd(this.strm);
      this.onEnd(status);
      this.ended = true;
      return status === Z_OK$2;
    }
    if (strm.avail_out === 0) {
      this.onData(strm.output);
      continue;
    }
    if (_flush_mode > 0 && strm.next_out > 0) {
      this.onData(strm.output.subarray(0, strm.next_out));
      strm.avail_out = 0;
      continue;
    }
    if (strm.avail_in === 0)
      break;
  }
  return true;
};
Deflate$1.prototype.onData = function(chunk) {
  this.chunks.push(chunk);
};
Deflate$1.prototype.onEnd = function(status) {
  if (status === Z_OK$2) {
    this.result = common.flattenChunks(this.chunks);
  }
  this.chunks = [];
  this.err = status;
  this.msg = this.strm.msg;
};
function deflate$1(input, options) {
  const deflator = new Deflate$1(options);
  deflator.push(input, true);
  if (deflator.err) {
    throw deflator.msg || messages[deflator.err];
  }
  return deflator.result;
}
function deflateRaw$1(input, options) {
  options = options || {};
  options.raw = true;
  return deflate$1(input, options);
}
function gzip$1(input, options) {
  options = options || {};
  options.gzip = true;
  return deflate$1(input, options);
}
var Deflate_1$1 = Deflate$1;
var deflate_2 = deflate$1;
var deflateRaw_1$1 = deflateRaw$1;
var gzip_1$1 = gzip$1;
var constants$1 = constants$2;
var deflate_1$1 = {
  Deflate: Deflate_1$1,
  deflate: deflate_2,
  deflateRaw: deflateRaw_1$1,
  gzip: gzip_1$1,
  constants: constants$1
};
var BAD$1 = 16209;
var TYPE$1 = 16191;
var inffast = function inflate_fast(strm, start) {
  let _in;
  let last;
  let _out;
  let beg;
  let end;
  let dmax;
  let wsize;
  let whave;
  let wnext;
  let s_window;
  let hold;
  let bits;
  let lcode;
  let dcode;
  let lmask;
  let dmask;
  let here;
  let op;
  let len;
  let dist;
  let from;
  let from_source;
  let input, output;
  const state = strm.state;
  _in = strm.next_in;
  input = strm.input;
  last = _in + (strm.avail_in - 5);
  _out = strm.next_out;
  output = strm.output;
  beg = _out - (start - strm.avail_out);
  end = _out + (strm.avail_out - 257);
  dmax = state.dmax;
  wsize = state.wsize;
  whave = state.whave;
  wnext = state.wnext;
  s_window = state.window;
  hold = state.hold;
  bits = state.bits;
  lcode = state.lencode;
  dcode = state.distcode;
  lmask = (1 << state.lenbits) - 1;
  dmask = (1 << state.distbits) - 1;
  top:
    do {
      if (bits < 15) {
        hold += input[_in++] << bits;
        bits += 8;
        hold += input[_in++] << bits;
        bits += 8;
      }
      here = lcode[hold & lmask];
      dolen:
        for (; ; ) {
          op = here >>> 24;
          hold >>>= op;
          bits -= op;
          op = here >>> 16 & 255;
          if (op === 0) {
            output[_out++] = here & 65535;
          } else if (op & 16) {
            len = here & 65535;
            op &= 15;
            if (op) {
              if (bits < op) {
                hold += input[_in++] << bits;
                bits += 8;
              }
              len += hold & (1 << op) - 1;
              hold >>>= op;
              bits -= op;
            }
            if (bits < 15) {
              hold += input[_in++] << bits;
              bits += 8;
              hold += input[_in++] << bits;
              bits += 8;
            }
            here = dcode[hold & dmask];
            dodist:
              for (; ; ) {
                op = here >>> 24;
                hold >>>= op;
                bits -= op;
                op = here >>> 16 & 255;
                if (op & 16) {
                  dist = here & 65535;
                  op &= 15;
                  if (bits < op) {
                    hold += input[_in++] << bits;
                    bits += 8;
                    if (bits < op) {
                      hold += input[_in++] << bits;
                      bits += 8;
                    }
                  }
                  dist += hold & (1 << op) - 1;
                  if (dist > dmax) {
                    strm.msg = "invalid distance too far back";
                    state.mode = BAD$1;
                    break top;
                  }
                  hold >>>= op;
                  bits -= op;
                  op = _out - beg;
                  if (dist > op) {
                    op = dist - op;
                    if (op > whave) {
                      if (state.sane) {
                        strm.msg = "invalid distance too far back";
                        state.mode = BAD$1;
                        break top;
                      }
                    }
                    from = 0;
                    from_source = s_window;
                    if (wnext === 0) {
                      from += wsize - op;
                      if (op < len) {
                        len -= op;
                        do {
                          output[_out++] = s_window[from++];
                        } while (--op);
                        from = _out - dist;
                        from_source = output;
                      }
                    } else if (wnext < op) {
                      from += wsize + wnext - op;
                      op -= wnext;
                      if (op < len) {
                        len -= op;
                        do {
                          output[_out++] = s_window[from++];
                        } while (--op);
                        from = 0;
                        if (wnext < len) {
                          op = wnext;
                          len -= op;
                          do {
                            output[_out++] = s_window[from++];
                          } while (--op);
                          from = _out - dist;
                          from_source = output;
                        }
                      }
                    } else {
                      from += wnext - op;
                      if (op < len) {
                        len -= op;
                        do {
                          output[_out++] = s_window[from++];
                        } while (--op);
                        from = _out - dist;
                        from_source = output;
                      }
                    }
                    while (len > 2) {
                      output[_out++] = from_source[from++];
                      output[_out++] = from_source[from++];
                      output[_out++] = from_source[from++];
                      len -= 3;
                    }
                    if (len) {
                      output[_out++] = from_source[from++];
                      if (len > 1) {
                        output[_out++] = from_source[from++];
                      }
                    }
                  } else {
                    from = _out - dist;
                    do {
                      output[_out++] = output[from++];
                      output[_out++] = output[from++];
                      output[_out++] = output[from++];
                      len -= 3;
                    } while (len > 2);
                    if (len) {
                      output[_out++] = output[from++];
                      if (len > 1) {
                        output[_out++] = output[from++];
                      }
                    }
                  }
                } else if ((op & 64) === 0) {
                  here = dcode[(here & 65535) + (hold & (1 << op) - 1)];
                  continue dodist;
                } else {
                  strm.msg = "invalid distance code";
                  state.mode = BAD$1;
                  break top;
                }
                break;
              }
          } else if ((op & 64) === 0) {
            here = lcode[(here & 65535) + (hold & (1 << op) - 1)];
            continue dolen;
          } else if (op & 32) {
            state.mode = TYPE$1;
            break top;
          } else {
            strm.msg = "invalid literal/length code";
            state.mode = BAD$1;
            break top;
          }
          break;
        }
    } while (_in < last && _out < end);
  len = bits >> 3;
  _in -= len;
  bits -= len << 3;
  hold &= (1 << bits) - 1;
  strm.next_in = _in;
  strm.next_out = _out;
  strm.avail_in = _in < last ? 5 + (last - _in) : 5 - (_in - last);
  strm.avail_out = _out < end ? 257 + (end - _out) : 257 - (_out - end);
  state.hold = hold;
  state.bits = bits;
  return;
};
var MAXBITS = 15;
var ENOUGH_LENS$1 = 852;
var ENOUGH_DISTS$1 = 592;
var CODES$1 = 0;
var LENS$1 = 1;
var DISTS$1 = 2;
var lbase = new Uint16Array([
  /* Length codes 257..285 base */
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  13,
  15,
  17,
  19,
  23,
  27,
  31,
  35,
  43,
  51,
  59,
  67,
  83,
  99,
  115,
  131,
  163,
  195,
  227,
  258,
  0,
  0
]);
var lext = new Uint8Array([
  /* Length codes 257..285 extra */
  16,
  16,
  16,
  16,
  16,
  16,
  16,
  16,
  17,
  17,
  17,
  17,
  18,
  18,
  18,
  18,
  19,
  19,
  19,
  19,
  20,
  20,
  20,
  20,
  21,
  21,
  21,
  21,
  16,
  72,
  78
]);
var dbase = new Uint16Array([
  /* Distance codes 0..29 base */
  1,
  2,
  3,
  4,
  5,
  7,
  9,
  13,
  17,
  25,
  33,
  49,
  65,
  97,
  129,
  193,
  257,
  385,
  513,
  769,
  1025,
  1537,
  2049,
  3073,
  4097,
  6145,
  8193,
  12289,
  16385,
  24577,
  0,
  0
]);
var dext = new Uint8Array([
  /* Distance codes 0..29 extra */
  16,
  16,
  16,
  16,
  17,
  17,
  18,
  18,
  19,
  19,
  20,
  20,
  21,
  21,
  22,
  22,
  23,
  23,
  24,
  24,
  25,
  25,
  26,
  26,
  27,
  27,
  28,
  28,
  29,
  29,
  64,
  64
]);
var inflate_table = (type, lens, lens_index, codes, table, table_index, work, opts) => {
  const bits = opts.bits;
  let len = 0;
  let sym = 0;
  let min = 0, max = 0;
  let root = 0;
  let curr = 0;
  let drop = 0;
  let left = 0;
  let used = 0;
  let huff = 0;
  let incr;
  let fill;
  let low;
  let mask;
  let next;
  let base = null;
  let match;
  const count = new Uint16Array(MAXBITS + 1);
  const offs = new Uint16Array(MAXBITS + 1);
  let extra = null;
  let here_bits, here_op, here_val;
  for (len = 0; len <= MAXBITS; len++) {
    count[len] = 0;
  }
  for (sym = 0; sym < codes; sym++) {
    count[lens[lens_index + sym]]++;
  }
  root = bits;
  for (max = MAXBITS; max >= 1; max--) {
    if (count[max] !== 0) {
      break;
    }
  }
  if (root > max) {
    root = max;
  }
  if (max === 0) {
    table[table_index++] = 1 << 24 | 64 << 16 | 0;
    table[table_index++] = 1 << 24 | 64 << 16 | 0;
    opts.bits = 1;
    return 0;
  }
  for (min = 1; min < max; min++) {
    if (count[min] !== 0) {
      break;
    }
  }
  if (root < min) {
    root = min;
  }
  left = 1;
  for (len = 1; len <= MAXBITS; len++) {
    left <<= 1;
    left -= count[len];
    if (left < 0) {
      return -1;
    }
  }
  if (left > 0 && (type === CODES$1 || max !== 1)) {
    return -1;
  }
  offs[1] = 0;
  for (len = 1; len < MAXBITS; len++) {
    offs[len + 1] = offs[len] + count[len];
  }
  for (sym = 0; sym < codes; sym++) {
    if (lens[lens_index + sym] !== 0) {
      work[offs[lens[lens_index + sym]]++] = sym;
    }
  }
  if (type === CODES$1) {
    base = extra = work;
    match = 20;
  } else if (type === LENS$1) {
    base = lbase;
    extra = lext;
    match = 257;
  } else {
    base = dbase;
    extra = dext;
    match = 0;
  }
  huff = 0;
  sym = 0;
  len = min;
  next = table_index;
  curr = root;
  drop = 0;
  low = -1;
  used = 1 << root;
  mask = used - 1;
  if (type === LENS$1 && used > ENOUGH_LENS$1 || type === DISTS$1 && used > ENOUGH_DISTS$1) {
    return 1;
  }
  for (; ; ) {
    here_bits = len - drop;
    if (work[sym] + 1 < match) {
      here_op = 0;
      here_val = work[sym];
    } else if (work[sym] >= match) {
      here_op = extra[work[sym] - match];
      here_val = base[work[sym] - match];
    } else {
      here_op = 32 + 64;
      here_val = 0;
    }
    incr = 1 << len - drop;
    fill = 1 << curr;
    min = fill;
    do {
      fill -= incr;
      table[next + (huff >> drop) + fill] = here_bits << 24 | here_op << 16 | here_val | 0;
    } while (fill !== 0);
    incr = 1 << len - 1;
    while (huff & incr) {
      incr >>= 1;
    }
    if (incr !== 0) {
      huff &= incr - 1;
      huff += incr;
    } else {
      huff = 0;
    }
    sym++;
    if (--count[len] === 0) {
      if (len === max) {
        break;
      }
      len = lens[lens_index + work[sym]];
    }
    if (len > root && (huff & mask) !== low) {
      if (drop === 0) {
        drop = root;
      }
      next += min;
      curr = len - drop;
      left = 1 << curr;
      while (curr + drop < max) {
        left -= count[curr + drop];
        if (left <= 0) {
          break;
        }
        curr++;
        left <<= 1;
      }
      used += 1 << curr;
      if (type === LENS$1 && used > ENOUGH_LENS$1 || type === DISTS$1 && used > ENOUGH_DISTS$1) {
        return 1;
      }
      low = huff & mask;
      table[low] = root << 24 | curr << 16 | next - table_index | 0;
    }
  }
  if (huff !== 0) {
    table[next + huff] = len - drop << 24 | 64 << 16 | 0;
  }
  opts.bits = root;
  return 0;
};
var inftrees = inflate_table;
var CODES = 0;
var LENS = 1;
var DISTS = 2;
var {
  Z_FINISH: Z_FINISH$1,
  Z_BLOCK,
  Z_TREES,
  Z_OK: Z_OK$1,
  Z_STREAM_END: Z_STREAM_END$1,
  Z_NEED_DICT: Z_NEED_DICT$1,
  Z_STREAM_ERROR: Z_STREAM_ERROR$1,
  Z_DATA_ERROR: Z_DATA_ERROR$1,
  Z_MEM_ERROR: Z_MEM_ERROR$1,
  Z_BUF_ERROR,
  Z_DEFLATED
} = constants$2;
var HEAD = 16180;
var FLAGS = 16181;
var TIME = 16182;
var OS = 16183;
var EXLEN = 16184;
var EXTRA = 16185;
var NAME = 16186;
var COMMENT = 16187;
var HCRC = 16188;
var DICTID = 16189;
var DICT = 16190;
var TYPE = 16191;
var TYPEDO = 16192;
var STORED = 16193;
var COPY_ = 16194;
var COPY = 16195;
var TABLE = 16196;
var LENLENS = 16197;
var CODELENS = 16198;
var LEN_ = 16199;
var LEN = 16200;
var LENEXT = 16201;
var DIST = 16202;
var DISTEXT = 16203;
var MATCH = 16204;
var LIT = 16205;
var CHECK = 16206;
var LENGTH = 16207;
var DONE = 16208;
var BAD = 16209;
var MEM = 16210;
var SYNC = 16211;
var ENOUGH_LENS = 852;
var ENOUGH_DISTS = 592;
var MAX_WBITS = 15;
var DEF_WBITS = MAX_WBITS;
var zswap32 = (q) => {
  return (q >>> 24 & 255) + (q >>> 8 & 65280) + ((q & 65280) << 8) + ((q & 255) << 24);
};
function InflateState() {
  this.strm = null;
  this.mode = 0;
  this.last = false;
  this.wrap = 0;
  this.havedict = false;
  this.flags = 0;
  this.dmax = 0;
  this.check = 0;
  this.total = 0;
  this.head = null;
  this.wbits = 0;
  this.wsize = 0;
  this.whave = 0;
  this.wnext = 0;
  this.window = null;
  this.hold = 0;
  this.bits = 0;
  this.length = 0;
  this.offset = 0;
  this.extra = 0;
  this.lencode = null;
  this.distcode = null;
  this.lenbits = 0;
  this.distbits = 0;
  this.ncode = 0;
  this.nlen = 0;
  this.ndist = 0;
  this.have = 0;
  this.next = null;
  this.lens = new Uint16Array(320);
  this.work = new Uint16Array(288);
  this.lendyn = null;
  this.distdyn = null;
  this.sane = 0;
  this.back = 0;
  this.was = 0;
}
var inflateStateCheck = (strm) => {
  if (!strm) {
    return 1;
  }
  const state = strm.state;
  if (!state || state.strm !== strm || state.mode < HEAD || state.mode > SYNC) {
    return 1;
  }
  return 0;
};
var inflateResetKeep = (strm) => {
  if (inflateStateCheck(strm)) {
    return Z_STREAM_ERROR$1;
  }
  const state = strm.state;
  strm.total_in = strm.total_out = state.total = 0;
  strm.msg = "";
  if (state.wrap) {
    strm.adler = state.wrap & 1;
  }
  state.mode = HEAD;
  state.last = 0;
  state.havedict = 0;
  state.flags = -1;
  state.dmax = 32768;
  state.head = null;
  state.hold = 0;
  state.bits = 0;
  state.lencode = state.lendyn = new Int32Array(ENOUGH_LENS);
  state.distcode = state.distdyn = new Int32Array(ENOUGH_DISTS);
  state.sane = 1;
  state.back = -1;
  return Z_OK$1;
};
var inflateReset = (strm) => {
  if (inflateStateCheck(strm)) {
    return Z_STREAM_ERROR$1;
  }
  const state = strm.state;
  state.wsize = 0;
  state.whave = 0;
  state.wnext = 0;
  return inflateResetKeep(strm);
};
var inflateReset2 = (strm, windowBits) => {
  let wrap;
  if (inflateStateCheck(strm)) {
    return Z_STREAM_ERROR$1;
  }
  const state = strm.state;
  if (windowBits < 0) {
    wrap = 0;
    windowBits = -windowBits;
  } else {
    wrap = (windowBits >> 4) + 5;
    if (windowBits < 48) {
      windowBits &= 15;
    }
  }
  if (windowBits && (windowBits < 8 || windowBits > 15)) {
    return Z_STREAM_ERROR$1;
  }
  if (state.window !== null && state.wbits !== windowBits) {
    state.window = null;
  }
  state.wrap = wrap;
  state.wbits = windowBits;
  return inflateReset(strm);
};
var inflateInit2 = (strm, windowBits) => {
  if (!strm) {
    return Z_STREAM_ERROR$1;
  }
  const state = new InflateState();
  strm.state = state;
  state.strm = strm;
  state.window = null;
  state.mode = HEAD;
  const ret = inflateReset2(strm, windowBits);
  if (ret !== Z_OK$1) {
    strm.state = null;
  }
  return ret;
};
var inflateInit = (strm) => {
  return inflateInit2(strm, DEF_WBITS);
};
var virgin = true;
var lenfix;
var distfix;
var fixedtables = (state) => {
  if (virgin) {
    lenfix = new Int32Array(512);
    distfix = new Int32Array(32);
    let sym = 0;
    while (sym < 144) {
      state.lens[sym++] = 8;
    }
    while (sym < 256) {
      state.lens[sym++] = 9;
    }
    while (sym < 280) {
      state.lens[sym++] = 7;
    }
    while (sym < 288) {
      state.lens[sym++] = 8;
    }
    inftrees(LENS, state.lens, 0, 288, lenfix, 0, state.work, { bits: 9 });
    sym = 0;
    while (sym < 32) {
      state.lens[sym++] = 5;
    }
    inftrees(DISTS, state.lens, 0, 32, distfix, 0, state.work, { bits: 5 });
    virgin = false;
  }
  state.lencode = lenfix;
  state.lenbits = 9;
  state.distcode = distfix;
  state.distbits = 5;
};
var updatewindow = (strm, src, end, copy) => {
  let dist;
  const state = strm.state;
  if (state.window === null) {
    state.wsize = 1 << state.wbits;
    state.wnext = 0;
    state.whave = 0;
    state.window = new Uint8Array(state.wsize);
  }
  if (copy >= state.wsize) {
    state.window.set(src.subarray(end - state.wsize, end), 0);
    state.wnext = 0;
    state.whave = state.wsize;
  } else {
    dist = state.wsize - state.wnext;
    if (dist > copy) {
      dist = copy;
    }
    state.window.set(src.subarray(end - copy, end - copy + dist), state.wnext);
    copy -= dist;
    if (copy) {
      state.window.set(src.subarray(end - copy, end), 0);
      state.wnext = copy;
      state.whave = state.wsize;
    } else {
      state.wnext += dist;
      if (state.wnext === state.wsize) {
        state.wnext = 0;
      }
      if (state.whave < state.wsize) {
        state.whave += dist;
      }
    }
  }
  return 0;
};
var inflate$2 = (strm, flush) => {
  let state;
  let input, output;
  let next;
  let put;
  let have, left;
  let hold;
  let bits;
  let _in, _out;
  let copy;
  let from;
  let from_source;
  let here = 0;
  let here_bits, here_op, here_val;
  let last_bits, last_op, last_val;
  let len;
  let ret;
  const hbuf = new Uint8Array(4);
  let opts;
  let n;
  const order = (
    /* permutation of code lengths */
    new Uint8Array([16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15])
  );
  if (inflateStateCheck(strm) || !strm.output || !strm.input && strm.avail_in !== 0) {
    return Z_STREAM_ERROR$1;
  }
  state = strm.state;
  if (state.mode === TYPE) {
    state.mode = TYPEDO;
  }
  put = strm.next_out;
  output = strm.output;
  left = strm.avail_out;
  next = strm.next_in;
  input = strm.input;
  have = strm.avail_in;
  hold = state.hold;
  bits = state.bits;
  _in = have;
  _out = left;
  ret = Z_OK$1;
  inf_leave:
    for (; ; ) {
      switch (state.mode) {
        case HEAD:
          if (state.wrap === 0) {
            state.mode = TYPEDO;
            break;
          }
          while (bits < 16) {
            if (have === 0) {
              break inf_leave;
            }
            have--;
            hold += input[next++] << bits;
            bits += 8;
          }
          if (state.wrap & 2 && hold === 35615) {
            if (state.wbits === 0) {
              state.wbits = 15;
            }
            state.check = 0;
            hbuf[0] = hold & 255;
            hbuf[1] = hold >>> 8 & 255;
            state.check = crc32_1(state.check, hbuf, 2, 0);
            hold = 0;
            bits = 0;
            state.mode = FLAGS;
            break;
          }
          if (state.head) {
            state.head.done = false;
          }
          if (!(state.wrap & 1) || /* check if zlib header allowed */
          (((hold & 255) << 8) + (hold >> 8)) % 31) {
            strm.msg = "incorrect header check";
            state.mode = BAD;
            break;
          }
          if ((hold & 15) !== Z_DEFLATED) {
            strm.msg = "unknown compression method";
            state.mode = BAD;
            break;
          }
          hold >>>= 4;
          bits -= 4;
          len = (hold & 15) + 8;
          if (state.wbits === 0) {
            state.wbits = len;
          }
          if (len > 15 || len > state.wbits) {
            strm.msg = "invalid window size";
            state.mode = BAD;
            break;
          }
          state.dmax = 1 << state.wbits;
          state.flags = 0;
          strm.adler = state.check = 1;
          state.mode = hold & 512 ? DICTID : TYPE;
          hold = 0;
          bits = 0;
          break;
        case FLAGS:
          while (bits < 16) {
            if (have === 0) {
              break inf_leave;
            }
            have--;
            hold += input[next++] << bits;
            bits += 8;
          }
          state.flags = hold;
          if ((state.flags & 255) !== Z_DEFLATED) {
            strm.msg = "unknown compression method";
            state.mode = BAD;
            break;
          }
          if (state.flags & 57344) {
            strm.msg = "unknown header flags set";
            state.mode = BAD;
            break;
          }
          if (state.head) {
            state.head.text = hold >> 8 & 1;
          }
          if (state.flags & 512 && state.wrap & 4) {
            hbuf[0] = hold & 255;
            hbuf[1] = hold >>> 8 & 255;
            state.check = crc32_1(state.check, hbuf, 2, 0);
          }
          hold = 0;
          bits = 0;
          state.mode = TIME;
        case TIME:
          while (bits < 32) {
            if (have === 0) {
              break inf_leave;
            }
            have--;
            hold += input[next++] << bits;
            bits += 8;
          }
          if (state.head) {
            state.head.time = hold;
          }
          if (state.flags & 512 && state.wrap & 4) {
            hbuf[0] = hold & 255;
            hbuf[1] = hold >>> 8 & 255;
            hbuf[2] = hold >>> 16 & 255;
            hbuf[3] = hold >>> 24 & 255;
            state.check = crc32_1(state.check, hbuf, 4, 0);
          }
          hold = 0;
          bits = 0;
          state.mode = OS;
        case OS:
          while (bits < 16) {
            if (have === 0) {
              break inf_leave;
            }
            have--;
            hold += input[next++] << bits;
            bits += 8;
          }
          if (state.head) {
            state.head.xflags = hold & 255;
            state.head.os = hold >> 8;
          }
          if (state.flags & 512 && state.wrap & 4) {
            hbuf[0] = hold & 255;
            hbuf[1] = hold >>> 8 & 255;
            state.check = crc32_1(state.check, hbuf, 2, 0);
          }
          hold = 0;
          bits = 0;
          state.mode = EXLEN;
        case EXLEN:
          if (state.flags & 1024) {
            while (bits < 16) {
              if (have === 0) {
                break inf_leave;
              }
              have--;
              hold += input[next++] << bits;
              bits += 8;
            }
            state.length = hold;
            if (state.head) {
              state.head.extra_len = hold;
            }
            if (state.flags & 512 && state.wrap & 4) {
              hbuf[0] = hold & 255;
              hbuf[1] = hold >>> 8 & 255;
              state.check = crc32_1(state.check, hbuf, 2, 0);
            }
            hold = 0;
            bits = 0;
          } else if (state.head) {
            state.head.extra = null;
          }
          state.mode = EXTRA;
        case EXTRA:
          if (state.flags & 1024) {
            copy = state.length;
            if (copy > have) {
              copy = have;
            }
            if (copy) {
              if (state.head) {
                len = state.head.extra_len - state.length;
                if (!state.head.extra) {
                  state.head.extra = new Uint8Array(state.head.extra_len);
                }
                state.head.extra.set(
                  input.subarray(
                    next,
                    // extra field is limited to 65536 bytes
                    // - no need for additional size check
                    next + copy
                  ),
                  /*len + copy > state.head.extra_max - len ? state.head.extra_max : copy,*/
                  len
                );
              }
              if (state.flags & 512 && state.wrap & 4) {
                state.check = crc32_1(state.check, input, copy, next);
              }
              have -= copy;
              next += copy;
              state.length -= copy;
            }
            if (state.length) {
              break inf_leave;
            }
          }
          state.length = 0;
          state.mode = NAME;
        case NAME:
          if (state.flags & 2048) {
            if (have === 0) {
              break inf_leave;
            }
            copy = 0;
            do {
              len = input[next + copy++];
              if (state.head && len && state.length < 65536) {
                state.head.name += String.fromCharCode(len);
              }
            } while (len && copy < have);
            if (state.flags & 512 && state.wrap & 4) {
              state.check = crc32_1(state.check, input, copy, next);
            }
            have -= copy;
            next += copy;
            if (len) {
              break inf_leave;
            }
          } else if (state.head) {
            state.head.name = null;
          }
          state.length = 0;
          state.mode = COMMENT;
        case COMMENT:
          if (state.flags & 4096) {
            if (have === 0) {
              break inf_leave;
            }
            copy = 0;
            do {
              len = input[next + copy++];
              if (state.head && len && state.length < 65536) {
                state.head.comment += String.fromCharCode(len);
              }
            } while (len && copy < have);
            if (state.flags & 512 && state.wrap & 4) {
              state.check = crc32_1(state.check, input, copy, next);
            }
            have -= copy;
            next += copy;
            if (len) {
              break inf_leave;
            }
          } else if (state.head) {
            state.head.comment = null;
          }
          state.mode = HCRC;
        case HCRC:
          if (state.flags & 512) {
            while (bits < 16) {
              if (have === 0) {
                break inf_leave;
              }
              have--;
              hold += input[next++] << bits;
              bits += 8;
            }
            if (state.wrap & 4 && hold !== (state.check & 65535)) {
              strm.msg = "header crc mismatch";
              state.mode = BAD;
              break;
            }
            hold = 0;
            bits = 0;
          }
          if (state.head) {
            state.head.hcrc = state.flags >> 9 & 1;
            state.head.done = true;
          }
          strm.adler = state.check = 0;
          state.mode = TYPE;
          break;
        case DICTID:
          while (bits < 32) {
            if (have === 0) {
              break inf_leave;
            }
            have--;
            hold += input[next++] << bits;
            bits += 8;
          }
          strm.adler = state.check = zswap32(hold);
          hold = 0;
          bits = 0;
          state.mode = DICT;
        case DICT:
          if (state.havedict === 0) {
            strm.next_out = put;
            strm.avail_out = left;
            strm.next_in = next;
            strm.avail_in = have;
            state.hold = hold;
            state.bits = bits;
            return Z_NEED_DICT$1;
          }
          strm.adler = state.check = 1;
          state.mode = TYPE;
        case TYPE:
          if (flush === Z_BLOCK || flush === Z_TREES) {
            break inf_leave;
          }
        case TYPEDO:
          if (state.last) {
            hold >>>= bits & 7;
            bits -= bits & 7;
            state.mode = CHECK;
            break;
          }
          while (bits < 3) {
            if (have === 0) {
              break inf_leave;
            }
            have--;
            hold += input[next++] << bits;
            bits += 8;
          }
          state.last = hold & 1;
          hold >>>= 1;
          bits -= 1;
          switch (hold & 3) {
            case 0:
              state.mode = STORED;
              break;
            case 1:
              fixedtables(state);
              state.mode = LEN_;
              if (flush === Z_TREES) {
                hold >>>= 2;
                bits -= 2;
                break inf_leave;
              }
              break;
            case 2:
              state.mode = TABLE;
              break;
            case 3:
              strm.msg = "invalid block type";
              state.mode = BAD;
          }
          hold >>>= 2;
          bits -= 2;
          break;
        case STORED:
          hold >>>= bits & 7;
          bits -= bits & 7;
          while (bits < 32) {
            if (have === 0) {
              break inf_leave;
            }
            have--;
            hold += input[next++] << bits;
            bits += 8;
          }
          if ((hold & 65535) !== (hold >>> 16 ^ 65535)) {
            strm.msg = "invalid stored block lengths";
            state.mode = BAD;
            break;
          }
          state.length = hold & 65535;
          hold = 0;
          bits = 0;
          state.mode = COPY_;
          if (flush === Z_TREES) {
            break inf_leave;
          }
        case COPY_:
          state.mode = COPY;
        case COPY:
          copy = state.length;
          if (copy) {
            if (copy > have) {
              copy = have;
            }
            if (copy > left) {
              copy = left;
            }
            if (copy === 0) {
              break inf_leave;
            }
            output.set(input.subarray(next, next + copy), put);
            have -= copy;
            next += copy;
            left -= copy;
            put += copy;
            state.length -= copy;
            break;
          }
          state.mode = TYPE;
          break;
        case TABLE:
          while (bits < 14) {
            if (have === 0) {
              break inf_leave;
            }
            have--;
            hold += input[next++] << bits;
            bits += 8;
          }
          state.nlen = (hold & 31) + 257;
          hold >>>= 5;
          bits -= 5;
          state.ndist = (hold & 31) + 1;
          hold >>>= 5;
          bits -= 5;
          state.ncode = (hold & 15) + 4;
          hold >>>= 4;
          bits -= 4;
          if (state.nlen > 286 || state.ndist > 30) {
            strm.msg = "too many length or distance symbols";
            state.mode = BAD;
            break;
          }
          state.have = 0;
          state.mode = LENLENS;
        case LENLENS:
          while (state.have < state.ncode) {
            while (bits < 3) {
              if (have === 0) {
                break inf_leave;
              }
              have--;
              hold += input[next++] << bits;
              bits += 8;
            }
            state.lens[order[state.have++]] = hold & 7;
            hold >>>= 3;
            bits -= 3;
          }
          while (state.have < 19) {
            state.lens[order[state.have++]] = 0;
          }
          state.lencode = state.lendyn;
          state.lenbits = 7;
          opts = { bits: state.lenbits };
          ret = inftrees(CODES, state.lens, 0, 19, state.lencode, 0, state.work, opts);
          state.lenbits = opts.bits;
          if (ret) {
            strm.msg = "invalid code lengths set";
            state.mode = BAD;
            break;
          }
          state.have = 0;
          state.mode = CODELENS;
        case CODELENS:
          while (state.have < state.nlen + state.ndist) {
            for (; ; ) {
              here = state.lencode[hold & (1 << state.lenbits) - 1];
              here_bits = here >>> 24;
              here_op = here >>> 16 & 255;
              here_val = here & 65535;
              if (here_bits <= bits) {
                break;
              }
              if (have === 0) {
                break inf_leave;
              }
              have--;
              hold += input[next++] << bits;
              bits += 8;
            }
            if (here_val < 16) {
              hold >>>= here_bits;
              bits -= here_bits;
              state.lens[state.have++] = here_val;
            } else {
              if (here_val === 16) {
                n = here_bits + 2;
                while (bits < n) {
                  if (have === 0) {
                    break inf_leave;
                  }
                  have--;
                  hold += input[next++] << bits;
                  bits += 8;
                }
                hold >>>= here_bits;
                bits -= here_bits;
                if (state.have === 0) {
                  strm.msg = "invalid bit length repeat";
                  state.mode = BAD;
                  break;
                }
                len = state.lens[state.have - 1];
                copy = 3 + (hold & 3);
                hold >>>= 2;
                bits -= 2;
              } else if (here_val === 17) {
                n = here_bits + 3;
                while (bits < n) {
                  if (have === 0) {
                    break inf_leave;
                  }
                  have--;
                  hold += input[next++] << bits;
                  bits += 8;
                }
                hold >>>= here_bits;
                bits -= here_bits;
                len = 0;
                copy = 3 + (hold & 7);
                hold >>>= 3;
                bits -= 3;
              } else {
                n = here_bits + 7;
                while (bits < n) {
                  if (have === 0) {
                    break inf_leave;
                  }
                  have--;
                  hold += input[next++] << bits;
                  bits += 8;
                }
                hold >>>= here_bits;
                bits -= here_bits;
                len = 0;
                copy = 11 + (hold & 127);
                hold >>>= 7;
                bits -= 7;
              }
              if (state.have + copy > state.nlen + state.ndist) {
                strm.msg = "invalid bit length repeat";
                state.mode = BAD;
                break;
              }
              while (copy--) {
                state.lens[state.have++] = len;
              }
            }
          }
          if (state.mode === BAD) {
            break;
          }
          if (state.lens[256] === 0) {
            strm.msg = "invalid code -- missing end-of-block";
            state.mode = BAD;
            break;
          }
          state.lenbits = 9;
          opts = { bits: state.lenbits };
          ret = inftrees(LENS, state.lens, 0, state.nlen, state.lencode, 0, state.work, opts);
          state.lenbits = opts.bits;
          if (ret) {
            strm.msg = "invalid literal/lengths set";
            state.mode = BAD;
            break;
          }
          state.distbits = 6;
          state.distcode = state.distdyn;
          opts = { bits: state.distbits };
          ret = inftrees(DISTS, state.lens, state.nlen, state.ndist, state.distcode, 0, state.work, opts);
          state.distbits = opts.bits;
          if (ret) {
            strm.msg = "invalid distances set";
            state.mode = BAD;
            break;
          }
          state.mode = LEN_;
          if (flush === Z_TREES) {
            break inf_leave;
          }
        case LEN_:
          state.mode = LEN;
        case LEN:
          if (have >= 6 && left >= 258) {
            strm.next_out = put;
            strm.avail_out = left;
            strm.next_in = next;
            strm.avail_in = have;
            state.hold = hold;
            state.bits = bits;
            inffast(strm, _out);
            put = strm.next_out;
            output = strm.output;
            left = strm.avail_out;
            next = strm.next_in;
            input = strm.input;
            have = strm.avail_in;
            hold = state.hold;
            bits = state.bits;
            if (state.mode === TYPE) {
              state.back = -1;
            }
            break;
          }
          state.back = 0;
          for (; ; ) {
            here = state.lencode[hold & (1 << state.lenbits) - 1];
            here_bits = here >>> 24;
            here_op = here >>> 16 & 255;
            here_val = here & 65535;
            if (here_bits <= bits) {
              break;
            }
            if (have === 0) {
              break inf_leave;
            }
            have--;
            hold += input[next++] << bits;
            bits += 8;
          }
          if (here_op && (here_op & 240) === 0) {
            last_bits = here_bits;
            last_op = here_op;
            last_val = here_val;
            for (; ; ) {
              here = state.lencode[last_val + ((hold & (1 << last_bits + last_op) - 1) >> last_bits)];
              here_bits = here >>> 24;
              here_op = here >>> 16 & 255;
              here_val = here & 65535;
              if (last_bits + here_bits <= bits) {
                break;
              }
              if (have === 0) {
                break inf_leave;
              }
              have--;
              hold += input[next++] << bits;
              bits += 8;
            }
            hold >>>= last_bits;
            bits -= last_bits;
            state.back += last_bits;
          }
          hold >>>= here_bits;
          bits -= here_bits;
          state.back += here_bits;
          state.length = here_val;
          if (here_op === 0) {
            state.mode = LIT;
            break;
          }
          if (here_op & 32) {
            state.back = -1;
            state.mode = TYPE;
            break;
          }
          if (here_op & 64) {
            strm.msg = "invalid literal/length code";
            state.mode = BAD;
            break;
          }
          state.extra = here_op & 15;
          state.mode = LENEXT;
        case LENEXT:
          if (state.extra) {
            n = state.extra;
            while (bits < n) {
              if (have === 0) {
                break inf_leave;
              }
              have--;
              hold += input[next++] << bits;
              bits += 8;
            }
            state.length += hold & (1 << state.extra) - 1;
            hold >>>= state.extra;
            bits -= state.extra;
            state.back += state.extra;
          }
          state.was = state.length;
          state.mode = DIST;
        case DIST:
          for (; ; ) {
            here = state.distcode[hold & (1 << state.distbits) - 1];
            here_bits = here >>> 24;
            here_op = here >>> 16 & 255;
            here_val = here & 65535;
            if (here_bits <= bits) {
              break;
            }
            if (have === 0) {
              break inf_leave;
            }
            have--;
            hold += input[next++] << bits;
            bits += 8;
          }
          if ((here_op & 240) === 0) {
            last_bits = here_bits;
            last_op = here_op;
            last_val = here_val;
            for (; ; ) {
              here = state.distcode[last_val + ((hold & (1 << last_bits + last_op) - 1) >> last_bits)];
              here_bits = here >>> 24;
              here_op = here >>> 16 & 255;
              here_val = here & 65535;
              if (last_bits + here_bits <= bits) {
                break;
              }
              if (have === 0) {
                break inf_leave;
              }
              have--;
              hold += input[next++] << bits;
              bits += 8;
            }
            hold >>>= last_bits;
            bits -= last_bits;
            state.back += last_bits;
          }
          hold >>>= here_bits;
          bits -= here_bits;
          state.back += here_bits;
          if (here_op & 64) {
            strm.msg = "invalid distance code";
            state.mode = BAD;
            break;
          }
          state.offset = here_val;
          state.extra = here_op & 15;
          state.mode = DISTEXT;
        case DISTEXT:
          if (state.extra) {
            n = state.extra;
            while (bits < n) {
              if (have === 0) {
                break inf_leave;
              }
              have--;
              hold += input[next++] << bits;
              bits += 8;
            }
            state.offset += hold & (1 << state.extra) - 1;
            hold >>>= state.extra;
            bits -= state.extra;
            state.back += state.extra;
          }
          if (state.offset > state.dmax) {
            strm.msg = "invalid distance too far back";
            state.mode = BAD;
            break;
          }
          state.mode = MATCH;
        case MATCH:
          if (left === 0) {
            break inf_leave;
          }
          copy = _out - left;
          if (state.offset > copy) {
            copy = state.offset - copy;
            if (copy > state.whave) {
              if (state.sane) {
                strm.msg = "invalid distance too far back";
                state.mode = BAD;
                break;
              }
            }
            if (copy > state.wnext) {
              copy -= state.wnext;
              from = state.wsize - copy;
            } else {
              from = state.wnext - copy;
            }
            if (copy > state.length) {
              copy = state.length;
            }
            from_source = state.window;
          } else {
            from_source = output;
            from = put - state.offset;
            copy = state.length;
          }
          if (copy > left) {
            copy = left;
          }
          left -= copy;
          state.length -= copy;
          do {
            output[put++] = from_source[from++];
          } while (--copy);
          if (state.length === 0) {
            state.mode = LEN;
          }
          break;
        case LIT:
          if (left === 0) {
            break inf_leave;
          }
          output[put++] = state.length;
          left--;
          state.mode = LEN;
          break;
        case CHECK:
          if (state.wrap) {
            while (bits < 32) {
              if (have === 0) {
                break inf_leave;
              }
              have--;
              hold |= input[next++] << bits;
              bits += 8;
            }
            _out -= left;
            strm.total_out += _out;
            state.total += _out;
            if (state.wrap & 4 && _out) {
              strm.adler = state.check = /*UPDATE_CHECK(state.check, put - _out, _out);*/
              state.flags ? crc32_1(state.check, output, _out, put - _out) : adler32_1(state.check, output, _out, put - _out);
            }
            _out = left;
            if (state.wrap & 4 && (state.flags ? hold : zswap32(hold)) !== state.check) {
              strm.msg = "incorrect data check";
              state.mode = BAD;
              break;
            }
            hold = 0;
            bits = 0;
          }
          state.mode = LENGTH;
        case LENGTH:
          if (state.wrap && state.flags) {
            while (bits < 32) {
              if (have === 0) {
                break inf_leave;
              }
              have--;
              hold += input[next++] << bits;
              bits += 8;
            }
            if (state.wrap & 4 && hold !== (state.total & 4294967295)) {
              strm.msg = "incorrect length check";
              state.mode = BAD;
              break;
            }
            hold = 0;
            bits = 0;
          }
          state.mode = DONE;
        case DONE:
          ret = Z_STREAM_END$1;
          break inf_leave;
        case BAD:
          ret = Z_DATA_ERROR$1;
          break inf_leave;
        case MEM:
          return Z_MEM_ERROR$1;
        case SYNC:
        default:
          return Z_STREAM_ERROR$1;
      }
    }
  strm.next_out = put;
  strm.avail_out = left;
  strm.next_in = next;
  strm.avail_in = have;
  state.hold = hold;
  state.bits = bits;
  if (state.wsize || _out !== strm.avail_out && state.mode < BAD && (state.mode < CHECK || flush !== Z_FINISH$1)) {
    if (updatewindow(strm, strm.output, strm.next_out, _out - strm.avail_out))
      ;
  }
  _in -= strm.avail_in;
  _out -= strm.avail_out;
  strm.total_in += _in;
  strm.total_out += _out;
  state.total += _out;
  if (state.wrap & 4 && _out) {
    strm.adler = state.check = /*UPDATE_CHECK(state.check, strm.next_out - _out, _out);*/
    state.flags ? crc32_1(state.check, output, _out, strm.next_out - _out) : adler32_1(state.check, output, _out, strm.next_out - _out);
  }
  strm.data_type = state.bits + (state.last ? 64 : 0) + (state.mode === TYPE ? 128 : 0) + (state.mode === LEN_ || state.mode === COPY_ ? 256 : 0);
  if ((_in === 0 && _out === 0 || flush === Z_FINISH$1) && ret === Z_OK$1) {
    ret = Z_BUF_ERROR;
  }
  return ret;
};
var inflateEnd = (strm) => {
  if (inflateStateCheck(strm)) {
    return Z_STREAM_ERROR$1;
  }
  let state = strm.state;
  if (state.window) {
    state.window = null;
  }
  strm.state = null;
  return Z_OK$1;
};
var inflateGetHeader = (strm, head) => {
  if (inflateStateCheck(strm)) {
    return Z_STREAM_ERROR$1;
  }
  const state = strm.state;
  if ((state.wrap & 2) === 0) {
    return Z_STREAM_ERROR$1;
  }
  state.head = head;
  head.done = false;
  return Z_OK$1;
};
var inflateSetDictionary = (strm, dictionary) => {
  const dictLength = dictionary.length;
  let state;
  let dictid;
  let ret;
  if (inflateStateCheck(strm)) {
    return Z_STREAM_ERROR$1;
  }
  state = strm.state;
  if (state.wrap !== 0 && state.mode !== DICT) {
    return Z_STREAM_ERROR$1;
  }
  if (state.mode === DICT) {
    dictid = 1;
    dictid = adler32_1(dictid, dictionary, dictLength, 0);
    if (dictid !== state.check) {
      return Z_DATA_ERROR$1;
    }
  }
  ret = updatewindow(strm, dictionary, dictLength, dictLength);
  if (ret) {
    state.mode = MEM;
    return Z_MEM_ERROR$1;
  }
  state.havedict = 1;
  return Z_OK$1;
};
var inflateReset_1 = inflateReset;
var inflateReset2_1 = inflateReset2;
var inflateResetKeep_1 = inflateResetKeep;
var inflateInit_1 = inflateInit;
var inflateInit2_1 = inflateInit2;
var inflate_2$1 = inflate$2;
var inflateEnd_1 = inflateEnd;
var inflateGetHeader_1 = inflateGetHeader;
var inflateSetDictionary_1 = inflateSetDictionary;
var inflateInfo = "pako inflate (from Nodeca project)";
var inflate_1$2 = {
  inflateReset: inflateReset_1,
  inflateReset2: inflateReset2_1,
  inflateResetKeep: inflateResetKeep_1,
  inflateInit: inflateInit_1,
  inflateInit2: inflateInit2_1,
  inflate: inflate_2$1,
  inflateEnd: inflateEnd_1,
  inflateGetHeader: inflateGetHeader_1,
  inflateSetDictionary: inflateSetDictionary_1,
  inflateInfo
};
function GZheader() {
  this.text = 0;
  this.time = 0;
  this.xflags = 0;
  this.os = 0;
  this.extra = null;
  this.extra_len = 0;
  this.name = "";
  this.comment = "";
  this.hcrc = 0;
  this.done = false;
}
var gzheader = GZheader;
var toString = Object.prototype.toString;
var {
  Z_NO_FLUSH,
  Z_FINISH,
  Z_OK,
  Z_STREAM_END,
  Z_NEED_DICT,
  Z_STREAM_ERROR,
  Z_DATA_ERROR,
  Z_MEM_ERROR
} = constants$2;
function Inflate$1(options) {
  this.options = common.assign({
    chunkSize: 1024 * 64,
    windowBits: 15,
    to: ""
  }, options || {});
  const opt = this.options;
  if (opt.raw && opt.windowBits >= 0 && opt.windowBits < 16) {
    opt.windowBits = -opt.windowBits;
    if (opt.windowBits === 0) {
      opt.windowBits = -15;
    }
  }
  if (opt.windowBits >= 0 && opt.windowBits < 16 && !(options && options.windowBits)) {
    opt.windowBits += 32;
  }
  if (opt.windowBits > 15 && opt.windowBits < 48) {
    if ((opt.windowBits & 15) === 0) {
      opt.windowBits |= 15;
    }
  }
  this.err = 0;
  this.msg = "";
  this.ended = false;
  this.chunks = [];
  this.strm = new zstream();
  this.strm.avail_out = 0;
  let status = inflate_1$2.inflateInit2(
    this.strm,
    opt.windowBits
  );
  if (status !== Z_OK) {
    throw new Error(messages[status]);
  }
  this.header = new gzheader();
  inflate_1$2.inflateGetHeader(this.strm, this.header);
  if (opt.dictionary) {
    if (typeof opt.dictionary === "string") {
      opt.dictionary = strings.string2buf(opt.dictionary);
    } else if (toString.call(opt.dictionary) === "[object ArrayBuffer]") {
      opt.dictionary = new Uint8Array(opt.dictionary);
    }
    if (opt.raw) {
      status = inflate_1$2.inflateSetDictionary(this.strm, opt.dictionary);
      if (status !== Z_OK) {
        throw new Error(messages[status]);
      }
    }
  }
}
Inflate$1.prototype.push = function(data, flush_mode) {
  const strm = this.strm;
  const chunkSize = this.options.chunkSize;
  const dictionary = this.options.dictionary;
  let status, _flush_mode, last_avail_out;
  if (this.ended)
    return false;
  if (flush_mode === ~~flush_mode)
    _flush_mode = flush_mode;
  else
    _flush_mode = flush_mode === true ? Z_FINISH : Z_NO_FLUSH;
  if (toString.call(data) === "[object ArrayBuffer]") {
    strm.input = new Uint8Array(data);
  } else {
    strm.input = data;
  }
  strm.next_in = 0;
  strm.avail_in = strm.input.length;
  for (; ; ) {
    if (strm.avail_out === 0) {
      strm.output = new Uint8Array(chunkSize);
      strm.next_out = 0;
      strm.avail_out = chunkSize;
    }
    status = inflate_1$2.inflate(strm, _flush_mode);
    if (status === Z_NEED_DICT && dictionary) {
      status = inflate_1$2.inflateSetDictionary(strm, dictionary);
      if (status === Z_OK) {
        status = inflate_1$2.inflate(strm, _flush_mode);
      } else if (status === Z_DATA_ERROR) {
        status = Z_NEED_DICT;
      }
    }
    while (strm.avail_in > 0 && status === Z_STREAM_END && strm.state.wrap > 0 && data[strm.next_in] !== 0) {
      inflate_1$2.inflateReset(strm);
      status = inflate_1$2.inflate(strm, _flush_mode);
    }
    switch (status) {
      case Z_STREAM_ERROR:
      case Z_DATA_ERROR:
      case Z_NEED_DICT:
      case Z_MEM_ERROR:
        this.onEnd(status);
        this.ended = true;
        return false;
    }
    last_avail_out = strm.avail_out;
    if (strm.next_out) {
      if (strm.avail_out === 0 || status === Z_STREAM_END) {
        if (this.options.to === "string") {
          let next_out_utf8 = strings.utf8border(strm.output, strm.next_out);
          let tail = strm.next_out - next_out_utf8;
          let utf8str = strings.buf2string(strm.output, next_out_utf8);
          strm.next_out = tail;
          strm.avail_out = chunkSize - tail;
          if (tail)
            strm.output.set(strm.output.subarray(next_out_utf8, next_out_utf8 + tail), 0);
          this.onData(utf8str);
        } else {
          this.onData(strm.output.length === strm.next_out ? strm.output : strm.output.subarray(0, strm.next_out));
        }
      }
    }
    if (status === Z_OK && last_avail_out === 0)
      continue;
    if (status === Z_STREAM_END) {
      status = inflate_1$2.inflateEnd(this.strm);
      this.onEnd(status);
      this.ended = true;
      return true;
    }
    if (strm.avail_in === 0)
      break;
  }
  return true;
};
Inflate$1.prototype.onData = function(chunk) {
  this.chunks.push(chunk);
};
Inflate$1.prototype.onEnd = function(status) {
  if (status === Z_OK) {
    if (this.options.to === "string") {
      this.result = this.chunks.join("");
    } else {
      this.result = common.flattenChunks(this.chunks);
    }
  }
  this.chunks = [];
  this.err = status;
  this.msg = this.strm.msg;
};
function inflate$1(input, options) {
  const inflator = new Inflate$1(options);
  inflator.push(input);
  if (inflator.err)
    throw inflator.msg || messages[inflator.err];
  return inflator.result;
}
function inflateRaw$1(input, options) {
  options = options || {};
  options.raw = true;
  return inflate$1(input, options);
}
var Inflate_1$1 = Inflate$1;
var inflate_2 = inflate$1;
var inflateRaw_1$1 = inflateRaw$1;
var ungzip$1 = inflate$1;
var constants = constants$2;
var inflate_1$1 = {
  Inflate: Inflate_1$1,
  inflate: inflate_2,
  inflateRaw: inflateRaw_1$1,
  ungzip: ungzip$1,
  constants
};
var { Deflate, deflate, deflateRaw, gzip } = deflate_1$1;
var { Inflate, inflate, inflateRaw, ungzip } = inflate_1$1;
var ungzip_1 = ungzip;

// webR/mount.ts
function mountImageUrl(url, mountpoint) {
  if (/\.tgz$|\.tar\.gz$|\.tar$/.test(url)) {
    const dataResp = Module2.downloadFileContent(url);
    if (dataResp.status < 200 || dataResp.status >= 300) {
      throw new Error("Can't download Emscripten filesystem image.");
    }
    const { data, metadata } = decodeVFSArchive(dataResp.response);
    mountImageData(data, metadata, mountpoint);
  } else {
    const urlBase = url.replace(/\.data\.gz$|\.data$|\.js.metadata$/, "");
    const metaResp = Module2.downloadFileContent(`${urlBase}.js.metadata`);
    if (metaResp.status < 200 || metaResp.status >= 300) {
      throw new Error("Can't download Emscripten filesystem image metadata.");
    }
    const metadata = JSON.parse(
      new TextDecoder().decode(metaResp.response)
    );
    const ext = metadata.gzip ? ".data.gz" : ".data";
    const dataResp = Module2.downloadFileContent(`${urlBase}${ext}`);
    if (dataResp.status < 200 || dataResp.status >= 300) {
      throw new Error("Can't download Emscripten filesystem image data.");
    }
    let data = dataResp.response;
    if (metadata.gzip) {
      data = ungzip_1(data).buffer;
    }
    mountImageData(data, metadata, mountpoint);
  }
}
function mountImagePath(path, mountpoint) {
  const fs = require("fs");
  if (/\.tgz$|\.tar\.gz$|\.tar$/.test(path)) {
    const buffer = fs.readFileSync(path);
    const { data, metadata } = decodeVFSArchive(buffer);
    mountImageData(data, metadata, mountpoint);
  } else {
    const pathBase = path.replace(/\.data\.gz$|\.data$|\.js.metadata$/, "");
    const metadata = JSON.parse(
      fs.readFileSync(`${pathBase}.js.metadata`, "utf8")
    );
    const ext = metadata.gzip ? ".data.gz" : ".data";
    let data = fs.readFileSync(`${pathBase}${ext}`);
    if (metadata.gzip) {
      data = ungzip_1(data).buffer;
    }
    mountImageData(data, metadata, mountpoint);
  }
}
function mountFSNode(type, opts, mountpoint) {
  if (!IN_NODE || type !== Module2.FS.filesystems.WORKERFS) {
    return Module2.FS._mount(type, opts, mountpoint);
  }
  if ("packages" in opts && opts.packages) {
    opts.packages.forEach((pkg) => {
      mountImageData(pkg.blob, pkg.metadata, mountpoint);
    });
  } else {
    throw new Error(
      "Can't mount data under Node. Mounting with `WORKERFS` under Node must use the `packages` key."
    );
  }
}
function mountImageData(data, metadata, mountpoint) {
  if (IN_NODE) {
    const buf = Buffer.from(data);
    const WORKERFS = Module2.FS.filesystems.WORKERFS;
    if (!WORKERFS.reader)
      WORKERFS.reader = {
        readAsArrayBuffer: (chunk) => new Uint8Array(chunk)
      };
    metadata.files.forEach((f) => {
      const contents = buf.subarray(f.start, f.end);
      contents.size = contents.byteLength;
      contents.slice = (start, end) => {
        const sub = contents.subarray(start, end);
        sub.size = sub.byteLength;
        return sub;
      };
      const parts = (mountpoint + f.filename).split("/");
      const file = parts.pop();
      if (!file) {
        throw new Error(`Invalid mount path "${mountpoint}${f.filename}".`);
      }
      const dir = parts.join("/");
      Module2.FS.mkdirTree(dir);
      const dirNode = Module2.FS.lookupPath(dir, {}).node;
      WORKERFS.createNode(dirNode, file, WORKERFS.FILE_MODE, 0, contents);
    });
  } else {
    Module2.FS.mount(Module2.FS.filesystems.WORKERFS, {
      packages: [{
        blob: new Blob([data]),
        metadata
      }]
    }, mountpoint);
  }
}
function decodeVFSArchive(data) {
  const buffer = ungzip_1(data).buffer;
  const index = getArchiveMetadata(buffer) || findArchiveMetadata(buffer);
  if (!index) {
    throw new Error("Can't mount archive, no VFS metadata found.");
  }
  const bytes = new DataView(buffer, 512 * index.block, index.len);
  const metadata = JSON.parse(new TextDecoder().decode(bytes));
  return { data: buffer, metadata };
}
function getArchiveMetadata(buffer) {
  const view = new DataView(buffer);
  const magic = view.getInt32(view.byteLength - 16);
  const block = view.getInt32(view.byteLength - 8);
  const len = view.getInt32(view.byteLength - 4);
  if (magic !== 2003133010 || block === 0 || len === 0) {
    return null;
  } else {
    return { block, len };
  }
}
function findArchiveMetadata(buffer) {
  const decoder2 = new TextDecoder();
  let offset = 0;
  while (offset < buffer.byteLength) {
    const header = buffer.slice(offset, offset + 512);
    offset += 512;
    if (new Uint8Array(header).every((byte) => byte === 0)) {
      return null;
    }
    const type = decoder2.decode(header.slice(156, 157));
    if (/5|g|[A-Z]/.test(type)) {
      continue;
    }
    const filename = decoder2.decode(header.slice(0, 100)).replace(/\0+$/, "");
    const len = parseInt(decoder2.decode(header.slice(124, 136)), 8);
    if (filename == ".vfs-index.json") {
      return { block: offset / 512, len };
    }
    offset += 512 * Math.ceil(len / 512);
  }
  return null;
}

// webR/webr-worker.ts
var initialised = false;
var chan;
var onWorkerMessage = function(msg) {
  if (!msg || !msg.type) {
    return;
  }
  if (msg.type === "init") {
    if (initialised) {
      throw new Error("Can't initialise worker multiple times.");
    }
    const messageInit = msg;
    chan = newChannelWorker(messageInit);
    messageInit.data.config.channelType = messageInit.data.channelType;
    init(messageInit.data.config);
    initialised = true;
    return;
  }
  chan == null ? void 0 : chan.onMessageFromMainThread(msg);
};
if (IN_NODE) {
  const workerThreads = require("worker_threads");
  workerThreads.parentPort.on("message", onWorkerMessage);
  globalThis.XMLHttpRequest = require_XMLHttpRequest().XMLHttpRequest;
} else {
  globalThis.onmessage = (ev) => onWorkerMessage(ev.data);
}
var _config;
function dispatch(msg) {
  switch (msg.type) {
    case "request": {
      const req = msg;
      const reqMsg = req.data.msg;
      const write = (resp, transferables) => chan == null ? void 0 : chan.write(newResponse(req.data.uuid, resp, transferables));
      try {
        switch (reqMsg.type) {
          case "lookupPath": {
            const msg2 = reqMsg;
            const node = Module2.FS.lookupPath(msg2.data.path, {}).node;
            write({
              obj: copyFSNode(node),
              payloadType: "raw"
            });
            break;
          }
          case "mkdir": {
            const msg2 = reqMsg;
            write({
              obj: copyFSNode(Module2.FS.mkdir(msg2.data.path)),
              payloadType: "raw"
            });
            break;
          }
          case "mount": {
            const msg2 = reqMsg;
            const type = msg2.data.type;
            if (type === "IDBFS" && _config.channelType == ChannelType.SharedArrayBuffer) {
              throw new Error(
                "The `IDBFS` filesystem type is not supported under the `SharedArrayBuffer` communication channel. The `PostMessage` communication channel must be used."
              );
            }
            const fs = Module2.FS.filesystems[type];
            Module2.FS.mount(fs, msg2.data.options, msg2.data.mountpoint);
            write({ obj: null, payloadType: "raw" });
            break;
          }
          case "syncfs": {
            const msg2 = reqMsg;
            Module2.FS.syncfs(msg2.data.populate, (err2) => {
              if (err2) {
                throw new Error(`Emscripten \`syncfs\` error: "${err2}".`);
              }
              write({ obj: null, payloadType: "raw" });
            });
            break;
          }
          case "readFile": {
            const msg2 = reqMsg;
            const reqData = msg2.data;
            const out = {
              obj: Module2.FS.readFile(reqData.path, {
                encoding: "binary",
                flags: reqData.flags
              }),
              payloadType: "raw"
            };
            write(out, [out.obj.buffer]);
            break;
          }
          case "rmdir": {
            const msg2 = reqMsg;
            write({
              obj: Module2.FS.rmdir(msg2.data.path),
              payloadType: "raw"
            });
            break;
          }
          case "writeFile": {
            const msg2 = reqMsg;
            const reqData = msg2.data;
            const data = Uint8Array.from(Object.values(reqData.data));
            write({
              obj: Module2.FS.writeFile(reqData.path, data, { flags: reqData.flags }),
              payloadType: "raw"
            });
            break;
          }
          case "unlink": {
            const msg2 = reqMsg;
            write({
              obj: Module2.FS.unlink(msg2.data.path),
              payloadType: "raw"
            });
            break;
          }
          case "unmount": {
            const msg2 = reqMsg;
            write({
              obj: Module2.FS.unmount(msg2.data.path),
              payloadType: "raw"
            });
            break;
          }
          case "newShelter": {
            const id = generateUUID();
            shelters.set(id, []);
            write({
              payloadType: "raw",
              obj: id
            });
            break;
          }
          case "shelterSize": {
            const msg2 = reqMsg;
            const size = shelters.get(msg2.data).length;
            write({ payloadType: "raw", obj: size });
            break;
          }
          case "shelterPurge": {
            const msg2 = reqMsg;
            purge(msg2.data);
            write({ payloadType: "raw", obj: null });
            break;
          }
          case "shelterDestroy": {
            const msg2 = reqMsg;
            destroy(msg2.data.id, msg2.data.obj.obj.ptr);
            write({ payloadType: "raw", obj: null });
            break;
          }
          case "captureR": {
            const msg2 = reqMsg;
            const data = msg2.data;
            const shelter = data.shelter;
            const prot = { n: 0 };
            try {
              const capture = captureR(data.code, data.options);
              protectInc(capture.result, prot);
              protectInc(capture.output, prot);
              const result = capture.result;
              keep(shelter, result);
              const n = capture.output.length;
              const output = [];
              for (let i = 1; i < n + 1; ++i) {
                const out = capture.output.get(i);
                const type = out.pluck(1, 1).toString();
                const data2 = out.get(2);
                if (type === "stdout" || type === "stderr") {
                  const msg3 = data2.toString();
                  output.push({ type, data: msg3 });
                } else {
                  keep(shelter, data2);
                  const payload = {
                    obj: {
                      ptr: data2.ptr,
                      type: data2.type(),
                      methods: RObject.getMethods(data2)
                    },
                    payloadType: "ptr"
                  };
                  output.push({ type, data: payload });
                }
              }
              const resultPayload = {
                payloadType: "ptr",
                obj: {
                  ptr: result.ptr,
                  type: result.type(),
                  methods: RObject.getMethods(result)
                }
              };
              write({
                payloadType: "raw",
                obj: {
                  result: resultPayload,
                  output,
                  images: capture.images
                }
              });
            } finally {
              unprotect(prot.n);
            }
            break;
          }
          case "evalR": {
            const msg2 = reqMsg;
            const result = evalR(msg2.data.code, msg2.data.options);
            keep(msg2.data.shelter, result);
            write({
              obj: {
                type: result.type(),
                ptr: result.ptr,
                methods: RObject.getMethods(result)
              },
              payloadType: "ptr"
            });
            break;
          }
          case "evalRRaw": {
            const msg2 = reqMsg;
            const result = evalR(msg2.data.code, msg2.data.options);
            protect(result);
            const throwType = () => {
              throw new Error(`Can't convert object of type ${result.type()} to ${msg2.data.outputType}.`);
            };
            try {
              let out = void 0;
              switch (msg2.data.outputType) {
                case "void":
                  break;
                case "boolean":
                  switch (result.type()) {
                    case "logical":
                      out = result.toBoolean();
                      break;
                    default:
                      throwType();
                  }
                  break;
                case "boolean[]":
                  switch (result.type()) {
                    case "logical":
                      out = result.toArray();
                      if (out.some((i) => i === null)) {
                        throwType();
                      }
                      break;
                    default:
                      throwType();
                  }
                  break;
                case "number":
                  switch (result.type()) {
                    case "logical":
                      out = result.toBoolean();
                      out = Number(out);
                      break;
                    case "integer":
                      out = result.toNumber();
                      break;
                    case "double":
                      out = result.toNumber();
                      break;
                    default:
                      throwType();
                  }
                  break;
                case "number[]":
                  switch (result.type()) {
                    case "logical":
                      out = result.toArray();
                      out = out.map((i) => i === null ? throwType() : Number(i));
                      break;
                    case "integer":
                      out = result.toArray();
                      if (out.some((i) => i === null)) {
                        throwType();
                      }
                      break;
                    case "double":
                      out = result.toArray();
                      if (out.some((i) => i === null)) {
                        throwType();
                      }
                      break;
                    default:
                      throwType();
                  }
                  break;
                case "string":
                  switch (result.type()) {
                    case "character":
                      out = result.toString();
                      break;
                    default:
                      throwType();
                  }
                  break;
                case "string[]":
                  switch (result.type()) {
                    case "character":
                      out = result.toArray();
                      if (out.some((i) => i === null)) {
                        throwType();
                      }
                      break;
                    default:
                      throwType();
                  }
                  break;
                default:
                  throw new Error("Unexpected output type in `evalRRaw().");
              }
              write({
                obj: out,
                payloadType: "raw"
              });
              break;
            } finally {
              unprotect(1);
            }
          }
          case "newRObject": {
            const msg2 = reqMsg;
            const payload = newRObject(msg2.data.args, msg2.data.objType);
            keep(msg2.data.shelter, payload.obj.ptr);
            write(payload);
            break;
          }
          case "callRObjectMethod": {
            const msg2 = reqMsg;
            const data = msg2.data;
            const obj = data.payload ? RObject.wrap(data.payload.obj.ptr) : RObject;
            const payload = callRObjectMethod(obj, data.prop, data.args);
            if (isWebRPayloadPtr(payload)) {
              keep(data.shelter, payload.obj.ptr);
            }
            write(payload);
            break;
          }
          case "invokeWasmFunction": {
            const msg2 = reqMsg;
            const res = Module2.getWasmTableEntry(msg2.data.ptr)(...msg2.data.args);
            write({
              payloadType: "raw",
              obj: res
            });
            break;
          }
          case "installPackages": {
            const msg2 = reqMsg;
            let pkgs = msg2.data.name;
            let repos = msg2.data.options.repos ? msg2.data.options.repos : _config.repoUrl;
            if (typeof pkgs === "string")
              pkgs = [pkgs];
            if (typeof repos === "string")
              repos = [repos];
            evalR(`webr::install(
              c(${pkgs.map((r) => '"' + r + '"').join(",")}),
              repos = c(${repos.map((r) => '"' + r + '"').join(",")}),
              quiet = ${msg2.data.options.quiet ? "TRUE" : "FALSE"},
              mount = ${msg2.data.options.mount ? "TRUE" : "FALSE"}
            )`);
            write({
              obj: true,
              payloadType: "raw"
            });
            break;
          }
          default:
            throw new Error("Unknown event `" + reqMsg.type + "`");
        }
      } catch (_e) {
        const e = _e;
        write({
          payloadType: "err",
          obj: { name: e.name, message: e.message, stack: e.stack }
        });
        if (e instanceof UnwindProtectException) {
          Module2._R_ContinueUnwind(e.cont);
          throwUnreachable();
        }
      }
      break;
    }
    default:
      throw new Error("Unknown event `" + msg.type + "`");
  }
}
function copyFSNode(obj) {
  const retObj = {
    id: obj.id,
    name: obj.name,
    mode: obj.mode,
    isFolder: obj.isFolder,
    mounted: null,
    contents: {}
  };
  if (obj.isFolder && obj.contents) {
    retObj.contents = Object.fromEntries(
      Object.entries(obj.contents).map(([name, node]) => [name, copyFSNode(node)])
    );
  }
  if (obj.mounted !== null) {
    retObj.mounted = {
      mountpoint: obj.mounted.mountpoint,
      root: copyFSNode(obj.mounted.root)
    };
  }
  return retObj;
}
function downloadFileContent(URL2, headers = []) {
  const request = new XMLHttpRequest();
  request.open("GET", URL2, false);
  request.responseType = "arraybuffer";
  try {
    headers.forEach((header) => {
      const splitHeader = header.split(": ");
      request.setRequestHeader(splitHeader[0], splitHeader[1]);
    });
  } catch {
    const responseText = "An error occurred setting headers in XMLHttpRequest";
    console.error(responseText);
    return { status: 400, response: responseText };
  }
  try {
    request.send(null);
    const status = IN_NODE ? JSON.parse(String(request.status)).data.statusCode : request.status;
    if (status >= 200 && status < 300) {
      return { status, response: request.response };
    } else {
      const responseText = new TextDecoder().decode(request.response);
      console.error(`Error fetching ${URL2} - ${responseText}`);
      return { status, response: responseText };
    }
  } catch {
    return { status: 400, response: "An error occurred in XMLHttpRequest" };
  }
}
function newRObject(args, objType) {
  const RClass = getRWorkerClass(objType);
  const _args = replaceInObject(
    args,
    isWebRPayloadPtr,
    (t) => RObject.wrap(t.obj.ptr)
  );
  const obj = new RClass(..._args);
  return {
    obj: {
      type: obj.type(),
      ptr: obj.ptr,
      methods: RObject.getMethods(obj)
    },
    payloadType: "ptr"
  };
}
function callRObjectMethod(obj, prop, args) {
  if (!(prop in obj)) {
    throw new ReferenceError(`${prop} is not defined`);
  }
  const fn = obj[prop];
  if (typeof fn !== "function") {
    throw Error("Requested property cannot be invoked");
  }
  const res = fn.apply(
    obj,
    args.map((arg) => {
      if (arg.payloadType === "ptr") {
        return RObject.wrap(arg.obj.ptr);
      }
      return replaceInObject(
        arg.obj,
        isWebRPayloadPtr,
        (t) => RObject.wrap(t.obj.ptr)
      );
    })
  );
  const ret = replaceInObject(res, isRObject, (obj2) => {
    return {
      obj: { type: obj2.type(), ptr: obj2.ptr, methods: RObject.getMethods(obj2) },
      payloadType: "ptr"
    };
  });
  return { obj: ret, payloadType: "raw" };
}
function captureR(expr, options = {}) {
  var _a;
  const _options = Object.assign(
    {
      env: objs.globalEnv,
      captureStreams: true,
      captureConditions: true,
      captureGraphics: typeof OffscreenCanvas !== "undefined",
      withAutoprint: false,
      throwJsException: true,
      withHandlers: true
    },
    replaceInObject(
      options,
      isWebRPayloadPtr,
      (t) => RObject.wrap(t.obj.ptr)
    )
  );
  const prot = { n: 0 };
  const devEnvObj = new REnvironment({});
  protectInc(devEnvObj, prot);
  Module2.setValue(Module2._R_Interactive, 0, "i8");
  try {
    const envObj = new REnvironment(_options.env);
    protectInc(envObj, prot);
    if (envObj.type() !== "environment") {
      throw new Error("Attempted to evaluate R code with invalid environment object");
    }
    if (_options.captureGraphics) {
      if (typeof OffscreenCanvas === "undefined") {
        throw new Error(
          "This environment does not have support for OffscreenCanvas. Consider disabling plot capture using `captureGraphics: false`."
        );
      }
      devEnvObj.bind("canvas_options", new RList(Object.assign({
        capture: true
      }, _options.captureGraphics)));
      parseEvalBare(`{
        old_dev <- dev.cur()
        do.call(webr::canvas, canvas_options)
        new_dev <- dev.cur()
        old_cache <- webr::canvas_cache()
        plots <- numeric()
      }`, devEnvObj);
    }
    const tPtr = objs.true.ptr;
    const fPtr = objs.false.ptr;
    const fn = parseEvalBare("webr::eval_r", objs.baseEnv);
    const qu = parseEvalBare("quote", objs.baseEnv);
    protectInc(fn, prot);
    protectInc(qu, prot);
    const exprObj = new RObject(expr);
    protectInc(exprObj, prot);
    const call = Module2._Rf_lang6(
      fn.ptr,
      Module2._Rf_lang2(qu.ptr, exprObj.ptr),
      _options.captureConditions ? tPtr : fPtr,
      _options.captureStreams ? tPtr : fPtr,
      _options.withAutoprint ? tPtr : fPtr,
      _options.withHandlers ? tPtr : fPtr
    );
    protectInc(call, prot);
    const capture = RList.wrap(safeEval(call, envObj));
    protectInc(capture, prot);
    if (_options.captureConditions && _options.throwJsException) {
      const output = capture.get("output");
      const error = output.toArray().find(
        (out) => out.get("type").toString() === "error"
      );
      if (error) {
        const call2 = error.pluck("data", "call");
        const source = call2 && call2.type() === "call" ? `\`${call2.deparse()}\`` : "unknown source";
        const message = ((_a = error.pluck("data", "message")) == null ? void 0 : _a.toString()) || "An error occurred evaluating R code.";
        throw new Error(`Error in ${source}: ${message}`);
      }
    }
    let images = [];
    if (_options.captureGraphics) {
      const plots = parseEvalBare(`{
        new_cache <- webr::canvas_cache()
        plots <- setdiff(new_cache, old_cache)
      }`, devEnvObj);
      protectInc(plots, prot);
      images = plots.toArray().map((idx) => {
        return Module2.webr.canvas[idx].offscreen.transferToImageBitmap();
      });
    }
    return {
      result: capture.get("result"),
      output: capture.get("output"),
      images
    };
  } finally {
    Module2.setValue(Module2._R_Interactive, _config.interactive ? 1 : 0, "i8");
    const newDev = devEnvObj.get("new_dev");
    if (_options.captureGraphics && newDev.type() !== "null") {
      parseEvalBare(`{
        dev.off(new_dev)
        dev.set(old_dev)
        webr::canvas_destroy(plots)
      }`, devEnvObj);
    }
    unprotect(prot.n);
  }
}
function evalR(expr, options = {}) {
  var _a, _b;
  options = Object.assign({
    captureGraphics: false
  }, options);
  const prot = { n: 0 };
  const capture = captureR(expr, options);
  try {
    protectInc(capture.output, prot);
    protectInc(capture.result, prot);
    for (let i = 1; i <= capture.output.length; i++) {
      const out = capture.output.get(i);
      const outputType = out.get("type").toString();
      switch (outputType) {
        case "stdout":
          chan == null ? void 0 : chan.writeSystem({ type: "console.log", data: out.get("data").toString() });
          break;
        case "stderr":
          chan == null ? void 0 : chan.writeSystem({ type: "console.warn", data: out.get("data").toString() });
          break;
        case "message":
          chan == null ? void 0 : chan.writeSystem({
            type: "console.warn",
            data: ((_a = out.pluck("data", "message")) == null ? void 0 : _a.toString()) || ""
          });
          break;
        case "warning":
          chan == null ? void 0 : chan.writeSystem({
            type: "console.warn",
            data: `Warning message: 
${((_b = out.pluck("data", "message")) == null ? void 0 : _b.toString()) || ""}`
          });
          break;
        default:
          chan == null ? void 0 : chan.writeSystem({ type: "console.warn", data: `Output of type ${outputType}:` });
          chan == null ? void 0 : chan.writeSystem({ type: "console.warn", data: out.get("data").toJs() });
          break;
      }
    }
    return capture.result;
  } finally {
    unprotect(prot.n);
  }
}
function init(config) {
  _config = config;
  const env = { ...config.REnv };
  if (!env.TZ) {
    const fmt = new Intl.DateTimeFormat();
    env.TZ = fmt.resolvedOptions().timeZone;
  }
  Module2.preRun = [];
  Module2.arguments = _config.RArgs;
  Module2.noExitRuntime = true;
  Module2.noImageDecoding = true;
  Module2.noAudioDecoding = true;
  Module2.noInitialRun = true;
  Module2.noWasmDecoding = true;
  Module2.preRun.push(() => {
    if (IN_NODE) {
      Module2.FS._mount = Module2.FS.mount;
      Module2.FS.mount = mountFSNode;
      globalThis.FS = Module2.FS;
      globalThis.chan = chan;
    }
    if (_config.createLazyFilesystem) {
      Module2.createLazyFilesystem();
    }
    Module2.FS.mkdirTree(_config.homedir);
    Module2.ENV.HOME = _config.homedir;
    Module2.FS.chdir(_config.homedir);
    Module2.ENV = Object.assign(Module2.ENV, env);
  });
  chan == null ? void 0 : chan.setDispatchHandler(dispatch);
  Module2.onRuntimeInitialized = () => {
    chan == null ? void 0 : chan.run(_config.RArgs);
  };
  Module2.webr = {
    UnwindProtectException,
    evalR,
    captureR,
    canvas: {},
    resolveInit: () => {
      initPersistentObjects();
      chan == null ? void 0 : chan.setInterrupt(Module2._Rf_onintr);
      Module2.setValue(Module2._R_Interactive, _config.interactive ? 1 : 0, "i8");
      evalR(`options(webr_pkg_repos="${_config.repoUrl}")`);
      chan == null ? void 0 : chan.resolve();
    },
    readConsole: () => {
      if (!chan) {
        throw new Error("Can't read console input without a communication channel");
      }
      return chan.inputOrDispatch();
    },
    handleEvents: () => {
      chan == null ? void 0 : chan.handleInterrupt();
    },
    dataViewer: (ptr, title) => {
      const data = RList.wrap(ptr).toObject({ depth: 0 });
      chan == null ? void 0 : chan.write({ type: "view", data: { data, title } });
    },
    evalJs: (code) => {
      try {
        return (0, eval)(Module2.UTF8ToString(code));
      } catch (e) {
        if (e instanceof UnwindProtectException) {
          Module2._R_ContinueUnwind(e.cont);
          throwUnreachable();
        } else if (e === Infinity) {
          throw e;
        }
        const msg = Module2.allocateUTF8OnStack(
          `An error occurred during JavaScript evaluation:
  ${e.message}`
        );
        Module2._Rf_error(msg);
      }
      throwUnreachable();
      return 0;
    },
    setTimeoutWasm: (ptr, delay, ...args) => {
      chan == null ? void 0 : chan.writeSystem({ type: "setTimeoutWasm", data: { ptr, delay, args } });
    }
  };
  Module2.locateFile = (path) => _config.baseUrl + path;
  Module2.downloadFileContent = downloadFileContent;
  Module2.mountImageUrl = mountImageUrl;
  Module2.mountImagePath = mountImagePath;
  Module2.print = (text) => {
    chan == null ? void 0 : chan.write({ type: "stdout", data: text });
  };
  Module2.printErr = (text) => {
    chan == null ? void 0 : chan.write({ type: "stderr", data: text });
  };
  Module2.setPrompt = (prompt) => {
    chan == null ? void 0 : chan.write({ type: "prompt", data: prompt });
  };
  globalThis.Module = Module2;
  setTimeout(() => {
    const scriptSrc = `${_config.baseUrl}R.bin.js`;
    void loadScript(scriptSrc);
  });
}
/*! Bundled license information:

xmlhttprequest-ssl/lib/XMLHttpRequest.js:
  (**
   * Wrapper for built-in http.js to emulate the browser XMLHttpRequest object.
   *
   * This can be used with JS designed for browsers to improve reuse of code and
   * allow the use of existing libraries.
   *
   * Usage: include("XMLHttpRequest.js") and use XMLHttpRequest per W3C specs.
   *
   * @author Dan DeFelippi <dan@driverdan.com>
   * @contributor David Ellis <d.f.ellis@ieee.org>
   * @license MIT
   *)

pako/dist/pako.esm.mjs:
  (*! pako 2.1.0 https://github.com/nodeca/pako @license (MIT AND Zlib) *)
*/
//# sourceMappingURL=webr-worker.js.map
