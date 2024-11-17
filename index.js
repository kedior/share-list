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
        {ciphertext: ciphertext},
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
    if(!static_dir) static_dir = '';
    if(contentStr.includes('<!DOCTYPE html>')) {
        window.document.write(contentStr);
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

function add_container() {
    const style = document.createElement("style");
    style.type = "text/css";
    style.innerHTML = `
        body {
            background-color: rgba(227, 249, 253, 0.2);
        }
            .markdown-body {
                box-shadow: 0px 4px 6px rgba(0, 0, 0, 0.2);
                border: 1px solid #d3d3d3;
                border-radius: 4px;
            }
        `;

    document.head.appendChild(style);
}