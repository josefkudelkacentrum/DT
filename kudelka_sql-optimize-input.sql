--- Point to parts that could be optimized
--- Feel free to comment any row that you think could be optimize/adjusted in some way!
--- The following query is from SAP HANA but applies to any DB
--- Do not worry if the tables/columns are not familiar to you 
----   -> you do not need to interpret the result (in fact the query does not reflect actual DB content)

SELECT 
	RSEG.EBELN,
	RSEG.EBELP,
    	RSEG.BELNR,
   	RSEG.AUGBL AS AUGBL_W,

    	LPAD(EKPO.BSART,6,0) as BSART,

	BKPF.GJAHR,

	BSEG.BUKRS,
	BSEG.BUZEI,
	BSEG.BSCHL,
	BSEG.SHKZG,
    	CASE WHEN BSEG.SHKZG = 'H' THEN (-1) * BSEG.DMBTR ELSE BSEG.DMBTR END AS DMBTR,					  --Not sure whats the role of (-1). Maybe we could use absolute value, but I cannot say when I dont see the records/I dont know the reques .... just thinking ...

    	COALESCE(LFA1.LAND1, 'Andere') AS LAND1, 
        LFA1.LIFNR,
    	LFA1.ZSYSNAME,

    	BKPF.BLART as BLART,
    	BKPF.BUDAT as BUDAT,
        BKPF.CPUDT as CPUDT

FROM "DTAG_DEV_CSBI_CELONIS_DATA"."dtag.dev.csbi.celonis.data.elog::V_RSEG" AS RSEG



LEFT JOIN "DTAG_DEV_CSBI_CELONIS_WORK"."dtag.dev.csbi.celonis.app.p2p_elog::__P2P_REF_CASES" AS EKPO ON 1=1               
    AND RSEG.ZSYSNAME = EKPO.SOURCE_SYSTEM
    AND RSEG.MANDT = EKPO.MANDT												  --RSEG_MANDT is always 200. We dont need to read its value.
    AND RSEG.EBELN || RSEG.EBELP = EKPO.EBELN || EKPO.EBELP                                                               --We could try to do it in two steps 

INNER JOIN "DTAG_DEV_CSBI_CELONIS_DATA"."dtag.dev.csbi.celonis.data.elog::V_BKPF" AS BKPF ON 1=1
    AND BKPF.AWKEY = RSEG.AWKEY
    AND RSEG.ZSYSNAME = BKPF.ZSYSNAME
    AND RSEG.MANDT in ('200')                                                                                             --IN is not needed. We can use simple "="

INNER JOIN "DTAG_DEV_CSBI_CELONIS_DATA"."dtag.dev.csbi.celonis.data.elog::V_BSEG" AS BSEG ON 1=1
    AND DATS_IS_VALID(BSEG.ZFBDT) = 1
    AND BSEG.KOART = 'K'
    AND CAST(BSEG.GJAHR AS INT) = 2020											  --SMALLINT should be enough when working only with years
    AND BKPF.ZSYSNAME = BSEG.ZSYSNAME
    AND BKPF.MANDT = BSEG.MANDT
    AND BKPF.BUKRS = BSEG.BUKRS
    AND BKPF.GJAHR = BSEG.GJAHR
    AND BKPF.BELNR = BSEG.BELNR
    AND BSEG.DMBTR*-1 >= 0											          --We can write it like "AND BSEG.DMBTR <= 0"

INNER JOIN (SELECT * FROM "DTAG_DEV_CSBI_CELONIS_DATA"."dtag.dev.csbi.celonis.data.elog::V_LFA1" AS TEMP                  --We should select only the needed columns. I also assume that this derived query has some sense (its efficient) in the query Otherwise its not needed to filter the records at this place.
            WHERE TEMP.LIFNR > '020000000') AS LFA1 ON 1=1 								  --I assume we are working with numbers=>leading zero and quotation marks are not needed
    AND BSEG.ZSYSNAME = LFA1.ZSYSNAME
    AND BSEG.LIFNR=LFA1.LIFNR
    AND BSEG.MANDT=LFA1.MANDT
    AND LFA1.LAND1 in ('DE','SK')												
;



