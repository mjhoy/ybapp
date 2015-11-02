{ mkDerivation, base, bytestring, containers, directory, filepath
, lens, process, regex-tdfa, snap-core, stdenv, text, xlsx
}:
mkDerivation {
  pname = "ybapp";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [
    base bytestring containers directory filepath lens process
    regex-tdfa snap-core text xlsx
  ];
  description = "Downloader for Yellow Barn applicant files";
  license = stdenv.lib.licenses.mit;
}
