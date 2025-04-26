# PostgreSQL Anonymizer Functions Reference

This document provides examples of the most commonly used anonymization functions in PostgreSQL Anonymizer.

## Basic Anonymization Functions

```sql
-- Email masking
SELECT anon.partial_email('john.doe@example.com');
-- Result: jo******@ex******.com

-- Random string generation
SELECT anon.random_string(10);
-- Result: NTx1xby9Aq (random 10-character string)

-- Fake data generation
SELECT anon.fake_company();
-- Result: Holder, Crawford and Johnson (random company name)

SELECT anon.fake_first_name(), anon.fake_last_name();
-- Result: Ashlee Blankenship (random person name)

SELECT anon.fake_address();
-- Result: 57068 Howell Summit, South Connie, MN 60662 (random address)
```

## Partial Data Masking

```sql
-- Mask part of a string with custom format
SELECT anon.partial('123-45-6789', 3, '***', 2);
-- Result: 123***89 (keeps first 3 and last 2 characters)

SELECT anon.partial('555-123-4567', 0, '***', 4);
-- Result: ***4567 (keeps last 4 characters)
```

## Randomization Functions

```sql
-- Random integer in a range
SELECT anon.random_int_between(50000, 100000);
-- Result: 75010 (random integer between 50000 and 100000)

-- Random date
SELECT anon.random_date_between('2020-01-01'::timestamp, '2025-12-31'::timestamp);
-- Result: 2023-05-17 14:32:19.123456+00 (random date between the two dates)

-- Random selection from a list
SELECT anon.random_in(ARRAY['Red', 'Green', 'Blue', 'Yellow']);
-- Result: Green (random selection from the array)
```

## Pseudonymization Functions

```sql
-- Consistent pseudonymization (same input always gives same output)
SELECT anon.hash('sensitive-value');
-- Result: 7328fddefd53de471b8f31131c3b2adf (consistent hash)

-- Pseudonymization with specific data types
SELECT anon.pseudo_first_name('john');
-- Result: Robert (consistent replacement)

SELECT anon.pseudo_city('New York');
-- Result: Chicago (consistent replacement)
```

## Generalization Functions

```sql
-- Generalize numeric values
SELECT anon.generalize_int4range(42, 10);
-- Result: [40,50) (range containing the value)

-- Generalize dates
SELECT anon.generalize_daterange('2025-04-26'::date, 'month');
-- Result: [2025-04-01,2025-05-01) (month containing the date)
```

## Noise Addition

```sql
-- Add noise to numeric values
SELECT anon.noise(100, 0.1);
-- Result: 105 (adds up to 10% noise)

-- Add noise to dates
SELECT anon.dnoise('2025-04-26'::timestamp, '7 days'::interval);
-- Result: 2025-04-29 (adds random noise within 7 days)
```

## Dummy Data Generation

```sql
-- Generate dummy data with specific formats
SELECT anon.dummy_credit_card_number();
-- Result: 4532383564703

SELECT anon.dummy_iban();
-- Result: FR7630006000011234567890189

SELECT anon.dummy_ip();
-- Result: 192.168.1.1
```

## Text Masking

```sql
-- Lorem ipsum text generation
SELECT anon.lorem_ipsum(2, 10);
-- Result: Two paragraphs with approximately 10 words each
```
