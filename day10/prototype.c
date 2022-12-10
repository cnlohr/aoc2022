// tcc -run prototype.c
#include <stdio.h>

int x = 1;
int cycle = 0;
int ackcyc = 20;
int dpycyc = 0;
int score = 0;

void CheckCur()
{
	cycle++;

	{
		if( dpycyc == 0 )
			printf("\n" );
		if( x < dpycyc-1 || x >= dpycyc+2 )
			printf( "." );
		else
			printf( "#" );
		dpycyc++;
		if( dpycyc == 40 ) dpycyc = 0;
	}

	if( cycle >= ackcyc )
	{
		//printf( "CYCLE: %d X: %d\n", cycle, x );
		score += x * ackcyc;
		ackcyc += 40;
	}
}

int main()
{
	FILE * f = fopen( "sample.txt", "r" );

	while( !feof( f ) )
	{
		char buf[1024];
		char * line;
		size_t len;
		ssize_t nread = getline( &line, &len, f );
		if( nread < 0 ) return;
		int ix;
		int l = sscanf( line, "%1023s %d\n", buf, &ix );

		CheckCur();
		
		if( l == 2 )
		{
			//AddX
			CheckCur();			
			x+=ix;
		}
		// Else, nop.
	}

	printf( "Score: %d\n", score );
}
