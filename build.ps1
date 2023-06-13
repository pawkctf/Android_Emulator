# Android Template Builder
# Android Studio must be installed
# Android SDK Tools must be installed
# Android Emulator must be installed
# Android Platform Tools must be installed
# Android SDK Command-line Tools must be installed
# Java SDK must be installed https://www.oracle.com/java/technologies/downloads/#jdk20-windows


# Globals
$UserDirectory = "C:\Users\" + $env:UserName
$BaseDir = Get-Location | Select-Object -ExpandProperty Path


# Check installed directories
function check_install {
    if (-not (Test-Path -Path "$UserDirectory\AppData\Local\Android\Sdk\platform-tools")){
        Write-Output "Android Platform Tools is not installed. Please refer to the OneDrive for instructions."
        break
    }
    if (-not (Test-Path -Path "$UserDirectory\AppData\Local\Android\Sdk\emulator")){
        Write-Output "Android Emulator is not installed. Please refer to the OneDrive for instructions."
        break
    }
    if (-not (Test-Path -Path "$UserDirectory\AppData\Local\Android\Sdk\cmdline-tools\latest\bin")){
        Write-Output "Android Command Line Tools is not installed. Please refer to the OneDrive for instructions."
    }
}

# Builds the Android Emulator
function build_emulator {
    Set-Location "$UserDirectory\AppData\Local\Android\Sdk\cmdline-tools\latest\bin\"
    .\avdmanager.bat create avd --force --name Android_Template --abi google_apis/x86 --package 'system-images;android-28;google_apis;x86' --device 'Nexus 6P'
}

# Runs the Emulator on a different PID
function run_emulator {
    Start-Job -ScriptBlock {
        Set-Location "$($args[0])\AppData\Local\Android\Sdk\emulator"
        .\emulator.exe -avd Android_Template -writable-system | Out-Null
    } -ArgumentList $UserDirectory
}

# Checks if the Emulator is up and running
function check_emulator_status {

    $value = 0
    $bool = $false

    Set-Location "$UserDirectory\AppData\Local\Android\Sdk\platform-tools"

    while ($value -ne 10){
        Write-Host "Checking device status... $value"
        $status = .\adb.exe devices | Select-Object -Skip 1
        if ($status -like "*device*"){
            $bool = $true
            $value = 10   
        }
        else {
            $value++
            Start-Sleep -Seconds 30
        }

    }
    return $bool
}

# Setup Emulator
function setup_emulator {
    # Check if Emulator is running
    $install_cert_proc = check_emulator_status
    if ($install_cert_proc -eq $true){
        # Install Certificate
        Set-Location "$UserDirectory\AppData\Local\Android\Sdk\platform-tools"
        .\adb.exe root
        Start-Sleep -Seconds 5
        .\adb.exe root
        Start-Sleep -Seconds 5
        .\adb.exe remount

        if (check_emulator_status){
            .\adb.exe push "$BaseDir\9a5ba575.0" /system/etc/security/cacerts
            .\adb.exe shell chmod 644 /system/etc/security/cacerts/9a5ba575.0
			Start-Sleep -Seconds 15
            .\adb.exe shell reboot -p
            Write-Host "Rebooting phone..."
        }
        else {
            Write-Host "Failed to remount device."
        }

    }
    else {
        Write-Output "Unable to connect to emulator."
        break
    }
    # Wait for Clean Shutdown
    Start-Sleep -Seconds 30
    
    # Boot Writeable Disk
    run_emulator

    $install_gsuite_proc = check_emulator_status
    if ($install_gsuite_proc -eq $true){
        # Install GSuite
        Set-Location "$UserDirectory\AppData\Local\Android\Sdk\platform-tools"
        .\adb.exe root
        Start-Sleep -Seconds 5
        .\adb.exe root
        Start-Sleep -Seconds 5
        .\adb.exe remount

        if (check_emulator_status){
            .\adb.exe push "$BaseDir\gplay\app" /system
            .\adb.exe push "$BaseDir\gplay\priv-app" /system
            .\adb.exe push "$BaseDir\gplay\etc" /system
            .\adb.exe push "$BaseDir\gplay\framework" /system
            .\adb.exe shell reboot -p
        }
        else {
            Write-Host "Failed to remount device."
        }

    }
    else {
        Write-Output "Unable to connect to emulator."
        break
    }

}


# MAIN
check_install
build_emulator
run_emulator
setup_emulator

# Wait for Clean Shutdown
Start-Sleep -Seconds 25

# Boot Finished Device
run_emulator

Write-Host "Build is complete."
