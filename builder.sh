#!/bin/bash

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
	

COMMAND="$1"
ADDITIONAL="$2"
TOP=${PWD}

#######################################################################################
ANDROID_ROOT=~/android/system
OUT=$ANDROID_ROOT/out/target/product/pascal2
PRODUCT_DIR=$ANDROID_ROOT/out/target/product/pascal2
#######################################################################################

# do not change this var 
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




#######################################################################################
mkimg_boot()
{	
	echo "****************  start make boot.img **************** "
	cd $OUT	
	mkdir images
	rm boot.img
	pushd $OUT/root/
	find . | cpio -o -H newc | gzip -n > ../boot.gz
	popd
	cd $OUT/rktools
        ./rkcrc -k $OUT/boot.gz $OUT/boot.img
	cd ..
	mv $OUT/boot.img $PRODUCT_IMAGES
	cd $ANDROID_ROOT
	echo "make boot.img ok"
}

#######################################################################################
mkimg_system()
{	
	echo "****************  start make system.img ****************"
	
	cd $OUT
	rm system.img
	sudo rm  $OUT/images/system -rf
	cd $PRODUCT_IMAGES
	
	mkdir system

	echo "alloc disk space..."
	dd if=/dev/zero of=$SYSTEMIMG bs=1024 count=${SYSTEMIMG_SIZE}
	#mke2fs -F -m 0 -i 2000 $SYSTEMIMG > /dev/null
	/sbin/mkfs.ext3 -F $SYSTEMIMG > /dev/null
	sudo mount -t ext3 -o loop $SYSTEMIMG $PRODUCT_IMAGES/system/

	cd $OUT
	sudo cp -rv system images

	cd ..
	sudo umount $PRODUCT_IMAGES/system/
	
	cd $ANDROID_ROOT
	echo "make system.img ok"
}
######################################################################################
mkimg_recovery()
{
	echo "****************  start make recovery.img ****************"
	cd $OUT
	rm recovery.img
	pushd $OUT/recovery/root/
	find . | cpio -o -H newc | gzip -n > ../../recovery.gz
	popd
        cd $OUT/rktools
	./rkcrc -k $OUT/recovery.gz $OUT/recovery.img
	cd ..
	mv $OUT/recovery.img $PRODUCT_IMAGES
	
	echo "make recovery.img ok!"
}

######################################################################################
# Starting Timer
START=$(date +%s)

# Device specific settings
case "$COMMAND" in
	clean)
		make clean
		rm -rf ./out/target/product
		exit
		;;
	pascal2)
	   	lunch=cm_pascal2-userdebug
	    	;;
	*)
		echo -e "${txtred}Usage: $0 DEVICE ADDITIONAL"
		echo -e "Example: ./builder.sh pascal2"
		echo -e "Supported Devices: pascal2${txtrst}"
		echo -e "Additional , build images of system,boot,..../builder.sh pascal2 img"
		exit 2
		;;
esac

brunch=${lunch}


# Setting up Build Environment
echo -e "${txtgrn}Setting up Build Environment...${txtrst}"
. build/envsetup.sh
lunch ${lunch}



#######################################################################################
# Start the Build
case "$ADDITIONAL" in
	build)
		echo -e "${txtgrn}Building Android...${txtrst}"
		brunch ${brunch}
		;;
	img)
		echo -e "${txtgrn}Building Android...${txtrst}"
		brunch ${brunch}
		echo -e "${txtgrn}Is building all?[ENTER]${txtrst}"
		read enter
		echo -e "${txtgrn} Create images...${txtrst}"	
       		mkimg_boot
		mkimg_recovery
		mkimg_system
		;;
	img_only)
		echo -e "${txtgrn} Create images...${txtrst}"	
       		mkimg_boot
		mkimg_recovery
		mkimg_system
		;;
	img_sys)
		echo -e "${txtgrn} Create images...${txtrst}"	
       		mkimg_system
		;;
	*)
		echo -e "${txtgrn}Building Android...${txtrst}"
		brunch ${brunch}
		;;
esac

#######################################################################################

END=$(date +%s)
ELAPSED=$((END - START))
E_MIN=$((ELAPSED / 60))
E_SEC=$((ELAPSED - E_MIN * 60))
printf "${txtgrn}Elapsed: "
[ $E_MIN != 0 ] && printf "%d min(s) " $E_MIN
printf "%d sec(s)\n ${txtrst}" $E_SEC