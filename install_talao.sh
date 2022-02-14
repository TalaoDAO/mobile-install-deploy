#!/usr/bin/env bash

sudo rm -r spruceid
mkdir spruceid
cd spruceid
rustup default nightly

echo "Cloning talao credible repo if not yet on previous directory"
git clone git@github.com:TalaoDAO/credible.git
cd credible
git checkout iphone_freeze_launch#123
cd -
echo "Cloning DIDKit repo if not yet on previous directory"
git clone https://github.com/spruceid/didkit.git
cd didkit
git checkout c5c422f2469c2c5cc2f6e6d8746e95b552fce3ed
cd ..


echo "Cloning SSI repo if not yet on previous directory"
git clone https://github.com/spruceid/ssi.git --recurse-submodules
cd ssi
git checkout 15e944620e20b31b4644edad094e01ff7b418e44
cd ..

echo "update didkit makefile to use flutter with fvm"
# cp ../Makefile didkit/lib/
cp ../key.properties credible/android/
# cp ../Cargo.toml ssi/
# cp ../jws.rs ssi/src/
  echo "Checking for android sdk."
#flutter channel dev
#flutter upgrade

#  flutter doctor --android-licenses

#cd $HOME
#wget https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip
#unzip sdk-tools-linux-4333796.zip -d Library/Android
#rm sdk-tools-linux-4333796.zip
#wget https://dl.google.com/android/repository/commandlinetools-linux-6200805_latest.zip
#unzip commandlinetools-linux-6200805_latest.zip -d Library/Android/cmdline-tools
#rm commandlinetools-linux-6200805_latest.zip
#cd -

cd didkit

  echo "Build didkit for Android"
  cd lib/flutter
  fvm use 2.8.1
  fvm flutter pub get
  cd -
  make -C lib install-rustup-android
  make -C lib ../target/test/java.stamp
  make -C lib ../target/test/android.stamp
  make -C lib ../target/test/flutter.stamp

cargo build
cd  ../credible
echo "moving to credible and building apk"
fvm use 2.8.1
  echo "build android version"
  fvm flutter pub get
  fvm flutter build apk
