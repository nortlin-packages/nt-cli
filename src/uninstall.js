import fs from "fs";
import path from "path";
import { createProgressBar } from "./utils.js";

export function uninstall(pkg) {
  const target = path.join(process.cwd(), "node_modules", pkg);

  if (!fs.existsSync(target)) {
    console.log(`Pacote '${pkg}' nao esta instalado`);
    return;
  }

  console.log(`Removendo ${pkg}...\n`);

  const bar = createProgressBar();
  bar.start(100, 0);

  let progress = 0;

  const interval = setInterval(() => {
    progress += 20;
    bar.update(progress);

    if (progress >= 100) {
      clearInterval(interval);
      
      try {
        fs.rmSync(target, { recursive: true, force: true });
        bar.stop();
        console.log("Removido\n");
      } catch (err) {
        bar.stop();
        console.error(`Erro ao remover: ${err.message}`);
        process.exit(1);
      }
    }
  }, 100);
}
