strcpy(d, s)
char* d;
char* s;
{
    while (*s) *d++ = *s++;
    *d = '\0';
}
