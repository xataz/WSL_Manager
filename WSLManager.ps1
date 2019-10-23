$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
Set-Location $scriptDir


Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()


## InstallFromSrc FORM
$InstallFromSrc_form             = New-Object system.Windows.Forms.Form
$InstallFromSrc_form.ClientSize  = '725,600'
$InstallFromSrc_form.text        = "WSL Manager - Install From Sources"
$InstallFromSrc_form.BackColor   = "#575555"
$InstallFromSrc_form.TopMost     = $false

$Description                     = New-Object system.Windows.Forms.Groupbox
$Description.height              = 575
$Description.width               = 290
$Description.BackColor           = "#575555"
$Description.Anchor              = 'top,right,bottom'
$Description.text                = "Description"
$Description.location            = New-Object System.Drawing.Point(428,10)

$IconDistribution                = New-Object system.Windows.Forms.PictureBox
$IconDistribution.width          = 166
$IconDistribution.height         = 144
$IconDistribution.location       = New-Object System.Drawing.Point(65,21)
$IconDistribution.imageLocation  = ""
$IconDistribution.SizeMode       = [System.Windows.Forms.PictureBoxSizeMode]::zoom

$DescribeText                    = New-Object system.Windows.Forms.TextBox
$DescribeText.multiline          = $true
$DescribeText.enabled            = $false
$DescribeText.width              = 256
$DescribeText.height             = 382
$DescribeText.anchor             = 'top,left,bottom,right'
$DescribeText.location           = New-Object System.Drawing.Point(20,184)
$DescribeText.Font               = 'Microsoft Sans Serif,10'

$ListDistrib                     = New-Object system.Windows.Forms.ListView
$ListDistrib.text                = "listView"
$ListDistrib.BackColor           = "#575555"
$ListDistrib.anchor              = 'top,right,left'
$ListDistrib.width               = 400
$ListDistrib.height              = 350
$ListDistrib.location            = New-Object System.Drawing.Point(15,10)
$ListDistrib.View                = "Details"

$ParametersGroup                 = New-Object system.Windows.Forms.Groupbox
$ParametersGroup.height          = 165
$ParametersGroup.width           = 420
$ParametersGroup.BackColor       = "#575555"
$ParametersGroup.Anchor          = 'top,left,bottom,right'
$ParametersGroup.text            = "Paramaters"
$ParametersGroup.location        = New-Object System.Drawing.Point(5,370)

$Parameters                      = New-Object system.Windows.Forms.PropertyGrid
$Parameters.width                = 400
$Parameters.height               = 135
$Parameters.anchor               = 'bottom,right,left,top'
$Parameters.location             = New-Object System.Drawing.Point(10,17)


$Parameters.SelectedObject = (Get-LocalUser)


$InstallSrc                      = New-Object system.Windows.Forms.Button
$InstallSrc.text                 = "Install"
$InstallSrc.width                = 90
$InstallSrc.height               = 30
$InstallSrc.anchor               = 'bottom,left'
$InstallSrc.location             = New-Object System.Drawing.Point(15,550)
$InstallSrc.Font                 = 'Microsoft Sans Serif,10'

$InstallFromSrc_form.controls.AddRange(@($Description,$ListDistrib,$InstallSrc,$ParametersGroup))
$ParametersGroup.controls.AddRange(@($Parameters))
$Description.controls.AddRange(@($IconDistribution,$DescribeText))

## Main FORM
$main_form                       = New-Object system.Windows.Forms.Form
$main_form.ClientSize            = '725,600'
$main_form.text                  = "WSL Manager"
$main_form.BackColor             = "#575555"
$main_form.TopMost               = $false

$List_WSL                        = New-Object system.Windows.Forms.ListView
$List_WSL.text                   = "List_WSL"
$List_WSL.width                  = 725
$List_WSL.height                 = 575
$List_WSL.Margin                 = 0
$List_WSL.Anchor                 = 'top,right,bottom,left'
$List_WSL.BackColor              = "#575555"
$List_WSL.location               = New-Object System.Drawing.Point(0,25)
$List_WSL.View = "Details"

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

$main_form.controls.AddRange(@($List_WSL,$menuMain))
$menuMain.Items.AddRange(@($menuTools,$menuHelp))
$menuTools.DropDownItems.AddRange(@($submenuInstallSrc,$submenuInstallDocker,$submenuSettings,$submenuExit))
$menuHelp.DropDownItems.AddRange(@($submenuAbout))

$List_WSL.Add_DoubleClick({ write-host "Click $List_WSL.SelectedSubItem" })

$main_form.Add_Shown({ 
    $List_WSL.Columns.Add("Name")
    $List_WSL.Columns.Add("Distribution")
        
    $itemname = New-Object System.Windows.Forms.ListViewItem("Debian")
    $itemname.SubItems.Add("Debian 10 (buster)")
    $List_WSL.Items.Add($itemname)
    $List_WSL.AutoResizeColumns(2)
})



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
    $distribution = $ListDistrib.SelectedItems.text
    . "distribution\$distribution.ps1"

    write-host = $logo
    $IconDistribution.imageLocation = "$scriptDir\$logo"
    #$IconDistribution.Image = [System.Drawing.Image]::Fromfile("$scriptDir\$logo")
    $DescribeText.Text = $summary
})

$submenuInstallSrc.Add_Click({
    
    
    [void]$InstallFromSrc_form.ShowDialog()
})


$InstallSrc.Add_Click({

})

#Write your logic code here

[void]$main_form.ShowDialog()