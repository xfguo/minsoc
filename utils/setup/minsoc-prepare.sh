#!/bin/bash

# This script sets-up an initial environment for minsoc development
# Written by Javier Almansa Sobrino <javier.almansa@efsystems.net>

SYN_DIR=$MINSOC_DIR/syn
SYNSUPPORT_DIR=$SYN_DIR/buildSupport
FIND_PART='DEVICE_PART'
FIND_FAMILY='FAMILY_PART'
FIND_VERSION='SW_VERSION'
FIND_CONSTRAINT='CONSTRAINT_FILE'
HOME_DIR=`pwd`
MAKE_PATTERN=make.generic

dialog --no-cancel --title "Select device part" \
       --inputbox "Select device" 7 50 "EP3C25Q240C8" 2> /tmp/device.$$

case $? in
    255) echo "Device not selected. Aborting...\n"; exit 1 ;;
    0) DEVICE_PART=`cat /tmp/device.$$`;;
esac

dialog --no-cancel --title "Select device vendor" \
       --radiolist "Select FPGA vendor" 10 50 5 1 "Altera" on 2 "Xilinx" off 2> /tmp/vendor.$$

if [ $? -eq 255 ]; then
    echo "Device vendor not selected. Aborting...\n"
    exit 1
fi

case `cat /tmp/vendor.$$` in
    1) SYNSRC_DIR=$MINSOC_DIR/prj/altera; \
	MAKEFILE_DIR=$SYN_DIR/altera; \
	PROJECT_FILE=minsoc_top.qsf; \
	VENDOR="Altera" \
	SYN_FILES=(adbg_top.vprj jtag_top.vprj or1200_top.vprj uart_top.vprj \
	minsoc_top.vprj altera_virtual_jtag.vhdprj) ;;
    2) SYNSRC_DIR=$MINSOC_DIR/prj/xilinx; \
	MAKEFILE_DIR=$SYN_DIR/xilinx; \
	VENDOR="Xilinx" \
	SYN_FILES= ;;
esac

case `cat /tmp/vendor.$$` in
    1) dialog --no-cancel --title "Select Altera device family" \
	--radiolist "Select Altera device family" 15 50 10 \
	1 "Arria II GX" off \
	2 "Cyclone II" off \
	3 "Cyclone III" on \
	4 "Cyclone III LS" off \
	5 "Cyclone IV E" off \
	6 "Cyclone IV GX" off \
	7 "Cyclone V (E/GX/GT/SX/SE/ST)" off \
	2> /tmp/family.$$ ;;
    2) echo "Families for Xilinx devices not configured. Aborting..."; exit 1 ;;
esac

FAMILY=`cat /tmp/family.$$`
case `cat /tmp/family.$$` in
    1) FAMILY_PART="Arria II GX" ;;
    2) FAMILY_PART="Cyclone II" ;;
    3) FAMILY_PART="Cyclone III" ;;
    4) FAMILY_PART="Cyclone III LS" ;;
    5) FAMILY_PART="Cyclone IV E" ;;
    6) FAMILY_PART="Cyclone IV GX" ;;
    7) FAMILY_PART="Cyclone V (E/GX/GT/SX/SE/ST)" ;;
esac

dialog --no-cancel --title "Select user Verilog path list" \
       --inputbox "Select user Verilog path list" 7 50 "verilog.path" 2> /tmp/vpath.$$

case $? in
    0) if [ `cat /tmp/vpath.$$ | wc -c` = "0" ]; then 
	VERILOG_PATH=" " 
       else
        VERILOG_PATH=`cat /tmp/vpath.$$`
       fi ;;
    255) VERILOG_PATH=" " ;;
esac

dialog --no-cancel --title "Select user VHDL path list" \
       --inputbox "Select user VHDL path list" 7 50 "vhdl.path" 2> /tmp/vhdpath.$$

case $? in
    0) if [ `cat /tmp/vhdpath.$$ | wc -c` = "0" ]; then
	VHDL_PATH=" " 
       else
	VHDL_PATH=`cat /tmp/vhdpath.$$`
       fi ;;
    255) VHDL_PATH=" " ;;
esac

if [ $VENDOR = "Altera" ]; then

    dialog --no-cancel --title "Select user UCF File" \
	--inputbox "Select user UCF File" 7 50 "user.ucf" 2> /tmp/ucf.$$

    case $? in
	0) if [ `cat /tmp/ucf.$$ | wc -c` = "0" ]; then
             echo "Error: You must privide an UCF file"; exit 1;
           else
             UCF_FILE=`cat /tmp/ucf.$$`
           fi ;;
	255) echo "Error: You must privide an UCF file"; exit 1;;
    esac

    DEFINES_FILE=minsoc_defines.v
    MINSOC_TOP_FILE=minsoc_top.v
    VERILOG_USER_FILES=$HOME_DIR/verilog
    VHDL_USER_FILES=$HOME_DIR/vhdl
    VERILOG_PRJ_FILE=user.vprj
    VHDL_PRJ_FILE=user.vhdprj

    command -v quartus >/dev/null 2>&1 || { echo >&2 "Altera synthesis requires Quartus software but it's not installed. Aborting..."; exit 1; }

    reset

    echo "Minsoc configuration report:"
    echo -n "Device Vendor:     "
    echo $VENDOR
    echo -n "Device Family:     "
    echo $FAMILY_PART
    echo -n "Device Part:       "
    echo $DEVICE_PART
    echo -n "Minsoc Home:       "
    echo $MINSOC_DIR
    echo -n "Minsoc output dir: "
    echo $HOME_DIR
    echo -n "UCF File:          "
    echo $UCF_FILE

    if [ ! $VERILOG_PATH == " " ]
    then
    	for filedir in `cat $VERILOG_PATH`
    	do
	    echo -n "User Verilog path: "
	    echo $filedir
    	done
    fi

    if [ ! $VHDL_PATH ==  " " ]
    then
    	for filedir in `cat $VHDL_PATH`
    	do
	    echo -n "User VHDL path:    "
	    echo $filedir
    	done
    fi
    echo
    echo "Press [ENTER] to start Minsoc base deploying"
    read
    echo "Starting..."
    echo "Generating project files for simulation and synthesis..."
    echo "__________________________________________________________________________"
    echo ""
    make -C $MINSOC_DIR/prj
    echo "Generation complete."
    echo ""
    echo "__________________________________________________________________________"
    echo
    echo "Device part and family for files under $SYNSRC_DIR will patched and stored "
    echo "temporarily." 
    echo "Afterwards, they are copied to $HOME_DIR."
    echo "__________________________________________________________________________"
    echo ""
    sed "s/$FIND_PART/$DEVICE_PART/g" $MAKEFILE_DIR/$PROJECT_FILE > /tmp/TMPFILE.$$
    sed "s/$FIND_FAMILY/$FAMILY_PART/g" /tmp/TMPFILE.$$ > $HOME_DIR/$PROJECT_FILE

    echo "Generating quartus settings from prj files in $SYNSRC_DIR"
    for file in "${SYN_FILES[@]}"
    do
	echo "Adding settings from file $file..."
	cat $SYNSRC_DIR/$file | grep -v "minsoc_defines" | grep -v minsoc_top >> $HOME_DIR/$PROJECT_FILE
    done

    echo "set_global_assignment -name SEARCH_PATH" $HOME_DIR >> $HOME_DIR/$PROJECT_FILE
    echo "set_global_assignment -name VERILOG_FILE" $HOME_DIR/$DEFINES_FILE >> $HOME_DIR/$PROJECT_FILE
    echo "set_global_assignment -name VERILOG_FILE" $HOME_DIR/$MINSOC_TOP_FILE >> $HOME_DIR/$PROJECT_FILE

    if [ ! $VERILOG_PATH == " " ]
    then
	echo "Adding user Verilog files to project"
    	for filedir in `cat $VERILOG_PATH`
    	do
    	    echo "set_global_assignment -name SEARCH_PATH" $filedir >> $HOME_DIR/$PROJECT_FILE
    	    for file in `ls -C $filedir/*.v`
    	    do
    		echo "set_global_assignment -name VERILOG_FILE" $file >> $HOME_DIR/$PROJECT_FILE
    		echo "Adding" $file "to project"
    	    done
    	done
    fi

    if [ ! $VHDL_PATH == " " ]
    then
	echo "Adding user Verilog files to project"
	for filedir in `cat $VHDL_PATH`
	do
	    echo "set_global_assignment -name SEARCH_PATH" $filedir >> $HOME_DIR/$PROJECT_FILE
	    for file in `ls -C $filedir/*.vhdl`
	    do
		echo "set_global_assignment -name VHDL_FILE" $file >> $HOME_DIR/$PROJECT_FILE
		echo "Adding" $file "to project"
	    done
        done
    fi
    echo "Adding user constraints from" $UCF_FILE
    cat $UCF_FILE >> $HOME_DIR/$PROJECT_FILE

    ls $HOME_DIR/$DEFINES_FILE 2> /dev/null > /dev/null
    if [ $? -eq 0 ]
    then
	echo "$HOME_DIR/$DEFINES_FILE exists. Skipping ..."
    else
	cp $MINSOC_DIR/backend/altera_3c25_board/$DEFINES_FILE $HOME_DIR
	echo "Created" $DEFINES_FILE "file in" $HOME_DIR
    fi;

    ls $HOME_DIR/$MINSOC_TOP_FILE 2> /dev/null > /dev/null
    if [ $? -eq 0 ]
    then
	echo "$HOME_DIR/$MINSOC_TOP_FILE exists. Skipping ..."
    else
	cp $MINSOC_DIR/rtl/verilog/minsoc_top.v $HOME_DIR
	echo "Created" $MINSOC_TOP_FILE "file in" $HOME_DIR
    fi;

    ls $HOME_DIR/Makefile 2> /dev/null > /dev/null
    if [ $? -eq 0 ]
    then
	echo "$HOME_DIR/Makefile exists. Skipping ..."
    else
	cp $MAKEFILE_DIR/$MAKE_PATTERN $HOME_DIR/Makefile
	echo "Created Makefile in" $HOME_DIR
    fi;

    echo ""
    echo ""
    echo "MinSoC is ready to be synthetized. If you need, you can tune-up"
    echo "your project before by editing" $HOME_DIR/$PROJECT_FILE "for add or delete"
    echo "your own VHDL or Verilog modules."
    echo "If you have added your own Whisbone compatible modules to your project, you"
    echo "will need to tune-up" $HOME_DIR/$MINSOC_TOP_FILE "to connecto your modules"
    echo "to the rest of the system."
    echo $HOME_DIR/$DEFINES_FILE "contains definitions for configuring default components".
    echo ""
    echo "For synthetize help, type 'make'"

fi # IF ALTERA


