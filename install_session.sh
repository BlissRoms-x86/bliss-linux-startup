#!/usr/bin/env bash

# Bliss OS Session Installer
# 
# This will install Weston session manager, qemu, and setup the 
# Bliss session option
# 

SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
HPATH=$HOME
CONFIG="false"

# echo "Checking for dependencies first..."
# sudo apt install weston qemu qemu-system mutter sakura libvirt-clients
echo "now installing..."
sudo cp -rp $SCRIPT_PATH/usr/* /usr/
cp -r $SCRIPT_PATH/home/ $HPATH/
sudo chmod +X /usr/bin/bliss*
sudo chmod 777 /usr/bin/bliss-*

echo "All set. Thanks for installing."
