<#
    .SYNOPSIS
    Compares Cloud Platforms' services and gives information about them.
    It's intended to be a quick access tool for searching and comparing the data hold 
    by the website: https://comparecloud.in/
    Only works for Powershell 7+

    .DESCRIPTION
    This script uses a csv called "clouds.csv" to compare and expose information about
    cloud platforms.

    It can not only expose all the data hold by the csv file, but also search for equivalent
    solutions of one platform among the others.

    If not using the parameter "Tablify", every solution found is outputted as an object,
    so it can be pipelined into other filtering scripts for further processing.

    Any data contained in the csv can be autocompleted (and is checked) using tab while writing the
    command in the terminal.

    The data can be filtered, from a bigger scope to a lower one, following the next tree:
    Plaform > Category > Service > Solution

    .PARAMETER Platform
    Specifies the Platform on which to do the searching

    .PARAMETER Category
    Specifies the Category on which to do the searching

    .PARAMETER Service
    Specifies the Service to search

    .PARAMETER Solution
    Specifies the Solution being search or compared

    .PARAMETER IncludeDescription 
    Specifies whether the solution's description field should be included or not in the output

    .PARAMETER FindEquivalent
    If included next to a solution, the script will search for its equivalent in other cloud platforms

    .PARAMETER Tablify
    If included, the output will be formatted as an easy to read table, but won't be easy to process by other scripts on the pipeline

    .INPUTS
    None. No pipe objects accepted.

    .OUTPUTS
    Yes. The results are pipelined as individual objects that can be further processed.

    .EXAMPLE
    PS > .\Compare-CloudServices.ps1 -Platform AWS
    
    ###### Gets the whole platform information details.

    Sample output:

    Platform    : AWS
    Category    : Application Discovery Services
    Service     : Application Discovery Services
    Solution    : Application Discovery Service
    Description : https://aws.amazon.com/application-discovery/

    Platform    : AWS
    Category    : Application Services
    Service     : Media Transcoders
    Solution    : AWS Elemental MediaConnect
    Description : https://aws.amazon.com/mediaconnect/

    [...]

    .EXAMPLE
    PS > .\Compare-CloudServices.ps1 -Platform AWS -Category Storage

    ###### Gets all the platform's services for the specified category.

    Sample output:

    Service
    -------
    File Storage (SMB Compatible)
    File Storage (SMB Compatible)
    File Storage (SMB Compatible)
    File Storage (SMB Compatible)
    File Storage (SMB Compatible)
    Hybrid Storage/Storage Gateway
    Long Term Cold Storage
    Object Storage
    Virtual Machine Disk Storage

    .EXAMPLE
    PS > .\Compare-CloudServices.ps1 -Platform AWS -Service 'Object Storage' -IncludeDescription

    ###### Gets all the solutions for the specified platform's service and includes its descriptions.

    Sample output:

    Solution                           Description
    --------                           -----------
    Amazon Simple Storage Service (S3) https://aws.amazon.com/documentation/s3/

    .EXAMPLE
    PS > .\Compare-CloudServices.ps1 -Service 'Object Storage' -IncludeDescription
    
    ###### Gets all the solutions for the specified service and includes its descriptions.

    Sample output:

    Platform              Solution                                   Description
    --------              --------                                   -----------
    AWS                   Amazon Simple Storage Service (S3)         https://aws.amazon.com/documenta…
    Microsoft Azure       Azure Blob Storage                         https://azure.microsoft.com/serv…
    IBM Cloud             Cloud Object Storage                       https://cloud.ibm.com/docs/servi…
    Google Cloud Platform Cloud Storage                              https://cloud.google.com/storage/
    Alibaba Cloud         Object Storage Service                     https://www.alibabacloud.com/pro…
    Huawei Cloud          Object Storage Service                     https://www.huaweicloud.com/intl…
    Oracle Cloud          Oracle Cloud Infrastructure Object Storage https://www.oracle.com/cloud/sto…

    .EXAMPLE
    PS > .\Compare-CloudServices.ps1 -Category 'Storage' | Where-Object { $_.platform -in ('IBM Cloud','AWS')} | Select-Object -Unique service,platform | Sort-Object platform

    ###### Gets all the services for the given category. The output is then post-processed to only get those of 
    IBM and AWS and sort them by platform.

    Sample output:

    Service                        Platform
    -------                        --------
    File Storage (SMB Compatible)  AWS
    Hybrid Storage/Storage Gateway AWS
    Long Term Cold Storage         AWS
    Object Storage                 AWS
    Virtual Machine Disk Storage   AWS
    File Storage (SMB Compatible)  IBM Cloud
    Long Term Cold Storage         IBM Cloud
    Object Storage                 IBM Cloud
    Virtual Machine Disk Storage   IBM Cloud

    .EXAMPLE
    PS > .\Compare-CloudServices.ps1 -Solution 'Amazon Elastic File System (EFS)'

    ###### Gets all the solution's information.

    Sample output:

    Platform    : AWS
    Category    : Storage
    Service     : File Storage (SMB Compatible)
    Solution    : Amazon Elastic File System (EFS)
    Description : https://aws.amazon.com/efs/

    .EXAMPLE
    PS > .\Compare-CloudServices.ps1 -Solution 'Amazon Elastic File System (EFS)' -FindEquivalent -IncludeDescription

    ###### Finds the solution's twin in other platforms and includes their description.

    Sample output:

    Platform              Solution                     Description
    --------              --------                     -----------
    Microsoft Azure       Azure Files                  https://azure.microsoft.com/en-us/services/sto…
    Microsoft Azure       Azure NetApp Files           https://azure.microsoft.com/en-gb/services/net…
    IBM Cloud             File Storage                 https://cloud.ibm.com/docs/infrastructure/File…
    Google Cloud Platform File Store                   http://cloud.google.com/filestore
    Alibaba Cloud         NAS File Storage             https://www.alibabacloud.com/product/nas
    Oracle Cloud          Oracle File Storage Services https://docs.oracle.com/en-us/iaas/Content/Fil…
    Huawei Cloud          Scalable File Service        https://www.huaweicloud.com/intl/en-us/product…

    .LINK
    Credits to: https://comparecloud.in/ that inspired this idea and also gathered all the cloud platform's information in one place.
    My github: https://github.com/petrodcas
#>
param (
    <# Cada parámetro tiene un ValidateScript para asegurarse de que el valor introducido está incluido en el csv, 
    así como un ArgumentCompleter para poder autocompletar los valores usando el tabulador en la terminal.
    Esto podría haberse hecho usando clases, pero dado que se trata de un solo script y no de un módulo, se vuelve
    imposible y se opta por esta forma aunque dificulte la lectura y el mantenimiento. #>
    [ValidateScript(
        {
            $platforms=Get-Content ".\clouds.csv" -Raw | ConvertFrom-Csv | Select-Object -Unique Platform | ForEach-Object { $_.Platform }
            "$_" -in $platforms
        },
        ErrorMessage="Specify a valid csv file"
    )]
    [ArgumentCompleter(
        {
            param($cmd, $param, $wordToComplete)
            $platforms=Get-Content ".\clouds.csv" -Raw | ConvertFrom-Csv | Select-Object -Unique Platform | ForEach-Object { $_.Platform }
            if ($wordToComplete[0] -eq "`'" ) {
                $wordToComplete=$wordToComplete.substring(1)
                $wordToComplete=$wordToComplete.substring(0,$wordToComplete.Length-1)
            }
            $CompletionResult = $platforms -match "\b$wordToComplete" | Select-Object -First 1
            if ($CompletionResult -ne $null) {
                "`'$CompletionResult`'"
            }
            else {
                $CompletionResult
            }
        }
    )]
    [Parameter(Mandatory, ParameterSetName="GetPlatformDetails")]
    [Parameter(Mandatory, ParameterSetName="GetPlatformServices")]
    [Parameter(Mandatory, ParameterSetName="GetPlatformSolutions")]
    [string]$Platform,
    [ValidateScript(
        {
            $categories=Get-Content ".\clouds.csv" -Raw | ConvertFrom-Csv | Select-Object -Unique Category | ForEach-Object { $_.Category }
            "$_" -in $categories
        },
        ErrorMessage="Specify a valid csv file."
    )]
    [ArgumentCompleter(
        {
            param($cmd, $param, $wordToComplete)
            $categories=Get-Content ".\clouds.csv" -Raw | ConvertFrom-Csv | Select-Object -Unique Category | ForEach-Object { $_.Category }
            if ($wordToComplete[0] -eq "`'" ) {
                $wordToComplete=$wordToComplete.substring(1)
                $wordToComplete=$wordToComplete.substring(0,$wordToComplete.Length-1)
            }
            $CompletionResult = $categories -match "\b$wordToComplete" | Select-Object -First 1
            if ($CompletionResult -ne $null) {
                "`'$CompletionResult`'"
            }
            else {
                $CompletionResult
            }
        }
    )]
    [Parameter(Mandatory, ParameterSetName="GetPlatformServices")]
    [Parameter(Mandatory, ParameterSetName="GetCategoryServices")]
    [string]$Category,
    [ValidateScript(
        {
            $services=Get-Content ".\clouds.csv" -Raw | ConvertFrom-Csv | Select-Object -Unique Service | ForEach-Object { $_.Service }
            "$_" -in $services
        },
        ErrorMessage="Specify a valid csv file."
    )]
    [ArgumentCompleter(
        {
            param($cmd, $param, $wordToComplete)
            $services=Get-Content ".\clouds.csv" -Raw | ConvertFrom-Csv | Select-Object -Unique Service | ForEach-Object { $_.Service }
            if ($wordToComplete[0] -eq "`'" ) {
                $wordToComplete=$wordToComplete.substring(1)
                $wordToComplete=$wordToComplete.substring(0,$wordToComplete.Length-1)
            }
            $CompletionResult = $services -match "\b$wordToComplete" | Select-Object -First 1
            if ($CompletionResult -ne $null) {
                "`'$CompletionResult`'"
            }
            else {
                $CompletionResult
            }
        }
    )]
    [Parameter(Mandatory, ParameterSetName="GetPlatformSolutions")]
    [Parameter(Mandatory, ParameterSetName="GetServiceSolutions")]
    [string]$Service,
    [ValidateScript(
        {
            $solutions=Get-Content ".\clouds.csv" -Raw | ConvertFrom-Csv | Select-Object -Unique Solution | ForEach-Object { $_.Solution }
            "$_" -in $solutions
        },
        ErrorMessage="Specify a valid csv file."
    )]
    [ArgumentCompleter(
        {
            param($cmd, $param, $wordToComplete)
            $solutions=Get-Content ".\clouds.csv" -Raw | ConvertFrom-Csv | Select-Object -Unique Solution | ForEach-Object { $_.Solution }
            if ($wordToComplete[0] -eq "`'" ) {
                $wordToComplete=$wordToComplete.substring(1)
                $wordToComplete=$wordToComplete.substring(0,$wordToComplete.Length-1)
            }
            $CompletionResult = $solutions -match "\b$wordToComplete" | Select-Object -First 1
            if ($CompletionResult -ne $null) {
                "`'$CompletionResult`'"
            }
            else {
                $CompletionResult
            }
        }
    )]
    [Parameter(Mandatory, ParameterSetName="GetSolutionDetail")]
    [Parameter(Mandatory, ParameterSetName="GetSolutionEquivalent")]
    [string]$Solution,
    [Parameter(Mandatory=$false, ParameterSetName="GetPlatformSolutions")]
    [Parameter(Mandatory=$false, ParameterSetName="GetServiceSolutions")]
    [Parameter(Mandatory=$false, ParameterSetName="GetSolutionEquivalent")]
    [Switch]$IncludeDescription,
    [Parameter(Mandatory, ParameterSetName="GetSolutionEquivalent")]
    [Switch]$FindEquivalent,
    [Parameter(ParameterSetName="Default")]
    [Parameter(ParameterSetName="GetPlatformDetails")]
    [Parameter(ParameterSetName="GetPlatformServices")]
    [Parameter(ParameterSetName="GetPlatformSolutions")]
    [Parameter(ParameterSetName="GetServiceSolutions")]
    [Parameter(ParameterSetName="GetSolutionEquivalent")]
    [Parameter(ParameterSetName="GetSolutionDetail")]
    [Parameter(ParameterSetName="GetCategoryServices")]
    [Switch]$Tablify
)

[string]$usedParameterSet=$PSCmdlet.ParameterSetName
[string]$csvfile=".\clouds.csv"


function Get-PlatformDetails {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$platform
    )
    
    process {
        Get-Content "$csvfile" -Raw | ConvertFrom-Csv | Where-Object { "$($_.Platform)" -eq "$platform" } | Select-Object Platform,Category,Service,Solution,Description | Sort-Object Category 
    }
}

function Get-PlatformServicesByCategory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Platform,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Category
    )

    process {
        Get-Content "$csvfile" -Raw | ConvertFrom-Csv | Where-Object { "$($_.Platform)" -eq "$Platform" -and "$($_.Category)" -eq "$Category"} | Select-Object Service | Sort-Object Service 
    }
}

function Get-PlatformSolutionsByService {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Platform,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Service,
        [switch]$IncludeDescription
    )
    process {
        $found=Get-Content "$csvfile" -Raw | ConvertFrom-Csv | Where-Object {
            "$($_.Platform)" -eq "$Platform" -and "$($_.Service)" -eq "$Service"
        }
        if ($IncludeDescription) {
            $found=$found | Select-Object Solution,Description
        }
        else {
            $found=$found | Select-Object Solution
        }
        $found | Sort-Object Solution 
    }
}

function Get-ServicesByCategory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Category
    )

    process {
        Get-Content "$csvfile" -Raw | ConvertFrom-Csv | Where-Object { "$($_.Category)" -eq "$Category"} | Select-Object Platform,Service | Sort-Object Service 
    }
}

function Get-SolutionsByService {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Service,
        [switch]$IncludeDescription
    )
    process {
        $found=Get-Content "$csvfile" -Raw | ConvertFrom-Csv | Where-Object {
            "$($_.Service)" -eq "$Service"
        }
        if ($IncludeDescription) {
            $found=$found | Select-Object Platform,Solution,Description
        }
        else {
            $found=$found | Select-Object Platform,Solution
        }
        $found | Sort-Object Solution 
    }
}

function Get-SolutionDetails {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Solution
    )
    process {
        Get-Content "$csvfile" -Raw | ConvertFrom-Csv | Where-Object {
            "$($_.Solution)" -eq "$Solution"
        } | Select-Object Platform,Category,Service,Solution,Description
    }
}

function Get-SolutionEquivalents {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Solution,
        [switch]$IncludeDescription
    )
    process {
        $input_details=Get-SolutionDetails -Solution "$Solution"
        if ($IncludeDescription) {
            $input_details | ForEach-Object {
                $in_service=$_.Service
                $in_platform=$_.Platform
                Get-SolutionsByService -Service "$in_service" -IncludeDescription:$IncludeDescription | Where-Object { "$($_.Platform)" -ne "$in_platform" }
            } | Select-Object -Unique platform,solution,description
        }
        else {
            $input_details | ForEach-Object {
                $in_service=$_.Service
                $in_platform=$_.Platform
                Get-SolutionsByService -Service "$in_service" -IncludeDescription:$IncludeDescription | Where-Object { "$($_.Platform)" -ne "$in_platform" }
            } | Select-Object -Unique platform,solution
        }
    }
}

function Format-AsTableIfNeeded {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromRemainingArguments)]
        [psobject[]]$input_object
    )
    begin {
        [psobject[]]$ob_array
    }
    process {
        $ob_array+=$input_object
    }
    end {
        if ($Tablify) {
            $ob_array | Format-Table -AutoSize
            return
        }
        else {
            $ob_array
        }
    }

}

switch ($usedParameterSet) {
    "GetPlatformDetails" {    
        # returns all the details for the specified platform
        Get-PlatformDetails "$Platform" | Format-AsTableIfNeeded
    }
    "GetPlatformServices" { 
        # returns all the platform's services' information
        [PSCustomObject]@{Platform="$Platform";Category="$Category"} | Get-PlatformServicesByCategory | Format-AsTableIfNeeded
    }
    "GetPlatformSolutions" {
        # returns all the platform's solutions' information
        Get-PlatformSolutionsByService -Platform "$Platform" -Service "$Service" -IncludeDescription:$IncludeDescription | Format-AsTableIfNeeded
    }
    "GetCategoryServices" {
        # returns all the services for the given category
        Get-ServicesByCategory -Category "$Category" | Format-AsTableIfNeeded
    }
    "GetServiceSolutions" {
        # returs all the solutions for the given service
        Get-SolutionsByService -Service "$Service" -IncludeDescription:$IncludeDescription | Format-AsTableIfNeeded
    }
    "GetSolutionDetail" {
        # returns information about the given solution
        Get-SolutionDetails -Solution "$Solution" | Format-AsTableIfNeeded
    }
    "GetSolutionEquivalent" {
        # finds and returns all the twins of the given solution in other platforms
        Get-SolutionEquivalents -Solution "$Solution" -IncludeDescription:$IncludeDescription | Format-AsTableIfNeeded
    }
    Default {
        # Write-Error "An error ocurred: Unknown query."
        Get-Content -Raw '.\clouds.csv' | ConvertFrom-Csv | Format-AsTableIfNeeded
    }
}


