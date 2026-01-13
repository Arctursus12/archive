#include <stdio.h>

main(argc, argv)
int argc;
char* argv[];
{
    FILE *infp;
    int c, nl, nw, nc, inword;

    if (argc != 2) {
        printf("Usage: wc <infile>\n");
        exit();
    }
    if ((infp = fopen(argv[1], "r")) == NULL) {
        printf("Can’t open %s\n", argv[1]);
        exit();
    }
    inword = 0;
    nl = nw = nc = 0;
    while ((c = fgetc(infp)) != EOF) {
        ++nc;
        if (c == '\n') {
            ++nl;
        }
        if (c == ' ' || c == '\n' || c == '\t') {
            inword = 0;
        } else if (!inword) {
            inword = 1;
            ++nw;
        }
    }
    fclose(infp);
    printf("  %d %d %d %s\n", nl, nw, nc, argv[1]);
}
