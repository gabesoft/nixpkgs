{ stdenv, lib, fetchFromGitHub, makeWrapper, autoreconfHook,
  libmspack, openssl, pam, xercesc, icu, libdnet, procps,
  xlibsWrapper, libXinerama, libXi, libXrender, libXrandr, libXtst,
  pkgconfig, glib, gtk, gtkmm, iproute, dbus, systemd }:

let
  majorVersion = "10.1";
  minorVersion = "0";
  version = "${majorVersion}.${minorVersion}";

in stdenv.mkDerivation rec {
  name = "open-vm-tools-${version}";
  src = fetchFromGitHub {
    owner = "vmware";
    repo = "open-vm-tools";
    rev = "stable-${version}";
    sha256 = "1qzk4mvw618ca4j9agsfpqch9jgwghvdc4rpkvlyz8kirvh9iniz";
  };

  sourceRoot = "${src.name}/open-vm-tools";

  buildInputs =
    [ autoreconfHook makeWrapper libmspack openssl pam xercesc icu libdnet procps
      pkgconfig glib gtk gtkmm xlibsWrapper libXinerama libXi libXrender libXrandr libXtst ];

  postPatch = ''
     sed -i s,-Werror,,g configure.ac
     sed -i 's,^confdir = ,confdir = ''${prefix},' scripts/Makefile.am
     sed -i 's,etc/vmware-tools,''${prefix}/etc/vmware-tools,' services/vmtoolsd/Makefile.am
  '';

  patches = [ ./recognize_nixos.patch ];

  configureFlags = "--without-kernel-modules --without-xmlsecurity";

  postInstall = ''
	sed -i 's,which ,command -v ,' "$out/etc/vmware-tools/scripts/vmware/network"
	wrapProgram "$out/etc/vmware-tools/scripts/vmware/network" \
		--prefix PATH ':' "${lib.makeBinPath [ iproute dbus systemd ]}"
  '';

  meta = with stdenv.lib; {
    homepage = "https://github.com/vmware/open-vm-tools";
    description = "Set of tools for VMWare guests to improve host-guest interaction";
    longDescription = ''
      A set of services and modules that enable several features in VMware products for 
      better management of, and seamless user interactions with, guests. 
    '';
    license = licenses.gpl2;
    platforms = platforms.linux;
    maintainers = with maintainers; [ joamaki ];
  };
}
