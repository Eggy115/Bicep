targetScope = 'managementGroup'

param location string = 'westeurope'
param policy object
param policyDefinitionId string

module policyAssignment './assignment.bicep' = [for scope in policy.scopes: {
  name: 'poAssign_${take(policy.name, 40)}'
  scope: managementGroup(scope)
  params: {
    policy: policy
    location: location
    policyDefinitionId: policyDefinitionId
  }
}]
