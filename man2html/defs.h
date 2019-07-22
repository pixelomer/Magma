extern int nroff;
extern int local_lynx;

typedef struct STRDEF STRDEF;
struct STRDEF {
    int nr,slen;
    char *st;
    STRDEF *next;
};

typedef struct INTDEF INTDEF;
struct INTDEF {
    int nr;
    int val;
    int incr;
    INTDEF *next;
};

extern STRDEF *chardef, *strdef, *defdef;
extern INTDEF *intdef, *nargdef, *curfdef;

#define V(A,B) ((A)*256+(B))
#define V4(A,B,C,D) ((((((((A)*256)+(B))*256)+(C))*256)+(D)))

#include <sys/types.h>
extern void stdinit(void);
extern char *lookup_abbrev(char *);
extern void include_file_html(char *);
extern void ftp_html(char *);
extern void www_html(char *);
extern void mailto_html(char *);
extern void url_html(char *);
extern void set_separator(char);
extern void set_lynxcgibase(char *);
extern void set_cgibase(char *);
extern void set_man2htmlpath(char *);
extern void set_relative_html_links(void);
extern void *xmalloc(size_t size);
extern void *xrealloc(void *ptr, size_t size);
extern char *xstrdup(const char *s);
