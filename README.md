# GPU Data Collection Script

This PowerShell script establishes an SSH connection to a remote server to continuously collect GPU utilization and memory usage data for a 24-hour period and exports this data to an Excel file.

## Features

- **Continuous Monitoring**: Collects data in intervals and computes total averages over 24 hours.
- **Excel Export**: Outputs the data to an Excel file with detailed interval and total average sheets.
- **Easy Configuration**: Customize the server IP, username, password, and export path as needed.

## Prerequisites

This script requires the following PowerShell modules:
- Posh-SSH
- ImportExcel

Install them using PowerShell:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Install-Module -Name Posh-SSH -Repository PSGallery -Force
Install-Module -Name ImportExcel -Repository PSGallery -Force
```

## Usage

Modify the `serverIP`, `username`, `password`, and `exportPath` variables to fit your environment, then run the script:
```powershell
.\serverIP-GPU-Data-Collection.ps1
```

## Example Output

The script exports the GPU data to an Excel file, which includes:
- **Intervals Worksheet**: Shows each data point collected at intervals.
- **Total Averages Worksheet**: Shows the average utilization and memory usage calculated over the entire collection period.

## Disclaimer

This script is provided as-is, and it is recommended to review and test it in a development environment before deploying in a production environment. The author assumes no responsibility for any damages that may occur.

## Author

This script was authored by [aviado1](https://github.com/aviado1).
