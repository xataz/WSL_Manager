$versions = @("xenial", "bionic", "disco", "eoan")
$logo = "logo\ubuntu.png"
$summary = @"
Ubuntu is an open-source operating system (OS) based on the Debian GNU/Linux distribution.

Ubuntu incorporates all the features of a Unix OS with an added customizable GUI, which makes it popular in universities and research organizations. Ubuntu is primarily designed to be used on personal computers, although a server editions does also exist.

Ubuntu is an African word that literally means "humanity to others."

"@

function prepare($version) {
    $letter = $env:TMP[0]
    $tmpwsl = $env:TMP -replace ".?:","/mnt/$letter".tolower() -replace "\\","/"
    write-output "Creating temp alpine"
    Invoke-WebRequest "http://dl-cdn.alpinelinux.org/alpine/v3.10/releases/x86_64/alpine-minirootfs-3.10.3-x86_64.tar.gz" -OutFile $env:TMP\tmp.tar.gz   
    wsl.exe --import "TempAlpine" $env:TMP\TempAlpine $env:TMP\tmp.tar.gz 
    wsl.exe --distribution TempAlpine apk update
    wsl.exe --distribution TempAlpine apk add --upgrade perl debootstrap
    write-output "Creating rootfs"
    wsl.exe --distribution TempAlpine debootstrap --arch=amd64 $version /mnt/ubuntu
    wsl.exe --distribution TempAlpine tar czf $tmpwsl/ubuntu.tar.gz -C /mnt/ubuntu .
}

function install($name, $location, $username, $passwd) {
    write-output "Creating $name"
    wsl.exe --import $name $location\$name $env:TMP\ubuntu.tar.gz
    write-output "Upgrading $name"
    wsl.exe --distribution $name apt-get update
    wsl.exe --distribution $name apt-get upgrade -y
    write-output "Installing shadow and openssl"
    wsl.exe --distribution $name apt-get install -y openssl
    write-output "Creating user $username"
    $password = (wsl.exe --distribution $name openssl passwd -1 $passwd)
    wsl.exe --distribution $name useradd -m -p "'"$password"'" $username
}

function clean($name) {
    write-output "Removing temp alpine"
    wsl.exe --unregister TempAlpine
    write-output "Removing openssl"
    wsl.exe --distribution $name apt-get autoremove -y openssl
    write-output "Removing temp file"
    Remove-Item $env:TMP\tmp.tar.gz
    Remove-Item $env:TMP\ubuntu.tar.gz
}

function setup($name, $version, $username, $password, $location) {
    prepare $version
    install $name $username $password
    clean $name
}