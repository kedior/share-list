import upng from "upng-js";

export async function doDecodeDataFromImage(imageUrl: string) {
  const response = await fetch(imageUrl);
  const buffer = await response.arrayBuffer();
  const img = upng.decode(buffer);
  const dataBuffer = upng.toRGBA8(img);
  const data = new Uint8Array(dataBuffer[0]!);

  const nibbles: number[] = [];
  for (let i = 0; i < data.length; i += 4) {
    nibbles.push(data[i]! & 0x0f); // R
    nibbles.push(data[i + 1]! & 0x0f); // G
    nibbles.push(data[i + 2]! & 0x0f); // B
  }

  const bytes: number[] = [];
  for (let i = 0; i + 1 < nibbles.length; i += 2) {
    bytes.push(nibbles[i]! | (nibbles[i + 1]! << 4));
  }

  if (bytes.length < 4) throw new Error("数据长度不足");
  const dataLen =
    bytes[0]! | (bytes[1]! << 8) | (bytes[2]! << 16) | (bytes[3]! << 24);

  const resultBytes = bytes.slice(4, 4 + dataLen);
  return new Uint8Array(resultBytes);
}

export const doDecryptData = async (
  encryptedData: Uint8Array,
  password: string,
): Promise<string> => {
  const { salt, iv, ciphertext } = extractEncryptionComponents(encryptedData);
  const derivedKey = await deriveKeyFromPassword(password, salt);
  const plaintext = await decryptWithAesGcm(derivedKey, iv, ciphertext);
  if (!plaintext) {
    throw new Error("unable to decrypt data");
  }
  return new TextDecoder().decode(plaintext);
};

export const doRenderRawHTML = (contentStr: string) => {
  // inject hash listener before </head>
  const setupHashReload = () => {
    window.addEventListener("hashchange", () => {
      location.reload();
    });
  };
  const refreshScript = `<script>(${setupHashReload.toString()})();</script>`;

  if (contentStr.includes("</head>")) {
    contentStr = contentStr.replace("</head>", refreshScript + "\n</head>");
  } else {
    contentStr += refreshScript;
  }

  document.open();
  (document as any).write(contentStr);
  document.close();
};

export const doDownloadFile = async (
  url: string,
  onProgress: (percent: number) => void,
): Promise<Uint8Array> => {
  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }

  const lengthStr = response.headers.get("Content-Length");
  if (!lengthStr) throw new Error("unable to get file size");
  const length = parseInt(lengthStr, 10);

  const reader = response.body!.getReader();
  const chunks: Uint8Array[] = [];
  let loaded = 0;

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(value);
    loaded += value.length;
    const percent = (loaded / length) * 100;
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
// not export --------------------------------------------------------------------

const extractEncryptionComponents = (encryptedData: Uint8Array) => {
  const salt = encryptedData.slice(0, 16);
  const iv = encryptedData.slice(16, 32);
  const ciphertext = encryptedData.slice(32);
  return { salt, iv, ciphertext };
};

const deriveKeyFromPassword = async (
  password: string,
  salt: Uint8Array,
): Promise<CryptoKey> => {
  const pwBytes = new TextEncoder().encode(password);
  const keyMaterial = await crypto.subtle.importKey(
    "raw",
    pwBytes,
    "PBKDF2",
    false,
    ["deriveKey"],
  );
  const derivedKey = await crypto.subtle.deriveKey(
    {
      name: "PBKDF2",
      salt: salt,
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
  return derivedKey;
};

const decryptWithAesGcm = async (
  key: CryptoKey,
  iv: Uint8Array,
  ciphertext: Uint8Array,
): Promise<Uint8Array | null> => {
  // 解密
  const decrypted = await crypto.subtle.decrypt(
    {
      name: "AES-GCM",
      iv: iv,
    },
    key,
    ciphertext,
  );
  return new Uint8Array(decrypted);
};
