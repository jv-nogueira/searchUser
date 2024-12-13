# Carrega o assembly do Windows Forms
Add-Type -AssemblyName System.Windows.Forms

# FunÃ§Ã£o para obter informaÃ§Ãµes da rede
function Get-NetworkInfo {
    $hostname = $env:COMPUTERNAME
    # ObtÃ©m as informaÃ§Ãµes de IP usando Get-NetIPConfiguration
    $netInfo = Get-NetIPConfiguration | Where-Object { $_.IPv4Address -ne $null }
    $ipv4 = $netInfo.IPv4Address.IPAddress
    return [PSCustomObject]@{
        Hostname = $hostname
        IPv4 = $ipv4
    }
}

# Formulario
$form = New-Object Windows.Forms.Form
$form.Text = "InformaÃ§Ãµes de Rede"
$form.Size = New-Object Drawing.Size(350,240)
$form.StartPosition = "CenterScreen"

# Informacoes de rede
$networkInfo = Get-NetworkInfo

# Label para exibir o hostname
$labelHostname = New-Object Windows.Forms.Label
$labelHostname.Size = New-Object Drawing.Size(200,30)
$labelHostname.Location = New-Object Drawing.Point(25, 30)
$labelHostname.Text = "Hostname: " + $networkInfo.Hostname
$form.Controls.Add($labelHostname)

# Botao para copiar o hostname
$btnCopyHostname = New-Object Windows.Forms.Button
$btnCopyHostname.Size = New-Object Drawing.Size(100,30)
$btnCopyHostname.Location = New-Object Drawing.Point(230, 30)
$btnCopyHostname.Text = "Copiar"
$btnCopyHostname.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText($networkInfo.Hostname)
})
$form.Controls.Add($btnCopyHostname)

# Label para exibir o IPv4
$labelIPv4 = New-Object Windows.Forms.Label
$labelIPv4.Size = New-Object Drawing.Size(200,30)
$labelIPv4.Location = New-Object Drawing.Point(25, 70)
$labelIPv4.Text = "IPv4: " + $networkInfo.IPv4
$form.Controls.Add($labelIPv4)

# Botao para copiar o IPv4
$btnCopyIPv4 = New-Object Windows.Forms.Button
$btnCopyIPv4.Size = New-Object Drawing.Size(100,30)
$btnCopyIPv4.Location = New-Object Drawing.Point(230, 70)
$btnCopyIPv4.Text = "Copiar"
$btnCopyIPv4.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText($networkInfo.IPv4)
})
$form.Controls.Add($btnCopyIPv4)

# Label para exibir SN
$labelSN = New-Object Windows.Forms.Label
$labelSN.Size = New-Object Drawing.Size(200,30)
$labelSN.Location = New-Object Drawing.Point(25, 110)
$labelSN.Text = "SN: " + (wmic bios get serialnumber).Trim()
$form.Controls.Add($labelSN)

# Botao para copiar SN
$btnCopySN = New-Object Windows.Forms.Button
$btnCopySN.Size = New-Object Drawing.Size(100,30)
$btnCopySN.Location = New-Object Drawing.Point(230, 110)
$btnCopySN.Text = "Copiar"
$btnCopySN.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText((wmic bios get serialnumber).Trim())
})
$form.Controls.Add($btnCopySN)

# Label para exibir winver
$labelWinver = New-Object Windows.Forms.Label
$labelWinver.Size = New-Object Drawing.Size(200,30)
$labelWinver.Location = New-Object Drawing.Point(25, 150)
$labelWinver.Text = "Versão do Windows: " + (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion
$form.Controls.Add($labelWinver)

# Botao para copiar winver
$btnCopyWinver = New-Object Windows.Forms.Button
$btnCopyWinver.Size = New-Object Drawing.Size(100,30)
$btnCopyWinver.Location = New-Object Drawing.Point(230, 150)
$btnCopyWinver.Text = "Copiar"
$btnCopyWinver.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion)
})
$form.Controls.Add($btnCopyWinver)

# Exibe o formulÃ¡rio
$form.ShowDialog()
