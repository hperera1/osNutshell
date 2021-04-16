%{
#include <dirent.h>
#include <sys/types.h>
#include <pwd.h>
#include <fnmatch.h>
#include <errno.h>
#include <fcntl.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/wait.h>
#include "global.h"

int yylex();
int yyerror(char *s);

// linked list
struct node {
	struct node*	next;
	char*		value;
};

struct linked_list {
	struct node	*head, **tail;
	int length;
};

struct linked_list *new_list() {
	struct linked_list *rv = malloc(sizeof(struct linked_list));
	rv -> head = 0;
	rv ->tail = &rv->head;
	rv->length = 0;
	return rv;
}

void push_back(struct linked_list *list, char* value) {
	struct node *node = malloc(sizeof(struct node));
	node->next = 0;
	node->value = value;
	*list->tail = node;
	list->tail = &node->next;
	list->length = list->length + 1;
}

void pushback_wildcard(struct linked_list *list, char* wildcard){

	int num_matches = 0;

	DIR *d;
	struct dirent *dir;
	d = opendir(".");
	if (d) {
		while ((dir = readdir(d)) != NULL){
			if(fnmatch(wildcard, dir->d_name, 0) == 0){
				num_matches += 1;
				push_back(list, dir->d_name);
			}
		}
		closedir(d);
	}

	if(num_matches == 0){
		int iter = 0;

		const char ast = '*';
		const char que = '?';

		char* new_string = malloc(PATH_MAX*sizeof(char));
		for (int i = 0; wildcard[i] != '\0'; ++i){
			if ((wildcard[i] == ast) || (wildcard[i] == que)){
				continue;
			}
			new_string[iter++] = wildcard[i];
		}
		new_string[iter] = '\0';
		strcpy(wildcard, new_string);
		free(new_string);
		push_back(list, wildcard);
	}

}

// command driving/routing
int cmd(struct linked_list *args);

// pipe handlers
char* inHandler(struct linked_list* args1, struct linked_list* args2);
char* outHandler(struct linked_list* args1, struct linked_list* args2);
char* pipeHandler(struct linked_list* args1, struct linked_list* args2);
void appender(char* src, char* dest);
void copier(char* src, char* dest);
void printOutput();

// built in functions including helper/tester functions
int testingFunction(struct linked_list *args);
int startPrintenv();
int setEnv(char *variable, char *word);
int unsetEnv(char *variable);
int changeDirectory(char *directory);
int setAlias(char *variable, char *word);
int unsetAlias(char *variable);
int listAlias();
int setPath(char *variable, char* word);
int builtInCheck(char *input);
int isLoop(char* name, char* word);
char* expandEnv(char* text);

%}

%union {char *string; struct linked_list *list;}

%start cmd_line
%token <string> TESTING STRING END IN OUT TO ENVSTRING WILDCARD APPEND
%type <list> args pipes
%%

args :	STRING					{push_back($$ = new_list(), $1);}
	| args STRING				{push_back($$ = $1, $2);}
	| args ENVSTRING			{$2 = expandEnv($2); push_back($$ = $1, $2);}
	| args WILDCARD				{pushback_wildcard($$ = $1, $2);}
	;

pipes:	args IN args				{//printf("in args in args\n"); 
						 execute = 0;
						 piping = 1; firstPipe = 1; char* fileName = inHandler($1, $3); push_back($$ = $3, fileName);}

	| args OUT args				{//printf("in args out args\n"); 
						 execute = 0;
						 piping = 1; firstPipe = 1; char* fileName = outHandler($1, $3); push_back($$ = $3, fileName);}
	| args TO args				{//printf("in args to args\n"); 
						 piping = 1; firstPipe = 1; execute = 1;
						 //testingFunction($1); testingFunction($3);
						 char* fileName = pipeHandler($1, $3); push_back($$ = $3, fileName);}
	| args APPEND args			{//printf("in args append args\n"); 
						 execute = 0;
						 piping = 1; firstPipe = 1; appending = 1; char* fileName = outHandler($1, $3); push_back($$ = $3, fileName);}
	| pipes IN args				{//printf("in pipes in args\n"); 
						 execute = 0;
						 piping = 1; char* fileName = inHandler($1, $3); push_back($$ = $3, fileName);}
	| pipes OUT args			{//printf("in pipes out args\n"); 
						 execute = 0;
						 piping = 1; char* fileName = outHandler($1, $3); push_back($$ = $3, fileName);}
	| pipes TO args				{//printf("in pipes to args\n"); 
						 execute = 1;
						 piping = 1; char* fileName = pipeHandler($1, $3); push_back($$ = $3, fileName);}
	| pipes APPEND args			{//printf("in pipes append args"); 
						 execute = 0;
						 piping = 1; appending = 1; char* fileName = outHandler($1, $3); push_back($$ = $3, fileName);}
	;

cmd_line :
	pipes END				{
							//printf("in pipes end\n"); 
							piping = 1;
							
							if(execute == 1)
								cmd($1);

							//printf("postcmd\n");
							piping = 0;

							if(piping == 0)
							{
								printOutput();
							}

							fopen(".output.txt", "w");
							remove(".input.txt"); 
							remove(".output.txt"); 
							//printf("?????\n");
							return 1;
						}
	| args END				{
							//printf("in args end\n");
							firstPipe = 0;
							piping = 0;
							//testingFunction($1);
							cmd($1);
 
							return 1;
						}

%%

int yyerror(char *s)
{
	printf("%s\n", s);
	return 0;
}

char* inHandler(struct linked_list* args1, struct linked_list* args2)
{
	char* fileName = ".input.txt";
	push_back(args1, args2->head->value);
	cmd(args1);	
	copier(".output.txt", fileName);

	return fileName;
}

char* outHandler(struct linked_list* args1, struct linked_list* args2)
{
	char* fileName = ".input.txt";

	//testingFunction(args1);
	//testingFunction(args2);

	int savedStd;
	savedStd = dup(1);

	//pipeFile2 = open(args2->head->value, O_WRONLY|O_CREAT, 0666);	
	//dup2(pipeFile2, 1);
	cmd(args1);
	
	if(appending == 1)
	{
		copier(".output.txt", fileName);
		//printOutput();
		appender(fileName, args2->head->value);
	}
	else
	{
		copier(".output.txt", fileName);
		copier(fileName, args2->head->value);
	}

	appending = 0;	
	fopen(".output.txt", "w");
	dup2(savedStd, 1);
	close(savedStd);

	return fileName;
}

char* pipeHandler(struct linked_list* args1, struct linked_list* args2)
{
	char* fileName = ".input.txt";

	// setting flags
	cmd(args1);
	firstPipe = 0;

	copier(".output.txt", fileName);
	fopen(".output.txt", "w");

	return fileName;
}

void copier(char* src, char* dest)
{
	/*
	int savedStd;
	int savedErr;
	savedStd = dup(1);
	savedErr = dup(2);
	dup2(savedErr, 1);
	*/

	//if(access(".output.txt", F_OK) == -1)
	//{
	//	printf("creating output.txt\n");
	//	pipeFile2 = open(".output.txt", O_WRONLY|O_CREAT, 0666);
	//}

	pid_t pid;
	if((pid = fork()) == -1)
		perror("fork error\n");
	else if(pid == 0)
		execl("/bin/cp", "cp", src, dest, NULL);
	else
		wait(NULL);

	//dup2(savedStd, 1);
	//close(savedStd);
	//close(savedErr);
}

void appender(char* src, char* dest)
{
	FILE* file1;
	FILE* file2;
	char c;

	file1 = fopen(src, "r");
	file2 = fopen(dest, "a");

	if(!file1 && !file2)
	{
		printf("appending error\n");
		return;
	}

	c = fgetc(file1);
	while(c != EOF)
	{
		fputc(c, file2);
		c = fgetc(file1);
	}

	fclose(file1);
	fclose(file2);
}

void printOutput()
{
	FILE* file;
	char c;
	file = fopen(".output.txt", "r");
	c = fgetc(file);
	while(c != EOF)
	{
		printf("%c", c);
		c = fgetc(file);
	}

	fclose(file);
	fopen(".output.txt", "w");
}


int cmd(struct linked_list* args)
{
	int otherStd;
	otherStd = dup(1);

	//if(firstPipe == 1)
	//{
		//pipeFile1 = open("input.txt", O_WRONLY|O_CREAT, 0666);
		//pipeFile2 = open("output.txt", O_WRONLY|O_CREAT, 0666);
	//}

	if(piping == 1)
	{
		pipeFile1 = open(".input.txt", O_WRONLY|O_CREAT, 0666);
		pipeFile2 = open(".output.txt", O_WRONLY|O_CREAT, 0666);
		//dup2(pipeFile2, 1);
	}

	if(strcmp(args->head->value, "printenv") == 0){
		if(args->length == 1){
			if(piping == 1) dup2(pipeFile2, 1);
			startPrintenv();
			dup2(otherStd, 1); 
			close(otherStd);
			
			return 1;
		}
		
		printf("syntax error");
		return 1;
	}
	else if(strcmp(args->head->value, "alias") == 0){
		if(args->length == 1){
			if(piping == 1) dup2(pipeFile2, 1);
			listAlias();
			dup2(otherStd, 1); 
			close(otherStd);

			return 1;
		}
		else if(args->length == 3){
			setAlias(args->head->next->value, args->head->next->next->value);
			return 1;
		}
			printf("syntax error");
			return 1;
	}
	else if(strcmp(args->head->value, "bye") == 0){
		if(args->length == 1){
			exit(1);
		}

		printf("syntax error");
		return 1;
	}
	else if(strcmp(args->head->value, "cd") == 0){
		if(args->length == 1){
			changeDirectory("");
			return 1;
		}
		else if(args->length == 2){
			changeDirectory(args->head->next->value);
			return 1;
		}

		printf("syntax error");
		return 1;
	}
	else if(strcmp(args->head->value, "unsetenv") == 0){
		if(args->length == 2){
			unsetEnv(args->head->next->value);
			return 1;
		}

		printf("syntax error");
		return 1;
	}
	else if(strcmp(args->head->value, "unalias") == 0){
		if(args->length == 2){
			unsetAlias(args->head->next->value);
			return 1;
		}

		printf("Syntax Error");
		return 1;
	}
	else if(strcmp(args->head->value, "setenv") == 0){
		if(args->length == 3){
			setEnv(args->head->next->value, args->head->next->next->value);
			return 1;
		}

		printf("syntax error");
		return 1;
	}
	else if(strcmp(args->head->value, "alias") == 0){
		if(args->length == 3){
			setAlias(args->head->next->value, args->head->next->next->value);
			return 1;
		}
		printf("syntax error");
		return 1;
	}
	else
	{
		int forked = 0;
		int savedStd;
		savedStd = dup(1);
		pid_t pid;
		int returnVal;

		if(firstPipe == 1)
		{
			pipeFile1 = open(".input.txt", O_WRONLY|O_CREAT, 0666);
			pipeFile2 = open(".output.txt", O_WRONLY|O_CREAT, 0666);
		}

		const char slash = '/';
		const char colon = ':';
		int numPaths = 1;
		int pathIter = 0;
		char* pathVar = (char*) malloc(PATH_MAX * sizeof(char));
		pathVar = strdup(variableTable.word[3]);		

		for (int i = 0; i < strlen(variableTable.word[3]) ; i++){
			if(pathVar[i] == ':'){
				numPaths++;
			} 
		}

		for (int i = 0; i < numPaths; i++){
			int tempIter = 0;
			returnVal = 0;
			char* temp_path = (char*) malloc(PATH_MAX*sizeof(char));
	
			while((pathVar[pathIter] != colon) && (pathVar[pathIter] != '\0')){
				temp_path[tempIter] = pathVar[pathIter];
				pathIter++;
				tempIter++;
			}
			pathIter++;
			temp_path[tempIter] = slash;
			temp_path[tempIter+1] = '\0';

			strcat(&temp_path[tempIter], args->head->value);
			
			if(forked == 0)			
			{
				forked = 1;
				pid = fork();
			}

			if(pid == -1)
			{
				perror("fork error!");
			}
			else if(pid == 0)
			{
				int counter = 0;
				char* arguments[args->length+1];
				struct node* current = args->head;
				while (current != 0){
					arguments[counter] = current->value;
					current = current->next;
					counter += 1;
				}
				arguments[counter] = 0;
	
				if(piping == 1)
				{
					dup2(pipeFile2, 1);
					returnVal = execv(temp_path, arguments);	
					dup2(savedStd, 1);
					close(savedStd);

					if(returnVal == -1)
					{
						continue;
					}

				}
				else
				{
					returnVal = execv(temp_path, arguments);
				

					if(returnVal == -1)
					{
						continue;
					}
				}

				exit(1);
			}
			else
			{
				wait(NULL);
				if(returnVal != -1)
					break;
			}
				
			//printf("%d\n%d\n", returnVal, errno);
			free(temp_path);

			if(returnVal == 0 && errno == 2)
				break;

			if(returnVal == -1)
				continue;
		}
	}
	
	return 1;
}

int testingFunction(struct linked_list* args)
{
	printf("Input: ");
	struct node* current = args->head;
	while (current != 0){
		printf("%s ", current->value);
		current = current->next;
	}
	printf("\n");
	return 1;
}

int setEnv(char *variable, char *word)
{
	if(strcmp(variable, "PATH") == 0){
		setPath(variable, word);
		return 1;
	}

	for (int i = 0; i < variableIndex; i++)
	{
		if(strcmp(variableTable.var[i], variable)  == 0)
		{
			strcpy(variableTable.word[i], word);
			return 1;
		}
	}

	strcpy(variableTable.var[variableIndex], variable);
	strcpy(variableTable.word[variableIndex], word);
	variableIndex++;
	return 1;
}

int startPrintenv()
{
	printf("environment variables:\n");
	for(int i = 0; i < variableIndex; i++)
	{
		printf("%s = %s\n", variableTable.var[i], variableTable.word[i]);
	}

	return 1;
}

int unsetEnv(char *variable)
{
	int check = 1;
	if (strcmp(variable, "PATH") == 0){
		check = 0;
	}
	else if(strcmp(variable, "HOME") == 0){
		check = 0;
	}
	else if(strcmp(variable, "PWD") == 0){
		check = 0;
	}
	else if(strcmp(variable, "PROMPT") == 0){
		check = 0;
	}


	if(check == 0){
		printf("Cannot unset environment variable: %s\n", variable);
		return 1;
	}
	for (int i = 0; i < variableIndex; i++)
	{
		if(strcmp(variableTable.var[i], variable) == 0)
		{
			strcpy(variableTable.var[i], variableTable.var[variableIndex - 1]);
			strcpy(variableTable.word[i], variableTable.word[variableIndex - 1]);
			variableIndex--;

			return 1;
		}
	}

	printf("That variable is not defined.\n");
	return 1;
}

int changeDirectory(char *directory)
{
	if (strcmp(directory,"") == 0){
		chdir(variableTable.word[1]);
		strcpy(variableTable.word[0], variableTable.word[1]);
		setAlias(".", variableTable.word[1]);
		char temp[4096];
		char parent[4096];
		strcpy(temp, variableTable.word[1]);
		strcat(temp, "/..");
		if (chdir(temp) == 0){
			getcwd(parent, sizeof(cwd));
		}
		else{
			parent[0] = '\0';
		}
		if(strcmp(aliasTable.word[0], variableTable.word[1]) != 0){
			setAlias(".", variableTable.word[1]);
			setAlias("..", parent);
		}
		chdir(variableTable.word[1]);
		return 1;
	}
	else if (directory[0] != '/')
	{
		char parent[4096];
		char cur[4096];
		char temp[4096];

		strcat(variableTable.word[0], "/");
		strcat(variableTable.word[0], directory);

		if (chdir(variableTable.word[0]) == 0) //If we succesfully change directories
		{
			getcwd(cwd, sizeof(cwd));
			strcpy(variableTable.word[0], cwd);
			strcpy(cur, cwd);
			strcpy(temp, cwd);
			strcat(temp, "/..");
			if (chdir(temp) == 0){
				getcwd(cwd, sizeof(cwd));
				strcpy(parent, cwd);
			}		
			else{
				parent[0] = '\0';
			}
			chdir(cur);
			if(strcmp(aliasTable.word[0], cur) != 0){
				setAlias(".", cur);
				setAlias("..", parent);
			}
			return 1;
		}
		else
		{
			getcwd(cwd, sizeof(cwd));
			strcpy(variableTable.word[0], cwd);
			printf("Directory not found\n");
			return 1;
		}
	}
	else
	{
		char parent[4096];
		char cur[4096];
		char temp[4096];

		if (chdir(directory) == 0)
		{
			getcwd(cwd, sizeof(cwd));
			strcpy(variableTable.word[0], cwd);
			strcpy(cur, cwd);
			strcpy(temp, cwd);
			strcat(temp, "/..");
			if (chdir(temp) == 0){
				getcwd(cwd, sizeof(cwd));
				strcpy(parent, cwd);
			}
			else{
				parent[0] = '\0';
			}
			chdir(cur);
			if(strcmp(aliasTable.word[0], cur) != 0){
				setAlias(".", cur);
				setAlias("..", parent);
			}
			return 1;
		}
		else
		{
			printf("Directory not found\n");
			return 1;
		}
	}

	return 1;
}

int setAlias(char *variable, char *word)
{
	for(int i = 0; i < aliasIndex; i++)
	{
		if(strcmp(variable,word) == 0){
			printf("Error, expansion of \"%s\" would create a loop.\n", variable);
			return 1;
		}
		else if((strcmp(aliasTable.name[i], variable) == 0) && (strcmp(aliasTable.word[i], word) == 0)){
			printf("Error, expansion of \"%s\" would create a loop.\n", variable);
			return 1;
		}
		else if(isLoop(variable, word)){
			printf("Error, expansion of \"%s\" would create a loop.\n", variable);
			return 1;
		}
		else if(strcmp(aliasTable.name[i], variable) == 0)
		{
			strcpy(aliasTable.word[i], word);
			return 1;
		}
	}

	strcpy(aliasTable.name[aliasIndex], variable);
	strcpy(aliasTable.word[aliasIndex], word);
	aliasIndex++;

	return 1;
}

int unsetAlias(char *variable)
{
	for(int i = 0; i < aliasIndex; i++)
	{
		if(strcmp(aliasTable.name[i], variable) == 0)
		{
			strcpy(aliasTable.name[i], aliasTable.name[aliasIndex - 1]);
			strcpy(aliasTable.word[i], aliasTable.word[aliasIndex - 1]);
			aliasIndex--;

			return 1;
		}
	}

	printf("That variable is not defined.\n");
	return 1;
}

int listAlias()
{
	printf("aliases:\n");
	for(int i = 0; i < aliasIndex; i++)
	{
		printf("%s = %s\n", aliasTable.name[i], aliasTable.word[i]);
	}
	return 1;
}

int setPath(char* variable, char* word)
{
	for (int i = 0; i < variableIndex; i++){
		if(strcmp(variableTable.var[i], variable) == 0)
		{
			char new_path[4096];
			char tempPath[4096]; 
			char userName[4096];
			char entireName[4096];
			int tempIter = 0;
			int userIter = 0;
		
			new_path[0] = '\0';
			userName[0] = '\0';
			tempPath[0] = '\0';
			entireName[0] = '\0';
			strcpy(entireName, word);

			for (int j = 0; j < strlen(entireName); j++){
				if(word[j] == ':'){
					if(word[j+1] == '~'){
						tempPath[tempIter] = entireName[j];
						tempPath[tempIter + 1] = '\0';
						strcat(new_path, tempPath);

						strcpy(tempPath, "");
						tempIter = 0;

						//find the userName
						strcpy(userName, "");
						
						struct passwd* pwd;
						userIter = 0;
						for(int k = j+1; k < strlen(word); k++){
							if((word[k] == '/') || (word[k] == '0')){
								break;
							}
							strncat(userName,word+k,1);
						}
						j += strlen(userName);
						userName[userIter] = '\0';

						pwd = getpwnam(userName);
						if(pwd == NULL){
							strcat(tempPath, variableTable.word[1]);
							tempIter += strlen(variableTable.word[1]);
						}
						else{
							strcpy(tempPath, pwd->pw_dir);
							tempIter += strlen(pwd->pw_dir);
						}
					}
					else{
						tempPath[tempIter++] = word[j];
					}
				}
				else{
					tempPath[tempIter++] = word[j];
				}

			}

			tempPath[tempIter] = '\0';
			strcat(new_path, tempPath);

		//printf("Final: %s\n", new_path);
		strcpy(variableTable.word[i], new_path);
		}
	}
	return 1;
}

char* expandEnv(char* text){
	for (int i = 0; i < variableIndex; i++){
		if(strstr(text, variableTable.var[i]) != 0){
			char* new_string = (char*)malloc(PATH_MAX*sizeof(char));
			int iter = 0;
			
			while (*text) {
				if(strstr(text, variableTable.var[i]) == text){
					strcpy(&new_string[iter-2], variableTable.word[i]);
					iter += strlen(variableTable.word[i]);
					text += strlen(variableTable.var[i])+1;
				}
				else
					new_string[iter++] = *text++;
			}
			
			new_string[iter] = '\0';
			return new_string;
		}
	}
	return text;
}

int isLoop(char *name, char* word)
{
	char* expansion = (char*)malloc(PATH_MAX*sizeof(char));
	strcpy(expansion, word);
	char* old_expansion = strdup(" ");

	while(strcmp(old_expansion, expansion)){
		if(strcmp(name, expansion) == 0){
			return 1;
		}
		old_expansion = strdup(expansion);

		for(int i = 0; i < aliasIndex; i++){
			if(strcmp(aliasTable.name[i], expansion) == 0){
				expansion = strdup(aliasTable.word[i]);
				break;

			}
		}
	}

	if(strcmp(name, expansion) == 0){
		return 1;
	}

	return 0;
}
