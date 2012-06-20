#!/bin/sh

#######################################################################################
#
#	Auto image script for rockchip and android 
#
#######################################################################################

		txtrst='\e[0m'  # Color off
		txtred='\e[0;31m' # Red
		txtgrn='\e[0;32m' # Green
		txtylw='\e[0;33m' # Yellow
		txtblu='\e[0;34m' # Blue
		THREADS=`cat /proc/cpuinfo | grep processor | wc -l`

########################################################################################
# we should change this var for different config
ANDROID_ROOT=$ANDROID_BUILD_TOP
PRODUCT_DIR=$OUT

#######################################################################################
ANDROID_BUILD_TOP=~/android/system
OUT=$ANDROID_ROOT/out/target/product/pascal2

#######################################################################################

# donnot change this var 
PRODUCT_IMAGES=$PRODUCT_DIR/images
PRODUCT_ROOT=$PRODUCT_DIR/root
PRODUCT_SYSTEM=$PRODUCT_DIR/system
PRODUCT_DATA=$PRODUCT_DIR/data
PRODUCT_RECOVERY=$PRODUCT_DIR/recovery/root

BOOTIMG=boot.img
SYSTEMIMG=system.img
DATAIMG=data.img
RECOVERYIMG=recovery.img
CACHEIMG=cache.img

BOOTIMG_SIZE=32000
SYSTEMIMG_SIZE=256000
DATAIMG_SIZE=256000
RECOVERYIMG_SIZE=32000
CACHEIMG_SIZE=$SYSTEMIMG_SIZE

#######################################################################################	
	echo "****************  start building android ****************"

# Starting Timer
START=$(date +%s)


 #Setting up Build Environment
echo -e "${txtgrn}Setting up Build Environment...${txtrst}"

. build/envsetup.sh
lunch cm_pascal2-userdebug

END=$(date +%s)
ELAPSED=$((END - START))
E_MIN=$((ELAPSED / 60))
E_SEC=$((ELAPSED - E_MIN * 60))
printf "${txtgrn}Elapsed: "
[ $E_MIN != 0 ] && printf "%d min(s) " $E_MIN
printf "%d sec(s)\n ${txtrst}" $E_SEC


#######################################################################################
echo "de build is completed? (y/n)"
    read -n1 option
    echo -e "\r\n"

case $distribution in
    "y")
        echo "Building"
        mkimg_boot
        mkimg_system
        mkimg_recovery
        ;;
      "n")
      echo -e "${txtred}No complete. Aborting."
        echo -e "\r\n ${txtrst}"
        exit
        ;;
    *)
        echo -e "${txtred}No complete. Aborting."
        echo -e "\r\n ${txtrst}"
        exit
        ;;
    esac

#######################################################################################
mkdir -p $PRODUCT_IMAGES

#######################################################################################
mkimg_boot()
{	
	echo "****************  start make boot.img **************** "	
	
	pushd $OUT/root/
	find . | cpio -o -H newc | gzip -n > ../bootstrap/boot.gz
	popd

        ./$OUT/rktools/rkcrc -k $OUT/boot.gz $OUT/boot.img
	mv $OUT/boot.img $PRODUCT_IMAGES
	cd $ANDROID_ROOT
	echo "make boot.img ok"
}

#######################################################################################
mkimg_system()
{	
	echo "****************  start make system.img ****************"
	

	cd $PRODUCT_IMAGES
	mkdir system

	echo "alloc disk space..."
	dd if=/dev/zero of=$SYSTEMIMG bs=1024 count=${SYSTEMIMG_SIZE}
	#mke2fs -F -m 0 -i 2000 $SYSTEMIMG > /dev/null
	mkfs.ext4 -F $SYSTEMIMG > /dev/null
	sudo mount -o loop $SYSTEMIMG $PRODUCT_IMAGES/system/

	cd system

	echo "copy from systemfs..."

	cd ${PRODUCT_SYSTEM}
	sudo mv -r .* $PRODUCT_IMAGES/system

	cd ..
	sudo umount $PRODUCT_IMAGES/system/
	
	cd $ANDROID_ROOT
	echo "make system.img ok"
}
######################################################################################
mkimg_recovery()
{
	echo "****************  start make recovery.img ****************"

	
	
	pushd $OUT/recovery/root/
	find . | cpio -o -H newc | gzip -n > ../bootstrap/recovery.gz
	popd

        ./$OUT/rktools/rkcrc -k $OUT/recovery.gz $OUT/recovery.img
	mv $OUT/recovery.img $PRODUCT_IMAGES
	
	echo "make recovery.img ok!"
}

######################################################################################
        
