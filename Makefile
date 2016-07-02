CC=gcc
CXX=g++
LD=g++
CFLAGS=-O3 -march=native -fstack-protector=strong
CXXFLAGS=-O3 -march=native-fstack-protector=strong
LEX=flex
YACC=bison
all: mumei

mumei: mumei.tab.o lex.yy.o 
	$(LD) -o $@ $^ -lfl

lex.yy.o: lex.yy.c 
	$(CXX) $(CPPFLAGS) -c -o $@ $^

mumei.tab.o: mumei.tab.c
	$(CXX) $(CPPFLAGS) -c -o $@ $^

lex.yy.c: mumei.tab.c
	$(LEX) mumei.l

mumei.tab.c:
	$(YACC) -d mumei.y

.PHONY: clean all
clean:
	rm -rf mumei.tab.c mumei.tab.h lex.yy.c mumei *.o