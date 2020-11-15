﻿Push-Location -Path $PSScriptRoot

$FunctionsDir = "..\..\powershell-functions\scripts"
Get-ChildItem -Path $FunctionsDir | ForEach-Object -Process { .$_.FullName }

$Directories = @(
    "data"
    "data\$((Get-Date).ToString("yyyy-MM-dd"))-Level-1"
    "log"
)

$Directories = New-FolderConstruction -Path $Directories -Root $PSScriptRoot

$DataDir  = $Directories[0].FullName
$MonthDir = $Directories[1].FullName
$LogDir   = $Directories[2].FullName

Remove-PastFiles -Path $DataDir, $LogDir -Day 365 -Recurse

Start-Transcript -Path "${LogDir}\$((Get-Date).ToString("yyyyMMddHHmmss")).log" -Force | Out-Null

$Params = @(
    @{
        ComputerName = "remotehost-1"
        LogName      = "System", "Application"
        Level        = 1,2,3
        Recently     = 24
    }
    @{
        ComputerName = "remotehost-1"
        LogName      = "Security"
        Level        = 0
        Recently     = 24
        EventId      = 4625
    }
    @{
        ComputerName = "remotehost-2"
        LogName      = "System", "Application"
        Level        = 1,2,3
        Recently     = 24
    }
    @{
        ComputerName = "remotehost-2"
        LogName      = "Security"
        Level        = 0
        Recently     = 24
        EventId      = 4625
    }
)

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