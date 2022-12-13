async function main() {
  const fs = require("fs");
  const contractsDir = __dirname + "/../ethereum/EVM";

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  let Artifact
  Artifact = artifacts.readArtifactSync("ERC20Token");
  fs.writeFileSync(
    contractsDir + "/ERC20Token.json",
    JSON.stringify(Artifact, null, 2)
  );
  Artifact = artifacts.readArtifactSync("ERC721Token");
  fs.writeFileSync(
    contractsDir + "/ERC721Token.json",
    JSON.stringify(Artifact, null, 2)
  );
  Artifact = artifacts.readArtifactSync("ERC1155Token");
  fs.writeFileSync(
    contractsDir + "/ERC1155Token.json",
    JSON.stringify(Artifact, null, 2)
  );

  Artifact = artifacts.readArtifactSync("TWFactory");
  fs.writeFileSync(
    contractsDir + "/TWFactory.json",
    JSON.stringify(Artifact, null, 2)
  );
  Artifact = artifacts.readArtifactSync("TWRegistry");
  fs.writeFileSync(
    contractsDir + "/TWRegistry.json",
    JSON.stringify(Artifact, null, 2)
  );
  Artifact = artifacts.readArtifactSync("TokenERC20");
  fs.writeFileSync(
    contractsDir + "/TokenERC20.json",
    JSON.stringify(Artifact, null, 2)
  );
}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});
