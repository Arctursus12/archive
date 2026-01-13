#include <stdio.h>

main(argc, argv)
char *argv[];
{
    FILE *fp;
    char linbuf[MAXLINE];
    int lineno;
    if (argc != 2) {
        printf("Usage: pnum filename <cr>\n");
        exit();
    }
    if ((fp = fopen(argv[1], "r")) == NULL) {
        printf("Can’t open %s\n", argv[1]);
        exit();
    }
    lineno = 1;
    while (fgets(linbuf, MAXLINE, fp))
        printf("%3d: %s", lineno++, linbuf);
    fclose(fp);
}
