--
-- PostgreSQL database dump
--

\restrict R4hPq1pf6GS93q7TsjcO5lLavdjzlB7DzGpZGIaZizfm5jUEnKCdaaRc6RDUY3A

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: dbnext; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA IF NOT EXISTS dbnext;


ALTER SCHEMA dbnext OWNER TO postgres;


--
-- Required extensions (installed in public; referenced by dbnext objects).
-- Not emitted by pg_dump -n; added so a fresh database loads in one step.
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;

--
-- Name: check_project_record_has_project(); Type: FUNCTION; Schema: dbnext; Owner: postgres
--

CREATE FUNCTION dbnext.check_project_record_has_project() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM dbnext.project_record_project
        WHERE id_project_record = NEW.id
    ) THEN
        RAISE EXCEPTION 'project_record % has no associated project (project_record_project entry required)', NEW.id
            USING ERRCODE = 'foreign_key_violation';
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION dbnext.check_project_record_has_project() OWNER TO postgres;

--
-- Name: FUNCTION check_project_record_has_project(); Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON FUNCTION dbnext.check_project_record_has_project() IS 'Deferred constraint trigger function: a project_record must have at least one project_record_project association by transaction commit.';


--
-- Name: prevent_last_determination_delete(); Type: FUNCTION; Schema: dbnext; Owner: postgres
--

CREATE FUNCTION dbnext.prevent_last_determination_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM dbnext.project_record WHERE id = OLD.id_project_record
    ) THEN
        RETURN NULL;
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM dbnext.project_record_determination
        WHERE id_project_record = OLD.id_project_record
    ) THEN
        RAISE EXCEPTION 'Cannot remove the last determination for project_record %', OLD.id_project_record
            USING ERRCODE = 'restrict_violation';
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION dbnext.prevent_last_determination_delete() OWNER TO postgres;

--
-- Name: FUNCTION prevent_last_determination_delete(); Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON FUNCTION dbnext.prevent_last_determination_delete() IS 'Deferred constraint trigger function: once a project_record has determinations, the last one cannot be removed (by DELETE or by re-pointing via UPDATE) while the record exists.';


--
-- Name: prevent_last_project_record_project_delete(); Type: FUNCTION; Schema: dbnext; Owner: postgres
--

CREATE FUNCTION dbnext.prevent_last_project_record_project_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM dbnext.project_record WHERE id = OLD.id_project_record
    ) THEN
        RETURN NULL;
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM dbnext.project_record_project
        WHERE id_project_record = OLD.id_project_record
    ) THEN
        RAISE EXCEPTION 'Cannot remove the last project association for project_record %', OLD.id_project_record
            USING ERRCODE = 'restrict_violation';
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION dbnext.prevent_last_project_record_project_delete() OWNER TO postgres;

--
-- Name: FUNCTION prevent_last_project_record_project_delete(); Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON FUNCTION dbnext.prevent_last_project_record_project_delete() IS 'Deferred constraint trigger function: blocks removing (by DELETE or by re-pointing via UPDATE) the last project association of a still-existing project_record.';


--
-- Name: set_date_modify(); Type: FUNCTION; Schema: dbnext; Owner: postgres
--

CREATE FUNCTION dbnext.set_date_modify() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.date_modify IS NOT DISTINCT FROM OLD.date_modify THEN
        NEW.date_modify := now();
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION dbnext.set_date_modify() OWNER TO postgres;

--
-- Name: FUNCTION set_date_modify(); Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON FUNCTION dbnext.set_date_modify() IS 'Stamps date_modify with now() on UPDATE unless the caller set it explicitly.';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: data_definition; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.data_definition (
    id bigint NOT NULL,
    id_group bigint NOT NULL,
    name text NOT NULL,
    type text NOT NULL,
    validation_regex text,
    description text NOT NULL,
    rank integer NOT NULL
);


ALTER TABLE dbnext.data_definition OWNER TO postgres;

--
-- Name: COLUMN data_definition.type; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.data_definition.type IS 'type of custom field. int, string, date';


--
-- Name: COLUMN data_definition.validation_regex; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.data_definition.validation_regex IS 'definition of the regex that controls which value is allowed';


--
-- Name: COLUMN data_definition.rank; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.data_definition.rank IS 'Rank that can be used as position in designs';


--
-- Name: data_definition_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.data_definition_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.data_definition_id_seq OWNER TO postgres;

--
-- Name: data_definition_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.data_definition_id_seq OWNED BY dbnext.data_definition.id;


--
-- Name: data_group; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.data_group (
    id bigint NOT NULL,
    id_parent bigint,
    name text NOT NULL,
    description text NOT NULL
);


ALTER TABLE dbnext.data_group OWNER TO postgres;

--
-- Name: TABLE data_group; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.data_group IS 'in his table groups are organized that contains custom fields. see data_definition';


--
-- Name: COLUMN data_group.id_parent; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.data_group.id_parent IS 'data_groups can be organized hierarchically';


--
-- Name: data_group_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.data_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.data_group_id_seq OWNER TO postgres;

--
-- Name: data_group_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.data_group_id_seq OWNED BY dbnext.data_group.id;


--
-- Name: data_predefined_values; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.data_predefined_values (
    id bigint NOT NULL,
    id_data_definition bigint NOT NULL,
    value character varying[]
);


ALTER TABLE dbnext.data_predefined_values OWNER TO postgres;

--
-- Name: data_predefined_values_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.data_predefined_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.data_predefined_values_id_seq OWNER TO postgres;

--
-- Name: data_predefined_values_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.data_predefined_values_id_seq OWNED BY dbnext.data_predefined_values.id;


--
-- Name: external_identifier; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.external_identifier (
    id bigint NOT NULL,
    source text NOT NULL,
    identifier text NOT NULL,
    url text,
    description text NOT NULL
);


ALTER TABLE dbnext.external_identifier OWNER TO postgres;

--
-- Name: TABLE external_identifier; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.external_identifier IS 'Stores references to external systems (GBIF, BOLD, GenBank, Index Herbariorum, etc.)';


--
-- Name: COLUMN external_identifier.source; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.external_identifier.source IS 'Name of the external system, e.g. GBIF, GenBank, BOLD';


--
-- Name: COLUMN external_identifier.identifier; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.external_identifier.identifier IS 'The identifier value in the external system';


--
-- Name: COLUMN external_identifier.url; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.external_identifier.url IS 'Optional URL to the resource in the external system';


--
-- Name: external_identifier_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.external_identifier_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.external_identifier_id_seq OWNER TO postgres;

--
-- Name: external_identifier_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.external_identifier_id_seq OWNED BY dbnext.external_identifier.id;


--
-- Name: external_identifier_item; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.external_identifier_item (
    id bigint NOT NULL,
    id_external_identifier bigint NOT NULL,
    id_item bigint NOT NULL
);


ALTER TABLE dbnext.external_identifier_item OWNER TO postgres;

--
-- Name: TABLE external_identifier_item; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.external_identifier_item IS 'Links external identifiers to items (taxa, etc.)';


--
-- Name: external_identifier_item_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.external_identifier_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.external_identifier_item_id_seq OWNER TO postgres;

--
-- Name: external_identifier_item_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.external_identifier_item_id_seq OWNED BY dbnext.external_identifier_item.id;


--
-- Name: external_identifier_project_record; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.external_identifier_project_record (
    id bigint NOT NULL,
    id_external_identifier bigint CONSTRAINT external_identifier_project_rec_id_external_identifier_not_null NOT NULL,
    id_project_record bigint NOT NULL
);


ALTER TABLE dbnext.external_identifier_project_record OWNER TO postgres;

--
-- Name: TABLE external_identifier_project_record; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.external_identifier_project_record IS 'Links external identifiers to specimens/observations in project_record';


--
-- Name: external_identifier_project_record_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.external_identifier_project_record_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.external_identifier_project_record_id_seq OWNER TO postgres;

--
-- Name: external_identifier_project_record_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.external_identifier_project_record_id_seq OWNED BY dbnext.external_identifier_project_record.id;


--
-- Name: item; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.item (
    id bigint NOT NULL,
    language character(2) NOT NULL,
    data jsonb NOT NULL,
    name character varying(1000) NOT NULL,
    created_by bigint,
    modified_by bigint,
    date_create timestamp with time zone DEFAULT now() NOT NULL,
    date_modify timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE dbnext.item OWNER TO postgres;

--
-- Name: TABLE item; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.item IS 'items are subjects that can be recorded. see: project_record table. items are organized in lists. see: item_list table and item_list_item table';


--
-- Name: item_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.item_id_seq OWNER TO postgres;

--
-- Name: item_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.item_id_seq OWNED BY dbnext.item.id;


--
-- Name: item_keyword; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.item_keyword (
    id bigint NOT NULL,
    id_item bigint NOT NULL,
    id_keyword bigint NOT NULL
);


ALTER TABLE dbnext.item_keyword OWNER TO postgres;

--
-- Name: item_keyword_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.item_keyword_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.item_keyword_id_seq OWNER TO postgres;

--
-- Name: item_keyword_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.item_keyword_id_seq OWNED BY dbnext.item_keyword.id;


--
-- Name: item_list; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.item_list (
    id bigint NOT NULL,
    name text NOT NULL,
    description text NOT NULL,
    id_parent bigint,
    data jsonb NOT NULL,
    item_list_id_data_group bigint NOT NULL,
    item_id_data_group bigint NOT NULL,
    created_by bigint,
    modified_by bigint,
    date_create timestamp with time zone DEFAULT now() NOT NULL,
    date_modify timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE dbnext.item_list OWNER TO postgres;

--
-- Name: TABLE item_list; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.item_list IS 'in this table lists are organized that contains items. see item table and item_list_item table';


--
-- Name: COLUMN item_list.data; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.item_list.data IS 'can contains custom fields';


--
-- Name: COLUMN item_list.item_list_id_data_group; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.item_list.item_list_id_data_group IS 'reference to the data_group in which custom fields are defined in the data field of item_list.';


--
-- Name: COLUMN item_list.item_id_data_group; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.item_list.item_id_data_group IS 'reference to the data group in which custom fields are defined that are used in the data field of the item table in a specific list in item_list.';


--
-- Name: item_list_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.item_list_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.item_list_id_seq OWNER TO postgres;

--
-- Name: item_list_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.item_list_id_seq OWNED BY dbnext.item_list.id;


--
-- Name: item_list_item; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.item_list_item (
    id bigint NOT NULL,
    id_item_list bigint NOT NULL,
    id_item bigint NOT NULL,
    id_parent bigint,
    id_identity bigint,
    id_accepted bigint,
    created_by bigint,
    modified_by bigint,
    date_create timestamp with time zone DEFAULT now() NOT NULL,
    date_modify timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE dbnext.item_list_item OWNER TO postgres;

--
-- Name: TABLE item_list_item; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.item_list_item IS 'this table serves as the relation between item and item_list table. One item can be part of many lists in item_list. Also the parent of the id_item is defined by id_parent which points to id in item table.';


--
-- Name: COLUMN item_list_item.id_item_list; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.item_list_item.id_item_list IS 'reference to the item_list.id';


--
-- Name: COLUMN item_list_item.id_item; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.item_list_item.id_item IS 'reference to the item.id table';


--
-- Name: COLUMN item_list_item.id_parent; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.item_list_item.id_parent IS 'Self-referencing FK to item_list_item.id. Defines the parent within the same list hierarchy (e.g., taxonomic tree).';


--
-- Name: COLUMN item_list_item.id_identity; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.item_list_item.id_identity IS 'identifies the identity of this item. Items with the same id_identity are considered synonymous.';


--
-- Name: COLUMN item_list_item.id_accepted; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.item_list_item.id_accepted IS 'id_accepted points to the list accepted item_list_item.id.';


--
-- Name: item_list_item_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.item_list_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.item_list_item_id_seq OWNER TO postgres;

--
-- Name: item_list_item_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.item_list_item_id_seq OWNED BY dbnext.item_list_item.id;


--
-- Name: item_list_item_keyword; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.item_list_item_keyword (
    id bigint NOT NULL,
    id_item_list_item bigint NOT NULL,
    id_keyword bigint NOT NULL
);


ALTER TABLE dbnext.item_list_item_keyword OWNER TO postgres;

--
-- Name: item_list_item_keyword_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.item_list_item_keyword_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.item_list_item_keyword_id_seq OWNER TO postgres;

--
-- Name: item_list_item_keyword_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.item_list_item_keyword_id_seq OWNED BY dbnext.item_list_item_keyword.id;


--
-- Name: item_list_keyword; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.item_list_keyword (
    id bigint NOT NULL,
    id_item_list bigint NOT NULL,
    id_keyword bigint NOT NULL
);


ALTER TABLE dbnext.item_list_keyword OWNER TO postgres;

--
-- Name: TABLE item_list_keyword; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.item_list_keyword IS 'relation between keyword and item_list table. one to many';


--
-- Name: item_list_keyword_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.item_list_keyword_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.item_list_keyword_id_seq OWNER TO postgres;

--
-- Name: item_list_keyword_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.item_list_keyword_id_seq OWNED BY dbnext.item_list_keyword.id;


--
-- Name: keyword; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.keyword (
    id bigint NOT NULL,
    id_parent bigint,
    name text NOT NULL,
    description text,
    data jsonb,
    id_data_group bigint,
    rank integer,
    created_by bigint,
    modified_by bigint,
    date_create timestamp with time zone DEFAULT now() NOT NULL,
    date_modify timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE dbnext.keyword OWNER TO postgres;

--
-- Name: keyword_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.keyword_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.keyword_id_seq OWNER TO postgres;

--
-- Name: keyword_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.keyword_id_seq OWNED BY dbnext.keyword.id;


--
-- Name: media; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.media (
    id bigint NOT NULL,
    id_data_group bigint NOT NULL,
    data jsonb NOT NULL,
    file_path text NOT NULL,
    mime_type character varying(255) NOT NULL,
    description text NOT NULL,
    created_by bigint,
    modified_by bigint,
    date_create timestamp with time zone DEFAULT now() NOT NULL,
    date_modify timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE dbnext.media OWNER TO postgres;

--
-- Name: TABLE media; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.media IS 'Stores references to media files (images, documents, etc.) associated with records or items';


--
-- Name: COLUMN media.file_path; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.media.file_path IS 'Path or URL to the media file (actual file storage is external)';


--
-- Name: media_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.media_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.media_id_seq OWNER TO postgres;

--
-- Name: media_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.media_id_seq OWNED BY dbnext.media.id;


--
-- Name: media_item; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.media_item (
    id bigint NOT NULL,
    id_media bigint NOT NULL,
    id_item bigint NOT NULL
);


ALTER TABLE dbnext.media_item OWNER TO postgres;

--
-- Name: TABLE media_item; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.media_item IS 'Links media to taxa/items';


--
-- Name: media_item_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.media_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.media_item_id_seq OWNER TO postgres;

--
-- Name: media_item_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.media_item_id_seq OWNED BY dbnext.media_item.id;


--
-- Name: project; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.project (
    id bigint NOT NULL,
    id_parent bigint,
    name text NOT NULL,
    description text,
    data jsonb,
    id_data_group bigint,
    record_id_data_group bigint,
    created_by bigint,
    modified_by bigint,
    date_create timestamp with time zone DEFAULT now() NOT NULL,
    date_modify timestamp with time zone DEFAULT now() NOT NULL,
    id_user bigint
);


ALTER TABLE dbnext.project OWNER TO postgres;

--
-- Name: COLUMN project.id_user; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project.id_user IS 'The authority user for this project. One user per project.';


--
-- Name: project_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.project_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.project_id_seq OWNER TO postgres;

--
-- Name: project_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_id_seq OWNED BY dbnext.project.id;


--
-- Name: project_item_list; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.project_item_list (
    id bigint NOT NULL,
    id_project bigint NOT NULL,
    id_item_list bigint NOT NULL,
    preferred boolean DEFAULT false NOT NULL
);


ALTER TABLE dbnext.project_item_list OWNER TO postgres;

--
-- Name: TABLE project_item_list; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.project_item_list IS 'here is defined which item_list.id (item lists) are allowed to use in projects';


--
-- Name: project_item_list_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.project_item_list_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.project_item_list_id_seq OWNER TO postgres;

--
-- Name: project_item_list_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_item_list_id_seq OWNED BY dbnext.project_item_list.id;


--
-- Name: project_keyword; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.project_keyword (
    id bigint NOT NULL,
    id_project bigint NOT NULL,
    id_keyword bigint NOT NULL
);


ALTER TABLE dbnext.project_keyword OWNER TO postgres;

--
-- Name: TABLE project_keyword; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.project_keyword IS 'relation between keyword and project table. one to many';


--
-- Name: project_keyword_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.project_keyword_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.project_keyword_id_seq OWNER TO postgres;

--
-- Name: project_keyword_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_keyword_id_seq OWNED BY dbnext.project_keyword.id;


--
-- Name: project_record; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.project_record (
    id bigint NOT NULL,
    data jsonb NOT NULL,
    date_create timestamp with time zone DEFAULT now() NOT NULL,
    date_modify timestamp with time zone DEFAULT now() NOT NULL,
    created_by bigint,
    modified_by bigint,
    date_start timestamp with time zone,
    date_end timestamp with time zone,
    date_range tstzrange GENERATED ALWAYS AS (
CASE
    WHEN ((date_start IS NOT NULL) OR (date_end IS NOT NULL)) THEN tstzrange(date_start, date_end, '[]'::text)
    ELSE NULL::tstzrange
END) STORED
);


ALTER TABLE dbnext.project_record OWNER TO postgres;

--
-- Name: TABLE project_record; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.project_record IS 'this is the central table that contains the purpose subjects of items ';


--
-- Name: COLUMN project_record.date_range; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record.date_range IS 'Generated range column from date_start and date_end. Enables range operators (@>, &&, etc.) for temporal queries.';


--
-- Name: project_record_data_group; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.project_record_data_group (
    id bigint NOT NULL,
    id_project bigint NOT NULL,
    id_data_group bigint NOT NULL
);


ALTER TABLE dbnext.project_record_data_group OWNER TO postgres;

--
-- Name: TABLE project_record_data_group; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.project_record_data_group IS 'Custom data fields in project_record are referenced by this table.It is possible to assign more than one data_group to a project_record';


--
-- Name: project_record_data_group_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.project_record_data_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.project_record_data_group_id_seq OWNER TO postgres;

--
-- Name: project_record_data_group_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_data_group_id_seq OWNED BY dbnext.project_record_data_group.id;


--
-- Name: project_record_determination; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.project_record_determination (
    id bigint NOT NULL,
    id_project_record bigint NOT NULL,
    id_item_list_item bigint NOT NULL,
    preferred boolean DEFAULT false NOT NULL,
    date_create timestamp with time zone DEFAULT now() NOT NULL,
    date_modify timestamp with time zone DEFAULT now() NOT NULL,
    determined_by bigint,
    determined_by_name text,
    determination_date timestamp with time zone,
    id_determination_method bigint,
    remarks text,
    id_user bigint
);


ALTER TABLE dbnext.project_record_determination OWNER TO postgres;

--
-- Name: COLUMN project_record_determination.determined_by; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_determination.determined_by IS 'FK to user table. The user who made the determination. Use determined_by_name for historical determiners not in the user table.';


--
-- Name: COLUMN project_record_determination.determined_by_name; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_determination.determined_by_name IS 'Free text name of the determiner. Used for historical determiners not registered as users.';


--
-- Name: COLUMN project_record_determination.determination_date; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_determination.determination_date IS 'Date when the actual determination was made (not the row creation date).';


--
-- Name: COLUMN project_record_determination.id_determination_method; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_determination.id_determination_method IS 'FK to keyword table. Defines the method used (e.g. morphological, molecular). Managed as keywords.';


--
-- Name: COLUMN project_record_determination.remarks; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_determination.remarks IS 'Free text remarks about the determination.';


--
-- Name: COLUMN project_record_determination.id_user; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_determination.id_user IS 'The user who made the determination (determinavit). Nullable for historical records with unknown determinator.';


--
-- Name: project_record_determination_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.project_record_determination_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.project_record_determination_id_seq OWNER TO postgres;

--
-- Name: project_record_determination_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_determination_id_seq OWNED BY dbnext.project_record_determination.id;


--
-- Name: project_record_determination_keyword; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.project_record_determination_keyword (
    id bigint NOT NULL,
    id_project_record_determination bigint CONSTRAINT project_record_determinatio_id_project_record_determin_not_null NOT NULL,
    id_keyword bigint NOT NULL
);


ALTER TABLE dbnext.project_record_determination_keyword OWNER TO postgres;

--
-- Name: TABLE project_record_determination_keyword; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.project_record_determination_keyword IS 'relation between keyword and project_record_determination table. one to many';


--
-- Name: project_record_determination_keyword_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.project_record_determination_keyword_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.project_record_determination_keyword_id_seq OWNER TO postgres;

--
-- Name: project_record_determination_keyword_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_determination_keyword_id_seq OWNED BY dbnext.project_record_determination_keyword.id;


--
-- Name: project_record_geometry; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.project_record_geometry (
    id bigint NOT NULL,
    id_record bigint NOT NULL,
    geom public.geometry(Geometry,4326)
);


ALTER TABLE dbnext.project_record_geometry OWNER TO postgres;

--
-- Name: project_record_geometry_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.project_record_geometry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.project_record_geometry_id_seq OWNER TO postgres;

--
-- Name: project_record_geometry_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_geometry_id_seq OWNED BY dbnext.project_record_geometry.id;


--
-- Name: project_record_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.project_record_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.project_record_id_seq OWNER TO postgres;

--
-- Name: project_record_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_id_seq OWNED BY dbnext.project_record.id;


--
-- Name: project_record_identifier; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.project_record_identifier (
    id bigint NOT NULL,
    id_project_record bigint NOT NULL,
    id_keyword bigint NOT NULL,
    value text NOT NULL
);


ALTER TABLE dbnext.project_record_identifier OWNER TO postgres;

--
-- Name: TABLE project_record_identifier; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.project_record_identifier IS 'Stores multiple identifiers per record (catalog number, accession number, field number, barcode, etc.). The identifier type is defined by id_keyword.';


--
-- Name: COLUMN project_record_identifier.id_keyword; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_identifier.id_keyword IS 'Defines the identifier type (e.g. Catalog Number, Accession Number). References keyword table.';


--
-- Name: COLUMN project_record_identifier.value; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_identifier.value IS 'The actual identifier value (e.g. the catalog number string)';


--
-- Name: project_record_identifier_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.project_record_identifier_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.project_record_identifier_id_seq OWNER TO postgres;

--
-- Name: project_record_identifier_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_identifier_id_seq OWNED BY dbnext.project_record_identifier.id;


--
-- Name: project_record_keyword; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.project_record_keyword (
    id bigint NOT NULL,
    id_project_record bigint NOT NULL,
    id_keyword bigint NOT NULL,
    description text
);


ALTER TABLE dbnext.project_record_keyword OWNER TO postgres;

--
-- Name: COLUMN project_record_keyword.description; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_keyword.description IS 'Example of how to use this field:
We have a keyword naming "ToDo" and  we build a relation to a project_record. Then we can add a description what exactly is to do in future on this record.';


--
-- Name: project_record_keyword_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.project_record_keyword_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.project_record_keyword_id_seq OWNER TO postgres;

--
-- Name: project_record_keyword_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_keyword_id_seq OWNED BY dbnext.project_record_keyword.id;


--
-- Name: project_record_media; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.project_record_media (
    id bigint NOT NULL,
    id_media bigint NOT NULL,
    id_project_record bigint NOT NULL
);


ALTER TABLE dbnext.project_record_media OWNER TO postgres;

--
-- Name: TABLE project_record_media; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.project_record_media IS 'Links media to specimens/observations in project_record';


--
-- Name: project_record_media_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.project_record_media_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.project_record_media_id_seq OWNER TO postgres;

--
-- Name: project_record_media_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_media_id_seq OWNED BY dbnext.project_record_media.id;


--
-- Name: project_record_parent; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.project_record_parent (
    id bigint NOT NULL,
    id_project_record bigint NOT NULL,
    id_project_record_parent bigint NOT NULL,
    id_keyword bigint,
    description text
);


ALTER TABLE dbnext.project_record_parent OWNER TO postgres;

--
-- Name: COLUMN project_record_parent.id_keyword; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_parent.id_keyword IS 'Optional keyword defining the type of hierarchical relationship';


--
-- Name: COLUMN project_record_parent.description; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_parent.description IS 'Optional free-text description of the specific relationship';


--
-- Name: project_record_parent_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.project_record_parent_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.project_record_parent_id_seq OWNER TO postgres;

--
-- Name: project_record_parent_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_parent_id_seq OWNED BY dbnext.project_record_parent.id;


--
-- Name: project_record_project; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.project_record_project (
    id bigint NOT NULL,
    id_project_record bigint NOT NULL,
    id_project bigint NOT NULL
);


ALTER TABLE dbnext.project_record_project OWNER TO postgres;

--
-- Name: project_record_project_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.project_record_project_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.project_record_project_id_seq OWNER TO postgres;

--
-- Name: project_record_project_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_project_id_seq OWNED BY dbnext.project_record_project.id;


--
-- Name: project_record_record; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.project_record_record (
    id bigint NOT NULL,
    id_project_record_1 bigint NOT NULL,
    id_project_record_2 bigint NOT NULL,
    id_keyword bigint NOT NULL,
    description text
);


ALTER TABLE dbnext.project_record_record OWNER TO postgres;

--
-- Name: TABLE project_record_record; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.project_record_record IS 'Horizontal (peer-to-peer) relationships between project records, qualified by a keyword defining the relationship type. Rows are directed (record 1 -> record 2). For symmetric relationship types (e.g. "duplicate of"), store a single row with id_project_record_1 < id_project_record_2 by application convention; do not store the mirrored pair.';


--
-- Name: COLUMN project_record_record.id_project_record_1; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_record.id_project_record_1 IS 'Source project_record.id of the relationship';


--
-- Name: COLUMN project_record_record.id_project_record_2; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_record.id_project_record_2 IS 'Target project_record.id of the relationship';


--
-- Name: COLUMN project_record_record.id_keyword; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_record.id_keyword IS 'Keyword defining the type of relationship (e.g. duplicate of, host of, same event)';


--
-- Name: COLUMN project_record_record.description; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_record.description IS 'Optional free-text description of the specific relationship';


--
-- Name: project_record_record_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.project_record_record_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.project_record_record_id_seq OWNER TO postgres;

--
-- Name: project_record_record_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_record_id_seq OWNED BY dbnext.project_record_record.id;


--
-- Name: project_record_user; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.project_record_user (
    id bigint NOT NULL,
    id_user bigint NOT NULL,
    id_project_record bigint NOT NULL
);


ALTER TABLE dbnext.project_record_user OWNER TO postgres;

--
-- Name: project_record_user_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.project_record_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.project_record_user_id_seq OWNER TO postgres;

--
-- Name: project_record_user_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_user_id_seq OWNED BY dbnext.project_record_user.id;


--
-- Name: project_record_user_keyword; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.project_record_user_keyword (
    id bigint NOT NULL,
    id_project_record_user bigint NOT NULL,
    id_keyword bigint NOT NULL
);


ALTER TABLE dbnext.project_record_user_keyword OWNER TO postgres;

--
-- Name: project_record_user_keyword_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.project_record_user_keyword_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.project_record_user_keyword_id_seq OWNER TO postgres;

--
-- Name: project_record_user_keyword_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_user_keyword_id_seq OWNED BY dbnext.project_record_user_keyword.id;


--
-- Name: users; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.users (
    id bigint NOT NULL,
    name character varying(1000) NOT NULL,
    nickname character varying(250),
    email character varying(500),
    status character varying(30),
    password character varying(128) DEFAULT ''::character varying NOT NULL,
    last_login timestamp with time zone,
    is_active boolean DEFAULT true NOT NULL,
    is_staff boolean DEFAULT false NOT NULL,
    is_superuser boolean DEFAULT false NOT NULL
);


ALTER TABLE dbnext.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.users_id_seq OWNED BY dbnext.users.id;


--
-- Name: users_keyword; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.users_keyword (
    id_user bigint NOT NULL,
    id_keyword bigint NOT NULL,
    id bigint NOT NULL
);


ALTER TABLE dbnext.users_keyword OWNER TO postgres;

--
-- Name: users_keyword_id_seq; Type: SEQUENCE; Schema: dbnext; Owner: postgres
--

CREATE SEQUENCE dbnext.users_keyword_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dbnext.users_keyword_id_seq OWNER TO postgres;

--
-- Name: users_keyword_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.users_keyword_id_seq OWNED BY dbnext.users_keyword.id;


--
-- Name: data_definition id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.data_definition ALTER COLUMN id SET DEFAULT nextval('dbnext.data_definition_id_seq'::regclass);


--
-- Name: data_group id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.data_group ALTER COLUMN id SET DEFAULT nextval('dbnext.data_group_id_seq'::regclass);


--
-- Name: data_predefined_values id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.data_predefined_values ALTER COLUMN id SET DEFAULT nextval('dbnext.data_predefined_values_id_seq'::regclass);


--
-- Name: external_identifier id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier ALTER COLUMN id SET DEFAULT nextval('dbnext.external_identifier_id_seq'::regclass);


--
-- Name: external_identifier_item id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier_item ALTER COLUMN id SET DEFAULT nextval('dbnext.external_identifier_item_id_seq'::regclass);


--
-- Name: external_identifier_project_record id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier_project_record ALTER COLUMN id SET DEFAULT nextval('dbnext.external_identifier_project_record_id_seq'::regclass);


--
-- Name: item id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item ALTER COLUMN id SET DEFAULT nextval('dbnext.item_id_seq'::regclass);


--
-- Name: item_keyword id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_keyword ALTER COLUMN id SET DEFAULT nextval('dbnext.item_keyword_id_seq'::regclass);


--
-- Name: item_list id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list ALTER COLUMN id SET DEFAULT nextval('dbnext.item_list_id_seq'::regclass);


--
-- Name: item_list_item id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item ALTER COLUMN id SET DEFAULT nextval('dbnext.item_list_item_id_seq'::regclass);


--
-- Name: item_list_item_keyword id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item_keyword ALTER COLUMN id SET DEFAULT nextval('dbnext.item_list_item_keyword_id_seq'::regclass);


--
-- Name: item_list_keyword id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_keyword ALTER COLUMN id SET DEFAULT nextval('dbnext.item_list_keyword_id_seq'::regclass);


--
-- Name: keyword id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.keyword ALTER COLUMN id SET DEFAULT nextval('dbnext.keyword_id_seq'::regclass);


--
-- Name: media id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.media ALTER COLUMN id SET DEFAULT nextval('dbnext.media_id_seq'::regclass);


--
-- Name: media_item id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.media_item ALTER COLUMN id SET DEFAULT nextval('dbnext.media_item_id_seq'::regclass);


--
-- Name: project id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project ALTER COLUMN id SET DEFAULT nextval('dbnext.project_id_seq'::regclass);


--
-- Name: project_item_list id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_item_list ALTER COLUMN id SET DEFAULT nextval('dbnext.project_item_list_id_seq'::regclass);


--
-- Name: project_keyword id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_keyword ALTER COLUMN id SET DEFAULT nextval('dbnext.project_keyword_id_seq'::regclass);


--
-- Name: project_record id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_id_seq'::regclass);


--
-- Name: project_record_data_group id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_data_group ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_data_group_id_seq'::regclass);


--
-- Name: project_record_determination id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_determination ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_determination_id_seq'::regclass);


--
-- Name: project_record_determination_keyword id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_determination_keyword ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_determination_keyword_id_seq'::regclass);


--
-- Name: project_record_geometry id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_geometry ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_geometry_id_seq'::regclass);


--
-- Name: project_record_identifier id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_identifier ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_identifier_id_seq'::regclass);


--
-- Name: project_record_keyword id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_keyword ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_keyword_id_seq'::regclass);


--
-- Name: project_record_media id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_media ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_media_id_seq'::regclass);


--
-- Name: project_record_parent id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_parent ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_parent_id_seq'::regclass);


--
-- Name: project_record_project id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_project ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_project_id_seq'::regclass);


--
-- Name: project_record_record id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_record ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_record_id_seq'::regclass);


--
-- Name: project_record_user id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_user ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_user_id_seq'::regclass);


--
-- Name: project_record_user_keyword id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_user_keyword ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_user_keyword_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.users ALTER COLUMN id SET DEFAULT nextval('dbnext.users_id_seq'::regclass);


--
-- Name: users_keyword id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.users_keyword ALTER COLUMN id SET DEFAULT nextval('dbnext.users_keyword_id_seq'::regclass);


--
-- Name: data_definition data_definition_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.data_definition
    ADD CONSTRAINT data_definition_pkey PRIMARY KEY (id);


--
-- Name: data_group data_group_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.data_group
    ADD CONSTRAINT data_group_pkey PRIMARY KEY (id);


--
-- Name: data_predefined_values data_predefined_values_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.data_predefined_values
    ADD CONSTRAINT data_predefined_values_pkey PRIMARY KEY (id);


--
-- Name: external_identifier_item external_identifier_item_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier_item
    ADD CONSTRAINT external_identifier_item_pkey PRIMARY KEY (id);


--
-- Name: external_identifier external_identifier_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier
    ADD CONSTRAINT external_identifier_pkey PRIMARY KEY (id);


--
-- Name: external_identifier_project_record external_identifier_project_record_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier_project_record
    ADD CONSTRAINT external_identifier_project_record_pkey PRIMARY KEY (id);


--
-- Name: item_keyword item_keyword_id_item_id_keyword_key; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_keyword
    ADD CONSTRAINT item_keyword_id_item_id_keyword_key UNIQUE (id_item, id_keyword);


--
-- Name: item_keyword item_keyword_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_keyword
    ADD CONSTRAINT item_keyword_pkey PRIMARY KEY (id);


--
-- Name: item_list_item_keyword item_list_item_keyword_id_item_list_item_id_keyword_key; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item_keyword
    ADD CONSTRAINT item_list_item_keyword_id_item_list_item_id_keyword_key UNIQUE (id_item_list_item, id_keyword);


--
-- Name: item_list_item_keyword item_list_item_keyword_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item_keyword
    ADD CONSTRAINT item_list_item_keyword_pkey PRIMARY KEY (id);


--
-- Name: item_list_item item_list_item_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item
    ADD CONSTRAINT item_list_item_pkey PRIMARY KEY (id);


--
-- Name: item_list_keyword item_list_keyword_id_item_list_id_keyword_key; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_keyword
    ADD CONSTRAINT item_list_keyword_id_item_list_id_keyword_key UNIQUE (id_item_list, id_keyword);


--
-- Name: item_list_keyword item_list_keyword_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_keyword
    ADD CONSTRAINT item_list_keyword_pkey PRIMARY KEY (id);


--
-- Name: item_list item_list_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list
    ADD CONSTRAINT item_list_pkey PRIMARY KEY (id);


--
-- Name: item item_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item
    ADD CONSTRAINT item_pkey PRIMARY KEY (id);


--
-- Name: keyword keyword_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.keyword
    ADD CONSTRAINT keyword_pkey PRIMARY KEY (id);


--
-- Name: media_item media_item_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.media_item
    ADD CONSTRAINT media_item_pkey PRIMARY KEY (id);


--
-- Name: media media_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.media
    ADD CONSTRAINT media_pkey PRIMARY KEY (id);


--
-- Name: users_keyword pk_users_keyword; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.users_keyword
    ADD CONSTRAINT pk_users_keyword PRIMARY KEY (id);


--
-- Name: project_item_list project_item_list_id_project_id_item_list_key; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_item_list
    ADD CONSTRAINT project_item_list_id_project_id_item_list_key UNIQUE (id_project, id_item_list);


--
-- Name: project_item_list project_item_list_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_item_list
    ADD CONSTRAINT project_item_list_pkey PRIMARY KEY (id);


--
-- Name: project_keyword project_keyword_id_project_id_keyword_key; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_keyword
    ADD CONSTRAINT project_keyword_id_project_id_keyword_key UNIQUE (id_project, id_keyword);


--
-- Name: project_keyword project_keyword_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_keyword
    ADD CONSTRAINT project_keyword_pkey PRIMARY KEY (id);


--
-- Name: project project_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project
    ADD CONSTRAINT project_pkey PRIMARY KEY (id);


--
-- Name: project_record_data_group project_record_data_group_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_data_group
    ADD CONSTRAINT project_record_data_group_pkey PRIMARY KEY (id);


--
-- Name: project_record_data_group project_record_data_group_project_data_group_key; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_data_group
    ADD CONSTRAINT project_record_data_group_project_data_group_key UNIQUE (id_project, id_data_group);


--
-- Name: project_record_determination_keyword project_record_determination_keyword_det_keyword_key; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_determination_keyword
    ADD CONSTRAINT project_record_determination_keyword_det_keyword_key UNIQUE (id_project_record_determination, id_keyword);


--
-- Name: project_record_determination_keyword project_record_determination_keyword_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_determination_keyword
    ADD CONSTRAINT project_record_determination_keyword_pkey PRIMARY KEY (id);


--
-- Name: project_record_determination project_record_determination_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_determination
    ADD CONSTRAINT project_record_determination_pkey PRIMARY KEY (id);


--
-- Name: project_record_geometry project_record_geometry_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_geometry
    ADD CONSTRAINT project_record_geometry_pkey PRIMARY KEY (id);


--
-- Name: project_record_identifier project_record_identifier_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_identifier
    ADD CONSTRAINT project_record_identifier_pkey PRIMARY KEY (id);


--
-- Name: project_record_keyword project_record_keyword_id_project_record_id_keyword_key; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_keyword
    ADD CONSTRAINT project_record_keyword_id_project_record_id_keyword_key UNIQUE (id_project_record, id_keyword);


--
-- Name: project_record_keyword project_record_keyword_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_keyword
    ADD CONSTRAINT project_record_keyword_pkey PRIMARY KEY (id);


--
-- Name: project_record_media project_record_media_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_media
    ADD CONSTRAINT project_record_media_pkey PRIMARY KEY (id);


--
-- Name: project_record_parent project_record_parent_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_parent
    ADD CONSTRAINT project_record_parent_pkey PRIMARY KEY (id);


--
-- Name: project_record project_record_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record
    ADD CONSTRAINT project_record_pkey PRIMARY KEY (id);


--
-- Name: project_record_project project_record_project_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_project
    ADD CONSTRAINT project_record_project_pkey PRIMARY KEY (id);


--
-- Name: project_record_project project_record_project_record_project_key; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_project
    ADD CONSTRAINT project_record_project_record_project_key UNIQUE (id_project_record, id_project);


--
-- Name: project_record_record project_record_record_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_record
    ADD CONSTRAINT project_record_record_pkey PRIMARY KEY (id);


--
-- Name: project_record_user_keyword project_record_user_keyword_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_user_keyword
    ADD CONSTRAINT project_record_user_keyword_pkey PRIMARY KEY (id);


--
-- Name: project_record_user project_record_user_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_user
    ADD CONSTRAINT project_record_user_pkey PRIMARY KEY (id);


--
-- Name: external_identifier_item uq_external_identifier_item; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier_item
    ADD CONSTRAINT uq_external_identifier_item UNIQUE (id_external_identifier, id_item);


--
-- Name: external_identifier_project_record uq_external_identifier_project_record; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier_project_record
    ADD CONSTRAINT uq_external_identifier_project_record UNIQUE (id_external_identifier, id_project_record);


--
-- Name: external_identifier uq_external_identifier_source_identifier; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier
    ADD CONSTRAINT uq_external_identifier_source_identifier UNIQUE (source, identifier);


--
-- Name: item_list_item uq_item_list_item_id_list; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item
    ADD CONSTRAINT uq_item_list_item_id_list UNIQUE (id, id_item_list);


--
-- Name: CONSTRAINT uq_item_list_item_id_list ON item_list_item; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON CONSTRAINT uq_item_list_item_id_list ON dbnext.item_list_item IS 'Target for the composite FKs that force id_parent / id_identity / id_accepted to reference an entry of the same list.';


--
-- Name: item_list_item uq_item_list_item_list_item; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item
    ADD CONSTRAINT uq_item_list_item_list_item UNIQUE (id_item_list, id_item);


--
-- Name: media_item uq_media_item; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.media_item
    ADD CONSTRAINT uq_media_item UNIQUE (id_media, id_item);


--
-- Name: project_record_identifier uq_project_record_identifier; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_identifier
    ADD CONSTRAINT uq_project_record_identifier UNIQUE (id_project_record, id_keyword, value);


--
-- Name: project_record_media uq_project_record_media; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_media
    ADD CONSTRAINT uq_project_record_media UNIQUE (id_media, id_project_record);


--
-- Name: project_record_parent uq_project_record_parent_pair; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_parent
    ADD CONSTRAINT uq_project_record_parent_pair UNIQUE (id_project_record, id_project_record_parent);


--
-- Name: project_record_record uq_project_record_record_pair; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_record
    ADD CONSTRAINT uq_project_record_record_pair UNIQUE (id_project_record_1, id_project_record_2, id_keyword);


--
-- Name: project_record_user_keyword uq_project_record_user_keyword; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_user_keyword
    ADD CONSTRAINT uq_project_record_user_keyword UNIQUE (id_project_record_user, id_keyword);


--
-- Name: project_record_user uq_project_record_user_pair; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_user
    ADD CONSTRAINT uq_project_record_user_pair UNIQUE (id_user, id_project_record);


--
-- Name: users uq_users_email; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.users
    ADD CONSTRAINT uq_users_email UNIQUE (email);


--
-- Name: users_keyword uq_users_keyword; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.users_keyword
    ADD CONSTRAINT uq_users_keyword UNIQUE (id_user, id_keyword);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: fki_fk_id_accepted_id; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX fki_fk_id_accepted_id ON dbnext.item_list_item USING btree (id_accepted);


--
-- Name: fki_fk_project_record_project_id_project_record; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX fki_fk_project_record_project_id_project_record ON dbnext.project_record_project USING btree (id_project_record);


--
-- Name: fki_fk_project_record_user_keyword_project_record_user; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX fki_fk_project_record_user_keyword_project_record_user ON dbnext.project_record_user_keyword USING btree (id_project_record_user);


--
-- Name: fki_fk_user; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX fki_fk_user ON dbnext.users_keyword USING btree (id_user);


--
-- Name: fki_fk_user_keyword; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX fki_fk_user_keyword ON dbnext.users_keyword USING btree (id_keyword);


--
-- Name: idx_data_group_parent; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_data_group_parent ON dbnext.data_group USING btree (id_parent);


--
-- Name: idx_date_start_date_end; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_date_start_date_end ON dbnext.project_record USING btree (date_start) INCLUDE (date_start, date_end) WITH (deduplicate_items='true');


--
-- Name: idx_dd_group; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_dd_group ON dbnext.data_definition USING btree (id_group);


--
-- Name: idx_ei_identifier; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_ei_identifier ON dbnext.external_identifier USING btree (identifier);


--
-- Name: idx_ei_source; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_ei_source ON dbnext.external_identifier USING btree (source);


--
-- Name: idx_eii_external_identifier; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_eii_external_identifier ON dbnext.external_identifier_item USING btree (id_external_identifier);


--
-- Name: idx_eii_item; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_eii_item ON dbnext.external_identifier_item USING btree (id_item);


--
-- Name: idx_eipr_external_identifier; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_eipr_external_identifier ON dbnext.external_identifier_project_record USING btree (id_external_identifier);


--
-- Name: idx_eipr_project_record; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_eipr_project_record ON dbnext.external_identifier_project_record USING btree (id_project_record);


--
-- Name: idx_ik_keyword; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_ik_keyword ON dbnext.item_keyword USING btree (id_keyword);


--
-- Name: idx_ili_created_by; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_ili_created_by ON dbnext.item_list_item USING btree (created_by);


--
-- Name: idx_ili_identity; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_ili_identity ON dbnext.item_list_item USING btree (id_identity);


--
-- Name: idx_ili_item; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_ili_item ON dbnext.item_list_item USING btree (id_item);


--
-- Name: idx_ili_item_list; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_ili_item_list ON dbnext.item_list_item USING btree (id_item_list);


--
-- Name: idx_ili_modified_by; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_ili_modified_by ON dbnext.item_list_item USING btree (modified_by);


--
-- Name: idx_ili_parent; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_ili_parent ON dbnext.item_list_item USING btree (id_parent);


--
-- Name: idx_ilik_keyword; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_ilik_keyword ON dbnext.item_list_item_keyword USING btree (id_keyword);


--
-- Name: idx_ilk_keyword; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_ilk_keyword ON dbnext.item_list_keyword USING btree (id_keyword);


--
-- Name: idx_item_created_by; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_item_created_by ON dbnext.item USING btree (created_by);


--
-- Name: idx_item_data; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_item_data ON dbnext.item USING gin (data jsonb_path_ops) WITH (fastupdate='true');


--
-- Name: idx_item_list; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_item_list ON dbnext.item_list USING gin (data jsonb_path_ops) WITH (fastupdate='true');


--
-- Name: idx_item_list_created_by; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_item_list_created_by ON dbnext.item_list USING btree (created_by);


--
-- Name: idx_item_list_item_data_group; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_item_list_item_data_group ON dbnext.item_list USING btree (item_id_data_group);


--
-- Name: idx_item_list_list_data_group; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_item_list_list_data_group ON dbnext.item_list USING btree (item_list_id_data_group);


--
-- Name: idx_item_list_modified_by; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_item_list_modified_by ON dbnext.item_list USING btree (modified_by);


--
-- Name: idx_item_list_parent; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_item_list_parent ON dbnext.item_list USING btree (id_parent);


--
-- Name: idx_item_modified_by; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_item_modified_by ON dbnext.item USING btree (modified_by);


--
-- Name: idx_item_name; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_item_name ON dbnext.item USING btree (name);


--
-- Name: idx_item_name_trgm; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_item_name_trgm ON dbnext.item USING gin (name public.gin_trgm_ops);


--
-- Name: idx_keyword; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_keyword ON dbnext.keyword USING gin (data jsonb_path_ops) WITH (fastupdate='true');


--
-- Name: idx_keyword_created_by; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_keyword_created_by ON dbnext.keyword USING btree (created_by);


--
-- Name: idx_keyword_data_group; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_keyword_data_group ON dbnext.keyword USING btree (id_data_group);


--
-- Name: idx_keyword_modified_by; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_keyword_modified_by ON dbnext.keyword USING btree (modified_by);


--
-- Name: idx_keyword_parent; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_keyword_parent ON dbnext.keyword USING btree (id_parent);


--
-- Name: idx_media_created_by; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_media_created_by ON dbnext.media USING btree (created_by);


--
-- Name: idx_media_data; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_media_data ON dbnext.media USING gin (data jsonb_path_ops) WITH (fastupdate='true');


--
-- Name: idx_media_data_group; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_media_data_group ON dbnext.media USING btree (id_data_group);


--
-- Name: idx_media_modified_by; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_media_modified_by ON dbnext.media USING btree (modified_by);


--
-- Name: idx_mi_item; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_mi_item ON dbnext.media_item USING btree (id_item);


--
-- Name: idx_mi_media; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_mi_media ON dbnext.media_item USING btree (id_media);


--
-- Name: idx_pil_item_list; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_pil_item_list ON dbnext.project_item_list USING btree (id_item_list);


--
-- Name: idx_pk_keyword; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_pk_keyword ON dbnext.project_keyword USING btree (id_keyword);


--
-- Name: idx_pk_project; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_pk_project ON dbnext.project_keyword USING btree (id_project);


--
-- Name: idx_pr_created_by; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_pr_created_by ON dbnext.project_record USING btree (created_by);


--
-- Name: idx_pr_modified_by; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_pr_modified_by ON dbnext.project_record USING btree (modified_by);


--
-- Name: idx_prd_determination_method; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prd_determination_method ON dbnext.project_record_determination USING btree (id_determination_method);


--
-- Name: idx_prd_determined_by; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prd_determined_by ON dbnext.project_record_determination USING btree (determined_by);


--
-- Name: idx_prd_item_list_item; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prd_item_list_item ON dbnext.project_record_determination USING btree (id_item_list_item);


--
-- Name: idx_prd_project_record; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prd_project_record ON dbnext.project_record_determination USING btree (id_project_record);


--
-- Name: idx_prd_user; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prd_user ON dbnext.project_record_determination USING btree (id_user);


--
-- Name: idx_prdg_data_group; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prdg_data_group ON dbnext.project_record_data_group USING btree (id_data_group);


--
-- Name: idx_prdk_determination; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prdk_determination ON dbnext.project_record_determination_keyword USING btree (id_project_record_determination);


--
-- Name: idx_prdk_keyword; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prdk_keyword ON dbnext.project_record_determination_keyword USING btree (id_keyword);


--
-- Name: idx_prg_geom; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prg_geom ON dbnext.project_record_geometry USING gist (geom);


--
-- Name: idx_prg_record; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prg_record ON dbnext.project_record_geometry USING btree (id_record);


--
-- Name: idx_pri_keyword; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_pri_keyword ON dbnext.project_record_identifier USING btree (id_keyword);


--
-- Name: idx_pri_project_record; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_pri_project_record ON dbnext.project_record_identifier USING btree (id_project_record);


--
-- Name: idx_pri_value; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_pri_value ON dbnext.project_record_identifier USING btree (value);


--
-- Name: idx_prk_keyword; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prk_keyword ON dbnext.project_record_keyword USING btree (id_keyword);


--
-- Name: idx_prm_media; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prm_media ON dbnext.project_record_media USING btree (id_media);


--
-- Name: idx_prm_project_record; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prm_project_record ON dbnext.project_record_media USING btree (id_project_record);


--
-- Name: idx_project; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_project ON dbnext.project USING gin (data jsonb_path_ops) WITH (fastupdate='true');


--
-- Name: idx_project_created_by; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_project_created_by ON dbnext.project USING btree (created_by);


--
-- Name: idx_project_data_group; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_project_data_group ON dbnext.project USING btree (id_data_group);


--
-- Name: idx_project_modified_by; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_project_modified_by ON dbnext.project USING btree (modified_by);


--
-- Name: idx_project_parent; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_project_parent ON dbnext.project USING btree (id_parent);


--
-- Name: idx_project_record; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_project_record ON dbnext.project_record USING gin (data jsonb_path_ops) WITH (fastupdate='true');


--
-- Name: idx_project_record_date_range; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_project_record_date_range ON dbnext.project_record USING gist (date_range);


--
-- Name: idx_project_user; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_project_user ON dbnext.project USING btree (id_user);


--
-- Name: idx_prp_keyword; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prp_keyword ON dbnext.project_record_parent USING btree (id_keyword);


--
-- Name: idx_prp_parent; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prp_parent ON dbnext.project_record_parent USING btree (id_project_record_parent);


--
-- Name: idx_prp_project_record; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prp_project_record ON dbnext.project_record_parent USING btree (id_project_record);


--
-- Name: idx_prpr_project; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prpr_project ON dbnext.project_record_project USING btree (id_project);


--
-- Name: idx_prr_keyword; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prr_keyword ON dbnext.project_record_record USING btree (id_keyword);


--
-- Name: idx_prr_project_record_1; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prr_project_record_1 ON dbnext.project_record_record USING btree (id_project_record_1);


--
-- Name: idx_prr_project_record_2; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prr_project_record_2 ON dbnext.project_record_record USING btree (id_project_record_2);


--
-- Name: idx_pru_project_record; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_pru_project_record ON dbnext.project_record_user USING btree (id_project_record);


--
-- Name: idx_pru_user; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_pru_user ON dbnext.project_record_user USING btree (id_user);


--
-- Name: idx_pruk_keyword; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_pruk_keyword ON dbnext.project_record_user_keyword USING btree (id_keyword);


--
-- Name: uq_keyword_parent_name; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE UNIQUE INDEX uq_keyword_parent_name ON dbnext.keyword USING btree (COALESCE(id_parent, (0)::bigint), name);


--
-- Name: uq_project_item_list_preferred; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE UNIQUE INDEX uq_project_item_list_preferred ON dbnext.project_item_list USING btree (id_project) WHERE preferred;


--
-- Name: uq_project_record_determination_preferred; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE UNIQUE INDEX uq_project_record_determination_preferred ON dbnext.project_record_determination USING btree (id_project_record) WHERE preferred;


--
-- Name: uq_users_email_lower; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE UNIQUE INDEX uq_users_email_lower ON dbnext.users USING btree (lower((email)::text));


--
-- Name: project_record_determination trg_prevent_last_determination_delete; Type: TRIGGER; Schema: dbnext; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_prevent_last_determination_delete AFTER DELETE ON dbnext.project_record_determination DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION dbnext.prevent_last_determination_delete();


--
-- Name: project_record_project trg_prevent_last_project_association_delete; Type: TRIGGER; Schema: dbnext; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_prevent_last_project_association_delete AFTER DELETE ON dbnext.project_record_project DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION dbnext.prevent_last_project_record_project_delete();


--
-- Name: project_record trg_project_record_requires_project; Type: TRIGGER; Schema: dbnext; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_project_record_requires_project AFTER INSERT ON dbnext.project_record DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION dbnext.check_project_record_has_project();


--
-- Name: item trg_set_date_modify; Type: TRIGGER; Schema: dbnext; Owner: postgres
--

CREATE TRIGGER trg_set_date_modify BEFORE UPDATE ON dbnext.item FOR EACH ROW EXECUTE FUNCTION dbnext.set_date_modify();


--
-- Name: item_list trg_set_date_modify; Type: TRIGGER; Schema: dbnext; Owner: postgres
--

CREATE TRIGGER trg_set_date_modify BEFORE UPDATE ON dbnext.item_list FOR EACH ROW EXECUTE FUNCTION dbnext.set_date_modify();


--
-- Name: item_list_item trg_set_date_modify; Type: TRIGGER; Schema: dbnext; Owner: postgres
--

CREATE TRIGGER trg_set_date_modify BEFORE UPDATE ON dbnext.item_list_item FOR EACH ROW EXECUTE FUNCTION dbnext.set_date_modify();


--
-- Name: keyword trg_set_date_modify; Type: TRIGGER; Schema: dbnext; Owner: postgres
--

CREATE TRIGGER trg_set_date_modify BEFORE UPDATE ON dbnext.keyword FOR EACH ROW EXECUTE FUNCTION dbnext.set_date_modify();


--
-- Name: media trg_set_date_modify; Type: TRIGGER; Schema: dbnext; Owner: postgres
--

CREATE TRIGGER trg_set_date_modify BEFORE UPDATE ON dbnext.media FOR EACH ROW EXECUTE FUNCTION dbnext.set_date_modify();


--
-- Name: project trg_set_date_modify; Type: TRIGGER; Schema: dbnext; Owner: postgres
--

CREATE TRIGGER trg_set_date_modify BEFORE UPDATE ON dbnext.project FOR EACH ROW EXECUTE FUNCTION dbnext.set_date_modify();


--
-- Name: project_record trg_set_date_modify; Type: TRIGGER; Schema: dbnext; Owner: postgres
--

CREATE TRIGGER trg_set_date_modify BEFORE UPDATE ON dbnext.project_record FOR EACH ROW EXECUTE FUNCTION dbnext.set_date_modify();


--
-- Name: project_record_determination trg_set_date_modify; Type: TRIGGER; Schema: dbnext; Owner: postgres
--

CREATE TRIGGER trg_set_date_modify BEFORE UPDATE ON dbnext.project_record_determination FOR EACH ROW EXECUTE FUNCTION dbnext.set_date_modify();


--
-- Name: data_definition fk_data_definition_group; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.data_definition
    ADD CONSTRAINT fk_data_definition_group FOREIGN KEY (id_group) REFERENCES dbnext.data_group(id);


--
-- Name: project_record_data_group fk_data_group_id; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_data_group
    ADD CONSTRAINT fk_data_group_id FOREIGN KEY (id_data_group) REFERENCES dbnext.data_group(id);


--
-- Name: data_group fk_data_group_parent; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.data_group
    ADD CONSTRAINT fk_data_group_parent FOREIGN KEY (id_parent) REFERENCES dbnext.data_group(id);


--
-- Name: external_identifier_item fk_eii_external_identifier; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier_item
    ADD CONSTRAINT fk_eii_external_identifier FOREIGN KEY (id_external_identifier) REFERENCES dbnext.external_identifier(id);


--
-- Name: external_identifier_item fk_eii_item; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier_item
    ADD CONSTRAINT fk_eii_item FOREIGN KEY (id_item) REFERENCES dbnext.item(id);


--
-- Name: external_identifier_project_record fk_eipr_external_identifier; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier_project_record
    ADD CONSTRAINT fk_eipr_external_identifier FOREIGN KEY (id_external_identifier) REFERENCES dbnext.external_identifier(id);


--
-- Name: external_identifier_project_record fk_eipr_project_record; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier_project_record
    ADD CONSTRAINT fk_eipr_project_record FOREIGN KEY (id_project_record) REFERENCES dbnext.project_record(id) ON DELETE CASCADE;


--
-- Name: project_record_geometry fk_geometry_record; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_geometry
    ADD CONSTRAINT fk_geometry_record FOREIGN KEY (id_record) REFERENCES dbnext.project_record(id) ON DELETE CASCADE;


--
-- Name: item_list_item fk_id_accepted_id; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item
    ADD CONSTRAINT fk_id_accepted_id FOREIGN KEY (id_accepted) REFERENCES dbnext.item_list_item(id) NOT VALID;


--
-- Name: item_list_item fk_ili_created_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item
    ADD CONSTRAINT fk_ili_created_by FOREIGN KEY (created_by) REFERENCES dbnext.users(id);


--
-- Name: item_list_item fk_ili_identity; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item
    ADD CONSTRAINT fk_ili_identity FOREIGN KEY (id_identity) REFERENCES dbnext.item_list_item(id);


--
-- Name: item_list_item fk_ili_item; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item
    ADD CONSTRAINT fk_ili_item FOREIGN KEY (id_item) REFERENCES dbnext.item(id);


--
-- Name: item_list_item fk_ili_list; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item
    ADD CONSTRAINT fk_ili_list FOREIGN KEY (id_item_list) REFERENCES dbnext.item_list(id);


--
-- Name: item_list_item fk_ili_modified_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item
    ADD CONSTRAINT fk_ili_modified_by FOREIGN KEY (modified_by) REFERENCES dbnext.users(id);


--
-- Name: item_list_item fk_ili_parent; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item
    ADD CONSTRAINT fk_ili_parent FOREIGN KEY (id_parent) REFERENCES dbnext.item_list_item(id);


--
-- Name: item_list_item_keyword fk_ilik_item; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item_keyword
    ADD CONSTRAINT fk_ilik_item FOREIGN KEY (id_item_list_item) REFERENCES dbnext.item_list_item(id);


--
-- Name: item_list_item_keyword fk_ilik_keyword; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item_keyword
    ADD CONSTRAINT fk_ilik_keyword FOREIGN KEY (id_keyword) REFERENCES dbnext.keyword(id);


--
-- Name: item_list_keyword fk_ilk_keyword; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_keyword
    ADD CONSTRAINT fk_ilk_keyword FOREIGN KEY (id_keyword) REFERENCES dbnext.keyword(id);


--
-- Name: item_list_keyword fk_ilk_list; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_keyword
    ADD CONSTRAINT fk_ilk_list FOREIGN KEY (id_item_list) REFERENCES dbnext.item_list(id);


--
-- Name: item fk_item_created_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item
    ADD CONSTRAINT fk_item_created_by FOREIGN KEY (created_by) REFERENCES dbnext.users(id);


--
-- Name: item_list fk_item_group; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list
    ADD CONSTRAINT fk_item_group FOREIGN KEY (item_id_data_group) REFERENCES dbnext.data_group(id);


--
-- Name: item_keyword fk_item_keyword_item; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_keyword
    ADD CONSTRAINT fk_item_keyword_item FOREIGN KEY (id_item) REFERENCES dbnext.item(id);


--
-- Name: item_keyword fk_item_keyword_keyword; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_keyword
    ADD CONSTRAINT fk_item_keyword_keyword FOREIGN KEY (id_keyword) REFERENCES dbnext.keyword(id);


--
-- Name: item_list fk_item_list_created_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list
    ADD CONSTRAINT fk_item_list_created_by FOREIGN KEY (created_by) REFERENCES dbnext.users(id);


--
-- Name: item_list fk_item_list_group; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list
    ADD CONSTRAINT fk_item_list_group FOREIGN KEY (item_list_id_data_group) REFERENCES dbnext.data_group(id);


--
-- Name: item_list fk_item_list_modified_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list
    ADD CONSTRAINT fk_item_list_modified_by FOREIGN KEY (modified_by) REFERENCES dbnext.users(id);


--
-- Name: item_list fk_item_list_parent; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list
    ADD CONSTRAINT fk_item_list_parent FOREIGN KEY (id_parent) REFERENCES dbnext.item_list(id);


--
-- Name: item fk_item_modified_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item
    ADD CONSTRAINT fk_item_modified_by FOREIGN KEY (modified_by) REFERENCES dbnext.users(id);


--
-- Name: keyword fk_keyword_created_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.keyword
    ADD CONSTRAINT fk_keyword_created_by FOREIGN KEY (created_by) REFERENCES dbnext.users(id);


--
-- Name: keyword fk_keyword_group; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.keyword
    ADD CONSTRAINT fk_keyword_group FOREIGN KEY (id_data_group) REFERENCES dbnext.data_group(id);


--
-- Name: keyword fk_keyword_modified_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.keyword
    ADD CONSTRAINT fk_keyword_modified_by FOREIGN KEY (modified_by) REFERENCES dbnext.users(id);


--
-- Name: keyword fk_keyword_parent; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.keyword
    ADD CONSTRAINT fk_keyword_parent FOREIGN KEY (id_parent) REFERENCES dbnext.keyword(id);


--
-- Name: media fk_media_created_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.media
    ADD CONSTRAINT fk_media_created_by FOREIGN KEY (created_by) REFERENCES dbnext.users(id);


--
-- Name: media fk_media_data_group; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.media
    ADD CONSTRAINT fk_media_data_group FOREIGN KEY (id_data_group) REFERENCES dbnext.data_group(id);


--
-- Name: media fk_media_modified_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.media
    ADD CONSTRAINT fk_media_modified_by FOREIGN KEY (modified_by) REFERENCES dbnext.users(id);


--
-- Name: media_item fk_mi_item; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.media_item
    ADD CONSTRAINT fk_mi_item FOREIGN KEY (id_item) REFERENCES dbnext.item(id);


--
-- Name: media_item fk_mi_media; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.media_item
    ADD CONSTRAINT fk_mi_media FOREIGN KEY (id_media) REFERENCES dbnext.media(id);


--
-- Name: project_item_list fk_pil_list; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_item_list
    ADD CONSTRAINT fk_pil_list FOREIGN KEY (id_item_list) REFERENCES dbnext.item_list(id);


--
-- Name: project_item_list fk_pil_project; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_item_list
    ADD CONSTRAINT fk_pil_project FOREIGN KEY (id_project) REFERENCES dbnext.project(id);


--
-- Name: project_keyword fk_pk_keyword; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_keyword
    ADD CONSTRAINT fk_pk_keyword FOREIGN KEY (id_keyword) REFERENCES dbnext.keyword(id);


--
-- Name: project_keyword fk_pk_project; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_keyword
    ADD CONSTRAINT fk_pk_project FOREIGN KEY (id_project) REFERENCES dbnext.project(id);


--
-- Name: project_record_determination fk_prd_determination_method; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_determination
    ADD CONSTRAINT fk_prd_determination_method FOREIGN KEY (id_determination_method) REFERENCES dbnext.keyword(id);


--
-- Name: project_record_determination fk_prd_determined_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_determination
    ADD CONSTRAINT fk_prd_determined_by FOREIGN KEY (determined_by) REFERENCES dbnext.users(id);


--
-- Name: project_record_determination fk_prd_item; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_determination
    ADD CONSTRAINT fk_prd_item FOREIGN KEY (id_item_list_item) REFERENCES dbnext.item_list_item(id);


--
-- Name: project_record_determination fk_prd_record; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_determination
    ADD CONSTRAINT fk_prd_record FOREIGN KEY (id_project_record) REFERENCES dbnext.project_record(id) ON DELETE CASCADE;


--
-- Name: project_record_determination fk_prd_user; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_determination
    ADD CONSTRAINT fk_prd_user FOREIGN KEY (id_user) REFERENCES dbnext.users(id);


--
-- Name: project_record_determination_keyword fk_prdk_determination; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_determination_keyword
    ADD CONSTRAINT fk_prdk_determination FOREIGN KEY (id_project_record_determination) REFERENCES dbnext.project_record_determination(id) ON DELETE CASCADE;


--
-- Name: project_record_determination_keyword fk_prdk_keyword; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_determination_keyword
    ADD CONSTRAINT fk_prdk_keyword FOREIGN KEY (id_keyword) REFERENCES dbnext.keyword(id);


--
-- Name: data_predefined_values fk_predefined_definition; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.data_predefined_values
    ADD CONSTRAINT fk_predefined_definition FOREIGN KEY (id_data_definition) REFERENCES dbnext.data_definition(id);


--
-- Name: project_record_identifier fk_pri_keyword; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_identifier
    ADD CONSTRAINT fk_pri_keyword FOREIGN KEY (id_keyword) REFERENCES dbnext.keyword(id);


--
-- Name: project_record_identifier fk_pri_project_record; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_identifier
    ADD CONSTRAINT fk_pri_project_record FOREIGN KEY (id_project_record) REFERENCES dbnext.project_record(id) ON DELETE CASCADE;


--
-- Name: project_record_keyword fk_prk_keyword; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_keyword
    ADD CONSTRAINT fk_prk_keyword FOREIGN KEY (id_keyword) REFERENCES dbnext.keyword(id);


--
-- Name: project_record_keyword fk_prk_project_record; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_keyword
    ADD CONSTRAINT fk_prk_project_record FOREIGN KEY (id_project_record) REFERENCES dbnext.project_record(id) ON DELETE CASCADE;


--
-- Name: project_record_media fk_prm_media; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_media
    ADD CONSTRAINT fk_prm_media FOREIGN KEY (id_media) REFERENCES dbnext.media(id);


--
-- Name: project_record_media fk_prm_project_record; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_media
    ADD CONSTRAINT fk_prm_project_record FOREIGN KEY (id_project_record) REFERENCES dbnext.project_record(id) ON DELETE CASCADE;


--
-- Name: project fk_project_created_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project
    ADD CONSTRAINT fk_project_created_by FOREIGN KEY (created_by) REFERENCES dbnext.users(id);


--
-- Name: project fk_project_group; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project
    ADD CONSTRAINT fk_project_group FOREIGN KEY (id_data_group) REFERENCES dbnext.data_group(id);


--
-- Name: project_record_data_group fk_project_id_project; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_data_group
    ADD CONSTRAINT fk_project_id_project FOREIGN KEY (id_project) REFERENCES dbnext.project(id);


--
-- Name: project fk_project_modified_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project
    ADD CONSTRAINT fk_project_modified_by FOREIGN KEY (modified_by) REFERENCES dbnext.users(id);


--
-- Name: project fk_project_parent; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project
    ADD CONSTRAINT fk_project_parent FOREIGN KEY (id_parent) REFERENCES dbnext.project(id);


--
-- Name: project_record fk_project_record_created_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record
    ADD CONSTRAINT fk_project_record_created_by FOREIGN KEY (created_by) REFERENCES dbnext.users(id);


--
-- Name: project fk_project_record_group; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project
    ADD CONSTRAINT fk_project_record_group FOREIGN KEY (record_id_data_group) REFERENCES dbnext.data_group(id);


--
-- Name: project_record fk_project_record_modified_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record
    ADD CONSTRAINT fk_project_record_modified_by FOREIGN KEY (modified_by) REFERENCES dbnext.users(id);


--
-- Name: project_record_project fk_project_record_project_id_project; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_project
    ADD CONSTRAINT fk_project_record_project_id_project FOREIGN KEY (id_project) REFERENCES dbnext.project(id);


--
-- Name: project_record_project fk_project_record_project_id_project_record; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_project
    ADD CONSTRAINT fk_project_record_project_id_project_record FOREIGN KEY (id_project_record) REFERENCES dbnext.project_record(id) ON DELETE CASCADE NOT VALID;


--
-- Name: project_record_user fk_project_record_user_id_project_record; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_user
    ADD CONSTRAINT fk_project_record_user_id_project_record FOREIGN KEY (id_project_record) REFERENCES dbnext.project_record(id) ON DELETE CASCADE;


--
-- Name: project_record_user fk_project_record_user_id_user; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_user
    ADD CONSTRAINT fk_project_record_user_id_user FOREIGN KEY (id_user) REFERENCES dbnext.users(id);


--
-- Name: project_record_user_keyword fk_project_record_user_keyword; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_user_keyword
    ADD CONSTRAINT fk_project_record_user_keyword FOREIGN KEY (id_keyword) REFERENCES dbnext.keyword(id);


--
-- Name: project_record_user_keyword fk_project_record_user_keyword_project_record_user; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_user_keyword
    ADD CONSTRAINT fk_project_record_user_keyword_project_record_user FOREIGN KEY (id_project_record_user) REFERENCES dbnext.project_record_user(id) ON DELETE CASCADE NOT VALID;


--
-- Name: project fk_project_user; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project
    ADD CONSTRAINT fk_project_user FOREIGN KEY (id_user) REFERENCES dbnext.users(id);


--
-- Name: project_record_parent fk_prp_keyword; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_parent
    ADD CONSTRAINT fk_prp_keyword FOREIGN KEY (id_keyword) REFERENCES dbnext.keyword(id);


--
-- Name: project_record_parent fk_prp_parent; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_parent
    ADD CONSTRAINT fk_prp_parent FOREIGN KEY (id_project_record_parent) REFERENCES dbnext.project_record(id) ON DELETE CASCADE;


--
-- Name: project_record_parent fk_prp_project_record; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_parent
    ADD CONSTRAINT fk_prp_project_record FOREIGN KEY (id_project_record) REFERENCES dbnext.project_record(id) ON DELETE CASCADE;


--
-- Name: project_record_record fk_prr_keyword; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_record
    ADD CONSTRAINT fk_prr_keyword FOREIGN KEY (id_keyword) REFERENCES dbnext.keyword(id);


--
-- Name: project_record_record fk_prr_project_record_1; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_record
    ADD CONSTRAINT fk_prr_project_record_1 FOREIGN KEY (id_project_record_1) REFERENCES dbnext.project_record(id) ON DELETE CASCADE;


--
-- Name: project_record_record fk_prr_project_record_2; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_record
    ADD CONSTRAINT fk_prr_project_record_2 FOREIGN KEY (id_project_record_2) REFERENCES dbnext.project_record(id) ON DELETE CASCADE;


--
-- Name: users_keyword fk_user; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.users_keyword
    ADD CONSTRAINT fk_user FOREIGN KEY (id_user) REFERENCES dbnext.users(id) NOT VALID;


--
-- Name: users_keyword fk_user_keyword; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.users_keyword
    ADD CONSTRAINT fk_user_keyword FOREIGN KEY (id_keyword) REFERENCES dbnext.keyword(id) NOT VALID;


--
-- PostgreSQL database dump complete
--

\unrestrict R4hPq1pf6GS93q7TsjcO5lLavdjzlB7DzGpZGIaZizfm5jUEnKCdaaRc6RDUY3A

