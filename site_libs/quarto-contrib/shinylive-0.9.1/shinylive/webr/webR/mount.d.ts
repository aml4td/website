/**
 * Internal virtual filesystem image mounting functionality.
 * @module Mount
 */
/// <reference types="emscripten" />
import type { FSMountOptions } from './webr-main';
/**
 * Download an Emscripten FS image and mount to the VFS
 * @internal
 */
export declare function mountImageUrl(url: string, mountpoint: string): void;
/**
 * Read an Emscripten FS image from disk and mount to the VFS (requires Node)
 * @internal
 */
export declare function mountImagePath(path: string, mountpoint: string): void;
/**
 * An implementation of FS.mount() for WORKERFS under Node.js
 * @internal
 */
export declare function mountFSNode(type: Emscripten.FileSystemType, opts: FSMountOptions, mountpoint: string): void;
