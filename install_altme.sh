#!/usr/bin/env bash

sudo rm -r altme
mkdir altme
cd altme
if [[ "$*" != *-android* ]] && [[ "$*" != *-ios* ]]; then
  echo -e "\033[0;31mAt least one of the following arguments are required to build didkit:\033[0m
    \033[0;36m-android\033[0m: builds didkit's Android binaries
    \033[0;36m-ios\033[0m: builds didkit's iOS binaries
"
  exit
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "Checking for brew installation."
  if ! command -v brew &>/dev/null; then
    echo -e "\033[0;Could not find brew, please install brew or add it to path.\033[0m"
    exit
  fi
fi

echo "Checking for rustup installation and setting rust to nightly."
if ! command -v rustup &>/dev/null; then
  echo "rustup"
  if ! command -v curl &>/dev/null; then
    echo "curl"
    if [[ "$OSTYPE" == "darwin"* ]]; then
      echo "rust darwin"
      brew install curl
    else
      echo "rust linux"
      sudo apt install curl -yet
    fi
  fi

  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

fi
rustup default nightly

if [[ "$*" == *-android* ]]; then
  echo "Checking for java installation."

  if ! command -v javac &>/dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      brew install openjdk
    else
      sudo apt install default-jdk
    fi
  fi
fi

echo "Cloning AltMet repo if not yet on previous directory"
[ ! -d "AltMe" ] && git clone git@github.com:TalaoDAO/AltMe.git

echo "Cloning DIDKit repo if not yet on previous directory"
[ ! -d "didkit" ] && git clone https://github.com/spruceid/didkit.git

echo "Cloning SSI repo if not yet on previous directory"
[ ! -d "ssi" ] && git clone https://github.com/spruceid/ssi.git --recurse-submodules

echo "update didkit makefile to use flutter with fvm"
cp ../key.properties altme/android/

if [[ "$*" == *-android* ]]; then
  echo "Checking for android sdk."
  [ ! -d "$ANDROID_SDK_ROOT" ] && echo -e "\033[0;31mFailed to find Android SDK\033[0m" && exit
  [ ! -d "$ANDROID_SDK_ROOT/build-tools" ] && [ ! -d "$ANDROID_TOOLS" ] && echo -e "\033[0;31mFailed to find android-tools\033[0m" && exit
  [ ! -d "$ANDROID_SDK_ROOT/ndk" ] && [ ! -d "$ANDROID_NDK_HOME" ] && echo -e "\033[0;31mFailed to find Android NDK\033[0m" && exit
fi

if ! command -v flutter &>/dev/null; then
  echo -e "\033[0;Could not find Flutter, please install flutter or add to path.\033[0m"
  exit
fi

if [[ "$*" == *-android* ]]; then
  flutter doctor --android-licenses
fi

cd didkit

if [[ "$*" == *-android* ]]; then
  echo "Build didkit for Android"
  cd lib/flutter
  fvm use 3.7.0
  fvm flutter pub get
  cd -
  make -C lib install-rustup-android
  make -C lib ../target/test/java.stamp
  make -C lib ../target/test/android.stamp
  make -C lib ../target/test/flutter.stamp
fi

if [[ "$*" == *-ios* ]]; then
  echo "Build didkit for iOS"
  make -C lib install-rustup-ios
  make -C lib ../target/test/ios.stamp
fi

echo "cargo build"
cargo build

cd  ../AltMe
echo "moving to AltMe wallet and building apk"
fvm use 3.7.0
if [[ "$*" == *-ios* ]]; then
  echo "update cocoapod"
  rm ios/Podfile.lock
  cd ios
  pod install
  pod update
  echo "build ios version"
  fvm flutter pub get
  fvm flutter build ios
  cd ios
  fastlane beta
fi
if [[ "$*" == *-android* ]]; then
  echo "build android version"
  fvm flutter pub get
  fvm flutter build apk
fi

