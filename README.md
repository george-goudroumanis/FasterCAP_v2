# FasterCap Version 2

## Description

FasterCap V2 is a powerful three- and two-dimensional capactiance extraction program originated from http://www.fastfieldsolvers.com/. This repository contains an optimized version of the tool achieving 5 times better execution time while producing the same QoRs with the original version.

For pre-compiled binaries, support, consultancy and additional information of the original version please visit http://www.fastfieldsolvers.com/. Access to the download pages is free, and you may access anonymously if you want.

This project was a collaboration between Dimitris Fotakis (https://www.linkedin.com/in/dimitris-fotakis-808111/) and Circuits and Systems Lab ([CASlab](https://www.linkedin.com/company/circuits-and-systems-laboratory-uth/mycompany/)) of University of Thessaly.
The goal of this projects was to review the FasterCap project as it is one of the most well-known and OpenSource field solvers and if possible to optimize it in order to establish it as viable solution to be integrated into the RCextraction step of modern Integrated Circuits (iCs).

Dimitris Fotakis provided a set of 3D patterns (https://github.com/hricky60/FasterCap_vs_Raphael) extracted from OpenRCX, which latter on this project was reviewed by Dimitris to extract more accurate 3D patterns. At the same time, the team started experimenting on the original 
FasterCap executable mainly focusing on memory and run-time analysis of the tool. We optimized the existing C++ functional modules by avoiding unnecessary operations, activating compiler optimization features, extending vectorized sections to multi-threaded and reconfiguring the 
memory management. Through extensive experiments with the initial set of patterns, we found-out that their simulation window affects directly the execution time and the QoRs. This way, a pre-processing step was introduced, reducing the pattern simulation window, in such way 
that the execution time is notably decreased while the QoRs are not drastically affected. Combining these optimizations, the overall gained speed-up reaches approximately twenty-two times better execution time while preserving similar Coupling and Self capacitances results. 

The results of our research are available upon request. 

## Compiling

FasterCap V2 can be compiled for MS Windows and for *nix. For multiple platform compilation support, FasterCap V2 uses CMake, plus Code::Blocks for the GUI version. The following software tools and complier chains are required. Used versions are indicated, higher version may work, but were not tested.

###  MS Windows 64 bits

- CMake 3.6.0
- Code::Blocks, version 13.12
- TDM-GCC 64 bits, version 4.8.1
- wxWidgets, version 3.0

#### Notes

- Use a fresh TDM-GCC package, not the one shipped with Code::Blocks, as the latter is missing the TDM OpenMP package.
      
- You need to pre-compile wxWidgets with TDM-GCC. Do not use pre-compiled versions, as the used compiler switch configurations may be very different when generating the binaries. Do NOT compile as monolithic, so .exe are smaller. Do two compiles, debug + release, using MSDOS makefiles and TDM-GCC (no need to use MSYS).

- Run CMake until you configure all the required parameters (you need some knowledge of how CMake works). You may want to set the switch FASTFIELDSOLVERS_HEADLESS as ON for a DOS-only version ("headless") of the software, however under Windows this is useless; just run FasterCap in shell-only mode with the appropriate -b switch (see FasterCap V2 documentation)

###  Linux 64 bits

- CMake 2.8.12
- Code::Blocks, version 13.12
- GCC, version 4.8.1
- wxWidgets (wxGTK), version 3.0

#### Notes

- Run CMake until you configure all the required parameters (you need some knowledge of how CMake works), then generate a CodeBlock project. You may want to set the switch FASTFIELDSOLVERS_HEADLESS as ON for a shell-only version ("headless") of the software, or you can keep this OFF and just run FasterCap in shell-only mode with the appropriate -b switch (see FasterCap V2 documentation)

Example (using a GUI-less CMake):

Move to the build directory you choose (different from the source files directory) and type the following command, where "../FasterCap" is the path to the base directory containing the FasterCap V2 source code:
    
`cmake -G"CodeBlocks - Unix Makefiles" -DCMAKE_BUILD_TYPE=Release ../FasterCap`

Then you can open Code::Blocks, open the FasterCap.cbp project file created by CMake under the build diretory, and compile it.

###  Linux 64 bits headless

- CMake 3.5.1
- GCC, version 4.8.1 or higher (higher version tested: on 5.4.0)
- wxWidgets, version 3.0.2 or higher (higher version tested: 3.0.2)

#### Notes

- Run CMake until you configure all the required parameters (you need some knowledge of how CMake works). You **must** set the switch FASTFIELDSOLVERS_HEADLESS as ON, as in a headless Linux distro you have no drivers at all for video.

Example: 

Move to the build directory you choose (different from the source files directory) and type the following command, where "../FasterCap" is the path to the base directory containing the FasterCap V2 source code:
    
`cmake -G"Unix Makefiles"  -DCMAKE_BUILD_TYPE=Release -DFASTFIELDSOLVERS_HEADLESS=ON ../FasterCap`

Then you can launch the build process with:
    
`make`
  
Remark: at run time you will see the an "Assert failure" message. This is a wxWidgets issue, see ["debug message when running without session manager"](http://trac.wxwidgets.org/ticket/16024). The assert is harmless, and it is fixed starting from wxWidgets 3.1.1

## wxWidgets Installation and Linking with FasterCap 


### Step 1: Install wxWidgets

#### Download wxWidgets
wxWidgets can be downloaded from:
- their [GitHub repository](https://github.com/wxWidgets/wxWidgets)
    - [version 3.2](https://github.com/wxWidgets/wxWidgets/tree/3.2)
- their [website](https://www.wxwidgets.org/downloads/ )


#### Prepare wxWidgets
1. After downloading the wxWidgets package, navigate to the wxWidgets directory and create a build directory. Change into the wxWidgets directory and create a new directory named `buildgtk` for the build files:
    ```sh
    cd wxWidgets
    mkdir buildgtk
    cd buildgtk
    ```

2. Configure the build for GTK:
    - Run the configure script with the `--with-gtk` option to set up the build environment for GTK.
    ```sh
    ../configure --with-gtk
    ```
    - Optionally, you can set the version of GTK:
    ```sh
    ../configure --with-gtk=2
    ```

3. Update Git submodules if you encounter any errors:
    - If you run into any errors during the configuration, update the necessary submodules. This ensures that all required third-party libraries are included.
    ```sh
    git submodule update --init src/jpeg
    git submodule update --init src/tiff
    git submodule update --init src/stc/scintilla
    git submodule update --init src/stc/lexilla
    git submodule update --init 3rdparty/catch
    git submodule update --init 3rdparty/pcre
    git submodule update --init 3rdparty/nanosvg
    ```

4. Compile and install wxWidgets:
    - Compile the wxWidgets source code and install it. Then clean up the build files and update the shared library cache.
    ```sh
    make
    sudo make install
    make clean
    sudo ldconfig
    ```

5. Verify the wxWidgets installation:
    - Check that wxWidgets is installed correctly by verifying the version.
    ```sh
    wx-config --version
    ```

### Step 2: Link FasterCap with wxWidgets

There are two ways to link FasterCap with wxWidgets, depending on the operating system of your computer.

#### Method 1: Using CMakeFiles 
*These steps are necessary <ins>only</ins> if `sudo make install` was not possible or if the library path is <ins>not set to the default path</ins>.*

1. Insert the following line into the file `/FasterCap/CMakeFiles/FasterCap.dir/link.txt`:
    ```sh
    -L/<wxWidgets_installation_path>/wxWidgets/lib -pthread -lwx_gtk2u_xrc-3.2
    ```
    Replace `<wxWidgets_installation_path>` with the path where you have installed the wxWidgets library.

2. **Optional**: Depending on your installed packages, you may need to add the following include directive to the file `/FasterCap/FasterCapConsole.h`:
    ```cpp
    #include <omp.h>
    ```
    If you encounter issues related to OpenMP, this step may resolve them.

3. Set the following environment variables:
    ```sh
    export LD_LIBRARY_PATH=<wxWidgets_installation_path>/wxWidgets/lib

    export LIBRARY_PATH=<wxWidgets_installation_path>/wxWidgets/lib

    export CPATH=<wxWidgets_installation_path>/wxWidgets/include/<wxWidgets_installed_version>
    ```

    Replace `<wxWidgets_installation_path>` with the path where you have installed the wxWidgets library and `<wxWidgets_installed_version>` with the version of wxWidgets you have installed (in our case this is equal to wx-3.2).

#### Method 2: Modifying CMakeLists.txt 
1. Replace with your wxWidgets version in file `CMakeLists.txt` of FasterCap:
    ```cmake
    set(wxWidgets_CONFIG_OPTIONS --version=<wxWidgets_installed_version> --static=no $<$<CONFIG:Debug>:--debug>)
    ```
    This method may be necessary on certain systems where the default linking method does not work properly. Replace `<wxWidgets_installed_version>` with the version of wxWidgets you have installed.


## Additional packages

FasterCap V2 also requires two additional source code packages, that are available through the same official repositories you can access from http://www.fastfieldsolvers.com/ or directly from GitHub.

The packages are:

- LinAlgebra
- Geometry

Both package directories, with the above names, must be at the same hierarchy level in the folder structure of the FasterCap source code directory, and are handled by CMake.



