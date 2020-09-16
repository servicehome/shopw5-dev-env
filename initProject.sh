#!/usr/bin/env bash

BASE=$(cd $(dirname "$0") && pwd)
COMPOSER_BIN=$(command -v composer)
PHP_BIN=$(command -v php)
WGET_BIN=$(command -v wget)

HOMESTEAD_CONFIG_FILE="Homestead.yaml"
INIT_TEMPLATE="shopwareInit.template"
INIT_SCRIPT="shopwareInit.sh"

PHP_VERSION="7.2"
SHOP_DOMAIN_NAME="shopware5.test"
SHOPDIR="$BASE/shopware5"
GIT_SHOPDIR="$BASE/git-shopware5"

# SHOPWARE DOWNLOAD URL
DOWNLOAD_URL="https://www.shopware.com/en/Download/redirect/version/sw5/file/install_5.6.8_7b49bfb8ea0d5269b349722157fe324a341ed28e.zip"

### You should modify these variables for your needs.
##########################################################
##########################################################

### HELPER
##########################################################

function guaranteeDirectory() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
  else
    return 0
  fi
}

function isEmptyDirectory() {
  if [ -z "$(ls -A $1)" ]; then
    return 0
  else
    return 1
  fi
}

function linkExists() {
  if [ -L "$1" ]; then
    return 0
  else
    return 1
  fi
}

function setColor() {
  echo "\e[$1m"
}

function resetColorsToDefault() {
  setColor 0
}

### SETUP FUNCTIONS
##########################################################

function cloneShopwareRepo() {
  guaranteeDirectory "$GIT_SHOPDIR" &&
    if isEmptyDirectory "$GIT_SHOPDIR"; then
      (cd "$GIT_SHOPDIR" && git clone https://github.com/shopware/shopware.git .)
    fi
}

function downloadAndUnzipShopwareInstaller() {
  if [ ! -d "$BASE/download" ]; then
    echo "download..."
    (mkdir -p "$BASE/download" && cd "$BASE/download" && $WGET_BIN $DOWNLOAD_URL)
  fi

  guaranteeDirectory "$SHOPDIR" &&
    if [ -d "$BASE/download" ]; then
      if isEmptyDirectory "$SHOPDIR"; then
        (cd "$BASE/download" && unzip "install_*.zip" -d "$SHOPDIR")
      else
        echo "Shopdirectory allready contains data!"
      fi
    else
      echo "no zip file found!"
    fi || echo "No shop directory. Error=$?"
}

function linkBuildDirectoryForComposerPostScripts() {
  if linkExists "$SHOPDIR/build"; then
    echo "build folder allready linked!"
    return 0
  else
    echo "link build folder..."
    (cd "$SHOPDIR" && ln -s "$GIT_SHOPDIR/build" .)

    linkExists "$SHOPDIR/build"
  fi
}

function setPermissions() {
  chmod -R 755 $SHOPDIR/custom/plugins &&
    chmod -R 755 $SHOPDIR/engine/Shopware/Plugins/Community &&
    chmod -R 755 $SHOPDIR/files &&
    chmod -R 755 $SHOPDIR/media &&
    chmod -R 755 $SHOPDIR/var &&
    chmod -R 755 $SHOPDIR/web
}

function composerRequireHomestead() {
  (cd $SHOPDIR && "$COMPOSER_BIN" require laravel/homestead --dev)
}

function setupHomestead() {
  # folders: type: "nfs"
  # sites: add type: "apache" and php: "7.2"
  # ../public -> ../
  # sites: map: homestead.test -> $SHOP_DOMAIN_NAME

  if [ ! -f "$SHOPDIR/$HOMESTEAD_CONFIG_FILE.backup" ]; then
    (
      cd "$SHOPDIR" && $PHP_BIN vendor/bin/homestead make &&
        [ -f "$HOMESTEAD_CONFIG_FILE" ] &&
        cp "$HOMESTEAD_CONFIG_FILE" "$HOMESTEAD_CONFIG_FILE.backup" &&
        awk '/\/home\/vagrant\/code$/ {print "        type: \"nfs\""}1' <"$HOMESTEAD_CONFIG_FILE.backup" |
        awk '/to: \/home\/vagrant\/code\/public/ { print "        type: apache\n        php: \"'$PHP_VERSION'\"" }1' |
        awk '{ gsub(/\/public$/, "") }1' |
        awk '{ gsub(/name:.*$/, "name: '$SHOP_DOMAIN_NAME'") }1' |
        awk '{ gsub(/hostname:.*$/, "hostname: '$SHOP_DOMAIN_NAME'") }1' |
        awk '{ gsub(/homestead\.test/, "'$SHOP_DOMAIN_NAME'")}1' >"$HOMESTEAD_CONFIG_FILE"
    )
  fi
}

function updateAfterScript() {
  cat "$BASE/homestead-after-script.template" |
    awk '{ gsub(/!!!PHP_VERSION!!!/, "'$PHP_VERSION'") }1' |
    awk '{ gsub(/!!!DOMAIN!!!/, "'$SHOP_DOMAIN_NAME'") }1' >>"$SHOPDIR/after.sh"
}

function printUsage() {
  printf "\nThe shop code is located here: $(setColor "42;97")$SHOPDIR$(resetColorsToDefault)\n"

  printf "\nHave a look at $(setColor "1;107;101")Homestead.yaml$(resetColorsToDefault) file in the shop directory to setup to your needs.\n"

  printf "\nGo to the shop directory and start container with: $(setColor "7")vagrant up$(resetColorsToDefault)\n\n"
}

### Start setup
##########################################################

cloneShopwareRepo &&
  downloadAndUnzipShopwareInstaller &&
  linkBuildDirectoryForComposerPostScripts &&
  setPermissions &&
  composerRequireHomestead &&
  setupHomestead &&
  updateAfterScript &&
  printUsage
