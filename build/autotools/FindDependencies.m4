
# Solaris needs to link against socket libs.
if test "$os_solaris" = "yes"; then
    CFLAGS="$CFLAGS -D__EXTENSIONS__"
    CFLAGS="$CFLAGS -D_XOPEN_SOURCE=1"
    CFLAGS="$CFLAGS -D_XOPEN_SOURCE_EXTENDED=1"
    LDFLAGS="$LDFLAGS -lsocket -lnsl"
fi

# Check if we should enable the bundled libbson.
if test "$with_libbson" = "auto"; then
   PKG_CHECK_MODULES(BSON, libbson-1.0 >= libbson_required_version,
                     [with_libbson=system], [with_libbson=bundled])
fi
AM_CONDITIONAL(ENABLE_LIBBSON, [test "$with_libbson" = "bundled"])

# Check for shm functions.
AC_CHECK_FUNCS([shm_open], [SHM_LIB=],
               [AC_CHECK_LIB([rt], [shm_open], [SHM_LIB=-lrt], [SHM_LIB=])])
AC_SUBST([SHM_LIB])

# Check for sched_getcpu
AC_CHECK_FUNCS([sched_getcpu])

AS_IF([test "$enable_rdtscp" = "yes"],
      [CPPFLAGS="$CPPFLAGS -DENABLE_RDTSCP"])

AS_IF([test "$enable_shm_counters" = "yes"],
      [CPPFLAGS="$CPPFLAGS -DMONGOC_ENABLE_SHM_COUNTERS"])

AC_CHECK_TYPE([socklen_t],
              [AC_SUBST(MONGOC_HAVE_SOCKLEN, 1)],
              [AC_SUBST(MONGOC_HAVE_SOCKLEN, 0)],
              [#include <sys/socket.h>])

# Thread-safe DNS query function for _mongoc_client_get_srv.
# Could be a macro, not a function, so check with AC_TRY_LINK.
AC_MSG_CHECKING([for res_nquery])
save_LIBS="$LIBS"
LIBS="$LIBS -lresolv"
AC_TRY_LINK([
   #include <sys/types.h>
   #include <netinet/in.h>
   #include <arpa/nameser.h>
   #include <resolv.h>
],[
   int len;
   unsigned char reply[1024];
   res_state statep;
   len = res_nquery(
      statep, "example.com", ns_c_in, ns_t_srv, reply, sizeof(reply));
],[
   AC_MSG_RESULT([yes])
   AC_SUBST(MONGOC_HAVE_RES_QUERY, 0)
   AC_SUBST(MONGOC_HAVE_RES_NQUERY, 1)
   AC_SUBST(RESOLV_LIB, -lresolv)

   # We have res_nquery. Call res_ndestroy (BSD/Mac) or res_nclose (Linux)?
   AC_MSG_CHECKING([for res_ndestroy])
   AC_TRY_LINK([
      #include <sys/types.h>
      #include <netinet/in.h>
      #include <arpa/nameser.h>
      #include <resolv.h>
   ],[
      res_state statep;
      res_ndestroy(statep);
   ], [
      AC_MSG_RESULT([yes])
      AC_SUBST(MONGOC_HAVE_RES_NDESTROY, 1)
      AC_SUBST(MONGOC_HAVE_RES_NCLOSE, 0)
   ], [
      AC_MSG_RESULT([no])
      AC_SUBST(MONGOC_HAVE_RES_NDESTROY, 0)

      AC_MSG_CHECKING([for res_nclose])
      AC_TRY_LINK([
         #include <sys/types.h>
         #include <netinet/in.h>
         #include <arpa/nameser.h>
         #include <resolv.h>
      ],[
         res_state statep;
         res_nclose(statep);
      ], [
         AC_MSG_RESULT([yes])
         AC_SUBST(MONGOC_HAVE_RES_NCLOSE, 1)
      ], [
         AC_MSG_RESULT([no])
         AC_SUBST(MONGOC_HAVE_RES_NCLOSE, 0)
      ])
   ])
],[
   AC_SUBST(MONGOC_HAVE_RES_NQUERY, 0)
   AC_SUBST(MONGOC_HAVE_RES_NDESTROY, 0)
   AC_SUBST(MONGOC_HAVE_RES_NCLOSE, 0)

   AC_MSG_RESULT([no])
   AC_MSG_CHECKING([for res_query])

   # Thread-unsafe function.
   AC_TRY_LINK([
      #include <sys/types.h>
      #include <netinet/in.h>
      #include <arpa/nameser.h>
      #include <resolv.h>
   ],[
      int len;
      unsigned char reply[1024];
      len = res_query("example.com", ns_c_in, ns_t_srv, reply, sizeof(reply));
   ], [
      AC_MSG_RESULT([yes])
      AC_SUBST(MONGOC_HAVE_RES_QUERY, 1)
      AC_SUBST(RESOLV_LIB, -lresolv)
   ], [
      AC_MSG_RESULT([no])
      AC_SUBST(MONGOC_HAVE_RES_QUERY, 0)
   ])
])

LIBS="$save_LIBS"

AX_PTHREAD
