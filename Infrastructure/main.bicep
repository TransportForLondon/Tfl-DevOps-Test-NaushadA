@minLength(1)
@maxLength(64)
@description('Name of the environment which is used to generate a short unique hash in all resources.')
param environmentName string

@minLength(1)
@description('Primary Location for all resources')
param location string

param apiServiceName string = ''
//param applicationInsightsDashboardName string = ''
param applicationInsightsName string = ''
param appServicePlanName string = ''
param keyVaultName string = ''
param sqlServerName string = ''
param sqlDatabaseName string = ''
param studentPortalServiceName string = ''

@description('Id of the user or app to assign application roles')
param principalId string = ''

@secure()
@description('SQL Server administration password')
param sqlAdminPassword string

@secure()
@description('Application User Password')
param appUserPassword string

@description('Unique Identifier for resources')
param resourceToken string
var tags = { 'azd-env-name': environmentName }

module studentPortal 'app/web.bicep' = {
  name: 'student-portal'
  params: {
    name: 'app-${studentPortalServiceName}-${resourceToken}'
    location: location
    tags: tags
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    appServicePlanId: appServicePlan.outputs.id
    appSettings: {
      URLAPI: schoolApi.outputs.SERVICE_API_URI
    }
  }
}

module schoolApi 'app/api.bicep' = {
  name: 'school-api'
  params: {
    name: 'api-${apiServiceName}-${resourceToken}'
    location: location
    tags: tags
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    appServicePlanId: appServicePlan.outputs.id
    keyVaultName: keyVault.outputs.name
    appSettings: {
      AZURE_SQL_CONNECTION_STRING_KEY: sqlServer.outputs.connectionStringKey
    }
  }
}

module apiKeyVaultAccess 'core/security/keyvault-access.bicep' = {
  name: 'school-api-keyvault-access'
  params: {
    keyVaultName: keyVault.outputs.name
    principalId: schoolApi.outputs.SERVICE_API_IDENTITY_PRINCIPAL_ID
  }
}

module sqlServer 'app/db.bicep' = {
  name: 'school-database'
  params: {
    name: 'sql-${sqlServerName}-${resourceToken}'
    location: location
    tags: tags
    sqlAdminPassword: sqlAdminPassword
    appUserPassword: appUserPassword
    keyVaultName: keyVault.outputs.name
    databaseName: 'sqldb-${sqlDatabaseName}-${resourceToken}'
  }
}

module appServicePlan 'core/host/appServicePlan.bicep' = {
  name: 'school-appserviceplan'
  params: {
    name: 'plan-${appServicePlanName}-${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: 'B2'
    }
  }
}

module keyVault 'core/security/keyvault.bicep' = {
  name: 'school-keyvault'
  params: {
    name: 'kv-${keyVaultName}-${resourceToken}'
    location: location
    tags: tags
    principalId: principalId
  }
}

module monitoring 'core/monitoring/monitoring.bicep' = {
  name: 'school-monitoring'
  params: {
    location: location
    tags: tags
    applicationInsightsName: 'appi-${applicationInsightsName}-${resourceToken}'
    //applicationInsightsDashboardName: 'dash-${applicationInsightsDashboardName}-${resourceToken}'
  }
}

// Data Outputs
output AZURE_SQL_CONNECTION_STRING_KEY string = sqlServer.outputs.connectionStringKey
output DATABASE_SERVER_NAME string = sqlServer.outputs.sqlServerName
output DATABASE_NAME string = sqlServer.outputs.databaseName

// App Outputs
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.endpoint
output AZURE_KEY_VAULT_NAME string = keyVault.outputs.name
output AZURE_LOCATION string = location
output AZURE_TENANTID string = tenant().tenantId
output API_NAME string = schoolApi.outputs.SERVICE_API_NAME
output STUDENTPORTAL_NAME string = studentPortal.outputs.SERVICE_WEB_NAME
