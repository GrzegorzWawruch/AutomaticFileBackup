 function Copy-RecentFiles {
    param ( 
    $Source = 'C:\Users\GW\Desktop\Source',
    $Destination = 'C:\Users\GW\Desktop\Destination',
    $PathToLogFile = 'C:\Users\GW\Desktop\LogFile.txt'
    )

    [datetime]$CurrentDate = Get-Date
    [datetime]$BackupsDate = $CurrentDate.AddDays(-7)
    $while = $true
    

    if((Test-Path -Path $PathToLogFile) -eq $true)
    {
        Remove-Item -Path $PathToLogFile
    }

    New-Item -ItemType file -Path $PathToLogFile

    while($while -eq $true)
    {
        $TestSource = Test-Path -path $Source

        if($TestSource -eq $false)
        {
            "The source directory doesn't exists or you enter the valid path. Try enter path again !!! "
            $while = $false
            break
        }

        $SourceFiles = Get-ChildItem -Path $Source
        $TestDestination = Test-Path -Path $Destination

        if($TestDestination -eq $false)
        {
            "The destination directory doesn't exists !!! "
            $while = $false
            break
        }
        foreach($item in $SourceFiles)
        {
            
            if($BackupsDate -gt (Get-ItemProperty -path $item.FullName -Name LastWriteTime).LastWriteTime)
            {
                try
                {

                    $DestinationFilePath = Join-Path -Path $Destination -ChildPath $item.Name
                    $DoFileExists = Test-Path -Path $DestinationFilePath
                    if($DoFileExists -eq $false)
                    {
                        Copy-Item $item.FullName -Destination $Destination
                        Write-Host $item.GetType() + " " + $item.Name + " was copied succesfully to Destination folder" | Out-File -FilePath $PathToLogFile -Append
                    }
                    elseif($DoFileExists -eq $true)
                    {
                        Remove-Item -Path $DestinationFilePath
                        Copy-Item $item.FullName -Destination $Destination
                        Write-Host $item.GetType() + " " + $item.Name + " was copied succesfully to Destination folder" | Out-File -FilePath $PathToLogFile -Append
                    }
                }
                catch
                {
                    $ErrorDate = Get-Date
                    Write-Host "Sorry but something gone wrong"
                    $wshell = New-Object -ComObject WScript.Shell
                    $wshell.Popup($Error[0] + '   ' + $ErrorDate)
                    $wshell.Popup('You must to turn on this script manualy if you want try make copy before next harmonogram date') 
                    $while = $false    
                    break
                }
                
            }
            else 
            {
                Write-Output "$($item.GetType())  $($item.Name)  is too young to be copied" | Out-File -FilePath $PathToLogFile -Append
            }
            
        }
        $while = $false
        break 
    
    }
}

Copy-RecentFiles

$TaskExists = Get-ScheduledTask -TaskName "Backup" -ErrorAction SilentlyContinue

if(-not $TaskExists)
{
    $Option = New-ScheduledJobOption -WakeToRun -RunElevated -StartIfOnBattery
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Friday -At 5pm 
    $ScriptPath = $MyInvocation.MyCommand.Path
    Register-ScheduledJob -FilePath $ScriptPath -Trigger $trigger -ScheduledJobOption $Option -Name "Backup"
}