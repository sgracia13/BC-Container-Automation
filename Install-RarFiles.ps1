function Install-Winrar {
    # Path for the workdir
    $workingDirectory = "c:\installer\"
    
    # Check if work directory exists if not create it
    
    if (Test-Path `
        -Path $workingDirectory `
        -PathType Container)
        { Write-Host "$workingDirectory already exists" `
        -ForegroundColor Red}
    else
        { New-Item `
        -Path $workingDirectory  `
        -ItemType directory }
    
    # Download the installer
    
    $source = "http://rarlab.com/rar/winrar-x64-540.exe"
    $destination = "$workingDirectory\winrar.exe"
    
    Invoke-WebRequest `
    $source `
    -OutFile $destination
    
    # Start the installation
    
    Start-Process `
    -FilePath "$workingDirectory\winrar.exe" `
    -ArgumentList "/S"
    
    # Wait XX Seconds for the installation to finish
    
    Start-Sleep -s 35
    
    # Remove the installer
    
    Remove-Item -Force $workingDirectory
    }
    
                
                
                
                
    function Get-AzureRarFiles {
                #verify credentials. This has to be manual. Simple click
                az login
                
                Start-Sleep `
                -Seconds 20
                
                Set-ExecutionPolicy Bypass `
                -Scope Process `
                -Force; 
                
                #Install Chocolatey
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
                
                Start-Sleep `
                -Seconds 5
                
                #use chocolatey to install azcopy
                choco install azcopy10
                
                Start-Sleep `
                -Seconds 10
                
                #use azcopy to grab rar files from blob storage account
                azcopy copy 'https://approductdevelopment.blob.core.windows.net/rarfiles/*' `
                'C:\rar' 
        }
    
    
    function Get-RarFilesExtractedFromWinRar {
                $rars = Get-ChildItem -Filter "*.rar" -Path C:\rar -Recurse
                $destinationForRars = 'C:/extracted'
                $winrar = 'C:\Program Files\WinRAR\WinRAR.exe'
                
                
                #create destination folder for rar files to be extracted
                New-Item `
                -Path 'C:/' `
                -Name 'extracted'  `
                -ItemType Directory
                
                Start-Sleep -Seconds 10
                Write-Host 'Created C:/extracted directory' -ForegroundColor blue -BackgroundColor White
                Start-Sleep -Seconds 10
                
                #extract all contents 
                foreach($rar in $rars) {
                &$winrar x -y $rar.FullName $destinationForRars
                }
    }
    
    
    
    Install-Winrar
    
    Start-Sleep -Seconds 5
    
    Get-AzureRarFiles
    
    Start-Sleep -Seconds 5
    
    Get-RarFilesExtractedFromWinRar
    
    Start-Sleep -Seconds 5
    
    
    Copy-FileToBcContainer -containerName 'cooks-direct-ci' -localPath 'C:\extracted\EDI-Comm-Setup.msi' -containerPath 'C:/EDI-Comm-Setup.msi'
    Copy-FileToBcContainer -containerName 'cooks-direct-ci' -localPath 'C:\extracted\E-Ship_Comm_Setup.msi' -containerPath 'C:/E-Ship_Comm_Setup.msi'
    
    
    Invoke-ScriptInBcContainer -containerName 'cooks-direct-ci' -scriptblock {
    start-process 'C:/EDI-Comm-Setup.msi' -ArgumentList “/quiet /qn /passive” -Wait 
    }
    
    Invoke-ScriptInBcContainer -containerName 'cooks-direct-ci' -scriptblock {
    start-process 'C:/E-Ship_Comm_Setup.msi' -ArgumentList “/quiet /qn /passive” -Wait 
    }