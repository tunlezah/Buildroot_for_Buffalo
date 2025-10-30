

##make sure we're not already nand booted?

##determine which mtd device is the big one for a rootfs
##just checking for the label set by stock fw for now.
rootdev=`cat /proc/mtd | grep '"rootfs"' | cut -d: -f1`
bootdev=`cat /proc/mtd | grep '"boot"' | cut -d: -f1`

if [ -z "$rootdev" ] || [ -z "$rootdev" ]; then
  echo "ubi devices needed for install not found"
fi

##check that both are already UBIFS, format them if not?
##maybe sanity check size, that it's NAND not SPI... not that mislabling is likely
ubichk=1
for x in $rootdev $bootdev
do
  [ `dd if=/dev/$x bs=4 count=1 2>/dev/null` == "UBI#" ] || ubichk=0
  #ubiformat /dev/$x
done

if [ $ubichk -eq 0 ]; then
  echo "UBIFS not detected on root/boot, quitting just to be safe"
  exit 1
fi

##process will replace onboard firmware install capability with a custom firmware, proceed?

##mount the roofs image so we can use it to populate ubifs
mkdir /mnt/install 2>/dev/null
modprobe loop
mount -o loop /boot/rootfs.squashfs /mnt/install/
[ $? -ne 0 ] && echo "failed to mount rootfs image, aborting" && exit

##format the device as UBI if it isn't already.
##this shouldn't really happen.
#[ "$ubichk" = "1" ] || ubiformat /dev/
#[ $? -ne 0 ] && echo "failed to format UBI device , aborting" && exit

ubiattach -p /dev/$bootdev -d 8
[ $? -ne 0 ] && echo "failed to attach UBI device to $bootdev, aborting" && exit

ubiattach -p /dev/$rootdev -d 9
[ $? -ne 0 ] && echo "failed to attach UBI device to $rootdev, aborting" && exit


##likewise, shouldn't be needed.
#[ "$ubichk" = "1" ] || ubimkvol /dev/ubi9 -m -N rootfs
#[ $? -ne 0 ] && echo "failed to create volume on UBI device mtd$devnum, aborting" && exit

##cover either scenario of how volumes created
tmpdev="`ls /dev/ubi9_?`"

mkfs.ubifs -v -d /mnt/install/ -x zlib "$tmpdev"
[ $? -ne 0 ] && echo "failed to create UBIFS filesystem on $rootdev, aborting" && exit

###not sure what this failing would actually look like, nothing good.
umount /mnt/install
[ $? -ne 0 ] && echo "failed to unmount install image, aborting" && exit

tmpdev="`ls /dev/ubi8_?`"

mount "$tmpdev" /mnt/install
[ $? -ne 0 ] && echo "failed to mount bootfs on $bootdev, aborting" && exit

for x in `ls /boot/*.{buffalo,dtb}`
do
  x=`basename "$x"`
  cp -v "/boot/$x" /mnt/install/
  #ln -s "/boot/$x" /mnt/install/
  [ $? -ne 0 ] && echo "failed to copy $x, bootfs likely in unusable state" && exit
done

umount /mnt/install/
ubidetach -d 8
ubidetach -d 9

echo "install of OS to NAND complete"

exit 0
confirm we have nand?
confirm boot order?
is it just mount what's there and copy files in? (for boot)
assume just normalish format of the relavant rootdev
