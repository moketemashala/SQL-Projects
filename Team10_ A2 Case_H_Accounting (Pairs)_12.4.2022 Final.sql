/* 
Date: 12/3/2022
Create by: Mokete Mashala and Kodchakorn Pratumkaew 
For assignment A2_Case - H_Accounting (Pairs/Trios)
Business Analysis with Structured Data - DAT-7470 - BMBAND1
*/

USE h_accounting;
/*Create DELIMITER and Procedure process */
DELIMITER $$ 
-- Drop Procedure
DROP PROCEDURE IF EXISTS Getfinancialstatement_Team10;

-- creating the stored procedure
CREATE PROCEDURE Getfinancialstatement_Team10(IN select_year INT)
BEGIN

/* Step1:
		We join all important tables that we need to use for performing Financial statements and store the data into view.
			- journal_entry_line_item >> we use this table to be the key table becuase we need all the amount of transaction.
			- journal_entry 
			- account
*/

DROP VIEW kpratumkaew_view; -- Need to change to your view**
CREATE VIEW kpratumkaew_view AS -- Need to change to your view**
SELECT 
    jel.journal_entry_id,
    jel.account_id,
    acc.account_code,
    acc.account,
    acc.balance_sheet_section_id, -- Use this for connect Balance sheet 
    acc.profit_loss_section_id, -- Use this for connect Profit and loss
    year(je.entry_date) AS year ,
    IFNULL(debit, 0) AS debit,
    IFNULL(credit, 0) AS credit,
    (IFNULL(debit, 0)-IFNULL(credit, 0)) AS Amount -- Use this amount to grouping into BS,P&L because there might be adjusting transactions that have abnomal (credit or debit)
		FROM h_accounting.journal_entry_line_item AS jel
INNER JOIN h_accounting.account AS acc 
	ON acc.account_id = jel.account_id
INNER JOIN h_accounting.journal_entry AS je 
	ON je.journal_entry_id = jel.journal_entry_id;


/* Step2: 
		Calculate amount of each account and set data into the table named "kpratumkaew_tmp" which is seperate into 
        3 sections: 1) Balance sheet 2) Income Statement 3) Statement of Cashflow
		
*/

-- Step2.1 : Calculate Balance sheet 
/* Note*:
		In pactical, each company will create the financial statement code depending on the structure. 
        If using this code for other company, should customize the financial section code properly.**
			However, this company set the statement section as follow; 
			61 : CURRENT ASSETS
			62 : FIXED ASSETS
			63 : DEFERRED ASSETS
			64 : CURRENT LIABILITIES
			65 : LONG-TERM LIABILITIES
			66 : DEFERRED LIABILITIES
			67 : EQUITY
			68 : REVENUE
			69 : RETURNS, REFUNDS, DISCOUNTS
			74 : COST OF GOODS AND SERVICES
			75 : ADMINISTRATIVE EXPENSES
			76 : SELLING EXPENSES
			77 : OTHER EXPENSES
			78 : OTHER INCOME
			79 : INCOME TAX
			80 : OTHER TAX
*/


-- Calculate current assets for current year (selected year)
SET @ca_cy =  
			(SELECT round(SUM(amount),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE balance_sheet_section_id = "61" -- Need to change if the comapny have difference structure
                AND year = select_year); 

-- calculate current assets for prior year (selected year-1)
SET @ca_py = 
			(SELECT round(SUM(amount),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE balance_sheet_section_id = "61" -- Need to change if the comapny have difference structure
                AND year = select_year-1);
                
-- Calculate fix assets for current year (selected year)          
SET @fa_cy =  
			(SELECT round(SUM(amount),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE balance_sheet_section_id = "62" -- Need to change if the comapny have difference structure
                AND year = select_year);

-- calculate Fix assets for prior year (selected year - 1)
SET @fa_py = 
			(SELECT round(SUM(amount),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE balance_sheet_section_id = "62" -- Need to change if the comapny have difference structure
                AND year = select_year-1);

-- Calculate deffered assets for current year (selected year)
SET @da_cy =  
			(SELECT round(SUM(amount),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE balance_sheet_section_id = "63" -- Need to change if the comapny have difference structure
                AND year = select_year);

-- calculate deffered assets for prior year (selected year - 1)
SET @da_py = 
			(SELECT round(SUM(amount),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE balance_sheet_section_id = "63" -- Need to change if the comapny have difference structure
                AND year = select_year-1);

-- Calculate current liabilites for current year (selected year)
SET @cl_cy =  
			(SELECT round(SUM(amount),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE balance_sheet_section_id = "64" -- Need to change if the comapny have difference structure
                AND year = select_year);
     
-- calculate current liabilities for prior year (selected year - 1)
SET @cl_py = 
			(SELECT round(SUM(amount),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE balance_sheet_section_id = "64" -- Need to change if the comapny have difference structure
                AND year = select_year-1);

-- Calculate long-term liabilites for current year (selected year)
SET @ltl_cy =  
			(SELECT round(SUM(amount),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE balance_sheet_section_id = "65" -- Need to change if the comapny have difference structure
                AND year = select_year);
    
-- calculate long-term liabilities for prior year (selected year - 1)
SET @ltl_py = 
			(SELECT round(SUM(amount),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE balance_sheet_section_id = "65" AND year = select_year-1);

-- Calculate deffered liabilites for current year (selected year)
SET @dl_cy =  
			(SELECT round(SUM(amount),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE balance_sheet_section_id = "66" -- Need to change if the comapny have difference structure
                AND year = select_year);
           
-- calculate deffered liabilities for prior year (selected year - 1)
SET @dl_py = 
			(SELECT round(SUM(amount),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE balance_sheet_section_id = "66" -- Need to change if the comapny have difference structure
                AND year = select_year-1);

-- Calculate equity for current year (selected year)
/* Note* : For Equity of this, we should include section 67, 0 into the Total Equity 
			because "0" in balance_sheet_section_id section means profit and loss during the year. 
			As we observe the data in journal_entry_line_item, we found several year close yearly entry properly 
			but some didn't specially in YE2020. Thus, we should include section "0" (profit and loss) in equity  
			otherwise the data in balance sheet will not balance. */
SET @eq_cy =  
			(SELECT round(SUM(amount),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE balance_sheet_section_id IN (67, 0) -- Need to change if the comapny have difference structure
                AND year = select_year);
      
-- calculate equity for prior year (selected year - 1)
SET @eq_py = 
			(SELECT round(SUM(amount),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE balance_sheet_section_id IN (67, 0) -- Need to change if the comapny have difference structure
                AND year = select_year-1);


SET @tas_cy = (IFNULL(@ca_cy,0) + IFNULL(@fa_cy,0) + IFNULL(@da_cy,0)); -- calculated total assets in current year
SET @tas_py =  (IFNULL(@ca_py,0) + IFNULL(@fa_py,0) + IFNULL(@da_py,0)); -- calculated total assets in prior year
SET @tl_cy = (IFNULL(@cl_cy,0) + IFNULL(@ltl_cy,0) + IFNULL(@ltl_cy,0)); -- calculated total liaibilities in current year
SET @tl_py =  (IFNULL(@cl_py,0) + IFNULL(@ltl_py,0) + IFNULL(@ltl_py,0)); -- calculated total liabilities in prior year
SET @tle_cy = (IFNULL(@tl_cy,0) + IFNULL(@eq_cy,0)); -- calculated total liaibilities and equities in current year
SET @tle_py =  (IFNULL(@tl_py,0) + IFNULL(@eq_py,0)); -- calculated total liabilities and equities in prior year
SET @ca_change = ((IFNULL(@ca_cy,0) - IFNULL(@ca_py,0)) / (NULLIF(@ca_py,0))*100); -- calculate change in current asset (YoY)
SET @fa_change = ((IFNULL(@fa_cy,0) - IFNULL(@fa_py,0)) / (NULLIF(@fa_py,0))*100); -- calculate change in fix asset (YoY)
SET @da_change = ((IFNULL(@da_cy,0) - IFNULL(@da_py,0)) / (NULLIF(@da_py,0))*100); -- calculate change in deffered asset (YoY)
SET @cl_change = ((IFNULL(@cl_cy,0) - IFNULL(@cl_py,0)) / (NULLIF(@cl_py,0))*100); -- calculate change in current liabilities (YoY)
SET @ltl_change = ((IFNULL(@ltl_cy,0) - IFNULL(@ltl_py,0)) / (NULLIF(@ltl_py,0))*100); -- calculate change in long-term liaibilities (YoY)
SET @dl_change = ((IFNULL(@dl_cy,0) - IFNULL(@dl_py,0)) / (NULLIF(@dl_py,0))*100); -- calculate change in deffered liaibilities (YoY)
SET @eq_change = ((IFNULL(@eq_cy,0) - IFNULL(@eq_py,0)) / (NULLIF(@eq_py,0))*100); -- calculate change in equity (YoY)
SET @tas_change = ((IFNULL(@tas_cy,0) - IFNULL(@tas_py,0)) / (NULLIF(@tas_py,0))*100); -- calculate change in total assets (YoY)
SET @tl_change = ((IFNULL(@tl_cy,0) - IFNULL(@tl_py,0)) / (NULLIF(@tl_py,0))*100); -- calculate change in total liabilities (YoY)
SET @tle_change = ((IFNULL(@tle_cy,0) - IFNULL(@tle_py,0)) / (NULLIF(@tle_py,0))*100); -- calculate change in total liabilities and equities(YoY)


-- Step2.2 : Calculate profit and loss for input into Income statement
/* Note*: We calculate revenue and expense by using an accounting logical as follow;
			- Revenues, Other incomes in "credit" side 
            - All expenses in "Debit" side
*/

-- Calculate revenues for current year (selected year)
SET @rev_cy =  
			(SELECT round(SUM(credit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "68" -- Need to change if the comapny have difference structure
                AND year = select_year);

-- Calculate revenue for prior year (selected year-1)
SET @rev_py =  
			(SELECT round(SUM(credit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "68" -- Need to change if the comapny have difference structure
                AND year = select_year-1);
                
-- Calculate revenue for prior year (selected year-2)
SET @rev_ppy =  
			(SELECT round(SUM(credit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "68" -- Need to change if the comapny have difference structure
                AND year = select_year-2);

-- Calculate returns, refunds, and discounts for current year (selected year)
SET @ret_cy =  
			(SELECT round(SUM(debit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "69" -- Need to change if the comapny have difference structure
                AND year = select_year);

-- Calculate returns, refunds, and discounts for prior year (selected year-1)
SET @ret_py =  
			(SELECT round(SUM(debit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "69" -- Need to change if the comapny have difference structure
                AND year = select_year-1);

-- Calculate returns, refunds, and discounts for prior year (selected year-2)           
SET @ret_ppy =  
			(SELECT round(SUM(debit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "69" -- Need to change if the comapny have difference structure
                AND year = select_year-2);

-- Calculate cost of goods and services for current year (selected year)
SET @cogs_cy =  
			(SELECT round(SUM(debit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "74" -- Need to change if the comapny have difference structure
                AND year = select_year);

-- Calculate cost of goods and services for prior year (selected year-1)
SET @cogs_py =  
			(SELECT round(SUM(debit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "74" -- Need to change if the comapny have difference structure
                AND year = select_year-1);
                
-- Calculate cost of goods and services for prior year (selected year-1)
SET @cogs_ppy =  
			(SELECT round(SUM(debit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "74" -- Need to change if the comapny have difference structure
                AND year = select_year-2);

-- Calculate general admin expenses for current year (selected year)
SET @gexp_cy =  
			(SELECT round(SUM(debit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "75" -- Need to change if the comapny have difference structure
                AND year = select_year);

-- Calculate general admin expense for prior year (selected year-1)
SET @gexp_py =  
			(SELECT round(SUM(debit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "75" -- Need to change if the comapny have difference structure
                AND year = select_year-1);

-- Calculate general admin expense for prior year (selected year-2)
SET @gexp_ppy =  
			(SELECT round(SUM(debit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "75" -- Need to change if the comapny have difference structure
                AND year = select_year-2);
                
 -- Calculate selling expenses for current year (selected year)               
SET @sexp_cy =  
			(SELECT round(SUM(debit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "76" -- Need to change if the comapny have difference structure
                AND year = select_year);

-- Calculate selling expense for prior year (selected year-1)
SET @sexp_py =  
			(SELECT round(SUM(debit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "76" -- Need to change if the comapny have difference structure
                AND year = select_year-1);

-- Calculate selling expense for prior year (selected year-2)                
SET @sexp_ppy =  
			(SELECT round(SUM(debit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "76" -- Need to change if the comapny have difference structure
                AND year = select_year-2);

-- Calculate other expenses for current year (selected year)
SET @oexp_cy =  
			(SELECT round(SUM(debit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "77" -- Need to change if the comapny have difference structure
                AND year = select_year);

-- Calculate other expense for prior year (selected year-1)
SET @oexp_py =  
			(SELECT round(SUM(debit),2) 
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "77" -- Need to change if the comapny have difference structure
                AND year = select_year-1);
                
-- Calculate other expense for prior year (selected year-2)
SET @oexp_ppy =  
			(SELECT round(SUM(debit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "77" -- Need to change if the comapny have difference structure
                AND year = select_year-2);

-- Calculate other income for current year (selected year)
SET @oi_cy =  
			(SELECT round(SUM(credit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "78" -- Need to change if the comapny have difference structure
                AND year = select_year);

-- Calculate other income for prior year (selected year-1)
SET @oi_py =  
			(SELECT round(SUM(credit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "78" -- Need to change if the comapny have difference structure
                AND year = select_year-1);
                
-- Calculate other income for prior year (selected year-2)
SET @oi_ppy =  
			(SELECT round(SUM(credit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "78" -- Need to change if the comapny have difference structure
                AND year = select_year-2);

-- Calculate income tax for current year (selected year)
SET @inctax_cy =  
			(SELECT round(SUM(debit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "79" -- Need to change if the comapny have difference structure
                AND year = select_year);

-- Calculate income tax for prior year (selected year-1)
SET @inctax_py =  
			(SELECT round(SUM(debit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "79" -- Need to change if the comapny have difference structure
                AND year = select_year-1);
			
-- Calculate income tax for prior year (selected year-2)
SET @inctax_ppy =  
			(SELECT round(SUM(debit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "79" -- Need to change if the comapny have difference structure
                AND year = select_year-2);
                
-- Calculate other tax for current year (selected year)
SET @othtax_cy =  
			(SELECT round(SUM(debit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "80" -- Need to change if the comapny have difference structure
                AND year = select_year);
                
-- Calculate other tax for prior year (selected year-1)
SET @othtax_py =  
			(SELECT round(SUM(debit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "80" -- Need to change if the comapny have difference structure
                AND year = select_year-1);
                
-- Calculate other tax for prior year (selected year-2)
SET @othtax_ppy =  
			(SELECT round(SUM(debit),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE profit_loss_section_id = "80" -- Need to change if the comapny have difference structure
                AND year = select_year-2);

SET @rev_change = ((IFNULL(@rev_cy,0) - IFNULL(@rev_py,0)) / (NULLIF(@rev_py,0))*100); -- Calculate change in revenue (yoy)
SET @ret_change = ((IFNULL(@ret_cy,0) - IFNULL(@ret_py,0)) / (NULLIF(@ret_py,0))*100);-- Calculate change in returns, refunds, and discounts (yoy)
SET @cogs_change = ((IFNULL(@cogs_cy,0) - IFNULL(@cogs_py,0)) / (NULLIF(@cogs_py,0))*100); -- Calculate change in cost of goods and services (yoy)
SET @gexp_change = ((IFNULL(@gexp_cy,0) - IFNULL(@gexp_py,0)) / (NULLIF(@gexp_py,0))*100); -- Calculate change in general administrative expenses (yoy)
SET @sexp_change = ((IFNULL(@sexp_cy,0) - IFNULL(@sexp_py,0)) / (NULLIF(@sexp_py,0))*100); -- Calculate change in selling expense (yoy)
SET @oexp_change = ((IFNULL(@oexp_cy,0) - IFNULL(@oexp_py,0)) / (NULLIF(@oexp_py,0))*100); -- Calculate change in other expense (yoy)
SET @oi_change = ((IFNULL(@oi_cy,0) - IFNULL(@oi_py,0)) / (NULLIF(@oi_py,0))*100); -- Calculate change in other incomes (yoy)
SET @inctax_change = ((IFNULL(@inctax_cy,0) - IFNULL(@inctax_py,0)) / (NULLIF(@inctax_py,0))*100); -- Calculate change in income tax (yoy)
SET @othtax_change = ((IFNULL(@othtax_cy,0) - IFNULL(@othtax_py,0)) / (NULLIF(@othtax_py,0))*100); -- Calculate change in other income tax (yoy)

/* Note*: Calculate profit and loss from this formular
			Revenues 
			+ Other incomes 
			- returns,refunes,discount 
			- cost of goods and services 
			- general admintistrative expenses 
			- selling expenses
			- others expenses 
			- income tax 
			- other income tax
            = Profit / (loss)
*/

-- Calculate profit and loss for current year 
SET @pl_cy = (IFNULL(@rev_cy,0) + IFNULL(@oi_cy,0) - IFNULL(@ret_cy,0) - IFNULL(@cogs_cy,0) - IFNULL(@gexp_cy,0) - IFNULL(@sexp_cy,0) - IFNULL(@oexp_cy,0) - IFNULL(@inctax_cy,0) - IFNULL(@othtax_cy,0));
-- Calculate profit and loss for prior year 
SET @pl_py = (IFNULL(@rev_py,0) + IFNULL(@oi_py,0) - IFNULL(@ret_py,0) - IFNULL(@cogs_py,0) - IFNULL(@gexp_py,0) - IFNULL(@sexp_py,0) - IFNULL(@oexp_py,0) - IFNULL(@inctax_py,0) - IFNULL(@othtax_py,0));
-- Calculate change in profit and loss
SET @pl_change = ((IFNULL(@pl_cy,0) - IFNULL(@pl_py,0)) / (NULLIF(@pl_py,0))*100);


-- Step2.3 : Calculate Statement of Cashflow

-- Calculate Change in current assets (Year-2) and Change in current assets
SET @ca_ppy = 
		(SELECT round(SUM(amount),2)
			FROM kpratumkaew_view -- Need to change to your view**
			WHERE balance_sheet_section_id = '61' -- Need to change if the comapny have difference structure
			AND year = select_year-2); 

SET @change_in_ca_cp = IFNULL(@ca_cy,0) - IFNULL(@ca_py,0); -- Calculate change in current asset (y to y-1)
SET @change_in_ca_pp = IFNULL(@ca_py,0) - IFNULL(@ca_ppy,0); -- Calculate change in current asset (y-1 to y-2)
SET @percent_change_in_ca = 
		((IFNULL(@change_in_ca_cp,0) - IFNULL(@change_in_ca_pp ,0)) 
			/ (NULLIF(@change_in_ca_pp ,0)*100)); -- Calculate percent change (y to y-1) vs (y-1 to y-2)


-- Calculate fix assets (Year-2) and Change in fix assets
SET @fa_ppy = 
			(SELECT round(SUM(amount),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE balance_sheet_section_id = "62" -- Need to change if the comapny have difference structure
                AND year = select_year-2);

SET @change_in_fa_cp = (IFNull(@fa_cy,0) - IFNULL(@fa_py,0)); -- Calculate change in current asset (y to y-1)
SET @change_in_fa_pp = (IFNull(@fa_py,0) - IFNULL(@fa_ppy,0)); -- Calculate change in current asset (y-1 to y-2)
SET @percent_change_in_fa = 
		((IFNULL(@change_in_fa_cp,0) - IFNULL(@change_in_fa_pp,0)) 
			/ (NULLIF(@change_in_fa_pp,0)*100)); -- Calculate percent change (y to y-1) vs (y-1 to y-2)



-- Calculate deffered assets (Year-2) and Change in deffered assets
SET @da_ppy = 
			(SELECT round(SUM(amount),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE balance_sheet_section_id = "63" -- Need to change if the comapny have difference structure
                AND year = select_year-2);

SET @change_in_da_cp = (IFNull(@da_cy,0) - IFNULL(@da_py,0));-- Calculate change in deffered asset (y to y-1)
SET @change_in_da_pp = (IFNull(@da_py,0) - IFNULL(@da_ppy,0)); -- Calculate change in deffered asset (y-1 to y-2)
SET @percent_change_in_da = 
		((IFNULL(@change_in_da_cp,0) - IFNULL(@change_in_da_pp,0)) 
			/ (NULLIF(@change_in_da_pp,0)*100)); -- Calculate percent change (y to y-1) vs (y-1 to y-2)


-- Calculate current liabilites (Year-2) and Change in current liaibilities 
SET @cl_ppy = 
			(SELECT round(SUM(amount),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE balance_sheet_section_id = "64" -- Need to change if the comapny have difference structure
                AND year = select_year-2);

SET @change_in_cl_cp = (IFNull(@cl_cy,0) - IFNULL(@cl_py,0)); -- Calculate change in differed asset (y to y-1)
SET @change_in_cl_pp = (IFNull(@cl_py,0) - IFNULL(@cl_ppy,0)); -- Calculate change in deffered asset (y-1 to y-2)
SET @percent_change_in_cl = 
		((IFNULL(@change_in_cl_cp,0) - IFNULL(@change_in_cl_pp,0)) 
			/ (NULLIF(@change_in_cl_pp,0)*100)); -- Calculate percent change (y to y-1) vs (y-1 to y-2)


-- Calculate long-term liabilites (Year-2) and change in long term liabilities
SET @ltl_ppy =  
			(SELECT round(SUM(amount),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE balance_sheet_section_id = "65" -- Need to change if the comapny have difference structure
                AND year = select_year-2);
                
SET @change_in_ltl_cp = (IFNull(@ltl_cy,0) - IFNULL(@ltl_py,0));-- Calculate change in differed asset (y to y-1)
SET @change_in_ltl_pp = (IFNull(@ltl_py,0) - IFNULL(@ltl_ppy,0)); -- Calculate change in deffered asset (y-1 to y-2)
SET @percent_change_in_ltl = 
		((IFNULL(@change_in_ltl_cp,0) - IFNULL(@change_in_ltl_pp,0)) 
			/ (NULLIF(@change_in_ltl_pp,0)*100)); -- Calculate percent change (y to y-1) vs (y-1 to y-2)


-- calculate deffered liabilites (Year-2) and change in deffered liabilites
SET @dl_ppy = 
			(SELECT round(SUM(amount),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE balance_sheet_section_id = "66" -- Need to change if the comapny have difference structure
                AND year = select_year-2);
                
SET @change_in_dl_cp = (IFNull(@dl_cy,0) - IFNULL(@dl_py,0)); -- Calculate change in deffered liabilities (y to y-1)
SET @change_in_dl_pp = (IFNull(@dl_py,0) - IFNULL(@dl_ppy,0)); -- Calculate change in deffered liabilities (y-1 to y-2)
SET @percent_change_in_dl = 
		((IFNULL(@change_in_dl_cp,0) - IFNULL(@change_in_dl_pp,0)) 
			/ (NULLIF(@change_in_dl_pp,0)*100)); -- Calculate percent change (y to y-1) vs (y-1 to y-2)

-- calculate deffered liabilites (Year-2) and change in deffered liabilites
SET @eqcf_cy =  -- Current year
			(SELECT round(SUM(amount),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE balance_sheet_section_id = "67" -- Need to change if the comapny have difference structure
                AND year = select_year);
                
SET @eqcf_py =  -- Year-1
			(SELECT round(SUM(amount),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE balance_sheet_section_id = "67" -- Need to change if the comapny have difference structure
                AND year = select_year-1);

SET @eqcf_ppy =  -- Year-2
			(SELECT round(SUM(amount),2)
				FROM kpratumkaew_view -- Need to change to your view**
				WHERE balance_sheet_section_id = "67" -- Need to change if the comapny have difference structure
                AND year = select_year-2);
                
SET @change_in_eqcf_cp = (IFNull(@eqcf_cy,0) - IFNULL(@eqcf_py,0)); -- Calculate change in equity (y to y-1)
SET @change_in_eqcf_pp = (IFNull(@eqcf_py,0) - IFNULL(@eqcf_ppy,0)); -- Calculate change in equity (y-1 to y-2)
SET @percent_change_in_eqcf = 
		((IFNULL(@change_in_eqcf_cp,0) - IFNULL(@change_in_eqcf_pp,0)) 
				/ (NULLIF(@change_in_eqcf_pp,0)*100));  -- Calculate percent change (y to y-1) vs (y-1 to y-2)              
                
                

-- Step2.4 : Calculate for financial ratio
-- Liquidity ratios
Set @current_ratio_cy = (IFNULL(@ca_cy,0) / IFNULL(@cl_cy*(-1),0));-- calculate current ratio for current year
Set @current_ratio_cy = (IFNULL(@ca_cy,0) / IFNULL(@cl_cy*(-1),0));-- calculate current ratio for current year
Set @current_ratio_py = (IFNULL(@ca_py,0) / IFNULL(@cl_py*(-1),0)); -- calculate current ratio for prior year
Set @ocf_ratio_cy =  ((IFNULL(@change_in_ca_cp,0*(-1)) + IFNULL(@change_in_cl_cp,0*(-1)) + IFNULL(@pl_cy,0)) / IFNULL(@cl_cy*(-1),0)); -- calculate operating cashflow ratio for current year
Set @ocf_ratio_py =  ((IFNULL(@change_in_ca_pp,0*(-1)) + IFNULL(@change_in_cl_pp,0*(-1)) + IFNULL(@pl_py,0)) / IFNULL(@cl_py*(-1),0)); -- calculate operating ratio for prior year

-- Leverage Financial Ratios
Set @debt_ratio_cy =(IFNULL(@tl_cy*(-1),0) / IFNULL(@tas_cy,0)); -- calculate debt ratio for current year
Set @debt_ratio_py = (IFNULL(@tl_py*(-1),0) / IFNULL(@tas_py,0)); -- calculate debt ratio for prior year
Set @debt_to_equity_ratio_cy = (IFNULL(@tl_cy*(-1),0) / IFNULL(@eq_cy*(-1),0)); -- calculate debt to equity ratio for current year
Set @debt_to_equity_ratio_py = (IFNULL(@tl_py*(-1),0) / IFNULL(@eq_py*(-1),0)); -- calculate debt to equity ratio for prior year

-- Efficiency Ratios
Set @asset_turnover_cy = (IFNULL(@rev_cy,0) / IFNULL(@tas_cy,0)); -- calculate asset turnover for current year
Set @asset_turnover_py = (IFNULL(@rev_py,0) / IFNULL(@tas_py,0));-- calculate asset turnover for prior year

-- Profitability Ratios
Set @return_to_equity_cy = (IFNULL(@pl_cy,0) / IFNULL(@eq_cy*(-1),0)); -- calculate return to equity for current year
Set @return_to_equity_py  = (IFNULL(@pl_py,0) / IFNULL(@eq_py*(-1),0)); -- calculate return to equity for prior year
Set @return_to_asset_cy = (IFNULL(@pl_cy,0) / IFNULL(@tas_cy,0)); -- calculate return on asset for current year
Set @return_to_asset_py  = (IFNULL(@pl_py,0) / IFNULL(@tas_py,0)); -- calculate return on asset for prior year
SET @gross_margin_ratio_cy = ((IFNULL(@rev_cy,0) - IFNULL(@ret_cy,0) - IFNULL(@cogs_cy,0)) / IFNULL(@rev_cy,0));-- calculate gross margin ratio for current year
SET @gross_margin_ratio_py = ((IFNULL(@rev_py,0) - IFNULL(@ret_py,0) - IFNULL(@cogs_py,0)) / IFNULL(@rev_py,0));-- calculate gross margin ratio for current year

/* Step3: Create table that have all the format for Balance sheet, Income statement and statement of cashflow
*/
DROP TABLE IF exists kpratumkaew_tmp; -- Need to change to your temp**

CREATE TABLE kpratumkaew_tmp ( -- Need to change to your temp**
statement_section VARCHAR(100),
current_year VARCHAR(15),
prior_year VARCHAR(15),
percent_change VARCHAR(15)
);


/*Step4:  Insert all data into the table
*/ 

INSERT INTO kpratumkaew_tmp  -- Need to change to your temp**
VALUE

-- Step4.1: Add value to Balance sheet
("", "__", "__", " "),
(" ", select_year , select_year-1 , " " ),
("", "__", "__", " "),
("Balance sheet"," ", " ", " "),
("--", " ", " ", " "),

-- Input current assets both current year and prior year to the table.
("Current Assets", 
	FORMAT(IFNULL(@ca_cy,0),2),
	FORMAT(IFNULL(@ca_py,0),2),
	FORMAT(@ca_change,2)
	),

-- Input fix assets both current year and prior year to the table.
("Fixed Assets", 
	FORMAT(IFNULL(@fa_cy,0),2),
	FORMAT(IFNULL(@fa_py,0),2),
	FORMAT(@fa_change,2)
),

-- Input deffers assets both current year and prior year to the table.
("Deferred Assets", 
	FORMAT(IFNULL(@da_cy,0),2),
	FORMAT(IFNULL(@da_py,0),2),
	FORMAT(@da_change,2)
),

-- Input total assets both current year and prior year to the table.
("Total Assets", 
	FORMAT(IFNULL(@tas_cy,0),2),
	FORMAT(IFNULL(@tas_py,0),2),
	FORMAT(@tas_change,2)
),

-- Input current liabilities both current year and prior year to the table.
/* Note*: Multiple (-1) inti the formular because we want to show all liabilities and equity with the comparable amount 
			with total assets
*/
("Current Liabilities", 
	FORMAT(IFNULL((@cl_cy*(-1)),0),2),
	FORMAT(IFNULL((@cl_py*(-1)),0),2),
	FORMAT(@cl_change*(-1),2)
),

-- Input long-term liabilities both current year and prior year to the table.
("Long-term Liabilites", 
	FORMAT(IFNULL((@ltl_cy*(-1)),0),2),
	FORMAT(IFNULL((@ltl_py*(-1)),0),2),
	FORMAT(@ltl_change*(-1),2)
),

-- Input deferred liabilities both current year and prior year to the table.
("Deferred Liabiities", 
	FORMAT(IFNULL((@dl_cy*(-1)),0),2),
	FORMAT(IFNULL((@dl_py*(-1)),0),2),
	FORMAT(@dl_change*(-1),2)
), 

-- Input total liabilities both current year and prior year to the table
("Total Liabilites", 
	FORMAT(IFNULL((@tl_cy*(-1)),0),2),
	FORMAT(IFNULL((@tl_py*(-1)),0),2),
	FORMAT(@tl_change*(-1),2)
), 

-- Input Equity both current year and prior year to the table
("Total Equity", 
	FORMAT(IFNULL((@eq_cy*(-1)),0),2),
	FORMAT(IFNULL((@eq_py*(-1)),0),2),
	FORMAT(@eq_change,2)
), 

-- Input total liaibilities and Equity both current year and prior year to the table
("Total Liabilities and Equity", 
	FORMAT(IFNULL((@tle_cy*(-1)),0),2),
	FORMAT(IFNULL((@tle_py*(-1)),0),2),
	FORMAT(@tle_change,2)
), 

(" ", " ", " ", " "),
(" ", " ", " ", " "),

-- Step4.3: Calculate statement of cashflow 
("", "__", "__", " "),
(" ", select_year , select_year-1 , " " ),
("", "__", "__", " "),
("Income Statement", " ", " ", " "),
("-", " ", " ", " "),

-- Input revenue both current year and prior year to the table.
("Revenues", 
	FORMAT(IFNULL(@rev_cy,0),2),
	FORMAT(IFNULL(@rev_py,0),2),
	FORMAT(@rev_change,2)
),

-- Input revenue both current year and prior year to the table.
("Returns, Refunds, Discounts", 
	FORMAT(IFNULL(@ret_cy*(-1),0),2),
	FORMAT(IFNULL(@ret_py*(-1),0),2),
	FORMAT(@ret_change,2)
),

-- Input revenue both current year and prior year to the table.
("Cost of goods and services", 
	FORMAT(IFNULL(@cogs_cy*(-1),0),2),
	FORMAT(IFNULL(@cogs_py*(-1),0),2),
	FORMAT(@cogs_change,2)
),

-- Input revenue both current year and prior year to the table.
("General Administative Expenses", 
	FORMAT(IFNULL(@gexp_cy*(-1),0),2),
	FORMAT(IFNULL(@gexp_py*(-1),0),2),
	FORMAT(@gexp_change,2)
),

-- Input revenue both current year and prior year to the table.
("Selling Expenses", 
	FORMAT(IFNULL(@sexp_cy*(-1),0),2),
	FORMAT(IFNULL(@sexp_py*(-1),0),2),
	FORMAT(@sexp_change,2)
),

-- Input revenue both current year and prior year to the table.
("Other Expenses", 
	FORMAT(IFNULL(@oexp_cy*(-1),0),2),
	FORMAT(IFNULL(@oexp_py*(-1),0),2),
	FORMAT(@oexp_change,2)
),

-- Input revenue both current year and prior year to the table.
("Other Income", 
	FORMAT(IFNULL(@oi_cy,0),2),
	FORMAT(IFNULL(@oi_py,0),2),
	FORMAT(@oi_change,2)
),

-- Input revenue both current year and prior year to the table.
("Income Tax", 
	FORMAT(IFNULL(@inctax_cy*(-1),0),2),
	FORMAT(IFNULL(@inctax_py*(-1),0),2),
	FORMAT(@inctax_change,2)
),

-- Input revenue both current year and prior year to the table.
("Other Tax", 
	FORMAT(IFNULL(@othtax_cy*(-1),0),2),
	FORMAT(IFNULL(@othtax_py*(-1),0),2),
	FORMAT(@othtax_change,2)
),

-- Input revenue both current year and prior year to the table.
("Net Income / (Loss)", 
	FORMAT(IFNULL(@pl_cy,0),2),
	FORMAT(IFNULL(@pl_py,0),2),
	FORMAT(@pl_change,2)
),

(" ", " ", " ", " "),
(" ", " ", " ", " "),


-- Step4.3: Add value to Statement of cashflow 
("", "__", "__", " "),
(" ", select_year , select_year-1 , " " ),
("", "__", "__", " "),
("Statement of Cashflow", " ", " ", " "),
("-", " ", " ", " "),
("Net Income", 
	FORMAT(IFNULL(@pl_cy,0),2),
	FORMAT(IFNULL(@pl_py,0),2),
	FORMAT(IFNULL(@pl_change,0),2)
),

("Change In Current Assets",
	FORMAT(IFNULL(@change_in_ca_cp,0)*(-1),2), 
	FORMAT(IFNULL(@change_in_ca_pp,0)*(-1),2), 
	FORMAT(@percent_change_in_ca*(-1),2)
),

("Change In Current Liabilities",
	FORMAT(IFNULL(@change_in_cl_cp,0)*(-1),2), 
	FORMAT(IFNULL(@change_in_cl_pp,0)*(-1),2), 
	FORMAT(@percent_change_in_cl*(-1),2)
),

/* Total cash from operating activities calculate from net income + change in current assets + Change in current liabilties 
*/
("Total Cash from Operating Activities",
	FORMAT(((IFNULL(@change_in_ca_cp,0)*(-1)) + IFNULL(@change_in_cl_cp*(-1),0) + IFNULL(@pl_cy,0)),2),
	FORMAT(((IFNULL(@change_in_ca_pp,0)*(-1)) + IFNULL(@change_in_cl_pp*(-1),0) + IFNULL(@pl_py,0)),2),
	FORMAT(((((IFNULL(@change_in_ca_cp,0)*(-1)) + IFNULL(@change_in_cl_cp*(-1),0) + IFNULL(@pl_cy,0)) 
            + ((IFNULL(@change_in_ca_pp,0)*(-1)) + IFNULL(@change_in_cl_pp*(-1),0) + IFNULL(@pl_py,0)))
              / ((IFNULL(@change_in_ca_pp,0)*(-1)) + IFNULL(@change_in_cl_pp*(-1),0) + IFNULL(@pl_py,0)))*100,2)
),

(" ", " ", " ", " "),
("Investment Activities","","",""),

("Change In Fix Assets", 
	FORMAT(IFNULL(@change_in_fa_cp,0),2), 
	FORMAT(IFNULL(@change_in_fa_pp,0),2), 
	FORMAT(@percent_change_in_fa,0)
),

("Change In Deffered Assets",
	FORMAT(IFNULL(@change_in_da_cp,0),2), 
	FORMAT(IFNULL(@change_in_da_pp,0),2), 
	FORMAT(@percent_change_in_da,2)
),

/* Calcualte cash from investment activities from total non-current assets
*/
("Total Cash from Invesment Activities",
	FORMAT(IFNULL(@change_in_fa_cp,0) + IFNULL(@change_in_da_cp,0),2),
	FORMAT(IFNULL(@change_in_fa_pp,0) + IFNULL(@change_in_da_pp,0),2),
	FORMAT(NULLIF(@percent_change_in_fa,0) + NULLIF(@percent_change_in_da,0),2)
),

(" ", " ", " ", " "),
("Financing Activities"," "," "," "),

("Change In long-term liabilities",
	FORMAT(IFNULL(@change_in_ltl_cp,0),2), 
	FORMAT(IFNULL(@change_in_ltl_pp,0),2), 
	FORMAT(@percent_change_in_ltl,2)
),

("Change In Deffered liabilities",
	FORMAT(IFNULL(@change_in_dl_cp,0),2), 
	FORMAT(IFNULL(@change_in_dl_pp,0),2), 
	FORMAT(@percent_change_in_dl,2)
),

("Change In Equity",
	FORMAT(IFNULL(@change_in_eqcf_cp,0),2), 
	FORMAT(IFNULL(@change_in_eqcf_pp,0),2), 
	FORMAT(@percent_change_in_eqcf,2)
),

/* Calculate financing activities from Change in long-term liabilties + change in equity 
*/
("Total Cash from Financing Activities",
	FORMAT(IFNULL(@change_in_ltl_cp,0) + IFNULL(@change_in_dl_cp,0) + IFNULL(@change_in_eqcf_cp,0),2),
	FORMAT(IFNULL(@change_in_ltl_pp,0) + IFNULL(@change_in_dl_pp,0) + IFNULL(@change_in_eqcf_pp,0),2),
	FORMAT(NULLIF(@percent_change_in_ltl,0) + NULLIF(@percent_change_in_dl,0) + NULLIF(@percent_change_in_eqcf,0),2)
),
  


-- Step4.4: Financial Ratio
("", " ", " ", " "),
(" ", " ", " ", " "),
("", "__", "__", " "),
(" ", select_year , select_year-1 , " " ),
("", "__", "__", " "),
("Financial Ratio", " ", " ", " "),
("-", " ", " ", " "),
("Liquidity ratios > ", " ", " ", " "),
-- Liquidity ratios
("Current ratio", 
	FORMAT(@current_ratio_cy,2),
	FORMAT(@current_ratio_py,2),
	FORMAT((@current_ratio_cy - @current_ratio_cy),2)
 ),
 
("operating cashflow ratio", 
	FORMAT(@ocf_ratio_cy,2),
	FORMAT(@ocf_ratio_py,2),
	FORMAT((@ocf_ratio_cy - @ocf_ratio_py),2)
 ),
(" ", " ", " ", " "),
("Leverage Financial Ratios >", " ", " ", " "),
("debt ratio", 
	FORMAT(@debt_ratio_cy,2),
	FORMAT(@debt_ratio_py,2),
	FORMAT((@debt_ratio_cy - @debt_ratio_cy),2)
 ),
 
("debt to equity ratio", 
	FORMAT(@debt_to_equity_ratio_cy,2),
	FORMAT(@debt_to_equity_ratio_py,2),
	FORMAT((@debt_to_equity_ratio_cy- @debt_to_equity_ratio_py),2)
 ),
 
(" ", " ", " ", " "),
("Efficiency Ratios >", " ", " ", " "),
("asset turnover", 
	FORMAT(@asset_turnover_cy,2),
	FORMAT(@asset_turnover_py,2),
	FORMAT((@asset_turnover_cy - @asset_turnover_py),2)
 ),
 (" ", " ", " ", " "),
 ("Profitability Ratios >", "", " ", " "),
 ("return to equity", 
	FORMAT(@return_to_equity_cy,2),
	FORMAT(@return_to_equity_py,2),
	FORMAT((@return_to_equity_cy - @return_to_equity_py),2)
 ),
  ("return on asset", 
	FORMAT(@return_to_asset_cy,2),
	FORMAT(@return_to_asset_py,2),
	FORMAT((@return_to_asset_cy - @return_to_asset_py),2)
 ),
 
  ("gross margin ratio", 
	FORMAT(@gross_margin_ratio_cy,2),
	FORMAT(@gross_margin_ratio_py,2),
	FORMAT((@gross_margin_ratio_cy - @gross_margin_ratio_py),2)
 )


;        

SELECT * FROM kpratumkaew_tmp; -- Need to change to your temp**

END$$

DELIMITER ;


-- running the stored procedure
CALL Getfinancialstatement_Team10(2016);
