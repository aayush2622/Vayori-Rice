{ self, inputs, ... }:
{
  flake.nixosModules.vmTesting = { pkgs, lib, config, ... }:
  let
    # The Nix-built qemu expects NixOS's own /run/opengl-driver mesa layout
    # for GPU passthrough (virtio-vga-gl), which doesn't exist on this
    # EndeavourOS dev host - these are its real Arch mesa paths instead.
    # Wrapping qemu itself (rather than requiring env vars at launch time)
    # means the plain `nix build .#nixosConfigurations.Diablo.config.system.build.vm`
    # + `./result/bin/run-Diablo-vm` workflow just works unmodified.
    qemuWithHostGL = pkgs.symlinkJoin {
      name = "qemu-host-gl";
      paths = [ pkgs.qemu_kvm ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/qemu-system-x86_64 \
          --set GBM_BACKENDS_PATH /usr/lib/gbm \
          --set LIBGL_DRIVERS_PATH /usr/lib/dri \
          --set __EGL_VENDOR_LIBRARY_DIRS /usr/share/glvnd/egl_vendor.d \
          --suffix LD_LIBRARY_PATH : /usr/lib:/usr/lib/dri:/usr/lib/gbm
      '';
    };
  in {
    virtualisation.vmVariant = {
      # QEMU has no Nvidia GPU and no ASUS hardware - the real driver
      # stack/daemons would just fail to find anything and block boot.
      services.xserver.videoDrivers = lib.mkForce [ ];
      services.asusd.enable = lib.mkForce false;
      services.supergfxd.enable = lib.mkForce false;

      # QEMU's bochs-drm has no real DRI2 driver, so the SDDM greeter's QML
      # frontend (a Wayland client) can't get a hardware EGL context, and
      # Mesa's zink fallback also fails (no Vulkan ICD) - without this the
      # VM goes black right after "Reached target Graphical Interface."
      services.displayManager.sddm.settings.General.GreeterEnvironment = lib.mkForce
        "XCURSOR_THEME=${config.vayori.theme.cursorTheme},XCURSOR_SIZE=${toString config.vayori.theme.cursorSize},XCURSOR_PATH=${config.vayori.theme.cursorPackage}/share/icons,QT_QUICK_BACKEND=software";

      virtualisation = {
        memorySize = 6144;
        cores = 4;
        # Gives niri's own TTY/DRM backend a real GPU allocator via the
        # host's GPU (see qemuWithHostGL above) - without this it falls
        # back to a plain framebuffer with no allocator at all, and niri
        # silently ends up with zero outputs.
        qemu.package = qemuWithHostGL;
        qemu.options = [
          "-display" "gtk,gl=on"
          "-device" "virtio-vga-gl"
        ];
      };
    };
  };
}
