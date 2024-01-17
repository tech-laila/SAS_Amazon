
/*
DP SAS Assignment 2 2023
Analysis Amazon File

Name:Laila Lima Alves
Student ID: 14344509


	Import the file and save it in a temporary library (work)  
*/


proc import datafile="/home/u60923758/A2023/A2/amazon.xlsx"
	dbms=xlsx
	out=AMZ
	replace;
	GETNAMES=YES;
run;


/* 
	
	Print the first 10 rows of the file and check their characteristics
	Use Proc content to check number of observations, number of variables, variable name, variable type and format
	The following variables are character types, but would rather be displayed as numerical:
	discounted_price
	actual_price
	rating_count
	Labels exist and their name is equal to the variables names 
*/




Title "Overview Amazon products list  in India (10 rows)";
proc print data=work.amz (obs=10);
run;


ODS NOPROCTITLE;
Title "File contents Amazon products in India";
proc contents data=work.amz;
run;



/* REMOVING DUPLICATES using NODUPRECS to eliminate rows with exactly the same information */
/* There are no duplicates rows in this file :-) */

proc sort data=work.amz out=work.amz;
by product_id;
run;


proc sort data=work.amz out=work.amz
	noduprecs dupout=work.amz_dup; 
	by _all_; 
run;



/* 
	Transform character variables into numerical and drop the old ones
	First transformed the monetary variables according to Matthew suggestions
	Second transform the rating variable into numerical
	A complete format check will be done later
*/


data AMZ; 
set AMZ; 
actual_price_p=ksubstr(actual_price, 2); 
price=input(actual_price_p, comma10.); 
discount_p=ksubstr(discounted_price, 2); 
discount=input(discount_p, comma10.); 
format price discount nlmnlinr.; 
drop actual_price_p  discount_p;
run;



data AMZ;
set amz;
rating_nr = input(rating_count, comma8.);
drop actual_price discounted_price rating_count;
run;



/* 
	Transformation of Categorical Variable 
	Divide the category into sub-category. A maximum of 4 sub-categories was chosen because the 5th sub-category showed a lot of missing values;
	https://www.statology.org/sas-split-string-by-delimiter/#:~:text=You%20can%20use%20the%20scan,based%20on%20a%20particular%20delimiter.
*/


data amz;
set amz;
main_category=scan(category, 1, '|');
sub_ctg1=scan(category, 2, '|');
sub_ctg2=scan(category, 3, '|');
sub_ctg3=scan(category, 4, '|');
run;


/* 
	Find the number of missing values in each variable and check their frequency
	https://blogs.sas.com/content/iml/2011/09/19/count-the-number-of-missing-values-for-each-variable.html
*/


proc format;
 value $missfmt ' '='Missing' other='Not Missing';
 value  missfmt  . ='Missing' other='Not Missing';
run;
 
 
Title "Number of missing values per variable"; 
Footnote color=red height=10pt "Number of missing values is low for all variables except the new created sub-category 3";
proc freq data=amz; 
format _CHAR_ $missfmt.; 
tables _CHAR_ / missing missprint nocum nopercent;
format _NUMERIC_ missfmt.;
tables _NUMERIC_ / missing missprint nocum nopercent;
run;
Title;
Footnote;




/* 
	Transformations include:
	1. Calculation discount level in percentage for each product
	2. New format for discount and price levels
	3. Drop further variables that wont be used in the analysis
	4. Conditional formating for the variable rating_nr
	5. Label all variables in the data
	Check the file structure with Contents 
	Check the statistical measures to use in the group scales (format,conditional statements)
*/


data amz;
set amz;
disc_perc = ((price - discount)/price)*100;
price_level = price;
format disc_perc 5.2;
run;



proc format;
value discat	low - < 8 = "<8%"
				8 - <30 = ">8% - <30%"
				30 - <50 = ">30% - <50%"
				50 - <60 = ">50% - <60%"
				60 - high = ">60%"
				;
run;



proc format;
value price		low - <2000 = "<2K"
				2000 - <10000 = ">2K - <10K"
				10000 - <20000 = ">10K - <20K"
				20000 - <50000 = ">20K - <50K"
				50000 - <100000 = ">50K - <100K"
				100000 - high = ">100K"
				;
run;



data amz;
set amz;
format disc_perc discat.;
format price_level price.;
drop category img_link product_link product_id;
run;



Title "Basic statistical values from numerical variables";
proc means data=amz maxdec=2 nolabels;
var rating price discount rating_nr disc_perc;
run;
Title;





data amz;
set amz;
length Feedback $20;
format Feedback $20.;
informat Feedback $20.;
if rating_nr < 1173 then Feedback = "< low feedback";
else if rating_nr < 18543 then Feedback = "average feedback";
else if rating_nr < 40895 then Feedback = "high feedback";
else Feedback = "Top feedback";
run;




data amz;
	set amz;
	label 	discount = "Discount in Ruppies"
			disc_perc = "Discount level"
			main_category = "Product main category"
			price = "Product price in Ruppies"
			price_level = "Product price level"
			rating_nr = "Number of ratings"
			sub_ctg1 = "Product Subcategory 1"
			sub_ctg2 = "Product Subcategory 2"
			sub_ctg3 = "Product Subcategory 3"
			Feedback = "Customer feedack scale"
			;
run;


 
data amz;
	length main_category sub_ctg1 sub_ctg2 sub_ctg3 $50;
	format main_category sub_ctg1 sub_ctg2 sub_ctg3 $50. rating_nr BEST.;
	informat main_category sub_ctg1 sub_ctg2 sub_ctg3 $50.;
	set amz;
run;




Title "Once all transformations are done, lets see how the file looks like";
proc contents data=amz;
run;
Title;


ODS noproctitle;
Title "Let´s see the statistical distribution of variables where I created levels";
proc univariate data=amz;
var rating_nr price discount;
run;
Title;


/* 
	Generate a PDF File with Cover page
	http://support.sas.com/kb/46/576.html
*/

options orientation=portrait nodate pageno=1 
leftmargin=.5in rightmargin=.5in topmargin=1in bottommargin=1in;

ods escapechar="^";  
options center;
title;
footnote;


data test;
   text = "Amazon Dataset analysis";
run;


ods pdf file='/home/u60923758/A2023/A2/A2_14344509_F.pdf' notoc startpage=no ; 


footnote1 j=c "Name: Laila Lima Alves";
footnote2 j=c "Student-ID: 14344509";
ods pdf text="^S={just=c} 26777 Data Processing Using SAS - Autumn 2023";
ods pdf TEXT="^S={just=c}Based on the information provided in Kaggle, the file includes scrapped data from Amazon Website in India.
These items are listed online and have been sold before because all of them have reviews, though no information on sales volume is available. 
The Dataset is mainly informative on each item scraped by the author.";
ods pdf text="^30n";


proc report data=test noheader 
     style(report)={rules=none frame=void} 
     style(column)={font_weight=bold font_size=30pt just=c};
run;
footnote;

ods pdf startpage=yes;




/* 
	Start PDF Report
	General Graphs with overall information on variables
	
*/


ods graphics / reset width=6.4in height=3.4in imagemap;

proc sgplot data=WORK.AMZ;
	title height=14pt "Price distribution very skewed";
	footnote2 justify=left height=9pt 
		"One extreme outlier with Price 140K Ruppies";
	hbox price /;
	xaxis grid;
run;

ods graphics / reset;
title;
footnote2;




ods graphics / reset width=5.8in height=4.8in imagemap;

proc sgplot data=WORK.AMZ;
	title height=14pt "Rating Distribution (skewed to the left)";
	footnote2 justify=left height=9pt 
		"Most products have been rated between 3.5 and 4.5";
	histogram rating / scale=proportion;
	density rating;
	yaxis grid;
run;

ods graphics / reset;
title;
footnote2;




ods graphics / reset width=5.8in height=4.8in imagemap;

proc sgplot data=WORK.AMZ;
	title height=14pt "Frequency distribution Discount Levels";
	footnote2 justify=left height=9pt 
		"Discounts above 60% appear more often, followed by 30% to 50%";
	vbar disc_perc /;
	yaxis grid;
run;

ods graphics / reset;
title;
footnote2;




/* 
	Frequency tables with more detailed information on variables 
*/



Title1 height=14pt "Frequency table for the main product categories";
Title2 " ";
Title3 height=10pt "Which categories appear more often?";
Title4 height=10pt "Electronics, Computer and acessories, Home and Kitchen represent 97% of total!";
Footnote "Home Improvement + Musical Instruments + Car&Motorbike + Health & PersonalCare + Toys & Game have 2 or less items listed";
proc freq data=amz order=freq;
table main_category;
run;
title;
footnote;




Title1 height=14pt "Frequency table for the main product categories versus subcategory";
Title2 " ";
Title3 height=10pt "Which sub-categories appear more often?";
Title4 height=10pt "Accessories&Peripherals | Kitchen&HomeAppliances | Mobiles&Accessories | HomeTheater,TV&Video";
Footnote "The 3 main categories are dominated by one or two sub-categories";
proc freq data=amz;
tables sub_ctg1 * main_category / Nocol Norow Nofreq;
where main_category = "Electronics" or main_category = "Home&Kitchen" or main_category = "Computers&Accessories";
run;
title;
footnote;




Title1 height=14pt "Frequency table for the price level";
Title2 " ";
Title3 height=10pt "Which price level is more frequent?";
Title4 height=10pt "Prices below 10K represent the highest proportion in the dataset : 86%";
Footnote "One outlier with the price value above 100K";
proc freq data=amz;
table price_level;
run;
title;
footnote;




Title1 height=14pt "Frequency table for the discount level";
Title2 " ";
Title3 height=10pt "Are discounts common usage?";
Title4 height=10pt "Discounts are extremely frequent! 
76% of the products have discounts > 30%";
Footnote "Are discounts real or marketing strategy to attract customers? Comparables with other website could answer this question";
proc freq data=amz;
table disc_perc;
run;
title;
footnote;




Title1 height=14pt "Summary statistics report for Price, product category and discount level";
Title2 " ";
Title3 height=10pt "Which additional insights are available?";
Title4 height=10pt "The mean & median price of Electronics are much higher than other categories";
Title5 height=10pt "Home&Kitchen have the second highest prices";
Title6 height=10pt "The discount levels are not correlated with product prices";

ods trace on;
ods output summary=summary;
proc means data=amz maxdec=0 mean median min max nonobs;
	var price;
	class main_category disc_perc;
	ways 2;
	output out=avgprice mean=mean_price  median=med_price min=min_price max=max_price;
run;
ods trace off;
ods output close;
title;
footnote;




title "Details about categories with less than two products online";
Footnote "These products could also have been classified in the main categories due to its characteristics";
proc print data=amz;
where main_category = "Car&Motorbike" 
or main_category = "Health&PersonalCare" 
or main_category = "HomeImprovement" 
or main_category = "Toys&Games"
or main_category = "MusicalInstruments";
var main_category sub_ctg1 product_name price discount rating;
run;
title;
footnote;





/* 
	Create Graphs based on the overall dataset

  	Include an additional file excluding the outlier with price 130 000 Ruppies*/




ods graphics / reset width=6.4in height=6.4in imagemap;


proc sgplot data=WORK.AMZ;
	title1 h=2 "Frequency table for the 3 main product categories (Histogramm)";
	title2 h=1 "Graphical visualization from the table previously shown";
	where main_category = "Electronics" or main_category = "Home&Kitchen" or main_category = "Computers&Accessories";
	vbar main_category / group=sub_ctg1 seglabel datalabel groupdisplay=stack;
	xaxis display=(nolabel noline noticks);
 	yaxis display=(noline noticks) grid;
 	keylegend / location=inside position=top fillheight=10 fillaspect=2;
run;

ods graphics / reset;
title;


  	
  	
data amz_oo;
set amz;
where price < 100000;
run;


goptions reset=all border cback=white htitle=14pt htext=10pt;   

axis1 label=("Products main categories");
axis2 label=("Sum of price listed for each item in the category");

    
proc gchart data=WORK.amz_oo;
*where main_category = "Electronics" or main_category = "Home&Kitchen" or main_category = "Computers&Accessories";
hbar main_category / sumvar=price
type= sum
nostats
maxis=axis1
raxis=axis2 space=1.8;
title h=2 'Bar Chart Products categories and Sum of prices';
title2 h=1 'The sum of all prices confirms Electronics is by far the most expensive category';
footnote 'Even when outlier in electronics for 130,000 Ruppies is excluded';
run;
quit;

ods graphics / reset;
title;
footnote;







ods graphics / reset width=6.4in height=6.4in imagemap;

proc sgplot data=WORK.AMZ_OO ;
	title1 h=2 "Strong correlation between Discount and Prices in Ruppies";
	title2 h=1 "Expected as prices are high, the discounts represent higher values";
	footnote1 "  ";
	footnote2 justify=left height=8pt 
		"Outlier excluded. The different bubble colors show the discount levels and follow an expected pattern with higher discount in the bottom";
	bubble x=price y=discount  size=price_level/ group=disc_perc 
		fillattrs=(transparency=0.5) bradiusmin=4 bradiusmax=12;
	xaxis grid;
	yaxis grid;
run;

ods graphics / reset;
title;
footnote;





ods graphics / reset width=6.4in height=6.4in imagemap;

proc sgplot data=WORK.AMZ_OO;
	title1 h=2 "Correlation between Discount and Ratings";
	title2 h=1 "Most Ratings are between 3.5 and 4.5 showing a positive evaluation for most products";
	footnote1 "  ";
	footnote2 justify=left height=8pt "Outlier excluded. More expensive products with more discount have similar ratings than cheaper ones";
	bubble x=discount y=rating size=rating_nr/ group=main_category 
		fillattrs=(transparency=0.5) bradiusmin=6 bradiusmax=16;
	xaxis grid;
	yaxis grid;
run;

ods graphics / reset;
title;
footnote;




ods graphics / reset width=6.8in height=6.8in imagemap;

proc sgplot data=WORK.AMZ_OO;
	title h=2 "Box-plot price distribution per Product sub-category";
	title2 h=1 "Sub-categories with highest dispersion in price: HomeTheater,TV&Video | Kitchen&HomeAppliances | Heating,Cooling&AirQuality | Mobiles&Accessories	"; 
	footnote2 justify=left height=8pt "Outlier excluded. Only 5 Sub-categories have prices above 40K";
	vbox price / category=sub_ctg1;
	xaxis valuesrotate=vertical;
	yaxis grid;
run;

ods graphics / reset;
title;
footnote;





ods graphics / reset width=6.4in height=7.4in imagemap;

proc sgplot data=WORK.AMZ;
	title h=2 "HeatMap for number of Ratings written per Product Sub-Category";
	title2 h=1 "Include only category Electronics, Home&Kitchen & Computers&Acessories";
	title3 h=1 "Kitchen&HomeAppliances has more Ratings below 3 than others";
	footnote1 " ";
	footnote2 justify=left height=8pt 
		"Sub-categories with more frequency have more Feedback (Accessories&Pheripherals + Kitchen&Homeappliances + Mobile&acessories)";
	where main_category = "Electronics" or main_category = "Home&Kitchen" or main_category = "Computers&Accessories";
	heatmap x=sub_ctg1 y=rating / name='HeatMap';
	gradlegend 'HeatMap';
	xaxis valuesrotate=vertical;
run;

ods graphics / reset;
title;
Footnote;




proc template;
	define statgraph SASStudio.Pie;
		begingraph;
		entrytitle "3/4 of the products have more than 18 000 customers writting feedback" / 
			textattrs=(size=14);
		entryfootnote halign=left 
			"Low Feedback < 1173   | 
			Average Feedback < 18543  |  
			High < 40895   |  
			Top > 40895" / 
			textattrs=(size=10);
		layout region;
		piechart category=Feedback / stat=pct;
		endlayout;
		endgraph;
	end;
run;

ods graphics / reset width=6.0in height=6.0in imagemap;

proc sgrender template=SASStudio.Pie data=WORK.AMZ;
run;

ods graphics / reset;





ods noproctitle;
	title1 height=14pt "Mosaic Plot for Discount and Price levels for Top 4 Sub-categories";
	title2 " ";
	title3 height=10pt "Accessories&Peripherals | Kitchen&HomeAppliances | Mobiles&Accessories | HomeTheater,TV&Video";
	title4 height=10pt "Accessories&Peripherals have lower prices and higher discounts";
	title5 height=10pt "Mobiles&Accessories have higher prices and less discounts";
proc freq data=WORK.AMZ;
	ods select MosaicPlot;
	where sub_ctg1 = "Accessories&Peripherals" or sub_ctg1 = "Kitchen&HomeAppliances" or sub_ctg1 = "Mobiles&Accessories" or sub_ctg1 = "HomeTheater,TV&Video";
	tables sub_ctg1*disc_perc*price_level / plots=mosaicplot;
run;
title;




/* 
	Create Reports based on specific aspects present in the dataset
	including Macros
*/


proc sort data=amz;
by main_category;
run;



ODS noproctitle;
title1 height=14pt "Two way frequency table for Mobiles&Accessories"; 
footnote height=10pt "Confirms that prices > 10K have discount < 30%. Discounts > 60% are for prices < 2K"; 
proc freq data=amz; 
by main_category; 
where sub_ctg1 eq "Mobiles&Accessories";
tables price_level * disc_perc / Nocol Norow Nofreq; 
run; 
footnote;




ODS noproctitle;
title1 height=14pt "Two way frequency table for HomeTheater,TV&Video"; 
footnote height=8pt "Most discounts are for prices < 2K. Products with price >10K have discounts <50% "; 
proc freq data=amz; 
by main_category; 
where sub_ctg1 eq "HomeTheater,TV&Video";
tables price_level * disc_perc / Nocol Norow Nofreq; 
run; 
footnote;






%let main_category = Computers&Accessories;


title1 height=14pt "Average price for &main_category";
proc means data=amz maxdec=2;
	var price;
	where main_category = "&main_category.";
run;




title1 height=14pt "Frequency table of price and discounts levels for &main_category ";
footnote height=8pt "Discounts above 50% for goods below 2K are the most common"; 
proc freq data=amz;
	tables price_level * disc_perc / Nocol Norow Nofreq;
	where main_category = "&main_category.";
run;




ods pdf close;