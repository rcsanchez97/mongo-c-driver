set (MONGOC_HAVE_RES_NQUERY 0)
set (MONGOC_HAVE_RES_NDESTROY 0)
set (MONGOC_HAVE_RES_QUERY 0)
set (MONGOC_HAVE_RES_NCLOSE 0)

if (WIN32)
   set (RESOLV_LIB Dnsapi)
else ()
   # Thread-safe DNS query function for _mongoc_client_get_srv.
   # Could be a macro, not a function, so use check_symbol_exists.
   check_symbol_exists (res_nquery resolv.h HAVE_RES_NQUERY)
   if (HAVE_RES_NQUERY)
      set (RESOLV_LIB resolv)
      set (MONGOC_HAVE_RES_NQUERY 1)

      # We have res_nquery. Call res_ndestroy (BSD/Mac) or res_nclose (Linux)?
      check_symbol_exists (res_ndestroy resolv.h HAVE_RES_NDESTROY)
      if (HAVE_RES_NDESTROY)
         set (MONGOC_HAVE_RES_NDESTROY 1)
      else ()
         check_symbol_exists (res_nclose resolv.h HAVE_RES_NCLOSE)
         if (HAVE_RES_NCLOSE)
            set (MONGOC_HAVE_RES_NCLOSE 1)
         endif ()
      endif ()
   else ()
      # Thread-unsafe function.
      check_symbol_exists (res_query resolv.h HAVE_RES_QUERY)
      if (HAVE_RES_QUERY)
         set (RESOLV_LIB resolv)
         set (MONGOC_HAVE_RES_QUERY 1)
      endif()
   endif ()
endif ()
