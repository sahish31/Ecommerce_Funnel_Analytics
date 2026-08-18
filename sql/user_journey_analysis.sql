-- =========================================================
-- USER JOURNEY FUNNEL ANALYSIS
-- SQL Analysis
-- =========================================================

SELECT VERSION();


-- =========================================================
-- 1. TABLE STRUCTURE
-- =========================================================


CREATE DATABASE user_journey_analysis;

USE user_journey_analysis;

SELECT DATABASE();

CREATE TABLE users (
    user_id VARCHAR(50) PRIMARY KEY,
    signup_date DATE,
    age INT,
    gender VARCHAR(20),
    location VARCHAR(50),
    device VARCHAR(20),
    customer_type VARCHAR(20)
);

DESCRIBE users;

CREATE TABLE sessions (
    session_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50),
    session_start DATETIME,
    device VARCHAR(20),
    location VARCHAR(50),
    traffic_source VARCHAR(50),
    customer_type VARCHAR(20),

    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
);

DESCRIBE sessions;

CREATE TABLE events (
    event_id VARCHAR(50) PRIMARY KEY,
    session_id VARCHAR(50),
    user_id VARCHAR(50),
    event_timestamp DATETIME,
    event_type VARCHAR(30),
    product_category VARCHAR(50),
    amount DECIMAL(12,2),
    device VARCHAR(20),
    location VARCHAR(50),
    traffic_source VARCHAR(50),
    customer_type VARCHAR(20),

    FOREIGN KEY (session_id)
        REFERENCES sessions(session_id),

    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
);

DESCRIBE events;
SELECT COUNT(*) AS total_users
FROM users;

SELECT *
FROM users
LIMIT 5;

SELECT COUNT(*) AS total_sessions
FROM sessions;

DELETE FROM sessions;

SELECT COUNT(*) AS total_sessions
FROM sessions;

DELETE FROM sessions;

SELECT COUNT(*) AS total_sessions
FROM sessions;

TRUNCATE TABLE sessions;

SELECT COUNT(*) AS total_sessions
FROM sessions;

SELECT DATABASE();

SELECT COUNT(*) FROM user_journey_analysis.sessions;

TRUNCATE TABLE user_journey_analysis.sessions;

SELECT COUNT(*) FROM user_journey_analysis.sessions;

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE user_journey_analysis.sessions;

SET FOREIGN_KEY_CHECKS = 1;

SELECT COUNT(*) AS total_sessions
FROM user_journey_analysis.sessions;

SELECT COUNT(*) AS total_sessions

SELECT *
FROM user_journey_analysis.sessions
LIMIT 5;
FROM sessions;

SELECT COUNT(*) AS total_sessions
FROM sessions;
SELECT COUNT(*) AS total_events
FROM events;

SELECT 
    COUNT(*) AS total_events,
    COUNT(DISTINCT user_id) AS unique_users,
    COUNT(DISTINCT session_id) AS unique_sessions
FROM events;

SELECT COUNT(*) AS events_without_user
FROM events e
LEFT JOIN users u
    ON e.user_id = u.user_id
WHERE u.user_id IS NULL;

SELECT COUNT(*) AS events_without_session
FROM events e
LEFT JOIN sessions s
    ON e.session_id = s.session_id
WHERE s.session_id IS NULL;

-- =========================================================
-- 2. OVERALL FUNNEL ANALYSIS
-- =========================================================

WITH funnel AS (
    SELECT
        COUNT(DISTINCT CASE
            WHEN event_type = 'visit'
            THEN session_id
        END) AS visit_sessions,

        COUNT(DISTINCT CASE
            WHEN event_type = 'product_view'
            THEN session_id
        END) AS product_view_sessions,

        COUNT(DISTINCT CASE
            WHEN event_type = 'add_to_cart'
            THEN session_id
        END) AS add_to_cart_sessions,

        COUNT(DISTINCT CASE
            WHEN event_type = 'signup'
            THEN session_id
        END) AS signup_sessions,

        COUNT(DISTINCT CASE
            WHEN event_type = 'checkout'
            THEN session_id
        END) AS checkout_sessions,

        COUNT(DISTINCT CASE
            WHEN event_type = 'purchase'
            THEN session_id
        END) AS purchase_sessions
    FROM events
)

SELECT
    'Visit' AS stage,
    visit_sessions AS sessions,
    100.00 AS conversion_rate,
    0.00 AS drop_off_rate
FROM funnel

UNION ALL

SELECT
    'Product View',
    product_view_sessions,
    ROUND(product_view_sessions / visit_sessions * 100, 2),
    ROUND((1 - product_view_sessions / visit_sessions) * 100, 2)
FROM funnel

UNION ALL

SELECT
    'Add to Cart',
    add_to_cart_sessions,
    ROUND(add_to_cart_sessions / product_view_sessions * 100, 2),
    ROUND((1 - add_to_cart_sessions / product_view_sessions) * 100, 2)
FROM funnel

UNION ALL

SELECT
    'Signup',
    signup_sessions,
    ROUND(signup_sessions / add_to_cart_sessions * 100, 2),
    ROUND((1 - signup_sessions / add_to_cart_sessions) * 100, 2)
FROM funnel

UNION ALL

SELECT
    'Checkout',
    checkout_sessions,
    ROUND(checkout_sessions / signup_sessions * 100, 2),
    ROUND((1 - checkout_sessions / signup_sessions) * 100, 2)
FROM funnel

UNION ALL

SELECT
    'Purchase',
    purchase_sessions,
    ROUND(purchase_sessions / checkout_sessions * 100, 2),
    ROUND((1 - purchase_sessions / checkout_sessions) * 100, 2)
FROM funnel;

-- Automatically identify the biggest leakage

WITH funnel AS (
    SELECT
        COUNT(DISTINCT CASE WHEN event_type = 'visit' THEN session_id END) AS visit_sessions,
        COUNT(DISTINCT CASE WHEN event_type = 'product_view' THEN session_id END) AS product_view_sessions,
        COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN session_id END) AS add_to_cart_sessions,
        COUNT(DISTINCT CASE WHEN event_type = 'signup' THEN session_id END) AS signup_sessions,
        COUNT(DISTINCT CASE WHEN event_type = 'checkout' THEN session_id END) AS checkout_sessions,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN session_id END) AS purchase_sessions
    FROM events
),

stage_dropoffs AS (

    SELECT
        'Visit → Product View' AS funnel_stage,
        ROUND((1 - product_view_sessions / visit_sessions) * 100, 2) AS drop_off_rate
    FROM funnel

    UNION ALL

    SELECT
        'Product View → Add to Cart',
        ROUND((1 - add_to_cart_sessions / product_view_sessions) * 100, 2)
    FROM funnel

    UNION ALL

    SELECT
        'Add to Cart → Signup',
        ROUND((1 - signup_sessions / add_to_cart_sessions) * 100, 2)
    FROM funnel

    UNION ALL

    SELECT
        'Signup → Checkout',
        ROUND((1 - checkout_sessions / signup_sessions) * 100, 2)
    FROM funnel

    UNION ALL

    SELECT
        'Checkout → Purchase',
        ROUND((1 - purchase_sessions / checkout_sessions) * 100, 2)
    FROM funnel
)

SELECT
    funnel_stage,
    drop_off_rate
FROM stage_dropoffs
ORDER BY drop_off_rate DESC
LIMIT 1;

-- =========================================================
-- 3. DEVICE ANALYSIS
-- =========================================================

SELECT
    device,

    COUNT(DISTINCT CASE
        WHEN event_type = 'visit'
        THEN session_id
    END) AS visits,

    COUNT(DISTINCT CASE
        WHEN event_type = 'product_view'
        THEN session_id
    END) AS product_views,

    COUNT(DISTINCT CASE
        WHEN event_type = 'add_to_cart'
        THEN session_id
    END) AS add_to_carts,

    COUNT(DISTINCT CASE
        WHEN event_type = 'signup'
        THEN session_id
    END) AS signups,

    COUNT(DISTINCT CASE
        WHEN event_type = 'checkout'
        THEN session_id
    END) AS checkouts,

    COUNT(DISTINCT CASE
        WHEN event_type = 'purchase'
        THEN session_id
    END) AS purchases,

    ROUND(
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN session_id END)
        /
        COUNT(DISTINCT CASE WHEN event_type = 'visit' THEN session_id END)
        * 100,
        2
    ) AS conversion_rate

FROM events

GROUP BY device

ORDER BY conversion_rate DESC;


SELECT
    device,

    ROUND(
        COUNT(DISTINCT CASE WHEN event_type = 'product_view' THEN session_id END)
        /
        COUNT(DISTINCT CASE WHEN event_type = 'visit' THEN session_id END)
        * 100,
        2
    ) AS visit_to_product_view,

    ROUND(
        COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN session_id END)
        /
        COUNT(DISTINCT CASE WHEN event_type = 'product_view' THEN session_id END)
        * 100,
        2
    ) AS product_view_to_cart,

    ROUND(
        COUNT(DISTINCT CASE WHEN event_type = 'signup' THEN session_id END)
        /
        COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN session_id END)
        * 100,
        2
    ) AS cart_to_signup,

    ROUND(
        COUNT(DISTINCT CASE WHEN event_type = 'checkout' THEN session_id END)
        /
        COUNT(DISTINCT CASE WHEN event_type = 'signup' THEN session_id END)
        * 100,
        2
    ) AS signup_to_checkout,

    ROUND(
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN session_id END)
        /
        COUNT(DISTINCT CASE WHEN event_type = 'checkout' THEN session_id END)
        * 100,
        2
    ) AS checkout_to_purchase

FROM events

GROUP BY device;


-- =========================================================
-- 4. TRAFFIC SOURCE ANALYSIS
-- =========================================================

SELECT
    traffic_source,

    COUNT(DISTINCT CASE
        WHEN event_type = 'visit'
        THEN session_id
    END) AS visits,

    COUNT(DISTINCT CASE
        WHEN event_type = 'purchase'
        THEN session_id
    END) AS purchases,

    ROUND(
        COUNT(DISTINCT CASE
            WHEN event_type = 'purchase'
            THEN session_id
        END)
        /
        COUNT(DISTINCT CASE
            WHEN event_type = 'visit'
            THEN session_id
        END)
        * 100,
        2
    ) AS conversion_rate

FROM events

GROUP BY traffic_source

ORDER BY conversion_rate DESC;

-- Traffic Source Funnel Stages

SELECT
    traffic_source,

    ROUND(
        COUNT(DISTINCT CASE
            WHEN event_type = 'product_view'
            THEN session_id
        END)
        /
        COUNT(DISTINCT CASE
            WHEN event_type = 'visit'
            THEN session_id
        END) * 100,
        2
    ) AS visit_to_product_view,

    ROUND(
        COUNT(DISTINCT CASE
            WHEN event_type = 'add_to_cart'
            THEN session_id
        END)
        /
        COUNT(DISTINCT CASE
            WHEN event_type = 'product_view'
            THEN session_id
        END) * 100,
        2
    ) AS product_view_to_cart,

    ROUND(
        COUNT(DISTINCT CASE
            WHEN event_type = 'signup'
            THEN session_id
        END)
        /
        COUNT(DISTINCT CASE
            WHEN event_type = 'add_to_cart'
            THEN session_id
        END) * 100,
        2
    ) AS cart_to_signup,

    ROUND(
        COUNT(DISTINCT CASE
            WHEN event_type = 'checkout'
            THEN session_id
        END)
        /
        COUNT(DISTINCT CASE
            WHEN event_type = 'signup'
            THEN session_id
        END) * 100,
        2
    ) AS signup_to_checkout,

    ROUND(
        COUNT(DISTINCT CASE
            WHEN event_type = 'purchase'
            THEN session_id
        END)
        /
        COUNT(DISTINCT CASE
            WHEN event_type = 'checkout'
            THEN session_id
        END) * 100,
        2
    ) AS checkout_to_purchase

FROM events

GROUP BY traffic_source

ORDER BY product_view_to_cart ASC; 


-- =========================================================
-- 5. LOCATION ANALYSIS
-- =========================================================

SELECT
    location,

    COUNT(DISTINCT CASE
        WHEN event_type = 'visit'
        THEN session_id
    END) AS visits,

    COUNT(DISTINCT CASE
        WHEN event_type = 'purchase'
        THEN session_id
    END) AS purchases,

    ROUND(
        COUNT(DISTINCT CASE
            WHEN event_type = 'purchase'
            THEN session_id
        END)
        /
        COUNT(DISTINCT CASE
            WHEN event_type = 'visit'
            THEN session_id
        END)
        * 100,
        2
    ) AS conversion_rate

FROM events

GROUP BY location

ORDER BY conversion_rate DESC;

-- =========================================================
-- 6. FINAL BUSINESS INSIGHTS
-- =========================================================

SELECT
    'Overall Funnel' AS analysis_area,
    'Product View → Add to Cart' AS key_finding,
    '59.77% drop-off' AS result,
    'Improve product page UX and Add to Cart CTA' AS recommendation

UNION ALL

SELECT
    'Device',
    'Tablet',
    'Lowest funnel performance',
    'Optimize tablet and mobile product/cart experience'

UNION ALL

SELECT
    'Traffic Source',
    'Facebook',
    '1.82% conversion rate',
    'Review targeting, landing pages and campaign quality'

UNION ALL

SELECT
    'Traffic Source',
    'Email',
    '15.37% conversion rate',
    'Expand email and remarketing campaigns'

UNION ALL

SELECT
    'Location',
    'Bangalore',
    '6.67% conversion rate',
    'Use Bangalore as a benchmark for other locations'

UNION ALL

SELECT
    'Location',
    'Kolkata',
    '6.01% conversion rate',
    'Investigate regional behavior, but avoid over-prioritizing location';
    
    -- some findings with query
    
    SELECT COUNT(*) AS total_rows
FROM users;

SELECT COUNT(DISTINCT user_id) AS unique_users
FROM users;

SELECT
    user_id,
    COUNT(*) AS occurrences
FROM users
GROUP BY user_id
HAVING COUNT(*) > 1
LIMIT 20;

SELECT *
FROM users
LIMIT 10;

SELECT
    gender,
    COUNT(*) AS count
FROM users
GROUP BY gender;

ALTER TABLE users
ADD COLUMN traffic_source VARCHAR(50);

UPDATE users
SET traffic_source = gender;

ALTER TABLE users
DROP COLUMN gender,
DROP COLUMN age,
DROP COLUMN signup_date;

DESCRIBE users;

SELECT * FROM users LIMIT 10;

TRUNCATE TABLE users;

SELECT COUNT(*) AS total_users
FROM users;

TRUNCATE TABLE user_journey_analysis.users;

SELECT COUNT(*) AS total_users
FROM user_journey_analysis.users;

SELECT DATABASE();

SELECT COUNT(*) FROM user_journey_analysis.users;

TRUNCATE TABLE user_journey_analysis.users;

SELECT COUNT(*) AS total_users
FROM user_journey_analysis.users;

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE user_journey_analysis.users;

SET FOREIGN_KEY_CHECKS = 1;

SELECT COUNT(*) AS total_users
FROM user_journey_analysis.users;

SELECT COUNT(*) AS total_users
FROM user_journey_analysis.users;

SELECT COUNT(DISTINCT user_id) AS unique_users
FROM user_journey_analysis.users;

SELECT *
FROM user_journey_analysis.users
LIMIT 10;

SELECT COUNT(*) AS total_users
FROM user_journey_analysis.users;

SELECT
    traffic_source,
    COUNT(*) AS user_count
FROM user_journey_analysis.users
GROUP BY traffic_source
ORDER BY user_count DESC;