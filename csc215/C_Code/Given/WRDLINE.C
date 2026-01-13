#include <stdio.h>
#define  MAXLINE 80

main(argc, argv)
int argc;
char* argv[];
{
    FILE *infp;
    int ch, wpos, inword;
    char word[MAXLINE];

    if (argc != 2) {
        printf("Usage: wdatime <infile>\n");
        exit();
    }
    if ((infp = fopen(argv[1], "r")) == NULL) {
        printf("Can’t open %s\n", argv[1]);
        exit();
    }
    wpos = inword = 0;
    while ((ch = fgetc(infp)) != EOF) {
        if (ch == ' ' || ch == '\n' || ch == '\t') {
            if (inword) {
                word[wpos] = '\0';
                printf("%s\n", word);
                wpos = 0;
            } 
            inword = 0;
        } else {            /*  ch is not whitespace */
            inword = 1;
            word[wpos++] = ch;
        }
    }
    fclose(infp);
    if (wpos) {             /* inword when EOF encountered, print last word */
        word[wpos] = '\0';
        printf("%s\n", word);
    }
}
