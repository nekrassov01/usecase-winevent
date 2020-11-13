Push-Location -Path $PSScriptRoot

$FunctionsDir = "..\..\powershell-functions\scripts"
Get-ChildItem -Path $FunctionsDir | ForEach-Object -Process { .$_.FullName }

$Directories = @(
    "data"
    "data\$((Get-Date).ToString("yyyy-MM-dd"))-Level-3"
    "log"
)

$Directories = New-FolderConstruction -Path $Directories -Root $PSScriptRoot

$DataDir = $Directories[0].FullName
$MonthDir = $Directories[1].FullName
$LogDir = $Directories[2].FullName

Remove-PastFiles -Path $DataDir, $LogDir -Day 365 -Recurse

Start-Transcript -Path "${LogDir}\$((Get-Date).ToString("yyyyMMddHHmmss")).log" -Force | Out-Null

$Json = Get-Content -Path ".\params.json"
$Params = @()
($Json | ConvertFrom-Json).Params | ForEach-Object -Process {
    $Serializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $Hashtable = $Serializer.Deserialize(($_ | ConvertTo-Json), [System.Collections.Hashtable])
    $Params += $Hashtable
}

$Result = @()

$Params | ForEach-Object -Process {

    $ComputerName = $_.ComputerName
    $LogName      = $_.LogName
    $Level        = $_.Level
    $Recently     = $_.Recently
    $EventId      = $_.EventId

    $Ping = Test-Connection -ComputerName $ComputerName -Quiet

    If($Ping)
    {
        $LogName | ForEach-Object -Process {
            
            $Params = @{
                ComputerName = $ComputerName
                LogName      = $_
                Level        = $Level
                Recently     = $Recently
                EventId      = $EventId
            }

            $Output = Dump-Eventlog @Params -ErrorAction SilentlyContinue
            $Output | Export-Csv -Path "${MonthDir}\${ComputerName}.${_}.csv" -Encoding Default -Force -NoTypeInformation
            $Result += $Output
            Out-Log "Done: ${ComputerName} - ${_}"
        }
    }
    Else
    {
        Out-Log "No Reachable: ${ComputerName}"
    }
}

$Result | Export-Csv -Path "${MonthDir}\all.csv" -Encoding Default -Force -NoTypeInformation

Pop-Location
Stop-Transcript | Out-Null
Get-Variable | Remove-Variable -ErrorAction SilentlyContinue