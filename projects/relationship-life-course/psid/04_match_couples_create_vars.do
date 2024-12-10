
********************************************************************************
* Project: Relationship Life Course Analysis
* Owner: Kimberly McErlean
* Started: September 2024
* File: match_couples_create_vars
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files takes the imputed data from step 3 at an individual level and
* matches the corresponding imputed partner data.
* It also creates couple-level variables.

use "$created_data/psid_individs_imputed_long_bysex", clear

********************************************************************************
* Match couples
********************************************************************************
// browse unique_id partner_id duration_rec _mi_miss _mi_m _mi_id imputed

// just keep necessary variables

local partnervars "weekly_hrs_t_focal housework_focal earnings_t_focal age_young_child num_children_imp partnered_imp family_income_t relationship in_sample hh_status FIRST_BIRTH_YR age_focal birth_yr_all SEX raceth_fixed_focal sample_type SAMPLE has_psid_gene fixed_education max_educ_focal childcare_focal adultcare_focal new_in_hh rolling_births had_birth first_survey_yr_focal last_survey_yr_focal imputed"

keep unique_id partner_id rel_start_all rel_end_all duration_rec _mi_miss _mi_m _mi_id  `partnervars'
mi rename partner_id x
mi rename unique_id partner_id
mi rename x unique_id // sp swap unique and partner to match (bc need to know it's the same couple / duration). I guess I could merge on rel_start_all as well

// rename them to indicate they are for spouse
foreach var in `partnervars'{
	mi rename `var' `var'_sp
}

mi update

save "$temp/partner_data_imputed.dta", replace
unique unique_id partner_id
browse unique_id partner_id rel_start_all rel_end_all duration_rec weekly_hrs_t_focal if inlist(unique_id, 16032, 16176, 18037, 18197) | inlist(partner_id, 16032, 16176, 18037, 18197)

// match on partner id and duration_rec
use "$created_data/psid_individs_imputed_long_bysex", clear
// browse unique_id partner_id rel_start_all rel_end_all duration_rec weekly_hrs_t_focal if inlist(unique_id, 16032, 16176, 18037, 18197) | inlist(partner_id, 16032, 16176, 18037, 18197)

mi merge 1:1 unique_id partner_id duration_rec using "$temp/partner_data_imputed.dta", keep(match) // gen(howmatch) // rel_start_all rel_end_all 

// browse unique_id partner_id rel_start_all rel_end_all duration_rec weekly_hrs_t_focal weekly_hrs_t_focal_sp if howmatch!=3
// browse unique_id partner_id rel_start_all rel_end_all duration_rec howmatch weekly_hrs_t_focal weekly_hrs_t_focal_sp if inlist(unique_id, 16032, 18037, 5579003) | inlist(partner_id, 16032, 18037, 5579003)

mi update

save "$created_data/psid_couples_imputed_long.dta", replace
unique unique_id partner_id

browse unique_id partner_id duration_rec SEX SEX_sp weekly_hrs_t_focal weekly_hrs_t_focal_sp _mi_m

drop if SEX==2 & SEX_sp==2
mi update

********************************************************************************
**# Create variables
********************************************************************************
capture drop weekly_hrs_woman weekly_hrs_man housework_woman housework_man partnered_woman partnered_man num_children_woman num_children_man
mi update

// first, let's make gendered versions of each variable
*paid work
mi passive: gen weekly_hrs_woman=weekly_hrs_t_focal if SEX==2
mi passive: replace weekly_hrs_woman=weekly_hrs_t_focal_sp if SEX==1

mi passive: gen weekly_hrs_man=weekly_hrs_t_focal if SEX==1
mi passive: replace weekly_hrs_man=weekly_hrs_t_focal_sp if SEX==2

*unpaid work
mi passive: gen housework_woman=housework_focal if SEX==2
mi passive: replace housework_woman=housework_focal_sp if SEX==1

mi passive: gen housework_man=housework_focal if SEX==1
mi passive: replace housework_man=housework_focal_sp if SEX==2

*relationship status
tab partnered_imp partnered_imp_sp 

mi passive: gen partnered_woman=partnered_imp if SEX==2
mi passive: replace partnered_woman=partnered_imp_sp if SEX==1

mi passive: gen partnered_man=partnered_imp if SEX==1
mi passive: replace partnered_man=partnered_imp_sp if SEX==2

*number of children
tab num_children_imp num_children_imp_sp if partnered_imp==1 & partnered_imp_sp==1 // hmm - so they don't always have the same number of children...
tab num_children_imp num_children_imp_sp if partnered_imp==1 & partnered_imp_sp==1 & imputed==0

mi passive: gen num_children_woman=num_children_imp if SEX==2
mi passive: replace num_children_woman=num_children_imp_sp if SEX==1

mi passive: gen num_children_man=num_children_imp if SEX==1
mi passive: replace num_children_man=num_children_imp_sp if SEX==2

// Stata assert command to check new variables created from imputed  
foreach var in weekly_hrs_woman weekly_hrs_man housework_woman housework_man partnered_woman partnered_man num_children_woman num_children_man{  
	inspect `var' if _mi_m != 0  
	assert `var' != . if _mi_m != 0  
} 

// paid work
mi passive: gen ft_pt_woman = .
mi passive: replace ft_pt_woman = 0 if weekly_hrs_woman==0 // not working
mi passive: replace ft_pt_woman = 1 if weekly_hrs_woman > 0 & weekly_hrs_woman < 35 // PT
mi passive: replace ft_pt_woman = 2 if weekly_hrs_woman >=35 & weekly_hrs_woman < 150 // FT

mi passive: gen overwork_woman=. // Cha and Weeden = 50 hrs, Cha 2010 = 50 and 60, Munsch = 60
mi passive: replace overwork_woman = 0 if weekly_hrs_woman >= 0 & weekly_hrs_woman < 50
mi passive: replace overwork_woman = 1 if weekly_hrs_woman >=50 & weekly_hrs_woman < 150 

mi passive: gen ft_pt_man = .
mi passive: replace ft_pt_man = 0 if weekly_hrs_man==0 // not working
mi passive: replace ft_pt_man = 1 if weekly_hrs_man > 0 & weekly_hrs_man < 35 // PT
mi passive: replace ft_pt_man = 2 if weekly_hrs_man >=35 & weekly_hrs_man < 150 // FT

mi passive: gen overwork_man=. // Cha and Weeden = 50 hrs, Cha 2010 = 50 and 60, Munsch = 60
mi passive: replace overwork_man = 0 if weekly_hrs_man >= 0 & weekly_hrs_man < 50
mi passive: replace overwork_man = 1 if weekly_hrs_man >=50 & weekly_hrs_man < 150 

label define ft_pt 0 "Not working" 1 "PT" 2 "FT"
label values ft_pt_woman ft_pt_man ft_pt

tab ft_pt_woman overwork_woman
tab ft_pt_man overwork_man

mi estimate: proportion ft_pt_woman
mi estimate: proportion ft_pt_man

* couple-level version
tab ft_pt_woman ft_pt_man

mi passive: gen couple_work=.
mi passive: replace couple_work = 1 if ft_pt_man == 2 & ft_pt_woman == 0
mi passive: replace couple_work = 2 if ft_pt_man == 2 & ft_pt_woman == 1
mi passive: replace couple_work = 3 if ft_pt_man == 2 & ft_pt_woman == 2
mi passive: replace couple_work = 4 if ft_pt_man == 0 & ft_pt_woman == 2
mi passive: replace couple_work = 4 if ft_pt_man == 1 & ft_pt_woman == 2
mi passive: replace couple_work = 5 if ft_pt_man == 1 & ft_pt_woman == 1
mi passive: replace couple_work = 6 if ft_pt_man == 0 & ft_pt_woman == 0
mi passive: replace couple_work = 6 if ft_pt_man == 0 & ft_pt_woman == 1
mi passive: replace couple_work = 6 if ft_pt_man == 1 & ft_pt_woman == 0

label define couple_work 1 "male bw" 2 "1.5 male bw" 3 "dual FT" 4 "female bw" 5 "dual PT" 6 "under work"
label values couple_work couple_work

mi estimate: proportion couple_work

* with overwork
mi passive: gen couple_work_ow=.
mi passive: replace couple_work_ow = 1 if ft_pt_man == 2 & ft_pt_woman == 0
mi passive: replace couple_work_ow = 2 if ft_pt_man == 2 & ft_pt_woman == 1
mi passive: replace couple_work_ow = 3 if ft_pt_man == 2 & ft_pt_woman == 2 & overwork_man==0 & overwork_woman==0
mi passive: replace couple_work_ow = 4 if ft_pt_man == 2 & ft_pt_woman == 2 & overwork_man==1 & overwork_woman==0
mi passive: replace couple_work_ow = 5 if ft_pt_man == 2 & ft_pt_woman == 2 & overwork_man==0 & overwork_woman==1
mi passive: replace couple_work_ow = 6 if ft_pt_man == 2 & ft_pt_woman == 2 & overwork_man==1 & overwork_woman==1
mi passive: replace couple_work_ow = 7 if ft_pt_man == 0 & ft_pt_woman == 2
mi passive: replace couple_work_ow = 7 if ft_pt_man == 1 & ft_pt_woman == 2
mi passive: replace couple_work_ow = 8 if ft_pt_man == 1 & ft_pt_woman == 1
mi passive: replace couple_work_ow = 8 if ft_pt_man == 0 & ft_pt_woman == 0
mi passive: replace couple_work_ow = 8 if ft_pt_man == 0 & ft_pt_woman == 1
mi passive: replace couple_work_ow = 8 if ft_pt_man == 1 & ft_pt_woman == 0

label define couple_work_ow 1 "male bw" 2 "1.5 male bw" 3 "dual FT: no OW" 4 "dual FT: his OW" 5 "dual FT: her OW" 6 "dual FT: both OW" /// 
7 "female bw" 8 "under work"
label values couple_work_ow couple_work_ow

mi estimate: proportion couple_work_ow

// unpaid work
mi passive: egen couple_hw_total = rowtotal(housework_woman housework_man)
mi passive: gen woman_hw_share = housework_woman / couple_hw_total // this does have missing I think is couple HW total is 0

sum housework_woman, det
sum housework_woman if housework_woman!=0, det
mi passive: egen hw_terc_woman = cut(housework_woman) if housework_woman!=0, group(3) // https://groups.google.com/g/missing-data/c/sN8PeFuuA4s
tab hw_terc_woman
tabstat housework_woman, by(hw_terc_woman)

sum housework_man, det
sum woman_hw_share, det

mi passive: gen couple_hw=.
mi passive: replace couple_hw = 1 if woman_hw_share==1
mi passive: replace couple_hw = 2 if woman_hw_share > 0.60 & woman_hw_share < 1
mi passive: replace couple_hw = 3 if woman_hw_share >= 0.40 & woman_hw_share <= 0.60
mi passive: replace couple_hw = 4 if woman_hw_share < 0.40
mi passive: replace couple_hw = 5 if housework_woman==0 & housework_man==0

label define couple_hw 1 "Woman All" 2 "Woman Most" 3 "Equal" 4 "Man Most" 5 "Neither HW"
label values couple_hw couple_hw

mi estimate: proportion couple_hw

* adding consideration of how many hours she does
mi passive: gen couple_hw_hrs=.
mi passive: replace couple_hw_hrs = 1 if woman_hw_share > 0.60 & woman_hw_share <=1 & hw_terc_woman==2
mi passive: replace couple_hw_hrs = 2 if woman_hw_share > 0.60 & woman_hw_share <=1 & hw_terc_woman==1
mi passive: replace couple_hw_hrs = 3 if woman_hw_share > 0.60 & woman_hw_share <=1 & hw_terc_woman==0
mi passive: replace couple_hw_hrs = 4 if woman_hw_share >= 0.40 & woman_hw_share <= 0.60
mi passive: replace couple_hw_hrs = 5 if woman_hw_share < 0.40
mi passive: replace couple_hw_hrs = 6 if housework_woman==0 & housework_man==0

label define couple_hw_hrs 1 "Woman Most: High" 2 "Woman Most: Med" 3 "Woman Most: Low" 4 "Equal" 5 "Man Most" 6 "Neither HW"
label values couple_hw_hrs couple_hw_hrs

mi estimate: proportion couple_hw_hrs

// family channel
* relationship type
mi merge m:1 unique_id partner_id rel_start_all rel_end_all rel_type_constant using "$created_data\couple_list_individ.dta", keep(match) // get the info about transition yr to fill in whether cohab or married
mi update

mi passive: gen dur_transitioned=.
mi passive: replace dur_transitioned = transition_yr_est - rel_start_all

browse unique_id partner_id duration_rec min_dur max_dur rel_start_all transition_yr_est dur_transitioned

mi passive: gen rel_type=.
mi passive: replace rel_type = 1 if rel_type_constant== 1
mi passive: replace rel_type = 1 if rel_type_constant== 3 & duration_rec >= dur_transitioned
mi passive: replace rel_type = 2 if rel_type_constant== 2
mi passive: replace rel_type = 2 if rel_type_constant== 3 & duration_rec < dur_transitioned
mi passive: replace rel_type = 0 if duration_rec > max_dur

label define rel_type 0 "Not together" 1 "Married" 2 "Cohab"
label values rel_type rel_type

mi estimate: proportion rel_type

browse unique_id partner_id duration_rec rel_start_all rel_end_all max_dur rel_type dur_transitioned transition_yr_est weekly_hrs_woman weekly_hrs_man in_sample in_sample_sp

* number of children
mi passive: egen couple_num_children = rowmax(num_children_woman num_children_man)
tab couple_num_children, m

mi passive: gen couple_num_children_gp=.
mi passive: replace couple_num_children_gp = 0 if couple_num_children==0
mi passive: replace couple_num_children_gp = 1 if couple_num_children==1
mi passive: replace couple_num_children_gp = 2 if couple_num_children==2
mi passive: replace couple_num_children_gp = 3 if couple_num_children>=3 & couple_num_children < 15

tab couple_num_children couple_num_children_gp

mi estimate: proportion couple_num_children_gp

tab rel_type couple_num_children_gp

* combined
mi passive: gen family_type=.
mi passive: replace family_type=0 if rel_type==0
mi passive: replace family_type=1 if rel_type==1 & couple_num_children_gp==0
mi passive: replace family_type=2 if rel_type==1 & couple_num_children_gp==1
mi passive: replace family_type=3 if rel_type==1 & couple_num_children_gp==2
mi passive: replace family_type=4 if rel_type==1 & couple_num_children_gp==3
mi passive: replace family_type=5 if rel_type==2 & couple_num_children_gp==0
mi passive: replace family_type=6 if rel_type==2 & couple_num_children_gp==1
mi passive: replace family_type=7 if rel_type==2 & couple_num_children_gp==2
mi passive: replace family_type=8 if rel_type==2 & couple_num_children_gp==3

label define family_type 0 "Not together" 1 "Married, 0 Ch" 2 "Married, 1 Ch" 3 "Married, 2 Ch" 4 "Married, 3+ Ch" ///
						5 "Cohab, 0 Ch" 6 "Cohab, 1 Ch" 7 "Cohab, 2 Ch" 8 "Cohab, 3+ Ch"
label values family_type family_type

mi estimate: proportion family_type

// check
inspect woman_hw_share if couple_hw_total == 0 & imputed==1 // so yes, these are missing when couple HW total is 0 because can't divide by 0, will remove from below
inspect hw_terc_woman if housework_woman == 0 & imputed==1 // I only did for women with hW hours. so these missings also make sense

foreach var in ft_pt_woman overwork_woman ft_pt_man overwork_man couple_work couple_work_ow couple_hw_total couple_hw couple_hw_hrs rel_type couple_num_children couple_num_children_gp family_type{  
	inspect `var' if _mi_m != 0  
	assert `var' != . if _mi_m != 0  
} 

// designate that relationship dissolved and create versions of all variables that stop at this point
foreach var in ft_pt_woman overwork_woman ft_pt_man overwork_man couple_work couple_work_ow couple_hw couple_hw_hrs couple_num_children_gp family_type{
	mi passive: gen `var'_end = `var'
	mi passive: replace `var'_end = 99 if rel_type==0
}

foreach var in ft_pt_woman_end overwork_woman_end ft_pt_man_end overwork_man_end couple_work_end couple_work_ow_end couple_hw_end couple_hw_hrs_end couple_num_children_gp_end family_type_end{
	assert `var' !=. if _mi_m!=0
}

// final update and save

mi update

save "$created_data/psid_couples_imputed_long.dta", replace

********************************************************************************
**# Quick descriptives for full sample while long
********************************************************************************
mi passive: gen duration = duration_rec - 2
browse duration duration_rec

drop if duration < 0 & duration > 10
drop duration_rec

mi update

********************************************************************************
**# Reshape back to wide to see the data by duration
********************************************************************************
ft_pt_woman_end overwork_woman_end ft_pt_man_end overwork_man_end couple_work_end couple_work_ow_end couple_hw_end couple_hw_hrs_end couple_num_children_gp_end family_type_end
