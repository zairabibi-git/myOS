# 64-bit OS
Our assignment was to build our own 64-bit operating system. Videos for guidance were prvided by the profesor and I followed them to create my OS. The code is similar to the video code, however, I have added comments and descriptions where necessary to show that I understood the code fully and completely.

##### Git Repository

[*zairabibi-git/myOS*](https://github.com/zairabibi-git/myOS)

##### Output Image

Onto the description:
##### Softwares Used
1. Visual Studio Code as a text editor
2. Docker to build container image
3. Qemu to emulate or OS so we don't have to boot it using USB
##### Building a 64-bit OS
Our first step in creating a 64-bit OS is to understand and create a 32-bit OS. 32-bit one is relatively simple so it is not described. We will start with 64-bit OS directly. It contains the following files and folders:

1. `buildenv` 

    It contains a [*Dockerfile*](https://github.com/zairabibi-git/myOS/blob/main/buildenv/Dockerfile) which describes all the sets we need to create our build environment image. Our image is based on a pre-made image which holds all the gcc image compilation tools we'll need.

2. `src\imp\x86_64\boot`

    The x86_64 folder gives us the entry point into our operating system. The boot folder contains:
    1. [*header.asm*](https://github.com/zairabibi-git/myOS/blob/main/src/impl/x86_64/boot/header.asm) 
    
    2. [*main.asm*](https://github.com/zairabibi-git/myOS/blob/main/src/impl/x86_64/boot/main.asm) 
    
    3. [*main64.asm*](https://github.com/zairabibi-git/myOS/blob/main/src/impl/x86_64/boot/main64.asm)

    4. [*main.c*](https://github.com/zairabibi-git/myOS/blob/main/src/impl/kernel/main.c): In the `src\imp\kernel` directory.

    5. [*print.c*](https://github.com/zairabibi-git/myOS/blob/main/src/impl/x86_64/print.c): Inside the `src\imp\x86_64` directory.

3. `src\interface`

    It will have a [*print.h*](https://github.com/zairabibi-git/myOS/blob/main/src/interface/print.h) file that provides us with the printing interface.

4. `targets/x86_64`
    Here we will hold all the files needed for building x86, and it might be expanded to other systems.

    1. [*linker.ld*](https://github.com/zairabibi-git/myOS/blob/main/targets/x86_64/linker.ld): It describes how to link our operating system together. We must specify the entry point in this file.

    2. `iso` folder: This will contain a grub configuration ([*grub.cfg*](https://github.com/zairabibi-git/myOS/blob/main/targets/x86_64/iso/boot/grub/grub.cfg)) file inside `boot/grub`.

5. [*Makefile*](https://github.com/zairabibi-git/myOS/blob/main/Makefile): Make is good tool to organize all the build commands and making sure that only those file which have been modified get rebuild.
##### Description
###### main.asm
1. We first set up a **stack** which is a region of computer memory. It handles function calls and all the data. It allows us to link with C code so that we can make our priting function.

2. We then switch our kernel from 32-bit to **64-bit** mode. To do this, we have to switch our CPU into long mode. This is done in the following sections
    
    1. **Check Multiboot:**
         
         This confirms that we have been loaded into a multiboot2 boot loader. A magic value is stored into `eax` register by any compliant boot loader, so we will check if `eax` hold that magic value. If the values don't match on comparing, then there is no multiboot so we will print an error message.
        

         Otherwise, we will return from the sub routine.

    2. **Check for CPU ID:**

        CPU ID is a CPU instruction which provides information about the CPU. We need to flip the ID bit of flag register, and if we're successful then the CPU supports CPU ID.

        This is done using stack so that all flags retain their original data after the subroutine ends. We store the flag data into `eax` and make a copy in  `ecx`. After flipping the `bit 21` of `eax`, which is the ID bit, we compare it with the copy stored in `ecx`. If they match, then we know that the CPU didnot allow us to flip that bit, which means that CPU ID is not available. In this case we print an error message.

        Otherwise, we will return from the sub routine.

    3. **Check for Long Mode Support:**

        We need to first confirm if the CPU ID supports the extended processor information. For this, we will run the *cpuid* instruction which will take `eax` as an argument, and store some value back into `eax`. If this value is greater than the value previously stored in `eax`, then the CPU supports extended processor information.

        Otherwise, extended processor information is not supported, and in turn long-mode is **not** supported and we will jump to `.no_long_mode` label.

          * **If Extended Processor Info is Supported**:
          We will again run *cpuid* instruction after storing a value in `eax`. This time, a value will be written in `edx` register. If *lm* bit (`bit 29`) is set, then long mode is supported and we can return succesfully from the sub routine. Otherwise we will jump to `.no_long_mode` label.

    We've checked for all the three things. but we cannot enter into long mode just yet. To enter long mode, we need to set up [*Paging*](https://www.geeksforgeeks.org/paging-in-operating-system/). (In simple words, Paging allows us to map virtual addresses to physical addresses). This will be done by:

    1. **Setting up Page Tables:**
       We have four types of page tables, namely L4, L3, L2, L1, so we will reserve memory for page tables (each page table is `4KB`). Doing *Identity Mapping*, i.e. mapping physical address to the exact same virtual address so that our instructions are executed perfectly since CPU will read the instructions and treat the address as virtual address. So we will add one entry to the *L4* table, which will point to the *L3* table, and similarly there will be one entry in the *L3* table which will point to the *L2* table. Enabling the `huge table` flag in *L2*, we can point directly to the physical memory and allocate a huge page. 


       * **Filling up all 512 entries of L2**
            Each entry is `2MB` each, so a total of 1 `GB` of physical memory will be identity mapped. In a loop, we will map a `2MB` page in each iteration. The loop will run 512 times to ensure each entry has been mapped.
    
       Once this is done, we can return from the sub routine.

    2. **Enabling Paging:**

         We will pass page table location to the CPU. This location will be in the `cr3` register. We enable Physical Address Extension (by enabling `PAE` flag of `cr4`) as it is necessary for 64-bit paging.

        * **Enable Long Mode:** We will enable long-mode by using model specific registers.

         * **Enable Paging:** Lastly we will enable paging by enabling `paging flag` in the `cr0` register.

    We'll now enter 64-bit mode by describing a 64-bit *Global Descriptor Table*. After that, we will enable the `64-bit` flag, and have a pointer to the `*Global Descriptor Table*. Loading the Table and the code segment, we now have successfully entered 64-bit mode.

**main64.asm**

We'll set our bits to 64 and have a global `long_mode_start` label. We'll then load `0` into many data segments so that our code is fully functional.  

**main.c**

It will have a main function which calls all the other functions for printing the required text or pattern on the screen.

**print.c**

It gives the implementation of *print.h* file. The function to print **NUST** using `*` is called `printNUST()` and uses loops to create the [*output*](https://github.com/zairabibi-git/myOS/blob/main/nust.JPG).

