# FROM https://github.com/multirom-htc/android_device_common_version-info/blob/master/MR_REC_VERSION.mk

#include this into the main BoardConfig for autogenerated MR_REC_VERSION
#do not echo anything back to stdout, seems to bork stuff -_-

#if MR_REC_BUILD_NUMBER_FILE is not already defined, use the current path
ifeq ($(MR_REC_BUILD_NUMBER_FILE),)
# ${CURDIR}									full path to TOP
# $(dir $(lastword $(MAKEFILE_LIST)))		relative path to this file
MR_REC_BUILD_NUMBER_FILE := "$(dir $(lastword $(MAKEFILE_LIST)))MR_REC_BUILD_NUMBER-$(TARGET_DEVICE).TXT"
endif

MR_STABLE_VERSION := STABLE7

#MR_REC_BUILD_NUMBER (later)
#line 0: TWRP version
#line 1: mrom date
#line 2: mrom build

#sub commands
cmd_put_out      := printf "%s-%02d" $$build_date $$build_num >$(MR_REC_BUILD_NUMBER_FILE);
cmd_get_out      := build_str=`cat $(MR_REC_BUILD_NUMBER_FILE)`; build_date=$${build_str:0:8}; build_num=$${build_str:9:2};
cmd_reset_ver    := echo -ne "\nMR_REC_VERSION.mk: New date, reset build number to 01\n\n" 1>&2; build_date=`date -u +%Y%m%d`; build_num=1;
cmd_incr_num     := build_num=$$(( 10\#$$build_num + 1 )); if [ $$build_num -gt 99 ]; then echo -ne "\nMR_REC_VERSION.mk: ERROR: Build number will exceed 99 resetting to 01\n\n" 1>&2; build_num=1; fi;
cmd_is_new_date  := `date -u +%Y%m%d` -gt $$build_date
cmd_get_TWRP_ver := `grep -azA1 ro.twrp.version $(ANDROID_PRODUCT_OUT)/recovery/root/sbin/recovery | grep -avz ro.twrp.version | head -c -1`


#run on envsetup and/or any make
cmd_pre_run  := if [ ! -f $(MR_REC_BUILD_NUMBER_FILE) ]; then
cmd_pre_run  += 	echo "MR_REC_VERSION.mk: Create MultiROM Recovery build number file" 1>&2;
cmd_pre_run  += 	$(cmd_reset_ver)
cmd_pre_run  += 	$(cmd_put_out)
cmd_pre_run  += else
cmd_pre_run  += 	$(cmd_get_out)
cmd_pre_run  += 	if [ $(cmd_is_new_date) ]; then
cmd_pre_run  += 		$(cmd_reset_ver)
cmd_pre_run  += 		$(cmd_put_out)
cmd_pre_run  += 	fi;
cmd_pre_run  += fi;


#run after: make recoveryimage
cmd_post_run := $(cmd_get_out)
cmd_post_run += if [ $(cmd_is_new_date) ]; then
cmd_post_run += 	$(cmd_reset_ver)
cmd_post_run += else
cmd_post_run += 	$(cmd_incr_num)
cmd_post_run += fi;
cmd_post_run += $(cmd_put_out)

#rename command
cmd_ren_rec_img := echo -ne "\n\nMR_REC_VERSION.mk: Rename output file " 1>&2;
cmd_ren_rec_img += mv -v
cmd_ren_rec_img +=  "$(ANDROID_PRODUCT_OUT)/recovery.img"
cmd_ren_rec_img +=  "$(ANDROID_PRODUCT_OUT)/mr-twrp-recovery-`cat $(MR_REC_BUILD_NUMBER_FILE)`-`cat $(MR_STABLE_VERSION)`.img"
cmd_ren_rec_img +=  1>&2;



#if the build number file doesnt exist create it as 01, if it does then check date
$(shell $(cmd_pre_run))

$(shell echo "MR_REC_VERSION.mk: MultiROM Recovery build number=`cat $(MR_REC_BUILD_NUMBER_FILE)`" 1>&2)


#once the recoveryimage is built, rename the output file, and increase the build number for the next run
recoveryimage:
	$(shell $(cmd_ren_rec_img))
	$(shell $(cmd_post_run))
	$(shell echo "MR_REC_VERSION.mk: Increase MultiROM Recovery build number to `cat $(MR_REC_BUILD_NUMBER_FILE)` for next build" 1>&2)

MR_REC_VERSION := $(shell cat $(MR_REC_BUILD_NUMBER_FILE))
