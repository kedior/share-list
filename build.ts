import { writeFile, mkdir, rm } from "fs/promises";
import { build } from "bun";

const distDir = "./out";
await rm(distDir, { recursive: true, force: true });
await mkdir(distDir, { recursive: true });

const entryJsPath = "./out/app.js";
const entryHtmlPath = "./out/index.html";
const jsCode = `import { main } from "../build/dev/javascript/app/app.mjs";main();`;
const htmlCode = `<!doctype html><script type="module" src="./app.js"></script>`;

await writeFile(entryJsPath, jsCode);
await writeFile(entryHtmlPath, htmlCode);

const result = await build({
  entrypoints: [entryJsPath],
  outdir: distDir,
  target: "browser",
  minify: true,
});

console.log(result);
