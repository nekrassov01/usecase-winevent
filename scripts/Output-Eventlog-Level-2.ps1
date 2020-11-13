Push-Location -Path $PSScriptRoot

$FunctionsDir = "..\..\powershell-functions\scripts"
Get-ChildItem -Path $FunctionsDir | ForEach-Object -Process { .$_.FullName }

$Directories = @(
    "data"
    "data\$((Get-Date).ToString("yyyy-MM-dd"))-Level-2"
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

    $Ping = Test-Connection -ComputerName $_.ComputerName -Quiet

    If($Ping)
    {
        $Output = Dump-Eventlog @_ -ErrorAction SilentlyContinue
        $Output = $Output | Sort-Object -Property LogName, LevelId, Date, Time
        $Result += $Output
        Out-Log "Done: $($_.ComputerName)"
    }
    Else
    {
        Out-Log "No Reachable: $($_.ComputerName)"
    }
}

$Result | Export-Csv -Path "${MonthDir}\eventlog.csv" -Encoding Default -Force -NoTypeInformation

Pop-Location
Stop-Transcript | Out-Null
Get-Variable | Remove-Variable -ErrorAction SilentlyContinue