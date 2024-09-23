********************************************************************************
********************************************************************************
* Project: Relative Density Approach - UK
* Code owner: Kimberly McErlean
* Started: September 2024
* File name: c_create_sample.do
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* Restrict sample to just partnered, might restrict to just survey years with the unpaid labor questions

********************************************************************************
* Import data
********************************************************************************
use "$outputpath/UKHLS_matched.dta", clear

// i am dumb and right now 1-13 are ukhls and 14-31 are bhps, so the wave order doesn't make a lot of sense. These aren't perfect but will work for now.
// okay i added interview characteristics, so use that?
browse pidp pid survey wavename intdatey intdaty_dv istrtdaty // istrtdaty seems the most comprehensive. the DV one is only UKHLS
// okay, but sometimes consecutive surveys are NOT consecutive years? 

gen year=.
replace year=2009 if wavename==1
replace year=2010 if wavename==2
replace year=2011 if wavename==3
replace year=2012 if wavename==4
replace year=2013 if wavename==5
replace year=2014 if wavename==6
replace year=2015 if wavename==7
replace year=2016 if wavename==8
replace year=2017 if wavename==9
replace year=2018 if wavename==10
replace year=2019 if wavename==11
replace year=2020 if wavename==12
replace year=2021 if wavename==13
replace year=1991 if wavename==14
replace year=1992 if wavename==15
replace year=1993 if wavename==16
replace year=1994 if wavename==17
replace year=1995 if wavename==18
replace year=1996 if wavename==19
replace year=1997 if wavename==20
replace year=1998 if wavename==21
replace year=1999 if wavename==22
replace year=2000 if wavename==23
replace year=2001 if wavename==24
replace year=2002 if wavename==25
replace year=2003 if wavename==26
replace year=2004 if wavename==27
replace year=2005 if wavename==28
replace year=2006 if wavename==29
replace year=2007 if wavename==30
replace year=2008 if wavename==31

********************************************************************************
* Relationship recodes
********************************************************************************

sort pidp year

browse pidp year partnered marital_status_defacto partner_id howlng howlng_sp

// identify couples who transitioned from cohab to marriage okay and transitioned into or out of a relationship also
gen marr_trans=0
replace marr_trans=1 if (marital_status_defacto==1 & marital_status_defacto[_n-1]==2) & pidp==pidp[_n-1] & partner_id==partner_id[_n-1] & year==year[_n-1]+1

gen rel_start=0
replace rel_start=1 if (inlist(marital_status_defacto,1,2) & inlist(marital_status_defacto[_n-1],3,4,5,6)) & pidp==pidp[_n-1] & year==year[_n-1]+1 //  & partner_id==partner_id[_n-1]

gen rel_end=0
replace rel_end=1 if (inlist(marital_status_defacto,3,4,5,6) & inlist(marital_status_defacto[_n-1],1,2)) & pidp==pidp[_n-1] & year==year[_n-1]+1 // partner_id==partner_id[_n-1] - won't have a partner id?

browse pidp year partnered marital_status_defacto rel_start marr_trans rel_end partner_id howlng howlng_sp
// this pidp did have transition 16339 - okay confirmed it worked.

// drop people without partners
keep if partnered==1 | rel_start==1 | marr_trans==1 | rel_end==1

// drop same-sex couples?!
tab sex sex_sp
drop if sex==sex_sp

// okay want to try to figure out things like relationship duration and relationship order, as some might have married prior to entering the survey. not sure if I have to merge partner history.
tab nmar survey, m // ukhls, but a lot of inapplicable? I think this variable is only for new entrants?! is there one maybe in the cross-wave file, then?!
tab nmar_bh survey, m // same with bhps
tab ttl_spells survey, m

browse pidp marital_status_defacto partner_id partner1 status1 partner2 status2 partner3 status3 partner4 status4

label define status_new 1 "Marriage" 2 "Cohab"
foreach var in status1 status2 status3 status4 status5 status6 status7 status8 status9 status10 status11 status12 status13 status14{
	gen x_`var' = `var'
	replace `var' = 1 if inlist(`var',2,3)
	replace `var' = 2 if `var'==10
	label values `var' .
	label values `var' status_new
}

gen rel_no=. // add this to get lookup for current relationship start and end dates
forvalues r=1/14{
	replace rel_no = `r' if status`r' == marital_status_defacto & partner`r' == partner_id
}
tab rel_no if inlist(marital_status_defacto,1,2), m // so about 4% missing. come back to this - can I see if any started during the survey to at least get duration?
browse pidp marital_status_defacto partner_id rel_no partner1 status1 partner2 status2 partner3 status3 partner4 status4
browse pidp marital_status_defacto partner_id rel_no partner1 status1 starty1 startm1 endy1 endm1 divorcey1 divorcem1 mrgend1 cohend1 ongoing1 // if separated, then divorced, end date is seapration date, and divorce date is against divorcey.

gen current_rel_start_year=.
gen current_rel_start_month=.
gen current_rel_end_year=.
gen current_rel_end_month=.
gen current_rel_ongoing=.
// gen current_rel_how_end=.
gen current_rel_marr_end=.
gen current_rel_coh_end=.

forvalues r=1/14{
	replace current_rel_start_year = starty`r' if rel_no==`r'
	replace current_rel_start_month = startm`r' if rel_no==`r'
	replace current_rel_end_year = endy`r' if rel_no==`r'
	replace current_rel_end_month = endm`r' if rel_no==`r'
	replace current_rel_ongoing = ongoing`r' if rel_no==`r'
	// replace current_rel_how_end = mrgend`r' if rel_no==`r' & status`r'==1 // if marriage - okay this actually won't work because the codes are different between marriage and cohab
	// replace current_rel_how_end = cohend`r' if rel_no==`r' & status`r'==2 // if cohab
	replace current_rel_marr_end = mrgend`r' if rel_no==`r'
	replace current_rel_coh_end = cohend`r' if rel_no==`r'
}

replace current_rel_start_year=. if current_rel_start_year==-9
replace current_rel_start_month=. if current_rel_start_month==-9
replace current_rel_end_year=. if current_rel_end_year==-9
replace current_rel_end_month=. if current_rel_end_month==-9

label values current_rel_ongoing ongoing
label values current_rel_marr_end mrgend
label values current_rel_coh_end cohend

browse pidp marital_status_defacto partner_id rel_no current_rel_start_year current_rel_start_month current_rel_end_year current_rel_end_month current_rel_ongoing current_rel_marr_end current_rel_coh_end partner1 status1 starty1 startm1 endy1 endm1 divorcey1 divorcem1 mrgend1 cohend1 ongoing1 partner2 status2 starty2 startm2 endy2 endm2 divorcey2 divorcem2 mrgend2 cohend2 ongoing2

// for those with missing, maybe if only 1 spell, use that info? as long as the status matches and the interview date is within the confines of the spell?
browse pidp istrtdaty istrtdatm marital_status_defacto partner_id rel_no ttl_spells partner1 status1 starty1 startm1 endy1 endm1 divorcey1 divorcem1 mrgend1 cohend1 ongoing1 partner2 status2 starty2 startm2 endy2 endm2 divorcey2 divorcem2 mrgend2 cohend2 ongoing2

replace current_rel_start_year = starty1 if rel_no==. & partner_id!=. & inlist(marital_status_defacto,1,2) & marital_status_defacto==status1 & istrtdaty>=starty1 & istrtdaty<=endy1
replace current_rel_start_month = startm1 if rel_no==. & partner_id!=. & inlist(marital_status_defacto,1,2) & marital_status_defacto==status1 & istrtdaty>=starty1 & istrtdaty<=endy1
replace current_rel_end_year = endy1 if rel_no==. & partner_id!=. & inlist(marital_status_defacto,1,2) & marital_status_defacto==status1 & istrtdaty>=starty1 & istrtdaty<=endy1
replace current_rel_end_month = endm1 if rel_no==. & partner_id!=. & inlist(marital_status_defacto,1,2) & marital_status_defacto==status1 & istrtdaty>=starty1 & istrtdaty<=endy1
replace current_rel_ongoing = ongoing1 if rel_no==. & partner_id!=. & inlist(marital_status_defacto,1,2) & marital_status_defacto==status1 & istrtdaty>=starty1 & istrtdaty<=endy1
gen rel_no_orig=rel_no
replace rel_no=1 if rel_no==. & partner_id!=. & inlist(marital_status_defacto,1,2) & marital_status_defacto==status1 & istrtdaty>=starty1 & istrtdaty<=endy1 // okay this actually didn't add that many more that is fine.

// okay duration info
gen current_rel_duration=.
replace current_rel_duration = istrtdaty-current_rel_start_year
browse pidp istrtdaty istrtdatm current_rel_duration current_rel_start_year current_rel_start_month

********************************************************************************
* Division of Labor recodes
********************************************************************************
// create DoL variables for the two continuous variables

**Paid labor: no overtime
egen paid_couple_total = rowtotal(jbhrs jbhrs_sp)
gen paid_wife_pct=jbhrs / paid_couple_total if sex==2 & sex_sp==1
replace paid_wife_pct=jbhrs_sp / paid_couple_total if sex==1 & sex_sp==2
sum paid_wife_pct
browse pidp year sex sex_sp jbhrs jbhrs_sp paid_couple_total paid_wife_pct

gen paid_dol=.
replace paid_dol = 1 if paid_wife_pct>=0.400000 & paid_wife_pct<=0.600000 // shared
replace paid_dol = 2 if paid_wife_pct <0.400000 & paid_wife_pct!=. // husband does more
replace paid_dol = 3 if paid_wife_pct >0.600000 & paid_wife_pct!=. // wife does more
replace paid_dol = 4 if jbhrs==0 & jbhrs_sp==0 // neither works

tab partner_match paid_dol, m // okay not quite sure what to do for the couples without a match...or when one partner is missing and the other is not. count as 0s? or ignore?
browse partner_match age_all age_all_sp jbhrs jbhrs_sp employed employed_sp paid_couple_total paid_wife_pct if paid_dol==. & partner_match==1 //
browse partner_match paid_dol age_all age_all_sp jbhrs jbhrs_sp employed employed_sp paid_couple_total paid_wife_pct // also a lot of neither works... is that concerning? so a bunch are retirement age, but also a lot are not... but should probably make an upper age limit?
tab paid_dol if age_all<=65

label define paid_dol 1 "Shared" 2 "Husband more" 3 "Wife more" 4 "Neither works"
label values paid_dol paid_dol

**Paid labor: with overtime
fre jbot
recode jbot (-8=0)(-9=.)(-7/-1=.)
recode jbot_sp (-8=0)(-9=.)(-7/-1=.)

egen total_hours=rowtotal(jbhrs jbot)
egen total_hours_sp=rowtotal(jbhrs_sp jbot_sp)

egen paid_couple_total_ot = rowtotal(total_hours total_hours_sp)
gen paid_wife_pct_ot=total_hours / paid_couple_total_ot if sex==2 & sex_sp==1
replace paid_wife_pct_ot=total_hours_sp / paid_couple_total_ot if sex==1 & sex_sp==2
sum paid_wife_pct
sum paid_wife_pct_ot

browse pidp year sex sex_sp total_hours total_hours_sp paid_couple_total_ot paid_wife_pct_ot

gen paid_dol_ot=.
replace paid_dol_ot = 1 if paid_wife_pct_ot>=0.400000 & paid_wife_pct_ot<=0.600000 // shared
replace paid_dol_ot = 2 if paid_wife_pct_ot <0.400000 & paid_wife_pct_ot!=. // husband does more
replace paid_dol_ot = 3 if paid_wife_pct_ot >0.600000 & paid_wife_pct_ot!=. // wife does more
replace paid_dol_ot = 4 if total_hours==0 & total_hours_sp==0 // neither works

label values paid_dol_ot paid_dol

**Unpaid labor
egen unpaid_couple_total = rowtotal(howlng howlng_sp)
gen unpaid_wife_pct=howlng / unpaid_couple_total if sex==2 & sex_sp==1
replace unpaid_wife_pct=howlng_sp / unpaid_couple_total if sex==1 & sex_sp==2
sum unpaid_wife_pct
browse pidp year sex sex_sp howlng howlng_sp unpaid_couple_total unpaid_wife_pct

gen unpaid_dol=.
replace unpaid_dol = 1 if unpaid_wife_pct>=0.400000 & unpaid_wife_pct<=0.600000 // shared
replace unpaid_dol = 2 if unpaid_wife_pct >0.600000 & unpaid_wife_pct!=. // wife does more
replace unpaid_dol = 3 if unpaid_wife_pct <0.400000 & unpaid_wife_pct!=. // husband does more
replace unpaid_dol = 4 if howlng==0 & howlng_sp==0 // neither works

label define unpaid_dol 1 "Shared" 2 "Wife more" 3 "Husband more" 4 "No one"
label values unpaid_dol unpaid_dol

tab partner_match unpaid_dol if inlist(wavename,1,2,4,6,8,10,12,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31), m row
tab wavename unpaid_dol, m

browse partner_match howlng howlng_sp unpaid_couple_total unpaid_wife_pct if unpaid_dol==. & inlist(wavename,1,2,4,6,8,10,12,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31) // okay a lot of missing, even when matched. need to figure out eligibility. okay, at one point says only asked January to June? need to figure it out, because coverage looks very high in the codebook... okay, but did a lot of checks and it actually seems right...
browse survey year wavename istrtdatm howlng if inlist(wavename,1,2,4,6,8,10,12,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31)

gen unpaid_flag=0
replace unpaid_flag=1 if inlist(wavename,1,2,4,6,8,10,12,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31)
replace unpaid_flag=0 if wavename==1 & inrange(intdatem,8,12)
tab unpaid_flag
tab howlng unpaid_flag, m

********************************************************************************
**# Create some preliminary descriptive statistics
* Eventually will automate this once more things are figured out
********************************************************************************
tab sex if partner_match==1 & partnered==1, m // so just use women's responses because right now, have multiple records per HH, right?
browse survey year partnered pidp partner_id hidp

// unique couples - then by marital status (married, cohab, transitioned)
unique pidp partner_id if partner_match==1 & partnered==1
unique pidp partner_id if partner_match==1 & partnered==1 & sex==2
unique pidp partner_id if partner_match==1 & partnered==1 & sex==2, by(marital_status_defacto)
tab marital_status_defacto if partner_match==1 & partnered==1 & sex==2

unique pidp partner_id if partner_match==1 & partnered==1 & sex==2 & unpaid_flag==1
unique pidp partner_id if partner_match==1 & partnered==1 & sex==2 & unpaid_flag==1, by(marital_status_defacto)
tab marital_status_defacto if partner_match==1 & partnered==1 & sex==2 & unpaid_flag==1

// then DoL - but not quite sure what to do when unmatched...
**Paid / Unpaid
sum jbhrs if partner_match==1 & partnered==1 & sex==2, detail
sum jbhrs_sp if partner_match==1 & partnered==1 & sex==2, detail // do these match (e.g. if spouse of woman or man himself replying?) essentially yes
sum jbhrs if partner_match==1 & partnered==1 & sex==1, detail // do these match?

sum total_hours if partner_match==1 & partnered==1 & sex==2, detail
sum total_hours_sp if partner_match==1 & partnered==1 & sex==2, detail

sum total_hours if partner_match==1 & partnered==1 & sex==2 & employed==1, detail
sum total_hours_sp if partner_match==1 & partnered==1 & sex==2 & employed_sp==1, detail

tabstat jbhrs_sp jbhrs total_hours_sp total_hours if partner_match==1 & partnered==1 & sex==2, by(marital_status_defacto)
tabstat jbhrs_sp total_hours_sp if partner_match==1 & partnered==1 & sex==2 & employed_sp==1, by(marital_status_defacto)
tabstat jbhrs total_hours if partner_match==1 & partnered==1 & sex==2 & employed==1, by(marital_status_defacto)

tabstat paid_wife_pct_ot unpaid_wife_pct if partner_match==1 & partnered==1 & sex==2, by(marital_status_defacto)
tab marital_status_defacto paid_dol_ot if partner_match==1 & partnered==1 & sex==2, row
tabstat howlng howlng_sp unpaid_wife_pct if partner_match==1 & partnered==1 & sex==2, by(marital_status_defacto)
tab marital_status_defacto unpaid_dol if partner_match==1 & partnered==1 & sex==2, row

**Categorical by gender
tab marital_status_defacto hubuys if partner_match==1 & partnered==1 & sex==2, row nofreq // women's responses
// tab marital_status_defacto hubuys_sp if partner_match==1 & partnered==1 & sex==2, row // men's responses
tab marital_status_defacto hubuys if partner_match==1 & partnered==1 & sex==1, row nofreq // men's responses

tab marital_status_defacto hufrys if partner_match==1 & partnered==1 & sex==2, row nofreq // women's responses
tab marital_status_defacto hufrys if partner_match==1 & partnered==1 & sex==1, row nofreq // men's responses

tab marital_status_defacto huiron if partner_match==1 & partnered==1 & sex==2, row nofreq // women's responses
tab marital_status_defacto huiron if partner_match==1 & partnered==1 & sex==1, row nofreq // men's responses

tab marital_status_defacto humops if partner_match==1 & partnered==1 & sex==2, row nofreq // women's responses
tab marital_status_defacto humops if partner_match==1 & partnered==1 & sex==1, row nofreq // men's responses

tab marital_status_defacto huboss if partner_match==1 & partnered==1 & sex==2, row nofreq // women's responses
tab marital_status_defacto huboss if partner_match==1 & partnered==1 & sex==1, row nofreq // men's responses

tab marital_status_defacto husits if partner_match==1 & partnered==1 & sex==2, row nofreq // women's responses
tab marital_status_defacto husits if partner_match==1 & partnered==1 & sex==1, row nofreq // men's responses

// then describe couples (age, education, race - except need to figure some of these out, might need to get from cross-wave file)
tabstat current_rel_duration age_all age_all_sp if partner_match==1 & partnered==1 & sex==2, by(marital_status_defacto)

recode gor_dv (1/9=1)(10=2)(11=3)(12=4), gen(country_all)
replace country_all=. if inlist(country_all,-9,13)
label define country 1 "England" 2 "Wales" 3 "Scotland" 4 "N. Ireland"
label values country_all country

tab marital_status_defacto country_all if partner_match==1 & partnered==1 & sex==2, row nofreq

gen kids_in_hh=0
replace kids_in_hh=1 if nkids_dv > 0 & nkids_dv!=.

tab marital_status_defacto kids_in_hh if partner_match==1 & partnered==1 & sex==2, row

fre hiqual_dv
tab marital_status_defacto hiqual_dv if partner_match==1 & partnered==1 & sex==2, row nofreq // this is probably not the best education to use, but will use for now.
tab marital_status_defacto hiqual_dv_sp if partner_match==1 & partnered==1 & sex==2, row nofreq // this is probably not the best education to use, but will use for now.
tab marital_status_defacto hiqual_dv if partner_match==1 & partnered==1 & sex==1, row nofreq // this is probably not the best education to use, but will use for now.