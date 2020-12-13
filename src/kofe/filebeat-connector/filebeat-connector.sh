#!/bin/sh

# Copyright Atomicorp, Inc.
# All Rights reserved

VERSION="0.1"


show_help() {
  echo
  echo "Atomicorp Filebeat connector $VERSION"
  echo
  echo "Usage: $0 [options] COMMAND "
  echo
  echo " List of Commands:"
  echo 
  echo "  -s <servers> 		list of Elasticsearch hosts(required)"
  echo "     Example:  -s es0.domain.com,es2.domain.com,es3.domain.com"
  echo
  echo
}


while getopts ":s:u:p:" opt; do
  case $opt in
    s) servers="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done


if [ ! $servers ]; then
	show_help
	exit 1
fi


echo
echo "Configuring Filebeat connector"
echo

# Create hosts array
for host in $(echo $servers | sed "s/,/ /g"); do
	ES_NODE+=("${host}:9200")		
done

SERVERS="["
last=${ES_NODE[-1]}
for i in ${!ES_NODE[@]}; do
	if [ ${ES_NODE[$i]} != ${ES_NODE[-1]} ]; then
		SERVERS+="\"${ES_NODE[$i]}\","
	else
		SERVERS+="\"${ES_NODE[$i]}\""
	fi
done
SERVERS+="]"
echo "   hosts: $SERVERS"
echo


cp -f /usr/share/awp/filebeat/ossec-template.json /etc/filebeat/
cp -f /usr/share/awp/filebeat/filebeat.yml.template /etc/filebeat/filebeat.yml
sed -i "s/@@SERVERS@@/${SERVERS}/g"  /etc/filebeat/filebeat.yml

#   ssl.certificate_authorities: ["/etc/elasticsearch/certs/ca.crt"]


systemctl enable filebeat
systemctl restart filebeat
