/*
 * XNAMES.H -- C callable external names of the SPP library procedures.
 * The C version of the name is identical to the SPP name except that it is
 * given as a macro in upper case.  The definition is the host system external
 * name of the Fortran procedure.  The trailing underscore in these names is
 * UNIX dependent; other systems use a leading underscore, or no special
 * characters at all (the purpose of the underscore on UNIX systems is to
 * avoid name collisions between C and Fortran procedures, since the F77
 * runtime library on UNIX is built on the UNIX/C library).  Change the names
 * in the column at the right if your system employs a different convention.
 *
 * If your system does not employ something like the underscore to avoid
 * name collisions, name collisions can be expected.  To fix these change
 * the name given here and add a define to lib$iraf.h to change the external
 * name generated by the preprocessor.  It is NOT necessary to resolve name
 * collisions by changing the actual program sources.
 *
 * The external names defined herein MUST agree with those in "hlib$iraf.h".
 */

#define	ACCESS		xfaccs_		/* to avoid name collisions */
#define	CALLOC		xcallc_
#define	CLOSE		xfcloe_
#define	DELETE		xfdele_
#define	ERROR		xerror_
#define	FLUSH		xffluh_
#define	GETC		xfgetc_
#define	GETCHAR		xfgetr_
#define	MALLOC		xmallc_
#define	MFREE		xmfree_
#define	MKTEMP		xmktep_
#define	NOTE		xfnote_
#define	OPEN		xfopen_
#define	PRINTF		xprinf_
#define	PUTC		xfputc_
#define	PUTCHAR		xfputr_
#define	QSORT		xqsort_
#define	READ		xfread_
#define	REALLOC		xrealc_
#define	SEEK		xfseek_
#define	SIZEOF		xsizef_
#define	UNGETC		xfungc_
#define	WRITE		xfwrie_

#define	AREAD		aread_		/* other VOS names */
#define	AREADB		areadb_
#define	AWAIT		await_
#define	AWAITB		awaitb_
#define	AWRITE		awrite_
#define	AWRITEB		awritb_
#define	BEGMEM		begmem_
#define	BRKTIME		brktie_
#define	BTOI		btoi_
#define	CLKTIME		clktie_
#define	CNVDATE		cnvdae_
#define	CNVTIME		cnvtie_
#define	COERCE		coerce_
#define	CPUTIME		cputie_
#define	CTOD		ctod_
#define	CTOX		ctox_
#define	DIROPEN		diropn_
#define	DTOC		dtoc_
#define	ENVFIND		envfid_
#define	ENVFREE		envfre_
#define	ENVGETB		envgeb_
#define	ENVGETI		envgei_
#define	ENVGETS		envges_
#define	ENVINIT		envint_
#define	ENVLIST		envlit_
#define ENVMARK		envmak_
#define	ENVPUTS		envpus_
#define	ENVRESET	envret_
#define	ENVSCAN		envscn_
#define	ERRACT		erract_
#define	ERRCODE		errcoe_
#define	ERRGET		errget_
#define	FALLOC		falloc_
#define	FATAL		xfatal_
#define	FCHDIR		xfchdr_
#define	FCOPY		fcopy_
#define	FCOPYO		fcopyo_
#define	FDEBUG		fdebug_
#define	FDELPF		fdelpf_
#define	FDEVBLK		fdevbk_
#define	FDIRNAME	fdirne_
#define	FILBUF		filbuf_
#define	FINFO		finfo_
#define	FIXMEM		fixmem_
#define	FLSBUF		flsbuf_
#define	FMAPFN		fmapfn_
#define	FMKDIR		fmkdir_
#define	FNEXTN		fnextn_
#define	FNLDIR		fnldir_
#define	FNROOT		fnroot_
#define	FNTCLS		fntcls_
#define	FNTGFN		fntgfn_
#define	FNTOPN		fntopn_
#define	FOWNER		fowner_
#define	FPATHNAME	fpathe_
#define	FPRINTF		fprinf_
#define	FREDIR		fredir_
#define	FREDIRO		fredio_
#define	FSETI		fseti_
#define	FSTATI		fstati_
#define	FSTATL		fstatl_
#define	FSTATS		fstats_
#define	GETPID		xgtpid_
#define	GCTOD		gctod_
#define	GCTOL		gctol_
#define	GCTOX		gctox_
#define	GETLINE		getlie_
#define	GETUID		xgtuid_
#define	GLTOC		gltoc_
#define	GPATMAKE	gpatme_
#define	GPATMATCH	gpatmh_
#define	GSTRMATCH	gstrmh_
#define	GTR_GFLUSH	gtrgfh_
#define	IMACCESS	imaccs_
#define	IMDRCUR		imdrcr_
#define	IRAF_MAIN	irafmn_
#define	XISATTY		xisaty_
#define	XTTYSIZE	xttyse_
#define	ITOB		itob_
#define	KI_EXTNODE	kiexte_
#define	KI_MAPCHAN	kimapn_
#define	LEXNUM		lexnum_
#define	LPOPEN		lpopen_
#define	NDOPEN		ndopen_
#define	ONENTRY		onenty_
#define	ONERROR		onerrr_
#define	ONEXIT		onexit_
#define	OSCMD		oscmd_
#define	PARGB		pargb_
#define	PARGC		pargc_
#define	PARGD		pargd_
#define	PARGI		pargi_
#define	PARGL		pargl_
#define	PARGR		pargr_
#define	PARGS		pargs_
#define	PARGSTR		pargsr_
#define	PARGX		pargx_
#define POLL            xfpoll_
#define POLL_OPEN       pollon_
#define POLL_CLOSE      pollce_
#define POLL_ZERO       pollzo_
#define POLL_SET        pollst_
#define POLL_CLEAR      pollcr_
#define POLL_TEST       polltt_
#define POLL_GET_NFDS   pollgs_
#define POLL_PRINT      pollpt_
#define	PRCHDIR		prchdr_
#define	PRCLCPR		prclcr_
#define	PRCLDPR		prcldr_
#define	PRCLOSE		prcloe_
#define	PRDONE		prdone_
#define	PRENVFREE	prenve_
#define	PRENVSET	prenvt_
#define	PRFILBUF	prfilf_
#define	PRKILL		prkill_
#define	PROPCPR		propcr_
#define	PROPDPR		propdr_
#define	PRFODPR		prfodr_
#define	PROPEN		propen_
#define	PROTECT		protet_
#define	PRREDIR		prredr_
#define	PRSIGNAL	prsigl_
#define	PRSTATI		prstai_
#define	PRUPDATE	prupde_
#define	PRPSINIT	prpsit_
#define	PUTCC		putcc_
#define	PUTLINE		putlie_
#define	RCURSOR		rcursr_
#define	RDUKEY		rdukey_
#define	RENAME		xfrnam_
#define	REOPEN		reopen_
#define	SALLOC		salloc_
#define	SFREE		sfree_
#define	SMARK		smark_
#define	SPRINTF		sprinf_
#define	STG_GETLINE	stggee_
#define	STG_PUTLINE	stgpue_
#define	STKCMP		stkcmp_
#define	STRMATCH	strmah_
#define	STROPEN		stropn_
#define	STRTBL		strtbl_
#define	STTYCO		sttyco_
#define	SYSRUK		sysruk_
#define	TSLEEP		tsleep_
#define	TTSETI		ttseti_
#define	TTSETS		ttsets_
#define	TTSTATI		ttstai_
#define	TTSTATS		ttstas_
#define	TTYCDES		ttycds_
#define	TTYCLEAR	ttyclr_
#define	TTYCLEARLN	ttycln_
#define	TTYCLOSE	ttycls_
#define	TTYCTRL		ttyctl_
#define	TTYGDES		ttygds_
#define	TTYGETB		ttygeb_
#define	TTYGETI		ttygei_
#define	TTYGETR		ttyger_
#define	TTYGETS		ttyges_
#define	TTYGOTO		ttygoo_
#define	TTYINIT		ttyint_
#define	TTYODES		ttyods_
#define	TTYOPEN		ttyopn_
#define	TTYPUTLINE	ttypue_
#define	TTYPUTS		ttypus_
#define	TTYSETI		ttysei_
#define	TTYSO		ttyso_
#define	TTYSTATI	ttysti_
#define	UNGETLINE	ungete_
#define	UNREAD		unread_
#define	URAND		urand_
#define	VFNOPEN		vfnopn_
#define	VFNCLOSE	vfncle_
#define	VFNMAP		vfnmap_
#define	VFNADD		vfnadd_
#define	VFNDEL		vfndel_
#define	VFNUNMAP	vfnunp_
#define	VMALLOC		vmallc_
#define	XACOS		xacos_
#define	XALLOCATE	xalloe_
#define	XASIN		xasin_
#define	XATAN		xatan_
#define	XATAN2		xatan2_
#define	XCOS		xcos_
#define	XDEALLOCATE	xdeale_
#define	XDEVOWNER	xdevor_
#define	XDEVSTATUS	xdevss_
#define XER_RESET	xerret_
#define	XEXP		xexp_
#define	XLOG		xlog_
#define	XLOG10		xlog10_
#define	XNINT		xnint_
#define	XMJBUF		xmjbuf_
#define	XONERR		xonerr_
#define	XPOW		xpow_
#define	XSIN		xsin_
#define	XSQRT		xsqrt_
#define	XTAN		xtan_
#define	XTOC		xtoc_
#define	XWHEN		xwhen_

#define	D_xnames
