#include <stdio.h>
#include <string.h>
#include <stdlib.h>

typedef struct {
    char *hostname;
    int v;
} mystruct;

int insert(mystruct *P, char *s, int n, int *size);

int main() {
    // read the string filename
    char filename[105];
    char output[200];

    scanf("%[^\n]", filename);
    FILE *f = fopen(filename, "r");


    int size = 2;
    mystruct *P = malloc(sizeof(mystruct) * size);
    int n = 0;

    char domain[300];
    char trash[900];

    while (fscanf(f, " %s %[^\n]", domain, trash) != EOF) {
        n = insert(P, domain, n, &size);
    }

    strcpy(output, "records_");

    strcat(output, filename);

    f = fopen(output, "w");

    for (int i = 0; i < n; i++) {
        fprintf(f, "%s %d\n", P[i].hostname, P[i].v);
    }

    // for (int i = 0; i < n; i++) {
    //     free(P[i].hostname);
    // }
    // free(P);


    return 0;
}


int insert(mystruct *P, char *s, int n, int *size){
    int new_n;
    int exist = 0;


    for (int i = 0; i < n && exist == 0; i++) {
        if (strcmp(P[i].hostname, s) == 0) {
            P[i].v++;
            exist = 1;
        }
    }

    if (exist == 0) {
        if (n == *(size)) {
            *(size) = *(size) + 20;
            printf("%d\n", *(size));
            P = (mystruct*) realloc(P, *(size));
            if (P == NULL)
              printf("erroo\n" );
        }

        P[n].v = 1;
        printf("%d ", P[n].v);

        P[n].hostname = malloc(sizeof(char) * 100);
        strcpy(P[n].hostname, s);
        printf("%s\n", P[n].hostname);
        new_n = n + 1;
    } else {
        new_n = n;
    }


    return new_n;
}
