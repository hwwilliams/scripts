# Updating Azure Template API Versions

When creating, or updating, an Azure Template it may be necessary to also update the API version used for a particular resource type, Microsoft has these schemas available online hosted under one of their [Azure Github repos](https://github.com/Azure/azure-resource-manager-schemas/tree/master/schemas) but as you'll find out, its a lot to dig through.

To make the process of updating them a little easier I found a module that will search and pull the latest API version for the specificed resource type.

You can determine the latest API version using either the full type:

`Get-AzureRmResourceProviderLatestApiVersion -Type Microsoft.Storage/storageAccounts`

Or by passing the Resource Provider and Resource Type:

`Get-AzureRmResourceProviderLatestApiVersion -ResourceProvider Microsoft.Storage -ResourceType storageAccounts`

Finally, to include preview versions you can append the -IncludePreview switch:

`Get-AzureRmResourceProviderLatestApiVersion -Type Microsoft.Storage/storageAccounts -IncludePreview`

For example take this resource snippet:

```
{
    "type": "Microsoft.Storage/storageAccounts",
    "name": "[variables('storageAccountName')]",
    "apiVersion": "2018-07-01",
    "location": "[resourceGroup().location]",
    "sku": {
        "name": "Standard_LRS"
    },
    "kind": "Storage",
    "properties": {}
}
```

As you can see in the previous example, a resource type for storage accounts would be `Microsoft.Storage/storageAccounts`.

The `apiVersion` specifies the version of the API that is used to deploy and manage the resource.

A resource provider offers a set of operations to deploy and manage resources using a REST API. If a resource provider adds new features, it releases a new version of the API. Therefore, if you have to utilize new features you may have to use the latest API Version.

More information about the module can be found [here](https://about-azure.com/2018/06/12/determine-latest-api-version-for-a-resource-provider/).

Or a direct link to the file on Github can be found [here](https://github.com/mjisaak/azure/blob/master/Get-AzureRmResourceProviderLatestApiVersion.ps1).

