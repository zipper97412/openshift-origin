# Post install stuff

For theses operations you need the `oc` command installed and an administrator access to the cluster.
Download `oc` here: https://www.okd.io/download.html#oc-platforms

For administrator access:

Connect via ssh to a master node (use the ssh keys used for deployment)

  OR

Login to the cluster with an administrator user 


> A Linux terminal is always better but powershell with GNU make and `oc` should work


## Authentication: Open Id Connect with Active Directory

Follow this doc: https://docs.microsoft.com/en-us/azure/virtual-machines/linux/openshift-post-deployment

## Give administrator role to a user

When connected with an admin account or from a master node:

`oc adm policy add-cluster-role-to-user cluster-admin <username>`

Replace `<username>` with a htpasswd user or an email address of a AAD user

If htpasswd is used for authentication: 

`oc login -u <username> -p <password>`

If Open Id Connect is used for authentication: 

- Go to the web console at `https://<master-lb-dns-name>:<api-port(443)>/console`
- Login to your Microsoft account (if not already logged in)
- Click on your name -> Copy Login Command
- Paste the command on a terminal

Well done, you are logged in as a cluster administrator

## Install Azure File `StorageClass`

Storage classes are used to dynamically create Persistent Volumes for pods.

By default, a storage class with azure disk as backend is used, you can create an other storage class which use azure file (a storage account) as backend.

> Persistent Volumes created with azure file can be mounted on different pods, on different nodes but you pay on each read/write operations.

> Persistent Volumes created with azure disk can only be mounted on pods on the same node but you pay for how long you use it (good for databases) and you have a limited number of disks on each VM (4?)

- You can reuse the storage account created for the registry or create an other one in the cluster resource group, use azure CLI or the web console
- Clone https://dev.azure.com/infologic-sante/Developpements/_git/OpenShift-templates
  this repository contains some useful deployments for the cluster, it use GNU make and `oc` to deploy resources
- `cd OpenShift-templates/azureFileStorage`
- create a file `all.yaml.env` containing :
```
LOCATION=francecentral
SKU=Standard_LRS
STORAGE_ACCOUNT=<the name of the storage account>
```
- `make apply`
- Check with `oc get storageclass azure-file`

## Install the cert-manager

The Cert Manager is an extension to the openshift API that let you issue new certificates for you applications.
You can install the cert manager along with a certificate issuer global to the cluster signed by infologic-santé ROOT CA.

- Clone https://dev.azure.com/infologic-sante/Developpements/_git/OpenShift-templates
- `cd OpenShift-templates/cert-manager`
- Ask your PKI administrator to create an intermediate ca issuer and give you back the certificate chain in PEM format in a file named `ca-issuer.crt` and the private key in PEM format without password in a file named `ca-issuer.key`
- `make apply`

If there is no error in the output, the cert manager is installed in a new project named `cert-manager`.

In any project you can create `Certificate` resources like `oc apply -f exemple-cert.yaml` and the corresponding tls secrets are automatically created ready to use.

For example, your can reference those secrets in `Ingress` resources to add https to your applications automagically

You can manually create other issuers if necessary, follow this doc: https://docs.cert-manager.io/en/latest/

## Install the ChorusCloud operator

An operator is an extension to the openshift API that manage the deployment of a complete application. 
To simplify, it is a Pod that watch custom resource instances in a project and deploy any necessary components for the application corresponding to the specification of the custom resource instance.

In this case, an operator is used to deploy ChorusCloud instances.
Before that, we need to deploy the operator in a new project via an openshift template,
But first, we need to deploy this template!

- Clone https://dev.azure.com/infologic-sante/Developpements/_git/OpenShift-templates
- `cd OpenShift-templates/choruscloud-operator`
- `oc new-project <project name>` to create a new project to host the operator and the application instances
- The operator build the application from its git repository (azure devops), so it needs a token with read access, you can generate one from azure devops web console. Copy the token in a file named `azure-token` (no blank/no line return!)
- The application also needs a `p12` client certificate to connect to the upstream government API. One for Prod, one for Qualif this certificate is uploaded on the cluster as a `Secret` resource. 
  This makefile can upload the qualif certificate. Copy here the `p12` file with the name `client.p12` and its password in an other file named `client.p12.password` (no blank/no line return!), `make chorus-cert-qualif.yaml` to see the generated secret yaml file
- `make apply`

Now you can deploy the operator in the project from the template with :

- The web console service catalog
- `oc process` command 
- or `make apply-operator-instance`

Then you can create many instances of the application by creating `ChorusCloud` resources in this project ex: `make apply-exemple`. The operator will make sure that the application is deployed correctly

