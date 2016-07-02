%{
#include <cstdio>
#include <iostream>
#include <vector>
#include <fstream>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
using namespace std;
extern "C" int yylex();
extern "C" int yyparse();
extern "C" FILE *yyin;
void yyerror(const char *s);
vector<string> nameTable;
int getVarID(string name) {
	auto it=nameTable.end();
	for(auto it=nameTable.begin(); it!=nameTable.end(); it++) {
		if(nameTable[it-nameTable.begin()]==name)
			return it-nameTable.begin();
	}
	nameTable.push_back(name);
	return nameTable.size()-1;
}
vector<string> argTable;
int getArgID(string name) {
	auto it=argTable.end();
	for(auto it=argTable.begin(); it!=argTable.end(); it++) {
		if(argTable[it-argTable.begin()]==name) {
			return (int)(it-argTable.begin())-(int)(argTable.size())-1;
    }
	}
	return 0;
}
void createArg(string arg) {
  argTable.push_back(arg);
}
ofstream out;
%}
%union {
  int ival;
  char* sval;
}
%token <ival> INT
%token PLUS
%token MINUS
%token MUL
%token LPARENS
%token RPARENS
%token DIV
%token <sval> VARNAME
%token EQ
%token COMMA
%token FUNCTION
%token END
%left PLUS MINUS MUL DIV FUNCTION
%right EQ
%%
program:
  fh function ef program
  | fh function ef
fh:
  FUNCTION VARNAME LPARENS args RPARENS {out << $2 << ":\n\tbpget\n\tspget\n\tbpset" << endl;}
  | FUNCTION VARNAME LPARENS RPARENS {out << $2 << ":\n\tbpget\n\tspget\n\tbpset" << endl;}
args:
  VARNAME COMMA args {createArg($1);}
  | VARNAME {createArg($1);}
ef:
  END {out << "\tbpget\n\tspset\n\tbpset\n\tret"<<endl;argTable.clear();}
function:
  VARNAME EQ exp function {out << "\t[ci:2] store "<<getVarID($1)*4 << endl;}
  | VARNAME EQ exp {out << "\t[ci:2] store "<<getVarID($1)*4 << endl;}
  | exp function {out << "\tdrop" << endl;}
  | exp {out << "\tdrop" << endl;}
exp:
  factor
  | exp PLUS exp { out << "\tadd" <<endl;}
  | exp MINUS exp { out << "\tsub" <<endl;}
factor:
  num 
  | factor MUL factor {out << "\tmul" << endl;}
  | factor DIV factor {out << "\tdiv" << endl;}
num:
  INT { out << "\tpush "<< $1 << endl;}
  | VARNAME LPARENS fargs RPARENS {out << "\tcpget\n\tjmp @" << $1 << "\n\t[ci:2] load " << getVarID($1) << endl;}
  | VARNAME LPARENS RPARENS {out << "\tcpget\n\tjmp @" << $1 << "\n\t[ci:2] load " << getVarID($1) << endl;}
  | VARNAME { char* arg=$1; int id; if((id=getArgID(arg))==0) {out << "\t[ci:2]load "<<getVarID(arg)*4<<endl;} else {out<< "\tget "<< id << endl;}}
  | LPARENS exp RPARENS
fargs:
  exp COMMA fargs
  | exp
%%
int main(int argc, char** argv) {
  int pid;
  mkfifo("tmp.a", 0660);
  if(!(pid=fork())) {
    system("as -o tmp.o crt0.asm tmp.a libmtg.asm");
    return 0;
  }
  out=ofstream("tmp.a",ios::out);
  unlink("tmp.a"); //Unlink when done
  if(argc<=3)
    yyerror("usage: mumei -o outfile infile1 [infile2 [infile3 ...]]");
  if("-o"s!=argv[1])
    yyerror("usage: mumei -o outfile infile1 [infile2 [infile3 ...]]");
  for(int i=3;i<argc;i++) {
    FILE *f=fopen(argv[i],"rb");
    yyin = f;
    do {
      yyparse();
    } while (!feof(yyin));
    fclose(f);
  }
  out.close();
  wait(NULL);
  system(("explink -o "s+argv[2]+" -c tmp.o -C 0").c_str());
  unlink("tmp.o");
}

void yyerror(const char *s) {
	cout << "parse error!  Message: " << s << endl;
  out.close();
  fclose(yyin);
	exit(-1);
}
