/**
 * @param {String} imageUrl
 * @returns {Promise<Uint8Array>}}
 */
export async function doDecodeDataFromImage(imageUrl) {
  const img = new Image();
  img.src = imageUrl;

  await img.decode().catch(() => {
    throw new Error("img decode failed");
  });

  const canvas = document.createElement("canvas");
  canvas.width = img.width;
  canvas.height = img.height;
  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("unable to fetch canvas context");

  ctx.drawImage(img, 0, 0);
  const imageData = ctx.getImageData(0, 0, img.width, img.height);
  const data = imageData.data;

  const nibbles = [];
  for (let i = 0; i < data.length; i += 4) {
    nibbles.push(data[i] & 0x0f); // R
    nibbles.push(data[i + 1] & 0x0f); // G
    nibbles.push(data[i + 2] & 0x0f); // B
  }

  const bytes = [];
  for (let i = 0; i + 1 < nibbles.length; i += 2) {
    bytes.push(nibbles[i] | (nibbles[i + 1] << 4));
  }

  if (bytes.length < 4) throw new Error("data length < 4");
  const dataLen =
    bytes[0] | (bytes[1] << 8) | (bytes[2] << 16) | (bytes[3] << 24);

  const resultBytes = bytes.slice(4, 4 + dataLen);

  return new Uint8Array(resultBytes);
}

/**
 * @param {Uint8Array} encryptedData
 * @param {string} password
 * @returns {Promise<string>}
 */
export const doDecryptData = async (encryptedData, password) => {
  const { salt, iv, ciphertext } = extractEncryptionComponents(encryptedData);
  const derivedKey = await deriveKeyFromPassword(password, salt);
  const plaintext = await decryptWithAesGcm(derivedKey, iv, ciphertext);
  if (!plaintext) {
    throw new Error("unable to extract data from img");
  }
  return new TextDecoder().decode(plaintext);
};

/**
 * @param {string} contentStr
 * @returns {never}
 */
export const doRenderRawHTML = (contentStr) => {
  // inject hash listener before </head>
  const setupHashReload = () => {
    window.addEventListener("hashchange", () => {
      location.reload();
    });
  };
  const refreshScript = `<script>(${setupHashReload.toString()})();</script>`;

  if (contentStr.includes("</head>")) {
    contentStr = contentStr.replace("</head>", refreshScript + "</head>");
  } else {
    contentStr += refreshScript;
  }

  document.open();
  document.write(contentStr);
  document.close();
};

// not export --------------------------------------------------------------------

/**
 * @param {Uint8Array} encryptedData
 * @returns {{ salt: Uint8Array, iv: Uint8Array, ciphertext: Uint8Array }}
 */
const extractEncryptionComponents = (encryptedData) => {
  const salt = encryptedData.slice(0, 16);
  const iv = encryptedData.slice(16, 32);
  const ciphertext = encryptedData.slice(32);
  return { salt, iv, ciphertext };
};

/**
 * @param {string} password
 * @param {Uint8Array} salt
 * @returns {Promise<CryptoKey>}
 */
const deriveKeyFromPassword = async (password, salt) => {
  const pwBytes = new TextEncoder().encode(password);
  const keyMaterial = await crypto.subtle.importKey(
    "raw",
    pwBytes,
    "PBKDF2",
    false,
    ["deriveKey"],
  );
  return crypto.subtle.deriveKey(
    {
      name: "PBKDF2",
      salt,
      iterations: 10000,
      hash: "SHA-256",
    },
    keyMaterial,
    {
      name: "AES-GCM",
      length: 256,
    },
    false,
    ["decrypt"],
  );
};

/**
 * @param {CryptoKey} key
 * @param {Uint8Array} iv
 * @param {Uint8Array} ciphertext
 * @returns {Promise<Uint8Array>}
 */
const decryptWithAesGcm = async (key, iv, ciphertext) => {
  const decrypted = await crypto.subtle.decrypt(
    {
      name: "AES-GCM",
      iv,
    },
    key,
    ciphertext,
  );
  return new Uint8Array(decrypted);
};

/**
 * @param {String} url
 * @param {(percent: number) => void} onProgress
 * @returns {Promise<Uint8Array>}
 */
export const doDownloadFile = async (url, onProgress) => {
  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }

  const lengthStr = response.headers.get("Content-Length");
  if (!lengthStr) throw new Error("unable to get file size");
  const length = parseInt(lengthStr, 10);

  const reader = response.body.getReader();
  const chunks = [];
  let loaded = 0;

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(value);
    loaded += value.length;
    const percent = Math.round((loaded / length) * 100);
    onProgress(percent);
  }

  const allChunks = new Uint8Array(loaded);
  let position = 0;
  for (const chunk of chunks) {
    allChunks.set(chunk, position);
    position += chunk.length;
  }
  return allChunks;
};
