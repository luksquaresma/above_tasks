let
  pconfig = { 
    config = { 
      allowUnfree = true;
      cudaSupport = true;
      android_sdk.accept_license = true;
    };
  };
  pkgs =     import <nixpkgs>        pconfig;
  unstable = import <nixos-unstable> pconfig;
  slib =     pkgs.lib.strings;

  androidComposition = pkgs.androidenv.composeAndroidPackages {
    # Specify desired API levels and ABI; include the emulator
    platformVersions = [ "34" ];
    abiVersions      = [ "armeabi-v7a" "arm64-v8a" ];
    includeEmulator  = true;
  };
  androidSdk = androidComposition.androidsdk;
in

pkgs.mkShell rec {
  name = "above_tasks";

  # Include Flutter, the composed Android SDK, and a JDK
  buildInputs = [
    pkgs.flutter
    androidSdk
    pkgs.jdk17
    unstable.google-chrome
  ];

  # Set environment variables so Flutter/ADB find the SDK and Java
  ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
  ANDROID_HOME     = "${androidSdk}/libexec/android-sdk";
  CHROME_EXECUTABLE="${unstable.google-chrome}/bin/google-chrome-stable";
  JAVA_HOME        = "${pkgs.jdk17}";

  shellHook = ''
    export PATH="$JAVA_HOME/bin:$PATH"

    function fok() { read -p "$1 (y/N): " && [[ $REPLY =~ ^([yY][eE][sS]|[yY])$ ]] }
    
    function code_here() {
      nohup code --disable-gpu ./ >/dev/null 2>&1 && echo;      
    }

    function get_git_branch() {
      git name-rev --name-only HEAD > /dev/null 2>&1
      if [[ $? -eq 0 ]]; then
        echo "($(git name-rev --name-only HEAD))";
      else
        echo "";
      fi
    };
    PS1="\n\[\033[1;33m\][${name}:\w]\n\$(get_git_branch)\$\[\033[0m\] ";

    flutter --disable-analytics
    echo; echo "Fixing Flutter Licenses"; flutter doctor --android-licenses; flutter doctor;
  '';
}
