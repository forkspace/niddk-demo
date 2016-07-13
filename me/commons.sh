#!/bin/bash

#===========================================================
#
#	FILE:	commons.sh
#		
#	USAGE:	
# DESCRIPTION:	general purpose shell script functions
#     OPTIONS:	
#REQUIREMENTS:	
#	 BUGS:	
#      AUTHOR:	jtv
#     VERSION:	1.1
#     CREATED:	20080822
#    REVISION:	20080827
#===========================================================


PSWD_SUFFIX=.PSWD

#=== FUNCTION ===================================================
#          NAME	: log
#   DESCRIPTION	: common logging function, prints the message to
#		  STDOUT and expects to find a 
#		  filename in a $LOGFILE variable to write in
#   PARAMETER 1	: the message to log
#       RETURNS : 0 - ok, else not ok
#       CREATED	: 20080829
#        AUTHOR	: jtv
#================================================================
log()
{
	message="<log>$(date +%Y%m%d%H%M%S) - $1"
	echo -e "$message"
	#only executes if LOGFILE variable exists
	#and has some value assigned
	if [ -n "$LOGFILE" ]
	then
		echo -e "$message" >> "$LOGFILE"
	fi
}

#=== FUNCTION ===================================================
#          NAME	: debug
#   DESCRIPTION	: common debuggingfunction, prints the message to
#		  STDOUT
#   PARAMETER 1	: the debug message
#       RETURNS : 0 - ok, else not ok
#       CREATED	: 20080829
#        AUTHOR	: jtv
#================================================================
debug()
{      
	#only executes if DEBUG variable exists
	#and has some value assigned
	if [ -n "$DEBUG" ]
	then
		echo -e "<debug>$(date +%Y%m%d%H%M%S) - $1"
	fi
}

#=== FUNCTION ===================================================
#          NAME	: splitString
#   DESCRIPTION	: splits a string and assigns its pieces to an 
#		  array to be conveyed in the RETURN_VALUE variable. 
#   PARAMETER 1	: the string to split
#   PARAMETER 2	: the string separator (OPTIONAL), assumes " " as
#		  default separator.
#       CREATED	: 20080828
#        AUTHOR	: jtv
#================================================================
splitString()
{
	log "«IN» splitString"


	if [ -z "$1" ];then
		log "!!!must supply the string!!!"
		exit -1
	fi
	
	if [ -n "$2" ];then
		SEPARATOR=$2
	fi
	
	local string="$@"
	
	debug "string to split is $string"
	debug "separator is $IFS"	

	RETURN_VALUE=

	trimString "$string"
	string=$RETURN_VALUE
	RETURN_VALUE=
	squeezeStringSpaces "$string"
	string="$RETURN_VALUE"
	debug "squeeze string places returned $string to splitString"

	#local array=($string)
	
	index=0
	RETURN_VALUE=
	
	for item in $string
	do
		RETURN_VALUE[$index]=$item
		index=`expr $index + 1`
	done
	
	debug "split created an array with $index elements"

	log "«OUT» splitString = (${RETURN_VALUE[*]})"
}

#=== FUNCTION ===================================================
#          NAME	: trimString
#   DESCRIPTION	: trims a string and assigns it to the 
#		  RETURN_VALUE variable. 
#   PARAMETER 1	: the string to be trimmed
#       CREATED	: 20080828
#        AUTHOR	: jtv
#================================================================
trimString()
{
	log "«IN» trimString"
	if [ -z "$1" ];then
		log "!!!must supply the string!!!"
		exit -1
	fi
	local string=$@
	RETURN_VALUE=$(echo "$string" | sed 's/^[ \t]*//;s/[ \t]*$//')
	log "«OUT» trimString = ($RETURN_VALUE)"
}



#=== FUNCTION ===================================================
#          NAME	: squeezeStringSpaces
#   DESCRIPTION	: squeezes multiple consecutive spaces and tabs 
#		  in a string to a single space, and assigns it to the 
#		  RETURN_VALUE variable.
#   PARAMETER 1	: the string to be squeezed
#       CREATED	: 20080828
#        AUTHOR	: jtv
#================================================================
squeezeStringSpaces()
{
	log "«IN» squeezeStringSpaces"
	if [ -z "$1" ];then
		log "!!!must supply the string!!!"
		exit -1
	fi
	local string="$@"
	RETURN_VALUE=`echo "$string" | sed 's/[ \t]\{2,\}/ /g'`
	log "«OUT» squeezeStringSpaces = ($RETURN_VALUE)"
}







#=== FUNCTION ===================================================
#          NAME	: getSecret	
#   DESCRIPTION	: reads a secret filethat should be kept private
#   PARAMETER 1	: secret to get, should be the name prefix of the secret file to read
#	OUTCOME		: returns the content of the secret file, for instance, a password, 
#					as in: 
#						mysecret=$(getSecret secretPrefix)
#================================================================

getSecret()
{	
	local SECRET_SUFFIX=".SECRET"
	if [ -z $1 ] 
	then
		echo "!!! no secret to inspect !!! ...leaving."
		return 1
	fi
	secret="$1"
	folder=$(dirname $(readlink -f $0))
	secretfile="$folder/$secret$SECRET_SUFFIX"
	#echo "secret file is $secretfile"
	if [ ! -e $secretfile ]
	then
		echo "!!! no secret file [$secretfile] !!! ...leaving."
		return -1
	fi
	result=`cat $secretfile`
	echo "$result"
}

#=== FUNCTION ===================================================
#          NAME	: resetUsbPorts	
#   DESCRIPTION	: due to power volatility some usb ports are 
#					sometimes faulty in my laptop, this is a fix.
#================================================================

resetUsbPorts()
{	
	echo "resetting usb ports...."
	sudo modprobe -r usbhid
	sudo modprobe usbhid
	echo "...reset usb ports...done. [$?]"
}

ipToint32()
{
	result=$(ip=`hostname -I` && ip=( ${ip//\./ } ) && echo "(${ip[0]} * (2^24)) + (${ip[1]}*(2^16)) + (${ip[2]}*(2^8)) + ${ip[3]}" | bc)
	echo "$result"
}