#include <stdio.h>
/* Nikita Kolesnikov - CSC215, 2025-26
BACKWARD.C - Display lines of a file in reverse order
Usage: BACKWARD filename.ext
Output: Displays file lines from last to first */
#define CTRLZ 0x1A
#define MAX_LINES 1000
#define MAX_LINE_LEN 256

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
        printf("Usage: BACKWARD filename.txt\n");
        exit();
    }

    /* Process the file and display results */
    process_file(argv[1]);
}

/* Read file and display lines in reverse order */
void process_file(filename)
char *filename;
{
    FILE *fp;
    int c;
    char lines[MAX_LINES][MAX_LINE_LEN];
    int line_count;
    int line_len;
    int i;

    /* Open input file */
    if ((fp = fopen(filename, "r")) == NULL) {
        error_exit("File not found.\n");
    }

    line_count = 0;
    line_len = 0;

    /* Read and store all lines */
    while ((c = fgetc(fp)) != EOF && line_count < MAX_LINES) {
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

            /* Store the line */
            lines[line_count][line_len] = '\0';
            line_count++;
            line_len = 0;
        } else {
            /* Add character to current line buffer */
            if (line_len < MAX_LINE_LEN - 1) {
                lines[line_count][line_len++] = c;
            }
        }
    }

    /* Handle last line if file doesn't end with newline */
    if (line_len > 0 && line_count < MAX_LINES) {
        lines[line_count][line_len] = '\0';
        line_count++;
    }

    /* Close input file */
    fclose(fp);

    /* Display lines in reverse order */
    for (i = line_count - 1; i >= 0; i--) {
        printf("%s\n", lines[i]);
    }
}

/* Display error message and exit */
void error_exit(msg)
char *msg;
{
    printf("%s", msg);
    exit();
}
