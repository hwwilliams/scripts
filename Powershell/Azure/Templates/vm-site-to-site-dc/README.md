# Windows DC with a Site to Site VPN Connection

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FSaltystew%2Fscripts%2Fwip%2FPowershell%2FAzure%2FTemplates%2Fvm-site-to-site-dc%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FSaltystew%2Fscripts%2Fwip%2FPowershell%2FAzure%2FTemplates%2Fvm-site-to-site-dc%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

This template will create a Windows server VM, with your choice of the server OS verson. The VM will be configured to be a domain controller, it will then create a Virtual Network, a subnet for that network, a Virtual Network Gateway and a Connection to your network outside of Azure (defined as your `local` network). This could be anything such as your on-premises network and can even be used with other cloud networks.

Please note that you must have a Public IP for your other network's VPN gateway and it cannot be behind NAT.

Although only the parameters in [azuredeploy.parameters.json](./azuredeploy.parameters.json) are necessary, you can override the defaults of any of the template parameters.