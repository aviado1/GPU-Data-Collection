<#
    .SYNOPSIS
    This script collects GPU information from a remote server and exports the data to Excel.

    .DESCRIPTION
    The script establishes an SSH connection to a specified server to retrieve GPU utilization and memory usage data continuously for 24 hours. It exports this data to an Excel file, both in intervals and as total averages.
    Modify the 'exportPath', 'username', 'password', and 'serverIP' variables to fit your environment.

    .AUTHOR
    Aviad Ofek

    .NOTES
    This script requires the Posh-SSH and ImportExcel PowerShell modules to be installed.

    .EXAMPLE
    .\serverIP-GPU-Data-Collection.ps1
#>

# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
# Install-Module -Name Posh-SSH -Repository PSGallery -Force
# Install-Module -Name ImportExcel -Repository PSGallery -Force

# Import Posh-SSH module
Import-Module Posh-SSH
# Import the Excel module
Import-Module ImportExcel

# Server credentials
$serverIP = "192.168.1.100"  # Sample server IP address - change as needed
$username = "admin"          # Sample username - change as needed
$securePassword = ConvertTo-SecureString "password123" -AsPlainText -Force  # Sample password - change as needed
$credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)

# Ensure the directory exists
$exportPath = "C:\Temp\GPU"  # Change the directory path as needed
if (-Not (Test-Path $exportPath)) {
    New-Item -Path $exportPath -ItemType Directory
}

# Establish SSH connection and handle potential errors
try {
    $session = New-SSHSession -ComputerName $serverIP -Credential $credential -ErrorAction Stop
}
catch {
    Write-Host "Failed to establish SSH connection: $($_.Exception.Message)"
    exit
}

# Function to get GPU information
function Get-GpuInfo {
    try {
        $gpuInfoCommand = "nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total --format=csv,noheader"
        $gpuInfo = Invoke-SSHCommand -SessionId $session.SessionId -Command $gpuInfoCommand
        return $gpuInfo.Output
    }
    catch {
        Write-Host "Failed to retrieve GPU information: $($_.Exception.Message)"
        return "Error retrieving GPU information"
    }
}

# Data structure to store intervals and totals
$gpuData = @()

# Start time and end time setup
$startTime = Get-Date
$endTime = $startTime.AddHours(24)  # Set to run for 24 hours

# Loop to continuously check GPU information for 24 hours with countdown
try {
    while ((Get-Date) -lt $endTime) {
        $currentInfo = Get-GpuInfo
        $timeStamp = Get-Date
        foreach ($line in $currentInfo) {
            $details = $line -split ", "
            $gpuData += [PSCustomObject]@{
                TimeStamp = $timeStamp
                GPUIndex = $details[0]
                GPUName = $details[1]
                GPULoad = $details[2] -replace '%', '' # Remove percentage sign for calculation
                MemoryUsed = [int]($details[3] -replace '\sMiB', '') # Remove ' MiB' and convert to integer
                MemoryTotal = [int]($details[4] -replace '\sMiB', '') # Remove ' MiB' and convert to integer
            }
        }
        Start-Sleep -Seconds 10  # Sample every 10 seconds

        # Update countdown timer
        $remainingTime = New-TimeSpan -Start (Get-Date) -End $endTime
        if ($remainingTime.TotalMinutes -gt 1) {
            $displayTime = [math]::Floor($remainingTime.TotalMinutes)
            Write-Host "Remaining time: $displayTime minutes"
        } else {
            $displayTime = [math]::Floor($remainingTime.TotalSeconds)
            Write-Host "Remaining time: $displayTime seconds"
        }
    }
}
finally {
    # Ensure the SSH session is closed when the script exits
    if ($session) {
        Remove-SSHSession -SessionId $session.SessionId
    }
}

# Format the timestamp for the filename including time without colons
$formattedDate = Get-Date -Format "dd-MM-yyyy_HH-mm"
$excelFilename = "${serverIP}_${formattedDate}.xlsx"
$excelPath = Join-Path -Path $exportPath -ChildPath $excelFilename

# Export interval data to Excel
$gpuData | Export-Excel -Path $excelPath -WorksheetName "Intervals" -AutoSize -TableName "IntervalData"

# Calculate total average load and memory usage for each GPU and append to the existing Excel
$totalAverageLoads = $gpuData | Group-Object GPUIndex | ForEach-Object {
    [PSCustomObject]@{
        TimeStamp = "Total Average"
        GPUIndex = $_.Name
        GPUName = ($_.Group | Select-Object -Unique GPUName).GPUName
        GPULoad = [math]::Round(($_.Group | Measure-Object -Property GPULoad -Average).Average, 2)
        MemoryUsed = [math]::Round(($_.Group | Measure-Object -Property MemoryUsed -Average).Average, 2)
        MemoryTotal = [math]::Round(($_.Group | Select-Object -Unique MemoryTotal).MemoryTotal, 2)
    }
}
$totalAverageLoads | Export-Excel -Path $excelPath -WorksheetName "TotalAverages" -AutoSize -TableName "TotalAverageData" -Append

Write-Host "Data and total averages exported to $excelPath"
