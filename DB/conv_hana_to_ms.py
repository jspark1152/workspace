import re

def convert_to_mssql(mssql_query):
    # HANA DB 쿼리를 MSSQL 쿼리로 변환하는 함수

    # IFNULL 함수 변환
    mssql_query = mssql_query.replace('IFNULL(', 'ISNULL(')

    # TO_DATE 함수 변환
    regex = r"TO_DATE\((.*?)\)"
    mssql_query = re.sub(regex, r"CONVERT(VARCHAR(8), \1, 112)", mssql_query)

    # TO_CHAR -Date
    pattern = r'TO_CHAR\((.*?),\s*\'(YYYY-MM)\'\)'
    mssql_query = re.sub(pattern, r"CONVERT(VARCHAR(7), \1, 23)", mssql_query)

    # TO_CHAR -TIME
    pattern = r'TO_CHAR\((.*?),\s*\'(HH24MI|HH24MISS)\'\)'
    mssql_query = re.sub(pattern, lambda x: f"CONVERT(VARCHAR({5 if x.group(2) == 'HH24MI' else 8}), {x.group(1)}, 108)", mssql_query)

    # TO_VARCHAR -TIME
    pattern = r'TO_VARCHAR\((.*?),\s*\'(HH24MI|HH24MISS)\'\)'
    mssql_query = re.sub(pattern, lambda x: f"CONVERT(VARCHAR({5 if x.group(2) == 'HH24MI' else 8}), {x.group(1)}, 108)", mssql_query)

    # TO_VARCHAR - DATE
    pattern = r'TO_VARCHAR\((.*?),\s*\'(YYYYMMDD)\'\)'
    mssql_query = re.sub(pattern, r"CONVERT(VARCHAR(8), \1, 112)", mssql_query)

    #SECONDs_BETWEEN
    mssql_query = mssql_query.replace('SECONDS_BETWEEN(', 'DATEDIFF(SECOND, ')
    mssql_query = mssql_query.replace('SECONDS_BETWEEN (', 'DATEDIFF(SECOND, ')

    #YEARS_BETWEEN
    mssql_query = mssql_query.replace('YEARS_BETWEEN(', 'DATEDIFF(YEAR, ')
    mssql_query = mssql_query.replace('YEARS_BETWEEN (', 'DATEDIFF(YEAR, ')

    # LOCATE_REGEXPR를 PATINDEX로 변환
    mssql_query = mssql_query.replace("LOCATE_REGEXPR('[ㄱ-ㅎ|ㅏ-ㅣ|가-힣]' IN", "PATINDEX('%[ㄱ-ㅎㅏ-ㅣ가-힣]%', ")

    #SUBSTR(
    mssql_query = mssql_query.replace('SUBSTR(', 'SUBSTRING(')
    
	#to_seconddate(
    mssql_query = mssql_query.replace('to_seconddate(', "DATEDIFF(SECOND, '19700101', ")

    # GREATEST 함수를 MAX 함수로 변환
    mssql_query = re.sub(r"GREATEST\((.*?)\)", r"MAX(\1)", mssql_query)

    # LENGTH 함수를 LEN 함수로 변환
    mssql_query = re.sub(r"LENGTH\((.*?)\)", r"LEN(\1)", mssql_query)

    return mssql_query


# HANA DB 쿼리 입력
hana_query = '''
IFNULL(UPPER(b.Ger_Rslt_Cd),'') AS Ger_Rslt_Cd
TO_DATE(b.Exam_Str_Ymd_Hms) AS Exam_Str_Ymd
TO_VARCHAR(b.Exam_Str_Ymd_Hms, 'HH24MI') AS Exam_Str_Hm
TO_VARCHAR(b.Exam_Str_Ymd_Hms, 'HH24MISS') AS Exam_Str_Hms
TO_VARCHAR(a.Spc_Impsi_Dt, 'YYYYMMDD') AS Spc_Impsi_Dt
SECONDS_BETWEEN (a.Ord_Ymd_Hms, a.Spc_Smp_Ymd_Hms)
CASE WHEN LOCATE_REGEXPR('[ㄱ-ㅎ|ㅏ-ㅣ|가-힣]' IN NM_OF_OPERATION)
THEN SUBSTR(CAST(NM_OF_OPERATION AS VARCHAR(5000)),
GREATEST( CASE WHEN LOCATE_REGEXPR('[ㄱ-ㅎ|ㅏ-ㅣ|가-힣]' IN NM_OF_OPERATION) < 1
THEN CASE WHEN LENGTH(NM_OF_OPERATION) >=4500
TO_CHAR(DSC_CALC_YMD_DSC_CALC_APP_HMS,'HH24MISS') AS DSC_CALC_YMD_DSC_CALC_APP_HMS
TO_CHAR(OTRM_YMD_HMS,
	 'HH24MISS') AS OTRM_HMS
TO_CHAR(BIRTH_YMD, 'YYYY-MM') AS BIRTH_YMD
THEN YEARS_BETWEEN(A.Birth_Ymd,
	 CURRENT_DATE)
TO_DATE(IFNULL(P.Vacc_Ymd_Hm, A.Ord_Ymd)) AS Vacc_Ymd
to_seconddate(M.ACT_STR_DT) RMK_STR_DT
'''
# HANA DB 쿼리를 MSSQL 쿼리로 변환
mssql_query = convert_to_mssql(hana_query)
print("MSSQL 쿼리:", mssql_query)