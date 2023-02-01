
# Installs the gpu drivers if necessary
$gpu = <gpu>
if (1 -eq $gpu) {
  Invoke-WebRequest https://github.com/GoogleCloudPlatform/compute-gpu-installation/raw/main/windows/install_gpu_driver.ps1 -OutFile C:\install_gpu_driver.ps1
  C:\install_gpu_driver.ps1
}

### Install GH Actions runner

# Create a folder under the drive root
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

# Stop the instance
Stop-Computer -ComputerName localhost
