#!/usr/bin/env bash

#
# Download today's Sandmännchen series movie. Should be invoked
# between 7 and 12 PM, after the daily movie finished.
#
# -- Jan-Benedict Glaw  <jbglaw@lug-owl.de>
#

#
# Get file name
#
T1="`tempfile`"
wget -q -O "${T1}" "http://www.kikaninchen.de/kikaninchen/filme/unsersandmaennchen/sandmann100-flashXml.xml"
DOWNLOAD_FILENAME="`xml2 < "${T1}" | grep fileName | grep '\.mp4' | cut -f 2 -d = | head -1`"
rm -- "${T1}"
echo "${DOWNLOAD_FILENAME}"

#
# Get RTMP server IP address
#
T2="`tempfile`"
wget -q -O "${T2}" "http://www.kikaplus.net/clients/kika/common/public/config/server.xml"
SERVER_IP="`xml2 < "${T2}" | grep '/servers/server/ip=' | sort | uniq | sort -R | cut -f 2 -d '='`"
rm -- "${T2}"
echo "${SERVER_IP}"

#
# Get title
#
TIME="`date '+%H%M' | sed -e 's/^0*//'`"
[ -z "${TIME}" ] && TIME=0
[ "${TIME}" -lt 1900 ] && echo 'W A R N I N G ! ! !   Filename will be wrong!' >&2
if [ "${TIME}" -lt 1850 ]; then
	THE_DAY="`date --date='1 day ago' '+%Y%m%d'`"
else
	THE_DAY="`date '+%Y%m%d'`"
fi
T3="`tempfile`"
wget -q -O "${T3}" "http://www.kika.de/sendungen/ipg/index.html"
TITLE="`egrep '(Unser Sandm|span class="desc)' "${T3}" | grep -A1 'Unser Sand' | grep 'span class="desc"' | cut -f 2 -d '>' | cut -f 1 -d '<'`"
rm -- "${T3}"
printf '>%s<\n' "${TITLE}"

#
# Download file
#
for IP in ${SERVER_IP}; do
	timeout 3600 rtmpdump	-r "rtmp://${IP}/vod"								\
				-a "vod"									\
				--live										\
				-f "LNX 11,2,202,291"								\
				-W "http://www.kikaninchen.de/kikaninchen/controlflash100.swf?version=21756"	\
				-p "http://www.kikaninchen.de/kikaninchen/index.html"				\
				-y "mp4:${DOWNLOAD_FILENAME}"							\
				-o "${THE_DAY}---${TITLE}.mp4"
	[ $? -eq 0 ] && break
done
