import fs from "fs";
import path from "path";

export function list() {
  const nodeModules = path.join(process.cwd(), "node_modules");

  if (!fs.existsSync(nodeModules)) {
    console.log("Nenhum pacote instalado");
    return;
  }

  const packages = fs.readdirSync(nodeModules).filter(item => {
    const itemPath = path.join(nodeModules, item);
    return fs.statSync(itemPath).isDirectory() && !item.startsWith(".");
  });

  if (packages.length === 0) {
    console.log("Nenhum pacote instalado");
    return;
  }

  console.log("Pacotes instalados:\n");

  packages.forEach(pkg => {
    const pkgPath = path.join(nodeModules, pkg, "package.json");
    let version = "";
    
    if (fs.existsSync(pkgPath)) {
      try {
        const pkgData = JSON.parse(fs.readFileSync(pkgPath, "utf-8"));
        version = pkgData.version ? `@${pkgData.version}` : "";
      } catch {
        // ignora erro de parse
      }
    }
    
    console.log(`  ${pkg}${version}`);
  });

  console.log("");
}
