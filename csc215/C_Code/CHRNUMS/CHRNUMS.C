#include <stdio.h>
/* Nikita Kolesnikov - CSC215, 2025-26
CHRNUMS.C - Prepend each line with its character count
Usage: CHRNUMS filename.ext
Output: Displays each line with character count prefix */
#define CTRLZ 0x1A

/* Function prototypes */
void error_exit(char *msg);
void process_file(char *filename);

/* Main program */
main(argc, argv)
int argc;
char* argv[];
{
    /* Check for filename argument */
    if (argc < 2) {
        printf("Usage: CHRNUMS filename.txt\n");
        exit();
    }

    /* Process the file and display results */
    process_file(argv[1]);
}

/* Read file and display each line with character count */
void process_file(filename)
char *filename;
{
    FILE *fp;
    int c;
    char line[256];
    int line_len;

    /* Open input file */
    if ((fp = fopen(filename, "r")) == NULL) {
        error_exit("File not found.\n");
    }

    line_len = 0;

    /* Read and process file character by character */
    while ((c = fgetc(fp)) != EOF) {
        /* Stop at CTRLZ (CP/M EOF marker) */
        if (c == CTRLZ) {
            break;
        }

        /* Check if we reached end of line */
        if (c == '\n' || c == '\r') {
            /* Skip carriage return if it's part of CRLF */
            if (c == '\r') {
                int next = fgetc(fp);
                if (next != '\n' && next != EOF) {
                    ungetc(next, fp);
                }
            }

            /* Print the line with character count prefix */
            line[line_len] = '\0';
            printf("%d: %s\n", line_len, line);

            /* Reset for next line */
            line_len = 0;
        } else {
            /* Add character to current line buffer */
            if (line_len < 255) {
                line[line_len++] = c;
            }
        }
    }

    /* Handle last line if file doesn't end with newline */
    if (line_len > 0) {
        line[line_len] = '\0';
        printf("%d: %s\n", line_len, line);
    }

    /* Close input file */
    fclose(fp);
}

/* Display error message and exit */
void error_exit(msg)
char *msg;
{
    printf("%s", msg);
    exit();
}
