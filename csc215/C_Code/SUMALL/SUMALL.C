#include <stdio.h>
/* Nikita Kolesnikov – CSC215, 2025-26
Presented by Sean Evans
SUMALL.ASM - Sum all single decimal digits in a file
Usage: SUMALL filename.ext
Output: Displays sum and writes to RESULT.TXT */
#define CTRLZ 0x1A

/* Function prototypes */
void error_exit(char *msg);
int sum_digits_in_file(char *filename);
void write_result(int sum);

/* Main program */
main(argc, argv)
int argc;
char* argv[];
{
    int sum;

    /* Check for filename argument */
    if (argc < 2) {
        printf("Usage: SUMALL filename.txt\n");
        exit();
    }

    /* Sum all digits in the file */
    sum = sum_digits_in_file(argv[1]);

    /* Display result */
    printf("Sum: %d\n", sum);

    /* Write result to RESULT.TXT */
    write_result(sum);

    printf("Sum written to RESULT.TXT.\n");
}

/* Read file and sum all single decimal digits (0-9) */
int sum_digits_in_file(filename)
char *filename;
{
    FILE *fp;
    int c;
    int sum;

    /* Open input file */
    if ((fp = fopen(filename, "r")) == NULL) {
        error_exit("File not found.\n");
    }

    sum = 0;

    /* Read and process file */
    while ((c = fgetc(fp)) != EOF) {
        /* Stop at CTRLZ (CP/M EOF marker) */
        if (c == CTRLZ) {
            break;
        }
        /* Check if character is a digit 0-9 */
        if (c >= '0' && c <= '9') {
            sum += (c - '0');
        }
    }

    /* Close input file */
    fclose(fp);

    return sum;
}

/* Write sum to RESULT.TXT on drive D: */
void write_result(sum)
int sum;
{
    FILE *fp;
    char result_str[10];
    int i;

    /* Convert sum to string manually */
    i = 0;
    if (sum == 0) {
        result_str[i++] = '0';
    } else {
        char temp[10];
        int j, temp_len;

        temp_len = 0;
        while (sum > 0) {
            temp[temp_len++] = (sum % 10) + '0';
            sum /= 10;
        }

        /* Reverse digits into result_str */
        for (j = temp_len - 1; j >= 0; j--) {
            result_str[i++] = temp[j];
        }
    }
    result_str[i] = '\0';

    /* Create/overwrite RESULT.TXT on drive D: */
    if ((fp = fopen("D:RESULT.TXT", "w")) == NULL) {
        error_exit("Cannot create RESULT.TXT.\n");
    }

    /* Write the result string */
    fprintf(fp, "%s\r\n", result_str);

    /* Close file */
    fclose(fp);
}

/* Display error message and exit */
void error_exit(msg)
char *msg;
{
    printf("%s", msg);
    exit();
}
