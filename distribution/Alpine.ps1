$versions = "3.10.3","3.9.4","3.8.4"
$logo = "logo\alpine.png"
$summary = @"
Alpine Linux is an independent, non-commercial, general purpose Linux distribution designed for power users who appreciate security, simplicity and resource efficiency.
Small

Alpine Linux is built around musl libc and busybox. This makes it smaller and more resource efficient than traditional GNU/Linux distributions. A container requires no more than 8 MB and a minimal installation to disk requires around 130 MB of storage. Not only do you get a fully-fledged Linux environment but a large selection of packages from the repository.

Binary packages are thinned out and split, giving you even more control over what you install, which in turn keeps your environment as small and efficient as possible.
Simple

Alpine Linux is a very simple distribution that will try to stay out of your way. It uses its own package manager called apk, the OpenRC init system, script driven set-ups and that’s it! This provides you with a simple, crystal-clear Linux environment without all the noise. You can then add on top of that just the packages you need for your project, so whether it’s building a home PVR, or an iSCSI storage controller, a wafer-thin mail server container, or a rock-solid embedded switch, nothing else will get in the way.
Secure

Alpine Linux was designed with security in mind. All userland binaries are compiled as Position Independent Executables (PIE) with stack smashing protection. These proactive security features prevent exploitation of entire classes of zero-day and other vulnerabilities.
"@


$labelUsername                   = New-Object system.Windows.Forms.Label
$labelUsername.text              = "Username :"
$labelUsername.AutoSize          = $true
$labelUsername.width             = 25
$labelUsername.height            = 10
$labelUsername.location          = New-Object System.Drawing.Point(26,33)
$labelUsername.Font              = 'Microsoft Sans Serif,10'

$textboxUsername                 = New-Object system.Windows.Forms.TextBox
$textboxUsername.multiline       = $false
$textboxUsername.width           = 100
$textboxUsername.height          = 20
$textboxUsername.location        = New-Object System.Drawing.Point(117,30)
$textboxUsername.Font            = 'Microsoft Sans Serif,10'

$labelPassword                   = New-Object system.Windows.Forms.Label
$labelPassword.text              = "Password :"
$labelPassword.AutoSize          = $true
$labelPassword.width             = 25
$labelPassword.height            = 10
$labelPassword.location          = New-Object System.Drawing.Point(309,33)
$labelPassword.Font              = 'Microsoft Sans Serif,10'

$textboxPassword                 = New-Object system.Windows.Forms.TextBox
$textboxPassword.multiline       = $false
$textboxPassword.width           = 100
$textboxPassword.height          = 20
$textboxPassword.location        = New-Object System.Drawing.Point(440,30)
$textboxPassword.Font            = 'Microsoft Sans Serif,10'

$labelPasswordRetype             = New-Object system.Windows.Forms.Label
$labelPasswordRetype.text        = "Retype Password :"
$labelPasswordRetype.AutoSize    = $true
$labelPasswordRetype.width       = 25
$labelPasswordRetype.height      = 10
$labelPasswordRetype.location    = New-Object System.Drawing.Point(309,67)
$labelPasswordRetype.Font        = 'Microsoft Sans Serif,10'

$textboxPasswordRetype           = New-Object system.Windows.Forms.TextBox
$textboxPasswordRetype.multiline  = $false
$textboxPasswordRetype.width     = 100
$textboxPasswordRetype.height    = 20
$textboxPasswordRetype.location  = New-Object System.Drawing.Point(440,64)
$textboxPasswordRetype.Font      = 'Microsoft Sans Serif,10'

    $group.controls.AddRange(@($labelUsername,$textboxUsername,$labelPassword,$textboxPassword,$labelPasswordRetype,$textboxPasswordRetype))

function prepare($version) {
    $version_short = $version.split(".")[0]+"."+$version.split(".")[1]
    $url_alpine="http://dl-cdn.alpinelinux.org/alpine/v$version_short/releases/x86_64/alpine-minirootfs-$version-x86_64.tar.gz"

    write-output "Downloading Alpine $version rootfs`n"
    Invoke-WebRequest $url_alpine -OutFile $env:TMP\alpine.tar.gz
}

function install($name, $location, $username, $passwd) {
    write-output "Creating $name`n"
    wsl.exe --import $name $location\$name $env:TMP\alpine.tar.gz
    write-output "Upgrading $name`n"
    wsl.exe --distribution $name apk update
    wsl.exe --distribution $name apk upgrade
    write-output "Installing shadow and openssl`n"
    wsl.exe --distribution $name apk add openssl shadow
    write-output "Creating user $username`n"
    $password = (wsl.exe --distribution $name openssl passwd -1 $passwd)
    wsl.exe --distribution $name useradd -m -p "'"$password"'" $username

}

function clean($name) {
    write-output "Removing shadow and openssl`n"
    wsl.exe --distribution $name --exec apk del openssl shadow
    write-output "Removing temp file`n"
    Remove-Item $env:TMP\alpine.tar.gz
}


function setup() {
    $name = $textboxName.Text
    $version = $comboboxVersion.SelectedItem
    $username = $textboxUsername.Text

    write-host $name $version $username
}