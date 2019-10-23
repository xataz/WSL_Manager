$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
Set-Location $scriptDir

Add-Type -assembly System.Windows.Forms

function Hide_Powershell_Console {
    Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
    '
    $consolePtr = [Console.Window]::GetConsoleWindow()
    [Console.Window]::ShowWindow($consolePtr, 0)
}

function Check_Requirement($this, $check) {
    if (-not (Get-Command Expand-7Zip -ErrorAction Ignore)) {
        
        #Install-Package -Scope CurrentUser -Force 7Zip4PowerShell > $null
    } else {

    }
    if (-not (Get-Command docker -ErrorAction Ignore)) {
        #Install-Package -Scope CurrentUser -Force docker > $null
    } else {

    }
    Start-Sleep -Seconds 1
    $this.Text = "Check if $check is installed : Ok"
}

function Requirement_Form() {
    $check_form = New-Object System.Windows.Forms.Form
    $check_form.Text = "Check requirement"
    $check_form.ClientSize = New-Object System.Drawing.Size(300,200)

    $label_windows = New-Object System.Windows.Forms.Label
    $label_windows.Text = "Check if windows 10 is installed : Checking ..."
    $label_windows.AutoSize = $true
    $label_windows.Location = New-Object System.Drawing.Size(25,50)
    $label_wsl = New-Object System.Windows.Forms.Label
    $label_wsl.Text = "Check if wsl if installed : Checking ..."
    $label_wsl.AutoSize = $true
    $label_wsl.Location = New-Object System.Drawing.Size(25,100)
    $label_docker = New-Object System.Windows.Forms.Label
    $label_docker.Text = "Check if docker if installed : Checking ..."
    $label_docker.AutoSize = $true
    $label_docker.Location = New-Object System.Drawing.Size(25,150)

    

    $check_form.Controls.Add($label_windows)
    $check_form.Controls.Add($label_wsl)
    $check_form.Controls.Add($label_docker)



    $check_form.add_Shown({
        $check_form.Activate()
        Check_Requirement $label_windows "windows"
        Check_Requirement $label_wsl "wsl"
        Check_Requirement $label_docker "docker"     
    })

    $check_form.ShowDialog()

}


function error_form($error) {
    $errorForm = New-Object System.Windows.Forms.Form
    $errorForm.Text = "Error !"
    $errorForm.StartPosition = "CenterScreen"
    $errorForm.AutoSize = $True
    $errorForm.AutoSizeMode = "GrowOnly"
    $errorForm.Size = New-Object System.Drawing.Size(150,100)

    $errorFormErrorLabel = New-Object System.Windows.Forms.Label
    $errorFormErrorLabel.Location = New-Object System.Drawing.Size(10,10)
    $errorFormErrorLabel.AutoSize = $True
    $errorFormErrorLabel.MaximumSize = New-Object System.Drawing.Size(500,5000)
    $errorFormErrorLabel.Text = "$error"

    $errorForm.Controls.Add($errorFormErrorLabel)

    $errorForm.ShowDialog()
}

function Main_Form () {
    # Variables
    $version_distribution = @()

    # initialize main_form
    $main_form = New-Object System.Windows.Forms.Form
    $TabControl = New-object System.Windows.Forms.TabControl
    $tab_list_wsl = New-Object System.Windows.Forms.TabPage
    $tab_install_wsl = New-Object System.Windows.Forms.TabPage
    $tab_docker2wsl = New-Object System.Windows.Forms.TabPage
    $label_log = New-Object System.Windows.Forms.Label
    $textBox_log = New-Object System.Windows.Forms.TextBox
    $button_refresh = New-Object System.Windows.Forms.Button
    $button_require = New-Object System.Windows.Forms.Button
    $button_require.Text = "Check Requirement"
    $button_require.Anchor = "right","top"
    $button_require.Location = New-Object System.Drawing.Point(550,5)
    $button_require.Size = New-Object System.Drawing.Size(150,30)
    $main_form.Text ='WSL Manager'
    $main_form.ClientSize = New-Object System.Drawing.Size(725,600)

    # initialize TabControl
    $tabControl.Name = "tabControl"
    $tabControl.Location = New-Object System.Drawing.Point(25,25)
    $tabControl.Size = New-Object System.Drawing.Size(675,250)
    $tabControl.Anchor = "left","right", "top"
    
    # initialize textBox_log
    $textBox_log.Location = New-Object System.Drawing.Point(25,325)
    $textBox_log.Size = New-Object System.Drawing.Size(675,200)
    $textBox_log.Anchor = "left","right", "bottom", "top"
    $textBox_log.Scrollbars = "Vertical"
    $textBox_log.Multiline = $True
    $textBox_log.ReadOnly = $True
    $label_log.Location = New-Object System.Drawing.Point(25,300)
    $label_log.Text = "Logs :"
    $label_log.AutoSize = $True

    # initialize tab_list_wsl
    $tab_list_wsl.Text = "WSL list"
    
    $ListView_list = New-Object system.Windows.Forms.ListView
    $ListView_list.Location = New-Object System.Drawing.Point(25,25)
    $ListView_list.Size = New-Object System.Drawing.Size(600,150)
    $ListView_list.View = "Details"

    $Button_run = New-Object System.Windows.Forms.Button
    $Button_run.Anchor = "right", "bottom"
    $Button_run.Text = "Run"
    $Button_run.Location = New-Object System.Drawing.Point(100,70)
    
    # initialize tab_install_wsl
    $tab_install_wsl.Text = "Install WSL"
    $label_ComboBox_distribution = New-Object System.Windows.Forms.Label
    $label_ComboBox_distribution.Text = "Distribution : "
    $label_ComboBox_distribution.Location = New-Object System.Drawing.Point(25,25)
    $ComboBox_distribution = New-Object System.Windows.Forms.ComboBox
    $ComboBox_distribution.Location = New-Object System.Drawing.Point(125,23)

    $label_ComboBox_version = New-Object System.Windows.Forms.Label
    $label_ComboBox_version.Text = "Version : "
    $label_ComboBox_version.Location = New-Object System.Drawing.Point(275,25)
    $ComboBox_version = New-Object System.Windows.Forms.ComboBox
    $ComboBox_version.Location = New-Object System.Drawing.Point(375,23)

    $label_TextBox_name = New-Object System.Windows.Forms.Label
    $label_TextBox_name.Text = "Name : "
    $label_TextBox_name.Location = New-Object System.Drawing.Point(25,50)
    $TextBox_name = New-Object System.Windows.Forms.TextBox
    $TextBox_name.Location = New-Object System.Drawing.Point(125,48)
    
    $label_TextBox_username = New-Object System.Windows.Forms.Label
    $label_TextBox_username.Text = "Username : "
    $label_TextBox_username.Location = New-Object System.Drawing.Point(25,100)
    $TextBox_username = New-Object System.Windows.Forms.TextBox
    $TextBox_username.Location = New-Object System.Drawing.Point(125,98)

    $label_TextBox_password = New-Object System.Windows.Forms.Label
    $label_TextBox_password.Text = "Password : "
    $label_TextBox_password.Location = New-Object System.Drawing.Point(25,125)
    $TextBox_password = New-Object System.Windows.Forms.TextBox
    $TextBox_password.Location = New-Object System.Drawing.Point(125,123)
    $TextBox_password.PasswordChar = "*"

    $label_TextBox_password_retype = New-Object System.Windows.Forms.Label
    $label_TextBox_password_retype.Text = "Retype Password : "
    $label_TextBox_password_retype.Location = New-Object System.Drawing.Point(25,150)
    $TextBox_password_retype = New-Object System.Windows.Forms.TextBox
    $TextBox_password_retype.Location = New-Object System.Drawing.Point(125,148)
    $TextBox_password_retype.PasswordChar = "*"

    $Button_install = New-Object System.Windows.Forms.Button
    $Button_install.Anchor = "right", "bottom"
    $Button_install.Text = "Install"
    $Button_install.Location = New-Object System.Drawing.Point(100,70)

    foreach($distribution in Get-ChildItem -Path distribution | % {$_.BaseName}) {
        $ComboBox_distribution.items.Add($distribution)
    }
    

    # initialize tab_docker2wsl
    $tab_docker2wsl.Text = "docker2wsl"

    # tab_list_wsl Controls
    $tab_list_wsl.Controls.Add($ListView_list)
    $tab_list_wsl.Controls.Add($Button_run)


    # tab_install_wsl Controls
    $tab_install_wsl.Controls.Add($label_ComboBox_distribution)
    $tab_install_wsl.Controls.Add($ComboBox_distribution)
    $tab_install_wsl.Controls.Add($label_ComboBox_version)
    $tab_install_wsl.Controls.Add($ComboBox_version)
    $ComboBox_distribution.SelectedIndex = 0
    $tab_install_wsl.Controls.Add($label_TextBox_name)
    $tab_install_wsl.Controls.Add($TextBox_name)

    $tab_install_wsl.Controls.Add($label_TextBox_username)
    $tab_install_wsl.Controls.Add($TextBox_username)
    $tab_install_wsl.Controls.Add($label_TextBox_password)
    $tab_install_wsl.Controls.Add($TextBox_password)
    $tab_install_wsl.Controls.Add($label_TextBox_password_retype)
    $tab_install_wsl.Controls.Add($TextBox_password_retype)

    $tab_install_wsl.Controls.Add($Button_install)
    

    # tab_docker2wsl Controls

    # TabControl Controls
    $TabControl.Controls.Add($tab_list_wsl)
    $TabControl.Controls.Add($tab_install_wsl)
    $TabControl.Controls.Add($tab_docker2wsl)

    # main_form Controls
    $main_form.Controls.Add($button_require)
    $main_form.Controls.Add($tabControl)
    $main_form.Controls.Add($textBox_log)
    $main_form.Controls.Add($label_log)


    $button_require.add_click({
        Requirement_Form
    })

    $Button_install.add_click({
        $distribution = $ComboBox_distribution.SelectedItem
        $version = $ComboBox_version.SelectedItem
        $name = $TextBox_name.Text
        $username = $TextBox_username.Text
        $password = $TextBox_password.Text
        $password_retype = $TextBox_password_retype.Text
        $location = "D:\WslDistro\"


        if (($distribution) -and ($version) -and ($name) -and ($username) -and ($password) -and ($password_retype)) {
            if (( $password -eq $password_retype )) {
                . distribution\$distribution.ps1

                prepare $version | foreach {
                    $textBox_log.AppendText("$_`r`n")
                }
                install $name $location $username $password | foreach {
                    $textBox_log.AppendText("$_`r`n")
                }
                clean $name | foreach {
                    $textBox_log.AppendText("$_`r`n")
                }

                Remove-Variable versions
                Remove-Item -Path Function:prepare
                Remove-Item -Path Function:install
                Remove-Item -Path Function:clean

                $textBox_log.AppendText("`r`n$name created`n")
            } else {
                error_form "Passwords doesn't match"
            }
        } else {
            error_form "Missing parameters"
        }
    })

    $Button_run.add_click({
        $name = [string]$ListView_list.SelectedItems
        error_form $name
    })

    $ComboBox_distribution.Add_SelectedIndexChanged({
        $ComboBox_version.items.Clear()
        $distribution = $ComboBox_distribution.SelectedItem
        . distribution\$distribution.ps1

        foreach($version in $versions) {
            $ComboBox_version.items.Add($version)
        }

        $ComboBox_version.SelectedIndex = 0
        Remove-Variable versions
        Remove-Item -Path Function:prepare
        Remove-Item -Path Function:install
        Remove-Item -Path Function:clean
    })

    $main_form.Add_Shown({
        $main_form.Activate()

        $ComboBox_version.items.Clear()
        $distribution = $ComboBox_distribution.SelectedItem
        . distribution\$distribution.ps1

        foreach($version in $versions) {
            $ComboBox_version.items.Add($version)
        }

        $ComboBox_version.SelectedIndex = 0
        Remove-Variable versions
        Remove-Item -Path Function:prepare
        Remove-Item -Path Function:install
        Remove-Item -Path Function:clean

        $ListView_list.Columns.Add("Name")
        $ListView_list.Columns.Add("Distribution")
        
        $itemname = New-Object System.Windows.Forms.ListViewItem("Debian")
        $itemname.SubItems.Add("Debian 10 (buster)")
        $ListView_list.Items.Add($itemname)
        $ListView_list.AutoResizeColumns(2)


    })
    # Show window
    $main_form.ShowDialog()
}


Hide_Powershell_Console
Main_Form