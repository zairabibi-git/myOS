#include "print.h"

void kernel_main()
{
    print_clear();
    print_set_color(PRINT_COLOR_RED,PRINT_COLOR_WHITE);
    print_str("Welcome to My First 64-bit OS");


}
