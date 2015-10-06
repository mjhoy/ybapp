{ mkDerivation, base, stdenv, xlsx }:
mkDerivation {
  pname = "ybapp";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [ base xlsx ];
  description = "Downloader for Yellow Barn applicant files";
  license = stdenv.lib.licenses.mit;
}
