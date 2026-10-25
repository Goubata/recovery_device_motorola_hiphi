#
#	This file is part of the OrangeFox Recovery Project
# 	Copyright (C) 2021-2022 The OrangeFox Recovery Project
#
#	OrangeFox is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	any later version.
#
#	OrangeFox is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
# 	This software is released under GPL version 3 or any later version.
#	See <http://www.gnu.org/licenses/>.
#
# 	Please maintain this if you use this script or any part of it
#

# Adapted from upstream fox_13 (9453279); sourced only by the OrangeFox build.
export OF_MAINTAINER="Goubata"
export FOX_BUILD_DEVICE=hiphi
export FOX_VARIANT=AOSP
export TARGET_DEVICE_ALT="hiphi,hiphic,hiphid,XT2201-1,XT2201-2,XT2201-3,XT2201-4,XT2201-6"
export FOX_TARGET_DEVICES="$TARGET_DEVICE_ALT"
export OF_AB_DEVICE_WITH_RECOVERY_PARTITION=1
export FOX_VANILLA_BUILD=1
export OF_DISABLE_OTA_MENU=1
export OF_USE_LZ4_COMPRESSION=1
export OF_USE_GREEN_LED=0
export OF_QUICK_BACKUP_LIST="/boot;/data;"
export OF_NO_TREBLE_COMPATIBILITY_CHECK=1
export FOX_ENABLE_APP_MANAGER=1
export FOX_USE_TAR_BINARY=1
export FOX_USE_SED_BINARY=1
export FOX_USE_XZ_UTILS=1
export OF_ENABLE_LPTOOLS=1
export OF_SCREEN_H=2400
export OF_STATUS_H=100
export OF_STATUS_INDENT_LEFT=48
export OF_STATUS_INDENT_RIGHT=48
export OF_CLOCK_POS=1
export OF_HIDE_NOTCH=1
