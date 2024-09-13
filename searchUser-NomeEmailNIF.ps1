# Importar o módulo do Active Directory
Import-Module ActiveDirectory

# Criar a função de interface GUI
function Create-GUI {
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

    # Janela principal (form)
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Pesquisa de Usuários AD"
    $form.Size = New-Object System.Drawing.Size(360,500) #340 de largura total
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $form.MaximizeBox = $false  # Desabilitar o botão de maximizar
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

    # TextBox para entrada de NIF, Email ou Nome Completo
    $textBoxNIF = New-Object System.Windows.Forms.TextBox
    $textBoxNIF.Location = New-Object System.Drawing.Point(20,20) # 20p depois da borda
    $textBoxNIF.Size = New-Object System.Drawing.Size(310,20) # 300p de largura
    $textBoxNIF.Text = "Digite o NIF, Email ou Nome Completo"
    $form.Controls.Add($textBoxNIF)

    # Painel para exibir os resultados
    $panelResultados = New-Object System.Windows.Forms.TextBox
    $panelResultados.Location = New-Object System.Drawing.Point(20,60)
    $panelResultados.Size = New-Object System.Drawing.Size(310,300)  # Ajustado até o botão de copiar
    $panelResultados.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D

    $panelResultados.ReadOnly = $true         # Tornar a caixa de texto somente leitura, mas ainda copiável
    $panelResultados.Multiline = $true        # Permite múltiplas linhas
    $form.Controls.Add($panelResultados)

        # Label para perguntar sobre copiar o painel
        $labelResetSenha = New-Object System.Windows.Forms.Label
        $labelResetSenha.Location = New-Object System.Drawing.Point(20,380)
        $labelResetSenha.Size = New-Object System.Drawing.Size(210,15)
        $labelResetSenha.Text = "Copiar as informações no painel?"
        $form.Controls.Add($labelResetSenha)

    # Botão para copiar os resultados
    $buttonCopiar = New-Object System.Windows.Forms.Button
    $buttonCopiar.Location = New-Object System.Drawing.Point(235,375)
    $buttonCopiar.Size = New-Object System.Drawing.Size(75,20) # largura / altura
    $buttonCopiar.Text = "Copiar"
    $form.Controls.Add($buttonCopiar)

        # Label para perguntar sobre a redefinição de senha
        $labelResetSenha = New-Object System.Windows.Forms.Label
        $labelResetSenha.Location = New-Object System.Drawing.Point(20,400)
        $labelResetSenha.Size = New-Object System.Drawing.Size(210,15)
        $labelResetSenha.Text = "Resetar a senha dos NIFs encontrados?"
        $form.Controls.Add($labelResetSenha)

    # Botão para redefinir a senha
    $buttonReset = New-Object System.Windows.Forms.Button
    $buttonReset.Location = New-Object System.Drawing.Point(235,400)
    $buttonReset.Size = New-Object System.Drawing.Size(75,20)
    $buttonReset.Text = "Reset"
    $form.Controls.Add($buttonReset)



    # Função para exibir os resultados no painel (como TextBox de múltiplas linhas)
function ExibirResultados {
    $panelResultados.Clear()
    $userInfo = $textBoxNIF.Text
    $global:Usuarios = ProcessNIF -nif $userInfo

    if ($global:Usuarios.Count -eq 0) {
        $panelResultados.Text = "Nenhum usuário encontrado."
    } else {
        $infoUsuarios = @()
        foreach ($Usuario in $global:Usuarios) {
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
                $infoUsuarios += ($infoUsuario -join "`r`n`r")
            }
        }
        # Exibir todos os resultados na TextBox
        $panelResultados.Text = $infoUsuarios -join "`n`n"  # Adicionar espaço entre os usuários
    }
}


    # Adicionar evento de pressionar Enter na TextBox para pesquisar
    $textBoxNIF.Add_KeyDown({
        param($sender, $e)
        if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
            ExibirResultados
            $e.SuppressKeyPress = $true  # Evita o som do "bip" ao pressionar Enter
        }
    })

    # Função para redefinir a senha com mensagem de confirmação
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
        [System.Windows.Forms.Clipboard]::SetText($resultadoTexto)  # Função de copiar 
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
    } elseif ($nif -match "sn" -or $nif -match "ss" -or $nif -match "tc") {
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
