$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
Set-Location $scriptDir

$xmlTemplate = @"
<parameters>
    <WSL>
        <Location></Location>
        <DefaultVersion></DefaultVersion>
    </WSL>
</parameters>
"@


$ParametersFile = "$scriptDir\WSLManager.xml"

if (!(Test-Path $ParametersFile)) {
    $xmlTemplate | out-file $ParametersFile
    [xml]$Parameters = Get-Content -Encoding UTF8 $ParametersFile
    $Parameters.parameters.WSL.Location = "$env:USERPROFILE\WSL"
    $Parameters.parameters.WSL.DefaultVersion = "1"
    $Parameters.Save($ParametersFile)
} else {
    [xml]$Parameters = Get-Content -Encoding UTF8 $ParametersFile
}


Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()


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

function Check_If_WSL {
    if (!(Get-Command -Name wsl -ErrorAction Ignore)) {
        error_form "WSL isn't installed"
    }
}

function InstallFromDocker($name, $image) {
    $location = $Parameters.parameters.WSL.Location

    write-host "Downloading docker image"
    docker pull $image
    write-host "Creating temp docker container"
    docker container create --name TmpWSL $image
    write-host "Creating tarball"
    docker container export -o $env:TMP\$name.tar.gz TmpWSL
    write-host "Creating WSL Distribution"
    wsl --import $name $location $env:TMP\$name.tar.gz
    write-host "Cleaning"
    docker container rm -f TmpWSL
    Remove-Item $env:TMP\$name.tar.gz


}

function refresh_List($List_WSL) {
    $List_WSL.Clear()
    $List_WSL.Columns.Add("Name")
    $List_WSL.Columns.Add("Status")
    $List_WSL.Columns.Add("WSL Version")
    

    $ListDistri = (wsl --list --verbose) | select -Skip 1 | foreach {
        if ($_.Length -ne 1) {
            $distriName = ""
            [int[]][char[]]$_ | foreach {
                if ( $_ -ne 0 ) {
                    $distriName += [char]$_
                }
            }
            $distriName
        } 
    } | ConvertFrom-String

    foreach ($distri in $ListDistri) {
        $itemname = New-Object System.Windows.Forms.ListViewItem($distri.p2)
        $itemname.SubItems.Add($distri.p3)
        $itemname.SubItems.Add($distri.p4)
        $List_WSL.Items.Add($itemname)
        $List_WSL.AutoResizeColumns(2)
    }
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
    $errorFormErrorLabel.MinimumSize = New-Object System.Drawing.Size(200,50)
    $errorFormErrorLabel.AutoSize = $True
    $errorFormErrorLabel.MaximumSize = New-Object System.Drawing.Size(500,5000)
    $errorFormErrorLabel.Text = "$error"

    $errorForm.Controls.Add($errorFormErrorLabel)

    $errorForm.ShowDialog()
}



## About FORM
$licence = @"
MIT License

Copyright (c) 2019 xataz

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

"@

$aboutForm                       = New-Object system.Windows.Forms.Form
$aboutForm.ClientSize            = '400,400'
$aboutForm.text                  = "Form"
$aboutForm.TopMost               = $false
$aboutForm.text                  = "WSL Manager - About"

$textboxLicence                  = New-Object system.Windows.Forms.TextBox
$textboxLicence.multiline        = $true
$textboxLicence.ReadOnly         = $true
$textboxLicence.width            = 360
$textboxLicence.height           = 304
$textboxLicence.location         = New-Object System.Drawing.Point(20,81)
$textboxLicence.Font             = 'Microsoft Sans Serif,10'
$textboxLicence.Text             = $licence
$textboxLicence.Scrollbars       = "Vertical" 

$labelTitle                      = New-Object system.Windows.Forms.Label
$labelTitle.text                 = "WSL Manager"
$labelTitle.AutoSize             = $true
$labelTitle.width                = 25
$labelTitle.height               = 10
$labelTitle.location             = New-Object System.Drawing.Point(104,30)
$labelTitle.Font                 = 'Microsoft Sans Serif,20'

$aboutForm.controls.AddRange(@($textboxLicence,$labelTitle))


## Main FORM
$main_form                       = New-Object system.Windows.Forms.Form
$main_form.ClientSize            = '725,600'
$main_form.text                  = "WSL Manager"
$main_form.BackColor             = "#575555"
$main_form.TopMost               = $false

$List_WSL                        = New-Object system.Windows.Forms.ListView
$List_WSL.text                   = "List_WSL"
$List_WSL.width                  = 325
$List_WSL.height                 = 250
$List_WSL.Margin                 = 0
$List_WSL.Anchor                 = 'top, bottom,left'
$List_WSL.BackColor              = "#575555"
$List_WSL.location               = New-Object System.Drawing.Point(0,25)
$List_WSL.View                   = "Details"

$InfoGroup                       = New-Object system.Windows.Forms.Groupbox
$InfoGroup.text                  = "Information"
$InfoGroup.height                = 250
$InfoGroup.width                 = 385
$InfoGroup.Anchor                = 'top,right,bottom'
$InfoGroup.location              = New-Object System.Drawing.Point(330,25)
$InfoGroup.BackColor             = "#575555"

$buttonStart                      = New-Object system.Windows.Forms.Button
$buttonStart.text                 = "Start"
$buttonStart.width                = 60
$buttonStart.height               = 30
$buttonStart.location             = New-Object System.Drawing.Point(666,359)
$buttonStart.Font                 = 'Microsoft Sans Serif,10'
$buttonStart.Enabled              = $False

$buttonDelete                      = New-Object system.Windows.Forms.Button
$buttonDelete.text                 = "Delete"
$buttonDelete.width                = 60
$buttonDelete.height               = 30
$buttonDelete.location             = New-Object System.Drawing.Point(666,359)
$buttonDelete.Font                 = 'Microsoft Sans Serif,10'
$buttonDelete.Enabled              = $False

$menuMain                        = New-Object System.Windows.Forms.MenuStrip
$menuMain.Margin                 = 0

$submenuInstallSrc               = New-Object System.Windows.Forms.ToolStripMenuItem
$submenuInstallSrc.Text          = "Install from source"

$submenuInstallDocker            = New-Object System.Windows.Forms.ToolStripMenuItem
$submenuInstallDocker.Text       = "Install from docker"

$submenuSettings                 = New-Object System.Windows.Forms.ToolStripMenuItem
$submenuSettings.Text            = "Settings"

$submenuExit                     = New-Object System.Windows.Forms.ToolStripMenuItem
$submenuExit.Text                = "Exit"

$menuTools                       = New-Object System.Windows.Forms.ToolStripMenuItem
$menuTools.Text                  = "Tools"

$menuHelp                        = New-Object System.Windows.Forms.ToolStripMenuItem
$menuHelp.Text                   = "?"

$submenuAbout                    = New-Object System.Windows.Forms.ToolStripMenuItem
$submenuAbout.Text               = "About"

$main_form.controls.AddRange(@($List_WSL,$menuMain,$InfoGroup))
$menuMain.Items.AddRange(@($menuTools,$menuHelp))
$menuTools.DropDownItems.AddRange(@($submenuInstallSrc,$submenuInstallDocker,$submenuSettings,$submenuExit))
$menuHelp.DropDownItems.AddRange(@($submenuAbout))

## Console FORM docker
$consoleFormDocker                     = New-Object system.Windows.Forms.Form
$consoleFormDocker.ClientSize          = '750,400'
$consoleFormDocker.text                = "WSL Manager - Console"
$consoleFormDocker.TopMost             = $false
$consoleFormDocker.BackColor             = "#575555"

$textboxConsoleDocker                  = New-Object system.Windows.Forms.TextBox
$textboxConsoleDocker.multiline        = $true
$textboxConsoleDocker.ReadOnly         = $true
$textboxConsoleDocker.Scrollbars       = 'Vertical'
$textboxConsoleDocker.width            = 725
$textboxConsoleDocker.height           = 330
$textboxConsoleDocker.Anchor           = 'top,right,bottom,left'
$textboxConsoleDocker.location         = New-Object System.Drawing.Point(12,15)
$textboxConsoleDocker.Font             = 'Microsoft Sans Serif,10'

$buttonDoneDocker                      = New-Object system.Windows.Forms.Button
$buttonDoneDocker.text                 = "Done"
$buttonDoneDocker.width                = 60
$buttonDoneDocker.height               = 30
$buttonDoneDocker.location             = New-Object System.Drawing.Point(666,359)
$buttonDoneDocker.Font                 = 'Microsoft Sans Serif,10'
$buttonDoneDocker.Enabled              = $False

$consoleFormDocker.controls.AddRange(@($textboxConsoleDocker,$buttonDoneDocker))

## Console FORM src
$consoleFormSrc                     = New-Object system.Windows.Forms.Form
$consoleFormSrc.ClientSize          = '750,400'
$consoleFormSrc.text                = "WSL Manager - Console"
$consoleFormSrc.TopMost             = $false
$consoleFormSrc.BackColor             = "#575555"

$textboxConsoleSrc                  = New-Object system.Windows.Forms.TextBox
$textboxConsoleSrc.multiline        = $true
$textboxConsoleSrc.ReadOnly         = $true
$textboxConsoleSrc.Scrollbars       = 'Vertical'
$textboxConsoleSrc.width            = 725
$textboxConsoleSrc.height           = 330
$textboxConsoleSrc.Anchor           = 'top,right,bottom,left'
$textboxConsoleSrc.location         = New-Object System.Drawing.Point(12,15)
$textboxConsoleSrc.Font             = 'Microsoft Sans Serif,10'

$buttonDoneSrc                      = New-Object system.Windows.Forms.Button
$buttonDoneSrc.text                 = "Done"
$buttonDoneSrc.width                = 60
$buttonDoneSrc.height               = 30
$buttonDoneSrc.location             = New-Object System.Drawing.Point(666,359)
$buttonDoneSrc.Font                 = 'Microsoft Sans Serif,10'
$buttonDoneSrc.Enabled              = $False

$consoleFormSrc.controls.AddRange(@($textboxConsoleSrc,$buttonDoneSrc))

## Console FORM
$consoleForm                     = New-Object system.Windows.Forms.Form
$consoleForm.ClientSize          = '750,400'
$consoleForm.text                = "WSL Manager - Console"
$consoleForm.TopMost             = $false
$consoleForm.BackColor             = "#575555"

$textboxConsole                  = New-Object system.Windows.Forms.TextBox
$textboxConsole.multiline        = $true
$textboxConsole.ReadOnly         = $true
$textboxConsole.Scrollbars       = 'Vertical'
$textboxConsole.width            = 725
$textboxConsole.height           = 330
$textboxConsole.Anchor           = 'top,right,bottom,left'
$textboxConsole.location         = New-Object System.Drawing.Point(12,15)
$textboxConsole.Font             = 'Microsoft Sans Serif,10'

$buttonDone                      = New-Object system.Windows.Forms.Button
$buttonDone.text                 = "Done"
$buttonDone.width                = 60
$buttonDone.height               = 30
$buttonDone.location             = New-Object System.Drawing.Point(666,359)
$buttonDone.Font                 = 'Microsoft Sans Serif,10'
$buttonDone.Enabled              = $False

$consoleForm.controls.AddRange(@($textboxConsole,$buttonDone))


## Settings FORM
$settingsForm                    = New-Object system.Windows.Forms.Form
$settingsForm.ClientSize         = '400,400'
$settingsForm.text               = "WSL Manager - Settings"
$settingsForm.TopMost            = $false
$settingsForm.BackColor          = "#575555"

$labelPathWSL                    = New-Object system.Windows.Forms.Label
$labelPathWSL.text               = "WSL Path :"
$labelPathWSL.AutoSize           = $true
$labelPathWSL.width              = 25
$labelPathWSL.height             = 10
$labelPathWSL.location           = New-Object System.Drawing.Point(22,29)
$labelPathWSL.Font               = 'Microsoft Sans Serif,10'

$labelWSLVersion                 = New-Object system.Windows.Forms.Label
$labelWSLVersion.text            = "WSL Version :"
$labelWSLVersion.AutoSize        = $true
$labelWSLVersion.width           = 25
$labelWSLVersion.height          = 10
$labelWSLVersion.location        = New-Object System.Drawing.Point(22,69)
$labelWSLVersion.Font            = 'Microsoft Sans Serif,10'

$buttonCancel                    = New-Object system.Windows.Forms.Button
$buttonCancel.text               = "Cancel"
$buttonCancel.width              = 60
$buttonCancel.height             = 30
$buttonCancel.location           = New-Object System.Drawing.Point(322,358)
$buttonCancel.Font               = 'Microsoft Sans Serif,10'

$buttonSave                      = New-Object system.Windows.Forms.Button
$buttonSave.text                 = "Save"
$buttonSave.width                = 60
$buttonSave.height               = 30
$buttonSave.location             = New-Object System.Drawing.Point(245,358)
$buttonSave.Font                 = 'Microsoft Sans Serif,10'

$textboxPathWSL                  = New-Object system.Windows.Forms.TextBox
$textboxPathWSL.multiline        = $false
$textboxPathWSL.width            = 100
$textboxPathWSL.height           = 20
$textboxPathWSL.location         = New-Object System.Drawing.Point(120,26)
$textboxPathWSL.Font             = 'Microsoft Sans Serif,10'
$textboxPathWSL.Text             = $Parameters.parameters.WSL.Location

$comboboxWSLVersion              = New-Object system.Windows.Forms.ComboBox
$comboboxWSLVersion.width        = 100
$comboboxWSLVersion.height       = 20
$comboboxWSLVersion.location     = New-Object System.Drawing.Point(120,67)
$comboboxWSLVersion.Font         = 'Microsoft Sans Serif,10'

$settingsForm.controls.AddRange(@($labelPathWSL,$labelWSLVersion,$buttonCancel,$buttonSave,$textboxPathWSL,$comboboxWSLVersion))

## InstallFromDocker FORM
$InstallFromDocker_form             = New-Object system.Windows.Forms.Form
$InstallFromDocker_form.ClientSize  = '200,200'
$InstallFromDocker_form.text        = "WSL Manager - Install From Sources"
$InstallFromDocker_form.BackColor   = "#575555"
$InstallFromDocker_form.TopMost     = $false

$labelNameDocker                    = New-Object system.Windows.Forms.Label
$labelNameDocker.text               = "Name :"
$labelNameDocker.AutoSize           = $true
$labelNameDocker.width              = 25
$labelNameDocker.height             = 10
$labelNameDocker.location           = New-Object System.Drawing.Point(20,21)
$labelNameDocker.Font               = 'Microsoft Sans Serif,10'

$textboxNameDocker                  = New-Object system.Windows.Forms.TextBox
$textboxNameDocker.multiline        = $false
$textboxNameDocker.width            = 100
$textboxNameDocker.height           = 20
$textboxNameDocker.location         = New-Object System.Drawing.Point(91,18)
$textboxNameDocker.Font             = 'Microsoft Sans Serif,10'

$labelImageDocker                    = New-Object system.Windows.Forms.Label
$labelImageDocker.text               = "Image :"
$labelImageDocker.AutoSize           = $true
$labelImageDocker.width              = 25
$labelImageDocker.height             = 10
$labelImageDocker.location           = New-Object System.Drawing.Point(20,61)
$labelImageDocker.Font               = 'Microsoft Sans Serif,10'

$textboxImageDocker                  = New-Object system.Windows.Forms.TextBox
$textboxImageDocker.multiline        = $false
$textboxImageDocker.width            = 100
$textboxImageDocker.height           = 20
$textboxImageDocker.location         = New-Object System.Drawing.Point(91,58)
$textboxImageDocker.Font             = 'Microsoft Sans Serif,10'

$button_InstallDocker               = New-Object system.Windows.Forms.Button
$button_InstallDocker.text          = "Install"
$button_InstallDocker.width         = 90
$button_InstallDocker.height        = 30
$button_InstallDocker.anchor        = 'bottom,left'
$button_InstallDocker.location      = New-Object System.Drawing.Point(15,101)
$button_InstallDocker.Font          = 'Microsoft Sans Serif,10'

$InstallFromDocker_form.controls.AddRange(@($labelNameDocker, $textboxNameDocker, $labelImageDocker, $textboxImageDocker, $button_InstallDocker))


## InstallFromSrc FORM
$InstallFromSrc_form             = New-Object system.Windows.Forms.Form
$InstallFromSrc_form.ClientSize  = '725,600'
$InstallFromSrc_form.text        = "WSL Manager - Install From Sources"
$InstallFromSrc_form.BackColor   = "#575555"
$InstallFromSrc_form.TopMost     = $false

$groupDescription                = New-Object system.Windows.Forms.Groupbox
$groupDescription.height         = 575
$groupDescription.width          = 290
$groupDescription.BackColor      = "#575555"
$groupDescription.Anchor         = 'top,right,bottom'
$groupDescription.text           = "Description"
$groupDescription.location       = New-Object System.Drawing.Point(428,10)

$IconDistribution                = New-Object system.Windows.Forms.PictureBox
$IconDistribution.width          = 166
$IconDistribution.height         = 144
$IconDistribution.location       = New-Object System.Drawing.Point(65,21)
$IconDistribution.imageLocation  = ""
$IconDistribution.SizeMode       = [System.Windows.Forms.PictureBoxSizeMode]::zoom

$DescribeText                    = New-Object system.Windows.Forms.TextBox
$DescribeText.multiline          = $true
$DescribeText.enabled            = $true
$DescribeText.ReadOnly           = $true
$DescribeText.width              = 256
$DescribeText.height             = 382
$DescribeText.anchor             = 'top,left,bottom,right'
$DescribeText.location           = New-Object System.Drawing.Point(20,184)
$DescribeText.Font               = 'Microsoft Sans Serif,10'
$DescribeText.Scrollbars         = "Vertical" 

$ListDistrib                     = New-Object system.Windows.Forms.ListView
$ListDistrib.text                = "listView"
$ListDistrib.BackColor           = "#575555"
$ListDistrib.anchor              = 'top,right,left'
$ListDistrib.width               = 400
$ListDistrib.height              = 300
$ListDistrib.location            = New-Object System.Drawing.Point(15,10)
$ListDistrib.View                = "Details"

$groupParam                      = New-Object system.Windows.Forms.Groupbox
$groupParam.height               = 200
$groupParam.width                = 400
$groupParam.BackColor            = "#575555"
$groupParam.Anchor               = 'top,right,bottom'
$groupParam.text                 = "Parameters"
$groupParam.location             = New-Object System.Drawing.Point(15,320)

$labelName                       = New-Object system.Windows.Forms.Label
$labelName.text                  = "Name :"
$labelName.AutoSize              = $true
$labelName.width                 = 25
$labelName.height                = 10
$labelName.location              = New-Object System.Drawing.Point(20,21)
$labelName.Font                  = 'Microsoft Sans Serif,10'

$textboxName                     = New-Object system.Windows.Forms.TextBox
$textboxName.multiline           = $false
$textboxName.width               = 100
$textboxName.height              = 20
$textboxName.location            = New-Object System.Drawing.Point(91,18)
$textboxName.Font                = 'Microsoft Sans Serif,10'

$labelVersion                    = New-Object system.Windows.Forms.Label
$labelVersion.text               = "Version :"
$labelVersion.AutoSize           = $true
$labelVersion.width              = 25
$labelVersion.height             = 10
$labelVersion.location           = New-Object System.Drawing.Point(200,21)
$labelVersion.Font               = 'Microsoft Sans Serif,10'

$comboboxVersion                 = New-Object system.Windows.Forms.ComboBox
$comboboxVersion.width           = 100
$comboboxVersion.height          = 20
$comboboxVersion.location        = New-Object System.Drawing.Point(270,18)
$comboboxVersion.Font            = 'Microsoft Sans Serif,10'

$labelUsername                   = New-Object system.Windows.Forms.Label
$labelUsername.text              = "Username :"
$labelUsername.AutoSize          = $true
$labelUsername.width             = 25
$labelUsername.height            = 10
$labelUsername.location          = New-Object System.Drawing.Point(20,71)
$labelUsername.Font              = 'Microsoft Sans Serif,10'

$textboxUsername                 = New-Object system.Windows.Forms.TextBox
$textboxUsername.multiline       = $false
$textboxUsername.width           = 100
$textboxUsername.height          = 20
$textboxUsername.location        = New-Object System.Drawing.Point(150,68)
$textboxUsername.Font            = 'Microsoft Sans Serif,10'

$labelPassword                   = New-Object system.Windows.Forms.Label
$labelPassword.text              = "Password :"
$labelPassword.AutoSize          = $true
$labelPassword.width             = 25
$labelPassword.height            = 10
$labelPassword.location          = New-Object System.Drawing.Point(20,111)
$labelPassword.Font              = 'Microsoft Sans Serif,10'

$textboxPassword                 = New-Object system.Windows.Forms.TextBox
$textboxPassword.multiline       = $false
$textboxPassword.width           = 100
$textboxPassword.height          = 20
$textboxPassword.location        = New-Object System.Drawing.Point(150,108)
$textboxPassword.Font            = 'Microsoft Sans Serif,10'
$textboxPassword.PasswordChar    = '*'

$labelPasswordRetype             = New-Object system.Windows.Forms.Label
$labelPasswordRetype.text        = "Retype Password :"
$labelPasswordRetype.AutoSize    = $true
$labelPasswordRetype.width       = 25
$labelPasswordRetype.height      = 10
$labelPasswordRetype.location    = New-Object System.Drawing.Point(20,151)
$labelPasswordRetype.Font        = 'Microsoft Sans Serif,10'

$textboxPasswordRetype           = New-Object system.Windows.Forms.TextBox
$textboxPasswordRetype.multiline  = $false
$textboxPasswordRetype.width     = 100
$textboxPasswordRetype.height    = 20
$textboxPasswordRetype.location  = New-Object System.Drawing.Point(150,148)
$textboxPasswordRetype.Font      = 'Microsoft Sans Serif,10'
$textboxPasswordRetype.PasswordChar = '*'

$button_InstallSrc               = New-Object system.Windows.Forms.Button
$button_InstallSrc.text          = "Install"
$button_InstallSrc.width         = 90
$button_InstallSrc.height        = 30
$button_InstallSrc.anchor        = 'bottom,left'
$button_InstallSrc.location      = New-Object System.Drawing.Point(15,550)
$button_InstallSrc.Font          = 'Microsoft Sans Serif,10'

$InstallFromSrc_form.controls.AddRange(@($groupDescription,$ListDistrib,$button_InstallSrc, $groupParam))
$groupDescription.controls.AddRange(@($IconDistribution,$DescribeText))
$groupParam.controls.AddRange(@($labelName,$textboxName,$labelVersion,$comboboxVersion,$labelUsername,$textboxUsername,$labelPassword,$textboxPassword,$labelPasswordRetype,$textboxPasswordRetype))
    
    
    
$InstallFromSrc_form.Add_Shown({
    $ListDistrib.Items.clear()

    $ListDistrib.Columns.Add("Distribution")
    
    foreach($distribution in Get-ChildItem -Path distribution | % {$_.BaseName}) {
        $ListDistrib.Items.Add($distribution)
        $ListDistrib.AutoResizeColumns(2)
    }
    
})
$ListDistrib.Add_Click({
    $IconDistribution.imageLocation = ""
    $DescribeText.Clear()
    $comboboxVersion.items.Clear()
    $comboboxVersion.Text = ""
    $distribution = $ListDistrib.SelectedItems.text
    . "distribution\$distribution.ps1"

    foreach($version in $versions) {
        $comboboxVersion.items.Add($version)
    }

    $IconDistribution.imageLocation = "$scriptDir\$logo"
    $DescribeText.Text = $summary
    $comboboxVersion.SelectedIndex = 0
})

$consoleFormSrc.Add_Shown({
    #$consoleForm.Activate()
    $name = $textboxName.Text
    $version = $comboboxVersion.SelectedItem
    $location = $Parameters.parameters.WSL.Location
    $username = $textboxUsername.Text
    $password = $textboxPassword.Text
    $passwordRetype = $textboxPasswordRetype.Text

    $buttonDoneSrc.Enabled = $False
    $textboxConsoleSrc.Clear()
    setup $name $version $username $password $location | foreach {
        $textboxConsoleSrc.AppendText("$_`r`n")
    }
    $buttonDoneSrc.Enabled = $True
                
})

$consoleFormDocker.Add_Shown({
    #$consoleForm.Activate()
    $name = $textboxNameDocker.Text
    $image = $textboxImageDocker.Text

    $buttonDoneDocker.Enabled = $False
    $textboxConsoleDocker.Clear()
        InstallFromDocker $name $image | foreach {
            $textboxConsoleDocker.AppendText("$_`r`n")
        }

    $buttonDoneDocker.Enabled = $True
})

$button_InstallSrc.Add_Click({
    $name = $textboxName.Text
    $version = $comboboxVersion.SelectedItem
    $location = $Parameters.parameters.WSL.Location
    $username = $textboxUsername.Text
    $password = $textboxPassword.Text
    $passwordRetype = $textboxPasswordRetype.Text

    if ($password -eq $passwordRetype) {
        $distribution = $ListDistrib.SelectedItems.text
        . "distribution\$distribution.ps1"          
            
        $consoleFormSrc.ShowDialog()

        if (Get-Variable versions) {
            Remove-Variable versions
        }
        if (Get-Item -Path Function:setup) {
            Remove-Item -Path Function:setup
        }
    } else {
        error_form "Password doesn't match"
    }
})

$InstallFromSrc_form.Add_Closed({
    refresh_List $List_WSL
})

$InstallFromDocker_form.Add_Closed({
    refresh_List $List_WSL
})
   
$settingsForm.Add_Shown({
    if ( [int](Get-WmiObject Win32_OperatingSystem).BuildNumber -le 18917) {
        $comboboxWSLVersion.items.Add("1")
    } else {
        $comboboxWSLVersion.items.AddRange(@("1","2"))
    }
    
    if ($Parameters.parameters.WSL.DefaultVersion -eq "1") {
        $comboboxWSLVersion.SelectedIndex = 0
    } elseif ($Parameters.parameters.WSL.DefaultVersion -eq "2") {
        $comboboxWSLVersion.SelectedIndex = 1
    }
})

$buttonCancel.Add_Click({
    $settingsForm.Close()
})

$buttonSave.Add_Click({
    $Parameters.parameters.WSL.DefaultVersion = $comboboxWSLVersion.SelectedItem
    $Parameters.parameters.WSL.Location = $textboxPathWSL.Text
    $Parameters.Save($ParametersFile)
    $settingsForm.Close()
})   


$List_WSL.Add_DoubleClick({ 
    $Distri = $List_WSL.SelectedItems.Text
    $ProcessDistro = Start-Process -FilePath wsl.exe -ArgumentList "-d $Distri" -PassThru

    $EventProcess = Register-ObjectEvent -InputEvent $ProcessDistro -EventName exited -Action {
        refresh_List $List_WSL
        Unregister-Event -SubscriptionId $EventProcess.ID
    }
    
    Start-Sleep -s 2
    refresh_List $List_WSL
    $ProcessDistro.Add_Exited({
        refresh_List $List_WSL
    })
})

$List_WSL.Add_Click({
    $name = $List_WSL.SelectedItems.Text
    $size = (wsl.exe -d $name du -hsx /).split()[0]
    $distributionName = (wsl.exe -d $name grep PRETTY_NAME /etc/os-release).split("=")[1] -replace '"',''
    $usersList = (wsl -d $name awk -F ":" '{if ($3 >= 1000 && $3 <= 60000) { print $1 }}' /etc/passwd)

})

$main_form.Add_Shown({ 
    $List_WSL.Columns.Add("Name")
    $List_WSL.Columns.Add("Status")
    $List_WSL.Columns.Add("WSL Version")
    

    $ListDistri = (wsl --list --verbose) | select -Skip 1 | foreach {
        if ($_.Length -ne 1) {
            $distriName = ""
            [int[]][char[]]$_ | foreach {
                if ( $_ -ne 0 ) {
                    $distriName += [char]$_
                }
            }
            $distriName
        } 
    } | ConvertFrom-String

    foreach ($distri in $ListDistri) {
        $itemname = New-Object System.Windows.Forms.ListViewItem($distri.p2)
        $itemname.SubItems.Add($distri.p3)
        $itemname.SubItems.Add($distri.p4)
        $List_WSL.Items.Add($itemname)
        $List_WSL.AutoResizeColumns(2)
    }

})

$button_InstallDocker.Add_Click({
    $name = $textboxNameDocker.Text
    $image = $textboxImageDocker.Text

    $consoleFormDocker.ShowDialog()
            
})



$submenuInstallSrc.Add_Click({
    $InstallFromSrc_form.ShowDialog()
})

$submenuInstallDocker.Add_Click({
    if (Get-Command -Name docker -ErrorAction Ignore) {
        $InstallFromDocker_form.ShowDialog()
    } else {
        error_form "Docker isn't installed"
    }
})


$submenuExit.Add_Click({
    $main_form.Close()
})

$submenuSettings.Add_Click({
    $settingsForm.ShowDialog()
})

$submenuAbout.Add_Click({
    $aboutForm.ShowDialog()
})

$buttonDoneDocker.Add_Click({
    $textboxConsoleDocker.Clear()
    $consoleFormDocker.Close()
})

$buttonDoneSrc.Add_Click({
    $textboxConsoleSrc.Clear()
    $consoleFormSrc.Close()
})

Hide_Powershell_Console
Check_If_WSL
[void]$main_form.ShowDialog()