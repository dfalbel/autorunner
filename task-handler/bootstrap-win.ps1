# Make sure the computer will always turn off after
# maximum 1h30
$job = Start-Job { Start-Sleep -Seconds 5400; Stop-Computer } -NoNewWindow

# Installs the gpu drivers if necessary
$gpu = <gpu>
if (1 -eq $gpu) {
  Invoke-WebRequest https://github.com/GoogleCloudPlatform/compute-gpu-installation/raw/main/windows/install_gpu_driver.ps1 -OutFile C:\install_gpu_driver.ps1
  C:\install_gpu_driver.ps1
}

### Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# enable global confirmation so you don't have to confirm stuff when installing
# with choco.
choco feature enable -n allowGlobalConfirmation

### Install GH Actions runner

# Create a folder under the drive root
cd C://

mkdir actions-runner; cd actions-runner
# Download the latest runner package
Invoke-WebRequest -Uri https://github.com/actions/runner/releases/download/v2.301.1/actions-runner-win-x64-2.301.1.zip -OutFile actions-runner-win-x64-2.301.1.zip
# Optional: Validate the hash
if((Get-FileHash -Path actions-runner-win-x64-2.301.1.zip -Algorithm SHA256).Hash.ToUpper() -ne 'e83b27af969cb074ca53629b340f38d20e528071f4d6f9d4ba7819dace689ece'.ToUpper()){ throw 'Computed checksum did not match' }
# Extract the installer
Add-Type -AssemblyName System.IO.Compression.FileSystem ; [System.IO.Compression.ZipFile]::ExtractToDirectory("$PWD/actions-runner-win-x64-2.301.1.zip", "$PWD")

## Start the runner

# Create the runner and start the configuration experience
./config.cmd --url https://github.com/<org> --token <runner_token> --ephemeral --labels <labels> --unattended
# Run it!
./run.cmd
