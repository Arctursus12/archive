#include <stdio.h>

main(argc, argv)
int argc;
char* argv[];
{
    FILE *infp, *outfp;
    int c;

    if (argc != 3) {
        printf("Usage: copy <infile> <outfile>\n");
        return;
    }
    printf("So, you want to copy %s to %s, eh?...\n", argv[1], argv[2]);
    printf("Let's do it!\n");
    if ((infp = fopen(argv[1], "r")) == NULL) {
        printf("Can’t open %s\n", argv[1]);
        exit();
    }
    if ((outfp = fopen(argv[2], "w")) == NULL) {
        printf("Can’t open %s\n", argv[2]);
        exit();
    }
    while ((c = fgetc(infp)) != EOF) {
        fputc(c, outfp);
        putchar(c);
    }
    fclose(infp);
    fclose(outfp);
}
