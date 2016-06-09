#!/bin/bash

# You should change this:
SRCDS_PATH="SET_THIS_FIRST"

# Don't change these, unless you know what you're doing
WORKSHOP="$SRCDS_PATH/steamapps/workshop/content/222880"
COOPMODES="Conquer Checkpoint Hunt Outpost Survival"
PVPMODES="Ambush Battle Elimination Firefight Flashpoint Infiltrate Invasion Occupy Push Skirmish Strike"

## Options
# --coop
# --pvp
# --all
# --modes=

usage() {
        printf "[USAGE] ./generate_mapcycle.sh [opts]\n"
        printf "Opts:\n"
        printf " coop\t\tReturn only Co-op game modes\n"
        printf " pvp\t\tReturn only PVP game modes\n"
        printf " all\t\tReturn all game modes\n"
        printf " modes=\tReturn only specified modes\n\n"

        printf "Examples:\n"
        printf "All Co-op maps: ./generate_mapcycle.sh coop\n"
        printf "Only Hunt maps: ./generate_mapcycle.sh modes=hunt\n"
        printf "Mixed modes: ./generate_mapcycle.sh modes=hunt,checkpoint,conquer\n"
        exit 1
}

if [[ "$SRCDS_PATH" == "SET_THIS_FIRST" ]]; then
        printf "[ERROR] Please set SRCDS_PATH [4]"
        exit 1
fi

if [[ $# == 0 || $# > 1 ]]; then
        usage
fi

VALIDMODES=""
if [[ "$1" == "coop" ]]; then VALIDMODES=$COOPMODES; fi
if [[ "$1" == "pvp" ]]; then VALIDMODES=$PVPMODES; fi
if [[ "$1" == "all" ]]; then VALIDMODES="$COOPMODES $PVPMODES"; fi
CUSTOM=$(echo "$1" | grep -i "modes" | sed 's#modes=##i')
if [[ "$VALIDMODES" == "" ]]; then
        if [[ "$CUSTOM" != "" ]]; then
                VALIDMODES=$(echo "$1")
        else
                printf "[ERROR] No modes supplied\n\n"
                usage
        fi
fi

OLDPWD=$(pwd);

get_ids() {
        cd $1
        IDS=$(find . -maxdepth 1 -type d | sed 's#./##' | sort | grep -v "^\.$")
        echo $IDS
}

get_bsp_name() {
        cd $SRCDS_PATH
        BSPNAME=$(find . -name *.bsp | grep $1 | awk -F / '{print $NF}' | sed 's#\.bsp##')
        echo $BSPNAME
}

get_map_modes() {
        if [ "$1" != "" ]; then
                wget -q "http://steamcommunity.com/sharedfiles/filedetails/?id=$1" -O /tmp/$1.html
                MODES=$(grep workshopTagsTitle /tmp/$1.html | sed -e "s#>#\n#g" -e "s#<#\n#g" | egrep "^[A-Z]" | grep -v "Maps")
                MAPNAME=$(get_bsp_name $1)
                for MODE in $MODES; do
                        COMBINED=$(echo $MAPNAME $MODE | awk '{print tolower($0)}')
                        if [[ $(echo "$VALIDMODES" | grep -i $MODE) != "" ]]; then
                                echo "$COMBINED"
                        fi
                done
                rm /tmp/$1.html
        fi
}

MAPIDS=$(get_ids $WORKSHOP)
for ID in $MAPIDS; do
        get_map_modes $ID
done

cd $OLDPWD
