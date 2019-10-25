$versions = @("3.10.3","3.9.4","3.8.4")
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


function prepare($version) {
    $version_short = $version.split(".")[0]+"."+$version.split(".")[1]
    $url_alpine="http://dl-cdn.alpinelinux.org/alpine/v$version_short/releases/x86_64/alpine-minirootfs-$version-x86_64.tar.gz"

    write-output "Downloading Alpine $version rootfs`n"
    Invoke-WebRequest $url_alpine -OutFile $env:TMP\alpine.tar.gz
}

function install($name, $username, $passwd) {
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


function setup($name, $version, $username, $password, $location) {
    prepare $version
    install $name $username $password
    clean $name
}