$versions = @("6","7","8")
$logo = "logo\centos.png"
$summary = @"
The CentOS Project is a community-driven free software effort focused on delivering a robust open source ecosystem around a Linux platform.

We offer two Linux distros:

– CentOS Linux is a consistent, manageable platform that suits a wide variety of deployments. For some open source communities, it is a solid, predictable base to build upon.

– The new CentOS Stream is a rolling-release distro that tracks just ahead of Red Hat Enterprise Linux (RHEL) development, positioned as a midstream between Fedora Linux and RHEL. For anyone interested in participating and collaborating in the RHEL ecosystem, CentOS Stream is your reliable platform for innovation.
"@

function prepare($version) {
    $letter = $env:TMP[0]
    $tmpwsl = $env:TMP -replace ".?:","/mnt/$letter".tolower() -replace "\\","/"
    if ($version -eq "6") {
        $url_centos="https://github.com/CentOS/sig-cloud-instance-images/raw/CentOS-6/docker/centos-6-docker.tar.xz"
    } elseif ($version -eq "7") {
        $url_centos="https://github.com/CentOS/sig-cloud-instance-images/raw/CentOS-7-x86_64/docker/centos-7-x86_64-docker.tar.xz"
    } elseif ($version -eq "8") {
        $url_centos="https://github.com/CentOS/sig-cloud-instance-images/raw/CentOS-8-x86_64/docker/centos-8-container.tar.xz"
    }
           
    write-output "Downloading Centos $version rootfs"
    Invoke-WebRequest $url_centos -OutFile $env:TMP\centos.tar.xz
    write-output "Creating temp alpine"
    Invoke-WebRequest "http://dl-cdn.alpinelinux.org/alpine/v3.10/releases/x86_64/alpine-minirootfs-3.10.3-x86_64.tar.gz" -OutFile $env:TMP\tmp.tar.gz   
    wsl.exe --import "TempAlpine" $env:TMP\TempAlpine $env:TMP\tmp.tar.gz 
    wsl.exe --distribution TempAlpine apk update
    wsl.exe --distribution TempAlpine apk add --upgrade perl debootstrap
    write-output "Creating rootfs"
    wsl.exe --distribution TempAlpine mkdir -p /mnt/centos
    wsl.exe --distribution TempAlpine tar xf $tmpwsl/centos.tar.xz -C /mnt/centos
    wsl.exe --distribution TempAlpine tar czf $tmpwsl/centos.tar.gz -C /mnt/centos .
}

function install($name, $location, $username, $passwd) {
    write-output "Creating $name"
    wsl.exe --import $name $location\$name $env:TMP\centos.tar.gz | out-host
    write-output "Upgrading $name"
    wsl.exe --distribution $name yum update -y
    write-output "Installing shadow and openssl"
    wsl.exe --distribution $name yum install openssl -y
    write-output "Creating user $username"
    $password = (wsl.exe --distribution $name openssl passwd -1 $passwd)
    wsl.exe --distribution $name useradd -m -p "'"$password"'" $username

}

function clean($name) {
    write-output "Removing temp alpine"
    wsl.exe --unregister TempAlpine
    write-output "Removing openssl"
    wsl.exe --distribution $name yum remove openssl -y
    write-output "Removing temp file"
    Remove-Item $env:TMP\tmp.tar.gz
    Remove-Item $env:TMP\centos.tar.gz
    Remove-Item $env:TMP\centos.tar.xz
}