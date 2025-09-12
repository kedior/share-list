import { writeFile, mkdir, rm } from "fs/promises";
import { build } from "bun";

const distDir = "./out";
await rm(distDir, { recursive: true, force: true });
await mkdir(distDir, { recursive: true });

const entryJsPath = "./out/__entry.js";
const jsCode = `import { main } from "../build/dev/javascript/app/app.mjs";main();`;
await writeFile(entryJsPath, jsCode);
const result = await build({
  entrypoints: [entryJsPath],
  target: "browser",
  minify: true,
});

let bundledJs = await result.outputs[0]?.text()!
console.log(result);
await rm(entryJsPath);

const safeJs = bundledJs.replace(/<\/script>/g, "<\\/script>");
const entryHtmlPath = "./out/index.html";
const htmlCode = `<!doctype html><html lang="en"><script type="module">${safeJs}</script></html>`;
await writeFile(entryHtmlPath, htmlCode);
console.log(`Build complete: ${entryHtmlPath}`);

