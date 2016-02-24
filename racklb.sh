#!/bin/bash
# Query and manipulate Rackspace cloud load balancers
# by Karl Kranich
# thanks to Adam Bull at www.haxed.me.uk for some sed inspiration

# Use -h to get usage info

# Load variables with config script
source racklb-config.sh

usage() {
cat << EOF
racklb.sh - query and manipulate Rackspace cloud load balancers
(Currently assumes that load balancers are at ORD)

Usage:
Show list of load balancers with racklb.sh
Show load balancer settings with racklb.sh -l LoadBalancerID
Add a certificate mapping with racklb.sh -a -l LoadBalancerID -n Hostname -c CertFile -k KeyFile [-i intermediateCert]
Delete a certificate mapping with racklb.sh -d -l LoadBalancerID -m MappingID
EOF
}

getToken() {
  rackToken=$(curl -s -H 'Content-type: application/json' -d "{\"auth\":{\"RAX-KSKEY:apiKeyCredentials\":{\"username\":\"$rackUser\",\"apiKey\":\"$rackKey\"}}}" -X POST https://identity.api.rackspacecloud.com/v2.0/tokens | jq '.access.token.id' | cut -f 2 -d '"')
}

query() {
  getToken
  echo General info:
  curl -s -H "Content-type: application/json" -H "X-Auth-Token: $rackToken" -X GET https://ord.loadbalancers.api.rackspacecloud.com/v1.0/$rackAccount/loadbalancers/$rackLBID | jq '.'
  echo SSL Termination info:
  curl -s -H "Content-type: application/json" -H "X-Auth-Token: $rackToken" -X GET https://ord.loadbalancers.api.rackspacecloud.com/v1.0/$rackAccount/loadbalancers/$rackLBID/ssltermination | jq '.'
  echo Other certificate mappings:
  curl -s -H "Content-type: application/json" -H "X-Auth-Token: $rackToken" -X GET https://ord.loadbalancers.api.rackspacecloud.com/v1.0/$rackAccount/loadbalancers/$rackLBID/ssltermination/certificatemappings | jq '.'
}

addMapping() {
  if [ -z "$rackLBID" ] || [ -z "$keyFile" ] || [ -z "$certFile" ] || [ -z "$hostname" ]; then
    echo -a requires ID, hostname, cert file, and key file
    exit
  fi

  # Build the json to submit (sed command is split up to maintain Mac (BSD) compatibility)
  echo "{
  \"certificateMapping\": {
     \"hostName\": \"$hostname\",
     \"certificate\": \"" > lb.json
  cat $certFile | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g' >> lb.json
  echo '", "privateKey": "' >> lb.json
  cat $keyFile | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g' >> lb.json
  if [ ! -z "$intCertFile" ]; then
    echo '", "intermediateCertificate": "' >> lb.json
    cat $intCertFile | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g' >> lb.json
  fi
  echo '" } }' >> lb.json
  #cat lb.json

  # Post the json
  getToken
  curl -H "X-Auth-Token: $rackToken" -d @lb.json -X POST -H "content-type: application/json" https://ord.loadbalancers.api.rackspacecloud.com/v1.0/$rackAccount/loadbalancers/$rackLBID/ssltermination/certificatemappings
  echo
}

deleteMapping() {
  if [ -z "$rackLBID" ] || [ -z "$rackMapID" ]; then
    echo -d requires ID and MappingID
    exit
  fi
  getToken
  curl -s -H "Content-type: application/json" -H "X-Auth-Token: $rackToken" -X DELETE https://ord.loadbalancers.api.rackspacecloud.com/v1.0/$rackAccount/loadbalancers/$rackLBID/ssltermination/certificatemappings/$rackMapID
}

# Main script
# First get all the arguments
optString='hadl:n:c:k:i:m:'
while getopts "$optString" option
do
  case $option in
    h)
      usage
      exit
      ;;
    l)
      rackLBID=$OPTARG
      ;;
    k)
      keyFile=$OPTARG
      ;;
    c)
      certFile=$OPTARG
      ;;
    i)
      intCertFile=$OPTARG
      ;;
    n)
      hostname=$OPTARG
      ;;
    m)
      rackMapID=$OPTARG
      ;;
  esac
done

# Now process the commands
OPTIND=1      #move option index back to the beginning
while getopts "$optString" option
do
  case $option in
    a)
      addMapping
      exit
      ;;
    d)
      deleteMapping
      exit
      ;;
    l)
      query
      exit
      ;;
  esac
done

# If there were no arguments given, show list of load balancers
if [ $OPTIND -eq 1 ]; then
  getToken
  curl -s -H "Content-type: application/json" -H "X-Auth-Token: $rackToken" -X GET https://ord.loadbalancers.api.rackspacecloud.com/v1.0/$rackAccount/loadbalancers | jq '.loadBalancers[] | {name, id, virtualIps}'
fi

