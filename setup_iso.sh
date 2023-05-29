#!/bin/bash

SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# First, we check for a .iso file in /updates/blissos 
# If found we use that as the path to the .iso file
if [ -f "$/updates/blissos/*.iso" ]; then
    # find newest .iso in there
    iso_path=$(ls -t $/updates/blissos/*.iso | head -1)
    echo "Using $iso_path as the path to the .iso file"
    ISO_PATH=$iso_path
fi


# Check $1 to make sure it's an iso file
if [ ! -f "$1" ]; then
    echo "File not found, you need to pass the path to your .iso file"
    exit 1
else
    ISO_PATH=$1
fi

# Check to see if we have a /blissos/ folder already
if [ ! -d "/blissos" ]; then
    echo "Folder already exists"
    sudo mkdir -p /blissos
else
	echo "/blissos folder found"
fi

# Mount the .iso file
echo "Mounting .iso file..."
sudo mkdir -p /mnt/iso
sudo mount -o loop $ISO_PATH /mnt/iso

# Check the mounted .iso file for a system.efs file
if [ -f "/mnt/iso/system.efs" ]; then
	echo "EFS system found"
    #Mount the system.efs file
    sudo mkdir -p /mnt/efs
    sudo mount -o loop /mnt/iso/system.efs /mnt/efs
    # copy the syste,.img from inside the mounted system.efs file to /blissos
    sudo cp /mnt/efs/system.img /blissos/
    # unmount the system.efs file
    sudo umount /mnt/efs
elif [ -f "/mnt/iso/system.sfs" ]; then
	echo "SFS system found"
    #Mount the system.sfs file
    sudo mkdir -p /mnt/sfs
    sudo mount -o loop /mnt/iso/system.sfs /mnt/sfs
    # copy the syste,.img from inside the mounted system.sfs file to /blissos
    sudo cp /mnt/sfs/system.img /blissos/
    # unmount the system.sfs file
    sudo umount /mnt/sfs
fi
if [ ! -f "/blissos/system.img" ]; then
	echo "Somethings wrong, exiting"
	exit 1
fi
# Copy the initrd.img and kernel files to /blissos
sudo cp /mnt/iso/initrd.img /blissos/initrd.img
sudo cp /mnt/iso/kernel /blissos/kernel

# unmount the iso file
sudo umount /mnt/iso

# check to see if /blissos/data.img exists already, if not create it
if [ ! -f "/blissos/data.img" ]; then

# Ask user what size they would like their data.img to be (4G,6G,8G,10G,12G,14G,16G, or other)
echo "What size would you like your data.img to be? (4G, 8G, 12G, 16G, or other)"
read size  # Read the user input

# Create the data.img using the $size specified in GB
sudo dd if=/dev/zero of=/blissos/data.img bs=1M count=0 seek=$size
sudo mkfs.ext4 -F /blissos/data.img
sudo chmod 777 /blissos/data.img
fi

# search /etc/grub.d/40_custom to see if we need to add the custom menu
if [ -f "/etc/grub.d/40_custom" ]; then
# Check for any mention of BlissOS in /etc/grub.d/40_custom
BLISS_MENTION=$(grep "BlissOS" /etc/grub.d/40_custom)

# If no mention of BlissOS in /etc/grub.d/40_custom
if [ -z "$BLISS_MENTION" ]; then

# GRUB_MENUS
# sudo cat >> /etc/grub.d/40_custom<< EOF
sudo tee -a /etc/grub.d/40_custom << EOF

menuentry "BlissOS (Default) w/ FFMPEG" { 
    set SOURCE_NAME="blissos" search --set=root --file /$SOURCE_NAME/kernel 
    linux /$SOURCE_NAME/kernel FFMPEG_CODEC=1 FFMPEG_PREFER_C2=1 quiet root=/dev/ram0 SRC=/$SOURCE_NAME  
    initrd /$SOURCE_NAME/initrd.img
}

menuentry "BlissOS (Intel) w/ FFMPEG" { 
    set SOURCE_NAME="blissos" search --set=root --file /$SOURCE_NAME/kernel 
    linux /$SOURCE_NAME/kernel HWC=drm_minigbm_celadon GRALLOC=minigbm FFMPEG_CODEC=1 FFMPEG_PREFER_C2=1 quiet root=/dev/ram0 SRC=/$SOURCE_NAME  
    initrd /$SOURCE_NAME/initrd.img
}

menuentry "BlissOS PC-Mode (Default) w/ FFMPEG" { 
    set SOURCE_NAME="blissos" search --set=root --file /$SOURCE_NAME/kernel 
    linux /$SOURCE_NAME/kernel  quiet root=/dev/ram0 SRC=/$SOURCE_NAME  
    initrd /$SOURCE_NAME/initrd.img
}

menuentry "BlissOS PC-Mode (Intel) w/ FFMPEG" { 
    set SOURCE_NAME="blissos" search --set=root --file /$SOURCE_NAME/kernel 
    linux /$SOURCE_NAME/kernel PC_MODE=1 HWC=drm_minigbm_celadon GRALLOC=minigbm FFMPEG_CODEC=1 FFMPEG_PREFER_C2=1 quiet root=/dev/ram0 SRC=/$SOURCE_NAME  
    initrd /$SOURCE_NAME/initrd.img
}

EOF
sudo update-grub
fi
fi

# Settup the session option
echo "Setting up session option"
bash $SCRIPT_PATH/install_session.sh
