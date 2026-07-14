# Superstore Sales Analysis — SQL (MySQL)

**MySQL 8.0** · 9,694 order lines · 5,009 orders · 793 customers · 2014–2017

An SQL analytics project on four years of US retail data. Cleaned the raw data in SQL, explored it,
answered seven business questions, and turned the results into recommendations a business could act
on tomorrow.

---
## Project Overview

Developed an  SQL analytics project to analyze Superstore sales data to identify key business insights related to sales, profit, categories, regions, discounts, and time-based trends.


**Find out where this business actually makes money — and where it quietly loses it.**

The company is growing: sales are up 51% in four years. But growth is not the same as health. The
goal of this project was to look past the sales leaderboard and ask a harder question: *is the
revenue we are adding worth having?*


| KPI | Value |
|---|---|
| Total sales | **$2,296,919** |
| Total profit | **$286,409** |
| Profit margin | **12.47%** |
| Orders / customers | 5,009 / 793 |
| Average order value | $458.56 |
| Average discount | 15.62% |
| **Order lines sold at a loss** | **18.71%** |

---

## The seven business questions

| # | Question | Answer |
|---|---|---|
| **1** | Which **categories** generate the highest sales and profit? | Technology leads both ($836K / $145K). But **Furniture is 32% of sales and only 6% of profit** — a 2.49% margin. |
| **2** | Which **sub-categories** are most and least profitable? | Best: Copiers (+$55.6K), Phones (+$44.5K). Worst: **Tables (−$17.7K), Bookcases (−$3.5K), Supplies (−$1.2K)** — all loss-making. |
| **3** | Which **regions** perform best? | West (14.94% margin). **Central sells $110K more than South and earns $7K less**, on a 24% average discount. |
| **4** | How do **discounts** affect profit? | Margin runs 29.5% → 11.9% → **negative** as discount goes 0% → 20% → 30%+. Correlation with margin: **r = −0.86**. |
| **5** | How did sales and profit change **over time**? | Sales **+51.5%** (2014→2017), sharp Q4 peak every year — but **margin flat at 12–13%** since 2015. |
| **6** | Who are the most **profitable customers**? | Tamara Chand (+$8,981). But **the biggest *spender* — Sean Miller, $25,043 — LOSES $1,981.** Spend ≠ value. |
| **7** | How can customers be **segmented by value**? | RFM. The **81 "At Risk" customers are worth more per head ($4,348) than the Champions ($4,052)** — and have gone quiet. |

---

## Q1–Q3 — Where the money is made and lost

### Categories

| Category | Sales | % of sales | Profit | % of profit | Margin |
|---|---:|---:|---:|---:|---:|
| Technology | $836,154 | 36.4% | $145,455 | 50.8% | 17.40% |
| Office Supplies | $719,047 | 31.3% | $122,491 | 42.8% | 17.04% |
| **Furniture** | **$741,718** | **32.3%** | **$18,463** | **6.4%** | **2.49%** |

Furniture sells almost as much as Technology and returns **a twelfth** of the profit.
Rank-by-sales is not rank-by-profit — which is exactly why you never stop at a sales leaderboard.

### Sub-categories

| Most profitable | Profit | | Least profitable | Profit | Avg discount |
|---|---:|---|---|---:|---:|
| Copiers | +$55,618 | | **Tables** | **−$17,725** | **26.1%** |
| Phones | +$44,516 | | **Bookcases** | **−$3,473** | **21.1%** |
| Accessories | +$41,937 | | **Supplies** | **−$1,189** | 7.7% |
| Paper | +$34,054 | | Machines | +$3,385 *(1.8% margin)* | 30.6% |
| Binders | +$30,222 | | Fasteners | +$950 | 8.2% |

The losers carry the heaviest discounts. Same root cause, showing up again.

### Regions

| Region | Sales | Profit | Margin | Avg discount |
|---|---:|---:|---:|---:|
| **West** | $725,458 | $108,418 | **14.94%** | **10.9%** |
| East | $678,500 | $91,535 | 13.49% | 14.5% |
| South | $391,722 | $46,749 | 11.93% | 14.7% |
| **Central** | **$501,240** | **$39,706** | **7.92%** | **24.0%** |

**Central sells $110K more than South and earns $7K less.** Its average discount is 24% — more than
double the West's. Not a demand problem. A pricing-discipline problem.

The four worst states burn **$70,857** between them: Texas (−$25,729 at 37% avg discount), Ohio
(−$16,959 / 32.5%), Pennsylvania (−$15,560 / 32.9%), Illinois (−$12,608 / 39.0%).

---

## Q4 — Discounts vs profit  **the headline**

| Discount band | Lines | Profit | Margin | Lines losing money | Avg units/line |
|---|---:|---:|---:|---:|---:|
| **0% (none)** | 4,798 | **+$320,988** | 29.51% | 0.0% | 3.81 |
| **1–20%** | 3,803 | **+$100,785** | 11.91% | 13.8% | 3.74 |
| **21–40%** | 459 | **−$35,805** | −15.31% | 90.2% | 3.79 |
| **41–60%** | 215 | **−$28,944** | −40.74% | 100% | 3.66 |
| **60%+** | 718 | **−$70,614** | −122.63% | 100% | 3.97 |

- Correlation between discount and **margin**: **r = −0.86**. About as strong as a real-world business relationship gets.
- Break-even sits **between 20% and 30%**. Above 50%, **not one order line in four years turned a profit.**

### And the discounts don't buy volume

Look at the last column. Average units per line is **flat** — 3.81 at no discount, 3.97 at 60%+.

**This is the most important number in the analysis.** It demolishes the obvious objection —
*"but discounts drive volume!"* — before anyone can raise it. The volume isn't being bought. The
margin is just being given away.

---

## Q5 — Time trends

| Year | Sales | YoY | Profit | Margin |
|---|---:|---:|---:|---:|
| 2014 | $483,966 | — | $49,556 | 10.24% |
| 2015 | $470,533 | −2.78% | $61,619 | 13.10% |
| 2016 | $609,206 | **+29.47%** | $81,795 | 13.43% |
| 2017 | $733,215 | **+20.36%** | $93,439 | 12.74% |

Sales up **51.5%** in four years. But margin **peaked in 2016 and has gone sideways**.
The business is growing by selling *more*, not by selling *better*.

**Seasonality is severe and completely predictable.** November ($352K) and December ($325K) are the
biggest months every single year, September ($308K) third. February is the trough at $60K — a sixth
of November. Q4 peaks; Q1 then collapses ~50%.

---

## Q6 — The most profitable customers

| Customer | Segment | Orders | Sales | Profit | Margin |
|---|---|---:|---:|---:|---:|
| Tamara Chand | Corporate | 5 | $19,052 | **+$8,981** | 47.1% |
| Raymond Buch | Consumer | 6 | $15,117 | **+$6,976** | 46.2% |
| Sanjit Chand | Consumer | 9 | $14,142 | **+$5,757** | 40.7% |
| Hunter Lopez | Consumer | 6 | $12,873 | **+$5,622** | 43.7% |
| Adrian Barton | Consumer | 10 | $14,474 | **+$5,445** | 37.6% |

### ⚠️ The finding hiding inside this question

**The biggest spender in the entire dataset is not profitable.**

| | Sales | Profit |
|---|---:|---:|
| **Sean Miller** — biggest spender | **$25,043** | **−$1,981** |
| Tamara Chand — most profitable | $19,052 | +$8,981 |

Sean Miller spends **31% more** than Tamara Chand and **loses the company money**.

And he's not alone: **155 of 793 customers — one in five — are net loss-making across their entire
lifetime.** Worst is Cindy Stewart: $5,690 of sales, **−$6,626 of profit.**

> **Revenue is a vanity metric. If you rank customers by spend, you will rank a loss-maker first.**

---

## Q7 — Customer segmentation (RFM)

Scored every customer 1–5 on **R**ecency, **F**requency and **M**onetary value using `NTILE(5)`,
then bucketed them into segments a marketing team can act on.

| Segment | Customers | Sales | % of sales | Avg value/customer | Days since last order |
|---|---:|---:|---:|---:|---:|
| **Champions** | 165 (20.8%) | $668,661 | 29.1% | $4,052 | 25 |
| **Loyal** | 164 (20.7%) | $540,730 | 23.5% | $3,297 | 59 |
| **At Risk (was valuable)** | **81 (10.2%)** | **$352,209** | **15.3%** | **$4,348** | **204** |
| Hibernating | 172 (21.7%) | $291,041 | 12.7% | $1,692 | 377 |
| Needs Attention | 123 (15.5%) | $284,890 | 12.4% | $2,316 | 160 |
| New / Promising | 88 (11.1%) | $159,389 | 6.9% | $1,811 | 26 |

**The 81 "At Risk" customers are worth more per head ($4,348) than the Champions ($4,052)** — and
they haven't ordered in roughly seven months. They are the most valuable individuals in the book,
and they are drifting away.

Supporting facts: the **top 20% of customers drive 48.1% of all sales**, and retention is *not* the
problem — 781 of 793 customers (98.5%) ordered more than once, averaging 6.3 orders each.

---

## Recommendations

1. **Cap discounts at 20%**, sign-off required above it. A re-pricing model puts the prize at
   **+$219,151 profit (+76.5%)**.
   ⚠️ That model holds volume constant, so it's the optimistic bound, not a forecast. The honest
   claim is *"there is a large prize here — size it with a holdout test before rolling out."*
2. **Start with Texas, Ohio, Pennsylvania and Illinois** — $70,857 of losses on 32–39% average
   discounts. Highest-ROI intervention in the dataset.
3. **Fix or delist the 15 chronic loss-makers** — products sold 5+ times that never once made money.
   Worst: the Chromcraft Bull-Nose Conference Table (−$2,876 across 5 sales, 28% avg discount).
4. **Win back the 81 "At Risk" customers** before spending a cent on a broad discount campaign —
   which, per finding 1, would lose money anyway.
5. **Audit the 155 loss-making customers.** Stop ranking accounts by revenue. Sean Miller looks like
   your best customer and is not.
6. **Staff and stock for the Sep/Nov/Dec peak**; run the pricing fix in the Q1 trough, when the
   revenue at risk is smallest.

---

## Data cleaning — what was found and fixed

`sql/cleaning.sql` is written as **profile → fix → prove**. Every fix is preceded by the query that
*proves* the problem exists, and followed by the query that proves it's gone.

| Issue | Evidence | Handling |
|---|---|---|
| **1 exact duplicate row** | `row_id` 3406 & 3407 — same order (US-2014-150119), same product, same date, same $281.372 | `ROW_NUMBER()` dedupe. **9,994 → 9,993 rows.** Query the raw table instead and sales reads $2,297,200.86 — **$281 of revenue that never happened**, propagating into every category, region and margin figure. |
| **449 postal codes lost their leading zero** | 7 North-East states; Vermont's `05408` arrives as `5408` | `LPAD(...,5,'0')`, stored as `CHAR(5)` |
| Dates stored as `M/D/YYYY` **text** | Can't do date maths on text | Rewrite to ISO format, *then* `ALTER TABLE ... MODIFY DATE` (a direct `ALTER` silently writes `0000-00-00`) |
| Sales/profit stored as **text** | Can't `SUM()` text | `CAST(... AS DECIMAL(12,4))` — DECIMAL, not FLOAT: money must be exact |
| **1,870 lines have negative profit** | — | **NOT errors. NOT deleted.** These are real loss-making sales and they are the *entire finding*. Deleting them looks like diligence; it deletes the answer. |
| **32 `product_id`s map to multiple product names** | `product_id` is not unique | Harmless in one flat table, but documented — it would **fan out** any normalised product join and silently inflate revenue. |
| **⚠️ Source CSV is cp1252, not UTF-8** | 367 rows contain non-UTF-8 bytes | Import as UTF-8 and MySQL **silently skips 300 rows** and reports success. Always reconcile `COUNT(*)` against the source: **9,994 or stop.** |

---

## Repository structure

```
Superstore_Sales_Analysis/
├── README.md
├── Dataset/
│   ├── Raw_Data/           Sample - Superstore.csv     9,994 rows, as downloaded
│   └── Cleaned_Data/       superstore_cleaned.csv      9,693 rows, after cleaning
├── Database/
│   └── create_database.sql
└── sql/
    ├── cleaning.sql             remove duplicates → standardize → nulls → columns/rows
    ├── exploratory_analysis.sql understand → numerical → categorical → time → outliers
    └── business_analysis.sql    the seven business questions
```

## How to run

```sql
-- 1. create the database
SOURCE Database/create_database.sql;

-- 2. import Dataset/Raw_Data/Sample - Superstore.csv

-- 3. clean
SOURCE sql/cleaning.sql;
  
-- 4. explore
SOURCE sql/exploratory_analysis.sql;

-- 5. answer the questions
SOURCE sql/business_analysis.sql;
```

**Data source:** [Sample - Superstore (Kaggle)](https://www.kaggle.com/code/jacopoferretti/superstore-sales-analysis-customer-segmentation?select=Sample+-+Superstore.csv) — US office-supplies retailer, 2014–2017.
