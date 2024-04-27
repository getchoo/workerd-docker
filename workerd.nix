{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "workerd";
  version = "1.20240423.0";

  src = let
    baseUrl = "https://github.com/cloudflare/workerd/releases/download/v${finalAttrs.version}";
  in
    fetchurl
    {
      x86_64-linux = {
        url = "${baseUrl}/workerd-linux-64.gz";
        hash = "sha256-gXqTFp+u9j+nOtwfowEUUk1QaxrhyqO8fFzZFGchAvk=";
      };

      aarch64-linux = {
        url = "${baseUrl}/workerd-linux-arm64.gz";
        hash = "sha256-6IynAN/xp8hieeMEuYbrv9X6edoTzKYZqCOcTPUy12o=";
      };
    }
    .${stdenvNoCC.hostPlatform.system}
    or (throw "${stdenvNoCC.hostPlatform.system} is not supported!");

  nativeBuildInputs = [autoPatchelfHook];

  dontConfigure = true;
  dontBuild = true;
  doCheck = false;

  unpackCmd = ''
    runHook preUnpack

    dest="$(stripHash $curSrc)"
    cp "$curSrc" "$dest"
    gzip -d "$dest"
    mkdir source
    mv ''${dest/.gz/} source/

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 workerd-* $out/bin/workerd

    runHook postInstall
  '';

  meta = with lib; {
    mainProgram = "workerd";
    description = "The JavaScript / Wasm runtime that powers Cloudflare Workers";
    homepage = "https://github.com/cloudflare/workerd";
    changelog = "https://github.com/cloudflare/workerd/releases/tag/v${finalAttrs.version}";
    license = licenses.asl20;
    maintainers = with maintainers; [getchoo];
    platforms = ["x86_64-linux" "aarch64-linux"];
  };
})
