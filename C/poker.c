#include <libgen.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

typedef struct card {
    int rank;
    int suit;
} card_t;

#define RANKZ   13
#define SUITZ    4
#define MAXCRDZ 52

card_t deck[MAXCRDZ];
card_t *dptr = deck;     /* deck pointer */
#define di (dptr - deck) /* deck index   */

char *ranksym = "23456789TJQKA";
char *suitsym = "cdhs";

card_t gamecard[MAXCRDZ]; /*           cards in play */
card_t *dashptr[MAXCRDZ]; /* ptrs of empty gamecards */

int *wincntr;  /* win counter for each player */

int playerz;   /* number of players        */
int dashez;    /* number of dashes         */
int gamecardz; /* number of gamecards      */
int scardz;    /* number of scenario cards */

#define PKT     2 /* pocket               */
#define CMTY    5 /* community            */
#define HNDCRDZ 5 /* number of hand cards */
#define COMBOZ  7 /* combinations         */
//
void usage(char *prognom)
{
    printf("Usage: %s ", basename(prognom));
    puts("[-h] [-m maxgames] [\"poktbl\"]");
}
// respect
void spit(char *fmt, ...)
{
     va_list args;

     va_start (args, fmt);
     vprintf (fmt, args);
     va_end (args);
}
// reset deck
void rstdeck(void)
{
    int ace = RANKZ - 1; // ace rank
    card_t *d = deck;    // iterator

    for (int r, s = 0; s < SUITZ; s++) {
	*d++ = (card_t) {ace, s};
	for (r = 0; r < ace; r++)
	    *d++ = (card_t) {r, s};
    }
}
//
void dumpcard(card_t *c)
{
    spit("%c", ranksym[c->rank]);
    spit("%c", suitsym[c->suit]);
}
//
void delim(bool cond)
{
    static char d[] = {'\n', ' '};

    putchar(d[cond]);
}
//
void dumpcards(card_t *c, int n)
{
    for (int j = 0; j < n; j++) {
	dumpcard(c + j);
	delim(j < n - 1);
    }
}
#define CLR "\033[1;31m"
#define RST "\033[0m"
// colorized card at dptr
void dumpdeck(void)
{
    for (int j = 0; j < MAXCRDZ; j++) {
    	if (j == di) {
    	    spit(CLR);
	    dumpcard(deck + j);
    	    spit(RST);
    	} else {
    	    dumpcard(deck + j);
    	}
	delim((j + 1)%RANKZ);
    }
}
// |0|1|2|...|j-1|j|... -> |j|0|1|...|j-2|j-1|...
void putinfront(int j)
{
    card_t t = deck[j];

    for (int i = j; i > 0; i--) {
	deck[i] = deck[i - 1];
    }
    deck[0] = t;
}
//
int search(char rank, char suit)
{
    card_t c;

    for (int j = di; j < MAXCRDZ; j++) {
	c = deck[j];
	if (ranksym[c.rank] == rank && 
	    suitsym[c.suit] == suit) return j;
    }
    return -1;
}
// reset deck pointer
void rstdptr(void)
{
    dptr = deck + scardz;
}
//
void parser(char *poktbl)
{
    char c;
    card_t *p = gamecard, **q = dashptr; // iterators

    while ((c = *poktbl++)) {
	switch (c) {
	case ' ':
	    playerz++;
	    continue;
	case '-':
	    dashez++;
	    *q++ = p;
	    break;
	default: // a card
	    putinfront(search(c, *poktbl++));
	    *p = deck[0];
	    break;
	}
	gamecardz++;
	p++;
    }
    scardz = gamecardz - dashez;
    rstdptr();
}
//
void init(char *poktbl)
{
    srand(time(NULL));
    rstdeck();
    playerz = dashez = gamecardz = 0;
    parser(poktbl);
    wincntr = calloc(playerz, sizeof (int));
}
// [min, max]
int getrand(int min, int max)
{
    return min + rand()%(max - min + 1);
}
//
void xch(int j, int i)
{
    card_t t = deck[j];
    deck[j] = deck[i];
    deck[i] = t;
}
//
void shuffle(void)
{
    for (int j = MAXCRDZ - 1; j > di; j--)
	xch(j, getrand(di, j));
}
//
void dealcrds(void)
{
    for (int j = 0; j < dashez; j++)
	*dashptr[j] = *dptr++;
}
// returns a sorted hand in increasing order with
// respect to the card's value from left to right
// (insert sort)
void hndsort(card_t *hnd, int n)
{
    card_t key;
    
    for (int i, j = 1; j < n; j++) {
	key = hnd[j];
	for (i = j - 1; i > -1; i--) {
	    if (hnd[i].rank < key.rank)	break;
	    hnd[i + 1] = hnd[i];
	}
	hnd[i + 1] = key;
    }
}
// hand id
#define STR8FLUSH 8
#define FOUR	  7
#define FULLHOUSE 6
#define FLUSH	  5
#define STR8	  4
#define THREE	  3
#define TWOPAIRS  2
#define PAIR	  1
#define HICARD    0
// hand rank
typedef struct hndRnk {
    int id;
    int kicker[HNDCRDZ];
} hndRnk_t;
//
int isflush(card_t *hnd)
{
    for (int j = 1; j < HNDCRDZ; j++) {
	if (hnd[j].suit != hnd[j - 1].suit) return 0;
    }
    return 1;
}
// iswheel and isstr8 assume hand is sorted
int iswheel(card_t *hnd)
{
    static int wheel[] = {0, 1, 2, 3, 12};

    for (int j = 0; j < HNDCRDZ; j++) {
	if (hnd[j].rank != wheel[j]) return 0;
    }
    return 1;
}
//
int isstr8(card_t *hnd)
{
    for (int j = 1; j < HNDCRDZ; j++) {
	if (hnd[j].rank != hnd[j - 1].rank + 1) return 0;
    }
    return 1;
}
// this structure is for counting a PAIR, TWO PAIRS,
// THREE OF A KIND, FULL HOUSE and FOUR OF A KIND
struct cntr {
    int rank;
    int n;
} cntr[HNDCRDZ];
typedef struct cntr cntr_t;
// here again hnd is sorted in advance
void fillcntr(card_t *hnd)
{
    int j;
    card_t *crd = --hnd + HNDCRDZ; // last card (max rank)

    for (j = 0; crd > hnd; j++) {
	cntr[j].rank = crd--->rank;
	cntr[j].n = 1;
	while (crd > hnd && crd->rank == (crd + 1)->rank) {
	    cntr[j].n++;
	    crd--;
	}
    }
    // clear remaining counters to zero
    for (; j < HNDCRDZ; j++) cntr[j].rank = cntr[j].n = 0;
}
//
void dumpcntr(void)
{
    int j = 0;
    cntr_t *c;

    while ((c = &cntr[j++])->n) {
	spit("%c", ranksym[c->rank]);
	spit(" %d\n", c->n);
    }
}
// sort by count
void sortcntr(void)
{
    cntr_t key;

    for (int i, j = 1; j < HNDCRDZ; j++) {
	key = cntr[j];
	i = j - 1;
	while (i > -1 && cntr[i].n < key.n) {
	    cntr[i + 1] = cntr[i];
	    i--;
	}
	cntr[i + 1] = key;
    }
}
// hnd should be sorted
hndRnk_t eval(card_t *hnd)
{
    int flush = isflush(hnd);
    int wheel = iswheel(hnd);
    int str8 = isstr8(hnd);
    hndRnk_t hndrnk = {HICARD, {-1, -1, -1, -1, -1}};
    int j, z = HNDCRDZ - 1; /* last index */
    hndrnk.kicker[0] = hnd[z].rank;
    if (str8 || wheel) {
	if (wheel) hndrnk.kicker[0] = hnd[z - 1].rank;
	hndrnk.id = flush ? STR8FLUSH : STR8;
	return hndrnk;
    }
    if (flush) {
	hndrnk.id = FLUSH;
	for (j = 1; j < HNDCRDZ; j++)
	    hndrnk.kicker[j] = hnd[z - j].rank;
	return hndrnk;
    }
    fillcntr(hnd);
    sortcntr();
    for (j = 0; j < HNDCRDZ; j++) {
	if (cntr[j].n == 0) break;
	hndrnk.kicker[j] = cntr[j].rank;
    }
    switch (cntr[0].n) {
    case 4:
	hndrnk.id = FOUR;
	break;
    case 3:
	hndrnk.id = THREE;
	if (cntr[1].n == 2)
	    hndrnk.id = FULLHOUSE;
	break;
    case 2:
	hndrnk.id = PAIR;
	if (cntr[1].n == 2)
	    hndrnk.id = TWOPAIRS;
	break;
    default:
	break;
    }
    return hndrnk;
}
//
void dumpHndRnk(hndRnk_t hndrnk)
{
    char str[] = "----------------|---|---|---|---|---";
    char *name[] = {"HICARD",
		    "PAIR",
		    "TWOPAIRS",
		    "THREE",
		    "STR8",
		    "FLUSH",
		    "FULLHOUSE",
		    "FOUR",
		    "STR8FLUSH"};
    int id = hndrnk.id;
    int len = strlen(name[id]);
    memcpy(str + 14 - len + 1, name[id], len);
    for (int j = 0; j < HNDCRDZ; j++) {
	if (hndrnk.kicker[j] != -1)
	    str[18 + j*4] = ranksym[hndrnk.kicker[j]];
    }
    puts(str);
}
// Knuth
int nextcombo(int k, int *c)
{
    int i;
    /* find i */
    for (i = 0; c[i] + 1 == c[i + 1]; i++)
	c[i] = i;
    /* fin */
    if (i == k)	return 0;
    /* increment */
    return ++c[i];
}
#define ck(X, Y) {				\
	if ((X) > (Y)) return 1;		\
	if ((X) < (Y)) return 2;		\
    }
//
int cmp(hndRnk_t a, hndRnk_t b)
{
    ck(a.id, b.id);
    for (int j = 0; j < HNDCRDZ; j++)
	ck(a.kicker[j], b.kicker[j]);
    return 0;
}
/* from the combination of player's pocket cards
 * and the community cards the function generates
 * all possible combinations and returns the hand
 * with maximum rank (i is the player's index) */
hndRnk_t getHndRnk(int i)
{
    int j = 0;
    static card_t combo[COMBOZ];

    /* get player's pocket cards */
    i *= PKT;
    while (j < PKT)
    	combo[j++] = gamecard[i++];
    /* get community cards */
    i = playerz*PKT;
    while (j < COMBOZ)
    	combo[j++] = gamecard[i++];

    hndsort(combo, COMBOZ);

    /* generate all possible hands */
    static int c[HNDCRDZ + 2];
    int k = HNDCRDZ;
    int n = COMBOZ;

    for (j = 0; j < k; j++) {
	c[j] = j;
    }
    c[k] = n;
    c[k + 1] = 0;

    static card_t hnd[HNDCRDZ];
    hndRnk_t hndrnk;
    hndRnk_t max = {-1, {-1, -1, -1, -1, -1}};
    do {
	for (j = 0; j < k; j++) {
	    hnd[j] = combo[c[j]];
	}
	hndrnk = eval(hnd);
	if (cmp(hndrnk, max) == 1) max = hndrnk;
    } while (nextcombo(k, c));
    return max;
}
//
void finalize(void)
{
      free(wincntr);
}
/* coz of the split win we save winners az bit positions */
void showdown(void)
{
    int j = 0;      // index
    int w = 1 << j; // bit positions
    hndRnk_t hndrnk, win = getHndRnk(j);
#ifdef DEBUG
    dumpHndRnk(win);
#endif
    for (j = 1; j < playerz; j++) {
    	hndrnk = getHndRnk(j);
#ifdef DEBUG
    	dumpHndRnk(hndrnk);
#endif
    	switch (cmp(hndrnk, win)) {
    	case 0: // split
    	    w |= (1 << j);
    	    break;
    	case 1:
    	    win = hndrnk;
    	    w = 1 << j;
    	    break;
    	default:
    	    break;
    	}
    }
#ifdef DEBUG
    spit("... and the winners are ");
#endif
    for (j = 0; j < playerz; j++) {
#ifdef DEBUG
	spit("%i", (w >> j) & 1);
#endif
	if ((w >> j) & 1) wincntr[j]++;
    }
#ifdef DEBUG
    putchar('\n');
    dumpHndRnk(win);
#endif
}
int main(int argc, char *argv[])
{
    int opt;
    char *prognom = argv[0];
    /* defaults */
    int maxgames = 100;
    char *poktbl = "AhAs -- -- -----"; /* poker table */

    while ((opt = getopt(argc, argv, "hm:")) != -1) {
    	switch (opt) {
    	case 'h':
    	    usage(prognom);
    	    return 0;
    	case 'm':
    	    maxgames = atoi(optarg);
    	    break;
    	default:
    	    usage(prognom);
    	    return EXIT_FAILURE;
    	}
    }
    if (optind < argc) {
 	poktbl = argv[optind];
    }
    init(poktbl);
#ifdef DEBUG
    spit("maxgames  = %i\n", maxgames);
    spit("poktbl    = %s\n", poktbl);
    spit("playerz   = %i\n", playerz);
    spit("dashez    = %i\n", dashez);
    spit("gamecardz = %i\n", gamecardz);
#endif
    // !!! test zone !¿!
    int j, game = 0;
    while (true) {
 	shuffle();
 	while (di <= MAXCRDZ - dashez) {
 	    dealcrds();
#ifdef DEBUG
 	    for (j = 0; j < playerz; j++) {
 		dumpcards(gamecard + PKT*j, PKT);
	    }
 	    dumpcards(gamecard + playerz*PKT, CMTY);
	    dumpdeck();
#endif
 	    showdown();
	    if (++game == maxgames) goto f;
 	}
 	rstdptr();
    }
 f:
    for (j = 0; j < playerz; j++)
    	spit("%3.2f\n", (100*wincntr[j])/(float) maxgames);
    finalize();
    return 0;
}
