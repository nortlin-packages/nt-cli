import axios from "axios";
import fs from "fs";
import path from "path";
import tar from "tar";
import { parsePackage, createProgressBar, getDownloadUrl, ORG, checkDependencies } from "./utils.js";

export async function install(input) {
  try {
    const { name, version } = parsePackage(input);
    
    const displayVersion = version ? `@${version}` : "";
    console.log(`Instalando ${name}${displayVersion}...\n`);

    let url;
    try {
      url = await getDownloadUrl(name, version);
    } catch (err) {
      if (err.response?.status === 404) {
        console.error(`Erro: Versao nao encontrada para ${name}${displayVersion}`);
        console.error(`Verifique se o repositorio '${ORG}/${name}' existe e tem releases.`);
        return;
      }
      throw err;
    }

    const tempFile = path.join(process.cwd(), `${name}.tar.gz`);
    const nodeModules = path.join(process.cwd(), "node_modules");

    if (!fs.existsSync(nodeModules)) {
      fs.mkdirSync(nodeModules, { recursive: true });
    }

    const bar = createProgressBar();
    bar.start(100, 0);

    const response = await axios({
      url,
      method: "GET",
      responseType: "stream"
    });

    const total = parseInt(response.headers["content-length"], 10) || 0;
    let downloaded = 0;

    const writer = fs.createWriteStream(tempFile);

    response.data.on("data", chunk => {
      downloaded += chunk.length;
      if (total > 0) {
        const percent = (downloaded / total) * 70;
        bar.update(Math.floor(percent));
      }
    });

    response.data.pipe(writer);

    await new Promise((resolve, reject) => {
      writer.on("finish", resolve);
      writer.on("error", reject);
    });

    if (total === 0) {
      bar.update(70);
    }

    let extractProgress = 70;

    await tar.x({
      file: tempFile,
      cwd: nodeModules,
      onentry: () => {
        extractProgress += 3;
        bar.update(Math.min(extractProgress, 99));
      }
    });

    bar.update(100);
    bar.stop();

    fs.unlinkSync(tempFile);

    console.log("Instalado\n");

    checkDependencies(name);

  } catch (err) {
    console.error("\nErro:", err.message);
    process.exit(1);
  }
}
