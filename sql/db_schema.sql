--
-- PostgreSQL database dump
--

\restrict uY0PSwGOs1WIijaKRn1yBXGDefyFUb0kPUbKACfko6kAmIRb6Vf6gCJ2od0nq9T

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

-- Started on 2026-05-06 10:22:28

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 227 (class 1259 OID 54752)
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
-- TOC entry 6410 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN data_definition.type; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.data_definition.type IS 'type of custom field. int, string, date';


--
-- TOC entry 6411 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN data_definition.validation_regex; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.data_definition.validation_regex IS 'definition of the regex that controls which value is allowed';


--
-- TOC entry 6412 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN data_definition.rank; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.data_definition.rank IS 'Rank that can be used as position in designs';


--
-- TOC entry 228 (class 1259 OID 54763)
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
-- TOC entry 6413 (class 0 OID 0)
-- Dependencies: 228
-- Name: data_definition_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.data_definition_id_seq OWNED BY dbnext.data_definition.id;


--
-- TOC entry 229 (class 1259 OID 54764)
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
-- TOC entry 6414 (class 0 OID 0)
-- Dependencies: 229
-- Name: TABLE data_group; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.data_group IS 'in his table groups are organized that contains custom fields. see data_definition';


--
-- TOC entry 6415 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN data_group.id_parent; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.data_group.id_parent IS 'data_groups can be organized hierarchically';


--
-- TOC entry 230 (class 1259 OID 54772)
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
-- TOC entry 6416 (class 0 OID 0)
-- Dependencies: 230
-- Name: data_group_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.data_group_id_seq OWNED BY dbnext.data_group.id;


--
-- TOC entry 231 (class 1259 OID 54773)
-- Name: data_predefined_values; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.data_predefined_values (
    id bigint NOT NULL,
    id_data_definition bigint NOT NULL,
    value character varying[]
);


ALTER TABLE dbnext.data_predefined_values OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 54780)
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
-- TOC entry 6417 (class 0 OID 0)
-- Dependencies: 232
-- Name: data_predefined_values_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.data_predefined_values_id_seq OWNED BY dbnext.data_predefined_values.id;


--
-- TOC entry 233 (class 1259 OID 54781)
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
-- TOC entry 6418 (class 0 OID 0)
-- Dependencies: 233
-- Name: TABLE external_identifier; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.external_identifier IS 'Stores references to external systems (GBIF, BOLD, GenBank, Index Herbariorum, etc.)';


--
-- TOC entry 6419 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN external_identifier.source; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.external_identifier.source IS 'Name of the external system, e.g. GBIF, GenBank, BOLD';


--
-- TOC entry 6420 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN external_identifier.identifier; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.external_identifier.identifier IS 'The identifier value in the external system';


--
-- TOC entry 6421 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN external_identifier.url; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.external_identifier.url IS 'Optional URL to the resource in the external system';


--
-- TOC entry 234 (class 1259 OID 54790)
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
-- TOC entry 6422 (class 0 OID 0)
-- Dependencies: 234
-- Name: external_identifier_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.external_identifier_id_seq OWNED BY dbnext.external_identifier.id;


--
-- TOC entry 235 (class 1259 OID 54791)
-- Name: external_identifier_item; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.external_identifier_item (
    id bigint NOT NULL,
    id_external_identifier bigint NOT NULL,
    id_item bigint NOT NULL
);


ALTER TABLE dbnext.external_identifier_item OWNER TO postgres;

--
-- TOC entry 6423 (class 0 OID 0)
-- Dependencies: 235
-- Name: TABLE external_identifier_item; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.external_identifier_item IS 'Links external identifiers to items (taxa, etc.)';


--
-- TOC entry 236 (class 1259 OID 54797)
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
-- TOC entry 6424 (class 0 OID 0)
-- Dependencies: 236
-- Name: external_identifier_item_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.external_identifier_item_id_seq OWNED BY dbnext.external_identifier_item.id;


--
-- TOC entry 237 (class 1259 OID 54798)
-- Name: external_identifier_project_record; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.external_identifier_project_record (
    id bigint NOT NULL,
    id_external_identifier bigint CONSTRAINT external_identifier_project_rec_id_external_identifier_not_null NOT NULL,
    id_project_record bigint NOT NULL
);


ALTER TABLE dbnext.external_identifier_project_record OWNER TO postgres;

--
-- TOC entry 6425 (class 0 OID 0)
-- Dependencies: 237
-- Name: TABLE external_identifier_project_record; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.external_identifier_project_record IS 'Links external identifiers to specimens/observations in project_record';


--
-- TOC entry 238 (class 1259 OID 54804)
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
-- TOC entry 6426 (class 0 OID 0)
-- Dependencies: 238
-- Name: external_identifier_project_record_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.external_identifier_project_record_id_seq OWNED BY dbnext.external_identifier_project_record.id;


--
-- TOC entry 239 (class 1259 OID 54805)
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
-- TOC entry 6427 (class 0 OID 0)
-- Dependencies: 239
-- Name: TABLE item; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.item IS 'items are subjects that can be recorded. see: project_record table. items are organized in lists. see: item_list table and item_list_item table';


--
-- TOC entry 240 (class 1259 OID 54818)
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
-- TOC entry 6428 (class 0 OID 0)
-- Dependencies: 240
-- Name: item_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.item_id_seq OWNED BY dbnext.item.id;


--
-- TOC entry 241 (class 1259 OID 54819)
-- Name: item_keyword; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.item_keyword (
    id bigint NOT NULL,
    id_item bigint NOT NULL,
    id_keyword bigint NOT NULL
);


ALTER TABLE dbnext.item_keyword OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 54825)
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
-- TOC entry 6429 (class 0 OID 0)
-- Dependencies: 242
-- Name: item_keyword_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.item_keyword_id_seq OWNED BY dbnext.item_keyword.id;


--
-- TOC entry 243 (class 1259 OID 54826)
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
-- TOC entry 6430 (class 0 OID 0)
-- Dependencies: 243
-- Name: TABLE item_list; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.item_list IS 'in this table lists are organized that contains items. see item table and item_list_item table';


--
-- TOC entry 6431 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN item_list.data; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.item_list.data IS 'can contains custom fields';


--
-- TOC entry 6432 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN item_list.item_list_id_data_group; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.item_list.item_list_id_data_group IS 'reference to the data_group in which custom fields are defined in the data field of item_list.';


--
-- TOC entry 6433 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN item_list.item_id_data_group; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.item_list.item_id_data_group IS 'reference to the data group in which custom fields are defined that are used in the data field of the item table in a specific list in item_list.';


--
-- TOC entry 244 (class 1259 OID 54841)
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
-- TOC entry 6434 (class 0 OID 0)
-- Dependencies: 244
-- Name: item_list_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.item_list_id_seq OWNED BY dbnext.item_list.id;


--
-- TOC entry 245 (class 1259 OID 54842)
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
-- TOC entry 6435 (class 0 OID 0)
-- Dependencies: 245
-- Name: TABLE item_list_item; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.item_list_item IS 'this table serves as the relation between item and item_list table. One item can be part of many lists in item_list. Also the parent of the id_item is defined by id_parent which points to id in item table.';


--
-- TOC entry 6436 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN item_list_item.id_item_list; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.item_list_item.id_item_list IS 'reference to the item_list.id';


--
-- TOC entry 6437 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN item_list_item.id_item; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.item_list_item.id_item IS 'reference to the item.id table';


--
-- TOC entry 6438 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN item_list_item.id_parent; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.item_list_item.id_parent IS 'Self-referencing FK to item_list_item.id. Defines the parent within the same list hierarchy (e.g., taxonomic tree).';


--
-- TOC entry 6439 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN item_list_item.id_identity; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.item_list_item.id_identity IS 'identifies the identity of this item. Items with the same id_identity are considered synonymous.';


--
-- TOC entry 6440 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN item_list_item.id_accepted; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.item_list_item.id_accepted IS 'id_accepted points to the list accepted item_list_item.id.';


--
-- TOC entry 246 (class 1259 OID 54852)
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
-- TOC entry 6441 (class 0 OID 0)
-- Dependencies: 246
-- Name: item_list_item_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.item_list_item_id_seq OWNED BY dbnext.item_list_item.id;


--
-- TOC entry 247 (class 1259 OID 54853)
-- Name: item_list_item_keyword; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.item_list_item_keyword (
    id bigint NOT NULL,
    id_item_list_item bigint NOT NULL,
    id_keyword bigint NOT NULL
);


ALTER TABLE dbnext.item_list_item_keyword OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 54859)
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
-- TOC entry 6442 (class 0 OID 0)
-- Dependencies: 248
-- Name: item_list_item_keyword_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.item_list_item_keyword_id_seq OWNED BY dbnext.item_list_item_keyword.id;


--
-- TOC entry 249 (class 1259 OID 54860)
-- Name: item_list_keyword; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.item_list_keyword (
    id bigint NOT NULL,
    id_item_list bigint NOT NULL,
    id_keyword bigint NOT NULL
);


ALTER TABLE dbnext.item_list_keyword OWNER TO postgres;

--
-- TOC entry 6443 (class 0 OID 0)
-- Dependencies: 249
-- Name: TABLE item_list_keyword; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.item_list_keyword IS 'relation between keyword and item_list table. one to many';


--
-- TOC entry 250 (class 1259 OID 54866)
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
-- TOC entry 6444 (class 0 OID 0)
-- Dependencies: 250
-- Name: item_list_keyword_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.item_list_keyword_id_seq OWNED BY dbnext.item_list_keyword.id;


--
-- TOC entry 251 (class 1259 OID 54867)
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
-- TOC entry 252 (class 1259 OID 54881)
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
-- TOC entry 6445 (class 0 OID 0)
-- Dependencies: 252
-- Name: keyword_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.keyword_id_seq OWNED BY dbnext.keyword.id;


--
-- TOC entry 253 (class 1259 OID 54882)
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
-- TOC entry 6446 (class 0 OID 0)
-- Dependencies: 253
-- Name: TABLE media; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.media IS 'Stores references to media files (images, documents, etc.) associated with records or items';


--
-- TOC entry 6447 (class 0 OID 0)
-- Dependencies: 253
-- Name: COLUMN media.file_path; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.media.file_path IS 'Path or URL to the media file (actual file storage is external)';


--
-- TOC entry 254 (class 1259 OID 54897)
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
-- TOC entry 6448 (class 0 OID 0)
-- Dependencies: 254
-- Name: media_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.media_id_seq OWNED BY dbnext.media.id;


--
-- TOC entry 255 (class 1259 OID 54898)
-- Name: media_item; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.media_item (
    id bigint NOT NULL,
    id_media bigint NOT NULL,
    id_item bigint NOT NULL
);


ALTER TABLE dbnext.media_item OWNER TO postgres;

--
-- TOC entry 6449 (class 0 OID 0)
-- Dependencies: 255
-- Name: TABLE media_item; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.media_item IS 'Links media to taxa/items';


--
-- TOC entry 256 (class 1259 OID 54904)
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
-- TOC entry 6450 (class 0 OID 0)
-- Dependencies: 256
-- Name: media_item_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.media_item_id_seq OWNED BY dbnext.media_item.id;


--
-- TOC entry 259 (class 1259 OID 54912)
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
-- TOC entry 6451 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN project.id_user; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project.id_user IS 'The authority user for this project. One user per project.';


--
-- TOC entry 260 (class 1259 OID 54927)
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
-- TOC entry 6452 (class 0 OID 0)
-- Dependencies: 260
-- Name: project_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_id_seq OWNED BY dbnext.project.id;


--
-- TOC entry 261 (class 1259 OID 54928)
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
-- TOC entry 6453 (class 0 OID 0)
-- Dependencies: 261
-- Name: TABLE project_item_list; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.project_item_list IS 'here is defined which item_list.id (item lists) are allowed to use in projects';


--
-- TOC entry 262 (class 1259 OID 54936)
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
-- TOC entry 6454 (class 0 OID 0)
-- Dependencies: 262
-- Name: project_item_list_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_item_list_id_seq OWNED BY dbnext.project_item_list.id;


--
-- TOC entry 263 (class 1259 OID 54937)
-- Name: project_keyword; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.project_keyword (
    id bigint NOT NULL,
    id_project bigint NOT NULL,
    id_keyword bigint NOT NULL
);


ALTER TABLE dbnext.project_keyword OWNER TO postgres;

--
-- TOC entry 6455 (class 0 OID 0)
-- Dependencies: 263
-- Name: TABLE project_keyword; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.project_keyword IS 'relation between keyword and project table. one to many';


--
-- TOC entry 264 (class 1259 OID 54943)
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
-- TOC entry 6456 (class 0 OID 0)
-- Dependencies: 264
-- Name: project_keyword_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_keyword_id_seq OWNED BY dbnext.project_keyword.id;


--
-- TOC entry 265 (class 1259 OID 54944)
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
-- TOC entry 6457 (class 0 OID 0)
-- Dependencies: 265
-- Name: TABLE project_record; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.project_record IS 'this is the central table that contains the purpose subjects of items ';


--
-- TOC entry 6458 (class 0 OID 0)
-- Dependencies: 265
-- Name: COLUMN project_record.date_range; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record.date_range IS 'Generated range column from date_start and date_end. Enables range operators (@>, &&, etc.) for temporal queries.';


--
-- TOC entry 266 (class 1259 OID 54956)
-- Name: project_record_data_group; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.project_record_data_group (
    id bigint NOT NULL,
    id_project bigint NOT NULL,
    id_data_group bigint NOT NULL
);


ALTER TABLE dbnext.project_record_data_group OWNER TO postgres;

--
-- TOC entry 6459 (class 0 OID 0)
-- Dependencies: 266
-- Name: TABLE project_record_data_group; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.project_record_data_group IS 'Custom data fields in project_record are referenced by this table.It is possible to assign more than one data_group to a project_record';


--
-- TOC entry 267 (class 1259 OID 54962)
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
-- TOC entry 6460 (class 0 OID 0)
-- Dependencies: 267
-- Name: project_record_data_group_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_data_group_id_seq OWNED BY dbnext.project_record_data_group.id;


--
-- TOC entry 268 (class 1259 OID 54963)
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
-- TOC entry 6461 (class 0 OID 0)
-- Dependencies: 268
-- Name: COLUMN project_record_determination.determined_by; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_determination.determined_by IS 'FK to user table. The user who made the determination. Use determined_by_name for historical determiners not in the user table.';


--
-- TOC entry 6462 (class 0 OID 0)
-- Dependencies: 268
-- Name: COLUMN project_record_determination.determined_by_name; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_determination.determined_by_name IS 'Free text name of the determiner. Used for historical determiners not registered as users.';


--
-- TOC entry 6463 (class 0 OID 0)
-- Dependencies: 268
-- Name: COLUMN project_record_determination.determination_date; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_determination.determination_date IS 'Date when the actual determination was made (not the row creation date).';


--
-- TOC entry 6464 (class 0 OID 0)
-- Dependencies: 268
-- Name: COLUMN project_record_determination.id_determination_method; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_determination.id_determination_method IS 'FK to keyword table. Defines the method used (e.g. morphological, molecular). Managed as keywords.';


--
-- TOC entry 6465 (class 0 OID 0)
-- Dependencies: 268
-- Name: COLUMN project_record_determination.remarks; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_determination.remarks IS 'Free text remarks about the determination.';


--
-- TOC entry 6466 (class 0 OID 0)
-- Dependencies: 268
-- Name: COLUMN project_record_determination.id_user; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_determination.id_user IS 'The user who made the determination (determinavit). Nullable for historical records with unknown determinator.';


--
-- TOC entry 269 (class 1259 OID 54977)
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
-- TOC entry 6467 (class 0 OID 0)
-- Dependencies: 269
-- Name: project_record_determination_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_determination_id_seq OWNED BY dbnext.project_record_determination.id;


--
-- TOC entry 270 (class 1259 OID 54978)
-- Name: project_record_determination_keyword; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.project_record_determination_keyword (
    id bigint NOT NULL,
    id_project_record_determination bigint CONSTRAINT project_record_determinatio_id_project_record_determin_not_null NOT NULL,
    id_keyword bigint NOT NULL
);


ALTER TABLE dbnext.project_record_determination_keyword OWNER TO postgres;

--
-- TOC entry 6468 (class 0 OID 0)
-- Dependencies: 270
-- Name: TABLE project_record_determination_keyword; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.project_record_determination_keyword IS 'relation between keyword and project_record_determination table. one to many';


--
-- TOC entry 271 (class 1259 OID 54984)
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
-- TOC entry 6469 (class 0 OID 0)
-- Dependencies: 271
-- Name: project_record_determination_keyword_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_determination_keyword_id_seq OWNED BY dbnext.project_record_determination_keyword.id;


--
-- TOC entry 272 (class 1259 OID 54985)
-- Name: project_record_geometry; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.project_record_geometry (
    id bigint NOT NULL,
    id_record bigint NOT NULL,
    geom public.geometry(Geometry,4326)
);


ALTER TABLE dbnext.project_record_geometry OWNER TO postgres;

--
-- TOC entry 273 (class 1259 OID 54992)
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
-- TOC entry 6470 (class 0 OID 0)
-- Dependencies: 273
-- Name: project_record_geometry_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_geometry_id_seq OWNED BY dbnext.project_record_geometry.id;


--
-- TOC entry 274 (class 1259 OID 54993)
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
-- TOC entry 6471 (class 0 OID 0)
-- Dependencies: 274
-- Name: project_record_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_id_seq OWNED BY dbnext.project_record.id;


--
-- TOC entry 275 (class 1259 OID 54994)
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
-- TOC entry 6472 (class 0 OID 0)
-- Dependencies: 275
-- Name: TABLE project_record_identifier; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.project_record_identifier IS 'Stores multiple identifiers per record (catalog number, accession number, field number, barcode, etc.). The identifier type is defined by id_keyword.';


--
-- TOC entry 6473 (class 0 OID 0)
-- Dependencies: 275
-- Name: COLUMN project_record_identifier.id_keyword; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_identifier.id_keyword IS 'Defines the identifier type (e.g. Catalog Number, Accession Number). References keyword table.';


--
-- TOC entry 6474 (class 0 OID 0)
-- Dependencies: 275
-- Name: COLUMN project_record_identifier.value; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_identifier.value IS 'The actual identifier value (e.g. the catalog number string)';


--
-- TOC entry 276 (class 1259 OID 55003)
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
-- TOC entry 6475 (class 0 OID 0)
-- Dependencies: 276
-- Name: project_record_identifier_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_identifier_id_seq OWNED BY dbnext.project_record_identifier.id;


--
-- TOC entry 277 (class 1259 OID 55004)
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
-- TOC entry 6476 (class 0 OID 0)
-- Dependencies: 277
-- Name: COLUMN project_record_keyword.description; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_keyword.description IS 'Example of how to use this field:
We have a keyword naming "ToDo" and  we build a relation to a project_record. Then we can add a description what exactly is to do in future on this record.';


--
-- TOC entry 278 (class 1259 OID 55012)
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
-- TOC entry 6477 (class 0 OID 0)
-- Dependencies: 278
-- Name: project_record_keyword_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_keyword_id_seq OWNED BY dbnext.project_record_keyword.id;


--
-- TOC entry 257 (class 1259 OID 54905)
-- Name: project_record_media; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.project_record_media (
    id bigint NOT NULL,
    id_media bigint NOT NULL,
    id_project_record bigint NOT NULL
);


ALTER TABLE dbnext.project_record_media OWNER TO postgres;

--
-- TOC entry 6478 (class 0 OID 0)
-- Dependencies: 257
-- Name: TABLE project_record_media; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.project_record_media IS 'Links media to specimens/observations in project_record';


--
-- TOC entry 258 (class 1259 OID 54911)
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
-- TOC entry 6479 (class 0 OID 0)
-- Dependencies: 258
-- Name: project_record_media_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_media_id_seq OWNED BY dbnext.project_record_media.id;


--
-- TOC entry 279 (class 1259 OID 55013)
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
-- TOC entry 6480 (class 0 OID 0)
-- Dependencies: 279
-- Name: COLUMN project_record_parent.id_keyword; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_parent.id_keyword IS 'Optional keyword defining the type of hierarchical relationship';


--
-- TOC entry 6481 (class 0 OID 0)
-- Dependencies: 279
-- Name: COLUMN project_record_parent.description; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_parent.description IS 'Optional free-text description of the specific relationship';


--
-- TOC entry 280 (class 1259 OID 55021)
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
-- TOC entry 6482 (class 0 OID 0)
-- Dependencies: 280
-- Name: project_record_parent_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_parent_id_seq OWNED BY dbnext.project_record_parent.id;


--
-- TOC entry 281 (class 1259 OID 55022)
-- Name: project_record_project; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.project_record_project (
    id bigint NOT NULL,
    id_project_record bigint NOT NULL,
    id_project bigint NOT NULL
);


ALTER TABLE dbnext.project_record_project OWNER TO postgres;

--
-- TOC entry 282 (class 1259 OID 55028)
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
-- TOC entry 6483 (class 0 OID 0)
-- Dependencies: 282
-- Name: project_record_project_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_project_id_seq OWNED BY dbnext.project_record_project.id;


--
-- TOC entry 283 (class 1259 OID 55029)
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
-- TOC entry 6484 (class 0 OID 0)
-- Dependencies: 283
-- Name: TABLE project_record_record; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON TABLE dbnext.project_record_record IS 'Horizontal (peer-to-peer) relationships between project records, qualified by a keyword defining the relationship type.';


--
-- TOC entry 6485 (class 0 OID 0)
-- Dependencies: 283
-- Name: COLUMN project_record_record.id_project_record_1; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_record.id_project_record_1 IS 'Source project_record.id of the relationship';


--
-- TOC entry 6486 (class 0 OID 0)
-- Dependencies: 283
-- Name: COLUMN project_record_record.id_project_record_2; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_record.id_project_record_2 IS 'Target project_record.id of the relationship';


--
-- TOC entry 6487 (class 0 OID 0)
-- Dependencies: 283
-- Name: COLUMN project_record_record.id_keyword; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_record.id_keyword IS 'Keyword defining the type of relationship (e.g. duplicate of, host of, same event)';


--
-- TOC entry 6488 (class 0 OID 0)
-- Dependencies: 283
-- Name: COLUMN project_record_record.description; Type: COMMENT; Schema: dbnext; Owner: postgres
--

COMMENT ON COLUMN dbnext.project_record_record.description IS 'Optional free-text description of the specific relationship';


--
-- TOC entry 284 (class 1259 OID 55038)
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
-- TOC entry 6489 (class 0 OID 0)
-- Dependencies: 284
-- Name: project_record_record_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_record_id_seq OWNED BY dbnext.project_record_record.id;


--
-- TOC entry 285 (class 1259 OID 55039)
-- Name: project_record_user; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.project_record_user (
    id bigint NOT NULL,
    id_user bigint NOT NULL,
    id_project_record bigint NOT NULL
);


ALTER TABLE dbnext.project_record_user OWNER TO postgres;

--
-- TOC entry 286 (class 1259 OID 55045)
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
-- TOC entry 6490 (class 0 OID 0)
-- Dependencies: 286
-- Name: project_record_user_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_user_id_seq OWNED BY dbnext.project_record_user.id;


--
-- TOC entry 287 (class 1259 OID 55046)
-- Name: project_record_user_keyword; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.project_record_user_keyword (
    id bigint NOT NULL,
    id_project_record_user bigint NOT NULL,
    id_keyword bigint NOT NULL
);


ALTER TABLE dbnext.project_record_user_keyword OWNER TO postgres;

--
-- TOC entry 288 (class 1259 OID 55052)
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
-- TOC entry 6491 (class 0 OID 0)
-- Dependencies: 288
-- Name: project_record_user_keyword_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.project_record_user_keyword_id_seq OWNED BY dbnext.project_record_user_keyword.id;


--
-- TOC entry 289 (class 1259 OID 55053)
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
-- TOC entry 290 (class 1259 OID 55068)
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
-- TOC entry 6492 (class 0 OID 0)
-- Dependencies: 290
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.users_id_seq OWNED BY dbnext.users.id;


--
-- TOC entry 291 (class 1259 OID 55069)
-- Name: users_keyword; Type: TABLE; Schema: dbnext; Owner: postgres
--

CREATE TABLE dbnext.users_keyword (
    id_user bigint NOT NULL,
    id_keyword bigint NOT NULL,
    id bigint NOT NULL
);


ALTER TABLE dbnext.users_keyword OWNER TO postgres;

--
-- TOC entry 292 (class 1259 OID 55075)
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
-- TOC entry 6493 (class 0 OID 0)
-- Dependencies: 292
-- Name: users_keyword_id_seq; Type: SEQUENCE OWNED BY; Schema: dbnext; Owner: postgres
--

ALTER SEQUENCE dbnext.users_keyword_id_seq OWNED BY dbnext.users_keyword.id;


--
-- TOC entry 5948 (class 2604 OID 55681)
-- Name: data_definition id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.data_definition ALTER COLUMN id SET DEFAULT nextval('dbnext.data_definition_id_seq'::regclass);


--
-- TOC entry 5949 (class 2604 OID 55682)
-- Name: data_group id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.data_group ALTER COLUMN id SET DEFAULT nextval('dbnext.data_group_id_seq'::regclass);


--
-- TOC entry 5950 (class 2604 OID 55683)
-- Name: data_predefined_values id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.data_predefined_values ALTER COLUMN id SET DEFAULT nextval('dbnext.data_predefined_values_id_seq'::regclass);


--
-- TOC entry 5951 (class 2604 OID 55684)
-- Name: external_identifier id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier ALTER COLUMN id SET DEFAULT nextval('dbnext.external_identifier_id_seq'::regclass);


--
-- TOC entry 5952 (class 2604 OID 55685)
-- Name: external_identifier_item id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier_item ALTER COLUMN id SET DEFAULT nextval('dbnext.external_identifier_item_id_seq'::regclass);


--
-- TOC entry 5953 (class 2604 OID 55686)
-- Name: external_identifier_project_record id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier_project_record ALTER COLUMN id SET DEFAULT nextval('dbnext.external_identifier_project_record_id_seq'::regclass);


--
-- TOC entry 5954 (class 2604 OID 55687)
-- Name: item id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item ALTER COLUMN id SET DEFAULT nextval('dbnext.item_id_seq'::regclass);


--
-- TOC entry 5957 (class 2604 OID 55688)
-- Name: item_keyword id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_keyword ALTER COLUMN id SET DEFAULT nextval('dbnext.item_keyword_id_seq'::regclass);


--
-- TOC entry 5958 (class 2604 OID 55689)
-- Name: item_list id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list ALTER COLUMN id SET DEFAULT nextval('dbnext.item_list_id_seq'::regclass);


--
-- TOC entry 5961 (class 2604 OID 55690)
-- Name: item_list_item id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item ALTER COLUMN id SET DEFAULT nextval('dbnext.item_list_item_id_seq'::regclass);


--
-- TOC entry 5964 (class 2604 OID 55691)
-- Name: item_list_item_keyword id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item_keyword ALTER COLUMN id SET DEFAULT nextval('dbnext.item_list_item_keyword_id_seq'::regclass);


--
-- TOC entry 5965 (class 2604 OID 55692)
-- Name: item_list_keyword id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_keyword ALTER COLUMN id SET DEFAULT nextval('dbnext.item_list_keyword_id_seq'::regclass);


--
-- TOC entry 5966 (class 2604 OID 55693)
-- Name: keyword id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.keyword ALTER COLUMN id SET DEFAULT nextval('dbnext.keyword_id_seq'::regclass);


--
-- TOC entry 5969 (class 2604 OID 55694)
-- Name: media id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.media ALTER COLUMN id SET DEFAULT nextval('dbnext.media_id_seq'::regclass);


--
-- TOC entry 5972 (class 2604 OID 55695)
-- Name: media_item id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.media_item ALTER COLUMN id SET DEFAULT nextval('dbnext.media_item_id_seq'::regclass);


--
-- TOC entry 5974 (class 2604 OID 55697)
-- Name: project id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project ALTER COLUMN id SET DEFAULT nextval('dbnext.project_id_seq'::regclass);


--
-- TOC entry 5977 (class 2604 OID 55698)
-- Name: project_item_list id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_item_list ALTER COLUMN id SET DEFAULT nextval('dbnext.project_item_list_id_seq'::regclass);


--
-- TOC entry 5979 (class 2604 OID 55699)
-- Name: project_keyword id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_keyword ALTER COLUMN id SET DEFAULT nextval('dbnext.project_keyword_id_seq'::regclass);


--
-- TOC entry 5980 (class 2604 OID 55700)
-- Name: project_record id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_id_seq'::regclass);


--
-- TOC entry 5984 (class 2604 OID 55701)
-- Name: project_record_data_group id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_data_group ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_data_group_id_seq'::regclass);


--
-- TOC entry 5985 (class 2604 OID 55702)
-- Name: project_record_determination id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_determination ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_determination_id_seq'::regclass);


--
-- TOC entry 5989 (class 2604 OID 55703)
-- Name: project_record_determination_keyword id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_determination_keyword ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_determination_keyword_id_seq'::regclass);


--
-- TOC entry 5990 (class 2604 OID 55704)
-- Name: project_record_geometry id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_geometry ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_geometry_id_seq'::regclass);


--
-- TOC entry 5991 (class 2604 OID 55705)
-- Name: project_record_identifier id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_identifier ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_identifier_id_seq'::regclass);


--
-- TOC entry 5992 (class 2604 OID 55706)
-- Name: project_record_keyword id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_keyword ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_keyword_id_seq'::regclass);


--
-- TOC entry 5973 (class 2604 OID 55696)
-- Name: project_record_media id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_media ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_media_id_seq'::regclass);


--
-- TOC entry 5993 (class 2604 OID 55707)
-- Name: project_record_parent id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_parent ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_parent_id_seq'::regclass);


--
-- TOC entry 5994 (class 2604 OID 55708)
-- Name: project_record_project id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_project ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_project_id_seq'::regclass);


--
-- TOC entry 5995 (class 2604 OID 55709)
-- Name: project_record_record id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_record ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_record_id_seq'::regclass);


--
-- TOC entry 5996 (class 2604 OID 55710)
-- Name: project_record_user id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_user ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_user_id_seq'::regclass);


--
-- TOC entry 5997 (class 2604 OID 55711)
-- Name: project_record_user_keyword id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_user_keyword ALTER COLUMN id SET DEFAULT nextval('dbnext.project_record_user_keyword_id_seq'::regclass);


--
-- TOC entry 5998 (class 2604 OID 55712)
-- Name: users id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.users ALTER COLUMN id SET DEFAULT nextval('dbnext.users_id_seq'::regclass);


--
-- TOC entry 6003 (class 2604 OID 55713)
-- Name: users_keyword id; Type: DEFAULT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.users_keyword ALTER COLUMN id SET DEFAULT nextval('dbnext.users_keyword_id_seq'::regclass);


--
-- TOC entry 6005 (class 2606 OID 55110)
-- Name: data_definition data_definition_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.data_definition
    ADD CONSTRAINT data_definition_pkey PRIMARY KEY (id);


--
-- TOC entry 6008 (class 2606 OID 55112)
-- Name: data_group data_group_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.data_group
    ADD CONSTRAINT data_group_pkey PRIMARY KEY (id);


--
-- TOC entry 6010 (class 2606 OID 55114)
-- Name: data_predefined_values data_predefined_values_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.data_predefined_values
    ADD CONSTRAINT data_predefined_values_pkey PRIMARY KEY (id);


--
-- TOC entry 6016 (class 2606 OID 55116)
-- Name: external_identifier_item external_identifier_item_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier_item
    ADD CONSTRAINT external_identifier_item_pkey PRIMARY KEY (id);


--
-- TOC entry 6012 (class 2606 OID 55118)
-- Name: external_identifier external_identifier_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier
    ADD CONSTRAINT external_identifier_pkey PRIMARY KEY (id);


--
-- TOC entry 6022 (class 2606 OID 55120)
-- Name: external_identifier_project_record external_identifier_project_record_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier_project_record
    ADD CONSTRAINT external_identifier_project_record_pkey PRIMARY KEY (id);


--
-- TOC entry 6033 (class 2606 OID 55122)
-- Name: item_keyword item_keyword_id_item_id_keyword_key; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_keyword
    ADD CONSTRAINT item_keyword_id_item_id_keyword_key UNIQUE (id_item, id_keyword);


--
-- TOC entry 6035 (class 2606 OID 55124)
-- Name: item_keyword item_keyword_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_keyword
    ADD CONSTRAINT item_keyword_pkey PRIMARY KEY (id);


--
-- TOC entry 6050 (class 2606 OID 55126)
-- Name: item_list_item_keyword item_list_item_keyword_id_item_list_item_id_keyword_key; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item_keyword
    ADD CONSTRAINT item_list_item_keyword_id_item_list_item_id_keyword_key UNIQUE (id_item_list_item, id_keyword);


--
-- TOC entry 6052 (class 2606 OID 55128)
-- Name: item_list_item_keyword item_list_item_keyword_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item_keyword
    ADD CONSTRAINT item_list_item_keyword_pkey PRIMARY KEY (id);


--
-- TOC entry 6046 (class 2606 OID 55130)
-- Name: item_list_item item_list_item_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item
    ADD CONSTRAINT item_list_item_pkey PRIMARY KEY (id);


--
-- TOC entry 6054 (class 2606 OID 55132)
-- Name: item_list_keyword item_list_keyword_id_item_list_id_keyword_key; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_keyword
    ADD CONSTRAINT item_list_keyword_id_item_list_id_keyword_key UNIQUE (id_item_list, id_keyword);


--
-- TOC entry 6056 (class 2606 OID 55134)
-- Name: item_list_keyword item_list_keyword_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_keyword
    ADD CONSTRAINT item_list_keyword_pkey PRIMARY KEY (id);


--
-- TOC entry 6039 (class 2606 OID 55136)
-- Name: item_list item_list_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list
    ADD CONSTRAINT item_list_pkey PRIMARY KEY (id);


--
-- TOC entry 6031 (class 2606 OID 55138)
-- Name: item item_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item
    ADD CONSTRAINT item_pkey PRIMARY KEY (id);


--
-- TOC entry 6059 (class 2606 OID 55140)
-- Name: keyword keyword_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.keyword
    ADD CONSTRAINT keyword_pkey PRIMARY KEY (id);


--
-- TOC entry 6068 (class 2606 OID 55142)
-- Name: media_item media_item_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.media_item
    ADD CONSTRAINT media_item_pkey PRIMARY KEY (id);


--
-- TOC entry 6064 (class 2606 OID 55144)
-- Name: media media_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.media
    ADD CONSTRAINT media_pkey PRIMARY KEY (id);


--
-- TOC entry 6163 (class 2606 OID 55148)
-- Name: users_keyword pk_users_keyword; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.users_keyword
    ADD CONSTRAINT pk_users_keyword PRIMARY KEY (id);


--
-- TOC entry 6081 (class 2606 OID 55150)
-- Name: project_item_list project_item_list_id_project_id_item_list_key; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_item_list
    ADD CONSTRAINT project_item_list_id_project_id_item_list_key UNIQUE (id_project, id_item_list);


--
-- TOC entry 6083 (class 2606 OID 55152)
-- Name: project_item_list project_item_list_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_item_list
    ADD CONSTRAINT project_item_list_pkey PRIMARY KEY (id);


--
-- TOC entry 6087 (class 2606 OID 55154)
-- Name: project_keyword project_keyword_id_project_id_keyword_key; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_keyword
    ADD CONSTRAINT project_keyword_id_project_id_keyword_key UNIQUE (id_project, id_keyword);


--
-- TOC entry 6089 (class 2606 OID 55156)
-- Name: project_keyword project_keyword_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_keyword
    ADD CONSTRAINT project_keyword_pkey PRIMARY KEY (id);


--
-- TOC entry 6079 (class 2606 OID 55158)
-- Name: project project_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project
    ADD CONSTRAINT project_pkey PRIMARY KEY (id);


--
-- TOC entry 6096 (class 2606 OID 55160)
-- Name: project_record_data_group project_record_data_group_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_data_group
    ADD CONSTRAINT project_record_data_group_pkey PRIMARY KEY (id);


--
-- TOC entry 6098 (class 2606 OID 55162)
-- Name: project_record_data_group project_record_data_group_project_data_group_key; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_data_group
    ADD CONSTRAINT project_record_data_group_project_data_group_key UNIQUE (id_project, id_data_group);


--
-- TOC entry 6109 (class 2606 OID 55164)
-- Name: project_record_determination_keyword project_record_determination_keyword_det_keyword_key; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_determination_keyword
    ADD CONSTRAINT project_record_determination_keyword_det_keyword_key UNIQUE (id_project_record_determination, id_keyword);


--
-- TOC entry 6111 (class 2606 OID 55166)
-- Name: project_record_determination_keyword project_record_determination_keyword_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_determination_keyword
    ADD CONSTRAINT project_record_determination_keyword_pkey PRIMARY KEY (id);


--
-- TOC entry 6105 (class 2606 OID 55168)
-- Name: project_record_determination project_record_determination_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_determination
    ADD CONSTRAINT project_record_determination_pkey PRIMARY KEY (id);


--
-- TOC entry 6115 (class 2606 OID 55170)
-- Name: project_record_geometry project_record_geometry_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_geometry
    ADD CONSTRAINT project_record_geometry_pkey PRIMARY KEY (id);


--
-- TOC entry 6120 (class 2606 OID 55172)
-- Name: project_record_identifier project_record_identifier_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_identifier
    ADD CONSTRAINT project_record_identifier_pkey PRIMARY KEY (id);


--
-- TOC entry 6125 (class 2606 OID 55174)
-- Name: project_record_keyword project_record_keyword_id_project_record_id_keyword_key; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_keyword
    ADD CONSTRAINT project_record_keyword_id_project_record_id_keyword_key UNIQUE (id_project_record, id_keyword);


--
-- TOC entry 6127 (class 2606 OID 55176)
-- Name: project_record_keyword project_record_keyword_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_keyword
    ADD CONSTRAINT project_record_keyword_pkey PRIMARY KEY (id);


--
-- TOC entry 6074 (class 2606 OID 55146)
-- Name: project_record_media project_record_media_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_media
    ADD CONSTRAINT project_record_media_pkey PRIMARY KEY (id);


--
-- TOC entry 6132 (class 2606 OID 55178)
-- Name: project_record_parent project_record_parent_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_parent
    ADD CONSTRAINT project_record_parent_pkey PRIMARY KEY (id);


--
-- TOC entry 6094 (class 2606 OID 55180)
-- Name: project_record project_record_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record
    ADD CONSTRAINT project_record_pkey PRIMARY KEY (id);


--
-- TOC entry 6137 (class 2606 OID 55182)
-- Name: project_record_project project_record_project_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_project
    ADD CONSTRAINT project_record_project_pkey PRIMARY KEY (id);


--
-- TOC entry 6139 (class 2606 OID 55184)
-- Name: project_record_project project_record_project_record_project_key; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_project
    ADD CONSTRAINT project_record_project_record_project_key UNIQUE (id_project_record, id_project);


--
-- TOC entry 6144 (class 2606 OID 55186)
-- Name: project_record_record project_record_record_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_record
    ADD CONSTRAINT project_record_record_pkey PRIMARY KEY (id);


--
-- TOC entry 6155 (class 2606 OID 55188)
-- Name: project_record_user_keyword project_record_user_keyword_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_user_keyword
    ADD CONSTRAINT project_record_user_keyword_pkey PRIMARY KEY (id);


--
-- TOC entry 6150 (class 2606 OID 55190)
-- Name: project_record_user project_record_user_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_user
    ADD CONSTRAINT project_record_user_pkey PRIMARY KEY (id);


--
-- TOC entry 6020 (class 2606 OID 55192)
-- Name: external_identifier_item uq_external_identifier_item; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier_item
    ADD CONSTRAINT uq_external_identifier_item UNIQUE (id_external_identifier, id_item);


--
-- TOC entry 6026 (class 2606 OID 55194)
-- Name: external_identifier_project_record uq_external_identifier_project_record; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier_project_record
    ADD CONSTRAINT uq_external_identifier_project_record UNIQUE (id_external_identifier, id_project_record);


--
-- TOC entry 6048 (class 2606 OID 55196)
-- Name: item_list_item uq_item_list_item_list_item; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item
    ADD CONSTRAINT uq_item_list_item_list_item UNIQUE (id_item_list, id_item);


--
-- TOC entry 6070 (class 2606 OID 55198)
-- Name: media_item uq_media_item; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.media_item
    ADD CONSTRAINT uq_media_item UNIQUE (id_media, id_item);


--
-- TOC entry 6122 (class 2606 OID 55202)
-- Name: project_record_identifier uq_project_record_identifier; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_identifier
    ADD CONSTRAINT uq_project_record_identifier UNIQUE (id_project_record, id_keyword, value);


--
-- TOC entry 6076 (class 2606 OID 55200)
-- Name: project_record_media uq_project_record_media; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_media
    ADD CONSTRAINT uq_project_record_media UNIQUE (id_media, id_project_record);


--
-- TOC entry 6134 (class 2606 OID 55204)
-- Name: project_record_parent uq_project_record_parent_pair; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_parent
    ADD CONSTRAINT uq_project_record_parent_pair UNIQUE (id_project_record, id_project_record_parent);


--
-- TOC entry 6146 (class 2606 OID 55206)
-- Name: project_record_record uq_project_record_record_pair; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_record
    ADD CONSTRAINT uq_project_record_record_pair UNIQUE (id_project_record_1, id_project_record_2, id_keyword);


--
-- TOC entry 6152 (class 2606 OID 55208)
-- Name: project_record_user uq_project_record_user_pair; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_user
    ADD CONSTRAINT uq_project_record_user_pair UNIQUE (id_user, id_project_record);


--
-- TOC entry 6157 (class 2606 OID 55210)
-- Name: users uq_users_email; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.users
    ADD CONSTRAINT uq_users_email UNIQUE (email);


--
-- TOC entry 6159 (class 2606 OID 55212)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 6040 (class 1259 OID 55213)
-- Name: fki_fk_id_accepted_id; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX fki_fk_id_accepted_id ON dbnext.item_list_item USING btree (id_accepted);


--
-- TOC entry 6135 (class 1259 OID 55214)
-- Name: fki_fk_project_record_project_id_project_record; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX fki_fk_project_record_project_id_project_record ON dbnext.project_record_project USING btree (id_project_record);


--
-- TOC entry 6153 (class 1259 OID 55215)
-- Name: fki_fk_project_record_user_keyword_project_record_user; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX fki_fk_project_record_user_keyword_project_record_user ON dbnext.project_record_user_keyword USING btree (id_project_record_user);


--
-- TOC entry 6160 (class 1259 OID 55216)
-- Name: fki_fk_user; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX fki_fk_user ON dbnext.users_keyword USING btree (id_user);


--
-- TOC entry 6161 (class 1259 OID 55217)
-- Name: fki_fk_user_keyword; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX fki_fk_user_keyword ON dbnext.users_keyword USING btree (id_keyword);


--
-- TOC entry 6090 (class 1259 OID 55218)
-- Name: idx_date_start_date_end; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_date_start_date_end ON dbnext.project_record USING btree (date_start) INCLUDE (date_start, date_end) WITH (deduplicate_items='true');


--
-- TOC entry 6006 (class 1259 OID 55219)
-- Name: idx_dd_group; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_dd_group ON dbnext.data_definition USING btree (id_group);


--
-- TOC entry 6013 (class 1259 OID 55220)
-- Name: idx_ei_identifier; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_ei_identifier ON dbnext.external_identifier USING btree (identifier);


--
-- TOC entry 6014 (class 1259 OID 55221)
-- Name: idx_ei_source; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_ei_source ON dbnext.external_identifier USING btree (source);


--
-- TOC entry 6017 (class 1259 OID 55222)
-- Name: idx_eii_external_identifier; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_eii_external_identifier ON dbnext.external_identifier_item USING btree (id_external_identifier);


--
-- TOC entry 6018 (class 1259 OID 55223)
-- Name: idx_eii_item; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_eii_item ON dbnext.external_identifier_item USING btree (id_item);


--
-- TOC entry 6023 (class 1259 OID 55224)
-- Name: idx_eipr_external_identifier; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_eipr_external_identifier ON dbnext.external_identifier_project_record USING btree (id_external_identifier);


--
-- TOC entry 6024 (class 1259 OID 55225)
-- Name: idx_eipr_project_record; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_eipr_project_record ON dbnext.external_identifier_project_record USING btree (id_project_record);


--
-- TOC entry 6041 (class 1259 OID 55226)
-- Name: idx_ili_identity; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_ili_identity ON dbnext.item_list_item USING btree (id_identity);


--
-- TOC entry 6042 (class 1259 OID 55227)
-- Name: idx_ili_item; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_ili_item ON dbnext.item_list_item USING btree (id_item);


--
-- TOC entry 6043 (class 1259 OID 55228)
-- Name: idx_ili_item_list; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_ili_item_list ON dbnext.item_list_item USING btree (id_item_list);


--
-- TOC entry 6044 (class 1259 OID 55229)
-- Name: idx_ili_parent; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_ili_parent ON dbnext.item_list_item USING btree (id_parent);


--
-- TOC entry 6027 (class 1259 OID 55230)
-- Name: idx_item_data; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_item_data ON dbnext.item USING gin (data jsonb_path_ops) WITH (fastupdate='true');


--
-- TOC entry 6036 (class 1259 OID 55231)
-- Name: idx_item_list; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_item_list ON dbnext.item_list USING gin (data jsonb_path_ops) WITH (fastupdate='true');


--
-- TOC entry 6037 (class 1259 OID 55232)
-- Name: idx_item_list_parent; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_item_list_parent ON dbnext.item_list USING btree (id_parent);


--
-- TOC entry 6028 (class 1259 OID 55233)
-- Name: idx_item_name; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_item_name ON dbnext.item USING btree (name);


--
-- TOC entry 6029 (class 1259 OID 55234)
-- Name: idx_item_name_trgm; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_item_name_trgm ON dbnext.item USING gin (name public.gin_trgm_ops);


--
-- TOC entry 6057 (class 1259 OID 55235)
-- Name: idx_keyword; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_keyword ON dbnext.keyword USING gin (data jsonb_path_ops) WITH (fastupdate='true');


--
-- TOC entry 6061 (class 1259 OID 55236)
-- Name: idx_media_data; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_media_data ON dbnext.media USING gin (data jsonb_path_ops) WITH (fastupdate='true');


--
-- TOC entry 6062 (class 1259 OID 55237)
-- Name: idx_media_data_group; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_media_data_group ON dbnext.media USING btree (id_data_group);


--
-- TOC entry 6065 (class 1259 OID 55238)
-- Name: idx_mi_item; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_mi_item ON dbnext.media_item USING btree (id_item);


--
-- TOC entry 6066 (class 1259 OID 55239)
-- Name: idx_mi_media; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_mi_media ON dbnext.media_item USING btree (id_media);


--
-- TOC entry 6084 (class 1259 OID 55242)
-- Name: idx_pk_keyword; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_pk_keyword ON dbnext.project_keyword USING btree (id_keyword);


--
-- TOC entry 6085 (class 1259 OID 55243)
-- Name: idx_pk_project; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_pk_project ON dbnext.project_keyword USING btree (id_project);


--
-- TOC entry 6099 (class 1259 OID 55244)
-- Name: idx_prd_determination_method; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prd_determination_method ON dbnext.project_record_determination USING btree (id_determination_method);


--
-- TOC entry 6100 (class 1259 OID 55245)
-- Name: idx_prd_determined_by; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prd_determined_by ON dbnext.project_record_determination USING btree (determined_by);


--
-- TOC entry 6101 (class 1259 OID 55246)
-- Name: idx_prd_item_list_item; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prd_item_list_item ON dbnext.project_record_determination USING btree (id_item_list_item);


--
-- TOC entry 6102 (class 1259 OID 55247)
-- Name: idx_prd_project_record; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prd_project_record ON dbnext.project_record_determination USING btree (id_project_record);


--
-- TOC entry 6103 (class 1259 OID 55248)
-- Name: idx_prd_user; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prd_user ON dbnext.project_record_determination USING btree (id_user);


--
-- TOC entry 6106 (class 1259 OID 55249)
-- Name: idx_prdk_determination; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prdk_determination ON dbnext.project_record_determination_keyword USING btree (id_project_record_determination);


--
-- TOC entry 6107 (class 1259 OID 55250)
-- Name: idx_prdk_keyword; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prdk_keyword ON dbnext.project_record_determination_keyword USING btree (id_keyword);


--
-- TOC entry 6112 (class 1259 OID 55251)
-- Name: idx_prg_geom; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prg_geom ON dbnext.project_record_geometry USING gist (geom);


--
-- TOC entry 6113 (class 1259 OID 55252)
-- Name: idx_prg_record; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prg_record ON dbnext.project_record_geometry USING btree (id_record);


--
-- TOC entry 6116 (class 1259 OID 55253)
-- Name: idx_pri_keyword; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_pri_keyword ON dbnext.project_record_identifier USING btree (id_keyword);


--
-- TOC entry 6117 (class 1259 OID 55254)
-- Name: idx_pri_project_record; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_pri_project_record ON dbnext.project_record_identifier USING btree (id_project_record);


--
-- TOC entry 6118 (class 1259 OID 55255)
-- Name: idx_pri_value; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_pri_value ON dbnext.project_record_identifier USING btree (value);


--
-- TOC entry 6123 (class 1259 OID 55256)
-- Name: idx_prk_keyword; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prk_keyword ON dbnext.project_record_keyword USING btree (id_keyword);


--
-- TOC entry 6071 (class 1259 OID 55240)
-- Name: idx_prm_media; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prm_media ON dbnext.project_record_media USING btree (id_media);


--
-- TOC entry 6072 (class 1259 OID 55241)
-- Name: idx_prm_project_record; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prm_project_record ON dbnext.project_record_media USING btree (id_project_record);


--
-- TOC entry 6077 (class 1259 OID 55257)
-- Name: idx_project; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_project ON dbnext.project USING gin (data jsonb_path_ops) WITH (fastupdate='true');


--
-- TOC entry 6091 (class 1259 OID 55258)
-- Name: idx_project_record; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_project_record ON dbnext.project_record USING gin (data jsonb_path_ops) WITH (fastupdate='true');


--
-- TOC entry 6092 (class 1259 OID 55259)
-- Name: idx_project_record_date_range; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_project_record_date_range ON dbnext.project_record USING gist (date_range);


--
-- TOC entry 6128 (class 1259 OID 55260)
-- Name: idx_prp_keyword; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prp_keyword ON dbnext.project_record_parent USING btree (id_keyword);


--
-- TOC entry 6129 (class 1259 OID 55261)
-- Name: idx_prp_parent; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prp_parent ON dbnext.project_record_parent USING btree (id_project_record_parent);


--
-- TOC entry 6130 (class 1259 OID 55262)
-- Name: idx_prp_project_record; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prp_project_record ON dbnext.project_record_parent USING btree (id_project_record);


--
-- TOC entry 6140 (class 1259 OID 55263)
-- Name: idx_prr_keyword; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prr_keyword ON dbnext.project_record_record USING btree (id_keyword);


--
-- TOC entry 6141 (class 1259 OID 55264)
-- Name: idx_prr_project_record_1; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prr_project_record_1 ON dbnext.project_record_record USING btree (id_project_record_1);


--
-- TOC entry 6142 (class 1259 OID 55265)
-- Name: idx_prr_project_record_2; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_prr_project_record_2 ON dbnext.project_record_record USING btree (id_project_record_2);


--
-- TOC entry 6147 (class 1259 OID 55266)
-- Name: idx_pru_project_record; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_pru_project_record ON dbnext.project_record_user USING btree (id_project_record);


--
-- TOC entry 6148 (class 1259 OID 55267)
-- Name: idx_pru_user; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE INDEX idx_pru_user ON dbnext.project_record_user USING btree (id_user);


--
-- TOC entry 6060 (class 1259 OID 55268)
-- Name: uq_keyword_parent_name; Type: INDEX; Schema: dbnext; Owner: postgres
--

CREATE UNIQUE INDEX uq_keyword_parent_name ON dbnext.keyword USING btree (COALESCE(id_parent, (0)::bigint), name);


--
-- TOC entry 6250 (class 2620 OID 55715)
-- Name: project_record_determination trg_prevent_last_determination_delete; Type: TRIGGER; Schema: dbnext; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_prevent_last_determination_delete AFTER DELETE ON dbnext.project_record_determination DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION dbnext.prevent_last_determination_delete();


--
-- TOC entry 6252 (class 2620 OID 55271)
-- Name: project_record_project trg_prevent_last_project_association_delete; Type: TRIGGER; Schema: dbnext; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_prevent_last_project_association_delete AFTER DELETE ON dbnext.project_record_project DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION dbnext.prevent_last_project_record_project_delete();


--
-- TOC entry 6248 (class 2620 OID 55273)
-- Name: project_record trg_project_record_requires_project; Type: TRIGGER; Schema: dbnext; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_project_record_requires_project AFTER INSERT ON dbnext.project_record DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION dbnext.check_project_record_has_project();


--
-- TOC entry 6242 (class 2620 OID 55276)
-- Name: item trg_set_date_modify; Type: TRIGGER; Schema: dbnext; Owner: postgres
--

CREATE TRIGGER trg_set_date_modify BEFORE UPDATE ON dbnext.item FOR EACH ROW EXECUTE FUNCTION dbnext.set_date_modify();


--
-- TOC entry 6243 (class 2620 OID 55277)
-- Name: item_list trg_set_date_modify; Type: TRIGGER; Schema: dbnext; Owner: postgres
--

CREATE TRIGGER trg_set_date_modify BEFORE UPDATE ON dbnext.item_list FOR EACH ROW EXECUTE FUNCTION dbnext.set_date_modify();


--
-- TOC entry 6244 (class 2620 OID 55278)
-- Name: item_list_item trg_set_date_modify; Type: TRIGGER; Schema: dbnext; Owner: postgres
--

CREATE TRIGGER trg_set_date_modify BEFORE UPDATE ON dbnext.item_list_item FOR EACH ROW EXECUTE FUNCTION dbnext.set_date_modify();


--
-- TOC entry 6245 (class 2620 OID 55279)
-- Name: keyword trg_set_date_modify; Type: TRIGGER; Schema: dbnext; Owner: postgres
--

CREATE TRIGGER trg_set_date_modify BEFORE UPDATE ON dbnext.keyword FOR EACH ROW EXECUTE FUNCTION dbnext.set_date_modify();


--
-- TOC entry 6246 (class 2620 OID 55280)
-- Name: media trg_set_date_modify; Type: TRIGGER; Schema: dbnext; Owner: postgres
--

CREATE TRIGGER trg_set_date_modify BEFORE UPDATE ON dbnext.media FOR EACH ROW EXECUTE FUNCTION dbnext.set_date_modify();


--
-- TOC entry 6247 (class 2620 OID 55281)
-- Name: project trg_set_date_modify; Type: TRIGGER; Schema: dbnext; Owner: postgres
--

CREATE TRIGGER trg_set_date_modify BEFORE UPDATE ON dbnext.project FOR EACH ROW EXECUTE FUNCTION dbnext.set_date_modify();


--
-- TOC entry 6249 (class 2620 OID 55282)
-- Name: project_record trg_set_date_modify; Type: TRIGGER; Schema: dbnext; Owner: postgres
--

CREATE TRIGGER trg_set_date_modify BEFORE UPDATE ON dbnext.project_record FOR EACH ROW EXECUTE FUNCTION dbnext.set_date_modify();


--
-- TOC entry 6251 (class 2620 OID 55283)
-- Name: project_record_determination trg_set_date_modify; Type: TRIGGER; Schema: dbnext; Owner: postgres
--

CREATE TRIGGER trg_set_date_modify BEFORE UPDATE ON dbnext.project_record_determination FOR EACH ROW EXECUTE FUNCTION dbnext.set_date_modify();


--
-- TOC entry 6164 (class 2606 OID 55284)
-- Name: data_definition fk_data_definition_group; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.data_definition
    ADD CONSTRAINT fk_data_definition_group FOREIGN KEY (id_group) REFERENCES dbnext.data_group(id);


--
-- TOC entry 6214 (class 2606 OID 55289)
-- Name: project_record_data_group fk_data_group_id; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_data_group
    ADD CONSTRAINT fk_data_group_id FOREIGN KEY (id_data_group) REFERENCES dbnext.data_group(id);


--
-- TOC entry 6165 (class 2606 OID 55294)
-- Name: data_group fk_data_group_parent; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.data_group
    ADD CONSTRAINT fk_data_group_parent FOREIGN KEY (id_parent) REFERENCES dbnext.data_group(id);


--
-- TOC entry 6167 (class 2606 OID 55299)
-- Name: external_identifier_item fk_eii_external_identifier; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier_item
    ADD CONSTRAINT fk_eii_external_identifier FOREIGN KEY (id_external_identifier) REFERENCES dbnext.external_identifier(id);


--
-- TOC entry 6168 (class 2606 OID 55304)
-- Name: external_identifier_item fk_eii_item; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier_item
    ADD CONSTRAINT fk_eii_item FOREIGN KEY (id_item) REFERENCES dbnext.item(id);


--
-- TOC entry 6169 (class 2606 OID 55309)
-- Name: external_identifier_project_record fk_eipr_external_identifier; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier_project_record
    ADD CONSTRAINT fk_eipr_external_identifier FOREIGN KEY (id_external_identifier) REFERENCES dbnext.external_identifier(id);


--
-- TOC entry 6170 (class 2606 OID 55314)
-- Name: external_identifier_project_record fk_eipr_project_record; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.external_identifier_project_record
    ADD CONSTRAINT fk_eipr_project_record FOREIGN KEY (id_project_record) REFERENCES dbnext.project_record(id) ON DELETE CASCADE;


--
-- TOC entry 6223 (class 2606 OID 55319)
-- Name: project_record_geometry fk_geometry_record; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_geometry
    ADD CONSTRAINT fk_geometry_record FOREIGN KEY (id_record) REFERENCES dbnext.project_record(id) ON DELETE CASCADE;


--
-- TOC entry 6180 (class 2606 OID 55324)
-- Name: item_list_item fk_id_accepted_id; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item
    ADD CONSTRAINT fk_id_accepted_id FOREIGN KEY (id_accepted) REFERENCES dbnext.item_list_item(id) NOT VALID;


--
-- TOC entry 6181 (class 2606 OID 55329)
-- Name: item_list_item fk_ili_created_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item
    ADD CONSTRAINT fk_ili_created_by FOREIGN KEY (created_by) REFERENCES dbnext.users(id);


--
-- TOC entry 6182 (class 2606 OID 55334)
-- Name: item_list_item fk_ili_identity; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item
    ADD CONSTRAINT fk_ili_identity FOREIGN KEY (id_identity) REFERENCES dbnext.item_list_item(id);


--
-- TOC entry 6183 (class 2606 OID 55339)
-- Name: item_list_item fk_ili_item; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item
    ADD CONSTRAINT fk_ili_item FOREIGN KEY (id_item) REFERENCES dbnext.item(id);


--
-- TOC entry 6184 (class 2606 OID 55344)
-- Name: item_list_item fk_ili_list; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item
    ADD CONSTRAINT fk_ili_list FOREIGN KEY (id_item_list) REFERENCES dbnext.item_list(id);


--
-- TOC entry 6185 (class 2606 OID 55349)
-- Name: item_list_item fk_ili_modified_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item
    ADD CONSTRAINT fk_ili_modified_by FOREIGN KEY (modified_by) REFERENCES dbnext.users(id);


--
-- TOC entry 6186 (class 2606 OID 55354)
-- Name: item_list_item fk_ili_parent; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item
    ADD CONSTRAINT fk_ili_parent FOREIGN KEY (id_parent) REFERENCES dbnext.item_list_item(id);


--
-- TOC entry 6187 (class 2606 OID 55359)
-- Name: item_list_item_keyword fk_ilik_item; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item_keyword
    ADD CONSTRAINT fk_ilik_item FOREIGN KEY (id_item_list_item) REFERENCES dbnext.item_list_item(id);


--
-- TOC entry 6188 (class 2606 OID 55364)
-- Name: item_list_item_keyword fk_ilik_keyword; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_item_keyword
    ADD CONSTRAINT fk_ilik_keyword FOREIGN KEY (id_keyword) REFERENCES dbnext.keyword(id);


--
-- TOC entry 6189 (class 2606 OID 55369)
-- Name: item_list_keyword fk_ilk_keyword; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_keyword
    ADD CONSTRAINT fk_ilk_keyword FOREIGN KEY (id_keyword) REFERENCES dbnext.keyword(id);


--
-- TOC entry 6190 (class 2606 OID 55374)
-- Name: item_list_keyword fk_ilk_list; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list_keyword
    ADD CONSTRAINT fk_ilk_list FOREIGN KEY (id_item_list) REFERENCES dbnext.item_list(id);


--
-- TOC entry 6171 (class 2606 OID 55379)
-- Name: item fk_item_created_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item
    ADD CONSTRAINT fk_item_created_by FOREIGN KEY (created_by) REFERENCES dbnext.users(id);


--
-- TOC entry 6175 (class 2606 OID 55384)
-- Name: item_list fk_item_group; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list
    ADD CONSTRAINT fk_item_group FOREIGN KEY (item_id_data_group) REFERENCES dbnext.data_group(id);


--
-- TOC entry 6173 (class 2606 OID 55389)
-- Name: item_keyword fk_item_keyword_item; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_keyword
    ADD CONSTRAINT fk_item_keyword_item FOREIGN KEY (id_item) REFERENCES dbnext.item(id);


--
-- TOC entry 6174 (class 2606 OID 55394)
-- Name: item_keyword fk_item_keyword_keyword; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_keyword
    ADD CONSTRAINT fk_item_keyword_keyword FOREIGN KEY (id_keyword) REFERENCES dbnext.keyword(id);


--
-- TOC entry 6176 (class 2606 OID 55399)
-- Name: item_list fk_item_list_created_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list
    ADD CONSTRAINT fk_item_list_created_by FOREIGN KEY (created_by) REFERENCES dbnext.users(id);


--
-- TOC entry 6177 (class 2606 OID 55404)
-- Name: item_list fk_item_list_group; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list
    ADD CONSTRAINT fk_item_list_group FOREIGN KEY (item_list_id_data_group) REFERENCES dbnext.data_group(id);


--
-- TOC entry 6178 (class 2606 OID 55409)
-- Name: item_list fk_item_list_modified_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list
    ADD CONSTRAINT fk_item_list_modified_by FOREIGN KEY (modified_by) REFERENCES dbnext.users(id);


--
-- TOC entry 6179 (class 2606 OID 55414)
-- Name: item_list fk_item_list_parent; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item_list
    ADD CONSTRAINT fk_item_list_parent FOREIGN KEY (id_parent) REFERENCES dbnext.item_list(id);


--
-- TOC entry 6172 (class 2606 OID 55419)
-- Name: item fk_item_modified_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.item
    ADD CONSTRAINT fk_item_modified_by FOREIGN KEY (modified_by) REFERENCES dbnext.users(id);


--
-- TOC entry 6191 (class 2606 OID 55424)
-- Name: keyword fk_keyword_created_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.keyword
    ADD CONSTRAINT fk_keyword_created_by FOREIGN KEY (created_by) REFERENCES dbnext.users(id);


--
-- TOC entry 6192 (class 2606 OID 55429)
-- Name: keyword fk_keyword_group; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.keyword
    ADD CONSTRAINT fk_keyword_group FOREIGN KEY (id_data_group) REFERENCES dbnext.data_group(id);


--
-- TOC entry 6193 (class 2606 OID 55434)
-- Name: keyword fk_keyword_modified_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.keyword
    ADD CONSTRAINT fk_keyword_modified_by FOREIGN KEY (modified_by) REFERENCES dbnext.users(id);


--
-- TOC entry 6194 (class 2606 OID 55439)
-- Name: keyword fk_keyword_parent; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.keyword
    ADD CONSTRAINT fk_keyword_parent FOREIGN KEY (id_parent) REFERENCES dbnext.keyword(id);


--
-- TOC entry 6195 (class 2606 OID 55444)
-- Name: media fk_media_created_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.media
    ADD CONSTRAINT fk_media_created_by FOREIGN KEY (created_by) REFERENCES dbnext.users(id);


--
-- TOC entry 6196 (class 2606 OID 55449)
-- Name: media fk_media_data_group; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.media
    ADD CONSTRAINT fk_media_data_group FOREIGN KEY (id_data_group) REFERENCES dbnext.data_group(id);


--
-- TOC entry 6197 (class 2606 OID 55454)
-- Name: media fk_media_modified_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.media
    ADD CONSTRAINT fk_media_modified_by FOREIGN KEY (modified_by) REFERENCES dbnext.users(id);


--
-- TOC entry 6198 (class 2606 OID 55459)
-- Name: media_item fk_mi_item; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.media_item
    ADD CONSTRAINT fk_mi_item FOREIGN KEY (id_item) REFERENCES dbnext.item(id);


--
-- TOC entry 6199 (class 2606 OID 55464)
-- Name: media_item fk_mi_media; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.media_item
    ADD CONSTRAINT fk_mi_media FOREIGN KEY (id_media) REFERENCES dbnext.media(id);


--
-- TOC entry 6208 (class 2606 OID 55479)
-- Name: project_item_list fk_pil_list; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_item_list
    ADD CONSTRAINT fk_pil_list FOREIGN KEY (id_item_list) REFERENCES dbnext.item_list(id);


--
-- TOC entry 6209 (class 2606 OID 55484)
-- Name: project_item_list fk_pil_project; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_item_list
    ADD CONSTRAINT fk_pil_project FOREIGN KEY (id_project) REFERENCES dbnext.project(id);


--
-- TOC entry 6210 (class 2606 OID 55489)
-- Name: project_keyword fk_pk_keyword; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_keyword
    ADD CONSTRAINT fk_pk_keyword FOREIGN KEY (id_keyword) REFERENCES dbnext.keyword(id);


--
-- TOC entry 6211 (class 2606 OID 55494)
-- Name: project_keyword fk_pk_project; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_keyword
    ADD CONSTRAINT fk_pk_project FOREIGN KEY (id_project) REFERENCES dbnext.project(id);


--
-- TOC entry 6216 (class 2606 OID 55499)
-- Name: project_record_determination fk_prd_determination_method; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_determination
    ADD CONSTRAINT fk_prd_determination_method FOREIGN KEY (id_determination_method) REFERENCES dbnext.keyword(id);


--
-- TOC entry 6217 (class 2606 OID 55504)
-- Name: project_record_determination fk_prd_determined_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_determination
    ADD CONSTRAINT fk_prd_determined_by FOREIGN KEY (determined_by) REFERENCES dbnext.users(id);


--
-- TOC entry 6218 (class 2606 OID 55509)
-- Name: project_record_determination fk_prd_item; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_determination
    ADD CONSTRAINT fk_prd_item FOREIGN KEY (id_item_list_item) REFERENCES dbnext.item_list_item(id);


--
-- TOC entry 6219 (class 2606 OID 55514)
-- Name: project_record_determination fk_prd_record; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_determination
    ADD CONSTRAINT fk_prd_record FOREIGN KEY (id_project_record) REFERENCES dbnext.project_record(id) ON DELETE CASCADE;


--
-- TOC entry 6220 (class 2606 OID 55519)
-- Name: project_record_determination fk_prd_user; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_determination
    ADD CONSTRAINT fk_prd_user FOREIGN KEY (id_user) REFERENCES dbnext.users(id);


--
-- TOC entry 6221 (class 2606 OID 55524)
-- Name: project_record_determination_keyword fk_prdk_determination; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_determination_keyword
    ADD CONSTRAINT fk_prdk_determination FOREIGN KEY (id_project_record_determination) REFERENCES dbnext.project_record_determination(id) ON DELETE CASCADE;


--
-- TOC entry 6222 (class 2606 OID 55529)
-- Name: project_record_determination_keyword fk_prdk_keyword; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_determination_keyword
    ADD CONSTRAINT fk_prdk_keyword FOREIGN KEY (id_keyword) REFERENCES dbnext.keyword(id);


--
-- TOC entry 6166 (class 2606 OID 55534)
-- Name: data_predefined_values fk_predefined_definition; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.data_predefined_values
    ADD CONSTRAINT fk_predefined_definition FOREIGN KEY (id_data_definition) REFERENCES dbnext.data_definition(id);


--
-- TOC entry 6224 (class 2606 OID 55539)
-- Name: project_record_identifier fk_pri_keyword; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_identifier
    ADD CONSTRAINT fk_pri_keyword FOREIGN KEY (id_keyword) REFERENCES dbnext.keyword(id);


--
-- TOC entry 6225 (class 2606 OID 55544)
-- Name: project_record_identifier fk_pri_project_record; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_identifier
    ADD CONSTRAINT fk_pri_project_record FOREIGN KEY (id_project_record) REFERENCES dbnext.project_record(id) ON DELETE CASCADE;


--
-- TOC entry 6226 (class 2606 OID 55549)
-- Name: project_record_keyword fk_prk_keyword; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_keyword
    ADD CONSTRAINT fk_prk_keyword FOREIGN KEY (id_keyword) REFERENCES dbnext.keyword(id);


--
-- TOC entry 6227 (class 2606 OID 55554)
-- Name: project_record_keyword fk_prk_project_record; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_keyword
    ADD CONSTRAINT fk_prk_project_record FOREIGN KEY (id_project_record) REFERENCES dbnext.project_record(id) ON DELETE CASCADE;


--
-- TOC entry 6200 (class 2606 OID 55469)
-- Name: project_record_media fk_prm_media; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_media
    ADD CONSTRAINT fk_prm_media FOREIGN KEY (id_media) REFERENCES dbnext.media(id);


--
-- TOC entry 6201 (class 2606 OID 55474)
-- Name: project_record_media fk_prm_project_record; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_media
    ADD CONSTRAINT fk_prm_project_record FOREIGN KEY (id_project_record) REFERENCES dbnext.project_record(id) ON DELETE CASCADE;


--
-- TOC entry 6202 (class 2606 OID 55559)
-- Name: project fk_project_created_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project
    ADD CONSTRAINT fk_project_created_by FOREIGN KEY (created_by) REFERENCES dbnext.users(id);


--
-- TOC entry 6203 (class 2606 OID 55564)
-- Name: project fk_project_group; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project
    ADD CONSTRAINT fk_project_group FOREIGN KEY (id_data_group) REFERENCES dbnext.data_group(id);


--
-- TOC entry 6215 (class 2606 OID 55569)
-- Name: project_record_data_group fk_project_id_project; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_data_group
    ADD CONSTRAINT fk_project_id_project FOREIGN KEY (id_project) REFERENCES dbnext.project(id);


--
-- TOC entry 6204 (class 2606 OID 55574)
-- Name: project fk_project_modified_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project
    ADD CONSTRAINT fk_project_modified_by FOREIGN KEY (modified_by) REFERENCES dbnext.users(id);


--
-- TOC entry 6205 (class 2606 OID 55579)
-- Name: project fk_project_parent; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project
    ADD CONSTRAINT fk_project_parent FOREIGN KEY (id_parent) REFERENCES dbnext.project(id);


--
-- TOC entry 6212 (class 2606 OID 55584)
-- Name: project_record fk_project_record_created_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record
    ADD CONSTRAINT fk_project_record_created_by FOREIGN KEY (created_by) REFERENCES dbnext.users(id);


--
-- TOC entry 6206 (class 2606 OID 55589)
-- Name: project fk_project_record_group; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project
    ADD CONSTRAINT fk_project_record_group FOREIGN KEY (record_id_data_group) REFERENCES dbnext.data_group(id);


--
-- TOC entry 6213 (class 2606 OID 55594)
-- Name: project_record fk_project_record_modified_by; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record
    ADD CONSTRAINT fk_project_record_modified_by FOREIGN KEY (modified_by) REFERENCES dbnext.users(id);


--
-- TOC entry 6231 (class 2606 OID 55599)
-- Name: project_record_project fk_project_record_project_id_project; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_project
    ADD CONSTRAINT fk_project_record_project_id_project FOREIGN KEY (id_project) REFERENCES dbnext.project(id);


--
-- TOC entry 6232 (class 2606 OID 55604)
-- Name: project_record_project fk_project_record_project_id_project_record; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_project
    ADD CONSTRAINT fk_project_record_project_id_project_record FOREIGN KEY (id_project_record) REFERENCES dbnext.project_record(id) ON DELETE CASCADE NOT VALID;


--
-- TOC entry 6236 (class 2606 OID 55609)
-- Name: project_record_user fk_project_record_user_id_project_record; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_user
    ADD CONSTRAINT fk_project_record_user_id_project_record FOREIGN KEY (id_project_record) REFERENCES dbnext.project_record(id) ON DELETE CASCADE;


--
-- TOC entry 6237 (class 2606 OID 55614)
-- Name: project_record_user fk_project_record_user_id_user; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_user
    ADD CONSTRAINT fk_project_record_user_id_user FOREIGN KEY (id_user) REFERENCES dbnext.users(id);


--
-- TOC entry 6238 (class 2606 OID 55619)
-- Name: project_record_user_keyword fk_project_record_user_keyword; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_user_keyword
    ADD CONSTRAINT fk_project_record_user_keyword FOREIGN KEY (id_keyword) REFERENCES dbnext.keyword(id);


--
-- TOC entry 6239 (class 2606 OID 55624)
-- Name: project_record_user_keyword fk_project_record_user_keyword_project_record_user; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_user_keyword
    ADD CONSTRAINT fk_project_record_user_keyword_project_record_user FOREIGN KEY (id_project_record_user) REFERENCES dbnext.project_record_user(id) ON DELETE CASCADE NOT VALID;


--
-- TOC entry 6207 (class 2606 OID 55629)
-- Name: project fk_project_user; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project
    ADD CONSTRAINT fk_project_user FOREIGN KEY (id_user) REFERENCES dbnext.users(id);


--
-- TOC entry 6228 (class 2606 OID 55634)
-- Name: project_record_parent fk_prp_keyword; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_parent
    ADD CONSTRAINT fk_prp_keyword FOREIGN KEY (id_keyword) REFERENCES dbnext.keyword(id);


--
-- TOC entry 6229 (class 2606 OID 55639)
-- Name: project_record_parent fk_prp_parent; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_parent
    ADD CONSTRAINT fk_prp_parent FOREIGN KEY (id_project_record_parent) REFERENCES dbnext.project_record(id) ON DELETE CASCADE;


--
-- TOC entry 6230 (class 2606 OID 55644)
-- Name: project_record_parent fk_prp_project_record; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_parent
    ADD CONSTRAINT fk_prp_project_record FOREIGN KEY (id_project_record) REFERENCES dbnext.project_record(id) ON DELETE CASCADE;


--
-- TOC entry 6233 (class 2606 OID 55649)
-- Name: project_record_record fk_prr_keyword; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_record
    ADD CONSTRAINT fk_prr_keyword FOREIGN KEY (id_keyword) REFERENCES dbnext.keyword(id);


--
-- TOC entry 6234 (class 2606 OID 55654)
-- Name: project_record_record fk_prr_project_record_1; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_record
    ADD CONSTRAINT fk_prr_project_record_1 FOREIGN KEY (id_project_record_1) REFERENCES dbnext.project_record(id) ON DELETE CASCADE;


--
-- TOC entry 6235 (class 2606 OID 55659)
-- Name: project_record_record fk_prr_project_record_2; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.project_record_record
    ADD CONSTRAINT fk_prr_project_record_2 FOREIGN KEY (id_project_record_2) REFERENCES dbnext.project_record(id) ON DELETE CASCADE;


--
-- TOC entry 6240 (class 2606 OID 55664)
-- Name: users_keyword fk_user; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.users_keyword
    ADD CONSTRAINT fk_user FOREIGN KEY (id_user) REFERENCES dbnext.users(id) NOT VALID;


--
-- TOC entry 6241 (class 2606 OID 55669)
-- Name: users_keyword fk_user_keyword; Type: FK CONSTRAINT; Schema: dbnext; Owner: postgres
--

ALTER TABLE ONLY dbnext.users_keyword
    ADD CONSTRAINT fk_user_keyword FOREIGN KEY (id_keyword) REFERENCES dbnext.keyword(id) NOT VALID;


-- Completed on 2026-05-06 10:22:29

--
-- PostgreSQL database dump complete
--

\unrestrict uY0PSwGOs1WIijaKRn1yBXGDefyFUb0kPUbKACfko6kAmIRb6Vf6gCJ2od0nq9T

