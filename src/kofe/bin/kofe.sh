#!/bin/bash
#
# KOFE (Kibana OSSEC Filebeat Elasticsearch)
#
# Atomicorp, Inc.

# Globals
# Globals
VERSION=1.0
command=$1


# Helper Functions
function check_input {
  message=$1
  validate=$2
  default=$3

  while [ $? -ne 1 ]; do
    echo -n "$message "
    read INPUTTEXT
    if [ "$INPUTTEXT" == "" -a "$default" != "" ]; then
      INPUTTEXT=$default
      return 1
    fi
    echo $INPUTTEXT | egrep -q "$validate" && return 1
    echo "Invalid input"
  done

}

##############################

show_help() {
  echo
  echo "Kibana OSSEC Filebeat Elasticsearch (KOFE) $VERSION"
  echo
  echo "Usage: kofe [options] COMMAND "
  echo
  echo " List of Commands:"
  echo
  echo "  help			Display a helpful usage message."
  echo "  list			List dashboards to be installed."
  echo "  install		Install a KOFE dashboard."
  echo "  setup 		Setup KOFE."
  echo "  version		Display version"
  echo
}

function configure_tls {

  PATH_CERT="/usr/share/elasticsearch"
  ELASTIC_IP=$1

  pushd /usr/share/elasticsearch
    echo "xpack.security.enabled: true" >> /etc/elasticsearch/elasticsearch.yml
    systemctl restart elasticsearch

    ./bin/elasticsearch-certutil ca -out "$PATH_CERT/kofe-stack-ca.p12"

    if [ "$?" -ne 0 ]; then
      echo "ERROR: Configuring CA certificate"
      return
    fi

    ./bin/elasticsearch-certutil cert --ca "$PATH_CERT/kofe-stack-ca.p12" -out "$PATH_CERT/kofe-stack-certificates.p12"

    if [ ! -d "/etc/elasticsearch/certs/" ]; then
      mkdir -p /etc/elasticsearch/certs
    fi

    /usr/bin/cp -f "$PATH_CERT/kofe-stack-ca.p12" /etc/elasticsearch/certs
    /usr/bin/cp -f "$PATH_CERT/kofe-stack-certificates.p12" /etc/elasticsearch/certs
    /usr/bin/cp -f "$PATH_CERT/kofe-stack-certificates.p12" /etc/elasticsearch

    cat << EOF >> /etc/elasticsearch/elasticsearch.yml
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: kofe-stack-certificates.p12
xpack.security.transport.ssl.truststore.path: kofe-stack-certificates.p12
EOF

  chmod 0660 /etc/elasticsearch/kofe-stack-certificates.p12
  ./bin/elasticsearch-setup-passwords auto -b > ./creds.txt

  kibana_pass=$(grep kibana_system ./creds.txt | grep PASSWORD | cut -d " " -f 4)
  sed -i -e "s/#elasticsearch.password:.*/elasticsearch.password: \"${kibana_pass}\"/g" /etc/kibana/kibana.yml
  sed -i -e "s/#elasticsearch.username: \"kibana_system\"/elasticsearch.username: \"kibana_system\"/g" /etc/kibana/kibana.yml


  check_input "Enter default administator username [default: admin]" "" "admin"
  username=$INPUTTEXT

  check_input "Enter default administator password [default: admin123!]" "" "admin123!"
  password=$INPUTTEXT

  /usr/share/elasticsearch/bin/elasticsearch-users useradd ${username} -p ${password} -r superuser
  systemctl restart elasticsearch

}

function setup_kofe {
  echo
  echo "Beginning KOFE setup process... Please be patient."
  echo

  echo "Setting up repos"
  cat << EOF > /etc/yum.repos.d/elasticsearch.repo
[elasticsearch-7.x]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

  echo
  echo
  echo "Installing packages"

  yum -y install GeoIP elasticsearch kibana GeoIP-GeoLite-data filebeat
  echo
  echo

  # Add to startup
  /bin/systemctl daemon-reload
  /bin/systemctl enable elasticsearch.service
  service elasticsearch start


  check_input "IP Address of Elasticsearch [Default: 127.0.0.1]" "" "127.0.0.1"
  servers=$INPUTTEXT

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

  echo -n "Loading Filebeat OSSEC index modules: "
  cp -f /usr/share/kofe/filebeat/ossec-template.json /etc/filebeat/
  cp -f /usr/share/kofe/filebeat/filebeat.yml.template /etc/filebeat/filebeat.yml
  cp -a /usr/share/kofe/filebeat/module/ossec/ /usr/share/filebeat/module/

  echo "Complete"
  echo

  echo -n "Configuring Filebeat with Elasticsearch IP Address. Using ${SERVERS}"
  sed -i "s/@@SERVERS@@/${SERVERS}/g"  /etc/filebeat/filebeat.yml
  echo
  echo

  check_input "IP Address of Kibana [Default: 127.0.0.1]" "" "127.0.0.1"
  kibana_ip=$INPUTTEXT

  sed -i "s/#server.host.*/server.host: \"$kibana_ip\"/g" /etc/kibana/kibana.yml

  check_input "Would you like to setup SSL/TLS for the Elastic Stack [Default: yes]" "" "yes"
  is_TLS=$INPUTTEXT

  if [ "$INPUTTEXT" != "no" ]; then
    echo "Beginning TLS/SSL configuration process"
    configure_tls $servers
  else
    echo "User opted to not setup TLS configuration. Skipping"
  fi



  systemctl enable kibana
  systemctl start kibana

  systemctl enable filebeat
  systemctl start filebeat

  echo
  echo "KOFE Installation Complete!"
  echo
  echo "  To access your KOFE setup visit http://$kibana_ip:5601"
  echo
}

function list_dashboards {
  dashboardsDir="/usr/share/kofe/dashboards"

  if [ ! -d ${dashboardsDir} ]; then
    echo "ERROR: Could not locate dashboards."
    echo
    exit 1
  fi

  echo "========================================================================================================="
  echo " Component                            NAME                                 Installed"
  echo "========================================================================================================="

    for dashboard in `ls $dashboardsDir | cut -f1 -d .`; do
      installed="No"
      if egrep -q $(echo ${dashboard}) "/usr/share/kofe/dashboards/.dashboards_installed" ; then
        installed="Yes"
      fi

      printf "  %-35s" $(echo Dashboard ${dashboard} ${installed})
      printf "\n"
    done
  echo
  echo
  echo  "========================================================================================================="
  echo

}

function install_dashboard {
  dashPath="/usr/share/kofe/dashboards"
  installFile=".dashboards_installed"

  if egrep -q $(echo ${1}) $(echo ${dashPath}"/"${installFile}) ; then
    echo
    echo "Dashboard: ${1} is already installed. Dashboard will not be imported!"
    echo
    exit 1
  fi

  kibana_ip=$(grep server.host: /etc/kibana/kibana.yml | awk -F":" '{print $2}' | tr -d \" | tr -d " " )
  kibana_url="http://${kibana_ip}:5601/api/saved_objects/_import"

  echo
  echo "Installing dashboard: ${1}"

  curl -s -X POST \
  "${kibana_url}" \
  -H 'kbn-xsrf: true'  \
  --form file=@"${dashPath}/${1}.ndjson" > /dev/null

  if [ "$?" -ne "0" ]; then
    echo "ERROR: Importing Dashboard ${1}"
    echo
    exit 1
  else
    echo "Dashboard ${1} imported successfully!"
    echo "${1}" >> ${dashPath}"/"${installFile}
  fi
}

case "$command" in

  list)
    list_dashboards
    shift $((OPTIND -1))
    ;;
  install)
    shift
    install_dashboard $1
    shift $((OPTIND -1))
    ;;
  setup)
    setup_kofe
    shift $((OPTIND -1))
    ;;
  help)
    show_help
    shift $((OPTIND -1))
    ;;
  version)
   echo "KOFE Version: $VERSION"
   shift $((OPTIND -1))
   ;;
  *)
   show_help
   ;;
esac
