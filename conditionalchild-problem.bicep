@description('Resource name for backend Web or Function App')
param apiAppName string = ''

var apimServiceId = ''

resource apiApp 'Microsoft.Web/sites@2022-03-01' existing = if (!empty(apiAppName)) {
  name: apiAppName
}

resource apiAppProperties 'Microsoft.Web/sites/config@2022-03-01' = if (!empty(apiAppName)) {
  name: 'web'
  kind: 'string'
  parent: apiApp
  properties: {
      apiManagementConfig: {
        id: '${apimServiceId}/apis/${apiName}'
      }
  }
}

