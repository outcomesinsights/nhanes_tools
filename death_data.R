# documentation of death files extracted from SAS code
# saving this file as a resource

	SEQN			1-5 	/* SEQN IS THE PUBLIC-USE ID FOR NHANES */
	ELIGSTAT		15
	MORTSTAT		16
	CAUSEAVL		17
	UCOD_LEADING	$18-20
	DIABETES		21
	HYPERTEN		22
	
	PERMTH_INT		44-46	/*NHANES ONLY*/
	PERMTH_EXM		47-49	/*NHANES ONLY*/

	MORTSRCE_NDI	50
	MORTSRCE_CMS	51
	MORTSRCE_SSA	52
	MORTSRCE_DC		53
	MORTSRCE_DCL	54
	
	ELIGSTAT		=	'Eligibility Status for Mortality Follow-up'
	MORTSTAT		=	'Final Mortality Status'
	CAUSEAVL		=	'Cause of Death Data Available'
	UCOD_LEADING	=	'Underlying Cause of Death Recode from UCOD_113 Leading Causes'
	DIABETES		=	'Diabetes flag from multiple cause of death'
	HYPERTEN		=	'Hypertension flag from multiple cause of death'
	SEQN			=	'NHANES Respondent Sequence Number'
	PERMTH_INT		=	'Person Months of Follow-up from Interview Date'
	PERMTH_EXM		=	'Person Months of Follow-up from MEC/Exam Date'

	MORTSRCE_NDI	=	'Mortality Source: NDI Match'
	MORTSRCE_CMS 	=	'Mortality Source: CMS Information'
	MORTSRCE_SSA 	=	'Mortality Source: SSA Information'
	MORTSRCE_DC 	=	'Mortality Source: Death Certificate Match'
	MORTSRCE_DCL 	=	'Mortality Source: Data Collection'
	
  VALUE ELIGFMT
    1 = "Eligible"
    2 = "Under age 18"
    3 = "Ineligible" ;

  VALUE MORTFMT
    0 = "Assumed alive"
    1 = "Assumed deceased"
    . = "Ineligible or under age 18";

  VALUE MRSRCFMT
  	1 = "Yes";

 VALUE CAUSEFMT
  	0 = "No"
	1 = "Yes"
	. = "Ineligible, under age 18 or assumed alive";

  VALUE FLAGFMT
    0 = "No"
    1 = "Yes"  
    . = "Ineligible, under age 18, assumed alive or no cause data";

  VALUE QRTFMT
    1 = "January - March"
    2 = "April   - June"
    3 = "July    - September"
    4 = "October - December" 
    . = "Ineligible, under age 18 or assumed alive";

  VALUE DODYFMT
    . = "Ineligible, under age 18 or assumed alive";

  VALUE $UCODFMT
		"001" = "Diseases of heart (I00-I09, I11, I13, I20-I51)"
		"002" = "Malignant neoplasms (C00-C97)"
		"003" = "Chronic lower respiratory diseases (J40-J47)"
		"004" = "Accidents (unintentional injuries) (V01-X59, Y85-Y86)"
		"005" = "Cerebrovascular diseases (I60-I69)"
		"006" = "Alzheimer's disease (G30)"
		"007" = "Diabetes mellitus (E10-E14)"
		"008" = "Influenza and pneumonia (J09-J18)"
		"009" = "Nephritis, nephrotic syndrome and nephrosis (N00-N07, N17-N19, N25-N27)"
		"010" = "All other causes (residual)" 
		"   " = "Ineligible, under age 18, assumed alive or no cause data" ;
		
FORMAT    
	ELIGSTAT 		ELIGFMT.          
	MORTSTAT 		MORTFMT.
	UCOD_LEADING	UCODFMT.
	MORTSRCE_NDI 	MRSRCFMT.
	MORTSRCE_CMS 	MRSRCFMT.
	MORTSRCE_SSA 	MRSRCFMT.
	MORTSRCE_DC 	MRSRCFMT.
	MORTSRCE_DCL 	MRSRCFMT.
	
	CAUSEAVL 		CAUSEFMT.
	DODQTR   		QRTFMT.           
	DODYEAR  		DODYFMT.
	DIABETES 		FLAGFMT.          
	HYPERTEN 		FLAGFMT. 
     	;