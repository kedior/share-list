function decryptData(encryptedData, password) {
  password = CryptoJS.SHA256(password).toString(CryptoJS.enc.Hex);
  const salt = CryptoJS.lib.WordArray.create(
    encryptedData.slice(0, 16),
  );
  const iv = CryptoJS.lib.WordArray.create(
    encryptedData.slice(16, 32),
  );
  const ciphertext = CryptoJS.lib.WordArray.create(
    encryptedData.slice(32),
  );

  const key = CryptoJS.PBKDF2(password, salt, {
    keySize: 256 / 32,
    iterations: 1000,
    hasher: CryptoJS.algo.SHA256,
  });

  const decrypted = CryptoJS.AES.decrypt(
    { ciphertext: ciphertext },
    key,
    {
      iv: iv,
      mode: CryptoJS.mode.CBC,
      padding: CryptoJS.pad.Pkcs7,
    },
  );

  return decrypted.toString(CryptoJS.enc.Utf8);
}

async function showContent(contentStr, static_dir) {
  if (!static_dir) static_dir = '';
  if (contentStr.includes('<!DOCTYPE html>')) {
    // 注入 hash 监听脚本到 </head> 之前
    const refreshScript = `
      <script>
      window.addEventListener('DOMContentLoaded', function () {
        var lastHash = location.hash;
        window.addEventListener('hashchange', async function () {
          if (location.hash !== lastHash) {
            const response = await fetch(location.href);
            const htmlText = await response.text();
            document.open();
            document.write(htmlText);
            document.close();
          }
        });
      });
      </script>
    `;

    // 尝试插入到 </head> 前，或者结尾
    if (contentStr.includes('</head>')) {
      contentStr = contentStr.replace('</head>', refreshScript + '\n</head>');
    } else {
      contentStr += refreshScript;
    }

    document.open();
    document.write(contentStr);
    document.close();
    return;
  }

  await Promise.all([
    (async (title) => {
      title = title.substring(title.search('#'));
      title = title.substring(title.search(' '));
      let end = title.search('\n');
      if (end >= 0) title = title.substring(0, end);
      document.title = title.trim();
    })(contentStr),

    Vditor.preview(document.getElementById("content"), contentStr, {
      cdn: static_dir + 'vditor',
      theme: {
        current: 'kedior',
        path: static_dir + "theme"
      },
      hljs: {
        style: "ant-design",
      },
      hint: {
        emojiPath: static_dir + "vditor/dist/images/emoji"
      }
    })
  ]);
}

function set_pdf_container(is_pdf) {
  var style = document.getElementById("container_id");
  if (!style) {
    style = document.createElement("style");
    style.id = "container_id"
    document.head.appendChild(style);
  }
  if (is_pdf) {
    style.innerHTML = "";
  } else {
    style.innerHTML = `
      @media (min-width: 767px) {
        body {
            background-color: rgb(229, 231, 235);
            <!-- background-color: rgba(227, 249, 253, 0.2); -->
        }

        .markdown-body {
            box-shadow: 0px 4px 6px rgba(0, 0, 0, 0.2);
            border: 1px solid #d3d3d3;
            border-radius: 4px;
        }
      }
      `;
  }
}

function enableImagePreview(imgElement) {
  if (!imgElement || !(imgElement instanceof HTMLImageElement)) return;

  imgElement.style.cursor = 'zoom-in';

  imgElement.addEventListener('click', () => {
    // 创建一个临时 container
    const container = document.createElement('div');
    container.style.display = 'none'; // viewer.js 需要容器存在于 DOM

    const clone = imgElement.cloneNode();
    container.appendChild(clone);
    document.body.appendChild(container);

    const viewer = new Viewer(clone, {
      inline: false,
      navbar: false,
      title: false,
      toolbar: false,
      tooltip: false,
      movable: true,
      zoomable: true,
      scalable: false,
      transition: true,
      fullscreen: false,
      zIndex: 9999,
      hidden() {
        viewer.destroy();
        container.remove(); // 清理 DOM
      }
    });

    viewer.show(); // 显示图片查看器
  });
}

function urlKeySearch(key) {
  const urlParams = new URLSearchParams(window.location.search);
  const hashParams = new URLSearchParams(window.location.hash.slice(1));

  const paramKey = urlParams.get(key);
  const hashKey = hashParams.get(key);
  return hashKey || paramKey || "";
}

