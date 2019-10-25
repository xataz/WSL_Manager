$versions = @("jessie", "stretch", "buster", "testing", "sid")
$logo = "logo\debian.png"
$summary = @"
The Debian Project is an association of individuals who have made common cause to create a free operating system. This operating system that we have created is called Debian.

An operating system is the set of basic programs and utilities that make your computer run. At the core of an operating system is the kernel. The kernel is the most fundamental program on the computer and does all the basic housekeeping and lets you start other programs.

Debian systems currently use the Linux kernel or the FreeBSD kernel. Linux is a piece of software started by Linus Torvalds and supported by thousands of programmers worldwide. FreeBSD is an operating system including a kernel and other software.

However, work is in progress to provide Debian for other kernels, primarily for the Hurd. The Hurd is a collection of servers that run on top of a microkernel (such as Mach) to implement different features. The Hurd is free software produced by the GNU project.

A large part of the basic tools that fill out the operating system come from the GNU project; hence the names: GNU/Linux, GNU/kFreeBSD, and GNU/Hurd. These tools are also free.

Of course, the thing that people want is application software: programs to help them get what they want to do done, from editing documents to running a business to playing games to writing more software. Debian comes with over 59000 packages (precompiled software that is bundled up in a nice format for easy installation on your machine), a package manager (APT), and other utilities that make it possible to manage thousands of packages on thousands of computers as easily as installing a single application. All of it free.

It's a bit like a tower. At the base is the kernel. On top of that are all the basic tools. Next is all the software that you run on the computer. At the top of the tower is Debian — carefully organizing and fitting everything so it all works together. 
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
    wsl.exe --distribution TempAlpine debootstrap --arch=amd64 $version /mnt/debian
    wsl.exe --distribution TempAlpine tar czf $tmpwsl/debian.tar.gz -C /mnt/debian .
}

function install($name, $location, $username, $passwd) {
    write-output "Creating $name"
    wsl.exe --import $name $location\$name $env:TMP\debian.tar.gz
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
    Remove-Item $env:TMP\debian.tar.gz
}