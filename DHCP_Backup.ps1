$dhcp1 = "q-dhcp1"
$date = date -Format "dd.MM.yyyy HH:mm:ss"
$date_logs = date -Format "dd.MM.yyyy"
$dhcp_servers = ("q-dhcp1","s-dhcp1","t-dhcp1")
#$dhcp_servers = ("k48-264-dhcp1")
function to_log ([string]$data_log)
    {
        #$date = date -Format "dd.MM.yyyy HH:mm:ss"
        Add-Content C:\Scripts\logs\dhcp_backup_$date_logs.log "$date, $data_log"

    }

  try {
        New-Item -Path "\\zz.qq.ru\temp\OBS Backup DHCP\" -Name $date_logs -ItemType "directory"
        }
    catch {
    
    to_log "Error. Can't create folder in OBS Backup DHCP. $_" -ErrorAction Continue
        break
    }


    foreach ($server in $dhcp_servers) {
#Проверяем возможность записи файла на DHCP сервер и заодно, его доступность
    try {
        
        Invoke-Command -ComputerName $server -ScriptBlock { New-Item -Path c:\dhcptemp -Name "testfile1.txt" -ItemType "file" -Value "This is a test text string."  } -ErrorAction Stop
        Invoke-Command -ComputerName $server -ScriptBlock {Remove-Item c:\dhcptemp\* -Force -Confirm:$false -Recurse} -ErrorAction Stop
                 
        }

    catch {

        to_log "Error. Can't write test file in $server. $_" -ErrorAction Continue
        break
        }
#Backup
    try {
        Invoke-Command -ComputerName $server -ScriptBlock { backup-dhcpserver -Path C:\dhcptemp } -ErrorAction Stop   
        }

    catch {
        to_log "Error. Can't backup DHCP on $server. $_" -ErrorAction Continue
        break
        }
#Export DHCP config    
    try {
        Invoke-Command -ComputerName $server -ScriptBlock { Export-DhcpServer -File C:\dhcptemp\DHCPdata.xml -Leases -Force} -ErrorAction Stop
        }
    catch {
        to_log "Error. Can't export DHCP config from $server. $_" -ErrorAction Continue
        break
    }

#Copy the Backup
    New-Item -Path "\\zz.qq.ru\temp\OBS Backup DHCP\$date_logs" -Name $server -ItemType "directory"
    copy \\$server\c$\dhcptemp\* "\\zz.qq.ru\temp\OBS Backup DHCP\$date_logs\$server" -Recurse
    to_log "Info. $server DHCP backup is OK." 
}




