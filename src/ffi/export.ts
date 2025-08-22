import type { String } from "lightningcss";
import {
  Ok,
  Error,
  BitArray,
  toBitArray,
  // use it when dev to get lsp info
  // } from "../../build/dev/javascript/app/gleam.mjs";
} from "../gleam.mjs";

import {
  doDecodeDataFromImage,
  doDecryptData,
  doRenderRawHTML,
  doDownloadFile,
} from "./implement.js";

export const domClick = (dom: HTMLElement) => {
  dom.click();
};

export const historyReplaceState = (url: String) => {
  return history.replaceState(null, "", url);
};

export const decodeDataFromImage = async (imageUrl: String) => {
  try {
    const data = await doDecodeDataFromImage(imageUrl);
    return new Ok(toBitArray([data]));
  } catch (err) {
    console.log(err);
    return new Error(undefined);
  }
};

export const decryptData = async (
  encryptedData: BitArray,
  password: String,
) => {
  try {
    const uint8array = encryptedData.rawBuffer;
    const data = await doDecryptData(uint8array, password);
    return new Ok(data);
  } catch (err) {
    console.log(err);
    return new Error(undefined);
  }
};

export const downloadFile = async (
  url: String,
  onProgress: (percent: number) => void,
) => {
  try {
    const data = await doDownloadFile(url, onProgress);
    return new Ok(toBitArray([data]));
  } catch (err) {
    console.log(err);
    return new Error(undefined);
  }
};

export const renderRawHTML = (contentStr: String) => {
  doRenderRawHTML(contentStr);
};
