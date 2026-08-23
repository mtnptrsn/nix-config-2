# Scrapling's parser, packaged because nixpkgs does not carry it.
#
# Only the base install: the `fetchers` extra pulls in playwright, patchright,
# curl_cffi and a browser fingerprint database, none of which are wanted here.
# The session cookie plus httpx already gets the page; scrapling is here purely
# for adaptive selectors, which relocate an element when Matchi renames a class.
{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  cssselect,
  lxml,
  orjson,
  tld,
  typing-extensions,
  w3lib,
}:
buildPythonPackage rec {
  pname = "scrapling";
  version = "0.4.15";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-ckBpAPQ3MWIJ3QXZhT2uBEIPHKsOEQcWBLtFiLbi9xM=";
  };

  build-system = [ setuptools ];

  # nixpkgs is on cssselect 1.3.0 and upstream asks for >=1.5.0. Scrapling uses
  # only the plain css-to-xpath translation, which has not changed, and the
  # adaptive-selector tests in this repo exercise it against real Matchi markup.
  pythonRelaxDeps = [ "cssselect" ];

  dependencies = [
    cssselect
    lxml
    orjson
    tld
    typing-extensions
    w3lib
  ];

  # Upstream's suite drives real browsers and hits the network.
  doCheck = false;

  pythonImportsCheck = [ "scrapling" ];

  meta = {
    description = "HTML parsing library with adaptive element relocation";
    homepage = "https://github.com/D4Vinci/Scrapling";
    license = lib.licenses.bsd3;
  };
}
