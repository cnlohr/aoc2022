#include <stdio.h>

#define TREEX 99
#define TREEY 99

char treecounted[TREEX*TREEY];
char treeat[TREEX*TREEY];

int main()
{
	int i;
	i = 0;
	do
	{
		int c = getchar();
		if( c == EOF )
		{
			fprintf( stderr, "Error: can't do tree.\n" );
			return -5;
		}
		if( c >= '0' && c <= '9' )
			treeat[i++] = c;
	} while( i < TREEX*TREEY );

	int x, y;
	int visiblecount = 0;
	for( y = 1; y < TREEY-1; y++ )
	{
		x = 0;
		int highest = treeat[x+y*TREEX];
		for( x = 1; x < TREEX-1; x++ )
		{
			if( treeat[x+y*TREEX] > highest )
			{
				highest = treeat[x+y*TREEX];
				if( !treecounted[x+y*TREEX] ) visiblecount++;
				treecounted[x+y*TREEX] = 1;
			}
		}

		x = TREEX-1;
		highest = treeat[x+y*TREEX];
		for( x = TREEX-2; x > 0; x-- )
		{
			if( treeat[x+y*TREEX] > highest )
			{
				highest = treeat[x+y*TREEX];
				if( !treecounted[x+y*TREEX] ) visiblecount++;
				treecounted[x+y*TREEX] = 1;
			}
		}
	}
	
	for( x = 1; x < TREEX-1; x++ )
	{
		y = 0;
		int highest = treeat[x+y*TREEX];
		for( y = 1; y < TREEX-1; y++ )
		{
			if( treeat[x+y*TREEX] > highest )
			{
				highest = treeat[x+y*TREEX];
				if( !treecounted[x+y*TREEX] ) visiblecount++;
				treecounted[x+y*TREEX] = 1;
			}
		}

		y = TREEX-1;
		highest = treeat[x+y*TREEX];
		for( y = TREEX-2; y > 0; y-- )
		{
			if( treeat[x+y*TREEX] > highest )
			{
				highest = treeat[x+y*TREEX];
				if( !treecounted[x+y*TREEX] ) visiblecount++;
				treecounted[x+y*TREEX] = 1; 
			}
		}
	}
	
	printf( "Sides: %d + %d = %d\n", visiblecount, ((TREEX-1)+(TREEY-1))*2, visiblecount + ((TREEX-1)+(TREEY-1))*2 );

	int bestscore = 0;
	int atx, aty;
	for( y = 0; y < TREEY; y++ )
	for( x = 0; x < TREEX; x++ )
	{
		int score[4] = { 0 };
		int height = treeat[x+y*TREEX];
		int hsofar = '0';
		int do_debug = (x==4  && y==51);

		for( i = x+1; i < TREEX; i++ )
		{
			int t = treeat[i+y*TREEX];
			//if( t >= hsofar )
			{
				score[0]++;
				hsofar = t;
			}
			if( t >= height ) break;
		}
		hsofar = '0';
		for( i = x-1; i >= 0; i-- )
		{
			int t = treeat[i+y*TREEX];
			//if( t >= hsofar )
			{
				score[1]++;
				hsofar = t;
			}
			if( t >= height ) break;
		}
		hsofar = '0';
		for( i = y+1; i < TREEY; i++ )
		{
			int t = treeat[x+i*TREEX];
			//if( t >= hsofar )
			{
				score[2]++;
				hsofar = t;
			}
			if( t >= height ) break;
		}
		hsofar = '0';
		for( i = y-1; i >= 0; i-- )
		{
			int t = treeat[x+i*TREEX];
			//if( t >= hsofar )
			{
				score[3]++;
				hsofar = t;
			}
			if( t >= height ) break;
		}
		int this_score = score[0] * score[1] * score[2] * score[3];
		if( do_debug ) printf( "%d %d %d %d %d %d %d \n", x, y, score[0], score[1], score[2], score[3], this_score );
		if( this_score > bestscore ) { bestscore = this_score; atx = x; aty = y; }
	}
	printf( "Best Score: %d (%d %d)\n", bestscore, atx, aty );
}

/*
 It's not 1470, 1296, 320  (Maybe tried 450)
 */