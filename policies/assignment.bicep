targetScope = 'managementGroup'

param location string = 'westeurope'
param policy object
param policyDefinitionId string

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2021-06-01' = [for scope in policy.scopes: {
  name: uniqueString('${policy.name}_${scope}')
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    description: policy.policyDefinition.properties.description
    displayName: policy.name
    policyDefinitionId: policyDefinitionId
    parameters: policy.parameters
  }
}]

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for (scope, i) in policy.scopes: if (!policy.identity == false) {
  name: guid('${policy.name}_${scope}_${i}')
  properties: {
    roleDefinitionId: policy.policyDefinition.properties.policyRule.then.details.roleDefinitionIds[0]
    principalId: policyAssignment[i].identity.principalId
    principalType: 'ServicePrincipal'
  }
}]

output policyAssignments array = [for (scope, i) in policy.scopes: {
  policyAssignmentId: policyAssignment[i].id
  principalId: policyAssignment[i].identity.principalId
}]
