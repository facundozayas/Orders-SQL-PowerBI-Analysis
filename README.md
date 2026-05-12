# Orders SQL & Power BI Analysis

End-to-end analysis of an e-commerce orders dataset covering customer behavior, 
retention, segmentation and revenue concentration.

## Dataset
- Source: synthetic e-commerce dataset
- ~7,000 orders across 6 product categories and 6 countries
- Period: 2022–2025

## Tools
- SQL (SQLite / DBeaver) — data analysis and modeling
- Power BI — interactive dashboard

## Structure
- `sql/portfolio_orders_v2.sql` — full analysis script
- `powerbi/orders_dashboard.pbix` — Power BI dashboard

## Dashboard — 4 pages
1. **General & Seasonality** — revenue matrix by category/year, monthly trends
2. **Customers** — cohort retention, new customers per year, VIP segmentation
3. **Categories & Countries** — interactive cross-filter by country and category
4. **Pareto & RFM** — revenue concentration by country, customer distribution

## Key Findings
- Retention rate is near 0% across all cohorts — main business pain point
- USA alone represents ~41% of total revenue
- VIP segment: only 12 customers out of 4,736 — but 2x average ticket
- No clear seasonality detected across the 4-year period
- New customer acquisition growing year over year (+8% from 2022 to 2024)
