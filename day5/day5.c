#include <stdio.h>

#define MAX_COLUMNS 11
#define MAX_DEPTH 80

int is_eof = 0;
int column_array[MAX_COLUMNS][MAX_DEPTH];
int column_length[MAX_COLUMNS];

void columnappend( int which_column, int c )
{
	int length = column_length[which_column]++;
	column_array[which_column][length] = c;
}

int columnpull( int which_column )
{
	int length = --column_length[which_column];
	return column_array[which_column][length];
}

void cargomoveFlip( int qty, int from, int to )
{
	int i;
	for( i = 0; i < qty; i++ )
	{
		columnappend( 0, columnpull( from ) );
	}
	for( i = 0; i < qty; i++ )
	{
		columnappend( to, columnpull( 0 ) );
	}
}

void cargomove( int qty, int from, int to )
{
	int i;
	for( i = 0; i < qty; i++ )
	{
		columnappend( to, columnpull( from ) );
	}
}

int readnumber()
{
	int c;
	int val = 0;
keepgoing:
	c = getchar();
	if( c == EOF ) { is_eof = 1; return -1; }
	if( c < '0' ) return val;
	if( c > '9' ) return val;
	val = val * 10;
	val = val + c - '0';
	goto keepgoing;
}

int dupstdintospace()
{
	int c;
keepgoing:
	c = getchar();
	if( c == EOF ) return -1;
	if( c == ' ' ) return 0;
	if( c == '\n' ) return 0;
	goto keepgoing;
}

void printtree()
{
	int i, j;
	int maxheight = 0;
	i = 0;

keep_reading:
	j = column_length[i];
	if( j > maxheight ) maxheight = j;
	i++;
	if( i < MAX_COLUMNS ) goto keep_reading;

	j = maxheight-1;

next_row:
	if( j < 0 ) goto done;
	i = 0;
next_col:
	if( j < column_length[i] )
		putchar( column_array[i][j] );
	else
		putchar( ' ' );
	i++;
	if( i <MAX_COLUMNS ) goto next_col;
	putchar( '\n' );
	j--;
	goto next_row;

done:
	putchar( '\n' );
}


int main()
{
	int c;
	int placeinline;
newline:
	placeinline = 0;
keep_reading:
	c = getchar();
	if( c == EOF ) goto abort;
	if( c == '\n' ) 
	{
		if( placeinline < 2 ) goto movemode;
		goto newline;
	}
	placeinline++;
	if( placeinline % 4 == 2 ) 
	{
		if( c >= 'A' && c <= 'Z' )
		{
			int which_column = placeinline / 4 + 1;
			columnappend( which_column, c );
		}
	}
	goto keep_reading;

	// Flip it all around.
movemode:
	placeinline = 0;
copystart:
	placeinline++;
	cargomove( column_length[placeinline], placeinline, MAX_COLUMNS-1 );
	cargomoveFlip( column_length[MAX_COLUMNS-1], MAX_COLUMNS-1, placeinline );
	if( placeinline < MAX_COLUMNS - 1 ) goto copystart;

donecopy:

	printtree();

keep_moving:

	dupstdintospace();
	int qty = readnumber();
	dupstdintospace();
	int from = readnumber();
	dupstdintospace();
	int to = readnumber();
	if( is_eof ) goto done;
//	cargomove( qty, from, to );     //Part 2
	cargomoveFlip( qty, from, to ); //Part 1
	goto keep_moving;

	//Part 1: JDTMRWCQJ
done:

	printtree();
	return 0;
abort:
	fprintf( stderr, "Error: Unexpected EOF found\n" );
	return 0;
}

