# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  masterTarball = fetchTarball
    "https://github.com/NixOS/nixpkgs/archive/master.tar.gz";
  customTarball = fetchTarball
    "https://github.com/msfjarvis/custom-nixpkgs/archive/cec5c9cf897502a444d3843f7a0aaaa852bd3fe2.tar.gz";

in {
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Enable non-free packages, and add an `latest` reference to use packages
  # from the nixpkgs master branch.
  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      latest = import masterTarball { config = config.nixpkgs.config; };
      custom = import customTarball { };
    };
  };

  # Use the latest available kernel.
  boot.kernelPackages = pkgs.linuxPackages_4_19;

  # Enable the rtl8821ce module
  boot.extraModulePackages = with config.boot.kernelPackages; [ rtl8821ce ];

  # Set come cmdline options for AMDGPU
  boot.kernelParams = [ "amd_iommu=pt" "ivrs_ioapic[32]=00:14.0" "iommu=soft" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking settings.
  networking = {
    nameservers = [ "::1" ];
    hostName = "jarvisbox";
    resolvconf.dnsExtensionMechanism = false;
    networkmanager.dns = "none";
    useDHCP = false;
    interfaces.enp2s0.useDHCP = true;
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Configure fonts
  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [
      latest.cascadia-code
      custom.jetbrains-mono-nerdfonts
      latest.noto-fonts
      latest.roboto
      latest.ubuntu_font_family
    ];
    fontconfig = {
      penultimate.enable = false;
      defaultFonts = {
        serif = [ "Ubuntu" ];
        sansSerif = [ "Ubuntu" ];
        monospace = [ "Jetbrains Mono Nerd Font Mono Regular" ];
      };
    };
  };

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    latest.bind
    latest.busybox
    latest.clang_10
    latest.cmake
    latest.curl
    latest.file
    latest.htop
    latest.llvmPackages_10.bintools
    latest.lsb-release
    latest.networkmanager
    latest.ninja
    latest.openssl_1_1
    latest.plata-theme
    latest.python38
    latest.python38Packages.python-fontconfig
    latest.traceroute
    latest.wget
    latest.wireguard
    latest.wireguard-go
    latest.wireguard-tools
    latest.unzip
    latest.xclip
  ];

  # Make sure ~/bin is in $PATH.
  environment.homeBinInPath = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    pinentryFlavor = "gnome3";
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Disable the resolved service.
  services.resolved.enable = false;

  # Enable PCSC-Lite daemon for use with my Yubikey.
  services.pcscd.enable = true;

  # Enable U2F support
  hardware.u2f.enable = true;

  # Configure dnscrypt-proxy with the Cloudflare DoH resolver and dnsmasq to work alongside.
  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      listen_addresses = [ "127.0.0.1:43" ];
      ipv6_servers = true;
      require_dnssec = true;
      server_names = [ "cloudflare-security" "cloudflare-security-ipv6" ];
      static."cloudflare-security".stamp =
        "sdns://AgMAAAAAAAAABzEuMC4wLjIAG3NlY3VyaXR5LmNsb3VkZmxhcmUtZG5zLmNvbQovZG5zLXF1ZXJ5";
      static."cloudflare-security-ipv6".stamp =
        "sdns://AgMAAAAAAAAAGlsyNjA2OjQ3MDA6NDcwMDo6MTExMl06NDQzABtzZWN1cml0eS5jbG91ZGZsYXJlLWRucy5jb20KL2Rucy1xdWVyeQ";
    };
  };
  services.dnsmasq.enable = true;
  services.dnsmasq.servers = [ "127.0.0.1#43" ];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable the X11 windowing system and additional services for GNOME Desktop Environment.
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome3.enable = true;
    layout = "us";
    videoDrivers = [ "amdgpu" ];
  };

  # Configure Ryzen and AMDGPU
  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;

  # Enable touchpad support.
  services.xserver.libinput.enable = true;

  # Install udev packages
  services.udev.packages = with pkgs; [
    libu2f-host
    gnome3.gnome-settings-daemon
  ];

  # Stuff for gnome-shell-extensions to work properly.
  services.gnome3.chrome-gnome-shell.enable = true;

  # Disable services for faster boot times.
  systemd.services.NetworkManager-wait-online.enable = false;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.msfjarvis = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networking" ]; # Enable ‘sudo’ for the user.
  };

  # User-specific packages for me, myself and I.
  users.users.msfjarvis.packages = with pkgs; [
    latest.android-udev-rules
    latest.aria2
    latest.asciinema
    latest.bandwhich
    latest.bat
    latest.brave
    latest.browserpass
    latest.cargo
    latest.cargo-audit
    latest.cargo-bloat
    latest.cargo-deps
    latest.cargo-edit
    latest.cargo-outdated
    latest.cargo-release
    latest.cargo-sweep
    latest.cargo-update
    latest.gitAndTools.diff-so-fancy
    latest.gitAndTools.git-crypt
    latest.gitAndTools.git-extras
    latest.diskus
    latest.du-dust
    latest.exa
    latest.fd
    latest.figlet
    latest.fontconfig
    latest.fzf
    latest.gitAndTools.gh
    latest.git
    latest.glow
    latest.gnome3.gnome-shell-extensions
    latest.gnome3.gnome-tweaks
    latest.gnumake
    latest.gitAndTools.hub
    latest.hugo
    latest.hyperfine
    latest.jq
    latest.mosh
    latest.nano
    latest.ncdu
    latest.neo-cowsay
    latest.neofetch
    latest.nixfmt
    latest.nodejs-13_x
    latest.pass
    latest.patchelf
    latest.procs
    latest.ripgrep
    latest.rustup
    latest.tdesktop
    latest.sass
    latest.shellcheck
    latest.shfmt
    latest.spotify-tui
    latest.starship
    latest.vscode
    latest.zoxide
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

  system.copySystemConfiguration = true;
}
