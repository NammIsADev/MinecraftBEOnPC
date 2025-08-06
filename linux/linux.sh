#!/bin/bash
# MBOP Setup - Minecraft Bedrock on Linux (Waydroid)
# Supports: Debian/Ubuntu and derivatives

set -e

# === Functions ===
info() { echo -e "\033[1;32m[*]\033[0m $1"; }
error() { echo -e "\033[1;31m[!]\033[0m $1"; }

# === Title ===
echo "==============================================="
echo "     MBOP Installer - Minecraft on PC"
echo "     Platform: Debian/Ubuntu Linux Systems"
echo "==============================================="

# === Check for root ===
if [[ $EUID -ne 0 ]]; then
  error "Please run this script as root (use sudo)."
  exit 1
fi

# === Check for apt ===
if ! command -v apt > /dev/null; then
  error "This script only works on Debian/Ubuntu-based systems."
  exit 1
fi

# === Install system dependencies ===
info "Installing system dependencies..."
apt update
apt install -y curl ca-certificates git python3 python3-venv lzip lxc adb

# === Add Waydroid repository ===
info "Adding Waydroid repository..."
curl -s https://repo.waydro.id | bash || {
  error "Failed to add Waydroid repo. Try manually:"
  echo "curl -s https://repo.waydro.id | sudo bash -s <DISTRO>"
  exit 1
}

# === Install Waydroid ===
info "Installing Waydroid..."
apt install -y waydroid || {
  error "Waydroid installation failed."
  exit 1
}

# === Prompt to open Waydroid and download image ===
info "Please open the Waydroid app now and download the Android image."
echo "Make sure you're using a Wayland session (Ubuntu 22.04+)."
echo "Once the image is initialized, proceed."
read -p "Press Enter once the Android image is installed..."

# === Clone waydroid_script ===
if [ ! -d "waydroid_script" ]; then
  info "Cloning casualsnek/waydroid_script..."
  git clone https://github.com/casualsnek/waydroid_script.git
fi

# === Setup Python venv and install requirements ===
cd waydroid_script
info "Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# === Ask for optional modules ===
echo
echo "Required Waydroid components (space-separated):"
echo "libndk (for AMD), libhoudini (for Intel)"
echo "If you don't want to install required compoments, you will need a x86 Minecraft PE APK."
read -rp "Enter options to install (or leave blank, not recommended): " OPTIONS

if [ -n "$OPTIONS" ]; then
  sudo python3 main.py install $OPTIONS
fi
cd ..

# === Ask for Waydroid IP ===
echo
info "Make sure Waydroid is running."
info "Grab waydroid IP address from Android Settings-> About"
read -rp "Enter Waydroid IP address (default is 192.168.250.1): " USER_IP
USER_IP=${USER_IP:-192.168.250.1}

# === ADB Connect ===
info "Connecting ADB to Waydroid at $USER_IP:5555..."
adb connect "$USER_IP:5555" || {
  error "Failed to connect to Waydroid via ADB. Is it running and debugging enabled?"
  exit 1
}

# === Check for Minecraft APK ===
APK_FILE="runtime/Minecraft.apk"
if [ ! -f "$APK_FILE" ]; then
  error "Minecraft.apk not found in 'runtime' folder."
  echo "Please download the APK and place it at: runtime/Minecraft.apk"
  exit 1
fi

# === Install Minecraft ===
info "Installing Minecraft into Waydroid..."
waydroid app install "$APK_FILE" || {
  error "APK installation failed. Ensure Waydroid is running and ADB is connected."
  exit 1
}

# === Success ===
echo
echo -e "\033[1;34m[✔]\033[0m Minecraft Bedrock has been successfully installed!"
echo "Enjoy Minecraft on Linux via Waydroid 🎉"
