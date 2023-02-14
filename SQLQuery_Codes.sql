
/* WELCOME TO SSMS! 
This code was written to assist newcomers to SSMS who need to perform queries
within databases 

/* Connect to a SQL Server
You should get a prompt when opening to connect to a SQL Server. If not, 
this will help you connect and view databases on that server */;

(1) In Management Studio, on FILE menu select CONNECT OBJECT EXPLORER. 
(2) The CONNECT TO SERVER dialog box will open. The SERVER TYPE box displays the type of
	component that was last used.
(3) Select DATABASE ENGINE. 
(4) In the "Server name" select the name of the Database Engine. This might be in a drop down box. 
	If this is not available, you may have to go into ODBC DATA SOURCES on your computer, set up 
	server connections, utilizing admin approval (if needed to access certain connections). */


/* CODES BELOW FOR RETRIEVING DATA: */


/* IMMUNIZATION DATA */
/* Pull immunization data from cases_iz & match to CEDRS */

SELECT iz.profileid, iz.eventid, iz.vaccination_date, iz.vaccination_code_id, 
		cdr.profileid, cdr.eventid,cdr.collectiondate, cdr.countyassigned, cdr.breakthrough,
			 cdr.partialonly, cdr.reinfection, cdr.hospitalized, cdr.deathdueto_vs_u071

	FROM [covid19].[ciis].[case_iz] iz
	
	LEFT JOIN [covid19].[dbo].[cedrs_view] cdr on iz.eventid = cdr.eventid
	
	WHERE BREAKTHROUGH = 1 
	ORDER BY iz.eventid, iz.vaccination_date
; 


/* Find a COUNT for a variable */
/* How many eventids (cases) are there were breakthrough = 1? */;

SELECT COUNT (eventid) 
	FROM [covid19].[dbo].[cedrs_view] 
	WHERE Breakthrough = 1; 

/* How many eventids (cases) are there were breakthrough = 1 on & after 9/1/2022? */;	
SELECT COUNT (eventid) 
	FROM [covid19].[dbo].[cedrs_view] 
	WHERE Breakthrough = 1 and collectiondate >= '2022-09-01' 

/* How many eventids (cases) are there were breakthrough = 1 and hospitialized in September 2022? */;	
/* use BETWEEN, as it is similar to >= and <= */
SELECT COUNT (eventid) 
	FROM [covid19].[dbo].[cedrs_view] 
	WHERE Breakthrough = 1 and hospitalized = 1 and collectiondate between '2022-09-01' and '2022-09-30' 




/* ELR DATA PULLS */;
/* This code creates a trailing 3-week variable based upon when lab last submitted */

WITH raw_data ( PatientID,Test_LOINC, CollectionDate, ReceiveDate, Submitter, Result, DateAdded, ResultDate, Sender, 
Performing_Organization, COVID19Negative, sender_new ) AS (

SELECT
PatientID
, Test_LOINC
, CollectionDate
, ReceiveDate
, Submitter
, Result
, DateAdded
, ResultDate
, Sender
, Performing_Organization
, COVID19Negative
, CASE WHEN sender = 'ProviderFlatfileUpload' or sender is null THEN submitter ELSE sender end as sender_new

from ELR_DW.dbo.viewPatientTestELR

where
CollectionDate > '2022-11-10' and
Test_LOINC in  ('41458-1', '94306-8', '94309-2', '94500-6', '94502-2', '94531-1', '94533-7', 
                '94534-5', '94559-2', '94565-9', '94568-9', '94640-0', '94756-4', '94757-2', 
                '94759-8', '94760-6', '94845-5', '95406-5', '95409-9', '95423-0', '95425-5', 
                '95608-6', '96094-8', '96123-5', '96448-6', '96986-5', '99999-9', 'COV19RES', 
                'COVID', 'Z5664', 'COV_CHLDRN', 'UN_COV_RT', 'COVIDEPLEX', '2019-nCoV RNA')
), sender_daily_totals ( DateAdded, daily_total, sender_new )  as (

SELECT
DateAdded
, count(*) as daily_total
, sender_new
FROM raw_data
group by DateAdded, sender_new

)

SELECT
*
, sum(daily_total) OVER ( PARTITION BY sender_new ORDER BY DateAdded ROWS 2 PRECEDING ) AS trailing3_results
FROM sender_daily_totals