#!/bin/bash

echo $(date) " - Starting Script"

set -e

cat <<EOF > /home/$1/env.sh
export SUDOUSER="$1"
export PASSWORD="$2"
export PRIVATEKEY="$3"
export MASTER="$4"
export MASTERPUBLICIPHOSTNAME="$5"
export MASTERPUBLICIPADDRESS="$6"
export INFRA="$7"
export NODE="$8"
export NODECOUNT="$9"
export INFRACOUNT="${10}"
export MASTERCOUNT="${11}"
export ROUTING="${12}"
export REGISTRYSA="${13}"
export ACCOUNTKEY="${14}"
export TENANTID="${15}"
export SUBSCRIPTIONID="${16}"
export AADCLIENTID="${17}"
export AADCLIENTSECRET="${18}"
export RESOURCEGROUP="${19}"
export LOCATION="${20}"
export METRICS="${21}"
export LOGGING="${22}"
export AZURE="${23}"
export STORAGEKIND="${24}"

export MASTERLOOP=$((MASTERCOUNT - 1))
export INFRALOOP=$((INFRACOUNT - 1))
export NODELOOP=$((NODECOUNT - 1))
EOF
chmod +x /home/$1/env.sh
echo "source ~/env.sh" >> /home/$1/.bashrc

runuser -l $SUDOUSER -c "echo \"$PRIVATEKEY\" > ~/.ssh/id_rsa"
runuser -l $SUDOUSER -c "chmod 600 ~/.ssh/id_rsa*"