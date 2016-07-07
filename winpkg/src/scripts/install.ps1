### Licensed to the Apache Software Foundation (ASF) under one or more
### contributor license agreements.  See the NOTICE file distributed with
### this work for additional information regarding copyright ownership.
### The ASF licenses this file to You under the Apache License, Version 2.0
### (the "License"); you may not use this file except in compliance with
### the License.  You may obtain a copy of the License at
###
###     http://www.apache.org/licenses/LICENSE-2.0
###
### Unless required by applicable law or agreed to in writing, software
### distributed under the License is distributed on an "AS IS" BASIS,
### WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
### See the License for the specific language governing permissions and
### limitations under the License.

###
### Install script that can be used to install storm as a Single-Node cluster.
### To invoke the scipt, run the following command from PowerShell:
###   install.ps1 -username <username> -password <password> or
###   install.ps1 -credentialFilePath <credentialFilePath>
###
### where:
###   <username> and <password> represent account credentials used to run
###   storm services as Windows services.
###   <credentialFilePath> encripted credentials file path
###
### By default, Hadoop is installed to "C:\Hadoop". To change this set
### HADOOP_NODE_INSTALL_ROOT environment variable to a location were
### you'd like Hadoop installed.
###
### Script pre-requisites:
###   JAVA_HOME must be set to point to a valid Java location.
###   HADOOP_HOME must be set to point to a valid Hadoop install location.
###
### To uninstall previously installed Single-Node cluster run:
###   uninstall.ps1
###
### NOTE: Notice @version@ strings throughout the file. First compile
### winpkg with "ant winpkg", that will replace the version string.

###

param(
    [String]
    [Parameter( ParameterSetName='UsernamePassword', Position=0, Mandatory=$true )]
    [Parameter( ParameterSetName='UsernamePasswordBase64', Position=0, Mandatory=$true )]
    $username,
    [String]
    [Parameter( ParameterSetName='UsernamePassword', Position=1, Mandatory=$true )]
    $password,
    [String]
    [Parameter( ParameterSetName='UsernamePasswordBase64', Position=1, Mandatory=$true )]
    $passwordBase64,
    [Parameter( ParameterSetName='CredentialFilePath', Mandatory=$true )]
    $credentialFilePath,
    [String]
    $roles
    )

function Main( $scriptDir )
{
    $FinalName = "storm-@storm.version@"
    if ( -not (Test-Path ENV:WINPKG_LOG))
    {
        $ENV:WINPKG_LOG = "$FinalName.winpkg.log"
    }

    $HDP_INSTALL_PATH, $HDP_RESOURCES_DIR = Initialize-InstallationEnv $scriptDir "$FinalName.winpkg.log"
    $nodeInstallRoot = "$ENV:HADOOP_NODE_INSTALL_ROOT"


    ###
    ### Create the Credential object from the given username and password or the provided credentials file
    ###
    $serviceCredential = Get-HadoopUserCredentials -credentialsHash @{"username" = $username; "password" = $password; `
        "passwordBase64" = $passwordBase64; "credentialFilePath" = $credentialFilePath}
    $username = $serviceCredential.UserName
    Write-Log "Username: $username"
    Write-Log "CredentialFilePath: $credentialFilePath"    

    ###
    ### Install and Configure storm
    ###
    if ( $ENV:IS_STORM_NIMBUS -eq "yes" ) {
      $roles = "nimbus"
      $roles = $roles+" "+"ui"
    }

    if ( $ENV:IS_STORM_SUPERVISOR -eq "yes" ) {
      $roles = $roles+" "+"supervisor"
      $roles = $roles+" "+"logviewer"
    }

    $roles = $roles.Trim()
    Write-Log "Roles are $roles"
    Install "storm" $nodeInstallRoot $serviceCredential $roles

    $ENV:STORM_NIMBUS_LOCAL_DIR = $ENV:HDP_DATA_DIR.Replace('\\', '\')
    $ENV:STORM_NIMBUS_LOCAL_DIR = $ENV:STORM_NIMBUS_LOCAL_DIR.Replace('\', '\\')
    $config += @{"storm.zookeeper.servers"=$ENV:ZOOKEEPER_HOSTS;
        "nimbus.seeds"='["' + $ENV:STORM_NIMBUS + '"]';
        "storm.local.dir"='"' + $ENV:STORM_NIMBUS_LOCAL_DIR+ '"'
    }

    Write-Log "Start configuration of storm"
    Configure "storm" $nodeInstallRoot $null $config

    ###
    ### ACL Storm logs directory such that machine users can write to it
    ###
    if(Test-Path ENV:STORM_LOG_DIR)
    {
        $stormlogdir = $ENV:STORM_LOG_DIR
    }
    if( -not (Test-Path "$stormlogdir"))
    {
        Write-Log "Creating Storm logs folder"
        $cmd = "mkdir `"$stormlogdir`""
        Invoke-CmdChk $cmd
    }
    GiveFullPermissions "$stormlogdir" "*S-1-5-32-545"

    Write-Log "Installation of storm completed successfully"
}

### Gives full permissions on the folder to the given user
function GiveFullPermissions(
    [String]
    [Parameter( Position=0, Mandatory=$true )]
    $folder,
    [String]
    [Parameter( Position=1, Mandatory=$true )]
    $username,
    [bool]
    [Parameter( Position=2, Mandatory=$false )]
    $recursive = $false)
{
    Write-Log "Giving user/group `"$username`" full permissions to `"$folder`""
    $cmd = "icacls `"$folder`" /grant ${username}:(OI)(CI)F"
    if ($recursive) {
        $cmd += " /T"
    }
    Invoke-CmdChk $cmd
}

try
{ 
    $scriptDir = Resolve-Path (Split-Path $MyInvocation.MyCommand.Path)
    $utilsModule = Import-Module -Name "$scriptDir\..\resources\Winpkg.Utils.psm1" -ArgumentList ("storm") -PassThru
    $apiModule = Import-Module -Name "$scriptDir\InstallApi.psm1" -PassThru
    Main $scriptDir
}
catch [Exception]
	{
		Write-Log $_.Exception.Message $_
	}
finally
{
    if( $apiModule -ne $null )
    {
        Remove-Module $apiModule
    }

    if( $utilsModule -ne $null )
    {

        Remove-Module $utilsModule
    }
}
