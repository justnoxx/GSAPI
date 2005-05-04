#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

#include <iapi.h>

typedef gs_main_instance *GSAPI__instance;

static SV *cb_io[3];

static int
run_cb(int idx, char *msg, int msglen)
{
  dSP;
  int cnt, rc;
  ENTER; SAVETMPS; PUSHMARK(SP);
  if(idx) {
    // for stdout/stderr string is passed.
    XPUSHs(sv_2mortal(newSVpvn(msg, msglen)));
  } else {
    // for stdin, length is passed.
    XPUSHs(sv_2mortal(newSViv(msglen)));
  }
  PUTBACK;
  cnt = call_sv(cb_io[idx], G_SCALAR);
  SPAGAIN;
  if(cnt != 1)
    croak("run_cb: function should return one argument");
  if(idx) {
        rc = POPi; 
  } else {
        SV *sv;
        char * p;
        STRLEN len;
        sv = POPs;
        p = SvPV(sv, len);
        if(len > msglen)
          croak("run_cb: too long string returned.");
        memcpy(msg, p, len);
        rc = len;
  }
  PUTBACK; FREETMPS; LEAVE;
  return rc;
}

static int
run_stdin(void *caller_handle, char *buf, int len)
{
  if(cb_io[0])
     return run_cb(0, buf, len);
  return 0;
}

static int
run_stdout(void *caller_handle, char *buf, int len)
{
  if(cb_io[1])
     return run_cb(1, buf, len);
  return 0;
}

static int
run_stderr(void *caller_handle, char *buf, int len)
{
  if(cb_io[2])
     return run_cb(2, buf, len);
  return 0;
}

MODULE = GSAPI		PACKAGE = GSAPI		


INCLUDE: const-xs.inc

void
revision()
  PROTOTYPE:
  PREINIT:
     gsapi_revision_t rev;
  PPCODE:
     gsapi_revision(&rev, sizeof(rev));
     EXTEND(SP, 4);
     PUSHs(sv_2mortal(newSVpv(rev.product,0)));
     PUSHs(sv_2mortal(newSVpv(rev.copyright, 0)));
     PUSHs(sv_2mortal(newSViv(rev.revision)));
     PUSHs(sv_2mortal(newSViv(rev.revisiondate)));

GSAPI::instance
new_instance()
  PROTOTYPE:
  PREINIT:
      gs_main_instance *inst = 0;
  CODE:
       gsapi_new_instance(&inst, 0); // we don't need to check rc.
       RETVAL = inst;
  OUTPUT:
       RETVAL

void
delete_instance(inst)
        GSAPI::instance inst
   PROTOTYPE: $
   CODE:
        gsapi_delete_instance(inst);
        

IV
set_stdio(inst, Fstdin, Fstdout, Fstderr)
        GSAPI::instance inst
        SV *Fstdin
        SV *Fstdout
        SV *Fstderr
    PROTOTYPE: $$$$
    PREINIT:
        int i;
    CODE:
       for(i = 0; i < 3; i++)
          if(!cb_io[i])
            cb_io[i] = NEWSV(0,0);
        sv_setsv(cb_io[0], Fstdin);
        sv_setsv(cb_io[1], Fstdout);
        sv_setsv(cb_io[2], Fstderr);
        RETVAL = gsapi_set_stdio(inst, run_stdin, run_stdout, run_stderr);
    OUTPUT:
        RETVAL
        
IV
init_with_args(inst, ...)
        GSAPI::instance inst
  PROTOTYPE: $;@
  PREINIT:
        int i;
        char **argv;
  CODE:
        argv = (char **) malloc(items*sizeof(char *));
        for(i = 0; i < (items-1); i++) {
          argv[i] = SvPV(ST(i+1), PL_na);
        }
        argv[i] = 0;
        RETVAL = gsapi_init_with_args(inst, items -1, argv);
        free(argv);
OUTPUT:
        RETVAL
        
IV
exit(inst)
        GSAPI::instance inst
   PROTOTYPE: $
   CODE:
        RETVAL = gsapi_exit(inst);
   OUTPUT:
        RETVAL

IV
run_string(inst, sv, ...)
        GSAPI::instance inst
        SV *sv
     ALIAS:
       run_file = 1
       run_string_continue = 2
   PROTOTYPE: $$;$
   PREINIT:
        int user_errors = 0; // ??
        int pexit_code; // ??
        char *p;
        STRLEN len;
   CODE:
        p = SvPV(sv, len);
        if(items > 2)
                user_errors = SvIV(ST(2));
        switch(ix) {
          case 0:
                RETVAL = gsapi_run_string_with_length(inst, p, len, user_errors, &pexit_code);
                break;
          case 1:
                RETVAL = gsapi_run_file(inst, p, user_errors, &pexit_code);
                break;
          case 2:
                RETVAL = gsapi_run_string_continue(inst, p, len, user_errors, &pexit_code);
                break;
        }
     OUTPUT:
        RETVAL

IV
run_string_begin(inst, ...)
        GSAPI::instance inst
      ALIAS:
        run_string_end = 1
      PROTOTYPE: $;$
      PREINIT:
        int user_errors = 0;
        int pexit_code;
      CODE:
        if(items >1)
                user_errors = SvIV(ST(1));
        switch(ix) {
          case 0:
            RETVAL = gsapi_run_string_begin(inst, user_errors, &pexit_code);
            break;
          case 1:
            RETVAL = gsapi_run_string_end(inst, user_errors, &pexit_code);
            break;
        }
     OUTPUT:
        RETVAL



