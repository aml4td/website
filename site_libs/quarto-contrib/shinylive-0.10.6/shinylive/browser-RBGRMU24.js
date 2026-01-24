// Shinylive 0.10.6
// Copyright 2025 Posit, PBC
import {
  __commonJS
} from "./chunk-BVOTH6Y6.js";

// node_modules/ws/browser.js
var require_browser = __commonJS({
  "node_modules/ws/browser.js"(exports, module) {
    module.exports = function() {
      throw new Error(
        "ws does not work in the browser. Browser clients must use the native WebSocket object"
      );
    };
  }
});
export default require_browser();
