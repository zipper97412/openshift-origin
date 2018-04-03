# OpenShift Origin Deployment Template for Azure Stack

Bookmark [aka.ms/OpenShift](http://aka.ms/OpenShift) for future reference.

For the **OpenShift Container Platform** refer to https://github.com/Microsoft/openshift-container-platform

## OpenShift Origin 3.7 with Username / Password for OpenShift in Azure Stack

Additional documentation for deploying OpenShift in Azure can be found here: https://docs.microsoft.com/en-us/azure/virtual-machines/linux/openshift-get-started

This template deploys OpenShift Origin with basic username / password for authentication to OpenShift. This uses CentOS and includes the following resources:

|Resource           |Properties                                                                                                                          |
|-------------------|------------------------------------------------------------------------------------------------------------------------------------|
|Virtual Network   		|**Address prefix:** 10.0.0.0/8<br />**Master subnet:** 10.1.0.0/16<br />**Node subnet:** 10.2.0.0/16                      |
|Master Load Balancer	|1 probes and 1 rule for TCP 8443 <br/> NAT rules for SSH on Ports 2200-220X                                           |
|Infra Load Balancer	|2 probes and 2 rules for TCP 80 and TCP 443								                                             |
|Public IP Addresses	|OpenShift Master public IP attached to Master Load Balancer<br />OpenShift Router public IP attached to Infra Load Balancer            |
|Storage Accounts <br />Unmanaged Disks  	|1 Storage Account for Master VMs <br />1 Storage Account for Infra VMs<br />2 Storage Accounts for Node VMs<br />2 Storage Accounts for Diagnostics Logs <br />1 Storage Account for Private Docker Registry<br />1 Storage Account for Persistent Volumes  |
|Network Security Groups|1 Network Security Group Master VMs<br />1 Network Security Group for Infra VMs<br />1 Network Security Group for Node VMs  |
|Availability Sets      |1 Availability Set for Master VMs<br />1 Availability Set for Infra VMs<br />1 Availability Set for Node VMs  |
|Virtual Machines   	|3 or 5 Masters. First Master is used to run Ansible Playbook to install OpenShift<br />2 or 3 Infra nodes<br />User-defined number of Nodes (1 to 30)<br />All VMs include a single attached data disk for Docker thin pool logical volume|

## READ the instructions in its entirety before deploying!

Currently, the Azure Cloud Provider does not work in Azure Stack. This means you will not be able to use disk attach for persistent storage in Azure Stack. You can always configure other storage options such as NFS, iSCSI, Gluster, etc. that can be used for persistent storage. We are exploring options to address the Azure Cloud Provider in Azure Stack but this will take a little bit of time.

Additional documentation for deploying OpenShift in Azure can be found here: https://docs.microsoft.com/en-us/azure/virtual-machines/linux/openshift-get-started

This template deploys multiple VMs and requires some pre-work before you can successfully deploy the OpenShift Cluster. If you don't get the pre-work done correctly, you will most likely fail to deploy the cluster using this template.  Please read the instructions completely before you proceed.

## Prerequisites

### Configure Azure CLI to connect to your Azure Stack environment

In order to use the Azure CLI to manage resources in your Azure Stack environment, you will need to first configure the CLI to connect to your Azure Stack.  Follow instructions here: https://docs.microsoft.com/en-us/azure/azure-stack/user/azure-stack-connect-cli.

You will need to determine the necessary endpoints for each of the following settings:

  - endpoint-resource-manager 
  - suffix-storage-endpoint 
  - suffix-keyvault-dns  
  - endpoint-active-directory-graph-resource-id 
  - endpoint-vm-image-alias-doc 
  
### Generate SSH Keys

You'll need to generate a pair of SSH keys in order to provision this template. Ensure that you do **NOT** include a passphrase with the private key.

If you are using a Windows computer, you can download puttygen.exe. You will need to export to OpenSSH (from Conversions menu) to get a valid Private Key for use in the Template.

From a Linux or Mac, you can just use the ssh-keygen command. Once you are finished deploying the cluster, you can always generate new keys that uses a passphrase and replace the original ones used during inital deployment.

### Create Key Vault to store SSH Private Key

You will need to create a Key Vault to store your SSH Private Key that will then be used as part of the deployment.

1. **Create Key Vault using Azure CLI 2.0**<br/>
  a.  Create new Resource Group: az group create -n \<name\> -l \<location\><br/>
         Ex: `az group create -n ResourceGroupName -l 'East US'`<br/>
  b.  Create Key Vault: az keyvault create -n \<vault-name\> -g \<resource-group\> -l \<location\> --enabled-for-template-deployment true<br/>
         Ex: `az keyvault create -n KeyVaultName -g ResourceGroupName -l 'East US' --enabled-for-template-deployment true`<br/>
  c.  Create Secret: az keyvault secret set --vault-name \<vault-name\> -n \<secret-name\> --file \<private-key-file-name\><br/>
         Ex: `az keyvault secret set --vault-name KeyVaultName -n SecretName --file ~/.ssh/id_rsa`<br/>


### azuredeploy.Parameters.json File Explained

1.  _artifactsLocation: The base URL where artifacts required by this template are located. If you are using your own fork of the repo and want the deployment to pick up artifacts from your fork, update this value appropriately (user and branch), for example, change from `https://raw.githubusercontent.com/Microsoft/openshift-origin/master/` to `https://raw.githubusercontent.com/YourUser/openshift-origin/YourBranch/`
2.  masterVmSize: Size of the Master VM. Select from one of the allowed VM sizes listed in the azuredeploy.json file
3.  infraVmSize: Size of the Infra VM. Select from one of the allowed VM sizes listed in the azuredeploy.json file
3.  nodeVmSize: Size of the Node VM. Select from one of the allowed VM sizes listed in the azuredeploy.json file
4.  storageKind: The type of storage to be used. Value can only be "unmanaged". When Azure Stack supports managed disk, this will be updated
5.  openshiftClusterPrefix: Cluster Prefix used to configure hostnames for all nodes - master, infra and nodes. Between 1 and 20 characters
8.  masterInstanceCount: Number of Masters nodes to deploy
8.  infraInstanceCount: Number of infra nodes to deploy
9.  nodeInstanceCount: Number of Nodes to deploy
9.  dataDiskSize: Size of data disk to attach to nodes for Docker volume - valid sizes are 128 GB, 512 GB and 1023 GB
10. adminUsername: Admin username for both OS login and OpenShift login
11. openshiftPassword: Password for OpenShift login
11. enableMetrics: Enable Metrics - value is either "true" or "false"
11. enableLogging: Enable Logging - value is either "true" or "false"
12. sshPublicKey: Copy your SSH Public Key here
14. keyVaultResourceGroup: The name of the Resource Group that contains the Key Vault
15. keyVaultName: The name of the Key Vault you created
16. keyVaultSecret: The Secret Name you used when creating the Secret (that contains the Private Key)
18. enableAzure: Enable Azure Cloud Provider - value is only "false". When Azure Cloud Provider is supported in Azure Stack, this will be updated
18. aadClientId: Azure Active Directory Client ID also known as Application ID for Service Principal
18. aadClientSecret: Azure Active Directory Client Secret for Service Principal
17. defaultSubDomainType: This will either be nipio (if you don't have your own domain) or custom if you have your own domain that you would like to use for routing
18. defaultSubDomain: The wildcard DNS name you would like to use for routing if you selected custom above.  If you selected nipio above, then this field will be ignored

## Deploy Template

Once you have collected all of the prerequisites for the template, you can deploy the template by populating the *azuredeploy.parameters.local.json* file and executing Resource Manager deployment commands with PowerShell or the CLI.

For Azure CLI 2.0, sample commands:

```bash
az group create --name OpenShiftTestRG --location WestUS2
```
while in the folder where your local fork resides

```bash
az group deployment create --resource-group OpenShiftTestRG --template-file azuredeploy.json --parameters @azuredeploy.parameters.local.json --no-wait
```

Monitor deployment via CLI or Portal and get the console URL from outputs of successful deployment which will look something like (if using sample parameters file and "West US 2" location):

`https://me-master1.westus2.cloudapp.azure.com:443/console`

The cluster will use self-signed certificates. Accept the warning and proceed to the login page.

### NOTE

Be sure to follow the OpenShift instructions to create the necessary DNS entry for the OpenShift Router for access to applications.

### TROUBLESHOOTING

If you encounter an error during deployment of the cluster, please view the deployment status. The following Error Codes will help to narrow things down.

1. Exit Code 5: Unable to provision Docker Thin Pool Volume

For further troubleshooting, please SSH into your master0 node on port 2200. You will need to be root **(sudo su -)** and then navigate to the following directory: **/var/lib/waagent/custom-script/download**<br/><br/>
You should see a folder named '0' and '1'. In each of these folders, you will see two files, stderr and stdout. You can look through these files to determine where the failure occurred.

## Post-Deployment Operations

### Metrics and logging

**Metrics**

If you deployed Metrics, it will take a few extra minutes deployment to complete. Please be patient.

Once the deployment is complete, log into the OpenShift Web Console and complete an addition configuration step.  Go to the openshift-infra project, click on Hawkster metrics route, and accept the SSL exception in your browser.

**Logging**

If you deployed Logging, it will take a few extra minutes deployment to complete. Please be patient.

Once the deployment is complete, log into the OpenShift Web Console and complete an addition configuration step.  Go to the logging project, click on the Kubana route, and accept the SSL exception in your browser.

### Creation of additional users

To create additional (non-admin) users in your environment, login to your master server(s) via SSH and run:
<br><i>htpasswd /etc/origin/master/htpasswd mynewuser</i>

### Additional OpenShift Configuration Options

You can configure additional settings per the official [OpenShift Origin Documentation](https://docs.openshift.org/latest/welcome/index.html).

Few options you have

1. Deployment Output
  a. openshiftConsoleUrl the openshift console url<br/>
  b. openshiftMasterSsh  ssh command for master node<br/>
  c. openshiftNodeLoadBalancerFQDN node load balancer<br/>
2. Get the deployment output data
  a. portal.azure.com -> choose 'Resource groups' select your group select 'Deployments' and there the deployment 'Microsoft.Template'. As output from the deployment it contains information about the openshift console url, ssh command and load balancer url.<br/>
  b. With the Azure CLI : 
    ```bash
    azure group deployment list -g <resource group name>
    ```

