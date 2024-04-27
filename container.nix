{
  lib,
  buildEnv,
  dockerTools,
  runCommand,
  bashInteractive,
  workerd,
}:
dockerTools.buildLayeredImage {
  name = workerd.pname;
  tag = "latest";

  contents = [
    (buildEnv {
      name = "image-root";
      paths = [
        (runCommand "bin-sh" {} ''
          mkdir -p $out/bin
          ln -s ${lib.getExe bashInteractive} $out/bin/sh
        '')
        workerd
      ];
      pathsToLink = ["/bin" "/etc"];
    })
    dockerTools.caCertificates
  ];

  config.Cmd = [(lib.getExe workerd)];
  architecture = workerd.stdenv.hostPlatform.ubootArch;
}
