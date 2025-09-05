-- Table: fact_loans

DROP TABLE IF EXISTS fact_loans;

CREATE TABLE IF NOT EXISTS fact_loans
(
    loan_id bigint,
    approval_date date,
    approval_ym date,
    approval_m integer,
    gross_approval numeric(10,2),
    project_state character varying(2),
    borr_state character varying(2),
    bank_state character varying(2),
    naics_code character varying(6),
    naics_code_2 character(2),
    term_in_months smallint,
    size_bucket character varying(10),
    gross_charge_off_amount numeric(10,2),
    default_flag smallint,
    processing_code character(3),
    processing_bucket character varying(20)
)
;