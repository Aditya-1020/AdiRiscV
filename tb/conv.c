// conv dec to hex and back
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
    if (argc != 3) {
        printf("Usage: %s -d <decimal> | %s -h <hex>\n", argv[0], argv[0]);
        return 1;
    }

    if (strcmp(argv[1], "-d") == 0) {
        unsigned long dec = strtoul(argv[2], NULL, 10);
        printf("%lX\n", dec);
    } else if (strcmp(argv[1], "-h") == 0) {
        unsigned long hex = strtoul(argv[2], NULL, 16);
        printf("%lu\n", hex);
    } else if (strcmp(argv[1], "-h4") == 0) {
        unsigned long hex_4 = strtoul(argv[2], NULL, 16) + 4; 
        printf("%lu\n", hex_4);
    }
    
    else {
        printf("Invalid flag.. use -d, -h or -h4 (for hex +4)\n");
        return 1;
    }
    return 0;
}