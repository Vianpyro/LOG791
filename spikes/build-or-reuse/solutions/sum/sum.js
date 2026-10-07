const [a, b] = require("node:fs").readFileSync(0, "utf8").trim().split(/\s+/).map(BigInt);

console.log(String(a + b));
