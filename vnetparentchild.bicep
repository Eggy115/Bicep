@description('Name for DNS Private Zone')
param dnsZoneName string = 'contoso'

@description('Fully Qualified DNS Private Zone')
param dnsZoneFqdn string = '${dnsZoneName}.private.mysql.database.azure.com'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Virtual Network Name')
param virtualNetworkName string = 'myawsomevnet'

@description('Subnet Name')
param subnetName string = 'azure_mysql_subnet'

@description('Virtual Network Address Prefix')
param vnetAddressPrefix string = '10.0.0.0/24'

@description('Subnet Address Prefix')
param mySqlSubnetPrefix string = '10.0.0.0/28'

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
  }
}

resource mysqlSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {
  name: subnetName
  parent: vnet
  properties: {
    addressPrefix: mySqlSubnetPrefix
    delegations: [
      {
        name: 'dlg-Microsoft.DBforMySQL-flexibleServers'
        properties: {
          serviceName: 'Microsoft.DBforMySQL/flexibleServers'
        }
      }
    ]
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource dnszone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: dnsZoneFqdn
  location: 'global'
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: vnet.name
  parent: dnszone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

@description('Composing the subnetId')
var mysqlSubnetId =  '${vnetLink.properties.virtualNetwork.id}/subnets/${subnetName}'

param deployMySql bool = false

@description('Database administrator login name')
@minLength(1)
param administratorLogin string = 'admingeneric'

@description('Database administrator password')
@minLength(8)
@secure()
param administratorLoginPassword string = newGuid()

@description('Server Name for Azure database for MySQL')
param serverName string = 'mysqldb'

resource mysqlDbServer 'Microsoft.DBforMySQL/flexibleServers@2021-05-01' = if(deployMySql) {
  name: serverName
  location: location
  sku: {
    name: 'Standard_B1s'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storage: {
      autoGrow: 'Enabled'
      iops: 360
      storageSizeGB: 20
    }
    createMode: 'Default'
    version: '8.0.21'
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    network: {
      delegatedSubnetResourceId: mysqlSubnetId
      privateDnsZoneResourceId: dnszone.id
    }
  }
}
