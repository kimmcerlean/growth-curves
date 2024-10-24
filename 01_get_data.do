********************************************************************************
********************************************************************************
* Project: Relationship Growth Curves
* Owner: Kimberly McErlean
* Started: September 2024
* File: get_data
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files gets the data from the PSID and reorganizes it for analysis

********************************************************************************
* Import data and reshape so it's long
********************************************************************************
use "$PSID\PSID_full_renamed.dta", clear
rename X1968_PERSON_NUM_1968 main_per_id

gen unique_id = (main_per_id*1000) + INTERVIEW_NUM_1968 // (ER30001 * 1000) + ER30002
browse main_per_id INTERVIEW_NUM_1968 unique_id

merge 1:1 unique_id using "T:\data\PSID\strata.dta", keepusing(stratum cluster)
drop if _merge==2
drop _merge

gen id=_n

local reshape_vars "RELEASE_ X1968_PERSON_NUM_ INTERVIEW_NUM_ RELATION_ AGE_ MARITAL_PAIRS_ MOVED_ YRS_EDUCATION_ TYPE_OF_INCOME_ TOTAL_MONEY_INCOME_ ANNUAL_WORK_HRS_ RELEASE_NUM2_ FAMILY_COMPOSITION_ AGE_REF_  AGE_SPOUSE_ SEX_HEAD_ AGE_YOUNG_CHILD_ RESPONDENT_WHO_ RACE_1_HEAD_ EMPLOY_STATUS_HEAD_ MARITAL_STATUS_HEAD_ WIDOW_LENGTH_HEAD_ WAGES_HEAD_ FAMILY_INTERVIEW_NUM_ FATHER_EDUC_HEAD_ WAGE_RATE_HEAD_ WAGE_RATE_WIFE_ REGION_ NUM_CHILDREN_ CORE_WEIGHT_ TOTAL_HOURS_HEAD_ TOTAL_HOURS_WIFE_ LABOR_INCOME_HEAD_ LABOR_INCOME_WIFE_ TOTAL_FAMILY_INCOME_ TAXABLE_HEAD_WIFE_ EDUC1_HEAD_ EDUC1_WIFE_ WEEKLY_HRS1_WIFE_ WEEKLY_HRS1_HEAD_ TOTAL_HOUSEWORK_HW_ RENT_COST_V1_ MORTGAGE_COST_ HOUSE_VALUE_ HOUSE_STATUS_ VEHICLE_OWN_ POVERTY_THRESHOLD_ SEQ_NUMBER_ RESPONDENT_ FAMILY_ID_SO_ COMPOSITION_CHANGE_ NEW_REF_ HOUSEWORK_WIFE_ HOUSEWORK_HEAD_ MOST_HOUSEWORK_ AGE_OLDEST_CHILD_ FOOD_STAMPS_ HRLY_RATE_HEAD_ RELIGION_HEAD_ CHILDCARE_COSTS_ TRANSFER_INCOME_ WELFARE_JOINT_ NEW_SPOUSE_ FATHER_EDUC_WIFE_ MOTHER_EDUC_WIFE_ MOTHER_EDUC_HEAD_ TYPE_TAXABLE_INCOME_ OFUM_TAXABLE_INCOME_ COLLEGE_HEAD_ COLLEGE_WIFE_ EDUC_HEAD_ EDUC_WIFE_ SALARY_TYPE_HEAD_ FIRST_MARRIAGE_YR_WIFE_ RELIGION_WIFE_ WORK_MONEY_WIFE_ EMPLOY_STATUS_WIFE_ SALARY_TYPE_WIFE_ HRLY_RATE_WIFE_ RESEPONDENT_WIFE_ WORK_MONEY_HEAD_ MARITAL_STATUS_REF_ EVER_MARRIED_HEAD_ EMPLOYMENT_ STUDENT_ BIRTH_YR_ COUPLE_STATUS_REF_ OTHER_ASSETS_ STOCKS_MF_ WEALTH_NO_EQUITY_ WEALTH_EQUITY_ VEHICLE_VALUE_ RELATION_TO_HEAD_ NUM_MARRIED_HEAD_ FIRST_MARRIAGE_YR_HEAD_ FIRST_MARRIAGE_END_HEAD_ FIRST_WIDOW_YR_HEAD_ FIRST_DIVORCE_YR_HEAD_ FIRST_SEPARATED_YR_HEAD_ LAST_MARRIAGE_YR_HEAD_ LAST_WIDOW_YR_HEAD_ LAST_DIVORCE_YR_HEAD_ LAST_SEPARATED_YR_HEAD_ FAMILY_STRUCTURE_HEAD_ RACE_2_HEAD_ NUM_MARRIED_WIFE_ FIRST_MARRIAGE_END_WIFE_ FIRST_WIDOW_YR_WIFE_ FIRST_DIVORCE_YR_WIFE_ FIRST_SEPARATED_YR_WIFE_ LAST_MARRIAGE_YR_WIFE_ LAST_WIDOW_YR_WIFE_ LAST_DIVORCE_YR_WIFE_ LAST_SEPARATED_YR_WIFE_ FAMILY_STRUCTURE_WIFE_ RACE_1_WIFE_ RACE_2_WIFE_ STATE_ BIRTHS_REF_ BIRTH_SPOUSE_ BIRTHS_BOTH_ WELFARE_HEAD_1_ WELFARE_SPOUSE_1_ OFUM_LABOR_INCOME_ RELEASE_NUM_ SALARY_HEAD_ SALARY_WIFE_ WAGES_WIFE_ RENT_COST_V2_ DIVIDENDS_HEAD_ DIVIDENDS_SPOUSE_ WELFARE_HEAD_2_ WELFARE_SPOUSE_2_ EMPLOY_STATUS1_HEAD_ EMPLOY_STATUS2_HEAD_ EMPLOY_STATUS3_HEAD_ EMPLOY_STATUS1_WIFE_ EMPLOY_STATUS2_WIFE_ EMPLOY_STATUS3_WIFE_ RACE_3_WIFE_ RACE_3_HEAD_ WAGES_HEAD_PRE_ WAGES_WIFE_PRE_ WEEKLY_HRS_HEAD_ WEEKLY_HRS_WIFE_ RACE_4_HEAD_ COR_IMM_WT_ ETHNIC_WIFE_ ETHNIC_HEAD_ CROSS_SECTION_FAM_WT_ LONG_WT_ CROSS_SECTION_WT_ CDS_ELIGIBLE_ EARNINGS_2YRLAG_ TOTAL_HOUSING_ HEALTH_INSURANCE_FAM_ BANK_ASSETS_ AMOUNTEARN_1_HEAD_ TOTAL_WEEKS_HEAD_ TOTAL_HOURS2_HEAD_ AMOUNTEARN_1_WIFE_ TOTAL_WEEK_WIFE_ TOTAL_HOURS2_WIFE_ HOURS_WK_HEAD_ AMOUNTEARN_2_HEAD_ AMOUNTEARN_3_HEAD_ AMOUNTEARN_4_HEAD_ AMOUNTEARN_2_WIFE_ AMOUNTEARN_3_WIFE_ AMOUNTEARN_4_WIFE_ DIVIDENDS_JOINT_ INTEREST_JOINT_ NUM_JOBS_ BACHELOR_YR_ ENROLLED_ COLLEGE_ SEX_WIFE_ BACHELOR_YR_WIFE_ ENROLLED_WIFE_ BACHELOR_YR_HEAD_ ENROLLED_HEAD_ WAGES1_WIFE_ METRO_ CURRENTLY_WORK_HEAD_ CURRENTLY_WORK_WIFE_"

reshape long `reshape_vars', i(id unique_id stratum cluster) j(survey_yr)

save "$temp\PSID_full_long.dta", replace
