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


def save_to_file(data, file_path):
    # 데이터를 파일에 저장하는 함수
    with open(file_path, 'w') as file:
        file.write(data)

# HANA DB 쿼리
hana_query = '''
CREATE VIEW MO_OP_MAIN_SP_V AS SELECT
	 SVR_ID,
	 OP_SEQ,
	 ALS_UNIT_NO,
	 CHOS_GB,
	 ALS_CHOS_NO,
	 OP_YMD,
	 OP_RNK,
	 EMER_YN,
	 OP_CNTR_CD,
	 OP_RM_NO,
	 ANS_GB_CD,
	 SYNC_OP_YN,
	 OP_GB,
	 TO_DATE(PAT_ARV_YMD_HM) AS PAT_ARV_YMD,
	 PAT_ARV_YMD_HM,
	 TO_CHAR(PAT_ARV_YMD_HM, 'HH24MISS') AS PAT_ARV_HMS,
	 TO_DATE(PAT_INRM_YMD_HM) AS PAT_INRM_YMD,
	 PAT_INRM_YMD_HM,
	 TO_CHAR(PAT_INRM_YMD_HM, 'HH24MISS') AS PAT_INRM_HMS,
	 TO_DATE(PAT_DSC_YMD_HM) AS PAT_DSC_YMD,
	 PAT_DSC_YMD_HM,
	 TO_CHAR(PAT_DSC_YMD_HM, 'HH24MISS') AS PAT_DSC_HMS,
	 TO_DATE(OP_STR_YMD_HM) AS OP_STR_YMD,
	 OP_STR_YMD_HM,
	 TO_CHAR(OP_STR_YMD_HM, 'HH24MISS') AS OP_STR_HMS,
	 TO_DATE(STAFF_ARV_YMD_HM) AS STAFF_ARV_YMD,
	 STAFF_ARV_YMD_HM,
	 TO_CHAR(STAFF_ARV_YMD_HM, 'HH24MISS') AS STAFF_ARV_HMS,
	 TO_DATE(OP_END_YMD_HM) AS OP_END_YMD,
	 OP_END_YMD_HM,
	 TO_CHAR(OP_END_YMD_HM, 'HH24MISS') AS OP_END_HMS,
	 WOUND_CLS_CD,
	 TOT_OP_HM,
	 RE_OP_GB,
	 MAIN_OP_CLN_DEPT_CD,
	 STAFF_ID,
	 OP_RMK,
	 MNGT_YN,
	 OP_AGE,
	 OP_CNCL_DAY_GB,
	 OP_START_END_GB,
	 SEX,
	 TO_CHAR(BIRTH_YMD,
	 'YYYY-MM') AS BIRTH_YMD,
	 OP_CD,
	 MV_GB,
	 MV_WARD,
	 OP_NUR_REC_KEY,
	 ETL_DTM,
	 OP_CNCL_GB,
	 ANS_ORD_CFR_GB 
FROM CDWDATA.MO_OP_MAIN 
WHERE OP_YN = 'Y'
'''
# HANA DB 쿼리를 MSSQL로 변환
mssql_query = convert_to_mssql(hana_query)
# 변환된 쿼리를 새로운 파일로 저장
save_to_file(mssql_query, "CREATE_VIEW_023_mssql.txt")