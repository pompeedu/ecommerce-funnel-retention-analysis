# E-commerce Funnel & Retention Analysis

## 📌 Problem

The product shows consistent growth in daily active users (**DAU**), but **revenue and number of orders are not scaling proportionally**.

This indicates a potential issue in user conversion and monetization efficiency.



## 🎯 Goal

Identify which user segments drive DAU growth and determine why this growth does not translate into revenue.

Define key bottlenecks in the funnel and provide actionable product recommendations.



## 🚀 Key Insights

- ~49% of DAU are **new users (0d)**, but they generate a disproportionately low number of orders  
- The main drop occurs between **product view → add to cart**
- ~92% of new users leave without adding items to cart
- Returning users (**31+ days**) are the core revenue drivers
- Conversion gap is caused by **low-quality activation of new users**, not by product assortment

> 👉 The product successfully attracts users but fails to convert them into buyers.



## 📊 Dataset

- 700M+ user events  
- Event-based structure
- Link: https://www.kaggle.com/datasets/mkechinov/ecommerce-behavior-data-from-multi-category-store  

**Table: `events`**
- `event_time`
- `event_type` (view, cart, purchase)
- `product_id`, `category_code`, `brand`
- `price`
- `user_id`, `user_session`

**Notes:**
- Orders are defined as `purchase` events  
- Revenue is calculated as the sum of `price` for purchase events  



## 🧱 Data Modeling

To handle large-scale data, aggregated tables (**data marts**) were created:

- `user_day_activity` — DAU, retention, activity  
- `user_first_touch` — cohort analysis  
- `funnel_events` — funnel metrics  
- `user_segments` — user segmentation by lifetime  

All tables are indexed by `dt` and `user_id` to optimize performance.



## 📈 Key Metrics

- DAU  
- Conversion Rate  
- Retention (D1, D7, D30)  
- Orders per user  



## 🔍 Analysis Overview

### 1. Growth Dynamics
- DAU is steadily increasing  
- Orders are growing slower than user base  
- Orders per user is unstable  

### 2. User Structure
- Growth is driven by both new and returning users  
- Share of returning users increases over time  

### 3. Retention

- **D1:** ~15–17%  
- **D7:** ~8–11%  
- **D30:** ~7%  

Retention is moderate, indicating a stable but not highly engaging product.

### 4. Funnel Analysis

- 76.76% drop after product view  
- 9.89% drop after cart  
- 12.76% complete purchase  

> 👉 The biggest loss happens **before intent is formed**

### 5. Segmentation by User Age

| Segment | Share of Users | Orders per User |
|--------|---------------|----------------|
| 0d     | 49%           | 0.05           |
| 1–7d   | 8.5%          | 0.33           |
| 8–30d  | 10%           | 0.50           |
| 31+d   | 32%           | 1.20           |

> 👉 Core users (31+d) generate most of the revenue

### 6. Funnel Comparison (0d vs 31+d)

| Segment | View | Cart | Purchase |
|--------|------|------|----------|
| 0d     | ~100% | 7.6% | 3.8% |
| 31+d   | ~100% | 43.8% | 26.9% |

> 👉 The gap appears at the **view → cart transition**

### 7. Category Analysis

- New users explore the same categories as core users  
- Conversion differences are not caused by assortment  
- High-performing categories:
  - `construction.tools.light`
  - `electronics.smartphone`
  - `appliances.environment.vacuum`


## 💡 Product Interpretation

- Growth is driven by acquisition, not monetization  
- New users are not properly activated  
- Core users generate most of the value  
- The main bottleneck is **intent formation**



## 📊 Dashboard

Power BI dashboard included in the repository:

- Category-level conversion analysis  
- Comparison of user segments (0d vs 31+d)  

### Preview


![dashboard_preview](/dashboard/dashboard_preview.png)



## 🧾 SQL

The project contains:

- Data marts (aggregations for performance)  
- Analytical queries for:
  - DAU & revenue dynamics  
  - Retention  
  - Funnel analysis  
  - User segmentation  
  - Category conversion  



## 📽 Presentation

Includes a product-focused presentation with:

- Key findings  
- Funnel bottlenecks  
- Product recommendations  


## 🛠 Tools

- SQL (PostgreSQL)  
- Power BI  
- Large-scale data aggregation  



## 📌 Recommendations

1. **Improve new user activation**
   - onboarding
   - personalized recommendations  

2. **Stimulate first purchase**
   - first-order discounts  
   - free delivery  

3. **Optimize product pages**
   - better visuals  
   - reviews  
   - pricing clarity  

4. **Analyze traffic sources**
   - identify low-quality acquisition channels  



## ⚠️ Limitations

- No marketing channel data  
- Orders defined via events (no separate order table)  
- Limited time range (possible seasonality impact)  
- No pricing/discount context  



## 📁 Project Structure


/sql # queries and marts

/data # processed datasets

/dashboard # Power BI dashboard

/presentation # business recommendations

/docs # full case description




## 🧠 Final Conclusion

**DAU growth alone does not guarantee business growth.**

The key issue is not acquisition —  
it is the inability to convert new users into paying customers.

## 👤 Author

Firuzjon Qurbonov

Product Analyst  

📬 Telegram: https://t.me/pompeedu  
✉️ Email: firuzjonkurbonov735700@gmail.com