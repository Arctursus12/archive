#include <stdio.h>
#include "string.h"

main() {
    char dest[20];
    char* src;
    src = "Hello, CP/M!";
    
    /* Test the included function */
    strcpy(dest, src);
    
    printf("%s\n", dest);
}
