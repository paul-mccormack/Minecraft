using './main.bicep'

param appName = 'samsserver'
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

