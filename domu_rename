#!/bin/bash

# define var for newname and oldname

DATE=$(date +%Y-%m-%d-%H:%M)
VGNAME=rootvg
MAIN_VM_FOLDER=/usr/local/xenvm/
LINK_VM_FILE=/etc/xen/
AUTO_VM_FILE=/etc/xen/auto/
OLDNAME=$1
NEWNAME=$2

# check the usage vars and print help

if [ -z $OLDNAME ] || [ -z $NEWNAME ]
then echo "  domu_rename: Rename a VM

domu_rename
        { Oldname Newname }"
exit 1
fi

# set up check function

check_folder(){
        if [[ ( -f $LINK_VM_FILE/$OLDNAME ) && ( -d $MAIN_VM_FOLDER/$OLDNAME ) && ( -f $AUTO_VM_FILE/99-$OLDNAME ) ]]
        then echo "$DATE:: folder exist" >> /tmp/check.log
        else echo "VM does't exist. Abort!";echo "$DATE:: ERROR: vm folder doesn't exist" >> /tmp/check_error.log;exit 1
        fi
}

check_lvm(){
        lvs | grep $OLDNAME >> /tmp/check.log
        if [ $? = 0 ]
        then echo "$DATE:: lvm exist" >> /tmp/check.log
        else echo "ERROR: lvm doesn't exist. Abort!";echo "$DATE:: ERROR: lvm doesn't exist" >> /tmp/check_error.log;exit 1
        fi
}

# rename the lvm

rename_lvm(){
        for oldlvm in $(lvs | grep $OLDNAME | awk '{print $1}')
        do
        echo "changing lvm..."
        lvrename $VGNAME $oldlvm $(echo $oldlvm | sed 's/'"$OLDNAME"'/'"$NEWNAME"'/g') >> /tmp/check.log 2>> /tmp/check_error.log
        if [ $? != 0 ]
        then echo "ERROR: changing faild. Abort!";echo "$DATE:: ERROR: changing faild" >> /tmp/check_error.log;exit 1
        else echo "changing lvm complate"
        fi
        done
}

# change vm configuration

change_conf(){
        echo "changing config..."
        sed -i 's/'"$OLDNAME"'/'"$NEWNAME"'/g' $MAIN_VM_FOLDER/$OLDNAME/$OLDNAME.cfg >> /tmp/check.log 2>> /tmp/check_error.log
        if [ $? != 0 ]
        then echo "ERROR: changing faild. Abort!";echo "$DATE:: ERROR: changing faild" >> /tmp/check_error.log;exit 1
        fi
        echo "moving config..."
        mv $MAIN_VM_FOLDER/$OLDNAME/$OLDNAME.cfg $MAIN_VM_FOLDER/$OLDNAME/$NEWNAME.cfg
        if [ $? != 0 ]
        then echo "ERROR: moving faild. Abort!";echo "$DATE:: ERROR: moving faild" >> /tmp/check_error.log;exit 1
        fi
}

# renmae folder and link

change_link(){
        echo "cleanning link files..."
        rm -f $MAIN_VM_FOLDER/$OLDNAME/*_*
        rm -f $LINK_VM_FILE/$OLDNAME
        rm -f $AUTO_VM_FILE/99-$OLDNAME
        echo "moving folder..."
        mv $MAIN_VM_FOLDER/$OLDNAME $MAIN_VM_FOLDER/$NEWNAME
        if [ $? != 0 ]
        then echo "ERROR: moving faild" ; echo "$DATE:: ERROR: moving faild" >> /tmp/check_error.log;exit 1
        else echo "moving complate"
        fi
        echo "creating link files..."
        ln -s /dev/rootvg/$NEWNAME* $MAIN_VM_FOLDER/$NEWNAME/ >> /tmp/check.log 2>> /tmp/check_error.log
        if [ $? != 0 ]
        then echo "ERROR: create lvm link faild" ; echo "$DATE:: ERROR: create lvm link faild" >> /tmp/check_error.log;exit 1
        else echo "creating lvm link complate"
        fi
        echo "creating conf link files..."
        ln -s $MAIN_VM_FOLDER/$NEWNAME/$NEWNAME.cfg $LINK_VM_FILE/$NEWNAME >> /tmp/check.log 2>> /tmp/check_error.log
        if [ $? != 0 ]
        then echo "create conf link faild";echo "$DATE:: ERROR: create conf link faild" >> /tmp/check_error.log;exit 1
        else echo "creating conf link complate"
        fi
        echo "create auto start link"
        ln -s $LINK_VM_FILE/$NEWNAME $AUTO_VM_FILE/99-$NEWNAME >> /tmp/check.log 2>> /tmp/check_error.log
        if [ $? != 0 ]
        then echo "create auto link faild";echo "$DATE:: ERROR: create auto link faild" >> /tmp/check_error.log;exit 1
        else echo "create auto link complate"
        fi
        echo "rename successful"
}

check_folder
check_lvm
rename_lvm
change_conf
change_link
 
