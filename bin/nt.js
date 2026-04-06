#!/usr/bin/env node

import { install } from "../src/install.js";
import { uninstall } from "../src/uninstall.js";
import { list } from "../src/list.js";

const args = process.argv.slice(2);
const command = args[0];
const pkg = args[1];

switch (command) {
  case "install":
    if (!pkg) {
      console.log("Uso: nt install <package>[@version]");
      process.exit(1);
    }
    install(pkg);
    break;

  case "uninstall":
    if (!pkg) {
      console.log("Uso: nt uninstall <package>");
      process.exit(1);
    }
    uninstall(pkg);
    break;

  case "list":
    list();
    break;

  default:
    console.log("Comando nao reconhecido.");
    console.log("Uso: nt <install|uninstall|list> [package]");
}
