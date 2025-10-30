#!/bin/bash

bootfs_type="ext3"
rootfs_type="ext4"

. ../scripts/functions.sh

gen_appended_uImage

generate_initrd_uboot

bootfs_dtb_copy

bootfs_copy "../scripts/armada370_nand_install.sh"

create_image

exit 0
