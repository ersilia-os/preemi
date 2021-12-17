/*PREEMI data analysis for Albert
by: jake pry
create date: 3 mar 2020
modify date: 12 apr 2021
analysis outlined in albert's email 26 feb 2020 */

*import data
	clear
	import delimited "/Users/jakepry/Box Sync/Admin/Manuscripts/Manasayan_PREEMI/Datasets/dataset_recon-12apr2021.csv", varn(1)
	des

	drop dod_e2_str dod_e3_str yob e7mort e28mort ptd peri parity_cat age_cat facility_encoded anc_visit bwt lmp_date sex_baby educ_cat still g_age outcome

	use "/Users/jakepry/Box Sync/Admin/Manuscripts/Manasayan_PREEMI/Datasets/dataset_recon-25apr2021.dta", clear
	
*gen yes/no variable label
	*la def ny 0 "No" 1 "Yes" 2 "Don't Know" 3 "NA"

	foreach x of varlist antcar_e2 motrcvttc_e2-motrcvult_e2 motconobs_e2-motconpl_e2 motconpprom_e2-mattremag_e2 multbirth_e2-neotrekmc_e2 {
		replace `x' = strltrim(`x')
		replace `x' = strrtrim(`x')
		replace `x' = "0" if `x' == "2=No" | `x' == "2" | lower(`x') == "no"
		replace `x' = "1" if `x' == "1=Yes" | `x' == "1" | lower(`x') == "yes"
		replace `x' = "2" if `x' == "3=Donât know" | lower(`x') == "don't know"
		replace `x' = "3" if `x' == "4=NA"
		destring `x', replace
		}
	
	la val antcar_e2 motrcvttc_e2-motrcvult_e2 motconobs_e2-motconpl_e2 motconpprom_e2-mattremag_e2 multbirth_e2-neotrekmc_e2 ny

	*alive/dead label
	foreach x of varlist infsta_e4 infsta_e3 matsta_e5 {
		replace `x' = "0" if `x' == "1=Alive" | `x' == "0" | lower(`x') == "alive"
		replace `x' = "1" if `x' == "2=Died" | `x' == "1" | lower(`x') == "died"
		destring `x', replace
		}
		
	la def alive 0 "Alive" 1 "Dead"
	la val infsta_e4 infsta_e3 matsta_e5 alive
	
	la var infsta_e4 "Infant Status 28 Days"
	la var infsta_e3 "Infant Status 7 Days"
	la var matsta_e5 "Maternal Status 42 Days"

*1= Miscarriage (<24 wks) [skip to E1], 2=Medically Terminated Pregnancy (MTP) [skip to E1], 3=Fresh Stillbirth, 4=Macerated Stillbirth, 5=Born alive
	drop outcome
	gen outcome = 1 if fetneo_e2 == "1= Miscarriage (<24 wks) [skip to E1]"
	replace outcome = 2 if fetneo_e2 == "2=Medically Terminated Pregnancy (MTP) [skip to E1]"
	replace outcome = 3 if fetneo_e2 == "3=Fresh Stillbirth (No movement" | fetneo_e2 == "3=Fresh Stillbirth"
	replace outcome = 4 if fetneo_e2 == "4=Macerated Stillbirth"
	replace outcome = 5 if fetneo_e2 == "5=Born alive"
	
	la def outcome 1 "Miscarriage" 2 "Med Terminated Preg" 3 "Fresh SB" 4 "Mascerated SB" 5 "Born Alive"
	la val outcome outcome

*variable for status at 28 days
	la var dod_e3 "Date of Death (28 days)"
	tab infsta_e4
	rename dod_e4 dod_e4_str
	gen dod_e4 = date(dod_e4_str, "DMY", 2019)
		format dod_e4 %td
	
	hist dod_e4, fcolor(green*.5) lcolor(white) freq
	replace dod_e4 = . if dod_e4 == td(01jan1900)

*variable for status at 7 days
	drop dod_e3_str
	la var dod_e3 "Date of Death (7 days)"
	tab infsta_e3
	rename dod_e3 dod_e3_str
	gen dod_e3 = date(dod_e3_str, "DMY", 2019)
		format dod_e3 %td

*year of birth (yob)
	la var dod_e2 "Date of Delivery"
	hist dod_e2, freq graphregion(c(white)) fcol(midblue) lcol(white)
	
	drop yob
	gen yob = year(dod_e2)
		tab yob
		
*facility category
	drop facility_encoded
	encode facid_e1, gen(facility_encoded)
	
*hiv test
	tab motrcvhivt_e2 
	la var motrcvhivt_e2 "Maternal HIV Test Done" 
	*not status
	
*birth weight
	drop bwt
	gen birthweight =  babwght_e2
	la var birthweight "Birth Weght (grams)"
		codebook birthweight
		*missing 353 values
		
	replace birthweight = . if bwt == 9999	
	*drop 143 values
	
	hist birthweight, freq graphregion(c(white)) fcol(midblue) lcol(white)
	

/********* outcome *********/

drop e7mort e28mort still ptd peri

*outcome 7 days if live birth
	bys studysubjectid: gen e7mort = 1 if infsta_e3 == 1 & outcome == 5
	bys studysubjectid: replace e7mort = 0 if outcome == 5 & e7mort == .
	
*outcome 28 days if live birth
	bys studysubjectid: gen e28mort = 1 if infsta_e4 == 1 & outcome == 5
	bys studysubjectid: replace e28mort = 0 if outcome == 5 & e28mort == .
	
*outcome stillbirth
	bys studysubjectid: gen still = 1 if outcome == 3 | outcome == 4
	bys studysubjectid: replace still = 0 if outcome == 5 & still == .
		
*neo-natel deaths among pre-term
	la var motconpl_e2 "Preterm labour"
	bys studysubjectid: gen ptd = 1 if (infsta_e4 == 1 | infsta_e3 == 1) & outcome == 5 & motconpl_e2 == 1
	bys studysubjectid: replace ptd = 0 if outcome == 5 & motconpl_e2 == 1 & ptd == .
	
*perinatal death
	bys studysubjectid: gen peri = 1 if (outcome == 3 | infsta_e3 == 1)
	bys studysubjectid: replace peri = 0 if outcome != 1 & peri == .

/********* end outcome *********/
	
* antenatal visits
	tab antcarfreq_e2
	la var antcarfreq_e2 "Antenatal Visits"
	
		drop anc_visit
		gen anc_visit = 1 if antcarfreq_e2 == 1
		replace anc_visit = 2 if antcarfreq_e2 == 2
		replace anc_visit = 3 if antcarfreq_e2 == 3
		replace anc_visit = 4 if antcarfreq_e2 > 3 & antcarfreq_e2 != .

			la def anc_visit 1 "1 ANC Visit" 2 "2 ANC Visits" 3 "3 ANC Visits" 4 "4+ ANC Visits" 5 "5+ ANC Visits"
			la val anc_visit anc_visit
			tab anc_visit
		
*parity
	tab parity_e1
	
		drop parity_cat
		gen parity_cat = 1 if parity_e1 == 1
		replace parity_cat = 2 if parity_e1 == 2
		replace parity_cat = 3 if parity_e1 == 3
		replace parity_cat = 4 if parity_e1 > 4 & parity_e1 != .
	
*age categorically
	drop age_cat
	gen age_cat = 1 if matage_e1 < 20 
	replace age_cat = 2 if matage_e1 < 25 & matage_e1 >= 20
	replace age_cat = 3 if matage_e1 < 30 & matage_e1 >= 25
	replace age_cat = 4 if matage_e1 < 35 & matage_e1 >= 30
	replace age_cat = 5 if matage_e1 < 40 & matage_e1 >= 35
	replace age_cat = 6 if matage_e1 < 45 & matage_e1 >= 40
	replace age_cat = 7 if matage_e1 >= 45 & matage_e1 != .
	
		la def age_cat 1 "<20 years" 2 "20-24 years" 3 "25-29 years" 4 "30-34 years" 5 "35-39 years" 6 "40-44 years" 7 "≥45 years"
		la val age_cat age_cat
			tab age_cat, m	
			
*years of education
	tab eduyrs_e1, m
	drop educ_cat
	gen educ_cat = 1 if eduyrs_e1 == 0
	replace educ_cat = 2 if eduyrs_e1 >= 1 & eduyrs_e1 < 10
	replace educ_cat = 3 if eduyrs_e1 >= 10 & eduyrs_e1 != .
		la def educ_cat 1 "None" 2 "1-9 years" 3 "≥10 years"
		la val educ_cat educ_cat
			tab educ_cat
			
*gestational age calc based on last menstual period date

	drop lmp_date
	gen lmp_date = date(mensdate_e1, "DMY", 2019)
		format lmp_date %td
		
	replace lmp_date = . if lmp_date == td(1jan1900)
	
	drop g_age
	gen g_age = ((dod_e2-lmp_date)) if dod_e2 != . & lmp_date != .
	replace g_age = . if g_age < 0
	replace g_age = . if g_age >= 390
		la var g_age "Gestational Age (days)"
		
	gen gestage = round(g_age/7, 1)
		la var gestage "Gestational Age (weeks)"
		hist gestage, graphregion(c(white)) freq fcol(green*.5) lcol(white)
		
	replace delivwhr_e2 = "1" if delivwhr_e2 == "1=Hospital"
	replace delivwhr_e2 = "2" if delivwhr_e2 == "2=Clinic/Health centre"
	replace delivwhr_e2 = "3" if delivwhr_e2 == "3=Home"
	replace delivwhr_e2 = "4" if delivwhr_e2 == "4=Other"
		destring delivwhr_e2, replace
	
		la def delivwhr_e2 1 "Hospital" 2 "Clinic/Health Center" 3 "Home" 4 "Other"
		la val delivwhr_e2 delivwhr_e2
			tab delivwhr_e2
	
*save new working dataset
	save "/Users/jakepry/Box Sync/Admin/Manuscripts/Manasayan_PREEMI/Datasets/dataset_recon-25apr2021.dta"
	
	use "/Users/jakepry/Box Sync/Admin/Manuscripts/Manasayan_PREEMI/Datasets/dataset_recon-25apr2021.dta", clear
		
***************** end var prep *****************

*plot the deaths continuously over time
	hist yob, graphregion(c(white))
	scatter dod_e2 dod_e3, graphregion(c(white))

		dotplot dod_e2, recast(scatter) graphregion(c(white))
		dotplot dod_e4, recast(scatter) graphregion(c(white))
		dotplot dod_e3, recast(scatter) graphregion(c(white))

		codebook studysubjectid
		*11,535 individuals

*confidence intervals
	ci prop e7mort if yob == 2015
	ci prop e7mort if yob == 2016
	ci prop e7mort if yob == 2017

	ci prop e28mort if yob == 2015
	ci prop e28mort if yob == 2016
	ci prop e28mort if yob == 2017

	ci prop still if yob == 2015
	ci prop still if yob == 2016
	ci prop still if yob == 2017

	ci prop ptd if yob == 2015
	ci prop ptd if yob == 2016
	ci prop ptd if yob == 2017

	ci prop peri if yob == 2015
	ci prop peri if yob == 2016
	ci prop peri if yob == 2017


*unadjusted models
	melogit e7mort i.age_cat i.anc_visit i.educ_cat ib2.delivwhr_e2 || facility_encoded:, vce(robust) or
	
	margins i.age_cat##i.anc_visit
	marginsplot, graphregion(c(white))

*prep for meeting with Albert & Dan

/*should we consider dropping those for which we do not have birth outcome?*/

	*yes
	*drop if outcome == .
	*drop 321 obs

	hist bwt, fcol(green*.5) lcol(white) freq graphregion(c(white)) norm
	
	*mean weight live and still
	sum bwt if still == 0, d
	sum bwt if still == 1, d
		
	*mean gestational age live and still
	sum g_age if still == 0, d
	sum g_age if still == 1, d
			
	tab sex if still == 0, m
	tab sex if still == 1, m
	
	tab educ_cat if still == 0, m
	tab educ_cat if still == 1, m
	
	*save "/Users/jakepry/Box Sync/Admin/Manuscripts/Manasayan_PREEMI/Datasets/preemi_output-13feb2021.dta"
	*use "/Users/jakepry/Box Sync/Admin/Manuscripts/Manasayan_PREEMI/Datasets/preemi_output-13feb2021.dta", clear
	
	use "/Users/jakepry/Box Sync/Admin/Manuscripts/Manasayan_PREEMI/Datasets/dataset_recon-25apr2021.dta", clear
	
	keep if dod_e2 == .
	keep if g_age >= 316
	keep if g_age <= 126 & outcome != 1
	
	tab outcome if g_wks == 40
	br if outcome == 4 & g_wks == 40
	br if bwt == 840 & g_wks == 40
	
	hist bwt if g_wks == 40, freq 
	sum bwt if g_wks == 40

*id cleaning
	replace studysubjectid = strltrim(studysubjectid)
	replace studysubjectid = strrtrim(studysubjectid)
	replace studysubjectid = "115A-03429-1" if studysubjectid == "15A-03429 -1"
	replace studysubjectid = "15A-04085-1" if studysubjectid == "15A-04085--1"
	
*gen mother id
	split studysubjectid, parse("-") gen(mt_id)
	gen mt_id = mt_id1 + "-" + mt_id2
		drop mt_id1-mt_id3
		
		codebook mt_id
		
*gen pregnancy id
	gen pr_id = studysubjectid
	
		codebook pr_id

*gen child id
	gen ch_id = _n if outcome == 5
	
		codebook ch_id

*gen vital status
	gen vitalstatus = 0 if outcome == 5
	replace vitalstatus = 1 if outcome != 5 & outcome != .
	replace vitalstatus = 8 if outcome == .
	
	label var vitalstatus "Vital status at delivery"
	label define vitalstatus 0 "Live birth" 1 "Pregnancy loss" 8"LTF" 9"Censored", replace 
	label values vitalstatus vitalstatus 
	
		tab vitalstatus
	
*gen livebirth
	gen livebirth = 0 if outcome == 5
	replace livebirth = 1 if outcome != 5 & outcome != .
	
	label var livebirth "Vital status at delivery"
	label define livebirth 0 "Live birth" 1 "Pregnancy loss", replace 
	label values livebirth livebirth 
	
		tab livebirth
	
*gen sex
	gen sex = 0 if babysex_e2 == "1=Male"
	replace sex = 1 if babysex_e2 == "2=Female"
	replace sex = 9 if babysex_e2 == "" & outcome == 5
	
	label variable sex "Sex of infant" 
	label define sex 0 "Male" 1 "Female" 9 "Don't know", replace 
	label values sex sex
	
		tab sex
		
*gen multiple birth var
	split studysubjectid, parse("-") gen(multiple)
	destring multiple3, replace
	bys mt_id: egen multiple = max(multiple3) if multiple3 < 5 & livebirth != .

		replace multiple = 0 if multiple < 2
		replace multiple = 1 if multiple == 2
		replace multiple = 2 if multiple > 2 & multiple != . 
		
				drop multiple1-multiple3
	
	label variable multiple "Single or multiple birth"
	label define multiple 0 "Singleton" 1 "Twins" 2 "Triplets or higher order", replace 
	label values multiple multiple
	
		tab multiple
	
*gestational age
	*clean up estimated delivery date
	replace edd_e1 = "" if edd_e1 == "01/01/1900"
	replace mensdate_e1 = "" if mensdate_e1 == "01/01/1900"
	
	gen mensdate = date(mensdate_e1, "MDY", 2018) 
		format mensdate %td

	gen preterm = 0 if gest_age >= 37 & gest_age != . 
	replace preterm = 1 if gest_age < 37
	replace preterm = . if gest_age == .
	label define preterm 0 "Term" 1 "Preterm", replace 
	label values preterm preterm

	tab preterm 
	tab preterm, m 
	
*birth weight
	gen birthweight = bwt
	
*time weight collected
	tab delivwhr_e2, m
	
* VARIABLE 14: GESTATIONAL AGE CATEGORY 1 
********************
	gen gestagecat1 = 0 if gestage>=40
		replace gestagecat1 = 1 if gestage >= 37 & gestage < 40
		replace gestagecat1 = 2 if gestage >= 34 & gestage < 37
		replace gestagecat1 = 3 if gestage >= 32 & gestage < 34
		replace gestagecat1 = 4 if gestage >= 30 & gestage < 32
		replace gestagecat1 = 5 if gestage >= 28 & gestage < 30 
		replace gestagecat1 = 6 if gestage < 28
		label define gestagecat1 0 "≥40 weeks"    ///
								 1 "≥37-40 weeks" /// 
								 2 "≥34-<37 weeks" /// 
								 3 "≥32-<34 weeks" ///
								 4 "≥30-<32 weeks" /// 
								 5 "≥28-<30 weeks" /// 
								 6 "<28 weeks", replace
		label values gestagecat1 gestagecat1
		
	tab gestagecat1
	tab gestagecat1, m 	
	
* VARIABLE 15: GESTATIONAL AGE CATEGORY 2 
********************
	egen gestagecat2 = cut(gestage), at(0 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44) icodes 
		replace gestagecat2 = 23 if gestage >= 44 & gestage != .
		label define gestagecat2 0 "<22" 1 "≥22-<23" 2 "≥23-<24" ///
							 3 "≥24-<25" 4 "≥25-<26" 5 "≥26-<27" ///
							 6 "≥27-28" 7 "≥28-<29" 8 "≥29-<30" /// 
							 9 "≥30-31" 10 "≥31-<32" 11 "≥32-<33" /// 
							 12 "≥33-34" 13 "≥34-<35" 14 "≥35-<36" ///  
							 15 "≥36-37" 16 "≥37-<38" 17 "≥38-<39" ///  
							 18 "≥39-40" 19 "≥40-<41" 20 "≥41-<42" ///  
							 21 "≥42-43" 22 "≥43-<44" 23 "≥44", replace  
		label values gestagecat2 gestagecat2
		
	tab gestagecat2
	tab gestagecat2, m 

* VARIABLE 11: METHOD OF GESTATIONAL AGE ASSESSMENT 
********************
	gen gestmethod = 4 if gestage != .
	replace gestmethod = 9 if gestage == . 
	
	label variable gestmethod "Methods of gestational age assessment"
	label define gestmethod 0 "1st trimester (<14 weeks) ultrasound" /// 
							1 "Second trimester (14-24 weeks) ultrasound" ///
							2 "3rd trimester (>24 weeks) ultrasound" /// 
							3 "Ultrasound, exam date unknown" ///
							4 "LMP" /// 
							6 "Other" ///
							9 "Missing", replace 						
	label values gestmethod gestmethod 
	

* Note value 6 "other" in variable gestage_other if appropriate
	
* VARIABLE 16: BIRTH WEIGHT COLLECTION TIME
******************** 
/* generate a variable "bwtime" to indicate hours weight measurement was taken since delivery 
rename xxxx bwtime

* VARIABLE 17: BIRTH WEIGHT COLLECTION TIME CATEGORY
******************** 
gen bwdat=.
	replace bwdat=0 if bwtime<6| bwtime !=.
	replace bwdat=1 if bwtime>=6 & bwtime <24
	replace bwdat=2 if bwtime>=24 & bwtime <72
	replace bwdat=3 if bwtime>72 & bwtime !=.
	replace bwdat=9 if birthweight==. | bwtime ==.
	label define bwdat  0"At delivery (between 0-6 hours)" /// 
						1"Birthweight ≥6 hours & <24 hours" ///
						2"Birthweight taken ≥24 hours & ≤72 hours" ///
						3"Birthweight >72 hours" ///
						9"Birth weight missing", replace 
	label values bwdat bwdat
	
tab bwdat
tab bwdat, m
*/

* VARIABLE 18:LOW BIRTH WEIGHT 
********************
	cap drop lbw 
	gen lbw = 0 if birthweight >= 2500
		replace lbw = 1 if birthweight < 2500
		replace lbw = . if birthweight == . 
		label define lbw 0 "Normal birthweight" 1 "Low birthweight", replace 
		label values lbw lbw
		
	tab lbw 
	tab lbw, m  

* VARIABLE 19: BIRTH WEIGHT CATEGORY 1
********************
	egen birthweightcat1 = cut(birthweight), at(0 1000 1250 1500 1750 2000 2250 2500 2750 3000 3250 3500 3750 4000 5000) icodes 
		replace birthweightcat1 = 13 if birthweightcat1 >= 4000 & birthweightcat1 != .
		label define birthweightcat1 0 "<1000" 1 "≥1000-<1250" 2 "≥1250-<1500" ///
									 3 "≥1500-<1750" 4 "≥1750-<2000" 5 "≥2000-<2250" ///
									 6 "≥2250-2500" 7 "≥2500-<2750" 8 "≥2750-<3000" /// 
									 9 "≥3000-3250" 10 "≥3250-<3500" 11 "≥3500-<3750" /// 
									 12 "≥3750-4000" 13 "≥4000", replace  
		label values birthweightcat1 birthweightcat1
		
	tab birthweightcat1
	tab birthweightcat1, m 


/* VARIABLE 20: SGA 
********************
	cap drop sga 
	gen sga = . 
		replace sga = 0 if weightcentile >= 10
		replace sga = 1 if weightcentile < 10
		label define sga 0"AGA" 1"SGA (<10%)", replace 
		label values sga sga 
		
	tab sga 
	tab sga, m 

* VARIABLE 21: SGA CATEGORY 1
********************
gen sgacat1=0 if weightcentile >=10
	replace sgacat1=1 if weightcentile <10 & weightcentile >3
	replace sgacat1=2 if weightcentile <3
	label define sgacat1 0"AGA" 1"SGA (3-<10%)" 2"SGA(<3%)", replace 
	label values sgacat1 sgacat1 
	
tab sgacat1
tab sgacat1, m 

* VARIABLE 22: SGA CATEGORY 2
********************
egen sgacat2 = cut(weightcentile), at(0 3 4 5 6 7 8 9 10 20 30 40 50 60 70 80 90 100) icodes 
	replace sgacat2 = 16 if weightcentile >=90 & weightcentile !=.
	label define sgacat2 		 0 "<3%" 1 "≥3-<4%" 2 "≥4-<5" 3 "≥5-<6" 4 "≥6-<7" ///
								 5 "≥7-<8" 6 "≥8-<9" 7 "≥9-<10" 8 "≥10-<20" ///
								 9 "≥20-30" 10 "≥30-<40" 11 "≥40-<50" 12 "≥50-<60" /// 
							     13 "≥60-70" 14 "≥70-<80" 15 "≥80-<90" /// 
								 16 "≥90-100", replace  
	label values sgacat2 sgacat2
	
tab sgacat2 
tab sgacat2, m 

* VARIABLE 23: Weight for age centile 
********************
egen weightcentilecat1 = cut(weightcentile), at(0 3 4 5 6 7 8 9 10 20 30 40 50 60 70 80 90 91 92 93 94 95 96 97 98 99 100) icodes 
	replace weightcentilecat1 = 25 if weightcentile==100
	label define weightcentilecat1 		 0 "<3%" 1 "≥3-<4%" 2 "≥4-<5" 3 "≥5-<6" 4 "≥6-<7" ///
								 5 "≥7-<8" 6 "≥8-<9" 7 "≥9-<10" 8 "≥10-<20" ///
								 9 "≥20-30" 10 "≥30-<40" 11 "≥40-<50" 12 "≥50-<60" /// 
							     13 "≥60-70" 14 "≥70-<80" 15 "≥80-<90" /// 
								 16 "≥90-<91%" 17"≥91-<92%" 18"≥92-<93%" 19"≥93-<94%" 20"≥94-<95%" 21"≥95-<96%" 22"≥96-<97%" 23"≥97-<98%" 24"≥98-<99%" 25"≥99-100%", replace  
	label values weightcentilecat1 weightcentilecat1
	
tab weightcentilecat1 
tab weightcentilecat1, m 

// VARIABLE 24: PHENOTYPES OF VULNERABLE NEWBORNS
********************
gen phenotype = 0 if sga ==0 & preterm == 0 & lbw == 0
	replace phenotype = 1 if sga == 1 & preterm == 0 & lbw == 0
	replace phenotype = 2 if sga == 1 & preterm == 0 & lbw == 1
	replace phenotype = 3 if sga == 0 & preterm == 1 & lbw == 0
	replace phenotype = 4 if sga == 0 & preterm == 1 & lbw == 1
	replace phenotype = 5 if sga == 1 & preterm == 1 & lbw == 1	
	replace phenotype = 6 if sga == 0 & preterm == 0 & lbw == 1	
	label define phenotype 0 "AGA+T+NBW" 1 "SGA+T+NBW" 2 "SGA+T+LBW" ///
						   3 "AGA+PT+NBW" 4 "AGA+PT+LBW" 5 "SGA+PT+LBW" ///
						   6 "AGA+T+LBW", replace 
	label values phenotype phenotype
	
tab phenotype
tab phenotype, m 
*/

// B. GENERATE VITAL STATUS, LAST DATE ALIVE, DATE OF DEATH 
****************************************	
	rename dod_e2 dob 
	rename e28mort vitalstatus28
	replace vitalstatus28 = 9 if vitalstatus28 == .

	label variable vitalstatus28 "Vital status at 28 days"
	label define vitalstatus28 0 "Alive" 1 "Dead" 9 "Unknown", replace 
	label values vitalstatus28 vitalstatus28

tab vitalstatus28
tab vitalstatus28, m 

	rename e7mort vitalstatus7
	replace vitalstatus7 = 9 if vitalstatus7 == .

	label variable vitalstatus7 "Vital status at 7 days"
	label define vitalstatus28 0 "Alive" 1 "Dead" 9 "Unknown", replace 
	label values vitalstatus7 vitalstatus28

tab vitalstatus7
tab vitalstatus7, m 

cap drop died 
gen died = 0 if vitalstatus28 == 0 
	replace died = 1 if vitalstatus28 == 1
	label variable died "Alive or died"
	label define died 0 "Alive" 1 "Died", replace 
	label values died died 

tab died
tab died, m 

// C. FOLLOW-UP TIME & MORTALITY BY PERIOD
****************************************
gen fup_days = 7 if vitalstatus7 == 0
replace fup_days = 28 if vitalstatus28 == 0  //follow-up in days

* Generate variables for follow-up by time period  
gen fup_earlyneo = fup_days
	replace fup_earlyneo = 7 if fup_earlyneo >= 7 & fup_days != . 

gen fup_lateneo = fup_days
	replace fup_lateneo = . if fup_lateneo <7 
	replace fup_lateneo = 28 if fup_lateneo >= 28 & fup_days != . 

gen fup_neo = fup_days
	replace fup_neo = 28 if fup_neo >= 28 & fup_days != . 

//D. Generate variables for mortality by age category 
****************************************
gen earlyneo = . 
	replace earlyneo = 0 if died == 1 & fup_days>7 & fup_days != . 
	replace earlyneo = 0 if died == 0 & fup_days>7 & fup_days != . 
	replace earlyneo = 1 if died == 1 & fup_days <=7 
	replace earlyneo = 2 if died == 0 & fup_days<=7
	label define earlyneo  0 "Alive at End of 7 Day Follow-up" /// 
						   1 "Death During 7 Day Follow-up" /// 
						   2 "Censored During 7 Day Follow-up", replace  
	label values earlyneo earlyneo
	
tab earlyneo
tab earlyneo, m

gen lateneo = . 
	replace lateneo = 0 if died == 1 & fup_days>28 & fup_days != . 
	replace lateneo = 0 if died == 0 & fup_days>28 & fup_days != . 
	replace lateneo = 1 if died == 1 & fup_days >7 & fup_days <=28
	replace lateneo = 2 if died == 0 & fup_days>7 & fup_days <=28
	label define lateneo  0 "Alive at End of 7-28 Day Follow-up" /// 
						  1 "Death During 7-28 Day Follow-up" /// 
						  2 "Censored During 7-28 Day Follow-up", replace  
	label values lateneo lateneo

tab lateneo
tab lateneo, m

gen neo = . 
	replace neo = 0 if died == 1 & fup_days>28 & fup_days != . 
	replace neo = 0 if died == 0 & fup_days>28 & fup_days != . 
	replace neo = 1 if died == 1 & fup_days <=28
	replace neo = 2 if died == 0 & fup_days<=28
	label define neo  0 "Alive at End of 28 Day Follow-up" /// 
					  1 "Death During 28 Day Follow-up" /// 
				      2 "Censored During 28 Day Follow-up", replace  
	label values neo neo
	
tab neo
tab neo, m

********************************************************************************
// 7. GENERATE VARIABLES FOR COVARIATES 
********************************************************************************	

// VARIABLE 26: MATERNAL AGE 
****************************************
rename matage_e1 matage  //maternal age in years at enrollment 

gen matagecat=0 if matage<20
	replace matagecat=1 if matage>=20 & matage<25
	replace matagecat=2 if matage>=25 & matage<30
	replace matagecat=3 if matage>=30 & matage<35
	replace matagecat=4 if matage>=35
	replace matagecat=9 if missing(matage)
	label define matagecat 0 "<20" 1 "20-24" 2 "25-29" 3 "30-34" 4 "≥35" 9"Don't know", replace
	label values matagecat matagecat

tab matagecat, m  

// VARIABLE 27: PARITY
****************************************
rename parity_e1 parity_lbsb  //Parity of live and still births 

gen parity = 0
replace parity = 1 if parity_lbsb>0 & parity_lbsb<4
	replace parity = 2 if parity_lbsb>=4
	replace parity = 9 if parity_lbsb==.
	label define parity 0 "0" 1 "1-3" 2 "≥4" 9 "Don't know", replace 
	label values parity parity

tab parity 
tab parity_lbsb parity, m  

// VARIABLE 28: EDUCATION
****************************************
	rename educ_cat womeduc	
	
	label define womeduc 0 "0 years (no formal education)" 1 "1-9 years" /// 
	2 "≥10 years" 9 "Don't know", replace
	label values womeduc womeduc

tab womeduc
tab womeduc, m 

// VARIABLE 29: PLACE OF DELIVERY 
****************************************
	gen deplace = delivwhr_e2
	replace deplace = 0 if deplace == 3
	replace deplace = 1 if deplace == 2
	replace deplace = 9 if deplace == 4 | deplace == .

	label define deplace 0 "Home delivery" 1 "Facility delivery" 9 "Don't know", replace 
	label values deplace deplace

tab deplace 
tab deplace, m  

// VARIABLE 30: TYPE OF DELIVERY
****************************************
* This variable should include both facility and non-facility births 
	gen detype = mod_e2
	replace detype = "0" if strpos(lower(detype), "vaginal") 
	replace detype = "1" if strpos(lower(detype), "section") 
	replace detype = "9" if detype == ""
		destring detype, replace

	label define detype 0 "Vaginal" 1 "Cesarean" 9"Don't know", replace 
	label values detype detype 

tab detype
tab detype, m

// VARIABLE 35: PREGNANCY OUTCOME
****************************************
	gen pr_outcome = 0 if outcome == 5
	replace pr_outcome = 1 if outcome == 3 | outcome == 4
	replace pr_outcome = 3 if outcome == 1
	replace pr_outcome = 9 if outcome == .
	
	label define pr_outcome 0 "Live birth" 1 "Stillbirth" 2 "Abortion" ///
	3 "Miscarriage" 9 "Don't know", replace 
	label values pr_outcome pr_outcome

tab pr_outcome
tab pr_outcome, m 

* VARIABLE 17: BIRTH WEIGHT COLLECTION TIME CATEGORY
******************** 
* if born in hospital/clinic weight measured and recorded within 6hrs if home within 72hrs and other venue is unknown
gen bwdat = .
	replace bwdat = 0 if delivwhr_e2 == 1 | delivwhr_e2 == 2
	*replace bwdat = 1 if delivwhr_e2 == [x]
	*replace bwdat = 2 if bwtime >= 24 & bwtime < 72
	replace bwdat = 3 if delivwhr_e2 == 3
	replace bwdat = 9 if delivwhr_e2 == 4 | delivwhr_e2 == .
	
	label define bwdat  0 "At delivery (between 0-6 hours)" /// 
						1 "Birthweight ≥6 hours & <24 hours" ///
						2 "Birthweight taken ≥24 hours & ≤72 hours" ///
						3 "Birthweight >72 hours" ///
						9 "Birth weight missing", replace 
	label values bwdat bwdat
	
tab bwdat
tab bwdat, m	

*export csv
	export delimited using "/Users/jakepry/Box Sync/Admin/Manuscripts/Manasayan_PREEMI/Datasets/preemi_vul_newborn_review-26apr2021.csv"
	
*clean vars 
	save "/Users/jakepry/Box Sync/Admin/Manuscripts/Manasayan_PREEMI/Datasets/preemi-30apr2021.dta"
	
	use "/Users/jakepry/Box Sync/Admin/Manuscripts/Manasayan_PREEMI/Datasets/preemi-30apr2021.dta"
	
*strip down stata file for Dan & Liz
	keep mt_id pr_id ch_id vitalstatus livebirth sex multiple preterm gestagecat2 gestagecat1 lbw birthweightcat1 gestage ///
	 dob bwdat BWDQ_cat dob_day pr_outcome gestmethod parity matagecat detype deplace died 
	 
	la var mt_id "Mother ID"
	la var pr_id "Pregnancy ID"
	la var ch_id "Child ID"
	la var preterm "Pre-Term Delievry Status"
	la var gestagecat1 "Gestational Age (week) Cat 1"
	la var gestagecat2 "Gestational Age (week) Cat 2"
	la var lbw "Low Birthweight"
	la var deplace "Place of Delievery"
	la var detype "Type/Method of Delievery"
	la var matagecat "Maternal Age Category"
	la var parity "Parity"
	la var pr_outcome "Pregancy Outcome"
	 
	save "/Users/jakepry/Box Sync/Admin/Manuscripts/Manasayan_PREEMI/Datasets/preemi_vul_newborn_review-30apr2021_final.dta"
	



