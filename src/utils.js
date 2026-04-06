import axios from "axios";
import cliProgress from "cli-progress";
import fs from "fs";
import path from "path";

export const ORG = "nortlin-packages";

export function parsePackage(input) {
  const [name, version] = input.split("@");
  return { name, version };
}

export function createProgressBar() {
  return new cliProgress.SingleBar({
    format: "[{bar}] {percentage}%",
    barCompleteChar: "=",
    barIncompleteChar: "-",
    hideCursor: true
  });
}

export async function getDownloadUrl(name, version) {
  let url;
  
  if (version) {
    const response = await axios.get(
      `https://api.github.com/repos/${ORG}/${name}/releases/tags/v${version}`
    );
    url = response.data;
  } else {
    const response = await axios.get(
      `https://api.github.com/repos/${ORG}/${name}/releases/latest`
    );
    url = response.data;
  }

  if (!url.assets || url.assets.length === 0) {
    throw new Error("Nenhum asset encontrado na release");
  }

  const asset = url.assets.find(a => a.name.endsWith(".tar.gz"));

  if (!asset) {
    throw new Error("Nenhum .tar.gz encontrado na release");
  }

  return asset.browser_download_url;
}

export function checkDependencies(pkgName) {
  const pkgPath = path.join(process.cwd(), "node_modules", pkgName);
  const pkgJsonPath = path.join(pkgPath, "package.json");

  if (!fs.existsSync(pkgJsonPath)) return;

  const pkg = JSON.parse(fs.readFileSync(pkgJsonPath, "utf-8"));

  if (!pkg.dependencies) return;

  const deps = Object.keys(pkg.dependencies);

  if (deps.length === 0) return;

  console.log("\nDependencias necessarias:");

  deps.forEach(dep => {
    const depPath = path.join(process.cwd(), "node_modules", dep);
    const installed = fs.existsSync(depPath);
    const status = installed ? "[OK]" : "[PENDENTE]";
    console.log(`  ${status} ${dep}`);
  });

  console.log("\nInstale manualmente:");
  deps.forEach(dep => {
    console.log(`  nt install ${dep}`);
  });
}
