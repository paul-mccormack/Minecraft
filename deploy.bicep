@description('Base string to be assigned to Azure resources')
param baseName string

@description('The region where the resources will be deployed. If not specified, it will be the same as the resource groups region.')
param location string = resourceGroup().location

@description('The CIDR of the entire virtual network.')
param vnetCidr string

@description('CIDR for Container Apps Environment.')
param acaSubnetCidr string

@description('Suffix to be assigned to revisions of container apps.')
param now string = toLower(utcNow())

@description('Number of CPU cores assigned to the container app.')
@allowed([
  '0.5'
  '1.0'
  '1.5'
  '2.0'
])
param cpu string

@description('Memory allocated to the container app.')
@allowed([
  '1.0Gi'
  '2.0Gi'
  '3.0Gi'
  '4.0Gi'
])
param memory string

@description('Docker image URL for Minecraft Java Edition by itzg.')
param containerImage string

@description('TCP port number for Minecraft server.')
param minecraftPort int

@description('Mount point of persistent storage.')
param volumeMountPoint string

@description('The minimum number of replicas for the container app. If this value is set to 0, the container will stop after being idle for 5 minutes.')
@minValue(0)
@maxValue(1)
param minReplicas int = 0

@description('The environment variables required to start a Minecraft server.')
param env array

@description('Deployment Variables')
var omsName = 'log-${baseName}'
var acaName = 'acaenv-${baseName}'
var vnetName = 'vnet-${baseName}'
var acaSubnetName = 'snet-aca'
var fileShareName = 'mcdata'
var storageName = take('st${toLower(baseName)}${uniqueString(resourceGroup().id)}', 24)
var containerName = 'minecraft'

@description('Deploy the Azure Container App Environement')
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerName
  location: location
  properties: {
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      secrets: []
      registries: []
      ingress: {
        external: true
        exposedPort: minecraftPort
        targetPort: minecraftPort
        transport: 'tcp'
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
    }
    template: {
      revisionSuffix: now
      containers: [
        {
          image: containerImage
          name: containerName
          env: env
          args: []
          probes: []
          volumeMounts: [
            {
              volumeName: fileShareName
              mountPath: volumeMountPoint
            }
          ]
          resources: {
            cpu: any(cpu)
            memory: memory
          }
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: 1
        rules: []
      }
      volumes: [
        {
          storageType: 'AzureFile'
          name: fileShareName
          storageName: fileShareName
        }
      ]
    }
  }
}

@description('Deploy vnet for Container Instances and enable Storage Service Endpoint')
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetCidr
      ]
    }
    subnets: [
      {
        name: acaSubnetName
        properties: {
          addressPrefix: acaSubnetCidr
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
    ]
  }
}

@description('Existing resource declaration for the container instance subnet')
resource acaSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  parent: virtualNetwork
  name: acaSubnetName
}

@description('Configure storage mount for Container Environment')
resource containerAppEnvironmentStorage 'Microsoft.App/managedEnvironments/storages@2024-03-01' = {
  parent: containerAppEnvironment
  name: fileShareName
  properties: {
    azureFile: {
      accountName: storageAccount.name
      shareName: fileShareName
      accountKey: storageAccount.listKeys().keys[0].value
      accessMode: 'ReadWrite'
    }
  }
}

@description('Configure Logging to Azure Monitor')
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: acaName
  location: location
  properties: {
    vnetConfiguration: {
      internal: false
      infrastructureSubnetId: acaSubnet.id
    }
    appLogsConfiguration: {
      destination: 'azure-monitor'
    }
  }
}

@description('Deploy Log Analytics Workspace')
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: omsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

@description('Enable diagnostic logging Container Environment')
resource containerAppEnvironmentDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: containerAppEnvironment
  name: omsName
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    metrics: []
    logs: [
      {
        enabled: true
        categoryGroup: 'allLogs'
      }
    ]
  }
}

@description('Deploy Storage account')
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Premium_LRS'
  }
  kind: 'FileStorage'
  properties: {
    allowBlobPublicAccess: false
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: acaSubnet.id
          action: 'Allow'
        }
      ]
    }

    allowSharedKeyAccess: true
  }
}

@description('Existing resource declaration for Storage Account File Service')
resource storageAccountFile 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' existing = {
  name: 'default'
  parent: storageAccount
}

@description('Create Files Share')
resource storageAccountFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01' = {
  parent: storageAccountFile
  name: fileShareName
  properties: {
    shareQuota: 100
  }
}

@description('Output the fqdn of the server once successfully deployed')
output minecraftServerAddress string = containerApp.properties.configuration.ingress.fqdn
