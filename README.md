## About This DevContainer

This repository provides a DevContainer setup for C++.
The Docker image is based on `RockyLinux:9.0`.
The Docker image size is approximately 4.0GB after build.

This setup has been tested on macOS-x86_64 and Linux-x86_64 as host platforms, with Linux-x86_64 as the container runtime. Compatibility with other environments is not guaranteed.

`Zig` is used to perform cross-builds for creating self-contained executables for various platforms.

**Note:** This project uses **C++20** for debugging, release builds, and cross-builds.

### Target Platform Compatibility and Dynamic/Static Library Build Support

| Target OS | Target Arch | Build | Strip        | Dynamic Library | Static Library |
|-----------|-------------|--------|--------------|------------------|----------------|
| Windows   | x64         | OK     | OK           | OK               | OK             |
| Windows   | arm64       | OK     | OK           | OK               | OK             |
| macOS     | x64         | OK     | Not supported| OK               | OK             |
| macOS     | arm64       | OK     | Not supported| OK               | OK             |
| Linux     | x64         | OK     | OK           | OK               | OK             |
| Linux     | arm64       | OK     | OK           | OK               | OK             |

**Legend:**
- **OK**: Fully supported and tested.
- **Not supported**: Not supported for this configuration.
- **Planned**: Planned for future support.
- **Not tested**: Not yet tested.

---

## Getting Started (With Dev Containers)

### 1. Launch VSCode  
Open Visual Studio Code.

### 2. Open the Project Folder in VSCode  
Go to **File → Open Folder** and select the folder where the project is cloned.

### 3. Install VSCode Extension  
If you see a message at the bottom of VSCode saying **"Do you want to install the recommended extensions from GitHub, Microsoft and others for this repository?"**, click **Install** to install the **Dev Containers** extension along with other recommended extensions.

### 4. Reopen the Project in a Container  
Click the **bottom left corner** of the VSCode window where it says **"Open a Remote Window"** → **Reopen in Container**.  

### 5. Wait for the Container to Build and Set Up  
Wait while the **Dev Container environment prepares**. This process may include **downloading the base image**, **installing required tools and libraries**, and **building the Docker image if necessary**.  
Depending on your internet speed and system performance, this may take **a few minutes**.  
If you see a message prompting you to install recommended extensions like in the previous steps, click **Install** to install the extensions in the container environment.

### 6. Debug the Project  
Open `[WORKSPACE_FOLDER]/app/src/main.cpp` and press **F5** to start debugging.  
The project will be **compiled and executed inside the container**, and the output will be visible in the **Terminal**.  
If you see a message in the **Debug Console** after starting the project, switch to the **Terminal** tab to find the running program.

### 7. Cross-Build the Project  
Open the command palette: Press **Ctrl + Shift + P** (macOS: **Cmd + Shift + P**) → **Tasks: Run Task** → **Zig: build all releases**.

### 8. Library Build and Testing  
This section explains how to build and test dynamic and static libraries for all supported platforms.

#### 8.1 Build Dynamic Libraries for All Supported Platforms  
Open the command palette: Press **Ctrl + Shift + P** (macOS: **Cmd + Shift + P**) → **Tasks: Run Task** → **Zig: build lib-dynamic all platforms**.  
The dynamic libraries for all target platforms will be built and compressed into `.tar.gz` archives.  
You can find the resulting files in the `[WORKSPACE_FOLDER]/app/build/dynamic/packages/` directory, organized by target platform.

#### 8.2 Build Static Libraries for All Supported Platforms  
Open the command palette: Press **Ctrl + Shift + P** (macOS: **Cmd + Shift + P**) → **Tasks: Run Task** → **Zig: build lib-static all platforms**.  
The static libraries for all target platforms will be built and compressed into `.tar.gz` archives.  
You can find the resulting files in the `[WORKSPACE_FOLDER]/app/build/static/packages/` directory, organized by target platform.

#### 8.3 Test the Built Libraries  
An example C++ project for testing the libraries is located at `[WORKSPACE_FOLDER]/app/example/libtest`.  
Refer to the `how-to-test-[OS].txt` file in the same directory for instructions on how to test the libraries.  
**Note:** Testing must be performed on the respective target OS for the libraries.
