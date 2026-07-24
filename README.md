Bright Coffee Shop — Sales Performance Case Study

Overview

Bright Coffee Shop's new CEO set out to grow revenue and improve product performance. As Junior Data Analyst on this project, my task was to take raw, unstructured point-of-sale transaction data and turn it into actionable insight the CEO could use to make decisions covering which products drive the most revenue, when the store performs best, how sales trend across products and time, and what should change to grow the business.

This repository documents the full analysis: from initial planning through data cleaning, analysis, visualization, and final recommendations.

Approach

The project followed a structured, end-to-end analytics workflow:

Planning — Mapped out the full project on Miro before touching any data: a data architecture diagram (source → ETL → storage → analysis → presentation), the key insights the analysis needed to deliver, and the calculations required (total amount, time-interval grouping, units sold by product).
Data processing (Databricks) — Loaded the raw transaction CSV into Databricks and ran it through a full data-quality pass: checked for nulls, duplicates, and inconsistent category/type naming; identified and fixed a comma-decimal formatting issue in unit_price (e.g. '3,1' → 3.1); and caught a subtler issue where the transaction_time column's date component defaulted to the current system date rather than the true transaction date — meaning only the time-of-day portion of that field could be trusted. Built a cleaned, transformed table with a calculated total_amount column and a 30-minute transaction_time_bucket for time-of-day analysis.
Analysis (Excel) — Built a dashboard workbook with formula-driven summary tables (not hardcoded values, so everything recalculates if the underlying data changes) covering revenue by product type, revenue and transaction volume by time interval, units sold by category, and best-selling products by both revenue and volume — plus supporting charts for each.
Reporting — Packaged the findings into a polished PDF report (styled as a BI-tool export) covering key insights, recommendations, and next steps, and into a final CEO-facing PowerPoint presentation.
Live dashboard — Built an interactive, filterable web dashboard so the CEO (and team) can explore the data live rather than relying on a static snapshot.
Key Insights
Revenue leaders aren't always volume leaders. Barista Espresso generates the most revenue ($91,406), but Brewed Chai tea actually sells more units (26,250 vs. 24,943) — Espresso simply carries a higher price point per order.
Coffee and tea dominate. These two categories alone account for roughly two-thirds of all revenue (38.6% and 28.1% respectively); together with Bakery and Drinking Chocolate, the top four categories make up 88.9% of total revenue.
There's a sharp, predictable mid-morning peak. Revenue climbs steadily from opening and peaks at 10:30am ($44,967 in that single 30-minute window), then settles into a flat, stable afternoon plateau (~$19,500–$21,500 per interval) before tapering off in the evening.
Trading is weakest at open and close. The 6:00am opening interval and the 8:00–8:30pm closing window are 7–28x lower in revenue than the 10:30am peak — the clearest opportunity for targeted promotions.
A small group of products consistently underperform. Green beans, Green tea, and Organic Chocolate each earn under 2% of what the top product earns, flagging them as candidates for promotion or menu review.
Recommendations
Run marketing campaigns during the identified slow time slots (opening and closing).
Prioritize inventory and prep capacity for the best-selling products, especially through the morning rush.
Promote (or reassess) the lowest-performing products to determine whether the issue is low awareness or genuinely low demand.
Next Steps
Automate daily sales reporting so the dashboard reflects current performance without manual exports.
Extend the analysis to compare performance across Bright Coffee Shop's three locations (Astoria, Hell's Kitchen, Lower Manhattan).
Design loyalty programs around the identified peak and slow time slots to help smooth demand across the day.
Tools Used
Miro  — project planning, architecture diagramming, and insight mapping
Canva - Project gantt chart
Databricks (SQL) — data ingestion, cleaning, transformation, and aggregation
Microsoft Excel — formula-driven summary tables, pivot-style analysis, and charts
Lovable.ai — live, interactive web dashboard
Power BI / Databricks  — alternative dashboard build paths for the same visuals
Looker studio - Create an alternative dashboard
Microsoft PowerPoint — final CEO-facing presentation
PDF — exported analytics report summarizing insights, recommendations, and next steps
Author

Kagiso Matenchi — Junior Data Analyst
