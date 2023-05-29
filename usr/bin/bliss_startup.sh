#!/bin/bash

# Session Type
#SESSION_TYPE=$(echo $XDG_SESSION_TYPE)
SESSION_TYPE=$(loginctl --value show-session "$XDG_SESSION_ID" -p Type)
if [[ "${SESSION_TYPE}" == "x11" ]]; then
	DISPLAY_TYPE="sdl"
#elif [ "$SESSION_TYPE" == "wayland" ]; then
else
	DISPLAY_TYPE="gtk"
fi

#location=/nvme/PS/android-2021-04-04
LOCATION=/blissos
DIMENSIONS=$(xdpyinfo | grep dimensions | sed -r 's/^[^0-9]*([0-9]+x[0-9]+).*$/\1/')
WIDTH=$(echo $DIMENSIONS | sed -r 's/x.*//')
HEIGHT=$(echo $DIMENSIONS | sed -r 's/.*x//')
if [ "$HEIGHT" == "" ]; then
DIMENSIONS=$(cat /sys/class/graphics/*/virtual_size)
WIDTH=$(echo $DIMENSIONS | sed -r 's/,.*//')
HEIGHT=$(echo $DIMENSIONS | sed -r 's/.*,//')
fi

#kernargs=(root=/dev/ram0 RAMDISK=vdb console=ttyS0 HWC=drm_minigbm GRALLOC=minigbm_arcvm video=800x480 DATA=/dev/vdb)

args=(
      #CPU
      '-smp 4' #threads
      '-M q35' #platform, this should be left alone
      '-m 4096' #memory
      '-cpu host' #reported cpu
      '-accel kvm' #acceleration, should be left alone
      # '-bios /usr/share/OVMF/x64/OVMF.fd' #UEFI BIOS, only needed for qcow2
      #GPU
      '-device virtio-vga-gl,xres='${WIDTH}',yres='${HEIGHT}
      '-display '${DISPLAY_TYPE}',gl=on'
      #'-display egl-headless' #needed for remote connections via spice or vnc
      
      ##devices
      '-device qemu-xhci' #USB 3.0
      '-device usb-hub'
      ##This is for USB host passthrough,
      #'-device usb-host,hostbus=003,hostport=1'
      ##this is for evdev touch passthrough, this NEEDS a hotkey currently lctrl + rctrl
      #'-device virtio-input-host,id=touch0,evdev=/dev/input/event7'

      ##Audio setup, for better audio use jack/pipewire as shown in docs
      '-audiodev pa,id=snd0'
      '-device AC97,audiodev=snd0'

      ##Input Setup
      '-device virtio-tablet'
      '-device virtio-keyboard'

      ##spice USB redirection, needs GTK or SPICE
      #'-device virtio-serial -chardev spicevmc,id=vdagent,debug=0,name=vdagent'
      #'-device virtserialport,chardev=vdagent,name=com.redhat.spice.0'
      #'-chardev spicevmc,name=usbredir,id=usbredirchardev1'
      #'-device usb-redir,chardev=usbredirchardev1,id=usbredirdev1'
      #'-chardev spicevmc,name=usbredir,id=usbredirchardev2'
      #'-device usb-redir,chardev=usbredirchardev2,id=usbredirdev2'
      #'-chardev spicevmc,name=usbredir,id=usbredirchardev3'
      #'-device usb-redir,chardev=usbredirchardev3,id=usbredirdev3'

      ##net
      ### forward port 4444 to port 5555 in vm, allows `adb connect 4444`
      '-net nic,model=virtio-net-pci -net user,hostfwd=tcp::4444-:5555'

      #drives
      '-drive index=0,if=virtio,id=system,file='${LOCATION}'/system.img,format=raw,readonly=on'
      '-drive index=3,if=virtio,file='${LOCATION}'/data.img,format=raw,readonly=off'
      #'-virtfs local,id=data,path='${LOCATION}'/data,security_model=passthrough,mount_tag=data' ##NEEDS ROOT
      '-initrd '${LOCATION}'/initrd.img'

      #misc
      #'-monitor stdio'
      #'-serial mon:stdio'
      '-serial stdio'
      '-full-screen'
      #'-no-quit'
)

##EVDEV passthrough
pass=(
      '-device virtio-mouse,id=mouse1'
      '-device virtio-keyboard,id=kbd1'
      '-object input-linux,id=mouse1,evdev=/dev/input/by-id/MOUSE-NAME'
      '-object input-linux,id=kbd1,evdev=/dev/input/by-id/KEYBOARD-NAME,grab_all=on,repeat=on'
)

##VFIO passthrough, used for pci devices such as GPUS
vfio=(
      '-vga none'
      '-display none'
      '-device vfio-pci,host=0d:00.0,multifunction=on,x-vga=on' #Change host= to pcie device see advanced qemu docs
)

##SETUP SCRIPT FOR VFIO
#su -c 'echo 0000:0d:00.0 > /sys/bus/pci/drivers/i915/unbind'

#sudo modprobe vfio ##needs vid:pid for some reason
#su -c 'echo 8086 56a5 > /sys/bus/pci/drivers/vfio-pci/new_id"'

qemu-system-x86_64 ${args[@]} \
      -append "root=/dev/ram0 console=ttyS0 DATA=/dev/vdb PC_MODE=1 SETUPWIZARD=0" -kernel ${LOCATION}/kernel

pkill qemu
