//Modify this file to change what commands output to your statusbar, and recompile using the make command.
static const Block blocks[] = {
	/*Icon*/	/*Command*/		/*Update Interval*/	/*Update Signal*/
	{"",	"sb-tasks",	10,	26},
	/*{"",	"sb-crypto_btc",	3600,	21},*/
	/*{"",	"sb-crypto_eth",	3600,	22},*/
	/*{"",	"sb-crypto_xmr",	3600,	23},*/
	/*{"",	"sb-crypto_ada",	3600,	24},*/
	{"",	"sb-cpu",		10,	18},
	{"",	"sb-clock",	60,	1},
	{"",	"sb-torrent",	20,	7},
	/* {"",	"sb-memory",	10,	14}, */
	/*{"",	"sb-mailbox",	180,	12},*/
	{"",	"sb-nettraf",	1,	16},
	{"",	"sb-internet",	5,	4},
	{"",	"sb-volume",	0,	10},
	{"",	"sb-battery",	5,	3},
};

//Sets delimiter between status commands. NULL character ('\0') means no delimiter.
static char *delim = " ";

// Have dwmblocks automatically recompile and run when you edit this file in
// vim with the following line in your vimrc/init.vim:

// autocmd BufWritePost ~/.local/src/dwmblocks/config.h !cd ~/.local/src/dwmblocks/; sudo make install && { killall -q dwmblocks;setsid dwmblocks & }
