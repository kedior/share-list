import {
  Result,
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
} from "./implement.mjs";

export const domClick = (dom) => {
  dom.click();
};

export const historyReplaceState = (url) => {
  return history.replaceState(null, "", url);
};

/**
 * @param {String} imageUrl
 * @returns {Promise<Result<BitArray, undefined>>}}
 */
export const decodeDataFromImage = async (imageUrl) => {
  try {
    const data = await doDecodeDataFromImage(imageUrl);
    return new Ok(toBitArray(data));
  } catch (err) {
    console.log(err);
    return new Error(undefined);
  }
};

/**
 * @param {BitArray} encryptedData
 * @param {string} password
 * @returns {Promise<Result<string, undefined>>}
 */
export const decryptData = async (encryptedData, password) => {
  try {
    const uint8array = encryptedData.rawBuffer;
    const data = await doDecryptData(uint8array, password);
    return new Ok(data);
  } catch (err) {
    console.log(err);
    return new Error(undefined);
  }
};

/**
 * @param {String} url
 * @param {(percent: number) => void} onProgress
 * @returns {Promise<Result<BitArray, undefined>>}
 */
export const downloadFile = async (url, onProgress) => {
  try {
    const data = await doDownloadFile(url, onProgress);
    return new Ok(toBitArray(data));
  } catch (err) {
    console.log(err);
    return new Error(undefined);
  }
};

/**
 * @param {string} contentStr
 * @returns {undefined}
 */
export const renderRawHTML = (contentStr) => {
  doRenderRawHTML(contentStr);
};
