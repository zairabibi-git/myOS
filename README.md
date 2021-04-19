# myOS
# 64-bit OS
Our assignment was to build our own 64-bit operating system. Videos for guidance were prvided by the profesor and I followed them to create my OS. The code is similar to the video code, however, I have added comments and descriptions where necessary to show that I understood the code fully and completely.

Onto the description:
##### Softwares Used
1. Visual Studio Code as a text editor
2. Docker to build container image
3. Qemu to emulate or OS so we don't have to boot it using USB
##### Building a 32-bit OS
Our first step in creating a 64-bit OS is to understand and create a 32-bit OS. It contains the following files and folders:

1. `buildenv` 

    It contains a [*Dockerfile*](https://github.com/zairabibi-git/myOS/blob/main/buildenv/Dockerfile) which describes all the sets we need to create our build environment image. Our image is based on a pre-made image which holds all the gcc image compilation tools we'll need.

2. `src\imp\x86_64\boot`

    The x86_64 folder gives us the entry point into our operating system. 

    The boot folder containes [*header.asm*](https://github.com/zairabibi-git/myOS/blob/main/src/impl/x86_64/boot/header.asm) and [*main.asm*](https://github.com/zairabibi-git/myOS/blob/main/src/impl/x86_64/boot/main.asm) files.
