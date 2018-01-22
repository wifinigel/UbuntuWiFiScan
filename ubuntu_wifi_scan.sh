#!/bin/sh
#
# ubuntu_wifi_scan.sh - script to list wifi networks
#
# Author: Nigel Bowden
# Version: v0.1 - 7th Jan 2018
#
# This script parses the output of the cli command "iw dev <adapter> scan"
# to determine all wi-fi networks that can be heard by an Ubuntu client. It 
# uses grep to parse/scrape the command output. It will run in a loop
# giving output until you hit Ctrl-C to stop it.
#
# You will also need root (or equivalent) access to run the script, as a 
# number of embedded commands in this script run using 'sudo'
#
# (Note: this script is liable to break if command output changes over time)
#
#
#  grep output:
#
#  BSS 5a:83:bf:34:67:e5
#  freq: 2412
#  signal: -83.00
#  SSID: BTWifi-X
#
#
#  Standard output from running script on cli: 
#
#  . ./ubuntu_wifi_scan.sh
#
#  Output:
#
#  BSSID              RSSI     CH    Freq    SSID
#                     (dBm)          (Mhz)
#  ===============================================================
#  ac:86:74:64:a1:91  -45.00    1    2412    
#  ac:86:74:64:a1:82  -45.00    1    2412    VM202651-2G
#  ae:86:74:64:a1:95  -57.00   44    5220    VM202651-5G
#  28:76:10:01:ac:00  -59.00   44    5220    
#  e8:fc:af:2e:1e:88  -75.00    6    2437    VM202651-2G
#  c0:05:c2:5f:1c:61  -79.00    6    2437    HomeWifi2G
#  28:76:10:01:ac:08  -83.00   44    5220    VM202651-5G
#  80:2a:a8:d2:20:69  -89.00   36    5180    HomeWifi5G
#  f6:6b:ef:28:ee:8d  -91.00   11    2462    Virgin Media
#  d2:05:c2:5f:1c:61  -91.00   11    2462    VM3668793
#  e8:fc:af:14:5a:38  -93.00   11    2462    BTWifi-with-FON
#  ===============================================================
#
#
#  With "-csv" command line option, output as follows (all networks detected
#  will be listed in this format):
#
#  . ./ubuntu_wifi_scan.sh  -csv
#
#  "ssid_name", "bssid_mac", "sig_level", "channel_num", "hh:mm:ss"
#
#  Example: "Virgin Media", "D2:08:C2:5F:74:23", -57", "36", "19:47:05"
#
#  This can be imported in to the MAC application:  Wifi Explorer
#  for further analysis
#
########################################################################


# Initialize vars
field_count=1
csv="false"

# set the name of our wireless adapter (run the 'iwconfig' command yourself and get the adapter name, which will be something like 'wlan0' or 'wlx687f74807e6f')
WLAN_NIC="wlx687f74807e6f"

# set our path to 'iw' - enter "which iw" on the CLI if not sure usually "/sbin/iw" or "/usr/sbin/iw"
IW=`which iw`

# The script runs in a continuous loop - set the pause time between each run (in secs) here (added 
# to try to mitigate "device not ready" errors, but not sure if it improves anything to be honest)
LOOP_PAUSE=2

# List all of our Wi-Fi channels to lookup from the frequency we gather in the output of the "iw" scan command
declare -A CHANNELS=(
['2412']='1'
['2417']='2'
['2422']='3'
['2427']='4'
['2432']='5'
['2437']='6'
['2442']='7'
['2447']='8'
['2452']='9'
['2457']='10'
['2462']='11'
['2467']='12'
['2472']='13'
['5180']='36'
['5200']='40'
['5220']='44'
['5240']='48'
['5260']='52'
['5280']='56'
['5300']='60'
['5320']='64'
['5500']='100'
['5520']='104'
['5540']='108'
['5560']='112'
['5580']='116'
['5600']='120'
['5620']='124'
['5640']='128'
['5660']='132'
['5680']='136'
['5700']='140'
['5720']='144'
['5745']='149'
['5765']='153'
['5785']='157'
['5805']='161'
['5825']='165'
)

# Check if this should be csv ouput
if [[ "$1" == "-csv" ]] 
then 
  csv="true"
fi

# start of main while loop
while [ 1 ]
do

  # Set IFS to ensure grep output split only at line end on for statement
  IFS='
'
  # capture grep output in "iw" scan command in to array
  grep_output=( `sudo $IW dev $WLAN_NIC scan | grep -o 'BSS ..\:..\:..:..\:..\:..\|SSID: .*\|signal\: .* \|freq\: .*'` )

  # print headers (unless csv output required)
  if [[ "$csv" == "false" ]]
  then
    echo "BSSID              RSSI     CH    Freq    SSID"
    echo "                   (dBm)          (Mhz)"
    echo "==============================================================="
  fi


  # Read through grep output from "iw" scan command
  for line in "${grep_output[@]}"
  do
    # set IFS to space & tab
    IFS=" 	"

    # first field should be BSS
    if [[ $line =~ BSS ]]
    then
      bss_array=( $line )
      bssid=${bss_array[1]}
    fi

    # second field should be freq:
    if [[ $line =~ "freq:" ]]
    then
      freq_array=( $line )
      freq=${freq_array[1]}
    fi

    # third field should be signal:
    if [[ $line =~ "signal:" ]]
    then
      signal_array=( $line )
      rssi=${signal_array[1]}
    fi

    # fourth field should be SSID 
    if [[ $line =~ "SSID" ]]
    then
      ssid_array=( $line )
      # get rid of first array element so that we can print whole array, leaving just SSID name which may have spaces
      unset ssid_array[0]
      ssid=${ssid_array[@]}
    fi

    # Every 4th line we have all the input we need to write out the data
    if [ $field_count -eq 4 ]
    then
      
      
      
      if [[ "$csv" == "false" ]]
      then
	     #format channel number to fit display nicely
		 channel=$(printf '%3s' "${CHANNELS[$freq]}")
		 
         echo "$bssid  $rssi  $channel    $freq    $ssid"
      else
	    # Derive current time in correct format for csv file output
        CURRENT_TIME=`date +%H:%M:%S`
		
		# lookup channel from channel array using freq (no formatting applied)
		channel=${CHANNELS[$freq]}
		
		# output the required csv data fo this BSSID
        echo "\"${ssid}\", \"${bssid}\", \"${rssi}\", \"${channel}\", \"${CURRENT_TIME}\""
      fi

      field_count=0

      # clear all arrays and variable for the next while loop run
      ssid_array=()
      signal_array=()
      freq_array=()
      bss_array=()
      grep_output=()

      bssid=''
      ssid=''
      freq=''
      rssi=''
      channel=''

    fi

    ((field_count++))

  done | sort -k2

  if [[ "$csv" == "false" ]]
  then
    echo "==============================================================="
    echo
  fi
  #break

  # Have a little break before we go around the loop again
  sleep $LOOP_PAUSE

done
