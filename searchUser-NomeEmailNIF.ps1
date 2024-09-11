# Importar o módulo do Active Directory
Import-Module ActiveDirectory

# Criar a função de interface GUI
function Create-GUI {
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

    # Criar a janela principal (form)
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Pesquisa de Usuários AD"
    $form.Size = New-Object System.Drawing.Size(600,550)

    # Criar uma TextBox para entrada de NIF, Email ou Nome Completo
    $textBoxNIF = New-Object System.Windows.Forms.TextBox
    $textBoxNIF.Location = New-Object System.Drawing.Point(20,20)
    $textBoxNIF.Size = New-Object System.Drawing.Size(300,20)
    $textBoxNIF.Text = "Digite o NIF, Email ou Nome Completo"
    $form.Controls.Add($textBoxNIF)

    # Criar um botão para pesquisar
    $buttonPesquisar = New-Object System.Windows.Forms.Button
    $buttonPesquisar.Location = New-Object System.Drawing.Point(340,20)
    $buttonPesquisar.Size = New-Object System.Drawing.Size(75,23)
    $buttonPesquisar.Text = "Procurar"
    $form.Controls.Add($buttonPesquisar)

    # Criar um botão para copiar os resultados
    $buttonCopiar = New-Object System.Windows.Forms.Button
    $buttonCopiar.Location = New-Object System.Drawing.Point(420,20)
    $buttonCopiar.Size = New-Object System.Drawing.Size(75,23)
    $buttonCopiar.Text = "Copiar"
    $form.Controls.Add($buttonCopiar)

    # Criar um painel para exibir os resultados
    $panelResultados = New-Object System.Windows.Forms.Panel
    $panelResultados.Location = New-Object System.Drawing.Point(20,60)
    $panelResultados.Size = New-Object System.Drawing.Size(540,300)
    $panelResultados.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
    $panelResultados.AutoScroll = $true
    $form.Controls.Add($panelResultados)

    # Criar uma label para perguntar sobre a redefinição de senha
    $labelResetSenha = New-Object System.Windows.Forms.Label
    $labelResetSenha.Location = New-Object System.Drawing.Point(20,380)
    $labelResetSenha.Size = New-Object System.Drawing.Size(300,20)
    $labelResetSenha.Text = "Deseja resetar a senha dos NIFs encontrados?"
    $form.Controls.Add($labelResetSenha)

    # Criar um botão para redefinir a senha
    $buttonReset = New-Object System.Windows.Forms.Button
    $buttonReset.Location = New-Object System.Drawing.Point(340,380)
    $buttonReset.Size = New-Object System.Drawing.Size(75,23)
    $buttonReset.Text = "Resetar Senha"
    $form.Controls.Add($buttonReset)


    # Função para exibir os resultados no painel (apenas os campos preenchidos)
    function ExibirResultados {
        $panelResultados.Controls.Clear()
        $userInfo = $textBoxNIF.Text
        $Usuarios = ProcessNIF -nif $userInfo
        
        if ($Usuarios.Count -eq 0) {
            $resultLabel = New-Object System.Windows.Forms.Label
            $resultLabel.Text = "Nenhum usuário encontrado."
            $panelResultados.Controls.Add($resultLabel)
        } else {
            $yPosition = 0  # Para posicionar dinamicamente os resultados no painel
            foreach ($Usuario in $Usuarios) {
                $infoUsuario = @()

                if ($Usuario.SamAccountName) {
                    $infoUsuario += "NIF: $($Usuario.SamAccountName)"
                }
                if ($Usuario.DisplayName) {
                    $infoUsuario += "Nome completo: $($Usuario.DisplayName)"
                }
                if ($Usuario.Office) {
                    $infoUsuario += "Unidade: $($Usuario.Office)"
                }
                if ($Usuario.physicalDeliveryOfficeName) {
                    $infoUsuario += "Escritório: $($Usuario.physicalDeliveryOfficeName)"
                }
                if ($Usuario.Department) {
                    $infoUsuario += "Departamento: $($Usuario.Department)"
                }
                if ($Usuario.Manager -match "CN=([^,]+),") {
                    $infoUsuario += "Superior imediato: $($matches[1])"
                }
                if ($Usuario.Title) {
                    $infoUsuario += "Cargo: $($Usuario.Title)"
                }
                if ($Usuario.telephoneNumber) {
                    $infoUsuario += "Telefone: $($Usuario.telephoneNumber)"
                }
                if ($Usuario.EmailAddress) {
                    $infoUsuario += "E-mail: $($Usuario.EmailAddress)"
                }

                if ($infoUsuario.Count -gt 0) {
                    $userLabel = New-Object System.Windows.Forms.Label
                    $userLabel.Text = $infoUsuario -join "`n"
                    $userLabel.AutoSize = $true
                    $userLabel.Location = New-Object System.Drawing.Point(0, $yPosition)

                    $panelResultados.Controls.Add($userLabel)
                    # Atualizar a posição para o próximo resultado
                    $yPosition += $userLabel.Height + 10
                }
            }
        }
    }

    # Executar pesquisa ao clicar no botão "Procurar"
    $buttonPesquisar.Add_Click({
        ExibirResultados
    })

    # Adicionar evento de pressionar Enter na TextBox para pesquisar
    $textBoxNIF.Add_KeyDown({
        param($sender, $e)
        if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
            ExibirResultados
            $e.SuppressKeyPress = $true  # Evita o som do "bip" ao pressionar Enter
        }
    })

    # Função para redefinir a senha
    $buttonReset.Add_Click({
        $resetarSenha = [System.Windows.Forms.MessageBox]::Show("Deseja resetar a senha?", "Confirmação", [System.Windows.Forms.MessageBoxButtons]::YesNo)
        if ($resetarSenha -eq [System.Windows.Forms.DialogResult]::Yes) {
            foreach ($Usuario in $Usuarios) {
                if ($Usuario.SamAccountName) {
                    $novaSenha = ConvertTo-SecureString -AsPlainText "Sesisenaisp@24" -Force
                    Set-ADAccountPassword -Identity $Usuario.SamAccountName -NewPassword $novaSenha -Reset
                    Set-ADUser -Identity $Usuario.SamAccountName -ChangePasswordAtLogon $true
                    [System.Windows.Forms.MessageBox]::Show("Senha redefinida para: $($Usuario.DisplayName)")
                }
            }
        }
    })

    # Função para copiar o conteúdo do painel de resultados
    $buttonCopiar.Add_Click({
        $resultadoTexto = ""
        foreach ($control in $panelResultados.Controls) {
            if ($control.Text) {
                $resultadoTexto += $control.Text + "`n`n"
            }
        }

    })

    # Exibir a janela
    $form.ShowDialog()
}

# Função ProcessNIF adaptada para uso na interface GUI
function ProcessNIF {
    param($nif)
    $Usuarios = @()

    if ($nif -like "*@*") {
        $Usuarios = ExecuteScript -property "EmailAddress" -value $nif
    } elseif ($nif -match "\s") {
        $Usuarios = ExecuteScript -property "DisplayName" -value $nif
    } elseif ($nif -match "sn" -or $nif -match "ss") {
        $Usuarios = ExecuteScript -property "SamAccountName" -value $nif
    } elseif ($nif -match "^\d+$") {
        $nifWithSN = "SN" + $nif
        $nifWithSS = "SS" + $nif
        $nifWithTC = "TC" + $nif
        $Usuarios = @($Usuarios + (ExecuteScript -property "SamAccountName" -value $nifWithSN))
        $Usuarios = @($Usuarios + (ExecuteScript -property "SamAccountName" -value $nifWithSS))
        $Usuarios = @($Usuarios + (ExecuteScript -property "SamAccountName" -value $nifWithTC))
    } else {
        return @()
    }
    return $Usuarios
}

# Função para executar o script
function ExecuteScript {
    param($property, $value)
    $Usuarios = Get-ADUser -Filter {$property -eq $value} -Properties DisplayName, EmailAddress, SamAccountName, Office, Department, Title, telephoneNumber, Manager, physicalDeliveryOfficeName
    return $Usuarios
}

# Iniciar a GUI
Create-GUI
