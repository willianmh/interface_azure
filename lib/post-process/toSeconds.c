#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char const *argv[]) {
	char entrada[200];
	char hour[3][20];
	int hours;
	int minutes;
	float seconds;

	char *token;
	const char s[2] = ":";

	scanf(" %s", entrada);
	size_t len = strlen(entrada);

	token = strtok(entrada, s);
	int i = 0;
	while (token != NULL) {
		strcpy(hour[i], token);
		token = strtok(NULL, s);
		i++;
	}

	if (i == 3) {
		hours = atoi(hour[0]);
		minutes = atoi(hour[1]);
		seconds = atof(hour[2]);

		seconds = seconds + 60.0*minutes + 3600.0*hours;
	} else {
		minutes = atoi(hour[0]);
		seconds = atof(hour[1]);

		seconds = seconds + 60.0*minutes;
	}

	printf("%f\n", seconds);



	// for (int i = 0; i < len; i++)
	// 	if (entrada[i] == ':')
	// 		strncpy(first, entrada, i);
	//
	// if (entrada[i+3] == ':') {
	// 	hours = atof(first);
	//
	// }

	return 0;
}
