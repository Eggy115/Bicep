targetScope = 'managementGroup'

@description('Location of deployment')
param location string
@description('List of allowed locations')
param listOfAllowedLocations array
@description('List of management group Ids')
param managementGroupIds object
@description('List of policies')
param policies array =  [
  {
    // 1
    name: 'a_tag_policy.json'
    policyDefinition: json(loadTextContent('./custom/a_tag_policy.json'))
    parameters: {}
    identity: false
    scopes: [
      managementGroupIds.development
    ]
  }
  {
    // 2
    name: 'allowed_location.json'
    policyDefinition: json(loadTextContent('./custom/allowed_location.json'))
    parameters: {
      listOfAllowedLocations: {
        value: listOfAllowedLocations
      }
    }
    identity: false
    scopes: [
      managementGroupIds.development
    ]
  }
  {
    // 3
    name: 'dine_enable_mdc.json'
    policyDefinition: json(loadTextContent('./custom/enable_mdc_on_subscription.json'))
    parameters: {}
    identity: true
    scopes: [
      managementGroupIds.production
    ]
  }
]

resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = [for policy in policies: {
  name: guid(policy.name)
  properties: {
    description: policy.policyDefinition.properties.description
    displayName: policy.policyDefinition.properties.displayName
    metadata: policy.policyDefinition.properties.metadata
    mode: policy.policyDefinition.properties.mode
    parameters: policy.policyDefinition.properties.parameters
    policyType: policy.policyDefinition.properties.policyType
    policyRule: policy.policyDefinition.properties.policyRule
  }
}]

module policyAssignment './wrapper.bicep' = [for (policy, i) in policies: {
  name: 'poAssign_${take(policy.name, 40)}'
  params: {
    policy: policy
    location: location
    policyDefinitionId: policyDefinition[i].id  
  }
  dependsOn: [
    policyDefinition
  ]
}]
