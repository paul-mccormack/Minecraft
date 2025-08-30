<center>

![minecraft](https://raw.githubusercontent.com/paul-mccormack/Minecraft/refs/heads/main/images/minecraft-banner.jpg)

</center>

# Introduction

This project deploys a minecraft server onto [Azure Container Instances](https://azure.microsoft.com/en-us/products/container-instances).  The image being deployed is [itzg/minecraft-server](https://hub.docker.com/r/itzg/minecraft-server) from Docker Hub.  Documentation for setting up the image is available at the link.

An Azure Files enabled storage account with file share is being deployed to provide persistent storage for the container along with a Log Analytics Workspace to provide diagnostic logging.  This is a fun learning project but we are going to do it properly.

# Deployment details

The project service connection is scoped to the Sandbox subscription.  The following tasks are performed at deployment:

* Lint the code to check for stylisitc and syntax errors.
* Publish the test results into the DevOps project
* Login to Azure and create the Resource Group
* Login to Azure and validate the deployment via the Azure Resource Manager
* Login to Azure and run a what-if analysis for the deployment.
* Pause the run and notify approvers that a deployment is waiting to be reviewed.  Once review has completed and approved the actual deployment will be completed.

Customise the Resource Group name and tags by editing the pipeline config file [azure-pipeline.yml](https://dev.azure.com/scc-ddat-infrastructure/_git/Minecraft?path=/azure-pipelines.yml).

The variables section is shown below:

```
variables:
  #Edit variables before deployment
  rgName: rg-uks-sandbox-pmc-aci-demo
  rgLocation: uksouth
  costTag: "Cost Centre=Training"
  serviceTag: "Service=Training"
  createdTag: "Created By=Paul McCormack" 
```

Customise deployment as required using the bicep parameter file [main.bicepparam](https://dev.azure.com/scc-ddat-infrastructure/_git/Minecraft?path=/main.bicepparam)

Example deployment shown in the snippet below:

```
using './main.bicep'

param appName = 'mcserver'
param appImage = 'docker.io/itzg/minecraft-server:latest'
param networkConfig = 'Public'
param port = 25565
param protocol = 'TCP'
param cpuCores = 4
param memoryInGb = 8
param osType = 'Linux'
param restartPolicy = 'Always'
param storageSKU = 'Standard_LRS'
param containerMountPath = '/data'
```

The only parameter that really needs to be changed is the ```appName```.  This will form the prefix for the resource names and the DNS record Azure will create for the server.

# Simulate a failed deployment

Bicep contains a set of best practises and recommendations when you are creating a template.  By default most of these rules will only generate a warning and allow the deployment to proceed.  You can change this behaviour by placing a file called ```bicepconfig.json``` in the same folder as your templates.  You can find the file in this repo: [bicepconfig.json](https://dev.azure.com/scc-ddat-infrastructure/_git/Minecraft?path=/bicepconfig.json).  This version of the file has increased the alert level on a selection of rules to error.  This will cause the deployment to fail at the Lint stage.  The rules are all to do with managing secret values.  If a secret value is exposed during a deployment, which is allowed to complete the secret will appear in the deployment logs and console.  Potentially leaking confidential information.

In the Bicep template [main.bicep](https://dev.azure.com/scc-ddat-infrastructure/_git/Minecraft?path=/main.bicep) there is a commented out line in the outputs section, shown below:

```
//uncomment the output below to trigger an error causing the deployment to fail
//output secret string = stg.listKeys().keys[0].value
```

If this line is uncommented the access key for the storage account created will be output into the logs and in the console.  VSCode will warn you but you can still run the deployment.

