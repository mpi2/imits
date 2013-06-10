--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: audits; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE audits (
    id integer NOT NULL,
    auditable_id integer,
    auditable_type character varying(255),
    associated_id integer,
    associated_type character varying(255),
    user_id integer,
    user_type character varying(255),
    username character varying(255),
    action character varying(255),
    audited_changes text,
    version integer DEFAULT 0,
    comment character varying(255),
    remote_address character varying(255),
    created_at timestamp without time zone
);


--
-- Name: audits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE audits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE audits_id_seq OWNED BY audits.id;


--
-- Name: centres; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE centres (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: centres_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE centres_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: centres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE centres_id_seq OWNED BY centres.id;


--
-- Name: consortia; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE consortia (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    funding character varying(255),
    participants text,
    contact character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: consortia_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE consortia_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: consortia_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE consortia_id_seq OWNED BY consortia.id;


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE contacts (
    id integer NOT NULL,
    email character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    report_to_public boolean DEFAULT true
);


--
-- Name: contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contacts_id_seq OWNED BY contacts.id;


--
-- Name: deleter_strains; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE deleter_strains (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: deleter_strains_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE deleter_strains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deleter_strains_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE deleter_strains_id_seq OWNED BY deleter_strains.id;


--
-- Name: deposited_materials; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE deposited_materials (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: deposited_materials_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE deposited_materials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deposited_materials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE deposited_materials_id_seq OWNED BY deposited_materials.id;


--
-- Name: email_templates; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE email_templates (
    id integer NOT NULL,
    status character varying(255),
    welcome_body text,
    update_body text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: email_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE email_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE email_templates_id_seq OWNED BY email_templates.id;


--
-- Name: es_cells; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE es_cells (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    allele_symbol_superscript_template character varying(75),
    allele_type character varying(2),
    pipeline_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    gene_id integer NOT NULL,
    parental_cell_line character varying(255),
    ikmc_project_id character varying(100),
    mutation_subtype character varying(100),
    allele_id integer NOT NULL
);


--
-- Name: es_cells_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE es_cells_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: es_cells_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE es_cells_id_seq OWNED BY es_cells.id;


--
-- Name: genes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE genes (
    id integer NOT NULL,
    marker_symbol character varying(75) NOT NULL,
    mgi_accession_id character varying(40),
    ikmc_projects_count integer,
    conditional_es_cells_count integer,
    non_conditional_es_cells_count integer,
    deletion_es_cells_count integer,
    other_targeted_mice_count integer,
    other_condtional_mice_count integer,
    mutation_published_as_lethal_count integer,
    publications_for_gene_count integer,
    go_annotations_for_gene_count integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: genes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE genes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: genes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE genes_id_seq OWNED BY genes.id;


--
-- Name: intermediate_report; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE intermediate_report (
    id integer NOT NULL,
    consortium character varying(255) NOT NULL,
    sub_project character varying(255) NOT NULL,
    priority character varying(255),
    production_centre character varying(255) NOT NULL,
    gene character varying(75) NOT NULL,
    mgi_accession_id character varying(40),
    overall_status character varying(50),
    mi_plan_status character varying(50),
    mi_attempt_status character varying(50),
    phenotype_attempt_status character varying(50),
    ikmc_project_id character varying(255),
    mutation_sub_type character varying(100),
    allele_symbol character varying(255) NOT NULL,
    genetic_background character varying(255) NOT NULL,
    assigned_date date,
    assigned_es_cell_qc_in_progress_date date,
    assigned_es_cell_qc_complete_date date,
    micro_injection_in_progress_date date,
    chimeras_obtained_date date,
    genotype_confirmed_date date,
    micro_injection_aborted_date date,
    phenotype_attempt_registered_date date,
    rederivation_started_date date,
    rederivation_complete_date date,
    cre_excision_started_date date,
    cre_excision_complete_date date,
    phenotyping_started_date date,
    phenotyping_complete_date date,
    phenotype_attempt_aborted_date date,
    distinct_genotype_confirmed_es_cells integer,
    distinct_old_non_genotype_confirmed_es_cells integer,
    mi_plan_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    total_pipeline_efficiency_gene_count integer,
    gc_pipeline_efficiency_gene_count integer,
    is_bespoke_allele boolean,
    aborted_es_cell_qc_failed_date date,
    mi_attempt_colony_name character varying(255),
    mi_attempt_consortium character varying(255),
    mi_attempt_production_centre character varying(255),
    phenotype_attempt_colony_name character varying(255)
);


--
-- Name: intermediate_report_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE intermediate_report_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intermediate_report_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE intermediate_report_id_seq OWNED BY intermediate_report.id;


--
-- Name: mi_attempt_distribution_centres; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mi_attempt_distribution_centres (
    id integer NOT NULL,
    start_date date,
    end_date date,
    mi_attempt_id integer NOT NULL,
    deposited_material_id integer NOT NULL,
    centre_id integer NOT NULL,
    is_distributed_by_emma boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    distribution_network character varying(255)
);


--
-- Name: mi_attempt_distribution_centres_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mi_attempt_distribution_centres_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mi_attempt_distribution_centres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mi_attempt_distribution_centres_id_seq OWNED BY mi_attempt_distribution_centres.id;


--
-- Name: mi_attempt_status_stamps; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mi_attempt_status_stamps (
    id integer NOT NULL,
    mi_attempt_id integer NOT NULL,
    status_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: mi_attempt_status_stamps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mi_attempt_status_stamps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mi_attempt_status_stamps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mi_attempt_status_stamps_id_seq OWNED BY mi_attempt_status_stamps.id;


--
-- Name: mi_attempt_statuses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mi_attempt_statuses (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    order_by integer,
    code character varying(10) NOT NULL
);


--
-- Name: mi_attempt_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mi_attempt_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mi_attempt_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mi_attempt_statuses_id_seq OWNED BY mi_attempt_statuses.id;


--
-- Name: mi_attempts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mi_attempts (
    id integer NOT NULL,
    es_cell_id integer NOT NULL,
    mi_date date NOT NULL,
    status_id integer NOT NULL,
    colony_name character varying(125),
    updated_by_id integer,
    blast_strain_id integer,
    total_blasts_injected integer,
    total_transferred integer,
    number_surrogates_receiving integer,
    total_pups_born integer,
    total_female_chimeras integer,
    total_male_chimeras integer,
    total_chimeras integer,
    number_of_males_with_0_to_39_percent_chimerism integer,
    number_of_males_with_40_to_79_percent_chimerism integer,
    number_of_males_with_80_to_99_percent_chimerism integer,
    number_of_males_with_100_percent_chimerism integer,
    colony_background_strain_id integer,
    test_cross_strain_id integer,
    date_chimeras_mated date,
    number_of_chimera_matings_attempted integer,
    number_of_chimera_matings_successful integer,
    number_of_chimeras_with_glt_from_cct integer,
    number_of_chimeras_with_glt_from_genotyping integer,
    number_of_chimeras_with_0_to_9_percent_glt integer,
    number_of_chimeras_with_10_to_49_percent_glt integer,
    number_of_chimeras_with_50_to_99_percent_glt integer,
    number_of_chimeras_with_100_percent_glt integer,
    total_f1_mice_from_matings integer,
    number_of_cct_offspring integer,
    number_of_het_offspring integer,
    number_of_live_glt_offspring integer,
    mouse_allele_type character varying(2),
    qc_southern_blot_id integer,
    qc_five_prime_lr_pcr_id integer,
    qc_five_prime_cassette_integrity_id integer,
    qc_tv_backbone_assay_id integer,
    qc_neo_count_qpcr_id integer,
    qc_neo_sr_pcr_id integer,
    qc_loa_qpcr_id integer,
    qc_homozygous_loa_sr_pcr_id integer,
    qc_lacz_sr_pcr_id integer,
    qc_mutant_specific_sr_pcr_id integer,
    qc_loxp_confirmation_id integer,
    qc_three_prime_lr_pcr_id integer,
    report_to_public boolean DEFAULT true NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    is_released_from_genotyping boolean DEFAULT false NOT NULL,
    comments text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    mi_plan_id integer NOT NULL,
    genotyping_comment character varying(512),
    legacy_es_cell_id integer,
    qc_lacz_count_qpcr_id integer DEFAULT 1,
    qc_critical_region_qpcr_id integer DEFAULT 1,
    qc_loxp_srpcr_id integer DEFAULT 1,
    qc_loxp_srpcr_and_sequencing_id integer DEFAULT 1
);


--
-- Name: mi_attempts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mi_attempts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mi_attempts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mi_attempts_id_seq OWNED BY mi_attempts.id;


--
-- Name: mi_plan_es_cell_qcs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mi_plan_es_cell_qcs (
    id integer NOT NULL,
    number_starting_qc integer,
    number_passing_qc integer,
    mi_plan_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: mi_plan_es_cell_qcs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mi_plan_es_cell_qcs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mi_plan_es_cell_qcs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mi_plan_es_cell_qcs_id_seq OWNED BY mi_plan_es_cell_qcs.id;


--
-- Name: mi_plan_es_qc_comments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mi_plan_es_qc_comments (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: mi_plan_es_qc_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mi_plan_es_qc_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mi_plan_es_qc_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mi_plan_es_qc_comments_id_seq OWNED BY mi_plan_es_qc_comments.id;


--
-- Name: mi_plan_priorities; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mi_plan_priorities (
    id integer NOT NULL,
    name character varying(10) NOT NULL,
    description character varying(100),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: mi_plan_priorities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mi_plan_priorities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mi_plan_priorities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mi_plan_priorities_id_seq OWNED BY mi_plan_priorities.id;


--
-- Name: mi_plan_status_stamps; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mi_plan_status_stamps (
    id integer NOT NULL,
    mi_plan_id integer NOT NULL,
    status_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: mi_plan_status_stamps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mi_plan_status_stamps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mi_plan_status_stamps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mi_plan_status_stamps_id_seq OWNED BY mi_plan_status_stamps.id;


--
-- Name: mi_plan_statuses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mi_plan_statuses (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(255),
    order_by integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    code character varying(10) NOT NULL
);


--
-- Name: mi_plan_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mi_plan_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mi_plan_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mi_plan_statuses_id_seq OWNED BY mi_plan_statuses.id;


--
-- Name: mi_plan_sub_projects; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mi_plan_sub_projects (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: mi_plan_sub_projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mi_plan_sub_projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mi_plan_sub_projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mi_plan_sub_projects_id_seq OWNED BY mi_plan_sub_projects.id;


--
-- Name: mi_plans; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mi_plans (
    id integer NOT NULL,
    gene_id integer NOT NULL,
    consortium_id integer NOT NULL,
    status_id integer NOT NULL,
    priority_id integer NOT NULL,
    production_centre_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    number_of_es_cells_starting_qc integer,
    number_of_es_cells_passing_qc integer,
    sub_project_id integer NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    is_bespoke_allele boolean DEFAULT false NOT NULL,
    is_conditional_allele boolean DEFAULT false NOT NULL,
    is_deletion_allele boolean DEFAULT false NOT NULL,
    is_cre_knock_in_allele boolean DEFAULT false NOT NULL,
    is_cre_bac_allele boolean DEFAULT false NOT NULL,
    comment text,
    withdrawn boolean DEFAULT false NOT NULL,
    es_qc_comment_id integer,
    phenotype_only boolean DEFAULT false,
    completion_note character varying(100),
    recovery boolean,
    conditional_tm1c boolean DEFAULT false NOT NULL,
    ignore_available_mice boolean DEFAULT false NOT NULL,
    number_of_es_cells_received integer,
    es_cells_received_on date,
    es_cells_received_from_id integer
);


--
-- Name: mi_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mi_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mi_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mi_plans_id_seq OWNED BY mi_plans.id;


--
-- Name: new_intermediate_report; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE new_intermediate_report (
    id integer NOT NULL,
    gene character varying(75) NOT NULL,
    mi_plan_id integer NOT NULL,
    consortium character varying(255) NOT NULL,
    production_centre character varying(255),
    sub_project character varying(255),
    priority character varying(255),
    mgi_accession_id character varying(40),
    overall_status character varying(50),
    mi_plan_status character varying(50),
    mi_attempt_status character varying(50),
    phenotype_attempt_status character varying(50),
    ikmc_project_id character varying(255),
    mutation_sub_type character varying(100),
    allele_symbol character varying(255),
    genetic_background character varying(255),
    is_bespoke_allele boolean,
    mi_attempt_colony_name character varying(255),
    mi_attempt_consortium character varying(255),
    mi_attempt_production_centre character varying(255),
    phenotype_attempt_colony_name character varying(255),
    assigned_date date,
    assigned_es_cell_qc_in_progress_date date,
    assigned_es_cell_qc_complete_date date,
    aborted_es_cell_qc_failed_date date,
    micro_injection_in_progress_date date,
    chimeras_obtained_date date,
    genotype_confirmed_date date,
    micro_injection_aborted_date date,
    phenotype_attempt_registered_date date,
    rederivation_started_date date,
    rederivation_complete_date date,
    cre_excision_started_date date,
    cre_excision_complete_date date,
    phenotyping_started_date date,
    phenotyping_complete_date date,
    phenotype_attempt_aborted_date date,
    distinct_genotype_confirmed_es_cells integer,
    distinct_old_genotype_confirmed_es_cells integer,
    distinct_non_genotype_confirmed_es_cells integer,
    distinct_old_non_genotype_confirmed_es_cells integer,
    total_pipeline_efficiency_gene_count integer,
    total_old_pipeline_efficiency_gene_count integer,
    gc_pipeline_efficiency_gene_count integer,
    gc_old_pipeline_efficiency_gene_count integer,
    created_at timestamp without time zone
);


--
-- Name: new_intermediate_report_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE new_intermediate_report_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: new_intermediate_report_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE new_intermediate_report_id_seq OWNED BY new_intermediate_report.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE notifications (
    id integer NOT NULL,
    welcome_email_sent timestamp without time zone,
    welcome_email_text text,
    last_email_sent timestamp without time zone,
    last_email_text text,
    gene_id integer NOT NULL,
    contact_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE notifications_id_seq OWNED BY notifications.id;


--
-- Name: phenotype_attempt_distribution_centres; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE phenotype_attempt_distribution_centres (
    id integer NOT NULL,
    start_date date,
    end_date date,
    phenotype_attempt_id integer NOT NULL,
    deposited_material_id integer NOT NULL,
    centre_id integer NOT NULL,
    is_distributed_by_emma boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    distribution_network character varying(255)
);


--
-- Name: phenotype_attempt_distribution_centres_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE phenotype_attempt_distribution_centres_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: phenotype_attempt_distribution_centres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE phenotype_attempt_distribution_centres_id_seq OWNED BY phenotype_attempt_distribution_centres.id;


--
-- Name: phenotype_attempt_status_stamps; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE phenotype_attempt_status_stamps (
    id integer NOT NULL,
    phenotype_attempt_id integer NOT NULL,
    status_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: phenotype_attempt_status_stamps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE phenotype_attempt_status_stamps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: phenotype_attempt_status_stamps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE phenotype_attempt_status_stamps_id_seq OWNED BY phenotype_attempt_status_stamps.id;


--
-- Name: phenotype_attempt_statuses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE phenotype_attempt_statuses (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    order_by integer,
    code character varying(10) NOT NULL
);


--
-- Name: phenotype_attempt_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE phenotype_attempt_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: phenotype_attempt_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE phenotype_attempt_statuses_id_seq OWNED BY phenotype_attempt_statuses.id;


--
-- Name: phenotype_attempts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE phenotype_attempts (
    id integer NOT NULL,
    mi_attempt_id integer NOT NULL,
    status_id integer NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    rederivation_started boolean DEFAULT false NOT NULL,
    rederivation_complete boolean DEFAULT false NOT NULL,
    number_of_cre_matings_started integer DEFAULT 0 NOT NULL,
    number_of_cre_matings_successful integer DEFAULT 0 NOT NULL,
    phenotyping_started boolean DEFAULT false NOT NULL,
    phenotyping_complete boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    mi_plan_id integer NOT NULL,
    colony_name character varying(125) NOT NULL,
    mouse_allele_type character varying(2),
    deleter_strain_id integer,
    colony_background_strain_id integer,
    cre_excision_required boolean DEFAULT true NOT NULL,
    tat_cre boolean DEFAULT false
);


--
-- Name: phenotype_attempts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE phenotype_attempts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: phenotype_attempts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE phenotype_attempts_id_seq OWNED BY phenotype_attempts.id;


--
-- Name: pipelines; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pipelines (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: pipelines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pipelines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pipelines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pipelines_id_seq OWNED BY pipelines.id;


--
-- Name: production_goals; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE production_goals (
    id integer NOT NULL,
    consortium_id integer,
    year integer,
    month integer,
    mi_goal integer,
    gc_goal integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: production_goals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE production_goals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: production_goals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE production_goals_id_seq OWNED BY production_goals.id;


--
-- Name: qc_results; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE qc_results (
    id integer NOT NULL,
    description character varying(50) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: qc_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE qc_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: qc_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE qc_results_id_seq OWNED BY qc_results.id;


--
-- Name: report_caches; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE report_caches (
    id integer NOT NULL,
    name text NOT NULL,
    data text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    format text NOT NULL
);


--
-- Name: report_caches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE report_caches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_caches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE report_caches_id_seq OWNED BY report_caches.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: solr_update_queue_items; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE solr_update_queue_items (
    id integer NOT NULL,
    mi_attempt_id integer,
    phenotype_attempt_id integer,
    action text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    allele_id integer,
    gene_id integer,
    CONSTRAINT solr_update_queue_items_action CHECK ((action = ANY (ARRAY['update'::text, 'delete'::text]))),
    CONSTRAINT solr_update_queue_items_xor_fkeys_newer CHECK ((((((((allele_id IS NULL) AND (mi_attempt_id IS NULL)) AND (phenotype_attempt_id IS NOT NULL)) AND (gene_id IS NULL)) OR ((((allele_id IS NULL) AND (mi_attempt_id IS NOT NULL)) AND (phenotype_attempt_id IS NULL)) AND (gene_id IS NULL))) OR ((((allele_id IS NOT NULL) AND (mi_attempt_id IS NULL)) AND (phenotype_attempt_id IS NULL)) AND (gene_id IS NULL))) OR ((((allele_id IS NULL) AND (mi_attempt_id IS NULL)) AND (phenotype_attempt_id IS NULL)) AND (gene_id IS NOT NULL))))
);


--
-- Name: solr_update_queue_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE solr_update_queue_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solr_update_queue_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE solr_update_queue_items_id_seq OWNED BY solr_update_queue_items.id;


--
-- Name: strains; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE strains (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: strains_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE strains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: strains_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE strains_id_seq OWNED BY strains.id;


--
-- Name: targ_rep_alleles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE targ_rep_alleles (
    id integer NOT NULL,
    gene_id integer,
    assembly character varying(50) DEFAULT 'NCBIM37'::character varying NOT NULL,
    chromosome character varying(2) NOT NULL,
    strand character varying(1) NOT NULL,
    homology_arm_start integer,
    homology_arm_end integer,
    loxp_start integer,
    loxp_end integer,
    cassette_start integer,
    cassette_end integer,
    cassette character varying(100),
    backbone character varying(100),
    subtype_description character varying(255),
    floxed_start_exon character varying(255),
    floxed_end_exon character varying(255),
    project_design_id integer,
    reporter character varying(255),
    mutation_method_id integer,
    mutation_type_id integer,
    mutation_subtype_id integer,
    cassette_type character varying(50),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    intron integer,
    type character varying(255) DEFAULT 'TargRep::TargetedAllele'::character varying
);


--
-- Name: targ_rep_alleles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_alleles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_alleles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_alleles_id_seq OWNED BY targ_rep_alleles.id;


--
-- Name: targ_rep_centre_pipelines; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE targ_rep_centre_pipelines (
    id integer NOT NULL,
    name character varying(255),
    centres text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: targ_rep_centre_pipelines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_centre_pipelines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_centre_pipelines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_centre_pipelines_id_seq OWNED BY targ_rep_centre_pipelines.id;


--
-- Name: targ_rep_distribution_qcs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE targ_rep_distribution_qcs (
    id integer NOT NULL,
    five_prime_sr_pcr character varying(255),
    three_prime_sr_pcr character varying(255),
    karyotype_low double precision,
    karyotype_high double precision,
    copy_number character varying(255),
    five_prime_lr_pcr character varying(255),
    three_prime_lr_pcr character varying(255),
    thawing character varying(255),
    loa character varying(255),
    loxp character varying(255),
    lacz character varying(255),
    chr1 character varying(255),
    chr8a character varying(255),
    chr8b character varying(255),
    chr11a character varying(255),
    chr11b character varying(255),
    chry character varying(255),
    es_cell_id integer,
    es_cell_distribution_centre_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    loxp_srpcr character varying(255),
    unspecified_repository_testing character varying(255),
    neo_qpcr character varying(255)
);


--
-- Name: targ_rep_distribution_qcs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_distribution_qcs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_distribution_qcs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_distribution_qcs_id_seq OWNED BY targ_rep_distribution_qcs.id;


--
-- Name: targ_rep_es_cell_distribution_centres; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE targ_rep_es_cell_distribution_centres (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: targ_rep_es_cell_distribution_centres_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_es_cell_distribution_centres_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_es_cell_distribution_centres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_es_cell_distribution_centres_id_seq OWNED BY targ_rep_es_cell_distribution_centres.id;


--
-- Name: targ_rep_es_cells; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE targ_rep_es_cells (
    id integer NOT NULL,
    allele_id integer NOT NULL,
    targeting_vector_id integer,
    parental_cell_line character varying(255),
    mgi_allele_symbol_superscript character varying(75),
    name character varying(100) NOT NULL,
    comment character varying(255),
    contact character varying(255),
    ikmc_project_id character varying(255),
    mgi_allele_id character varying(50),
    pipeline_id integer,
    report_to_public boolean DEFAULT true NOT NULL,
    strain character varying(25),
    production_qc_five_prime_screen character varying(255),
    production_qc_three_prime_screen character varying(255),
    production_qc_loxp_screen character varying(255),
    production_qc_loss_of_allele character varying(255),
    production_qc_vector_integrity character varying(255),
    user_qc_map_test character varying(255),
    user_qc_karyotype character varying(255),
    user_qc_tv_backbone_assay character varying(255),
    user_qc_loxp_confirmation character varying(255),
    user_qc_southern_blot character varying(255),
    user_qc_loss_of_wt_allele character varying(255),
    user_qc_neo_count_qpcr character varying(255),
    user_qc_lacz_sr_pcr character varying(255),
    user_qc_mutant_specific_sr_pcr character varying(255),
    user_qc_five_prime_cassette_integrity character varying(255),
    user_qc_neo_sr_pcr character varying(255),
    user_qc_five_prime_lr_pcr character varying(255),
    user_qc_three_prime_lr_pcr character varying(255),
    user_qc_comment text,
    allele_type character varying(2),
    mutation_subtype character varying(100),
    allele_symbol_superscript_template character varying(75),
    legacy_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    production_centre_auto_update boolean DEFAULT true,
    user_qc_loxp_srpcr_and_sequencing character varying(255),
    user_qc_karyotype_spread character varying(255),
    user_qc_karyotype_pcr character varying(255),
    user_qc_mouse_clinic_id integer,
    user_qc_chr1 character varying(255),
    user_qc_chr11 character varying(255),
    user_qc_chr8 character varying(255),
    user_qc_chry character varying(255),
    user_qc_lacz_qpcr character varying(255)
);


--
-- Name: targ_rep_mutation_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE targ_rep_mutation_types (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(100) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: targ_rep_es_cell_mutation_types; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW targ_rep_es_cell_mutation_types AS
    SELECT es.id AS es_cell_id, types.name AS mutation_type FROM ((targ_rep_es_cells es LEFT JOIN targ_rep_alleles al ON ((es.allele_id = al.id))) LEFT JOIN targ_rep_mutation_types types ON ((al.mutation_type_id = types.id)));


--
-- Name: targ_rep_es_cells_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_es_cells_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_es_cells_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_es_cells_id_seq OWNED BY targ_rep_es_cells.id;


--
-- Name: targ_rep_genbank_files; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE targ_rep_genbank_files (
    id integer NOT NULL,
    allele_id integer NOT NULL,
    escell_clone text,
    targeting_vector text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: targ_rep_genbank_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_genbank_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_genbank_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_genbank_files_id_seq OWNED BY targ_rep_genbank_files.id;


--
-- Name: targ_rep_mutation_methods; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE targ_rep_mutation_methods (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(100) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: targ_rep_mutation_methods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_mutation_methods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_mutation_methods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_mutation_methods_id_seq OWNED BY targ_rep_mutation_methods.id;


--
-- Name: targ_rep_mutation_subtypes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE targ_rep_mutation_subtypes (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(100) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: targ_rep_mutation_subtypes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_mutation_subtypes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_mutation_subtypes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_mutation_subtypes_id_seq OWNED BY targ_rep_mutation_subtypes.id;


--
-- Name: targ_rep_mutation_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_mutation_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_mutation_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_mutation_types_id_seq OWNED BY targ_rep_mutation_types.id;


--
-- Name: targ_rep_pipelines; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE targ_rep_pipelines (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    legacy_id integer,
    report_to_public boolean DEFAULT true,
    gene_trap boolean DEFAULT false
);


--
-- Name: targ_rep_pipelines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_pipelines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_pipelines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_pipelines_id_seq OWNED BY targ_rep_pipelines.id;


--
-- Name: targ_rep_targeting_vectors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE targ_rep_targeting_vectors (
    id integer NOT NULL,
    allele_id integer NOT NULL,
    name character varying(255) NOT NULL,
    ikmc_project_id character varying(255),
    intermediate_vector character varying(255),
    report_to_public boolean NOT NULL,
    pipeline_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: targ_rep_targeting_vectors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_targeting_vectors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_targeting_vectors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_targeting_vectors_id_seq OWNED BY targ_rep_targeting_vectors.id;


--
-- Name: tracking_goals; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tracking_goals (
    id integer NOT NULL,
    production_centre_id integer,
    date date,
    goal_type character varying(255),
    goal integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tracking_goals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tracking_goals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tracking_goals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tracking_goals_id_seq OWNED BY tracking_goals.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    email character varying(255) DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying(128) DEFAULT ''::character varying NOT NULL,
    remember_created_at timestamp without time zone,
    production_centre_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    name character varying(255),
    is_contactable boolean DEFAULT false,
    reset_password_token character varying(255),
    reset_password_sent_at timestamp without time zone,
    es_cell_distribution_centre_id integer,
    legacy_id integer,
    admin boolean DEFAULT false
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY audits ALTER COLUMN id SET DEFAULT nextval('audits_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY centres ALTER COLUMN id SET DEFAULT nextval('centres_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY consortia ALTER COLUMN id SET DEFAULT nextval('consortia_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY contacts ALTER COLUMN id SET DEFAULT nextval('contacts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY deleter_strains ALTER COLUMN id SET DEFAULT nextval('deleter_strains_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY deposited_materials ALTER COLUMN id SET DEFAULT nextval('deposited_materials_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY email_templates ALTER COLUMN id SET DEFAULT nextval('email_templates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY es_cells ALTER COLUMN id SET DEFAULT nextval('es_cells_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY genes ALTER COLUMN id SET DEFAULT nextval('genes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY intermediate_report ALTER COLUMN id SET DEFAULT nextval('intermediate_report_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempt_distribution_centres ALTER COLUMN id SET DEFAULT nextval('mi_attempt_distribution_centres_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempt_status_stamps ALTER COLUMN id SET DEFAULT nextval('mi_attempt_status_stamps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempt_statuses ALTER COLUMN id SET DEFAULT nextval('mi_attempt_statuses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts ALTER COLUMN id SET DEFAULT nextval('mi_attempts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plan_es_cell_qcs ALTER COLUMN id SET DEFAULT nextval('mi_plan_es_cell_qcs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plan_es_qc_comments ALTER COLUMN id SET DEFAULT nextval('mi_plan_es_qc_comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plan_priorities ALTER COLUMN id SET DEFAULT nextval('mi_plan_priorities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plan_status_stamps ALTER COLUMN id SET DEFAULT nextval('mi_plan_status_stamps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plan_statuses ALTER COLUMN id SET DEFAULT nextval('mi_plan_statuses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plan_sub_projects ALTER COLUMN id SET DEFAULT nextval('mi_plan_sub_projects_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plans ALTER COLUMN id SET DEFAULT nextval('mi_plans_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY new_intermediate_report ALTER COLUMN id SET DEFAULT nextval('new_intermediate_report_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications ALTER COLUMN id SET DEFAULT nextval('notifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotype_attempt_distribution_centres ALTER COLUMN id SET DEFAULT nextval('phenotype_attempt_distribution_centres_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotype_attempt_status_stamps ALTER COLUMN id SET DEFAULT nextval('phenotype_attempt_status_stamps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotype_attempt_statuses ALTER COLUMN id SET DEFAULT nextval('phenotype_attempt_statuses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotype_attempts ALTER COLUMN id SET DEFAULT nextval('phenotype_attempts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY pipelines ALTER COLUMN id SET DEFAULT nextval('pipelines_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY production_goals ALTER COLUMN id SET DEFAULT nextval('production_goals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY qc_results ALTER COLUMN id SET DEFAULT nextval('qc_results_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY report_caches ALTER COLUMN id SET DEFAULT nextval('report_caches_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY solr_update_queue_items ALTER COLUMN id SET DEFAULT nextval('solr_update_queue_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY strains ALTER COLUMN id SET DEFAULT nextval('strains_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_alleles ALTER COLUMN id SET DEFAULT nextval('targ_rep_alleles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_centre_pipelines ALTER COLUMN id SET DEFAULT nextval('targ_rep_centre_pipelines_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_distribution_qcs ALTER COLUMN id SET DEFAULT nextval('targ_rep_distribution_qcs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_es_cell_distribution_centres ALTER COLUMN id SET DEFAULT nextval('targ_rep_es_cell_distribution_centres_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_es_cells ALTER COLUMN id SET DEFAULT nextval('targ_rep_es_cells_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_genbank_files ALTER COLUMN id SET DEFAULT nextval('targ_rep_genbank_files_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_mutation_methods ALTER COLUMN id SET DEFAULT nextval('targ_rep_mutation_methods_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_mutation_subtypes ALTER COLUMN id SET DEFAULT nextval('targ_rep_mutation_subtypes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_mutation_types ALTER COLUMN id SET DEFAULT nextval('targ_rep_mutation_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_pipelines ALTER COLUMN id SET DEFAULT nextval('targ_rep_pipelines_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_targeting_vectors ALTER COLUMN id SET DEFAULT nextval('targ_rep_targeting_vectors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tracking_goals ALTER COLUMN id SET DEFAULT nextval('tracking_goals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: audits_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY audits
    ADD CONSTRAINT audits_pkey PRIMARY KEY (id);


--
-- Name: centres_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY centres
    ADD CONSTRAINT centres_pkey PRIMARY KEY (id);


--
-- Name: consortia_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY consortia
    ADD CONSTRAINT consortia_pkey PRIMARY KEY (id);


--
-- Name: contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: deleter_strains_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY deleter_strains
    ADD CONSTRAINT deleter_strains_pkey PRIMARY KEY (id);


--
-- Name: deposited_materials_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY deposited_materials
    ADD CONSTRAINT deposited_materials_pkey PRIMARY KEY (id);


--
-- Name: email_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY email_templates
    ADD CONSTRAINT email_templates_pkey PRIMARY KEY (id);


--
-- Name: es_cells_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY es_cells
    ADD CONSTRAINT es_cells_pkey PRIMARY KEY (id);


--
-- Name: genes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY genes
    ADD CONSTRAINT genes_pkey PRIMARY KEY (id);


--
-- Name: intermediate_report_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY intermediate_report
    ADD CONSTRAINT intermediate_report_pkey PRIMARY KEY (id);


--
-- Name: mi_attempt_distribution_centres_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mi_attempt_distribution_centres
    ADD CONSTRAINT mi_attempt_distribution_centres_pkey PRIMARY KEY (id);


--
-- Name: mi_attempt_status_stamps_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mi_attempt_status_stamps
    ADD CONSTRAINT mi_attempt_status_stamps_pkey PRIMARY KEY (id);


--
-- Name: mi_attempt_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mi_attempt_statuses
    ADD CONSTRAINT mi_attempt_statuses_pkey PRIMARY KEY (id);


--
-- Name: mi_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_pkey PRIMARY KEY (id);


--
-- Name: mi_plan_es_cell_qcs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mi_plan_es_cell_qcs
    ADD CONSTRAINT mi_plan_es_cell_qcs_pkey PRIMARY KEY (id);


--
-- Name: mi_plan_es_qc_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mi_plan_es_qc_comments
    ADD CONSTRAINT mi_plan_es_qc_comments_pkey PRIMARY KEY (id);


--
-- Name: mi_plan_priorities_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mi_plan_priorities
    ADD CONSTRAINT mi_plan_priorities_pkey PRIMARY KEY (id);


--
-- Name: mi_plan_status_stamps_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mi_plan_status_stamps
    ADD CONSTRAINT mi_plan_status_stamps_pkey PRIMARY KEY (id);


--
-- Name: mi_plan_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mi_plan_statuses
    ADD CONSTRAINT mi_plan_statuses_pkey PRIMARY KEY (id);


--
-- Name: mi_plan_sub_projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mi_plan_sub_projects
    ADD CONSTRAINT mi_plan_sub_projects_pkey PRIMARY KEY (id);


--
-- Name: mi_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mi_plans
    ADD CONSTRAINT mi_plans_pkey PRIMARY KEY (id);


--
-- Name: new_intermediate_report_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY new_intermediate_report
    ADD CONSTRAINT new_intermediate_report_pkey PRIMARY KEY (id);


--
-- Name: notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: phenotype_attempt_distribution_centres_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phenotype_attempt_distribution_centres
    ADD CONSTRAINT phenotype_attempt_distribution_centres_pkey PRIMARY KEY (id);


--
-- Name: phenotype_attempt_status_stamps_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phenotype_attempt_status_stamps
    ADD CONSTRAINT phenotype_attempt_status_stamps_pkey PRIMARY KEY (id);


--
-- Name: phenotype_attempt_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phenotype_attempt_statuses
    ADD CONSTRAINT phenotype_attempt_statuses_pkey PRIMARY KEY (id);


--
-- Name: phenotype_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phenotype_attempts
    ADD CONSTRAINT phenotype_attempts_pkey PRIMARY KEY (id);


--
-- Name: pipelines_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pipelines
    ADD CONSTRAINT pipelines_pkey PRIMARY KEY (id);


--
-- Name: production_goals_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY production_goals
    ADD CONSTRAINT production_goals_pkey PRIMARY KEY (id);


--
-- Name: qc_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY qc_results
    ADD CONSTRAINT qc_results_pkey PRIMARY KEY (id);


--
-- Name: report_caches_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY report_caches
    ADD CONSTRAINT report_caches_pkey PRIMARY KEY (id);


--
-- Name: solr_update_queue_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY solr_update_queue_items
    ADD CONSTRAINT solr_update_queue_items_pkey PRIMARY KEY (id);


--
-- Name: strains_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY strains
    ADD CONSTRAINT strains_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_alleles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY targ_rep_alleles
    ADD CONSTRAINT targ_rep_alleles_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_centre_pipelines_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY targ_rep_centre_pipelines
    ADD CONSTRAINT targ_rep_centre_pipelines_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_distribution_qcs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY targ_rep_distribution_qcs
    ADD CONSTRAINT targ_rep_distribution_qcs_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_es_cell_distribution_centres_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY targ_rep_es_cell_distribution_centres
    ADD CONSTRAINT targ_rep_es_cell_distribution_centres_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_es_cells_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY targ_rep_es_cells
    ADD CONSTRAINT targ_rep_es_cells_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_genbank_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY targ_rep_genbank_files
    ADD CONSTRAINT targ_rep_genbank_files_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_mutation_methods_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY targ_rep_mutation_methods
    ADD CONSTRAINT targ_rep_mutation_methods_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_mutation_subtypes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY targ_rep_mutation_subtypes
    ADD CONSTRAINT targ_rep_mutation_subtypes_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_mutation_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY targ_rep_mutation_types
    ADD CONSTRAINT targ_rep_mutation_types_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_pipelines_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY targ_rep_pipelines
    ADD CONSTRAINT targ_rep_pipelines_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_targeting_vectors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY targ_rep_targeting_vectors
    ADD CONSTRAINT targ_rep_targeting_vectors_pkey PRIMARY KEY (id);


--
-- Name: tracking_goals_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tracking_goals
    ADD CONSTRAINT tracking_goals_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: associated_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX associated_index ON audits USING btree (associated_id, associated_type);


--
-- Name: auditable_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX auditable_index ON audits USING btree (auditable_id, auditable_type);


--
-- Name: es_cells_allele_id_fk; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX es_cells_allele_id_fk ON targ_rep_es_cells USING btree (allele_id);


--
-- Name: es_cells_pipeline_id_fk; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX es_cells_pipeline_id_fk ON targ_rep_es_cells USING btree (pipeline_id);


--
-- Name: genbank_files_allele_id_fk; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX genbank_files_allele_id_fk ON targ_rep_genbank_files USING btree (allele_id);


--
-- Name: index_audits_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_audits_on_created_at ON audits USING btree (created_at);


--
-- Name: index_centres_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_centres_on_name ON centres USING btree (name);


--
-- Name: index_consortia_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_consortia_on_name ON consortia USING btree (name);


--
-- Name: index_contacts_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_contacts_on_email ON contacts USING btree (email);


--
-- Name: index_deposited_materials_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_deposited_materials_on_name ON deposited_materials USING btree (name);


--
-- Name: index_distribution_qcs_centre_es_cell; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_distribution_qcs_centre_es_cell ON targ_rep_distribution_qcs USING btree (es_cell_distribution_centre_id, es_cell_id);


--
-- Name: index_es_cells_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_es_cells_on_name ON es_cells USING btree (name);


--
-- Name: index_genes_on_marker_symbol; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_genes_on_marker_symbol ON genes USING btree (marker_symbol);


--
-- Name: index_genes_on_mgi_accession_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_genes_on_mgi_accession_id ON genes USING btree (mgi_accession_id);


--
-- Name: index_mi_attempt_statuses_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_mi_attempt_statuses_on_name ON mi_attempt_statuses USING btree (name);


--
-- Name: index_mi_attempts_on_colony_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_mi_attempts_on_colony_name ON mi_attempts USING btree (colony_name);


--
-- Name: index_mi_plan_es_qc_comments_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_mi_plan_es_qc_comments_on_name ON mi_plan_es_qc_comments USING btree (name);


--
-- Name: index_mi_plan_priorities_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_mi_plan_priorities_on_name ON mi_plan_priorities USING btree (name);


--
-- Name: index_mi_plan_statuses_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_mi_plan_statuses_on_name ON mi_plan_statuses USING btree (name);


--
-- Name: index_one_status_stamp_per_status_and_mi_attempt; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_one_status_stamp_per_status_and_mi_attempt ON mi_attempt_status_stamps USING btree (status_id, mi_attempt_id);


--
-- Name: index_one_status_stamp_per_status_and_mi_plan; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_one_status_stamp_per_status_and_mi_plan ON mi_plan_status_stamps USING btree (status_id, mi_plan_id);


--
-- Name: index_one_status_stamp_per_status_and_phenotype_attempt; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_one_status_stamp_per_status_and_phenotype_attempt ON phenotype_attempt_status_stamps USING btree (status_id, phenotype_attempt_id);


--
-- Name: index_phenotype_attempts_on_colony_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_phenotype_attempts_on_colony_name ON phenotype_attempts USING btree (colony_name);


--
-- Name: index_pipelines_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_pipelines_on_name ON pipelines USING btree (name);


--
-- Name: index_production_goals_on_consortium_id_and_year_and_month; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_production_goals_on_consortium_id_and_year_and_month ON production_goals USING btree (consortium_id, year, month);


--
-- Name: index_qc_results_on_description; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_qc_results_on_description ON qc_results USING btree (description);


--
-- Name: index_report_caches_on_name_and_format; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_report_caches_on_name_and_format ON report_caches USING btree (name, format);


--
-- Name: index_solr_update_queue_items_on_allele_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_solr_update_queue_items_on_allele_id ON solr_update_queue_items USING btree (allele_id);


--
-- Name: index_solr_update_queue_items_on_mi_attempt_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_solr_update_queue_items_on_mi_attempt_id ON solr_update_queue_items USING btree (mi_attempt_id);


--
-- Name: index_solr_update_queue_items_on_phenotype_attempt_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_solr_update_queue_items_on_phenotype_attempt_id ON solr_update_queue_items USING btree (phenotype_attempt_id);


--
-- Name: index_strains_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_strains_on_name ON strains USING btree (name);


--
-- Name: index_targ_rep_pipelines_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_targ_rep_pipelines_on_name ON targ_rep_pipelines USING btree (name);


--
-- Name: index_targvec; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_targvec ON targ_rep_targeting_vectors USING btree (name);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: mi_plan_logical_key; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX mi_plan_logical_key ON mi_plans USING btree (gene_id, consortium_id, production_centre_id, sub_project_id, is_bespoke_allele, is_conditional_allele, is_deletion_allele, is_cre_knock_in_allele, is_cre_bac_allele, conditional_tm1c, phenotype_only);


--
-- Name: targ_rep_index_es_cells_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX targ_rep_index_es_cells_on_name ON targ_rep_es_cells USING btree (name);


--
-- Name: targeting_vectors_allele_id_fk; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX targeting_vectors_allele_id_fk ON targ_rep_targeting_vectors USING btree (allele_id);


--
-- Name: targeting_vectors_pipeline_id_fk; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX targeting_vectors_pipeline_id_fk ON targ_rep_targeting_vectors USING btree (pipeline_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: user_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX user_index ON audits USING btree (user_id, user_type);


--
-- Name: mi_attempt_distribution_centres_centre_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempt_distribution_centres
    ADD CONSTRAINT mi_attempt_distribution_centres_centre_id_fk FOREIGN KEY (centre_id) REFERENCES centres(id);


--
-- Name: mi_attempt_distribution_centres_deposited_material_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempt_distribution_centres
    ADD CONSTRAINT mi_attempt_distribution_centres_deposited_material_id_fk FOREIGN KEY (deposited_material_id) REFERENCES deposited_materials(id);


--
-- Name: mi_attempt_distribution_centres_mi_attempt_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempt_distribution_centres
    ADD CONSTRAINT mi_attempt_distribution_centres_mi_attempt_id_fk FOREIGN KEY (mi_attempt_id) REFERENCES mi_attempts(id);


--
-- Name: mi_attempt_status_stamps_mi_attempt_status_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempt_status_stamps
    ADD CONSTRAINT mi_attempt_status_stamps_mi_attempt_status_id_fk FOREIGN KEY (status_id) REFERENCES mi_attempt_statuses(id);


--
-- Name: mi_attempts_blast_strain_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_blast_strain_id_fk FOREIGN KEY (blast_strain_id) REFERENCES strains(id);


--
-- Name: mi_attempts_colony_background_strain_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_colony_background_strain_id_fk FOREIGN KEY (colony_background_strain_id) REFERENCES strains(id);


--
-- Name: mi_attempts_mi_attempt_status_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_mi_attempt_status_id_fk FOREIGN KEY (status_id) REFERENCES mi_attempt_statuses(id);


--
-- Name: mi_attempts_mi_plan_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_mi_plan_id_fk FOREIGN KEY (mi_plan_id) REFERENCES mi_plans(id);


--
-- Name: mi_attempts_qc_critical_region_qpcr_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_qc_critical_region_qpcr_id_fk FOREIGN KEY (qc_critical_region_qpcr_id) REFERENCES qc_results(id);


--
-- Name: mi_attempts_qc_five_prime_cassette_integrity_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_qc_five_prime_cassette_integrity_id_fk FOREIGN KEY (qc_five_prime_cassette_integrity_id) REFERENCES qc_results(id);


--
-- Name: mi_attempts_qc_five_prime_lr_pcr_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_qc_five_prime_lr_pcr_id_fk FOREIGN KEY (qc_five_prime_lr_pcr_id) REFERENCES qc_results(id);


--
-- Name: mi_attempts_qc_homozygous_loa_sr_pcr_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_qc_homozygous_loa_sr_pcr_id_fk FOREIGN KEY (qc_homozygous_loa_sr_pcr_id) REFERENCES qc_results(id);


--
-- Name: mi_attempts_qc_lacz_sr_pcr_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_qc_lacz_sr_pcr_id_fk FOREIGN KEY (qc_lacz_sr_pcr_id) REFERENCES qc_results(id);


--
-- Name: mi_attempts_qc_loa_qpcr_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_qc_loa_qpcr_id_fk FOREIGN KEY (qc_loa_qpcr_id) REFERENCES qc_results(id);


--
-- Name: mi_attempts_qc_loxp_confirmation_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_qc_loxp_confirmation_id_fk FOREIGN KEY (qc_loxp_confirmation_id) REFERENCES qc_results(id);


--
-- Name: mi_attempts_qc_loxp_srpcr_and_sequencing_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_qc_loxp_srpcr_and_sequencing_id_fk FOREIGN KEY (qc_loxp_srpcr_and_sequencing_id) REFERENCES qc_results(id);


--
-- Name: mi_attempts_qc_loxp_srpcr_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_qc_loxp_srpcr_id_fk FOREIGN KEY (qc_loxp_srpcr_id) REFERENCES qc_results(id);


--
-- Name: mi_attempts_qc_mutant_specific_sr_pcr_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_qc_mutant_specific_sr_pcr_id_fk FOREIGN KEY (qc_mutant_specific_sr_pcr_id) REFERENCES qc_results(id);


--
-- Name: mi_attempts_qc_neo_count_qpcr_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_qc_neo_count_qpcr_id_fk FOREIGN KEY (qc_neo_count_qpcr_id) REFERENCES qc_results(id);


--
-- Name: mi_attempts_qc_neo_sr_pcr_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_qc_neo_sr_pcr_id_fk FOREIGN KEY (qc_neo_sr_pcr_id) REFERENCES qc_results(id);


--
-- Name: mi_attempts_qc_southern_blot_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_qc_southern_blot_id_fk FOREIGN KEY (qc_southern_blot_id) REFERENCES qc_results(id);


--
-- Name: mi_attempts_qc_three_prime_lr_pcr_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_qc_three_prime_lr_pcr_id_fk FOREIGN KEY (qc_three_prime_lr_pcr_id) REFERENCES qc_results(id);


--
-- Name: mi_attempts_qc_tv_backbone_assay_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_qc_tv_backbone_assay_id_fk FOREIGN KEY (qc_tv_backbone_assay_id) REFERENCES qc_results(id);


--
-- Name: mi_attempts_test_cross_strain_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_test_cross_strain_id_fk FOREIGN KEY (test_cross_strain_id) REFERENCES strains(id);


--
-- Name: mi_attempts_updated_by_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_updated_by_id_fk FOREIGN KEY (updated_by_id) REFERENCES users(id);


--
-- Name: mi_plan_es_cell_qcs_mi_plan_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plan_es_cell_qcs
    ADD CONSTRAINT mi_plan_es_cell_qcs_mi_plan_id_fk FOREIGN KEY (mi_plan_id) REFERENCES mi_plans(id);


--
-- Name: mi_plan_status_stamps_mi_plan_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plan_status_stamps
    ADD CONSTRAINT mi_plan_status_stamps_mi_plan_id_fk FOREIGN KEY (mi_plan_id) REFERENCES mi_plans(id);


--
-- Name: mi_plan_status_stamps_mi_plan_status_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plan_status_stamps
    ADD CONSTRAINT mi_plan_status_stamps_mi_plan_status_id_fk FOREIGN KEY (status_id) REFERENCES mi_plan_statuses(id);


--
-- Name: mi_plans_consortium_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plans
    ADD CONSTRAINT mi_plans_consortium_id_fk FOREIGN KEY (consortium_id) REFERENCES consortia(id);


--
-- Name: mi_plans_es_qc_comment_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plans
    ADD CONSTRAINT mi_plans_es_qc_comment_id_fk FOREIGN KEY (es_qc_comment_id) REFERENCES mi_plan_es_qc_comments(id);


--
-- Name: mi_plans_gene_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plans
    ADD CONSTRAINT mi_plans_gene_id_fk FOREIGN KEY (gene_id) REFERENCES genes(id);


--
-- Name: mi_plans_mi_plan_priority_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plans
    ADD CONSTRAINT mi_plans_mi_plan_priority_id_fk FOREIGN KEY (priority_id) REFERENCES mi_plan_priorities(id);


--
-- Name: mi_plans_mi_plan_status_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plans
    ADD CONSTRAINT mi_plans_mi_plan_status_id_fk FOREIGN KEY (status_id) REFERENCES mi_plan_statuses(id);


--
-- Name: mi_plans_production_centre_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plans
    ADD CONSTRAINT mi_plans_production_centre_id_fk FOREIGN KEY (production_centre_id) REFERENCES centres(id);


--
-- Name: mi_plans_sub_project_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plans
    ADD CONSTRAINT mi_plans_sub_project_id_fk FOREIGN KEY (sub_project_id) REFERENCES mi_plan_sub_projects(id);


--
-- Name: notifications_contact_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_contact_id_fk FOREIGN KEY (contact_id) REFERENCES contacts(id);


--
-- Name: notifications_gene_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_gene_id_fk FOREIGN KEY (gene_id) REFERENCES genes(id);


--
-- Name: phenotype_attempt_distribution_centres_centre_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotype_attempt_distribution_centres
    ADD CONSTRAINT phenotype_attempt_distribution_centres_centre_id_fk FOREIGN KEY (centre_id) REFERENCES centres(id);


--
-- Name: phenotype_attempt_distribution_centres_deposited_material_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotype_attempt_distribution_centres
    ADD CONSTRAINT phenotype_attempt_distribution_centres_deposited_material_id_fk FOREIGN KEY (deposited_material_id) REFERENCES deposited_materials(id);


--
-- Name: phenotype_attempt_distribution_centres_phenotype_attempt_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotype_attempt_distribution_centres
    ADD CONSTRAINT phenotype_attempt_distribution_centres_phenotype_attempt_id_fk FOREIGN KEY (phenotype_attempt_id) REFERENCES phenotype_attempts(id);


--
-- Name: phenotype_attempt_status_stamps_phenotype_attempt_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotype_attempt_status_stamps
    ADD CONSTRAINT phenotype_attempt_status_stamps_phenotype_attempt_id_fk FOREIGN KEY (phenotype_attempt_id) REFERENCES phenotype_attempts(id);


--
-- Name: phenotype_attempt_status_stamps_status_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotype_attempt_status_stamps
    ADD CONSTRAINT phenotype_attempt_status_stamps_status_id_fk FOREIGN KEY (status_id) REFERENCES phenotype_attempt_statuses(id);


--
-- Name: phenotype_attempts_colony_background_strain_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotype_attempts
    ADD CONSTRAINT phenotype_attempts_colony_background_strain_id_fk FOREIGN KEY (colony_background_strain_id) REFERENCES strains(id);


--
-- Name: phenotype_attempts_mi_plan_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotype_attempts
    ADD CONSTRAINT phenotype_attempts_mi_plan_id_fk FOREIGN KEY (mi_plan_id) REFERENCES mi_plans(id);


--
-- Name: phenotype_attempts_status_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotype_attempts
    ADD CONSTRAINT phenotype_attempts_status_id_fk FOREIGN KEY (status_id) REFERENCES phenotype_attempt_statuses(id);


--
-- Name: targ_rep_es_cells_user_qc_mouse_clinic_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_es_cells
    ADD CONSTRAINT targ_rep_es_cells_user_qc_mouse_clinic_id_fk FOREIGN KEY (user_qc_mouse_clinic_id) REFERENCES centres(id);


--
-- Name: users_es_cell_distribution_centre_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_es_cell_distribution_centre_id_fk FOREIGN KEY (es_cell_distribution_centre_id) REFERENCES targ_rep_es_cell_distribution_centres(id);


--
-- PostgreSQL database dump complete
--

INSERT INTO schema_migrations (version) VALUES ('20110315000000');

INSERT INTO schema_migrations (version) VALUES ('20110419101838');

INSERT INTO schema_migrations (version) VALUES ('20110419105759');

INSERT INTO schema_migrations (version) VALUES ('20110419120000');

INSERT INTO schema_migrations (version) VALUES ('20110420010000');

INSERT INTO schema_migrations (version) VALUES ('20110421095045');

INSERT INTO schema_migrations (version) VALUES ('20110421140001');

INSERT INTO schema_migrations (version) VALUES ('20110421140011');

INSERT INTO schema_migrations (version) VALUES ('20110421150000');

INSERT INTO schema_migrations (version) VALUES ('20110527121721');

INSERT INTO schema_migrations (version) VALUES ('20110721091844');

INSERT INTO schema_migrations (version) VALUES ('20110725141713');

INSERT INTO schema_migrations (version) VALUES ('20110727110911');

INSERT INTO schema_migrations (version) VALUES ('20110802094958');

INSERT INTO schema_migrations (version) VALUES ('20110915000000');

INSERT INTO schema_migrations (version) VALUES ('20110921000001');

INSERT INTO schema_migrations (version) VALUES ('20110922103626');

INSERT INTO schema_migrations (version) VALUES ('20111014000000');

INSERT INTO schema_migrations (version) VALUES ('20111018103514');

INSERT INTO schema_migrations (version) VALUES ('20111026000000');

INSERT INTO schema_migrations (version) VALUES ('20111101000000');

INSERT INTO schema_migrations (version) VALUES ('20111101173922');

INSERT INTO schema_migrations (version) VALUES ('20111121113850');

INSERT INTO schema_migrations (version) VALUES ('20111123172943');

INSERT INTO schema_migrations (version) VALUES ('20111201183938');

INSERT INTO schema_migrations (version) VALUES ('20111202105057');

INSERT INTO schema_migrations (version) VALUES ('20111208000000');

INSERT INTO schema_migrations (version) VALUES ('20111209081222');

INSERT INTO schema_migrations (version) VALUES ('20111209084000');

INSERT INTO schema_migrations (version) VALUES ('20111215090406');

INSERT INTO schema_migrations (version) VALUES ('20111220165606');

INSERT INTO schema_migrations (version) VALUES ('20120109122259');

INSERT INTO schema_migrations (version) VALUES ('20120112154903');

INSERT INTO schema_migrations (version) VALUES ('20120206184229');

INSERT INTO schema_migrations (version) VALUES ('20120209111757');

INSERT INTO schema_migrations (version) VALUES ('20120214105538');

INSERT INTO schema_migrations (version) VALUES ('20120215164706');

INSERT INTO schema_migrations (version) VALUES ('20120301123306');

INSERT INTO schema_migrations (version) VALUES ('20120313170227');

INSERT INTO schema_migrations (version) VALUES ('20120313171943');

INSERT INTO schema_migrations (version) VALUES ('20120323153009');

INSERT INTO schema_migrations (version) VALUES ('20120323162146');

INSERT INTO schema_migrations (version) VALUES ('20120328110402');

INSERT INTO schema_migrations (version) VALUES ('20120411132445');

INSERT INTO schema_migrations (version) VALUES ('20120508123747');

INSERT INTO schema_migrations (version) VALUES ('20120515144152');

INSERT INTO schema_migrations (version) VALUES ('20120517151408');

INSERT INTO schema_migrations (version) VALUES ('20120522123605');

INSERT INTO schema_migrations (version) VALUES ('20120524110807');

INSERT INTO schema_migrations (version) VALUES ('20120524111009');

INSERT INTO schema_migrations (version) VALUES ('20120612153941');

INSERT INTO schema_migrations (version) VALUES ('20120613132955');

INSERT INTO schema_migrations (version) VALUES ('20120615105644');

INSERT INTO schema_migrations (version) VALUES ('20120615105954');

INSERT INTO schema_migrations (version) VALUES ('20120618150335');

INSERT INTO schema_migrations (version) VALUES ('20120627135453');

INSERT INTO schema_migrations (version) VALUES ('20120710161237');

INSERT INTO schema_migrations (version) VALUES ('20120716095705');

INSERT INTO schema_migrations (version) VALUES ('20120716095723');

INSERT INTO schema_migrations (version) VALUES ('20120720150932');

INSERT INTO schema_migrations (version) VALUES ('20120721093257');

INSERT INTO schema_migrations (version) VALUES ('20120723110726');

INSERT INTO schema_migrations (version) VALUES ('20120724163920');

INSERT INTO schema_migrations (version) VALUES ('20120725145204');

INSERT INTO schema_migrations (version) VALUES ('20120731091856');

INSERT INTO schema_migrations (version) VALUES ('20120807115108');

INSERT INTO schema_migrations (version) VALUES ('20120917153914');

INSERT INTO schema_migrations (version) VALUES ('20120924160841');

INSERT INTO schema_migrations (version) VALUES ('20120926124146');

INSERT INTO schema_migrations (version) VALUES ('20121017152352');

INSERT INTO schema_migrations (version) VALUES ('20121030082321');

INSERT INTO schema_migrations (version) VALUES ('20121030084149');

INSERT INTO schema_migrations (version) VALUES ('20121030084658');

INSERT INTO schema_migrations (version) VALUES ('20121030085127');

INSERT INTO schema_migrations (version) VALUES ('20121030085445');

INSERT INTO schema_migrations (version) VALUES ('20121030091506');

INSERT INTO schema_migrations (version) VALUES ('20121030112955');

INSERT INTO schema_migrations (version) VALUES ('20121030120806');

INSERT INTO schema_migrations (version) VALUES ('20121030120918');

INSERT INTO schema_migrations (version) VALUES ('20121030121338');

INSERT INTO schema_migrations (version) VALUES ('20121030122923');

INSERT INTO schema_migrations (version) VALUES ('20121031124856');

INSERT INTO schema_migrations (version) VALUES ('20121105082318');

INSERT INTO schema_migrations (version) VALUES ('20121105114415');

INSERT INTO schema_migrations (version) VALUES ('20121106130926');

INSERT INTO schema_migrations (version) VALUES ('20121106154008');

INSERT INTO schema_migrations (version) VALUES ('20121107080657');

INSERT INTO schema_migrations (version) VALUES ('20121109144055');

INSERT INTO schema_migrations (version) VALUES ('20121113112851');

INSERT INTO schema_migrations (version) VALUES ('20121123145151');

INSERT INTO schema_migrations (version) VALUES ('20121129000000');

INSERT INTO schema_migrations (version) VALUES ('20121203164954');

INSERT INTO schema_migrations (version) VALUES ('20130102155346');

INSERT INTO schema_migrations (version) VALUES ('20130103092321');

INSERT INTO schema_migrations (version) VALUES ('20130103113250');

INSERT INTO schema_migrations (version) VALUES ('20130107104030');

INSERT INTO schema_migrations (version) VALUES ('20130109114249');

INSERT INTO schema_migrations (version) VALUES ('20130110103728');

INSERT INTO schema_migrations (version) VALUES ('20130110140730');

INSERT INTO schema_migrations (version) VALUES ('20130118115026');

INSERT INTO schema_migrations (version) VALUES ('20130123092333');

INSERT INTO schema_migrations (version) VALUES ('20130123114424');

INSERT INTO schema_migrations (version) VALUES ('20130130121045');

INSERT INTO schema_migrations (version) VALUES ('20130205114839');

INSERT INTO schema_migrations (version) VALUES ('20130219102215');

INSERT INTO schema_migrations (version) VALUES ('20130307114011');

INSERT INTO schema_migrations (version) VALUES ('20130318163354');

INSERT INTO schema_migrations (version) VALUES ('20130322100056');

INSERT INTO schema_migrations (version) VALUES ('20130322154023');

INSERT INTO schema_migrations (version) VALUES ('20130326153718');

INSERT INTO schema_migrations (version) VALUES ('20130403100056');

INSERT INTO schema_migrations (version) VALUES ('20130417142254');

INSERT INTO schema_migrations (version) VALUES ('20130422152724');

INSERT INTO schema_migrations (version) VALUES ('20130423142230');

INSERT INTO schema_migrations (version) VALUES ('20130424100316');

INSERT INTO schema_migrations (version) VALUES ('20130502132202');

INSERT INTO schema_migrations (version) VALUES ('20130502150234');

INSERT INTO schema_migrations (version) VALUES ('20130510104125');

INSERT INTO schema_migrations (version) VALUES ('20130510111914');

INSERT INTO schema_migrations (version) VALUES ('20130510144848');

INSERT INTO schema_migrations (version) VALUES ('20130520101048');

INSERT INTO schema_migrations (version) VALUES ('20130521115232');

INSERT INTO schema_migrations (version) VALUES ('20130523144937');

INSERT INTO schema_migrations (version) VALUES ('20130523154950');

INSERT INTO schema_migrations (version) VALUES ('20130523161221');

INSERT INTO schema_migrations (version) VALUES ('20130524110125');

INSERT INTO schema_migrations (version) VALUES ('20130528083431');

INSERT INTO schema_migrations (version) VALUES ('20130528131803');

INSERT INTO schema_migrations (version) VALUES ('20130528142149');

INSERT INTO schema_migrations (version) VALUES ('20130610142149');