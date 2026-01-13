#include <stdio.h>

main(argc, argv)
char *argv[];
{
    FILE *ifp, *ofp;
    int c;
    if (argc != 3) {
        printf("Usage: ucase <file> <newfile>\n");
        exit();
    }
    if ((ifp = fopen(argv[1], "r")) == NULL) {
        printf("Can’t open %s\n",argv[1]);
        exit();
    }
    if ((ofp = fopen(argv[2], "w")) == NULL) {
        printf("Can’t create %s\n",argv[2]);
        exit();
    }
    while ((c = fgetc(ifp)) != EOF)
        if (fputc(toupper(c), ofp) == ERROR) {
            printf("Write error; disk probably full.\n");
            exit();
        }
    fclose(ifp);
    fclose(ofp);
}
