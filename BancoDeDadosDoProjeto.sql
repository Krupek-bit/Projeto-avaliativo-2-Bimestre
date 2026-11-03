--
-- PostgreSQL database dump
--

\restrict iPsgMRF4sQlregf9lmEDr9j8eGhCSOl2Iaw3XInoomFRmHkLzcpJOR0STwiE9vP

-- Dumped from database version 18.6 (ac70818)
-- Dumped by pg_dump version 18.4

-- Started on 2026-11-03 10:19:45

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
-- TOC entry 6 (class 2615 OID 24576)
-- Name: gabriel_trabalho_bd; Type: SCHEMA; Schema: -; Owner: neondb_owner
--

CREATE SCHEMA gabriel_trabalho_bd;


ALTER SCHEMA gabriel_trabalho_bd OWNER TO neondb_owner;

--
-- TOC entry 5 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- TOC entry 3640 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 264 (class 1255 OID 65582)
-- Name: fn_consumo_medio(integer); Type: FUNCTION; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE FUNCTION gabriel_trabalho_bd.fn_consumo_medio(p_id_veiculo integer) RETURNS numeric
    LANGUAGE plpgsql STABLE
    SET search_path TO 'gabriel_trabalho_bd', 'public'
    AS $$
DECLARE
    v_km_min   integer;
    v_km_max   integer;
    v_litros   numeric;
    v_primeiro numeric;
BEGIN
    SELECT MIN(quilometragem), MAX(quilometragem), SUM(litros)
      INTO v_km_min, v_km_max, v_litros
      FROM abastecimentos
     WHERE id_veiculo = p_id_veiculo;

    IF v_km_min IS NULL OR v_km_max = v_km_min THEN
        RETURN NULL;   -- dados insuficientes
    END IF;

    SELECT litros INTO v_primeiro
      FROM abastecimentos
     WHERE id_veiculo = p_id_veiculo AND quilometragem = v_km_min
     ORDER BY data_abastecimento
     LIMIT 1;

    IF (v_litros - v_primeiro) <= 0 THEN
        RETURN NULL;
    END IF;

    RETURN ROUND((v_km_max - v_km_min)::numeric / (v_litros - v_primeiro), 2);
END;
$$;


ALTER FUNCTION gabriel_trabalho_bd.fn_consumo_medio(p_id_veiculo integer) OWNER TO neondb_owner;

--
-- TOC entry 266 (class 1255 OID 65583)
-- Name: fn_custo_total_veiculo(integer, date, date); Type: FUNCTION; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE FUNCTION gabriel_trabalho_bd.fn_custo_total_veiculo(p_id_veiculo integer, p_data_inicio date, p_data_fim date) RETURNS numeric
    LANGUAGE sql STABLE
    SET search_path TO 'gabriel_trabalho_bd', 'public'
    AS $$
    SELECT
        COALESCE((SELECT SUM(valor_total) FROM abastecimentos
                   WHERE id_veiculo = p_id_veiculo
                     AND data_abastecimento BETWEEN p_data_inicio AND p_data_fim), 0)
      + COALESCE((SELECT SUM(valor) FROM manutencoes
                   WHERE id_veiculo = p_id_veiculo
                     AND data_manutencao BETWEEN p_data_inicio AND p_data_fim), 0)
      + COALESCE((SELECT SUM(valor) FROM despesas
                   WHERE id_veiculo = p_id_veiculo
                     AND data_despesa BETWEEN p_data_inicio AND p_data_fim), 0);
$$;


ALTER FUNCTION gabriel_trabalho_bd.fn_custo_total_veiculo(p_id_veiculo integer, p_data_inicio date, p_data_fim date) OWNER TO neondb_owner;

--
-- TOC entry 250 (class 1255 OID 90116)
-- Name: fn_gasto_combustivel(integer); Type: FUNCTION; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE FUNCTION gabriel_trabalho_bd.fn_gasto_combustivel(p_id_veiculo integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(valor_total), 0)
    INTO v_total
    FROM gabriel_trabalho_bd.abastecimentos
    WHERE id_veiculo = p_id_veiculo;

    RETURN v_total;
END;
$$;


ALTER FUNCTION gabriel_trabalho_bd.fn_gasto_combustivel(p_id_veiculo integer) OWNER TO neondb_owner;

--
-- TOC entry 248 (class 1255 OID 90114)
-- Name: fn_km_percorridos(integer); Type: FUNCTION; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE FUNCTION gabriel_trabalho_bd.fn_km_percorridos(p_id_veiculo integer) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_km BIGINT;
BEGIN
    SELECT COALESCE(SUM(km_final - km_inicial), 0)
    INTO v_km
    FROM gabriel_trabalho_bd.viagens
    WHERE id_veiculo = p_id_veiculo;

    RETURN v_km;
END;
$$;


ALTER FUNCTION gabriel_trabalho_bd.fn_km_percorridos(p_id_veiculo integer) OWNER TO neondb_owner;

--
-- TOC entry 267 (class 1255 OID 65584)
-- Name: fn_motorista_apto(integer); Type: FUNCTION; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE FUNCTION gabriel_trabalho_bd.fn_motorista_apto(p_id_motorista integer) RETURNS boolean
    LANGUAGE plpgsql STABLE
    SET search_path TO 'gabriel_trabalho_bd', 'public'
    AS $$
DECLARE
    v_status   varchar;
    v_validade date;
BEGIN
    SELECT status, validade_cnh INTO v_status, v_validade
      FROM motoristas WHERE id_motorista = p_id_motorista;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF v_status <> 'ativo' OR v_validade IS NULL OR v_validade < CURRENT_DATE THEN
        RETURN FALSE;
    END IF;

    IF EXISTS (SELECT 1 FROM viagens
                WHERE id_motorista = p_id_motorista AND data_retorno IS NULL) THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;
END;
$$;


ALTER FUNCTION gabriel_trabalho_bd.fn_motorista_apto(p_id_motorista integer) OWNER TO neondb_owner;

--
-- TOC entry 251 (class 1255 OID 90117)
-- Name: fn_total_abastecimentos(integer); Type: FUNCTION; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE FUNCTION gabriel_trabalho_bd.fn_total_abastecimentos(p_id_veiculo integer) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_quantidade BIGINT;
BEGIN
    SELECT COUNT(*)
    INTO v_quantidade
    FROM gabriel_trabalho_bd.abastecimentos
    WHERE id_veiculo = p_id_veiculo;

    RETURN v_quantidade;
END;
$$;


ALTER FUNCTION gabriel_trabalho_bd.fn_total_abastecimentos(p_id_veiculo integer) OWNER TO neondb_owner;

--
-- TOC entry 273 (class 1255 OID 90112)
-- Name: fn_total_despesas(integer); Type: FUNCTION; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE FUNCTION gabriel_trabalho_bd.fn_total_despesas(p_id_veiculo integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(valor), 0)
    INTO v_total
    FROM gabriel_trabalho_bd.despesas
    WHERE id_veiculo = p_id_veiculo;

    RETURN v_total;
END;
$$;


ALTER FUNCTION gabriel_trabalho_bd.fn_total_despesas(p_id_veiculo integer) OWNER TO neondb_owner;

--
-- TOC entry 274 (class 1255 OID 90113)
-- Name: fn_total_manutencao(integer); Type: FUNCTION; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE FUNCTION gabriel_trabalho_bd.fn_total_manutencao(p_id_veiculo integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(valor), 0)
    INTO v_total
    FROM gabriel_trabalho_bd.manutencoes
    WHERE id_veiculo = p_id_veiculo;

    RETURN v_total;
END;
$$;


ALTER FUNCTION gabriel_trabalho_bd.fn_total_manutencao(p_id_veiculo integer) OWNER TO neondb_owner;

--
-- TOC entry 249 (class 1255 OID 90115)
-- Name: fn_total_viagens_motorista(integer); Type: FUNCTION; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE FUNCTION gabriel_trabalho_bd.fn_total_viagens_motorista(p_id_motorista integer) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_quantidade BIGINT;
BEGIN
    SELECT COUNT(*)
    INTO v_quantidade
    FROM gabriel_trabalho_bd.viagens
    WHERE id_motorista = p_id_motorista;

    RETURN v_quantidade;
END;
$$;


ALTER FUNCTION gabriel_trabalho_bd.fn_total_viagens_motorista(p_id_motorista integer) OWNER TO neondb_owner;

--
-- TOC entry 265 (class 1255 OID 65598)
-- Name: sp_concluir_manutencao(integer); Type: PROCEDURE; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE PROCEDURE gabriel_trabalho_bd.sp_concluir_manutencao(IN p_id_veiculo integer)
    LANGUAGE plpgsql
    SET search_path TO 'gabriel_trabalho_bd', 'public'
    AS $$
BEGIN
    UPDATE veiculos SET status = 'ativo'
     WHERE id_veiculo = p_id_veiculo AND status = 'em_manutencao';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Veículo % não está em manutenção', p_id_veiculo;
    END IF;
END;
$$;


ALTER PROCEDURE gabriel_trabalho_bd.sp_concluir_manutencao(IN p_id_veiculo integer) OWNER TO neondb_owner;

--
-- TOC entry 272 (class 1255 OID 65596)
-- Name: sp_finalizar_viagem(integer, integer); Type: PROCEDURE; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE PROCEDURE gabriel_trabalho_bd.sp_finalizar_viagem(IN p_id_viagem integer, IN p_km_final integer)
    LANGUAGE plpgsql
    SET search_path TO 'gabriel_trabalho_bd', 'public'
    AS $$
DECLARE
    v_viagem viagens%ROWTYPE;
BEGIN
    SELECT * INTO v_viagem FROM viagens WHERE id_viagem = p_id_viagem FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Viagem % não encontrada', p_id_viagem;
    END IF;
    IF v_viagem.data_retorno IS NOT NULL THEN
        RAISE EXCEPTION 'Viagem % já foi finalizada', p_id_viagem;
    END IF;
    IF p_km_final < v_viagem.km_inicial THEN
        RAISE EXCEPTION 'Km final (%) menor que o km inicial (%)', p_km_final, v_viagem.km_inicial;
    END IF;

    UPDATE viagens
       SET data_retorno = NOW(), km_final = p_km_final
     WHERE id_viagem = p_id_viagem;

    UPDATE veiculos SET status = 'ativo' WHERE id_veiculo = v_viagem.id_veiculo;

    INSERT INTO hodometros (id_veiculo, data_registro, quilometragem, observacao)
    VALUES (v_viagem.id_veiculo, CURRENT_DATE, p_km_final,
            'Registro automático ao finalizar a viagem #' || p_id_viagem);
END;
$$;


ALTER PROCEDURE gabriel_trabalho_bd.sp_finalizar_viagem(IN p_id_viagem integer, IN p_km_final integer) OWNER TO neondb_owner;

--
-- TOC entry 271 (class 1255 OID 65595)
-- Name: sp_iniciar_viagem(integer, integer, character varying, character varying, integer); Type: PROCEDURE; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE PROCEDURE gabriel_trabalho_bd.sp_iniciar_viagem(IN p_id_veiculo integer, IN p_id_motorista integer, IN p_destino character varying, IN p_finalidade character varying, IN p_km_inicial integer)
    LANGUAGE plpgsql
    SET search_path TO 'gabriel_trabalho_bd', 'public'
    AS $$
DECLARE
    v_status varchar;
    v_km     integer;
BEGIN
    SELECT status, quilometragem_atual INTO v_status, v_km
      FROM veiculos WHERE id_veiculo = p_id_veiculo FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Veículo % não encontrado', p_id_veiculo;
    END IF;
    IF v_status <> 'ativo' THEN
        RAISE EXCEPTION 'Veículo % não está disponível (status: %)', p_id_veiculo, v_status;
    END IF;
    IF NOT fn_motorista_apto(p_id_motorista) THEN
        RAISE EXCEPTION 'Motorista % não está apto para dirigir', p_id_motorista;
    END IF;
    IF p_km_inicial < v_km THEN
        RAISE EXCEPTION 'Km inicial (%) menor que a quilometragem atual do veículo (%)',
            p_km_inicial, v_km;
    END IF;

    INSERT INTO viagens (id_veiculo, id_motorista, data_saida, km_inicial, destino, finalidade)
    VALUES (p_id_veiculo, p_id_motorista, NOW(), p_km_inicial, p_destino, p_finalidade);

    UPDATE veiculos SET status = 'em_viagem' WHERE id_veiculo = p_id_veiculo;
END;
$$;


ALTER PROCEDURE gabriel_trabalho_bd.sp_iniciar_viagem(IN p_id_veiculo integer, IN p_id_motorista integer, IN p_destino character varying, IN p_finalidade character varying, IN p_km_inicial integer) OWNER TO neondb_owner;

--
-- TOC entry 275 (class 1255 OID 65597)
-- Name: sp_registrar_manutencao(integer, character varying, character varying, character varying, numeric, integer); Type: PROCEDURE; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE PROCEDURE gabriel_trabalho_bd.sp_registrar_manutencao(IN p_id_veiculo integer, IN p_tipo character varying, IN p_descricao character varying, IN p_oficina character varying, IN p_valor numeric, IN p_km integer)
    LANGUAGE plpgsql
    SET search_path TO 'gabriel_trabalho_bd', 'public'
    AS $$
DECLARE
    v_status varchar;
BEGIN
    SELECT status INTO v_status FROM veiculos WHERE id_veiculo = p_id_veiculo FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Veículo % não encontrado', p_id_veiculo;
    END IF;
    IF v_status <> 'ativo' THEN
        RAISE EXCEPTION 'Veículo % não pode ir para manutenção (status: %)', p_id_veiculo, v_status;
    END IF;

    INSERT INTO manutencoes (id_veiculo, data_manutencao, tipo_manutencao, descricao,
                             oficina, valor, quilometragem)
    VALUES (p_id_veiculo, CURRENT_DATE, p_tipo, p_descricao, p_oficina, p_valor, p_km);

    UPDATE veiculos SET status = 'em_manutencao' WHERE id_veiculo = p_id_veiculo;
END;
$$;


ALTER PROCEDURE gabriel_trabalho_bd.sp_registrar_manutencao(IN p_id_veiculo integer, IN p_tipo character varying, IN p_descricao character varying, IN p_oficina character varying, IN p_valor numeric, IN p_km integer) OWNER TO neondb_owner;

--
-- TOC entry 268 (class 1255 OID 65585)
-- Name: tg_fn_abastecimento_valida(); Type: FUNCTION; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE FUNCTION gabriel_trabalho_bd.tg_fn_abastecimento_valida() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'gabriel_trabalho_bd', 'public'
    AS $$
DECLARE
    v_km_anterior integer;
BEGIN
    NEW.valor_total := ROUND(NEW.litros * NEW.valor_litro, 2);

    SELECT MAX(quilometragem) INTO v_km_anterior
      FROM abastecimentos
     WHERE id_veiculo = NEW.id_veiculo
       AND data_abastecimento < NEW.data_abastecimento
       AND id_abastecimento IS DISTINCT FROM NEW.id_abastecimento;

    IF v_km_anterior IS NOT NULL AND NEW.quilometragem < v_km_anterior THEN
        RAISE EXCEPTION 'Quilometragem % menor que a do abastecimento anterior (%) do veículo %',
            NEW.quilometragem, v_km_anterior, NEW.id_veiculo;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION gabriel_trabalho_bd.tg_fn_abastecimento_valida() OWNER TO neondb_owner;

--
-- TOC entry 262 (class 1255 OID 65591)
-- Name: tg_fn_atualiza_km_veiculo(); Type: FUNCTION; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE FUNCTION gabriel_trabalho_bd.tg_fn_atualiza_km_veiculo() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'gabriel_trabalho_bd', 'public'
    AS $$
BEGIN
    UPDATE veiculos
       SET quilometragem_atual = GREATEST(quilometragem_atual, NEW.quilometragem)
     WHERE id_veiculo = NEW.id_veiculo;
    RETURN NEW;
END;
$$;


ALTER FUNCTION gabriel_trabalho_bd.tg_fn_atualiza_km_veiculo() OWNER TO neondb_owner;

--
-- TOC entry 269 (class 1255 OID 65587)
-- Name: tg_fn_veiculo_historico_status(); Type: FUNCTION; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE FUNCTION gabriel_trabalho_bd.tg_fn_veiculo_historico_status() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'gabriel_trabalho_bd', 'public'
    AS $$
BEGIN
    INSERT INTO historico_status_veiculo (id_veiculo, status_anterior, status_novo)
    VALUES (NEW.id_veiculo, OLD.status, NEW.status);
    RETURN NEW;
END;
$$;


ALTER FUNCTION gabriel_trabalho_bd.tg_fn_veiculo_historico_status() OWNER TO neondb_owner;

--
-- TOC entry 270 (class 1255 OID 65589)
-- Name: tg_fn_viagem_valida(); Type: FUNCTION; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE FUNCTION gabriel_trabalho_bd.tg_fn_viagem_valida() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'gabriel_trabalho_bd', 'public'
    AS $$
DECLARE
    v_status varchar;
BEGIN
    IF NEW.data_retorno IS NOT NULL THEN
        RETURN NEW;
    END IF;

    SELECT status INTO v_status FROM veiculos WHERE id_veiculo = NEW.id_veiculo;

    IF v_status IS DISTINCT FROM 'ativo' THEN
        RAISE EXCEPTION 'Veículo % não está disponível (status atual: %)',
            NEW.id_veiculo, COALESCE(v_status, 'inexistente');
    END IF;

    IF EXISTS (SELECT 1 FROM viagens
                WHERE id_veiculo = NEW.id_veiculo AND data_retorno IS NULL) THEN
        RAISE EXCEPTION 'Veículo % já possui uma viagem em andamento', NEW.id_veiculo;
    END IF;

    IF NOT fn_motorista_apto(NEW.id_motorista) THEN
        RAISE EXCEPTION 'Motorista % não está apto (inativo, CNH vencida ou em viagem)',
            NEW.id_motorista;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION gabriel_trabalho_bd.tg_fn_viagem_valida() OWNER TO neondb_owner;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 228 (class 1259 OID 32821)
-- Name: abastecimentos; Type: TABLE; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE TABLE gabriel_trabalho_bd.abastecimentos (
    id_abastecimento integer NOT NULL,
    id_veiculo integer NOT NULL,
    data_abastecimento date NOT NULL,
    tipo_combustivel character varying(30) NOT NULL,
    litros numeric(10,2) NOT NULL,
    valor_litro numeric(10,2) NOT NULL,
    valor_total numeric(10,2) NOT NULL,
    quilometragem integer NOT NULL,
    CONSTRAINT chk_abast_km CHECK ((quilometragem >= 0)),
    CONSTRAINT chk_abast_litros CHECK ((litros > (0)::numeric)),
    CONSTRAINT chk_abast_valor_litro CHECK ((valor_litro > (0)::numeric)),
    CONSTRAINT chk_abast_valor_total CHECK ((valor_total >= (0)::numeric))
);


ALTER TABLE gabriel_trabalho_bd.abastecimentos OWNER TO neondb_owner;

--
-- TOC entry 227 (class 1259 OID 32820)
-- Name: abastecimentos_id_abastecimento_seq; Type: SEQUENCE; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE SEQUENCE gabriel_trabalho_bd.abastecimentos_id_abastecimento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE gabriel_trabalho_bd.abastecimentos_id_abastecimento_seq OWNER TO neondb_owner;

--
-- TOC entry 3660 (class 0 OID 0)
-- Dependencies: 227
-- Name: abastecimentos_id_abastecimento_seq; Type: SEQUENCE OWNED BY; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER SEQUENCE gabriel_trabalho_bd.abastecimentos_id_abastecimento_seq OWNED BY gabriel_trabalho_bd.abastecimentos.id_abastecimento;


--
-- TOC entry 232 (class 1259 OID 32860)
-- Name: despesas; Type: TABLE; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE TABLE gabriel_trabalho_bd.despesas (
    id_despesa integer NOT NULL,
    id_veiculo integer NOT NULL,
    data_despesa date NOT NULL,
    tipo_despesa character varying(50) NOT NULL,
    descricao character varying(255),
    valor numeric(10,2) NOT NULL,
    CONSTRAINT chk_despesa_valor CHECK ((valor >= (0)::numeric))
);


ALTER TABLE gabriel_trabalho_bd.despesas OWNER TO neondb_owner;

--
-- TOC entry 231 (class 1259 OID 32859)
-- Name: despesas_id_despesa_seq; Type: SEQUENCE; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE SEQUENCE gabriel_trabalho_bd.despesas_id_despesa_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE gabriel_trabalho_bd.despesas_id_despesa_seq OWNER TO neondb_owner;

--
-- TOC entry 3663 (class 0 OID 0)
-- Dependencies: 231
-- Name: despesas_id_despesa_seq; Type: SEQUENCE OWNED BY; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER SEQUENCE gabriel_trabalho_bd.despesas_id_despesa_seq OWNED BY gabriel_trabalho_bd.despesas.id_despesa;


--
-- TOC entry 241 (class 1259 OID 65539)
-- Name: historico_status_veiculo; Type: TABLE; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE TABLE gabriel_trabalho_bd.historico_status_veiculo (
    id_historico integer NOT NULL,
    id_veiculo integer NOT NULL,
    status_anterior character varying(20),
    status_novo character varying(20) NOT NULL,
    data_alteracao timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE gabriel_trabalho_bd.historico_status_veiculo OWNER TO neondb_owner;

--
-- TOC entry 240 (class 1259 OID 65538)
-- Name: historico_status_veiculo_id_historico_seq; Type: SEQUENCE; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE SEQUENCE gabriel_trabalho_bd.historico_status_veiculo_id_historico_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE gabriel_trabalho_bd.historico_status_veiculo_id_historico_seq OWNER TO neondb_owner;

--
-- TOC entry 3666 (class 0 OID 0)
-- Dependencies: 240
-- Name: historico_status_veiculo_id_historico_seq; Type: SEQUENCE OWNED BY; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER SEQUENCE gabriel_trabalho_bd.historico_status_veiculo_id_historico_seq OWNED BY gabriel_trabalho_bd.historico_status_veiculo.id_historico;


--
-- TOC entry 226 (class 1259 OID 32805)
-- Name: hodometros; Type: TABLE; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE TABLE gabriel_trabalho_bd.hodometros (
    id_hodometro integer NOT NULL,
    id_veiculo integer NOT NULL,
    data_registro date NOT NULL,
    quilometragem integer NOT NULL,
    observacao character varying(255)
);


ALTER TABLE gabriel_trabalho_bd.hodometros OWNER TO neondb_owner;

--
-- TOC entry 225 (class 1259 OID 32804)
-- Name: hodometros_id_hodometro_seq; Type: SEQUENCE; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE SEQUENCE gabriel_trabalho_bd.hodometros_id_hodometro_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE gabriel_trabalho_bd.hodometros_id_hodometro_seq OWNER TO neondb_owner;

--
-- TOC entry 3669 (class 0 OID 0)
-- Dependencies: 225
-- Name: hodometros_id_hodometro_seq; Type: SEQUENCE OWNED BY; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER SEQUENCE gabriel_trabalho_bd.hodometros_id_hodometro_seq OWNED BY gabriel_trabalho_bd.hodometros.id_hodometro;


--
-- TOC entry 230 (class 1259 OID 32841)
-- Name: manutencoes; Type: TABLE; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE TABLE gabriel_trabalho_bd.manutencoes (
    id_manutencao integer NOT NULL,
    id_veiculo integer NOT NULL,
    data_manutencao date NOT NULL,
    tipo_manutencao character varying(50) NOT NULL,
    descricao character varying(255) NOT NULL,
    oficina character varying(100),
    valor numeric(10,2) NOT NULL,
    quilometragem integer NOT NULL,
    CONSTRAINT chk_manut_valor CHECK ((valor >= (0)::numeric))
);


ALTER TABLE gabriel_trabalho_bd.manutencoes OWNER TO neondb_owner;

--
-- TOC entry 229 (class 1259 OID 32840)
-- Name: manutencoes_id_manutencao_seq; Type: SEQUENCE; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE SEQUENCE gabriel_trabalho_bd.manutencoes_id_manutencao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE gabriel_trabalho_bd.manutencoes_id_manutencao_seq OWNER TO neondb_owner;

--
-- TOC entry 3672 (class 0 OID 0)
-- Dependencies: 229
-- Name: manutencoes_id_manutencao_seq; Type: SEQUENCE OWNED BY; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER SEQUENCE gabriel_trabalho_bd.manutencoes_id_manutencao_seq OWNED BY gabriel_trabalho_bd.manutencoes.id_manutencao;


--
-- TOC entry 220 (class 1259 OID 24577)
-- Name: modalidade; Type: TABLE; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE TABLE gabriel_trabalho_bd.modalidade (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nome character varying(100) NOT NULL,
    descricao character varying(255)
);


ALTER TABLE gabriel_trabalho_bd.modalidade OWNER TO neondb_owner;

--
-- TOC entry 224 (class 1259 OID 32785)
-- Name: motoristas; Type: TABLE; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE TABLE gabriel_trabalho_bd.motoristas (
    id_motorista integer NOT NULL,
    nome character varying(100) NOT NULL,
    cnh character varying(20) NOT NULL,
    categoria_cnh character varying(5) NOT NULL,
    telefone character varying(20),
    data_admissao date NOT NULL,
    status character varying(20) NOT NULL,
    validade_cnh date,
    CONSTRAINT chk_motorista_status CHECK (((status)::text = ANY ((ARRAY['ativo'::character varying, 'inativo'::character varying])::text[])))
);


ALTER TABLE gabriel_trabalho_bd.motoristas OWNER TO neondb_owner;

--
-- TOC entry 223 (class 1259 OID 32784)
-- Name: motoristas_id_motorista_seq; Type: SEQUENCE; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE SEQUENCE gabriel_trabalho_bd.motoristas_id_motorista_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE gabriel_trabalho_bd.motoristas_id_motorista_seq OWNER TO neondb_owner;

--
-- TOC entry 3676 (class 0 OID 0)
-- Dependencies: 223
-- Name: motoristas_id_motorista_seq; Type: SEQUENCE OWNED BY; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER SEQUENCE gabriel_trabalho_bd.motoristas_id_motorista_seq OWNED BY gabriel_trabalho_bd.motoristas.id_motorista;


--
-- TOC entry 222 (class 1259 OID 32769)
-- Name: veiculos; Type: TABLE; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE TABLE gabriel_trabalho_bd.veiculos (
    id_veiculo integer NOT NULL,
    placa character varying(10) NOT NULL,
    marca character varying(50) NOT NULL,
    modelo character varying(50) NOT NULL,
    ano integer NOT NULL,
    tipo character varying(30) NOT NULL,
    capacidade numeric(10,2),
    status character varying(20) NOT NULL,
    quilometragem_atual integer DEFAULT 0 NOT NULL,
    CONSTRAINT chk_veiculo_ano CHECK (((ano >= 1980) AND (ano <= 2100))),
    CONSTRAINT chk_veiculo_status CHECK (((status)::text = ANY ((ARRAY['ativo'::character varying, 'em_viagem'::character varying, 'em_manutencao'::character varying, 'inativo'::character varying])::text[])))
);


ALTER TABLE gabriel_trabalho_bd.veiculos OWNER TO neondb_owner;

--
-- TOC entry 245 (class 1259 OID 73770)
-- Name: mv_consumo_veiculos; Type: MATERIALIZED VIEW; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE MATERIALIZED VIEW gabriel_trabalho_bd.mv_consumo_veiculos AS
 WITH base AS (
         SELECT abastecimentos.id_veiculo,
            min(abastecimentos.quilometragem) AS km_min,
            max(abastecimentos.quilometragem) AS km_max,
            sum(abastecimentos.litros) AS litros_total,
            sum(abastecimentos.valor_total) AS valor_total,
            count(*) AS qtd_abastecimentos
           FROM gabriel_trabalho_bd.abastecimentos
          GROUP BY abastecimentos.id_veiculo
        ), primeiro AS (
         SELECT DISTINCT ON (a.id_veiculo) a.id_veiculo,
            a.litros
           FROM (gabriel_trabalho_bd.abastecimentos a
             JOIN base b_1 ON (((b_1.id_veiculo = a.id_veiculo) AND (a.quilometragem = b_1.km_min))))
          ORDER BY a.id_veiculo, a.data_abastecimento
        )
 SELECT v.id_veiculo,
    v.placa,
    v.marca,
    v.modelo,
    v.tipo,
    COALESCE(b.qtd_abastecimentos, (0)::bigint) AS qtd_abastecimentos,
    COALESCE(b.litros_total, (0)::numeric) AS litros_total,
    COALESCE(b.valor_total, (0)::numeric) AS valor_total_combustivel,
    b.km_min,
    b.km_max,
        CASE
            WHEN ((b.km_max > b.km_min) AND ((b.litros_total - p.litros) > (0)::numeric)) THEN round((((b.km_max - b.km_min))::numeric / (b.litros_total - p.litros)), 2)
            ELSE NULL::numeric
        END AS consumo_medio_km_l,
        CASE
            WHEN (b.km_max > b.km_min) THEN round((b.valor_total / ((b.km_max - b.km_min))::numeric), 2)
            ELSE NULL::numeric
        END AS custo_combustivel_por_km
   FROM ((gabriel_trabalho_bd.veiculos v
     LEFT JOIN base b ON ((b.id_veiculo = v.id_veiculo)))
     LEFT JOIN primeiro p ON ((p.id_veiculo = v.id_veiculo)))
  WITH NO DATA;


ALTER MATERIALIZED VIEW gabriel_trabalho_bd.mv_consumo_veiculos OWNER TO neondb_owner;

--
-- TOC entry 234 (class 1259 OID 32877)
-- Name: viagens; Type: TABLE; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE TABLE gabriel_trabalho_bd.viagens (
    id_viagem integer NOT NULL,
    id_veiculo integer NOT NULL,
    id_motorista integer NOT NULL,
    data_saida timestamp without time zone NOT NULL,
    data_retorno timestamp without time zone,
    km_inicial integer NOT NULL,
    km_final integer,
    destino character varying(100) NOT NULL,
    finalidade character varying(255),
    id_modalidade uuid,
    CONSTRAINT chk_viagem_datas CHECK (((data_retorno IS NULL) OR (data_retorno >= data_saida))),
    CONSTRAINT chk_viagem_km CHECK (((km_final IS NULL) OR (km_final >= km_inicial)))
);


ALTER TABLE gabriel_trabalho_bd.viagens OWNER TO neondb_owner;

--
-- TOC entry 247 (class 1259 OID 73795)
-- Name: mv_dashboard_frota; Type: MATERIALIZED VIEW; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE MATERIALIZED VIEW gabriel_trabalho_bd.mv_dashboard_frota AS
 SELECT 1 AS id,
    ( SELECT count(*) AS count
           FROM gabriel_trabalho_bd.veiculos) AS total_veiculos,
    ( SELECT count(*) AS count
           FROM gabriel_trabalho_bd.veiculos
          WHERE ((veiculos.status)::text = 'ativo'::text)) AS veiculos_ativos,
    ( SELECT count(*) AS count
           FROM gabriel_trabalho_bd.veiculos
          WHERE ((veiculos.status)::text = 'em_viagem'::text)) AS veiculos_em_viagem,
    ( SELECT count(*) AS count
           FROM gabriel_trabalho_bd.veiculos
          WHERE ((veiculos.status)::text = 'em_manutencao'::text)) AS veiculos_em_manutencao,
    ( SELECT count(*) AS count
           FROM gabriel_trabalho_bd.veiculos
          WHERE ((veiculos.status)::text = 'inativo'::text)) AS veiculos_inativos,
    ( SELECT count(*) AS count
           FROM gabriel_trabalho_bd.motoristas
          WHERE ((motoristas.status)::text = 'ativo'::text)) AS motoristas_ativos,
    ( SELECT count(*) AS count
           FROM gabriel_trabalho_bd.motoristas
          WHERE ((motoristas.status)::text = 'inativo'::text)) AS motoristas_inativos,
    ( SELECT count(*) AS count
           FROM gabriel_trabalho_bd.viagens) AS total_viagens,
    ( SELECT count(*) AS count
           FROM gabriel_trabalho_bd.viagens
          WHERE (viagens.data_retorno IS NULL)) AS viagens_em_andamento,
    ( SELECT COALESCE(sum((viagens.km_final - viagens.km_inicial)), (0)::bigint) AS "coalesce"
           FROM gabriel_trabalho_bd.viagens
          WHERE (viagens.km_final IS NOT NULL)) AS km_total_viagens,
    ( SELECT COALESCE(sum(abastecimentos.valor_total), (0)::numeric) AS "coalesce"
           FROM gabriel_trabalho_bd.abastecimentos) AS gasto_abastecimento,
    ( SELECT COALESCE(sum(manutencoes.valor), (0)::numeric) AS "coalesce"
           FROM gabriel_trabalho_bd.manutencoes) AS gasto_manutencao,
    ( SELECT COALESCE(sum(despesas.valor), (0)::numeric) AS "coalesce"
           FROM gabriel_trabalho_bd.despesas) AS gasto_despesas,
    ((( SELECT COALESCE(sum(abastecimentos.valor_total), (0)::numeric) AS "coalesce"
           FROM gabriel_trabalho_bd.abastecimentos) + ( SELECT COALESCE(sum(manutencoes.valor), (0)::numeric) AS "coalesce"
           FROM gabriel_trabalho_bd.manutencoes)) + ( SELECT COALESCE(sum(despesas.valor), (0)::numeric) AS "coalesce"
           FROM gabriel_trabalho_bd.despesas)) AS gasto_total,
    now() AS atualizado_em
  WITH NO DATA;


ALTER MATERIALIZED VIEW gabriel_trabalho_bd.mv_dashboard_frota OWNER TO neondb_owner;

--
-- TOC entry 244 (class 1259 OID 73756)
-- Name: mv_desempenho_motoristas; Type: MATERIALIZED VIEW; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE MATERIALIZED VIEW gabriel_trabalho_bd.mv_desempenho_motoristas AS
 SELECT m.id_motorista,
    m.nome,
    m.categoria_cnh,
    m.status,
    m.validade_cnh,
        CASE
            WHEN (m.validade_cnh IS NULL) THEN 'sem_validade'::text
            WHEN (m.validade_cnh < CURRENT_DATE) THEN 'vencida'::text
            WHEN (m.validade_cnh <= (CURRENT_DATE + 30)) THEN 'vence_em_30_dias'::text
            ELSE 'regular'::text
        END AS situacao_cnh,
    count(vi.id_viagem) AS total_viagens,
    count(vi.id_viagem) FILTER (WHERE (vi.data_retorno IS NOT NULL)) AS viagens_concluidas,
    count(vi.id_viagem) FILTER (WHERE (vi.data_retorno IS NULL)) AS viagens_em_andamento,
    COALESCE(sum((vi.km_final - vi.km_inicial)) FILTER (WHERE (vi.km_final IS NOT NULL)), (0)::bigint) AS km_percorridos,
    avg((vi.data_retorno - vi.data_saida)) AS duracao_media,
    max(vi.data_saida) AS ultima_saida
   FROM (gabriel_trabalho_bd.motoristas m
     LEFT JOIN gabriel_trabalho_bd.viagens vi ON ((vi.id_motorista = m.id_motorista)))
  GROUP BY m.id_motorista, m.nome, m.categoria_cnh, m.status, m.validade_cnh
  WITH NO DATA;


ALTER MATERIALIZED VIEW gabriel_trabalho_bd.mv_desempenho_motoristas OWNER TO neondb_owner;

--
-- TOC entry 243 (class 1259 OID 73742)
-- Name: mv_gastos_mensais; Type: MATERIALIZED VIEW; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE MATERIALIZED VIEW gabriel_trabalho_bd.mv_gastos_mensais AS
 WITH lancamentos AS (
         SELECT abastecimentos.id_veiculo,
            abastecimentos.data_abastecimento AS data,
            'abastecimento'::text AS categoria,
            abastecimentos.valor_total AS valor
           FROM gabriel_trabalho_bd.abastecimentos
        UNION ALL
         SELECT manutencoes.id_veiculo,
            manutencoes.data_manutencao,
            'manutencao'::text,
            manutencoes.valor
           FROM gabriel_trabalho_bd.manutencoes
        UNION ALL
         SELECT despesas.id_veiculo,
            despesas.data_despesa,
            'despesa'::text,
            despesas.valor
           FROM gabriel_trabalho_bd.despesas
        )
 SELECT l.id_veiculo,
    v.placa,
    (date_trunc('month'::text, (l.data)::timestamp with time zone))::date AS mes,
    l.categoria,
    sum(l.valor) AS valor_total,
    count(*) AS qtd_lancamentos
   FROM (lancamentos l
     JOIN gabriel_trabalho_bd.veiculos v ON ((v.id_veiculo = l.id_veiculo)))
  GROUP BY l.id_veiculo, v.placa, (date_trunc('month'::text, (l.data)::timestamp with time zone)), l.categoria
  WITH NO DATA;


ALTER MATERIALIZED VIEW gabriel_trabalho_bd.mv_gastos_mensais OWNER TO neondb_owner;

--
-- TOC entry 242 (class 1259 OID 73728)
-- Name: mv_gastos_veiculos; Type: MATERIALIZED VIEW; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE MATERIALIZED VIEW gabriel_trabalho_bd.mv_gastos_veiculos AS
 WITH ab AS (
         SELECT abastecimentos.id_veiculo,
            sum(abastecimentos.valor_total) AS total,
            sum(abastecimentos.litros) AS litros,
            count(*) AS qtd
           FROM gabriel_trabalho_bd.abastecimentos
          GROUP BY abastecimentos.id_veiculo
        ), ma AS (
         SELECT manutencoes.id_veiculo,
            sum(manutencoes.valor) AS total,
            count(*) AS qtd
           FROM gabriel_trabalho_bd.manutencoes
          GROUP BY manutencoes.id_veiculo
        ), de AS (
         SELECT despesas.id_veiculo,
            sum(despesas.valor) AS total,
            count(*) AS qtd
           FROM gabriel_trabalho_bd.despesas
          GROUP BY despesas.id_veiculo
        )
 SELECT v.id_veiculo,
    v.placa,
    v.marca,
    v.modelo,
    v.tipo,
    v.status,
    COALESCE(ab.total, (0)::numeric) AS gastos_abastecimento,
    COALESCE(ma.total, (0)::numeric) AS gastos_manutencao,
    COALESCE(de.total, (0)::numeric) AS gastos_despesas,
    ((COALESCE(ab.total, (0)::numeric) + COALESCE(ma.total, (0)::numeric)) + COALESCE(de.total, (0)::numeric)) AS gasto_total,
    COALESCE(ab.litros, (0)::numeric) AS litros_abastecidos,
    COALESCE(ab.qtd, (0)::bigint) AS qtd_abastecimentos,
    COALESCE(ma.qtd, (0)::bigint) AS qtd_manutencoes,
    COALESCE(de.qtd, (0)::bigint) AS qtd_despesas
   FROM (((gabriel_trabalho_bd.veiculos v
     LEFT JOIN ab ON ((ab.id_veiculo = v.id_veiculo)))
     LEFT JOIN ma ON ((ma.id_veiculo = v.id_veiculo)))
     LEFT JOIN de ON ((de.id_veiculo = v.id_veiculo)))
  WITH NO DATA;


ALTER MATERIALIZED VIEW gabriel_trabalho_bd.mv_gastos_veiculos OWNER TO neondb_owner;

--
-- TOC entry 246 (class 1259 OID 73783)
-- Name: mv_manutencoes_por_tipo; Type: MATERIALIZED VIEW; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE MATERIALIZED VIEW gabriel_trabalho_bd.mv_manutencoes_por_tipo AS
 SELECT m.id_veiculo,
    v.placa,
    v.modelo,
    m.tipo_manutencao,
    count(*) AS qtd_manutencoes,
    sum(m.valor) AS valor_total,
    round(avg(m.valor), 2) AS valor_medio,
    max(m.data_manutencao) AS ultima_manutencao,
    max(m.quilometragem) AS ultimo_km
   FROM (gabriel_trabalho_bd.manutencoes m
     JOIN gabriel_trabalho_bd.veiculos v ON ((v.id_veiculo = m.id_veiculo)))
  GROUP BY m.id_veiculo, v.placa, v.modelo, m.tipo_manutencao
  WITH NO DATA;


ALTER MATERIALIZED VIEW gabriel_trabalho_bd.mv_manutencoes_por_tipo OWNER TO neondb_owner;

--
-- TOC entry 221 (class 1259 OID 32768)
-- Name: veiculos_id_veiculo_seq; Type: SEQUENCE; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE SEQUENCE gabriel_trabalho_bd.veiculos_id_veiculo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE gabriel_trabalho_bd.veiculos_id_veiculo_seq OWNER TO neondb_owner;

--
-- TOC entry 3686 (class 0 OID 0)
-- Dependencies: 221
-- Name: veiculos_id_veiculo_seq; Type: SEQUENCE OWNED BY; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER SEQUENCE gabriel_trabalho_bd.veiculos_id_veiculo_seq OWNED BY gabriel_trabalho_bd.veiculos.id_veiculo;


--
-- TOC entry 233 (class 1259 OID 32876)
-- Name: viagens_id_viagem_seq; Type: SEQUENCE; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE SEQUENCE gabriel_trabalho_bd.viagens_id_viagem_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE gabriel_trabalho_bd.viagens_id_viagem_seq OWNER TO neondb_owner;

--
-- TOC entry 3688 (class 0 OID 0)
-- Dependencies: 233
-- Name: viagens_id_viagem_seq; Type: SEQUENCE OWNED BY; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER SEQUENCE gabriel_trabalho_bd.viagens_id_viagem_seq OWNED BY gabriel_trabalho_bd.viagens.id_viagem;


--
-- TOC entry 235 (class 1259 OID 32906)
-- Name: vw_gastos_veiculos; Type: VIEW; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE VIEW gabriel_trabalho_bd.vw_gastos_veiculos AS
 SELECT id_veiculo,
    placa,
    marca,
    modelo,
    COALESCE(( SELECT sum(a.valor_total) AS sum
           FROM gabriel_trabalho_bd.abastecimentos a
          WHERE (a.id_veiculo = v.id_veiculo)), (0)::numeric) AS gastos_abastecimento,
    COALESCE(( SELECT sum(m.valor) AS sum
           FROM gabriel_trabalho_bd.manutencoes m
          WHERE (m.id_veiculo = v.id_veiculo)), (0)::numeric) AS gastos_manutencao,
    COALESCE(( SELECT sum(d.valor) AS sum
           FROM gabriel_trabalho_bd.despesas d
          WHERE (d.id_veiculo = v.id_veiculo)), (0)::numeric) AS gastos_despesas
   FROM gabriel_trabalho_bd.veiculos v;


ALTER VIEW gabriel_trabalho_bd.vw_gastos_veiculos OWNER TO neondb_owner;

--
-- TOC entry 237 (class 1259 OID 32921)
-- Name: vw_historico_abastecimentos; Type: VIEW; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE VIEW gabriel_trabalho_bd.vw_historico_abastecimentos AS
 SELECT a.id_abastecimento,
    a.id_veiculo,
    v.placa,
    v.marca,
    v.modelo,
    a.data_abastecimento,
    a.tipo_combustivel,
    a.litros,
    a.valor_litro,
    a.valor_total,
    a.quilometragem
   FROM (gabriel_trabalho_bd.abastecimentos a
     JOIN gabriel_trabalho_bd.veiculos v ON ((a.id_veiculo = v.id_veiculo)));


ALTER VIEW gabriel_trabalho_bd.vw_historico_abastecimentos OWNER TO neondb_owner;

--
-- TOC entry 236 (class 1259 OID 32911)
-- Name: vw_resumo_viagens; Type: VIEW; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE VIEW gabriel_trabalho_bd.vw_resumo_viagens AS
 SELECT vi.id_viagem,
    v.placa,
    v.modelo,
    m.nome AS motorista,
    vi.data_saida,
    vi.data_retorno,
    vi.destino,
    vi.finalidade,
    vi.km_inicial,
    vi.km_final,
    COALESCE((vi.km_final - vi.km_inicial), 0) AS km_percorridos
   FROM ((gabriel_trabalho_bd.viagens vi
     JOIN gabriel_trabalho_bd.veiculos v ON ((vi.id_veiculo = v.id_veiculo)))
     JOIN gabriel_trabalho_bd.motoristas m ON ((vi.id_motorista = m.id_motorista)));


ALTER VIEW gabriel_trabalho_bd.vw_resumo_viagens OWNER TO neondb_owner;

--
-- TOC entry 239 (class 1259 OID 57384)
-- Name: migrations; Type: TABLE; Schema: public; Owner: professor_bd
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


ALTER TABLE public.migrations OWNER TO professor_bd;

--
-- TOC entry 238 (class 1259 OID 57383)
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: professor_bd
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.migrations_id_seq OWNER TO professor_bd;

--
-- TOC entry 3693 (class 0 OID 0)
-- Dependencies: 238
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: professor_bd
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- TOC entry 3376 (class 2604 OID 32824)
-- Name: abastecimentos id_abastecimento; Type: DEFAULT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.abastecimentos ALTER COLUMN id_abastecimento SET DEFAULT nextval('gabriel_trabalho_bd.abastecimentos_id_abastecimento_seq'::regclass);


--
-- TOC entry 3378 (class 2604 OID 32863)
-- Name: despesas id_despesa; Type: DEFAULT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.despesas ALTER COLUMN id_despesa SET DEFAULT nextval('gabriel_trabalho_bd.despesas_id_despesa_seq'::regclass);


--
-- TOC entry 3381 (class 2604 OID 65542)
-- Name: historico_status_veiculo id_historico; Type: DEFAULT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.historico_status_veiculo ALTER COLUMN id_historico SET DEFAULT nextval('gabriel_trabalho_bd.historico_status_veiculo_id_historico_seq'::regclass);


--
-- TOC entry 3375 (class 2604 OID 32808)
-- Name: hodometros id_hodometro; Type: DEFAULT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.hodometros ALTER COLUMN id_hodometro SET DEFAULT nextval('gabriel_trabalho_bd.hodometros_id_hodometro_seq'::regclass);


--
-- TOC entry 3377 (class 2604 OID 32844)
-- Name: manutencoes id_manutencao; Type: DEFAULT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.manutencoes ALTER COLUMN id_manutencao SET DEFAULT nextval('gabriel_trabalho_bd.manutencoes_id_manutencao_seq'::regclass);


--
-- TOC entry 3374 (class 2604 OID 32788)
-- Name: motoristas id_motorista; Type: DEFAULT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.motoristas ALTER COLUMN id_motorista SET DEFAULT nextval('gabriel_trabalho_bd.motoristas_id_motorista_seq'::regclass);


--
-- TOC entry 3372 (class 2604 OID 32772)
-- Name: veiculos id_veiculo; Type: DEFAULT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.veiculos ALTER COLUMN id_veiculo SET DEFAULT nextval('gabriel_trabalho_bd.veiculos_id_veiculo_seq'::regclass);


--
-- TOC entry 3379 (class 2604 OID 32880)
-- Name: viagens id_viagem; Type: DEFAULT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.viagens ALTER COLUMN id_viagem SET DEFAULT nextval('gabriel_trabalho_bd.viagens_id_viagem_seq'::regclass);


--
-- TOC entry 3380 (class 2604 OID 57387)
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: professor_bd
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- TOC entry 3617 (class 0 OID 32821)
-- Dependencies: 228
-- Data for Name: abastecimentos; Type: TABLE DATA; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

COPY gabriel_trabalho_bd.abastecimentos (id_abastecimento, id_veiculo, data_abastecimento, tipo_combustivel, litros, valor_litro, valor_total, quilometragem) FROM stdin;
1	1	2026-01-10	gasolina	42.50	5.89	250.33	45500
2	1	2026-02-12	gasolina	45.20	5.95	268.94	47080
3	1	2026-03-14	gasolina	43.80	6.02	263.68	48700
4	1	2026-04-15	gasolina	44.30	6.09	269.79	50400
5	1	2026-05-16	gasolina	46.10	6.15	283.52	52150
6	1	2026-06-17	gasolina	45.70	6.19	282.88	53900
7	2	2026-01-08	etanol	48.00	4.09	196.32	38450
8	2	2026-02-10	etanol	49.50	4.15	205.43	40020
9	2	2026-03-12	etanol	47.80	4.20	200.76	41700
10	2	2026-04-14	etanol	50.10	4.25	212.93	43400
11	2	2026-05-15	etanol	49.30	4.29	211.50	45100
12	2	2026-06-16	etanol	51.00	4.35	221.85	46800
13	3	2026-01-11	gasolina	40.20	5.89	236.78	29500
14	3	2026-02-13	gasolina	42.00	5.95	249.90	31000
15	3	2026-03-15	gasolina	41.50	6.02	249.83	32600
16	3	2026-04-16	gasolina	43.20	6.09	263.09	34300
17	3	2026-05-17	gasolina	42.80	6.15	263.22	35900
18	3	2026-06-18	gasolina	44.00	6.19	272.36	37600
19	4	2026-01-09	diesel	70.00	6.19	433.30	63000
20	4	2026-02-11	diesel	75.00	6.25	468.75	65200
21	4	2026-03-13	diesel	72.50	6.30	456.75	67500
22	4	2026-04-15	diesel	78.00	6.39	498.42	69900
23	4	2026-05-16	diesel	76.50	6.45	493.43	72200
24	4	2026-06-17	diesel	80.00	6.49	519.20	74600
25	5	2026-01-10	diesel	74.00	6.19	458.06	71800
26	5	2026-02-12	diesel	76.00	6.25	475.00	74100
27	5	2026-03-14	diesel	78.00	6.30	491.40	76500
28	5	2026-04-16	diesel	75.00	6.39	479.25	78800
29	5	2026-05-17	diesel	80.00	6.45	516.00	81200
30	5	2026-06-18	diesel	79.00	6.49	512.71	83500
31	11	2026-07-08	gasolina	47.30	6.25	295.78	44700
32	11	2026-08-10	gasolina	45.80	6.29	288.08	46400
33	11	2026-09-02	gasolina	48.20	6.35	305.67	48150
34	12	2026-07-09	gasolina	51.20	6.25	320.00	52600
35	12	2026-08-11	gasolina	49.70	6.29	312.61	54400
36	12	2026-09-03	gasolina	52.10	6.35	330.84	56200
37	13	2026-07-10	gasolina	43.50	6.25	271.88	38100
38	13	2026-08-12	gasolina	45.20	6.29	284.31	39900
39	13	2026-09-04	gasolina	44.80	6.35	284.48	41700
40	14	2026-07-11	gasolina	46.30	6.25	289.38	49800
41	14	2026-08-13	gasolina	47.50	6.29	298.78	51700
42	14	2026-09-03	gasolina	48.10	6.35	305.44	53600
43	15	2026-07-12	diesel	78.00	6.55	510.90	65500
44	15	2026-08-14	diesel	82.00	6.59	540.38	67900
45	15	2026-09-04	diesel	80.50	6.65	535.33	70300
46	16	2026-07-13	diesel	76.00	6.55	497.80	60300
47	16	2026-08-15	diesel	79.50	6.59	523.91	62600
48	16	2026-09-02	diesel	81.00	6.65	538.65	64900
49	17	2026-07-14	diesel	84.00	6.55	550.20	76100
50	17	2026-08-16	diesel	82.50	6.59	543.68	78400
51	17	2026-09-03	diesel	86.00	6.65	571.90	80700
52	18	2026-07-15	gasolina	46.00	6.25	287.50	45600
53	18	2026-08-17	gasolina	47.80	6.29	300.66	47400
54	18	2026-09-04	gasolina	49.20	6.35	312.42	49200
55	19	2026-07-16	gasolina	50.00	6.25	312.50	51700
56	19	2026-08-18	gasolina	52.30	6.29	328.97	53700
57	19	2026-09-02	gasolina	51.00	6.35	323.85	55700
58	20	2026-07-17	gasolina	44.50	6.25	278.13	40300
59	20	2026-08-19	gasolina	46.00	6.29	289.34	42100
60	20	2026-09-03	gasolina	47.20	6.35	299.72	43900
61	21	2026-07-18	diesel	80.00	6.55	524.00	70900
62	21	2026-08-20	diesel	83.50	6.59	550.27	73300
63	21	2026-09-04	diesel	85.00	6.65	565.25	75700
64	22	2026-07-19	diesel	75.00	6.55	491.25	61600
65	22	2026-08-21	diesel	77.50	6.59	510.73	63800
66	22	2026-09-02	diesel	79.00	6.65	525.35	66000
67	23	2026-07-20	diesel	88.00	6.55	576.40	87500
68	23	2026-08-22	diesel	91.00	6.59	599.69	89900
69	23	2026-09-03	diesel	89.50	6.65	595.18	92300
70	24	2026-07-21	diesel	82.00	6.55	537.10	81000
71	24	2026-08-23	diesel	84.50	6.59	556.86	83400
72	24	2026-09-04	diesel	86.00	6.65	571.90	85800
73	25	2026-07-22	diesel	90.00	6.55	589.50	95900
74	25	2026-08-24	diesel	94.00	6.59	619.46	98400
75	25	2026-09-02	diesel	92.50	6.65	615.13	100900
76	26	2026-07-23	diesel	78.00	6.55	510.90	65000
77	26	2026-08-25	diesel	80.00	6.59	527.20	67200
78	26	2026-09-03	diesel	82.50	6.65	548.63	69400
79	27	2026-07-24	gasolina	45.00	6.25	281.25	41900
80	27	2026-08-26	gasolina	46.50	6.29	292.49	43700
81	27	2026-09-04	gasolina	48.00	6.35	304.80	45500
82	28	2026-07-25	gasolina	49.00	6.25	306.25	56300
83	28	2026-08-27	gasolina	51.00	6.29	320.79	58300
84	28	2026-09-02	gasolina	50.50	6.35	320.68	60300
85	29	2026-07-26	gasolina	53.00	6.25	331.25	70000
86	29	2026-08-28	gasolina	55.00	6.29	345.95	72100
87	29	2026-09-03	gasolina	54.00	6.35	342.90	74200
88	30	2026-07-27	gasolina	47.00	6.25	293.75	49900
89	30	2026-08-29	gasolina	49.50	6.29	311.36	51800
90	30	2026-09-04	gasolina	51.00	6.35	323.85	53700
91	11	2026-07-08	gasolina	47.30	6.25	295.78	44700
92	11	2026-08-10	gasolina	45.80	6.29	288.08	46400
93	11	2026-09-02	gasolina	48.20	6.35	305.67	48150
94	12	2026-07-09	gasolina	51.20	6.25	320.00	52600
95	12	2026-08-11	gasolina	49.70	6.29	312.61	54400
96	12	2026-09-03	gasolina	52.10	6.35	330.84	56200
97	13	2026-07-10	gasolina	43.50	6.25	271.88	38100
98	13	2026-08-12	gasolina	45.20	6.29	284.31	39900
99	13	2026-09-04	gasolina	44.80	6.35	284.48	41700
100	14	2026-07-11	gasolina	46.30	6.25	289.38	49800
101	14	2026-08-13	gasolina	47.50	6.29	298.78	51700
102	14	2026-09-03	gasolina	48.10	6.35	305.44	53600
103	15	2026-07-12	diesel	78.00	6.55	510.90	65500
104	15	2026-08-14	diesel	82.00	6.59	540.38	67900
105	15	2026-09-04	diesel	80.50	6.65	535.33	70300
106	16	2026-07-13	diesel	76.00	6.55	497.80	60300
107	16	2026-08-15	diesel	79.50	6.59	523.91	62600
108	16	2026-09-02	diesel	81.00	6.65	538.65	64900
109	17	2026-07-14	diesel	84.00	6.55	550.20	76100
110	17	2026-08-16	diesel	82.50	6.59	543.68	78400
111	17	2026-09-03	diesel	86.00	6.65	571.90	80700
112	18	2026-07-15	gasolina	46.00	6.25	287.50	45600
113	18	2026-08-17	gasolina	47.80	6.29	300.66	47400
114	18	2026-09-04	gasolina	49.20	6.35	312.42	49200
115	19	2026-07-16	gasolina	50.00	6.25	312.50	51700
116	19	2026-08-18	gasolina	52.30	6.29	328.97	53700
117	19	2026-09-02	gasolina	51.00	6.35	323.85	55700
118	20	2026-07-17	gasolina	44.50	6.25	278.13	40300
119	20	2026-08-19	gasolina	46.00	6.29	289.34	42100
120	20	2026-09-03	gasolina	47.20	6.35	299.72	43900
121	21	2026-07-18	diesel	80.00	6.55	524.00	70900
122	21	2026-08-20	diesel	83.50	6.59	550.27	73300
123	21	2026-09-04	diesel	85.00	6.65	565.25	75700
124	22	2026-07-19	diesel	75.00	6.55	491.25	61600
125	22	2026-08-21	diesel	77.50	6.59	510.73	63800
126	22	2026-09-02	diesel	79.00	6.65	525.35	66000
127	23	2026-07-20	diesel	88.00	6.55	576.40	87500
128	23	2026-08-22	diesel	91.00	6.59	599.69	89900
129	23	2026-09-03	diesel	89.50	6.65	595.18	92300
130	24	2026-07-21	diesel	82.00	6.55	537.10	81000
131	24	2026-08-23	diesel	84.50	6.59	556.86	83400
132	24	2026-09-04	diesel	86.00	6.65	571.90	85800
133	25	2026-07-22	diesel	90.00	6.55	589.50	95900
134	25	2026-08-24	diesel	94.00	6.59	619.46	98400
135	25	2026-09-02	diesel	92.50	6.65	615.13	100900
136	26	2026-07-23	diesel	78.00	6.55	510.90	65000
137	26	2026-08-25	diesel	80.00	6.59	527.20	67200
138	26	2026-09-03	diesel	82.50	6.65	548.63	69400
139	27	2026-07-24	gasolina	45.00	6.25	281.25	41900
140	27	2026-08-26	gasolina	46.50	6.29	292.49	43700
141	27	2026-09-04	gasolina	48.00	6.35	304.80	45500
142	28	2026-07-25	gasolina	49.00	6.25	306.25	56300
143	28	2026-08-27	gasolina	51.00	6.29	320.79	58300
144	28	2026-09-02	gasolina	50.50	6.35	320.68	60300
145	29	2026-07-26	gasolina	53.00	6.25	331.25	70000
146	29	2026-08-28	gasolina	55.00	6.29	345.95	72100
147	29	2026-09-03	gasolina	54.00	6.35	342.90	74200
148	30	2026-07-27	gasolina	47.00	6.25	293.75	49900
149	30	2026-08-29	gasolina	49.50	6.29	311.36	51800
150	30	2026-09-04	gasolina	51.00	6.35	323.85	53700
151	1	2027-01-05	gasolina	42.50	6.29	267.33	67000
152	2	2027-01-06	gasolina	45.20	6.29	284.31	68700
153	3	2027-01-07	gasolina	43.80	6.29	275.50	70400
154	4	2027-01-08	diesel	68.50	6.49	444.57	72100
155	5	2027-01-09	diesel	72.30	6.49	469.23	73800
156	6	2027-01-10	diesel	78.40	6.49	508.82	75500
157	7	2027-01-11	diesel	81.20	6.49	527.39	77200
158	8	2027-01-12	diesel	85.60	6.49	555.54	78900
159	9	2027-01-13	diesel	96.40	6.49	625.64	80600
160	10	2027-01-14	diesel	102.50	6.49	665.23	82300
161	11	2027-01-15	diesel	88.30	6.49	573.07	84000
162	12	2027-01-16	diesel	110.40	6.49	716.50	85700
163	13	2027-01-17	gasolina	40.50	6.29	254.75	87400
164	14	2027-01-18	gasolina	44.80	6.29	281.79	89100
165	15	2027-01-19	gasolina	46.20	6.29	290.60	90800
166	16	2027-01-20	gasolina	47.50	6.29	298.78	92500
167	17	2027-01-21	gasolina	49.30	6.29	310.10	94200
168	18	2027-01-22	gasolina	52.10	6.29	327.95	95900
169	19	2027-01-23	gasolina	50.80	6.29	319.53	97600
170	20	2027-01-24	gasolina	48.60	6.29	305.69	99300
171	21	2027-01-25	diesel	75.40	6.49	489.35	101000
172	22	2027-01-26	diesel	78.20	6.49	507.52	102700
173	23	2027-01-27	diesel	90.50	6.49	587.35	104400
174	24	2027-01-28	diesel	86.40	6.49	560.74	106100
175	25	2027-01-29	diesel	98.50	6.49	639.27	107800
176	26	2027-01-30	diesel	82.30	6.49	534.13	109500
177	27	2027-01-31	diesel	69.80	6.49	452.00	111200
178	28	2027-02-01	gasolina	43.70	6.29	274.87	112900
179	29	2027-02-02	gasolina	51.20	6.29	322.05	114600
180	30	2027-02-03	gasolina	47.80	6.29	300.66	116300
181	1	2027-02-05	gasolina	44.30	6.35	281.31	68600
182	2	2027-02-06	gasolina	46.10	6.35	292.74	70300
183	3	2027-02-07	gasolina	42.70	6.35	271.15	72000
184	4	2027-02-08	diesel	70.20	6.59	462.62	73700
185	5	2027-02-09	diesel	74.50	6.59	490.96	75400
186	6	2027-02-10	diesel	80.30	6.59	529.18	77100
187	7	2027-02-11	diesel	83.70	6.59	551.58	78800
188	8	2027-02-12	diesel	87.40	6.59	576.27	80500
189	9	2027-02-13	diesel	98.20	6.59	647.14	82200
190	10	2027-02-14	diesel	105.60	6.59	695.90	83900
191	11	2027-02-15	diesel	90.70	6.59	597.71	85600
192	12	2027-02-16	diesel	112.30	6.59	739.04	87300
193	13	2027-02-17	gasolina	41.80	6.35	265.43	89000
194	14	2027-02-18	gasolina	45.60	6.35	289.56	90700
195	15	2027-02-19	gasolina	47.90	6.35	304.17	92400
196	16	2027-02-20	gasolina	49.20	6.35	312.42	94100
197	17	2027-02-21	gasolina	50.70	6.35	321.95	95800
198	18	2027-02-22	gasolina	53.40	6.35	339.09	97500
199	19	2027-02-23	gasolina	52.30	6.35	332.11	99200
200	20	2027-02-24	gasolina	49.80	6.35	316.23	100900
201	21	2027-02-25	diesel	77.30	6.59	509.41	102600
202	22	2027-02-26	diesel	80.50	6.59	530.50	104300
203	23	2027-02-27	diesel	93.20	6.59	614.19	106000
204	24	2027-02-28	diesel	88.70	6.59	584.53	107700
205	25	2027-03-01	diesel	101.30	6.59	667.57	109400
206	26	2027-03-02	diesel	85.20	6.59	561.47	111100
207	27	2027-03-03	diesel	72.40	6.59	477.12	112800
208	28	2027-03-04	gasolina	45.10	6.35	286.39	114500
209	29	2027-03-05	gasolina	53.60	6.35	340.36	116200
210	30	2027-03-06	gasolina	49.30	6.35	313.06	117900
211	1	2027-03-08	gasolina	43.80	6.39	279.88	70400
212	2	2027-03-09	gasolina	47.30	6.39	302.25	72100
213	3	2027-03-10	gasolina	44.60	6.39	284.99	73800
214	4	2027-03-11	diesel	71.80	6.69	480.34	75500
215	5	2027-03-12	diesel	76.20	6.69	509.78	77200
216	6	2027-03-13	diesel	82.50	6.69	551.93	78900
217	7	2027-03-14	diesel	85.40	6.69	571.33	80600
218	8	2027-03-15	diesel	89.80	6.69	600.76	82300
219	9	2027-03-16	diesel	100.50	6.69	672.35	84000
220	10	2027-03-17	diesel	108.20	6.69	723.86	85700
221	11	2027-03-18	diesel	92.40	6.69	618.16	87400
222	12	2027-03-19	diesel	115.30	6.69	771.36	89100
223	13	2027-03-20	gasolina	42.50	6.39	271.58	90800
224	14	2027-03-21	gasolina	46.80	6.39	299.05	92500
225	15	2027-03-22	gasolina	48.70	6.39	311.19	94200
226	16	2027-03-23	gasolina	50.40	6.39	322.06	95900
227	17	2027-03-24	gasolina	52.10	6.39	332.92	97600
228	18	2027-03-25	gasolina	54.80	6.39	350.17	99300
229	19	2027-03-26	gasolina	53.20	6.39	339.95	101000
230	20	2027-03-27	gasolina	51.30	6.39	327.81	102700
231	21	2027-03-28	diesel	79.60	6.69	532.52	104400
232	22	2027-03-29	diesel	82.40	6.69	551.26	106100
233	23	2027-03-30	diesel	95.70	6.69	640.23	107800
234	24	2027-03-31	diesel	91.20	6.69	610.13	109500
235	25	2027-04-01	diesel	103.50	6.69	692.42	111200
236	26	2027-04-02	diesel	87.60	6.69	586.04	112900
237	27	2027-04-03	diesel	74.20	6.69	496.40	114600
238	28	2027-04-04	gasolina	46.50	6.39	297.14	116300
239	29	2027-04-05	gasolina	55.10	6.39	352.09	118000
240	30	2027-04-06	gasolina	50.80	6.39	324.61	119700
241	1	2027-04-08	gasolina	45.20	6.45	291.54	72200
242	2	2027-04-09	gasolina	48.10	6.45	310.25	73900
243	3	2027-04-10	gasolina	45.90	6.45	296.06	75600
244	4	2027-04-11	diesel	73.50	6.79	499.07	77300
245	5	2027-04-12	diesel	78.40	6.79	532.34	79000
246	6	2027-04-13	diesel	84.60	6.79	574.43	80700
247	7	2027-04-14	diesel	87.30	6.79	592.77	82400
248	8	2027-04-15	diesel	92.10	6.79	625.36	84100
249	9	2027-04-16	diesel	102.80	6.79	698.01	85800
250	10	2027-04-17	diesel	110.40	6.79	749.62	87500
251	11	2027-04-18	diesel	94.30	6.79	640.30	89200
252	12	2027-04-19	diesel	118.20	6.79	802.28	90900
253	13	2027-04-20	gasolina	43.90	6.45	283.16	92600
254	14	2027-04-21	gasolina	48.20	6.45	310.89	94300
255	15	2027-04-22	gasolina	50.10	6.45	323.15	96000
256	16	2027-04-23	gasolina	51.80	6.45	334.11	97700
257	17	2027-04-24	gasolina	53.40	6.45	344.43	99400
258	18	2027-04-25	gasolina	56.20	6.45	362.49	101100
259	19	2027-04-26	gasolina	54.70	6.45	352.82	102800
260	20	2027-04-27	gasolina	52.60	6.45	339.27	104500
261	21	2027-04-28	diesel	81.20	6.79	551.35	106200
262	22	2027-04-29	diesel	84.70	6.79	575.11	107900
263	23	2027-04-30	diesel	98.40	6.79	668.14	109600
264	24	2027-05-01	diesel	93.80	6.79	636.90	111300
265	25	2027-05-02	diesel	106.20	6.79	721.10	113000
266	26	2027-05-03	diesel	89.40	6.79	607.03	114700
267	27	2027-05-04	diesel	76.80	6.79	521.47	116400
268	28	2027-05-05	gasolina	48.10	6.45	310.25	118100
269	29	2027-05-06	gasolina	57.30	6.45	369.59	119800
270	30	2027-05-07	gasolina	52.40	6.45	337.98	121500
271	1	2027-05-09	gasolina	46.70	6.49	303.08	74000
272	2	2027-05-10	gasolina	49.50	6.49	321.26	75700
273	3	2027-05-11	gasolina	47.30	6.49	306.92	77400
274	4	2027-05-12	diesel	75.20	6.89	518.13	79100
275	5	2027-05-13	diesel	80.10	6.89	552.11	80800
276	6	2027-05-14	diesel	86.30	6.89	594.41	82500
277	7	2027-05-15	diesel	89.50	6.89	616.66	84200
278	8	2027-05-16	diesel	94.30	6.89	649.73	85900
279	9	2027-05-17	diesel	104.60	6.89	720.19	87600
280	10	2027-05-18	diesel	112.50	6.89	775.13	89300
281	11	2027-05-19	diesel	96.20	6.89	662.82	91000
282	12	2027-05-20	diesel	121.40	6.89	836.45	92700
283	13	2027-05-21	gasolina	45.30	6.49	293.99	94400
284	14	2027-05-22	gasolina	49.60	6.49	321.90	96100
285	15	2027-05-23	gasolina	51.80	6.49	336.18	97800
286	16	2027-05-24	gasolina	53.20	6.49	345.27	99500
287	17	2027-05-25	gasolina	55.10	6.49	357.60	101200
288	18	2027-05-26	gasolina	57.40	6.49	372.53	102900
289	19	2027-05-27	gasolina	56.20	6.49	364.74	104600
290	20	2027-05-28	gasolina	54.30	6.49	352.41	106300
291	21	2027-05-29	diesel	83.10	6.89	572.26	108000
292	22	2027-05-30	diesel	86.80	6.89	598.05	109700
293	23	2027-05-31	diesel	101.20	6.89	697.27	111400
294	24	2027-06-01	diesel	96.40	6.89	664.20	113100
295	25	2027-06-02	diesel	109.30	6.89	753.08	114800
296	26	2027-06-03	diesel	91.80	6.89	632.50	116500
297	27	2027-06-04	diesel	78.40	6.89	540.18	118200
298	28	2027-06-05	gasolina	49.60	6.49	321.90	119900
299	29	2027-06-06	gasolina	58.40	6.49	379.02	121600
300	30	2027-06-07	gasolina	53.70	6.49	348.51	123300
2271	1	2026-11-04	Diesel S10	63.37	5.29	335.23	78060
301	1	2026-10-29	Gasolina	32.00	6.29	201.28	77860
302	2	2026-10-29	Diesel	34.00	6.15	209.10	79570
303	3	2026-10-29	Etanol	36.00	4.49	161.64	81280
304	4	2026-10-29	Diesel	38.00	6.15	233.70	82990
305	5	2026-10-29	Gasolina	40.00	6.29	251.60	84700
306	6	2026-10-29	Etanol	42.00	4.49	188.58	98910
307	7	2026-10-29	Gasolina	44.00	6.29	276.76	88120
308	8	2026-10-29	Diesel	46.00	6.15	282.90	89830
309	9	2026-10-29	Etanol	48.00	4.49	215.52	126640
310	10	2026-10-29	Diesel	50.00	6.15	307.50	154550
311	46	2026-01-08	etanol	40.57	4.49	182.16	111010
312	31	2026-01-10	diesel	90.01	6.22	559.86	35668
313	34	2026-01-10	diesel	54.12	6.22	336.63	34159
314	47	2026-01-10	gasolina	40.86	6.24	254.97	66652
315	36	2026-01-11	diesel	65.60	6.08	398.85	43317
316	48	2026-01-11	gasolina	46.03	5.81	267.43	114320
317	49	2026-01-17	etanol	42.01	4.23	177.70	65302
318	32	2026-01-18	diesel	123.67	6.44	796.43	104996
319	37	2026-01-18	diesel	74.81	6.24	466.81	116764
320	43	2026-01-21	gasolina	59.23	6.06	358.93	99804
321	42	2026-01-22	diesel	52.83	6.28	331.77	69476
322	39	2026-01-23	gasolina	44.12	6.19	273.10	58199
323	35	2026-01-24	diesel	47.36	6.16	291.74	104141
324	38	2026-01-25	gasolina	41.22	5.84	240.72	119964
325	44	2026-01-26	diesel	50.73	6.44	326.70	78511
326	40	2026-01-27	gasolina	37.03	6.10	225.88	73229
327	45	2026-01-27	gasolina	42.16	6.19	260.97	32862
328	50	2026-01-27	gasolina	35.75	6.25	223.44	90646
329	33	2026-01-28	diesel	91.71	5.96	546.59	113522
330	41	2026-01-28	diesel	52.10	6.19	322.50	97774
331	31	2026-02-09	diesel	126.61	6.01	760.93	36514
332	42	2026-02-14	diesel	52.12	5.95	310.11	70301
333	33	2026-02-17	diesel	136.01	6.36	865.02	114608
334	35	2026-02-17	diesel	69.63	6.42	447.02	106964
335	41	2026-02-17	gasolina	70.53	6.23	439.40	100058
336	37	2026-02-18	diesel	54.32	5.90	320.49	118531
337	39	2026-02-18	etanol	46.58	4.54	211.47	59593
338	47	2026-02-18	etanol	46.37	4.07	188.73	68866
339	48	2026-02-18	etanol	40.16	4.37	175.50	116700
340	46	2026-02-19	gasolina	43.90	6.13	269.11	113098
341	40	2026-02-20	gasolina	48.72	6.34	308.88	74613
342	43	2026-02-21	diesel	68.88	6.00	413.28	102061
343	45	2026-02-21	gasolina	33.39	5.78	192.99	34440
344	49	2026-02-22	gasolina	46.76	5.82	272.14	67172
345	36	2026-02-23	diesel	49.16	6.35	312.17	44308
346	44	2026-02-24	diesel	72.99	6.02	439.40	80424
347	34	2026-02-25	diesel	66.78	6.26	418.04	35666
348	38	2026-02-26	gasolina	44.10	6.18	272.54	121227
349	50	2026-02-26	gasolina	41.30	6.15	254.00	92704
350	32	2026-02-27	diesel	136.79	6.23	852.20	106130
351	38	2026-03-08	etanol	47.32	4.21	199.22	123661
352	45	2026-03-08	gasolina	42.12	6.16	259.46	36179
353	46	2026-03-08	gasolina	34.89	6.00	209.34	114570
354	34	2026-03-10	diesel	67.98	6.06	411.96	37357
355	33	2026-03-12	diesel	102.97	5.98	615.76	117319
356	50	2026-03-12	etanol	37.42	4.10	153.42	94033
357	41	2026-03-14	diesel	64.19	6.37	408.89	100752
358	43	2026-03-14	diesel	74.85	6.34	474.55	103921
359	44	2026-03-16	diesel	53.51	5.95	318.38	82129
360	40	2026-03-18	etanol	47.36	4.14	196.07	76039
361	36	2026-03-19	diesel	63.88	6.27	400.53	46186
362	49	2026-03-19	gasolina	43.24	5.94	256.85	69946
363	42	2026-03-20	gasolina	57.49	6.14	352.99	72244
364	47	2026-03-21	etanol	40.24	4.48	180.28	70433
365	35	2026-03-22	diesel	46.12	6.22	286.87	108093
366	39	2026-03-22	gasolina	47.84	6.19	296.13	61495
367	48	2026-03-22	etanol	32.56	4.37	142.29	119767
368	32	2026-03-27	diesel	92.28	6.12	564.75	107278
369	31	2026-03-28	diesel	135.11	6.43	868.76	39272
370	37	2026-03-28	diesel	64.77	6.15	398.34	119524
371	47	2026-04-09	gasolina	33.24	5.76	191.46	72046
372	33	2026-04-10	diesel	96.38	6.08	585.99	118874
373	48	2026-04-10	gasolina	33.69	6.00	202.14	121774
374	41	2026-04-12	gasolina	68.43	5.79	396.21	102432
375	38	2026-04-14	etanol	46.67	4.01	187.15	124558
376	46	2026-04-14	etanol	40.03	4.40	176.13	116009
377	36	2026-04-16	diesel	47.50	6.27	297.83	47184
378	40	2026-04-18	gasolina	41.35	6.33	261.75	77819
379	44	2026-04-18	gasolina	69.19	6.34	438.66	83919
380	50	2026-04-18	gasolina	37.76	6.29	237.51	95617
381	32	2026-04-19	diesel	117.76	6.44	758.37	108790
382	43	2026-04-19	gasolina	50.72	5.96	302.29	104946
383	45	2026-04-21	gasolina	35.94	5.97	214.56	38838
384	34	2026-04-23	diesel	70.59	6.44	454.60	39373
385	37	2026-04-25	diesel	48.16	6.35	305.82	121867
386	42	2026-04-25	gasolina	53.33	5.96	317.85	73660
387	49	2026-04-25	gasolina	32.74	5.79	189.56	72627
388	31	2026-04-26	diesel	111.44	5.90	657.50	40751
389	35	2026-04-26	diesel	61.93	6.11	378.39	110611
390	39	2026-04-27	gasolina	38.31	6.21	237.91	64736
391	45	2026-05-09	gasolina	32.11	6.05	194.27	40123
392	37	2026-05-10	diesel	70.80	6.09	431.17	122668
393	31	2026-05-12	diesel	136.17	6.42	874.21	42001
394	35	2026-05-12	diesel	73.78	6.24	460.39	112492
395	40	2026-05-12	gasolina	40.92	6.00	245.52	80445
396	38	2026-05-14	etanol	49.45	4.23	209.17	126985
397	41	2026-05-14	diesel	72.61	5.97	433.48	103597
398	36	2026-05-17	diesel	52.14	6.11	318.58	49096
399	39	2026-05-17	etanol	42.00	4.22	177.24	66779
400	43	2026-05-17	gasolina	69.80	5.76	402.05	107669
401	33	2026-05-19	diesel	112.87	6.24	704.31	121195
402	32	2026-05-20	diesel	141.68	6.27	888.33	110369
403	48	2026-05-20	gasolina	42.85	6.32	270.81	123032
404	42	2026-05-21	diesel	69.94	6.02	421.04	75435
405	46	2026-05-23	gasolina	43.81	6.02	263.74	118029
406	44	2026-05-24	diesel	52.96	6.22	329.41	86201
407	47	2026-05-24	gasolina	46.65	6.24	291.10	73860
408	34	2026-05-25	diesel	54.54	6.09	332.15	40652
409	49	2026-05-26	gasolina	32.59	5.88	191.63	74191
410	50	2026-05-28	gasolina	38.68	6.13	237.11	96840
411	35	2026-06-10	diesel	71.95	5.97	429.54	114234
412	40	2026-06-10	etanol	43.73	4.07	177.98	81978
413	37	2026-06-11	diesel	55.39	5.98	331.23	124650
414	38	2026-06-11	etanol	37.39	4.43	165.64	128448
415	43	2026-06-11	diesel	60.36	6.11	368.80	109608
416	36	2026-06-13	diesel	62.84	6.22	390.86	52449
417	42	2026-06-13	gasolina	62.75	6.32	396.58	77288
418	47	2026-06-13	etanol	37.86	3.97	150.30	75937
419	50	2026-06-13	gasolina	40.92	5.81	237.75	98713
420	33	2026-06-15	diesel	118.46	6.17	730.90	122461
421	48	2026-06-16	gasolina	36.25	5.96	216.05	124177
422	44	2026-06-17	gasolina	54.73	5.99	327.83	88875
423	49	2026-06-18	gasolina	37.28	6.12	228.15	77694
424	32	2026-06-21	diesel	107.51	6.35	682.69	110887
425	39	2026-06-22	gasolina	44.46	5.92	263.20	68296
426	46	2026-06-23	etanol	33.44	4.06	135.77	119669
427	34	2026-06-24	diesel	70.90	6.00	425.40	42371
428	41	2026-06-25	gasolina	55.12	6.23	343.40	105693
429	31	2026-06-27	diesel	122.75	6.16	756.14	43250
430	45	2026-06-28	etanol	43.74	4.02	175.83	42039
431	35	2026-07-09	diesel	50.05	6.37	318.82	116508
432	38	2026-07-10	gasolina	41.99	5.80	243.54	130612
433	43	2026-07-10	gasolina	66.41	5.90	391.82	111441
434	32	2026-07-11	diesel	142.71	6.05	863.40	112507
435	42	2026-07-11	gasolina	70.88	5.88	416.77	79274
436	37	2026-07-12	diesel	72.54	6.20	449.75	127682
437	31	2026-07-13	diesel	142.56	6.18	881.02	44988
438	40	2026-07-13	gasolina	38.99	6.02	234.72	84614
439	48	2026-07-14	gasolina	33.09	5.95	196.89	125229
440	44	2026-07-15	gasolina	51.89	6.33	328.46	90108
441	49	2026-07-16	gasolina	39.85	6.02	239.90	80190
442	50	2026-07-17	etanol	40.38	4.18	168.79	99908
443	36	2026-07-18	diesel	54.21	6.19	335.56	54082
444	41	2026-07-19	gasolina	62.14	5.78	359.17	107158
445	45	2026-07-20	gasolina	35.48	6.20	219.98	44286
446	46	2026-07-21	gasolina	34.54	5.96	205.86	120936
447	47	2026-07-22	gasolina	41.77	6.24	260.64	78079
448	39	2026-07-24	etanol	45.43	3.99	181.27	69169
449	33	2026-07-26	diesel	139.72	6.28	877.44	123970
450	34	2026-07-27	diesel	60.62	6.11	370.39	43974
451	32	2026-08-08	diesel	107.82	6.13	660.94	114317
452	37	2026-08-10	diesel	47.73	6.28	299.74	128843
453	42	2026-08-10	diesel	71.95	6.05	435.30	81943
454	47	2026-08-10	etanol	39.22	4.25	166.69	79106
455	35	2026-08-11	diesel	67.47	5.94	400.77	119375
456	36	2026-08-11	diesel	72.61	6.00	435.66	55351
457	45	2026-08-13	gasolina	34.33	5.89	202.20	46388
458	49	2026-08-14	etanol	44.75	4.17	186.61	81393
459	38	2026-08-15	gasolina	40.51	6.15	249.14	132769
460	39	2026-08-16	etanol	46.17	4.20	193.91	70390
461	31	2026-08-17	diesel	146.10	6.33	924.81	47722
462	41	2026-08-18	gasolina	72.73	5.92	430.56	108378
463	34	2026-08-21	diesel	74.39	5.92	440.39	45971
464	40	2026-08-21	etanol	38.98	4.44	173.07	85809
465	46	2026-08-21	etanol	33.78	4.14	139.85	123030
466	43	2026-08-22	gasolina	55.54	5.77	320.47	113382
467	50	2026-08-22	gasolina	41.48	5.94	246.39	101129
468	33	2026-08-23	diesel	110.71	5.94	657.62	126754
469	44	2026-08-25	diesel	54.13	6.32	342.10	92084
470	48	2026-08-26	etanol	45.17	4.32	195.13	127636
471	40	2026-09-08	etanol	47.12	4.26	200.73	86773
472	49	2026-09-10	gasolina	33.65	6.10	205.27	83521
473	32	2026-09-11	diesel	122.53	6.09	746.21	115609
474	37	2026-09-11	diesel	58.25	5.93	345.42	131036
475	38	2026-09-11	gasolina	40.10	5.81	232.98	135433
476	35	2026-09-12	diesel	66.97	6.37	426.60	120749
477	47	2026-09-12	gasolina	43.08	5.76	248.14	80274
478	33	2026-09-13	diesel	136.68	6.05	826.91	127939
479	46	2026-09-13	gasolina	32.83	5.80	190.41	124113
480	31	2026-09-14	diesel	120.46	6.11	736.01	48387
481	34	2026-09-16	diesel	60.24	6.19	372.89	48782
482	44	2026-09-16	gasolina	61.97	5.89	365.00	94540
483	39	2026-09-18	gasolina	45.59	6.06	276.28	72303
484	41	2026-09-21	gasolina	66.98	5.90	395.18	109935
485	45	2026-09-23	etanol	39.57	4.36	172.53	48144
486	43	2026-09-24	gasolina	59.65	6.15	366.85	115567
487	50	2026-09-26	gasolina	35.28	5.89	207.80	104728
488	36	2026-09-27	diesel	52.28	6.16	322.04	58509
489	48	2026-09-27	etanol	35.53	4.55	161.66	129562
490	42	2026-09-28	gasolina	66.62	6.29	419.04	83214
491	39	2026-10-08	etanol	49.24	4.11	202.38	74873
492	44	2026-10-09	gasolina	71.86	6.23	447.69	96078
493	47	2026-10-09	gasolina	34.14	6.12	208.94	82563
494	31	2026-10-10	diesel	112.56	6.43	723.76	49781
495	36	2026-10-10	diesel	73.64	6.41	472.03	59615
496	37	2026-10-10	diesel	74.93	6.12	458.57	133235
497	38	2026-10-12	gasolina	45.35	6.03	273.46	136940
498	40	2026-10-12	gasolina	35.22	6.19	218.01	89605
499	42	2026-10-13	gasolina	53.74	5.86	314.92	84503
500	46	2026-10-14	etanol	38.23	4.06	155.21	126079
501	43	2026-10-16	gasolina	66.33	5.79	384.05	116408
502	34	2026-10-18	diesel	68.27	6.29	429.42	50494
503	45	2026-10-20	gasolina	32.43	5.75	186.47	49824
504	35	2026-10-22	diesel	54.21	6.16	333.93	122728
505	50	2026-10-22	gasolina	38.21	6.08	232.32	105722
506	33	2026-10-23	diesel	109.50	6.18	676.71	129029
507	48	2026-10-23	gasolina	45.64	6.29	287.08	131492
508	49	2026-10-23	gasolina	35.01	5.91	206.91	86535
509	32	2026-10-24	diesel	99.73	5.97	595.39	116702
510	41	2026-10-27	gasolina	70.86	5.79	410.28	111519
2272	2	2026-11-05	Gasolina	41.50	5.58	231.57	79777
511	53	2025-01-08	diesel	113.98	6.16	702.12	61918
512	65	2025-01-08	gasolina	40.29	6.01	242.14	68583
513	69	2025-01-08	diesel	60.66	5.82	353.04	4557
514	73	2025-01-08	gasolina	58.57	6.15	360.21	3832
515	79	2025-01-08	gasolina	42.67	6.33	270.10	139178
516	62	2025-01-09	diesel	52.03	5.88	305.94	28237
517	75	2025-01-09	diesel	59.13	6.21	367.20	127847
518	76	2025-01-09	diesel	55.85	5.79	323.37	85212
519	84	2025-01-09	gasolina	33.95	6.11	207.43	24455
520	90	2025-01-09	gasolina	57.79	5.93	342.69	128005
521	51	2025-01-10	diesel	105.56	6.09	642.86	28057
522	54	2025-01-10	diesel	102.39	6.06	620.48	61179
523	55	2025-01-10	diesel	126.41	6.29	795.12	84286
524	56	2025-01-10	diesel	123.40	6.14	757.68	100995
525	57	2025-01-10	diesel	57.35	5.91	338.94	115620
526	64	2025-01-10	etanol	46.43	4.03	187.11	96785
527	78	2025-01-10	etanol	38.53	4.15	159.90	10418
528	87	2025-01-10	etanol	53.98	4.04	218.08	117193
529	58	2025-01-11	diesel	51.01	6.23	317.79	50781
530	59	2025-01-11	diesel	73.05	6.31	460.95	120992
531	60	2025-01-11	diesel	60.82	5.75	349.72	43267
532	63	2025-01-11	diesel	54.56	6.03	329.00	120314
533	66	2025-01-11	etanol	39.34	4.29	168.77	76526
534	68	2025-01-11	gasolina	47.17	6.31	297.64	64367
535	74	2025-01-11	gasolina	53.89	5.66	305.02	57825
536	81	2025-01-11	etanol	37.26	4.47	166.55	66013
537	85	2025-01-11	gasolina	44.25	6.27	277.45	3670
538	86	2025-01-11	gasolina	37.94	6.05	229.54	34711
539	71	2025-01-12	gasolina	70.56	6.09	429.71	106017
540	77	2025-01-12	gasolina	36.91	5.76	212.60	139089
541	83	2025-01-12	etanol	32.48	4.24	137.72	94183
542	52	2025-01-13	diesel	113.66	5.88	668.32	112843
543	67	2025-01-13	gasolina	45.72	5.73	261.98	97556
544	70	2025-01-13	diesel	53.12	6.23	330.94	138989
545	80	2025-01-13	gasolina	44.38	6.23	276.49	89910
546	89	2025-01-13	gasolina	54.60	6.36	347.26	10361
547	61	2025-01-14	diesel	65.16	6.49	422.89	85983
548	72	2025-01-14	diesel	63.84	6.19	395.17	20902
549	82	2025-01-14	gasolina	42.75	5.70	243.68	10953
550	88	2025-01-14	etanol	51.77	4.58	237.11	125422
551	67	2025-01-18	gasolina	35.51	5.64	200.28	98538
552	68	2025-01-18	gasolina	37.29	5.67	211.43	65080
553	82	2025-01-18	gasolina	40.14	5.63	225.99	11547
554	53	2025-01-19	diesel	98.97	6.53	646.27	62870
555	65	2025-01-19	gasolina	39.18	5.66	221.76	68959
556	71	2025-01-19	gasolina	66.32	5.63	373.38	106825
557	84	2025-01-19	gasolina	41.79	5.64	235.70	25111
558	57	2025-01-20	diesel	65.59	6.14	402.72	116804
559	73	2025-01-20	gasolina	53.65	6.01	322.44	4551
560	75	2025-01-20	diesel	60.97	5.92	360.94	128161
561	81	2025-01-20	etanol	30.25	3.89	117.67	66946
562	52	2025-01-21	diesel	120.04	6.40	768.26	113573
563	55	2025-01-21	diesel	145.56	6.22	905.38	84716
564	56	2025-01-21	diesel	107.73	6.37	686.24	101681
565	60	2025-01-21	diesel	58.64	6.40	375.30	44370
566	69	2025-01-21	diesel	55.05	6.11	336.36	5182
567	87	2025-01-21	etanol	45.32	3.96	179.47	117851
568	90	2025-01-21	gasolina	44.18	5.89	260.22	128505
569	80	2025-01-22	gasolina	37.73	6.00	226.38	90655
570	86	2025-01-22	gasolina	30.47	5.90	179.77	35589
571	51	2025-01-23	diesel	143.86	6.28	903.44	29634
572	63	2025-01-23	diesel	62.20	5.83	362.63	120760
573	83	2025-01-23	etanol	34.03	3.96	134.76	95335
574	54	2025-01-24	diesel	141.26	6.10	861.69	62030
575	61	2025-01-24	diesel	52.89	5.87	310.46	86485
576	77	2025-01-24	gasolina	38.28	6.23	238.48	139484
577	89	2025-01-24	gasolina	43.37	6.10	264.56	10990
578	59	2025-01-25	diesel	50.29	5.80	291.68	121530
579	62	2025-01-25	diesel	68.70	5.95	408.77	29217
580	72	2025-01-25	diesel	72.51	6.53	473.49	21756
581	70	2025-01-26	diesel	49.86	5.76	287.19	140001
582	64	2025-01-27	etanol	35.43	4.64	164.40	97006
583	66	2025-01-27	etanol	30.76	4.21	129.50	77335
584	74	2025-01-27	gasolina	63.75	5.63	358.91	58443
585	76	2025-01-27	diesel	61.12	6.26	382.61	85927
586	78	2025-01-27	etanol	36.65	4.49	164.56	11387
587	79	2025-01-27	gasolina	36.97	5.56	205.55	139884
588	88	2025-01-27	etanol	41.51	4.22	175.17	125840
589	58	2025-01-28	diesel	47.99	5.94	285.06	51048
590	85	2025-01-28	gasolina	39.23	6.12	240.09	4195
591	56	2025-02-08	diesel	126.36	6.03	761.95	103026
592	70	2025-02-08	gasolina	71.93	5.65	406.40	140884
593	73	2025-02-08	diesel	60.42	6.16	372.19	5534
594	75	2025-02-08	diesel	69.45	5.99	416.01	128935
595	77	2025-02-08	etanol	34.90	4.28	149.37	140603
596	88	2025-02-08	etanol	43.03	4.21	181.16	127169
597	53	2025-02-09	diesel	92.47	6.20	573.31	63602
598	58	2025-02-09	diesel	63.03	5.81	366.20	52594
599	59	2025-02-09	diesel	60.35	6.41	386.84	122697
600	62	2025-02-09	diesel	70.81	6.52	461.68	30097
601	66	2025-02-09	gasolina	37.93	6.24	236.68	77876
602	68	2025-02-09	gasolina	44.00	5.91	260.04	65883
603	80	2025-02-09	gasolina	43.56	6.14	267.46	92202
604	60	2025-02-10	diesel	65.29	6.54	427.00	46066
605	85	2025-02-10	gasolina	41.28	6.19	255.52	4941
606	89	2025-02-10	gasolina	42.67	6.26	267.11	11748
607	90	2025-02-10	gasolina	42.56	5.69	242.17	129498
608	52	2025-02-11	diesel	144.38	6.55	945.69	114526
609	55	2025-02-11	diesel	117.58	5.82	684.32	86001
610	65	2025-02-11	etanol	46.47	3.86	179.37	69836
611	82	2025-02-11	etanol	39.60	4.56	180.58	12454
612	51	2025-02-12	diesel	115.24	6.48	746.76	30511
613	64	2025-02-12	etanol	41.24	4.62	190.53	97993
614	72	2025-02-12	gasolina	70.19	6.16	432.37	22630
615	79	2025-02-12	gasolina	34.51	5.84	201.54	140519
616	54	2025-02-13	diesel	107.77	5.77	621.83	62940
617	57	2025-02-13	diesel	52.25	6.16	321.86	117854
618	71	2025-02-13	diesel	70.68	6.55	462.95	107994
619	76	2025-02-13	diesel	71.45	6.13	437.99	86812
620	78	2025-02-13	etanol	36.83	4.00	147.32	12303
621	86	2025-02-13	etanol	40.04	4.17	166.97	36154
622	87	2025-02-13	gasolina	56.34	5.91	332.97	119005
623	61	2025-02-14	diesel	73.69	6.36	468.67	88205
624	63	2025-02-14	diesel	71.88	5.80	416.90	121509
625	67	2025-02-14	etanol	44.68	3.98	177.83	99666
626	69	2025-02-14	diesel	70.81	6.50	460.27	6388
627	74	2025-02-14	diesel	69.82	5.77	402.86	59408
628	81	2025-02-14	etanol	30.01	3.96	118.84	68200
629	83	2025-02-14	gasolina	35.75	5.65	201.99	96346
630	84	2025-02-14	gasolina	30.67	6.40	196.29	25809
631	53	2025-02-18	diesel	130.07	6.01	781.72	64001
632	63	2025-02-18	diesel	71.41	6.28	448.45	122103
633	73	2025-02-18	diesel	61.92	6.38	395.05	6167
634	85	2025-02-18	gasolina	37.44	6.19	231.75	5651
635	55	2025-02-19	diesel	103.97	6.21	645.65	86741
636	61	2025-02-19	diesel	50.61	6.40	323.90	88554
637	70	2025-02-19	gasolina	53.41	6.32	337.55	142029
638	71	2025-02-19	diesel	55.25	6.52	360.23	108615
639	87	2025-02-19	gasolina	55.63	5.74	319.32	119824
640	88	2025-02-19	etanol	43.77	4.20	183.83	128461
641	52	2025-02-20	diesel	122.87	5.95	731.08	115321
642	66	2025-02-20	gasolina	40.86	5.70	232.90	78410
643	76	2025-02-20	diesel	62.96	6.04	380.28	87018
644	86	2025-02-20	etanol	42.35	4.03	170.67	37019
645	59	2025-02-21	diesel	57.05	5.78	329.75	123709
646	79	2025-02-22	gasolina	35.50	5.84	207.32	140909
647	80	2025-02-22	gasolina	32.88	6.13	201.55	92734
648	82	2025-02-22	etanol	34.35	4.22	144.96	12778
649	83	2025-02-22	gasolina	31.52	6.33	199.52	96863
650	65	2025-02-23	etanol	47.76	4.04	192.95	70660
651	67	2025-02-23	etanol	37.24	3.99	148.59	100633
652	77	2025-02-23	etanol	32.14	4.14	133.06	140953
653	54	2025-02-24	diesel	90.33	5.94	536.56	63795
654	62	2025-02-24	diesel	47.85	6.10	291.89	31057
655	64	2025-02-24	etanol	46.45	4.49	208.56	99161
656	78	2025-02-24	etanol	35.63	4.04	143.95	13077
657	74	2025-02-25	diesel	53.58	5.95	318.80	60291
658	84	2025-02-25	gasolina	42.23	5.84	246.62	26792
659	90	2025-02-25	gasolina	54.75	5.73	313.72	130110
660	51	2025-02-26	diesel	99.11	6.16	610.52	31489
661	56	2025-02-26	diesel	113.27	6.10	690.95	103940
662	60	2025-02-26	diesel	64.98	5.86	380.78	47097
663	68	2025-02-26	gasolina	45.77	5.93	271.42	66182
664	69	2025-02-26	diesel	64.27	6.03	387.55	7121
665	81	2025-02-26	etanol	35.13	4.37	153.52	68438
666	58	2025-02-27	diesel	55.23	5.86	323.65	53094
667	72	2025-02-27	gasolina	60.27	5.91	356.20	23419
668	57	2025-02-28	diesel	55.54	5.99	332.68	118696
669	75	2025-02-28	diesel	52.64	5.98	314.79	129421
670	89	2025-02-28	gasolina	51.12	5.55	283.72	12437
671	56	2025-03-08	diesel	121.26	6.54	793.04	105044
672	62	2025-03-08	diesel	72.12	5.81	419.02	32133
673	67	2025-03-08	gasolina	46.36	5.91	273.99	101683
674	68	2025-03-08	gasolina	38.28	6.13	234.66	67237
675	78	2025-03-08	gasolina	32.72	5.80	189.78	14060
676	84	2025-03-08	gasolina	33.73	6.33	213.51	28116
677	57	2025-03-09	diesel	62.63	5.94	372.02	119511
678	64	2025-03-09	etanol	41.75	4.23	176.60	100231
679	69	2025-03-09	diesel	70.30	5.81	408.44	7605
680	71	2025-03-09	diesel	52.93	6.21	328.70	109559
681	60	2025-03-10	diesel	64.99	5.81	377.59	47876
682	63	2025-03-10	diesel	61.28	6.49	397.71	123088
683	65	2025-03-10	gasolina	40.57	5.89	238.96	71166
684	70	2025-03-10	gasolina	73.27	5.78	423.50	143087
685	75	2025-03-10	diesel	57.55	6.29	361.99	130133
686	90	2025-03-10	gasolina	55.87	6.09	340.25	130755
687	53	2025-03-11	diesel	123.00	6.25	768.75	64636
688	74	2025-03-11	diesel	64.06	6.16	394.61	61706
689	76	2025-03-11	diesel	57.31	6.14	351.88	88197
690	83	2025-03-11	etanol	42.00	4.22	177.24	97709
691	87	2025-03-11	gasolina	46.65	5.69	265.44	121188
692	52	2025-03-12	diesel	95.47	5.94	567.09	116548
693	58	2025-03-12	diesel	64.27	5.76	370.20	54325
694	59	2025-03-12	diesel	54.90	6.06	332.69	124568
695	61	2025-03-12	diesel	54.70	6.16	336.95	89745
696	77	2025-03-12	gasolina	36.10	6.22	224.54	142038
697	79	2025-03-12	gasolina	32.81	6.18	202.77	141682
698	54	2025-03-13	diesel	124.44	6.35	790.19	64381
699	73	2025-03-13	diesel	54.99	6.00	329.94	6895
700	80	2025-03-13	gasolina	30.95	6.38	197.46	93894
701	81	2025-03-13	etanol	40.94	4.48	183.41	69427
702	82	2025-03-13	gasolina	41.31	6.07	250.75	13743
703	86	2025-03-13	gasolina	34.77	5.88	204.45	38600
704	89	2025-03-13	gasolina	44.39	5.67	251.69	13655
705	51	2025-03-14	diesel	100.99	5.75	580.69	32244
706	55	2025-03-14	diesel	121.31	6.13	743.63	87538
707	66	2025-03-14	etanol	34.28	4.30	147.40	79536
708	72	2025-03-14	diesel	62.57	6.45	403.58	23884
709	85	2025-03-14	gasolina	36.42	6.17	224.71	6914
710	88	2025-03-14	gasolina	42.33	6.31	267.10	129422
711	58	2025-03-18	diesel	51.37	6.01	308.73	55334
712	66	2025-03-18	etanol	41.05	4.38	179.80	80823
713	72	2025-03-18	diesel	54.50	6.23	339.54	24582
714	75	2025-03-18	diesel	59.46	6.15	365.68	131051
715	57	2025-03-19	diesel	61.45	6.36	390.82	120039
716	59	2025-03-19	diesel	51.62	5.81	299.91	125353
717	63	2025-03-19	diesel	64.64	6.20	400.77	123482
718	71	2025-03-19	diesel	49.72	6.20	308.26	110230
719	76	2025-03-19	diesel	74.05	6.52	482.81	88621
720	79	2025-03-19	gasolina	31.57	5.82	183.74	142690
721	86	2025-03-19	gasolina	44.05	6.13	270.03	39366
722	88	2025-03-19	gasolina	51.43	6.22	319.89	130006
723	51	2025-03-20	diesel	98.49	6.25	615.56	32519
724	56	2025-03-20	diesel	115.01	6.28	722.26	105586
725	62	2025-03-20	diesel	71.11	6.09	433.06	32955
726	54	2025-03-21	diesel	130.07	6.27	815.54	65268
727	55	2025-03-21	diesel	102.76	5.82	598.06	88503
728	64	2025-03-21	etanol	46.62	3.98	185.55	101334
729	80	2025-03-21	gasolina	42.19	5.85	246.81	94147
730	83	2025-03-21	etanol	38.68	4.54	175.61	97983
731	82	2025-03-22	gasolina	38.27	6.22	238.04	14374
732	69	2025-03-23	diesel	67.23	6.18	415.48	9135
733	78	2025-03-23	gasolina	38.52	6.25	240.75	14652
734	89	2025-03-23	gasolina	42.05	5.66	238.00	13923
735	53	2025-03-24	diesel	108.49	5.95	645.52	65143
736	61	2025-03-24	diesel	72.49	5.75	416.82	90210
737	77	2025-03-24	gasolina	33.08	5.83	192.86	142976
738	60	2025-03-25	diesel	52.99	5.99	317.41	48235
739	67	2025-03-25	gasolina	41.94	6.34	265.90	102572
740	73	2025-03-25	diesel	73.93	6.12	452.45	7609
741	90	2025-03-25	gasolina	49.05	6.38	312.94	131771
742	65	2025-03-26	gasolina	44.59	5.79	258.18	72814
743	68	2025-03-26	gasolina	39.63	5.71	226.29	68060
744	74	2025-03-26	diesel	49.36	6.50	320.84	62592
745	81	2025-03-26	etanol	40.59	4.09	166.01	70135
746	84	2025-03-26	gasolina	36.36	6.23	226.52	28825
747	85	2025-03-26	gasolina	39.09	6.41	250.57	7494
748	87	2025-03-26	gasolina	51.70	6.40	330.88	121881
749	52	2025-03-27	diesel	102.13	5.77	589.29	117578
750	70	2025-03-28	gasolina	59.24	5.78	342.41	143993
751	51	2025-04-08	diesel	109.56	6.16	674.89	33700
752	59	2025-04-08	diesel	59.91	6.43	385.22	126000
753	67	2025-04-08	etanol	30.56	4.12	125.91	103337
754	68	2025-04-08	gasolina	31.66	5.76	182.36	68861
755	72	2025-04-08	diesel	49.00	6.22	304.78	25218
756	74	2025-04-08	diesel	71.87	5.83	419.00	63240
757	77	2025-04-08	gasolina	37.34	5.97	222.92	144500
758	80	2025-04-08	etanol	35.87	3.90	139.89	95284
759	56	2025-04-09	diesel	126.98	6.43	816.48	107070
760	83	2025-04-09	etanol	42.91	4.42	189.66	99258
761	85	2025-04-09	gasolina	30.89	5.82	179.78	8195
762	89	2025-04-09	etanol	45.80	4.64	212.51	15039
763	53	2025-04-10	diesel	116.81	6.10	712.54	65738
764	55	2025-04-10	diesel	111.77	6.20	692.97	89151
765	73	2025-04-10	gasolina	62.45	6.00	374.70	8776
766	75	2025-04-10	diesel	66.06	5.80	383.15	132451
767	81	2025-04-10	gasolina	44.88	5.77	258.96	71324
768	52	2025-04-11	diesel	114.83	6.17	708.50	118296
769	64	2025-04-11	etanol	46.01	4.58	210.73	102620
770	65	2025-04-11	etanol	47.77	3.89	185.83	73503
771	71	2025-04-11	diesel	71.66	5.83	417.78	110984
772	87	2025-04-11	gasolina	41.11	5.72	235.15	122777
773	61	2025-04-12	diesel	64.45	5.82	375.10	90836
774	63	2025-04-12	diesel	57.97	6.32	366.37	124061
775	78	2025-04-12	gasolina	36.41	6.04	219.92	15795
776	86	2025-04-12	gasolina	43.85	5.60	245.56	39819
777	54	2025-04-13	diesel	132.00	6.43	848.76	66055
778	57	2025-04-13	diesel	49.64	6.53	324.15	121717
779	58	2025-04-13	diesel	59.59	6.24	371.84	56410
780	60	2025-04-13	diesel	63.96	6.05	386.96	49125
781	66	2025-04-13	etanol	43.73	3.93	171.86	81910
782	82	2025-04-13	gasolina	37.41	5.59	209.12	15636
783	88	2025-04-13	gasolina	50.93	5.91	301.00	131424
784	90	2025-04-13	gasolina	40.01	6.13	245.26	132716
785	62	2025-04-14	diesel	54.01	6.28	339.18	34230
786	69	2025-04-14	diesel	53.63	5.94	318.56	9854
787	70	2025-04-14	gasolina	62.32	5.70	355.22	145122
788	76	2025-04-14	gasolina	58.22	6.25	363.88	89821
789	79	2025-04-14	gasolina	42.55	5.75	244.66	144307
790	84	2025-04-14	gasolina	35.87	6.20	222.39	29650
791	68	2025-04-18	gasolina	37.53	5.58	209.42	69825
792	87	2025-04-18	gasolina	40.83	5.57	227.42	123921
793	88	2025-04-18	gasolina	56.94	5.91	336.52	132050
794	51	2025-04-19	diesel	142.99	5.80	829.34	34366
795	63	2025-04-19	diesel	50.51	5.98	302.05	124554
796	75	2025-04-19	diesel	52.33	6.08	318.17	132618
797	58	2025-04-20	diesel	46.72	6.08	284.06	56766
798	70	2025-04-20	gasolina	65.29	6.12	399.57	145452
799	71	2025-04-20	diesel	68.33	6.48	442.78	112116
800	74	2025-04-20	diesel	59.65	6.42	382.95	63867
801	80	2025-04-20	etanol	37.67	4.17	157.08	96223
802	65	2025-04-21	etanol	40.78	3.99	162.71	74054
803	77	2025-04-21	gasolina	41.27	5.61	231.52	144800
804	52	2025-04-23	diesel	135.13	6.15	831.05	119306
805	69	2025-04-23	diesel	48.63	5.97	290.32	10679
806	72	2025-04-23	diesel	68.35	6.29	429.92	26413
807	82	2025-04-23	gasolina	45.09	5.96	268.74	16269
808	57	2025-04-24	diesel	69.94	5.84	408.45	122321
809	66	2025-04-24	etanol	35.43	4.42	156.60	82222
810	67	2025-04-24	etanol	42.86	4.48	192.01	104015
811	79	2025-04-24	gasolina	31.43	6.02	189.21	145406
812	85	2025-04-24	gasolina	41.83	6.09	254.74	9064
813	59	2025-04-25	diesel	46.65	6.29	293.43	127329
814	64	2025-04-25	etanol	38.88	4.06	157.85	103134
815	55	2025-04-26	diesel	141.42	5.95	841.45	89970
816	56	2025-04-26	diesel	95.70	6.44	616.31	107851
817	76	2025-04-26	gasolina	70.83	5.64	399.48	90516
818	78	2025-04-26	gasolina	40.43	6.10	246.62	16206
819	81	2025-04-26	gasolina	33.39	6.42	214.36	71760
820	86	2025-04-26	gasolina	38.90	5.76	224.06	40507
821	90	2025-04-26	gasolina	55.86	6.35	354.71	133856
822	53	2025-04-27	diesel	149.17	6.12	912.92	66889
823	61	2025-04-27	diesel	62.84	6.39	401.55	91240
824	62	2025-04-27	diesel	48.50	5.94	288.09	35055
825	83	2025-04-27	etanol	32.50	4.11	133.58	99991
826	89	2025-04-27	etanol	55.04	3.94	216.86	15279
827	54	2025-04-28	diesel	97.45	6.10	594.45	66550
828	60	2025-04-28	diesel	46.79	6.27	293.37	49886
829	73	2025-04-28	gasolina	55.90	6.30	352.17	9940
830	84	2025-04-28	gasolina	33.51	6.18	207.09	30380
831	51	2025-05-08	diesel	136.34	6.16	839.85	35827
832	61	2025-05-08	diesel	64.84	6.24	404.60	92267
833	71	2025-05-08	diesel	72.20	6.43	464.25	112798
834	72	2025-05-08	diesel	62.93	6.51	409.67	27716
835	76	2025-05-08	diesel	64.01	6.08	389.18	91328
836	83	2025-05-08	gasolina	30.39	5.59	169.88	100934
837	85	2025-05-08	gasolina	36.42	5.76	209.78	9354
838	88	2025-05-08	gasolina	50.59	5.66	286.34	132504
839	78	2025-05-09	gasolina	32.12	5.61	180.19	17277
840	80	2025-05-09	etanol	41.98	4.56	191.43	97028
841	81	2025-05-09	gasolina	45.32	6.04	273.73	72658
842	84	2025-05-09	gasolina	40.53	5.65	228.99	31158
843	52	2025-05-10	diesel	97.55	6.15	599.93	120163
844	57	2025-05-10	diesel	59.60	5.78	344.49	124002
845	66	2025-05-10	etanol	32.28	4.23	136.54	83312
846	79	2025-05-10	etanol	35.60	4.59	163.40	146292
847	82	2025-05-10	gasolina	39.88	6.34	252.84	17441
848	55	2025-05-11	diesel	112.44	5.83	655.53	90862
849	56	2025-05-11	diesel	106.12	6.25	663.25	108799
850	59	2025-05-11	diesel	70.89	6.19	438.81	128416
851	67	2025-05-11	gasolina	31.21	5.93	185.08	104647
852	69	2025-05-11	diesel	56.12	6.29	352.99	12356
853	87	2025-05-11	etanol	41.05	4.08	167.48	125366
854	89	2025-05-11	etanol	45.01	3.95	177.79	16134
855	53	2025-05-12	diesel	136.80	6.12	837.22	67767
856	62	2025-05-12	diesel	65.39	6.05	395.61	36055
857	65	2025-05-12	etanol	47.21	3.98	187.90	75304
858	74	2025-05-12	diesel	73.25	6.14	449.76	64737
859	77	2025-05-12	gasolina	30.65	6.33	194.01	146168
860	54	2025-05-13	diesel	95.87	6.09	583.85	67675
861	58	2025-05-13	diesel	63.38	6.37	403.73	58387
862	60	2025-05-13	diesel	74.29	5.80	430.88	50921
863	63	2025-05-13	diesel	55.70	5.93	330.30	125373
864	90	2025-05-13	etanol	42.01	4.27	179.38	134914
865	64	2025-05-14	etanol	47.53	4.11	195.35	104035
866	68	2025-05-14	etanol	45.82	4.41	202.07	70522
867	70	2025-05-14	diesel	74.79	6.14	459.21	146732
868	73	2025-05-14	diesel	70.91	6.31	447.44	11198
869	75	2025-05-14	diesel	57.50	6.45	370.88	134010
870	86	2025-05-14	gasolina	31.15	6.35	197.80	41498
871	63	2025-05-18	diesel	51.57	6.46	333.14	126152
872	83	2025-05-18	gasolina	33.81	6.25	211.31	101484
873	89	2025-05-18	etanol	40.77	4.56	185.91	17670
874	90	2025-05-18	etanol	40.84	4.52	184.60	135734
875	51	2025-05-19	diesel	116.59	6.24	727.52	36722
876	55	2025-05-19	diesel	99.37	6.23	619.08	91615
877	64	2025-05-19	etanol	36.62	4.62	169.18	104804
878	67	2025-05-19	gasolina	33.85	5.84	197.68	105243
879	56	2025-05-20	diesel	114.78	5.83	669.17	109622
880	66	2025-05-20	etanol	39.07	4.36	170.35	84947
881	71	2025-05-20	diesel	68.74	5.81	399.38	114203
882	52	2025-05-21	diesel	95.56	6.47	618.27	120556
883	70	2025-05-21	diesel	54.53	5.87	320.09	147064
884	81	2025-05-21	gasolina	33.61	5.93	199.31	73243
885	57	2025-05-22	diesel	50.91	6.31	321.24	124598
886	65	2025-05-22	etanol	43.66	4.45	194.29	76314
887	79	2025-05-22	etanol	36.06	4.30	155.06	147551
888	87	2025-05-22	etanol	53.49	4.04	216.10	125755
889	74	2025-05-23	diesel	57.33	5.97	342.26	65019
890	77	2025-05-23	gasolina	43.75	5.92	259.00	146960
891	82	2025-05-23	gasolina	42.63	5.92	252.37	17839
892	58	2025-05-24	diesel	52.71	6.12	322.59	58576
893	68	2025-05-24	etanol	35.43	4.43	156.95	70896
894	76	2025-05-24	diesel	74.00	6.11	452.14	92134
895	80	2025-05-24	etanol	31.07	4.39	136.40	97849
896	85	2025-05-24	gasolina	35.26	6.28	221.43	10090
897	86	2025-05-24	gasolina	39.49	5.76	227.46	42580
898	88	2025-05-24	gasolina	45.30	5.55	251.42	133174
899	53	2025-05-25	diesel	114.02	5.80	661.32	68583
900	62	2025-05-26	diesel	50.78	5.81	295.03	37183
901	72	2025-05-26	diesel	59.26	5.90	349.63	28431
902	78	2025-05-26	gasolina	36.65	6.07	222.47	17945
903	59	2025-05-27	diesel	49.21	6.08	299.20	128769
904	69	2025-05-27	diesel	67.64	6.36	430.19	13404
905	73	2025-05-27	diesel	59.22	6.03	357.10	12217
906	54	2025-05-28	diesel	99.39	6.43	639.08	68148
907	60	2025-05-28	diesel	48.57	6.05	293.85	51284
908	61	2025-05-28	diesel	45.23	6.35	287.21	92689
909	75	2025-05-28	diesel	60.24	6.00	361.44	134663
910	84	2025-05-28	gasolina	40.88	6.44	263.27	31935
911	54	2025-06-08	diesel	127.29	6.08	773.92	69062
912	57	2025-06-08	diesel	49.84	6.11	304.52	125587
913	72	2025-06-08	diesel	69.05	6.10	421.21	29913
914	76	2025-06-08	diesel	73.67	6.02	443.49	93604
915	86	2025-06-08	gasolina	38.53	5.80	223.47	43790
916	89	2025-06-08	gasolina	56.22	6.38	358.68	18119
917	90	2025-06-08	gasolina	53.74	6.16	331.04	136506
918	81	2025-06-09	gasolina	33.84	5.79	195.93	74568
919	82	2025-06-09	etanol	42.60	4.37	186.16	18850
920	84	2025-06-09	gasolina	40.33	6.11	246.42	32682
921	53	2025-06-10	diesel	95.50	6.10	582.55	69436
922	58	2025-06-10	diesel	61.92	6.54	404.96	59606
923	65	2025-06-10	gasolina	38.31	5.74	219.90	76758
924	67	2025-06-10	etanol	36.84	4.59	169.10	106434
925	77	2025-06-10	etanol	42.31	4.22	178.55	148402
926	63	2025-06-11	diesel	49.73	6.26	311.31	126558
927	64	2025-06-11	gasolina	40.48	6.42	259.88	105322
928	71	2025-06-11	diesel	73.28	6.14	449.94	114802
929	73	2025-06-11	diesel	72.14	6.48	467.47	13736
930	75	2025-06-11	gasolina	73.07	6.26	457.42	136151
931	78	2025-06-11	gasolina	34.65	5.57	193.00	19341
932	51	2025-06-12	diesel	101.96	5.97	608.70	37666
933	55	2025-06-12	diesel	126.43	5.83	737.09	92543
934	56	2025-06-12	diesel	125.15	6.15	769.67	111178
935	60	2025-06-12	diesel	71.73	6.33	454.05	52414
936	62	2025-06-12	diesel	56.46	6.44	363.60	38387
937	66	2025-06-12	gasolina	39.32	5.67	222.94	86119
938	79	2025-06-12	gasolina	32.51	6.41	208.39	148779
939	80	2025-06-12	etanol	40.71	3.87	157.55	99047
940	52	2025-06-13	diesel	116.75	6.51	760.04	121753
941	59	2025-06-13	diesel	49.37	6.02	297.21	129860
942	69	2025-06-13	diesel	52.59	6.11	321.32	14830
943	70	2025-06-13	gasolina	71.93	6.14	441.65	148270
944	74	2025-06-13	diesel	73.20	6.28	459.70	66113
945	83	2025-06-13	etanol	40.65	4.23	171.95	101982
946	85	2025-06-13	etanol	32.67	4.45	145.38	10808
947	87	2025-06-13	etanol	47.80	4.08	195.02	126657
948	61	2025-06-14	diesel	60.21	6.42	386.55	93528
949	68	2025-06-14	etanol	38.46	3.88	149.22	71890
950	88	2025-06-14	gasolina	51.64	6.37	328.95	134217
951	52	2025-06-18	diesel	97.63	6.09	594.57	122640
952	53	2025-06-18	diesel	92.44	5.85	540.77	70084
953	59	2025-06-18	diesel	50.58	6.18	312.58	130358
954	60	2025-06-18	diesel	73.45	6.14	450.98	52747
955	77	2025-06-18	etanol	41.98	4.26	178.83	149360
956	87	2025-06-18	etanol	47.62	4.37	208.10	127917
957	65	2025-06-19	gasolina	46.29	5.72	264.78	77355
958	72	2025-06-19	diesel	62.66	6.03	377.84	30414
959	85	2025-06-19	etanol	30.52	4.11	125.44	11216
960	54	2025-06-20	diesel	143.67	6.01	863.46	69384
961	71	2025-06-20	diesel	69.27	6.42	444.71	116103
962	73	2025-06-20	diesel	72.28	5.86	423.56	14183
963	76	2025-06-20	diesel	69.98	6.07	424.78	94501
964	81	2025-06-20	gasolina	35.57	5.84	207.73	75666
965	88	2025-06-20	gasolina	48.50	6.27	304.10	134766
966	68	2025-06-21	etanol	44.48	4.63	205.94	72321
967	70	2025-06-21	gasolina	49.72	6.39	317.71	148872
968	83	2025-06-21	etanol	34.99	3.93	137.51	102923
969	57	2025-06-22	diesel	50.04	5.81	290.73	125897
970	78	2025-06-22	gasolina	40.87	5.66	231.32	19911
971	86	2025-06-22	gasolina	35.36	6.21	219.59	44283
972	63	2025-06-24	diesel	51.05	5.99	305.79	127471
973	66	2025-06-24	gasolina	37.94	6.08	230.68	86663
974	69	2025-06-24	diesel	49.08	6.12	300.37	15585
975	51	2025-06-25	diesel	120.47	5.95	716.80	38231
976	67	2025-06-25	etanol	31.13	4.21	131.06	106876
977	79	2025-06-25	gasolina	35.27	6.30	222.20	149500
978	64	2025-06-26	gasolina	33.21	6.24	207.23	105982
979	89	2025-06-26	gasolina	54.49	5.59	304.60	18863
980	90	2025-06-26	gasolina	47.99	5.57	267.30	137021
981	55	2025-06-27	diesel	119.18	6.20	738.92	93036
982	56	2025-06-27	diesel	98.98	6.43	636.44	111594
983	58	2025-06-27	diesel	66.30	6.42	425.65	60482
984	74	2025-06-27	diesel	54.43	5.80	315.69	66487
985	75	2025-06-27	gasolina	66.34	6.42	425.90	136711
986	84	2025-06-27	gasolina	41.69	6.37	265.57	33063
987	61	2025-06-28	diesel	67.07	6.29	421.87	94241
988	62	2025-06-28	diesel	52.10	6.04	314.68	39027
989	80	2025-06-28	etanol	34.49	4.55	156.93	99481
990	82	2025-06-28	etanol	45.92	4.26	195.62	19231
991	58	2025-07-08	diesel	49.69	5.86	291.18	61648
992	59	2025-07-08	diesel	54.39	5.95	323.62	131614
993	64	2025-07-08	etanol	47.22	4.21	198.80	106934
994	70	2025-07-08	diesel	63.51	6.52	414.09	149957
995	74	2025-07-08	diesel	63.28	5.98	378.41	67441
996	79	2025-07-08	gasolina	36.04	6.18	222.73	150574
997	84	2025-07-08	gasolina	30.76	5.92	182.10	34131
998	86	2025-07-08	etanol	36.48	4.06	148.11	45510
999	88	2025-07-08	gasolina	56.82	5.58	317.06	135596
1000	76	2025-07-09	diesel	59.57	6.23	371.12	95477
1001	78	2025-07-09	etanol	41.95	4.15	174.09	20615
1002	85	2025-07-09	gasolina	30.26	5.66	171.27	12279
1003	51	2025-07-10	diesel	145.37	6.46	939.09	38764
1004	53	2025-07-10	diesel	136.66	6.16	841.83	70535
1005	60	2025-07-10	diesel	49.34	6.22	306.89	54034
1006	67	2025-07-10	etanol	37.11	4.04	149.92	108212
1007	73	2025-07-10	gasolina	72.69	6.15	447.04	15543
1008	68	2025-07-11	gasolina	31.92	6.20	197.90	73408
1009	71	2025-07-11	diesel	62.59	5.95	372.41	116865
1010	87	2025-07-11	gasolina	41.71	6.10	254.43	128717
1011	56	2025-07-12	diesel	126.44	6.05	764.96	112818
1012	61	2025-07-12	diesel	74.29	6.19	459.86	94774
1013	65	2025-07-12	etanol	38.20	4.59	175.34	78310
1014	66	2025-07-12	gasolina	43.36	5.64	244.55	88151
1015	72	2025-07-12	diesel	62.56	6.45	403.51	31812
1016	77	2025-07-12	etanol	33.70	4.21	141.88	150666
1017	83	2025-07-12	gasolina	32.11	5.83	187.20	104401
1018	90	2025-07-12	gasolina	53.78	5.84	314.08	137991
1019	62	2025-07-13	diesel	69.66	6.31	439.55	39895
1020	63	2025-07-13	diesel	74.17	6.14	455.40	128481
1021	69	2025-07-13	diesel	71.22	6.45	459.37	16748
1022	80	2025-07-13	gasolina	37.10	6.18	229.28	99982
1023	81	2025-07-13	gasolina	34.12	5.83	198.92	76736
1024	82	2025-07-13	gasolina	45.05	6.20	279.31	19757
1025	89	2025-07-13	gasolina	42.68	5.98	255.23	19730
1026	52	2025-07-14	diesel	118.40	6.22	736.45	123180
1027	54	2025-07-14	diesel	119.39	6.53	779.62	70227
1028	55	2025-07-14	diesel	106.79	5.83	622.59	93851
1029	57	2025-07-14	diesel	59.57	6.35	378.27	126919
1030	75	2025-07-14	gasolina	58.85	5.74	337.80	137870
1031	60	2025-07-18	diesel	74.93	5.89	441.34	54728
1032	63	2025-07-18	diesel	65.05	5.86	381.19	129072
1033	74	2025-07-18	diesel	63.09	5.96	376.02	68046
1034	76	2025-07-18	diesel	63.52	5.92	376.04	96332
1035	78	2025-07-18	etanol	40.63	4.21	171.05	21341
1036	79	2025-07-18	gasolina	43.38	6.43	278.93	151323
1037	58	2025-07-19	diesel	55.74	6.04	336.67	61986
1038	61	2025-07-19	diesel	47.64	5.94	282.98	95895
1039	70	2025-07-19	diesel	68.87	5.94	409.09	150408
1040	88	2025-07-19	gasolina	46.06	5.82	268.07	136280
1041	89	2025-07-19	gasolina	46.38	6.13	284.31	20935
1042	72	2025-07-20	diesel	57.79	6.12	353.67	32123
1043	71	2025-07-21	diesel	60.42	5.97	360.71	117694
1044	75	2025-07-21	gasolina	65.53	5.75	376.80	138519
1045	84	2025-07-21	gasolina	32.79	6.10	200.02	34658
1046	90	2025-07-22	gasolina	53.68	6.25	335.50	138578
1047	65	2025-07-23	etanol	47.67	3.99	190.20	79012
1048	82	2025-07-23	gasolina	31.86	6.45	205.50	20112
1049	83	2025-07-23	gasolina	41.25	6.03	248.74	104631
1050	52	2025-07-24	diesel	145.81	6.49	946.31	123954
1051	66	2025-07-24	gasolina	35.50	5.60	198.80	88442
1052	86	2025-07-24	etanol	35.92	4.44	159.48	46117
1053	51	2025-07-25	diesel	98.23	5.85	574.65	39305
1054	56	2025-07-25	diesel	107.28	6.03	646.90	113611
1055	69	2025-07-25	diesel	71.43	5.93	423.58	17213
1056	85	2025-07-25	gasolina	45.17	6.17	278.70	13054
1057	53	2025-07-26	diesel	143.69	6.27	900.94	72076
1058	54	2025-07-26	diesel	103.07	6.32	651.40	71133
1059	59	2025-07-26	diesel	56.84	6.46	367.19	132523
1060	87	2025-07-26	gasolina	40.05	5.85	234.29	129285
1061	55	2025-07-27	diesel	139.13	6.52	907.13	94441
1062	57	2025-07-27	diesel	52.93	6.27	331.87	128231
1063	77	2025-07-27	etanol	40.50	4.27	172.94	151436
1064	81	2025-07-27	gasolina	41.86	6.27	262.46	77902
1065	62	2025-07-28	diesel	59.15	6.29	372.05	41361
1066	64	2025-07-28	etanol	42.52	4.23	179.86	108012
1067	67	2025-07-28	etanol	32.82	4.20	137.84	109521
1068	68	2025-07-28	gasolina	39.36	6.40	251.90	73911
1069	73	2025-07-28	gasolina	65.77	5.75	378.18	16055
1070	80	2025-07-28	gasolina	30.08	5.72	172.06	101284
1071	51	2025-08-08	diesel	130.27	6.09	793.34	39808
1072	53	2025-08-08	diesel	141.42	6.55	926.30	73302
1073	55	2025-08-08	diesel	110.33	6.55	722.66	95331
1074	61	2025-08-08	diesel	47.69	5.97	284.71	96630
1075	62	2025-08-08	diesel	58.35	6.02	351.27	42387
1076	65	2025-08-08	etanol	36.69	4.54	166.57	79595
1077	66	2025-08-08	etanol	40.30	4.02	162.01	89697
1078	79	2025-08-08	gasolina	43.99	5.68	249.86	152308
1079	80	2025-08-08	etanol	43.82	4.08	178.79	102370
1080	83	2025-08-08	etanol	31.87	4.43	141.18	105799
1081	86	2025-08-08	etanol	30.59	3.85	117.77	47337
1082	54	2025-08-09	diesel	121.15	5.83	706.30	71688
1083	77	2025-08-09	gasolina	42.19	5.76	243.01	152349
1084	82	2025-08-09	gasolina	38.69	5.66	218.99	21404
1085	84	2025-08-09	etanol	41.36	3.89	160.89	36035
1086	87	2025-08-09	gasolina	44.21	5.98	264.38	129988
1087	59	2025-08-10	diesel	54.13	6.44	348.60	133568
1088	60	2025-08-10	diesel	63.82	5.94	379.09	55737
1089	70	2025-08-10	diesel	58.10	6.33	367.77	151294
1090	73	2025-08-10	diesel	55.47	6.42	356.12	16725
1091	81	2025-08-10	gasolina	38.39	5.86	224.97	78721
1092	90	2025-08-10	gasolina	40.28	5.76	232.01	139406
1093	52	2025-08-11	diesel	148.33	5.95	882.56	124499
1094	57	2025-08-11	diesel	50.69	6.18	313.26	128632
1095	67	2025-08-11	etanol	45.04	4.62	208.08	110189
1096	76	2025-08-11	gasolina	58.89	5.92	348.63	97309
1097	78	2025-08-11	gasolina	30.81	5.92	182.40	21913
1098	85	2025-08-11	etanol	34.37	4.15	142.64	13964
1099	89	2025-08-11	gasolina	51.41	5.62	288.92	21389
1100	56	2025-08-12	diesel	123.32	6.06	747.32	114620
1101	64	2025-08-12	gasolina	47.25	6.15	290.59	108624
1102	69	2025-08-12	diesel	51.00	5.76	293.76	18303
1103	71	2025-08-12	diesel	54.17	5.88	318.52	118641
1104	74	2025-08-12	gasolina	66.17	6.23	412.24	69144
1105	58	2025-08-13	diesel	62.65	6.19	387.80	63033
1106	68	2025-08-13	gasolina	41.67	6.14	255.85	74565
1107	63	2025-08-14	diesel	61.83	6.39	395.09	129611
1108	72	2025-08-14	diesel	60.67	5.92	359.17	33022
1109	75	2025-08-14	diesel	54.58	6.25	341.13	139986
1110	88	2025-08-14	gasolina	48.37	5.75	278.13	137628
1111	55	2025-08-18	diesel	93.06	6.20	576.97	96116
1112	60	2025-08-18	diesel	57.62	6.53	376.26	56413
1113	53	2025-08-19	diesel	101.62	6.54	664.59	74133
1114	57	2025-08-19	diesel	64.34	6.25	402.13	129678
1115	52	2025-08-20	diesel	99.12	6.53	647.25	125082
1116	80	2025-08-20	etanol	41.96	4.06	170.36	103248
1117	64	2025-08-21	gasolina	40.89	5.82	237.98	110222
1118	72	2025-08-21	diesel	60.12	5.99	360.12	33600
1119	75	2025-08-21	diesel	65.45	6.29	411.68	140613
1120	87	2025-08-21	gasolina	42.17	6.08	256.39	130749
1121	51	2025-08-22	diesel	137.04	6.47	886.65	40234
1122	61	2025-08-22	diesel	49.43	6.24	308.44	98077
1123	66	2025-08-22	etanol	42.20	4.08	172.18	90140
1124	73	2025-08-22	diesel	72.29	5.95	430.13	17290
1125	74	2025-08-22	gasolina	60.18	5.94	357.47	69775
1126	76	2025-08-22	gasolina	65.52	5.94	389.19	98340
1127	77	2025-08-22	gasolina	34.48	6.03	207.91	153067
1128	89	2025-08-22	gasolina	45.77	6.28	287.44	21979
1129	69	2025-08-23	diesel	58.46	6.35	371.22	19807
1130	65	2025-08-24	etanol	36.44	4.12	150.13	80195
1131	56	2025-08-25	diesel	112.84	5.99	675.91	115457
1132	68	2025-08-25	gasolina	40.40	5.93	239.57	74834
1133	79	2025-08-25	gasolina	40.61	6.44	261.53	153379
1134	90	2025-08-25	gasolina	48.40	5.61	271.52	139819
1135	54	2025-08-26	diesel	102.30	6.13	627.10	72017
1136	59	2025-08-26	diesel	52.71	5.91	311.52	133828
1137	70	2025-08-26	diesel	62.59	6.42	401.83	152452
1138	81	2025-08-26	gasolina	33.33	5.85	194.98	79336
1139	83	2025-08-26	etanol	32.94	4.44	146.25	107042
1140	84	2025-08-26	etanol	34.26	4.21	144.23	36804
1141	58	2025-08-27	diesel	62.25	5.93	369.14	63888
1142	82	2025-08-27	gasolina	36.51	5.55	202.63	22004
1143	85	2025-08-27	etanol	39.84	4.56	181.67	14510
1144	86	2025-08-27	etanol	33.92	4.60	156.03	47863
1145	62	2025-08-28	diesel	71.69	6.12	438.74	42911
1146	63	2025-08-28	diesel	61.54	6.36	391.39	131133
1147	67	2025-08-28	etanol	32.22	4.36	140.48	111228
1148	71	2025-08-28	diesel	58.23	6.36	370.34	119303
1149	78	2025-08-28	gasolina	41.13	5.77	237.32	22526
1150	88	2025-08-28	gasolina	50.05	5.95	297.80	138349
1151	72	2025-09-08	gasolina	59.33	5.75	341.15	34299
1152	86	2025-09-08	etanol	33.03	4.29	141.70	49101
1153	62	2025-09-09	diesel	74.35	5.82	432.72	44078
1154	78	2025-09-09	gasolina	33.45	5.55	185.65	23404
1155	79	2025-09-09	etanol	30.81	4.31	132.79	155006
1156	81	2025-09-09	gasolina	33.19	6.01	199.47	80646
1157	90	2025-09-09	gasolina	49.92	5.93	296.03	141262
1158	63	2025-09-10	diesel	46.60	5.79	269.81	131789
1159	65	2025-09-10	etanol	43.71	4.34	189.70	81219
1160	66	2025-09-10	gasolina	38.21	5.84	223.15	90826
1161	69	2025-09-10	gasolina	72.53	5.85	424.30	20308
1162	71	2025-09-10	diesel	71.63	6.26	448.40	119935
1163	76	2025-09-10	gasolina	68.19	6.00	409.14	99132
1164	80	2025-09-10	etanol	42.79	4.44	189.99	103808
1165	82	2025-09-10	etanol	35.12	3.92	137.67	22899
1166	87	2025-09-10	gasolina	53.02	5.67	300.62	132150
1167	89	2025-09-10	gasolina	50.53	6.25	315.81	22863
1168	55	2025-09-11	diesel	119.21	6.43	766.52	97205
1169	68	2025-09-11	etanol	41.31	3.90	161.11	75748
1170	74	2025-09-11	diesel	56.05	6.32	354.24	70749
1171	83	2025-09-11	etanol	41.39	4.22	174.67	107448
1172	59	2025-09-12	diesel	64.57	6.50	419.71	135003
1173	70	2025-09-12	diesel	72.56	6.39	463.66	153482
1174	75	2025-09-12	diesel	56.18	6.01	337.64	142391
1175	85	2025-09-12	gasolina	41.76	5.86	244.71	15348
1176	88	2025-09-12	etanol	49.24	4.03	198.44	139190
1177	51	2025-09-13	diesel	128.61	6.04	776.80	41116
1178	57	2025-09-13	diesel	65.98	6.27	413.69	130007
1179	64	2025-09-13	gasolina	47.51	5.61	266.53	110640
1180	67	2025-09-13	etanol	32.81	4.18	137.15	111783
1181	73	2025-09-13	diesel	48.55	5.93	287.90	17884
1182	84	2025-09-13	gasolina	31.86	6.15	195.94	37903
1183	52	2025-09-14	diesel	133.30	6.27	835.79	126370
1184	53	2025-09-14	diesel	144.96	5.88	852.36	75455
1185	54	2025-09-14	diesel	139.74	6.17	862.20	73211
1186	56	2025-09-14	diesel	98.70	6.21	612.93	116217
1187	58	2025-09-14	diesel	66.34	6.36	421.92	64975
1188	60	2025-09-14	diesel	73.50	6.26	460.11	57158
1189	61	2025-09-14	diesel	50.76	5.81	294.92	98506
1190	77	2025-09-14	gasolina	33.89	6.09	206.39	153879
1191	57	2025-09-18	diesel	45.76	6.07	277.76	130503
1192	70	2025-09-18	diesel	74.21	6.36	471.98	153869
1193	74	2025-09-18	diesel	52.70	5.97	314.62	71668
1194	86	2025-09-18	etanol	39.78	4.33	172.25	49647
1195	56	2025-09-19	diesel	139.30	6.01	837.19	116831
1196	65	2025-09-19	etanol	36.59	4.64	169.78	82133
1197	71	2025-09-19	diesel	61.13	6.45	394.29	120821
1198	88	2025-09-19	etanol	57.43	4.47	256.71	140381
1199	51	2025-09-20	diesel	148.05	5.93	877.94	42700
1200	69	2025-09-20	gasolina	69.35	5.57	386.28	20943
1201	53	2025-09-21	diesel	93.93	6.03	566.40	76234
1202	58	2025-09-22	diesel	64.55	6.19	399.56	65671
1203	75	2025-09-22	diesel	58.64	6.12	358.88	142881
1204	60	2025-09-23	diesel	65.73	5.97	392.41	57582
1205	67	2025-09-23	etanol	38.03	4.22	160.49	112700
1206	76	2025-09-23	gasolina	72.69	5.59	406.34	100807
1207	83	2025-09-23	etanol	34.97	4.54	158.76	108058
1208	89	2025-09-23	gasolina	56.68	5.71	323.64	23907
1209	73	2025-09-24	diesel	65.10	6.34	412.73	18930
1210	79	2025-09-24	etanol	30.30	4.10	124.23	156053
1211	82	2025-09-24	etanol	45.38	4.12	186.97	23571
1212	52	2025-09-25	diesel	95.10	6.37	605.79	126720
1213	54	2025-09-25	diesel	102.61	6.30	646.44	74225
1214	72	2025-09-25	gasolina	57.77	6.15	355.29	35156
1215	81	2025-09-25	gasolina	40.85	6.08	248.37	81227
1216	85	2025-09-25	gasolina	42.61	6.09	259.49	15807
1217	87	2025-09-25	gasolina	50.06	6.41	320.88	133092
1218	62	2025-09-26	diesel	57.27	6.52	373.40	44622
1219	63	2025-09-26	diesel	70.53	6.32	445.75	132372
1220	64	2025-09-26	gasolina	31.28	6.01	187.99	111549
1221	68	2025-09-26	etanol	36.51	4.16	151.88	76900
1222	77	2025-09-26	gasolina	32.93	6.01	197.91	155009
1223	90	2025-09-26	gasolina	40.82	6.03	246.14	141585
1224	55	2025-09-27	diesel	128.39	6.49	833.25	98034
1225	59	2025-09-27	diesel	49.24	6.49	319.57	135560
1226	78	2025-09-27	gasolina	32.33	5.69	183.96	24431
1227	80	2025-09-27	etanol	35.82	4.53	162.26	104243
1228	84	2025-09-27	gasolina	45.59	5.91	269.44	38938
1229	61	2025-09-28	diesel	65.77	6.23	409.75	99378
1230	66	2025-09-28	gasolina	41.56	5.63	233.98	91482
1231	55	2025-10-08	diesel	105.43	6.20	653.67	98906
1232	73	2025-10-08	diesel	68.81	5.93	408.04	20186
1233	74	2025-10-08	gasolina	67.41	5.84	393.67	73170
1234	83	2025-10-08	gasolina	33.19	5.79	192.17	108569
1235	52	2025-10-09	diesel	103.95	6.49	674.64	128220
1236	53	2025-10-09	diesel	109.43	6.24	682.84	77059
1237	62	2025-10-09	diesel	56.12	6.32	354.68	45171
1238	63	2025-10-09	diesel	60.32	6.50	392.08	133216
1239	72	2025-10-09	diesel	73.98	5.98	442.40	36098
1240	77	2025-10-09	gasolina	43.44	5.86	254.56	155972
1241	79	2025-10-09	etanol	34.63	4.21	145.79	157269
1242	81	2025-10-09	etanol	34.32	3.98	136.59	82224
1243	85	2025-10-09	gasolina	40.25	6.29	253.17	16581
1244	86	2025-10-09	gasolina	36.39	5.83	212.15	50252
1245	88	2025-10-09	gasolina	51.58	5.70	294.01	141235
1246	90	2025-10-09	gasolina	56.65	5.71	323.47	143359
1247	57	2025-10-10	diesel	50.57	6.26	316.57	131794
1248	65	2025-10-10	gasolina	42.13	5.65	238.03	83038
1249	66	2025-10-10	etanol	34.12	3.94	134.43	92288
1250	68	2025-10-10	etanol	47.49	3.92	186.16	77888
1251	51	2025-10-11	diesel	143.10	5.88	841.43	43383
1252	59	2025-10-11	diesel	72.58	6.19	449.27	136270
1253	61	2025-10-11	diesel	74.51	6.49	483.57	100480
1254	69	2025-10-11	diesel	62.66	6.34	397.26	21989
1255	70	2025-10-11	diesel	59.87	5.93	355.03	155480
1256	87	2025-10-11	etanol	55.94	4.19	234.39	133809
1257	56	2025-10-12	diesel	140.29	6.52	914.69	117229
1258	58	2025-10-12	diesel	53.35	6.17	329.17	66591
1259	60	2025-10-12	diesel	59.87	5.79	346.65	58612
1260	67	2025-10-12	etanol	47.36	3.96	187.55	113881
1261	76	2025-10-12	gasolina	48.97	5.66	277.17	101788
1262	80	2025-10-12	gasolina	39.55	5.78	228.60	104812
1263	84	2025-10-12	etanol	43.58	4.12	179.55	40005
1264	89	2025-10-12	gasolina	47.37	5.93	280.90	24832
1265	64	2025-10-13	gasolina	31.99	5.81	185.86	112045
1266	71	2025-10-13	diesel	73.65	6.09	448.53	121510
1267	75	2025-10-13	gasolina	73.67	5.63	414.76	144252
1268	82	2025-10-13	gasolina	40.99	5.83	238.97	24746
1269	54	2025-10-14	diesel	145.96	6.33	923.93	75348
1270	78	2025-10-14	etanol	39.39	4.17	164.26	25512
1271	65	2025-10-18	gasolina	47.22	5.87	277.18	84270
1272	78	2025-10-18	etanol	41.57	4.50	187.07	26408
1273	80	2025-10-18	gasolina	35.08	5.80	203.46	105595
1274	68	2025-10-19	etanol	37.11	4.21	156.23	79379
1275	58	2025-10-20	diesel	52.59	6.20	326.06	66801
1276	60	2025-10-20	diesel	51.02	6.40	326.53	59092
1277	63	2025-10-20	diesel	49.60	6.10	302.56	133732
1278	72	2025-10-20	diesel	53.58	5.80	310.76	36534
1279	73	2025-10-20	diesel	52.85	5.94	313.93	20604
1280	74	2025-10-20	gasolina	61.22	5.67	347.12	74043
1281	76	2025-10-20	gasolina	49.77	6.37	317.03	102194
1282	82	2025-10-20	gasolina	35.36	6.45	228.07	25899
1283	89	2025-10-20	gasolina	43.08	5.72	246.42	25575
1284	90	2025-10-20	gasolina	48.77	5.82	283.84	144304
1285	51	2025-10-21	diesel	99.69	6.10	608.11	43855
1286	61	2025-10-21	diesel	72.49	6.34	459.59	101673
1287	64	2025-10-21	gasolina	42.21	6.19	261.28	112554
1288	70	2025-10-21	diesel	67.86	5.81	394.27	156529
1289	71	2025-10-21	diesel	62.09	5.90	366.33	121992
1290	75	2025-10-21	gasolina	68.65	6.18	424.26	145154
1291	84	2025-10-21	etanol	30.34	4.31	130.77	40797
1292	52	2025-10-22	diesel	147.75	6.25	923.44	128963
1293	77	2025-10-22	gasolina	41.63	5.88	244.78	156904
1294	81	2025-10-22	etanol	34.16	4.01	136.98	82879
1295	59	2025-10-23	diesel	45.26	5.80	262.51	137124
1296	88	2025-10-23	gasolina	41.54	6.33	262.95	142097
1297	56	2025-10-24	diesel	143.48	6.51	934.05	117785
1298	53	2025-10-25	diesel	98.61	6.15	606.45	77592
1299	62	2025-10-25	diesel	68.01	5.85	397.86	45758
1300	79	2025-10-25	etanol	36.16	4.38	158.38	157601
1301	66	2025-10-26	etanol	35.24	4.10	144.48	93010
1302	69	2025-10-26	diesel	50.80	6.05	307.34	22899
1303	85	2025-10-26	gasolina	32.53	5.73	186.40	17376
1304	83	2025-10-27	gasolina	39.84	6.14	244.62	109466
1305	86	2025-10-27	gasolina	36.53	6.01	219.55	50619
1306	87	2025-10-27	etanol	50.76	4.26	216.24	134611
1307	54	2025-10-28	diesel	93.40	5.97	557.60	75792
1308	55	2025-10-28	diesel	120.39	5.90	710.30	99577
1309	57	2025-10-28	diesel	50.05	6.38	319.32	132741
1310	67	2025-10-28	etanol	39.01	3.86	150.58	114773
1311	54	2025-11-08	diesel	94.51	6.48	612.42	76625
1312	61	2025-11-08	diesel	70.12	6.32	443.16	102369
1313	68	2025-11-08	etanol	34.31	3.86	132.44	80925
1314	75	2025-11-08	diesel	53.09	6.26	332.34	145907
1315	84	2025-11-08	gasolina	41.18	5.96	245.43	41995
1316	85	2025-11-08	etanol	44.11	3.87	170.71	18041
1317	53	2025-11-09	diesel	125.51	6.24	783.18	78193
1318	62	2025-11-09	diesel	71.37	5.84	416.80	46759
1319	63	2025-11-09	diesel	63.06	5.96	375.84	134853
1320	82	2025-11-09	etanol	45.13	4.38	197.67	27006
1321	88	2025-11-09	gasolina	57.31	6.03	345.58	142593
1322	89	2025-11-09	gasolina	47.82	5.67	271.14	26456
1323	90	2025-11-09	etanol	44.90	4.13	185.44	144935
1324	51	2025-11-10	diesel	115.28	6.04	696.29	44494
1325	55	2025-11-10	diesel	147.95	6.54	967.59	100077
1326	56	2025-11-10	diesel	123.90	6.15	761.99	119158
1327	60	2025-11-10	diesel	67.15	5.89	395.51	60138
1328	67	2025-11-10	gasolina	45.26	6.29	284.69	115780
1329	69	2025-11-10	diesel	73.84	5.95	439.35	23374
1330	83	2025-11-10	gasolina	43.49	6.43	279.64	110455
1331	87	2025-11-10	gasolina	50.84	5.81	295.38	135199
1332	52	2025-11-11	diesel	131.91	5.84	770.35	129697
1333	64	2025-11-11	gasolina	31.58	5.80	183.16	114093
1334	74	2025-11-11	diesel	65.75	5.87	385.95	74525
1335	77	2025-11-11	gasolina	39.75	6.13	243.67	157695
1336	81	2025-11-11	etanol	33.74	3.88	130.91	83778
1337	86	2025-11-11	etanol	42.00	3.99	167.58	51400
1338	66	2025-11-12	etanol	47.66	4.56	217.33	94634
1339	76	2025-11-12	diesel	53.25	6.40	340.80	103212
1340	78	2025-11-12	gasolina	43.08	5.55	239.09	27119
1341	57	2025-11-13	diesel	63.50	6.05	384.18	133594
1342	65	2025-11-13	gasolina	33.56	6.03	202.37	85526
1343	70	2025-11-13	gasolina	55.25	5.82	321.56	157563
1344	71	2025-11-13	diesel	56.37	6.43	362.46	122789
1345	73	2025-11-13	diesel	50.19	5.90	296.12	21958
1346	80	2025-11-13	gasolina	42.63	6.25	266.44	106465
1347	58	2025-11-14	diesel	68.22	6.04	412.05	68063
1348	59	2025-11-14	diesel	54.71	5.97	326.62	137703
1349	72	2025-11-14	diesel	50.44	5.86	295.58	37658
1350	79	2025-11-14	gasolina	35.95	6.12	220.01	158906
1351	55	2025-11-18	diesel	146.50	6.50	952.25	100666
1352	60	2025-11-18	diesel	62.62	6.53	408.91	60942
1353	64	2025-11-18	gasolina	39.27	5.87	230.51	114982
1354	79	2025-11-18	gasolina	38.01	6.15	233.76	159807
1355	80	2025-11-18	gasolina	36.61	5.90	216.00	107709
1356	83	2025-11-18	gasolina	33.20	5.62	186.58	111730
1357	88	2025-11-18	gasolina	57.89	6.21	359.50	143263
1358	73	2025-11-19	diesel	55.71	6.53	363.79	22838
1359	74	2025-11-19	diesel	49.62	6.25	310.13	75054
1360	81	2025-11-20	etanol	33.62	4.56	153.31	84601
1361	84	2025-11-20	gasolina	41.31	6.16	254.47	42620
1362	58	2025-11-21	diesel	57.03	6.53	372.41	68738
1363	67	2025-11-21	gasolina	37.69	5.57	209.93	117195
1364	56	2025-11-22	diesel	122.31	6.55	801.13	119675
1365	59	2025-11-22	diesel	51.02	5.92	302.04	138293
1366	65	2025-11-22	gasolina	34.19	6.26	214.03	86549
1367	68	2025-11-22	etanol	45.66	4.39	200.45	82020
1368	51	2025-11-23	diesel	91.17	6.19	564.34	45645
1369	53	2025-11-23	diesel	92.21	5.90	544.04	79119
1370	57	2025-11-23	diesel	54.60	6.04	329.78	134222
1371	76	2025-11-23	diesel	69.73	6.00	418.38	103808
1372	86	2025-11-23	etanol	36.79	3.94	144.95	52705
1373	89	2025-11-23	gasolina	46.45	5.78	268.48	27713
1374	62	2025-11-24	diesel	63.48	6.27	398.02	47394
1375	63	2025-11-24	diesel	51.49	6.25	321.81	135249
1376	70	2025-11-24	gasolina	69.60	5.79	402.98	158052
1377	78	2025-11-24	gasolina	39.39	5.86	230.83	28116
1378	66	2025-11-25	etanol	34.63	4.50	155.84	95253
1379	75	2025-11-25	diesel	68.09	5.96	405.82	146300
1380	82	2025-11-25	etanol	30.62	4.63	141.77	28201
1381	52	2025-11-26	diesel	146.61	5.90	865.00	130546
1382	69	2025-11-26	diesel	55.12	6.20	341.74	24541
1383	71	2025-11-26	diesel	70.54	6.12	431.70	123307
1384	72	2025-11-26	diesel	56.75	6.28	356.39	38154
1385	85	2025-11-26	etanol	42.08	4.13	173.79	18553
1386	87	2025-11-27	gasolina	44.30	5.85	259.16	135720
1387	54	2025-11-28	diesel	111.13	5.96	662.33	77046
1388	61	2025-11-28	diesel	49.05	6.48	317.84	103998
1389	77	2025-11-28	gasolina	33.83	5.56	188.09	158843
1390	90	2025-11-28	etanol	42.48	4.27	181.39	145996
1391	51	2025-12-08	diesel	113.06	6.16	696.45	46539
1392	61	2025-12-08	diesel	50.39	6.50	327.54	104679
1393	64	2025-12-08	gasolina	40.32	6.44	259.66	115971
1394	73	2025-12-08	diesel	58.29	6.39	372.47	23865
1395	74	2025-12-08	diesel	58.71	6.44	378.09	75447
1396	79	2025-12-08	gasolina	33.92	6.33	214.71	160902
1397	66	2025-12-09	gasolina	47.96	6.13	293.99	96337
1398	80	2025-12-09	etanol	37.87	3.93	148.83	108807
1399	83	2025-12-09	gasolina	43.45	6.31	274.17	112543
1400	53	2025-12-10	diesel	130.78	6.47	846.15	80246
1401	57	2025-12-10	diesel	70.13	5.95	417.27	134805
1402	60	2025-12-10	diesel	73.86	5.90	435.77	61505
1403	82	2025-12-10	etanol	30.56	4.33	132.32	28901
1404	86	2025-12-10	etanol	33.22	4.64	154.14	54013
1405	87	2025-12-10	gasolina	44.95	5.80	260.71	136736
1406	90	2025-12-10	gasolina	56.74	5.88	333.63	146724
1407	62	2025-12-11	diesel	73.27	6.21	455.01	48331
1408	78	2025-12-11	etanol	33.49	3.92	131.28	28806
1409	55	2025-12-12	diesel	144.27	6.42	926.21	101623
1410	56	2025-12-12	diesel	133.63	6.09	813.81	120524
1411	58	2025-12-12	diesel	49.02	5.80	284.32	69365
1412	59	2025-12-12	diesel	58.64	6.50	381.16	138931
1413	69	2025-12-12	diesel	73.21	6.51	476.60	26101
1414	72	2025-12-12	gasolina	54.30	6.09	330.69	39158
1415	77	2025-12-12	gasolina	40.70	5.74	233.62	160041
1416	84	2025-12-12	gasolina	31.12	5.80	180.50	43960
1417	54	2025-12-13	diesel	114.03	6.51	742.34	78353
1418	67	2025-12-13	gasolina	44.40	6.21	275.72	117701
1419	70	2025-12-13	gasolina	73.39	5.95	436.67	158832
1420	71	2025-12-13	diesel	48.60	6.03	293.06	124178
1421	75	2025-12-13	diesel	49.33	6.50	320.65	147412
1422	76	2025-12-13	diesel	68.36	6.06	414.26	104896
1423	52	2025-12-14	diesel	126.06	5.76	726.11	131503
1424	63	2025-12-14	diesel	45.17	6.02	271.92	136228
1425	65	2025-12-14	etanol	43.20	3.87	167.18	87612
1426	68	2025-12-14	gasolina	42.05	5.95	250.20	83194
1427	81	2025-12-14	gasolina	44.98	5.97	268.53	85980
1428	85	2025-12-14	etanol	30.08	3.91	117.61	19163
1429	88	2025-12-14	gasolina	43.84	5.70	249.89	144381
1430	89	2025-12-14	gasolina	49.18	5.55	272.95	28578
1431	56	2025-12-18	diesel	125.68	6.03	757.85	121409
1432	70	2025-12-18	gasolina	65.65	5.70	374.21	160035
1433	73	2025-12-18	diesel	62.69	6.39	400.59	24599
1434	80	2025-12-18	etanol	45.70	4.41	201.54	109125
1435	90	2025-12-18	gasolina	45.50	5.64	256.62	147824
1436	51	2025-12-19	diesel	96.77	6.48	627.07	47069
1437	57	2025-12-19	diesel	62.01	6.25	387.56	135752
1438	61	2025-12-20	diesel	52.58	5.99	314.95	105117
1439	74	2025-12-20	diesel	73.49	5.95	437.27	76219
1440	83	2025-12-20	gasolina	35.25	6.28	221.37	113581
1441	88	2025-12-20	gasolina	46.54	6.39	297.39	145403
1442	59	2025-12-21	diesel	46.73	6.10	285.05	139900
1443	63	2025-12-21	diesel	61.16	5.94	363.29	136904
1444	64	2025-12-21	gasolina	31.83	6.39	203.39	116251
1445	67	2025-12-21	gasolina	35.58	5.73	203.87	118718
1446	85	2025-12-21	etanol	38.45	4.60	176.87	20007
1447	53	2025-12-22	diesel	96.90	6.17	597.87	81039
1448	69	2025-12-22	diesel	72.58	6.36	461.61	26657
1449	79	2025-12-22	gasolina	40.50	5.81	235.31	161510
1450	84	2025-12-22	gasolina	31.70	5.61	177.84	44411
1451	87	2025-12-22	gasolina	54.10	6.42	347.32	137353
1452	89	2025-12-22	gasolina	54.53	6.42	350.08	28991
1453	65	2025-12-23	etanol	42.28	4.39	185.61	88808
1454	54	2025-12-24	diesel	117.73	5.88	692.25	79130
1455	62	2025-12-24	diesel	54.43	6.40	348.35	49525
1456	81	2025-12-24	gasolina	43.81	6.38	279.51	87126
1457	52	2025-12-25	diesel	106.72	6.00	640.32	132487
1458	60	2025-12-25	diesel	50.92	6.01	306.03	62207
1459	68	2025-12-25	gasolina	38.00	5.66	215.08	83683
1460	75	2025-12-25	diesel	71.50	6.48	463.32	148502
1461	82	2025-12-25	etanol	44.16	4.42	195.19	29464
1462	86	2025-12-25	etanol	45.46	4.20	190.93	54393
1463	55	2025-12-26	diesel	132.58	6.27	831.28	103234
1464	58	2025-12-26	diesel	68.32	5.96	407.19	70092
1465	66	2025-12-26	gasolina	30.27	5.78	174.96	96998
1466	71	2025-12-26	diesel	72.51	6.27	454.64	124679
1467	72	2025-12-26	gasolina	48.28	6.09	294.03	40497
1468	76	2025-12-27	diesel	54.43	5.99	326.04	105793
1469	77	2025-12-27	gasolina	43.80	5.64	247.03	160940
1470	78	2025-12-28	etanol	44.87	4.27	191.59	29867
1471	51	2026-01-08	diesel	95.04	5.97	567.39	48335
1472	54	2026-01-08	diesel	138.57	6.26	867.45	79712
1473	55	2026-01-08	diesel	96.06	6.00	576.36	103703
1474	59	2026-01-08	diesel	49.11	6.45	316.76	141023
1475	60	2026-01-08	diesel	65.45	6.04	395.32	63027
1476	68	2026-01-08	etanol	36.29	4.50	163.31	85075
1477	70	2026-01-08	gasolina	61.21	5.62	344.00	160875
1478	73	2026-01-08	diesel	50.67	6.33	320.74	25707
1479	75	2026-01-08	diesel	64.09	6.52	417.87	149557
1480	52	2026-01-09	diesel	118.52	5.94	704.01	133058
1481	63	2026-01-09	diesel	63.09	6.47	408.19	137496
1482	74	2026-01-09	diesel	74.15	6.13	454.54	77079
1483	79	2026-01-09	etanol	39.28	3.94	154.76	162374
1484	84	2026-01-09	gasolina	32.99	6.00	197.94	44796
1485	53	2026-01-10	diesel	147.97	6.11	904.10	82015
1486	61	2026-01-10	diesel	56.47	5.88	332.04	105730
1487	66	2026-01-10	etanol	42.42	4.59	194.71	97829
1488	69	2026-01-10	diesel	54.87	6.04	331.41	27763
1489	71	2026-01-10	diesel	59.84	5.84	349.47	125402
1490	72	2026-01-10	gasolina	62.85	6.35	399.10	41239
1491	78	2026-01-10	gasolina	37.72	5.99	225.94	31055
1492	86	2026-01-11	gasolina	39.30	5.72	224.80	55878
1493	87	2026-01-11	gasolina	48.64	6.10	296.70	138806
1494	88	2026-01-12	gasolina	45.03	6.45	290.44	145935
1495	56	2026-01-13	diesel	94.10	5.93	558.01	121934
1496	57	2026-01-13	diesel	57.10	5.79	330.61	136379
1497	58	2026-01-13	diesel	49.48	5.89	291.44	71226
1498	62	2026-01-13	diesel	65.28	5.88	383.85	50273
1499	64	2026-01-13	etanol	47.40	4.17	197.66	117507
1500	67	2026-01-13	etanol	37.80	4.16	157.25	119636
1501	76	2026-01-13	diesel	67.64	6.27	424.10	106876
1502	77	2026-01-13	gasolina	40.57	6.19	251.13	161770
1503	80	2026-01-13	gasolina	30.64	6.19	189.66	110202
1504	81	2026-01-13	gasolina	30.77	5.57	171.39	88125
1505	83	2026-01-13	gasolina	35.21	6.40	225.34	114063
1506	85	2026-01-13	gasolina	31.28	6.31	197.38	20937
1507	89	2026-01-13	gasolina	46.85	5.95	278.76	30072
1508	90	2026-01-13	gasolina	45.62	5.78	263.68	148556
1509	65	2026-01-14	etanol	33.56	3.99	133.90	89920
1510	82	2026-01-14	gasolina	32.94	6.15	202.58	30343
1511	79	2026-01-18	etanol	42.85	4.54	194.54	162899
1512	53	2026-01-19	diesel	105.12	6.18	649.64	83304
1513	64	2026-01-19	etanol	40.74	4.41	179.66	118316
1514	87	2026-01-19	gasolina	44.12	6.29	277.51	139414
1515	51	2026-01-20	diesel	106.23	5.85	621.45	48862
1516	58	2026-01-20	diesel	60.85	6.03	366.93	72147
1517	65	2026-01-20	etanol	34.66	4.37	151.46	90310
1518	66	2026-01-20	etanol	42.84	3.93	168.36	98887
1519	90	2026-01-20	gasolina	46.05	6.39	294.26	149230
1520	55	2026-01-21	diesel	130.61	5.99	782.35	104988
1521	69	2026-01-21	diesel	62.90	6.17	388.09	28283
1522	73	2026-01-21	diesel	58.17	6.30	366.47	26908
1523	88	2026-01-21	gasolina	54.57	5.82	317.60	146629
1524	67	2026-01-22	etanol	39.34	4.32	169.95	120437
1525	77	2026-01-23	gasolina	36.95	6.38	235.74	162541
1526	52	2026-01-24	diesel	132.28	6.00	793.68	133631
1527	57	2026-01-24	diesel	59.99	5.88	352.74	137361
1528	85	2026-01-24	gasolina	42.71	5.89	251.56	21616
1529	89	2026-01-24	gasolina	52.89	6.17	326.33	30345
1530	59	2026-01-25	diesel	50.40	6.49	327.10	141659
1531	60	2026-01-25	diesel	53.01	5.91	313.29	64132
1532	68	2026-01-25	etanol	46.47	4.62	214.69	85612
1533	70	2026-01-25	gasolina	59.99	5.86	351.54	161276
1534	74	2026-01-25	diesel	73.99	6.46	477.98	77425
1535	75	2026-01-25	diesel	59.11	6.54	386.58	150338
1536	76	2026-01-25	diesel	50.96	6.26	319.01	107509
1537	80	2026-01-25	gasolina	30.22	5.72	172.86	110796
1538	54	2026-01-26	diesel	133.24	6.40	852.74	80139
1539	56	2026-01-26	diesel	114.05	6.20	707.11	122621
1540	81	2026-01-26	gasolina	39.80	5.68	226.06	88663
1541	82	2026-01-26	gasolina	42.73	5.92	252.96	31833
1542	63	2026-01-27	diesel	66.65	5.84	389.24	138518
1543	72	2026-01-27	gasolina	62.27	5.92	368.64	42144
1544	78	2026-01-27	gasolina	33.75	6.35	214.31	31767
1545	84	2026-01-27	gasolina	39.46	5.79	228.47	45437
1546	86	2026-01-27	gasolina	42.78	6.08	260.10	56704
1547	61	2026-01-28	diesel	64.68	6.13	396.49	106620
1548	62	2026-01-28	diesel	68.00	6.42	436.56	50937
1549	71	2026-01-28	diesel	55.22	6.42	354.51	126404
1550	83	2026-01-28	gasolina	31.30	6.03	188.74	115128
1551	68	2026-02-08	gasolina	43.04	5.95	256.09	86474
1552	76	2026-02-08	diesel	56.03	5.90	330.58	108529
1553	87	2026-02-08	gasolina	46.85	6.19	290.00	139896
1554	56	2026-02-09	diesel	147.87	6.14	907.92	123510
1555	66	2026-02-09	gasolina	38.56	6.13	236.37	99986
1556	75	2026-02-09	gasolina	62.49	6.08	379.94	151214
1557	79	2026-02-09	etanol	38.28	3.85	147.38	163792
1558	69	2026-02-10	diesel	49.93	6.31	315.06	28900
1559	70	2026-02-10	diesel	58.49	5.86	342.75	161785
1560	71	2026-02-10	diesel	48.31	6.05	292.28	127402
1561	86	2026-02-10	etanol	45.52	4.21	191.64	57605
1562	52	2026-02-11	diesel	143.09	6.27	897.17	134566
1563	58	2026-02-11	diesel	74.47	6.15	457.99	72920
1564	60	2026-02-11	diesel	60.04	6.08	365.04	64747
1565	77	2026-02-11	etanol	33.06	4.05	133.89	163013
1566	81	2026-02-11	gasolina	34.38	5.71	196.31	89348
1567	57	2026-02-12	diesel	63.79	5.86	373.81	138353
1568	63	2026-02-12	diesel	66.32	5.97	395.93	139995
1569	64	2026-02-12	etanol	32.66	4.14	135.21	119482
1570	74	2026-02-12	diesel	61.72	6.18	381.43	78577
1571	84	2026-02-12	gasolina	31.72	5.56	176.36	46021
1572	85	2026-02-12	gasolina	37.90	5.68	215.27	22576
1573	88	2026-02-12	etanol	57.94	4.29	248.56	147065
1574	89	2026-02-12	gasolina	49.49	5.64	279.12	31214
1575	51	2026-02-13	diesel	139.14	5.96	829.27	49669
1576	53	2026-02-13	diesel	137.86	5.96	821.65	84301
1577	54	2026-02-13	diesel	128.33	6.40	821.31	81169
1578	62	2026-02-13	diesel	52.46	6.22	326.30	51801
1579	65	2026-02-13	gasolina	39.17	5.83	228.36	91387
1580	67	2026-02-13	etanol	36.32	4.18	151.82	121163
1581	73	2026-02-13	diesel	51.09	5.85	298.88	28116
1582	83	2026-02-13	etanol	35.39	4.28	151.47	116699
1583	90	2026-02-13	gasolina	54.92	6.10	335.01	149948
1584	55	2026-02-14	diesel	129.15	6.13	791.69	105894
1585	59	2026-02-14	diesel	49.92	5.93	296.03	142755
1586	61	2026-02-14	diesel	74.83	6.35	475.17	107217
1587	72	2026-02-14	diesel	52.07	6.17	321.27	43250
1588	78	2026-02-14	gasolina	43.03	6.05	260.33	32759
1589	80	2026-02-14	gasolina	32.20	6.26	201.57	111864
1590	82	2026-02-14	etanol	31.02	4.26	132.15	32494
1591	64	2026-02-18	etanol	47.89	4.64	222.21	120076
1592	66	2026-02-18	gasolina	46.13	6.41	295.69	100635
1593	75	2026-02-19	gasolina	70.10	5.78	405.18	152250
1594	85	2026-02-19	gasolina	37.37	6.44	240.66	23225
1595	57	2026-02-20	diesel	58.30	6.53	380.70	138869
1596	65	2026-02-20	gasolina	42.90	6.21	266.41	91846
1597	69	2026-02-20	diesel	73.87	6.34	468.34	29500
1598	77	2026-02-20	etanol	34.60	3.87	133.90	163594
1599	78	2026-02-20	gasolina	40.32	6.38	257.24	33301
1600	87	2026-02-20	gasolina	44.47	6.16	273.94	140459
1601	90	2026-02-20	gasolina	49.08	6.11	299.88	150542
1602	52	2026-02-21	diesel	130.04	6.49	843.96	135301
1603	61	2026-02-21	diesel	45.39	6.18	280.51	107764
1604	79	2026-02-21	etanol	42.47	4.53	192.39	164266
1605	89	2026-02-21	gasolina	40.47	5.57	225.42	32140
1606	59	2026-02-22	diesel	69.06	6.18	426.79	143203
1607	58	2026-02-23	diesel	72.03	6.06	436.50	73228
1608	60	2026-02-23	diesel	46.32	5.97	276.53	66017
1609	62	2026-02-23	diesel	67.99	5.99	407.26	52215
1610	81	2026-02-23	gasolina	43.25	5.95	257.34	90229
1611	88	2026-02-23	etanol	40.49	4.31	174.51	147503
1612	55	2026-02-24	diesel	97.45	6.14	598.34	106521
1613	76	2026-02-24	diesel	67.23	6.48	435.65	109600
1614	54	2026-02-25	diesel	149.77	6.36	952.54	81674
1615	72	2026-02-25	diesel	68.64	6.16	422.82	44105
1616	82	2026-02-25	etanol	45.08	3.99	179.87	33519
1617	86	2026-02-25	etanol	32.48	4.17	135.44	59431
1618	51	2026-02-26	diesel	124.24	6.31	783.95	50245
1619	63	2026-02-26	diesel	46.58	6.51	303.24	140707
1620	70	2026-02-26	diesel	50.32	6.04	303.93	162381
1621	80	2026-02-26	gasolina	45.55	5.72	260.55	112283
1622	83	2026-02-26	etanol	37.50	4.29	160.88	117280
1623	53	2026-02-27	diesel	98.77	6.01	593.61	84493
1624	56	2026-02-27	diesel	143.95	6.22	895.37	124589
1625	68	2026-02-27	gasolina	32.35	6.18	199.92	86780
1626	71	2026-02-27	diesel	66.51	6.14	408.37	128181
1627	73	2026-02-27	diesel	60.59	5.96	361.12	29097
1628	84	2026-02-27	gasolina	43.33	6.42	278.18	46718
1629	67	2026-02-28	etanol	40.64	4.28	173.94	121955
1630	74	2026-02-28	diesel	69.24	5.86	405.75	79277
1631	51	2026-03-08	diesel	137.98	5.90	814.08	51425
1632	52	2026-03-08	diesel	131.75	6.32	832.66	136425
1633	57	2026-03-08	diesel	70.52	6.13	432.29	139870
1634	63	2026-03-08	diesel	71.06	6.47	459.76	141943
1635	71	2026-03-08	gasolina	49.43	5.62	277.80	129016
1636	74	2026-03-08	gasolina	52.16	5.66	295.23	80060
1637	84	2026-03-08	gasolina	39.36	5.91	232.62	47198
1638	85	2026-03-08	gasolina	38.58	6.21	239.58	24151
1639	53	2026-03-09	diesel	100.61	6.34	637.87	85414
1640	55	2026-03-09	diesel	138.45	6.48	897.16	108057
1641	64	2026-03-09	etanol	36.69	4.14	151.90	120727
1642	66	2026-03-09	etanol	36.74	4.41	162.02	101882
1643	68	2026-03-09	etanol	39.06	4.42	172.65	88245
1644	82	2026-03-09	gasolina	38.21	5.93	226.59	34212
1645	87	2026-03-09	gasolina	52.30	6.24	326.35	141223
1646	90	2026-03-09	gasolina	53.58	6.04	323.62	151143
1647	65	2026-03-10	etanol	35.42	4.01	142.03	93034
1648	70	2026-03-10	gasolina	68.05	5.99	407.62	163653
1649	76	2026-03-10	diesel	69.83	5.96	416.19	110820
1650	78	2026-03-10	gasolina	42.66	6.06	258.52	34094
1651	80	2026-03-10	gasolina	44.22	5.61	248.07	113148
1652	83	2026-03-10	etanol	43.63	4.64	202.44	118350
1653	88	2026-03-10	gasolina	47.36	6.40	303.10	148330
1654	67	2026-03-11	etanol	35.68	4.24	151.28	123009
1655	69	2026-03-11	gasolina	69.45	6.42	445.87	30398
1656	86	2026-03-11	gasolina	32.60	5.89	192.01	59932
1657	61	2026-03-12	diesel	71.59	6.49	464.62	108480
1658	77	2026-03-12	etanol	33.41	4.64	155.02	164284
1659	81	2026-03-12	etanol	35.80	4.04	144.63	91741
1660	89	2026-03-12	gasolina	50.86	6.03	306.69	33042
1661	56	2026-03-13	diesel	138.95	5.89	818.42	125492
1662	60	2026-03-13	diesel	61.76	6.29	388.47	67273
1663	73	2026-03-13	diesel	48.65	5.95	289.47	30057
1664	75	2026-03-13	diesel	63.75	5.76	367.20	153712
1665	54	2026-03-14	diesel	140.02	6.03	844.32	82613
1666	58	2026-03-14	diesel	72.11	5.84	421.12	74106
1667	59	2026-03-14	diesel	72.54	5.92	429.44	144233
1668	62	2026-03-14	diesel	46.94	6.11	286.80	53407
1669	72	2026-03-14	diesel	62.26	5.80	361.11	44988
1670	79	2026-03-14	etanol	38.79	4.13	160.20	164842
1671	70	2026-03-18	gasolina	52.03	6.42	334.03	164634
1672	71	2026-03-18	gasolina	61.43	5.78	355.07	130038
1673	86	2026-03-18	gasolina	31.28	5.84	182.68	60981
1674	56	2026-03-19	diesel	139.56	6.16	859.69	126262
1675	58	2026-03-19	diesel	69.20	6.48	448.42	74672
1676	59	2026-03-19	diesel	51.05	5.82	297.11	145093
1677	90	2026-03-19	gasolina	49.98	5.56	277.89	151798
1678	80	2026-03-20	gasolina	34.10	6.20	211.42	113557
1679	81	2026-03-20	etanol	39.81	4.55	181.14	92509
1680	82	2026-03-20	gasolina	32.44	5.61	181.99	35568
1681	61	2026-03-21	diesel	71.69	6.39	458.10	109196
1682	51	2026-03-22	diesel	146.30	6.26	915.84	52020
1683	54	2026-03-22	diesel	132.25	6.30	833.18	83411
1684	60	2026-03-22	diesel	56.75	6.32	358.66	67852
1685	72	2026-03-22	diesel	60.80	6.17	375.14	45733
1686	83	2026-03-22	etanol	36.65	4.14	151.73	118918
1687	57	2026-03-23	diesel	45.08	6.42	289.41	141385
1688	64	2026-03-23	etanol	34.59	3.96	136.98	121621
1689	73	2026-03-23	diesel	66.75	5.76	384.48	31195
1690	87	2026-03-23	gasolina	50.82	5.57	283.07	141943
1691	52	2026-03-24	diesel	101.88	6.39	651.01	137755
1692	63	2026-03-24	diesel	49.26	6.12	301.47	142798
1693	74	2026-03-24	gasolina	69.37	6.42	445.36	81508
1694	77	2026-03-24	etanol	37.66	4.02	151.39	164830
1695	55	2026-03-25	diesel	133.03	5.91	786.21	108368
1696	67	2026-03-25	etanol	40.14	4.02	161.36	123683
1697	75	2026-03-25	diesel	69.98	5.82	407.28	154159
1698	76	2026-03-25	diesel	59.97	6.44	386.21	111622
1699	53	2026-03-26	diesel	105.22	6.26	658.68	87137
1700	69	2026-03-26	gasolina	69.84	6.39	446.28	30810
1701	79	2026-03-26	etanol	36.62	4.60	168.45	165958
1702	84	2026-03-26	gasolina	37.48	6.22	233.13	47530
1703	62	2026-03-27	diesel	46.37	6.47	300.01	54182
1704	65	2026-03-27	etanol	45.00	4.39	197.55	93477
1705	68	2026-03-27	etanol	34.12	4.12	140.57	88846
1706	88	2026-03-27	gasolina	40.79	6.04	246.37	149045
1707	66	2026-03-28	etanol	35.14	4.38	153.91	102463
1708	78	2026-03-28	gasolina	42.61	6.24	265.89	35222
1709	85	2026-03-28	gasolina	34.69	5.60	194.26	25230
1710	89	2026-03-28	gasolina	46.60	6.03	281.00	33895
1711	51	2026-04-08	diesel	126.49	5.93	750.09	52482
1712	61	2026-04-08	diesel	46.06	6.43	296.17	109828
1713	64	2026-04-08	gasolina	40.59	6.27	254.50	122684
1714	67	2026-04-08	gasolina	36.22	6.25	226.38	125521
1715	68	2026-04-08	etanol	37.91	4.50	170.60	89676
1716	71	2026-04-08	diesel	57.21	6.50	371.87	131369
1717	74	2026-04-08	gasolina	62.14	6.25	388.38	82184
1718	78	2026-04-08	gasolina	32.73	5.58	182.63	36010
1719	84	2026-04-08	etanol	33.22	4.25	141.19	48492
1720	59	2026-04-09	diesel	64.77	5.96	386.03	146765
1721	66	2026-04-09	etanol	37.03	3.96	146.64	103369
1722	81	2026-04-09	gasolina	44.67	6.06	270.70	93825
1723	82	2026-04-09	gasolina	30.20	5.65	170.63	36803
1724	56	2026-04-10	diesel	131.39	6.41	842.21	127931
1725	58	2026-04-10	diesel	46.80	6.20	290.16	75541
1726	73	2026-04-10	diesel	71.75	5.85	419.74	32058
1727	77	2026-04-10	etanol	42.24	4.62	195.15	166114
1728	79	2026-04-10	etanol	32.01	4.21	134.76	167287
1729	62	2026-04-11	diesel	66.77	5.97	398.62	54816
1730	69	2026-04-11	diesel	66.08	6.42	424.23	31874
1731	70	2026-04-11	diesel	56.93	5.85	333.04	165494
1732	72	2026-04-11	diesel	70.64	5.88	415.36	46625
1733	85	2026-04-11	etanol	41.03	4.06	166.58	26525
1734	86	2026-04-11	etanol	41.76	3.98	166.20	62232
1735	87	2026-04-11	etanol	43.61	3.95	172.26	143232
1736	52	2026-04-12	diesel	94.05	6.15	578.41	138487
1737	53	2026-04-12	diesel	145.71	6.47	942.74	88038
1738	63	2026-04-12	diesel	55.08	6.36	350.31	143539
1739	65	2026-04-12	etanol	32.27	4.53	146.18	94104
1740	80	2026-04-12	etanol	41.57	4.51	187.48	114410
1741	54	2026-04-13	diesel	101.15	5.75	581.61	84159
1742	75	2026-04-13	diesel	51.11	5.92	302.57	155696
1743	76	2026-04-13	diesel	58.93	6.00	353.58	112640
1744	55	2026-04-14	diesel	103.23	6.50	671.00	109760
1745	57	2026-04-14	diesel	60.34	5.86	353.59	141946
1746	60	2026-04-14	diesel	53.65	6.25	335.31	68750
1747	83	2026-04-14	gasolina	31.40	6.05	189.97	119573
1748	88	2026-04-14	etanol	53.27	4.43	235.99	150053
1749	89	2026-04-14	gasolina	40.13	5.73	229.94	34770
1750	90	2026-04-14	gasolina	53.72	5.99	321.78	152168
1751	53	2026-04-18	diesel	103.30	5.98	617.73	88782
1752	57	2026-04-18	diesel	60.44	6.09	368.08	142724
1753	60	2026-04-18	diesel	46.24	6.41	296.40	69635
1754	62	2026-04-18	diesel	70.11	5.82	408.04	55461
1755	78	2026-04-18	gasolina	39.42	6.09	240.07	36480
1756	85	2026-04-18	etanol	40.16	4.21	169.07	27299
1757	51	2026-04-19	diesel	117.23	6.02	705.72	53048
1758	79	2026-04-19	etanol	37.94	4.10	155.55	168027
1759	88	2026-04-19	etanol	53.86	4.23	227.83	150928
1760	55	2026-04-20	diesel	136.70	6.52	891.28	110310
1761	80	2026-04-20	etanol	44.55	4.31	192.01	115632
1762	82	2026-04-20	gasolina	35.13	6.02	211.48	37727
1763	86	2026-04-20	etanol	41.22	4.41	181.78	62681
1764	52	2026-04-21	diesel	103.85	5.93	615.83	139452
1765	63	2026-04-21	diesel	51.83	6.45	334.30	144315
1766	67	2026-04-21	gasolina	38.97	5.82	226.81	126475
1767	54	2026-04-22	diesel	111.48	6.27	698.98	84648
1768	81	2026-04-22	gasolina	37.08	6.17	228.78	94282
1769	87	2026-04-22	etanol	43.89	3.95	173.37	143994
1770	61	2026-04-23	diesel	56.01	6.18	346.14	110456
1771	66	2026-04-23	etanol	47.87	4.22	202.01	104044
1772	71	2026-04-23	diesel	55.47	6.16	341.70	131573
1773	56	2026-04-24	diesel	127.87	6.17	788.96	128624
1774	58	2026-04-24	diesel	73.35	6.25	458.44	76393
1775	77	2026-04-24	etanol	38.66	3.96	153.09	166912
1776	83	2026-04-24	gasolina	34.78	5.60	194.77	119956
1777	84	2026-04-25	etanol	32.54	4.60	149.68	48950
1778	89	2026-04-25	gasolina	57.03	5.88	335.34	35951
1779	64	2026-04-26	gasolina	40.21	5.64	226.78	123529
1780	65	2026-04-26	etanol	47.46	4.51	214.04	94802
1781	68	2026-04-26	etanol	35.95	4.61	165.73	90974
1782	69	2026-04-26	diesel	63.50	6.41	407.04	32517
1783	74	2026-04-26	gasolina	67.64	5.58	377.43	83371
1784	76	2026-04-26	diesel	61.64	6.20	382.17	113025
1785	90	2026-04-26	gasolina	42.44	5.99	254.22	152820
1786	70	2026-04-27	diesel	63.54	6.52	414.28	166397
1787	75	2026-04-27	diesel	49.51	6.02	298.05	156156
1788	59	2026-04-28	diesel	57.74	6.44	371.85	147605
1789	72	2026-04-28	diesel	57.90	6.51	376.93	47364
1790	73	2026-04-28	diesel	68.07	6.12	416.59	33420
1791	65	2026-05-08	gasolina	41.01	5.58	228.84	95753
1792	84	2026-05-08	etanol	45.64	4.36	198.99	49767
1793	56	2026-05-09	diesel	120.29	5.90	709.71	129314
1794	59	2026-05-09	diesel	46.25	6.42	296.93	148277
1795	61	2026-05-09	diesel	51.35	5.79	297.32	110934
1796	62	2026-05-09	diesel	51.90	5.96	309.32	56388
1797	72	2026-05-09	diesel	49.98	6.31	315.37	48538
1798	73	2026-05-09	diesel	62.78	6.08	381.70	34121
1799	85	2026-05-09	gasolina	37.75	5.99	226.12	28397
1800	51	2026-05-10	diesel	127.30	5.78	735.79	53856
1801	52	2026-05-10	diesel	96.54	6.25	603.38	140322
1802	58	2026-05-10	diesel	45.62	6.32	288.32	77550
1803	60	2026-05-10	diesel	63.06	6.04	380.88	70943
1804	71	2026-05-10	gasolina	50.01	6.00	300.06	133091
1805	89	2026-05-10	gasolina	47.18	5.74	270.81	37752
1806	90	2026-05-10	gasolina	47.92	5.71	273.62	153663
1807	53	2026-05-11	diesel	120.76	6.47	781.32	89574
1808	54	2026-05-11	diesel	115.71	6.26	724.34	85829
1809	55	2026-05-11	diesel	140.53	6.25	878.31	111024
1810	57	2026-05-11	diesel	45.26	6.51	294.64	143592
1811	63	2026-05-11	diesel	54.10	5.88	318.11	145227
1812	75	2026-05-11	diesel	53.93	5.77	311.18	157160
1813	64	2026-05-12	etanol	43.50	4.43	192.71	124287
1814	67	2026-05-12	etanol	31.38	4.44	139.33	127003
1815	69	2026-05-12	diesel	62.50	6.21	388.13	33654
1816	74	2026-05-12	diesel	67.06	6.00	402.36	83884
1817	76	2026-05-12	diesel	59.86	5.78	345.99	113876
1818	81	2026-05-12	etanol	38.32	4.50	172.44	95357
1819	82	2026-05-12	etanol	35.54	3.88	137.90	38406
1820	86	2026-05-12	etanol	34.85	4.64	161.70	63672
1821	66	2026-05-13	gasolina	43.37	6.19	268.46	105047
1822	80	2026-05-13	gasolina	43.73	5.63	246.20	116679
1823	88	2026-05-13	etanol	54.97	3.90	214.38	151738
1824	68	2026-05-14	etanol	40.91	3.94	161.19	91634
1825	70	2026-05-14	diesel	70.36	6.02	423.57	167115
1826	77	2026-05-14	gasolina	34.40	5.93	203.99	168209
1827	78	2026-05-14	gasolina	38.11	6.38	243.14	37566
1828	79	2026-05-14	gasolina	31.57	6.37	201.10	168906
1829	83	2026-05-14	etanol	43.92	4.57	200.71	120823
1830	87	2026-05-14	gasolina	48.66	6.37	309.96	144794
1831	74	2026-05-18	diesel	57.97	6.17	357.67	84489
1832	80	2026-05-18	gasolina	41.65	6.06	252.40	117269
1833	85	2026-05-18	gasolina	31.28	6.03	188.62	28879
1834	88	2026-05-18	etanol	47.64	3.95	188.18	152284
1835	51	2026-05-19	diesel	148.15	5.96	882.97	54249
1836	60	2026-05-19	diesel	71.27	5.83	415.50	71585
1837	63	2026-05-19	diesel	49.28	6.22	306.52	146020
1838	76	2026-05-19	diesel	63.67	5.97	380.11	114526
1839	84	2026-05-19	etanol	44.30	4.34	192.26	50580
1840	57	2026-05-20	diesel	56.36	5.75	324.07	144972
1841	64	2026-05-20	etanol	34.26	4.46	152.80	125024
1842	70	2026-05-20	diesel	62.43	6.22	388.31	168064
1843	75	2026-05-20	diesel	74.36	6.00	446.16	158028
1844	89	2026-05-20	gasolina	52.14	5.64	294.07	38109
1845	52	2026-05-21	diesel	119.10	6.48	771.77	140777
1846	53	2026-05-21	diesel	126.75	5.79	733.88	90489
1847	59	2026-05-21	diesel	71.24	6.39	455.22	149448
1848	61	2026-05-21	diesel	73.14	6.08	444.69	111505
1849	62	2026-05-21	diesel	45.58	5.84	266.19	57057
1850	67	2026-05-21	etanol	42.40	4.15	175.96	127958
1851	71	2026-05-21	gasolina	57.82	5.80	335.36	134119
1852	72	2026-05-21	diesel	68.31	5.76	393.47	49267
1853	77	2026-05-21	gasolina	30.84	5.67	174.86	168806
1854	81	2026-05-22	etanol	35.88	4.39	157.51	96038
1855	54	2026-05-23	diesel	99.17	5.99	594.03	86486
1856	55	2026-05-23	diesel	109.35	5.94	649.54	111700
1857	58	2026-05-23	diesel	51.10	6.36	325.00	78440
1858	66	2026-05-23	gasolina	45.83	5.79	265.36	105796
1859	82	2026-05-23	etanol	31.82	4.04	128.55	39313
1860	87	2026-05-23	gasolina	40.51	6.00	243.06	145926
1861	73	2026-05-24	diesel	48.79	6.44	314.21	35372
1862	79	2026-05-24	gasolina	44.87	5.60	251.27	169996
1863	69	2026-05-25	diesel	57.28	6.08	348.26	34884
1864	78	2026-05-25	gasolina	41.17	5.85	240.84	37950
1865	65	2026-05-26	gasolina	43.11	5.79	249.61	96377
1866	68	2026-05-27	etanol	33.15	4.25	140.89	92661
1867	83	2026-05-27	etanol	38.32	4.20	160.94	121904
1868	86	2026-05-27	etanol	35.67	4.12	146.96	64166
1869	90	2026-05-27	gasolina	52.68	6.14	323.46	154981
1870	56	2026-05-28	diesel	123.90	5.84	723.58	130566
1871	54	2026-06-08	diesel	139.67	6.47	903.66	87672
1872	68	2026-06-08	etanol	35.80	4.01	143.56	93338
1873	75	2026-06-08	diesel	71.22	6.35	452.25	158955
1874	83	2026-06-08	gasolina	45.79	5.68	260.09	122948
1875	62	2026-06-09	diesel	49.46	6.02	297.75	57819
1876	64	2026-06-09	etanol	43.92	4.52	198.52	126060
1877	79	2026-06-09	gasolina	35.45	6.28	222.63	170983
1878	81	2026-06-09	gasolina	36.21	5.89	213.28	96782
1879	51	2026-06-10	diesel	127.72	6.17	788.03	55104
1880	55	2026-06-10	diesel	98.57	5.93	584.52	112858
1881	58	2026-06-10	diesel	71.38	6.15	438.99	79448
1882	63	2026-06-10	diesel	50.51	6.13	309.63	147294
1883	66	2026-06-10	etanol	35.62	4.14	147.47	106688
1884	67	2026-06-10	etanol	31.20	4.29	133.85	128563
1885	70	2026-06-10	diesel	58.09	6.26	363.64	169245
1886	72	2026-06-10	gasolina	50.28	5.97	300.17	50378
1887	69	2026-06-11	gasolina	53.20	6.16	327.71	35854
1888	89	2026-06-11	etanol	47.27	3.96	187.19	39808
1889	52	2026-06-12	diesel	98.78	6.06	598.61	142010
1890	53	2026-06-12	diesel	111.30	5.84	649.99	91796
1891	77	2026-06-12	gasolina	35.91	6.19	222.28	169504
1892	82	2026-06-12	etanol	41.76	4.36	182.07	39764
1893	86	2026-06-12	gasolina	42.97	6.24	268.13	64854
1894	87	2026-06-12	gasolina	50.75	6.44	326.83	146548
1895	56	2026-06-13	diesel	128.19	5.78	740.94	131580
1896	57	2026-06-13	diesel	55.44	5.91	327.65	145555
1897	59	2026-06-13	diesel	49.62	6.48	321.54	150382
1898	61	2026-06-13	diesel	68.29	6.26	427.50	112298
1899	71	2026-06-13	diesel	70.82	6.43	455.37	134732
1900	73	2026-06-13	diesel	60.32	6.43	387.86	35978
1901	60	2026-06-14	diesel	57.38	6.40	367.23	72327
1902	65	2026-06-14	gasolina	47.09	5.57	262.29	97085
1903	74	2026-06-14	gasolina	55.72	5.90	328.75	85298
1904	76	2026-06-14	gasolina	55.82	5.70	318.17	115395
1905	78	2026-06-14	gasolina	39.55	5.85	231.37	38630
1906	80	2026-06-14	gasolina	35.33	5.95	210.21	117915
1907	84	2026-06-14	etanol	43.37	4.21	182.59	51286
1908	85	2026-06-14	gasolina	35.10	6.27	220.08	29616
1909	88	2026-06-14	gasolina	49.71	5.63	279.87	153300
1910	90	2026-06-14	gasolina	48.68	5.86	285.26	155820
1911	56	2026-06-18	diesel	108.40	6.30	682.92	132115
1912	75	2026-06-18	diesel	48.13	6.43	309.48	159909
1913	80	2026-06-18	gasolina	33.55	6.15	206.33	118932
1914	82	2026-06-18	etanol	44.52	4.21	187.43	40812
1915	88	2026-06-18	gasolina	45.28	6.07	274.85	154676
1916	72	2026-06-19	gasolina	61.31	6.42	393.61	51575
1917	89	2026-06-19	etanol	43.92	4.39	192.81	40839
1918	54	2026-06-20	diesel	121.84	6.03	734.70	88258
1919	58	2026-06-20	diesel	59.32	6.50	385.58	80005
1920	66	2026-06-20	etanol	45.20	4.39	198.43	107020
1921	74	2026-06-20	gasolina	57.26	5.76	329.82	85645
1922	53	2026-06-21	diesel	114.79	5.99	687.59	92299
1923	59	2026-06-21	diesel	49.56	6.39	316.69	151925
1924	61	2026-06-21	diesel	53.62	6.48	347.46	112730
1925	65	2026-06-21	gasolina	37.92	6.30	238.90	97775
1926	67	2026-06-21	etanol	32.24	3.91	126.06	128982
1927	78	2026-06-21	gasolina	41.32	6.24	257.84	39457
1928	84	2026-06-21	etanol	36.68	4.37	160.29	52391
1929	60	2026-06-22	diesel	49.98	5.89	294.38	73395
1930	81	2026-06-22	gasolina	41.37	5.56	230.02	97245
1931	87	2026-06-22	gasolina	52.74	6.02	317.49	147286
1932	90	2026-06-22	gasolina	43.29	6.40	277.06	156567
1933	57	2026-06-23	diesel	60.50	6.09	368.45	146459
1934	62	2026-06-23	diesel	53.75	6.35	341.31	58986
1935	64	2026-06-24	etanol	36.04	4.46	160.74	126479
1936	79	2026-06-24	gasolina	39.66	5.63	223.29	171690
1937	51	2026-06-25	diesel	120.01	5.89	706.86	55798
1938	55	2026-06-25	diesel	123.20	5.87	723.18	114386
1939	68	2026-06-26	etanol	41.13	4.57	187.96	93665
1940	69	2026-06-26	gasolina	51.56	5.78	298.02	36630
1941	70	2026-06-26	diesel	57.96	5.97	346.02	170050
1942	73	2026-06-26	diesel	53.85	5.83	313.95	37063
1943	83	2026-06-26	gasolina	42.03	5.74	241.25	123917
1944	86	2026-06-26	gasolina	31.94	5.68	181.42	66093
1945	52	2026-06-27	diesel	98.51	5.79	570.37	142902
1946	63	2026-06-27	diesel	59.59	6.51	387.93	148092
1947	77	2026-06-27	gasolina	37.20	5.60	208.32	170460
1948	85	2026-06-27	gasolina	41.24	6.43	265.17	30761
1949	71	2026-06-28	diesel	53.76	6.54	351.59	135904
1950	76	2026-06-28	gasolina	68.57	5.56	381.25	115886
1951	51	2026-07-08	diesel	149.67	5.78	865.09	56471
1952	76	2026-07-08	diesel	55.60	6.04	335.82	116707
1953	63	2026-07-09	diesel	59.15	6.16	364.36	149063
1954	73	2026-07-09	gasolina	72.76	6.18	449.66	37717
1955	77	2026-07-09	gasolina	40.52	5.70	230.96	171247
1956	82	2026-07-09	etanol	38.40	3.99	153.22	41847
1957	86	2026-07-09	gasolina	35.10	6.02	211.30	67179
1958	89	2026-07-09	etanol	44.17	4.45	196.56	41857
1959	53	2026-07-10	diesel	127.44	6.13	781.21	93187
1960	55	2026-07-10	diesel	115.10	5.95	684.85	114951
1961	56	2026-07-10	diesel	113.85	5.83	663.75	133056
1962	61	2026-07-10	diesel	57.94	5.84	338.37	114076
1963	62	2026-07-10	diesel	46.65	5.82	271.50	59505
1964	79	2026-07-10	gasolina	42.63	6.21	264.73	172791
1965	52	2026-07-11	diesel	116.98	6.32	739.31	144240
1966	59	2026-07-11	diesel	74.23	6.01	446.12	152353
1967	64	2026-07-11	gasolina	47.78	5.76	275.21	127153
1968	70	2026-07-11	diesel	55.32	6.14	339.66	170669
1969	72	2026-07-11	diesel	72.77	6.47	470.82	52613
1970	74	2026-07-11	diesel	73.39	5.96	437.40	87014
1971	78	2026-07-11	etanol	32.67	3.91	127.74	40310
1972	87	2026-07-11	etanol	53.03	4.43	234.92	148022
1973	66	2026-07-12	gasolina	39.54	5.98	236.45	108313
1974	68	2026-07-12	etanol	42.31	4.21	178.13	94616
1975	71	2026-07-12	gasolina	69.26	5.88	407.25	137286
1976	85	2026-07-12	etanol	45.18	4.10	185.24	31724
1977	90	2026-07-12	gasolina	52.58	5.75	302.34	158251
1978	54	2026-07-13	diesel	90.69	6.51	590.39	89113
1979	57	2026-07-13	diesel	70.96	6.53	463.37	147522
1980	60	2026-07-13	diesel	65.76	6.37	418.89	74230
1981	67	2026-07-13	etanol	43.08	4.15	178.78	130416
1982	69	2026-07-13	diesel	52.71	5.75	303.08	37722
1983	84	2026-07-13	gasolina	39.92	6.17	246.31	53440
1984	58	2026-07-14	diesel	49.10	5.99	294.11	80429
1985	65	2026-07-14	gasolina	33.28	5.83	194.02	98731
1986	75	2026-07-14	gasolina	52.42	6.21	325.53	160834
1987	80	2026-07-14	gasolina	31.69	6.14	194.58	120403
1988	81	2026-07-14	gasolina	39.46	6.25	246.63	98187
1989	83	2026-07-14	gasolina	43.18	5.55	239.65	124625
1990	88	2026-07-14	gasolina	46.26	6.22	287.74	155769
1991	56	2026-07-18	diesel	101.80	6.15	626.07	133689
1992	58	2026-07-18	diesel	59.57	6.46	384.82	80905
1993	86	2026-07-18	gasolina	44.31	6.11	270.73	67984
1994	52	2026-07-19	diesel	149.85	6.50	974.03	144897
1995	62	2026-07-19	diesel	46.90	5.79	271.55	60421
1996	70	2026-07-19	diesel	73.58	6.13	451.05	171082
1997	73	2026-07-19	gasolina	57.34	5.65	323.97	38447
1998	74	2026-07-19	diesel	55.86	5.91	330.13	88269
1999	81	2026-07-19	gasolina	36.05	5.91	213.06	98871
2000	64	2026-07-20	gasolina	33.57	5.78	194.03	128072
2001	79	2026-07-20	gasolina	32.79	5.76	188.87	173662
2002	53	2026-07-21	diesel	132.45	6.11	809.27	93990
2003	63	2026-07-21	diesel	47.20	6.31	297.83	150049
2004	71	2026-07-21	gasolina	48.24	6.25	301.50	138251
2005	83	2026-07-21	gasolina	33.10	6.05	200.26	125556
2006	54	2026-07-22	diesel	126.49	6.21	785.50	89831
2007	59	2026-07-22	diesel	51.70	6.19	320.02	152786
2008	67	2026-07-22	etanol	33.35	4.00	133.40	131298
2009	68	2026-07-22	etanol	34.72	4.20	145.82	95577
2010	60	2026-07-23	diesel	57.00	6.15	350.55	75081
2011	75	2026-07-23	gasolina	64.82	6.38	413.55	161705
2012	76	2026-07-23	diesel	50.73	6.21	315.03	117409
2013	90	2026-07-23	gasolina	44.80	6.05	271.04	158788
2014	82	2026-07-24	etanol	38.46	4.03	154.99	42327
2015	84	2026-07-24	gasolina	31.00	5.70	176.70	54120
2016	85	2026-07-24	etanol	41.39	4.23	175.08	32223
2017	89	2026-07-24	etanol	48.99	4.55	222.90	42915
2018	77	2026-07-25	gasolina	30.93	6.09	188.36	171746
2019	88	2026-07-25	gasolina	57.90	6.38	369.40	156383
2020	51	2026-07-26	diesel	123.06	5.90	726.05	57415
2021	66	2026-07-26	gasolina	32.79	6.20	203.30	108710
2022	72	2026-07-26	diesel	52.24	5.92	309.26	53301
2023	78	2026-07-26	etanol	41.29	3.92	161.86	40790
2024	87	2026-07-26	etanol	55.52	4.24	235.40	148473
2025	55	2026-07-27	diesel	140.37	6.02	845.03	115908
2026	57	2026-07-27	diesel	47.44	6.40	303.62	148075
2027	61	2026-07-27	diesel	58.14	6.30	366.28	114471
2028	65	2026-07-27	gasolina	30.47	5.85	178.25	99210
2029	69	2026-07-27	diesel	70.85	6.01	425.81	38159
2030	80	2026-07-28	gasolina	42.11	5.61	236.24	121434
2031	65	2026-08-08	gasolina	41.23	5.66	233.36	100428
2032	74	2026-08-08	gasolina	49.87	6.17	307.70	89544
2033	87	2026-08-08	gasolina	43.63	6.08	265.27	149266
2034	88	2026-08-08	etanol	55.39	4.36	241.50	157611
2035	52	2026-08-09	diesel	129.15	6.17	796.86	145839
2036	53	2026-08-09	diesel	142.28	6.38	907.75	95179
2037	54	2026-08-09	diesel	136.58	6.03	823.58	90251
2038	62	2026-08-09	diesel	68.75	6.33	435.19	61070
2039	69	2026-08-09	gasolina	54.52	5.65	308.04	39369
2040	72	2026-08-09	diesel	57.02	5.77	329.01	54432
2041	83	2026-08-09	etanol	31.91	4.06	129.55	126661
2042	89	2026-08-09	gasolina	48.66	6.24	303.64	43744
2043	56	2026-08-10	diesel	142.27	6.47	920.49	134450
2044	57	2026-08-10	diesel	63.27	5.99	378.99	148718
2045	64	2026-08-10	gasolina	41.68	5.93	247.16	128634
2046	77	2026-08-10	etanol	30.47	3.88	118.22	173056
2047	81	2026-08-10	etanol	44.23	4.09	180.90	100318
2048	82	2026-08-10	etanol	30.05	4.45	133.72	43132
2049	86	2026-08-10	etanol	44.92	3.89	174.74	68757
2050	51	2026-08-11	diesel	96.38	6.41	617.80	58401
2051	55	2026-08-11	diesel	96.55	6.11	589.92	117185
2052	59	2026-08-11	diesel	49.47	5.90	291.87	153505
2053	63	2026-08-11	diesel	48.01	6.34	304.38	150764
2054	78	2026-08-11	etanol	35.49	3.88	137.70	41568
2055	84	2026-08-11	etanol	39.20	4.12	161.50	54915
2056	90	2026-08-11	gasolina	56.42	6.28	354.32	159930
2057	68	2026-08-12	gasolina	33.46	5.67	189.72	96180
2058	70	2026-08-12	gasolina	69.14	6.19	427.98	171862
2059	71	2026-08-12	diesel	50.01	5.81	290.56	139156
2060	76	2026-08-12	gasolina	57.59	5.95	342.66	118513
2061	58	2026-08-13	diesel	63.31	6.52	412.78	81589
2062	61	2026-08-13	diesel	53.53	6.06	324.39	115124
2063	67	2026-08-13	etanol	46.22	4.46	206.14	131959
2064	75	2026-08-13	diesel	70.59	6.29	444.01	162889
2065	60	2026-08-14	diesel	50.57	6.45	326.18	76420
2066	66	2026-08-14	etanol	35.19	3.92	137.94	109635
2067	73	2026-08-14	gasolina	72.03	6.15	442.98	39373
2068	79	2026-08-14	gasolina	31.38	6.37	199.89	174279
2069	80	2026-08-14	etanol	39.49	4.53	178.89	122091
2070	85	2026-08-14	etanol	32.44	4.03	130.73	33455
2071	58	2026-08-18	diesel	71.49	5.92	423.22	82558
2072	61	2026-08-18	diesel	47.75	6.44	307.51	116111
2073	66	2026-08-18	etanol	47.08	4.03	189.73	110375
2074	88	2026-08-18	etanol	55.51	4.03	223.71	158667
2075	69	2026-08-19	gasolina	65.26	5.76	375.90	39751
2076	70	2026-08-19	gasolina	68.68	5.64	387.36	172425
2077	76	2026-08-19	gasolina	60.95	5.61	341.93	119003
2078	55	2026-08-20	diesel	148.72	5.80	862.58	118225
2079	56	2026-08-20	diesel	124.47	6.08	756.78	134972
2080	74	2026-08-20	gasolina	52.70	5.99	315.67	90008
2081	75	2026-08-20	diesel	64.20	6.19	397.40	163230
2082	89	2026-08-20	gasolina	57.09	6.30	359.67	44725
2083	82	2026-08-21	etanol	45.08	4.41	198.80	43603
2084	84	2026-08-21	etanol	37.45	4.18	156.54	55807
2085	86	2026-08-21	etanol	37.28	3.92	146.14	69188
2086	52	2026-08-22	diesel	129.87	6.05	785.71	146496
2087	53	2026-08-22	diesel	148.03	5.79	857.09	95982
2088	65	2026-08-22	gasolina	42.09	5.82	244.96	101824
2089	83	2026-08-22	etanol	37.98	4.25	161.42	126867
2090	87	2026-08-22	gasolina	40.13	5.76	231.15	150266
2091	57	2026-08-23	diesel	59.42	6.27	372.56	149106
2092	68	2026-08-23	gasolina	33.12	6.29	208.32	97047
2093	71	2026-08-23	diesel	61.51	6.55	402.89	139306
2094	72	2026-08-23	diesel	63.48	6.41	406.91	54909
2095	79	2026-08-23	gasolina	32.61	6.41	209.03	175480
2096	80	2026-08-23	etanol	33.78	3.92	132.42	122253
2097	54	2026-08-24	diesel	137.50	5.88	808.50	91097
2098	59	2026-08-24	diesel	48.43	6.41	310.44	153948
2099	63	2026-08-24	diesel	64.36	6.12	393.88	152174
2100	77	2026-08-24	etanol	32.61	4.46	145.44	173688
2101	78	2026-08-24	etanol	34.22	3.88	132.77	42755
2102	51	2026-08-25	diesel	122.75	6.46	792.97	59671
2103	62	2026-08-25	diesel	49.23	6.23	306.70	62524
2104	90	2026-08-25	gasolina	47.92	5.89	282.25	160558
2105	60	2026-08-26	diesel	57.41	6.49	372.59	77217
2106	64	2026-08-26	gasolina	44.02	5.95	261.92	129462
2107	73	2026-08-27	gasolina	63.72	6.09	388.05	40044
2108	85	2026-08-27	etanol	40.74	4.40	179.26	33752
2109	67	2026-08-28	etanol	44.61	4.46	198.96	132678
2110	81	2026-08-28	etanol	36.11	4.42	159.61	100950
2111	77	2026-09-08	gasolina	43.97	5.69	250.19	174699
2112	82	2026-09-08	etanol	41.26	4.19	172.88	44407
2113	87	2026-09-08	gasolina	57.62	6.04	348.02	150862
2114	89	2026-09-08	gasolina	46.68	6.01	280.55	45452
2115	56	2026-09-09	diesel	121.11	6.16	746.04	135846
2116	59	2026-09-09	diesel	74.88	6.50	486.72	155095
2117	60	2026-09-09	diesel	55.16	5.80	319.93	78355
2118	84	2026-09-09	gasolina	42.97	5.70	244.93	56567
2119	51	2026-09-10	diesel	131.26	6.54	858.44	60242
2120	52	2026-09-10	diesel	116.55	5.84	680.65	147302
2121	53	2026-09-10	diesel	125.68	6.21	780.47	96893
2122	57	2026-09-10	diesel	60.91	6.26	381.30	150031
2123	58	2026-09-10	diesel	46.39	6.37	295.50	83052
2124	64	2026-09-10	gasolina	37.78	6.39	241.41	130073
2125	67	2026-09-10	etanol	42.10	4.28	180.19	133864
2126	74	2026-09-10	diesel	66.58	6.16	410.13	91332
2127	81	2026-09-10	gasolina	34.47	6.15	211.99	102127
2128	68	2026-09-11	etanol	32.79	4.14	135.75	97836
2129	69	2026-09-11	diesel	63.79	5.84	372.53	40755
2130	70	2026-09-11	diesel	50.12	6.45	323.27	173217
2131	76	2026-09-11	gasolina	68.33	6.21	424.33	119926
2132	83	2026-09-11	etanol	39.31	4.64	182.40	127702
2133	54	2026-09-12	diesel	148.63	5.82	865.03	92228
2134	61	2026-09-12	diesel	73.93	6.26	462.80	116993
2135	63	2026-09-12	diesel	45.19	6.43	290.57	153365
2136	72	2026-09-12	gasolina	57.51	6.44	370.36	56136
2137	73	2026-09-12	diesel	63.44	5.86	371.76	41163
2138	80	2026-09-12	etanol	34.68	4.30	149.12	123553
2139	85	2026-09-12	gasolina	38.29	5.86	224.38	35240
2140	86	2026-09-12	gasolina	31.94	5.65	180.46	70112
2141	55	2026-09-13	diesel	145.51	6.20	902.16	119026
2142	71	2026-09-13	diesel	53.61	6.00	321.66	140101
2143	79	2026-09-13	gasolina	39.70	6.06	240.58	176629
2144	88	2026-09-13	gasolina	49.02	6.07	297.55	159322
2145	62	2026-09-14	diesel	46.54	5.87	273.19	63328
2146	65	2026-09-14	gasolina	33.69	6.42	216.29	102943
2147	66	2026-09-14	etanol	41.36	4.48	185.29	111030
2148	75	2026-09-14	gasolina	71.08	5.58	396.63	164522
2149	78	2026-09-14	gasolina	43.74	6.34	277.31	43757
2150	90	2026-09-14	etanol	44.43	4.58	203.49	161286
2151	78	2026-09-18	gasolina	32.87	5.76	189.33	44412
2152	88	2026-09-18	gasolina	42.61	6.04	257.36	159750
2153	52	2026-09-19	diesel	111.09	6.51	723.20	148192
2154	55	2026-09-19	diesel	105.47	5.91	623.33	119424
2155	56	2026-09-19	diesel	100.23	6.17	618.42	136790
2156	67	2026-09-19	etanol	39.99	4.16	166.36	134436
2157	79	2026-09-19	gasolina	45.14	5.64	254.59	177112
2158	82	2026-09-19	etanol	39.54	3.97	156.97	45183
2159	70	2026-09-20	diesel	72.63	5.85	424.89	174042
2160	75	2026-09-20	gasolina	58.25	5.78	336.69	164902
2161	77	2026-09-20	gasolina	43.51	5.97	259.75	175479
2162	85	2026-09-20	gasolina	45.73	6.22	284.44	36561
2163	57	2026-09-21	diesel	65.36	6.11	399.35	150273
2164	66	2026-09-21	etanol	37.26	4.04	150.53	112036
2165	59	2026-09-22	diesel	59.70	5.76	343.87	156268
2166	65	2026-09-22	gasolina	39.96	5.55	221.78	103490
2167	73	2026-09-22	diesel	67.04	6.33	424.36	41895
2168	80	2026-09-22	etanol	43.08	4.36	187.83	124121
2169	63	2026-09-23	diesel	60.27	6.32	380.91	154345
2170	84	2026-09-23	gasolina	38.39	5.91	226.88	56990
2171	87	2026-09-23	gasolina	41.75	6.29	262.61	151518
2172	89	2026-09-23	gasolina	57.79	6.02	347.90	46419
2173	58	2026-09-24	diesel	70.92	6.55	464.53	83479
2174	62	2026-09-24	diesel	53.85	5.76	310.18	63842
2175	72	2026-09-24	gasolina	64.00	6.41	410.24	56529
2176	69	2026-09-25	diesel	73.23	6.39	467.94	41806
2177	86	2026-09-25	gasolina	43.07	5.92	254.97	70765
2178	90	2026-09-25	etanol	52.74	4.18	220.45	161822
2179	53	2026-09-26	diesel	134.01	5.95	797.36	98074
2180	54	2026-09-26	diesel	137.28	6.42	881.34	92693
2181	60	2026-09-26	diesel	45.09	6.21	280.01	78877
2182	64	2026-09-26	gasolina	37.72	5.70	215.00	130882
2183	71	2026-09-26	diesel	52.25	6.36	332.31	140744
2184	74	2026-09-27	diesel	66.08	6.08	401.77	91979
2185	81	2026-09-27	gasolina	32.46	5.78	187.62	102460
2186	51	2026-09-28	diesel	98.38	6.54	643.41	61228
2187	61	2026-09-28	diesel	47.08	5.80	273.06	117547
2188	68	2026-09-28	etanol	34.51	4.63	159.78	98504
2189	76	2026-09-28	gasolina	51.45	6.19	318.48	120897
2190	83	2026-09-28	etanol	45.11	4.38	197.58	128565
2191	53	2026-10-08	diesel	93.69	5.77	540.59	98625
2192	58	2026-10-08	diesel	69.15	5.87	405.91	84624
2193	59	2026-10-08	diesel	51.02	5.97	304.59	157132
2194	61	2026-10-08	diesel	46.92	5.80	272.14	118195
2195	62	2026-10-08	diesel	69.06	5.83	402.62	64757
2196	67	2026-10-08	etanol	30.17	4.40	132.75	135134
2197	80	2026-10-08	gasolina	33.16	5.61	186.03	125336
2198	81	2026-10-08	gasolina	36.18	6.20	224.32	103948
2199	86	2026-10-08	etanol	39.16	4.52	177.00	71421
2200	65	2026-10-09	etanol	35.54	4.61	163.84	104986
2201	78	2026-10-09	gasolina	35.67	5.69	202.96	45218
2202	82	2026-10-09	etanol	31.92	4.26	135.98	46281
2203	84	2026-10-09	gasolina	36.47	5.58	203.50	58192
2204	85	2026-10-09	etanol	40.07	4.40	176.31	37477
2205	88	2026-10-09	gasolina	49.17	6.04	296.99	160470
2206	55	2026-10-10	diesel	149.89	6.49	972.79	120104
2207	69	2026-10-10	diesel	58.27	6.11	356.03	43066
2208	71	2026-10-10	diesel	67.35	6.19	416.90	141563
2209	72	2026-10-10	diesel	70.02	6.41	448.83	57476
2210	90	2026-10-10	gasolina	53.45	6.33	338.34	162565
2211	60	2026-10-11	diesel	57.11	6.21	354.65	79667
2212	63	2026-10-11	diesel	63.59	5.88	373.91	155564
2213	68	2026-10-11	gasolina	47.66	6.29	299.78	99131
2214	73	2026-10-11	gasolina	74.99	5.82	436.44	42703
2215	79	2026-10-11	gasolina	40.87	6.12	250.12	178146
2216	56	2026-10-12	diesel	115.84	6.39	740.22	137503
2217	75	2026-10-12	diesel	51.80	6.49	336.18	165725
2218	54	2026-10-13	diesel	102.79	5.81	597.21	94055
2219	57	2026-10-13	diesel	62.37	6.19	386.07	151584
2220	66	2026-10-13	etanol	37.55	4.38	164.47	112735
2221	77	2026-10-13	gasolina	41.24	6.30	259.81	176875
2222	83	2026-10-13	gasolina	40.15	5.74	230.46	129368
2223	87	2026-10-13	etanol	57.18	4.11	235.01	152669
2224	51	2026-10-14	diesel	97.79	5.81	568.16	62189
2225	52	2026-10-14	diesel	102.44	6.04	618.74	149838
2226	64	2026-10-14	gasolina	43.23	6.22	268.89	132306
2227	70	2026-10-14	diesel	53.44	6.15	328.66	174984
2228	74	2026-10-14	diesel	56.38	6.06	341.66	92650
2229	76	2026-10-14	diesel	56.79	5.78	328.25	121978
2230	89	2026-10-14	gasolina	43.37	6.29	272.80	47228
2231	63	2026-10-18	diesel	73.48	5.87	431.33	156311
2232	64	2026-10-18	gasolina	35.13	5.59	196.38	132564
2233	74	2026-10-18	diesel	54.21	6.27	339.90	92892
2234	73	2026-10-19	gasolina	56.06	5.60	313.94	43613
2235	90	2026-10-19	gasolina	47.55	5.65	268.66	164095
2236	53	2026-10-20	diesel	93.50	6.37	595.60	99164
2237	58	2026-10-20	diesel	72.35	5.87	424.69	85327
2238	79	2026-10-20	gasolina	44.68	6.20	277.02	178688
2239	86	2026-10-20	etanol	32.45	4.11	133.37	71665
2240	62	2026-10-21	diesel	68.82	6.11	420.49	65204
2241	70	2026-10-21	diesel	60.97	6.12	373.14	175593
2242	80	2026-10-21	gasolina	40.42	6.00	242.52	126588
2243	88	2026-10-21	gasolina	53.92	6.24	336.46	161731
2244	51	2026-10-22	diesel	115.84	5.79	670.71	63110
2245	55	2026-10-22	diesel	114.94	5.88	675.85	121123
2246	85	2026-10-22	etanol	43.13	4.12	177.70	38256
2247	57	2026-10-23	diesel	60.90	6.20	377.58	152030
2248	61	2026-10-23	diesel	47.23	6.20	292.83	119178
2249	68	2026-10-23	gasolina	47.97	6.29	301.73	100286
2250	75	2026-10-23	diesel	65.76	5.93	389.96	166089
2251	89	2026-10-23	gasolina	46.51	5.85	272.08	47523
2252	52	2026-10-24	diesel	95.27	6.31	601.15	150325
2253	77	2026-10-24	gasolina	35.32	5.70	201.32	178069
2254	82	2026-10-24	etanol	44.84	4.35	195.05	47277
2255	83	2026-10-24	gasolina	40.07	6.07	243.22	129953
2256	65	2026-10-25	etanol	41.02	4.54	186.23	105420
2257	66	2026-10-25	etanol	35.16	4.63	162.79	113787
2258	84	2026-10-25	gasolina	37.77	5.97	225.49	59121
2259	72	2026-10-26	diesel	55.21	5.82	321.32	58148
2260	59	2026-10-27	diesel	61.22	5.82	356.30	157949
2261	81	2026-10-27	gasolina	39.11	6.44	251.87	104667
2262	54	2026-10-28	diesel	142.96	6.19	884.92	94354
2263	56	2026-10-28	diesel	136.23	6.01	818.74	138197
2264	60	2026-10-28	diesel	68.65	6.42	440.73	80190
2265	67	2026-10-28	etanol	42.94	4.09	175.62	135686
2266	69	2026-10-28	diesel	64.93	6.11	396.72	44221
2267	71	2026-10-28	diesel	69.34	6.20	429.91	142386
2268	76	2026-10-28	diesel	62.92	6.06	381.30	122544
2269	78	2026-10-28	gasolina	34.78	5.97	207.64	46610
2270	87	2026-10-28	etanol	46.03	4.38	201.61	153510
2273	3	2026-11-06	Etanol	69.19	6.27	433.82	81494
2274	4	2026-11-07	Diesel S500	78.53	5.38	422.49	83211
2275	5	2026-11-08	Diesel S10	50.32	5.29	266.19	84928
2276	6	2026-11-09	Gasolina	38.12	6.01	229.10	99145
2277	7	2026-11-10	Etanol	26.59	5.55	147.57	88362
2278	8	2026-11-11	Diesel S500	63.99	6.07	388.42	90079
2279	9	2026-11-12	Diesel S10	38.23	6.13	234.35	126896
2280	10	2026-11-13	Gasolina	73.57	5.26	386.98	154813
2281	11	2026-11-14	Etanol	73.35	6.30	462.11	94750
2282	12	2026-11-15	Diesel S500	45.42	5.48	248.90	96457
2283	13	2026-11-16	Diesel S10	82.43	5.75	473.97	98164
2284	14	2026-11-17	Gasolina	30.56	5.40	165.02	99871
2285	15	2026-11-18	Etanol	75.85	6.16	467.24	101578
2286	16	2026-11-19	Diesel S500	73.43	6.34	465.55	103285
2287	17	2026-11-20	Diesel S10	57.17	6.71	383.61	104992
2288	18	2026-11-21	Gasolina	47.71	6.08	290.08	106699
2289	19	2026-11-22	Etanol	74.76	6.18	462.02	108406
2290	20	2026-11-23	Diesel S500	76.70	6.12	469.40	110113
2291	21	2026-11-24	Diesel S10	67.27	5.32	357.88	110020
2292	22	2026-11-25	Gasolina	38.67	5.68	219.65	111727
2293	23	2026-11-26	Etanol	29.79	5.60	166.82	113434
2294	24	2026-11-27	Diesel S500	31.06	5.67	176.11	115141
2295	25	2026-11-28	Diesel S10	63.14	5.80	366.21	116848
2296	26	2026-11-29	Gasolina	47.21	5.56	262.49	118555
2297	27	2026-11-30	Etanol	41.02	6.65	272.78	120262
2298	28	2026-12-01	Diesel S500	63.88	6.16	393.50	121969
2299	29	2026-12-02	Diesel S10	35.27	6.34	223.61	123676
2300	30	2026-12-03	Gasolina	34.80	5.82	202.54	125383
2301	1	2026-12-04	Etanol	84.37	6.21	523.94	78420
2302	2	2026-12-05	Diesel S500	58.42	6.28	366.88	80144
2303	3	2026-12-06	Diesel S10	75.57	6.41	484.40	81868
2304	4	2026-12-07	Gasolina	38.74	5.30	205.32	83592
2305	5	2026-12-08	Etanol	43.93	5.65	248.20	85316
2306	6	2026-12-09	Diesel S500	37.66	6.66	250.82	99540
2307	7	2026-12-10	Diesel S10	77.58	5.72	443.76	88764
2308	8	2026-12-11	Gasolina	64.33	5.84	375.69	90488
2309	9	2026-12-12	Etanol	79.87	5.94	474.43	127312
2310	10	2026-12-13	Diesel S500	40.89	5.62	229.80	155236
2311	11	2026-12-14	Diesel S10	58.68	5.64	330.96	95180
2312	12	2026-12-15	Gasolina	60.08	6.60	396.53	96894
2313	13	2026-12-16	Etanol	48.96	5.58	273.20	98608
2314	14	2026-12-17	Diesel S500	84.85	6.01	509.95	100322
2315	15	2026-12-18	Diesel S10	30.45	5.32	161.99	102036
2316	16	2026-12-19	Gasolina	31.58	6.19	195.48	103750
2317	17	2026-12-20	Etanol	72.52	5.88	426.42	105464
2318	18	2026-12-21	Diesel S500	28.81	5.82	167.67	107178
2319	19	2026-12-22	Diesel S10	84.77	6.04	512.01	108892
2320	20	2026-12-23	Gasolina	83.26	6.54	544.52	110606
2321	21	2026-12-24	Etanol	25.69	6.33	162.62	110520
2322	22	2026-12-25	Diesel S500	65.90	6.06	399.35	112234
2323	23	2026-12-26	Diesel S10	41.01	6.21	254.67	113948
2324	24	2026-12-27	Gasolina	31.69	5.90	186.97	115662
2325	25	2026-12-28	Etanol	52.22	6.68	348.83	117376
2326	26	2026-12-29	Diesel S500	77.55	5.65	438.16	119090
2327	27	2026-12-30	Diesel S10	55.04	5.52	303.82	120804
2328	28	2026-12-31	Gasolina	79.76	6.56	523.23	122518
2329	29	2027-01-01	Etanol	42.91	6.21	266.47	124232
2330	30	2027-01-02	Diesel S500	61.54	5.48	337.24	125946
2331	1	2027-01-03	Diesel S10	70.75	6.06	428.75	78960
2332	2	2027-01-04	Gasolina	71.72	6.05	433.91	80691
2333	3	2027-01-05	Etanol	25.03	5.74	143.67	82422
2334	4	2027-01-06	Diesel S500	26.17	6.64	173.77	84153
2335	5	2027-01-07	Diesel S10	77.72	6.50	505.18	85884
2336	6	2027-01-08	Gasolina	43.45	5.34	232.02	100115
2337	7	2027-01-09	Etanol	77.68	6.67	518.13	89346
2338	8	2027-01-10	Diesel S500	30.14	5.98	180.24	91077
2339	9	2027-01-11	Diesel S10	29.15	6.39	186.27	127908
2340	10	2027-01-12	Gasolina	70.95	5.44	385.97	155839
2341	11	2027-01-13	Etanol	53.52	6.07	324.87	95790
2342	12	2027-01-14	Diesel S500	40.90	6.56	268.30	97511
2343	13	2027-01-15	Diesel S10	50.39	5.57	280.67	99232
2344	14	2027-01-16	Gasolina	57.36	6.34	363.66	100953
2345	15	2027-01-17	Etanol	37.07	5.72	212.04	102674
2346	16	2027-01-18	Diesel S500	84.71	6.22	526.90	104395
2347	17	2027-01-19	Diesel S10	51.29	6.03	309.28	106116
2348	18	2027-01-20	Gasolina	32.26	5.59	180.33	107837
2349	19	2027-01-21	Etanol	45.29	6.13	277.63	109558
2350	20	2027-01-22	Diesel S500	38.81	5.58	216.56	111279
2351	21	2027-01-23	Diesel S10	29.26	6.20	181.41	111200
2352	22	2027-01-24	Gasolina	38.74	6.61	256.07	112921
2353	23	2027-01-25	Etanol	76.58	5.36	410.47	114642
2354	24	2027-01-26	Diesel S500	39.28	6.25	245.50	116363
2355	25	2027-01-27	Diesel S10	37.85	5.45	206.28	118084
2356	26	2027-01-28	Gasolina	81.13	6.11	495.70	119805
2357	27	2027-01-29	Etanol	53.36	6.43	343.10	121526
2358	28	2027-01-30	Diesel S500	73.45	5.54	406.91	123247
2359	29	2027-01-31	Diesel S10	30.82	5.90	181.84	124968
2360	30	2027-02-01	Gasolina	50.41	5.95	299.94	126689
2361	1	2027-02-02	Etanol	68.74	6.26	430.31	79680
2362	2	2027-02-03	Diesel S500	84.05	5.40	453.87	81418
2363	3	2027-02-04	Diesel S10	49.16	5.76	283.16	83156
2364	4	2027-02-05	Gasolina	76.70	5.62	431.05	84894
2365	5	2027-02-06	Etanol	36.41	5.92	215.55	86632
2366	6	2027-02-07	Diesel S500	50.31	5.67	285.26	100870
2367	7	2027-02-08	Diesel S10	39.99	6.63	265.13	90108
2368	8	2027-02-09	Gasolina	51.59	6.54	337.40	91846
2369	9	2027-02-10	Etanol	58.02	5.33	309.25	128684
2370	10	2027-02-11	Diesel S500	84.96	6.50	552.24	156622
2371	11	2027-02-12	Diesel S10	83.14	6.64	552.05	96580
2372	12	2027-02-13	Gasolina	75.92	5.50	417.56	98308
2373	13	2027-02-14	Etanol	54.14	5.57	301.56	100036
2374	14	2027-02-15	Diesel S500	49.06	5.34	261.98	101764
2375	15	2027-02-16	Diesel S10	47.74	6.73	321.29	103492
2376	16	2027-02-17	Gasolina	40.91	6.43	263.05	105220
2377	17	2027-02-18	Etanol	52.30	5.88	307.52	106948
2378	18	2027-02-19	Diesel S500	82.44	6.74	555.65	108676
2379	19	2027-02-20	Diesel S10	58.35	6.33	369.36	110404
2380	20	2027-02-21	Gasolina	34.29	5.70	195.45	112132
2381	21	2027-02-22	Etanol	83.12	6.12	508.69	112060
2382	22	2027-02-23	Diesel S500	57.53	6.37	366.47	113788
2383	23	2027-02-24	Diesel S10	28.43	6.13	174.28	115516
2384	24	2027-02-25	Gasolina	55.17	6.53	360.26	117244
2385	25	2027-02-26	Etanol	34.45	6.69	230.47	118972
2386	26	2027-02-27	Diesel S500	29.81	5.53	164.85	120700
2387	27	2027-02-28	Diesel S10	60.70	6.26	379.98	122428
2388	28	2027-03-01	Gasolina	39.11	5.43	212.37	124156
2389	29	2027-03-02	Etanol	78.42	5.62	440.72	125884
2390	30	2027-03-03	Diesel S500	60.67	6.18	374.94	127612
2391	1	2027-03-04	Diesel S10	50.15	6.13	307.42	80580
2392	2	2027-03-05	Gasolina	56.37	6.65	374.86	82325
2393	3	2027-03-06	Etanol	37.26	6.32	235.48	84070
2394	4	2027-03-07	Diesel S500	39.32	5.84	229.63	85815
2395	5	2027-03-08	Diesel S10	65.30	5.70	372.21	87560
2396	6	2027-03-09	Gasolina	43.97	6.38	280.53	101805
2397	7	2027-03-10	Etanol	29.35	5.94	174.34	91050
2398	8	2027-03-11	Diesel S500	84.91	6.74	572.29	92795
2399	9	2027-03-12	Diesel S10	29.40	5.57	163.76	129640
2400	10	2027-03-13	Gasolina	40.91	6.65	272.05	157585
2401	11	2027-03-14	Etanol	77.85	6.57	511.47	97550
2402	12	2027-03-15	Diesel S500	47.17	5.49	258.96	99285
2403	13	2027-03-16	Diesel S10	75.02	6.31	473.38	101020
2404	14	2027-03-17	Gasolina	61.70	6.73	415.24	102755
2405	15	2027-03-18	Etanol	64.24	5.26	337.90	104490
2406	16	2027-03-19	Diesel S500	74.03	5.70	421.97	106225
2407	17	2027-03-20	Diesel S10	64.80	6.66	431.57	107960
2408	18	2027-03-21	Gasolina	33.06	5.42	179.19	109695
2409	19	2027-03-22	Etanol	31.42	6.08	191.03	111430
2410	20	2027-03-23	Diesel S500	41.34	6.16	254.65	113165
2411	21	2027-03-24	Diesel S10	68.06	5.56	378.41	113100
2412	22	2027-03-25	Gasolina	63.05	5.65	356.23	114835
2413	23	2027-03-26	Etanol	54.31	6.61	358.99	116570
2414	24	2027-03-27	Diesel S500	75.77	5.39	408.40	118305
2415	25	2027-03-28	Diesel S10	50.41	5.67	285.82	120040
2416	26	2027-03-29	Gasolina	25.21	6.41	161.60	121775
2417	27	2027-03-30	Etanol	63.23	5.64	356.62	123510
2418	28	2027-03-31	Diesel S500	69.47	6.08	422.38	125245
2419	29	2027-04-01	Diesel S10	50.66	5.26	266.47	126980
2420	30	2027-04-02	Gasolina	29.51	6.57	193.88	128715
2421	1	2027-04-03	Etanol	79.24	6.07	480.99	81660
2422	2	2027-04-04	Diesel S500	75.08	6.12	459.49	83412
2423	3	2027-04-05	Diesel S10	33.89	5.44	184.36	85164
2424	4	2027-04-06	Gasolina	43.50	6.60	287.10	86916
2425	5	2027-04-07	Etanol	72.77	6.54	475.92	88668
2426	6	2027-04-08	Diesel S500	78.94	5.57	439.70	102920
2427	7	2027-04-09	Diesel S10	39.97	5.40	215.84	92172
2428	8	2027-04-10	Gasolina	71.81	6.58	472.51	93924
2429	9	2027-04-11	Etanol	49.38	6.18	305.17	130776
2430	10	2027-04-12	Diesel S500	34.27	6.64	227.55	158728
2431	11	2027-04-13	Diesel S10	76.88	6.71	515.86	98700
2432	12	2027-04-14	Gasolina	73.65	6.57	483.88	100442
2433	13	2027-04-15	Etanol	26.49	6.35	168.21	102184
2434	14	2027-04-16	Diesel S500	44.93	6.65	298.78	103926
2435	15	2027-04-17	Diesel S10	73.13	6.55	479.00	105668
2436	16	2027-04-18	Gasolina	73.64	5.65	416.07	107410
2437	17	2027-04-19	Etanol	72.24	5.41	390.82	109152
2438	18	2027-04-20	Diesel S500	77.33	6.54	505.74	110894
2439	19	2027-04-21	Diesel S10	38.35	6.47	248.12	112636
2440	20	2027-04-22	Gasolina	52.62	5.71	300.46	114378
2441	21	2027-04-23	Etanol	72.72	5.59	406.50	114320
2442	22	2027-04-24	Diesel S500	26.42	5.54	146.37	116062
2443	23	2027-04-25	Diesel S10	44.70	6.55	292.79	117804
2444	24	2027-04-26	Gasolina	83.01	5.67	470.67	119546
2445	25	2027-04-27	Etanol	63.49	5.85	371.42	121288
2446	26	2027-04-28	Diesel S500	83.87	6.05	507.41	123030
2447	27	2027-04-29	Diesel S10	81.35	5.42	440.92	124772
2448	28	2027-04-30	Gasolina	83.22	5.52	459.37	126514
2449	29	2027-05-01	Etanol	82.75	5.65	467.54	128256
2450	30	2027-05-02	Diesel S500	31.50	5.90	185.85	129998
2451	1	2027-05-03	Diesel S10	68.71	5.72	393.02	82920
2452	2	2027-05-04	Gasolina	61.37	6.02	369.45	84679
2453	3	2027-05-05	Etanol	48.11	6.11	293.95	86438
2454	4	2027-05-06	Diesel S500	40.28	6.31	254.17	88197
2455	5	2027-05-07	Diesel S10	25.10	6.64	166.66	89956
2456	6	2027-05-08	Gasolina	57.31	6.33	362.77	104215
2457	7	2027-05-09	Etanol	69.52	6.26	435.20	93474
2458	8	2027-05-10	Diesel S500	46.85	5.35	250.65	95233
2459	9	2027-05-11	Diesel S10	64.85	5.75	372.89	132092
2460	10	2027-05-12	Gasolina	43.83	6.52	285.77	160051
2461	11	2027-05-13	Etanol	68.19	5.70	388.68	100030
2462	12	2027-05-14	Diesel S500	43.56	5.86	255.26	101779
2463	13	2027-05-15	Diesel S10	49.14	5.69	279.61	103528
2464	14	2027-05-16	Gasolina	32.64	5.88	191.92	105277
2465	15	2027-05-17	Etanol	81.42	6.27	510.50	107026
2466	16	2027-05-18	Diesel S500	79.17	6.17	488.48	108775
2467	17	2027-05-19	Diesel S10	43.06	6.07	261.37	110524
2468	18	2027-05-20	Gasolina	25.02	5.68	142.11	112273
2469	19	2027-05-21	Etanol	50.79	6.12	310.83	114022
2470	20	2027-05-22	Diesel S500	64.28	5.95	382.47	115771
2471	85	2025-02-01	Diesel S10	34.32	5.39	184.98	108367
2472	107	2025-06-16	Diesel S500	51.12	5.32	271.96	71997
2473	129	2024-04-08	Gasolina	72.11	5.48	395.16	269161
2474	152	2024-03-12	Etanol	86.90	6.04	524.88	201099
2475	112	2025-11-30	Diesel S10	38.36	5.29	202.92	297928
2476	56	2026-04-30	Diesel S500	79.12	6.23	492.92	205526
2477	17	2026-03-02	Gasolina	26.69	6.21	165.74	121017
2478	19	2025-09-22	Etanol	42.80	5.27	225.56	171656
2479	173	2024-06-15	Diesel S10	88.42	6.87	607.45	181681
2480	41	2024-11-22	Gasolina	70.73	5.31	375.58	111519
2481	50	2025-10-12	Etanol	75.73	6.32	478.61	221634
2482	161	2026-08-12	Diesel S10	83.19	5.36	445.90	237761
2483	105	2026-10-17	Diesel S500	76.54	6.25	478.38	226984
2484	161	2025-06-06	Gasolina	64.30	5.85	376.16	237761
2485	16	2026-02-28	Etanol	94.73	6.66	630.90	127038
2486	140	2024-02-10	Diesel S500	41.36	6.35	262.64	191053
2487	133	2026-08-31	Gasolina	82.71	6.43	531.83	184085
2488	118	2025-05-25	Etanol	20.83	6.75	140.60	289578
2489	59	2024-06-20	Diesel S10	43.97	6.35	279.21	157949
2490	150	2024-09-04	Gasolina	55.22	6.37	351.75	214341
2491	140	2025-11-14	Etanol	99.48	5.50	547.14	191053
2492	70	2026-09-23	Diesel S10	94.54	5.58	527.53	286500
2493	69	2026-07-30	Diesel S500	47.96	5.85	280.57	225212
2494	118	2024-02-29	Etanol	61.78	6.49	400.95	289578
2495	145	2025-02-18	Diesel S10	44.19	5.74	253.65	134919
2496	73	2025-07-22	Diesel S500	90.04	6.35	571.75	283333
2497	83	2026-06-06	Gasolina	57.48	6.02	346.03	205058
2498	149	2024-08-12	Etanol	34.18	6.10	208.50	216265
2499	164	2025-10-25	Diesel S10	68.51	6.33	433.67	266092
2500	1	2024-10-18	Diesel S500	93.80	6.62	620.96	92629
2501	128	2025-11-12	Gasolina	59.07	6.75	398.72	281773
2502	92	2024-07-11	Etanol	76.54	6.25	478.38	204425
2503	31	2025-01-29	Diesel S10	64.76	5.67	367.19	73070
2504	27	2024-04-24	Diesel S500	74.07	5.47	405.16	265231
2505	70	2026-09-28	Gasolina	31.98	5.70	182.29	286500
2506	10	2024-07-08	Etanol	77.49	5.17	400.62	295031
2507	17	2025-11-11	Diesel S10	97.92	6.52	638.44	240048
2508	64	2026-06-19	Diesel S500	69.23	5.73	396.69	132564
2509	152	2025-01-17	Gasolina	46.06	6.14	282.81	201099
2510	28	2024-12-29	Etanol	72.13	5.20	375.08	135340
2511	146	2025-10-22	Diesel S10	41.93	6.74	282.61	139036
2512	142	2026-07-06	Diesel S500	30.80	6.33	194.96	277838
2513	162	2026-01-06	Gasolina	77.44	5.33	412.76	211609
2514	47	2026-10-18	Etanol	22.08	6.79	149.92	217726
2515	40	2024-12-11	Diesel S500	86.80	6.67	578.96	99296
2516	64	2025-12-26	Gasolina	85.29	5.23	446.07	261792
2517	103	2024-12-30	Diesel S10	96.74	6.63	641.39	223770
2518	117	2025-07-13	Diesel S500	49.63	6.84	339.47	106149
2519	60	2025-04-11	Gasolina	44.49	6.19	275.39	80190
2520	15	2026-09-26	Etanol	24.45	5.83	142.54	117421
2521	170	2026-07-30	Diesel S10	70.12	6.79	476.11	228823
2522	32	2025-04-21	Diesel S500	54.59	6.72	366.84	116702
2523	38	2024-10-03	Gasolina	89.08	6.41	571.00	186819
2524	105	2026-04-29	Etanol	72.68	5.92	430.27	226984
2525	14	2024-03-15	Diesel S10	53.17	6.42	341.35	169168
2526	84	2025-12-13	Diesel S500	79.52	5.52	438.95	142937
2527	50	2026-03-11	Gasolina	31.07	6.82	211.90	221634
2528	12	2024-03-13	Etanol	45.58	5.24	238.84	112359
2529	57	2026-09-29	Diesel S10	32.75	5.42	177.51	152030
2530	20	2025-04-26	Diesel S500	41.77	5.69	237.67	126411
2531	83	2024-12-26	Gasolina	76.80	5.60	430.08	205058
2532	55	2025-12-29	Diesel S10	42.96	5.68	244.01	121123
2533	73	2024-09-16	Diesel S500	95.84	5.73	549.16	283333
2534	114	2026-07-08	Gasolina	33.01	6.34	209.28	117675
2535	158	2024-03-06	Etanol	36.03	6.28	226.27	277695
2536	189	2024-08-01	Diesel S10	27.66	6.21	171.77	102213
2537	44	2024-03-18	Diesel S500	20.49	6.89	141.18	225246
2538	127	2026-05-18	Gasolina	63.70	5.54	352.90	283561
2539	184	2025-06-26	Etanol	85.21	5.28	449.91	202478
2540	55	2024-09-21	Diesel S10	41.58	6.74	280.25	224400
2541	182	2025-05-16	Diesel S500	76.06	5.53	420.61	284921
2542	103	2025-11-20	Gasolina	34.51	6.89	237.77	223770
2543	108	2025-09-21	Etanol	98.25	5.50	540.38	243112
2544	173	2026-05-11	Diesel S10	66.16	6.56	434.01	181681
2545	74	2025-08-23	Diesel S500	38.07	6.23	237.18	295295
2546	104	2025-11-01	Gasolina	69.91	6.77	473.29	224547
2547	145	2024-03-12	Etanol	39.63	6.58	260.77	278417
2548	152	2024-08-26	Diesel S10	66.02	5.64	372.35	201099
2549	80	2025-05-11	Gasolina	92.22	6.02	555.16	269530
2550	87	2025-09-30	Etanol	34.26	6.11	209.33	232389
2551	112	2024-11-09	Diesel S10	97.45	5.21	507.71	297928
2552	136	2026-04-09	Diesel S500	21.42	5.35	114.60	201015
2553	136	2026-08-27	Gasolina	30.62	5.19	158.92	201015
2554	62	2025-02-25	Etanol	90.15	6.48	584.17	81499
2555	27	2026-10-31	Diesel S10	51.72	5.56	287.56	265231
2556	105	2024-12-26	Diesel S500	49.90	6.57	327.84	226984
2557	168	2024-08-18	Gasolina	54.25	5.27	285.90	197957
2558	90	2024-04-01	Gasolina	52.94	6.38	337.76	267279
2559	142	2026-08-19	Etanol	84.66	5.52	467.32	277838
2560	169	2024-05-12	Diesel S10	39.88	5.68	226.52	146192
2561	138	2026-04-27	Diesel S500	49.17	5.49	269.94	158697
2562	38	2024-07-15	Gasolina	60.49	5.15	311.52	186819
2563	171	2024-09-19	Etanol	20.09	6.12	122.95	247838
2564	139	2026-04-01	Diesel S10	96.93	6.26	606.78	193126
2565	98	2024-04-09	Diesel S500	29.54	5.42	160.11	219769
2566	116	2025-10-10	Gasolina	99.69	5.69	567.24	267194
2567	68	2024-02-24	Etanol	76.99	6.10	469.64	286777
2568	86	2024-09-07	Diesel S10	89.57	6.80	609.08	161039
2569	135	2026-10-02	Diesel S500	30.57	6.41	195.95	288826
2570	61	2024-10-29	Gasolina	91.46	5.51	503.94	294212
2571	82	2024-06-28	Etanol	32.03	6.32	202.43	201996
2572	126	2025-10-22	Diesel S10	58.52	6.11	357.56	143809
2573	107	2024-05-24	Diesel S500	89.90	6.31	567.27	94664
2574	82	2026-07-02	Gasolina	59.27	5.34	316.50	227013
2575	50	2026-04-28	Etanol	29.63	6.23	184.59	232769
2576	26	2024-02-14	Diesel S10	91.75	6.11	560.59	131772
2577	33	2025-01-06	Diesel S500	34.04	6.01	204.58	292449
2578	118	2026-10-18	Gasolina	71.13	5.44	386.95	289578
2579	187	2026-03-28	Etanol	43.12	5.83	251.39	115516
2580	174	2025-09-26	Diesel S10	89.11	6.11	544.46	268268
2581	110	2026-05-15	Diesel S500	43.71	5.39	235.60	120997
2582	159	2024-06-23	Gasolina	67.59	5.91	399.46	223184
2583	165	2025-08-08	Etanol	89.22	6.23	555.84	109447
2584	1	2024-09-12	Diesel S10	96.42	5.74	553.45	119847
2585	26	2025-07-17	Diesel S500	44.90	6.33	284.22	150515
2586	120	2026-08-09	Gasolina	33.01	6.39	210.93	238642
2587	142	2025-03-21	Etanol	43.62	6.56	286.15	277838
2588	175	2025-05-26	Diesel S10	44.55	6.63	295.37	110912
2589	7	2024-12-11	Diesel S500	52.84	5.82	307.53	103477
2590	144	2025-12-18	Gasolina	39.21	5.69	223.10	82585
2591	22	2026-05-03	Etanol	29.87	6.10	182.21	177055
2592	134	2026-02-24	Diesel S500	87.45	5.98	522.95	198446
2593	69	2024-11-25	Gasolina	84.00	6.60	554.40	225212
2594	38	2024-02-08	Etanol	61.49	6.17	379.39	186819
2595	128	2024-11-26	Diesel S10	26.85	6.72	180.43	281773
2596	186	2025-06-18	Diesel S500	74.78	5.63	421.01	207358
2597	17	2026-09-08	Gasolina	88.75	6.72	596.40	240048
2598	100	2026-01-15	Etanol	27.32	6.40	174.85	76528
2599	47	2025-09-15	Diesel S10	96.30	5.88	566.24	217726
2600	67	2024-04-18	Diesel S500	68.23	5.86	399.83	135686
2601	137	2026-05-13	Gasolina	32.70	6.49	212.22	140906
2602	40	2025-08-11	Etanol	66.52	6.14	408.43	244777
2603	131	2025-08-18	Diesel S10	68.24	5.11	348.71	162834
2604	8	2026-06-07	Diesel S500	46.30	5.88	272.24	119089
2605	28	2024-11-05	Gasolina	49.05	6.32	310.00	178918
2606	97	2026-06-12	Etanol	21.67	5.74	124.39	183231
2607	67	2025-02-11	Diesel S10	74.92	6.51	487.73	252148
2608	64	2026-07-16	Diesel S500	69.61	6.39	444.81	298669
2609	2	2024-02-21	Gasolina	80.61	5.39	434.49	120979
2610	31	2024-12-04	Etanol	99.18	6.02	597.06	214165
2611	177	2024-08-22	Diesel S10	23.87	6.45	153.96	199398
2612	167	2025-07-15	Diesel S500	60.03	5.70	342.17	90209
2613	128	2026-02-02	Gasolina	24.46	5.11	124.99	281773
2614	31	2024-12-26	Etanol	23.86	6.06	144.59	228267
2615	45	2025-08-09	Diesel S10	55.25	6.56	362.44	65697
2616	103	2025-03-11	Diesel S500	35.48	6.60	234.17	295659
2617	152	2026-02-11	Gasolina	60.02	5.58	334.91	295796
2618	17	2025-04-29	Etanol	46.08	6.83	314.73	240048
2619	120	2026-06-03	Diesel S10	65.12	6.13	399.19	238642
2620	107	2026-07-02	Diesel S500	33.56	6.49	217.80	259205
2621	48	2026-06-15	Gasolina	83.71	6.20	519.00	131492
2622	136	2025-12-11	Etanol	57.98	6.85	397.16	201015
2623	125	2026-10-01	Diesel S10	91.58	5.81	532.08	199596
2624	39	2025-06-01	Diesel S500	72.26	5.74	414.77	74873
2625	58	2026-03-06	Gasolina	32.90	6.55	215.50	85327
2626	98	2024-12-21	Etanol	96.01	6.07	582.78	235238
2627	183	2024-09-15	Diesel S10	40.28	5.48	220.73	253709
2628	111	2025-06-20	Diesel S500	99.59	6.20	617.46	274180
2629	20	2026-06-08	Gasolina	43.70	5.59	244.28	288513
2630	108	2026-10-29	Etanol	27.91	6.65	185.60	243112
2631	16	2025-02-14	Diesel S10	52.72	6.19	326.34	215243
2632	165	2025-07-31	Gasolina	79.43	6.72	533.77	220934
2633	119	2024-04-15	Etanol	20.47	5.55	113.61	200086
2634	141	2026-09-16	Diesel S10	41.55	6.24	259.27	170501
2635	100	2025-01-25	Diesel S500	84.40	6.59	556.20	76528
2636	9	2025-02-10	Gasolina	53.85	6.67	359.18	142193
2637	162	2024-08-17	Etanol	97.15	5.50	534.33	244994
2638	89	2025-11-12	Diesel S10	36.57	5.99	219.05	229223
2639	163	2026-05-11	Diesel S500	33.03	5.89	194.55	78073
2640	85	2025-01-27	Gasolina	50.43	6.84	344.94	171591
2641	181	2025-12-30	Etanol	53.00	5.37	284.61	270644
2642	14	2026-07-18	Diesel S10	70.59	5.15	363.54	169168
2643	14	2025-05-12	Diesel S500	89.38	6.88	614.93	191122
2644	19	2025-07-11	Gasolina	52.10	6.30	328.23	226900
2645	6	2024-05-05	Etanol	89.54	6.45	577.53	260917
2646	156	2025-05-23	Diesel S10	80.31	5.76	462.59	266561
2647	41	2025-05-10	Diesel S500	29.17	6.63	193.40	199872
2648	53	2024-10-20	Gasolina	86.47	5.42	468.67	136901
2649	24	2025-05-21	Etanol	41.59	6.42	267.01	128204
2650	91	2024-08-14	Diesel S10	39.92	5.86	233.93	284065
2651	64	2024-11-26	Diesel S500	45.29	6.26	283.52	298669
2652	118	2025-09-06	Gasolina	43.07	6.40	275.65	289578
2653	144	2025-02-21	Etanol	43.79	6.50	284.64	143227
2654	126	2026-04-20	Diesel S10	67.13	6.10	409.49	209143
2655	150	2026-03-20	Diesel S500	95.18	5.32	506.36	214341
2656	113	2024-11-05	Gasolina	22.35	6.42	143.49	219688
2657	65	2024-05-22	Etanol	81.99	5.94	487.02	143677
2658	109	2025-02-05	Diesel S10	27.96	6.67	186.49	249082
2659	104	2025-08-01	Diesel S500	88.65	6.45	571.79	224547
2660	156	2024-02-27	Gasolina	89.55	5.54	496.11	278020
2661	59	2025-11-20	Etanol	85.46	5.60	478.58	157949
2662	174	2026-06-21	Diesel S500	91.72	5.81	532.89	268268
2663	49	2024-12-04	Etanol	79.99	5.63	450.34	297911
2664	131	2025-04-17	Diesel S10	56.60	5.76	326.02	162834
2665	36	2026-02-12	Diesel S500	65.72	5.44	357.52	75975
2666	12	2024-05-20	Gasolina	87.21	5.63	490.99	112359
2667	39	2026-06-30	Etanol	70.38	5.29	372.31	155124
2668	110	2025-08-28	Diesel S10	35.51	6.31	224.07	151366
2669	161	2026-05-05	Diesel S500	29.21	5.14	150.14	237761
2670	106	2026-07-04	Gasolina	72.24	5.47	395.15	243175
2671	48	2026-04-19	Etanol	53.86	5.19	279.53	295673
2672	148	2025-09-27	Diesel S10	36.83	6.56	241.60	298488
2673	128	2025-01-21	Diesel S500	55.89	6.67	372.79	281773
2674	179	2025-09-11	Gasolina	77.19	5.87	453.11	186236
2675	85	2025-07-14	Etanol	49.05	5.28	258.98	277000
2676	82	2025-03-01	Diesel S10	63.49	5.14	326.34	227013
2677	55	2026-10-01	Diesel S500	72.49	6.76	490.03	224400
2678	125	2025-12-21	Gasolina	69.35	5.61	389.05	247167
2679	109	2025-05-04	Etanol	31.81	6.72	213.76	249082
2680	15	2026-08-19	Diesel S10	34.02	5.56	189.15	117421
2681	138	2025-07-27	Diesel S500	32.69	5.52	180.45	158697
2682	129	2026-04-25	Gasolina	77.36	6.24	482.73	269161
2683	162	2025-04-26	Etanol	95.27	6.37	606.87	270870
2684	166	2024-12-09	Diesel S10	59.31	5.43	322.05	179250
2685	105	2026-10-22	Diesel S500	74.12	6.80	504.02	226984
2686	148	2026-02-07	Gasolina	57.70	5.80	334.66	298488
2687	121	2026-09-11	Etanol	37.51	5.65	211.93	201243
2688	179	2025-11-13	Diesel S10	43.14	6.57	283.43	186236
2689	158	2025-11-03	Diesel S500	60.69	5.38	326.51	277695
2690	21	2024-07-29	Gasolina	58.15	6.26	364.02	202964
2691	150	2024-07-21	Etanol	31.32	6.18	193.56	214341
2692	96	2024-12-21	Diesel S10	76.08	5.77	438.98	277702
2693	33	2024-06-25	Diesel S500	83.28	5.38	448.05	292449
2694	186	2025-07-17	Gasolina	41.37	6.63	274.28	207358
2695	144	2025-08-08	Etanol	44.56	6.69	298.11	230493
2696	156	2024-05-06	Diesel S10	87.42	6.14	536.76	278020
2697	81	2025-02-20	Gasolina	29.16	6.51	189.83	104667
2698	41	2025-08-17	Etanol	88.58	6.71	594.37	206137
2699	101	2024-06-15	Diesel S10	79.84	5.51	439.92	178322
2700	127	2025-04-02	Diesel S500	41.94	5.35	224.38	283561
2701	63	2024-08-19	Gasolina	85.55	5.45	466.25	254030
2702	168	2024-04-27	Etanol	67.54	6.80	459.27	283138
2703	28	2025-06-05	Diesel S10	40.86	5.33	217.78	178918
2704	119	2026-05-19	Diesel S500	66.80	6.62	442.22	298843
2705	176	2026-07-06	Gasolina	47.37	6.27	297.01	276125
2706	13	2024-11-03	Etanol	65.70	5.96	391.57	283352
2707	150	2024-03-13	Diesel S10	79.01	5.92	467.74	214341
2708	184	2026-09-28	Diesel S500	72.73	5.62	408.74	273445
2709	45	2024-07-02	Gasolina	54.09	5.73	309.94	273608
2710	103	2026-04-27	Etanol	44.47	6.84	304.17	295659
2711	84	2026-06-12	Diesel S10	78.52	6.45	506.45	142937
2712	154	2024-07-23	Diesel S500	64.26	5.11	328.37	276087
2713	17	2026-07-09	Gasolina	25.06	5.53	138.58	240048
2714	59	2026-10-26	Etanol	70.94	6.47	458.98	164297
2715	21	2025-02-26	Diesel S10	65.06	5.55	361.08	202964
2716	148	2024-07-25	Diesel S500	76.37	6.54	499.46	298488
2717	166	2024-12-07	Gasolina	87.42	5.20	454.58	179250
2718	182	2025-02-04	Etanol	46.80	5.10	238.68	284921
2719	166	2024-11-03	Diesel S10	63.56	5.17	328.61	179250
2720	161	2025-11-17	Diesel S500	81.96	6.78	555.69	237761
2721	114	2026-04-18	Gasolina	28.78	5.44	156.56	117675
2722	149	2025-10-22	Etanol	95.33	6.63	632.04	216265
2723	177	2025-03-04	Diesel S10	21.35	5.11	109.10	199398
2724	11	2024-12-05	Diesel S500	94.06	6.52	613.27	110229
2725	155	2025-03-30	Gasolina	66.72	6.26	417.67	165581
2726	39	2026-07-28	Diesel S10	20.08	6.38	128.11	202503
2727	89	2026-10-23	Diesel S500	49.39	5.57	275.10	279122
2728	67	2026-06-20	Gasolina	86.96	5.48	476.54	252148
2729	162	2025-01-29	Diesel S10	82.33	6.23	512.92	270870
2730	116	2024-03-26	Diesel S500	72.42	6.07	439.59	267194
2731	152	2024-07-12	Gasolina	87.48	6.26	547.62	295796
2732	39	2025-06-15	Etanol	58.93	5.49	323.53	202503
2733	173	2025-01-25	Diesel S10	55.10	6.27	345.48	181681
2734	122	2024-04-10	Diesel S500	21.91	5.50	120.51	132582
2735	70	2026-04-23	Gasolina	27.64	6.44	178.00	286500
2736	114	2025-02-03	Etanol	26.82	6.77	181.57	117675
2737	158	2024-12-13	Diesel S10	59.11	5.12	302.64	277695
2738	25	2024-08-30	Diesel S500	84.34	5.73	483.27	193456
2739	156	2026-08-18	Gasolina	37.72	5.28	199.16	278020
2740	162	2024-09-24	Etanol	37.47	6.46	242.06	270870
2741	129	2025-05-17	Diesel S10	21.98	5.18	113.86	269161
2742	103	2025-07-04	Gasolina	36.22	5.77	208.99	295659
2743	37	2026-10-17	Etanol	41.42	6.08	251.83	246323
2744	155	2024-04-30	Diesel S10	76.76	6.78	520.43	165581
2745	41	2024-09-20	Diesel S500	21.30	5.34	113.74	234020
2746	119	2024-11-21	Gasolina	84.50	5.72	483.34	298843
2747	75	2024-10-13	Etanol	76.08	5.54	421.48	166089
2748	72	2026-07-18	Diesel S10	45.38	6.67	302.68	277997
2749	113	2024-03-15	Diesel S500	97.68	6.38	623.20	242288
2750	71	2026-01-18	Gasolina	23.56	6.62	155.97	142386
2751	138	2026-08-19	Etanol	76.48	6.28	480.29	158697
\.


--
-- TOC entry 3621 (class 0 OID 32860)
-- Dependencies: 232
-- Data for Name: despesas; Type: TABLE DATA; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

COPY gabriel_trabalho_bd.despesas (id_despesa, id_veiculo, data_despesa, tipo_despesa, descricao, valor) FROM stdin;
1	1	2026-01-12	pedagio	pedagio em viagem regional	45.50
2	1	2026-02-14	lavagem	lavagem completa	80.00
3	1	2026-03-16	pedagio	pedagio em viagem regional	52.00
4	1	2026-04-18	documentacao	taxa administrativa	120.00
5	2	2026-01-15	pedagio	pedagio rodoviario	38.00
6	2	2026-02-17	lavagem	lavagem completa	75.00
7	2	2026-03-19	estacionamento	estacionamento em viagem	32.00
8	2	2026-05-21	pedagio	pedagio rodoviario	44.50
9	3	2026-01-20	lavagem	lavagem externa	65.00
10	3	2026-03-22	pedagio	pedagio regional	41.00
11	3	2026-05-24	estacionamento	estacionamento centro	28.00
12	4	2026-01-18	pedagio	pedagio rodoviario	95.00
13	4	2026-02-20	lavagem	lavagem de veiculo	120.00
14	4	2026-04-22	pedagio	pedagio rodoviario	110.00
15	4	2026-06-25	documentacao	taxa de licenciamento	180.00
16	5	2026-01-22	pedagio	pedagio rodoviario	102.00
17	5	2026-03-24	lavagem	lavagem completa	130.00
18	5	2026-05-26	pedagio	pedagio rodoviario	118.00
19	6	2026-02-10	pedagio	pedagio de rodovia	150.00
20	6	2026-03-12	lavagem	lavagem de caminhao	180.00
21	6	2026-05-14	estacionamento	patio de carga	90.00
22	7	2026-01-14	pedagio	pedagio rodoviario	130.00
23	7	2026-04-16	lavagem	lavagem de van	140.00
24	8	2026-02-18	pedagio	pedagio rodoviario	145.00
25	8	2026-05-20	estacionamento	estacionamento de carga	110.00
26	9	2026-01-25	pedagio	pedagios interestaduais	280.00
27	9	2026-03-27	lavagem	lavagem de caminhao	220.00
28	9	2026-06-28	estacionamento	patio de carga	160.00
29	10	2026-02-26	pedagio	pedagios interestaduais	310.00
30	10	2026-04-28	lavagem	lavagem de caminhao	240.00
31	10	2026-06-30	estacionamento	patio de carga	180.00
32	10	2026-10-09	Lavagem	Despesa de rotina do veículo	313.00
33	1	2026-10-27	Seguro	Despesa de rotina do veículo	67.30
34	2	2026-10-25	Lavagem	Despesa de rotina do veículo	94.60
35	3	2026-10-23	Licenciamento	Despesa de rotina do veículo	121.90
36	4	2026-10-21	Pedágio	Despesa de rotina do veículo	149.20
37	5	2026-10-19	Seguro	Despesa de rotina do veículo	176.50
38	6	2026-10-17	Lavagem	Despesa de rotina do veículo	203.80
39	7	2026-10-15	Licenciamento	Despesa de rotina do veículo	231.10
40	8	2026-10-13	Pedágio	Despesa de rotina do veículo	258.40
41	9	2026-10-11	Seguro	Despesa de rotina do veículo	285.70
42	39	2026-01-01	pedagio	pedagio em viagem regional	93.67
43	50	2026-01-01	pedagio	pedagio em viagem regional	49.97
44	39	2026-01-06	documentacao	taxa administrativa	125.17
45	45	2026-01-09	documentacao	licenciamento anual	205.56
46	50	2026-01-14	lavagem	lavagem completa	93.08
47	38	2026-01-18	documentacao	licenciamento anual	243.19
48	41	2026-01-19	documentacao	taxa administrativa	127.18
49	41	2026-01-22	documentacao	taxa administrativa	122.54
50	42	2026-01-23	documentacao	taxa administrativa	128.45
51	47	2026-01-23	lavagem	lavagem completa	73.37
52	39	2026-01-24	documentacao	licenciamento anual	300.97
53	34	2026-01-26	documentacao	licenciamento anual	329.99
54	40	2026-02-08	pedagio	pedagio em viagem regional	43.48
55	42	2026-02-10	pedagio	pedagio em viagem regional	53.11
56	40	2026-02-15	estacionamento	estacionamento em visita ao cliente	55.95
57	48	2026-02-17	documentacao	licenciamento anual	156.19
58	31	2026-02-18	lavagem	lavagem completa	79.96
59	44	2026-02-21	documentacao	licenciamento anual	228.29
60	44	2026-02-26	estacionamento	estacionamento em visita ao cliente	50.21
61	48	2026-02-27	documentacao	licenciamento anual	308.00
62	31	2026-03-02	lavagem	lavagem completa	92.41
63	34	2026-03-09	lavagem	lavagem completa	108.16
64	35	2026-03-10	documentacao	taxa administrativa	111.69
65	45	2026-03-11	lavagem	lavagem completa	107.53
66	45	2026-03-13	documentacao	taxa administrativa	98.02
67	34	2026-03-15	estacionamento	estacionamento em visita ao cliente	22.57
68	31	2026-03-19	lavagem	lavagem completa	85.98
69	38	2026-03-20	documentacao	licenciamento anual	418.03
70	32	2026-03-21	estacionamento	estacionamento em visita ao cliente	41.71
71	34	2026-03-22	pedagio	pedagio em viagem regional	38.31
72	49	2026-03-22	documentacao	taxa administrativa	127.08
73	43	2026-03-23	documentacao	taxa administrativa	115.14
74	32	2026-04-01	lavagem	lavagem completa	60.83
75	47	2026-04-03	lavagem	lavagem completa	80.05
76	47	2026-04-07	estacionamento	estacionamento em visita ao cliente	34.96
77	33	2026-04-11	estacionamento	estacionamento em visita ao cliente	58.75
78	41	2026-04-17	lavagem	lavagem completa	83.28
79	33	2026-05-05	documentacao	taxa administrativa	139.06
80	38	2026-05-05	pedagio	pedagio em viagem regional	45.97
81	43	2026-05-07	pedagio	pedagio em viagem regional	82.96
82	37	2026-05-08	documentacao	licenciamento anual	350.24
83	48	2026-05-13	lavagem	lavagem completa	86.36
84	36	2026-05-15	documentacao	taxa administrativa	159.24
85	36	2026-05-15	estacionamento	estacionamento em visita ao cliente	48.28
86	38	2026-05-16	lavagem	lavagem completa	91.76
87	41	2026-05-19	pedagio	pedagio em viagem regional	54.40
88	46	2026-05-20	documentacao	taxa administrativa	123.78
89	45	2026-05-23	pedagio	pedagio em viagem regional	74.37
90	43	2026-05-24	estacionamento	estacionamento em visita ao cliente	33.14
91	34	2026-05-26	pedagio	pedagio em viagem regional	48.06
92	49	2026-05-27	lavagem	lavagem completa	78.36
93	42	2026-06-01	estacionamento	estacionamento em visita ao cliente	59.86
94	40	2026-06-02	documentacao	licenciamento anual	253.17
95	49	2026-06-04	pedagio	pedagio em viagem regional	56.69
96	45	2026-06-05	pedagio	pedagio em viagem regional	87.95
97	48	2026-06-05	documentacao	taxa administrativa	95.29
98	33	2026-06-09	pedagio	pedagio em viagem regional	84.36
99	35	2026-06-09	documentacao	licenciamento anual	357.09
100	36	2026-06-15	lavagem	lavagem completa	100.49
101	38	2026-06-16	lavagem	lavagem completa	63.23
102	39	2026-06-21	pedagio	pedagio em viagem regional	36.78
103	48	2026-06-24	lavagem	lavagem completa	61.60
104	37	2026-06-25	lavagem	lavagem completa	63.79
105	44	2026-06-26	documentacao	licenciamento anual	278.13
106	42	2026-07-02	estacionamento	estacionamento em visita ao cliente	52.27
107	33	2026-07-09	lavagem	lavagem completa	76.45
108	41	2026-07-09	estacionamento	estacionamento em visita ao cliente	46.32
109	42	2026-07-12	documentacao	licenciamento anual	376.49
110	44	2026-07-13	documentacao	licenciamento anual	195.72
111	43	2026-07-15	estacionamento	estacionamento em visita ao cliente	38.92
112	49	2026-07-15	pedagio	pedagio em viagem regional	53.35
113	35	2026-07-24	lavagem	lavagem completa	61.70
114	50	2026-07-27	lavagem	lavagem completa	95.44
115	37	2026-07-28	estacionamento	estacionamento em visita ao cliente	42.67
116	40	2026-08-01	documentacao	licenciamento anual	230.63
117	49	2026-08-05	estacionamento	estacionamento em visita ao cliente	19.92
118	36	2026-08-10	documentacao	taxa administrativa	167.40
119	32	2026-08-14	documentacao	licenciamento anual	221.23
120	31	2026-08-19	documentacao	taxa administrativa	145.67
121	36	2026-08-19	pedagio	pedagio em viagem regional	36.14
122	33	2026-08-24	lavagem	lavagem completa	88.33
123	47	2026-08-27	documentacao	licenciamento anual	324.57
124	32	2026-09-01	lavagem	lavagem completa	93.08
125	35	2026-09-01	documentacao	taxa administrativa	134.91
126	43	2026-09-02	pedagio	pedagio em viagem regional	76.87
127	47	2026-09-04	documentacao	licenciamento anual	220.95
128	37	2026-09-06	documentacao	licenciamento anual	292.44
129	32	2026-09-13	documentacao	licenciamento anual	390.07
130	40	2026-09-17	pedagio	pedagio em viagem regional	67.39
131	50	2026-09-18	pedagio	pedagio em viagem regional	76.88
132	46	2026-09-19	estacionamento	estacionamento em visita ao cliente	50.51
133	46	2026-09-22	documentacao	licenciamento anual	225.32
134	44	2026-09-25	pedagio	pedagio em viagem regional	41.85
135	31	2026-10-11	documentacao	taxa administrativa	131.29
136	39	2026-10-12	pedagio	pedagio em viagem regional	55.06
137	35	2026-10-16	pedagio	pedagio em viagem regional	67.57
138	50	2026-10-16	pedagio	pedagio em viagem regional	33.83
139	46	2026-10-23	documentacao	taxa administrativa	175.06
140	37	2026-10-25	pedagio	pedagio em viagem regional	69.39
141	46	2026-10-27	pedagio	pedagio em viagem regional	68.00
142	68	2025-01-06	pedagio	pedagio em viagem regional	67.64
143	75	2025-01-06	documentacao	taxa administrativa	181.39
144	83	2025-01-06	documentacao	licenciamento anual	345.69
145	56	2025-01-10	lavagem	lavagem completa	78.76
146	82	2025-01-13	documentacao	taxa administrativa	160.10
147	73	2025-01-17	lavagem	lavagem completa	61.63
148	70	2025-01-25	documentacao	taxa administrativa	151.10
149	56	2025-01-26	documentacao	taxa administrativa	176.82
150	52	2025-01-27	pedagio	pedagio em viagem regional	44.37
151	59	2025-02-02	documentacao	taxa administrativa	93.96
152	60	2025-02-02	multa	multa de transito	216.06
153	71	2025-02-02	documentacao	taxa administrativa	130.79
154	55	2025-02-06	estacionamento	estacionamento em visita ao cliente	50.11
155	90	2025-02-10	estacionamento	estacionamento em visita ao cliente	42.73
156	71	2025-02-12	estacionamento	estacionamento em visita ao cliente	48.83
157	83	2025-02-12	documentacao	taxa administrativa	155.93
158	76	2025-02-13	seguro	parcela do seguro	351.25
159	55	2025-02-17	documentacao	taxa administrativa	171.06
160	69	2025-02-17	documentacao	licenciamento anual	270.86
161	71	2025-02-17	estacionamento	estacionamento em visita ao cliente	24.52
162	64	2025-02-18	pedagio	pedagio em viagem regional	41.43
163	73	2025-02-20	multa	multa de transito	158.83
164	71	2025-02-21	lavagem	lavagem completa	87.99
165	87	2025-02-21	pedagio	pedagio em viagem regional	31.65
166	84	2025-02-22	seguro	parcela do seguro	468.08
167	63	2025-02-24	lavagem	lavagem completa	103.33
168	85	2025-02-24	lavagem	lavagem completa	73.44
169	90	2025-02-24	documentacao	taxa administrativa	121.14
170	74	2025-02-25	lavagem	lavagem completa	106.79
171	64	2025-02-26	seguro	parcela do seguro	517.57
172	72	2025-02-26	lavagem	lavagem completa	87.40
173	55	2025-03-01	documentacao	taxa administrativa	130.95
174	69	2025-03-03	estacionamento	estacionamento em visita ao cliente	30.31
175	58	2025-03-04	estacionamento	estacionamento em visita ao cliente	21.02
176	60	2025-03-04	documentacao	licenciamento anual	384.81
177	86	2025-03-04	documentacao	taxa administrativa	148.38
178	83	2025-03-05	documentacao	licenciamento anual	283.07
179	78	2025-03-06	multa	multa de transito	254.64
180	78	2025-03-08	pedagio	pedagio em viagem regional	96.06
181	88	2025-03-08	lavagem	lavagem completa	109.28
182	51	2025-03-09	pedagio	pedagio em viagem regional	85.19
183	58	2025-03-09	lavagem	lavagem completa	97.21
184	62	2025-03-10	estacionamento	estacionamento em visita ao cliente	17.45
185	60	2025-03-12	documentacao	licenciamento anual	156.53
186	87	2025-03-12	documentacao	taxa administrativa	148.96
187	73	2025-03-14	pedagio	pedagio em viagem regional	32.26
188	52	2025-03-17	documentacao	licenciamento anual	205.25
189	53	2025-03-17	lavagem	lavagem completa	55.91
190	81	2025-03-17	lavagem	lavagem completa	55.61
191	64	2025-03-19	estacionamento	estacionamento em visita ao cliente	55.73
192	55	2025-03-23	pedagio	pedagio em viagem regional	79.29
193	70	2025-03-25	pedagio	pedagio em viagem regional	33.81
194	72	2025-03-26	pedagio	pedagio em viagem regional	86.58
195	82	2025-03-27	documentacao	taxa administrativa	180.20
196	82	2025-04-02	documentacao	licenciamento anual	236.81
197	63	2025-04-05	seguro	parcela do seguro	446.88
198	70	2025-04-05	multa	multa de transito	169.47
199	59	2025-04-08	pedagio	pedagio em viagem regional	36.19
200	67	2025-04-10	pedagio	pedagio em viagem regional	52.39
201	56	2025-04-11	estacionamento	estacionamento em visita ao cliente	41.69
202	75	2025-04-11	documentacao	licenciamento anual	387.40
203	75	2025-04-13	multa	multa de transito	140.79
204	77	2025-04-13	pedagio	pedagio em viagem regional	57.00
205	59	2025-04-14	documentacao	licenciamento anual	331.11
206	60	2025-04-16	documentacao	taxa administrativa	112.45
207	54	2025-04-17	estacionamento	estacionamento em visita ao cliente	39.21
208	81	2025-04-18	lavagem	lavagem completa	75.49
209	82	2025-04-18	documentacao	taxa administrativa	114.74
210	88	2025-04-19	pedagio	pedagio em viagem regional	86.01
211	79	2025-04-20	lavagem	lavagem completa	70.11
212	57	2025-04-21	seguro	parcela do seguro	635.98
213	79	2025-04-21	pedagio	pedagio em viagem regional	30.92
214	80	2025-04-23	seguro	parcela do seguro	629.92
215	81	2025-04-25	lavagem	lavagem completa	91.47
216	62	2025-04-26	estacionamento	estacionamento em visita ao cliente	40.34
217	61	2025-04-27	documentacao	taxa administrativa	188.27
218	72	2025-04-28	seguro	parcela do seguro	381.63
219	76	2025-05-01	documentacao	taxa administrativa	137.34
220	51	2025-05-02	seguro	parcela do seguro	564.69
221	54	2025-05-02	multa	multa de transito	164.14
222	67	2025-05-04	documentacao	licenciamento anual	234.95
223	64	2025-05-05	documentacao	taxa administrativa	96.71
224	62	2025-05-06	estacionamento	estacionamento em visita ao cliente	18.10
225	51	2025-05-10	documentacao	taxa administrativa	162.42
226	57	2025-05-14	pedagio	pedagio em viagem regional	91.60
227	63	2025-05-14	pedagio	pedagio em viagem regional	86.63
228	60	2025-05-15	multa	multa de transito	174.01
229	85	2025-05-15	pedagio	pedagio em viagem regional	83.69
230	74	2025-05-16	seguro	parcela do seguro	472.51
231	58	2025-05-17	documentacao	taxa administrativa	132.85
232	67	2025-05-21	multa	multa de transito	251.29
233	75	2025-05-21	seguro	parcela do seguro	607.39
234	87	2025-05-21	multa	multa de transito	183.01
235	64	2025-05-22	documentacao	taxa administrativa	158.57
236	87	2025-05-22	estacionamento	estacionamento em visita ao cliente	31.33
237	73	2025-05-26	pedagio	pedagio em viagem regional	41.07
238	52	2025-06-01	documentacao	taxa administrativa	170.26
239	70	2025-06-05	lavagem	lavagem completa	71.77
240	83	2025-06-05	documentacao	taxa administrativa	175.01
241	56	2025-06-06	pedagio	pedagio em viagem regional	53.09
242	52	2025-06-08	multa	multa de transito	195.24
243	65	2025-06-16	documentacao	taxa administrativa	187.06
244	65	2025-06-17	documentacao	taxa administrativa	166.44
245	64	2025-06-19	seguro	parcela do seguro	633.55
246	86	2025-06-22	documentacao	licenciamento anual	246.97
247	69	2025-06-24	documentacao	taxa administrativa	136.23
248	78	2025-06-24	documentacao	licenciamento anual	328.41
249	79	2025-06-24	documentacao	taxa administrativa	189.26
250	81	2025-06-26	seguro	parcela do seguro	478.66
251	66	2025-06-27	seguro	parcela do seguro	627.87
252	60	2025-07-01	estacionamento	estacionamento em visita ao cliente	37.89
253	61	2025-07-03	multa	multa de transito	274.78
254	86	2025-07-03	documentacao	taxa administrativa	149.43
255	66	2025-07-05	lavagem	lavagem completa	67.55
256	88	2025-07-06	multa	multa de transito	138.38
257	69	2025-07-08	lavagem	lavagem completa	75.73
258	62	2025-07-10	lavagem	lavagem completa	114.72
259	67	2025-07-10	seguro	parcela do seguro	381.21
260	65	2025-07-11	multa	multa de transito	199.98
261	67	2025-07-11	documentacao	taxa administrativa	137.18
262	73	2025-07-13	seguro	parcela do seguro	227.61
263	86	2025-07-14	seguro	parcela do seguro	451.47
264	78	2025-07-16	lavagem	lavagem completa	106.47
265	58	2025-07-17	pedagio	pedagio em viagem regional	31.35
266	60	2025-07-18	lavagem	lavagem completa	102.61
267	55	2025-07-19	multa	multa de transito	179.29
268	67	2025-07-19	seguro	parcela do seguro	273.10
269	79	2025-07-19	multa	multa de transito	151.70
270	65	2025-07-21	lavagem	lavagem completa	98.35
271	75	2025-07-25	documentacao	taxa administrativa	163.40
272	84	2025-07-26	documentacao	licenciamento anual	260.26
273	86	2025-07-27	pedagio	pedagio em viagem regional	30.67
274	57	2025-08-02	documentacao	taxa administrativa	127.23
275	61	2025-08-02	documentacao	licenciamento anual	168.14
276	70	2025-08-02	lavagem	lavagem completa	74.41
277	62	2025-08-05	documentacao	licenciamento anual	199.08
278	55	2025-08-06	estacionamento	estacionamento em visita ao cliente	43.16
279	74	2025-08-12	documentacao	taxa administrativa	136.31
280	89	2025-08-12	seguro	parcela do seguro	299.27
281	78	2025-08-14	lavagem	lavagem completa	107.47
282	90	2025-08-14	documentacao	licenciamento anual	193.85
283	62	2025-08-15	seguro	parcela do seguro	223.00
284	89	2025-08-16	seguro	parcela do seguro	538.66
285	80	2025-08-17	documentacao	licenciamento anual	248.90
286	77	2025-08-21	documentacao	taxa administrativa	162.39
287	58	2025-08-22	lavagem	lavagem completa	87.43
288	70	2025-08-24	lavagem	lavagem completa	107.65
289	53	2025-08-27	estacionamento	estacionamento em visita ao cliente	52.19
290	63	2025-09-04	documentacao	taxa administrativa	163.34
291	61	2025-09-06	seguro	parcela do seguro	229.63
292	85	2025-09-07	seguro	parcela do seguro	474.96
293	81	2025-09-08	multa	multa de transito	237.68
294	58	2025-09-09	pedagio	pedagio em viagem regional	32.82
295	82	2025-09-09	seguro	parcela do seguro	566.88
296	67	2025-09-10	pedagio	pedagio em viagem regional	74.59
297	85	2025-09-10	documentacao	licenciamento anual	222.80
298	86	2025-09-10	lavagem	lavagem completa	78.09
299	65	2025-09-12	estacionamento	estacionamento em visita ao cliente	46.78
300	85	2025-09-13	documentacao	taxa administrativa	127.00
301	70	2025-09-15	documentacao	taxa administrativa	105.61
302	71	2025-09-17	multa	multa de transito	197.45
303	59	2025-09-18	documentacao	taxa administrativa	144.10
304	84	2025-09-19	estacionamento	estacionamento em visita ao cliente	51.03
305	88	2025-09-20	estacionamento	estacionamento em visita ao cliente	19.24
306	61	2025-09-21	documentacao	taxa administrativa	98.89
307	66	2025-09-22	seguro	parcela do seguro	327.86
308	53	2025-09-23	multa	multa de transito	138.41
309	66	2025-09-23	estacionamento	estacionamento em visita ao cliente	52.18
310	79	2025-09-26	pedagio	pedagio em viagem regional	96.50
311	61	2025-09-28	pedagio	pedagio em viagem regional	93.15
312	68	2025-09-28	estacionamento	estacionamento em visita ao cliente	53.35
313	81	2025-10-01	estacionamento	estacionamento em visita ao cliente	30.44
314	62	2025-10-02	seguro	parcela do seguro	543.09
315	67	2025-10-04	documentacao	taxa administrativa	127.35
316	74	2025-10-05	pedagio	pedagio em viagem regional	92.15
317	63	2025-10-08	lavagem	lavagem completa	68.16
318	65	2025-10-09	pedagio	pedagio em viagem regional	83.52
319	68	2025-10-09	estacionamento	estacionamento em visita ao cliente	28.62
320	51	2025-10-10	pedagio	pedagio em viagem regional	72.08
321	89	2025-10-10	lavagem	lavagem completa	73.44
322	77	2025-10-11	seguro	parcela do seguro	471.53
323	56	2025-10-13	documentacao	taxa administrativa	177.53
324	62	2025-10-13	seguro	parcela do seguro	345.65
325	65	2025-10-13	documentacao	taxa administrativa	149.33
326	54	2025-10-14	lavagem	lavagem completa	75.52
327	74	2025-10-16	documentacao	taxa administrativa	103.38
328	85	2025-10-16	estacionamento	estacionamento em visita ao cliente	57.98
329	78	2025-10-17	seguro	parcela do seguro	562.77
330	75	2025-10-22	seguro	parcela do seguro	226.75
331	68	2025-10-23	documentacao	licenciamento anual	178.22
332	80	2025-10-26	documentacao	licenciamento anual	256.91
333	52	2025-10-27	seguro	parcela do seguro	507.61
334	55	2025-10-27	estacionamento	estacionamento em visita ao cliente	46.96
335	60	2025-10-27	lavagem	lavagem completa	113.43
336	63	2025-10-27	estacionamento	estacionamento em visita ao cliente	39.75
337	87	2025-10-27	documentacao	taxa administrativa	126.41
338	59	2025-11-01	pedagio	pedagio em viagem regional	86.96
339	75	2025-11-02	documentacao	licenciamento anual	156.55
340	89	2025-11-02	lavagem	lavagem completa	78.95
341	82	2025-11-04	estacionamento	estacionamento em visita ao cliente	48.64
342	89	2025-11-06	documentacao	taxa administrativa	104.31
343	53	2025-11-07	lavagem	lavagem completa	107.81
344	66	2025-11-07	seguro	parcela do seguro	618.25
345	60	2025-11-11	seguro	parcela do seguro	438.20
346	81	2025-11-11	pedagio	pedagio em viagem regional	44.88
347	76	2025-11-12	seguro	parcela do seguro	636.49
348	56	2025-11-13	documentacao	taxa administrativa	155.13
349	68	2025-11-15	documentacao	licenciamento anual	162.87
350	70	2025-11-15	pedagio	pedagio em viagem regional	32.83
351	70	2025-11-17	documentacao	taxa administrativa	127.88
352	72	2025-11-19	multa	multa de transito	156.80
353	88	2025-11-19	multa	multa de transito	181.06
354	53	2025-11-24	pedagio	pedagio em viagem regional	92.76
355	62	2025-11-27	documentacao	taxa administrativa	160.41
356	88	2025-11-28	seguro	parcela do seguro	328.11
357	80	2025-12-02	documentacao	licenciamento anual	409.92
358	57	2025-12-06	pedagio	pedagio em viagem regional	53.69
359	59	2025-12-06	lavagem	lavagem completa	94.76
360	61	2025-12-06	estacionamento	estacionamento em visita ao cliente	41.15
361	58	2025-12-07	pedagio	pedagio em viagem regional	87.72
362	78	2025-12-08	lavagem	lavagem completa	113.09
363	73	2025-12-09	documentacao	licenciamento anual	347.97
364	69	2025-12-14	multa	multa de transito	182.06
365	90	2025-12-17	seguro	parcela do seguro	428.63
366	61	2025-12-18	estacionamento	estacionamento em visita ao cliente	51.13
367	76	2025-12-20	lavagem	lavagem completa	92.93
368	77	2025-12-20	pedagio	pedagio em viagem regional	68.98
369	69	2025-12-21	lavagem	lavagem completa	92.20
370	62	2025-12-22	documentacao	licenciamento anual	350.57
371	78	2025-12-22	lavagem	lavagem completa	73.64
372	79	2025-12-23	estacionamento	estacionamento em visita ao cliente	47.12
373	59	2025-12-24	pedagio	pedagio em viagem regional	74.42
374	89	2025-12-24	documentacao	taxa administrativa	117.06
375	57	2025-12-25	lavagem	lavagem completa	92.13
376	61	2025-12-26	lavagem	lavagem completa	99.23
377	63	2025-12-26	pedagio	pedagio em viagem regional	55.14
378	54	2025-12-27	estacionamento	estacionamento em visita ao cliente	39.69
379	58	2025-12-27	documentacao	licenciamento anual	288.95
380	63	2026-01-01	seguro	parcela do seguro	242.56
381	73	2026-01-04	pedagio	pedagio em viagem regional	44.83
382	84	2026-01-10	estacionamento	estacionamento em visita ao cliente	26.90
383	87	2026-01-14	estacionamento	estacionamento em visita ao cliente	61.26
384	69	2026-01-17	multa	multa de transito	280.21
385	57	2026-01-18	seguro	parcela do seguro	283.64
386	51	2026-01-19	lavagem	lavagem completa	57.50
387	51	2026-01-25	documentacao	licenciamento anual	241.32
388	75	2026-01-25	multa	multa de transito	158.08
389	71	2026-01-26	estacionamento	estacionamento em visita ao cliente	41.04
390	64	2026-02-03	documentacao	taxa administrativa	105.57
391	77	2026-02-04	multa	multa de transito	148.76
392	80	2026-02-06	seguro	parcela do seguro	558.76
393	68	2026-02-07	documentacao	licenciamento anual	217.80
394	88	2026-02-07	estacionamento	estacionamento em visita ao cliente	22.97
395	89	2026-02-13	pedagio	pedagio em viagem regional	52.27
396	83	2026-02-15	lavagem	lavagem completa	63.85
397	90	2026-02-18	lavagem	lavagem completa	88.98
398	59	2026-02-19	lavagem	lavagem completa	105.23
399	76	2026-02-20	estacionamento	estacionamento em visita ao cliente	45.87
400	76	2026-02-22	pedagio	pedagio em viagem regional	75.41
401	76	2026-02-25	estacionamento	estacionamento em visita ao cliente	26.66
402	52	2026-02-27	estacionamento	estacionamento em visita ao cliente	39.67
403	56	2026-02-27	pedagio	pedagio em viagem regional	91.91
404	87	2026-02-27	estacionamento	estacionamento em visita ao cliente	62.80
405	69	2026-03-01	seguro	parcela do seguro	383.37
406	85	2026-03-01	lavagem	lavagem completa	72.13
407	70	2026-03-06	lavagem	lavagem completa	61.28
408	80	2026-03-06	lavagem	lavagem completa	111.33
409	59	2026-03-08	estacionamento	estacionamento em visita ao cliente	23.20
410	83	2026-03-09	multa	multa de transito	138.71
411	56	2026-03-10	multa	multa de transito	196.94
412	52	2026-03-12	estacionamento	estacionamento em visita ao cliente	54.19
413	72	2026-03-13	lavagem	lavagem completa	109.11
414	71	2026-03-14	multa	multa de transito	244.01
415	66	2026-03-16	seguro	parcela do seguro	551.04
416	78	2026-03-16	multa	multa de transito	213.26
417	60	2026-03-19	pedagio	pedagio em viagem regional	66.84
418	77	2026-03-19	lavagem	lavagem completa	57.40
419	84	2026-03-20	estacionamento	estacionamento em visita ao cliente	42.17
420	75	2026-03-21	seguro	parcela do seguro	601.38
421	52	2026-03-25	documentacao	taxa administrativa	128.65
422	81	2026-03-28	multa	multa de transito	223.26
423	86	2026-04-02	multa	multa de transito	201.83
424	56	2026-04-03	estacionamento	estacionamento em visita ao cliente	27.15
425	86	2026-04-04	documentacao	licenciamento anual	426.86
426	55	2026-04-05	multa	multa de transito	269.52
427	71	2026-04-05	documentacao	licenciamento anual	207.64
428	72	2026-04-05	lavagem	lavagem completa	73.26
429	84	2026-04-05	estacionamento	estacionamento em visita ao cliente	25.68
430	84	2026-04-07	estacionamento	estacionamento em visita ao cliente	47.79
431	64	2026-04-09	seguro	parcela do seguro	293.43
432	85	2026-04-09	multa	multa de transito	160.28
433	59	2026-04-10	multa	multa de transito	153.85
434	90	2026-04-10	lavagem	lavagem completa	89.20
435	86	2026-04-13	documentacao	taxa administrativa	153.43
436	64	2026-04-19	seguro	parcela do seguro	557.77
437	73	2026-04-23	documentacao	licenciamento anual	254.28
438	89	2026-04-23	documentacao	taxa administrativa	137.83
439	65	2026-04-24	estacionamento	estacionamento em visita ao cliente	60.61
440	87	2026-04-26	multa	multa de transito	177.97
441	83	2026-04-27	lavagem	lavagem completa	89.19
442	88	2026-04-27	documentacao	taxa administrativa	161.73
443	72	2026-04-28	estacionamento	estacionamento em visita ao cliente	22.91
444	90	2026-05-01	multa	multa de transito	276.77
445	68	2026-05-03	multa	multa de transito	261.53
446	71	2026-05-03	documentacao	licenciamento anual	373.63
447	57	2026-05-04	seguro	parcela do seguro	407.79
448	51	2026-05-05	seguro	parcela do seguro	601.25
449	53	2026-05-09	multa	multa de transito	177.30
450	80	2026-05-09	multa	multa de transito	177.96
451	87	2026-05-09	documentacao	taxa administrativa	116.86
452	76	2026-05-10	documentacao	licenciamento anual	162.79
453	82	2026-05-13	multa	multa de transito	281.45
454	66	2026-05-15	documentacao	taxa administrativa	134.95
455	74	2026-05-15	lavagem	lavagem completa	105.40
456	80	2026-05-15	documentacao	taxa administrativa	142.97
457	82	2026-05-16	pedagio	pedagio em viagem regional	37.14
458	79	2026-05-17	estacionamento	estacionamento em visita ao cliente	51.57
459	54	2026-05-18	multa	multa de transito	253.29
460	72	2026-05-18	documentacao	licenciamento anual	210.41
461	86	2026-05-20	multa	multa de transito	147.65
462	51	2026-05-21	seguro	parcela do seguro	394.58
463	69	2026-05-21	pedagio	pedagio em viagem regional	36.84
464	54	2026-06-02	estacionamento	estacionamento em visita ao cliente	56.34
465	82	2026-06-08	pedagio	pedagio em viagem regional	30.75
466	83	2026-06-10	seguro	parcela do seguro	273.98
467	58	2026-06-12	multa	multa de transito	172.75
468	71	2026-06-12	lavagem	lavagem completa	66.60
469	89	2026-06-14	documentacao	licenciamento anual	299.63
470	53	2026-06-16	multa	multa de transito	205.54
471	67	2026-06-16	estacionamento	estacionamento em visita ao cliente	44.89
472	77	2026-06-16	lavagem	lavagem completa	90.59
473	58	2026-06-17	seguro	parcela do seguro	637.16
474	65	2026-06-18	lavagem	lavagem completa	91.09
475	80	2026-06-18	lavagem	lavagem completa	87.01
476	72	2026-06-20	documentacao	licenciamento anual	274.84
477	69	2026-06-21	documentacao	taxa administrativa	168.80
478	53	2026-06-22	seguro	parcela do seguro	397.50
479	75	2026-06-28	documentacao	licenciamento anual	246.94
480	78	2026-07-01	seguro	parcela do seguro	428.70
481	90	2026-07-05	lavagem	lavagem completa	59.56
482	79	2026-07-06	documentacao	taxa administrativa	186.58
483	66	2026-07-11	documentacao	taxa administrativa	182.00
484	57	2026-07-16	lavagem	lavagem completa	101.50
485	51	2026-07-17	pedagio	pedagio em viagem regional	87.73
486	73	2026-07-17	estacionamento	estacionamento em visita ao cliente	31.19
487	73	2026-07-18	pedagio	pedagio em viagem regional	66.62
488	63	2026-07-26	documentacao	licenciamento anual	389.99
489	65	2026-07-26	estacionamento	estacionamento em visita ao cliente	60.04
490	82	2026-08-03	multa	multa de transito	167.23
491	77	2026-08-04	seguro	parcela do seguro	443.04
492	66	2026-08-06	seguro	parcela do seguro	557.86
493	57	2026-08-07	pedagio	pedagio em viagem regional	60.18
494	84	2026-08-07	estacionamento	estacionamento em visita ao cliente	52.74
495	52	2026-08-08	lavagem	lavagem completa	74.67
496	53	2026-08-08	estacionamento	estacionamento em visita ao cliente	33.97
497	79	2026-08-08	documentacao	licenciamento anual	210.25
498	74	2026-08-10	seguro	parcela do seguro	219.84
499	88	2026-08-13	pedagio	pedagio em viagem regional	80.23
500	88	2026-08-14	seguro	parcela do seguro	350.78
501	84	2026-08-18	estacionamento	estacionamento em visita ao cliente	22.91
502	77	2026-08-19	documentacao	licenciamento anual	260.32
503	80	2026-08-20	estacionamento	estacionamento em visita ao cliente	42.51
504	68	2026-08-21	lavagem	lavagem completa	97.64
505	55	2026-08-22	lavagem	lavagem completa	97.47
506	67	2026-08-22	multa	multa de transito	265.37
507	85	2026-08-23	estacionamento	estacionamento em visita ao cliente	42.81
508	83	2026-08-24	documentacao	licenciamento anual	409.05
509	52	2026-08-26	seguro	parcela do seguro	482.61
510	55	2026-08-28	documentacao	licenciamento anual	151.30
511	57	2026-08-28	pedagio	pedagio em viagem regional	42.11
512	54	2026-09-01	seguro	parcela do seguro	218.84
513	84	2026-09-01	seguro	parcela do seguro	473.61
514	85	2026-09-01	seguro	parcela do seguro	539.71
515	64	2026-09-04	estacionamento	estacionamento em visita ao cliente	34.12
516	54	2026-09-05	documentacao	taxa administrativa	123.86
517	63	2026-09-18	estacionamento	estacionamento em visita ao cliente	15.60
518	76	2026-09-21	seguro	parcela do seguro	488.80
519	68	2026-09-22	documentacao	licenciamento anual	181.79
520	53	2026-09-23	multa	multa de transito	287.07
521	90	2026-09-23	estacionamento	estacionamento em visita ao cliente	20.21
522	68	2026-09-25	documentacao	taxa administrativa	125.64
523	87	2026-09-26	documentacao	taxa administrativa	124.56
524	83	2026-09-28	lavagem	lavagem completa	95.07
525	89	2026-09-28	documentacao	licenciamento anual	355.84
526	74	2026-10-01	pedagio	pedagio em viagem regional	29.34
527	74	2026-10-03	seguro	parcela do seguro	390.83
528	76	2026-10-04	multa	multa de transito	264.38
529	90	2026-10-11	documentacao	licenciamento anual	246.17
530	54	2026-10-12	multa	multa de transito	184.61
531	79	2026-10-12	lavagem	lavagem completa	77.27
532	72	2026-10-13	documentacao	licenciamento anual	323.02
533	81	2026-10-15	documentacao	taxa administrativa	164.47
534	74	2026-10-17	documentacao	licenciamento anual	397.95
535	77	2026-10-18	seguro	parcela do seguro	380.30
536	81	2026-10-18	documentacao	licenciamento anual	394.51
537	61	2026-10-22	lavagem	lavagem completa	90.22
538	66	2026-10-22	lavagem	lavagem completa	108.55
539	51	2026-10-23	lavagem	lavagem completa	102.04
540	56	2026-10-23	documentacao	taxa administrativa	148.48
541	54	2026-10-24	pedagio	pedagio em viagem regional	93.20
542	1	2026-11-02	Pedágio	Despesa operacional registrada no lote extra 1	809.83
543	2	2026-11-01	Estacionamento	Despesa operacional registrada no lote extra 2	404.32
544	3	2026-10-31	Lavagem	Despesa operacional registrada no lote extra 3	864.91
545	4	2026-10-30	Seguro	Despesa operacional registrada no lote extra 4	1624.60
546	5	2026-10-29	Documentação	Despesa operacional registrada no lote extra 5	1437.94
547	6	2026-10-28	Taxa de licenciamento	Despesa operacional registrada no lote extra 6	326.20
548	7	2026-10-27	Transporte	Despesa operacional registrada no lote extra 7	175.51
549	8	2026-10-26	Peças e acessórios	Despesa operacional registrada no lote extra 8	939.93
550	9	2026-10-25	Pedágio	Despesa operacional registrada no lote extra 9	1148.47
551	10	2026-10-24	Estacionamento	Despesa operacional registrada no lote extra 10	619.96
552	11	2026-10-23	Lavagem	Despesa operacional registrada no lote extra 11	1477.70
553	12	2026-10-22	Seguro	Despesa operacional registrada no lote extra 12	1358.27
554	13	2026-10-21	Documentação	Despesa operacional registrada no lote extra 13	1219.21
555	14	2026-10-20	Taxa de licenciamento	Despesa operacional registrada no lote extra 14	423.74
556	15	2026-10-19	Transporte	Despesa operacional registrada no lote extra 15	378.46
557	16	2026-10-18	Peças e acessórios	Despesa operacional registrada no lote extra 16	68.36
558	17	2026-10-17	Pedágio	Despesa operacional registrada no lote extra 17	459.60
559	18	2026-10-16	Estacionamento	Despesa operacional registrada no lote extra 18	868.37
560	19	2026-10-15	Lavagem	Despesa operacional registrada no lote extra 19	1533.28
561	20	2026-10-14	Seguro	Despesa operacional registrada no lote extra 20	154.27
562	21	2026-10-13	Documentação	Despesa operacional registrada no lote extra 21	760.63
563	22	2026-10-12	Taxa de licenciamento	Despesa operacional registrada no lote extra 22	1142.83
564	23	2026-10-11	Transporte	Despesa operacional registrada no lote extra 23	370.12
565	24	2026-10-10	Peças e acessórios	Despesa operacional registrada no lote extra 24	1261.03
566	25	2026-10-09	Pedágio	Despesa operacional registrada no lote extra 25	902.52
567	26	2026-10-08	Estacionamento	Despesa operacional registrada no lote extra 26	458.07
568	27	2026-10-07	Lavagem	Despesa operacional registrada no lote extra 27	1189.50
569	28	2026-10-06	Seguro	Despesa operacional registrada no lote extra 28	34.84
570	29	2026-10-05	Documentação	Despesa operacional registrada no lote extra 29	1357.96
571	30	2026-10-04	Taxa de licenciamento	Despesa operacional registrada no lote extra 30	1391.83
572	1	2026-10-03	Transporte	Despesa operacional registrada no lote extra 31	214.19
573	2	2026-10-02	Peças e acessórios	Despesa operacional registrada no lote extra 32	779.63
574	3	2026-10-01	Pedágio	Despesa operacional registrada no lote extra 33	337.20
575	4	2026-09-30	Estacionamento	Despesa operacional registrada no lote extra 34	1725.39
576	5	2026-09-29	Lavagem	Despesa operacional registrada no lote extra 35	944.38
577	6	2026-09-28	Seguro	Despesa operacional registrada no lote extra 36	114.14
578	7	2026-09-27	Documentação	Despesa operacional registrada no lote extra 37	467.33
579	8	2026-09-26	Taxa de licenciamento	Despesa operacional registrada no lote extra 38	1530.80
580	9	2026-09-25	Transporte	Despesa operacional registrada no lote extra 39	835.22
581	10	2026-09-24	Peças e acessórios	Despesa operacional registrada no lote extra 40	1447.51
582	11	2026-09-23	Pedágio	Despesa operacional registrada no lote extra 41	1209.95
583	12	2026-09-22	Estacionamento	Despesa operacional registrada no lote extra 42	1778.51
584	13	2026-09-21	Lavagem	Despesa operacional registrada no lote extra 43	1081.93
585	14	2026-09-20	Seguro	Despesa operacional registrada no lote extra 44	1711.32
586	15	2026-09-19	Documentação	Despesa operacional registrada no lote extra 45	1607.28
587	16	2026-09-18	Taxa de licenciamento	Despesa operacional registrada no lote extra 46	1112.46
588	17	2026-09-17	Transporte	Despesa operacional registrada no lote extra 47	1301.71
589	18	2026-09-16	Peças e acessórios	Despesa operacional registrada no lote extra 48	920.98
590	19	2026-09-15	Pedágio	Despesa operacional registrada no lote extra 49	1499.26
591	20	2026-09-14	Estacionamento	Despesa operacional registrada no lote extra 50	997.47
592	21	2026-09-13	Lavagem	Despesa operacional registrada no lote extra 51	1617.54
593	22	2026-09-12	Seguro	Despesa operacional registrada no lote extra 52	1344.99
594	23	2026-09-11	Documentação	Despesa operacional registrada no lote extra 53	867.55
595	24	2026-09-10	Taxa de licenciamento	Despesa operacional registrada no lote extra 54	485.06
596	25	2026-09-09	Transporte	Despesa operacional registrada no lote extra 55	463.85
597	26	2026-09-08	Peças e acessórios	Despesa operacional registrada no lote extra 56	1156.85
598	27	2026-09-07	Pedágio	Despesa operacional registrada no lote extra 57	1384.32
599	28	2026-09-06	Estacionamento	Despesa operacional registrada no lote extra 58	950.31
600	29	2026-09-05	Lavagem	Despesa operacional registrada no lote extra 59	1137.48
601	30	2026-09-04	Seguro	Despesa operacional registrada no lote extra 60	512.41
602	1	2026-09-03	Documentação	Despesa operacional registrada no lote extra 61	162.53
603	2	2026-09-02	Taxa de licenciamento	Despesa operacional registrada no lote extra 62	532.17
604	3	2026-09-01	Transporte	Despesa operacional registrada no lote extra 63	507.29
605	4	2026-08-31	Peças e acessórios	Despesa operacional registrada no lote extra 64	592.48
606	5	2026-08-30	Pedágio	Despesa operacional registrada no lote extra 65	983.77
607	6	2026-08-29	Estacionamento	Despesa operacional registrada no lote extra 66	270.61
608	7	2026-08-28	Lavagem	Despesa operacional registrada no lote extra 67	435.49
609	8	2026-08-27	Seguro	Despesa operacional registrada no lote extra 68	1256.76
610	9	2026-08-26	Documentação	Despesa operacional registrada no lote extra 69	1278.89
611	10	2026-08-25	Taxa de licenciamento	Despesa operacional registrada no lote extra 70	139.01
612	11	2026-08-24	Transporte	Despesa operacional registrada no lote extra 71	748.49
613	12	2026-08-23	Peças e acessórios	Despesa operacional registrada no lote extra 72	988.13
614	13	2026-08-22	Pedágio	Despesa operacional registrada no lote extra 73	763.00
615	14	2026-08-21	Estacionamento	Despesa operacional registrada no lote extra 74	392.13
616	15	2026-08-20	Lavagem	Despesa operacional registrada no lote extra 75	770.75
617	16	2026-08-19	Seguro	Despesa operacional registrada no lote extra 76	1631.09
618	17	2026-08-18	Documentação	Despesa operacional registrada no lote extra 77	1061.74
619	18	2026-08-17	Taxa de licenciamento	Despesa operacional registrada no lote extra 78	1259.55
620	19	2026-08-16	Transporte	Despesa operacional registrada no lote extra 79	1545.70
621	20	2026-08-15	Peças e acessórios	Despesa operacional registrada no lote extra 80	1383.93
622	21	2026-08-14	Pedágio	Despesa operacional registrada no lote extra 81	700.18
623	22	2026-08-13	Estacionamento	Despesa operacional registrada no lote extra 82	35.47
624	23	2026-08-12	Lavagem	Despesa operacional registrada no lote extra 83	649.37
625	24	2026-08-11	Seguro	Despesa operacional registrada no lote extra 84	1362.42
626	25	2026-08-10	Documentação	Despesa operacional registrada no lote extra 85	1539.87
627	26	2026-08-09	Taxa de licenciamento	Despesa operacional registrada no lote extra 86	1717.34
628	27	2026-08-08	Transporte	Despesa operacional registrada no lote extra 87	768.76
629	28	2026-08-07	Peças e acessórios	Despesa operacional registrada no lote extra 88	1351.84
630	29	2026-08-06	Pedágio	Despesa operacional registrada no lote extra 89	994.38
631	30	2026-08-05	Estacionamento	Despesa operacional registrada no lote extra 90	1095.77
632	1	2026-08-04	Lavagem	Despesa operacional registrada no lote extra 91	416.46
633	2	2026-08-03	Seguro	Despesa operacional registrada no lote extra 92	414.47
634	3	2026-08-02	Documentação	Despesa operacional registrada no lote extra 93	798.61
635	4	2026-08-01	Taxa de licenciamento	Despesa operacional registrada no lote extra 94	76.52
636	5	2026-07-31	Transporte	Despesa operacional registrada no lote extra 95	621.63
637	6	2026-07-30	Peças e acessórios	Despesa operacional registrada no lote extra 96	1230.48
638	7	2026-07-29	Pedágio	Despesa operacional registrada no lote extra 97	742.66
639	8	2026-07-28	Estacionamento	Despesa operacional registrada no lote extra 98	317.95
640	9	2026-07-27	Lavagem	Despesa operacional registrada no lote extra 99	854.62
641	10	2026-07-26	Seguro	Despesa operacional registrada no lote extra 100	251.54
642	11	2026-07-25	Documentação	Despesa operacional registrada no lote extra 101	1129.51
643	12	2026-07-24	Taxa de licenciamento	Despesa operacional registrada no lote extra 102	72.87
644	13	2026-07-23	Transporte	Despesa operacional registrada no lote extra 103	724.39
645	14	2026-07-22	Peças e acessórios	Despesa operacional registrada no lote extra 104	1026.80
646	15	2026-07-21	Pedágio	Despesa operacional registrada no lote extra 105	73.11
647	16	2026-07-20	Estacionamento	Despesa operacional registrada no lote extra 106	1165.88
648	17	2026-07-19	Lavagem	Despesa operacional registrada no lote extra 107	265.87
649	18	2026-07-18	Seguro	Despesa operacional registrada no lote extra 108	844.51
650	19	2026-07-17	Documentação	Despesa operacional registrada no lote extra 109	114.26
651	20	2026-07-16	Taxa de licenciamento	Despesa operacional registrada no lote extra 110	697.91
652	21	2026-07-15	Transporte	Despesa operacional registrada no lote extra 111	400.70
653	22	2026-07-14	Peças e acessórios	Despesa operacional registrada no lote extra 112	605.15
654	23	2026-07-13	Pedágio	Despesa operacional registrada no lote extra 113	1376.18
655	24	2026-07-12	Estacionamento	Despesa operacional registrada no lote extra 114	697.95
656	25	2026-07-11	Lavagem	Despesa operacional registrada no lote extra 115	1359.82
657	26	2026-07-10	Seguro	Despesa operacional registrada no lote extra 116	1501.67
658	27	2026-07-09	Documentação	Despesa operacional registrada no lote extra 117	472.78
659	28	2026-07-08	Taxa de licenciamento	Despesa operacional registrada no lote extra 118	170.38
660	29	2026-07-07	Transporte	Despesa operacional registrada no lote extra 119	59.41
661	30	2026-07-06	Peças e acessórios	Despesa operacional registrada no lote extra 120	982.47
662	1	2026-07-05	Pedágio	Despesa operacional registrada no lote extra 121	1799.84
663	2	2026-07-04	Estacionamento	Despesa operacional registrada no lote extra 122	646.18
664	3	2026-07-03	Lavagem	Despesa operacional registrada no lote extra 123	1179.01
665	4	2026-07-02	Seguro	Despesa operacional registrada no lote extra 124	1411.69
666	5	2026-07-01	Documentação	Despesa operacional registrada no lote extra 125	1181.86
667	6	2026-06-30	Taxa de licenciamento	Despesa operacional registrada no lote extra 126	1363.76
668	7	2026-06-29	Transporte	Despesa operacional registrada no lote extra 127	1710.56
669	8	2026-06-28	Peças e acessórios	Despesa operacional registrada no lote extra 128	378.87
670	9	2026-06-27	Pedágio	Despesa operacional registrada no lote extra 129	61.17
671	10	2026-06-26	Estacionamento	Despesa operacional registrada no lote extra 130	295.48
672	11	2026-06-25	Lavagem	Despesa operacional registrada no lote extra 131	249.04
673	12	2026-06-24	Seguro	Despesa operacional registrada no lote extra 132	1213.29
674	13	2026-06-23	Documentação	Despesa operacional registrada no lote extra 133	1026.05
675	14	2026-06-22	Taxa de licenciamento	Despesa operacional registrada no lote extra 134	411.89
676	15	2026-06-21	Transporte	Despesa operacional registrada no lote extra 135	1266.55
677	16	2026-06-20	Peças e acessórios	Despesa operacional registrada no lote extra 136	1386.24
678	17	2026-06-19	Pedágio	Despesa operacional registrada no lote extra 137	322.83
679	18	2026-06-18	Estacionamento	Despesa operacional registrada no lote extra 138	1102.86
680	19	2026-06-17	Lavagem	Despesa operacional registrada no lote extra 139	1352.57
681	20	2026-06-16	Seguro	Despesa operacional registrada no lote extra 140	228.30
682	21	2026-06-15	Documentação	Despesa operacional registrada no lote extra 141	1479.26
683	22	2026-06-14	Taxa de licenciamento	Despesa operacional registrada no lote extra 142	1737.38
684	23	2026-06-13	Transporte	Despesa operacional registrada no lote extra 143	216.88
685	24	2026-06-12	Peças e acessórios	Despesa operacional registrada no lote extra 144	70.58
686	25	2026-06-11	Pedágio	Despesa operacional registrada no lote extra 145	578.72
687	26	2026-06-10	Estacionamento	Despesa operacional registrada no lote extra 146	1227.29
688	27	2026-06-09	Lavagem	Despesa operacional registrada no lote extra 147	1725.76
689	28	2026-06-08	Seguro	Despesa operacional registrada no lote extra 148	729.06
690	29	2026-06-07	Documentação	Despesa operacional registrada no lote extra 149	1294.15
691	30	2026-06-06	Taxa de licenciamento	Despesa operacional registrada no lote extra 150	159.89
692	1	2026-06-05	Transporte	Despesa operacional registrada no lote extra 151	1250.84
693	2	2026-06-04	Peças e acessórios	Despesa operacional registrada no lote extra 152	1138.36
694	3	2026-06-03	Pedágio	Despesa operacional registrada no lote extra 153	205.87
695	4	2026-06-02	Estacionamento	Despesa operacional registrada no lote extra 154	1396.15
696	5	2026-06-01	Lavagem	Despesa operacional registrada no lote extra 155	1534.27
697	6	2026-05-31	Seguro	Despesa operacional registrada no lote extra 156	1090.73
698	7	2026-05-30	Documentação	Despesa operacional registrada no lote extra 157	239.87
699	8	2026-05-29	Taxa de licenciamento	Despesa operacional registrada no lote extra 158	1771.32
700	9	2026-05-28	Transporte	Despesa operacional registrada no lote extra 159	1414.18
701	10	2026-05-27	Peças e acessórios	Despesa operacional registrada no lote extra 160	641.29
702	11	2026-05-26	Pedágio	Despesa operacional registrada no lote extra 161	785.37
703	12	2026-05-25	Estacionamento	Despesa operacional registrada no lote extra 162	682.76
704	13	2026-05-24	Lavagem	Despesa operacional registrada no lote extra 163	923.08
705	14	2026-05-23	Seguro	Despesa operacional registrada no lote extra 164	630.69
706	15	2026-05-22	Documentação	Despesa operacional registrada no lote extra 165	1533.00
707	16	2026-05-21	Taxa de licenciamento	Despesa operacional registrada no lote extra 166	1484.64
708	17	2026-05-20	Transporte	Despesa operacional registrada no lote extra 167	212.33
709	18	2026-05-19	Peças e acessórios	Despesa operacional registrada no lote extra 168	1730.40
710	19	2026-05-18	Pedágio	Despesa operacional registrada no lote extra 169	1153.16
711	20	2026-05-17	Estacionamento	Despesa operacional registrada no lote extra 170	1495.96
712	21	2026-05-16	Lavagem	Despesa operacional registrada no lote extra 171	1280.47
713	22	2026-05-15	Seguro	Despesa operacional registrada no lote extra 172	797.99
714	23	2026-05-14	Documentação	Despesa operacional registrada no lote extra 173	1327.49
715	24	2026-05-13	Taxa de licenciamento	Despesa operacional registrada no lote extra 174	1738.72
716	25	2026-05-12	Transporte	Despesa operacional registrada no lote extra 175	504.40
717	26	2026-05-11	Peças e acessórios	Despesa operacional registrada no lote extra 176	1459.55
718	27	2026-05-10	Pedágio	Despesa operacional registrada no lote extra 177	980.26
719	28	2026-05-09	Estacionamento	Despesa operacional registrada no lote extra 178	883.21
720	29	2026-05-08	Lavagem	Despesa operacional registrada no lote extra 179	798.14
721	30	2026-05-07	Seguro	Despesa operacional registrada no lote extra 180	1322.57
722	1	2026-05-06	Documentação	Despesa operacional registrada no lote extra 181	501.40
723	2	2026-05-05	Taxa de licenciamento	Despesa operacional registrada no lote extra 182	1536.79
724	3	2026-05-04	Transporte	Despesa operacional registrada no lote extra 183	1499.55
725	4	2026-05-03	Peças e acessórios	Despesa operacional registrada no lote extra 184	178.83
726	5	2026-05-02	Pedágio	Despesa operacional registrada no lote extra 185	1589.90
727	6	2026-05-01	Estacionamento	Despesa operacional registrada no lote extra 186	457.86
728	7	2026-04-30	Lavagem	Despesa operacional registrada no lote extra 187	849.86
729	8	2026-04-29	Seguro	Despesa operacional registrada no lote extra 188	1108.34
730	9	2026-04-28	Documentação	Despesa operacional registrada no lote extra 189	697.71
731	10	2026-04-27	Taxa de licenciamento	Despesa operacional registrada no lote extra 190	75.94
732	11	2026-04-26	Transporte	Despesa operacional registrada no lote extra 191	1535.44
733	12	2026-04-25	Peças e acessórios	Despesa operacional registrada no lote extra 192	347.77
734	13	2026-04-24	Pedágio	Despesa operacional registrada no lote extra 193	401.51
735	14	2026-04-23	Estacionamento	Despesa operacional registrada no lote extra 194	1441.15
736	15	2026-04-22	Lavagem	Despesa operacional registrada no lote extra 195	629.10
737	16	2026-04-21	Seguro	Despesa operacional registrada no lote extra 196	1587.57
738	17	2026-04-20	Documentação	Despesa operacional registrada no lote extra 197	1269.60
739	18	2026-04-19	Taxa de licenciamento	Despesa operacional registrada no lote extra 198	515.38
740	19	2026-04-18	Transporte	Despesa operacional registrada no lote extra 199	43.02
741	20	2026-04-17	Peças e acessórios	Despesa operacional registrada no lote extra 200	1707.81
742	147	2026-01-31	Pedagio	Despesa operacional para teste de frota - registro 1	335.94
743	51	2026-01-20	Estacionamento	Despesa operacional para teste de frota - registro 2	364.71
744	66	2025-02-01	Lavagem	Despesa operacional para teste de frota - registro 3	2664.28
745	156	2026-08-05	Seguro	Despesa operacional para teste de frota - registro 4	583.54
746	47	2025-11-24	Documentacao	Despesa operacional para teste de frota - registro 5	1568.86
747	133	2025-09-26	Licenciamento	Despesa operacional para teste de frota - registro 6	3862.20
748	111	2025-07-10	Pecas	Despesa operacional para teste de frota - registro 7	2135.28
749	62	2026-04-11	Transporte	Despesa operacional para teste de frota - registro 8	289.85
750	21	2025-07-16	Alimentacao em viagem	Despesa operacional para teste de frota - registro 9	2550.60
751	64	2025-01-15	Taxa operacional	Despesa operacional para teste de frota - registro 10	4212.34
752	190	2025-02-06	Pedagio	Despesa operacional para teste de frota - registro 11	2271.22
753	188	2024-07-12	Estacionamento	Despesa operacional para teste de frota - registro 12	32.29
754	29	2025-08-07	Seguro	Despesa operacional para teste de frota - registro 14	4237.24
755	137	2024-02-19	Documentacao	Despesa operacional para teste de frota - registro 15	2918.26
756	9	2025-10-14	Licenciamento	Despesa operacional para teste de frota - registro 16	1491.07
757	158	2024-10-25	Pecas	Despesa operacional para teste de frota - registro 17	976.19
758	61	2024-07-19	Transporte	Despesa operacional para teste de frota - registro 18	1624.90
759	174	2025-06-04	Alimentacao em viagem	Despesa operacional para teste de frota - registro 19	1284.38
760	186	2026-10-25	Taxa operacional	Despesa operacional para teste de frota - registro 20	3232.88
761	188	2024-07-10	Pedagio	Despesa operacional para teste de frota - registro 21	565.97
762	163	2024-03-04	Estacionamento	Despesa operacional para teste de frota - registro 22	3476.29
763	85	2026-06-16	Lavagem	Despesa operacional para teste de frota - registro 23	1387.77
764	106	2026-02-06	Seguro	Despesa operacional para teste de frota - registro 24	750.23
765	12	2026-08-05	Documentacao	Despesa operacional para teste de frota - registro 25	925.88
766	57	2026-09-26	Licenciamento	Despesa operacional para teste de frota - registro 26	3338.80
767	149	2025-04-02	Pecas	Despesa operacional para teste de frota - registro 27	50.38
768	12	2026-09-22	Transporte	Despesa operacional para teste de frota - registro 28	4132.42
769	69	2026-02-07	Alimentacao em viagem	Despesa operacional para teste de frota - registro 29	4174.26
770	137	2026-04-25	Taxa operacional	Despesa operacional para teste de frota - registro 30	2000.45
771	11	2025-10-15	Pedagio	Despesa operacional para teste de frota - registro 31	2544.75
772	165	2025-06-29	Estacionamento	Despesa operacional para teste de frota - registro 32	1373.43
773	51	2025-06-28	Lavagem	Despesa operacional para teste de frota - registro 33	3870.43
774	178	2026-05-24	Seguro	Despesa operacional para teste de frota - registro 34	2033.19
775	87	2026-07-11	Documentacao	Despesa operacional para teste de frota - registro 35	845.58
776	81	2025-12-05	Pecas	Despesa operacional para teste de frota - registro 37	2511.40
777	130	2025-10-09	Transporte	Despesa operacional para teste de frota - registro 38	4265.05
778	97	2025-10-25	Alimentacao em viagem	Despesa operacional para teste de frota - registro 39	3105.35
779	90	2024-06-01	Taxa operacional	Despesa operacional para teste de frota - registro 40	2587.05
780	76	2024-08-06	Pedagio	Despesa operacional para teste de frota - registro 41	1089.12
781	5	2025-06-17	Estacionamento	Despesa operacional para teste de frota - registro 42	3658.19
782	21	2025-10-02	Lavagem	Despesa operacional para teste de frota - registro 43	633.22
783	41	2026-09-08	Seguro	Despesa operacional para teste de frota - registro 44	4489.77
784	95	2025-06-01	Documentacao	Despesa operacional para teste de frota - registro 45	1703.80
785	76	2026-09-03	Licenciamento	Despesa operacional para teste de frota - registro 46	4433.52
786	7	2024-08-03	Transporte	Despesa operacional para teste de frota - registro 48	4157.56
787	153	2024-05-28	Alimentacao em viagem	Despesa operacional para teste de frota - registro 49	1748.36
788	53	2024-07-19	Taxa operacional	Despesa operacional para teste de frota - registro 50	2433.34
789	134	2025-11-06	Pedagio	Despesa operacional para teste de frota - registro 51	4287.49
790	21	2025-04-22	Estacionamento	Despesa operacional para teste de frota - registro 52	1351.47
791	74	2024-09-07	Lavagem	Despesa operacional para teste de frota - registro 53	2904.30
792	156	2026-04-04	Seguro	Despesa operacional para teste de frota - registro 54	2717.81
793	22	2025-02-27	Documentacao	Despesa operacional para teste de frota - registro 55	1883.15
794	8	2025-08-06	Licenciamento	Despesa operacional para teste de frota - registro 56	911.43
795	130	2024-02-23	Transporte	Despesa operacional para teste de frota - registro 58	2099.94
796	109	2026-02-14	Alimentacao em viagem	Despesa operacional para teste de frota - registro 59	1511.30
797	112	2025-11-06	Taxa operacional	Despesa operacional para teste de frota - registro 60	781.05
798	19	2024-04-02	Pedagio	Despesa operacional para teste de frota - registro 61	2262.85
799	130	2024-08-27	Estacionamento	Despesa operacional para teste de frota - registro 62	4330.63
800	102	2024-12-24	Lavagem	Despesa operacional para teste de frota - registro 63	1377.08
801	43	2026-08-18	Seguro	Despesa operacional para teste de frota - registro 64	20.68
802	50	2026-05-15	Documentacao	Despesa operacional para teste de frota - registro 65	4041.46
803	48	2024-04-24	Licenciamento	Despesa operacional para teste de frota - registro 66	2711.64
804	28	2026-01-26	Pecas	Despesa operacional para teste de frota - registro 67	3696.11
805	147	2026-07-25	Transporte	Despesa operacional para teste de frota - registro 68	87.96
806	99	2025-09-14	Alimentacao em viagem	Despesa operacional para teste de frota - registro 69	206.19
807	85	2025-09-29	Taxa operacional	Despesa operacional para teste de frota - registro 70	3731.37
808	168	2025-02-28	Estacionamento	Despesa operacional para teste de frota - registro 72	3007.57
809	140	2025-10-17	Lavagem	Despesa operacional para teste de frota - registro 73	2969.35
810	190	2024-12-26	Seguro	Despesa operacional para teste de frota - registro 74	508.64
811	124	2025-04-23	Documentacao	Despesa operacional para teste de frota - registro 75	142.62
812	58	2025-06-09	Licenciamento	Despesa operacional para teste de frota - registro 76	3965.86
813	50	2026-06-25	Pecas	Despesa operacional para teste de frota - registro 77	1032.78
814	15	2024-03-10	Transporte	Despesa operacional para teste de frota - registro 78	3882.59
815	16	2026-05-03	Alimentacao em viagem	Despesa operacional para teste de frota - registro 79	3209.95
816	44	2024-03-08	Taxa operacional	Despesa operacional para teste de frota - registro 80	2834.72
817	17	2026-08-25	Pedagio	Despesa operacional para teste de frota - registro 81	2009.44
818	175	2025-02-07	Estacionamento	Despesa operacional para teste de frota - registro 82	776.02
819	182	2025-06-08	Lavagem	Despesa operacional para teste de frota - registro 83	2342.83
820	15	2025-04-01	Seguro	Despesa operacional para teste de frota - registro 84	3003.93
821	173	2024-03-22	Documentacao	Despesa operacional para teste de frota - registro 85	2753.26
822	8	2026-04-06	Licenciamento	Despesa operacional para teste de frota - registro 86	3211.16
823	29	2024-09-12	Pecas	Despesa operacional para teste de frota - registro 87	2352.37
824	184	2025-07-12	Transporte	Despesa operacional para teste de frota - registro 88	4046.48
825	91	2026-05-25	Alimentacao em viagem	Despesa operacional para teste de frota - registro 89	3198.62
826	48	2024-10-03	Taxa operacional	Despesa operacional para teste de frota - registro 90	2155.06
827	35	2024-08-04	Pedagio	Despesa operacional para teste de frota - registro 91	3386.28
828	14	2026-06-27	Estacionamento	Despesa operacional para teste de frota - registro 92	4297.00
829	161	2025-08-09	Lavagem	Despesa operacional para teste de frota - registro 93	2826.88
830	179	2024-03-15	Documentacao	Despesa operacional para teste de frota - registro 95	4479.89
831	81	2024-12-23	Licenciamento	Despesa operacional para teste de frota - registro 96	3092.03
832	88	2025-06-02	Pecas	Despesa operacional para teste de frota - registro 97	2954.59
833	52	2025-12-31	Transporte	Despesa operacional para teste de frota - registro 98	2035.79
834	47	2025-11-12	Alimentacao em viagem	Despesa operacional para teste de frota - registro 99	4359.91
835	7	2026-04-23	Taxa operacional	Despesa operacional para teste de frota - registro 100	3246.67
836	124	2025-06-24	Pedagio	Despesa operacional para teste de frota - registro 101	229.33
837	62	2024-03-14	Estacionamento	Despesa operacional para teste de frota - registro 102	1530.26
838	86	2025-06-13	Lavagem	Despesa operacional para teste de frota - registro 103	3126.86
839	137	2024-04-21	Seguro	Despesa operacional para teste de frota - registro 104	3890.00
840	26	2024-04-30	Documentacao	Despesa operacional para teste de frota - registro 105	1319.06
841	45	2026-06-18	Licenciamento	Despesa operacional para teste de frota - registro 106	4086.06
842	36	2026-03-15	Pecas	Despesa operacional para teste de frota - registro 107	2718.38
843	140	2024-11-27	Transporte	Despesa operacional para teste de frota - registro 108	3522.84
844	66	2024-07-08	Alimentacao em viagem	Despesa operacional para teste de frota - registro 109	1339.49
845	60	2026-03-08	Taxa operacional	Despesa operacional para teste de frota - registro 110	3253.81
846	154	2024-06-05	Pedagio	Despesa operacional para teste de frota - registro 111	709.15
847	47	2024-04-05	Estacionamento	Despesa operacional para teste de frota - registro 112	144.32
848	130	2024-12-05	Lavagem	Despesa operacional para teste de frota - registro 113	4043.48
849	166	2024-09-11	Seguro	Despesa operacional para teste de frota - registro 114	3393.30
850	5	2026-10-08	Documentacao	Despesa operacional para teste de frota - registro 115	1122.04
851	49	2025-04-01	Licenciamento	Despesa operacional para teste de frota - registro 116	2639.41
852	113	2026-05-28	Pecas	Despesa operacional para teste de frota - registro 117	845.62
853	65	2025-01-16	Transporte	Despesa operacional para teste de frota - registro 118	2685.00
854	10	2026-10-31	Alimentacao em viagem	Despesa operacional para teste de frota - registro 119	3992.20
855	125	2026-01-31	Estacionamento	Despesa operacional para teste de frota - registro 122	436.90
856	8	2026-09-09	Lavagem	Despesa operacional para teste de frota - registro 123	1355.43
857	13	2024-03-10	Seguro	Despesa operacional para teste de frota - registro 124	163.42
858	136	2025-01-18	Documentacao	Despesa operacional para teste de frota - registro 125	672.03
859	186	2025-01-17	Licenciamento	Despesa operacional para teste de frota - registro 126	2274.22
860	123	2025-10-13	Pecas	Despesa operacional para teste de frota - registro 127	4131.59
861	172	2025-11-20	Transporte	Despesa operacional para teste de frota - registro 128	4182.88
862	74	2024-04-29	Alimentacao em viagem	Despesa operacional para teste de frota - registro 129	1430.24
863	62	2025-08-19	Taxa operacional	Despesa operacional para teste de frota - registro 130	4223.81
864	102	2025-06-16	Pedagio	Despesa operacional para teste de frota - registro 131	2115.31
865	101	2025-04-20	Estacionamento	Despesa operacional para teste de frota - registro 132	4153.87
866	116	2025-04-17	Lavagem	Despesa operacional para teste de frota - registro 133	4315.67
867	40	2025-06-29	Seguro	Despesa operacional para teste de frota - registro 134	1819.50
868	26	2024-08-30	Documentacao	Despesa operacional para teste de frota - registro 135	2362.93
869	78	2024-08-27	Licenciamento	Despesa operacional para teste de frota - registro 136	3044.05
870	142	2025-04-30	Pecas	Despesa operacional para teste de frota - registro 137	3109.19
871	138	2026-02-16	Transporte	Despesa operacional para teste de frota - registro 138	4469.35
872	143	2024-06-25	Alimentacao em viagem	Despesa operacional para teste de frota - registro 139	2492.75
873	7	2025-09-16	Taxa operacional	Despesa operacional para teste de frota - registro 140	3629.10
874	188	2026-04-16	Pedagio	Despesa operacional para teste de frota - registro 141	2293.54
875	181	2024-10-30	Estacionamento	Despesa operacional para teste de frota - registro 142	1084.17
876	66	2024-05-04	Lavagem	Despesa operacional para teste de frota - registro 143	3182.51
877	149	2026-09-08	Seguro	Despesa operacional para teste de frota - registro 144	4481.14
878	136	2024-08-08	Documentacao	Despesa operacional para teste de frota - registro 145	1777.82
879	185	2025-04-13	Licenciamento	Despesa operacional para teste de frota - registro 146	2177.81
880	9	2025-09-14	Pecas	Despesa operacional para teste de frota - registro 147	2831.81
881	181	2025-01-16	Transporte	Despesa operacional para teste de frota - registro 148	1450.92
882	117	2026-03-24	Alimentacao em viagem	Despesa operacional para teste de frota - registro 149	2913.33
883	29	2025-03-16	Taxa operacional	Despesa operacional para teste de frota - registro 150	626.65
884	118	2024-11-21	Pedagio	Despesa operacional para teste de frota - registro 151	2497.25
885	130	2024-09-18	Estacionamento	Despesa operacional para teste de frota - registro 152	4219.32
886	21	2026-02-19	Lavagem	Despesa operacional para teste de frota - registro 153	2148.56
887	13	2024-03-04	Seguro	Despesa operacional para teste de frota - registro 154	3673.56
888	189	2024-09-16	Documentacao	Despesa operacional para teste de frota - registro 155	3796.27
889	26	2024-10-12	Licenciamento	Despesa operacional para teste de frota - registro 156	1430.20
890	173	2025-10-01	Pecas	Despesa operacional para teste de frota - registro 157	839.43
891	24	2025-05-22	Transporte	Despesa operacional para teste de frota - registro 158	848.90
892	159	2024-02-14	Alimentacao em viagem	Despesa operacional para teste de frota - registro 159	1498.04
893	161	2024-12-27	Taxa operacional	Despesa operacional para teste de frota - registro 160	1383.53
894	79	2025-10-02	Pedagio	Despesa operacional para teste de frota - registro 161	3940.72
895	50	2026-10-21	Estacionamento	Despesa operacional para teste de frota - registro 162	2219.54
896	113	2026-08-21	Lavagem	Despesa operacional para teste de frota - registro 163	850.54
897	47	2024-07-15	Documentacao	Despesa operacional para teste de frota - registro 165	3314.28
898	127	2026-06-10	Licenciamento	Despesa operacional para teste de frota - registro 166	4204.55
899	20	2025-04-12	Pecas	Despesa operacional para teste de frota - registro 167	4161.99
900	88	2026-07-09	Transporte	Despesa operacional para teste de frota - registro 168	646.81
901	7	2026-03-07	Alimentacao em viagem	Despesa operacional para teste de frota - registro 169	919.97
902	158	2025-12-03	Taxa operacional	Despesa operacional para teste de frota - registro 170	2200.26
903	177	2026-05-24	Pedagio	Despesa operacional para teste de frota - registro 171	701.66
904	87	2024-08-22	Estacionamento	Despesa operacional para teste de frota - registro 172	2467.29
905	137	2025-01-01	Lavagem	Despesa operacional para teste de frota - registro 173	2002.71
906	104	2024-08-25	Seguro	Despesa operacional para teste de frota - registro 174	4154.24
907	106	2026-06-19	Documentacao	Despesa operacional para teste de frota - registro 175	3139.21
908	77	2025-01-23	Licenciamento	Despesa operacional para teste de frota - registro 176	689.21
909	32	2026-10-04	Pecas	Despesa operacional para teste de frota - registro 177	3101.19
910	146	2026-07-24	Transporte	Despesa operacional para teste de frota - registro 178	3377.24
911	66	2025-07-06	Alimentacao em viagem	Despesa operacional para teste de frota - registro 179	2391.11
912	176	2024-05-21	Taxa operacional	Despesa operacional para teste de frota - registro 180	2564.33
913	122	2026-08-27	Pedagio	Despesa operacional para teste de frota - registro 181	409.88
914	28	2026-06-20	Estacionamento	Despesa operacional para teste de frota - registro 182	2496.93
915	91	2025-07-22	Lavagem	Despesa operacional para teste de frota - registro 183	3127.27
916	147	2026-06-02	Seguro	Despesa operacional para teste de frota - registro 184	4468.85
917	84	2025-05-30	Documentacao	Despesa operacional para teste de frota - registro 185	1833.71
918	46	2026-09-09	Licenciamento	Despesa operacional para teste de frota - registro 186	2986.35
919	155	2026-01-04	Pecas	Despesa operacional para teste de frota - registro 187	754.09
920	81	2024-09-16	Transporte	Despesa operacional para teste de frota - registro 188	2428.81
921	114	2025-02-21	Alimentacao em viagem	Despesa operacional para teste de frota - registro 189	1823.75
922	135	2026-06-29	Taxa operacional	Despesa operacional para teste de frota - registro 190	3435.47
923	140	2026-05-25	Pedagio	Despesa operacional para teste de frota - registro 191	1619.80
924	114	2026-01-31	Estacionamento	Despesa operacional para teste de frota - registro 192	78.06
925	131	2026-06-10	Lavagem	Despesa operacional para teste de frota - registro 193	1122.33
926	110	2025-12-19	Seguro	Despesa operacional para teste de frota - registro 194	585.49
927	118	2025-10-04	Documentacao	Despesa operacional para teste de frota - registro 195	91.91
928	9	2025-12-13	Licenciamento	Despesa operacional para teste de frota - registro 196	4184.08
929	57	2026-10-01	Pecas	Despesa operacional para teste de frota - registro 197	4077.19
930	190	2026-09-08	Transporte	Despesa operacional para teste de frota - registro 198	295.53
931	166	2024-12-28	Alimentacao em viagem	Despesa operacional para teste de frota - registro 199	1632.16
932	176	2024-08-07	Taxa operacional	Despesa operacional para teste de frota - registro 200	3885.10
933	71	2024-04-20	Pedagio	Despesa operacional para teste de frota - registro 201	1311.74
934	63	2026-04-19	Estacionamento	Despesa operacional para teste de frota - registro 202	682.21
935	135	2026-09-23	Lavagem	Despesa operacional para teste de frota - registro 203	3519.77
936	111	2026-03-15	Seguro	Despesa operacional para teste de frota - registro 204	3904.95
937	13	2025-04-11	Documentacao	Despesa operacional para teste de frota - registro 205	1451.38
938	26	2024-09-13	Licenciamento	Despesa operacional para teste de frota - registro 206	1823.13
939	44	2024-05-21	Pecas	Despesa operacional para teste de frota - registro 207	892.32
940	166	2026-09-16	Alimentacao em viagem	Despesa operacional para teste de frota - registro 209	195.19
941	182	2025-06-30	Taxa operacional	Despesa operacional para teste de frota - registro 210	2673.87
942	17	2025-06-11	Pedagio	Despesa operacional para teste de frota - registro 211	3824.68
943	179	2025-09-06	Estacionamento	Despesa operacional para teste de frota - registro 212	1856.94
944	178	2025-11-22	Lavagem	Despesa operacional para teste de frota - registro 213	3807.82
945	29	2024-07-30	Seguro	Despesa operacional para teste de frota - registro 214	2474.01
946	36	2025-10-08	Documentacao	Despesa operacional para teste de frota - registro 215	3291.08
947	71	2025-12-05	Licenciamento	Despesa operacional para teste de frota - registro 216	2472.82
948	118	2025-02-24	Pecas	Despesa operacional para teste de frota - registro 217	2660.49
949	96	2026-05-29	Transporte	Despesa operacional para teste de frota - registro 218	819.39
950	55	2026-04-16	Alimentacao em viagem	Despesa operacional para teste de frota - registro 219	2600.39
951	90	2024-04-24	Taxa operacional	Despesa operacional para teste de frota - registro 220	322.52
952	110	2024-05-16	Pedagio	Despesa operacional para teste de frota - registro 221	1783.10
953	106	2025-09-28	Estacionamento	Despesa operacional para teste de frota - registro 222	2065.21
954	137	2025-12-20	Lavagem	Despesa operacional para teste de frota - registro 223	2485.22
955	58	2024-04-23	Seguro	Despesa operacional para teste de frota - registro 224	1363.30
956	15	2024-03-02	Documentacao	Despesa operacional para teste de frota - registro 225	3770.43
957	172	2025-11-27	Licenciamento	Despesa operacional para teste de frota - registro 226	2916.95
958	146	2025-03-31	Pecas	Despesa operacional para teste de frota - registro 227	3319.73
959	118	2025-12-03	Transporte	Despesa operacional para teste de frota - registro 228	793.01
960	80	2024-09-12	Alimentacao em viagem	Despesa operacional para teste de frota - registro 229	3072.85
961	105	2025-08-04	Taxa operacional	Despesa operacional para teste de frota - registro 230	1970.70
962	167	2026-06-16	Pedagio	Despesa operacional para teste de frota - registro 231	2442.26
963	17	2025-05-14	Estacionamento	Despesa operacional para teste de frota - registro 232	3070.54
964	101	2025-04-28	Lavagem	Despesa operacional para teste de frota - registro 233	2602.13
965	143	2026-02-17	Seguro	Despesa operacional para teste de frota - registro 234	256.78
966	125	2024-05-08	Documentacao	Despesa operacional para teste de frota - registro 235	43.01
967	65	2024-09-10	Licenciamento	Despesa operacional para teste de frota - registro 236	243.06
968	159	2026-05-12	Pecas	Despesa operacional para teste de frota - registro 237	303.44
969	11	2026-09-28	Transporte	Despesa operacional para teste de frota - registro 238	2427.46
970	40	2025-03-24	Alimentacao em viagem	Despesa operacional para teste de frota - registro 239	1723.24
971	40	2025-11-02	Taxa operacional	Despesa operacional para teste de frota - registro 240	893.54
972	56	2025-03-08	Pedagio	Despesa operacional para teste de frota - registro 241	1935.88
973	14	2024-09-04	Estacionamento	Despesa operacional para teste de frota - registro 242	307.69
974	50	2026-01-14	Lavagem	Despesa operacional para teste de frota - registro 243	432.51
975	20	2024-08-07	Seguro	Despesa operacional para teste de frota - registro 244	3410.04
976	134	2025-06-12	Documentacao	Despesa operacional para teste de frota - registro 245	4486.68
977	36	2024-12-21	Licenciamento	Despesa operacional para teste de frota - registro 246	1853.01
978	91	2025-05-17	Transporte	Despesa operacional para teste de frota - registro 248	1062.03
979	166	2026-10-16	Alimentacao em viagem	Despesa operacional para teste de frota - registro 249	614.37
980	59	2025-09-29	Taxa operacional	Despesa operacional para teste de frota - registro 250	468.33
981	70	2024-05-18	Pedagio	Despesa operacional para teste de frota - registro 251	1188.14
982	56	2026-04-15	Estacionamento	Despesa operacional para teste de frota - registro 252	3891.71
983	147	2026-10-02	Lavagem	Despesa operacional para teste de frota - registro 253	3733.45
984	115	2024-05-28	Documentacao	Despesa operacional para teste de frota - registro 255	2549.46
985	40	2026-04-17	Licenciamento	Despesa operacional para teste de frota - registro 256	1802.89
986	113	2024-08-31	Pecas	Despesa operacional para teste de frota - registro 257	3182.29
987	188	2024-05-16	Transporte	Despesa operacional para teste de frota - registro 258	2647.62
988	41	2024-10-14	Alimentacao em viagem	Despesa operacional para teste de frota - registro 259	182.55
989	36	2025-11-18	Taxa operacional	Despesa operacional para teste de frota - registro 260	2099.64
990	125	2024-10-15	Pedagio	Despesa operacional para teste de frota - registro 261	555.08
991	28	2026-06-09	Estacionamento	Despesa operacional para teste de frota - registro 262	813.58
992	16	2024-07-20	Lavagem	Despesa operacional para teste de frota - registro 263	2937.53
993	132	2025-03-12	Seguro	Despesa operacional para teste de frota - registro 264	3327.85
994	104	2024-09-21	Licenciamento	Despesa operacional para teste de frota - registro 266	2600.99
995	122	2025-03-19	Pecas	Despesa operacional para teste de frota - registro 267	2712.25
996	165	2024-07-31	Transporte	Despesa operacional para teste de frota - registro 268	1310.14
997	26	2026-07-22	Alimentacao em viagem	Despesa operacional para teste de frota - registro 269	4286.86
998	58	2025-01-06	Taxa operacional	Despesa operacional para teste de frota - registro 270	4251.96
999	171	2024-07-24	Pedagio	Despesa operacional para teste de frota - registro 271	1152.40
1000	54	2026-09-20	Estacionamento	Despesa operacional para teste de frota - registro 272	4171.20
1001	58	2025-09-21	Lavagem	Despesa operacional para teste de frota - registro 273	1186.11
1002	60	2024-09-21	Seguro	Despesa operacional para teste de frota - registro 274	4182.58
1003	85	2026-03-07	Documentacao	Despesa operacional para teste de frota - registro 275	3581.39
1004	170	2026-09-04	Licenciamento	Despesa operacional para teste de frota - registro 276	2183.13
1005	87	2024-06-01	Pecas	Despesa operacional para teste de frota - registro 277	2629.07
1006	134	2026-05-17	Alimentacao em viagem	Despesa operacional para teste de frota - registro 279	4423.31
1007	187	2025-05-06	Taxa operacional	Despesa operacional para teste de frota - registro 280	3754.74
1008	103	2025-08-29	Pedagio	Despesa operacional para teste de frota - registro 281	3523.28
1009	154	2026-09-06	Estacionamento	Despesa operacional para teste de frota - registro 282	3657.56
1010	168	2025-06-09	Lavagem	Despesa operacional para teste de frota - registro 283	2325.22
1011	179	2024-05-12	Seguro	Despesa operacional para teste de frota - registro 284	2031.60
1012	91	2024-06-14	Documentacao	Despesa operacional para teste de frota - registro 285	3886.60
1013	116	2026-04-05	Licenciamento	Despesa operacional para teste de frota - registro 286	2201.27
1014	185	2026-02-21	Pecas	Despesa operacional para teste de frota - registro 287	2622.05
1015	25	2025-10-24	Transporte	Despesa operacional para teste de frota - registro 288	612.45
1016	82	2025-01-25	Alimentacao em viagem	Despesa operacional para teste de frota - registro 289	1553.24
1017	68	2024-11-14	Taxa operacional	Despesa operacional para teste de frota - registro 290	982.41
1018	146	2025-10-12	Pedagio	Despesa operacional para teste de frota - registro 291	920.57
1019	77	2024-09-25	Estacionamento	Despesa operacional para teste de frota - registro 292	3657.76
1020	178	2024-09-30	Lavagem	Despesa operacional para teste de frota - registro 293	3816.95
1021	1	2024-03-21	Seguro	Despesa operacional para teste de frota - registro 294	647.50
1022	71	2025-04-18	Documentacao	Despesa operacional para teste de frota - registro 295	1549.02
1023	5	2024-07-29	Licenciamento	Despesa operacional para teste de frota - registro 296	3110.70
1024	14	2024-09-15	Pecas	Despesa operacional para teste de frota - registro 297	1023.19
1025	149	2026-02-24	Transporte	Despesa operacional para teste de frota - registro 298	2244.44
1026	105	2025-12-07	Alimentacao em viagem	Despesa operacional para teste de frota - registro 299	340.23
1027	120	2026-05-01	Taxa operacional	Despesa operacional para teste de frota - registro 300	777.57
\.


--
-- TOC entry 3627 (class 0 OID 65539)
-- Dependencies: 241
-- Data for Name: historico_status_veiculo; Type: TABLE DATA; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

COPY gabriel_trabalho_bd.historico_status_veiculo (id_historico, id_veiculo, status_anterior, status_novo, data_alteracao) FROM stdin;
5	11	ativo	em_viagem	2026-10-29 23:10:51.451432
6	31	ativo	em_manutencao	2026-11-03 12:54:44.375243
7	36	ativo	em_manutencao	2026-11-03 12:54:44.375243
8	40	ativo	inativo	2026-11-03 12:54:44.375243
9	51	ativo	em_manutencao	2026-11-03 12:59:39.989503
10	56	ativo	em_manutencao	2026-11-03 12:59:39.989503
11	73	ativo	em_manutencao	2026-11-03 12:59:39.989503
12	70	ativo	inativo	2026-11-03 12:59:39.989503
13	90	ativo	inativo	2026-11-03 12:59:39.989503
14	1	ativo	em_manutencao	2026-11-02 13:03:24.855367
15	2	em_manutencao	ativo	2026-11-01 13:03:24.855367
16	3	ativo	inativo	2026-10-31 13:03:24.855367
17	4	inativo	ativo	2026-10-30 13:03:24.855367
18	5	ativo	em_viagem	2026-10-29 13:03:24.855367
19	6	em_viagem	ativo	2026-10-28 13:03:24.855367
20	7	ativo	em_manutencao	2026-10-27 13:03:24.855367
21	8	em_manutencao	ativo	2026-10-26 13:03:24.855367
22	9	ativo	inativo	2026-10-25 13:03:24.855367
23	10	inativo	ativo	2026-10-24 13:03:24.855367
24	11	ativo	em_viagem	2026-10-23 13:03:24.855367
25	12	em_viagem	ativo	2026-10-22 13:03:24.855367
26	13	ativo	em_manutencao	2026-10-21 13:03:24.855367
27	14	em_manutencao	ativo	2026-10-20 13:03:24.855367
28	15	ativo	inativo	2026-10-19 13:03:24.855367
29	16	inativo	ativo	2026-10-18 13:03:24.855367
30	17	ativo	em_viagem	2026-10-17 13:03:24.855367
31	18	em_viagem	ativo	2026-10-16 13:03:24.855367
32	19	ativo	em_manutencao	2026-10-15 13:03:24.855367
33	20	em_manutencao	ativo	2026-10-14 13:03:24.855367
34	21	ativo	inativo	2026-10-13 13:03:24.855367
35	22	inativo	ativo	2026-10-12 13:03:24.855367
36	23	ativo	em_viagem	2026-10-11 13:03:24.855367
37	24	em_viagem	ativo	2026-10-10 13:03:24.855367
38	25	ativo	em_manutencao	2026-10-09 13:03:24.855367
39	26	em_manutencao	ativo	2026-10-08 13:03:24.855367
40	27	ativo	inativo	2026-10-07 13:03:24.855367
41	28	inativo	ativo	2026-10-06 13:03:24.855367
42	29	ativo	em_viagem	2026-10-05 13:03:24.855367
43	30	em_viagem	ativo	2026-10-04 13:03:24.855367
44	1	ativo	em_manutencao	2026-10-03 13:03:24.855367
45	2	em_manutencao	ativo	2026-10-02 13:03:24.855367
46	3	ativo	inativo	2026-10-01 13:03:24.855367
47	4	inativo	ativo	2026-09-30 13:03:24.855367
48	5	ativo	em_viagem	2026-09-29 13:03:24.855367
49	6	em_viagem	ativo	2026-09-28 13:03:24.855367
50	7	ativo	em_manutencao	2026-09-27 13:03:24.855367
51	8	em_manutencao	ativo	2026-09-26 13:03:24.855367
52	9	ativo	inativo	2026-09-25 13:03:24.855367
53	10	inativo	ativo	2026-09-24 13:03:24.855367
54	11	ativo	em_viagem	2026-09-23 13:03:24.855367
55	12	em_viagem	ativo	2026-09-22 13:03:24.855367
56	13	ativo	em_manutencao	2026-09-21 13:03:24.855367
57	14	em_manutencao	ativo	2026-09-20 13:03:24.855367
58	15	ativo	inativo	2026-09-19 13:03:24.855367
59	16	inativo	ativo	2026-09-18 13:03:24.855367
60	17	ativo	em_viagem	2026-09-17 13:03:24.855367
61	18	em_viagem	ativo	2026-09-16 13:03:24.855367
62	19	ativo	em_manutencao	2026-09-15 13:03:24.855367
63	20	em_manutencao	ativo	2026-09-14 13:03:24.855367
64	21	ativo	inativo	2026-09-13 13:03:24.855367
65	22	inativo	ativo	2026-09-12 13:03:24.855367
66	23	ativo	em_viagem	2026-09-11 13:03:24.855367
67	24	em_viagem	ativo	2026-09-10 13:03:24.855367
68	25	ativo	em_manutencao	2026-09-09 13:03:24.855367
69	26	em_manutencao	ativo	2026-09-08 13:03:24.855367
70	27	ativo	inativo	2026-09-07 13:03:24.855367
71	28	inativo	ativo	2026-09-06 13:03:24.855367
72	29	ativo	em_viagem	2026-09-05 13:03:24.855367
73	30	em_viagem	ativo	2026-09-04 13:03:24.855367
74	1	ativo	em_manutencao	2026-09-03 13:03:24.855367
75	2	em_manutencao	ativo	2026-09-02 13:03:24.855367
76	3	ativo	inativo	2026-09-01 13:03:24.855367
77	4	inativo	ativo	2026-08-31 13:03:24.855367
78	5	ativo	em_viagem	2026-08-30 13:03:24.855367
79	6	em_viagem	ativo	2026-08-29 13:03:24.855367
80	7	ativo	em_manutencao	2026-08-28 13:03:24.855367
81	8	em_manutencao	ativo	2026-08-27 13:03:24.855367
82	9	ativo	inativo	2026-08-26 13:03:24.855367
83	10	inativo	ativo	2026-08-25 13:03:24.855367
84	11	ativo	em_viagem	2026-08-24 13:03:24.855367
85	12	em_viagem	ativo	2026-08-23 13:03:24.855367
86	13	ativo	em_manutencao	2026-08-22 13:03:24.855367
87	14	em_manutencao	ativo	2026-08-21 13:03:24.855367
88	15	ativo	inativo	2026-08-20 13:03:24.855367
89	16	inativo	ativo	2026-08-19 13:03:24.855367
90	17	ativo	em_viagem	2026-08-18 13:03:24.855367
91	18	em_viagem	ativo	2026-08-17 13:03:24.855367
92	19	ativo	em_manutencao	2026-08-16 13:03:24.855367
93	20	em_manutencao	ativo	2026-08-15 13:03:24.855367
94	21	ativo	inativo	2026-08-14 13:03:24.855367
95	22	inativo	ativo	2026-08-13 13:03:24.855367
96	23	ativo	em_viagem	2026-08-12 13:03:24.855367
97	24	em_viagem	ativo	2026-08-11 13:03:24.855367
98	25	ativo	em_manutencao	2026-08-10 13:03:24.855367
99	26	em_manutencao	ativo	2026-08-09 13:03:24.855367
100	27	ativo	inativo	2026-08-08 13:03:24.855367
101	28	inativo	ativo	2026-08-07 13:03:24.855367
102	29	ativo	em_viagem	2026-08-06 13:03:24.855367
103	30	em_viagem	ativo	2026-08-05 13:03:24.855367
104	1	ativo	em_manutencao	2026-08-04 13:03:24.855367
105	2	em_manutencao	ativo	2026-08-03 13:03:24.855367
106	3	ativo	inativo	2026-08-02 13:03:24.855367
107	4	inativo	ativo	2026-08-01 13:03:24.855367
108	5	ativo	em_viagem	2026-07-31 13:03:24.855367
109	6	em_viagem	ativo	2026-07-30 13:03:24.855367
110	7	ativo	em_manutencao	2026-07-29 13:03:24.855367
111	8	em_manutencao	ativo	2026-07-28 13:03:24.855367
112	9	ativo	inativo	2026-07-27 13:03:24.855367
113	10	inativo	ativo	2026-07-26 13:03:24.855367
114	28	ativo	em_viagem	2025-11-08 13:04:55.097711
115	170	em_viagem	ativo	2025-05-05 13:04:55.097711
116	21	ativo	em_manutencao	2025-09-05 13:04:55.097711
117	143	em_manutencao	ativo	2024-05-26 13:04:55.097711
118	51	ativo	inativo	2025-08-09 13:04:55.097711
119	62	inativo	ativo	2024-09-13 13:04:55.097711
120	139	ativo	em_viagem	2026-04-09 13:04:55.097711
121	117	em_viagem	ativo	2025-06-26 13:04:55.097711
122	50	ativo	em_manutencao	2025-06-15 13:04:55.097711
123	56	em_manutencao	ativo	2025-08-07 13:04:55.097711
124	26	ativo	inativo	2026-06-10 13:04:55.097711
125	160	inativo	ativo	2025-02-28 13:04:55.097711
126	60	ativo	em_viagem	2026-06-29 13:04:55.097711
127	63	em_viagem	ativo	2025-05-20 13:04:55.097711
128	79	ativo	em_manutencao	2026-02-28 13:04:55.097711
129	175	em_manutencao	ativo	2026-02-19 13:04:55.097711
130	92	ativo	inativo	2026-05-03 13:04:55.097711
131	133	inativo	ativo	2025-08-07 13:04:55.097711
132	118	ativo	em_viagem	2025-04-20 13:04:55.097711
133	24	em_viagem	ativo	2024-11-09 13:04:55.097711
134	160	ativo	em_manutencao	2024-06-25 13:04:55.097711
135	47	em_manutencao	ativo	2025-11-08 13:04:55.097711
136	51	ativo	inativo	2026-03-24 13:04:55.097711
137	94	inativo	ativo	2024-07-17 13:04:55.097711
138	113	ativo	em_viagem	2024-04-05 13:04:55.097711
139	7	em_viagem	ativo	2024-04-27 13:04:55.097711
140	69	ativo	em_manutencao	2024-05-21 13:04:55.097711
141	45	em_manutencao	ativo	2026-01-10 13:04:55.097711
142	130	ativo	inativo	2024-08-02 13:04:55.097711
143	68	inativo	ativo	2025-10-10 13:04:55.097711
144	93	ativo	em_viagem	2026-01-02 13:04:55.097711
145	122	em_viagem	ativo	2026-03-01 13:04:55.097711
146	167	ativo	em_manutencao	2024-08-24 13:04:55.097711
147	55	em_manutencao	ativo	2026-02-10 13:04:55.097711
148	130	inativo	ativo	2026-07-25 13:04:55.097711
149	166	ativo	em_viagem	2025-10-21 13:04:55.097711
150	112	em_viagem	ativo	2024-02-14 13:04:55.097711
151	32	ativo	em_manutencao	2025-02-13 13:04:55.097711
152	183	em_manutencao	ativo	2024-02-17 13:04:55.097711
153	148	ativo	inativo	2024-03-03 13:04:55.097711
154	77	inativo	ativo	2026-09-04 13:04:55.097711
155	183	ativo	em_viagem	2024-02-12 13:04:55.097711
156	106	em_viagem	ativo	2025-10-12 13:04:55.097711
157	175	ativo	em_manutencao	2024-03-25 13:04:55.097711
158	157	em_manutencao	ativo	2024-05-18 13:04:55.097711
159	140	ativo	inativo	2025-07-01 13:04:55.097711
160	44	inativo	ativo	2024-08-12 13:04:55.097711
161	74	ativo	em_viagem	2026-03-21 13:04:55.097711
162	105	em_viagem	ativo	2024-09-07 13:04:55.097711
163	177	ativo	em_manutencao	2025-03-02 13:04:55.097711
164	15	em_manutencao	ativo	2024-09-18 13:04:55.097711
165	28	ativo	inativo	2025-11-10 13:04:55.097711
166	98	inativo	ativo	2024-11-24 13:04:55.097711
167	169	ativo	em_viagem	2024-04-29 13:04:55.097711
168	190	em_viagem	ativo	2026-10-16 13:04:55.097711
169	140	ativo	em_manutencao	2024-09-04 13:04:55.097711
170	167	em_manutencao	ativo	2025-05-30 13:04:55.097711
171	124	ativo	inativo	2026-01-06 13:04:55.097711
172	161	ativo	em_viagem	2025-03-25 13:04:55.097711
173	155	em_viagem	ativo	2025-11-02 13:04:55.097711
174	111	ativo	em_manutencao	2024-05-04 13:04:55.097711
175	42	em_manutencao	ativo	2024-10-21 13:04:55.097711
176	75	ativo	inativo	2026-07-28 13:04:55.097711
177	116	inativo	ativo	2026-01-06 13:04:55.097711
178	134	ativo	em_viagem	2024-10-13 13:04:55.097711
179	171	em_viagem	ativo	2026-04-13 13:04:55.097711
180	147	ativo	em_manutencao	2024-10-16 13:04:55.097711
181	166	em_manutencao	ativo	2026-02-26 13:04:55.097711
182	93	ativo	inativo	2026-06-05 13:04:55.097711
183	54	inativo	ativo	2024-03-16 13:04:55.097711
184	91	ativo	em_viagem	2025-04-27 13:04:55.097711
185	67	em_viagem	ativo	2026-05-03 13:04:55.097711
186	110	ativo	em_manutencao	2025-05-09 13:04:55.097711
187	168	em_manutencao	ativo	2025-11-22 13:04:55.097711
188	94	ativo	inativo	2026-10-30 13:04:55.097711
189	52	inativo	ativo	2024-02-26 13:04:55.097711
190	160	ativo	em_viagem	2024-12-31 13:04:55.097711
191	110	em_viagem	ativo	2024-05-15 13:04:55.097711
192	149	ativo	em_manutencao	2026-10-14 13:04:55.097711
193	82	em_manutencao	ativo	2025-07-07 13:04:55.097711
194	88	ativo	inativo	2024-04-12 13:04:55.097711
195	128	inativo	ativo	2026-06-03 13:04:55.097711
196	133	ativo	em_viagem	2024-10-10 13:04:55.097711
197	157	em_viagem	ativo	2025-08-11 13:04:55.097711
198	132	ativo	em_manutencao	2026-10-02 13:04:55.097711
199	133	em_manutencao	ativo	2024-03-28 13:04:55.097711
200	87	ativo	inativo	2024-11-18 13:04:55.097711
201	70	inativo	ativo	2026-04-01 13:04:55.097711
202	190	em_viagem	ativo	2026-03-24 13:04:55.097711
203	146	ativo	em_manutencao	2026-08-20 13:04:55.097711
204	90	em_manutencao	ativo	2026-02-27 13:04:55.097711
205	86	ativo	inativo	2025-09-24 13:04:55.097711
206	144	inativo	ativo	2026-05-31 13:04:55.097711
207	47	ativo	em_viagem	2025-08-15 13:04:55.097711
208	185	em_viagem	ativo	2024-07-26 13:04:55.097711
209	149	em_manutencao	ativo	2024-09-13 13:04:55.097711
210	185	ativo	inativo	2025-03-06 13:04:55.097711
211	104	inativo	ativo	2026-05-05 13:04:55.097711
212	88	ativo	em_viagem	2024-09-23 13:04:55.097711
213	121	ativo	em_manutencao	2025-10-01 13:04:55.097711
214	169	em_manutencao	ativo	2026-10-07 13:04:55.097711
215	174	ativo	inativo	2025-08-07 13:04:55.097711
216	6	inativo	ativo	2025-08-22 13:04:55.097711
217	149	ativo	em_viagem	2024-08-26 13:04:55.097711
218	51	em_viagem	ativo	2025-07-03 13:04:55.097711
219	152	ativo	em_manutencao	2025-07-22 13:04:55.097711
220	141	em_manutencao	ativo	2025-03-30 13:04:55.097711
221	38	ativo	inativo	2026-10-12 13:04:55.097711
222	99	inativo	ativo	2026-04-27 13:04:55.097711
223	41	ativo	em_viagem	2026-03-08 13:04:55.097711
224	115	em_viagem	ativo	2026-09-01 13:04:55.097711
225	166	ativo	em_manutencao	2024-05-28 13:04:55.097711
226	112	em_manutencao	ativo	2025-07-20 13:04:55.097711
227	78	ativo	inativo	2024-11-20 13:04:55.097711
228	76	inativo	ativo	2026-10-17 13:04:55.097711
229	114	ativo	em_viagem	2024-10-16 13:04:55.097711
230	56	em_viagem	ativo	2025-08-07 13:04:55.097711
231	149	ativo	em_manutencao	2026-06-16 13:04:55.097711
232	61	em_manutencao	ativo	2025-07-22 13:04:55.097711
233	114	ativo	inativo	2025-05-28 13:04:55.097711
234	67	inativo	ativo	2026-03-18 13:04:55.097711
235	1	ativo	em_viagem	2026-10-30 13:04:55.097711
236	154	em_viagem	ativo	2024-05-14 13:04:55.097711
237	19	em_manutencao	ativo	2026-01-11 13:04:55.097711
238	105	ativo	inativo	2024-07-24 13:04:55.097711
239	28	ativo	em_viagem	2025-06-01 13:04:55.097711
240	115	em_viagem	ativo	2025-04-09 13:04:55.097711
241	96	ativo	em_manutencao	2025-09-04 13:04:55.097711
242	175	em_manutencao	ativo	2025-02-24 13:04:55.097711
243	73	ativo	inativo	2024-11-13 13:04:55.097711
244	143	inativo	ativo	2025-02-26 13:04:55.097711
245	162	ativo	em_viagem	2026-03-26 13:04:55.097711
246	130	em_viagem	ativo	2024-05-07 13:04:55.097711
247	132	ativo	em_manutencao	2025-12-03 13:04:55.097711
248	170	em_manutencao	ativo	2024-07-14 13:04:55.097711
249	104	ativo	inativo	2025-12-15 13:04:55.097711
250	129	inativo	ativo	2024-07-20 13:04:55.097711
251	7	ativo	em_viagem	2025-12-14 13:04:55.097711
252	21	em_viagem	ativo	2025-05-29 13:04:55.097711
253	178	ativo	em_manutencao	2024-05-10 13:04:55.097711
254	88	em_manutencao	ativo	2026-04-16 13:04:55.097711
255	165	ativo	inativo	2024-12-29 13:04:55.097711
256	27	ativo	em_viagem	2024-03-06 13:04:55.097711
257	120	ativo	em_manutencao	2026-10-14 13:04:55.097711
258	147	em_manutencao	ativo	2026-02-27 13:04:55.097711
259	76	ativo	inativo	2024-05-15 13:04:55.097711
260	110	inativo	ativo	2026-04-28 13:04:55.097711
261	109	ativo	em_viagem	2026-06-07 13:04:55.097711
262	18	em_viagem	ativo	2026-04-28 13:04:55.097711
263	64	ativo	em_manutencao	2024-05-19 13:04:55.097711
264	47	em_manutencao	ativo	2025-11-15 13:04:55.097711
265	93	ativo	inativo	2025-12-15 13:04:55.097711
266	118	inativo	ativo	2025-07-17 13:04:55.097711
267	84	ativo	em_viagem	2024-06-03 13:04:55.097711
268	64	em_viagem	ativo	2024-12-13 13:04:55.097711
269	32	ativo	em_manutencao	2025-11-07 13:04:55.097711
270	52	em_manutencao	ativo	2026-09-03 13:04:55.097711
271	56	ativo	inativo	2026-01-22 13:04:55.097711
272	108	inativo	ativo	2026-07-09 13:04:55.097711
273	161	ativo	em_viagem	2024-11-18 13:04:55.097711
274	172	em_viagem	ativo	2024-08-06 13:04:55.097711
275	17	ativo	em_manutencao	2024-11-01 13:04:55.097711
276	113	em_manutencao	ativo	2025-12-24 13:04:55.097711
277	138	ativo	inativo	2025-04-15 13:04:55.097711
278	13	inativo	ativo	2024-11-06 13:04:55.097711
279	51	ativo	em_viagem	2024-07-12 13:04:55.097711
280	107	em_viagem	ativo	2026-02-04 13:04:55.097711
281	113	ativo	em_manutencao	2025-06-17 13:04:55.097711
282	60	em_manutencao	ativo	2025-03-21 13:04:55.097711
283	108	ativo	inativo	2024-05-15 13:04:55.097711
284	55	inativo	ativo	2024-09-10 13:04:55.097711
285	39	ativo	em_viagem	2025-06-10 13:04:55.097711
286	47	em_viagem	ativo	2025-06-12 13:04:55.097711
287	107	ativo	em_manutencao	2025-03-04 13:04:55.097711
288	1	em_manutencao	ativo	2026-06-27 13:04:55.097711
289	138	ativo	inativo	2025-10-06 13:04:55.097711
290	164	inativo	ativo	2026-01-12 13:04:55.097711
291	178	ativo	em_viagem	2024-12-24 13:04:55.097711
292	130	em_viagem	ativo	2024-10-19 13:04:55.097711
293	57	ativo	em_manutencao	2024-08-25 13:04:55.097711
294	24	em_manutencao	ativo	2025-05-17 13:04:55.097711
295	13	ativo	inativo	2024-10-26 13:04:55.097711
296	82	inativo	ativo	2025-09-30 13:04:55.097711
297	7	ativo	em_viagem	2024-06-22 13:04:55.097711
298	122	em_viagem	ativo	2026-05-23 13:04:55.097711
299	77	ativo	em_manutencao	2024-11-30 13:04:55.097711
300	156	em_manutencao	ativo	2026-08-30 13:04:55.097711
301	46	inativo	ativo	2024-03-12 13:04:55.097711
302	152	ativo	em_viagem	2025-10-28 13:04:55.097711
303	50	em_viagem	ativo	2025-02-12 13:04:55.097711
\.


--
-- TOC entry 3615 (class 0 OID 32805)
-- Dependencies: 226
-- Data for Name: hodometros; Type: TABLE DATA; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

COPY gabriel_trabalho_bd.hodometros (id_hodometro, id_veiculo, data_registro, quilometragem, observacao) FROM stdin;
1	1	2026-01-05	45200	registro mensal
2	1	2026-02-05	46850	registro mensal
3	1	2026-03-05	48520	registro mensal
4	1	2026-04-05	50190	registro mensal
5	1	2026-05-05	51980	registro mensal
6	1	2026-06-05	53750	registro mensal
7	2	2026-01-05	38200	registro mensal
8	2	2026-02-05	39780	registro mensal
9	2	2026-03-05	41450	registro mensal
10	2	2026-04-05	43120	registro mensal
11	2	2026-05-05	44890	registro mensal
12	2	2026-06-05	46600	registro mensal
13	3	2026-01-05	29100	registro mensal
14	3	2026-02-05	30580	registro mensal
15	3	2026-03-05	32120	registro mensal
16	3	2026-04-05	33800	registro mensal
17	3	2026-05-05	35450	registro mensal
18	3	2026-06-05	37100	registro mensal
19	4	2026-01-05	62500	registro mensal
20	4	2026-02-05	64800	registro mensal
21	4	2026-03-05	67100	registro mensal
22	4	2026-04-05	69450	registro mensal
23	4	2026-05-05	71800	registro mensal
24	4	2026-06-05	74200	registro mensal
25	5	2026-01-05	71200	registro mensal
26	5	2026-02-05	73500	registro mensal
27	5	2026-03-05	75900	registro mensal
28	5	2026-04-05	78200	registro mensal
29	5	2026-05-05	80600	registro mensal
30	5	2026-06-05	82900	registro mensal
31	6	2026-01-05	88400	registro mensal
32	6	2026-02-05	90200	registro mensal
33	6	2026-03-05	92100	registro mensal
34	6	2026-04-05	94050	registro mensal
35	6	2026-05-05	96000	registro mensal
36	6	2026-06-05	98050	registro mensal
37	7	2026-01-05	54800	registro mensal
38	7	2026-02-05	56700	registro mensal
39	7	2026-03-05	58600	registro mensal
40	7	2026-04-05	60500	registro mensal
41	7	2026-05-05	62400	registro mensal
42	7	2026-06-05	64300	registro mensal
43	8	2026-01-05	68300	registro mensal
44	8	2026-02-05	70400	registro mensal
45	8	2026-03-05	72500	registro mensal
46	8	2026-04-05	74600	registro mensal
47	8	2026-05-05	76700	registro mensal
48	8	2026-06-05	78800	registro mensal
49	9	2026-01-05	112500	registro mensal
50	9	2026-02-05	115200	registro mensal
51	9	2026-03-05	117900	registro mensal
52	9	2026-04-05	120600	registro mensal
53	9	2026-05-05	123400	registro mensal
54	9	2026-06-05	126200	registro mensal
55	10	2026-01-05	138000	registro mensal
56	10	2026-02-05	141100	registro mensal
57	10	2026-03-05	144300	registro mensal
58	10	2026-04-05	147500	registro mensal
59	10	2026-05-05	150800	registro mensal
60	10	2026-06-05	154100	registro mensal
61	11	2026-07-05	44500	registro mensal
62	11	2026-08-05	46250	registro mensal
63	11	2026-09-01	48000	registro mensal
64	12	2026-07-05	52400	registro mensal
65	12	2026-08-05	54200	registro mensal
66	12	2026-09-01	56050	registro mensal
67	13	2026-07-05	37900	registro mensal
68	13	2026-08-05	39700	registro mensal
69	13	2026-09-01	41500	registro mensal
70	14	2026-07-05	49600	registro mensal
71	14	2026-08-05	51500	registro mensal
72	14	2026-09-01	53400	registro mensal
73	15	2026-07-05	65300	registro mensal
74	15	2026-08-05	67700	registro mensal
75	15	2026-09-01	70100	registro mensal
76	16	2026-07-05	60100	registro mensal
77	16	2026-08-05	62400	registro mensal
78	16	2026-09-01	64700	registro mensal
79	17	2026-07-05	75900	registro mensal
80	17	2026-08-05	78200	registro mensal
81	17	2026-09-01	80500	registro mensal
82	18	2026-07-05	45400	registro mensal
83	18	2026-08-05	47200	registro mensal
84	18	2026-09-01	49000	registro mensal
85	19	2026-07-05	51500	registro mensal
86	19	2026-08-05	53500	registro mensal
87	19	2026-09-01	55500	registro mensal
88	20	2026-07-05	40100	registro mensal
89	20	2026-08-05	41900	registro mensal
90	20	2026-09-01	43700	registro mensal
91	21	2026-07-05	70700	registro mensal
92	21	2026-08-05	73100	registro mensal
93	21	2026-09-01	75500	registro mensal
94	22	2026-07-05	61400	registro mensal
95	22	2026-08-05	63600	registro mensal
96	22	2026-09-01	65800	registro mensal
97	23	2026-07-05	87300	registro mensal
98	23	2026-08-05	89700	registro mensal
99	23	2026-09-01	92100	registro mensal
100	24	2026-07-05	80800	registro mensal
101	24	2026-08-05	83200	registro mensal
102	24	2026-09-01	85600	registro mensal
103	25	2026-07-05	95700	registro mensal
104	25	2026-08-05	98200	registro mensal
105	25	2026-09-01	100700	registro mensal
106	26	2026-07-05	64800	registro mensal
107	26	2026-08-05	67000	registro mensal
108	26	2026-09-01	69200	registro mensal
109	27	2026-07-05	41700	registro mensal
110	27	2026-08-05	43500	registro mensal
111	27	2026-09-01	45300	registro mensal
112	28	2026-07-05	56100	registro mensal
113	28	2026-08-05	58100	registro mensal
114	28	2026-09-01	60100	registro mensal
115	29	2026-07-05	69800	registro mensal
116	29	2026-08-05	71900	registro mensal
117	29	2026-09-01	74000	registro mensal
118	30	2026-07-05	49700	registro mensal
119	30	2026-08-05	51600	registro mensal
120	30	2026-09-01	53500	registro mensal
121	11	2026-07-05	44500	registro mensal
122	11	2026-08-05	46250	registro mensal
123	11	2026-09-01	48000	registro mensal
124	12	2026-07-05	52400	registro mensal
125	12	2026-08-05	54200	registro mensal
126	12	2026-09-01	56050	registro mensal
127	13	2026-07-05	37900	registro mensal
128	13	2026-08-05	39700	registro mensal
129	13	2026-09-01	41500	registro mensal
130	14	2026-07-05	49600	registro mensal
131	14	2026-08-05	51500	registro mensal
132	14	2026-09-01	53400	registro mensal
133	15	2026-07-05	65300	registro mensal
134	15	2026-08-05	67700	registro mensal
135	15	2026-09-01	70100	registro mensal
136	16	2026-07-05	60100	registro mensal
137	16	2026-08-05	62400	registro mensal
138	16	2026-09-01	64700	registro mensal
139	17	2026-07-05	75900	registro mensal
140	17	2026-08-05	78200	registro mensal
141	17	2026-09-01	80500	registro mensal
142	18	2026-07-05	45400	registro mensal
143	18	2026-08-05	47200	registro mensal
144	18	2026-09-01	49000	registro mensal
145	19	2026-07-05	51500	registro mensal
146	19	2026-08-05	53500	registro mensal
147	19	2026-09-01	55500	registro mensal
148	20	2026-07-05	40100	registro mensal
149	20	2026-08-05	41900	registro mensal
150	20	2026-09-01	43700	registro mensal
151	21	2026-07-05	70700	registro mensal
152	21	2026-08-05	73100	registro mensal
153	21	2026-09-01	75500	registro mensal
154	22	2026-07-05	61400	registro mensal
155	22	2026-08-05	63600	registro mensal
156	22	2026-09-01	65800	registro mensal
157	23	2026-07-05	87300	registro mensal
158	23	2026-08-05	89700	registro mensal
159	23	2026-09-01	92100	registro mensal
160	24	2026-07-05	80800	registro mensal
161	24	2026-08-05	83200	registro mensal
162	24	2026-09-01	85600	registro mensal
163	25	2026-07-05	95700	registro mensal
164	25	2026-08-05	98200	registro mensal
165	25	2026-09-01	100700	registro mensal
166	26	2026-07-05	64800	registro mensal
167	26	2026-08-05	67000	registro mensal
168	26	2026-09-01	69200	registro mensal
169	27	2026-07-05	41700	registro mensal
170	27	2026-08-05	43500	registro mensal
171	27	2026-09-01	45300	registro mensal
172	28	2026-07-05	56100	registro mensal
173	28	2026-08-05	58100	registro mensal
174	28	2026-09-01	60100	registro mensal
175	29	2026-07-05	69800	registro mensal
176	29	2026-08-05	71900	registro mensal
177	29	2026-09-01	74000	registro mensal
178	30	2026-07-05	49700	registro mensal
179	30	2026-08-05	51600	registro mensal
180	30	2026-09-01	53500	registro mensal
181	1	2027-01-01	66700	registro periodico
182	2	2027-01-02	68400	registro periodico
183	3	2027-01-03	70100	registro periodico
184	4	2027-01-04	71800	registro periodico
185	5	2027-01-05	73500	registro periodico
186	6	2027-01-06	75200	registro periodico
187	7	2027-01-07	76900	registro periodico
188	8	2027-01-08	78600	registro periodico
189	9	2027-01-09	80300	registro periodico
190	10	2027-01-10	82000	registro periodico
191	11	2027-01-11	83700	registro periodico
192	12	2027-01-12	85400	registro periodico
193	13	2027-01-13	87100	registro periodico
194	14	2027-01-14	88800	registro periodico
195	15	2027-01-15	90500	registro periodico
196	16	2027-01-16	92200	registro periodico
197	17	2027-01-17	93900	registro periodico
198	18	2027-01-18	95600	registro periodico
199	19	2027-01-19	97300	registro periodico
200	20	2027-01-20	99000	registro periodico
201	21	2027-01-21	100700	registro periodico
202	22	2027-01-22	102400	registro periodico
203	23	2027-01-23	104100	registro periodico
204	24	2027-01-24	105800	registro periodico
205	25	2027-01-25	107500	registro periodico
206	26	2027-01-26	109200	registro periodico
207	27	2027-01-27	110900	registro periodico
208	28	2027-01-28	112600	registro periodico
209	29	2027-01-29	114300	registro periodico
210	30	2027-01-30	116000	registro periodico
211	1	2027-01-31	68500	registro periodico
212	2	2027-02-01	70200	registro periodico
213	3	2027-02-02	71900	registro periodico
214	4	2027-02-03	73600	registro periodico
215	5	2027-02-04	75300	registro periodico
216	6	2027-02-05	77000	registro periodico
217	7	2027-02-06	78700	registro periodico
218	8	2027-02-07	80400	registro periodico
219	9	2027-02-08	82100	registro periodico
220	10	2027-02-09	83800	registro periodico
221	11	2027-02-10	85500	registro periodico
222	12	2027-02-11	87200	registro periodico
223	13	2027-02-12	88900	registro periodico
224	14	2027-02-13	90600	registro periodico
225	15	2027-02-14	92300	registro periodico
226	16	2027-02-15	94000	registro periodico
227	17	2027-02-16	95700	registro periodico
228	18	2027-02-17	97400	registro periodico
229	19	2027-02-18	99100	registro periodico
230	20	2027-02-19	100800	registro periodico
231	21	2027-02-20	102500	registro periodico
232	22	2027-02-21	104200	registro periodico
233	23	2027-02-22	105900	registro periodico
234	24	2027-02-23	107600	registro periodico
235	25	2027-02-24	109300	registro periodico
236	26	2027-02-25	111000	registro periodico
237	27	2027-02-26	112700	registro periodico
238	28	2027-02-27	114400	registro periodico
239	29	2027-02-28	116100	registro periodico
240	30	2027-03-01	117800	registro periodico
241	1	2027-03-02	70300	registro periodico
242	2	2027-03-03	72000	registro periodico
243	3	2027-03-04	73700	registro periodico
244	4	2027-03-05	75400	registro periodico
245	5	2027-03-06	77100	registro periodico
246	6	2027-03-07	78800	registro periodico
247	7	2027-03-08	80500	registro periodico
248	8	2027-03-09	82200	registro periodico
249	9	2027-03-10	83900	registro periodico
250	10	2027-03-11	85600	registro periodico
251	11	2027-03-12	87300	registro periodico
252	12	2027-03-13	89000	registro periodico
253	13	2027-03-14	90700	registro periodico
254	14	2027-03-15	92400	registro periodico
255	15	2027-03-16	94100	registro periodico
256	16	2027-03-17	95800	registro periodico
257	17	2027-03-18	97500	registro periodico
258	18	2027-03-19	99200	registro periodico
259	19	2027-03-20	100900	registro periodico
260	20	2027-03-21	102600	registro periodico
261	21	2027-03-22	104300	registro periodico
262	22	2027-03-23	106000	registro periodico
263	23	2027-03-24	107700	registro periodico
264	24	2027-03-25	109400	registro periodico
265	25	2027-03-26	111100	registro periodico
266	26	2027-03-27	112800	registro periodico
267	27	2027-03-28	114500	registro periodico
268	28	2027-03-29	116200	registro periodico
269	29	2027-03-30	117900	registro periodico
270	30	2027-03-31	119600	registro periodico
271	1	2027-04-01	72100	registro periodico
272	2	2027-04-02	73800	registro periodico
273	3	2027-04-03	75500	registro periodico
274	4	2027-04-04	77200	registro periodico
275	5	2027-04-05	78900	registro periodico
276	6	2027-04-06	80600	registro periodico
277	7	2027-04-07	82300	registro periodico
278	8	2027-04-08	84000	registro periodico
279	9	2027-04-09	85700	registro periodico
280	10	2027-04-10	87400	registro periodico
281	11	2027-04-11	89100	registro periodico
282	12	2027-04-12	90800	registro periodico
283	13	2027-04-13	92500	registro periodico
284	14	2027-04-14	94200	registro periodico
285	15	2027-04-15	95900	registro periodico
286	16	2027-04-16	97600	registro periodico
287	17	2027-04-17	99300	registro periodico
288	18	2027-04-18	101000	registro periodico
289	19	2027-04-19	102700	registro periodico
290	20	2027-04-20	104400	registro periodico
291	21	2027-04-21	106100	registro periodico
292	22	2027-04-22	107800	registro periodico
293	23	2027-04-23	109500	registro periodico
294	24	2027-04-24	111200	registro periodico
295	25	2027-04-25	112900	registro periodico
296	26	2027-04-26	114600	registro periodico
297	27	2027-04-27	116300	registro periodico
298	28	2027-04-28	118000	registro periodico
299	29	2027-04-29	119700	registro periodico
300	30	2027-04-30	121400	registro periodico
301	1	2027-05-01	73900	registro periodico
302	2	2027-05-02	75600	registro periodico
303	3	2027-05-03	77300	registro periodico
304	4	2027-05-04	79000	registro periodico
305	5	2027-05-05	80700	registro periodico
306	6	2027-05-06	82400	registro periodico
307	7	2027-05-07	84100	registro periodico
308	8	2027-05-08	85800	registro periodico
309	9	2027-05-09	87500	registro periodico
310	10	2027-05-10	89200	registro periodico
311	11	2027-05-11	90900	registro periodico
312	12	2027-05-12	92600	registro periodico
313	13	2027-05-13	94300	registro periodico
314	14	2027-05-14	96000	registro periodico
315	15	2027-05-15	97700	registro periodico
316	16	2027-05-16	99400	registro periodico
317	17	2027-05-17	101100	registro periodico
318	18	2027-05-18	102800	registro periodico
319	19	2027-05-19	104500	registro periodico
320	20	2027-05-20	106200	registro periodico
321	21	2027-05-21	107900	registro periodico
322	22	2027-05-22	109600	registro periodico
323	23	2027-05-23	111300	registro periodico
324	24	2027-05-24	113000	registro periodico
325	25	2027-05-25	114700	registro periodico
326	26	2027-05-26	116400	registro periodico
327	27	2027-05-27	118100	registro periodico
328	28	2027-05-28	119800	registro periodico
329	29	2027-05-29	121500	registro periodico
330	30	2027-05-30	123200	registro periodico
331	1	2027-05-31	75700	registro periodico
332	2	2027-06-01	77400	registro periodico
333	3	2027-06-02	79100	registro periodico
334	4	2027-06-03	80800	registro periodico
335	5	2027-06-04	82500	registro periodico
336	6	2027-06-05	84200	registro periodico
337	7	2027-06-06	85900	registro periodico
338	8	2027-06-07	87600	registro periodico
339	9	2027-06-08	89300	registro periodico
340	10	2027-06-09	91000	registro periodico
341	11	2027-06-10	92700	registro periodico
342	12	2027-06-11	94400	registro periodico
343	13	2027-06-12	96100	registro periodico
344	14	2027-06-13	97800	registro periodico
345	15	2027-06-14	99500	registro periodico
346	16	2027-06-15	101200	registro periodico
347	17	2027-06-16	102900	registro periodico
348	18	2027-06-17	104600	registro periodico
349	19	2027-06-18	106300	registro periodico
350	20	2027-06-19	108000	registro periodico
351	21	2027-06-20	109700	registro periodico
352	22	2027-06-21	111400	registro periodico
353	23	2027-06-22	113100	registro periodico
354	24	2027-06-23	114800	registro periodico
355	25	2027-06-24	116500	registro periodico
356	26	2027-06-25	118200	registro periodico
357	27	2027-06-26	119900	registro periodico
358	28	2027-06-27	121600	registro periodico
359	29	2027-06-28	123300	registro periodico
360	30	2027-06-29	125000	registro periodico
361	1	2027-06-30	77500	registro periodico
362	2	2027-07-01	79200	registro periodico
363	3	2027-07-02	80900	registro periodico
364	4	2027-07-03	82600	registro periodico
365	5	2027-07-04	84300	registro periodico
366	6	2027-07-05	86000	registro periodico
367	7	2027-07-06	87700	registro periodico
368	8	2027-07-07	89400	registro periodico
369	9	2027-07-08	91100	registro periodico
370	10	2027-07-09	92800	registro periodico
371	11	2027-07-10	94500	registro periodico
372	12	2027-07-11	96200	registro periodico
373	13	2027-07-12	97900	registro periodico
374	14	2027-07-13	99600	registro periodico
375	15	2027-07-14	101300	registro periodico
376	16	2027-07-15	103000	registro periodico
377	17	2027-07-16	104700	registro periodico
378	18	2027-07-17	106400	registro periodico
379	19	2027-07-18	108100	registro periodico
380	20	2027-07-19	109800	registro periodico
514	34	2026-07-05	43519	registro mensal
1471	1	2027-05-23	83173	Leitura periódica de hodômetro - lote extra 1
381	1	2026-10-29	77880	Leitura de conferência
382	2	2026-10-29	79590	Leitura de conferência
383	3	2026-10-29	81300	Leitura de conferência
384	4	2026-10-29	83010	Leitura de conferência
385	5	2026-10-29	84720	Leitura de conferência
386	6	2026-10-29	98930	Leitura de conferência
387	7	2026-10-29	88140	Leitura de conferência
388	8	2026-10-29	89850	Leitura de conferência
389	9	2026-10-29	126660	Leitura de conferência
390	10	2026-10-29	154570	Leitura de conferência
391	31	2026-01-05	34266	registro mensal
392	32	2026-01-05	103438	registro mensal
393	33	2026-01-05	112054	registro mensal
394	34	2026-01-05	32554	registro mensal
395	35	2026-01-05	102775	registro mensal
396	36	2026-01-05	42696	registro mensal
397	37	2026-01-05	116122	registro mensal
398	38	2026-01-05	118668	registro mensal
399	39	2026-01-05	57186	registro mensal
400	40	2026-01-05	72233	registro mensal
401	41	2026-01-05	97361	registro mensal
402	42	2026-01-05	68191	registro mensal
403	43	2026-01-05	98653	registro mensal
404	44	2026-01-05	76846	registro mensal
405	45	2026-01-05	31546	registro mensal
406	46	2026-01-05	110322	registro mensal
407	47	2026-01-05	66165	registro mensal
408	48	2026-01-05	113973	registro mensal
409	49	2026-01-05	64365	registro mensal
410	50	2026-01-05	90006	registro mensal
411	31	2026-02-05	35911	registro mensal
412	32	2026-02-05	105386	registro mensal
413	33	2026-02-05	114254	registro mensal
414	34	2026-02-05	34638	registro mensal
415	35	2026-02-05	105121	registro mensal
416	36	2026-02-05	43834	registro mensal
417	37	2026-02-05	117429	registro mensal
418	38	2026-02-05	120670	registro mensal
419	39	2026-02-05	58872	registro mensal
420	40	2026-02-05	73458	registro mensal
421	41	2026-02-05	98757	registro mensal
422	42	2026-02-05	69736	registro mensal
423	43	2026-02-05	101225	registro mensal
424	44	2026-02-05	78919	registro mensal
425	45	2026-02-05	33196	registro mensal
426	46	2026-02-05	111948	registro mensal
427	47	2026-02-05	67740	registro mensal
428	48	2026-02-05	115322	registro mensal
429	49	2026-02-05	66755	registro mensal
430	50	2026-02-05	91821	registro mensal
431	31	2026-03-05	38031	registro mensal
432	32	2026-03-05	106517	registro mensal
433	33	2026-03-05	115703	registro mensal
434	34	2026-03-05	36487	registro mensal
435	35	2026-03-05	107517	registro mensal
436	36	2026-03-05	45639	registro mensal
437	37	2026-03-05	118768	registro mensal
438	38	2026-03-05	122920	registro mensal
439	39	2026-03-05	60837	registro mensal
440	40	2026-03-05	74821	registro mensal
441	41	2026-03-05	100219	registro mensal
442	42	2026-03-05	70964	registro mensal
443	43	2026-03-05	103366	registro mensal
444	44	2026-03-05	81025	registro mensal
445	45	2026-03-05	34927	registro mensal
446	46	2026-03-05	113855	registro mensal
447	47	2026-03-05	69510	registro mensal
448	48	2026-03-05	117674	registro mensal
449	49	2026-03-05	68585	registro mensal
450	50	2026-03-05	93210	registro mensal
451	31	2026-04-05	39889	registro mensal
452	32	2026-04-05	107734	registro mensal
453	33	2026-04-05	118281	registro mensal
454	34	2026-04-05	38106	registro mensal
455	35	2026-04-05	109831	registro mensal
456	36	2026-04-05	46891	registro mensal
457	37	2026-04-05	120313	registro mensal
458	38	2026-04-05	124069	registro mensal
459	39	2026-04-05	62830	registro mensal
460	40	2026-04-05	76917	registro mensal
461	41	2026-04-05	102037	registro mensal
462	42	2026-04-05	73020	registro mensal
463	43	2026-04-05	104489	registro mensal
464	44	2026-04-05	83081	registro mensal
465	45	2026-04-05	37381	registro mensal
466	46	2026-04-05	115149	registro mensal
467	47	2026-04-05	70782	registro mensal
468	48	2026-04-05	120209	registro mensal
469	49	2026-04-05	71110	registro mensal
470	50	2026-04-05	94480	registro mensal
471	31	2026-05-05	41186	registro mensal
472	32	2026-05-05	109031	registro mensal
473	33	2026-05-05	120438	registro mensal
474	34	2026-05-05	40160	registro mensal
475	35	2026-05-05	111029	registro mensal
476	36	2026-05-05	48257	registro mensal
477	37	2026-05-05	122227	registro mensal
478	38	2026-05-05	125756	registro mensal
479	39	2026-05-05	65069	registro mensal
480	40	2026-05-05	79418	registro mensal
481	41	2026-05-05	103140	registro mensal
482	42	2026-05-05	75019	registro mensal
483	43	2026-05-05	106271	registro mensal
484	44	2026-05-05	85218	registro mensal
485	45	2026-05-05	39197	registro mensal
486	46	2026-05-05	117393	registro mensal
487	47	2026-05-05	73063	registro mensal
488	48	2026-05-05	121973	registro mensal
489	49	2026-05-05	73063	registro mensal
490	50	2026-05-05	96422	registro mensal
491	31	2026-06-05	42684	registro mensal
492	32	2026-06-05	110612	registro mensal
493	33	2026-06-05	121598	registro mensal
494	34	2026-06-05	41667	registro mensal
495	35	2026-06-05	113558	registro mensal
496	36	2026-06-05	50517	registro mensal
497	37	2026-06-05	123579	registro mensal
498	38	2026-06-05	127693	registro mensal
499	39	2026-06-05	67054	registro mensal
500	40	2026-06-05	80724	registro mensal
501	41	2026-06-05	104560	registro mensal
502	42	2026-06-05	76678	registro mensal
503	43	2026-06-05	108563	registro mensal
504	44	2026-06-05	87009	registro mensal
505	45	2026-06-05	40460	registro mensal
506	46	2026-06-05	118681	registro mensal
507	47	2026-06-05	75060	registro mensal
508	48	2026-06-05	123469	registro mensal
509	49	2026-06-05	75525	registro mensal
510	50	2026-06-05	97852	registro mensal
511	31	2026-07-05	44626	registro mensal
512	32	2026-07-05	111759	registro mensal
513	33	2026-07-05	123065	registro mensal
515	35	2026-07-05	116030	registro mensal
516	36	2026-07-05	52675	registro mensal
517	37	2026-07-05	125615	registro mensal
518	38	2026-07-05	129552	registro mensal
519	39	2026-07-05	68565	registro mensal
520	40	2026-07-05	82872	registro mensal
521	41	2026-07-05	105882	registro mensal
522	42	2026-07-05	78648	registro mensal
523	43	2026-07-05	110209	registro mensal
524	44	2026-07-05	89530	registro mensal
525	45	2026-07-05	42791	registro mensal
526	46	2026-07-05	120027	registro mensal
527	47	2026-07-05	77025	registro mensal
528	48	2026-07-05	124677	registro mensal
529	49	2026-07-05	78001	registro mensal
530	50	2026-07-05	99136	registro mensal
531	31	2026-08-05	46025	registro mensal
532	32	2026-08-05	113493	registro mensal
533	33	2026-08-05	124809	registro mensal
534	34	2026-08-05	45179	registro mensal
535	35	2026-08-05	118277	registro mensal
536	36	2026-08-05	54273	registro mensal
537	37	2026-08-05	127946	registro mensal
538	38	2026-08-05	131792	registro mensal
539	39	2026-08-05	69848	registro mensal
540	40	2026-08-05	84831	registro mensal
541	41	2026-08-05	107707	registro mensal
542	42	2026-08-05	80536	registro mensal
543	43	2026-08-05	112550	registro mensal
544	44	2026-08-05	91248	registro mensal
545	45	2026-08-05	45047	registro mensal
546	46	2026-08-05	122163	registro mensal
547	47	2026-08-05	78214	registro mensal
548	48	2026-08-05	127002	registro mensal
549	49	2026-08-05	80537	registro mensal
550	50	2026-08-05	100789	registro mensal
551	31	2026-09-05	48045	registro mensal
552	32	2026-09-05	114844	registro mensal
553	33	2026-09-05	127013	registro mensal
554	34	2026-09-05	47328	registro mensal
555	35	2026-09-05	120045	registro mensal
556	36	2026-09-05	56344	registro mensal
557	37	2026-09-05	129756	registro mensal
558	38	2026-09-05	134277	registro mensal
559	39	2026-09-05	71760	registro mensal
560	40	2026-09-05	86182	registro mensal
561	41	2026-09-05	109131	registro mensal
562	42	2026-09-05	82191	registro mensal
563	43	2026-09-05	114676	registro mensal
564	44	2026-09-05	93070	registro mensal
565	45	2026-09-05	46801	registro mensal
566	46	2026-09-05	123744	registro mensal
567	47	2026-09-05	79869	registro mensal
568	48	2026-09-05	128797	registro mensal
569	49	2026-09-05	82634	registro mensal
570	50	2026-09-05	102426	registro mensal
571	31	2026-10-05	49173	registro mensal
572	32	2026-10-05	116136	registro mensal
573	33	2026-10-05	128409	registro mensal
574	34	2026-10-05	49927	registro mensal
575	35	2026-10-05	121666	registro mensal
576	36	2026-10-05	58864	registro mensal
577	37	2026-10-05	132158	registro mensal
578	38	2026-10-05	136280	registro mensal
579	39	2026-10-05	73629	registro mensal
580	40	2026-10-05	88035	registro mensal
581	41	2026-10-05	110234	registro mensal
582	42	2026-10-05	83721	registro mensal
583	43	2026-10-05	115868	registro mensal
584	44	2026-10-05	95142	registro mensal
585	45	2026-10-05	49395	registro mensal
586	46	2026-10-05	125276	registro mensal
587	47	2026-10-05	81371	registro mensal
588	48	2026-10-05	130637	registro mensal
589	49	2026-10-05	84908	registro mensal
590	50	2026-10-05	105009	registro mensal
591	51	2025-01-05	27675	registro mensal
592	52	2025-01-05	112621	registro mensal
593	53	2025-01-05	61520	registro mensal
594	54	2025-01-05	60955	registro mensal
595	55	2025-01-05	83866	registro mensal
596	56	2025-01-05	100621	registro mensal
597	57	2025-01-05	115090	registro mensal
598	58	2025-01-05	50124	registro mensal
599	59	2025-01-05	120659	registro mensal
600	60	2025-01-05	42841	registro mensal
601	61	2025-01-05	85247	registro mensal
602	62	2025-01-05	27535	registro mensal
603	63	2025-01-05	119822	registro mensal
604	64	2025-01-05	96182	registro mensal
605	65	2025-01-05	67910	registro mensal
606	66	2025-01-05	75833	registro mensal
607	67	2025-01-05	97049	registro mensal
608	68	2025-01-05	63806	registro mensal
609	69	2025-01-05	4073	registro mensal
610	70	2025-01-05	138132	registro mensal
611	71	2025-01-05	105859	registro mensal
612	72	2025-01-05	20654	registro mensal
613	73	2025-01-05	3061	registro mensal
614	74	2025-01-05	57513	registro mensal
615	75	2025-01-05	127295	registro mensal
616	76	2025-01-05	84750	registro mensal
617	77	2025-01-05	138353	registro mensal
618	78	2025-01-05	10089	registro mensal
619	79	2025-01-05	138894	registro mensal
620	80	2025-01-05	89419	registro mensal
621	81	2025-01-05	65754	registro mensal
622	82	2025-01-05	10596	registro mensal
623	83	2025-01-05	93251	registro mensal
624	84	2025-01-05	24112	registro mensal
625	85	2025-01-05	3500	registro mensal
626	86	2025-01-05	34432	registro mensal
627	87	2025-01-05	116750	registro mensal
628	88	2025-01-05	124414	registro mensal
629	89	2025-01-05	10221	registro mensal
630	90	2025-01-05	127349	registro mensal
631	51	2025-02-05	30021	registro mensal
632	52	2025-02-05	113904	registro mensal
633	53	2025-02-05	63137	registro mensal
634	54	2025-02-05	62668	registro mensal
635	55	2025-02-05	85404	registro mensal
636	56	2025-02-05	102372	registro mensal
637	57	2025-02-05	117475	registro mensal
638	58	2025-02-05	51747	registro mensal
639	59	2025-02-05	121924	registro mensal
640	60	2025-02-05	45239	registro mensal
641	61	2025-02-05	87473	registro mensal
642	62	2025-02-05	29779	registro mensal
643	63	2025-02-05	121064	registro mensal
644	64	2025-02-05	97623	registro mensal
645	65	2025-02-05	69591	registro mensal
646	66	2025-02-05	77588	registro mensal
647	67	2025-02-05	99346	registro mensal
648	68	2025-02-05	65360	registro mensal
649	69	2025-02-05	5995	registro mensal
650	70	2025-02-05	140349	registro mensal
651	71	2025-02-05	107035	registro mensal
652	72	2025-02-05	21903	registro mensal
653	73	2025-02-05	5037	registro mensal
654	74	2025-02-05	59072	registro mensal
655	75	2025-02-05	128697	registro mensal
656	76	2025-02-05	86250	registro mensal
657	77	2025-02-05	140252	registro mensal
658	78	2025-02-05	12052	registro mensal
659	79	2025-02-05	140236	registro mensal
660	80	2025-02-05	91265	registro mensal
661	81	2025-02-05	67499	registro mensal
662	82	2025-02-05	11856	registro mensal
663	83	2025-02-05	95588	registro mensal
664	84	2025-02-05	25332	registro mensal
665	85	2025-02-05	4614	registro mensal
666	86	2025-02-05	35825	registro mensal
667	87	2025-02-05	118647	registro mensal
668	88	2025-02-05	126811	registro mensal
669	89	2025-02-05	11342	registro mensal
670	90	2025-02-05	129202	registro mensal
671	51	2025-03-05	31738	registro mensal
672	52	2025-03-05	116223	registro mensal
673	53	2025-03-05	64396	registro mensal
674	54	2025-03-05	63997	registro mensal
675	55	2025-03-05	86952	registro mensal
676	56	2025-03-05	104315	registro mensal
677	57	2025-03-05	118896	registro mensal
678	58	2025-03-05	53935	registro mensal
679	59	2025-03-05	124190	registro mensal
680	60	2025-03-05	47523	registro mensal
681	61	2025-03-05	89254	registro mensal
682	62	2025-03-05	31307	registro mensal
683	63	2025-03-05	122733	registro mensal
684	64	2025-03-05	99574	registro mensal
685	65	2025-03-05	70850	registro mensal
686	66	2025-03-05	78955	registro mensal
687	67	2025-03-05	101414	registro mensal
688	68	2025-03-05	66639	registro mensal
689	69	2025-03-05	7259	registro mensal
690	70	2025-03-05	142358	registro mensal
691	71	2025-03-05	109312	registro mensal
692	72	2025-03-05	23734	registro mensal
693	73	2025-03-05	6471	registro mensal
694	74	2025-03-05	61049	registro mensal
695	75	2025-03-05	129761	registro mensal
696	76	2025-03-05	87557	registro mensal
697	77	2025-03-05	141304	registro mensal
698	78	2025-03-05	13805	registro mensal
699	79	2025-03-05	141397	registro mensal
700	80	2025-03-05	93477	registro mensal
701	81	2025-03-05	69178	registro mensal
702	82	2025-03-05	13306	registro mensal
703	83	2025-03-05	97305	registro mensal
704	84	2025-03-05	27540	registro mensal
705	85	2025-03-05	6433	registro mensal
706	86	2025-03-05	37936	registro mensal
707	87	2025-03-05	120680	registro mensal
708	88	2025-03-05	128979	registro mensal
709	89	2025-03-05	12978	registro mensal
710	90	2025-03-05	130221	registro mensal
711	51	2025-04-05	33057	registro mensal
712	52	2025-04-05	117809	registro mensal
713	53	2025-04-05	65485	registro mensal
714	54	2025-04-05	65480	registro mensal
715	55	2025-04-05	88817	registro mensal
716	56	2025-04-05	106437	registro mensal
717	57	2025-04-05	120773	registro mensal
718	58	2025-04-05	55658	registro mensal
719	59	2025-04-05	125582	registro mensal
720	60	2025-04-05	48608	registro mensal
721	61	2025-04-05	90382	registro mensal
722	62	2025-04-05	33549	registro mensal
723	63	2025-04-05	123786	registro mensal
724	64	2025-04-05	101804	registro mensal
725	65	2025-04-05	73241	registro mensal
726	66	2025-04-05	81216	registro mensal
727	67	2025-04-05	103085	registro mensal
728	68	2025-04-05	68583	registro mensal
729	69	2025-04-05	9411	registro mensal
730	70	2025-04-05	144715	registro mensal
731	71	2025-04-05	110351	registro mensal
732	72	2025-04-05	24887	registro mensal
733	73	2025-04-05	8262	registro mensal
734	74	2025-04-05	62800	registro mensal
735	75	2025-04-05	131960	registro mensal
736	76	2025-04-05	89101	registro mensal
737	77	2025-04-05	143671	registro mensal
738	78	2025-04-05	14974	registro mensal
739	79	2025-04-05	143471	registro mensal
740	80	2025-04-05	94524	registro mensal
741	81	2025-04-05	70755	registro mensal
742	82	2025-04-05	14703	registro mensal
743	83	2025-04-05	98377	registro mensal
744	84	2025-04-05	29454	registro mensal
745	85	2025-04-05	7914	registro mensal
746	86	2025-04-05	39561	registro mensal
747	87	2025-04-05	122495	registro mensal
748	88	2025-04-05	130806	registro mensal
749	89	2025-04-05	14484	registro mensal
750	90	2025-04-05	132469	registro mensal
751	51	2025-05-05	35180	registro mensal
752	52	2025-05-05	119803	registro mensal
753	53	2025-05-05	67473	registro mensal
754	54	2025-05-05	67151	registro mensal
755	55	2025-05-05	90139	registro mensal
756	56	2025-05-05	108058	registro mensal
757	57	2025-05-05	123151	registro mensal
758	58	2025-05-05	57616	registro mensal
759	59	2025-05-05	127770	registro mensal
760	60	2025-05-05	50377	registro mensal
761	61	2025-05-05	91870	registro mensal
762	62	2025-05-05	35479	registro mensal
763	63	2025-05-05	124838	registro mensal
764	64	2025-05-05	103764	registro mensal
765	65	2025-05-05	74312	registro mensal
766	66	2025-05-05	83024	registro mensal
767	67	2025-05-05	104349	registro mensal
768	68	2025-05-05	70007	registro mensal
769	69	2025-05-05	11638	registro mensal
770	70	2025-05-05	145720	registro mensal
771	71	2025-05-05	112393	registro mensal
772	72	2025-05-05	27087	registro mensal
773	73	2025-05-05	10553	registro mensal
774	74	2025-05-05	64161	registro mensal
775	75	2025-05-05	133116	registro mensal
776	76	2025-05-05	90743	registro mensal
777	77	2025-05-05	145572	registro mensal
778	78	2025-05-05	17087	registro mensal
779	79	2025-05-05	145840	registro mensal
780	80	2025-05-05	96663	registro mensal
781	81	2025-05-05	72024	registro mensal
782	82	2025-05-05	16792	registro mensal
783	83	2025-05-05	100436	registro mensal
784	84	2025-05-05	30956	registro mensal
785	85	2025-05-05	9201	registro mensal
786	86	2025-05-05	41043	registro mensal
787	87	2025-05-05	124646	registro mensal
788	88	2025-05-05	132207	registro mensal
789	89	2025-05-05	15785	registro mensal
790	90	2025-05-05	134145	registro mensal
791	51	2025-06-05	37302	registro mensal
792	52	2025-06-05	120903	registro mensal
793	53	2025-06-05	69117	registro mensal
794	54	2025-06-05	68538	registro mensal
795	55	2025-06-05	92340	registro mensal
796	56	2025-06-05	110313	registro mensal
797	57	2025-06-05	125199	registro mensal
798	58	2025-06-05	59347	registro mensal
799	59	2025-06-05	129532	registro mensal
800	60	2025-06-05	51754	registro mensal
801	61	2025-06-05	93338	registro mensal
802	62	2025-06-05	37451	registro mensal
803	63	2025-06-05	126303	registro mensal
804	64	2025-06-05	104928	registro mensal
805	65	2025-06-05	76591	registro mensal
806	66	2025-06-05	85327	registro mensal
807	67	2025-06-05	105728	registro mensal
808	68	2025-06-05	71436	registro mensal
809	69	2025-06-05	13991	registro mensal
810	70	2025-06-05	148051	registro mensal
811	71	2025-06-05	114513	registro mensal
812	72	2025-06-05	29276	registro mensal
813	73	2025-06-05	12889	registro mensal
814	74	2025-06-05	65444	registro mensal
815	75	2025-06-05	135245	registro mensal
816	76	2025-06-05	93123	registro mensal
817	77	2025-06-05	147644	registro mensal
818	78	2025-06-05	18541	registro mensal
819	79	2025-06-05	147892	registro mensal
820	80	2025-06-05	98516	registro mensal
821	81	2025-06-05	73950	registro mensal
822	82	2025-06-05	18350	registro mensal
823	83	2025-06-05	101701	registro mensal
824	84	2025-06-05	32173	registro mensal
825	85	2025-06-05	10305	registro mensal
826	86	2025-06-05	43355	registro mensal
827	87	2025-06-05	126299	registro mensal
828	88	2025-06-05	133902	registro mensal
829	89	2025-06-05	17881	registro mensal
830	90	2025-06-05	135991	registro mensal
831	51	2025-07-05	38570	registro mensal
832	52	2025-07-05	123029	registro mensal
833	53	2025-07-05	70226	registro mensal
834	54	2025-07-05	70067	registro mensal
835	55	2025-07-05	93426	registro mensal
836	56	2025-07-05	112291	registro mensal
837	57	2025-07-05	126460	registro mensal
838	58	2025-07-05	61224	registro mensal
839	59	2025-07-05	130661	registro mensal
840	60	2025-07-05	53552	registro mensal
841	61	2025-07-05	94348	registro mensal
842	62	2025-07-05	39601	registro mensal
843	63	2025-07-05	128060	registro mensal
844	64	2025-07-05	106523	registro mensal
845	65	2025-07-05	77976	registro mensal
846	66	2025-07-05	87353	registro mensal
847	67	2025-07-05	107370	registro mensal
848	68	2025-07-05	72933	registro mensal
849	69	2025-07-05	16074	registro mensal
850	70	2025-07-05	149528	registro mensal
851	71	2025-07-05	116487	registro mensal
852	72	2025-07-05	31225	registro mensal
853	73	2025-07-05	15161	registro mensal
854	74	2025-07-05	66989	registro mensal
855	75	2025-07-05	137432	registro mensal
856	76	2025-07-05	95315	registro mensal
857	77	2025-07-05	149764	registro mensal
858	78	2025-07-05	20388	registro mensal
859	79	2025-07-05	149969	registro mensal
860	80	2025-07-05	99753	registro mensal
861	81	2025-07-05	76346	registro mensal
862	82	2025-07-05	19511	registro mensal
863	83	2025-07-05	103729	registro mensal
864	84	2025-07-05	33779	registro mensal
865	85	2025-07-05	11542	registro mensal
866	86	2025-07-05	44810	registro mensal
867	87	2025-07-05	128396	registro mensal
868	88	2025-07-05	134912	registro mensal
869	89	2025-07-05	19292	registro mensal
870	90	2025-07-05	137794	registro mensal
871	51	2025-08-05	39613	registro mensal
872	52	2025-08-05	124289	registro mensal
873	53	2025-08-05	72470	registro mensal
874	54	2025-08-05	71275	registro mensal
875	55	2025-08-05	95016	registro mensal
876	56	2025-08-05	114251	registro mensal
877	57	2025-08-05	128462	registro mensal
878	58	2025-08-05	62362	registro mensal
879	59	2025-08-05	133024	registro mensal
880	60	2025-08-05	55107	registro mensal
881	61	2025-08-05	96151	registro mensal
882	62	2025-08-05	41723	registro mensal
883	63	2025-08-05	129204	registro mensal
884	64	2025-08-05	108225	registro mensal
885	65	2025-08-05	79399	registro mensal
886	66	2025-08-05	89202	registro mensal
887	67	2025-08-05	109769	registro mensal
888	68	2025-08-05	74233	registro mensal
889	69	2025-08-05	17752	registro mensal
890	70	2025-08-05	150692	registro mensal
891	71	2025-08-05	118219	registro mensal
892	72	2025-08-05	32673	registro mensal
893	73	2025-08-05	16513	registro mensal
894	74	2025-08-05	68636	registro mensal
895	75	2025-08-05	139281	registro mensal
896	76	2025-08-05	96491	registro mensal
897	77	2025-08-05	151844	registro mensal
898	78	2025-08-05	21560	registro mensal
899	79	2025-08-05	151990	registro mensal
900	80	2025-08-05	101528	registro mensal
901	81	2025-08-05	78449	registro mensal
902	82	2025-08-05	20540	registro mensal
903	83	2025-08-05	105256	registro mensal
904	84	2025-08-05	35338	registro mensal
905	85	2025-08-05	13470	registro mensal
906	86	2025-08-05	46773	registro mensal
907	87	2025-08-05	129469	registro mensal
908	88	2025-08-05	136978	registro mensal
909	89	2025-08-05	21153	registro mensal
910	90	2025-08-05	138942	registro mensal
911	51	2025-09-05	40642	registro mensal
912	52	2025-09-05	125638	registro mensal
913	53	2025-09-05	74773	registro mensal
914	54	2025-09-05	72612	registro mensal
915	55	2025-09-05	96304	registro mensal
916	56	2025-09-05	115886	registro mensal
917	57	2025-09-05	129849	registro mensal
918	58	2025-09-05	64354	registro mensal
919	59	2025-09-05	134440	registro mensal
920	60	2025-09-05	56788	registro mensal
921	61	2025-09-05	98310	registro mensal
922	62	2025-09-05	43514	registro mensal
923	63	2025-09-05	131463	registro mensal
924	64	2025-09-05	110471	registro mensal
925	65	2025-09-05	80440	registro mensal
926	66	2025-09-05	90452	registro mensal
927	67	2025-09-05	111573	registro mensal
928	68	2025-09-05	75290	registro mensal
929	69	2025-09-05	20085	registro mensal
930	70	2025-09-05	152658	registro mensal
931	71	2025-09-05	119730	registro mensal
932	72	2025-09-05	33760	registro mensal
933	73	2025-09-05	17637	registro mensal
934	74	2025-09-05	70324	registro mensal
935	75	2025-09-05	141404	registro mensal
936	76	2025-09-05	98805	registro mensal
937	77	2025-09-05	153346	registro mensal
938	78	2025-09-05	22904	registro mensal
939	79	2025-09-05	153966	registro mensal
940	80	2025-09-05	103450	registro mensal
941	81	2025-09-05	79964	registro mensal
942	82	2025-09-05	22559	registro mensal
943	83	2025-09-05	107258	registro mensal
944	84	2025-09-05	37215	registro mensal
945	85	2025-09-05	14745	registro mensal
946	86	2025-09-05	48660	registro mensal
947	87	2025-09-05	131209	registro mensal
948	88	2025-09-05	138658	registro mensal
949	89	2025-09-05	22282	registro mensal
950	90	2025-09-05	140367	registro mensal
951	51	2025-10-05	42972	registro mensal
952	52	2025-10-05	127605	registro mensal
953	53	2025-10-05	76567	registro mensal
954	54	2025-10-05	74959	registro mensal
955	55	2025-10-05	98475	registro mensal
956	56	2025-10-05	116949	registro mensal
957	57	2025-10-05	130938	registro mensal
958	58	2025-10-05	66007	registro mensal
959	59	2025-10-05	136114	registro mensal
960	60	2025-10-05	58097	registro mensal
961	61	2025-10-05	99769	registro mensal
962	62	2025-10-05	44795	registro mensal
963	63	2025-10-05	132601	registro mensal
964	64	2025-10-05	111850	registro mensal
965	65	2025-10-05	82626	registro mensal
966	66	2025-10-05	91693	registro mensal
967	67	2025-10-05	112870	registro mensal
968	68	2025-10-05	77592	registro mensal
969	69	2025-10-05	21099	registro mensal
970	70	2025-10-05	154594	registro mensal
971	71	2025-10-05	121058	registro mensal
972	72	2025-10-05	35692	registro mensal
973	73	2025-10-05	19325	registro mensal
974	74	2025-10-05	72550	registro mensal
975	75	2025-10-05	143785	registro mensal
976	76	2025-10-05	101169	registro mensal
977	77	2025-10-05	155744	registro mensal
978	78	2025-10-05	25302	registro mensal
979	79	2025-10-05	156337	registro mensal
980	80	2025-10-05	104528	registro mensal
981	81	2025-10-05	81922	registro mensal
982	82	2025-10-05	24313	registro mensal
983	83	2025-10-05	108276	registro mensal
984	84	2025-10-05	39206	registro mensal
985	85	2025-10-05	16095	registro mensal
986	86	2025-10-05	49959	registro mensal
987	87	2025-10-05	133433	registro mensal
988	88	2025-10-05	140960	registro mensal
989	89	2025-10-05	24328	registro mensal
990	90	2025-10-05	142440	registro mensal
991	51	2025-11-05	44182	registro mensal
992	52	2025-11-05	129454	registro mensal
993	53	2025-11-05	77743	registro mensal
994	54	2025-11-05	76167	registro mensal
995	55	2025-11-05	99776	registro mensal
996	56	2025-11-05	118445	registro mensal
997	57	2025-11-05	133083	registro mensal
998	58	2025-11-05	67365	registro mensal
999	59	2025-11-05	137258	registro mensal
1000	60	2025-11-05	59839	registro mensal
1001	61	2025-11-05	102067	registro mensal
1002	62	2025-11-05	46329	registro mensal
1003	63	2025-11-05	134620	registro mensal
1004	64	2025-11-05	113129	registro mensal
1005	65	2025-11-05	85007	registro mensal
1006	66	2025-11-05	93763	registro mensal
1007	67	2025-11-05	115255	registro mensal
1008	68	2025-11-05	79953	registro mensal
1009	69	2025-11-05	23101	registro mensal
1010	70	2025-11-05	156939	registro mensal
1011	71	2025-11-05	122236	registro mensal
1012	72	2025-11-05	37047	registro mensal
1013	73	2025-11-05	21594	registro mensal
1014	74	2025-11-05	74223	registro mensal
1015	75	2025-11-05	145652	registro mensal
1016	76	2025-11-05	102927	registro mensal
1017	77	2025-11-05	157279	registro mensal
1018	78	2025-11-05	26765	registro mensal
1019	79	2025-11-05	158597	registro mensal
1020	80	2025-11-05	105982	registro mensal
1021	81	2025-11-05	83183	registro mensal
1022	82	2025-11-05	26617	registro mensal
1023	83	2025-11-05	110204	registro mensal
1024	84	2025-11-05	41408	registro mensal
1025	85	2025-11-05	17748	registro mensal
1026	86	2025-11-05	51097	registro mensal
1027	87	2025-11-05	134970	registro mensal
1028	88	2025-11-05	142355	registro mensal
1029	89	2025-11-05	26058	registro mensal
1030	90	2025-11-05	144549	registro mensal
1031	51	2025-12-05	46260	registro mensal
1032	52	2025-12-05	131157	registro mensal
1033	53	2025-12-05	80013	registro mensal
1034	54	2025-12-05	77567	registro mensal
1035	55	2025-12-05	101336	registro mensal
1036	56	2025-12-05	120128	registro mensal
1037	57	2025-12-05	134617	registro mensal
1038	58	2025-12-05	68929	registro mensal
1039	59	2025-12-05	138421	registro mensal
1040	60	2025-12-05	61181	registro mensal
1041	61	2025-12-05	104393	registro mensal
1042	62	2025-12-05	47821	registro mensal
1043	63	2025-12-05	135727	registro mensal
1044	64	2025-12-05	115450	registro mensal
1045	65	2025-12-05	87179	registro mensal
1046	66	2025-12-05	95713	registro mensal
1047	67	2025-12-05	117415	registro mensal
1048	68	2025-12-05	82334	registro mensal
1049	69	2025-12-05	25231	registro mensal
1050	70	2025-12-05	158359	registro mensal
1051	71	2025-12-05	124037	registro mensal
1052	72	2025-12-05	38846	registro mensal
1053	73	2025-12-05	23648	registro mensal
1054	74	2025-12-05	75261	registro mensal
1055	75	2025-12-05	146669	registro mensal
1056	76	2025-12-05	104457	registro mensal
1057	77	2025-12-05	159383	registro mensal
1058	78	2025-12-05	28416	registro mensal
1059	79	2025-12-05	160460	registro mensal
1060	80	2025-12-05	108165	registro mensal
1061	81	2025-12-05	85425	registro mensal
1062	82	2025-12-05	28438	registro mensal
1063	83	2025-12-05	112215	registro mensal
1064	84	2025-12-05	43532	registro mensal
1065	85	2025-12-05	18850	registro mensal
1066	86	2025-12-05	53239	registro mensal
1067	87	2025-12-05	136175	registro mensal
1068	88	2025-12-05	143792	registro mensal
1069	89	2025-12-05	28202	registro mensal
1070	90	2025-12-05	146210	registro mensal
1071	51	2026-01-05	47545	registro mensal
1072	52	2026-01-05	132734	registro mensal
1073	53	2026-01-05	81341	registro mensal
1074	54	2026-01-05	79353	registro mensal
1075	55	2026-01-05	103457	registro mensal
1076	56	2026-01-05	121581	registro mensal
1077	57	2026-01-05	135974	registro mensal
1078	58	2026-01-05	70456	registro mensal
1079	59	2026-01-05	140333	registro mensal
1080	60	2026-01-05	62640	registro mensal
1081	61	2026-01-05	105471	registro mensal
1082	62	2026-01-05	49972	registro mensal
1083	63	2026-01-05	137133	registro mensal
1084	64	2026-01-05	116695	registro mensal
1085	65	2026-01-05	89430	registro mensal
1086	66	2026-01-05	97327	registro mensal
1087	67	2026-01-05	119332	registro mensal
1088	68	2026-01-05	84528	registro mensal
1089	69	2026-01-05	27357	registro mensal
1090	70	2026-01-05	160350	registro mensal
1091	71	2026-01-05	125099	registro mensal
1092	72	2026-01-05	40832	registro mensal
1093	73	2026-01-05	25073	registro mensal
1094	74	2026-01-05	76748	registro mensal
1095	75	2026-01-05	148748	registro mensal
1096	76	2026-01-05	106395	registro mensal
1097	77	2026-01-05	161205	registro mensal
1098	78	2026-01-05	30339	registro mensal
1099	79	2026-01-05	161898	registro mensal
1100	80	2026-01-05	109728	registro mensal
1101	81	2026-01-05	87559	registro mensal
1102	82	2026-01-05	29926	registro mensal
1103	83	2026-01-05	113746	registro mensal
1104	84	2026-01-05	44605	registro mensal
1105	85	2026-01-05	20454	registro mensal
1106	86	2026-01-05	55044	registro mensal
1107	87	2026-01-05	138200	registro mensal
1108	88	2026-01-05	145750	registro mensal
1109	89	2026-01-05	29622	registro mensal
1110	90	2026-01-05	148312	registro mensal
1111	51	2026-02-05	49433	registro mensal
1112	52	2026-02-05	134343	registro mensal
1113	53	2026-02-05	83652	registro mensal
1114	54	2026-02-05	80662	registro mensal
1115	55	2026-02-05	105480	registro mensal
1116	56	2026-02-05	122967	registro mensal
1117	57	2026-02-05	138093	registro mensal
1118	58	2026-02-05	72575	registro mensal
1119	59	2026-02-05	142110	registro mensal
1120	60	2026-02-05	64359	registro mensal
1121	61	2026-02-05	106967	registro mensal
1122	62	2026-02-05	51218	registro mensal
1123	63	2026-02-05	139079	registro mensal
1124	64	2026-02-05	119016	registro mensal
1125	65	2026-02-05	90904	registro mensal
1126	66	2026-02-05	99324	registro mensal
1127	67	2026-02-05	120896	registro mensal
1128	68	2026-02-05	86080	registro mensal
1129	69	2026-02-05	28661	registro mensal
1130	70	2026-02-05	161628	registro mensal
1131	71	2026-02-05	126863	registro mensal
1132	72	2026-02-05	43096	registro mensal
1133	73	2026-02-05	27282	registro mensal
1134	74	2026-02-05	77928	registro mensal
1135	75	2026-02-05	150607	registro mensal
1136	76	2026-02-05	108070	registro mensal
1137	77	2026-02-05	162694	registro mensal
1138	78	2026-02-05	32453	registro mensal
1139	79	2026-02-05	163361	registro mensal
1140	80	2026-02-05	111589	registro mensal
1141	81	2026-02-05	88892	registro mensal
1142	82	2026-02-05	32283	registro mensal
1143	83	2026-02-05	115857	registro mensal
1144	84	2026-02-05	45641	registro mensal
1145	85	2026-02-05	22236	registro mensal
1146	86	2026-02-05	57305	registro mensal
1147	87	2026-02-05	139584	registro mensal
1148	88	2026-02-05	146823	registro mensal
1149	89	2026-02-05	30775	registro mensal
1150	90	2026-02-05	149572	registro mensal
1151	51	2026-03-05	50831	registro mensal
1152	52	2026-03-05	135866	registro mensal
1153	53	2026-03-05	85106	registro mensal
1154	54	2026-03-05	81965	registro mensal
1155	55	2026-03-05	107190	registro mensal
1156	56	2026-03-05	125016	registro mensal
1157	57	2026-03-05	139428	registro mensal
1158	58	2026-03-05	73622	registro mensal
1159	59	2026-03-05	143915	registro mensal
1160	60	2026-03-05	66608	registro mensal
1161	61	2026-03-05	108159	registro mensal
1162	62	2026-03-05	52778	registro mensal
1163	63	2026-03-05	141389	registro mensal
1164	64	2026-03-05	120396	registro mensal
1165	65	2026-03-05	92505	registro mensal
1166	66	2026-03-05	101233	registro mensal
1167	67	2026-03-05	122411	registro mensal
1168	68	2026-03-05	87348	registro mensal
1169	69	2026-03-05	29679	registro mensal
1170	70	2026-03-05	162878	registro mensal
1171	71	2026-03-05	128643	registro mensal
1172	72	2026-03-05	44265	registro mensal
1173	73	2026-03-05	29502	registro mensal
1174	74	2026-03-05	79562	registro mensal
1175	75	2026-03-05	152869	registro mensal
1176	76	2026-03-05	110272	registro mensal
1177	77	2026-03-05	163827	registro mensal
1178	78	2026-03-05	33843	registro mensal
1179	79	2026-03-05	164377	registro mensal
1180	80	2026-03-05	112614	registro mensal
1181	81	2026-03-05	91066	registro mensal
1182	82	2026-03-05	33742	registro mensal
1183	83	2026-03-05	117898	registro mensal
1184	84	2026-03-05	46868	registro mensal
1185	85	2026-03-05	23731	registro mensal
1186	86	2026-03-05	59693	registro mensal
1187	87	2026-03-05	140793	registro mensal
1188	88	2026-03-05	147855	registro mensal
1189	89	2026-03-05	32577	registro mensal
1190	90	2026-03-05	150753	registro mensal
1191	51	2026-04-05	52263	registro mensal
1192	52	2026-04-05	138202	registro mensal
1193	53	2026-04-05	87377	registro mensal
1194	54	2026-04-05	83583	registro mensal
1195	55	2026-04-05	109284	registro mensal
1196	56	2026-04-05	127134	registro mensal
1197	57	2026-04-05	141733	registro mensal
1198	58	2026-04-05	74959	registro mensal
1199	59	2026-04-05	145991	registro mensal
1200	60	2026-04-05	68415	registro mensal
1201	61	2026-04-05	109568	registro mensal
1202	62	2026-04-05	54630	registro mensal
1203	63	2026-04-05	143211	registro mensal
1204	64	2026-04-05	122420	registro mensal
1205	65	2026-04-05	93706	registro mensal
1206	66	2026-04-05	103017	registro mensal
1207	67	2026-04-05	124649	registro mensal
1208	68	2026-04-05	89344	registro mensal
1209	69	2026-04-05	31370	registro mensal
1210	70	2026-04-05	164904	registro mensal
1211	71	2026-04-05	130865	registro mensal
1212	72	2026-04-05	46139	registro mensal
1213	73	2026-04-05	31510	registro mensal
1214	74	2026-04-05	81952	registro mensal
1215	75	2026-04-05	155043	registro mensal
1216	76	2026-04-05	111808	registro mensal
1217	77	2026-04-05	165633	registro mensal
1218	78	2026-04-05	35530	registro mensal
1219	79	2026-04-05	166541	registro mensal
1220	80	2026-04-05	114068	registro mensal
1221	81	2026-04-05	93400	registro mensal
1222	82	2026-04-05	36010	registro mensal
1223	83	2026-04-05	119144	registro mensal
1224	84	2026-04-05	48027	registro mensal
1225	85	2026-04-05	26025	registro mensal
1226	86	2026-04-05	61614	registro mensal
1227	87	2026-04-05	142497	registro mensal
1228	88	2026-04-05	149353	registro mensal
1229	89	2026-04-05	34470	registro mensal
1230	90	2026-04-05	151946	registro mensal
1231	51	2026-05-05	53320	registro mensal
1232	52	2026-05-05	139734	registro mensal
1233	53	2026-05-05	89205	registro mensal
1234	54	2026-05-05	85192	registro mensal
1235	55	2026-05-05	110458	registro mensal
1236	56	2026-05-05	128918	registro mensal
1237	57	2026-05-05	143216	registro mensal
1238	58	2026-05-05	77241	registro mensal
1239	59	2026-05-05	147840	registro mensal
1240	60	2026-05-05	70046	registro mensal
1241	61	2026-05-05	110569	registro mensal
1242	62	2026-05-05	55935	registro mensal
1243	63	2026-05-05	144848	registro mensal
1244	64	2026-05-05	123953	registro mensal
1245	65	2026-05-05	95115	registro mensal
1246	66	2026-05-05	104235	registro mensal
1247	67	2026-05-05	126760	registro mensal
1248	68	2026-05-05	91190	registro mensal
1249	69	2026-05-05	33349	registro mensal
1250	70	2026-05-05	166832	registro mensal
1251	71	2026-05-05	132073	registro mensal
1252	72	2026-05-05	48316	registro mensal
1253	73	2026-05-05	33639	registro mensal
1254	74	2026-05-05	83620	registro mensal
1255	75	2026-05-05	156877	registro mensal
1256	76	2026-05-05	113660	registro mensal
1257	77	2026-05-05	167477	registro mensal
1258	78	2026-05-05	37211	registro mensal
1259	79	2026-05-05	168644	registro mensal
1260	80	2026-05-05	116131	registro mensal
1261	81	2026-05-05	94514	registro mensal
1262	82	2026-05-05	37964	registro mensal
1263	83	2026-05-05	120274	registro mensal
1264	84	2026-05-05	49436	registro mensal
1265	85	2026-05-05	28067	registro mensal
1266	86	2026-05-05	63397	registro mensal
1267	87	2026-05-05	144354	registro mensal
1268	88	2026-05-05	151154	registro mensal
1269	89	2026-05-05	36779	registro mensal
1270	90	2026-05-05	153058	registro mensal
1271	51	2026-06-05	54835	registro mensal
1272	52	2026-06-05	141565	registro mensal
1273	53	2026-06-05	91463	registro mensal
1274	54	2026-06-05	87082	registro mensal
1275	55	2026-06-05	112563	registro mensal
1276	56	2026-06-05	131117	registro mensal
1277	57	2026-06-05	145329	registro mensal
1278	58	2026-06-05	78789	registro mensal
1279	59	2026-06-05	149857	registro mensal
1280	60	2026-06-05	72069	registro mensal
1281	61	2026-06-05	111646	registro mensal
1282	62	2026-06-05	57215	registro mensal
1283	63	2026-06-05	146824	registro mensal
1284	64	2026-06-05	125641	registro mensal
1285	65	2026-06-05	96607	registro mensal
1286	66	2026-06-05	106126	registro mensal
1287	67	2026-06-05	128135	registro mensal
1288	68	2026-06-05	92931	registro mensal
1289	69	2026-06-05	35163	registro mensal
1290	70	2026-06-05	168981	registro mensal
1291	71	2026-06-05	134409	registro mensal
1292	72	2026-06-05	49920	registro mensal
1293	73	2026-06-05	35730	registro mensal
1294	74	2026-06-05	84829	registro mensal
1295	75	2026-06-05	158598	registro mensal
1296	76	2026-06-05	114928	registro mensal
1297	77	2026-06-05	169187	registro mensal
1298	78	2026-06-05	38219	registro mensal
1299	79	2026-06-05	170427	registro mensal
1300	80	2026-06-05	117441	registro mensal
1301	81	2026-06-05	96566	registro mensal
1302	82	2026-06-05	39484	registro mensal
1303	83	2026-06-05	122119	registro mensal
1304	84	2026-06-05	50912	registro mensal
1305	85	2026-06-05	29102	registro mensal
1306	86	2026-06-05	64564	registro mensal
1307	87	2026-06-05	146211	registro mensal
1308	88	2026-06-05	152878	registro mensal
1309	89	2026-06-05	38984	registro mensal
1310	90	2026-06-05	155318	registro mensal
1311	51	2026-07-05	56270	registro mensal
1312	52	2026-07-05	143908	registro mensal
1313	53	2026-07-05	92864	registro mensal
1314	54	2026-07-05	88642	registro mensal
1315	55	2026-07-05	114696	registro mensal
1316	56	2026-07-05	132928	registro mensal
1317	57	2026-07-05	146862	registro mensal
1318	58	2026-07-05	80274	registro mensal
1319	59	2026-07-05	152173	registro mensal
1320	60	2026-07-05	73721	registro mensal
1321	61	2026-07-05	113601	registro mensal
1322	62	2026-07-05	59284	registro mensal
1323	63	2026-07-05	148598	registro mensal
1324	64	2026-07-05	126977	registro mensal
1325	65	2026-07-05	98084	registro mensal
1326	66	2026-07-05	107593	registro mensal
1327	67	2026-07-05	129412	registro mensal
1328	68	2026-07-05	93937	registro mensal
1329	69	2026-07-05	36926	registro mensal
1330	70	2026-07-05	170221	registro mensal
1331	71	2026-07-05	136679	registro mensal
1332	72	2026-07-05	51879	registro mensal
1333	73	2026-07-05	37272	registro mensal
1334	74	2026-07-05	86229	registro mensal
1335	75	2026-07-05	160083	registro mensal
1336	76	2026-07-05	116301	registro mensal
1337	77	2026-07-05	170834	registro mensal
1338	78	2026-07-05	40013	registro mensal
1339	79	2026-07-05	172165	registro mensal
1340	80	2026-07-05	119602	registro mensal
1341	81	2026-07-05	97721	registro mensal
1342	82	2026-07-05	41481	registro mensal
1343	83	2026-07-05	124337	registro mensal
1344	84	2026-07-05	53169	registro mensal
1345	85	2026-07-05	31448	registro mensal
1346	86	2026-07-05	66925	registro mensal
1347	87	2026-07-05	147619	registro mensal
1348	88	2026-07-05	154987	registro mensal
1349	89	2026-07-05	41136	registro mensal
1350	90	2026-07-05	157475	registro mensal
1351	51	2026-08-05	57869	registro mensal
1352	52	2026-08-05	145396	registro mensal
1353	53	2026-08-05	94832	registro mensal
1354	54	2026-08-05	90043	registro mensal
1355	55	2026-08-05	116688	registro mensal
1356	56	2026-08-05	133952	registro mensal
1357	57	2026-08-05	148373	registro mensal
1358	58	2026-08-05	81315	registro mensal
1359	59	2026-08-05	153225	registro mensal
1360	60	2026-08-05	75758	registro mensal
1361	61	2026-08-05	114700	registro mensal
1362	62	2026-08-05	60561	registro mensal
1363	63	2026-08-05	150232	registro mensal
1364	64	2026-08-05	128312	registro mensal
1365	65	2026-08-05	100049	registro mensal
1366	66	2026-08-05	109371	registro mensal
1367	67	2026-08-05	131670	registro mensal
1368	68	2026-08-05	95827	registro mensal
1369	69	2026-08-05	39086	registro mensal
1370	70	2026-08-05	171231	registro mensal
1371	71	2026-08-05	138703	registro mensal
1372	72	2026-08-05	54277	registro mensal
1373	73	2026-08-05	38840	registro mensal
1374	74	2026-08-05	88609	registro mensal
1375	75	2026-08-05	161919	registro mensal
1376	76	2026-08-05	117744	registro mensal
1377	77	2026-08-05	172213	registro mensal
1378	78	2026-08-05	41209	registro mensal
1379	79	2026-08-05	173982	registro mensal
1380	80	2026-08-05	121649	registro mensal
1381	81	2026-08-05	99720	registro mensal
1382	82	2026-08-05	42580	registro mensal
1383	83	2026-08-05	126031	registro mensal
1384	84	2026-08-05	54348	registro mensal
1385	85	2026-08-05	32479	registro mensal
1386	86	2026-08-05	68156	registro mensal
1387	87	2026-08-05	148799	registro mensal
1388	88	2026-08-05	157095	registro mensal
1389	89	2026-08-05	43351	registro mensal
1390	90	2026-08-05	159748	registro mensal
1391	51	2026-09-05	59895	registro mensal
1392	52	2026-09-05	147012	registro mensal
1393	53	2026-09-05	96206	registro mensal
1394	54	2026-09-05	91266	registro mensal
1395	55	2026-09-05	118469	registro mensal
1396	56	2026-09-05	135674	registro mensal
1397	57	2026-09-05	149494	registro mensal
1398	58	2026-09-05	82762	registro mensal
1399	59	2026-09-05	154445	registro mensal
1400	60	2026-09-05	78000	registro mensal
1401	61	2026-09-05	116523	registro mensal
1402	62	2026-09-05	62751	registro mensal
1403	63	2026-09-05	152539	registro mensal
1404	64	2026-09-05	129768	registro mensal
1405	65	2026-09-05	102249	registro mensal
1406	66	2026-09-05	110780	registro mensal
1407	67	2026-09-05	133431	registro mensal
1408	68	2026-09-05	97685	registro mensal
1409	69	2026-09-05	40142	registro mensal
1410	70	2026-09-05	172885	registro mensal
1411	71	2026-09-05	139791	registro mensal
1412	72	2026-09-05	55366	registro mensal
1413	73	2026-09-05	40284	registro mensal
1414	74	2026-09-05	90780	registro mensal
1415	75	2026-09-05	164140	registro mensal
1416	76	2026-09-05	119609	registro mensal
1417	77	2026-09-05	174316	registro mensal
1418	78	2026-09-05	43271	registro mensal
1419	79	2026-09-05	175935	registro mensal
1420	80	2026-09-05	122676	registro mensal
1421	81	2026-09-05	101378	registro mensal
1422	82	2026-09-05	44015	registro mensal
1423	83	2026-09-05	127494	registro mensal
1424	84	2026-09-05	56090	registro mensal
1425	85	2026-09-05	34695	registro mensal
1426	86	2026-09-05	69868	registro mensal
1427	87	2026-09-05	150437	registro mensal
1428	88	2026-09-05	159014	registro mensal
1429	89	2026-09-05	45027	registro mensal
1430	90	2026-09-05	160803	registro mensal
1431	51	2026-10-05	61387	registro mensal
1432	52	2026-10-05	149001	registro mensal
1433	53	2026-10-05	98363	registro mensal
1434	54	2026-10-05	93572	registro mensal
1435	55	2026-10-05	119879	registro mensal
1436	56	2026-10-05	137006	registro mensal
1437	57	2026-10-05	150838	registro mensal
1438	58	2026-10-05	83859	registro mensal
1439	59	2026-10-05	156659	registro mensal
1440	60	2026-10-05	79387	registro mensal
1441	61	2026-10-05	118015	registro mensal
1442	62	2026-10-05	64408	registro mensal
1443	63	2026-10-05	154833	registro mensal
1444	64	2026-10-05	131738	registro mensal
1445	65	2026-10-05	104425	registro mensal
1446	66	2026-10-05	112438	registro mensal
1447	67	2026-10-05	134742	registro mensal
1448	68	2026-10-05	98801	registro mensal
1449	69	2026-10-05	42470	registro mensal
1450	70	2026-10-05	174262	registro mensal
1451	71	2026-10-05	140864	registro mensal
1452	72	2026-10-05	57179	registro mensal
1453	73	2026-10-05	42341	registro mensal
1454	74	2026-10-05	92284	registro mensal
1455	75	2026-10-05	165499	registro mensal
1456	76	2026-10-05	121675	registro mensal
1457	77	2026-10-05	176274	registro mensal
1458	78	2026-10-05	44705	registro mensal
1459	79	2026-10-05	177637	registro mensal
1460	80	2026-10-05	124907	registro mensal
1461	81	2026-10-05	103229	registro mensal
1462	82	2026-10-05	45746	registro mensal
1463	83	2026-10-05	128969	registro mensal
1464	84	2026-10-05	57422	registro mensal
1465	85	2026-10-05	36807	registro mensal
1466	86	2026-10-05	70994	registro mensal
1467	87	2026-10-05	152381	registro mensal
1468	88	2026-10-05	160027	registro mensal
1469	89	2026-10-05	46607	registro mensal
1470	90	2026-10-05	162258	registro mensal
1472	2	2027-05-24	84935	Leitura periódica de hodômetro - lote extra 2
1473	3	2027-05-25	86697	Leitura periódica de hodômetro - lote extra 3
1474	4	2027-05-26	88459	Leitura periódica de hodômetro - lote extra 4
1475	5	2027-05-27	90221	Leitura periódica de hodômetro - lote extra 5
1476	6	2027-05-28	104483	Leitura periódica de hodômetro - lote extra 6
1477	7	2027-05-29	93745	Leitura periódica de hodômetro - lote extra 7
1478	8	2027-05-30	95507	Leitura periódica de hodômetro - lote extra 8
1479	9	2027-05-31	132369	Leitura periódica de hodômetro - lote extra 9
1480	10	2027-06-01	160331	Leitura periódica de hodômetro - lote extra 10
1481	11	2027-06-02	100313	Leitura periódica de hodômetro - lote extra 11
1482	12	2027-06-03	102065	Leitura periódica de hodômetro - lote extra 12
1483	13	2027-06-04	103817	Leitura periódica de hodômetro - lote extra 13
1484	14	2027-06-05	105569	Leitura periódica de hodômetro - lote extra 14
1485	15	2027-06-06	107321	Leitura periódica de hodômetro - lote extra 15
1486	16	2027-06-07	109073	Leitura periódica de hodômetro - lote extra 16
1487	17	2027-06-08	110825	Leitura periódica de hodômetro - lote extra 17
1488	18	2027-06-09	112577	Leitura periódica de hodômetro - lote extra 18
1489	19	2027-06-10	114329	Leitura periódica de hodômetro - lote extra 19
1490	20	2027-06-11	116081	Leitura periódica de hodômetro - lote extra 20
1491	21	2027-06-12	114633	Leitura periódica de hodômetro - lote extra 21
1492	22	2027-06-13	116378	Leitura periódica de hodômetro - lote extra 22
1493	23	2027-06-14	118123	Leitura periódica de hodômetro - lote extra 23
1494	24	2027-06-15	119868	Leitura periódica de hodômetro - lote extra 24
1495	25	2027-06-16	121613	Leitura periódica de hodômetro - lote extra 25
1496	26	2027-06-17	123358	Leitura periódica de hodômetro - lote extra 26
1497	27	2027-06-18	125103	Leitura periódica de hodômetro - lote extra 27
1498	28	2027-06-19	126848	Leitura periódica de hodômetro - lote extra 28
1499	29	2027-06-20	128593	Leitura periódica de hodômetro - lote extra 29
1500	30	2027-06-21	130338	Leitura periódica de hodômetro - lote extra 30
1501	1	2027-06-22	83516	Leitura periódica de hodômetro - lote extra 31
1502	2	2027-06-23	85281	Leitura periódica de hodômetro - lote extra 32
1503	3	2027-06-24	87046	Leitura periódica de hodômetro - lote extra 33
1504	4	2027-06-25	88811	Leitura periódica de hodômetro - lote extra 34
1505	5	2027-06-26	90576	Leitura periódica de hodômetro - lote extra 35
1506	6	2027-06-27	104841	Leitura periódica de hodômetro - lote extra 36
1507	7	2027-06-28	94106	Leitura periódica de hodômetro - lote extra 37
1508	8	2027-06-29	95871	Leitura periódica de hodômetro - lote extra 38
1509	9	2027-06-30	132736	Leitura periódica de hodômetro - lote extra 39
1510	10	2027-07-01	160701	Leitura periódica de hodômetro - lote extra 40
1511	11	2027-07-02	100686	Leitura periódica de hodômetro - lote extra 41
1512	12	2027-07-03	102441	Leitura periódica de hodômetro - lote extra 42
1513	13	2027-07-04	104196	Leitura periódica de hodômetro - lote extra 43
1514	14	2027-07-05	105951	Leitura periódica de hodômetro - lote extra 44
1515	15	2027-07-06	107706	Leitura periódica de hodômetro - lote extra 45
1516	16	2027-07-07	109461	Leitura periódica de hodômetro - lote extra 46
1517	17	2027-07-08	111216	Leitura periódica de hodômetro - lote extra 47
1518	18	2027-07-09	112971	Leitura periódica de hodômetro - lote extra 48
1519	19	2027-07-10	114726	Leitura periódica de hodômetro - lote extra 49
1520	20	2027-07-11	116481	Leitura periódica de hodômetro - lote extra 50
1521	21	2027-07-12	115036	Leitura periódica de hodômetro - lote extra 51
1522	22	2027-07-13	116784	Leitura periódica de hodômetro - lote extra 52
1523	23	2027-07-14	118532	Leitura periódica de hodômetro - lote extra 53
1524	24	2027-07-15	120280	Leitura periódica de hodômetro - lote extra 54
1525	25	2027-07-16	122028	Leitura periódica de hodômetro - lote extra 55
1526	26	2027-07-17	123776	Leitura periódica de hodômetro - lote extra 56
1527	27	2027-07-18	125524	Leitura periódica de hodômetro - lote extra 57
1528	28	2027-07-19	127272	Leitura periódica de hodômetro - lote extra 58
1529	29	2027-07-20	129020	Leitura periódica de hodômetro - lote extra 59
1530	30	2027-07-21	130768	Leitura periódica de hodômetro - lote extra 60
1531	1	2027-07-22	83949	Leitura periódica de hodômetro - lote extra 61
1532	2	2027-07-23	85717	Leitura periódica de hodômetro - lote extra 62
1533	3	2027-07-24	87485	Leitura periódica de hodômetro - lote extra 63
1534	4	2027-07-25	89253	Leitura periódica de hodômetro - lote extra 64
1535	5	2027-07-26	91021	Leitura periódica de hodômetro - lote extra 65
1536	6	2027-07-27	105289	Leitura periódica de hodômetro - lote extra 66
1537	7	2027-07-28	94557	Leitura periódica de hodômetro - lote extra 67
1538	8	2027-07-29	96325	Leitura periódica de hodômetro - lote extra 68
1539	9	2027-07-30	133193	Leitura periódica de hodômetro - lote extra 69
1540	10	2027-07-31	161161	Leitura periódica de hodômetro - lote extra 70
1541	11	2027-08-01	101149	Leitura periódica de hodômetro - lote extra 71
1542	12	2027-08-02	102907	Leitura periódica de hodômetro - lote extra 72
1543	13	2027-08-03	104665	Leitura periódica de hodômetro - lote extra 73
1544	14	2027-08-04	106423	Leitura periódica de hodômetro - lote extra 74
1545	15	2027-08-05	108181	Leitura periódica de hodômetro - lote extra 75
1546	16	2027-08-06	109939	Leitura periódica de hodômetro - lote extra 76
1547	17	2027-08-07	111697	Leitura periódica de hodômetro - lote extra 77
1548	18	2027-08-08	113455	Leitura periódica de hodômetro - lote extra 78
1549	19	2027-08-09	115213	Leitura periódica de hodômetro - lote extra 79
1550	20	2027-08-10	116971	Leitura periódica de hodômetro - lote extra 80
1551	21	2027-08-11	115529	Leitura periódica de hodômetro - lote extra 81
1552	22	2027-08-12	117280	Leitura periódica de hodômetro - lote extra 82
1553	23	2027-08-13	119031	Leitura periódica de hodômetro - lote extra 83
1554	24	2027-08-14	120782	Leitura periódica de hodômetro - lote extra 84
1555	25	2027-08-15	122533	Leitura periódica de hodômetro - lote extra 85
1556	26	2027-08-16	124284	Leitura periódica de hodômetro - lote extra 86
1557	27	2027-08-17	126035	Leitura periódica de hodômetro - lote extra 87
1558	28	2027-08-18	127786	Leitura periódica de hodômetro - lote extra 88
1559	29	2027-08-19	129537	Leitura periódica de hodômetro - lote extra 89
1560	30	2027-08-20	131288	Leitura periódica de hodômetro - lote extra 90
1561	1	2027-08-21	84472	Leitura periódica de hodômetro - lote extra 91
1562	2	2027-08-22	86243	Leitura periódica de hodômetro - lote extra 92
1563	3	2027-08-23	88014	Leitura periódica de hodômetro - lote extra 93
1564	4	2027-08-24	89785	Leitura periódica de hodômetro - lote extra 94
1565	5	2027-08-25	91556	Leitura periódica de hodômetro - lote extra 95
1566	6	2027-08-26	105827	Leitura periódica de hodômetro - lote extra 96
1567	7	2027-08-27	95098	Leitura periódica de hodômetro - lote extra 97
1568	8	2027-08-28	96869	Leitura periódica de hodômetro - lote extra 98
1569	9	2027-08-29	133740	Leitura periódica de hodômetro - lote extra 99
1570	10	2027-08-30	161711	Leitura periódica de hodômetro - lote extra 100
1571	11	2027-08-31	101702	Leitura periódica de hodômetro - lote extra 101
1572	12	2027-09-01	103463	Leitura periódica de hodômetro - lote extra 102
1573	13	2027-09-02	105224	Leitura periódica de hodômetro - lote extra 103
1574	14	2027-09-03	106985	Leitura periódica de hodômetro - lote extra 104
1575	15	2027-09-04	108746	Leitura periódica de hodômetro - lote extra 105
1576	16	2027-09-05	110507	Leitura periódica de hodômetro - lote extra 106
1577	17	2027-09-06	112268	Leitura periódica de hodômetro - lote extra 107
1578	18	2027-09-07	114029	Leitura periódica de hodômetro - lote extra 108
1579	19	2027-09-08	115790	Leitura periódica de hodômetro - lote extra 109
1580	20	2027-09-09	117551	Leitura periódica de hodômetro - lote extra 110
1581	21	2027-09-10	116112	Leitura periódica de hodômetro - lote extra 111
1582	22	2027-09-11	117866	Leitura periódica de hodômetro - lote extra 112
1583	23	2027-09-12	119620	Leitura periódica de hodômetro - lote extra 113
1584	24	2027-09-13	121374	Leitura periódica de hodômetro - lote extra 114
1585	25	2027-09-14	123128	Leitura periódica de hodômetro - lote extra 115
1586	26	2027-09-15	124882	Leitura periódica de hodômetro - lote extra 116
1587	27	2027-09-16	126636	Leitura periódica de hodômetro - lote extra 117
1588	28	2027-09-17	128390	Leitura periódica de hodômetro - lote extra 118
1589	29	2027-09-18	130144	Leitura periódica de hodômetro - lote extra 119
1590	30	2027-09-19	131898	Leitura periódica de hodômetro - lote extra 120
1591	1	2027-09-20	85085	Leitura periódica de hodômetro - lote extra 121
1592	2	2027-09-21	86859	Leitura periódica de hodômetro - lote extra 122
1593	3	2027-09-22	88633	Leitura periódica de hodômetro - lote extra 123
1594	4	2027-09-23	90407	Leitura periódica de hodômetro - lote extra 124
1595	5	2027-09-24	92181	Leitura periódica de hodômetro - lote extra 125
1596	6	2027-09-25	106455	Leitura periódica de hodômetro - lote extra 126
1597	7	2027-09-26	95729	Leitura periódica de hodômetro - lote extra 127
1598	8	2027-09-27	97503	Leitura periódica de hodômetro - lote extra 128
1599	9	2027-09-28	134377	Leitura periódica de hodômetro - lote extra 129
1600	10	2027-09-29	162351	Leitura periódica de hodômetro - lote extra 130
1601	11	2027-09-30	102345	Leitura periódica de hodômetro - lote extra 131
1602	12	2027-10-01	104109	Leitura periódica de hodômetro - lote extra 132
1603	13	2027-10-02	105873	Leitura periódica de hodômetro - lote extra 133
1604	14	2027-10-03	107637	Leitura periódica de hodômetro - lote extra 134
1605	15	2027-10-04	109401	Leitura periódica de hodômetro - lote extra 135
1606	16	2027-10-05	111165	Leitura periódica de hodômetro - lote extra 136
1607	17	2027-10-06	112929	Leitura periódica de hodômetro - lote extra 137
1608	18	2027-10-07	114693	Leitura periódica de hodômetro - lote extra 138
1609	19	2027-10-08	116457	Leitura periódica de hodômetro - lote extra 139
1610	20	2027-10-09	118221	Leitura periódica de hodômetro - lote extra 140
1611	21	2027-10-10	116785	Leitura periódica de hodômetro - lote extra 141
1612	22	2027-10-11	118542	Leitura periódica de hodômetro - lote extra 142
1613	23	2027-10-12	120299	Leitura periódica de hodômetro - lote extra 143
1614	24	2027-10-13	122056	Leitura periódica de hodômetro - lote extra 144
1615	25	2027-10-14	123813	Leitura periódica de hodômetro - lote extra 145
1616	26	2027-10-15	125570	Leitura periódica de hodômetro - lote extra 146
1617	27	2027-10-16	127327	Leitura periódica de hodômetro - lote extra 147
1618	28	2027-10-17	129084	Leitura periódica de hodômetro - lote extra 148
1619	29	2027-10-18	130841	Leitura periódica de hodômetro - lote extra 149
1620	30	2027-10-19	132598	Leitura periódica de hodômetro - lote extra 150
1621	1	2027-10-20	85788	Leitura periódica de hodômetro - lote extra 151
1622	2	2027-10-21	87565	Leitura periódica de hodômetro - lote extra 152
1623	3	2027-10-22	89342	Leitura periódica de hodômetro - lote extra 153
1624	4	2027-10-23	91119	Leitura periódica de hodômetro - lote extra 154
1625	5	2027-10-24	92896	Leitura periódica de hodômetro - lote extra 155
1626	6	2027-10-25	107173	Leitura periódica de hodômetro - lote extra 156
1627	7	2027-10-26	96450	Leitura periódica de hodômetro - lote extra 157
1628	8	2027-10-27	98227	Leitura periódica de hodômetro - lote extra 158
1629	9	2027-10-28	135104	Leitura periódica de hodômetro - lote extra 159
1630	10	2027-10-29	163081	Leitura periódica de hodômetro - lote extra 160
1631	11	2027-10-30	103078	Leitura periódica de hodômetro - lote extra 161
1632	12	2027-10-31	104845	Leitura periódica de hodômetro - lote extra 162
1633	13	2027-11-01	106612	Leitura periódica de hodômetro - lote extra 163
1634	14	2027-11-02	108379	Leitura periódica de hodômetro - lote extra 164
1635	15	2027-11-03	110146	Leitura periódica de hodômetro - lote extra 165
1636	16	2027-11-04	111913	Leitura periódica de hodômetro - lote extra 166
1637	17	2027-11-05	113680	Leitura periódica de hodômetro - lote extra 167
1638	18	2027-11-06	115447	Leitura periódica de hodômetro - lote extra 168
1639	19	2027-11-07	117214	Leitura periódica de hodômetro - lote extra 169
1640	20	2027-11-08	118981	Leitura periódica de hodômetro - lote extra 170
1641	21	2027-11-09	117548	Leitura periódica de hodômetro - lote extra 171
1642	22	2027-11-10	119308	Leitura periódica de hodômetro - lote extra 172
1643	23	2027-11-11	121068	Leitura periódica de hodômetro - lote extra 173
1644	24	2027-11-12	122828	Leitura periódica de hodômetro - lote extra 174
1645	25	2027-11-13	124588	Leitura periódica de hodômetro - lote extra 175
1646	26	2027-11-14	126348	Leitura periódica de hodômetro - lote extra 176
1647	27	2027-11-15	128108	Leitura periódica de hodômetro - lote extra 177
1648	28	2027-11-16	129868	Leitura periódica de hodômetro - lote extra 178
1649	29	2027-11-17	131628	Leitura periódica de hodômetro - lote extra 179
1650	30	2027-11-18	133388	Leitura periódica de hodômetro - lote extra 180
1651	1	2027-11-19	86581	Leitura periódica de hodômetro - lote extra 181
1652	2	2027-11-20	88361	Leitura periódica de hodômetro - lote extra 182
1653	3	2027-11-21	90141	Leitura periódica de hodômetro - lote extra 183
1654	4	2027-11-22	91921	Leitura periódica de hodômetro - lote extra 184
1655	5	2027-11-23	93701	Leitura periódica de hodômetro - lote extra 185
1656	6	2027-11-24	107981	Leitura periódica de hodômetro - lote extra 186
1657	7	2027-11-25	97261	Leitura periódica de hodômetro - lote extra 187
1658	8	2027-11-26	99041	Leitura periódica de hodômetro - lote extra 188
1659	9	2027-11-27	135921	Leitura periódica de hodômetro - lote extra 189
1660	10	2027-11-28	163901	Leitura periódica de hodômetro - lote extra 190
1661	11	2027-11-29	103901	Leitura periódica de hodômetro - lote extra 191
1662	12	2027-11-30	105671	Leitura periódica de hodômetro - lote extra 192
1663	13	2027-12-01	107441	Leitura periódica de hodômetro - lote extra 193
1664	14	2027-12-02	109211	Leitura periódica de hodômetro - lote extra 194
1665	15	2027-12-03	110981	Leitura periódica de hodômetro - lote extra 195
1666	16	2027-12-04	112751	Leitura periódica de hodômetro - lote extra 196
1667	17	2027-12-05	114521	Leitura periódica de hodômetro - lote extra 197
1668	18	2027-12-06	116291	Leitura periódica de hodômetro - lote extra 198
1669	19	2027-12-07	118061	Leitura periódica de hodômetro - lote extra 199
1670	20	2027-12-08	119831	Leitura periódica de hodômetro - lote extra 200
1671	25	2025-06-29	278626	Leitura de rotina - lote 3 registro 1
1672	42	2024-11-21	126499	Leitura de rotina - lote 3 registro 2
1673	76	2025-03-06	225577	Leitura de rotina - lote 3 registro 3
1674	160	2024-03-28	246947	Leitura de rotina - lote 3 registro 4
1675	70	2026-05-21	286500	Leitura de rotina - lote 3 registro 5
1676	18	2026-06-23	122815	Leitura de rotina - lote 3 registro 6
1677	26	2026-09-20	150515	Leitura de rotina - lote 3 registro 7
1678	82	2024-11-07	227013	Leitura de rotina - lote 3 registro 9
1679	30	2024-10-16	180818	Leitura de rotina - lote 3 registro 10
1680	22	2024-02-08	177055	Leitura de rotina - lote 3 registro 11
1681	20	2024-03-26	288513	Leitura de rotina - lote 3 registro 12
1682	56	2025-06-05	205526	Leitura de rotina - lote 3 registro 13
1683	176	2025-12-06	276125	Leitura de rotina - lote 3 registro 14
1684	130	2025-07-14	205098	Leitura de rotina - lote 3 registro 15
1685	12	2024-11-23	112359	Leitura de rotina - lote 3 registro 16
1686	72	2026-10-09	292163	Leitura de rotina - lote 3 registro 17
1687	153	2025-02-02	201816	Leitura de rotina - lote 3 registro 18
1688	42	2025-04-16	209317	Leitura de rotina - lote 3 registro 19
1689	34	2025-08-22	286591	Leitura de rotina - lote 3 registro 20
1690	88	2024-05-30	161731	Leitura de rotina - lote 3 registro 21
1691	28	2025-08-19	198084	Leitura de rotina - lote 3 registro 22
1692	70	2025-12-14	308534	Leitura de rotina - lote 3 registro 23
1693	84	2026-09-06	142937	Leitura de rotina - lote 3 registro 24
1694	181	2025-03-07	270644	Leitura de rotina - lote 3 registro 25
1695	146	2025-01-18	216759	Leitura de rotina - lote 3 registro 26
1696	41	2024-04-11	234020	Leitura de rotina - lote 3 registro 27
1697	55	2024-04-27	276268	Leitura de rotina - lote 3 registro 28
1698	117	2024-02-10	215824	Leitura de rotina - lote 3 registro 29
1699	123	2025-10-23	197823	Leitura de rotina - lote 3 registro 30
1700	158	2026-09-13	277695	Leitura de rotina - lote 3 registro 31
1701	25	2025-11-09	278626	Leitura de rotina - lote 3 registro 32
1702	2	2024-03-31	192872	Leitura de rotina - lote 3 registro 33
1703	13	2025-06-18	283352	Leitura de rotina - lote 3 registro 34
1704	173	2024-05-28	181681	Leitura de rotina - lote 3 registro 35
1705	72	2026-10-06	292163	Leitura de rotina - lote 3 registro 36
1706	158	2026-04-10	295941	Leitura de rotina - lote 3 registro 37
1707	178	2024-02-24	58693	Leitura de rotina - lote 3 registro 38
1708	8	2024-08-29	193143	Leitura de rotina - lote 3 registro 39
1709	5	2025-10-31	224255	Leitura de rotina - lote 3 registro 40
1710	124	2024-03-05	249376	Leitura de rotina - lote 3 registro 41
1711	157	2026-06-03	168792	Leitura de rotina - lote 3 registro 42
1712	124	2026-02-20	249376	Leitura de rotina - lote 3 registro 43
1713	32	2026-02-04	116702	Leitura de rotina - lote 3 registro 44
1714	184	2026-01-13	273445	Leitura de rotina - lote 3 registro 46
1715	122	2026-08-18	132582	Leitura de rotina - lote 3 registro 47
1716	142	2024-05-23	277838	Leitura de rotina - lote 3 registro 48
1717	155	2025-03-01	187877	Leitura de rotina - lote 3 registro 49
1718	152	2025-09-10	295796	Leitura de rotina - lote 3 registro 50
1719	72	2026-10-06	292163	Leitura de rotina - lote 3 registro 52
1720	184	2026-10-22	310297	Leitura de rotina - lote 3 registro 53
1721	85	2025-12-21	277000	Leitura de rotina - lote 3 registro 54
1722	98	2024-04-20	253043	Leitura de rotina - lote 3 registro 55
1723	70	2024-05-31	308534	Leitura de rotina - lote 3 registro 56
1724	34	2024-08-01	286591	Leitura de rotina - lote 3 registro 57
1725	156	2025-10-19	287972	Leitura de rotina - lote 3 registro 58
1726	107	2024-11-04	259205	Leitura de rotina - lote 3 registro 59
1727	31	2026-02-02	228267	Leitura de rotina - lote 3 registro 60
1728	33	2025-05-05	292449	Leitura de rotina - lote 3 registro 61
1729	39	2024-03-21	202503	Leitura de rotina - lote 3 registro 62
1730	67	2025-05-31	252148	Leitura de rotina - lote 3 registro 65
1731	102	2025-09-28	268063	Leitura de rotina - lote 3 registro 66
1732	93	2026-04-19	188535	Leitura de rotina - lote 3 registro 67
1733	143	2026-05-26	106986	Leitura de rotina - lote 3 registro 68
1734	118	2024-02-29	289578	Leitura de rotina - lote 3 registro 69
1735	124	2024-06-10	264430	Leitura de rotina - lote 3 registro 71
1736	98	2025-09-30	253043	Leitura de rotina - lote 3 registro 72
1737	118	2026-05-04	289578	Leitura de rotina - lote 3 registro 73
1738	47	2024-07-09	299110	Leitura de rotina - lote 3 registro 74
1739	160	2024-07-25	246947	Leitura de rotina - lote 3 registro 75
1740	93	2025-08-27	188535	Leitura de rotina - lote 3 registro 76
1741	10	2024-06-08	295031	Leitura de rotina - lote 3 registro 77
1742	103	2025-09-08	295659	Leitura de rotina - lote 3 registro 78
1743	109	2025-12-08	249082	Leitura de rotina - lote 3 registro 79
1744	129	2026-02-15	269161	Leitura de rotina - lote 3 registro 80
1745	97	2024-08-25	239033	Leitura de rotina - lote 3 registro 81
1746	150	2025-06-05	214341	Leitura de rotina - lote 3 registro 82
1747	85	2026-02-23	277000	Leitura de rotina - lote 3 registro 83
1748	182	2026-02-01	313010	Leitura de rotina - lote 3 registro 84
1749	64	2025-04-14	298669	Leitura de rotina - lote 3 registro 85
1750	148	2025-04-06	298488	Leitura de rotina - lote 3 registro 86
1751	174	2025-01-13	268268	Leitura de rotina - lote 3 registro 87
1752	99	2025-08-04	287275	Leitura de rotina - lote 3 registro 88
1753	99	2026-02-24	287275	Leitura de rotina - lote 3 registro 89
1754	6	2024-04-20	260917	Leitura de rotina - lote 3 registro 90
1755	148	2026-04-11	298488	Leitura de rotina - lote 3 registro 91
1756	178	2024-04-17	192727	Leitura de rotina - lote 3 registro 92
1757	136	2024-06-11	201015	Leitura de rotina - lote 3 registro 93
1758	12	2026-03-05	112359	Leitura de rotina - lote 3 registro 94
1759	84	2024-12-18	172023	Leitura de rotina - lote 3 registro 95
1760	76	2025-11-18	225577	Leitura de rotina - lote 3 registro 96
1761	34	2025-10-17	286591	Leitura de rotina - lote 3 registro 97
1762	31	2025-02-26	258937	Leitura de rotina - lote 3 registro 99
1763	136	2025-07-27	201015	Leitura de rotina - lote 3 registro 100
1764	131	2026-01-24	162834	Leitura de rotina - lote 3 registro 101
1765	36	2024-09-15	93001	Leitura de rotina - lote 3 registro 102
1766	183	2026-07-26	253709	Leitura de rotina - lote 3 registro 103
1767	125	2024-11-09	247167	Leitura de rotina - lote 3 registro 104
1768	129	2024-04-16	269161	Leitura de rotina - lote 3 registro 105
1769	52	2024-02-15	289179	Leitura de rotina - lote 3 registro 106
1770	156	2025-12-05	314464	Leitura de rotina - lote 3 registro 107
1771	3	2025-09-10	311967	Leitura de rotina - lote 3 registro 108
1772	105	2024-10-11	226984	Leitura de rotina - lote 3 registro 109
1773	1	2025-05-10	252493	Leitura de rotina - lote 3 registro 110
1774	105	2025-08-12	226984	Leitura de rotina - lote 3 registro 111
1775	95	2024-05-21	209194	Leitura de rotina - lote 3 registro 112
1776	56	2026-01-05	301949	Leitura de rotina - lote 3 registro 113
1777	169	2025-05-08	146192	Leitura de rotina - lote 3 registro 114
1778	97	2025-06-11	239033	Leitura de rotina - lote 3 registro 115
1779	94	2024-10-21	126988	Leitura de rotina - lote 3 registro 116
1780	128	2025-02-08	281773	Leitura de rotina - lote 3 registro 117
1781	183	2024-09-17	253709	Leitura de rotina - lote 3 registro 118
1782	139	2026-06-24	193126	Leitura de rotina - lote 3 registro 119
1783	87	2026-08-21	232389	Leitura de rotina - lote 3 registro 120
1784	119	2024-10-23	298843	Leitura de rotina - lote 3 registro 121
1785	71	2024-05-20	231791	Leitura de rotina - lote 3 registro 122
1786	64	2024-05-23	309221	Leitura de rotina - lote 3 registro 123
1787	77	2025-03-21	178069	Leitura de rotina - lote 3 registro 124
1788	60	2025-03-08	184760	Leitura de rotina - lote 3 registro 126
1789	186	2024-10-30	207358	Leitura de rotina - lote 3 registro 127
1790	190	2024-02-14	153287	Leitura de rotina - lote 3 registro 128
1791	7	2024-10-09	228841	Leitura de rotina - lote 3 registro 129
1792	60	2024-06-08	184760	Leitura de rotina - lote 3 registro 130
1793	186	2025-01-05	207358	Leitura de rotina - lote 3 registro 131
1794	126	2026-03-25	219762	Leitura de rotina - lote 3 registro 132
1795	117	2025-12-03	215824	Leitura de rotina - lote 3 registro 133
1796	109	2025-04-14	271349	Leitura de rotina - lote 3 registro 134
1797	42	2025-05-26	254999	Leitura de rotina - lote 3 registro 135
1798	112	2024-03-24	297928	Leitura de rotina - lote 3 registro 137
1799	148	2024-11-04	298488	Leitura de rotina - lote 3 registro 138
1800	109	2026-08-31	271349	Leitura de rotina - lote 3 registro 139
1801	159	2025-09-08	261280	Leitura de rotina - lote 3 registro 140
1802	184	2025-04-28	310297	Leitura de rotina - lote 3 registro 141
1803	70	2026-11-01	308534	Leitura de rotina - lote 3 registro 142
1804	104	2025-07-08	224547	Leitura de rotina - lote 3 registro 143
1805	79	2026-07-20	178688	Leitura de rotina - lote 3 registro 144
1806	171	2024-11-02	247838	Leitura de rotina - lote 3 registro 145
1807	98	2026-01-06	253043	Leitura de rotina - lote 3 registro 146
1808	8	2025-09-19	289324	Leitura de rotina - lote 3 registro 147
1809	112	2025-07-31	297928	Leitura de rotina - lote 3 registro 148
1810	140	2025-03-30	191053	Leitura de rotina - lote 3 registro 149
1811	70	2025-02-17	308534	Leitura de rotina - lote 3 registro 150
1812	173	2025-10-18	285420	Leitura de rotina - lote 3 registro 151
1813	71	2026-03-16	231791	Leitura de rotina - lote 3 registro 152
1814	39	2026-08-08	202503	Leitura de rotina - lote 3 registro 153
1815	111	2026-10-30	274180	Leitura de rotina - lote 3 registro 154
1816	166	2024-08-05	179250	Leitura de rotina - lote 3 registro 155
1817	146	2024-06-02	228722	Leitura de rotina - lote 3 registro 156
1818	71	2025-11-18	231791	Leitura de rotina - lote 3 registro 157
1819	148	2024-03-06	298488	Leitura de rotina - lote 3 registro 158
1820	32	2025-04-14	116702	Leitura de rotina - lote 3 registro 159
1821	145	2026-06-03	278417	Leitura de rotina - lote 3 registro 160
1822	46	2026-04-27	276806	Leitura de rotina - lote 3 registro 161
1823	31	2025-12-05	258937	Leitura de rotina - lote 3 registro 162
1824	88	2025-06-26	302323	Leitura de rotina - lote 3 registro 163
1825	96	2026-04-26	277702	Leitura de rotina - lote 3 registro 164
1826	28	2025-06-24	198084	Leitura de rotina - lote 3 registro 166
1827	178	2026-01-06	192727	Leitura de rotina - lote 3 registro 167
1828	96	2026-09-28	277702	Leitura de rotina - lote 3 registro 169
1829	46	2026-03-20	276806	Leitura de rotina - lote 3 registro 170
1830	69	2024-10-06	225212	Leitura de rotina - lote 3 registro 171
1831	76	2026-05-22	225577	Leitura de rotina - lote 3 registro 172
1832	83	2026-03-19	205058	Leitura de rotina - lote 3 registro 173
1833	176	2025-12-04	276125	Leitura de rotina - lote 3 registro 174
1834	112	2024-07-25	297928	Leitura de rotina - lote 3 registro 175
1835	90	2026-06-13	267279	Leitura de rotina - lote 3 registro 177
1836	181	2025-05-12	270644	Leitura de rotina - lote 3 registro 178
1837	32	2024-09-21	121739	Leitura de rotina - lote 3 registro 179
1838	36	2024-10-19	245890	Leitura de rotina - lote 3 registro 180
1839	42	2026-01-16	313716	Leitura de rotina - lote 3 registro 181
1840	135	2025-06-03	288826	Leitura de rotina - lote 3 registro 182
1841	104	2024-12-08	224547	Leitura de rotina - lote 3 registro 184
1842	83	2026-02-07	205058	Leitura de rotina - lote 3 registro 187
1843	51	2025-10-26	177041	Leitura de rotina - lote 3 registro 188
1844	127	2026-10-08	283561	Leitura de rotina - lote 3 registro 189
1845	157	2026-06-30	168792	Leitura de rotina - lote 3 registro 190
1846	43	2025-07-12	289755	Leitura de rotina - lote 3 registro 191
1847	5	2026-05-24	276880	Leitura de rotina - lote 3 registro 192
1848	102	2024-06-02	268063	Leitura de rotina - lote 3 registro 193
1849	174	2025-12-11	268268	Leitura de rotina - lote 3 registro 194
1850	35	2025-11-20	313900	Leitura de rotina - lote 3 registro 196
1851	187	2025-02-10	283341	Leitura de rotina - lote 3 registro 197
1852	91	2025-03-31	284065	Leitura de rotina - lote 3 registro 198
1853	118	2025-08-28	289578	Leitura de rotina - lote 3 registro 199
1854	101	2025-09-08	178322	Leitura de rotina - lote 3 registro 200
1855	33	2026-04-21	292449	Leitura de rotina - lote 3 registro 201
1856	174	2024-10-09	268268	Leitura de rotina - lote 3 registro 202
1857	157	2024-05-30	168792	Leitura de rotina - lote 3 registro 203
1858	13	2024-05-22	283352	Leitura de rotina - lote 3 registro 205
1859	50	2024-09-23	232769	Leitura de rotina - lote 3 registro 206
1860	64	2024-07-30	309221	Leitura de rotina - lote 3 registro 207
1861	63	2025-11-20	254030	Leitura de rotina - lote 3 registro 208
1862	56	2024-03-05	301949	Leitura de rotina - lote 3 registro 209
1863	190	2026-06-04	173359	Leitura de rotina - lote 3 registro 210
1864	113	2025-02-28	242288	Leitura de rotina - lote 3 registro 211
1865	142	2024-06-18	277838	Leitura de rotina - lote 3 registro 212
1866	125	2024-12-29	309916	Leitura de rotina - lote 3 registro 213
1867	141	2025-07-16	236164	Leitura de rotina - lote 3 registro 214
1868	131	2024-10-26	162834	Leitura de rotina - lote 3 registro 215
1869	78	2025-07-17	232535	Leitura de rotina - lote 3 registro 216
1870	94	2024-08-11	126988	Leitura de rotina - lote 3 registro 217
1871	174	2026-09-11	268268	Leitura de rotina - lote 3 registro 218
1872	152	2025-09-19	295796	Leitura de rotina - lote 3 registro 219
1873	4	2024-09-11	163564	Leitura de rotina - lote 3 registro 220
1874	168	2024-12-28	283138	Leitura de rotina - lote 3 registro 221
1875	54	2024-06-10	260548	Leitura de rotina - lote 3 registro 222
1876	148	2026-09-11	298488	Leitura de rotina - lote 3 registro 223
1877	27	2025-11-06	265231	Leitura de rotina - lote 3 registro 224
1878	21	2024-10-13	202964	Leitura de rotina - lote 3 registro 225
1879	182	2026-07-09	313010	Leitura de rotina - lote 3 registro 226
1880	20	2026-04-30	288513	Leitura de rotina - lote 3 registro 227
1881	40	2026-09-06	244777	Leitura de rotina - lote 3 registro 228
1882	165	2024-07-31	220934	Leitura de rotina - lote 3 registro 229
1883	37	2026-01-16	246323	Leitura de rotina - lote 3 registro 230
1884	138	2024-10-04	158697	Leitura de rotina - lote 3 registro 231
1885	141	2026-08-24	273030	Leitura de rotina - lote 3 registro 232
1886	37	2024-08-14	246323	Leitura de rotina - lote 3 registro 233
1887	84	2025-07-23	172023	Leitura de rotina - lote 3 registro 234
1888	88	2025-07-13	302323	Leitura de rotina - lote 3 registro 235
1889	144	2026-09-28	235107	Leitura de rotina - lote 3 registro 236
1890	67	2025-01-03	257604	Leitura de rotina - lote 3 registro 238
1891	36	2025-08-11	245890	Leitura de rotina - lote 3 registro 239
1892	127	2025-11-21	286857	Leitura de rotina - lote 3 registro 241
1893	55	2026-07-29	276268	Leitura de rotina - lote 3 registro 242
1894	120	2024-03-16	238642	Leitura de rotina - lote 3 registro 243
1895	178	2025-02-14	192727	Leitura de rotina - lote 3 registro 245
1896	183	2025-04-10	286692	Leitura de rotina - lote 3 registro 246
1897	159	2024-05-17	279549	Leitura de rotina - lote 3 registro 247
1898	125	2026-05-21	309916	Leitura de rotina - lote 3 registro 248
1899	91	2025-11-24	284065	Leitura de rotina - lote 3 registro 249
1900	175	2024-05-18	276286	Leitura de rotina - lote 3 registro 250
1901	141	2024-10-12	273030	Leitura de rotina - lote 3 registro 251
1902	173	2025-08-12	285420	Leitura de rotina - lote 3 registro 252
1903	21	2026-09-14	309255	Leitura de rotina - lote 3 registro 253
1904	4	2026-02-25	176246	Leitura de rotina - lote 3 registro 254
1905	154	2024-04-26	276087	Leitura de rotina - lote 3 registro 255
1906	40	2024-09-19	244777	Leitura de rotina - lote 3 registro 256
1907	39	2024-02-13	235472	Leitura de rotina - lote 3 registro 257
1908	141	2024-05-20	273030	Leitura de rotina - lote 3 registro 258
1909	187	2026-10-15	283341	Leitura de rotina - lote 3 registro 259
1910	139	2026-02-14	223041	Leitura de rotina - lote 3 registro 260
1911	34	2024-08-23	286591	Leitura de rotina - lote 3 registro 261
1912	130	2026-06-18	294207	Leitura de rotina - lote 3 registro 262
1913	38	2024-04-04	304753	Leitura de rotina - lote 3 registro 263
1914	116	2026-03-26	267194	Leitura de rotina - lote 3 registro 264
1915	38	2025-06-29	304753	Leitura de rotina - lote 3 registro 266
1916	8	2025-11-29	289324	Leitura de rotina - lote 3 registro 267
1917	58	2026-08-24	85327	Leitura de rotina - lote 3 registro 268
1918	34	2026-09-29	286591	Leitura de rotina - lote 3 registro 269
1919	73	2026-01-05	283333	Leitura de rotina - lote 3 registro 270
1920	133	2025-02-04	184085	Leitura de rotina - lote 3 registro 272
1921	107	2026-06-23	259205	Leitura de rotina - lote 3 registro 273
1922	49	2024-02-19	297911	Leitura de rotina - lote 3 registro 274
1923	22	2025-07-17	177055	Leitura de rotina - lote 3 registro 275
1924	20	2024-06-05	303291	Leitura de rotina - lote 3 registro 276
1925	180	2025-10-22	244736	Leitura de rotina - lote 3 registro 277
1926	85	2026-04-27	277000	Leitura de rotina - lote 3 registro 278
1927	116	2026-10-27	267194	Leitura de rotina - lote 3 registro 279
1928	67	2024-10-18	257604	Leitura de rotina - lote 3 registro 280
1929	185	2025-11-27	158846	Leitura de rotina - lote 3 registro 281
1930	8	2025-06-12	289324	Leitura de rotina - lote 3 registro 282
1931	9	2024-10-06	145954	Leitura de rotina - lote 3 registro 283
1932	141	2025-08-07	305428	Leitura de rotina - lote 3 registro 284
1933	93	2026-10-15	264692	Leitura de rotina - lote 3 registro 285
1934	71	2026-07-23	231791	Leitura de rotina - lote 3 registro 286
1935	75	2025-01-29	166089	Leitura de rotina - lote 3 registro 287
1936	34	2026-02-01	286591	Leitura de rotina - lote 3 registro 289
1937	61	2024-05-29	294212	Leitura de rotina - lote 3 registro 290
1938	29	2026-10-10	195067	Leitura de rotina - lote 3 registro 291
1939	21	2025-08-24	309255	Leitura de rotina - lote 3 registro 292
1940	22	2026-04-13	177055	Leitura de rotina - lote 3 registro 293
1941	4	2026-01-26	315833	Leitura de rotina - lote 3 registro 294
1942	113	2025-11-20	242288	Leitura de rotina - lote 3 registro 295
1943	89	2024-12-21	279122	Leitura de rotina - lote 3 registro 296
1944	42	2024-03-22	313716	Leitura de rotina - lote 3 registro 297
1945	148	2024-10-18	298488	Leitura de rotina - lote 3 registro 298
1946	6	2024-08-05	260917	Leitura de rotina - lote 3 registro 299
1947	71	2026-07-10	231791	Leitura de rotina - lote 3 registro 300
\.


--
-- TOC entry 3619 (class 0 OID 32841)
-- Dependencies: 230
-- Data for Name: manutencoes; Type: TABLE DATA; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

COPY gabriel_trabalho_bd.manutencoes (id_manutencao, id_veiculo, data_manutencao, tipo_manutencao, descricao, oficina, valor, quilometragem) FROM stdin;
1	1	2026-01-20	preventiva	troca de oleo e filtros	oficina central	380.00	45800
2	1	2026-04-22	preventiva	revisao dos freios	oficina central	620.00	50600
3	2	2026-02-18	preventiva	troca de oleo e filtro de ar	auto center sul	410.00	40200
4	2	2026-05-20	corretiva	troca da bateria	auto center sul	780.00	45200
5	3	2026-03-25	preventiva	alinhamento e balanceamento	oficina norte	290.00	33000
6	3	2026-06-21	corretiva	troca das pastilhas de freio	oficina norte	540.00	37800
7	4	2026-01-28	preventiva	troca de oleo e filtros	diesel service	680.00	63500
8	4	2026-04-28	corretiva	manutencao da suspensao	diesel service	1450.00	70000
9	5	2026-02-24	preventiva	revisao completa	diesel service	920.00	74500
10	5	2026-05-25	corretiva	troca de embreagem	diesel service	3850.00	81500
11	6	2026-01-30	preventiva	troca de oleo e filtros	mecanica pesada	850.00	89000
12	6	2026-03-30	corretiva	reparo no sistema de freios	mecanica pesada	2100.00	92500
13	6	2026-06-28	preventiva	revisao geral	mecanica pesada	1250.00	98500
14	7	2026-02-05	preventiva	troca de oleo e filtros	master service	720.00	55500
15	7	2026-05-08	corretiva	troca do alternador	master service	1680.00	62800
16	8	2026-03-08	preventiva	revisao de motor	sprinter center	1150.00	73000
17	8	2026-06-10	corretiva	troca de pneus	sprinter center	3200.00	77500
18	9	2026-01-15	preventiva	troca de oleo e filtros	caminhoes parana	980.00	113000
19	9	2026-04-18	corretiva	manutencao do sistema de freios	caminhoes parana	2450.00	121000
20	10	2026-02-16	preventiva	revisao completa do motor	mercedes diesel	1350.00	142000
21	10	2026-05-19	corretiva	troca de pneus	mercedes diesel	4600.00	151000
22	10	2026-09-29	Preventiva	Troca de óleo e filtros	Oficina Central	1105.00	154570
23	1	2026-10-26	Corretiva	Troca de pastilhas de freio	Auto Mecânica Pitanga	335.50	77880
24	2	2026-10-23	Preventiva	Alinhamento e balanceamento	Oficina Central	421.00	79590
25	3	2026-10-20	Corretiva	Revisão geral	Auto Mecânica Pitanga	506.50	81300
26	4	2026-10-17	Preventiva	Troca de pneus	Oficina Central	592.00	83010
27	5	2026-10-14	Corretiva	Troca de óleo e filtros	Auto Mecânica Pitanga	677.50	84720
28	6	2026-10-11	Preventiva	Troca de pastilhas de freio	Oficina Central	763.00	98930
29	7	2026-10-08	Corretiva	Alinhamento e balanceamento	Auto Mecânica Pitanga	848.50	88140
30	8	2026-10-05	Preventiva	Revisão geral	Oficina Central	934.00	89850
31	9	2026-10-02	Corretiva	Troca de pneus	Auto Mecânica Pitanga	1019.50	126660
32	39	2026-09-16	preventiva	troca de oleo e filtros	mecanica boa viagem	486.68	72694
33	39	2026-06-20	corretiva	troca do embreagem	retifica paranaense	2579.09	67809
34	39	2026-03-17	preventiva	alinhamento e balanceamento	auto pecas e servicos	310.22	61833
35	44	2026-09-18	preventiva	alinhamento e balanceamento	auto center sul	227.15	94106
36	44	2026-06-21	corretiva	troca da correia dentada	auto center sul	1015.00	88269
37	44	2026-03-25	preventiva	revisao geral	mecanica boa viagem	745.13	82053
38	47	2026-09-27	preventiva	revisao dos freios	retifica paranaense	524.75	80620
39	47	2026-06-27	corretiva	troca do embreagem	oficina central	1464.35	76042
40	47	2026-03-23	preventiva	troca de pneus	mecanica boa viagem	3170.34	70146
41	31	2026-09-26	preventiva	alinhamento e balanceamento	mecanica boa viagem	307.95	48609
42	31	2026-06-12	corretiva	troca da bateria	auto pecas e servicos	700.89	43655
43	31	2026-03-23	preventiva	troca de oleo e filtros	mecanica boa viagem	508.87	38960
44	36	2026-09-21	preventiva	revisao geral	auto center sul	859.63	57604
45	36	2026-06-25	corretiva	troca da correia dentada	mecanica boa viagem	610.14	51596
46	36	2026-03-12	preventiva	revisao dos freios	auto pecas e servicos	627.69	46265
47	37	2026-09-20	preventiva	alinhamento e balanceamento	retifica paranaense	290.03	130957
48	37	2026-06-12	corretiva	troca da correia dentada	auto center sul	901.25	124597
49	37	2026-03-19	preventiva	alinhamento e balanceamento	retifica paranaense	195.26	119540
50	38	2026-09-23	preventiva	troca de pneus	auto center sul	1737.80	135278
51	38	2026-06-24	corretiva	troca da bateria	mecanica boa viagem	743.43	128622
52	38	2026-03-16	preventiva	revisao dos freios	auto center sul	634.64	123494
53	40	2026-09-26	preventiva	revisao dos freios	oficina central	699.58	87108
54	40	2026-06-16	corretiva	reparo no sistema eletrico	retifica paranaense	389.73	81798
55	40	2026-03-16	preventiva	alinhamento e balanceamento	auto center sul	183.78	75869
56	42	2026-09-18	preventiva	troca de pneus	mecanica boa viagem	1987.25	82956
57	42	2026-06-18	corretiva	reparo na suspensao	retifica paranaense	807.27	77663
58	42	2026-03-24	preventiva	alinhamento e balanceamento	mecanica boa viagem	249.42	71992
59	46	2026-09-27	preventiva	revisao geral	auto center sul	688.73	124510
60	46	2026-06-27	corretiva	troca do embreagem	oficina central	2532.29	119354
61	46	2026-03-26	preventiva	troca de pneus	retifica paranaense	2105.84	114502
62	43	2026-09-22	preventiva	troca de pneus	retifica paranaense	3098.65	115272
63	43	2026-06-20	corretiva	troca da correia dentada	oficina central	1089.83	109386
64	43	2026-03-25	preventiva	troca de oleo e filtros	oficina central	504.26	103927
65	34	2026-09-16	preventiva	revisao dos freios	auto center sul	703.25	48627
66	34	2026-06-18	corretiva	reparo na suspensao	auto center sul	1367.45	42593
67	34	2026-03-24	preventiva	alinhamento e balanceamento	auto pecas e servicos	266.13	37296
68	45	2026-09-21	preventiva	troca de pneus	auto center sul	2158.17	48098
69	45	2026-06-20	corretiva	troca do embreagem	mecanica boa viagem	1725.31	41625
70	45	2026-03-26	preventiva	revisao dos freios	retifica paranaense	543.35	36154
71	35	2026-09-17	preventiva	revisao geral	retifica paranaense	753.73	120855
72	35	2026-06-25	corretiva	reparo no sistema eletrico	oficina central	568.92	114794
73	35	2026-03-24	preventiva	revisao dos freios	auto center sul	623.94	108674
74	50	2026-09-25	preventiva	alinhamento e balanceamento	mecanica boa viagem	251.58	103717
75	50	2026-06-26	corretiva	troca da bateria	auto center sul	764.47	98494
76	50	2026-03-13	preventiva	revisao geral	oficina central	883.52	93845
77	33	2026-09-25	preventiva	alinhamento e balanceamento	auto pecas e servicos	233.43	127711
78	33	2026-06-19	corretiva	troca do embreagem	mecanica boa viagem	2286.47	122331
79	33	2026-03-22	preventiva	troca de pneus	auto center sul	1753.67	116992
80	48	2026-09-12	preventiva	alinhamento e balanceamento	mecanica boa viagem	281.02	129717
81	48	2026-06-16	corretiva	reparo no sistema eletrico	oficina central	819.65	124073
82	48	2026-03-14	preventiva	troca de oleo e filtros	mecanica boa viagem	431.39	118941
83	49	2026-09-13	preventiva	troca de pneus	auto center sul	2947.12	83771
84	49	2026-06-12	corretiva	reparo na suspensao	auto pecas e servicos	1492.22	76763
85	49	2026-03-15	preventiva	alinhamento e balanceamento	auto center sul	201.36	69847
86	32	2026-09-25	preventiva	revisao dos freios	auto center sul	696.97	115490
87	32	2026-06-23	corretiva	troca da correia dentada	retifica paranaense	792.05	111185
88	32	2026-03-21	preventiva	alinhamento e balanceamento	oficina central	239.47	107125
89	41	2026-09-14	preventiva	troca de pneus	auto center sul	2503.72	109682
90	41	2026-06-24	corretiva	troca do embreagem	retifica paranaense	1351.35	105221
91	41	2026-03-21	preventiva	troca de pneus	mecanica boa viagem	2717.52	101128
92	78	2025-03-12	preventiva	revisao dos freios	concessionaria regional	490.22	14389
93	88	2025-03-12	preventiva	troca de pneus	mecanica boa viagem	1349.67	129892
94	89	2025-03-12	preventiva	revisao dos freios	concessionaria regional	736.51	13731
95	79	2025-03-13	preventiva	alinhamento e balanceamento	concessionaria regional	285.18	142434
96	81	2025-03-13	preventiva	alinhamento e balanceamento	auto pecas e servicos	295.87	69966
97	62	2025-03-14	preventiva	revisao dos freios	concessionaria regional	605.72	32428
98	69	2025-03-14	preventiva	troca de oleo e filtros	concessionaria regional	372.89	8335
99	73	2025-03-14	preventiva	alinhamento e balanceamento	mecanica boa viagem	237.03	7366
100	80	2025-03-14	preventiva	alinhamento e balanceamento	oficina central	173.76	94000
101	66	2025-03-15	preventiva	troca de oleo e filtros	auto pecas e servicos	324.63	80085
102	75	2025-03-15	preventiva	revisao geral	concessionaria regional	850.12	130860
103	54	2025-03-16	preventiva	revisao dos freios	retifica paranaense	612.72	64738
104	55	2025-03-16	preventiva	alinhamento e balanceamento	concessionaria regional	172.56	87884
105	58	2025-03-17	preventiva	troca de oleo e filtros	retifica paranaense	470.21	54796
106	90	2025-03-17	preventiva	alinhamento e balanceamento	mecanica boa viagem	238.16	131345
107	53	2025-03-18	preventiva	revisao geral	auto center sul	880.30	64940
108	64	2025-03-18	preventiva	revisao geral	auto pecas e servicos	874.79	100689
109	68	2025-03-18	preventiva	revisao geral	auto center sul	731.56	67611
110	84	2025-03-18	preventiva	troca de pneus	mecanica boa viagem	1443.26	28497
111	57	2025-03-19	preventiva	troca de oleo e filtros	auto center sul	533.08	119834
112	59	2025-03-19	preventiva	alinhamento e balanceamento	auto pecas e servicos	317.94	124886
113	60	2025-03-19	preventiva	troca do filtro de combustivel	auto pecas e servicos	171.24	48065
114	67	2025-03-19	preventiva	troca do filtro de combustivel	mecanica boa viagem	185.43	102249
115	70	2025-03-19	preventiva	alinhamento e balanceamento	auto pecas e servicos	305.72	143536
116	56	2025-03-20	preventiva	alinhamento e balanceamento	auto center sul	175.26	105376
117	61	2025-03-20	preventiva	troca do filtro de combustivel	retifica paranaense	180.24	89818
118	87	2025-03-20	preventiva	troca de oleo e filtros	oficina central	450.02	121587
119	51	2025-03-21	preventiva	troca de pneus	auto pecas e servicos	1808.65	32397
120	77	2025-03-21	preventiva	revisao dos freios	mecanica boa viagem	747.28	142487
121	63	2025-03-22	preventiva	troca de pneus	auto pecas e servicos	2500.00	123259
122	71	2025-03-22	preventiva	troca de oleo e filtros	retifica paranaense	508.94	109831
123	83	2025-03-22	preventiva	revisao geral	mecanica boa viagem	961.36	97841
124	85	2025-03-22	preventiva	revisao geral	auto pecas e servicos	1058.89	7173
125	82	2025-03-24	preventiva	revisao geral	oficina central	837.30	14004
126	86	2025-03-25	preventiva	revisao dos freios	retifica paranaense	685.71	38748
127	52	2025-03-26	preventiva	revisao geral	auto center sul	823.68	117016
128	65	2025-03-26	preventiva	troca do filtro de combustivel	retifica paranaense	283.63	72045
129	74	2025-03-26	preventiva	revisao dos freios	auto pecas e servicos	600.03	61924
130	76	2025-03-26	preventiva	revisao geral	mecanica boa viagem	726.40	88329
131	72	2025-03-27	preventiva	revisao geral	auto pecas e servicos	1091.99	24310
132	51	2025-06-13	corretiva	reparo no sistema eletrico	retifica paranaense	394.92	37936
133	60	2025-06-13	corretiva	reparo no sistema eletrico	concessionaria regional	881.33	52653
134	86	2025-06-13	corretiva	troca da bateria	auto center sul	740.19	44082
135	73	2025-06-14	corretiva	troca do alternador	oficina central	1233.92	14025
136	56	2025-06-15	corretiva	troca do alternador	auto pecas e servicos	690.96	111302
137	57	2025-06-15	corretiva	troca da correia dentada	auto center sul	1071.44	125829
138	59	2025-06-15	corretiva	troca da bateria	oficina central	654.93	130096
139	70	2025-06-15	corretiva	reparo no sistema eletrico	mecanica boa viagem	648.66	148789
140	78	2025-06-15	corretiva	troca do alternador	mecanica boa viagem	898.85	19464
141	62	2025-06-16	corretiva	troca da embreagem	oficina central	1529.45	38526
142	69	2025-06-16	corretiva	reparo no sistema eletrico	oficina central	659.35	15032
143	72	2025-06-16	corretiva	troca da bateria	mecanica boa viagem	909.74	30250
144	75	2025-06-16	corretiva	reparo no sistema eletrico	retifica paranaense	851.43	136338
145	77	2025-06-16	corretiva	troca do alternador	retifica paranaense	766.34	148704
146	82	2025-06-16	corretiva	troca do alternador	auto pecas e servicos	793.12	18930
147	83	2025-06-17	corretiva	troca da embreagem	auto center sul	2414.09	102715
148	64	2025-06-18	corretiva	troca da correia dentada	retifica paranaense	727.61	105725
149	65	2025-06-18	corretiva	troca da embreagem	auto center sul	1657.69	77283
150	79	2025-06-19	corretiva	troca da embreagem	auto center sul	1618.47	148930
151	61	2025-06-20	corretiva	troca da bateria	mecanica boa viagem	677.65	93843
152	68	2025-06-20	corretiva	reparo no sistema eletrico	oficina central	697.67	72184
153	81	2025-06-20	corretiva	troca da correia dentada	concessionaria regional	1090.79	75148
154	87	2025-06-20	corretiva	troca da correia dentada	oficina central	1123.18	127347
155	90	2025-06-20	corretiva	troca do alternador	auto center sul	921.10	136892
156	71	2025-06-21	corretiva	troca da correia dentada	retifica paranaense	1146.52	115500
157	55	2025-06-22	corretiva	reparo na suspensao	auto pecas e servicos	850.97	92883
158	63	2025-06-22	corretiva	troca da correia dentada	auto center sul	893.15	127181
159	67	2025-06-23	corretiva	troca do alternador	auto pecas e servicos	1144.40	106549
160	74	2025-06-23	corretiva	troca da embreagem	oficina central	1583.51	66216
161	76	2025-06-23	corretiva	reparo na suspensao	auto pecas e servicos	1737.63	94219
162	80	2025-06-23	corretiva	troca da correia dentada	mecanica boa viagem	624.94	99134
163	89	2025-06-23	corretiva	reparo no sistema eletrico	auto pecas e servicos	864.04	18586
164	53	2025-06-25	corretiva	reparo na suspensao	auto pecas e servicos	893.06	69671
165	58	2025-06-25	corretiva	troca da bateria	mecanica boa viagem	788.97	60285
166	84	2025-06-25	corretiva	reparo na suspensao	auto pecas e servicos	1125.28	32976
167	85	2025-06-26	corretiva	troca da embreagem	auto center sul	1886.86	10923
168	52	2025-06-27	corretiva	troca do alternador	oficina central	1060.58	121966
169	54	2025-06-27	corretiva	troca da bateria	retifica paranaense	907.46	69302
170	66	2025-06-27	corretiva	troca do alternador	auto pecas e servicos	745.21	86340
171	88	2025-06-27	corretiva	reparo na suspensao	oficina central	1648.98	134407
172	84	2025-09-12	preventiva	troca de oleo e filtros	concessionaria regional	505.05	38210
173	71	2025-09-13	preventiva	troca de oleo e filtros	oficina central	421.85	120394
174	85	2025-09-13	preventiva	alinhamento e balanceamento	concessionaria regional	275.53	15420
175	87	2025-09-13	preventiva	revisao dos freios	auto center sul	705.99	132321
176	53	2025-09-14	preventiva	alinhamento e balanceamento	mecanica boa viagem	270.15	75670
177	64	2025-09-14	preventiva	troca de pneus	auto center sul	3195.46	111160
178	79	2025-09-14	preventiva	alinhamento e balanceamento	oficina central	316.27	155151
179	80	2025-09-14	preventiva	revisao dos freios	mecanica boa viagem	462.87	103989
180	57	2025-09-15	preventiva	alinhamento e balanceamento	auto center sul	254.92	130393
181	73	2025-09-15	preventiva	revisao geral	concessionaria regional	1182.33	18481
182	83	2025-09-15	preventiva	troca do filtro de combustivel	retifica paranaense	183.81	107767
183	66	2025-09-16	preventiva	troca de pneus	auto pecas e servicos	2271.97	91072
184	61	2025-09-17	preventiva	troca do filtro de combustivel	retifica paranaense	318.18	99039
185	63	2025-09-17	preventiva	troca de pneus	mecanica boa viagem	1542.38	132032
186	76	2025-09-17	preventiva	alinhamento e balanceamento	retifica paranaense	256.77	99987
187	62	2025-09-18	preventiva	revisao geral	oficina central	1149.16	44154
188	74	2025-09-18	preventiva	troca do filtro de combustivel	concessionaria regional	206.31	71437
189	78	2025-09-18	preventiva	revisao geral	mecanica boa viagem	864.46	24103
190	65	2025-09-19	preventiva	troca do filtro de combustivel	auto center sul	268.16	81533
191	82	2025-09-19	preventiva	troca do filtro de combustivel	auto pecas e servicos	260.62	23436
192	70	2025-09-20	preventiva	troca de oleo e filtros	concessionaria regional	356.23	153626
193	72	2025-09-20	preventiva	troca do filtro de combustivel	retifica paranaense	185.05	34726
194	75	2025-09-20	preventiva	revisao geral	auto pecas e servicos	649.88	142594
195	77	2025-09-20	preventiva	alinhamento e balanceamento	auto center sul	250.04	154545
196	55	2025-09-21	preventiva	troca de oleo e filtros	auto center sul	399.22	97389
197	59	2025-09-21	preventiva	revisao dos freios	oficina central	506.75	135277
198	89	2025-09-22	preventiva	alinhamento e balanceamento	concessionaria regional	317.33	23305
199	67	2025-09-23	preventiva	revisao geral	concessionaria regional	1240.96	112221
200	52	2025-09-24	preventiva	revisao dos freios	oficina central	573.94	126621
201	58	2025-09-24	preventiva	troca do filtro de combustivel	mecanica boa viagem	316.54	65180
202	60	2025-09-24	preventiva	troca do filtro de combustivel	mecanica boa viagem	172.32	57442
203	81	2025-09-24	preventiva	troca do filtro de combustivel	mecanica boa viagem	310.58	80943
204	90	2025-09-24	preventiva	troca de pneus	auto pecas e servicos	2192.28	141403
205	68	2025-09-25	preventiva	troca do filtro de combustivel	auto center sul	161.72	76441
206	51	2025-09-26	preventiva	alinhamento e balanceamento	oficina central	212.12	41807
207	56	2025-09-26	preventiva	revisao dos freios	auto pecas e servicos	577.27	116417
208	86	2025-09-26	preventiva	troca do filtro de combustivel	concessionaria regional	298.27	49309
209	88	2025-09-26	preventiva	revisao dos freios	oficina central	524.27	139809
210	54	2025-09-27	preventiva	troca do filtro de combustivel	auto center sul	234.69	73785
211	69	2025-09-27	preventiva	troca de pneus	retifica paranaense	2092.63	20592
212	54	2025-12-12	preventiva	revisao geral	auto center sul	1149.68	78460
213	79	2025-12-12	preventiva	alinhamento e balanceamento	auto center sul	195.57	161179
214	65	2025-12-13	preventiva	troca de pneus	auto center sul	1499.45	88304
215	84	2025-12-13	preventiva	troca de pneus	retifica paranaense	2285.54	44068
216	52	2025-12-14	preventiva	troca de pneus	oficina central	1839.73	131945
217	67	2025-12-14	preventiva	troca de pneus	oficina central	2508.17	118373
218	68	2025-12-14	preventiva	alinhamento e balanceamento	auto center sul	187.45	83431
219	71	2025-12-14	preventiva	troca do filtro de combustivel	auto pecas e servicos	311.50	124568
220	75	2025-12-14	preventiva	alinhamento e balanceamento	concessionaria regional	296.09	147708
221	77	2025-12-15	preventiva	revisao geral	auto center sul	882.47	160294
222	80	2025-12-15	preventiva	alinhamento e balanceamento	concessionaria regional	209.37	108946
223	82	2025-12-15	preventiva	alinhamento e balanceamento	auto pecas e servicos	238.07	29182
224	70	2025-12-16	preventiva	revisao dos freios	auto pecas e servicos	619.02	159354
225	86	2025-12-16	preventiva	troca de oleo e filtros	concessionaria regional	514.25	54141
226	85	2025-12-17	preventiva	troca de oleo e filtros	auto center sul	450.95	19652
227	89	2025-12-17	preventiva	troca de oleo e filtros	auto center sul	510.74	28912
228	90	2025-12-17	preventiva	troca de pneus	auto pecas e servicos	2728.87	147261
229	56	2025-12-19	preventiva	troca de oleo e filtros	retifica paranaense	448.19	120854
230	58	2025-12-19	preventiva	troca de oleo e filtros	auto center sul	494.26	69692
231	62	2025-12-19	preventiva	troca de pneus	mecanica boa viagem	2352.74	48896
232	64	2025-12-19	preventiva	troca de oleo e filtros	concessionaria regional	407.64	116072
233	88	2025-12-19	preventiva	troca de pneus	auto center sul	3398.34	144771
234	74	2025-12-20	preventiva	alinhamento e balanceamento	retifica paranaense	319.06	76004
235	51	2025-12-22	preventiva	alinhamento e balanceamento	auto center sul	175.51	46902
236	63	2025-12-22	preventiva	troca de oleo e filtros	retifica paranaense	416.98	136430
237	73	2025-12-22	preventiva	revisao geral	auto pecas e servicos	751.58	24360
238	81	2025-12-22	preventiva	troca de oleo e filtros	oficina central	376.54	86492
239	76	2025-12-23	preventiva	alinhamento e balanceamento	auto pecas e servicos	322.45	105426
240	83	2025-12-23	preventiva	troca do filtro de combustivel	oficina central	202.73	112980
241	60	2025-12-24	preventiva	troca do filtro de combustivel	auto pecas e servicos	302.36	61910
242	66	2025-12-24	preventiva	alinhamento e balanceamento	auto center sul	200.61	96520
243	55	2025-12-25	preventiva	troca de oleo e filtros	auto center sul	380.91	102396
244	69	2025-12-25	preventiva	revisao dos freios	retifica paranaense	511.41	26294
245	59	2025-12-26	preventiva	alinhamento e balanceamento	retifica paranaense	209.58	139377
246	61	2025-12-26	preventiva	troca de oleo e filtros	mecanica boa viagem	390.99	104932
247	72	2025-12-26	preventiva	revisao dos freios	auto pecas e servicos	569.98	39839
248	87	2025-12-26	preventiva	alinhamento e balanceamento	auto pecas e servicos	265.13	137187
249	53	2025-12-27	preventiva	troca do filtro de combustivel	concessionaria regional	241.53	80677
250	57	2025-12-27	preventiva	alinhamento e balanceamento	auto center sul	258.64	135295
251	78	2025-12-27	preventiva	troca de pneus	auto pecas e servicos	2686.95	29377
252	58	2026-03-12	corretiva	troca do alternador	oficina central	737.64	74290
253	61	2026-03-12	corretiva	troca da correia dentada	retifica paranaense	1052.39	108863
254	90	2026-03-12	corretiva	troca da bateria	concessionaria regional	644.85	151349
255	75	2026-03-13	corretiva	reparo na suspensao	mecanica boa viagem	1123.95	153956
256	52	2026-03-14	corretiva	troca do alternador	auto pecas e servicos	870.40	137034
257	60	2026-03-14	corretiva	troca do alternador	auto pecas e servicos	1043.15	67511
258	83	2026-03-14	corretiva	troca da embreagem	retifica paranaense	1528.31	118521
259	85	2026-03-14	corretiva	reparo na suspensao	concessionaria regional	1726.91	24878
260	86	2026-03-14	corretiva	troca da bateria	retifica paranaense	689.82	60653
261	57	2026-03-15	corretiva	troca da correia dentada	concessionaria regional	872.52	140580
262	78	2026-03-15	corretiva	troca da embreagem	mecanica boa viagem	2406.03	34686
263	55	2026-03-16	corretiva	troca da correia dentada	auto center sul	877.34	108237
264	73	2026-03-17	corretiva	troca da correia dentada	auto center sul	1077.79	30506
265	80	2026-03-17	corretiva	troca da bateria	auto center sul	777.78	113341
266	51	2026-03-18	corretiva	reparo no sistema eletrico	mecanica boa viagem	393.43	51547
267	84	2026-03-18	corretiva	reparo no sistema eletrico	auto pecas e servicos	419.64	47447
268	81	2026-03-19	corretiva	reparo no sistema eletrico	oficina central	715.04	92233
269	82	2026-03-19	corretiva	reparo na suspensao	retifica paranaense	1772.64	34876
270	87	2026-03-19	corretiva	reparo na suspensao	concessionaria regional	858.42	141645
271	72	2026-03-20	corretiva	troca da bateria	mecanica boa viagem	749.30	45202
272	77	2026-03-20	corretiva	troca do alternador	auto center sul	686.19	164730
273	69	2026-03-21	corretiva	troca da embreagem	auto pecas e servicos	1388.10	30524
274	79	2026-03-21	corretiva	troca do alternador	mecanica boa viagem	733.96	165459
275	62	2026-03-22	corretiva	reparo na suspensao	concessionaria regional	749.64	53704
276	66	2026-03-22	corretiva	troca do alternador	auto pecas e servicos	931.91	102125
277	88	2026-03-22	corretiva	troca da embreagem	oficina central	1661.03	148604
278	59	2026-03-23	corretiva	troca do alternador	auto center sul	721.27	144953
279	63	2026-03-23	corretiva	reparo no sistema eletrico	auto pecas e servicos	834.99	142300
280	65	2026-03-23	corretiva	troca da embreagem	retifica paranaense	1989.28	93105
281	67	2026-03-24	corretiva	troca da bateria	concessionaria regional	846.44	123530
282	71	2026-03-24	corretiva	reparo no sistema eletrico	mecanica boa viagem	810.04	129754
283	76	2026-03-24	corretiva	reparo na suspensao	mecanica boa viagem	925.29	111040
284	53	2026-03-25	corretiva	troca da embreagem	concessionaria regional	2572.78	86241
285	64	2026-03-25	corretiva	troca da correia dentada	oficina central	885.62	121408
286	56	2026-03-26	corretiva	troca da bateria	oficina central	779.08	126075
287	70	2026-03-26	corretiva	reparo na suspensao	auto center sul	1253.41	163891
288	54	2026-03-27	corretiva	troca da embreagem	concessionaria regional	1680.39	82774
289	68	2026-03-27	corretiva	reparo no sistema eletrico	mecanica boa viagem	650.90	88346
290	74	2026-03-27	corretiva	reparo no sistema eletrico	mecanica boa viagem	323.72	80757
291	89	2026-03-27	corretiva	reparo na suspensao	mecanica boa viagem	1399.00	33523
292	62	2026-06-12	preventiva	revisao dos freios	auto center sul	619.22	58249
293	81	2026-06-12	preventiva	troca do filtro de combustivel	auto center sul	308.97	97143
294	57	2026-06-14	preventiva	revisao geral	retifica paranaense	1048.08	146095
295	59	2026-06-14	preventiva	alinhamento e balanceamento	concessionaria regional	259.47	151015
296	61	2026-06-15	preventiva	revisao dos freios	auto center sul	714.95	112623
297	72	2026-06-15	preventiva	troca de oleo e filtros	concessionaria regional	434.16	50899
298	75	2026-06-15	preventiva	troca de pneus	mecanica boa viagem	2471.89	159340
299	55	2026-06-17	preventiva	revisao dos freios	auto center sul	648.22	113629
300	69	2026-06-17	preventiva	revisao geral	mecanica boa viagem	854.65	36044
301	70	2026-06-18	preventiva	revisao dos freios	concessionaria regional	709.73	169601
302	71	2026-06-18	preventiva	revisao geral	concessionaria regional	1179.32	135544
303	56	2026-06-19	preventiva	revisao dos freios	oficina central	502.60	132022
304	58	2026-06-19	preventiva	revisao geral	auto pecas e servicos	891.21	79531
305	76	2026-06-19	preventiva	troca de oleo e filtros	auto center sul	444.62	115614
306	79	2026-06-19	preventiva	troca de pneus	auto center sul	1782.34	171296
307	60	2026-06-20	preventiva	revisao geral	auto pecas e servicos	754.24	72895
308	68	2026-06-20	preventiva	alinhamento e balanceamento	mecanica boa viagem	278.34	93434
309	80	2026-06-20	preventiva	alinhamento e balanceamento	oficina central	248.27	118521
310	87	2026-06-20	preventiva	troca de pneus	auto center sul	2538.78	146915
311	66	2026-06-21	preventiva	revisao dos freios	auto pecas e servicos	675.35	106859
312	82	2026-06-21	preventiva	alinhamento e balanceamento	auto center sul	277.68	40482
313	86	2026-06-21	preventiva	revisao geral	oficina central	898.83	65744
314	88	2026-06-21	preventiva	alinhamento e balanceamento	auto pecas e servicos	175.91	153932
315	90	2026-06-21	preventiva	troca de pneus	auto center sul	2924.72	156396
316	52	2026-06-22	preventiva	alinhamento e balanceamento	auto pecas e servicos	176.97	142736
317	63	2026-06-22	preventiva	alinhamento e balanceamento	concessionaria regional	320.07	147711
318	77	2026-06-22	preventiva	troca de pneus	retifica paranaense	2953.91	170010
319	54	2026-06-23	preventiva	troca de pneus	retifica paranaense	2179.52	87862
320	64	2026-06-23	preventiva	alinhamento e balanceamento	mecanica boa viagem	209.71	126309
321	73	2026-06-23	preventiva	revisao dos freios	auto pecas e servicos	509.84	36501
322	74	2026-06-23	preventiva	troca de oleo e filtros	auto pecas e servicos	528.48	85529
323	78	2026-06-23	preventiva	alinhamento e balanceamento	concessionaria regional	329.37	39116
324	51	2026-06-24	preventiva	alinhamento e balanceamento	oficina central	245.94	55552
325	85	2026-06-24	preventiva	revisao dos freios	oficina central	482.88	30275
326	83	2026-06-25	preventiva	revisao geral	auto center sul	1154.39	123228
327	84	2026-06-25	preventiva	troca do filtro de combustivel	oficina central	284.10	52040
328	53	2026-06-26	preventiva	troca de oleo e filtros	auto center sul	369.71	92163
329	65	2026-06-27	preventiva	revisao geral	oficina central	1013.24	97345
330	67	2026-06-27	preventiva	alinhamento e balanceamento	auto center sul	239.65	128773
331	89	2026-06-27	preventiva	revisao dos freios	concessionaria regional	716.74	40060
332	58	2026-09-12	preventiva	troca de oleo e filtros	oficina central	537.97	83310
333	68	2026-09-13	preventiva	troca do filtro de combustivel	concessionaria regional	276.66	98243
334	84	2026-09-13	preventiva	revisao dos freios	mecanica boa viagem	503.25	56756
335	54	2026-09-14	preventiva	troca do filtro de combustivel	auto center sul	258.30	92419
336	59	2026-09-15	preventiva	troca de oleo e filtros	auto center sul	451.03	155552
337	57	2026-09-16	preventiva	troca de pneus	auto pecas e servicos	2456.18	150166
338	74	2026-09-16	preventiva	troca de pneus	mecanica boa viagem	1772.34	91532
339	76	2026-09-16	preventiva	revisao geral	auto center sul	677.16	120642
340	56	2026-09-17	preventiva	revisao geral	mecanica boa viagem	623.88	136340
341	90	2026-09-17	preventiva	revisao geral	auto center sul	1222.52	161530
342	51	2026-09-18	preventiva	revisao geral	auto center sul	937.98	60641
343	67	2026-09-18	preventiva	troca do filtro de combustivel	retifica paranaense	317.05	134086
344	69	2026-09-19	preventiva	revisao geral	auto center sul	900.82	41306
345	79	2026-09-19	preventiva	troca de pneus	auto center sul	2196.85	176786
346	53	2026-09-20	preventiva	troca de oleo e filtros	auto center sul	461.68	97284
347	78	2026-09-20	preventiva	revisao dos freios	auto center sul	472.88	43988
348	81	2026-09-20	preventiva	revisao geral	mecanica boa viagem	1185.11	102303
349	60	2026-09-21	preventiva	revisao dos freios	oficina central	568.71	78693
350	70	2026-09-21	preventiva	alinhamento e balanceamento	mecanica boa viagem	303.38	173573
351	77	2026-09-21	preventiva	troca de pneus	concessionaria regional	1520.50	175295
352	89	2026-09-21	preventiva	troca de pneus	concessionaria regional	3306.54	45817
353	52	2026-09-22	preventiva	troca do filtro de combustivel	mecanica boa viagem	200.56	148006
354	61	2026-09-22	preventiva	troca do filtro de combustivel	mecanica boa viagem	256.23	117269
355	63	2026-09-22	preventiva	troca de oleo e filtros	mecanica boa viagem	405.17	153686
356	64	2026-09-22	preventiva	troca do filtro de combustivel	auto center sul	156.44	130753
357	82	2026-09-22	preventiva	alinhamento e balanceamento	mecanica boa viagem	328.99	44880
358	65	2026-09-23	preventiva	troca do filtro de combustivel	retifica paranaense	185.65	103337
359	66	2026-09-23	preventiva	troca de oleo e filtros	auto pecas e servicos	342.47	111609
360	75	2026-09-24	preventiva	troca de oleo e filtros	auto pecas e servicos	472.11	164819
361	87	2026-09-24	preventiva	troca de oleo e filtros	retifica paranaense	513.61	151409
362	73	2026-09-25	preventiva	troca de pneus	concessionaria regional	2680.78	41312
363	83	2026-09-25	preventiva	troca de oleo e filtros	auto center sul	409.15	128231
364	88	2026-09-25	preventiva	alinhamento e balanceamento	mecanica boa viagem	286.57	159520
365	62	2026-09-26	preventiva	revisao dos freios	auto pecas e servicos	513.47	63579
366	71	2026-09-26	preventiva	revisao geral	auto pecas e servicos	794.70	140327
367	80	2026-09-26	preventiva	revisao geral	mecanica boa viagem	1034.51	123791
368	86	2026-09-26	preventiva	revisao dos freios	auto pecas e servicos	656.19	70431
369	55	2026-09-27	preventiva	troca de oleo e filtros	mecanica boa viagem	358.57	119174
370	72	2026-09-27	preventiva	troca de pneus	concessionaria regional	2899.12	56272
371	85	2026-09-27	preventiva	revisao dos freios	auto center sul	567.96	35751
372	1	2028-03-18	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Auto Center Paraná	666.21	87085
373	2	2028-03-19	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Oficina Central	4714.08	88869
374	3	2028-03-20	Pneus	Manutenção pneus realizada conforme necessidade operacional	Mecânica Avenida	3237.13	90653
375	4	2028-03-21	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Diesel Service	4957.09	92437
376	5	2028-03-22	Freios	Manutenção freios realizada conforme necessidade operacional	Centro Automotivo Brasil	4526.09	94221
377	6	2028-03-23	Motor	Manutenção motor realizada conforme necessidade operacional	Auto Center Paraná	4240.86	108505
378	7	2028-03-24	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Oficina Central	3251.44	97789
379	8	2028-03-25	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Mecânica Avenida	5178.91	99573
380	9	2028-03-26	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Diesel Service	713.68	136457
381	10	2028-03-27	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Centro Automotivo Brasil	1533.79	164441
382	11	2028-03-28	Pneus	Manutenção pneus realizada conforme necessidade operacional	Auto Center Paraná	4533.60	104445
383	12	2028-03-29	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Oficina Central	2073.59	106219
384	13	2028-03-30	Freios	Manutenção freios realizada conforme necessidade operacional	Mecânica Avenida	3830.32	107993
385	14	2028-03-31	Motor	Manutenção motor realizada conforme necessidade operacional	Diesel Service	3139.40	109767
386	15	2028-04-01	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Centro Automotivo Brasil	3507.28	111541
387	16	2028-04-02	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Auto Center Paraná	2834.71	113315
388	17	2028-04-03	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Oficina Central	4879.07	115089
389	18	2028-04-04	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Mecânica Avenida	2230.45	116863
390	19	2028-04-05	Pneus	Manutenção pneus realizada conforme necessidade operacional	Diesel Service	4604.21	118637
391	20	2028-04-06	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Centro Automotivo Brasil	1848.45	120411
392	21	2028-04-07	Freios	Manutenção freios realizada conforme necessidade operacional	Auto Center Paraná	1723.96	118132
393	22	2028-04-08	Motor	Manutenção motor realizada conforme necessidade operacional	Oficina Central	889.78	119896
394	23	2028-04-09	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Mecânica Avenida	1348.69	121660
395	24	2028-04-10	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Diesel Service	882.76	123424
396	25	2028-04-11	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Centro Automotivo Brasil	3538.81	125188
397	26	2028-04-12	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Auto Center Paraná	4982.77	126952
398	27	2028-04-13	Pneus	Manutenção pneus realizada conforme necessidade operacional	Oficina Central	1301.26	128716
399	28	2028-04-14	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Mecânica Avenida	1500.53	130480
400	29	2028-04-15	Freios	Manutenção freios realizada conforme necessidade operacional	Diesel Service	3209.19	132244
401	30	2028-04-16	Motor	Manutenção motor realizada conforme necessidade operacional	Centro Automotivo Brasil	4742.85	134008
402	1	2028-04-17	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Auto Center Paraná	6350.75	87709
403	2	2028-04-18	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Oficina Central	3467.18	89497
404	3	2028-04-19	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Mecânica Avenida	1925.53	91285
405	4	2028-04-20	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Diesel Service	761.36	93073
406	5	2028-04-21	Pneus	Manutenção pneus realizada conforme necessidade operacional	Centro Automotivo Brasil	1358.47	94861
407	6	2028-04-22	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Auto Center Paraná	1571.34	109149
408	7	2028-04-23	Freios	Manutenção freios realizada conforme necessidade operacional	Oficina Central	1264.84	98437
409	8	2028-04-24	Motor	Manutenção motor realizada conforme necessidade operacional	Mecânica Avenida	210.27	100225
410	9	2028-04-25	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Diesel Service	3527.78	137113
411	10	2028-04-26	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Centro Automotivo Brasil	1870.11	165101
412	11	2028-04-27	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Auto Center Paraná	6336.00	105109
413	12	2028-04-28	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Oficina Central	3650.43	106887
414	13	2028-04-29	Pneus	Manutenção pneus realizada conforme necessidade operacional	Mecânica Avenida	4569.52	108665
415	14	2028-04-30	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Diesel Service	925.66	110443
416	15	2028-05-01	Freios	Manutenção freios realizada conforme necessidade operacional	Centro Automotivo Brasil	5660.78	112221
417	16	2028-05-02	Motor	Manutenção motor realizada conforme necessidade operacional	Auto Center Paraná	3251.81	113999
418	17	2028-05-03	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Oficina Central	5687.95	115777
419	18	2028-05-04	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Mecânica Avenida	3782.53	117555
420	19	2028-05-05	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Diesel Service	3114.75	119333
421	20	2028-05-06	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Centro Automotivo Brasil	2930.19	121111
422	21	2028-05-07	Pneus	Manutenção pneus realizada conforme necessidade operacional	Auto Center Paraná	1296.24	118836
423	22	2028-05-08	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Oficina Central	447.78	120604
424	23	2028-05-09	Freios	Manutenção freios realizada conforme necessidade operacional	Mecânica Avenida	6123.99	122372
425	24	2028-05-10	Motor	Manutenção motor realizada conforme necessidade operacional	Diesel Service	3167.91	124140
426	25	2028-05-11	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Centro Automotivo Brasil	5365.10	125908
427	26	2028-05-12	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Auto Center Paraná	2676.51	127676
428	27	2028-05-13	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Oficina Central	592.64	129444
429	28	2028-05-14	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Mecânica Avenida	4135.86	131212
430	29	2028-05-15	Pneus	Manutenção pneus realizada conforme necessidade operacional	Diesel Service	462.03	132980
431	30	2028-05-16	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Centro Automotivo Brasil	1071.88	134748
432	1	2028-05-17	Freios	Manutenção freios realizada conforme necessidade operacional	Auto Center Paraná	3710.92	88453
433	2	2028-05-18	Motor	Manutenção motor realizada conforme necessidade operacional	Oficina Central	2058.47	90245
434	3	2028-05-19	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Mecânica Avenida	6461.20	92037
435	4	2028-05-20	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Diesel Service	875.72	93829
436	5	2028-05-21	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Centro Automotivo Brasil	4997.15	95621
437	6	2028-05-22	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Auto Center Paraná	3988.31	109913
438	7	2028-05-23	Pneus	Manutenção pneus realizada conforme necessidade operacional	Oficina Central	5164.93	99205
439	8	2028-05-24	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Mecânica Avenida	1559.88	100997
440	9	2028-05-25	Freios	Manutenção freios realizada conforme necessidade operacional	Diesel Service	3454.01	137889
441	10	2028-05-26	Motor	Manutenção motor realizada conforme necessidade operacional	Centro Automotivo Brasil	2994.28	165881
442	11	2028-05-27	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Auto Center Paraná	2944.56	105893
443	12	2028-05-28	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Oficina Central	5607.86	107675
444	13	2028-05-29	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Mecânica Avenida	6436.40	109457
445	14	2028-05-30	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Diesel Service	2068.33	111239
446	15	2028-05-31	Pneus	Manutenção pneus realizada conforme necessidade operacional	Centro Automotivo Brasil	4082.15	113021
447	16	2028-06-01	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Auto Center Paraná	4009.45	114803
448	17	2028-06-02	Freios	Manutenção freios realizada conforme necessidade operacional	Oficina Central	4841.77	116585
449	18	2028-06-03	Motor	Manutenção motor realizada conforme necessidade operacional	Mecânica Avenida	6165.63	118367
450	19	2028-06-04	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Diesel Service	1445.69	120149
451	20	2028-06-05	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Centro Automotivo Brasil	1466.34	121931
452	21	2028-06-06	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Auto Center Paraná	4333.53	119660
453	22	2028-06-07	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Oficina Central	1122.02	121432
454	23	2028-06-08	Pneus	Manutenção pneus realizada conforme necessidade operacional	Mecânica Avenida	1228.93	123204
455	24	2028-06-09	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Diesel Service	598.91	124976
456	25	2028-06-10	Freios	Manutenção freios realizada conforme necessidade operacional	Centro Automotivo Brasil	137.07	126748
457	26	2028-06-11	Motor	Manutenção motor realizada conforme necessidade operacional	Auto Center Paraná	2994.21	128520
458	27	2028-06-12	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Oficina Central	3908.52	130292
459	28	2028-06-13	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Mecânica Avenida	1978.23	132064
460	29	2028-06-14	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Diesel Service	1596.82	133836
461	30	2028-06-15	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Centro Automotivo Brasil	4630.38	135608
462	1	2028-06-16	Pneus	Manutenção pneus realizada conforme necessidade operacional	Auto Center Paraná	4605.06	89317
463	2	2028-06-17	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Oficina Central	3016.72	91113
464	3	2028-06-18	Freios	Manutenção freios realizada conforme necessidade operacional	Mecânica Avenida	4505.52	92909
465	4	2028-06-19	Motor	Manutenção motor realizada conforme necessidade operacional	Diesel Service	6014.55	94705
466	5	2028-06-20	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Centro Automotivo Brasil	5146.34	96501
467	6	2028-06-21	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Auto Center Paraná	4107.87	110797
468	7	2028-06-22	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Oficina Central	4338.35	100093
469	8	2028-06-23	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Mecânica Avenida	6076.80	101889
470	9	2028-06-24	Pneus	Manutenção pneus realizada conforme necessidade operacional	Diesel Service	2832.39	138785
471	10	2028-06-25	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Centro Automotivo Brasil	3594.31	166781
472	11	2028-06-26	Freios	Manutenção freios realizada conforme necessidade operacional	Auto Center Paraná	4251.91	106797
473	12	2028-06-27	Motor	Manutenção motor realizada conforme necessidade operacional	Oficina Central	5915.67	108583
474	13	2028-06-28	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Mecânica Avenida	5393.91	110369
475	14	2028-06-29	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Diesel Service	575.59	112155
476	15	2028-06-30	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Centro Automotivo Brasil	1178.59	113941
477	16	2028-07-01	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Auto Center Paraná	2082.56	115727
478	17	2028-07-02	Pneus	Manutenção pneus realizada conforme necessidade operacional	Oficina Central	4898.35	117513
479	18	2028-07-03	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Mecânica Avenida	3751.54	119299
480	19	2028-07-04	Freios	Manutenção freios realizada conforme necessidade operacional	Diesel Service	1961.34	121085
481	20	2028-07-05	Motor	Manutenção motor realizada conforme necessidade operacional	Centro Automotivo Brasil	913.38	122871
482	21	2028-07-06	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Auto Center Paraná	4513.77	120604
483	22	2028-07-07	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Oficina Central	4584.30	122380
484	23	2028-07-08	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Mecânica Avenida	6134.27	124156
485	24	2028-07-09	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Diesel Service	3313.01	125932
486	25	2028-07-10	Pneus	Manutenção pneus realizada conforme necessidade operacional	Centro Automotivo Brasil	3270.41	127708
487	26	2028-07-11	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Auto Center Paraná	633.22	129484
488	27	2028-07-12	Freios	Manutenção freios realizada conforme necessidade operacional	Oficina Central	374.31	131260
489	28	2028-07-13	Motor	Manutenção motor realizada conforme necessidade operacional	Mecânica Avenida	2876.34	133036
490	29	2028-07-14	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Diesel Service	2176.41	134812
491	30	2028-07-15	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Centro Automotivo Brasil	1717.35	136588
492	1	2028-07-16	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Auto Center Paraná	702.67	90301
493	2	2028-07-17	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Oficina Central	6256.99	92101
494	3	2028-07-18	Pneus	Manutenção pneus realizada conforme necessidade operacional	Mecânica Avenida	5453.42	93901
495	4	2028-07-19	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Diesel Service	3789.77	95701
496	5	2028-07-20	Freios	Manutenção freios realizada conforme necessidade operacional	Centro Automotivo Brasil	6186.02	97501
497	6	2028-07-21	Motor	Manutenção motor realizada conforme necessidade operacional	Auto Center Paraná	6497.27	111801
498	7	2028-07-22	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Oficina Central	4409.16	101101
499	8	2028-07-23	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Mecânica Avenida	1839.48	102901
500	9	2028-07-24	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Diesel Service	376.68	139801
501	10	2028-07-25	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Centro Automotivo Brasil	4945.00	167801
502	11	2028-07-26	Pneus	Manutenção pneus realizada conforme necessidade operacional	Auto Center Paraná	3121.80	107821
503	12	2028-07-27	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Oficina Central	4276.63	109611
504	13	2028-07-28	Freios	Manutenção freios realizada conforme necessidade operacional	Mecânica Avenida	5964.54	111401
505	14	2028-07-29	Motor	Manutenção motor realizada conforme necessidade operacional	Diesel Service	1277.90	113191
506	15	2028-07-30	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Centro Automotivo Brasil	3854.40	114981
507	16	2028-07-31	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Auto Center Paraná	4169.93	116771
508	17	2028-08-01	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Oficina Central	3257.21	118561
509	18	2028-08-02	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Mecânica Avenida	702.13	120351
510	19	2028-08-03	Pneus	Manutenção pneus realizada conforme necessidade operacional	Diesel Service	2339.99	122141
511	20	2028-08-04	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Centro Automotivo Brasil	2246.51	123931
512	21	2028-08-05	Freios	Manutenção freios realizada conforme necessidade operacional	Auto Center Paraná	4395.45	121668
513	22	2028-08-06	Motor	Manutenção motor realizada conforme necessidade operacional	Oficina Central	5592.34	123448
514	23	2028-08-07	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Mecânica Avenida	2224.15	125228
515	24	2028-08-08	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Diesel Service	4545.64	127008
516	25	2028-08-09	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Centro Automotivo Brasil	1958.83	128788
517	26	2028-08-10	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Auto Center Paraná	6150.33	130568
518	27	2028-08-11	Pneus	Manutenção pneus realizada conforme necessidade operacional	Oficina Central	5310.55	132348
519	28	2028-08-12	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Mecânica Avenida	3629.62	134128
520	29	2028-08-13	Freios	Manutenção freios realizada conforme necessidade operacional	Diesel Service	3021.79	135908
521	30	2028-08-14	Motor	Manutenção motor realizada conforme necessidade operacional	Centro Automotivo Brasil	2126.62	137688
522	1	2028-08-15	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Auto Center Paraná	2182.49	91405
523	2	2028-08-16	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Oficina Central	6309.78	93209
524	3	2028-08-17	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Mecânica Avenida	2698.64	95013
525	4	2028-08-18	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Diesel Service	3403.12	96817
526	5	2028-08-19	Pneus	Manutenção pneus realizada conforme necessidade operacional	Centro Automotivo Brasil	6424.20	98621
527	6	2028-08-20	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Auto Center Paraná	4315.87	112925
528	7	2028-08-21	Freios	Manutenção freios realizada conforme necessidade operacional	Oficina Central	3581.75	102229
529	8	2028-08-22	Motor	Manutenção motor realizada conforme necessidade operacional	Mecânica Avenida	2756.52	104033
530	9	2028-08-23	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Diesel Service	1316.78	140937
531	10	2028-08-24	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Centro Automotivo Brasil	2428.15	168941
532	11	2028-08-25	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Auto Center Paraná	4946.11	108965
533	12	2028-08-26	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Oficina Central	4110.11	110759
534	13	2028-08-27	Pneus	Manutenção pneus realizada conforme necessidade operacional	Mecânica Avenida	4968.74	112553
535	14	2028-08-28	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Diesel Service	1418.70	114347
536	15	2028-08-29	Freios	Manutenção freios realizada conforme necessidade operacional	Centro Automotivo Brasil	3624.02	116141
537	16	2028-08-30	Motor	Manutenção motor realizada conforme necessidade operacional	Auto Center Paraná	6038.55	117935
538	17	2028-08-31	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Oficina Central	2915.18	119729
539	18	2028-09-01	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Mecânica Avenida	4574.84	121523
540	19	2028-09-02	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Diesel Service	894.70	123317
541	20	2028-09-03	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Centro Automotivo Brasil	6328.68	125111
542	21	2028-09-04	Pneus	Manutenção pneus realizada conforme necessidade operacional	Auto Center Paraná	4004.60	122852
543	22	2028-09-05	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Oficina Central	1646.72	124636
544	23	2028-09-06	Freios	Manutenção freios realizada conforme necessidade operacional	Mecânica Avenida	1130.45	126420
545	24	2028-09-07	Motor	Manutenção motor realizada conforme necessidade operacional	Diesel Service	3634.35	128204
546	25	2028-09-08	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Centro Automotivo Brasil	3643.36	129988
547	26	2028-09-09	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Auto Center Paraná	714.67	131772
548	27	2028-09-10	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Oficina Central	6450.60	133556
549	28	2028-09-11	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Mecânica Avenida	5944.49	135340
550	29	2028-09-12	Pneus	Manutenção pneus realizada conforme necessidade operacional	Diesel Service	3064.04	137124
551	30	2028-09-13	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Centro Automotivo Brasil	869.43	138908
552	1	2028-09-14	Freios	Manutenção freios realizada conforme necessidade operacional	Auto Center Paraná	5429.07	92629
553	2	2028-09-15	Motor	Manutenção motor realizada conforme necessidade operacional	Oficina Central	3299.64	94437
554	3	2028-09-16	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Mecânica Avenida	4691.93	96245
555	4	2028-09-17	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Diesel Service	3366.60	98053
556	5	2028-09-18	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Centro Automotivo Brasil	1864.45	99861
557	6	2028-09-19	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Auto Center Paraná	5445.54	114169
558	7	2028-09-20	Pneus	Manutenção pneus realizada conforme necessidade operacional	Oficina Central	6373.96	103477
559	8	2028-09-21	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Mecânica Avenida	1675.00	105285
560	9	2028-09-22	Freios	Manutenção freios realizada conforme necessidade operacional	Diesel Service	3637.07	142193
561	10	2028-09-23	Motor	Manutenção motor realizada conforme necessidade operacional	Centro Automotivo Brasil	2567.28	170201
562	11	2028-09-24	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Auto Center Paraná	6001.52	110229
563	12	2028-09-25	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Oficina Central	3362.58	112027
564	13	2028-09-26	Preventiva	Manutenção preventiva realizada conforme necessidade operacional	Mecânica Avenida	5730.10	113825
565	14	2028-09-27	Corretiva	Manutenção corretiva realizada conforme necessidade operacional	Diesel Service	5632.49	115623
566	15	2028-09-28	Pneus	Manutenção pneus realizada conforme necessidade operacional	Centro Automotivo Brasil	1882.46	117421
567	16	2028-09-29	Elétrica	Manutenção elétrica realizada conforme necessidade operacional	Auto Center Paraná	5160.24	119219
568	17	2028-09-30	Freios	Manutenção freios realizada conforme necessidade operacional	Oficina Central	2767.33	121017
569	18	2028-10-01	Motor	Manutenção motor realizada conforme necessidade operacional	Mecânica Avenida	6080.50	122815
570	19	2028-10-02	Suspensão	Manutenção suspensão realizada conforme necessidade operacional	Diesel Service	3359.37	124613
571	20	2028-10-03	Troca de óleo	Manutenção troca de óleo realizada conforme necessidade operacional	Centro Automotivo Brasil	5355.11	126411
572	78	2025-08-16	Preventiva	Servico de preventiva realizado no veiculo	Oficina Central	4127.25	232535
573	100	2025-11-23	Corretiva	Servico de corretiva realizado no veiculo	Auto Center Parana	1932.77	244940
574	137	2024-12-30	Troca de oleo	Servico de troca de oleo realizado no veiculo	Mecanica Avenida	2358.36	140906
575	77	2024-12-21	Sistema de freios	Servico de sistema de freios realizado no veiculo	Diesel Service	4027.85	178069
576	165	2025-11-21	Suspensao	Servico de suspensao realizado no veiculo	Centro Automotivo Brasil	4915.07	220934
577	145	2024-12-23	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Oficina Municipal	8141.79	278417
578	34	2026-03-23	Pneus	Servico de pneus realizado no veiculo	Oficina Central	5407.97	286591
579	74	2025-05-08	Motor	Servico de motor realizado no veiculo	Auto Center Parana	8538.02	295295
580	149	2025-04-04	Arrefecimento	Servico de arrefecimento realizado no veiculo	Mecanica Avenida	1673.46	282502
581	28	2025-09-30	Alinhamento	Servico de alinhamento realizado no veiculo	Diesel Service	323.27	198084
582	116	2025-07-31	Preventiva	Servico de preventiva realizado no veiculo	Centro Automotivo Brasil	205.12	267194
583	159	2026-04-18	Corretiva	Servico de corretiva realizado no veiculo	Oficina Municipal	2944.42	304196
584	16	2025-07-28	Troca de oleo	Servico de troca de oleo realizado no veiculo	Oficina Central	3851.06	215243
585	26	2024-03-07	Sistema de freios	Servico de sistema de freios realizado no veiculo	Auto Center Parana	7236.99	150515
586	63	2025-08-21	Suspensao	Servico de suspensao realizado no veiculo	Mecanica Avenida	6514.04	254030
587	187	2025-07-25	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Diesel Service	4777.50	283341
588	166	2026-06-07	Pneus	Servico de pneus realizado no veiculo	Centro Automotivo Brasil	1882.75	179250
589	116	2025-08-08	Motor	Servico de motor realizado no veiculo	Oficina Municipal	8064.73	267194
590	119	2025-05-18	Arrefecimento	Servico de arrefecimento realizado no veiculo	Oficina Central	457.53	298843
591	129	2026-06-17	Alinhamento	Servico de alinhamento realizado no veiculo	Auto Center Parana	764.07	269161
592	127	2025-05-04	Preventiva	Servico de preventiva realizado no veiculo	Mecanica Avenida	2351.08	286857
593	179	2026-02-08	Corretiva	Servico de corretiva realizado no veiculo	Diesel Service	4570.84	291570
594	93	2024-06-23	Troca de oleo	Servico de troca de oleo realizado no veiculo	Centro Automotivo Brasil	6085.50	282092
595	125	2025-01-21	Sistema de freios	Servico de sistema de freios realizado no veiculo	Oficina Municipal	5011.57	309916
596	124	2026-08-09	Suspensao	Servico de suspensao realizado no veiculo	Oficina Central	425.10	264430
597	52	2025-10-27	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Auto Center Parana	4302.79	289179
598	108	2024-03-06	Pneus	Servico de pneus realizado no veiculo	Mecanica Avenida	1560.10	243112
599	142	2026-10-11	Motor	Servico de motor realizado no veiculo	Diesel Service	3542.12	277838
600	37	2024-04-05	Arrefecimento	Servico de arrefecimento realizado no veiculo	Centro Automotivo Brasil	4482.89	252556
601	131	2024-09-09	Alinhamento	Servico de alinhamento realizado no veiculo	Oficina Municipal	1562.42	280434
602	59	2025-08-28	Preventiva	Servico de preventiva realizado no veiculo	Oficina Central	7118.42	244834
603	183	2026-05-23	Corretiva	Servico de corretiva realizado no veiculo	Auto Center Parana	2142.61	286692
604	8	2025-03-06	Troca de oleo	Servico de troca de oleo realizado no veiculo	Mecanica Avenida	4179.19	289324
605	14	2024-09-28	Sistema de freios	Servico de sistema de freios realizado no veiculo	Diesel Service	2605.16	191122
606	33	2024-03-20	Suspensao	Servico de suspensao realizado no veiculo	Centro Automotivo Brasil	7747.42	292449
607	118	2025-04-27	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Oficina Municipal	1786.45	289578
608	54	2024-03-12	Arrefecimento	Servico de arrefecimento realizado no veiculo	Mecanica Avenida	3186.70	260548
609	144	2026-03-08	Alinhamento	Servico de alinhamento realizado no veiculo	Diesel Service	868.92	305729
610	146	2025-11-27	Preventiva	Servico de preventiva realizado no veiculo	Centro Automotivo Brasil	4905.16	228722
611	82	2026-02-18	Corretiva	Servico de corretiva realizado no veiculo	Oficina Municipal	5981.33	229427
612	162	2026-10-31	Troca de oleo	Servico de troca de oleo realizado no veiculo	Oficina Central	6826.51	270870
613	58	2025-08-25	Sistema de freios	Servico de sistema de freios realizado no veiculo	Auto Center Parana	7853.46	166905
614	42	2024-07-20	Suspensao	Servico de suspensao realizado no veiculo	Mecanica Avenida	7518.08	313716
615	169	2024-06-17	Pneus	Servico de pneus realizado no veiculo	Centro Automotivo Brasil	1766.55	256957
616	158	2024-03-10	Motor	Servico de motor realizado no veiculo	Oficina Municipal	4057.42	295941
617	153	2024-03-06	Arrefecimento	Servico de arrefecimento realizado no veiculo	Oficina Central	4967.11	285428
618	7	2024-07-17	Alinhamento	Servico de alinhamento realizado no veiculo	Auto Center Parana	3727.80	228841
619	106	2024-12-23	Preventiva	Servico de preventiva realizado no veiculo	Mecanica Avenida	1387.49	243175
620	117	2025-08-05	Corretiva	Servico de corretiva realizado no veiculo	Diesel Service	3365.01	215824
621	3	2026-05-12	Troca de oleo	Servico de troca de oleo realizado no veiculo	Centro Automotivo Brasil	1580.57	311967
622	150	2024-04-05	Sistema de freios	Servico de sistema de freios realizado no veiculo	Oficina Municipal	6169.71	214341
623	180	2026-06-12	Suspensao	Servico de suspensao realizado no veiculo	Oficina Central	2137.01	244736
624	69	2026-04-01	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Auto Center Parana	349.73	283115
625	68	2026-05-16	Motor	Servico de motor realizado no veiculo	Diesel Service	1133.55	286777
626	60	2025-02-26	Arrefecimento	Servico de arrefecimento realizado no veiculo	Centro Automotivo Brasil	4205.63	222497
627	134	2026-09-15	Alinhamento	Servico de alinhamento realizado no veiculo	Oficina Municipal	5035.20	198446
628	57	2024-06-20	Preventiva	Servico de preventiva realizado no veiculo	Oficina Central	2290.63	152030
629	53	2026-02-08	Corretiva	Servico de corretiva realizado no veiculo	Auto Center Parana	4133.39	136901
630	111	2025-05-27	Troca de oleo	Servico de troca de oleo realizado no veiculo	Mecanica Avenida	2543.29	274180
631	54	2025-09-13	Sistema de freios	Servico de sistema de freios realizado no veiculo	Diesel Service	3805.03	260548
632	76	2025-03-03	Suspensao	Servico de suspensao realizado no veiculo	Centro Automotivo Brasil	1569.98	225577
633	82	2026-05-30	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Oficina Municipal	1254.09	229427
634	185	2024-12-29	Pneus	Servico de pneus realizado no veiculo	Oficina Central	5950.04	158846
635	149	2024-02-24	Motor	Servico de motor realizado no veiculo	Auto Center Parana	495.45	286486
636	157	2024-11-06	Arrefecimento	Servico de arrefecimento realizado no veiculo	Mecanica Avenida	3155.99	168792
637	87	2025-06-19	Alinhamento	Servico de alinhamento realizado no veiculo	Diesel Service	8494.12	232389
638	22	2024-07-31	Preventiva	Servico de preventiva realizado no veiculo	Centro Automotivo Brasil	4485.39	266982
639	48	2026-10-03	Corretiva	Servico de corretiva realizado no veiculo	Oficina Municipal	708.80	295673
640	91	2025-03-28	Troca de oleo	Servico de troca de oleo realizado no veiculo	Oficina Central	8607.38	284065
641	148	2024-07-13	Sistema de freios	Servico de sistema de freios realizado no veiculo	Auto Center Parana	3655.64	298488
642	14	2024-09-20	Suspensao	Servico de suspensao realizado no veiculo	Mecanica Avenida	5877.25	314914
643	167	2024-03-04	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Diesel Service	1469.72	163977
644	69	2025-08-03	Pneus	Servico de pneus realizado no veiculo	Centro Automotivo Brasil	829.01	283115
645	138	2025-10-21	Arrefecimento	Servico de arrefecimento realizado no veiculo	Oficina Central	1243.56	315794
646	66	2025-05-06	Alinhamento	Servico de alinhamento realizado no veiculo	Auto Center Parana	3992.22	129702
647	43	2026-02-01	Preventiva	Servico de preventiva realizado no veiculo	Mecanica Avenida	6704.20	289755
648	8	2026-01-22	Corretiva	Servico de corretiva realizado no veiculo	Diesel Service	3537.96	289324
649	148	2024-06-22	Troca de oleo	Servico de troca de oleo realizado no veiculo	Centro Automotivo Brasil	1792.10	298488
650	110	2025-04-21	Sistema de freios	Servico de sistema de freios realizado no veiculo	Oficina Municipal	1893.00	151366
651	43	2024-08-31	Suspensao	Servico de suspensao realizado no veiculo	Oficina Central	620.67	289755
652	67	2026-02-08	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Auto Center Parana	8054.54	257604
653	122	2024-10-23	Pneus	Servico de pneus realizado no veiculo	Mecanica Avenida	2755.67	132582
654	114	2026-10-09	Motor	Servico de motor realizado no veiculo	Diesel Service	162.83	260993
655	21	2026-10-29	Arrefecimento	Servico de arrefecimento realizado no veiculo	Centro Automotivo Brasil	1113.90	309255
656	25	2026-09-25	Alinhamento	Servico de alinhamento realizado no veiculo	Oficina Municipal	1132.21	278626
657	154	2025-07-10	Preventiva	Servico de preventiva realizado no veiculo	Oficina Central	4638.01	276087
658	81	2026-05-15	Corretiva	Servico de corretiva realizado no veiculo	Auto Center Parana	2654.28	280715
659	86	2024-09-18	Troca de oleo	Servico de troca de oleo realizado no veiculo	Mecanica Avenida	781.62	173853
660	150	2024-09-23	Sistema de freios	Servico de sistema de freios realizado no veiculo	Diesel Service	6309.18	214341
661	132	2024-02-18	Suspensao	Servico de suspensao realizado no veiculo	Centro Automotivo Brasil	7087.60	189082
662	138	2025-12-25	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Oficina Municipal	4966.12	315794
663	115	2026-03-02	Pneus	Servico de pneus realizado no veiculo	Oficina Central	4340.53	315881
664	172	2025-04-11	Motor	Servico de motor realizado no veiculo	Auto Center Parana	2924.91	38861
665	171	2025-02-04	Arrefecimento	Servico de arrefecimento realizado no veiculo	Mecanica Avenida	5926.16	247838
666	157	2024-12-23	Alinhamento	Servico de alinhamento realizado no veiculo	Diesel Service	1529.00	262958
667	133	2025-01-17	Preventiva	Servico de preventiva realizado no veiculo	Centro Automotivo Brasil	520.62	184085
668	153	2025-04-29	Corretiva	Servico de corretiva realizado no veiculo	Oficina Municipal	7312.76	285428
669	41	2024-11-05	Troca de oleo	Servico de troca de oleo realizado no veiculo	Oficina Central	150.32	234020
670	15	2024-04-03	Sistema de freios	Servico de sistema de freios realizado no veiculo	Auto Center Parana	1213.70	246321
671	175	2025-12-12	Suspensao	Servico de suspensao realizado no veiculo	Mecanica Avenida	5897.23	276286
672	82	2026-10-30	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Diesel Service	2998.20	229427
673	153	2024-11-14	Pneus	Servico de pneus realizado no veiculo	Centro Automotivo Brasil	6163.62	285428
674	187	2024-06-11	Motor	Servico de motor realizado no veiculo	Oficina Municipal	8194.48	283341
675	74	2025-10-29	Arrefecimento	Servico de arrefecimento realizado no veiculo	Oficina Central	1106.85	295295
676	27	2026-09-26	Alinhamento	Servico de alinhamento realizado no veiculo	Auto Center Parana	5892.21	265231
677	78	2024-02-22	Preventiva	Servico de preventiva realizado no veiculo	Mecanica Avenida	6500.77	318286
678	105	2025-02-02	Corretiva	Servico de corretiva realizado no veiculo	Diesel Service	479.47	226984
679	74	2025-06-22	Troca de oleo	Servico de troca de oleo realizado no veiculo	Centro Automotivo Brasil	8752.06	318087
680	44	2025-09-19	Sistema de freios	Servico de sistema de freios realizado no veiculo	Oficina Municipal	5036.26	225246
681	103	2026-08-24	Suspensao	Servico de suspensao realizado no veiculo	Oficina Central	3722.44	295659
682	165	2026-02-28	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Auto Center Parana	4546.56	220934
683	39	2025-09-10	Pneus	Servico de pneus realizado no veiculo	Mecanica Avenida	2889.93	235472
684	36	2024-08-22	Motor	Servico de motor realizado no veiculo	Diesel Service	612.69	274167
685	46	2024-03-26	Arrefecimento	Servico de arrefecimento realizado no veiculo	Centro Automotivo Brasil	8669.69	276806
686	103	2026-08-02	Alinhamento	Servico de alinhamento realizado no veiculo	Oficina Municipal	4225.29	295659
687	86	2024-07-20	Preventiva	Servico de preventiva realizado no veiculo	Oficina Central	3647.31	173853
688	23	2024-07-29	Corretiva	Servico de corretiva realizado no veiculo	Auto Center Parana	6191.42	126420
689	85	2024-06-19	Troca de oleo	Servico de troca de oleo realizado no veiculo	Mecanica Avenida	2118.00	277000
690	99	2026-06-03	Sistema de freios	Servico de sistema de freios realizado no veiculo	Diesel Service	4996.99	287275
691	161	2025-05-11	Suspensao	Servico de suspensao realizado no veiculo	Centro Automotivo Brasil	6276.21	237761
692	103	2025-03-08	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Oficina Municipal	5254.54	295659
693	11	2026-05-26	Pneus	Servico de pneus realizado no veiculo	Oficina Central	7793.18	172287
694	70	2026-01-21	Motor	Servico de motor realizado no veiculo	Auto Center Parana	5537.26	308534
695	135	2024-02-09	Arrefecimento	Servico de arrefecimento realizado no veiculo	Mecanica Avenida	8477.79	288826
696	81	2025-05-11	Alinhamento	Servico de alinhamento realizado no veiculo	Diesel Service	162.69	313899
697	132	2025-04-13	Preventiva	Servico de preventiva realizado no veiculo	Centro Automotivo Brasil	4026.21	201584
698	90	2024-03-15	Corretiva	Servico de corretiva realizado no veiculo	Oficina Municipal	7813.71	267279
699	29	2025-03-16	Troca de oleo	Servico de troca de oleo realizado no veiculo	Oficina Central	6402.00	195067
700	31	2026-08-13	Sistema de freios	Servico de sistema de freios realizado no veiculo	Auto Center Parana	8911.01	258937
701	80	2025-05-23	Suspensao	Servico de suspensao realizado no veiculo	Mecanica Avenida	6968.05	269530
702	72	2025-11-26	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Diesel Service	4335.41	292163
703	43	2025-09-03	Pneus	Servico de pneus realizado no veiculo	Centro Automotivo Brasil	3878.11	289755
704	142	2025-07-03	Motor	Servico de motor realizado no veiculo	Oficina Municipal	7454.07	277838
705	110	2025-06-20	Arrefecimento	Servico de arrefecimento realizado no veiculo	Oficina Central	1269.72	151366
706	127	2024-09-21	Alinhamento	Servico de alinhamento realizado no veiculo	Auto Center Parana	6142.25	286857
707	180	2026-01-19	Preventiva	Servico de preventiva realizado no veiculo	Mecanica Avenida	3348.26	244736
708	30	2025-01-23	Corretiva	Servico de corretiva realizado no veiculo	Diesel Service	759.38	294525
709	47	2024-11-05	Troca de oleo	Servico de troca de oleo realizado no veiculo	Centro Automotivo Brasil	517.76	299110
710	29	2024-09-24	Sistema de freios	Servico de sistema de freios realizado no veiculo	Oficina Municipal	1936.78	280467
711	152	2024-02-10	Suspensao	Servico de suspensao realizado no veiculo	Oficina Central	3053.02	295796
712	189	2025-09-13	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Auto Center Parana	8350.29	253328
713	71	2025-09-25	Pneus	Servico de pneus realizado no veiculo	Mecanica Avenida	8109.18	231791
714	176	2026-06-11	Motor	Servico de motor realizado no veiculo	Diesel Service	4060.48	278608
715	140	2025-10-07	Arrefecimento	Servico de arrefecimento realizado no veiculo	Centro Automotivo Brasil	2534.41	191053
716	2	2026-09-26	Alinhamento	Servico de alinhamento realizado no veiculo	Oficina Municipal	4859.08	204745
717	13	2026-07-24	Preventiva	Servico de preventiva realizado no veiculo	Oficina Central	5628.54	283352
718	142	2025-02-13	Corretiva	Servico de corretiva realizado no veiculo	Auto Center Parana	3275.07	277838
719	97	2024-04-21	Troca de oleo	Servico de troca de oleo realizado no veiculo	Mecanica Avenida	6260.51	282942
720	137	2026-10-14	Sistema de freios	Servico de sistema de freios realizado no veiculo	Diesel Service	5128.92	253525
721	18	2025-10-30	Suspensao	Servico de suspensao realizado no veiculo	Centro Automotivo Brasil	3724.92	300247
722	138	2026-03-25	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Oficina Municipal	7238.80	315794
723	23	2026-02-18	Pneus	Servico de pneus realizado no veiculo	Oficina Central	8628.72	269731
724	40	2026-02-19	Motor	Servico de motor realizado no veiculo	Auto Center Parana	3558.76	244777
725	78	2026-04-28	Arrefecimento	Servico de arrefecimento realizado no veiculo	Mecanica Avenida	2392.01	318286
726	136	2026-08-26	Alinhamento	Servico de alinhamento realizado no veiculo	Diesel Service	6234.76	201015
727	3	2025-12-28	Preventiva	Servico de preventiva realizado no veiculo	Centro Automotivo Brasil	7471.05	311967
728	58	2024-05-29	Corretiva	Servico de corretiva realizado no veiculo	Oficina Municipal	7551.07	166905
729	180	2024-11-30	Troca de oleo	Servico de troca de oleo realizado no veiculo	Oficina Central	1109.87	266679
730	174	2025-06-10	Sistema de freios	Servico de sistema de freios realizado no veiculo	Auto Center Parana	251.25	268268
731	165	2026-05-23	Suspensao	Servico de suspensao realizado no veiculo	Mecanica Avenida	5560.54	263766
732	169	2025-03-16	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Diesel Service	6105.06	256957
733	58	2024-05-20	Pneus	Servico de pneus realizado no veiculo	Centro Automotivo Brasil	1271.30	166905
734	42	2025-08-30	Motor	Servico de motor realizado no veiculo	Oficina Municipal	119.66	313716
735	183	2026-09-01	Arrefecimento	Servico de arrefecimento realizado no veiculo	Oficina Central	1320.09	286692
736	8	2026-03-01	Alinhamento	Servico de alinhamento realizado no veiculo	Auto Center Parana	8871.89	289324
737	131	2026-07-14	Preventiva	Servico de preventiva realizado no veiculo	Mecanica Avenida	2975.78	280434
738	87	2026-03-12	Troca de oleo	Servico de troca de oleo realizado no veiculo	Centro Automotivo Brasil	8929.74	232389
739	113	2026-09-02	Sistema de freios	Servico de sistema de freios realizado no veiculo	Oficina Municipal	4782.54	242288
740	62	2026-05-12	Suspensao	Servico de suspensao realizado no veiculo	Oficina Central	5504.94	163282
741	86	2024-06-28	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Auto Center Parana	1315.56	317313
742	123	2024-03-04	Pneus	Servico de pneus realizado no veiculo	Mecanica Avenida	1180.90	197823
743	119	2025-12-23	Motor	Servico de motor realizado no veiculo	Diesel Service	8178.22	298843
744	84	2026-04-07	Arrefecimento	Servico de arrefecimento realizado no veiculo	Centro Automotivo Brasil	1207.89	287670
745	25	2024-07-16	Alinhamento	Servico de alinhamento realizado no veiculo	Oficina Municipal	6926.64	278626
746	184	2026-08-22	Preventiva	Servico de preventiva realizado no veiculo	Oficina Central	7366.34	311654
747	89	2025-03-21	Corretiva	Servico de corretiva realizado no veiculo	Auto Center Parana	6980.10	279122
748	76	2026-10-08	Troca de oleo	Servico de troca de oleo realizado no veiculo	Mecanica Avenida	2260.12	284076
749	24	2025-10-21	Sistema de freios	Servico de sistema de freios realizado no veiculo	Diesel Service	8302.23	128204
750	83	2026-10-11	Suspensao	Servico de suspensao realizado no veiculo	Centro Automotivo Brasil	1369.35	205058
751	189	2025-04-28	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Oficina Municipal	6148.03	253328
752	85	2026-10-13	Pneus	Servico de pneus realizado no veiculo	Oficina Central	8573.08	277000
753	34	2024-10-08	Motor	Servico de motor realizado no veiculo	Auto Center Parana	3573.27	286591
754	112	2025-12-15	Arrefecimento	Servico de arrefecimento realizado no veiculo	Mecanica Avenida	5519.25	297928
755	6	2024-08-19	Alinhamento	Servico de alinhamento realizado no veiculo	Diesel Service	1476.08	260917
756	84	2025-04-22	Preventiva	Servico de preventiva realizado no veiculo	Centro Automotivo Brasil	6551.23	287670
757	104	2024-04-22	Corretiva	Servico de corretiva realizado no veiculo	Oficina Municipal	1256.90	264362
758	172	2024-04-12	Troca de oleo	Servico de troca de oleo realizado no veiculo	Oficina Central	524.09	231970
759	177	2026-03-15	Suspensao	Servico de suspensao realizado no veiculo	Mecanica Avenida	1129.12	249451
760	77	2026-02-12	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Diesel Service	4866.93	286696
761	4	2025-02-03	Pneus	Servico de pneus realizado no veiculo	Centro Automotivo Brasil	489.52	315833
762	171	2025-09-14	Motor	Servico de motor realizado no veiculo	Oficina Municipal	2320.26	247838
763	148	2024-12-25	Arrefecimento	Servico de arrefecimento realizado no veiculo	Oficina Central	2965.07	298488
764	30	2026-03-17	Preventiva	Servico de preventiva realizado no veiculo	Mecanica Avenida	3255.59	294525
765	132	2026-01-03	Corretiva	Servico de corretiva realizado no veiculo	Diesel Service	2236.90	201584
766	91	2025-01-31	Troca de oleo	Servico de troca de oleo realizado no veiculo	Centro Automotivo Brasil	2917.68	284065
767	93	2024-09-11	Sistema de freios	Servico de sistema de freios realizado no veiculo	Oficina Municipal	6686.24	287560
768	126	2024-08-07	Suspensao	Servico de suspensao realizado no veiculo	Oficina Central	6143.71	275697
769	178	2025-02-18	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Auto Center Parana	5093.37	192727
770	53	2025-04-27	Pneus	Servico de pneus realizado no veiculo	Mecanica Avenida	6372.55	136901
771	113	2025-03-04	Motor	Servico de motor realizado no veiculo	Diesel Service	1385.55	262034
772	91	2025-05-24	Arrefecimento	Servico de arrefecimento realizado no veiculo	Centro Automotivo Brasil	8328.08	284065
773	96	2025-10-01	Alinhamento	Servico de alinhamento realizado no veiculo	Oficina Municipal	1938.88	277702
774	165	2024-07-17	Preventiva	Servico de preventiva realizado no veiculo	Oficina Central	8137.68	299612
775	129	2025-11-15	Corretiva	Servico de corretiva realizado no veiculo	Auto Center Parana	8389.25	269161
776	174	2024-02-27	Troca de oleo	Servico de troca de oleo realizado no veiculo	Mecanica Avenida	5731.32	268268
777	114	2025-12-05	Sistema de freios	Servico de sistema de freios realizado no veiculo	Diesel Service	2650.29	260993
778	23	2025-07-15	Suspensao	Servico de suspensao realizado no veiculo	Centro Automotivo Brasil	6777.54	269731
779	99	2024-04-29	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Oficina Municipal	1737.32	287275
780	140	2026-08-27	Pneus	Servico de pneus realizado no veiculo	Oficina Central	2787.39	191053
781	59	2024-08-13	Motor	Servico de motor realizado no veiculo	Auto Center Parana	6773.53	244834
782	129	2025-04-09	Arrefecimento	Servico de arrefecimento realizado no veiculo	Mecanica Avenida	6088.58	269161
783	62	2024-04-05	Alinhamento	Servico de alinhamento realizado no veiculo	Diesel Service	982.79	163282
784	99	2026-06-24	Corretiva	Servico de corretiva realizado no veiculo	Oficina Municipal	1175.21	287275
785	36	2024-06-12	Troca de oleo	Servico de troca de oleo realizado no veiculo	Oficina Central	5109.59	274167
786	29	2025-09-03	Sistema de freios	Servico de sistema de freios realizado no veiculo	Auto Center Parana	5532.97	280467
787	133	2026-06-02	Suspensao	Servico de suspensao realizado no veiculo	Mecanica Avenida	6786.99	294138
788	157	2026-08-31	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Diesel Service	7739.92	262958
789	67	2025-12-29	Pneus	Servico de pneus realizado no veiculo	Centro Automotivo Brasil	4521.00	257604
790	29	2025-04-29	Motor	Servico de motor realizado no veiculo	Oficina Municipal	2956.38	280467
791	22	2024-09-15	Arrefecimento	Servico de arrefecimento realizado no veiculo	Oficina Central	2433.95	266982
792	104	2024-07-11	Alinhamento	Servico de alinhamento realizado no veiculo	Auto Center Parana	8373.95	264362
793	110	2025-08-31	Preventiva	Servico de preventiva realizado no veiculo	Mecanica Avenida	2152.89	151366
794	100	2025-08-24	Corretiva	Servico de corretiva realizado no veiculo	Diesel Service	4322.75	265393
795	162	2026-06-02	Troca de oleo	Servico de troca de oleo realizado no veiculo	Centro Automotivo Brasil	8699.92	270870
796	30	2024-03-24	Sistema de freios	Servico de sistema de freios realizado no veiculo	Oficina Municipal	4890.08	294525
797	70	2025-11-12	Suspensao	Servico de suspensao realizado no veiculo	Oficina Central	1495.13	308534
798	112	2024-05-09	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Auto Center Parana	7725.55	297928
799	108	2026-04-12	Pneus	Servico de pneus realizado no veiculo	Mecanica Avenida	3559.43	243112
800	106	2024-04-10	Motor	Servico de motor realizado no veiculo	Diesel Service	453.04	243175
801	25	2024-09-21	Arrefecimento	Servico de arrefecimento realizado no veiculo	Centro Automotivo Brasil	2758.75	278626
802	124	2024-10-15	Alinhamento	Servico de alinhamento realizado no veiculo	Oficina Municipal	8428.83	264430
803	106	2025-08-30	Preventiva	Servico de preventiva realizado no veiculo	Oficina Central	7280.85	243175
804	40	2025-09-11	Corretiva	Servico de corretiva realizado no veiculo	Auto Center Parana	4183.00	244777
805	32	2025-04-09	Troca de oleo	Servico de troca de oleo realizado no veiculo	Mecanica Avenida	433.40	234510
806	157	2026-09-26	Sistema de freios	Servico de sistema de freios realizado no veiculo	Diesel Service	913.99	297801
807	163	2025-02-14	Suspensao	Servico de suspensao realizado no veiculo	Centro Automotivo Brasil	4003.32	256002
808	69	2026-10-11	Pneus	Servico de pneus realizado no veiculo	Oficina Central	1404.91	283115
809	185	2024-07-07	Motor	Servico de motor realizado no veiculo	Auto Center Parana	3044.93	158846
810	26	2026-10-10	Arrefecimento	Servico de arrefecimento realizado no veiculo	Mecanica Avenida	1840.58	150515
811	24	2024-10-23	Alinhamento	Servico de alinhamento realizado no veiculo	Diesel Service	6904.73	128204
812	40	2025-07-01	Preventiva	Servico de preventiva realizado no veiculo	Centro Automotivo Brasil	3205.06	287750
813	134	2025-01-23	Corretiva	Servico de corretiva realizado no veiculo	Oficina Municipal	445.19	198446
814	28	2025-06-06	Troca de oleo	Servico de troca de oleo realizado no veiculo	Oficina Central	1241.14	198084
815	4	2024-06-08	Sistema de freios	Servico de sistema de freios realizado no veiculo	Auto Center Parana	3909.10	315833
816	180	2026-01-16	Suspensao	Servico de suspensao realizado no veiculo	Mecanica Avenida	3134.67	266679
817	43	2026-04-13	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Diesel Service	3519.70	289755
818	170	2025-04-18	Pneus	Servico de pneus realizado no veiculo	Centro Automotivo Brasil	988.04	228823
819	84	2025-06-16	Motor	Servico de motor realizado no veiculo	Oficina Municipal	1526.48	287670
820	82	2025-04-04	Arrefecimento	Servico de arrefecimento realizado no veiculo	Oficina Central	5653.80	292226
821	76	2025-04-28	Alinhamento	Servico de alinhamento realizado no veiculo	Auto Center Parana	1684.64	284076
822	175	2025-04-18	Preventiva	Servico de preventiva realizado no veiculo	Mecanica Avenida	2632.11	276286
823	76	2024-07-13	Corretiva	Servico de corretiva realizado no veiculo	Diesel Service	3554.09	284076
824	55	2026-09-23	Troca de oleo	Servico de troca de oleo realizado no veiculo	Centro Automotivo Brasil	7010.90	276268
825	166	2025-05-19	Sistema de freios	Servico de sistema de freios realizado no veiculo	Oficina Municipal	1945.65	179250
826	96	2026-09-22	Suspensao	Servico de suspensao realizado no veiculo	Oficina Central	5856.64	288212
827	42	2025-03-24	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Auto Center Parana	5497.30	313716
828	166	2024-03-16	Pneus	Servico de pneus realizado no veiculo	Mecanica Avenida	859.17	179250
829	135	2025-05-07	Motor	Servico de motor realizado no veiculo	Diesel Service	432.08	288826
830	91	2025-10-03	Arrefecimento	Servico de arrefecimento realizado no veiculo	Centro Automotivo Brasil	8124.63	284065
831	10	2026-09-29	Alinhamento	Servico de alinhamento realizado no veiculo	Oficina Municipal	2209.25	295031
832	134	2024-08-07	Preventiva	Servico de preventiva realizado no veiculo	Oficina Central	5162.14	233419
833	66	2024-04-22	Corretiva	Servico de corretiva realizado no veiculo	Auto Center Parana	4349.96	232605
834	38	2024-11-27	Troca de oleo	Servico de troca de oleo realizado no veiculo	Mecanica Avenida	4934.13	304753
835	1	2026-09-07	Sistema de freios	Servico de sistema de freios realizado no veiculo	Diesel Service	5332.34	252493
836	187	2026-05-06	Suspensao	Servico de suspensao realizado no veiculo	Centro Automotivo Brasil	1804.20	283341
837	25	2026-09-19	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Oficina Municipal	3561.12	278626
838	133	2024-04-04	Pneus	Servico de pneus realizado no veiculo	Oficina Central	7830.10	294138
839	77	2024-05-30	Motor	Servico de motor realizado no veiculo	Auto Center Parana	1205.75	286696
840	108	2024-05-08	Arrefecimento	Servico de arrefecimento realizado no veiculo	Mecanica Avenida	3370.30	243112
841	120	2024-03-02	Alinhamento	Servico de alinhamento realizado no veiculo	Diesel Service	814.01	238642
842	20	2024-12-08	Preventiva	Servico de preventiva realizado no veiculo	Centro Automotivo Brasil	8785.68	303291
843	184	2026-07-20	Corretiva	Servico de corretiva realizado no veiculo	Oficina Municipal	6977.21	311654
844	17	2026-09-18	Troca de oleo	Servico de troca de oleo realizado no veiculo	Oficina Central	7419.93	240048
845	85	2024-08-29	Sistema de freios	Servico de sistema de freios realizado no veiculo	Auto Center Parana	4688.45	277000
846	106	2025-08-08	Suspensao	Servico de suspensao realizado no veiculo	Mecanica Avenida	2507.34	243175
847	146	2025-04-08	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Diesel Service	5034.16	265601
848	104	2025-06-10	Pneus	Servico de pneus realizado no veiculo	Centro Automotivo Brasil	3563.60	264362
849	105	2026-08-06	Motor	Servico de motor realizado no veiculo	Oficina Municipal	8504.76	249051
850	3	2025-06-23	Arrefecimento	Servico de arrefecimento realizado no veiculo	Oficina Central	574.32	311967
851	184	2026-03-08	Alinhamento	Servico de alinhamento realizado no veiculo	Auto Center Parana	6460.60	311654
852	127	2024-08-14	Preventiva	Servico de preventiva realizado no veiculo	Mecanica Avenida	4194.89	286857
853	147	2025-09-27	Corretiva	Servico de corretiva realizado no veiculo	Diesel Service	860.60	227098
854	46	2025-01-16	Troca de oleo	Servico de troca de oleo realizado no veiculo	Centro Automotivo Brasil	5719.69	276806
855	5	2026-09-26	Sistema de freios	Servico de sistema de freios realizado no veiculo	Oficina Municipal	682.63	276880
856	171	2026-04-03	Suspensao	Servico de suspensao realizado no veiculo	Oficina Central	1197.51	247838
857	64	2026-05-02	Sistema eletrico	Servico de sistema eletrico realizado no veiculo	Auto Center Parana	1323.84	309221
858	185	2025-08-14	Pneus	Servico de pneus realizado no veiculo	Mecanica Avenida	5385.93	306128
859	26	2026-07-02	Motor	Servico de motor realizado no veiculo	Diesel Service	4477.34	268977
860	67	2026-11-01	Arrefecimento	Servico de arrefecimento realizado no veiculo	Centro Automotivo Brasil	637.45	257604
\.


--
-- TOC entry 3609 (class 0 OID 24577)
-- Dependencies: 220
-- Data for Name: modalidade; Type: TABLE DATA; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

COPY gabriel_trabalho_bd.modalidade (id, nome, descricao) FROM stdin;
4abd4707-52fb-4526-9c5a-e9108ac6d51d	Transporte de carga	Deslocamento de mercadorias entre unidades e clientes
5dcc2749-47ee-41f5-bf52-d7a2d20fbe6d	Transporte de passageiros	Deslocamento de funcionários e visitantes
6e149b4f-121c-40a5-a58d-eb7758f89d69	Entrega urbana	Entregas curtas dentro da cidade
9e057034-0f08-44a9-a25c-5639c2739fbe	Viagem intermunicipal	Deslocamentos entre cidades da região
fcce616b-9090-4c58-aac4-29dbbb859070	Serviço interno	Uso interno da empresa, sem carga
bb831427-e8e1-4a27-804b-656f26b2d50f	Manutenção externa	Deslocamento até oficinas e concessionárias
\.


--
-- TOC entry 3613 (class 0 OID 32785)
-- Dependencies: 224
-- Data for Name: motoristas; Type: TABLE DATA; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

COPY gabriel_trabalho_bd.motoristas (id_motorista, nome, cnh, categoria_cnh, telefone, data_admissao, status, validade_cnh) FROM stdin;
1	joao da silva	12345678901	d	42999910001	2021-02-10	ativo	2027-07-08
2	carlos eduardo	23456789012	d	42999910002	2020-06-15	ativo	2027-08-14
3	marcos antonio	34567890123	e	42999910003	2019-03-20	ativo	2027-09-20
4	andre luiz	45678901234	d	42999910004	2022-01-12	ativo	2027-10-27
5	roberto souza	56789012345	e	42999910005	2018-09-05	ativo	2027-12-03
6	felipe martins	67890123456	d	42999910006	2023-02-01	ativo	2028-01-09
7	lucas pereira	78901234567	b	42999910007	2022-07-18	ativo	2028-02-15
8	rafael costa	89012345678	d	42999910008	2021-11-22	ativo	2028-03-23
9	gustavo oliveira	90123456789	e	42999910009	2019-05-13	ativo	2028-04-29
10	daniel rocha	11234567890	d	42999910010	2020-10-08	ativo	2028-06-05
11	thiago santos	22345678901	b	42999910011	2023-04-17	ativo	2028-07-12
12	bruno almeida	33456789012	d	42999910012	2022-03-14	ativo	2028-08-18
13	eduardo lima	44567890123	e	42999910013	2018-12-03	ativo	2028-09-24
14	mateus fernandes	55678901234	d	42999910014	2021-08-25	ativo	2028-10-31
15	diego cardoso	66789012345	b	42999910015	2020-04-11	ativo	2028-12-07
16	henrique barbosa	77890123456	d	42999910016	2022-10-19	ativo	2029-01-13
17	leonardo dias	88901234567	e	42999910017	2019-07-30	ativo	2029-02-19
18	vinicius moraes	99012345678	d	42999910018	2023-01-09	ativo	2029-03-28
19	gabriel souza	10123456789	b	42999910019	2021-05-27	ativo	2029-05-04
20	murilo teixeira	21234567890	d	42999910020	2020-02-18	ativo	2029-06-10
21	rafael ferreira	80000000001	e	42999930001	2019-01-03	ativo	2027-01-10
22	paulo cardoso	80000000002	e	42999930002	2020-06-05	ativo	2028-08-11
23	lucas moreira	80000000003	d	42999930003	2021-11-07	ativo	2029-03-12
24	bruno mendes	80000000004	d	42999930004	2022-04-09	ativo	2027-10-13
25	diego barbosa	80000000005	d	42999930005	2023-09-11	ativo	2028-05-14
26	thiago ribeiro	80000000006	e	42999930006	2024-02-13	ativo	2029-12-15
27	felipe araujo	80000000007	b	42999930007	2019-07-15	ativo	2027-07-16
28	gustavo oliveira	80000000008	b	42999930008	2020-12-17	ativo	2028-02-17
29	rodrigo teixeira	80000000009	c	42999930009	2021-05-19	ativo	2029-09-18
30	anderson nunes	80000000010	c	42999930010	2022-10-21	inativo	2027-04-19
31	rafael barbosa	70000000001	e	42999840001	2015-01-02	ativo	2027-01-08
32	paulo pereira	70000000002	e	42999840002	2016-06-03	ativo	2028-08-09
33	lucas oliveira	70000000003	e	42999840003	2017-11-04	ativo	2029-03-10
34	bruno araujo	70000000004	d	42999840004	2018-04-05	ativo	2030-10-11
35	diego ferreira	70000000005	d	42999840005	2019-09-06	ativo	2027-05-12
36	thiago nunes	70000000006	d	42999840006	2020-02-07	ativo	2028-12-13
37	felipe mendes	70000000007	d	42999840007	2021-07-08	ativo	2029-07-14
38	gustavo moreira	70000000008	c	42999840008	2022-12-09	ativo	2030-02-15
39	rodrigo batista	70000000009	c	42999840009	2023-05-10	ativo	2027-09-16
40	anderson ribeiro	70000000010	b	42999840010	2024-10-11	ativo	2028-04-17
41	marcelo lopes	70000000011	e	42999840011	2015-03-12	ativo	2029-11-18
42	eduardo teixeira	70000000012	e	42999840012	2016-08-13	ativo	2030-06-19
43	fabio correia	70000000013	e	42999840013	2017-01-14	ativo	2027-01-20
44	leandro cardoso	70000000014	d	42999840014	2018-06-15	ativo	2028-08-21
45	renato machado	70000000015	d	42999840015	2019-11-16	ativo	2029-03-22
46	vinicius barbosa	70000000016	d	42999840016	2020-04-17	ativo	2030-10-23
47	matheus pereira	70000000017	d	42999840017	2021-09-18	ativo	2027-05-24
48	daniel oliveira	70000000018	c	42999840018	2022-02-19	ativo	2028-12-25
49	julio araujo	70000000019	c	42999840019	2023-07-20	inativo	2029-07-26
50	henrique ferreira	70000000020	b	42999840020	2024-12-21	inativo	2030-02-27
51	Joao Silva Souza	97000000001	C	(42) 95906-9750	2020-01-21	ativo	2027-09-12
52	Pedro Almeida Martins	97000000002	D	(42) 96978-8100	2025-10-15	ativo	2030-08-16
53	Lucas Martins Costa	97000000003	E	(42) 99518-3393	2021-12-18	ativo	2028-05-04
54	Marcos Santos Ribeiro	97000000004	B	(42) 97286-8409	2020-05-23	ativo	2031-01-05
55	Rafael Nascimento Almeida	97000000005	C	(42) 98267-6386	2024-05-15	ativo	2028-07-05
56	Carlos Rocha Mendes	97000000006	D	(42) 98534-7383	2018-09-29	ativo	2030-09-20
57	Andre Oliveira Lima	97000000007	E	(42) 93741-5675	2019-08-26	ativo	2029-04-01
58	Paulo Lima Silva	97000000008	B	(42) 91739-9019	2018-12-08	ativo	2031-09-30
59	Bruno Ribeiro Fernandes	97000000009	C	(42) 91212-1017	2021-12-30	inativo	2031-07-26
60	Mateus Souza Oliveira	97000000010	D	(42) 96272-3275	2020-12-07	ativo	2030-06-24
61	Felipe Araujo Gomes	97000000011	E	(42) 91049-2194	2026-01-31	ativo	2029-03-08
62	Diego Barbosa Pereira	97000000012	B	(42) 99538-9563	2023-06-01	ativo	2030-05-18
63	Eduardo Pereira Rocha	97000000013	C	(42) 97770-2331	2024-06-16	ativo	2029-09-27
64	Thiago Fernandes Rodrigues	97000000014	D	(42) 98498-4108	2019-02-09	ativo	2029-12-21
65	Gustavo Mendes Barbosa	97000000015	E	(42) 93278-9965	2021-09-17	ativo	2029-06-21
66	Henrique Costa Nascimento	97000000016	B	(42) 92193-9897	2022-09-29	ativo	2029-12-23
67	Roberto Carvalho Cardoso	97000000017	C	(42) 98776-1751	2022-09-18	ativo	2030-12-22
68	Daniel Cardoso Araujo	97000000018	D	(42) 95825-2004	2025-07-19	inativo	2030-08-21
69	Leonardo Rodrigues Santos	97000000019	E	(42) 91359-8842	2020-01-05	ativo	2028-09-21
70	Ricardo Gomes Carvalho	97000000020	B	(42) 99396-6231	2019-02-20	ativo	2027-10-20
71	Joao Silva Souza	97000000021	C	(42) 96299-3982	2024-12-22	ativo	2028-06-24
72	Pedro Almeida Martins	97000000022	D	(42) 97133-9767	2022-05-31	ativo	2029-09-27
73	Lucas Martins Costa	97000000023	E	(42) 99797-1659	2019-05-12	ativo	2028-03-04
74	Marcos Santos Ribeiro	97000000024	B	(42) 93155-8653	2020-03-29	ativo	2030-03-22
75	Rafael Nascimento Almeida	97000000025	C	(42) 94689-9221	2022-07-04	ativo	2030-08-14
76	Carlos Rocha Mendes	97000000026	D	(42) 91888-1501	2020-09-20	ativo	2031-07-13
77	Andre Oliveira Lima	97000000027	E	(42) 93670-4988	2019-04-24	inativo	2031-09-30
78	Paulo Lima Silva	97000000028	B	(42) 98499-6882	2026-02-05	ativo	2030-05-03
79	Bruno Ribeiro Fernandes	97000000029	C	(42) 96652-6062	2022-07-13	ativo	2027-04-14
80	Mateus Souza Oliveira	97000000030	D	(42) 99582-8297	2022-04-18	ativo	2031-09-21
81	Felipe Araujo Gomes	97000000031	E	(42) 93798-4686	2024-05-21	ativo	2031-04-07
82	Diego Barbosa Pereira	97000000032	B	(42) 97595-5080	2022-02-27	ativo	2029-08-20
83	Eduardo Pereira Rocha	97000000033	C	(42) 95179-6599	2021-03-19	ativo	2027-09-07
84	Thiago Fernandes Rodrigues	97000000034	D	(42) 99268-8751	2024-10-29	ativo	2029-02-02
85	Gustavo Mendes Barbosa	97000000035	E	(42) 94861-6813	2023-11-26	ativo	2031-05-28
86	Henrique Costa Nascimento	97000000036	B	(42) 92491-7909	2019-12-16	inativo	2029-12-26
87	Roberto Carvalho Cardoso	97000000037	C	(42) 99566-3202	2021-12-30	ativo	2029-11-14
88	Daniel Cardoso Araujo	97000000038	D	(42) 92613-2369	2024-07-12	ativo	2029-09-25
89	Leonardo Rodrigues Santos	97000000039	E	(42) 94930-2662	2018-10-30	ativo	2028-04-03
90	Ricardo Gomes Carvalho	97000000040	B	(42) 93216-4483	2026-04-30	ativo	2028-06-21
91	Joao Silva Souza	97000000041	C	(42) 91805-4312	2021-11-26	ativo	2030-08-12
92	Pedro Almeida Martins	97000000042	D	(42) 98348-6067	2020-09-01	ativo	2029-06-27
93	Lucas Martins Costa	97000000043	E	(42) 94526-2675	2021-12-24	ativo	2027-04-09
94	Marcos Santos Ribeiro	97000000044	B	(42) 93480-3657	2019-03-12	ativo	2029-06-16
95	Rafael Nascimento Almeida	97000000045	C	(42) 96179-3786	2019-10-01	inativo	2027-08-27
96	Carlos Rocha Mendes	97000000046	D	(42) 98415-3369	2021-10-23	ativo	2031-04-18
97	Andre Oliveira Lima	97000000047	E	(42) 97163-5609	2026-01-23	ativo	2030-10-10
98	Paulo Lima Silva	97000000048	B	(42) 95828-8855	2023-09-14	ativo	2028-07-01
99	Bruno Ribeiro Fernandes	97000000049	C	(42) 97718-1949	2019-09-05	ativo	2028-03-13
100	Mateus Souza Oliveira	97000000050	D	(42) 96448-5968	2019-04-29	ativo	2027-11-17
101	Felipe Araujo Gomes	97000000051	E	(42) 94829-6487	2021-10-21	ativo	2028-12-13
102	Diego Barbosa Pereira	97000000052	B	(42) 96987-8651	2026-04-30	ativo	2028-05-13
103	Eduardo Pereira Rocha	97000000053	C	(42) 92839-4296	2020-07-12	ativo	2030-07-20
104	Thiago Fernandes Rodrigues	97000000054	D	(42) 96851-2017	2022-06-04	inativo	2027-08-09
105	Gustavo Mendes Barbosa	97000000055	E	(42) 98984-9466	2023-03-04	ativo	2030-06-05
106	Henrique Costa Nascimento	97000000056	B	(42) 93999-6981	2026-03-25	ativo	2027-07-22
107	Roberto Carvalho Cardoso	97000000057	C	(42) 93984-9908	2025-08-07	ativo	2027-08-25
108	Daniel Cardoso Araujo	97000000058	D	(42) 97665-7290	2020-08-26	ativo	2028-03-05
109	Leonardo Rodrigues Santos	97000000059	E	(42) 99596-8354	2025-02-12	ativo	2030-08-01
110	Ricardo Gomes Carvalho	97000000060	B	(42) 95984-7298	2025-05-12	ativo	2030-02-09
111	Joao Silva Souza	97000000061	C	(42) 94130-9345	2022-10-21	ativo	2030-08-27
112	Pedro Almeida Martins	97000000062	D	(42) 94813-5673	2023-07-10	ativo	2027-03-14
113	Lucas Martins Costa	97000000063	E	(42) 93932-8252	2025-07-23	inativo	2030-05-08
114	Marcos Santos Ribeiro	97000000064	B	(42) 91586-4602	2023-02-04	ativo	2029-04-04
115	Rafael Nascimento Almeida	97000000065	C	(42) 99271-2215	2023-01-17	ativo	2027-07-18
116	Carlos Rocha Mendes	97000000066	D	(42) 96583-2361	2022-03-18	ativo	2028-09-08
117	Andre Oliveira Lima	97000000067	E	(42) 94176-1442	2022-03-21	ativo	2030-07-19
118	Paulo Lima Silva	97000000068	B	(42) 92738-6033	2019-04-30	ativo	2028-08-19
119	Bruno Ribeiro Fernandes	97000000069	C	(42) 95267-6727	2025-09-17	ativo	2031-03-04
120	Mateus Souza Oliveira	97000000070	D	(42) 95858-5487	2024-11-02	ativo	2028-02-15
121	Felipe Araujo Gomes	97000000071	E	(42) 95655-4989	2024-09-24	ativo	2029-06-17
122	Diego Barbosa Pereira	97000000072	B	(42) 99962-4070	2023-02-28	inativo	2028-04-08
123	Eduardo Pereira Rocha	97000000073	C	(42) 99506-2719	2019-04-30	ativo	2027-10-27
124	Thiago Fernandes Rodrigues	97000000074	D	(42) 94670-2729	2020-06-17	ativo	2029-02-16
125	Gustavo Mendes Barbosa	97000000075	E	(42) 93302-1219	2025-12-07	ativo	2030-04-01
126	Henrique Costa Nascimento	97000000076	B	(42) 92883-1196	2018-11-16	ativo	2027-04-22
127	Roberto Carvalho Cardoso	97000000077	C	(42) 98180-9164	2022-07-16	ativo	2030-04-14
128	Daniel Cardoso Araujo	97000000078	D	(42) 96254-9710	2021-02-24	ativo	2029-11-15
129	Leonardo Rodrigues Santos	97000000079	E	(42) 91916-2213	2023-06-28	ativo	2027-09-19
130	Ricardo Gomes Carvalho	97000000080	B	(42) 95989-1052	2020-07-10	ativo	2028-04-04
131	Joao Silva Souza	97000000081	C	(42) 96959-9267	2021-10-08	inativo	2027-04-16
132	Pedro Almeida Martins	97000000082	D	(42) 99412-8611	2022-08-04	ativo	2028-01-23
133	Lucas Martins Costa	97000000083	E	(42) 97259-4645	2019-06-23	ativo	2029-09-01
134	Marcos Santos Ribeiro	97000000084	B	(42) 98502-3363	2024-05-22	ativo	2029-04-08
135	Rafael Nascimento Almeida	97000000085	C	(42) 98117-6527	2024-06-01	ativo	2030-10-04
136	Carlos Rocha Mendes	97000000086	D	(42) 95626-2679	2021-07-13	ativo	2031-06-09
137	Andre Oliveira Lima	97000000087	E	(42) 99775-8510	2025-10-10	ativo	2031-08-25
138	Paulo Lima Silva	97000000088	B	(42) 93549-5989	2025-10-18	ativo	2031-07-11
139	Bruno Ribeiro Fernandes	97000000089	C	(42) 91838-4578	2021-03-30	ativo	2027-11-24
140	Mateus Souza Oliveira	97000000090	D	(42) 97354-5775	2023-03-05	inativo	2029-08-19
141	Felipe Araujo Gomes	97000000091	E	(42) 93229-4913	2019-07-12	ativo	2027-10-14
142	Diego Barbosa Pereira	97000000092	B	(42) 94483-5709	2020-09-23	ativo	2028-06-16
143	Eduardo Pereira Rocha	97000000093	C	(42) 95091-4178	2021-04-01	ativo	2031-03-13
144	Thiago Fernandes Rodrigues	97000000094	D	(42) 93082-7581	2019-01-23	ativo	2028-11-08
145	Gustavo Mendes Barbosa	97000000095	E	(42) 92215-3490	2025-10-24	ativo	2031-02-23
146	Henrique Costa Nascimento	97000000096	B	(42) 99315-9930	2021-12-26	ativo	2029-01-05
147	Roberto Carvalho Cardoso	97000000097	C	(42) 98813-1984	2020-02-24	ativo	2031-07-04
148	Daniel Cardoso Araujo	97000000098	D	(42) 93359-5185	2020-06-26	ativo	2029-06-28
149	Leonardo Rodrigues Santos	97000000099	E	(42) 99251-1619	2021-06-30	inativo	2030-10-17
150	Ricardo Gomes Carvalho	97000000100	B	(42) 95485-5757	2018-08-26	ativo	2028-03-15
\.


--
-- TOC entry 3611 (class 0 OID 32769)
-- Dependencies: 222
-- Data for Name: veiculos; Type: TABLE DATA; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

COPY gabriel_trabalho_bd.veiculos (id_veiculo, placa, marca, modelo, ano, tipo, capacidade, status, quilometragem_atual) FROM stdin;
151	QZ061A1	Fiat	Strada	2021	Utilitario	7347.25	ativo	216293
188	QZ098A8	Iveco	Daily	2025	Caminhao	7818.13	em_manutencao	53828
164	QZ074A4	Ford	Ranger	2023	Caminhonete	693.42	inativo	266092
92	QZ002A2	Volkswagen	Gol	2017	Passeio	382.61	ativo	204425
121	QZ031A1	Fiat	Strada	2024	Utilitario	1105.40	ativo	201243
155	QZ065A5	Mercedes-Benz	Sprinter	2025	Van	1887.51	ativo	187877
143	QZ053A3	Chevrolet	S10	2024	Caminhonete	11568.24	em_manutencao	106986
160	QZ070A0	Hyundai	HB20	2019	Passeio	399.98	ativo	246947
156	QZ066A6	Renault	Master	2015	Van	5150.38	ativo	314464
95	QZ005A5	Mercedes-Benz	Sprinter	2020	Van	2550.64	ativo	209194
128	QZ038A8	Iveco	Daily	2020	Caminhao	10768.52	em_manutencao	281773
186	QZ096A6	Renault	Master	2023	Van	10578.39	ativo	207358
109	QZ019A9	Toyota	Hilux	2023	Caminhonete	9192.77	inativo	271349
79	ext2i28	chevrolet	onix	2019	passeio	0.00	ativo	178688
98	QZ008A8	Iveco	Daily	2023	Caminhao	5731.07	em_manutencao	253043
181	QZ091A1	Fiat	Strada	2018	Utilitario	9540.58	ativo	270644
51	ext0a00	volkswagen	delivery	2023	caminhao	8.59	em_manutencao	177041
102	QZ012A2	Volkswagen	Gol	2016	Passeio	393.59	ativo	268063
101	QZ011A1	Fiat	Strada	2015	Utilitario	842.02	ativo	178322
56	ext0f05	volkswagen	delivery	2018	caminhao	10.48	em_manutencao	301949
190	QZ100A0	Hyundai	HB20	2016	Passeio	431.83	ativo	173359
94	QZ004A4	Ford	Ranger	2019	Caminhonete	6591.65	inativo	126988
168	QZ078A8	Iveco	Daily	2016	Caminhao	11773.05	em_manutencao	283138
182	QZ092A2	Volkswagen	Gol	2019	Passeio	462.73	ativo	313010
88	ext3h37	toyota	corolla cross	2021	suv	0.00	ativo	302323
45	pop1e14	hyundai	hb20	2024	passeio	0.00	ativo	273608
35	pop0e04	fiat	ducato	2024	van	1.55	ativo	313900
50	pop1j19	honda	civic	2019	passeio	0.00	ativo	232769
173	QZ083A3	Chevrolet	S10	2021	Caminhonete	5630.26	em_manutencao	285420
139	QZ049A9	Toyota	Hilux	2020	Caminhonete	8227.31	inativo	223041
130	QZ040A0	Hyundai	HB20	2022	Passeio	538.56	ativo	294207
73	ext2c22	chevrolet	s10	2016	picape	1.04	em_manutencao	283333
19	abd9f01	jeep	renegade	2021	suv	0.00	ativo	226900
12	abd2e34	volkswagen	constellation	2018	caminhao	12.00	ativo	112359
107	QZ017A7	Volkswagen	Delivery	2021	Caminhao	1033.30	ativo	259205
49	pop1i18	toyota	yaris	2022	passeio	0.00	ativo	297911
9	abc9e01	volkswagen	delivery	2019	caminhao	5.00	ativo	145954
141	QZ051A1	Fiat	Strada	2022	Utilitario	8320.30	ativo	305428
75	ext2e24	volkswagen	saveiro	2020	picape	0.94	ativo	166089
61	ext1a10	fiat	ducato	2023	van	1.62	ativo	294212
145	QZ055A5	Mercedes-Benz	Sprinter	2015	Van	9598.95	ativo	278417
159	QZ069A9	Toyota	Hilux	2018	Caminhonete	10239.88	inativo	304196
16	abd6e78	toyota	corolla	2022	passeio	0.00	ativo	215243
63	ext1c12	mercedes-benz	sprinter	2019	van	1.67	ativo	254030
116	QZ026A6	Renault	Master	2019	Van	8426.55	ativo	267194
179	QZ089A9	Toyota	Hilux	2016	Caminhonete	6200.82	inativo	291570
125	QZ035A5	Mercedes-Benz	Sprinter	2017	Van	8709.65	ativo	309916
52	ext0b01	mercedes-benz	accelo	2021	caminhao	8.93	ativo	289179
37	pop0g06	mercedes-benz	sprinter	2018	van	2.08	ativo	252556
33	pop0c02	volvo	vm	2022	caminhao	12.18	ativo	292449
118	QZ028A8	Iveco	Daily	2021	Caminhao	2531.46	em_manutencao	289578
144	QZ054A4	Ford	Ranger	2025	Caminhonete	9224.07	inativo	305729
158	QZ068A8	Iveco	Daily	2017	Caminhao	7762.41	em_manutencao	295941
7	abc7d89	renault	master	2022	van	1.60	ativo	228841
117	QZ027A7	Volkswagen	Delivery	2020	Caminhao	7447.33	ativo	215824
68	ext1h17	renault	kangoo	2017	utilitario	0.69	ativo	286777
60	ext0j09	peugeot	boxer	2020	van	2.18	ativo	222497
57	ext0g06	renault	master	2022	van	1.91	ativo	152030
111	QZ021A1	Fiat	Strada	2025	Utilitario	11723.91	ativo	274180
54	ext0d03	iveco	tector	2015	caminhao	11.05	ativo	260548
149	QZ059A9	Toyota	Hilux	2019	Caminhonete	11950.24	inativo	286486
48	pop1h17	volkswagen	polo	2018	passeio	0.00	ativo	295673
14	abd4e56	chevrolet	onix	2023	passeio	0.00	ativo	314914
167	QZ077A7	Volkswagen	Delivery	2015	Caminhao	7453.09	ativo	163977
122	QZ032A2	Volkswagen	Gol	2025	Passeio	400.05	ativo	132582
21	abe1f23	fiat	toro	2020	picape	1.00	ativo	309255
154	QZ064A4	Ford	Ranger	2024	Caminhonete	6426.93	inativo	276087
150	QZ060A0	Hyundai	HB20	2020	Passeio	525.79	ativo	214341
115	QZ025A5	Mercedes-Benz	Sprinter	2018	Van	8598.50	ativo	315881
41	pop1a10	chevrolet	s10	2018	picape	0.85	ativo	234020
15	abd5e67	hyundai	hb20	2021	passeio	0.00	ativo	246321
153	QZ063A3	Chevrolet	S10	2023	Caminhonete	1785.48	em_manutencao	285428
27	abe7f89	renault	oroch	2021	picape	0.70	ativo	265231
74	ext2d23	ford	ranger	2016	picape	1.05	ativo	318087
44	pop1d13	toyota	hilux	2022	picape	1.02	ativo	225246
39	pop0i08	peugeot	partner	2025	utilitario	0.90	ativo	235472
161	QZ071A1	Fiat	Strada	2020	Utilitario	3764.95	ativo	237761
103	QZ013A3	Chevrolet	S10	2017	Caminhonete	3107.33	em_manutencao	295659
11	abd1e23	iveco	daily	2021	caminhao	3.50	em_viagem	172287
81	ext3a30	toyota	yaris	2018	passeio	0.00	ativo	313899
90	ext3j39	volkswagen	t-cross	2024	suv	0.00	inativo	267279
31	pop0a00	volkswagen	delivery	2019	caminhao	6.95	em_manutencao	258937
80	ext2j29	volkswagen	polo	2023	passeio	0.00	ativo	269530
72	ext2b21	toyota	hilux	2018	picape	0.96	ativo	292163
47	pop1g16	chevrolet	onix	2025	passeio	0.00	ativo	299110
152	QZ062A2	Volkswagen	Gol	2022	Passeio	480.30	ativo	295796
71	ext2a20	fiat	strada	2025	picape	0.98	ativo	231791
176	QZ086A6	Renault	Master	2024	Van	4778.22	ativo	278608
2	abc2d34	fiat	strada	2021	utilitario	0.70	ativo	204745
13	abd3e45	fiat	argo	2022	passeio	0.00	ativo	283352
142	QZ052A2	Volkswagen	Gol	2023	Passeio	431.70	ativo	277838
97	QZ007A7	Volkswagen	Delivery	2022	Caminhao	2560.66	ativo	282942
137	QZ047A7	Volkswagen	Delivery	2018	Caminhao	6618.24	ativo	253525
18	abd8e90	renault	duster	2020	suv	0.00	ativo	300247
138	QZ048A8	Iveco	Daily	2019	Caminhao	11020.31	em_manutencao	315794
78	ext2h27	fiat	cronos	2023	passeio	0.00	ativo	318286
136	QZ046A6	Renault	Master	2017	Van	4520.29	ativo	201015
169	QZ079A9	Toyota	Hilux	2017	Caminhonete	6979.65	inativo	256957
58	ext0h07	mercedes-benz	sprinter	2018	van	1.67	ativo	166905
183	QZ093A3	Chevrolet	S10	2020	Caminhonete	5428.53	em_manutencao	286692
8	abc8d90	mercedes-benz	sprinter	2021	van	1.80	ativo	289324
131	QZ041A1	Fiat	Strada	2023	Utilitario	4725.72	ativo	280434
87	ext3g36	jeep	compass	2017	suv	0.00	ativo	232389
86	ext3f35	volkswagen	polo	2025	passeio	0.00	ativo	317313
123	QZ033A3	Chevrolet	S10	2015	Caminhonete	7761.01	em_manutencao	197823
119	QZ029A9	Toyota	Hilux	2022	Caminhonete	10683.69	inativo	298843
89	ext3i38	hyundai	creta	2017	suv	0.00	ativo	279122
83	ext3c32	hyundai	hb20	2024	passeio	0.00	ativo	205058
189	QZ099A9	Toyota	Hilux	2015	Caminhonete	4295.44	inativo	253328
34	pop0d03	volkswagen	transporter	2023	van	1.21	ativo	286591
6	abc6d78	fiat	ducato	2019	van	1.50	ativo	260917
172	QZ082A2	Volkswagen	Gol	2020	Passeio	517.43	ativo	231970
177	QZ087A7	Volkswagen	Delivery	2025	Caminhao	6101.36	ativo	249451
148	QZ058A8	Iveco	Daily	2018	Caminhao	11846.14	em_manutencao	298488
132	QZ042A2	Volkswagen	Gol	2024	Passeio	474.35	ativo	201584
93	QZ003A3	Chevrolet	S10	2018	Caminhonete	1128.90	em_manutencao	287560
126	QZ036A6	Renault	Master	2018	Van	5270.27	ativo	275697
178	QZ088A8	Iveco	Daily	2015	Caminhao	6407.71	em_manutencao	192727
53	ext0c02	volvo	vm	2016	caminhao	6.56	ativo	136901
113	QZ023A3	Chevrolet	S10	2016	Caminhonete	10119.91	em_manutencao	262034
165	QZ075A5	Mercedes-Benz	Sprinter	2024	Van	6645.07	ativo	299612
174	QZ084A4	Ford	Ranger	2022	Caminhonete	8542.47	inativo	268268
114	QZ024A4	Ford	Ranger	2017	Caminhonete	10506.83	inativo	260993
23	abe3f45	toyota	sw4	2021	suv	0.00	ativo	269731
140	QZ050A0	Hyundai	HB20	2021	Passeio	431.50	ativo	191053
59	ext0i08	volkswagen	transporter	2020	van	1.44	ativo	244834
129	QZ039A9	Toyota	Hilux	2021	Caminhonete	9993.78	inativo	269161
62	ext1b11	renault	master	2016	van	1.55	ativo	163282
99	QZ009A9	Toyota	Hilux	2024	Caminhonete	5715.22	inativo	287275
36	pop0f05	renault	master	2022	van	1.28	em_manutencao	274167
29	abe9g01	fiat	cron​os	2023	passeio	0.00	ativo	280467
22	abe2f34	ford	maverick	2023	picape	0.70	ativo	266982
110	QZ020A0	Hyundai	HB20	2024	Passeio	500.31	ativo	151366
100	QZ010A0	Hyundai	HB20	2025	Passeio	398.54	ativo	265393
162	QZ072A2	Volkswagen	Gol	2021	Passeio	515.78	ativo	270870
30	abe0g12	chevrolet	tracker	2022	suv	0.00	ativo	294525
70	ext1j19	volkswagen	saveiro	2017	picape	0.93	inativo	308534
112	QZ022A2	Volkswagen	Gol	2015	Passeio	383.19	ativo	297928
124	QZ034A4	Ford	Ranger	2016	Caminhonete	7014.49	inativo	264430
32	pop0b01	mercedes-benz	accelo	2025	caminhao	13.16	ativo	234510
157	QZ067A7	Volkswagen	Delivery	2016	Caminhao	6363.15	ativo	297801
163	QZ073A3	Chevrolet	S10	2022	Caminhonete	11642.36	em_manutencao	256002
69	ext1i18	ford	ranger	2019	picape	0.87	ativo	283115
24	abe4f56	volkswagen	amarok	2022	picape	1.00	ativo	128204
40	pop0j09	fiat	fiorino	2025	utilitario	0.77	inativo	287750
28	abe8f90	volkswagen	polo	2022	passeio	0.00	ativo	198084
4	abc4d56	toyota	hilux	2021	picape	1.00	ativo	315833
180	QZ090A0	Hyundai	HB20	2017	Passeio	382.55	ativo	266679
43	pop1c12	fiat	strada	2025	picape	1.08	ativo	289755
170	QZ080A0	Hyundai	HB20	2018	Passeio	367.84	ativo	228823
84	ext3d33	fiat	cronos	2020	passeio	0.00	ativo	287670
82	ext3b31	honda	civic	2020	passeio	0.00	ativo	292226
175	QZ085A5	Mercedes-Benz	Sprinter	2023	Van	9884.78	ativo	276286
76	ext2f25	fiat	strada	2022	picape	0.99	ativo	284076
55	ext0e04	volkswagen	constellation	2016	caminhao	6.37	ativo	276268
96	QZ006A6	Renault	Master	2021	Van	4237.05	ativo	288212
42	pop1b11	ford	ranger	2020	picape	0.97	ativo	313716
166	QZ076A6	Renault	Master	2025	Van	10734.69	ativo	179250
135	QZ045A5	Mercedes-Benz	Sprinter	2016	Van	2043.07	ativo	288826
91	QZ001A1	Fiat	Strada	2016	Utilitario	1528.56	ativo	284065
10	abc0e12	mercedes-benz	atego	2020	caminhao	8.00	ativo	295031
134	QZ044A4	Ford	Ranger	2015	Caminhonete	3663.20	inativo	233419
66	ext1f15	citroen	berlingo	2021	utilitario	0.80	ativo	232605
38	pop0h07	renault	kangoo	2025	utilitario	0.77	ativo	304753
1	abc1d23	volkswagen	saveiro	2020	utilitario	0.75	ativo	252493
187	QZ097A7	Volkswagen	Delivery	2024	Caminhao	7003.85	ativo	283341
25	abe5f67	mitsubishi	l200	2019	picape	1.00	ativo	278626
133	QZ043A3	Chevrolet	S10	2025	Caminhonete	11604.24	em_manutencao	294138
77	ext2g26	hyundai	hb20	2017	passeio	0.00	ativo	286696
108	QZ018A8	Iveco	Daily	2022	Caminhao	4400.28	em_manutencao	243112
120	QZ030A0	Hyundai	HB20	2023	Passeio	393.14	ativo	238642
20	abd0f12	chevrolet	spin	2022	minivan	0.00	ativo	303291
17	abd7e89	volkswagen	virtus	2023	passeio	0.00	ativo	240048
85	ext3e34	chevrolet	onix	2024	passeio	0.00	ativo	277000
106	QZ016A6	Renault	Master	2020	Van	7260.06	ativo	243175
146	QZ056A6	Renault	Master	2016	Van	5443.35	ativo	265601
104	QZ014A4	Ford	Ranger	2018	Caminhonete	4692.77	inativo	264362
105	QZ015A5	Mercedes-Benz	Sprinter	2019	Van	6077.31	ativo	249051
3	abc3d45	chevrolet	montana	2022	utilitario	0.65	ativo	311967
184	QZ094A4	Ford	Ranger	2021	Caminhonete	9295.20	inativo	311654
127	QZ037A7	Volkswagen	Delivery	2019	Caminhao	6010.83	ativo	286857
147	QZ057A7	Volkswagen	Delivery	2017	Caminhao	8356.01	ativo	227098
46	pop1f15	fiat	cronos	2025	passeio	0.00	ativo	276806
5	abc5d67	ford	ranger	2020	picape	1.00	ativo	276880
171	QZ081A1	Fiat	Strada	2019	Utilitario	3266.75	ativo	247838
64	ext1d13	renault	kangoo	2022	utilitario	0.87	ativo	309221
185	QZ095A5	Mercedes-Benz	Sprinter	2022	Van	3565.70	ativo	306128
26	abe6f78	nissan	frontier	2020	picape	1.00	ativo	268977
67	ext1g16	fiat	fiorino	2021	utilitario	0.95	ativo	257604
65	ext1e14	peugeot	partner	2017	utilitario	0.62	ativo	143677
\.


--
-- TOC entry 3623 (class 0 OID 32877)
-- Dependencies: 234
-- Data for Name: viagens; Type: TABLE DATA; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

COPY gabriel_trabalho_bd.viagens (id_viagem, id_veiculo, id_motorista, data_saida, data_retorno, km_inicial, km_final, destino, finalidade, id_modalidade) FROM stdin;
1	1	1	2026-01-08 07:30:00	2026-01-08 17:20:00	45300	45680	guarapuava	entrega de materiais	\N
2	1	2	2026-02-10 06:50:00	2026-02-10 18:10:00	46800	47250	ponta grossa	entrega de mercadorias	\N
3	1	3	2026-03-12 08:00:00	2026-03-12 16:30:00	48500	48820	prudentopolis	transporte de materiais	\N
4	2	4	2026-01-15 07:00:00	2026-01-15 18:00:00	38300	38750	irati	entrega de produtos	\N
5	2	5	2026-02-18 06:30:00	2026-02-18 19:00:00	39850	40320	curitiba	transporte de mercadorias	\N
6	2	6	2026-03-21 07:40:00	2026-03-21 17:50:00	41500	41900	ponta grossa	entrega de materiais	\N
7	3	7	2026-01-20 08:00:00	2026-01-20 17:00:00	29200	29650	pitanga	servico externo	\N
8	3	8	2026-03-22 07:30:00	2026-03-22 18:20:00	32200	32680	laranjeiras do sul	entrega de equipamentos	\N
9	3	9	2026-05-24 06:40:00	2026-05-24 18:00:00	35500	36050	cascavel	transporte de materiais	\N
10	4	10	2026-01-25 05:30:00	2026-01-25 20:00:00	62600	63350	curitiba	transporte de cargas	\N
11	4	11	2026-03-28 06:00:00	2026-03-28 19:30:00	67200	68020	ponta grossa	entrega de mercadorias	\N
12	4	12	2026-05-30 05:50:00	2026-05-30 21:00:00	71900	72850	sao paulo	transporte de cargas	\N
13	5	13	2026-02-05 05:40:00	2026-02-05 20:30:00	71300	72150	curitiba	transporte de cargas	\N
14	5	14	2026-04-10 06:10:00	2026-04-10 21:20:00	78300	79180	londrina	entrega de mercadorias	\N
15	5	15	2026-06-12 05:30:00	2026-06-12 22:00:00	80700	81650	foz do iguacu	transporte de cargas	\N
16	6	16	2026-01-30 05:00:00	2026-01-30 19:00:00	88500	89350	curitiba	entrega de cargas	\N
17	6	17	2026-03-15 05:30:00	2026-03-15 20:00:00	92200	93100	joinville	transporte de mercadorias	\N
18	6	18	2026-05-18 04:50:00	2026-05-18 21:30:00	96100	97050	florianopolis	entrega de cargas	\N
19	7	19	2026-02-08 06:00:00	2026-02-08 19:30:00	55000	55850	curitiba	transporte de equipamentos	\N
20	7	20	2026-04-12 06:20:00	2026-04-12 18:40:00	60600	61420	ponta grossa	entrega de mercadorias	\N
21	8	1	2026-03-10 05:40:00	2026-03-10 20:00:00	68500	69380	curitiba	transporte de funcionarios	\N
22	8	2	2026-06-15 06:00:00	2026-06-15 20:30:00	76800	77750	londrina	transporte de equipamentos	\N
23	9	3	2026-02-12 04:30:00	2026-02-12 22:00:00	113000	114250	sao paulo	transporte de cargas	\N
24	9	4	2026-04-20 05:00:00	2026-04-20 23:00:00	118000	119400	curitiba	transporte de mercadorias	\N
25	9	5	2026-06-22 04:40:00	2026-06-22 22:30:00	123500	125000	cascavel	transporte de cargas	\N
26	10	6	2026-02-20 04:00:00	2026-02-20 23:00:00	139000	140600	sao paulo	transporte de cargas	\N
27	10	7	2026-04-25 04:30:00	2026-04-25 23:30:00	145000	146750	curitiba	transporte de mercadorias	\N
28	10	8	2026-06-26 04:00:00	2026-06-26 22:00:00	151000	152800	porto alegre	transporte de cargas	\N
29	10	10	2026-10-20 17:00:00	2026-10-21 03:00:00	154570	154720	Campo Mourão	Entrega de mercadorias	\N
30	1	1	2026-10-20 08:00:00	2026-10-20 18:00:00	77880	77985	Curitiba	Transporte de carga	\N
31	2	2	2026-10-20 09:00:00	2026-10-20 19:00:00	79590	79700	Ponta Grossa	Visita técnica	\N
32	3	3	2026-10-20 10:00:00	2026-10-20 20:00:00	81300	81415	Cascavel	Serviço interno	\N
33	4	4	2026-10-20 11:00:00	2026-10-20 21:00:00	83010	83130	Londrina	Entrega de peças	\N
34	5	5	2026-10-20 12:00:00	2026-10-20 22:00:00	84720	84845	Maringá	Entrega de mercadorias	\N
35	6	6	2026-10-20 13:00:00	2026-10-20 23:00:00	98930	99060	Guarapuava	Transporte de carga	\N
36	7	7	2026-10-20 14:00:00	2026-10-21 00:00:00	88140	88275	Pitanga	Visita técnica	\N
37	8	8	2026-10-20 15:00:00	2026-10-21 01:00:00	89850	89990	Irati	Serviço interno	\N
38	9	9	2026-10-20 16:00:00	2026-10-21 02:00:00	126660	126805	Ivaiporã	Entrega de peças	\N
39	11	5	2026-10-29 23:10:51.451432	\N	94500	\N	Guarapuava	Entrega de mercadorias	\N
40	39	24	2026-01-07 07:00:00	2026-01-07 15:25:00	57265	57829	cascavel	entrega de materiais	\N
41	34	28	2026-01-08 08:00:00	2026-01-08 16:40:00	32762	32980	guarapuava	entrega de materiais	\N
42	48	26	2026-01-09 09:00:00	2026-01-09 19:25:00	114037	114403	irati	entrega de produtos	\N
43	50	30	2026-01-10 07:00:00	2026-01-10 16:00:00	90130	90219	londrina	entrega de materiais	\N
44	46	28	2026-01-14 06:15:00	2026-01-14 16:55:00	110380	110758	laranjeiras do sul	transporte de equipe	\N
45	42	29	2026-01-14 08:00:00	2026-01-14 19:00:00	68356	68534	ponta grossa	entrega de produtos	\N
46	37	24	2026-01-14 08:30:00	2026-01-14 19:55:00	116348	116574	curitiba	entrega de mercadorias	\N
47	44	23	2026-01-15 06:45:00	2026-01-15 13:55:00	77048	77485	castro	transporte de equipe	\N
48	35	24	2026-01-17 07:45:00	2026-01-17 17:45:00	103075	103212	laranjeiras do sul	entrega de mercadorias	\N
49	47	27	2026-01-18 07:30:00	2026-01-18 14:55:00	66384	66561	maringa	entrega de produtos	\N
50	49	21	2026-01-20 09:45:00	2026-01-20 21:10:00	64479	64784	irati	coleta de pecas	\N
51	38	26	2026-01-21 07:00:00	2026-01-21 19:00:00	118813	119178	curitiba	coleta de pecas	\N
52	32	26	2026-01-22 06:15:00	2026-01-22 18:55:00	103600	103717	guarapuava	entrega de produtos	\N
53	31	22	2026-01-22 07:15:00	2026-01-22 19:55:00	34530	34731	curitiba	coleta de pecas	\N
54	43	25	2026-01-22 07:30:00	2026-01-22 19:30:00	98933	99338	laranjeiras do sul	transporte de materiais	\N
55	41	30	2026-01-25 08:45:00	2026-01-25 18:10:00	97566	97914	laranjeiras do sul	entrega de materiais	\N
56	36	26	2026-01-27 07:15:00	2026-01-27 17:40:00	42780	42943	campo mourao	coleta de pecas	\N
57	45	26	2026-02-06 08:15:00	2026-02-06 19:25:00	33483	33632	telemaco borba	transporte de materiais	\N
58	33	25	2026-02-06 08:45:00	2026-02-06 15:55:00	114422	114901	castro	transporte de equipe	\N
59	38	24	2026-02-08 06:15:00	2026-02-08 15:15:00	120773	120844	campo mourao	transporte de equipe	\N
60	34	26	2026-02-09 08:15:00	2026-02-09 15:25:00	34938	35261	telemaco borba	entrega de mercadorias	\N
61	47	29	2026-02-10 06:00:00	2026-02-10 16:00:00	67807	68205	curitiba	coleta de pecas	\N
62	39	21	2026-02-12 09:00:00	2026-02-12 19:40:00	59031	59628	ivaipora	coleta de pecas	\N
63	36	30	2026-02-12 09:30:00	2026-02-12 21:55:00	44115	44485	telemaco borba	servico externo	\N
64	50	21	2026-02-15 08:30:00	2026-02-15 18:10:00	91987	92547	guarapuava	servico externo	\N
65	49	29	2026-02-15 09:30:00	2026-02-15 19:40:00	66824	67079	curitiba	transporte de materiais	\N
66	44	30	2026-02-17 09:00:00	2026-02-17 16:25:00	78949	79190	prudentopolis	coleta de pecas	\N
67	48	26	2026-02-18 06:00:00	2026-02-18 13:00:00	115515	115724	guarapuava	servico externo	\N
68	35	27	2026-02-19 07:30:00	2026-02-19 14:40:00	105123	105433	londrina	visita a cliente	\N
69	31	24	2026-02-23 08:30:00	2026-02-23 16:40:00	35951	36403	curitiba	servico externo	\N
70	43	26	2026-02-27 06:45:00	2026-02-27 17:25:00	101463	101977	londrina	visita a cliente	\N
71	50	30	2026-03-08 09:15:00	2026-03-08 19:15:00	93407	93743	londrina	visita a cliente	\N
72	38	25	2026-03-09 09:30:00	2026-03-09 21:40:00	123175	123768	guarapuava	transporte de equipe	\N
73	40	28	2026-03-12 09:00:00	2026-03-12 19:10:00	75090	75293	ponta grossa	coleta de pecas	\N
74	42	22	2026-03-13 06:00:00	2026-03-13 15:10:00	71154	71652	cascavel	entrega de mercadorias	\N
75	36	23	2026-03-13 06:15:00	2026-03-13 18:40:00	45899	46268	prudentopolis	coleta de pecas	\N
76	41	28	2026-03-13 08:15:00	2026-03-13 18:25:00	100310	100397	telemaco borba	coleta de pecas	\N
77	48	24	2026-03-16 06:00:00	2026-03-16 18:00:00	117696	118266	pitanga	entrega de produtos	\N
78	35	22	2026-03-17 06:00:00	2026-03-17 14:40:00	107647	107878	londrina	entrega de materiais	\N
79	44	30	2026-03-17 06:30:00	2026-03-17 15:30:00	81181	81680	telemaco borba	entrega de produtos	\N
80	47	28	2026-03-17 07:30:00	2026-03-17 17:40:00	69723	69848	curitiba	entrega de mercadorias	\N
81	46	21	2026-03-17 09:30:00	2026-03-17 18:30:00	114010	114291	prudentopolis	transporte de equipe	\N
82	34	27	2026-03-19 07:45:00	2026-03-19 15:55:00	36589	36823	pitanga	transporte de materiais	\N
83	49	26	2026-03-21 06:15:00	2026-03-21 18:40:00	68770	69230	maringa	coleta de pecas	\N
84	31	24	2026-03-21 07:45:00	2026-03-21 17:25:00	38178	38716	ponta grossa	visita a cliente	\N
85	45	30	2026-03-24 09:00:00	2026-03-24 16:10:00	34941	35458	ponta grossa	servico externo	\N
86	37	24	2026-03-25 08:30:00	2026-03-25 20:30:00	118768	119030	campo mourao	transporte de equipe	\N
87	33	23	2026-03-26 07:30:00	2026-03-26 14:55:00	115733	116202	prudentopolis	transporte de equipe	\N
88	32	25	2026-03-27 08:30:00	2026-03-27 16:55:00	106594	107062	telemaco borba	entrega de produtos	\N
89	49	23	2026-04-07 07:45:00	2026-04-07 19:45:00	71218	71781	irati	entrega de mercadorias	\N
90	31	22	2026-04-09 06:30:00	2026-04-09 17:10:00	40007	40072	londrina	transporte de materiais	\N
91	46	22	2026-04-11 06:45:00	2026-04-11 16:55:00	115440	115933	londrina	coleta de pecas	\N
92	45	28	2026-04-16 06:45:00	2026-04-16 14:25:00	37395	37853	cascavel	coleta de pecas	\N
93	50	24	2026-04-17 08:00:00	2026-04-17 16:10:00	94529	94866	pitanga	visita a cliente	\N
94	32	23	2026-04-17 09:30:00	2026-04-17 21:40:00	107969	108497	prudentopolis	coleta de pecas	\N
95	37	27	2026-04-18 06:45:00	2026-04-18 16:25:00	120549	120994	maringa	transporte de equipe	\N
96	41	21	2026-04-18 09:45:00	2026-04-18 21:10:00	102281	102688	ponta grossa	coleta de pecas	\N
97	48	30	2026-04-21 06:15:00	2026-04-21 16:55:00	120259	120332	ponta grossa	servico externo	\N
98	38	28	2026-04-21 08:15:00	2026-04-21 17:40:00	124288	124411	londrina	transporte de equipe	\N
99	34	27	2026-04-23 08:15:00	2026-04-23 20:40:00	38322	38852	campo mourao	servico externo	\N
100	43	30	2026-04-24 06:45:00	2026-04-24 17:10:00	104789	105261	pitanga	servico externo	\N
101	33	26	2026-04-24 09:00:00	2026-04-24 18:00:00	118493	119040	laranjeiras do sul	entrega de produtos	\N
102	42	26	2026-04-25 06:00:00	2026-04-25 13:00:00	73235	73361	maringa	transporte de equipe	\N
103	40	22	2026-04-26 07:30:00	2026-04-26 19:10:00	77006	77162	guarapuava	servico externo	\N
104	36	30	2026-04-27 09:45:00	2026-04-27 21:45:00	46955	47470	maringa	visita a cliente	\N
105	40	21	2026-05-07 07:45:00	2026-05-07 19:25:00	79503	79694	maringa	transporte de equipe	\N
106	39	22	2026-05-08 07:00:00	2026-05-08 16:00:00	65225	65695	guarapuava	transporte de materiais	\N
107	32	24	2026-05-10 09:15:00	2026-05-10 16:15:00	109033	109455	curitiba	transporte de equipe	\N
108	48	23	2026-05-11 08:00:00	2026-05-11 19:25:00	122127	122513	pitanga	transporte de materiais	\N
109	42	25	2026-05-15 06:00:00	2026-05-15 15:25:00	75177	75624	cascavel	transporte de equipe	\N
110	50	22	2026-05-15 06:30:00	2026-05-15 16:30:00	96517	96663	pitanga	transporte de equipe	\N
111	41	29	2026-05-15 07:15:00	2026-05-15 14:55:00	103169	103740	prudentopolis	transporte de materiais	\N
112	46	24	2026-05-16 06:45:00	2026-05-16 15:45:00	117571	117744	londrina	servico externo	\N
113	43	27	2026-05-16 08:30:00	2026-05-16 17:40:00	106490	106561	telemaco borba	coleta de pecas	\N
114	35	28	2026-05-17 07:45:00	2026-05-17 19:45:00	111292	111387	curitiba	entrega de mercadorias	\N
115	34	30	2026-05-23 07:15:00	2026-05-23 19:15:00	40406	40559	laranjeiras do sul	entrega de mercadorias	\N
116	37	27	2026-05-24 08:30:00	2026-05-24 18:55:00	122410	122484	laranjeiras do sul	servico externo	\N
117	33	21	2026-05-26 06:45:00	2026-05-26 15:10:00	120575	120969	maringa	transporte de equipe	\N
118	37	26	2026-06-06 06:00:00	2026-06-06 17:25:00	123790	124327	londrina	entrega de materiais	\N
119	39	24	2026-06-06 06:30:00	2026-06-06 13:30:00	67315	67621	campo mourao	entrega de produtos	\N
120	31	23	2026-06-06 07:30:00	2026-06-06 14:40:00	42764	43184	maringa	visita a cliente	\N
121	44	21	2026-06-07 06:45:00	2026-06-07 16:10:00	87027	87550	telemaco borba	transporte de equipe	\N
122	41	30	2026-06-07 09:30:00	2026-06-07 20:40:00	104832	105344	ivaipora	servico externo	\N
123	33	25	2026-06-08 06:30:00	2026-06-08 14:40:00	121694	121765	cascavel	entrega de produtos	\N
124	35	22	2026-06-11 06:00:00	2026-06-11 15:40:00	113700	113969	curitiba	entrega de mercadorias	\N
125	47	29	2026-06-12 08:45:00	2026-06-12 20:55:00	75111	75295	guarapuava	entrega de produtos	\N
126	40	25	2026-06-12 09:45:00	2026-06-12 19:10:00	80837	81026	telemaco borba	transporte de equipe	\N
127	45	25	2026-06-15 07:45:00	2026-06-15 17:45:00	40689	41212	cascavel	servico externo	\N
128	38	29	2026-06-18 09:00:00	2026-06-18 19:00:00	127734	127815	cascavel	transporte de materiais	\N
129	46	22	2026-06-19 08:30:00	2026-06-19 16:10:00	118801	119353	ivaipora	entrega de mercadorias	\N
130	49	29	2026-06-21 06:30:00	2026-06-21 13:40:00	75685	76242	curitiba	entrega de mercadorias	\N
131	43	21	2026-06-21 08:00:00	2026-06-21 16:40:00	108839	109404	prudentopolis	visita a cliente	\N
132	32	26	2026-06-23 06:15:00	2026-06-23 13:40:00	110747	110948	maringa	entrega de materiais	\N
133	42	24	2026-06-27 06:15:00	2026-06-27 18:40:00	76746	76876	curitiba	entrega de materiais	\N
134	39	21	2026-07-06 09:45:00	2026-07-06 17:45:00	68723	68953	castro	servico externo	\N
135	40	22	2026-07-07 06:00:00	2026-07-07 13:40:00	82975	83405	irati	servico externo	\N
136	36	30	2026-07-07 08:15:00	2026-07-07 18:40:00	52938	53343	laranjeiras do sul	transporte de equipe	\N
137	41	22	2026-07-08 09:00:00	2026-07-08 19:00:00	105885	105971	prudentopolis	transporte de materiais	\N
138	37	26	2026-07-09 09:30:00	2026-07-09 18:30:00	125836	126163	irati	entrega de produtos	\N
139	47	26	2026-07-11 07:00:00	2026-07-11 17:40:00	77284	77594	laranjeiras do sul	entrega de produtos	\N
140	50	26	2026-07-14 06:15:00	2026-07-14 15:15:00	99408	99627	curitiba	coleta de pecas	\N
141	43	29	2026-07-15 09:30:00	2026-07-15 19:40:00	110442	110571	castro	visita a cliente	\N
142	44	28	2026-07-16 07:15:00	2026-07-16 16:15:00	89621	89854	laranjeiras do sul	transporte de materiais	\N
143	34	30	2026-07-17 07:45:00	2026-07-17 15:55:00	43599	43776	castro	entrega de materiais	\N
144	32	24	2026-07-18 07:00:00	2026-07-18 18:00:00	112034	112622	prudentopolis	coleta de pecas	\N
145	45	21	2026-07-19 07:45:00	2026-07-19 16:10:00	42887	43243	ivaipora	coleta de pecas	\N
146	35	23	2026-07-23 07:00:00	2026-07-23 17:25:00	116310	116899	irati	coleta de pecas	\N
147	42	30	2026-07-26 06:30:00	2026-07-26 15:40:00	78732	78859	ponta grossa	visita a cliente	\N
148	38	28	2026-07-27 08:30:00	2026-07-27 15:30:00	129758	129941	irati	coleta de pecas	\N
149	37	22	2026-08-07 06:30:00	2026-08-07 19:10:00	128063	128303	ponta grossa	entrega de materiais	\N
150	40	28	2026-08-08 07:15:00	2026-08-08 16:25:00	84868	85054	campo mourao	transporte de equipe	\N
151	39	26	2026-08-09 07:00:00	2026-08-09 14:10:00	70027	70269	castro	servico externo	\N
152	44	27	2026-08-10 06:15:00	2026-08-10 17:25:00	91423	91745	irati	visita a cliente	\N
153	41	21	2026-08-11 06:45:00	2026-08-11 18:55:00	107959	108036	maringa	visita a cliente	\N
154	42	24	2026-08-11 07:45:00	2026-08-11 20:25:00	80784	81079	maringa	transporte de equipe	\N
155	47	30	2026-08-12 06:00:00	2026-08-12 13:10:00	78285	78681	maringa	visita a cliente	\N
156	38	24	2026-08-13 09:00:00	2026-08-13 21:00:00	131934	132212	guarapuava	servico externo	\N
157	36	27	2026-08-17 06:45:00	2026-08-17 17:25:00	54542	54827	maringa	transporte de equipe	\N
158	46	23	2026-08-18 07:15:00	2026-08-18 16:15:00	122231	122689	campo mourao	servico externo	\N
159	45	21	2026-08-18 07:30:00	2026-08-18 17:55:00	45139	45645	ivaipora	servico externo	\N
160	50	28	2026-08-23 06:30:00	2026-08-23 14:30:00	100796	100933	campo mourao	transporte de equipe	\N
161	34	23	2026-08-23 08:00:00	2026-08-23 18:40:00	45316	45670	londrina	servico externo	\N
162	49	29	2026-08-23 08:15:00	2026-08-23 17:25:00	80674	81234	laranjeiras do sul	transporte de equipe	\N
163	31	23	2026-08-24 06:00:00	2026-08-24 15:40:00	46309	46504	prudentopolis	entrega de mercadorias	\N
164	48	24	2026-08-24 06:00:00	2026-08-24 14:00:00	127047	127300	ivaipora	transporte de materiais	\N
165	33	26	2026-08-25 06:45:00	2026-08-25 17:55:00	124896	125272	ponta grossa	entrega de materiais	\N
166	43	24	2026-09-07 06:00:00	2026-09-07 17:40:00	114747	114820	prudentopolis	transporte de materiais	\N
167	39	29	2026-09-07 09:00:00	2026-09-07 19:25:00	71807	72020	laranjeiras do sul	servico externo	\N
168	40	27	2026-09-08 06:45:00	2026-09-08 17:45:00	86355	86790	laranjeiras do sul	entrega de mercadorias	\N
169	42	27	2026-09-09 08:30:00	2026-09-09 17:10:00	82459	82853	curitiba	visita a cliente	\N
170	49	30	2026-09-12 07:15:00	2026-09-12 19:25:00	82804	83389	castro	entrega de produtos	\N
171	44	21	2026-09-12 09:15:00	2026-09-12 16:25:00	93244	93307	laranjeiras do sul	servico externo	\N
172	36	29	2026-09-13 08:00:00	2026-09-13 20:00:00	56643	57089	irati	entrega de produtos	\N
173	33	24	2026-09-14 07:30:00	2026-09-14 17:55:00	127035	127284	pitanga	transporte de equipe	\N
174	45	22	2026-09-14 09:15:00	2026-09-14 19:25:00	46969	47317	campo mourao	entrega de produtos	\N
175	32	25	2026-09-16 06:15:00	2026-09-16 18:25:00	114977	115354	curitiba	visita a cliente	\N
176	48	25	2026-09-19 06:45:00	2026-09-19 18:10:00	128934	129032	campo mourao	entrega de produtos	\N
177	35	22	2026-09-20 06:45:00	2026-09-20 16:45:00	120169	120261	cascavel	transporte de materiais	\N
178	47	23	2026-09-25 07:30:00	2026-09-25 14:40:00	80014	80382	ponta grossa	entrega de produtos	\N
179	46	21	2026-09-26 09:30:00	2026-09-26 18:55:00	123975	124552	maringa	transporte de materiais	\N
180	31	21	2026-09-27 06:30:00	2026-09-27 17:55:00	48227	48476	maringa	entrega de mercadorias	\N
181	37	27	2026-10-09 06:00:00	2026-10-09 13:40:00	132275	132454	guarapuava	transporte de materiais	\N
182	49	21	2026-10-09 06:00:00	2026-10-09 16:10:00	85082	85244	cascavel	servico externo	\N
183	36	28	2026-10-11 07:15:00	2026-10-11 17:40:00	59065	59609	guarapuava	entrega de mercadorias	\N
184	35	24	2026-10-11 08:30:00	2026-10-11 18:40:00	121750	122014	cascavel	entrega de mercadorias	\N
185	34	26	2026-10-14 06:15:00	2026-10-14 14:40:00	50176	50377	cascavel	coleta de pecas	\N
186	31	23	2026-10-15 08:00:00	2026-10-15 15:40:00	49255	49582	telemaco borba	visita a cliente	\N
187	47	28	2026-10-16 06:15:00	2026-10-16 13:40:00	81612	81828	cascavel	coleta de pecas	\N
188	40	25	2026-10-16 09:00:00	2026-10-16 16:10:00	88146	88316	campo mourao	entrega de materiais	\N
189	38	23	2026-10-17 07:30:00	2026-10-17 19:40:00	136481	136676	curitiba	coleta de pecas	\N
190	44	26	2026-10-17 08:15:00	2026-10-17 19:40:00	95261	95658	curitiba	servico externo	\N
191	48	21	2026-10-18 06:15:00	2026-10-18 14:40:00	130831	131293	maringa	coleta de pecas	\N
192	45	25	2026-10-20 09:15:00	2026-10-20 21:15:00	49514	50006	telemaco borba	visita a cliente	\N
193	41	29	2026-10-21 09:15:00	2026-10-21 21:40:00	110307	110419	telemaco borba	visita a cliente	\N
194	46	25	2026-10-23 07:30:00	2026-10-23 15:30:00	125441	125631	campo mourao	visita a cliente	\N
195	32	23	2026-10-23 09:00:00	2026-10-23 17:40:00	116318	116515	castro	transporte de equipe	\N
196	39	23	2026-10-25 07:00:00	2026-10-25 18:10:00	73928	74161	irati	servico externo	\N
197	33	24	2026-10-25 08:00:00	2026-10-25 17:40:00	128539	129099	prudentopolis	entrega de materiais	\N
198	43	21	2026-10-25 09:00:00	2026-10-25 18:25:00	115972	116366	londrina	entrega de materiais	\N
199	50	28	2026-10-25 09:00:00	2026-10-25 18:10:00	105303	105627	laranjeiras do sul	coleta de pecas	\N
200	53	32	2025-01-06 07:30:00	2025-01-06 15:30:00	61574	61952	guarapuava	entrega de materiais	\N
201	61	31	2025-01-06 09:30:00	2025-01-06 17:55:00	85297	85696	guarapuava	servico externo	\N
202	72	40	2025-01-08 07:00:00	2025-01-08 16:40:00	20784	21076	curitiba	visita a cliente	\N
203	55	45	2025-01-09 06:15:00	2025-01-09 13:25:00	84119	84407	prudentopolis	entrega de produtos	\N
204	76	31	2025-01-09 06:45:00	2025-01-09 16:25:00	84995	85513	ponta grossa	vistoria em obra	\N
205	66	32	2025-01-10 07:30:00	2025-01-10 17:10:00	76133	76403	telemaco borba	coleta de pecas	\N
206	87	43	2025-01-10 09:45:00	2025-01-10 17:25:00	117043	117298	ivaipora	entrega de mercadorias	\N
207	81	33	2025-01-11 06:15:00	2025-01-11 18:15:00	65859	66398	maringa	entrega de produtos	\N
208	80	40	2025-01-12 08:30:00	2025-01-12 16:55:00	89663	89754	cascavel	visita a cliente	\N
209	56	45	2025-01-13 07:30:00	2025-01-13 18:40:00	100687	100794	reserva	servico externo	\N
210	63	45	2025-01-16 09:15:00	2025-01-16 16:25:00	119908	120025	castro	vistoria em obra	\N
211	60	42	2025-01-18 06:30:00	2025-01-18 17:55:00	43050	43225	londrina	entrega de mercadorias	\N
212	74	49	2025-01-19 08:15:00	2025-01-19 18:25:00	57739	58039	irati	coleta de pecas	\N
213	67	39	2025-01-19 08:30:00	2025-01-19 15:55:00	97224	97296	curitiba	entrega de produtos	\N
214	78	41	2025-01-21 06:15:00	2025-01-21 16:15:00	10205	10717	apucarana	entrega de mercadorias	\N
215	84	40	2025-01-21 07:15:00	2025-01-21 15:40:00	24197	24688	palmital	vistoria em obra	\N
216	69	44	2025-01-22 06:45:00	2025-01-22 14:45:00	4297	4539	pitanga	servico externo	\N
217	90	34	2025-01-22 06:45:00	2025-01-22 15:25:00	127450	127707	campo mourao	entrega de materiais	\N
218	73	49	2025-01-22 09:00:00	2025-01-22 19:00:00	3204	3679	castro	entrega de produtos	\N
219	77	44	2025-01-24 07:00:00	2025-01-24 17:10:00	138629	138901	pitanga	vistoria em obra	\N
220	57	32	2025-01-25 07:30:00	2025-01-25 16:40:00	115107	115640	palmital	entrega de materiais	\N
221	85	48	2025-01-25 09:15:00	2025-01-25 17:40:00	3607	3683	ponta grossa	transporte de equipe	\N
222	51	31	2025-01-26 07:45:00	2025-01-26 16:45:00	27947	28355	palmital	entrega de mercadorias	\N
223	86	48	2025-01-27 06:30:00	2025-01-27 16:10:00	34613	34674	telemaco borba	vistoria em obra	\N
224	66	47	2025-02-07 06:45:00	2025-02-07 14:55:00	77592	77817	campo mourao	entrega de materiais	\N
225	54	37	2025-02-07 09:00:00	2025-02-07 19:25:00	62951	63464	irati	entrega de materiais	\N
226	59	31	2025-02-09 06:45:00	2025-02-09 18:55:00	121978	122520	cascavel	entrega de mercadorias	\N
227	53	45	2025-02-10 06:00:00	2025-02-10 13:25:00	63158	63574	castro	reuniao com fornecedor	\N
228	84	34	2025-02-10 06:00:00	2025-02-10 15:10:00	25546	25686	cascavel	entrega de mercadorias	\N
229	68	49	2025-02-11 07:00:00	2025-02-11 15:25:00	65416	65759	candoi	reuniao com fornecedor	\N
230	81	37	2025-02-11 07:45:00	2025-02-11 14:55:00	67539	68032	umuarama	servico externo	\N
231	82	41	2025-02-15 07:00:00	2025-02-15 14:10:00	11867	12004	curitiba	entrega de produtos	\N
232	70	33	2025-02-16 06:00:00	2025-02-16 16:00:00	140516	140929	campo mourao	entrega de materiais	\N
233	69	49	2025-02-16 09:00:00	2025-02-16 18:25:00	6131	6583	ivaipora	entrega de materiais	\N
234	78	41	2025-02-16 09:30:00	2025-02-16 21:55:00	12175	12427	maringa	coleta de pecas	\N
235	63	44	2025-02-17 06:45:00	2025-02-17 16:25:00	121165	121409	telemaco borba	visita a cliente	\N
236	86	32	2025-02-18 07:00:00	2025-02-18 14:10:00	35836	35932	campo mourao	transporte de materiais	\N
237	58	33	2025-02-18 09:45:00	2025-02-18 17:45:00	51945	52394	cascavel	vistoria em obra	\N
238	52	41	2025-02-19 07:15:00	2025-02-19 17:55:00	114132	114280	umuarama	entrega de produtos	\N
239	65	36	2025-02-19 07:30:00	2025-02-19 16:10:00	69851	70370	laranjeiras do sul	visita a cliente	\N
240	90	50	2025-02-19 09:00:00	2025-02-19 17:25:00	129460	129812	palmital	coleta de pecas	\N
241	64	36	2025-02-20 06:45:00	2025-02-20 14:55:00	97624	97751	londrina	entrega de mercadorias	\N
242	79	45	2025-02-20 08:15:00	2025-02-20 18:15:00	140366	140851	prudentopolis	coleta de pecas	\N
243	62	45	2025-02-21 08:45:00	2025-02-21 21:10:00	29993	30447	umuarama	entrega de materiais	\N
244	51	42	2025-02-22 06:45:00	2025-02-22 15:45:00	30068	30465	londrina	entrega de produtos	\N
245	87	31	2025-02-23 08:00:00	2025-02-23 16:10:00	118730	119103	turvo	transporte de equipe	\N
246	83	33	2025-02-23 08:15:00	2025-02-23 17:40:00	95633	95744	laranjeiras do sul	transporte de equipe	\N
247	57	41	2025-02-24 06:45:00	2025-02-24 13:45:00	117533	117998	londrina	transporte de materiais	\N
248	73	38	2025-02-25 07:15:00	2025-02-25 16:40:00	5045	5395	irati	entrega de materiais	\N
249	60	41	2025-02-26 09:45:00	2025-02-26 22:25:00	45533	45661	castro	transporte de equipe	\N
250	66	34	2025-03-06 09:45:00	2025-03-06 22:25:00	78983	79479	ivaipora	entrega de mercadorias	\N
251	54	34	2025-03-07 06:45:00	2025-03-07 17:55:00	64240	64611	umuarama	entrega de mercadorias	\N
252	75	40	2025-03-07 08:15:00	2025-03-07 20:15:00	130005	130356	cascavel	entrega de materiais	\N
253	90	42	2025-03-07 09:00:00	2025-03-07 20:10:00	130271	130672	candoi	visita a cliente	\N
254	73	34	2025-03-08 06:45:00	2025-03-08 13:45:00	6650	7195	castro	transporte de equipe	\N
255	80	34	2025-03-09 06:00:00	2025-03-09 17:10:00	93563	94019	cascavel	reuniao com fornecedor	\N
256	64	43	2025-03-09 07:00:00	2025-03-09 15:00:00	99621	100024	ivaipora	entrega de mercadorias	\N
257	62	46	2025-03-09 08:15:00	2025-03-09 15:25:00	31540	31644	prudentopolis	servico externo	\N
258	65	34	2025-03-10 07:15:00	2025-03-10 17:25:00	70943	71372	palmital	reuniao com fornecedor	\N
259	81	44	2025-03-11 08:00:00	2025-03-11 16:40:00	69441	69577	laranjeiras do sul	reuniao com fornecedor	\N
260	78	48	2025-03-11 08:30:00	2025-03-11 19:10:00	13864	14316	palmital	vistoria em obra	\N
261	59	33	2025-03-11 09:45:00	2025-03-11 20:45:00	124325	124400	maringa	vistoria em obra	\N
262	85	37	2025-03-12 08:00:00	2025-03-12 16:00:00	6581	7064	guarapuava	vistoria em obra	\N
263	51	34	2025-03-12 09:00:00	2025-03-12 19:25:00	31973	32285	ponta grossa	vistoria em obra	\N
264	83	35	2025-03-13 07:45:00	2025-03-13 16:55:00	97552	97728	candoi	reuniao com fornecedor	\N
265	70	39	2025-03-13 08:30:00	2025-03-13 16:10:00	142642	142726	cascavel	vistoria em obra	\N
266	74	44	2025-03-14 08:15:00	2025-03-14 20:55:00	61233	61679	pitanga	entrega de materiais	\N
267	82	42	2025-03-15 06:00:00	2025-03-15 13:10:00	13341	13867	laranjeiras do sul	entrega de mercadorias	\N
268	63	34	2025-03-20 07:15:00	2025-03-20 15:25:00	122980	123052	ivaipora	entrega de materiais	\N
269	56	47	2025-03-20 08:30:00	2025-03-20 17:10:00	104437	104578	laranjeiras do sul	vistoria em obra	\N
270	84	47	2025-03-21 07:00:00	2025-03-21 14:25:00	27633	27701	guarapuava	entrega de produtos	\N
271	79	38	2025-03-21 07:15:00	2025-03-21 14:25:00	141599	141856	telemaco borba	transporte de materiais	\N
272	68	35	2025-03-21 09:45:00	2025-03-21 17:45:00	66922	67468	ivaipora	entrega de mercadorias	\N
273	72	44	2025-03-22 09:30:00	2025-03-22 21:30:00	23924	24255	irati	entrega de mercadorias	\N
274	89	47	2025-03-23 08:00:00	2025-03-23 18:40:00	13276	13616	cascavel	vistoria em obra	\N
275	55	33	2025-03-25 08:30:00	2025-03-25 19:30:00	87037	87149	guarapuava	entrega de mercadorias	\N
276	53	32	2025-03-27 07:15:00	2025-03-27 15:15:00	64592	64706	ponta grossa	entrega de materiais	\N
277	68	41	2025-04-06 06:15:00	2025-04-06 14:40:00	68656	68729	maringa	entrega de mercadorias	\N
278	72	39	2025-04-06 06:15:00	2025-04-06 17:25:00	25098	25212	campo mourao	reuniao com fornecedor	\N
279	81	40	2025-04-06 06:45:00	2025-04-06 17:55:00	70936	71444	pitanga	transporte de equipe	\N
280	59	32	2025-04-09 07:15:00	2025-04-09 18:15:00	125878	126049	cascavel	entrega de mercadorias	\N
281	57	42	2025-04-10 09:15:00	2025-04-10 20:40:00	120921	121428	reserva	visita a cliente	\N
282	54	31	2025-04-12 07:00:00	2025-04-12 19:10:00	65714	66094	ponta grossa	coleta de pecas	\N
283	70	37	2025-04-12 07:00:00	2025-04-12 14:00:00	144781	144843	pitanga	visita a cliente	\N
284	55	35	2025-04-12 09:15:00	2025-04-12 21:55:00	88826	89314	irati	transporte de equipe	\N
285	64	49	2025-04-15 09:15:00	2025-04-15 18:25:00	101966	102459	turvo	transporte de equipe	\N
286	74	47	2025-04-16 06:15:00	2025-04-16 13:40:00	62958	63199	palmital	visita a cliente	\N
287	77	35	2025-04-16 07:45:00	2025-04-16 15:25:00	143833	144159	curitiba	entrega de produtos	\N
288	83	49	2025-04-16 09:15:00	2025-04-16 17:40:00	98558	98779	prudentopolis	entrega de produtos	\N
289	67	34	2025-04-17 06:15:00	2025-04-17 16:40:00	103273	103508	prudentopolis	vistoria em obra	\N
290	90	46	2025-04-18 09:30:00	2025-04-18 19:10:00	132605	133023	palmital	reuniao com fornecedor	\N
291	79	39	2025-04-19 07:30:00	2025-04-19 16:10:00	143471	143706	londrina	vistoria em obra	\N
292	87	47	2025-04-20 06:45:00	2025-04-20 16:45:00	122758	123157	turvo	reuniao com fornecedor	\N
293	61	41	2025-04-20 09:45:00	2025-04-20 17:25:00	90441	90557	irati	servico externo	\N
294	71	49	2025-04-20 09:45:00	2025-04-20 17:10:00	110636	110877	irati	servico externo	\N
295	65	34	2025-04-21 07:45:00	2025-04-21 14:45:00	73249	73785	reserva	coleta de pecas	\N
296	56	42	2025-04-21 09:15:00	2025-04-21 21:40:00	106541	106717	umuarama	servico externo	\N
297	76	38	2025-04-22 07:45:00	2025-04-22 15:10:00	89253	89640	irati	coleta de pecas	\N
298	52	47	2025-04-23 08:30:00	2025-04-23 17:55:00	117871	118330	ivaipora	visita a cliente	\N
299	78	40	2025-04-24 06:30:00	2025-04-24 19:10:00	15044	15260	laranjeiras do sul	entrega de produtos	\N
300	66	43	2025-04-24 06:45:00	2025-04-24 19:10:00	81513	81734	telemaco borba	vistoria em obra	\N
301	80	36	2025-04-24 07:00:00	2025-04-24 16:25:00	94754	94842	pitanga	coleta de pecas	\N
302	75	44	2025-04-26 08:15:00	2025-04-26 18:15:00	132019	132156	laranjeiras do sul	entrega de mercadorias	\N
303	88	33	2025-04-26 09:00:00	2025-04-26 16:00:00	130996	131289	irati	servico externo	\N
304	82	42	2025-04-26 09:30:00	2025-04-26 16:40:00	14944	15407	guarapuava	reuniao com fornecedor	\N
305	62	43	2025-04-27 06:30:00	2025-04-27 16:30:00	33566	33779	curitiba	coleta de pecas	\N
306	78	39	2025-05-06 08:00:00	2025-05-06 17:40:00	17283	17665	guarapuava	coleta de pecas	\N
307	62	31	2025-05-07 07:00:00	2025-05-07 19:00:00	35626	36151	campo mourao	transporte de materiais	\N
308	69	33	2025-05-08 06:45:00	2025-05-08 14:25:00	11864	12341	prudentopolis	entrega de mercadorias	\N
309	72	32	2025-05-08 07:30:00	2025-05-08 15:40:00	27130	27487	campo mourao	servico externo	\N
310	54	44	2025-05-09 07:30:00	2025-05-09 18:55:00	67157	67405	maringa	transporte de materiais	\N
311	55	45	2025-05-09 08:00:00	2025-05-09 18:40:00	90230	90313	apucarana	reuniao com fornecedor	\N
312	64	42	2025-05-10 07:30:00	2025-05-10 19:40:00	103945	104266	candoi	entrega de materiais	\N
313	90	32	2025-05-10 07:30:00	2025-05-10 20:10:00	134419	134563	candoi	vistoria em obra	\N
314	71	50	2025-05-11 08:15:00	2025-05-11 16:25:00	112486	112999	pitanga	servico externo	\N
315	65	40	2025-05-12 07:30:00	2025-05-12 16:30:00	74428	74969	turvo	entrega de mercadorias	\N
316	52	34	2025-05-14 07:15:00	2025-05-14 15:25:00	120027	120213	maringa	vistoria em obra	\N
317	76	38	2025-05-15 06:30:00	2025-05-15 16:10:00	90852	91338	pitanga	entrega de materiais	\N
318	84	36	2025-05-15 07:30:00	2025-05-15 14:30:00	31206	31726	pitanga	transporte de equipe	\N
319	79	37	2025-05-16 07:00:00	2025-05-16 19:10:00	146060	146354	ivaipora	servico externo	\N
320	87	32	2025-05-17 07:45:00	2025-05-17 18:25:00	124925	124996	turvo	servico externo	\N
321	85	31	2025-05-19 07:30:00	2025-05-19 18:10:00	9466	9696	reserva	transporte de materiais	\N
322	75	47	2025-05-20 06:00:00	2025-05-20 18:00:00	133390	133509	ivaipora	entrega de produtos	\N
323	63	42	2025-05-20 09:00:00	2025-05-20 19:40:00	124855	125315	guarapuava	vistoria em obra	\N
324	61	33	2025-05-21 09:00:00	2025-05-21 16:10:00	91988	92266	prudentopolis	visita a cliente	\N
325	58	35	2025-05-22 07:00:00	2025-05-22 14:00:00	57809	57992	ponta grossa	coleta de pecas	\N
326	68	36	2025-05-22 07:30:00	2025-05-22 16:40:00	70216	70608	curitiba	servico externo	\N
327	89	33	2025-05-22 08:45:00	2025-05-22 17:45:00	16030	16337	reserva	transporte de equipe	\N
328	86	48	2025-05-23 07:15:00	2025-05-23 19:55:00	41248	41791	turvo	servico externo	\N
329	56	36	2025-05-24 09:15:00	2025-05-24 17:15:00	108331	108517	candoi	entrega de mercadorias	\N
330	60	34	2025-05-25 07:30:00	2025-05-25 15:30:00	50434	50700	candoi	entrega de materiais	\N
331	74	42	2025-06-06 08:45:00	2025-06-06 15:55:00	65448	65852	apucarana	servico externo	\N
332	66	46	2025-06-08 09:00:00	2025-06-08 19:00:00	85604	85933	laranjeiras do sul	entrega de mercadorias	\N
333	78	32	2025-06-10 06:30:00	2025-06-10 13:55:00	18811	19124	laranjeiras do sul	vistoria em obra	\N
334	71	49	2025-06-10 06:45:00	2025-06-10 17:25:00	114641	114743	prudentopolis	transporte de equipe	\N
335	68	45	2025-06-11 07:30:00	2025-06-11 17:40:00	71642	71794	reserva	transporte de equipe	\N
336	52	36	2025-06-12 08:15:00	2025-06-12 19:25:00	120936	121198	irati	servico externo	\N
337	86	45	2025-06-12 09:30:00	2025-06-12 20:40:00	43361	43805	ivaipora	visita a cliente	\N
338	80	38	2025-06-14 08:15:00	2025-06-14 19:15:00	98527	98726	laranjeiras do sul	transporte de equipe	\N
339	55	32	2025-06-14 09:15:00	2025-06-14 20:25:00	92402	92524	cascavel	transporte de materiais	\N
340	65	35	2025-06-15 06:00:00	2025-06-15 17:00:00	76720	77061	castro	entrega de produtos	\N
341	67	42	2025-06-15 06:30:00	2025-06-15 16:55:00	105997	106321	reserva	transporte de materiais	\N
342	87	47	2025-06-15 07:30:00	2025-06-15 17:30:00	126441	126521	maringa	reuniao com fornecedor	\N
343	61	41	2025-06-17 08:00:00	2025-06-17 15:10:00	93578	93760	turvo	entrega de produtos	\N
344	82	47	2025-06-18 09:15:00	2025-06-18 18:55:00	18388	18470	cascavel	reuniao com fornecedor	\N
345	64	44	2025-06-19 08:30:00	2025-06-19 16:10:00	105022	105104	ivaipora	reuniao com fornecedor	\N
346	54	31	2025-06-19 09:00:00	2025-06-19 19:00:00	68701	68771	irati	coleta de pecas	\N
347	60	46	2025-06-20 07:30:00	2025-06-20 15:55:00	51855	52319	guarapuava	vistoria em obra	\N
348	57	31	2025-06-20 07:45:00	2025-06-20 19:25:00	125211	125446	ponta grossa	entrega de materiais	\N
349	81	50	2025-06-20 08:00:00	2025-06-20 20:00:00	74233	74396	ivaipora	entrega de produtos	\N
350	75	34	2025-06-20 08:45:00	2025-06-20 21:25:00	135329	135460	prudentopolis	reuniao com fornecedor	\N
351	89	49	2025-06-21 08:30:00	2025-06-21 15:30:00	18145	18417	guarapuava	entrega de mercadorias	\N
352	79	40	2025-06-22 08:15:00	2025-06-22 15:15:00	147947	148178	candoi	coleta de pecas	\N
353	62	43	2025-06-23 07:15:00	2025-06-23 17:55:00	37659	37805	campo mourao	transporte de equipe	\N
354	58	36	2025-06-23 08:45:00	2025-06-23 19:45:00	59573	59914	turvo	servico externo	\N
355	56	47	2025-06-23 09:00:00	2025-06-23 21:10:00	110451	110887	maringa	entrega de materiais	\N
356	72	36	2025-06-24 07:45:00	2025-06-24 14:45:00	29344	29451	reserva	entrega de materiais	\N
357	77	43	2025-06-25 07:00:00	2025-06-25 16:25:00	147735	148267	laranjeiras do sul	vistoria em obra	\N
358	63	36	2025-06-26 07:00:00	2025-06-26 18:10:00	126505	126826	turvo	transporte de materiais	\N
359	51	44	2025-06-26 07:30:00	2025-06-26 16:55:00	37403	37502	umuarama	vistoria em obra	\N
360	90	43	2025-06-26 08:00:00	2025-06-26 16:40:00	136256	136504	ponta grossa	entrega de mercadorias	\N
361	88	32	2025-06-27 07:15:00	2025-06-27 18:15:00	134032	134404	irati	transporte de materiais	\N
362	85	37	2025-06-27 09:15:00	2025-06-27 17:25:00	10527	10899	umuarama	entrega de materiais	\N
363	60	32	2025-07-06 09:00:00	2025-07-06 21:25:00	53733	53898	reserva	transporte de equipe	\N
364	52	32	2025-07-07 07:45:00	2025-07-07 16:45:00	123031	123334	maringa	entrega de produtos	\N
365	88	40	2025-07-08 07:30:00	2025-07-08 19:55:00	135137	135648	reserva	servico externo	\N
366	72	45	2025-07-09 07:30:00	2025-07-09 19:55:00	31293	31489	reserva	vistoria em obra	\N
367	80	34	2025-07-09 07:45:00	2025-07-09 15:45:00	99760	100250	ivaipora	visita a cliente	\N
368	85	33	2025-07-09 09:30:00	2025-07-09 16:55:00	11835	11988	pitanga	entrega de materiais	\N
369	51	31	2025-07-10 09:30:00	2025-07-10 21:30:00	38816	38907	castro	servico externo	\N
370	78	38	2025-07-11 09:30:00	2025-07-11 17:30:00	20455	20860	umuarama	entrega de mercadorias	\N
371	65	33	2025-07-12 06:30:00	2025-07-12 16:40:00	78106	78295	londrina	entrega de materiais	\N
372	87	36	2025-07-14 06:15:00	2025-07-14 17:40:00	128666	128734	laranjeiras do sul	transporte de materiais	\N
373	69	31	2025-07-14 07:45:00	2025-07-14 15:45:00	16273	16380	campo mourao	vistoria em obra	\N
374	73	35	2025-07-16 06:45:00	2025-07-16 18:25:00	15166	15268	pitanga	vistoria em obra	\N
375	75	44	2025-07-17 06:15:00	2025-07-17 18:55:00	137498	137745	curitiba	reuniao com fornecedor	\N
376	86	43	2025-07-18 06:15:00	2025-07-18 13:40:00	44870	45265	castro	coleta de pecas	\N
377	84	38	2025-07-18 06:30:00	2025-07-18 18:40:00	33932	34350	prudentopolis	coleta de pecas	\N
378	83	50	2025-07-18 06:45:00	2025-07-18 18:55:00	103992	104529	ivaipora	servico externo	\N
379	56	45	2025-07-18 07:15:00	2025-07-18 16:25:00	112335	112750	irati	entrega de mercadorias	\N
380	77	42	2025-07-18 08:30:00	2025-07-18 18:55:00	149910	150266	turvo	visita a cliente	\N
381	66	44	2025-07-21 06:00:00	2025-07-21 18:40:00	87611	87977	maringa	entrega de materiais	\N
382	71	42	2025-07-21 06:00:00	2025-07-21 16:00:00	116546	116933	ivaipora	visita a cliente	\N
383	64	38	2025-07-21 09:30:00	2025-07-21 19:10:00	106784	107121	ponta grossa	visita a cliente	\N
384	89	50	2025-07-22 06:30:00	2025-07-22 17:30:00	19434	19593	pitanga	visita a cliente	\N
385	58	36	2025-07-22 07:45:00	2025-07-22 16:45:00	61503	61757	laranjeiras do sul	reuniao com fornecedor	\N
386	68	38	2025-07-23 06:30:00	2025-07-23 18:10:00	73139	73388	irati	reuniao com fornecedor	\N
387	74	36	2025-07-23 08:45:00	2025-07-23 20:25:00	67206	67519	turvo	transporte de equipe	\N
388	54	45	2025-07-24 06:00:00	2025-07-24 18:40:00	70274	70562	umuarama	vistoria em obra	\N
389	61	43	2025-07-24 06:45:00	2025-07-24 17:45:00	94540	94656	cascavel	reuniao com fornecedor	\N
390	59	36	2025-07-25 07:15:00	2025-07-25 16:40:00	130711	130792	prudentopolis	servico externo	\N
391	53	32	2025-07-26 06:15:00	2025-07-26 13:25:00	70373	70677	maringa	transporte de equipe	\N
392	55	43	2025-07-27 09:15:00	2025-07-27 16:55:00	93662	94104	telemaco borba	vistoria em obra	\N
393	69	47	2025-08-06 07:00:00	2025-08-06 14:10:00	17964	18379	cascavel	entrega de produtos	\N
394	81	42	2025-08-07 07:00:00	2025-08-07 18:10:00	78534	78861	campo mourao	reuniao com fornecedor	\N
395	72	50	2025-08-07 08:30:00	2025-08-07 18:10:00	32947	33205	campo mourao	entrega de mercadorias	\N
396	85	45	2025-08-08 08:15:00	2025-08-08 19:25:00	13616	13833	turvo	transporte de equipe	\N
397	57	33	2025-08-08 09:15:00	2025-08-08 21:55:00	128662	129153	laranjeiras do sul	entrega de produtos	\N
398	62	34	2025-08-09 06:00:00	2025-08-09 15:40:00	41957	42299	turvo	entrega de produtos	\N
399	61	42	2025-08-11 06:00:00	2025-08-11 16:25:00	96312	96480	palmital	servico externo	\N
400	80	37	2025-08-13 08:30:00	2025-08-13 16:55:00	101632	102058	reserva	visita a cliente	\N
401	90	43	2025-08-14 07:45:00	2025-08-14 16:55:00	139090	139613	laranjeiras do sul	transporte de materiais	\N
402	51	45	2025-08-15 09:45:00	2025-08-15 19:45:00	39877	40083	reserva	entrega de produtos	\N
403	53	37	2025-08-16 08:30:00	2025-08-16 17:30:00	72603	72673	ivaipora	transporte de equipe	\N
404	89	42	2025-08-16 09:00:00	2025-08-16 20:25:00	21337	21757	ponta grossa	vistoria em obra	\N
405	71	47	2025-08-17 07:15:00	2025-08-17 14:25:00	118348	118418	ivaipora	servico externo	\N
406	84	48	2025-08-18 07:45:00	2025-08-18 19:25:00	35344	35542	guarapuava	vistoria em obra	\N
407	79	49	2025-08-18 09:00:00	2025-08-18 16:10:00	152056	152424	guarapuava	visita a cliente	\N
408	75	48	2025-08-21 06:15:00	2025-08-21 16:15:00	139331	139561	curitiba	reuniao com fornecedor	\N
409	87	33	2025-08-21 09:15:00	2025-08-21 21:15:00	129647	129864	guarapuava	reuniao com fornecedor	\N
410	64	41	2025-08-21 09:30:00	2025-08-21 21:55:00	108334	108767	palmital	transporte de equipe	\N
411	68	49	2025-08-23 08:00:00	2025-08-23 16:25:00	74293	74643	campo mourao	coleta de pecas	\N
412	56	36	2025-08-23 08:15:00	2025-08-23 15:40:00	114507	114955	prudentopolis	entrega de produtos	\N
413	70	39	2025-08-24 06:00:00	2025-08-24 15:10:00	150799	151302	reserva	vistoria em obra	\N
414	88	35	2025-08-24 08:00:00	2025-08-24 16:00:00	137104	137197	palmital	transporte de materiais	\N
415	55	42	2025-08-25 06:30:00	2025-08-25 16:10:00	95034	95296	cascavel	transporte de equipe	\N
416	66	44	2025-08-25 06:45:00	2025-08-25 15:10:00	89343	89745	apucarana	servico externo	\N
417	86	37	2025-08-25 08:45:00	2025-08-25 20:25:00	47007	47266	prudentopolis	coleta de pecas	\N
418	82	50	2025-08-26 08:00:00	2025-08-26 20:10:00	20775	21218	londrina	transporte de materiais	\N
419	60	33	2025-08-26 08:30:00	2025-08-26 17:30:00	55396	55779	ponta grossa	transporte de materiais	\N
420	76	49	2025-08-27 09:45:00	2025-08-27 16:45:00	96518	97013	reserva	entrega de mercadorias	\N
421	77	37	2025-09-06 06:30:00	2025-09-06 18:30:00	153572	153990	prudentopolis	vistoria em obra	\N
422	81	31	2025-09-06 07:15:00	2025-09-06 16:25:00	80259	80538	irati	vistoria em obra	\N
423	68	48	2025-09-06 07:45:00	2025-09-06 17:10:00	75340	75451	ponta grossa	transporte de materiais	\N
424	70	36	2025-09-06 09:00:00	2025-09-06 16:00:00	152758	153132	cascavel	transporte de materiais	\N
425	64	42	2025-09-08 07:45:00	2025-09-08 20:10:00	110577	111059	ivaipora	entrega de materiais	\N
426	88	34	2025-09-10 09:30:00	2025-09-10 22:10:00	138799	139313	apucarana	servico externo	\N
427	69	41	2025-09-11 06:30:00	2025-09-11 16:40:00	20259	20519	candoi	servico externo	\N
428	72	49	2025-09-11 06:30:00	2025-09-11 17:55:00	34019	34514	ivaipora	entrega de mercadorias	\N
429	62	43	2025-09-11 09:45:00	2025-09-11 21:55:00	43661	44109	curitiba	entrega de produtos	\N
430	73	36	2025-09-14 09:45:00	2025-09-14 19:45:00	17807	18252	cascavel	entrega de mercadorias	\N
431	80	50	2025-09-15 07:45:00	2025-09-15 15:55:00	103742	103934	candoi	coleta de pecas	\N
432	78	34	2025-09-16 06:15:00	2025-09-16 16:25:00	23116	23254	turvo	entrega de produtos	\N
433	60	37	2025-09-17 09:00:00	2025-09-17 18:00:00	56803	57274	curitiba	transporte de equipe	\N
434	89	35	2025-09-17 09:30:00	2025-09-17 18:10:00	22371	22715	irati	transporte de equipe	\N
435	63	33	2025-09-18 06:30:00	2025-09-18 16:40:00	131465	131781	apucarana	coleta de pecas	\N
436	66	34	2025-09-18 06:30:00	2025-09-18 15:40:00	90603	90984	apucarana	coleta de pecas	\N
437	67	46	2025-09-21 07:15:00	2025-09-21 16:15:00	111741	112268	cascavel	entrega de produtos	\N
438	82	33	2025-09-22 06:00:00	2025-09-22 17:10:00	22586	22653	curitiba	coleta de pecas	\N
439	79	44	2025-09-22 08:00:00	2025-09-22 16:10:00	154056	154297	castro	transporte de materiais	\N
440	74	37	2025-09-24 09:00:00	2025-09-24 21:00:00	70516	70924	laranjeiras do sul	transporte de equipe	\N
441	59	33	2025-09-24 09:45:00	2025-09-24 16:45:00	134445	134667	cascavel	transporte de materiais	\N
442	57	42	2025-09-25 08:15:00	2025-09-25 17:25:00	129887	130131	apucarana	vistoria em obra	\N
443	75	37	2025-09-26 09:15:00	2025-09-26 20:55:00	141505	141955	laranjeiras do sul	vistoria em obra	\N
444	54	33	2025-09-27 09:00:00	2025-09-27 16:40:00	72855	73309	castro	transporte de materiais	\N
445	57	34	2025-10-07 08:45:00	2025-10-07 18:25:00	131024	131503	laranjeiras do sul	transporte de equipe	\N
446	52	31	2025-10-09 07:00:00	2025-10-09 16:10:00	127702	128069	palmital	vistoria em obra	\N
447	83	40	2025-10-10 07:30:00	2025-10-10 15:55:00	108526	108780	apucarana	transporte de equipe	\N
448	61	32	2025-10-10 08:00:00	2025-10-10 16:25:00	100000	100383	ivaipora	entrega de mercadorias	\N
449	71	44	2025-10-11 07:15:00	2025-10-11 16:40:00	121070	121568	umuarama	visita a cliente	\N
450	69	40	2025-10-12 07:30:00	2025-10-12 17:40:00	21365	21428	palmital	entrega de produtos	\N
451	67	32	2025-10-13 07:15:00	2025-10-13 18:55:00	112970	113388	ivaipora	servico externo	\N
452	58	43	2025-10-14 07:30:00	2025-10-14 17:10:00	66171	66267	ivaipora	reuniao com fornecedor	\N
453	65	45	2025-10-15 07:45:00	2025-10-15 14:55:00	82740	82990	guarapuava	entrega de mercadorias	\N
454	56	33	2025-10-15 08:45:00	2025-10-15 18:55:00	117153	117357	londrina	transporte de materiais	\N
455	85	41	2025-10-16 08:45:00	2025-10-16 15:55:00	16166	16524	ivaipora	transporte de equipe	\N
456	76	41	2025-10-17 09:15:00	2025-10-17 21:15:00	101422	101877	palmital	entrega de materiais	\N
457	74	50	2025-10-19 08:00:00	2025-10-19 19:10:00	72842	72919	ivaipora	coleta de pecas	\N
458	55	47	2025-10-19 08:45:00	2025-10-19 19:45:00	98763	99234	campo mourao	reuniao com fornecedor	\N
459	80	42	2025-10-20 06:00:00	2025-10-20 18:00:00	104612	104952	castro	entrega de mercadorias	\N
460	79	38	2025-10-20 08:00:00	2025-10-20 17:00:00	156635	156728	prudentopolis	transporte de materiais	\N
461	90	37	2025-10-21 06:00:00	2025-10-21 16:00:00	142477	142624	castro	transporte de equipe	\N
462	88	45	2025-10-21 06:15:00	2025-10-21 16:40:00	141046	141521	londrina	visita a cliente	\N
463	62	32	2025-10-21 07:00:00	2025-10-21 16:40:00	45057	45290	curitiba	vistoria em obra	\N
464	60	41	2025-10-21 08:30:00	2025-10-21 18:40:00	58139	58665	irati	reuniao com fornecedor	\N
465	77	41	2025-10-22 06:00:00	2025-10-22 13:25:00	156025	156112	londrina	reuniao com fornecedor	\N
466	59	44	2025-10-22 08:15:00	2025-10-22 16:25:00	136199	136336	cascavel	transporte de equipe	\N
467	81	37	2025-10-23 07:15:00	2025-10-23 18:15:00	82092	82250	irati	transporte de materiais	\N
468	73	39	2025-10-24 09:30:00	2025-10-24 21:10:00	19413	19947	apucarana	servico externo	\N
469	53	42	2025-10-25 08:00:00	2025-10-25 18:00:00	76810	77305	telemaco borba	reuniao com fornecedor	\N
470	84	31	2025-10-25 08:45:00	2025-10-25 21:25:00	39321	39711	ponta grossa	transporte de materiais	\N
471	75	38	2025-10-27 06:45:00	2025-10-27 18:25:00	143956	144215	guarapuava	entrega de mercadorias	\N
472	83	47	2025-11-06 08:45:00	2025-11-06 20:45:00	110333	110836	ponta grossa	reuniao com fornecedor	\N
473	56	36	2025-11-06 09:00:00	2025-11-06 21:40:00	118624	119143	cascavel	coleta de pecas	\N
474	74	45	2025-11-07 06:15:00	2025-11-07 17:25:00	74438	74814	castro	vistoria em obra	\N
475	59	31	2025-11-08 09:30:00	2025-11-08 16:30:00	137503	137582	castro	entrega de materiais	\N
476	53	36	2025-11-09 06:15:00	2025-11-09 18:15:00	77983	78403	apucarana	visita a cliente	\N
477	61	45	2025-11-09 08:15:00	2025-11-09 19:15:00	102310	102616	candoi	entrega de materiais	\N
478	81	34	2025-11-09 08:45:00	2025-11-09 18:55:00	83306	83551	telemaco borba	transporte de materiais	\N
479	72	46	2025-11-09 09:30:00	2025-11-09 19:40:00	37184	37537	reserva	vistoria em obra	\N
480	89	47	2025-11-10 08:30:00	2025-11-10 17:55:00	26218	26603	maringa	reuniao com fornecedor	\N
481	88	37	2025-11-11 06:45:00	2025-11-11 16:55:00	142369	142832	londrina	transporte de materiais	\N
482	52	46	2025-11-14 08:15:00	2025-11-14 15:40:00	129457	129571	campo mourao	transporte de materiais	\N
483	68	34	2025-11-14 08:15:00	2025-11-14 18:55:00	80143	80380	ponta grossa	transporte de equipe	\N
484	64	48	2025-11-14 08:45:00	2025-11-14 16:25:00	113160	113394	umuarama	reuniao com fornecedor	\N
485	51	32	2025-11-15 08:45:00	2025-11-15 16:25:00	44424	44492	londrina	coleta de pecas	\N
486	62	36	2025-11-16 08:15:00	2025-11-16 20:55:00	46417	46850	ponta grossa	entrega de materiais	\N
487	65	34	2025-11-16 09:00:00	2025-11-16 17:10:00	85238	85654	ivaipora	entrega de materiais	\N
488	57	31	2025-11-16 09:30:00	2025-11-16 17:30:00	133254	133610	cascavel	servico externo	\N
489	69	43	2025-11-16 09:45:00	2025-11-16 16:45:00	23394	23571	irati	entrega de mercadorias	\N
490	67	32	2025-11-17 07:45:00	2025-11-17 19:25:00	115353	115753	castro	entrega de materiais	\N
491	76	44	2025-11-18 09:45:00	2025-11-18 18:55:00	103163	103290	guarapuava	transporte de materiais	\N
492	78	50	2025-11-19 09:15:00	2025-11-19 19:25:00	26966	27359	maringa	transporte de materiais	\N
493	73	38	2025-11-21 08:15:00	2025-11-21 15:55:00	21596	21944	campo mourao	visita a cliente	\N
494	58	41	2025-11-24 07:00:00	2025-11-24 18:25:00	67657	67830	candoi	entrega de produtos	\N
495	60	35	2025-11-24 07:30:00	2025-11-24 16:30:00	60099	60358	castro	visita a cliente	\N
496	71	41	2025-11-25 09:15:00	2025-11-25 21:55:00	122459	122589	londrina	entrega de produtos	\N
497	75	45	2025-11-25 09:45:00	2025-11-25 17:25:00	145801	146067	prudentopolis	coleta de pecas	\N
498	54	31	2025-11-26 06:00:00	2025-11-26 13:10:00	76385	76447	irati	transporte de materiais	\N
499	70	32	2025-11-26 06:30:00	2025-11-26 16:10:00	156979	157418	reserva	coleta de pecas	\N
500	86	49	2025-11-26 07:45:00	2025-11-26 19:45:00	51235	51744	apucarana	transporte de equipe	\N
501	84	39	2025-12-06 07:45:00	2025-12-06 17:10:00	43561	43918	campo mourao	transporte de equipe	\N
502	70	49	2025-12-07 09:00:00	2025-12-07 18:40:00	158481	158576	palmital	vistoria em obra	\N
503	87	38	2025-12-07 09:00:00	2025-12-07 16:40:00	136329	136481	reserva	transporte de materiais	\N
504	77	38	2025-12-08 06:30:00	2025-12-08 16:30:00	159601	159904	guarapuava	entrega de materiais	\N
505	71	39	2025-12-09 08:30:00	2025-12-09 15:30:00	124256	124610	castro	transporte de materiais	\N
506	55	44	2025-12-10 09:00:00	2025-12-10 18:00:00	101516	101703	candoi	transporte de materiais	\N
507	76	50	2025-12-11 08:00:00	2025-12-11 19:00:00	104478	104806	campo mourao	transporte de materiais	\N
508	86	33	2025-12-11 09:00:00	2025-12-11 17:40:00	53382	53652	prudentopolis	transporte de equipe	\N
509	83	45	2025-12-12 08:45:00	2025-12-12 15:55:00	112365	112675	campo mourao	reuniao com fornecedor	\N
510	69	48	2025-12-15 06:00:00	2025-12-15 18:00:00	25294	25602	castro	entrega de materiais	\N
511	68	41	2025-12-15 08:00:00	2025-12-15 17:40:00	82596	82707	ivaipora	reuniao com fornecedor	\N
512	78	38	2025-12-15 09:45:00	2025-12-15 19:25:00	28469	28839	laranjeiras do sul	vistoria em obra	\N
513	67	32	2025-12-16 08:00:00	2025-12-16 18:10:00	117458	117658	candoi	reuniao com fornecedor	\N
514	65	43	2025-12-16 09:15:00	2025-12-16 18:55:00	87389	87782	prudentopolis	vistoria em obra	\N
515	56	44	2025-12-17 08:00:00	2025-12-17 17:10:00	120178	120331	ponta grossa	coleta de pecas	\N
516	59	46	2025-12-17 08:15:00	2025-12-17 18:55:00	138631	138738	curitiba	visita a cliente	\N
517	73	48	2025-12-19 08:45:00	2025-12-19 19:55:00	23723	24229	candoi	vistoria em obra	\N
518	88	40	2025-12-19 08:45:00	2025-12-19 18:55:00	143982	144306	ivaipora	transporte de materiais	\N
519	54	31	2025-12-21 07:45:00	2025-12-21 19:55:00	77708	78136	ponta grossa	transporte de equipe	\N
520	74	45	2025-12-21 09:45:00	2025-12-21 20:25:00	75524	75770	cascavel	transporte de materiais	\N
521	58	33	2025-12-22 07:15:00	2025-12-22 19:55:00	69116	69298	pitanga	entrega de materiais	\N
522	90	46	2025-12-23 06:00:00	2025-12-23 13:10:00	146449	146942	guarapuava	vistoria em obra	\N
523	80	45	2025-12-23 07:45:00	2025-12-23 19:25:00	108385	108578	palmital	entrega de materiais	\N
524	82	48	2025-12-23 08:15:00	2025-12-23 19:40:00	28559	29010	guarapuava	coleta de pecas	\N
525	66	31	2025-12-24 07:45:00	2025-12-24 16:45:00	95933	96228	maringa	entrega de materiais	\N
526	81	39	2025-12-24 09:30:00	2025-12-24 17:30:00	85635	86134	laranjeiras do sul	visita a cliente	\N
527	57	31	2025-12-25 07:30:00	2025-12-25 17:55:00	134691	135123	prudentopolis	reuniao com fornecedor	\N
528	63	37	2025-12-27 07:30:00	2025-12-27 17:40:00	135897	136202	londrina	entrega de produtos	\N
529	64	40	2025-12-27 08:45:00	2025-12-27 15:55:00	115567	115801	turvo	entrega de mercadorias	\N
530	52	34	2026-01-07 07:00:00	2026-01-07 16:40:00	132864	132943	ivaipora	transporte de materiais	\N
531	56	43	2026-01-07 07:30:00	2026-01-07 16:10:00	121663	121943	ponta grossa	reuniao com fornecedor	\N
532	80	50	2026-01-09 06:15:00	2026-01-09 16:40:00	109729	109928	guarapuava	coleta de pecas	\N
533	66	41	2026-01-10 07:00:00	2026-01-10 19:10:00	97357	97808	londrina	entrega de produtos	\N
534	54	45	2026-01-10 09:45:00	2026-01-10 22:10:00	79396	79606	ponta grossa	entrega de materiais	\N
535	53	37	2026-01-11 07:30:00	2026-01-11 14:30:00	81341	81669	ivaipora	servico externo	\N
536	62	43	2026-01-13 08:00:00	2026-01-13 15:25:00	50148	50213	cascavel	transporte de equipe	\N
537	74	32	2026-01-13 08:30:00	2026-01-13 19:40:00	76943	77318	ivaipora	servico externo	\N
538	83	44	2026-01-14 07:00:00	2026-01-14 14:25:00	113755	114138	ponta grossa	entrega de produtos	\N
539	59	31	2026-01-15 07:45:00	2026-01-15 18:10:00	140571	141057	apucarana	reuniao com fornecedor	\N
540	87	42	2026-01-16 06:15:00	2026-01-16 17:55:00	138258	138329	laranjeiras do sul	visita a cliente	\N
541	73	37	2026-01-17 09:30:00	2026-01-17 21:30:00	25321	25552	reserva	entrega de produtos	\N
542	70	50	2026-01-18 06:30:00	2026-01-18 18:10:00	160566	160718	guarapuava	transporte de materiais	\N
543	78	44	2026-01-18 09:15:00	2026-01-18 17:25:00	30512	30806	palmital	servico externo	\N
544	90	49	2026-01-18 09:30:00	2026-01-18 17:10:00	148387	148768	telemaco borba	entrega de mercadorias	\N
545	86	45	2026-01-20 08:15:00	2026-01-20 18:55:00	55311	55822	irati	visita a cliente	\N
546	88	33	2026-01-20 09:30:00	2026-01-20 21:30:00	145775	145991	campo mourao	vistoria em obra	\N
547	89	48	2026-01-21 08:15:00	2026-01-21 20:55:00	29895	30120	londrina	entrega de materiais	\N
548	79	41	2026-01-21 09:30:00	2026-01-21 16:30:00	161991	162434	ponta grossa	servico externo	\N
549	60	37	2026-01-22 09:15:00	2026-01-22 17:15:00	62836	62978	irati	entrega de produtos	\N
550	76	43	2026-01-23 06:15:00	2026-01-23 16:55:00	106480	106898	irati	servico externo	\N
551	85	44	2026-01-23 07:00:00	2026-01-23 15:10:00	20509	20600	ivaipora	reuniao com fornecedor	\N
552	68	49	2026-01-23 08:15:00	2026-01-23 15:40:00	84713	85003	prudentopolis	entrega de produtos	\N
553	77	45	2026-01-25 08:30:00	2026-01-25 16:30:00	161474	162001	londrina	transporte de materiais	\N
554	84	36	2026-01-26 06:15:00	2026-01-26 13:55:00	44812	45083	ivaipora	vistoria em obra	\N
555	61	41	2026-01-26 07:45:00	2026-01-26 19:55:00	105487	105822	ivaipora	transporte de materiais	\N
556	82	50	2026-01-26 09:45:00	2026-01-26 20:45:00	30105	30212	turvo	servico externo	\N
557	63	46	2026-01-27 08:30:00	2026-01-27 20:55:00	137135	137491	umuarama	transporte de equipe	\N
558	54	31	2026-02-06 06:45:00	2026-02-06 16:10:00	80669	81181	umuarama	transporte de materiais	\N
559	82	37	2026-02-06 09:00:00	2026-02-06 21:40:00	32448	32633	londrina	entrega de mercadorias	\N
560	70	47	2026-02-06 09:45:00	2026-02-06 21:45:00	161761	161981	maringa	entrega de mercadorias	\N
561	55	36	2026-02-08 06:15:00	2026-02-08 14:55:00	105701	105863	laranjeiras do sul	servico externo	\N
562	76	35	2026-02-09 07:15:00	2026-02-09 16:15:00	108255	108485	apucarana	servico externo	\N
563	53	41	2026-02-09 08:30:00	2026-02-09 19:40:00	83746	84059	maringa	entrega de produtos	\N
564	73	49	2026-02-10 06:00:00	2026-02-10 14:40:00	27517	27917	curitiba	coleta de pecas	\N
565	67	34	2026-02-11 07:45:00	2026-02-11 16:10:00	121160	121538	castro	vistoria em obra	\N
566	63	43	2026-02-11 08:00:00	2026-02-11 18:00:00	139358	139668	curitiba	coleta de pecas	\N
567	89	36	2026-02-11 08:15:00	2026-02-11 16:25:00	30895	31299	pitanga	transporte de equipe	\N
568	86	46	2026-02-11 08:30:00	2026-02-11 20:40:00	57430	57597	prudentopolis	coleta de pecas	\N
569	84	40	2026-02-11 09:30:00	2026-02-11 20:10:00	45669	45742	umuarama	servico externo	\N
570	62	36	2026-02-14 08:45:00	2026-02-14 19:10:00	51372	51623	irati	entrega de produtos	\N
571	85	36	2026-02-16 06:00:00	2026-02-16 13:10:00	22391	22819	londrina	entrega de produtos	\N
572	75	35	2026-02-16 08:30:00	2026-02-16 19:40:00	150646	150838	campo mourao	vistoria em obra	\N
573	87	40	2026-02-16 08:45:00	2026-02-16 20:10:00	139878	140203	laranjeiras do sul	vistoria em obra	\N
574	58	37	2026-02-16 09:00:00	2026-02-16 19:10:00	72760	73246	londrina	coleta de pecas	\N
575	64	37	2026-02-17 09:00:00	2026-02-17 21:10:00	119154	119672	campo mourao	coleta de pecas	\N
576	61	46	2026-02-18 06:30:00	2026-02-18 18:40:00	107131	107570	cascavel	entrega de materiais	\N
577	65	45	2026-02-22 09:30:00	2026-02-22 18:10:00	91127	91486	telemaco borba	entrega de produtos	\N
578	83	49	2026-02-23 07:30:00	2026-02-23 17:55:00	115948	116279	telemaco borba	visita a cliente	\N
579	71	41	2026-02-23 07:45:00	2026-02-23 18:55:00	126892	126992	laranjeiras do sul	transporte de materiais	\N
580	52	35	2026-02-25 06:45:00	2026-02-25 18:25:00	134382	134546	prudentopolis	coleta de pecas	\N
581	77	37	2026-02-25 08:45:00	2026-02-25 18:25:00	162894	163189	londrina	transporte de materiais	\N
582	80	43	2026-02-26 07:00:00	2026-02-26 19:40:00	111797	111904	candoi	coleta de pecas	\N
583	59	44	2026-02-26 08:15:00	2026-02-26 16:25:00	142169	142263	apucarana	servico externo	\N
584	72	45	2026-02-27 08:15:00	2026-02-27 20:15:00	43240	43444	reserva	entrega de materiais	\N
585	62	44	2026-03-06 07:00:00	2026-03-06 19:10:00	52988	53435	curitiba	visita a cliente	\N
586	75	49	2026-03-07 09:15:00	2026-03-07 19:15:00	152937	153356	umuarama	entrega de materiais	\N
587	58	36	2026-03-09 08:45:00	2026-03-09 20:45:00	73804	74203	londrina	coleta de pecas	\N
588	88	35	2026-03-10 08:30:00	2026-03-10 20:30:00	148075	148137	campo mourao	entrega de mercadorias	\N
589	69	50	2026-03-10 09:45:00	2026-03-10 18:10:00	29949	30125	ivaipora	transporte de materiais	\N
590	85	33	2026-03-11 08:45:00	2026-03-11 15:55:00	23910	24083	laranjeiras do sul	vistoria em obra	\N
591	51	34	2026-03-12 06:15:00	2026-03-12 18:40:00	50869	51226	ivaipora	transporte de materiais	\N
592	83	33	2026-03-12 09:15:00	2026-03-12 16:15:00	118173	118531	pitanga	reuniao com fornecedor	\N
593	78	47	2026-03-13 06:15:00	2026-03-13 17:40:00	33897	34200	londrina	entrega de mercadorias	\N
594	76	37	2026-03-13 07:00:00	2026-03-13 15:10:00	110497	110613	ponta grossa	entrega de mercadorias	\N
595	72	35	2026-03-13 08:30:00	2026-03-13 18:10:00	44449	44517	prudentopolis	entrega de produtos	\N
596	70	35	2026-03-14 07:45:00	2026-03-14 17:55:00	163139	163213	ivaipora	transporte de equipe	\N
597	82	39	2026-03-15 06:15:00	2026-03-15 17:55:00	33870	34398	ponta grossa	transporte de equipe	\N
598	56	44	2026-03-15 07:45:00	2026-03-15 20:10:00	125107	125456	telemaco borba	vistoria em obra	\N
599	81	33	2026-03-15 09:15:00	2026-03-15 21:25:00	91291	91351	reserva	vistoria em obra	\N
600	67	46	2026-03-16 09:30:00	2026-03-16 19:40:00	122451	122988	ivaipora	entrega de materiais	\N
601	77	39	2026-03-17 07:00:00	2026-03-17 18:40:00	163968	164161	maringa	transporte de equipe	\N
602	73	32	2026-03-17 07:15:00	2026-03-17 19:40:00	29633	29809	guarapuava	reuniao com fornecedor	\N
603	66	38	2026-03-18 08:15:00	2026-03-18 15:25:00	101503	101873	palmital	reuniao com fornecedor	\N
604	64	40	2026-03-20 08:15:00	2026-03-20 20:25:00	120611	120750	pitanga	transporte de equipe	\N
605	87	47	2026-03-21 06:00:00	2026-03-21 14:40:00	140881	141119	candoi	coleta de pecas	\N
606	90	38	2026-03-21 08:30:00	2026-03-21 20:40:00	150959	151254	telemaco borba	entrega de materiais	\N
607	54	43	2026-03-21 08:45:00	2026-03-21 18:55:00	81995	82216	curitiba	entrega de mercadorias	\N
608	71	40	2026-03-22 06:15:00	2026-03-22 14:25:00	128742	129212	ponta grossa	reuniao com fornecedor	\N
609	86	38	2026-03-22 07:00:00	2026-03-22 14:25:00	59757	60300	campo mourao	transporte de equipe	\N
610	89	49	2026-03-23 09:15:00	2026-03-23 19:55:00	32710	33197	maringa	coleta de pecas	\N
611	60	42	2026-03-24 06:00:00	2026-03-24 16:00:00	66802	66876	castro	vistoria em obra	\N
612	74	34	2026-03-24 06:30:00	2026-03-24 13:30:00	79705	79882	cascavel	coleta de pecas	\N
613	55	31	2026-03-26 08:30:00	2026-03-26 20:30:00	107210	107287	umuarama	entrega de mercadorias	\N
614	84	45	2026-03-27 07:45:00	2026-03-27 14:55:00	47115	47343	cascavel	coleta de pecas	\N
615	65	32	2026-03-27 09:15:00	2026-03-27 20:15:00	92791	92961	prudentopolis	transporte de equipe	\N
616	88	38	2026-04-06 08:30:00	2026-04-06 16:10:00	149370	149797	guarapuava	vistoria em obra	\N
617	77	48	2026-04-06 09:30:00	2026-04-06 16:55:00	165693	166059	apucarana	servico externo	\N
618	87	49	2026-04-07 09:15:00	2026-04-07 16:25:00	142577	142831	londrina	coleta de pecas	\N
619	71	48	2026-04-08 06:45:00	2026-04-08 16:25:00	131119	131362	reserva	entrega de materiais	\N
620	63	43	2026-04-08 08:45:00	2026-04-08 20:45:00	143423	143947	prudentopolis	vistoria em obra	\N
621	52	46	2026-04-09 07:00:00	2026-04-09 19:10:00	138404	138803	laranjeiras do sul	visita a cliente	\N
622	85	42	2026-04-12 08:15:00	2026-04-12 19:55:00	26199	26608	reserva	entrega de mercadorias	\N
623	72	47	2026-04-12 08:45:00	2026-04-12 19:55:00	46146	46513	irati	reuniao com fornecedor	\N
624	53	41	2026-04-13 06:45:00	2026-04-13 18:45:00	87461	87577	campo mourao	transporte de equipe	\N
625	86	32	2026-04-13 09:15:00	2026-04-13 20:25:00	61881	62233	reserva	entrega de produtos	\N
626	57	36	2026-04-14 07:00:00	2026-04-14 18:00:00	142024	142377	castro	coleta de pecas	\N
627	79	48	2026-04-14 07:15:00	2026-04-14 14:55:00	166741	167193	curitiba	entrega de produtos	\N
628	70	35	2026-04-14 08:15:00	2026-04-14 17:15:00	165058	165579	apucarana	vistoria em obra	\N
629	82	48	2026-04-15 08:00:00	2026-04-15 19:40:00	36088	36365	umuarama	entrega de produtos	\N
630	83	35	2026-04-15 08:45:00	2026-04-15 16:55:00	119418	119609	laranjeiras do sul	vistoria em obra	\N
631	58	41	2026-04-15 09:15:00	2026-04-15 20:25:00	75016	75306	guarapuava	transporte de materiais	\N
632	54	44	2026-04-17 09:45:00	2026-04-17 20:25:00	83666	84048	londrina	vistoria em obra	\N
633	65	31	2026-04-19 09:15:00	2026-04-19 17:55:00	93712	93904	curitiba	visita a cliente	\N
634	74	43	2026-04-21 07:30:00	2026-04-21 17:55:00	82151	82439	ivaipora	transporte de equipe	\N
635	59	34	2026-04-23 06:45:00	2026-04-23 19:25:00	146243	146597	campo mourao	coleta de pecas	\N
636	89	43	2026-04-23 08:30:00	2026-04-23 20:10:00	34745	34923	ponta grossa	visita a cliente	\N
637	76	33	2026-04-24 08:45:00	2026-04-24 16:25:00	111879	112305	candoi	entrega de produtos	\N
638	73	34	2026-04-24 09:30:00	2026-04-24 16:55:00	31759	32207	telemaco borba	reuniao com fornecedor	\N
639	51	47	2026-04-25 06:30:00	2026-04-25 15:10:00	52523	52726	turvo	coleta de pecas	\N
640	78	43	2026-04-25 06:45:00	2026-04-25 15:10:00	35698	35953	curitiba	vistoria em obra	\N
641	61	41	2026-04-25 07:00:00	2026-04-25 16:40:00	109609	109899	curitiba	entrega de produtos	\N
642	69	41	2026-04-26 07:45:00	2026-04-26 17:25:00	31604	32141	ponta grossa	visita a cliente	\N
643	80	49	2026-04-26 09:15:00	2026-04-26 21:15:00	114335	114440	ivaipora	visita a cliente	\N
644	81	43	2026-04-27 07:45:00	2026-04-27 18:10:00	93595	93928	telemaco borba	entrega de materiais	\N
645	68	44	2026-04-27 08:15:00	2026-04-27 18:15:00	89364	89444	curitiba	entrega de produtos	\N
646	70	31	2026-05-06 09:30:00	2026-05-06 21:55:00	166985	167217	pitanga	coleta de pecas	\N
647	51	33	2026-05-06 09:45:00	2026-05-06 20:10:00	53321	53867	curitiba	coleta de pecas	\N
648	80	44	2026-05-08 07:15:00	2026-05-08 15:25:00	116257	116528	pitanga	visita a cliente	\N
649	68	35	2026-05-09 06:15:00	2026-05-09 13:25:00	91416	91804	guarapuava	entrega de produtos	\N
650	53	37	2026-05-09 06:45:00	2026-05-09 18:45:00	89407	89923	ivaipora	entrega de produtos	\N
651	89	45	2026-05-12 06:45:00	2026-05-12 15:55:00	37030	37327	palmital	servico externo	\N
652	69	48	2026-05-12 08:30:00	2026-05-12 20:30:00	33465	33771	reserva	transporte de materiais	\N
653	75	44	2026-05-14 08:00:00	2026-05-14 15:25:00	156972	157316	prudentopolis	transporte de equipe	\N
654	79	49	2026-05-14 08:15:00	2026-05-14 15:15:00	168903	169404	reserva	servico externo	\N
655	55	32	2026-05-14 09:15:00	2026-05-14 16:40:00	110724	110790	irati	visita a cliente	\N
656	62	42	2026-05-14 09:30:00	2026-05-14 17:40:00	56101	56355	reserva	transporte de equipe	\N
657	72	33	2026-05-16 06:00:00	2026-05-16 17:40:00	48386	48508	cascavel	vistoria em obra	\N
658	54	35	2026-05-16 08:00:00	2026-05-16 16:25:00	85335	85426	apucarana	coleta de pecas	\N
659	58	41	2026-05-17 07:30:00	2026-05-17 18:55:00	77507	77905	laranjeiras do sul	visita a cliente	\N
660	59	32	2026-05-18 08:45:00	2026-05-18 17:45:00	147956	148350	maringa	servico externo	\N
661	66	42	2026-05-18 09:15:00	2026-05-18 20:40:00	104313	104784	ivaipora	entrega de materiais	\N
662	52	35	2026-05-19 06:30:00	2026-05-19 18:55:00	139891	140164	telemaco borba	coleta de pecas	\N
663	65	37	2026-05-19 09:00:00	2026-05-19 21:25:00	95188	95577	guarapuava	coleta de pecas	\N
664	71	47	2026-05-19 09:30:00	2026-05-19 16:55:00	132355	132437	pitanga	coleta de pecas	\N
665	81	49	2026-05-19 09:30:00	2026-05-19 17:40:00	94721	94928	turvo	servico externo	\N
666	82	49	2026-05-20 06:45:00	2026-05-20 19:25:00	38181	38697	irati	transporte de equipe	\N
667	67	46	2026-05-21 06:45:00	2026-05-21 18:55:00	126862	127023	umuarama	entrega de mercadorias	\N
668	73	41	2026-05-21 08:15:00	2026-05-21 16:40:00	33737	34246	turvo	transporte de equipe	\N
669	88	36	2026-05-23 06:45:00	2026-05-23 14:25:00	151267	151586	cascavel	transporte de materiais	\N
670	83	46	2026-05-24 08:45:00	2026-05-24 18:45:00	120411	120497	laranjeiras do sul	vistoria em obra	\N
671	57	43	2026-05-26 08:15:00	2026-05-26 16:15:00	143266	143511	maringa	transporte de equipe	\N
672	64	38	2026-05-27 07:00:00	2026-05-27 17:40:00	124122	124200	castro	transporte de materiais	\N
673	52	47	2026-06-06 07:45:00	2026-06-06 20:25:00	141751	142140	castro	entrega de materiais	\N
674	58	42	2026-06-06 08:00:00	2026-06-06 19:10:00	78891	78951	maringa	reuniao com fornecedor	\N
675	69	34	2026-06-08 07:00:00	2026-06-08 15:40:00	35276	35712	pitanga	entrega de materiais	\N
676	85	33	2026-06-08 07:30:00	2026-06-08 18:55:00	29320	29598	turvo	reuniao com fornecedor	\N
677	84	47	2026-06-08 08:00:00	2026-06-08 20:00:00	51114	51361	umuarama	entrega de produtos	\N
678	74	44	2026-06-10 06:15:00	2026-06-10 13:40:00	84933	85427	curitiba	coleta de pecas	\N
679	63	32	2026-06-10 06:45:00	2026-06-10 17:10:00	147016	147217	prudentopolis	servico externo	\N
680	86	42	2026-06-13 07:15:00	2026-06-13 14:25:00	64719	64976	campo mourao	coleta de pecas	\N
681	76	49	2026-06-15 06:45:00	2026-06-15 16:25:00	114959	115251	ponta grossa	transporte de materiais	\N
682	61	45	2026-06-15 07:00:00	2026-06-15 17:00:00	111806	112164	pitanga	entrega de materiais	\N
683	72	34	2026-06-15 09:00:00	2026-06-15 16:25:00	50125	50226	cascavel	transporte de materiais	\N
684	90	46	2026-06-15 09:30:00	2026-06-15 21:10:00	155610	155938	telemaco borba	servico externo	\N
685	67	35	2026-06-16 08:30:00	2026-06-16 20:30:00	128187	128344	telemaco borba	entrega de mercadorias	\N
686	51	37	2026-06-17 08:00:00	2026-06-17 17:25:00	54996	55117	laranjeiras do sul	entrega de mercadorias	\N
687	56	31	2026-06-17 08:00:00	2026-06-17 19:00:00	131174	131661	cascavel	entrega de mercadorias	\N
688	70	38	2026-06-17 09:00:00	2026-06-17 16:10:00	169026	169434	candoi	visita a cliente	\N
689	57	42	2026-06-17 09:30:00	2026-06-17 16:55:00	145454	145693	campo mourao	servico externo	\N
690	75	41	2026-06-19 06:15:00	2026-06-19 16:40:00	158768	159183	pitanga	transporte de materiais	\N
691	78	45	2026-06-19 08:30:00	2026-06-19 21:10:00	38406	38683	turvo	vistoria em obra	\N
692	65	41	2026-06-20 07:30:00	2026-06-20 14:40:00	96873	97238	ponta grossa	entrega de mercadorias	\N
693	73	34	2026-06-21 06:45:00	2026-06-21 14:25:00	35944	36119	umuarama	coleta de pecas	\N
694	66	39	2026-06-22 06:15:00	2026-06-22 13:55:00	106378	106464	reserva	entrega de mercadorias	\N
695	77	42	2026-06-22 08:30:00	2026-06-22 20:30:00	169336	169815	campo mourao	transporte de materiais	\N
696	60	32	2026-06-23 09:45:00	2026-06-23 21:55:00	72234	72467	guarapuava	entrega de produtos	\N
697	81	31	2026-06-24 09:00:00	2026-06-24 17:10:00	96840	97135	pitanga	servico externo	\N
698	71	32	2026-06-25 07:00:00	2026-06-25 15:10:00	134691	135092	apucarana	reuniao com fornecedor	\N
699	59	31	2026-06-25 09:45:00	2026-06-25 20:10:00	149913	150422	palmital	transporte de materiais	\N
700	88	38	2026-07-06 07:00:00	2026-07-06 14:10:00	155200	155519	reserva	entrega de produtos	\N
701	71	43	2026-07-06 07:15:00	2026-07-06 19:15:00	136690	137176	reserva	coleta de pecas	\N
702	72	49	2026-07-07 07:30:00	2026-07-07 20:10:00	51927	52204	cascavel	coleta de pecas	\N
703	56	46	2026-07-07 08:00:00	2026-07-07 18:40:00	133091	133258	umuarama	entrega de produtos	\N
704	89	40	2026-07-09 07:00:00	2026-07-09 19:00:00	41198	41393	curitiba	entrega de produtos	\N
705	68	43	2026-07-10 07:15:00	2026-07-10 18:55:00	94209	94719	turvo	visita a cliente	\N
706	82	48	2026-07-11 09:30:00	2026-07-11 17:30:00	41780	42316	palmital	vistoria em obra	\N
707	60	36	2026-07-12 06:00:00	2026-07-12 17:10:00	73916	74426	castro	servico externo	\N
708	51	45	2026-07-12 08:30:00	2026-07-12 17:30:00	56276	56797	laranjeiras do sul	coleta de pecas	\N
709	58	36	2026-07-14 08:45:00	2026-07-14 16:25:00	80404	80587	prudentopolis	entrega de produtos	\N
710	53	35	2026-07-15 07:45:00	2026-07-15 19:55:00	93083	93604	palmital	transporte de materiais	\N
711	76	48	2026-07-15 07:45:00	2026-07-15 16:25:00	116524	116848	laranjeiras do sul	visita a cliente	\N
712	59	42	2026-07-16 08:45:00	2026-07-16 18:45:00	152282	152384	maringa	transporte de equipe	\N
713	64	47	2026-07-17 08:45:00	2026-07-17 20:25:00	127038	127155	umuarama	visita a cliente	\N
714	83	50	2026-07-18 07:00:00	2026-07-18 19:25:00	124477	124901	candoi	visita a cliente	\N
715	52	33	2026-07-19 06:45:00	2026-07-19 18:10:00	144124	144242	palmital	transporte de materiais	\N
716	87	48	2026-07-19 08:15:00	2026-07-19 15:25:00	147714	148109	campo mourao	reuniao com fornecedor	\N
717	86	31	2026-07-21 06:00:00	2026-07-21 15:00:00	67044	67485	maringa	entrega de produtos	\N
718	85	47	2026-07-21 08:30:00	2026-07-21 18:40:00	31542	32031	maringa	vistoria em obra	\N
719	79	39	2026-07-22 07:15:00	2026-07-22 14:15:00	172370	172823	guarapuava	visita a cliente	\N
720	69	39	2026-07-23 07:45:00	2026-07-23 15:10:00	37113	37368	cascavel	transporte de equipe	\N
721	67	32	2026-07-23 09:45:00	2026-07-23 20:10:00	129564	130101	campo mourao	visita a cliente	\N
722	84	36	2026-07-25 07:30:00	2026-07-25 18:40:00	53288	53690	cascavel	transporte de materiais	\N
723	63	36	2026-07-26 09:30:00	2026-07-26 17:30:00	148647	148725	londrina	visita a cliente	\N
724	62	47	2026-07-27 07:30:00	2026-07-27 15:30:00	59312	59548	reserva	servico externo	\N
725	90	46	2026-08-06 09:15:00	2026-08-06 18:25:00	159845	160363	irati	transporte de equipe	\N
726	59	35	2026-08-08 09:45:00	2026-08-08 21:55:00	153320	153739	irati	entrega de produtos	\N
727	77	39	2026-08-09 09:30:00	2026-08-09 17:55:00	172311	172859	reserva	entrega de materiais	\N
728	58	37	2026-08-10 08:00:00	2026-08-10 20:40:00	81463	81839	laranjeiras do sul	transporte de equipe	\N
729	69	44	2026-08-10 08:30:00	2026-08-10 16:30:00	39220	39464	candoi	visita a cliente	\N
730	85	40	2026-08-11 06:30:00	2026-08-11 13:30:00	32558	32692	londrina	servico externo	\N
731	88	37	2026-08-12 08:30:00	2026-08-12 18:30:00	157366	157713	telemaco borba	transporte de equipe	\N
732	82	40	2026-08-14 07:00:00	2026-08-14 19:25:00	42691	43200	reserva	transporte de equipe	\N
733	87	43	2026-08-14 08:15:00	2026-08-14 16:40:00	148922	149381	londrina	visita a cliente	\N
734	76	44	2026-08-14 08:45:00	2026-08-14 20:55:00	117852	118018	maringa	visita a cliente	\N
735	56	42	2026-08-14 09:45:00	2026-08-14 19:25:00	133998	134236	candoi	entrega de materiais	\N
736	80	44	2026-08-15 09:45:00	2026-08-15 17:10:00	121862	122204	campo mourao	reuniao com fornecedor	\N
737	62	41	2026-08-16 07:30:00	2026-08-16 16:40:00	60797	61257	prudentopolis	entrega de mercadorias	\N
738	55	44	2026-08-17 06:30:00	2026-08-17 14:10:00	116773	116894	apucarana	reuniao com fornecedor	\N
739	61	41	2026-08-17 09:30:00	2026-08-17 21:10:00	114819	114912	castro	vistoria em obra	\N
740	63	34	2026-08-17 09:30:00	2026-08-17 19:55:00	150492	151034	laranjeiras do sul	servico externo	\N
741	66	35	2026-08-18 06:00:00	2026-08-18 16:10:00	109526	109863	turvo	entrega de mercadorias	\N
742	84	39	2026-08-18 09:00:00	2026-08-18 18:25:00	54468	54784	londrina	entrega de materiais	\N
743	60	43	2026-08-20 09:00:00	2026-08-20 20:00:00	76057	76588	turvo	transporte de materiais	\N
744	81	40	2026-08-21 08:00:00	2026-08-21 17:00:00	99740	99827	curitiba	vistoria em obra	\N
745	57	36	2026-08-22 07:30:00	2026-08-22 15:40:00	148497	148971	castro	entrega de materiais	\N
746	67	31	2026-08-23 07:00:00	2026-08-23 15:25:00	131766	132076	apucarana	coleta de pecas	\N
747	53	43	2026-08-23 08:15:00	2026-08-23 18:40:00	94849	95087	pitanga	servico externo	\N
748	73	46	2026-08-23 08:15:00	2026-08-23 19:15:00	38876	38989	telemaco borba	entrega de produtos	\N
749	51	32	2026-08-24 09:30:00	2026-08-24 16:55:00	58053	58586	irati	entrega de materiais	\N
750	79	32	2026-08-25 06:00:00	2026-08-25 18:40:00	174038	174118	ponta grossa	entrega de produtos	\N
751	77	50	2026-09-06 06:15:00	2026-09-06 17:55:00	174598	175112	guarapuava	entrega de produtos	\N
752	86	34	2026-09-06 06:30:00	2026-09-06 14:30:00	70144	70659	cascavel	vistoria em obra	\N
753	87	39	2026-09-07 06:15:00	2026-09-07 18:40:00	150660	150900	laranjeiras do sul	entrega de produtos	\N
754	70	40	2026-09-07 09:45:00	2026-09-07 19:45:00	173178	173488	candoi	transporte de equipe	\N
755	63	31	2026-09-09 08:00:00	2026-09-09 19:10:00	152613	153088	ivaipora	coleta de pecas	\N
756	90	48	2026-09-10 07:00:00	2026-09-10 18:10:00	161034	161205	pitanga	entrega de materiais	\N
757	55	41	2026-09-10 07:30:00	2026-09-10 17:55:00	118532	118853	londrina	entrega de produtos	\N
758	52	31	2026-09-10 07:45:00	2026-09-10 15:10:00	147038	147380	candoi	transporte de materiais	\N
759	66	35	2026-09-12 06:00:00	2026-09-12 15:00:00	110937	111114	pitanga	servico externo	\N
760	67	33	2026-09-12 06:15:00	2026-09-12 13:55:00	133473	133803	palmital	vistoria em obra	\N
761	61	34	2026-09-12 08:45:00	2026-09-12 17:55:00	116763	116926	campo mourao	entrega de materiais	\N
762	54	37	2026-09-13 09:15:00	2026-09-13 19:40:00	91464	91874	guarapuava	transporte de equipe	\N
763	65	32	2026-09-15 07:00:00	2026-09-15 14:00:00	102400	102616	maringa	entrega de materiais	\N
764	89	47	2026-09-15 07:45:00	2026-09-15 20:10:00	45163	45678	prudentopolis	visita a cliente	\N
765	75	50	2026-09-17 09:00:00	2026-09-17 20:00:00	164152	164400	umuarama	coleta de pecas	\N
766	60	44	2026-09-18 09:45:00	2026-09-18 20:55:00	78122	78549	irati	servico externo	\N
767	78	43	2026-09-19 06:00:00	2026-09-19 16:40:00	43559	43847	maringa	vistoria em obra	\N
768	83	31	2026-09-19 07:30:00	2026-09-19 15:10:00	127751	127965	maringa	transporte de equipe	\N
769	53	45	2026-09-20 07:15:00	2026-09-20 16:55:00	96337	96693	cascavel	reuniao com fornecedor	\N
770	79	38	2026-09-20 08:15:00	2026-09-20 15:25:00	176125	176571	castro	servico externo	\N
771	88	45	2026-09-21 07:45:00	2026-09-21 16:10:00	159236	159414	laranjeiras do sul	reuniao com fornecedor	\N
772	74	38	2026-09-21 09:15:00	2026-09-21 16:40:00	90908	91031	apucarana	visita a cliente	\N
773	76	44	2026-09-22 07:30:00	2026-09-22 19:55:00	119792	120092	maringa	transporte de materiais	\N
774	71	36	2026-09-22 09:00:00	2026-09-22 17:40:00	139797	140066	prudentopolis	entrega de produtos	\N
775	82	47	2026-09-26 06:30:00	2026-09-26 18:30:00	44219	44627	castro	entrega de produtos	\N
776	84	35	2026-09-26 08:30:00	2026-09-26 17:10:00	56220	56523	prudentopolis	servico externo	\N
777	51	35	2026-09-27 08:45:00	2026-09-27 20:10:00	59971	60158	castro	transporte de equipe	\N
778	57	41	2026-09-27 09:30:00	2026-09-27 17:30:00	149701	149989	curitiba	visita a cliente	\N
779	64	43	2026-10-06 09:00:00	2026-10-06 21:25:00	131937	132092	irati	transporte de equipe	\N
780	68	38	2026-10-06 09:00:00	2026-10-06 18:40:00	98962	99177	curitiba	vistoria em obra	\N
781	58	45	2026-10-07 09:30:00	2026-10-07 18:40:00	84010	84278	laranjeiras do sul	vistoria em obra	\N
782	55	45	2026-10-08 09:15:00	2026-10-08 21:55:00	120158	120365	castro	reuniao com fornecedor	\N
783	80	32	2026-10-09 09:45:00	2026-10-09 19:45:00	125133	125439	ponta grossa	vistoria em obra	\N
784	89	42	2026-10-09 09:45:00	2026-10-09 20:10:00	46656	47128	ivaipora	entrega de mercadorias	\N
785	52	36	2026-10-10 07:00:00	2026-10-10 14:40:00	149146	149288	turvo	entrega de produtos	\N
786	74	32	2026-10-11 08:30:00	2026-10-11 19:55:00	92561	92647	castro	coleta de pecas	\N
787	53	35	2026-10-12 07:15:00	2026-10-12 15:40:00	98517	98963	umuarama	reuniao com fornecedor	\N
788	63	35	2026-10-13 09:45:00	2026-10-13 16:45:00	155092	155169	prudentopolis	entrega de materiais	\N
789	57	35	2026-10-15 08:00:00	2026-10-15 16:00:00	151130	151472	apucarana	transporte de materiais	\N
790	70	32	2026-10-15 09:45:00	2026-10-15 17:10:00	174499	174586	ivaipora	entrega de produtos	\N
791	75	44	2026-10-16 09:45:00	2026-10-16 17:55:00	165795	166220	umuarama	entrega de materiais	\N
792	85	42	2026-10-17 07:45:00	2026-10-17 17:10:00	36841	36924	pitanga	coleta de pecas	\N
793	61	33	2026-10-19 06:30:00	2026-10-19 14:40:00	118190	118461	guarapuava	transporte de materiais	\N
794	51	31	2026-10-19 07:00:00	2026-10-19 14:40:00	61591	62118	palmital	vistoria em obra	\N
795	79	39	2026-10-20 08:15:00	2026-10-20 19:55:00	177698	177968	telemaco borba	transporte de materiais	\N
796	83	43	2026-10-21 08:15:00	2026-10-21 19:25:00	129267	129805	turvo	entrega de mercadorias	\N
797	77	41	2026-10-21 09:15:00	2026-10-21 19:55:00	176281	176617	pitanga	entrega de materiais	\N
798	90	38	2026-10-24 07:30:00	2026-10-24 17:30:00	162356	162899	curitiba	transporte de equipe	\N
799	67	39	2026-10-27 06:45:00	2026-10-27 18:10:00	134882	135411	candoi	entrega de materiais	\N
800	1	1	2026-10-23 13:03:24.855367	2026-10-23 17:03:24.855367	91517	91696	Guarapuava	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
801	2	2	2026-10-22 13:03:24.855367	2026-10-22 17:03:24.855367	93313	93719	Pitanga	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
802	3	3	2026-10-21 13:03:24.855367	2026-10-21 17:03:24.855367	95109	95296	Curitiba	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
803	4	4	2026-10-20 13:03:24.855367	2026-10-20 17:03:24.855367	96905	97240	Ponta Grossa	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
804	5	5	2026-10-19 13:03:24.855367	2026-10-19 17:03:24.855367	98701	99032	Cascavel	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
805	6	6	2026-10-18 13:03:24.855367	2026-10-18 17:03:24.855367	112997	113369	Londrina	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
806	7	7	2026-10-17 13:03:24.855367	2026-10-17 17:03:24.855367	102293	102578	Irati	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
807	8	8	2026-10-16 13:03:24.855367	2026-10-16 17:03:24.855367	104089	104200	Prudentópolis	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
808	9	9	2026-10-15 13:03:24.855367	2026-10-15 17:03:24.855367	140985	141248	Campo Mourão	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
809	10	10	2026-10-14 13:03:24.855367	2026-10-14 17:03:24.855367	168981	169291	Paranaguá	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
810	11	11	2026-10-13 13:03:24.855367	2026-10-13 17:03:24.855367	108997	109279	Guarapuava	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
811	12	12	2026-10-12 13:03:24.855367	2026-10-12 17:03:24.855367	110783	110994	Pitanga	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
812	13	13	2026-10-11 13:03:24.855367	2026-10-11 17:03:24.855367	112569	112774	Curitiba	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
813	14	14	2026-10-10 13:03:24.855367	2026-10-10 17:03:24.855367	114355	114672	Ponta Grossa	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
814	15	15	2026-10-09 13:03:24.855367	2026-10-09 17:03:24.855367	116141	116454	Cascavel	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
815	16	16	2026-10-08 13:03:24.855367	2026-10-08 17:03:24.855367	117927	118155	Londrina	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
816	17	17	2026-10-07 13:03:24.855367	2026-10-07 17:03:24.855367	119713	119981	Irati	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
817	18	18	2026-10-06 13:03:24.855367	2026-10-06 17:03:24.855367	121499	121698	Prudentópolis	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
818	19	19	2026-10-05 13:03:24.855367	2026-10-05 17:03:24.855367	123285	123416	Campo Mourão	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
819	20	20	2026-10-04 13:03:24.855367	2026-10-04 17:03:24.855367	125071	125463	Paranaguá	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
820	21	1	2026-10-03 13:03:24.855367	2026-10-03 17:03:24.855367	121500	121657	Guarapuava	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
821	22	2	2026-10-02 13:03:24.855367	2026-10-02 17:03:24.855367	123272	123599	Pitanga	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
822	23	3	2026-10-01 13:03:24.855367	2026-10-01 17:03:24.855367	125044	125275	Curitiba	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
823	24	4	2026-09-30 13:03:24.855367	2026-09-30 17:03:24.855367	126816	126970	Ponta Grossa	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
824	25	5	2026-09-29 13:03:24.855367	2026-09-29 17:03:24.855367	128588	128833	Cascavel	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
825	26	6	2026-09-28 13:03:24.855367	2026-09-28 17:03:24.855367	130360	130417	Londrina	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
826	27	7	2026-09-27 13:03:24.855367	2026-09-27 17:03:24.855367	132132	132329	Irati	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
827	28	8	2026-09-26 13:03:24.855367	2026-09-26 17:03:24.855367	133904	134320	Prudentópolis	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
828	29	9	2026-09-25 13:03:24.855367	2026-09-25 17:03:24.855367	135676	135953	Campo Mourão	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
829	30	10	2026-09-24 13:03:24.855367	2026-09-24 17:03:24.855367	137448	137844	Paranaguá	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
830	1	11	2026-09-23 13:03:24.855367	2026-09-23 17:03:24.855367	91157	91387	Guarapuava	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
831	2	12	2026-09-22 13:03:24.855367	2026-09-22 17:03:24.855367	92953	93185	Pitanga	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
832	3	13	2026-09-21 13:03:24.855367	2026-09-21 17:03:24.855367	94749	95123	Curitiba	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
833	4	14	2026-09-20 13:03:24.855367	2026-09-20 17:03:24.855367	96545	96913	Ponta Grossa	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
834	5	15	2026-09-19 13:03:24.855367	2026-09-19 17:03:24.855367	98341	98453	Cascavel	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
835	6	16	2026-09-18 13:03:24.855367	2026-09-18 17:03:24.855367	112637	112925	Londrina	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
836	7	17	2026-09-17 13:03:24.855367	2026-09-17 17:03:24.855367	101933	101986	Irati	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
837	8	18	2026-09-16 13:03:24.855367	2026-09-16 17:03:24.855367	103729	103828	Prudentópolis	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
838	9	19	2026-09-15 13:03:24.855367	2026-09-15 17:03:24.855367	140625	140917	Campo Mourão	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
839	10	20	2026-09-14 13:03:24.855367	2026-09-14 17:03:24.855367	168621	168958	Paranaguá	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
840	11	1	2026-09-13 13:03:24.855367	2026-09-13 17:03:24.855367	108637	108841	Guarapuava	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
841	12	2	2026-09-12 13:03:24.855367	2026-09-12 17:03:24.855367	110423	110509	Pitanga	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
842	13	3	2026-09-11 13:03:24.855367	2026-09-11 17:03:24.855367	112209	112469	Curitiba	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
843	14	4	2026-09-10 13:03:24.855367	2026-09-10 17:03:24.855367	113995	114081	Ponta Grossa	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
844	15	5	2026-09-09 13:03:24.855367	2026-09-09 17:03:24.855367	115781	116085	Cascavel	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
845	16	6	2026-09-08 13:03:24.855367	2026-09-08 17:03:24.855367	117567	117835	Londrina	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
846	17	7	2026-09-07 13:03:24.855367	2026-09-07 17:03:24.855367	119353	119395	Irati	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
847	18	8	2026-09-06 13:03:24.855367	2026-09-06 17:03:24.855367	121139	121543	Prudentópolis	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
848	19	9	2026-09-05 13:03:24.855367	2026-09-05 17:03:24.855367	122925	123033	Campo Mourão	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
849	20	10	2026-09-04 13:03:24.855367	2026-09-04 17:03:24.855367	124711	124955	Paranaguá	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
850	21	11	2026-09-03 13:03:24.855367	2026-09-03 17:03:24.855367	121140	121510	Guarapuava	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
851	22	12	2026-09-02 13:03:24.855367	2026-09-02 17:03:24.855367	122912	123026	Pitanga	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
852	23	13	2026-09-01 13:03:24.855367	2026-09-01 17:03:24.855367	124684	124757	Curitiba	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
853	24	14	2026-08-31 13:03:24.855367	2026-08-31 17:03:24.855367	126456	126731	Ponta Grossa	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
854	25	15	2026-08-30 13:03:24.855367	2026-08-30 17:03:24.855367	128228	128398	Cascavel	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
855	26	16	2026-08-29 13:03:24.855367	2026-08-29 17:03:24.855367	130000	130208	Londrina	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
856	27	17	2026-08-28 13:03:24.855367	2026-08-28 17:03:24.855367	131772	132126	Irati	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
857	28	18	2026-08-27 13:03:24.855367	2026-08-27 17:03:24.855367	133544	133933	Prudentópolis	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
858	29	19	2026-08-26 13:03:24.855367	2026-08-26 17:03:24.855367	135316	135554	Campo Mourão	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
859	30	20	2026-08-25 13:03:24.855367	2026-08-25 17:03:24.855367	137088	137455	Paranaguá	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
860	1	1	2026-08-24 13:03:24.855367	2026-08-24 17:03:24.855367	90797	90873	Guarapuava	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
861	2	2	2026-08-23 13:03:24.855367	2026-08-23 17:03:24.855367	92593	92796	Pitanga	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
862	3	3	2026-08-22 13:03:24.855367	2026-08-22 17:03:24.855367	94389	94769	Curitiba	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
863	4	4	2026-08-21 13:03:24.855367	2026-08-21 17:03:24.855367	96185	96493	Ponta Grossa	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
864	5	5	2026-08-20 13:03:24.855367	2026-08-20 17:03:24.855367	97981	98210	Cascavel	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
865	6	6	2026-08-19 13:03:24.855367	2026-08-19 17:03:24.855367	112277	112474	Londrina	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
866	7	7	2026-08-18 13:03:24.855367	2026-08-18 17:03:24.855367	101573	101928	Irati	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
867	8	8	2026-08-17 13:03:24.855367	2026-08-17 17:03:24.855367	103369	103771	Prudentópolis	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
868	9	9	2026-08-16 13:03:24.855367	2026-08-16 17:03:24.855367	140265	140549	Campo Mourão	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
869	10	10	2026-08-15 13:03:24.855367	2026-08-15 17:03:24.855367	168261	168573	Paranaguá	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
870	11	11	2026-08-14 13:03:24.855367	2026-08-14 17:03:24.855367	108277	108330	Guarapuava	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
871	12	12	2026-08-13 13:03:24.855367	2026-08-13 17:03:24.855367	110063	110414	Pitanga	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
872	13	13	2026-08-12 13:03:24.855367	2026-08-12 17:03:24.855367	111849	111919	Curitiba	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
873	14	14	2026-08-11 13:03:24.855367	2026-08-11 17:03:24.855367	113635	113790	Ponta Grossa	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
874	15	15	2026-08-10 13:03:24.855367	2026-08-10 17:03:24.855367	115421	115779	Cascavel	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
875	16	16	2026-08-09 13:03:24.855367	2026-08-09 17:03:24.855367	117207	117592	Londrina	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
876	17	17	2026-08-08 13:03:24.855367	2026-08-08 17:03:24.855367	118993	119175	Irati	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
877	18	18	2026-08-07 13:03:24.855367	2026-08-07 17:03:24.855367	120779	120930	Prudentópolis	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
878	19	19	2026-08-06 13:03:24.855367	2026-08-06 17:03:24.855367	122565	122982	Campo Mourão	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
879	20	20	2026-08-05 13:03:24.855367	2026-08-05 17:03:24.855367	124351	124432	Paranaguá	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
880	21	1	2026-08-04 13:03:24.855367	2026-08-04 17:03:24.855367	120780	121037	Guarapuava	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
881	22	2	2026-08-03 13:03:24.855367	2026-08-03 17:03:24.855367	122552	122637	Pitanga	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
882	23	3	2026-08-02 13:03:24.855367	2026-08-02 17:03:24.855367	124324	124683	Curitiba	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
883	24	4	2026-08-01 13:03:24.855367	2026-08-01 17:03:24.855367	126096	126491	Ponta Grossa	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
884	25	5	2026-07-31 13:03:24.855367	2026-07-31 17:03:24.855367	127868	127954	Cascavel	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
885	26	6	2026-07-30 13:03:24.855367	2026-07-30 17:03:24.855367	129640	129902	Londrina	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
886	27	7	2026-07-29 13:03:24.855367	2026-07-29 17:03:24.855367	131412	131532	Irati	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
887	28	8	2026-07-28 13:03:24.855367	2026-07-28 17:03:24.855367	133184	133574	Prudentópolis	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
888	29	9	2026-07-27 13:03:24.855367	2026-07-27 17:03:24.855367	134956	135144	Campo Mourão	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
889	30	10	2026-07-26 13:03:24.855367	2026-07-26 17:03:24.855367	136728	136777	Paranaguá	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
890	1	11	2026-07-25 13:03:24.855367	2026-07-25 17:03:24.855367	90437	90495	Guarapuava	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
891	2	12	2026-07-24 13:03:24.855367	2026-07-24 17:03:24.855367	92233	92434	Pitanga	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
892	3	13	2026-07-23 13:03:24.855367	2026-07-23 17:03:24.855367	94029	94092	Curitiba	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
893	4	14	2026-07-22 13:03:24.855367	2026-07-22 17:03:24.855367	95825	96010	Ponta Grossa	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
894	5	15	2026-07-21 13:03:24.855367	2026-07-21 17:03:24.855367	97621	97839	Cascavel	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
895	6	16	2026-07-20 13:03:24.855367	2026-07-20 17:03:24.855367	111917	112143	Londrina	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
896	7	17	2026-07-19 13:03:24.855367	2026-07-19 17:03:24.855367	101213	101468	Irati	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
897	8	18	2026-07-18 13:03:24.855367	2026-07-18 17:03:24.855367	103009	103118	Prudentópolis	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
898	9	19	2026-07-17 13:03:24.855367	2026-07-17 17:03:24.855367	139905	140065	Campo Mourão	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
899	10	20	2026-07-16 13:03:24.855367	2026-07-16 17:03:24.855367	167901	168207	Paranaguá	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
900	11	1	2026-07-15 13:03:24.855367	2026-07-15 17:03:24.855367	107917	108162	Guarapuava	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
901	12	2	2026-07-14 13:03:24.855367	2026-07-14 17:03:24.855367	109703	110027	Pitanga	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
902	13	3	2026-07-13 13:03:24.855367	2026-07-13 17:03:24.855367	111489	111873	Curitiba	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
903	14	4	2026-07-12 13:03:24.855367	2026-07-12 17:03:24.855367	113275	113402	Ponta Grossa	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
904	15	5	2026-07-11 13:03:24.855367	2026-07-11 17:03:24.855367	115061	115183	Cascavel	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
905	16	6	2026-07-10 13:03:24.855367	2026-07-10 17:03:24.855367	116847	116971	Londrina	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
906	17	7	2026-07-09 13:03:24.855367	2026-07-09 17:03:24.855367	118633	118708	Irati	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
907	18	8	2026-07-08 13:03:24.855367	2026-07-08 17:03:24.855367	120419	120766	Prudentópolis	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
908	19	9	2026-07-07 13:03:24.855367	2026-07-07 17:03:24.855367	122205	122435	Campo Mourão	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
909	20	10	2026-07-06 13:03:24.855367	2026-07-06 17:03:24.855367	123991	124343	Paranaguá	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
910	21	11	2026-07-05 13:03:24.855367	2026-07-05 17:03:24.855367	120420	120804	Guarapuava	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
911	22	12	2026-07-04 13:03:24.855367	2026-07-04 17:03:24.855367	122192	122350	Pitanga	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
912	23	13	2026-07-03 13:03:24.855367	2026-07-03 17:03:24.855367	123964	124253	Curitiba	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
913	24	14	2026-07-02 13:03:24.855367	2026-07-02 17:03:24.855367	125736	126069	Ponta Grossa	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
914	25	15	2026-07-01 13:03:24.855367	2026-07-01 17:03:24.855367	127508	127616	Cascavel	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
915	26	16	2026-06-30 13:03:24.855367	2026-06-30 17:03:24.855367	129280	129433	Londrina	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
916	27	17	2026-06-29 13:03:24.855367	2026-06-29 17:03:24.855367	131052	131323	Irati	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
917	28	18	2026-06-28 13:03:24.855367	2026-06-28 17:03:24.855367	132824	133185	Prudentópolis	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
918	29	19	2026-06-27 13:03:24.855367	2026-06-27 17:03:24.855367	134596	134761	Campo Mourão	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
919	30	20	2026-06-26 13:03:24.855367	2026-06-26 17:03:24.855367	136368	136638	Paranaguá	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
920	1	1	2026-06-25 13:03:24.855367	2026-06-25 17:03:24.855367	90077	90242	Guarapuava	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
921	2	2	2026-06-24 13:03:24.855367	2026-06-24 17:03:24.855367	91873	92249	Pitanga	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
922	3	3	2026-06-23 13:03:24.855367	2026-06-23 17:03:24.855367	93669	93708	Curitiba	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
923	4	4	2026-06-22 13:03:24.855367	2026-06-22 17:03:24.855367	95465	95738	Ponta Grossa	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
924	5	5	2026-06-21 13:03:24.855367	2026-06-21 17:03:24.855367	97261	97443	Cascavel	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
925	6	6	2026-06-20 13:03:24.855367	2026-06-20 17:03:24.855367	111557	111938	Londrina	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
926	7	7	2026-06-19 13:03:24.855367	2026-06-19 17:03:24.855367	100853	101167	Irati	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
927	8	8	2026-06-18 13:03:24.855367	2026-06-18 17:03:24.855367	102649	102764	Prudentópolis	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
928	9	9	2026-06-17 13:03:24.855367	2026-06-17 17:03:24.855367	139545	139617	Campo Mourão	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
929	10	10	2026-06-16 13:03:24.855367	2026-06-16 17:03:24.855367	167541	167802	Paranaguá	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
930	11	11	2026-06-15 13:03:24.855367	2026-06-15 17:03:24.855367	107557	107768	Guarapuava	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
931	12	12	2026-06-14 13:03:24.855367	2026-06-14 17:03:24.855367	109343	109678	Pitanga	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
932	13	13	2026-06-13 13:03:24.855367	2026-06-13 17:03:24.855367	111129	111317	Curitiba	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
933	14	14	2026-06-12 13:03:24.855367	2026-06-12 17:03:24.855367	112915	113277	Ponta Grossa	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
934	15	15	2026-06-11 13:03:24.855367	2026-06-11 17:03:24.855367	114701	114953	Cascavel	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
935	16	16	2026-06-10 13:03:24.855367	2026-06-10 17:03:24.855367	116487	116875	Londrina	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
936	17	17	2026-06-09 13:03:24.855367	2026-06-09 17:03:24.855367	118273	118436	Irati	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
937	18	18	2026-06-08 13:03:24.855367	2026-06-08 17:03:24.855367	120059	120327	Prudentópolis	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
938	19	19	2026-06-07 13:03:24.855367	2026-06-07 17:03:24.855367	121845	122034	Campo Mourão	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
939	20	20	2026-06-06 13:03:24.855367	2026-06-06 17:03:24.855367	123631	123767	Paranaguá	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
940	21	1	2026-06-05 13:03:24.855367	2026-06-05 17:03:24.855367	120060	120291	Guarapuava	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
941	22	2	2026-06-04 13:03:24.855367	2026-06-04 17:03:24.855367	121832	122114	Pitanga	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
942	23	3	2026-06-03 13:03:24.855367	2026-06-03 17:03:24.855367	123604	123693	Curitiba	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
943	24	4	2026-06-02 13:03:24.855367	2026-06-02 17:03:24.855367	125376	125532	Ponta Grossa	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
944	25	5	2026-06-01 13:03:24.855367	2026-06-01 17:03:24.855367	127148	127378	Cascavel	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
945	26	6	2026-05-31 13:03:24.855367	2026-05-31 17:03:24.855367	128920	129247	Londrina	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
946	27	7	2026-05-30 13:03:24.855367	2026-05-30 17:03:24.855367	130692	130910	Irati	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
947	28	8	2026-05-29 13:03:24.855367	2026-05-29 17:03:24.855367	132464	132793	Prudentópolis	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
948	29	9	2026-05-28 13:03:24.855367	2026-05-28 17:03:24.855367	134236	134422	Campo Mourão	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
949	30	10	2026-05-27 13:03:24.855367	2026-05-27 17:03:24.855367	136008	136401	Paranaguá	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
950	1	11	2026-05-26 13:03:24.855367	2026-05-26 17:03:24.855367	89717	89903	Guarapuava	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
951	2	12	2026-05-25 13:03:24.855367	2026-05-25 17:03:24.855367	91513	91559	Pitanga	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
952	3	13	2026-05-24 13:03:24.855367	2026-05-24 17:03:24.855367	93309	93681	Curitiba	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
953	4	14	2026-05-23 13:03:24.855367	2026-05-23 17:03:24.855367	95105	95342	Ponta Grossa	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
954	5	15	2026-05-22 13:03:24.855367	2026-05-22 17:03:24.855367	96901	97076	Cascavel	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
955	6	16	2026-05-21 13:03:24.855367	2026-05-21 17:03:24.855367	111197	111236	Londrina	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
956	7	17	2026-05-20 13:03:24.855367	2026-05-20 17:03:24.855367	100493	100817	Irati	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
957	8	18	2026-05-19 13:03:24.855367	2026-05-19 17:03:24.855367	102289	102675	Prudentópolis	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
958	9	19	2026-05-18 13:03:24.855367	2026-05-18 17:03:24.855367	139185	139601	Campo Mourão	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
959	10	20	2026-05-17 13:03:24.855367	2026-05-17 17:03:24.855367	167181	167241	Paranaguá	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
960	11	1	2026-05-16 13:03:24.855367	2026-05-16 17:03:24.855367	107197	107542	Guarapuava	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
961	12	2	2026-05-15 13:03:24.855367	2026-05-15 17:03:24.855367	108983	109399	Pitanga	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
962	13	3	2026-05-14 13:03:24.855367	2026-05-14 17:03:24.855367	110769	111058	Curitiba	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
963	14	4	2026-05-13 13:03:24.855367	2026-05-13 17:03:24.855367	112555	112736	Ponta Grossa	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
964	15	5	2026-05-12 13:03:24.855367	2026-05-12 17:03:24.855367	114341	114493	Cascavel	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
965	16	6	2026-05-11 13:03:24.855367	2026-05-11 17:03:24.855367	116127	116472	Londrina	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
966	17	7	2026-05-10 13:03:24.855367	2026-05-10 17:03:24.855367	117913	118128	Irati	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
967	18	8	2026-05-09 13:03:24.855367	2026-05-09 17:03:24.855367	119699	119846	Prudentópolis	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
968	19	9	2026-05-08 13:03:24.855367	2026-05-08 17:03:24.855367	121485	121845	Campo Mourão	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
969	20	10	2026-05-07 13:03:24.855367	2026-05-07 17:03:24.855367	123271	123403	Paranaguá	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
970	21	11	2026-05-06 13:03:24.855367	2026-05-06 17:03:24.855367	119700	120052	Guarapuava	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
971	22	12	2026-05-05 13:03:24.855367	2026-05-05 17:03:24.855367	121472	121635	Pitanga	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
972	23	13	2026-05-04 13:03:24.855367	2026-05-04 17:03:24.855367	123244	123626	Curitiba	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
973	24	14	2026-05-03 13:03:24.855367	2026-05-03 17:03:24.855367	125016	125420	Ponta Grossa	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
974	25	15	2026-05-02 13:03:24.855367	2026-05-02 17:03:24.855367	126788	127160	Cascavel	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
975	26	16	2026-05-01 13:03:24.855367	2026-05-01 17:03:24.855367	128560	128943	Londrina	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
976	27	17	2026-04-30 13:03:24.855367	2026-04-30 17:03:24.855367	130332	130437	Irati	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
977	28	18	2026-04-29 13:03:24.855367	2026-04-29 17:03:24.855367	132104	132460	Prudentópolis	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
978	29	19	2026-04-28 13:03:24.855367	2026-04-28 17:03:24.855367	133876	133960	Campo Mourão	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
979	30	20	2026-04-27 13:03:24.855367	2026-04-27 17:03:24.855367	135648	136004	Paranaguá	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
980	1	1	2026-04-26 13:03:24.855367	2026-04-26 17:03:24.855367	89357	89722	Guarapuava	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
981	2	2	2026-04-25 13:03:24.855367	2026-04-25 17:03:24.855367	91153	91208	Pitanga	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
982	3	3	2026-04-24 13:03:24.855367	2026-04-24 17:03:24.855367	92949	93142	Curitiba	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
983	4	4	2026-04-23 13:03:24.855367	2026-04-23 17:03:24.855367	94745	95005	Ponta Grossa	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
984	5	5	2026-04-22 13:03:24.855367	2026-04-22 17:03:24.855367	96541	96593	Cascavel	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
985	6	6	2026-04-21 13:03:24.855367	2026-04-21 17:03:24.855367	110837	111168	Londrina	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
986	7	7	2026-04-20 13:03:24.855367	2026-04-20 17:03:24.855367	100133	100354	Irati	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
987	8	8	2026-04-19 13:03:24.855367	2026-04-19 17:03:24.855367	101929	102338	Prudentópolis	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
988	9	9	2026-04-18 13:03:24.855367	2026-04-18 17:03:24.855367	138825	138927	Campo Mourão	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
989	10	10	2026-04-17 13:03:24.855367	2026-04-17 17:03:24.855367	166821	166902	Paranaguá	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
990	11	11	2026-04-16 13:03:24.855367	2026-04-16 17:03:24.855367	106837	107023	Guarapuava	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
991	12	12	2026-04-15 13:03:24.855367	2026-04-15 17:03:24.855367	108623	108825	Pitanga	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
992	13	13	2026-04-14 13:03:24.855367	2026-04-14 17:03:24.855367	110409	110826	Curitiba	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
993	14	14	2026-04-13 13:03:24.855367	2026-04-13 17:03:24.855367	112195	112442	Ponta Grossa	Serviço administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
994	15	15	2026-04-12 13:03:24.855367	2026-04-12 17:03:24.855367	113981	114105	Cascavel	Visita técnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
995	16	16	2026-04-11 13:03:24.855367	2026-04-11 17:03:24.855367	115767	115904	Londrina	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
996	17	17	2026-04-10 13:03:24.855367	2026-04-10 17:03:24.855367	117553	117655	Irati	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
997	18	18	2026-04-09 13:03:24.855367	2026-04-09 17:03:24.855367	119339	119650	Prudentópolis	Manutenção em unidade	6e149b4f-121c-40a5-a58d-eb7758f89d69
998	19	19	2026-04-08 13:03:24.855367	2026-04-08 17:03:24.855367	121125	121347	Campo Mourão	Reunião institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
999	20	20	2026-04-07 13:03:24.855367	2026-04-07 17:03:24.855367	122911	123217	Paranaguá	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1000	174	79	2026-03-02 13:04:55.097711	2026-03-02 14:04:55.097711	211908	212005	Pitanga	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1001	86	70	2026-03-21 13:04:55.097711	2026-03-21 20:04:55.097711	137064	137393	Curitiba	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1002	107	100	2025-06-17 13:04:55.097711	2025-06-17 18:04:55.097711	287450	287868	Ponta Grossa	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1003	78	6	2024-06-24 13:04:55.097711	2024-06-24 19:04:55.097711	70966	71360	Cascavel	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1004	128	38	2024-08-09 13:04:55.097711	2024-08-10 01:04:55.097711	29304	29413	Londrina	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1005	27	12	2026-09-05 13:04:55.097711	2026-09-05 15:04:55.097711	102407	102592	Irati	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1006	125	31	2025-10-09 13:04:55.097711	2025-10-10 00:04:55.097711	87672	87793	Prudentopolis	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1007	39	67	2024-09-02 13:04:55.097711	2024-09-02 16:04:55.097711	234713	235327	Campo Mourao	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1008	4	78	2024-10-07 13:04:55.097711	2024-10-07 16:04:55.097711	282093	282616	Paranagua	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1009	47	23	2025-01-07 13:04:55.097711	2025-01-07 22:04:55.097711	145973	146415	Maringa	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1010	124	8	2024-08-31 13:04:55.097711	2024-09-01 01:04:55.097711	285152	285278	Foz do Iguacu	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1011	107	60	2026-09-25 13:04:55.097711	2026-09-25 18:04:55.097711	171750	172167	Guarapuava	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1012	97	16	2025-03-25 13:04:55.097711	2025-03-25 19:04:55.097711	47032	47440	Pitanga	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1013	65	50	2025-07-21 13:04:55.097711	2025-07-21 17:04:55.097711	18828	19055	Curitiba	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1014	88	89	2025-02-24 13:04:55.097711	2025-02-24 14:04:55.097711	135448	136076	Ponta Grossa	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1015	16	14	2024-07-12 13:04:55.097711	2024-07-13 01:04:55.097711	198729	198889	Cascavel	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1016	160	61	2025-11-07 13:04:55.097711	2025-11-07 22:04:55.097711	295717	295887	Londrina	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1017	190	10	2025-05-19 13:04:55.097711	2025-05-19 17:04:55.097711	92995	93379	Irati	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1018	156	39	2025-11-25 13:04:55.097711	2025-11-25 20:04:55.097711	220059	220371	Prudentopolis	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1019	28	74	2025-05-07 13:04:55.097711	2025-05-07 17:04:55.097711	297285	297489	Campo Mourao	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1020	13	51	2024-09-10 13:04:55.097711	2024-09-10 21:04:55.097711	102385	103029	Paranagua	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1021	82	87	2025-12-31 13:04:55.097711	2025-12-31 14:04:55.097711	144629	144968	Maringa	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1022	178	20	2026-08-12 13:04:55.097711	2026-08-12 21:04:55.097711	228833	229123	Foz do Iguacu	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1023	10	40	2026-04-28 13:04:55.097711	2026-04-28 22:04:55.097711	277461	278079	Guarapuava	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1024	178	84	2025-08-05 13:04:55.097711	2025-08-06 01:04:55.097711	20185	20417	Pitanga	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1025	157	25	2024-09-24 13:04:55.097711	2024-09-24 20:04:55.097711	68923	69368	Ponta Grossa	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1026	67	57	2025-06-12 13:04:55.097711	2025-06-12 19:04:55.097711	291606	291773	Cascavel	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1027	134	65	2024-09-30 13:04:55.097711	2024-09-30 23:04:55.097711	261197	261532	Londrina	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1028	82	54	2026-06-05 13:04:55.097711	2026-06-05 21:04:55.097711	80505	80567	Irati	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1029	3	79	2024-11-28 13:04:55.097711	2024-11-29 00:04:55.097711	101131	101211	Prudentopolis	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1030	102	55	2025-12-01 13:04:55.097711	2025-12-01 19:04:55.097711	237977	238623	Campo Mourao	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1031	26	39	2026-05-28 13:04:55.097711	2026-05-28 21:04:55.097711	179102	179180	Paranagua	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1032	84	18	2026-01-01 13:04:55.097711	2026-01-01 15:04:55.097711	237570	237856	Maringa	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1033	135	88	2026-07-12 13:04:55.097711	2026-07-12 21:04:55.097711	19249	19591	Foz do Iguacu	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1034	81	100	2024-11-02 13:04:55.097711	2024-11-03 01:04:55.097711	275381	275986	Pitanga	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1035	119	95	2026-09-30 13:04:55.097711	2026-09-30 19:04:55.097711	185050	185685	Curitiba	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1036	10	4	2025-01-09 13:04:55.097711	2025-01-09 16:04:55.097711	209335	209812	Ponta Grossa	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1037	40	77	2025-01-18 13:04:55.097711	2025-01-18 19:04:55.097711	127058	127381	Cascavel	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1038	183	13	2026-09-02 13:04:55.097711	2026-09-02 15:04:55.097711	290481	290699	Londrina	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1039	94	73	2025-08-26 13:04:55.097711	2025-08-27 01:04:55.097711	78046	78441	Irati	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1040	24	60	2025-07-17 13:04:55.097711	2025-07-17 20:04:55.097711	84788	84887	Prudentopolis	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1041	59	58	2025-02-15 13:04:55.097711	2025-02-15 21:04:55.097711	132002	132530	Campo Mourao	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1042	190	25	2026-02-12 13:04:55.097711	2026-02-13 01:04:55.097711	162199	162802	Paranagua	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1043	91	19	2026-08-22 13:04:55.097711	2026-08-23 00:04:55.097711	203519	203924	Maringa	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1044	68	72	2025-11-19 13:04:55.097711	2025-11-19 20:04:55.097711	93653	94225	Foz do Iguacu	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1045	180	32	2026-09-10 13:04:55.097711	2026-09-10 18:04:55.097711	168408	168518	Guarapuava	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1046	166	15	2025-05-26 13:04:55.097711	2025-05-26 18:04:55.097711	293383	294029	Pitanga	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1047	102	42	2025-04-12 13:04:55.097711	2025-04-12 23:04:55.097711	197384	197603	Curitiba	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1048	54	51	2026-02-22 13:04:55.097711	2026-02-22 17:04:55.097711	202799	202936	Ponta Grossa	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1049	178	3	2024-06-13 13:04:55.097711	2024-06-13 16:04:55.097711	203025	203537	Cascavel	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1050	166	47	2026-04-02 13:04:55.097711	2026-04-02 15:04:55.097711	118146	118460	Londrina	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1051	165	68	2026-06-26 13:04:55.097711	2026-06-26 17:04:55.097711	91217	91393	Prudentopolis	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1052	159	3	2026-08-03 13:04:55.097711	2026-08-03 22:04:55.097711	246981	247170	Campo Mourao	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1053	117	31	2026-07-06 13:04:55.097711	2026-07-07 00:04:55.097711	111304	111891	Paranagua	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1054	104	45	2025-10-05 13:04:55.097711	2025-10-05 19:04:55.097711	74930	74955	Maringa	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1055	166	83	2025-08-18 13:04:55.097711	2025-08-18 19:04:55.097711	127535	128104	Foz do Iguacu	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1056	159	45	2026-05-16 13:04:55.097711	2026-05-16 19:04:55.097711	170473	170851	Guarapuava	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1057	31	95	2024-08-24 13:04:55.097711	2024-08-24 19:04:55.097711	30919	31108	Pitanga	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1058	151	41	2026-09-18 13:04:55.097711	2026-09-18 22:04:55.097711	70614	71119	Curitiba	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1059	175	44	2024-06-10 13:04:55.097711	2024-06-10 15:04:55.097711	96609	96629	Ponta Grossa	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1060	150	46	2026-06-27 13:04:55.097711	2026-06-27 20:04:55.097711	176923	176995	Cascavel	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1061	124	60	2024-10-14 13:04:55.097711	2024-10-14 18:04:55.097711	279852	280140	Londrina	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1062	130	96	2024-08-16 13:04:55.097711	2024-08-17 00:04:55.097711	261326	261708	Irati	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1063	126	46	2026-05-21 13:04:55.097711	2026-05-21 20:04:55.097711	247509	248118	Prudentopolis	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1064	170	32	2026-03-01 13:04:55.097711	2026-03-01 14:04:55.097711	148171	148325	Campo Mourao	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1065	66	21	2025-05-18 13:04:55.097711	2025-05-18 14:04:55.097711	222021	222074	Paranagua	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1066	181	69	2024-07-29 13:04:55.097711	2024-07-29 15:04:55.097711	158555	159163	Maringa	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1067	5	46	2025-06-22 13:04:55.097711	2025-06-22 15:04:55.097711	272225	272253	Foz do Iguacu	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1068	32	13	2026-06-29 13:04:55.097711	2026-06-30 01:04:55.097711	140179	140315	Guarapuava	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1069	56	70	2026-07-07 13:04:55.097711	2026-07-07 22:04:55.097711	37957	38454	Pitanga	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1070	11	30	2024-07-21 13:04:55.097711	2024-07-22 00:04:55.097711	273049	273426	Curitiba	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1071	128	71	2024-06-22 13:04:55.097711	2024-06-22 21:04:55.097711	48349	48621	Ponta Grossa	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1072	45	95	2026-08-27 13:04:55.097711	2026-08-28 00:04:55.097711	191516	191803	Cascavel	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1073	4	8	2025-07-20 13:04:55.097711	2025-07-21 00:04:55.097711	290836	291390	Londrina	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1074	185	61	2025-10-20 13:04:55.097711	2025-10-21 00:04:55.097711	108032	108587	Irati	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1075	3	87	2026-06-24 13:04:55.097711	2026-06-24 23:04:55.097711	247740	247867	Prudentopolis	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1076	78	61	2024-12-26 13:04:55.097711	2024-12-26 19:04:55.097711	227143	227163	Campo Mourao	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1077	111	32	2026-02-07 13:04:55.097711	2026-02-07 23:04:55.097711	150283	150373	Paranagua	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1078	190	67	2024-11-04 13:04:55.097711	2024-11-04 19:04:55.097711	258602	259175	Maringa	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1079	68	99	2026-07-20 13:04:55.097711	2026-07-20 15:04:55.097711	294373	294943	Foz do Iguacu	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1080	176	52	2025-12-29 13:04:55.097711	2025-12-29 14:04:55.097711	115822	115894	Guarapuava	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1081	1	9	2025-12-25 13:04:55.097711	2025-12-25 19:04:55.097711	132483	132507	Curitiba	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1082	59	4	2024-09-24 13:04:55.097711	2024-09-24 20:04:55.097711	177286	177612	Ponta Grossa	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1083	54	45	2025-11-25 13:04:55.097711	2025-11-26 01:04:55.097711	73390	73678	Cascavel	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1084	180	65	2026-08-27 13:04:55.097711	2026-08-27 15:04:55.097711	276255	276689	Londrina	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1085	25	48	2024-10-24 13:04:55.097711	2024-10-24 23:04:55.097711	275044	275138	Irati	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1086	124	80	2026-01-23 13:04:55.097711	2026-01-23 18:04:55.097711	204062	204112	Prudentopolis	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1087	6	84	2026-10-20 13:04:55.097711	2026-10-20 16:04:55.097711	84298	84680	Campo Mourao	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1088	164	96	2025-11-15 13:04:55.097711	2025-11-16 00:04:55.097711	266955	267427	Paranagua	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1089	63	29	2025-12-21 13:04:55.097711	2025-12-21 14:04:55.097711	251265	251418	Maringa	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1090	59	96	2025-04-25 13:04:55.097711	2025-04-25 16:04:55.097711	193149	193252	Foz do Iguacu	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1091	154	60	2026-04-15 13:04:55.097711	2026-04-15 23:04:55.097711	114559	115074	Guarapuava	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1092	16	88	2025-10-03 13:04:55.097711	2025-10-03 15:04:55.097711	51480	52056	Pitanga	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1093	146	33	2025-12-11 13:04:55.097711	2025-12-12 01:04:55.097711	48312	48815	Curitiba	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1094	42	12	2025-07-15 13:04:55.097711	2025-07-15 16:04:55.097711	85407	85901	Ponta Grossa	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1095	59	82	2025-11-04 13:04:55.097711	2025-11-04 20:04:55.097711	66268	66414	Cascavel	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1096	150	4	2025-06-04 13:04:55.097711	2025-06-04 20:04:55.097711	46183	46661	Londrina	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1097	6	13	2024-11-22 13:04:55.097711	2024-11-23 01:04:55.097711	257277	257332	Irati	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1098	127	7	2026-10-13 13:04:55.097711	2026-10-13 18:04:55.097711	132487	132706	Prudentopolis	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1099	105	46	2025-01-06 13:04:55.097711	2025-01-07 00:04:55.097711	221759	222291	Campo Mourao	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1100	149	45	2024-07-12 13:04:55.097711	2024-07-12 23:04:55.097711	261605	262153	Paranagua	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1101	71	14	2025-12-24 13:04:55.097711	2025-12-24 16:04:55.097711	46089	46485	Maringa	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1102	87	28	2026-04-23 13:04:55.097711	2026-04-24 00:04:55.097711	147237	147721	Foz do Iguacu	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1103	131	98	2024-08-24 13:04:55.097711	2024-08-24 19:04:55.097711	153487	153836	Guarapuava	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1104	38	31	2024-09-22 13:04:55.097711	2024-09-23 01:04:55.097711	49168	49695	Pitanga	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1105	91	86	2026-04-29 13:04:55.097711	2026-04-29 20:04:55.097711	98709	99331	Curitiba	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1106	186	71	2026-07-21 13:04:55.097711	2026-07-21 18:04:55.097711	84315	84781	Ponta Grossa	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1107	23	69	2026-04-15 13:04:55.097711	2026-04-15 21:04:55.097711	172859	173030	Londrina	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1108	110	15	2026-01-01 13:04:55.097711	2026-01-01 15:04:55.097711	83863	84198	Irati	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1109	180	52	2025-04-07 13:04:55.097711	2025-04-07 14:04:55.097711	141523	141789	Prudentopolis	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1110	179	74	2024-07-03 13:04:55.097711	2024-07-03 20:04:55.097711	194447	194572	Campo Mourao	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1111	77	76	2025-08-22 13:04:55.097711	2025-08-22 17:04:55.097711	217141	217301	Paranagua	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1112	29	32	2024-12-11 13:04:55.097711	2024-12-12 01:04:55.097711	297157	297292	Maringa	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1113	187	68	2026-06-13 13:04:55.097711	2026-06-13 18:04:55.097711	241575	242178	Foz do Iguacu	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1114	23	16	2026-01-21 13:04:55.097711	2026-01-21 16:04:55.097711	285529	286179	Guarapuava	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1115	142	15	2025-10-22 13:04:55.097711	2025-10-23 00:04:55.097711	292026	292314	Pitanga	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1116	173	52	2026-04-08 13:04:55.097711	2026-04-08 20:04:55.097711	243478	243948	Curitiba	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1117	8	86	2025-10-31 13:04:55.097711	2025-10-31 17:04:55.097711	241644	241942	Ponta Grossa	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1118	171	20	2026-06-23 13:04:55.097711	2026-06-23 20:04:55.097711	178446	178824	Cascavel	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1119	142	71	2025-08-27 13:04:55.097711	2025-08-28 00:04:55.097711	214480	215076	Londrina	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1120	18	21	2025-03-12 13:04:55.097711	2025-03-12 22:04:55.097711	87271	87501	Irati	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1121	150	69	2025-07-02 13:04:55.097711	2025-07-02 14:04:55.097711	115573	116127	Prudentopolis	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1122	46	91	2024-08-02 13:04:55.097711	2024-08-02 22:04:55.097711	276268	276330	Campo Mourao	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1123	142	77	2026-07-14 13:04:55.097711	2026-07-14 23:04:55.097711	67966	68380	Paranagua	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1124	59	34	2026-01-10 13:04:55.097711	2026-01-10 14:04:55.097711	144290	144322	Maringa	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1125	47	90	2026-04-08 13:04:55.097711	2026-04-08 17:04:55.097711	121437	121578	Foz do Iguacu	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1126	63	55	2025-06-05 13:04:55.097711	2025-06-05 23:04:55.097711	237200	237697	Guarapuava	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1127	40	9	2026-03-21 13:04:55.097711	2026-03-21 20:04:55.097711	132824	133443	Pitanga	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1128	134	7	2024-11-11 13:04:55.097711	2024-11-11 17:04:55.097711	168350	168923	Curitiba	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1129	149	93	2025-12-15 13:04:55.097711	2025-12-15 20:04:55.097711	80954	81529	Ponta Grossa	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1130	160	74	2025-12-05 13:04:55.097711	2025-12-05 16:04:55.097711	261156	261666	Cascavel	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1131	164	32	2025-04-20 13:04:55.097711	2025-04-20 18:04:55.097711	295564	295648	Londrina	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1132	107	29	2025-11-28 13:04:55.097711	2025-11-29 00:04:55.097711	119618	120038	Irati	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1133	3	49	2025-06-28 13:04:55.097711	2025-06-28 17:04:55.097711	145333	145830	Prudentopolis	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1134	11	97	2026-09-01 13:04:55.097711	2026-09-01 21:04:55.097711	221731	222353	Campo Mourao	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1135	84	61	2026-01-05 13:04:55.097711	2026-01-05 21:04:55.097711	207509	207938	Paranagua	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1136	173	96	2026-03-22 13:04:55.097711	2026-03-22 22:04:55.097711	158339	158566	Maringa	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1137	67	98	2024-10-19 13:04:55.097711	2024-10-19 19:04:55.097711	45696	45891	Foz do Iguacu	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1138	51	72	2026-03-01 13:04:55.097711	2026-03-01 16:04:55.097711	18430	19034	Guarapuava	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1139	106	60	2025-02-12 13:04:55.097711	2025-02-12 22:04:55.097711	102462	102795	Pitanga	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1140	71	33	2026-06-20 13:04:55.097711	2026-06-20 20:04:55.097711	111985	112573	Curitiba	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1141	13	20	2026-05-10 13:04:55.097711	2026-05-10 17:04:55.097711	120575	121065	Ponta Grossa	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1142	97	36	2025-12-15 13:04:55.097711	2025-12-15 22:04:55.097711	169147	169579	Cascavel	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1143	37	11	2026-03-29 13:04:55.097711	2026-03-29 17:04:55.097711	202458	203049	Londrina	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1144	160	10	2025-11-07 13:04:55.097711	2025-11-07 14:04:55.097711	54511	54661	Irati	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1145	118	57	2024-06-20 13:04:55.097711	2024-06-21 00:04:55.097711	49187	49409	Prudentopolis	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1146	154	43	2024-05-24 13:04:55.097711	2024-05-24 22:04:55.097711	42460	43110	Campo Mourao	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1147	116	95	2024-08-11 13:04:55.097711	2024-08-11 16:04:55.097711	200721	200844	Paranagua	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1148	132	86	2026-02-12 13:04:55.097711	2026-02-12 15:04:55.097711	132765	133285	Maringa	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1149	103	54	2024-12-11 13:04:55.097711	2024-12-12 00:04:55.097711	103688	103899	Foz do Iguacu	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1150	25	90	2026-08-30 13:04:55.097711	2026-08-30 14:04:55.097711	270717	270846	Guarapuava	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1151	183	7	2025-04-15 13:04:55.097711	2025-04-15 18:04:55.097711	224798	225050	Curitiba	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1152	151	19	2025-11-26 13:04:55.097711	2025-11-26 20:04:55.097711	65226	65667	Ponta Grossa	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1153	41	68	2024-10-14 13:04:55.097711	2024-10-14 22:04:55.097711	20121	20426	Cascavel	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1154	1	27	2026-05-19 13:04:55.097711	2026-05-19 22:04:55.097711	84628	85103	Londrina	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1155	31	17	2024-06-06 13:04:55.097711	2024-06-06 17:04:55.097711	195757	195902	Irati	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1156	21	74	2026-06-11 13:04:55.097711	2026-06-12 01:04:55.097711	154888	155148	Prudentopolis	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1157	100	75	2026-10-31 13:04:55.097711	2026-10-31 19:04:55.097711	237862	237914	Campo Mourao	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1158	10	5	2026-07-24 13:04:55.097711	2026-07-24 19:04:55.097711	77878	78311	Paranagua	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1159	184	17	2025-03-06 13:04:55.097711	2025-03-06 23:04:55.097711	117464	117557	Maringa	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1160	161	48	2024-06-07 13:04:55.097711	2024-06-07 21:04:55.097711	100635	100719	Foz do Iguacu	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1161	108	47	2025-12-04 13:04:55.097711	2025-12-04 18:04:55.097711	61277	61689	Guarapuava	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1162	37	85	2026-04-05 13:04:55.097711	2026-04-05 16:04:55.097711	273607	274084	Pitanga	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1163	72	25	2024-11-08 13:04:55.097711	2024-11-09 01:04:55.097711	298533	298662	Curitiba	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1164	89	35	2026-04-04 13:04:55.097711	2026-04-04 20:04:55.097711	34156	34190	Ponta Grossa	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1165	9	37	2024-10-28 13:04:55.097711	2024-10-28 14:04:55.097711	31636	31989	Cascavel	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1166	42	1	2026-05-26 13:04:55.097711	2026-05-26 21:04:55.097711	206598	206774	Londrina	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1167	95	94	2025-05-20 13:04:55.097711	2025-05-20 22:04:55.097711	139721	139923	Irati	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1168	88	27	2024-07-07 13:04:55.097711	2024-07-07 14:04:55.097711	296494	296552	Prudentopolis	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1169	19	49	2024-12-08 13:04:55.097711	2024-12-08 19:04:55.097711	290331	290598	Campo Mourao	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1170	135	49	2025-09-17 13:04:55.097711	2025-09-17 17:04:55.097711	131917	132345	Paranagua	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1171	72	87	2026-07-02 13:04:55.097711	2026-07-02 15:04:55.097711	117519	117696	Maringa	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1172	108	19	2026-09-08 13:04:55.097711	2026-09-08 23:04:55.097711	92348	92400	Guarapuava	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1173	8	40	2025-05-13 13:04:55.097711	2025-05-13 21:04:55.097711	168043	168506	Pitanga	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1174	184	15	2024-07-13 13:04:55.097711	2024-07-13 23:04:55.097711	257360	257755	Curitiba	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1175	130	17	2025-03-24 13:04:55.097711	2025-03-24 23:04:55.097711	162655	163107	Ponta Grossa	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1176	105	66	2026-09-04 13:04:55.097711	2026-09-04 23:04:55.097711	149550	149567	Cascavel	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1177	171	91	2025-10-31 13:04:55.097711	2025-10-31 20:04:55.097711	142418	143007	Londrina	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1178	185	67	2025-08-18 13:04:55.097711	2025-08-18 22:04:55.097711	148108	148167	Irati	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1179	164	40	2025-02-23 13:04:55.097711	2025-02-23 19:04:55.097711	129886	130163	Prudentopolis	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1180	118	59	2025-10-20 13:04:55.097711	2025-10-20 20:04:55.097711	219874	220060	Campo Mourao	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1181	55	58	2025-10-19 13:04:55.097711	2025-10-19 23:04:55.097711	18594	18773	Paranagua	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1182	38	100	2024-12-17 13:04:55.097711	2024-12-17 18:04:55.097711	278919	278995	Maringa	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1183	40	34	2025-08-25 13:04:55.097711	2025-08-25 16:04:55.097711	271807	272146	Foz do Iguacu	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1184	43	92	2026-02-04 13:04:55.097711	2026-02-05 00:04:55.097711	64566	64802	Pitanga	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1185	112	11	2026-06-05 13:04:55.097711	2026-06-05 16:04:55.097711	159702	160350	Curitiba	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1186	12	30	2025-12-28 13:04:55.097711	2025-12-28 18:04:55.097711	20683	20955	Ponta Grossa	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1187	144	21	2026-02-07 13:04:55.097711	2026-02-07 14:04:55.097711	231222	231505	Cascavel	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1188	131	28	2025-11-10 13:04:55.097711	2025-11-10 14:04:55.097711	168937	169116	Londrina	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1189	146	74	2024-10-14 13:04:55.097711	2024-10-14 20:04:55.097711	234541	234810	Prudentopolis	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1190	73	50	2026-08-19 13:04:55.097711	2026-08-20 00:04:55.097711	123285	123682	Campo Mourao	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1191	80	5	2025-05-15 13:04:55.097711	2025-05-15 20:04:55.097711	40753	41311	Paranagua	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1192	8	51	2025-01-07 13:04:55.097711	2025-01-08 00:04:55.097711	172099	172207	Maringa	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1193	155	84	2025-04-19 13:04:55.097711	2025-04-19 17:04:55.097711	120441	120868	Foz do Iguacu	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1194	150	18	2025-06-02 13:04:55.097711	2025-06-02 23:04:55.097711	289790	290341	Guarapuava	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1195	81	24	2024-06-10 13:04:55.097711	2024-06-10 21:04:55.097711	57103	57332	Pitanga	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1196	11	85	2026-06-30 13:04:55.097711	2026-06-30 23:04:55.097711	142454	143008	Curitiba	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1197	22	82	2025-10-10 13:04:55.097711	2025-10-10 19:04:55.097711	104009	104403	Ponta Grossa	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1198	149	66	2026-08-25 13:04:55.097711	2026-08-26 00:04:55.097711	143622	144121	Cascavel	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1199	54	74	2024-06-28 13:04:55.097711	2024-06-28 20:04:55.097711	52659	52877	Londrina	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1200	86	99	2025-09-08 13:04:55.097711	2025-09-08 14:04:55.097711	92619	93142	Irati	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1201	110	54	2024-10-11 13:04:55.097711	2024-10-11 16:04:55.097711	200711	200896	Prudentopolis	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1202	109	44	2026-04-02 13:04:55.097711	2026-04-02 21:04:55.097711	160483	160935	Campo Mourao	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1203	110	63	2025-01-03 13:04:55.097711	2025-01-04 00:04:55.097711	298497	298663	Paranagua	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1204	42	10	2026-04-19 13:04:55.097711	2026-04-20 00:04:55.097711	77572	77660	Maringa	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1205	62	9	2025-05-20 13:04:55.097711	2025-05-20 16:04:55.097711	286044	286626	Guarapuava	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1206	49	23	2026-02-26 13:04:55.097711	2026-02-26 16:04:55.097711	24163	24799	Pitanga	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1207	76	83	2025-06-03 13:04:55.097711	2025-06-03 15:04:55.097711	44869	45026	Curitiba	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1208	127	52	2024-12-03 13:04:55.097711	2024-12-03 22:04:55.097711	121888	122017	Cascavel	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1209	22	76	2025-03-04 13:04:55.097711	2025-03-04 19:04:55.097711	113020	113406	Londrina	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1210	55	96	2026-09-27 13:04:55.097711	2026-09-28 00:04:55.097711	123793	124299	Irati	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1211	152	12	2026-10-09 13:04:55.097711	2026-10-09 14:04:55.097711	222170	222422	Prudentopolis	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1212	92	53	2025-10-24 13:04:55.097711	2025-10-24 17:04:55.097711	69375	70005	Campo Mourao	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1213	100	61	2026-09-03 13:04:55.097711	2026-09-03 22:04:55.097711	133042	133457	Paranagua	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1214	58	30	2024-12-30 13:04:55.097711	2024-12-31 01:04:55.097711	296562	296939	Maringa	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1215	65	29	2026-05-21 13:04:55.097711	2026-05-22 01:04:55.097711	274203	274715	Foz do Iguacu	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1216	149	76	2025-07-12 13:04:55.097711	2025-07-12 23:04:55.097711	170067	170555	Guarapuava	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1217	138	45	2026-06-28 13:04:55.097711	2026-06-28 18:04:55.097711	73012	73552	Pitanga	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1218	155	48	2025-07-09 13:04:55.097711	2025-07-10 01:04:55.097711	282733	282784	Curitiba	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1219	145	60	2026-09-20 13:04:55.097711	2026-09-20 22:04:55.097711	196712	196874	Ponta Grossa	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1220	66	29	2026-01-06 13:04:55.097711	2026-01-06 22:04:55.097711	264125	264214	Cascavel	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1221	20	75	2025-03-05 13:04:55.097711	2025-03-05 18:04:55.097711	31953	32050	Londrina	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1222	22	8	2025-11-08 13:04:55.097711	2025-11-08 22:04:55.097711	217634	217977	Irati	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1223	115	15	2024-10-21 13:04:55.097711	2024-10-22 00:04:55.097711	29952	30181	Prudentopolis	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1224	29	23	2025-04-26 13:04:55.097711	2025-04-26 20:04:55.097711	40149	40232	Campo Mourao	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1225	1	54	2026-01-01 13:04:55.097711	2026-01-01 17:04:55.097711	70464	70906	Paranagua	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1226	163	12	2026-06-15 13:04:55.097711	2026-06-15 16:04:55.097711	76607	77069	Maringa	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1227	182	35	2026-07-17 13:04:55.097711	2026-07-17 22:04:55.097711	125770	125830	Foz do Iguacu	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1228	66	94	2026-07-22 13:04:55.097711	2026-07-22 19:04:55.097711	117288	117650	Guarapuava	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1229	28	87	2025-07-10 13:04:55.097711	2025-07-11 00:04:55.097711	287300	287801	Pitanga	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1230	28	45	2026-02-27 13:04:55.097711	2026-02-27 16:04:55.097711	225964	226334	Curitiba	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1231	115	20	2026-05-30 13:04:55.097711	2026-05-30 22:04:55.097711	129595	129640	Ponta Grossa	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1232	45	31	2025-12-24 13:04:55.097711	2025-12-24 22:04:55.097711	281367	281907	Cascavel	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1233	85	69	2025-08-07 13:04:55.097711	2025-08-07 21:04:55.097711	130827	130896	Irati	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1234	12	18	2025-08-25 13:04:55.097711	2025-08-26 01:04:55.097711	161320	161501	Prudentopolis	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1235	104	41	2026-04-07 13:04:55.097711	2026-04-07 20:04:55.097711	139193	139427	Campo Mourao	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1236	35	40	2025-06-27 13:04:55.097711	2025-06-27 20:04:55.097711	250105	250153	Paranagua	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1237	131	65	2026-10-06 13:04:55.097711	2026-10-07 00:04:55.097711	223341	223511	Maringa	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1238	185	2	2026-07-01 13:04:55.097711	2026-07-01 19:04:55.097711	76472	76898	Foz do Iguacu	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1239	88	73	2024-06-14 13:04:55.097711	2024-06-14 14:04:55.097711	38404	38616	Guarapuava	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1240	183	97	2024-10-18 13:04:55.097711	2024-10-18 17:04:55.097711	209323	209502	Pitanga	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1241	76	100	2024-11-27 13:04:55.097711	2024-11-27 23:04:55.097711	18988	19121	Curitiba	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1242	86	52	2025-09-08 13:04:55.097711	2025-09-09 01:04:55.097711	53477	53795	Ponta Grossa	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1243	104	30	2025-10-11 13:04:55.097711	2025-10-11 14:04:55.097711	236078	236670	Cascavel	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1244	140	26	2026-05-12 13:04:55.097711	2026-05-12 16:04:55.097711	248275	248451	Londrina	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1245	149	5	2024-11-09 13:04:55.097711	2024-11-09 14:04:55.097711	156673	157053	Irati	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1246	153	96	2024-10-05 13:04:55.097711	2024-10-05 17:04:55.097711	255904	256093	Prudentopolis	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1247	187	100	2025-07-02 13:04:55.097711	2025-07-03 00:04:55.097711	54910	55318	Campo Mourao	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1248	137	5	2026-05-14 13:04:55.097711	2026-05-15 00:04:55.097711	299529	299558	Paranagua	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1249	102	36	2026-06-25 13:04:55.097711	2026-06-25 19:04:55.097711	113174	113190	Maringa	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1250	36	37	2026-10-18 13:04:55.097711	2026-10-18 20:04:55.097711	165737	165773	Guarapuava	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1251	157	89	2025-10-09 13:04:55.097711	2025-10-09 22:04:55.097711	219088	219533	Pitanga	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1252	141	3	2024-07-28 13:04:55.097711	2024-07-28 19:04:55.097711	123075	123635	Curitiba	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1253	124	57	2026-06-17 13:04:55.097711	2026-06-17 20:04:55.097711	147932	148237	Ponta Grossa	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1254	37	94	2025-12-04 13:04:55.097711	2025-12-05 00:04:55.097711	53035	53060	Cascavel	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1255	178	73	2025-09-20 13:04:55.097711	2025-09-20 23:04:55.097711	136656	137069	Londrina	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1256	21	36	2025-12-06 13:04:55.097711	2025-12-06 23:04:55.097711	108541	108605	Irati	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1257	61	11	2024-09-05 13:04:55.097711	2024-09-05 22:04:55.097711	42285	42526	Prudentopolis	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1258	15	32	2026-03-07 13:04:55.097711	2026-03-07 17:04:55.097711	228374	228692	Campo Mourao	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1259	133	1	2024-06-24 13:04:55.097711	2024-06-24 23:04:55.097711	68502	68623	Paranagua	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1260	60	86	2024-08-04 13:04:55.097711	2024-08-04 17:04:55.097711	136276	136616	Maringa	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1261	68	3	2026-03-13 13:04:55.097711	2026-03-14 00:04:55.097711	97550	97756	Foz do Iguacu	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1262	168	71	2024-09-07 13:04:55.097711	2024-09-07 21:04:55.097711	172854	173120	Guarapuava	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1263	50	100	2025-07-23 13:04:55.097711	2025-07-23 18:04:55.097711	219688	220277	Pitanga	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1264	66	79	2024-09-01 13:04:55.097711	2024-09-01 16:04:55.097711	53192	53742	Curitiba	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1265	165	3	2026-07-12 13:04:55.097711	2026-07-12 23:04:55.097711	66120	66363	Ponta Grossa	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1266	60	65	2025-09-29 13:04:55.097711	2025-09-29 20:04:55.097711	223462	223908	Cascavel	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1267	7	54	2024-08-12 13:04:55.097711	2024-08-12 22:04:55.097711	134948	135551	Londrina	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1268	62	48	2026-04-23 13:04:55.097711	2026-04-23 20:04:55.097711	107023	107060	Irati	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1269	15	56	2026-05-23 13:04:55.097711	2026-05-23 23:04:55.097711	278660	279287	Prudentopolis	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1270	122	89	2025-06-28 13:04:55.097711	2025-06-28 19:04:55.097711	181018	181543	Campo Mourao	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1271	139	97	2024-09-01 13:04:55.097711	2024-09-01 17:04:55.097711	140286	140438	Paranagua	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1272	186	51	2025-11-22 13:04:55.097711	2025-11-22 23:04:55.097711	174378	174548	Maringa	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1273	118	79	2026-05-04 13:04:55.097711	2026-05-04 22:04:55.097711	73466	73940	Foz do Iguacu	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1274	80	15	2024-11-05 13:04:55.097711	2024-11-06 01:04:55.097711	274982	275024	Guarapuava	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1275	99	22	2025-02-07 13:04:55.097711	2025-02-07 20:04:55.097711	286690	286897	Pitanga	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1276	141	54	2026-07-03 13:04:55.097711	2026-07-04 01:04:55.097711	261069	261385	Curitiba	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1277	13	5	2025-09-05 13:04:55.097711	2025-09-06 00:04:55.097711	84553	84573	Ponta Grossa	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
1278	20	62	2024-08-13 13:04:55.097711	2024-08-13 23:04:55.097711	229805	230445	Cascavel	Atendimento externo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1279	130	79	2026-09-10 13:04:55.097711	2026-09-10 17:04:55.097711	78732	78902	Londrina	Reuniao institucional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1280	75	41	2026-10-30 13:04:55.097711	2026-10-30 18:04:55.097711	262008	262236	Irati	Transporte de equipe	6e149b4f-121c-40a5-a58d-eb7758f89d69
1281	157	59	2025-07-24 13:04:55.097711	2025-07-24 17:04:55.097711	189940	190282	Prudentopolis	Apoio operacional	6e149b4f-121c-40a5-a58d-eb7758f89d69
1282	184	2	2025-11-26 13:04:55.097711	2025-11-26 21:04:55.097711	183881	184275	Campo Mourao	Transporte de materiais	6e149b4f-121c-40a5-a58d-eb7758f89d69
1283	43	79	2026-08-06 13:04:55.097711	2026-08-06 20:04:55.097711	278962	279225	Paranagua	Servico administrativo	6e149b4f-121c-40a5-a58d-eb7758f89d69
1284	55	58	2024-10-12 13:04:55.097711	2024-10-12 21:04:55.097711	299155	299402	Maringa	Visita tecnica	6e149b4f-121c-40a5-a58d-eb7758f89d69
1285	181	18	2024-05-24 13:04:55.097711	2024-05-25 00:04:55.097711	62263	62671	Foz do Iguacu	Entrega de documentos	6e149b4f-121c-40a5-a58d-eb7758f89d69
\.


--
-- TOC entry 3625 (class 0 OID 57384)
-- Dependencies: 239
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: professor_bd
--

COPY public.migrations (id, migration, batch) FROM stdin;
\.


--
-- TOC entry 3694 (class 0 OID 0)
-- Dependencies: 227
-- Name: abastecimentos_id_abastecimento_seq; Type: SEQUENCE SET; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

SELECT pg_catalog.setval('gabriel_trabalho_bd.abastecimentos_id_abastecimento_seq', 2751, true);


--
-- TOC entry 3695 (class 0 OID 0)
-- Dependencies: 231
-- Name: despesas_id_despesa_seq; Type: SEQUENCE SET; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

SELECT pg_catalog.setval('gabriel_trabalho_bd.despesas_id_despesa_seq', 1027, true);


--
-- TOC entry 3696 (class 0 OID 0)
-- Dependencies: 240
-- Name: historico_status_veiculo_id_historico_seq; Type: SEQUENCE SET; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

SELECT pg_catalog.setval('gabriel_trabalho_bd.historico_status_veiculo_id_historico_seq', 303, true);


--
-- TOC entry 3697 (class 0 OID 0)
-- Dependencies: 225
-- Name: hodometros_id_hodometro_seq; Type: SEQUENCE SET; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

SELECT pg_catalog.setval('gabriel_trabalho_bd.hodometros_id_hodometro_seq', 1947, true);


--
-- TOC entry 3698 (class 0 OID 0)
-- Dependencies: 229
-- Name: manutencoes_id_manutencao_seq; Type: SEQUENCE SET; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

SELECT pg_catalog.setval('gabriel_trabalho_bd.manutencoes_id_manutencao_seq', 860, true);


--
-- TOC entry 3699 (class 0 OID 0)
-- Dependencies: 223
-- Name: motoristas_id_motorista_seq; Type: SEQUENCE SET; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

SELECT pg_catalog.setval('gabriel_trabalho_bd.motoristas_id_motorista_seq', 150, true);


--
-- TOC entry 3700 (class 0 OID 0)
-- Dependencies: 221
-- Name: veiculos_id_veiculo_seq; Type: SEQUENCE SET; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

SELECT pg_catalog.setval('gabriel_trabalho_bd.veiculos_id_veiculo_seq', 190, true);


--
-- TOC entry 3701 (class 0 OID 0)
-- Dependencies: 233
-- Name: viagens_id_viagem_seq; Type: SEQUENCE SET; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

SELECT pg_catalog.setval('gabriel_trabalho_bd.viagens_id_viagem_seq', 1285, true);


--
-- TOC entry 3702 (class 0 OID 0)
-- Dependencies: 238
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: professor_bd
--

SELECT pg_catalog.setval('public.migrations_id_seq', 1, false);


--
-- TOC entry 3410 (class 2606 OID 32834)
-- Name: abastecimentos abastecimentos_pkey; Type: CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.abastecimentos
    ADD CONSTRAINT abastecimentos_pkey PRIMARY KEY (id_abastecimento);


--
-- TOC entry 3418 (class 2606 OID 32870)
-- Name: despesas despesas_pkey; Type: CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.despesas
    ADD CONSTRAINT despesas_pkey PRIMARY KEY (id_despesa);


--
-- TOC entry 3429 (class 2606 OID 65549)
-- Name: historico_status_veiculo historico_status_veiculo_pkey; Type: CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.historico_status_veiculo
    ADD CONSTRAINT historico_status_veiculo_pkey PRIMARY KEY (id_historico);


--
-- TOC entry 3407 (class 2606 OID 32814)
-- Name: hodometros hodometros_pkey; Type: CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.hodometros
    ADD CONSTRAINT hodometros_pkey PRIMARY KEY (id_hodometro);


--
-- TOC entry 3416 (class 2606 OID 32853)
-- Name: manutencoes manutencoes_pkey; Type: CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.manutencoes
    ADD CONSTRAINT manutencoes_pkey PRIMARY KEY (id_manutencao);


--
-- TOC entry 3395 (class 2606 OID 24584)
-- Name: modalidade modalidade_pkey; Type: CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.modalidade
    ADD CONSTRAINT modalidade_pkey PRIMARY KEY (id);


--
-- TOC entry 3403 (class 2606 OID 32798)
-- Name: motoristas motoristas_cnh_key; Type: CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.motoristas
    ADD CONSTRAINT motoristas_cnh_key UNIQUE (cnh);


--
-- TOC entry 3405 (class 2606 OID 32796)
-- Name: motoristas motoristas_pkey; Type: CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.motoristas
    ADD CONSTRAINT motoristas_pkey PRIMARY KEY (id_motorista);


--
-- TOC entry 3398 (class 2606 OID 32781)
-- Name: veiculos veiculos_pkey; Type: CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.veiculos
    ADD CONSTRAINT veiculos_pkey PRIMARY KEY (id_veiculo);


--
-- TOC entry 3400 (class 2606 OID 32783)
-- Name: veiculos veiculos_placa_key; Type: CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.veiculos
    ADD CONSTRAINT veiculos_placa_key UNIQUE (placa);


--
-- TOC entry 3425 (class 2606 OID 32888)
-- Name: viagens viagens_pkey; Type: CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.viagens
    ADD CONSTRAINT viagens_pkey PRIMARY KEY (id_viagem);


--
-- TOC entry 3427 (class 2606 OID 57392)
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: professor_bd
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 3411 (class 1259 OID 32902)
-- Name: idx_abastecimentos_id_veiculo; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_abastecimentos_id_veiculo ON gabriel_trabalho_bd.abastecimentos USING btree (id_veiculo);


--
-- TOC entry 3412 (class 1259 OID 65569)
-- Name: idx_abastecimentos_veiculo_data; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_abastecimentos_veiculo_data ON gabriel_trabalho_bd.abastecimentos USING btree (id_veiculo, data_abastecimento DESC);


--
-- TOC entry 3419 (class 1259 OID 65557)
-- Name: idx_despesas_id_veiculo; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_despesas_id_veiculo ON gabriel_trabalho_bd.despesas USING btree (id_veiculo);


--
-- TOC entry 3430 (class 1259 OID 65555)
-- Name: idx_historico_status_id_veiculo; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_historico_status_id_veiculo ON gabriel_trabalho_bd.historico_status_veiculo USING btree (id_veiculo);


--
-- TOC entry 3408 (class 1259 OID 65556)
-- Name: idx_hodometros_id_veiculo; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_hodometros_id_veiculo ON gabriel_trabalho_bd.hodometros USING btree (id_veiculo);


--
-- TOC entry 3413 (class 1259 OID 32903)
-- Name: idx_manutencoes_id_veiculo; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_manutencoes_id_veiculo ON gabriel_trabalho_bd.manutencoes USING btree (id_veiculo);


--
-- TOC entry 3414 (class 1259 OID 65573)
-- Name: idx_manutencoes_veiculo_data; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_manutencoes_veiculo_data ON gabriel_trabalho_bd.manutencoes USING btree (id_veiculo, data_manutencao DESC);


--
-- TOC entry 3401 (class 1259 OID 65572)
-- Name: idx_motoristas_status; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_motoristas_status ON gabriel_trabalho_bd.motoristas USING btree (status);


--
-- TOC entry 3435 (class 1259 OID 73769)
-- Name: idx_mv_desempenho_motoristas_cnh; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_mv_desempenho_motoristas_cnh ON gabriel_trabalho_bd.mv_desempenho_motoristas USING btree (situacao_cnh);


--
-- TOC entry 3433 (class 1259 OID 73755)
-- Name: idx_mv_gastos_mensais_mes; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_mv_gastos_mensais_mes ON gabriel_trabalho_bd.mv_gastos_mensais USING btree (mes);


--
-- TOC entry 3431 (class 1259 OID 73741)
-- Name: idx_mv_gastos_veiculos_total; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_mv_gastos_veiculos_total ON gabriel_trabalho_bd.mv_gastos_veiculos USING btree (gasto_total DESC);


--
-- TOC entry 3396 (class 1259 OID 65571)
-- Name: idx_veiculos_status; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_veiculos_status ON gabriel_trabalho_bd.veiculos USING btree (status);


--
-- TOC entry 3420 (class 1259 OID 65570)
-- Name: idx_viagens_em_andamento; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE UNIQUE INDEX idx_viagens_em_andamento ON gabriel_trabalho_bd.viagens USING btree (id_veiculo) WHERE (data_retorno IS NULL);


--
-- TOC entry 3421 (class 1259 OID 81927)
-- Name: idx_viagens_id_modalidade; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_viagens_id_modalidade ON gabriel_trabalho_bd.viagens USING btree (id_modalidade);


--
-- TOC entry 3422 (class 1259 OID 32904)
-- Name: idx_viagens_id_motorista; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_viagens_id_motorista ON gabriel_trabalho_bd.viagens USING btree (id_motorista);


--
-- TOC entry 3423 (class 1259 OID 32905)
-- Name: idx_viagens_id_veiculo; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_viagens_id_veiculo ON gabriel_trabalho_bd.viagens USING btree (id_veiculo);


--
-- TOC entry 3437 (class 1259 OID 73782)
-- Name: uq_mv_consumo_veiculos; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE UNIQUE INDEX uq_mv_consumo_veiculos ON gabriel_trabalho_bd.mv_consumo_veiculos USING btree (id_veiculo);


--
-- TOC entry 3438 (class 1259 OID 73807)
-- Name: uq_mv_dashboard_frota; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE UNIQUE INDEX uq_mv_dashboard_frota ON gabriel_trabalho_bd.mv_dashboard_frota USING btree (id);


--
-- TOC entry 3436 (class 1259 OID 73768)
-- Name: uq_mv_desempenho_motoristas; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE UNIQUE INDEX uq_mv_desempenho_motoristas ON gabriel_trabalho_bd.mv_desempenho_motoristas USING btree (id_motorista);


--
-- TOC entry 3434 (class 1259 OID 73754)
-- Name: uq_mv_gastos_mensais; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE UNIQUE INDEX uq_mv_gastos_mensais ON gabriel_trabalho_bd.mv_gastos_mensais USING btree (id_veiculo, mes, categoria);


--
-- TOC entry 3432 (class 1259 OID 73740)
-- Name: uq_mv_gastos_veiculos; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE UNIQUE INDEX uq_mv_gastos_veiculos ON gabriel_trabalho_bd.mv_gastos_veiculos USING btree (id_veiculo);


--
-- TOC entry 3449 (class 2620 OID 65586)
-- Name: abastecimentos trg_abastecimento_valida; Type: TRIGGER; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE TRIGGER trg_abastecimento_valida BEFORE INSERT OR UPDATE ON gabriel_trabalho_bd.abastecimentos FOR EACH ROW EXECUTE FUNCTION gabriel_trabalho_bd.tg_fn_abastecimento_valida();


--
-- TOC entry 3450 (class 2620 OID 65592)
-- Name: abastecimentos trg_km_abastecimentos; Type: TRIGGER; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE TRIGGER trg_km_abastecimentos AFTER INSERT ON gabriel_trabalho_bd.abastecimentos FOR EACH ROW EXECUTE FUNCTION gabriel_trabalho_bd.tg_fn_atualiza_km_veiculo();


--
-- TOC entry 3448 (class 2620 OID 65594)
-- Name: hodometros trg_km_hodometros; Type: TRIGGER; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE TRIGGER trg_km_hodometros AFTER INSERT ON gabriel_trabalho_bd.hodometros FOR EACH ROW EXECUTE FUNCTION gabriel_trabalho_bd.tg_fn_atualiza_km_veiculo();


--
-- TOC entry 3451 (class 2620 OID 65593)
-- Name: manutencoes trg_km_manutencoes; Type: TRIGGER; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE TRIGGER trg_km_manutencoes AFTER INSERT ON gabriel_trabalho_bd.manutencoes FOR EACH ROW EXECUTE FUNCTION gabriel_trabalho_bd.tg_fn_atualiza_km_veiculo();


--
-- TOC entry 3447 (class 2620 OID 65588)
-- Name: veiculos trg_veiculo_historico_status; Type: TRIGGER; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE TRIGGER trg_veiculo_historico_status AFTER UPDATE OF status ON gabriel_trabalho_bd.veiculos FOR EACH ROW WHEN (((old.status)::text IS DISTINCT FROM (new.status)::text)) EXECUTE FUNCTION gabriel_trabalho_bd.tg_fn_veiculo_historico_status();


--
-- TOC entry 3452 (class 2620 OID 65590)
-- Name: viagens trg_viagem_valida; Type: TRIGGER; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE TRIGGER trg_viagem_valida BEFORE INSERT ON gabriel_trabalho_bd.viagens FOR EACH ROW EXECUTE FUNCTION gabriel_trabalho_bd.tg_fn_viagem_valida();


--
-- TOC entry 3440 (class 2606 OID 32835)
-- Name: abastecimentos abastecimentos_id_veiculo_fkey; Type: FK CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.abastecimentos
    ADD CONSTRAINT abastecimentos_id_veiculo_fkey FOREIGN KEY (id_veiculo) REFERENCES gabriel_trabalho_bd.veiculos(id_veiculo);


--
-- TOC entry 3442 (class 2606 OID 32871)
-- Name: despesas despesas_id_veiculo_fkey; Type: FK CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.despesas
    ADD CONSTRAINT despesas_id_veiculo_fkey FOREIGN KEY (id_veiculo) REFERENCES gabriel_trabalho_bd.veiculos(id_veiculo);


--
-- TOC entry 3446 (class 2606 OID 65550)
-- Name: historico_status_veiculo historico_status_veiculo_id_veiculo_fkey; Type: FK CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.historico_status_veiculo
    ADD CONSTRAINT historico_status_veiculo_id_veiculo_fkey FOREIGN KEY (id_veiculo) REFERENCES gabriel_trabalho_bd.veiculos(id_veiculo);


--
-- TOC entry 3439 (class 2606 OID 32815)
-- Name: hodometros hodometros_id_veiculo_fkey; Type: FK CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.hodometros
    ADD CONSTRAINT hodometros_id_veiculo_fkey FOREIGN KEY (id_veiculo) REFERENCES gabriel_trabalho_bd.veiculos(id_veiculo);


--
-- TOC entry 3441 (class 2606 OID 32854)
-- Name: manutencoes manutencoes_id_veiculo_fkey; Type: FK CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.manutencoes
    ADD CONSTRAINT manutencoes_id_veiculo_fkey FOREIGN KEY (id_veiculo) REFERENCES gabriel_trabalho_bd.veiculos(id_veiculo);


--
-- TOC entry 3443 (class 2606 OID 81922)
-- Name: viagens viagens_id_modalidade_fkey; Type: FK CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.viagens
    ADD CONSTRAINT viagens_id_modalidade_fkey FOREIGN KEY (id_modalidade) REFERENCES gabriel_trabalho_bd.modalidade(id);


--
-- TOC entry 3444 (class 2606 OID 32894)
-- Name: viagens viagens_id_motorista_fkey; Type: FK CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.viagens
    ADD CONSTRAINT viagens_id_motorista_fkey FOREIGN KEY (id_motorista) REFERENCES gabriel_trabalho_bd.motoristas(id_motorista);


--
-- TOC entry 3445 (class 2606 OID 32889)
-- Name: viagens viagens_id_veiculo_fkey; Type: FK CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.viagens
    ADD CONSTRAINT viagens_id_veiculo_fkey FOREIGN KEY (id_veiculo) REFERENCES gabriel_trabalho_bd.veiculos(id_veiculo);


--
-- TOC entry 3639 (class 0 OID 0)
-- Dependencies: 6
-- Name: SCHEMA gabriel_trabalho_bd; Type: ACL; Schema: -; Owner: neondb_owner
--

GRANT USAGE ON SCHEMA gabriel_trabalho_bd TO professor_bd;


--
-- TOC entry 3641 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO professor_bd;


--
-- TOC entry 3642 (class 0 OID 0)
-- Dependencies: 264
-- Name: FUNCTION fn_consumo_medio(p_id_veiculo integer); Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT ALL ON FUNCTION gabriel_trabalho_bd.fn_consumo_medio(p_id_veiculo integer) TO professor_bd;


--
-- TOC entry 3643 (class 0 OID 0)
-- Dependencies: 266
-- Name: FUNCTION fn_custo_total_veiculo(p_id_veiculo integer, p_data_inicio date, p_data_fim date); Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT ALL ON FUNCTION gabriel_trabalho_bd.fn_custo_total_veiculo(p_id_veiculo integer, p_data_inicio date, p_data_fim date) TO professor_bd;


--
-- TOC entry 3644 (class 0 OID 0)
-- Dependencies: 250
-- Name: FUNCTION fn_gasto_combustivel(p_id_veiculo integer); Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT ALL ON FUNCTION gabriel_trabalho_bd.fn_gasto_combustivel(p_id_veiculo integer) TO professor_bd;


--
-- TOC entry 3645 (class 0 OID 0)
-- Dependencies: 248
-- Name: FUNCTION fn_km_percorridos(p_id_veiculo integer); Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT ALL ON FUNCTION gabriel_trabalho_bd.fn_km_percorridos(p_id_veiculo integer) TO professor_bd;


--
-- TOC entry 3646 (class 0 OID 0)
-- Dependencies: 267
-- Name: FUNCTION fn_motorista_apto(p_id_motorista integer); Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT ALL ON FUNCTION gabriel_trabalho_bd.fn_motorista_apto(p_id_motorista integer) TO professor_bd;


--
-- TOC entry 3647 (class 0 OID 0)
-- Dependencies: 251
-- Name: FUNCTION fn_total_abastecimentos(p_id_veiculo integer); Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT ALL ON FUNCTION gabriel_trabalho_bd.fn_total_abastecimentos(p_id_veiculo integer) TO professor_bd;


--
-- TOC entry 3648 (class 0 OID 0)
-- Dependencies: 273
-- Name: FUNCTION fn_total_despesas(p_id_veiculo integer); Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT ALL ON FUNCTION gabriel_trabalho_bd.fn_total_despesas(p_id_veiculo integer) TO professor_bd;


--
-- TOC entry 3649 (class 0 OID 0)
-- Dependencies: 274
-- Name: FUNCTION fn_total_manutencao(p_id_veiculo integer); Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT ALL ON FUNCTION gabriel_trabalho_bd.fn_total_manutencao(p_id_veiculo integer) TO professor_bd;


--
-- TOC entry 3650 (class 0 OID 0)
-- Dependencies: 249
-- Name: FUNCTION fn_total_viagens_motorista(p_id_motorista integer); Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT ALL ON FUNCTION gabriel_trabalho_bd.fn_total_viagens_motorista(p_id_motorista integer) TO professor_bd;


--
-- TOC entry 3651 (class 0 OID 0)
-- Dependencies: 265
-- Name: PROCEDURE sp_concluir_manutencao(IN p_id_veiculo integer); Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT ALL ON PROCEDURE gabriel_trabalho_bd.sp_concluir_manutencao(IN p_id_veiculo integer) TO professor_bd;


--
-- TOC entry 3652 (class 0 OID 0)
-- Dependencies: 272
-- Name: PROCEDURE sp_finalizar_viagem(IN p_id_viagem integer, IN p_km_final integer); Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT ALL ON PROCEDURE gabriel_trabalho_bd.sp_finalizar_viagem(IN p_id_viagem integer, IN p_km_final integer) TO professor_bd;


--
-- TOC entry 3653 (class 0 OID 0)
-- Dependencies: 271
-- Name: PROCEDURE sp_iniciar_viagem(IN p_id_veiculo integer, IN p_id_motorista integer, IN p_destino character varying, IN p_finalidade character varying, IN p_km_inicial integer); Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT ALL ON PROCEDURE gabriel_trabalho_bd.sp_iniciar_viagem(IN p_id_veiculo integer, IN p_id_motorista integer, IN p_destino character varying, IN p_finalidade character varying, IN p_km_inicial integer) TO professor_bd;


--
-- TOC entry 3654 (class 0 OID 0)
-- Dependencies: 275
-- Name: PROCEDURE sp_registrar_manutencao(IN p_id_veiculo integer, IN p_tipo character varying, IN p_descricao character varying, IN p_oficina character varying, IN p_valor numeric, IN p_km integer); Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT ALL ON PROCEDURE gabriel_trabalho_bd.sp_registrar_manutencao(IN p_id_veiculo integer, IN p_tipo character varying, IN p_descricao character varying, IN p_oficina character varying, IN p_valor numeric, IN p_km integer) TO professor_bd;


--
-- TOC entry 3655 (class 0 OID 0)
-- Dependencies: 268
-- Name: FUNCTION tg_fn_abastecimento_valida(); Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT ALL ON FUNCTION gabriel_trabalho_bd.tg_fn_abastecimento_valida() TO professor_bd;


--
-- TOC entry 3656 (class 0 OID 0)
-- Dependencies: 262
-- Name: FUNCTION tg_fn_atualiza_km_veiculo(); Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT ALL ON FUNCTION gabriel_trabalho_bd.tg_fn_atualiza_km_veiculo() TO professor_bd;


--
-- TOC entry 3657 (class 0 OID 0)
-- Dependencies: 269
-- Name: FUNCTION tg_fn_veiculo_historico_status(); Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT ALL ON FUNCTION gabriel_trabalho_bd.tg_fn_veiculo_historico_status() TO professor_bd;


--
-- TOC entry 3658 (class 0 OID 0)
-- Dependencies: 270
-- Name: FUNCTION tg_fn_viagem_valida(); Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT ALL ON FUNCTION gabriel_trabalho_bd.tg_fn_viagem_valida() TO professor_bd;


--
-- TOC entry 3659 (class 0 OID 0)
-- Dependencies: 228
-- Name: TABLE abastecimentos; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.abastecimentos TO professor_bd;


--
-- TOC entry 3661 (class 0 OID 0)
-- Dependencies: 227
-- Name: SEQUENCE abastecimentos_id_abastecimento_seq; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT,USAGE ON SEQUENCE gabriel_trabalho_bd.abastecimentos_id_abastecimento_seq TO professor_bd;


--
-- TOC entry 3662 (class 0 OID 0)
-- Dependencies: 232
-- Name: TABLE despesas; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.despesas TO professor_bd;


--
-- TOC entry 3664 (class 0 OID 0)
-- Dependencies: 231
-- Name: SEQUENCE despesas_id_despesa_seq; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT,USAGE ON SEQUENCE gabriel_trabalho_bd.despesas_id_despesa_seq TO professor_bd;


--
-- TOC entry 3665 (class 0 OID 0)
-- Dependencies: 241
-- Name: TABLE historico_status_veiculo; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.historico_status_veiculo TO professor_bd;


--
-- TOC entry 3667 (class 0 OID 0)
-- Dependencies: 240
-- Name: SEQUENCE historico_status_veiculo_id_historico_seq; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON SEQUENCE gabriel_trabalho_bd.historico_status_veiculo_id_historico_seq TO professor_bd;


--
-- TOC entry 3668 (class 0 OID 0)
-- Dependencies: 226
-- Name: TABLE hodometros; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.hodometros TO professor_bd;


--
-- TOC entry 3670 (class 0 OID 0)
-- Dependencies: 225
-- Name: SEQUENCE hodometros_id_hodometro_seq; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT,USAGE ON SEQUENCE gabriel_trabalho_bd.hodometros_id_hodometro_seq TO professor_bd;


--
-- TOC entry 3671 (class 0 OID 0)
-- Dependencies: 230
-- Name: TABLE manutencoes; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.manutencoes TO professor_bd;


--
-- TOC entry 3673 (class 0 OID 0)
-- Dependencies: 229
-- Name: SEQUENCE manutencoes_id_manutencao_seq; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT,USAGE ON SEQUENCE gabriel_trabalho_bd.manutencoes_id_manutencao_seq TO professor_bd;


--
-- TOC entry 3674 (class 0 OID 0)
-- Dependencies: 220
-- Name: TABLE modalidade; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.modalidade TO professor_bd;


--
-- TOC entry 3675 (class 0 OID 0)
-- Dependencies: 224
-- Name: TABLE motoristas; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.motoristas TO professor_bd;


--
-- TOC entry 3677 (class 0 OID 0)
-- Dependencies: 223
-- Name: SEQUENCE motoristas_id_motorista_seq; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT,USAGE ON SEQUENCE gabriel_trabalho_bd.motoristas_id_motorista_seq TO professor_bd;


--
-- TOC entry 3678 (class 0 OID 0)
-- Dependencies: 222
-- Name: TABLE veiculos; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.veiculos TO professor_bd;


--
-- TOC entry 3679 (class 0 OID 0)
-- Dependencies: 245
-- Name: TABLE mv_consumo_veiculos; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.mv_consumo_veiculos TO professor_bd;


--
-- TOC entry 3680 (class 0 OID 0)
-- Dependencies: 234
-- Name: TABLE viagens; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.viagens TO professor_bd;


--
-- TOC entry 3681 (class 0 OID 0)
-- Dependencies: 247
-- Name: TABLE mv_dashboard_frota; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.mv_dashboard_frota TO professor_bd;


--
-- TOC entry 3682 (class 0 OID 0)
-- Dependencies: 244
-- Name: TABLE mv_desempenho_motoristas; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.mv_desempenho_motoristas TO professor_bd;


--
-- TOC entry 3683 (class 0 OID 0)
-- Dependencies: 243
-- Name: TABLE mv_gastos_mensais; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.mv_gastos_mensais TO professor_bd;


--
-- TOC entry 3684 (class 0 OID 0)
-- Dependencies: 242
-- Name: TABLE mv_gastos_veiculos; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.mv_gastos_veiculos TO professor_bd;


--
-- TOC entry 3685 (class 0 OID 0)
-- Dependencies: 246
-- Name: TABLE mv_manutencoes_por_tipo; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.mv_manutencoes_por_tipo TO professor_bd;


--
-- TOC entry 3687 (class 0 OID 0)
-- Dependencies: 221
-- Name: SEQUENCE veiculos_id_veiculo_seq; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT,USAGE ON SEQUENCE gabriel_trabalho_bd.veiculos_id_veiculo_seq TO professor_bd;


--
-- TOC entry 3689 (class 0 OID 0)
-- Dependencies: 233
-- Name: SEQUENCE viagens_id_viagem_seq; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT,USAGE ON SEQUENCE gabriel_trabalho_bd.viagens_id_viagem_seq TO professor_bd;


--
-- TOC entry 3690 (class 0 OID 0)
-- Dependencies: 235
-- Name: TABLE vw_gastos_veiculos; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.vw_gastos_veiculos TO professor_bd;


--
-- TOC entry 3691 (class 0 OID 0)
-- Dependencies: 237
-- Name: TABLE vw_historico_abastecimentos; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.vw_historico_abastecimentos TO professor_bd;


--
-- TOC entry 3692 (class 0 OID 0)
-- Dependencies: 236
-- Name: TABLE vw_resumo_viagens; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.vw_resumo_viagens TO professor_bd;


--
-- TOC entry 2153 (class 826 OID 81921)
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER DEFAULT PRIVILEGES FOR ROLE neondb_owner IN SCHEMA gabriel_trabalho_bd GRANT ALL ON FUNCTIONS TO professor_bd;


--
-- TOC entry 2152 (class 826 OID 81920)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER DEFAULT PRIVILEGES FOR ROLE neondb_owner IN SCHEMA gabriel_trabalho_bd GRANT SELECT ON TABLES TO professor_bd;


--
-- TOC entry 2151 (class 826 OID 16526)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: cloud_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE cloud_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO neon_superuser WITH GRANT OPTION;


--
-- TOC entry 2150 (class 826 OID 16525)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: cloud_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE cloud_admin IN SCHEMA public GRANT ALL ON TABLES TO neon_superuser WITH GRANT OPTION;


--
-- TOC entry 3631 (class 0 OID 73770)
-- Dependencies: 245 3635
-- Name: mv_consumo_veiculos; Type: MATERIALIZED VIEW DATA; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

REFRESH MATERIALIZED VIEW gabriel_trabalho_bd.mv_consumo_veiculos;


--
-- TOC entry 3633 (class 0 OID 73795)
-- Dependencies: 247 3635
-- Name: mv_dashboard_frota; Type: MATERIALIZED VIEW DATA; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

REFRESH MATERIALIZED VIEW gabriel_trabalho_bd.mv_dashboard_frota;


--
-- TOC entry 3630 (class 0 OID 73756)
-- Dependencies: 244 3635
-- Name: mv_desempenho_motoristas; Type: MATERIALIZED VIEW DATA; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

REFRESH MATERIALIZED VIEW gabriel_trabalho_bd.mv_desempenho_motoristas;


--
-- TOC entry 3629 (class 0 OID 73742)
-- Dependencies: 243 3635
-- Name: mv_gastos_mensais; Type: MATERIALIZED VIEW DATA; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

REFRESH MATERIALIZED VIEW gabriel_trabalho_bd.mv_gastos_mensais;


--
-- TOC entry 3628 (class 0 OID 73728)
-- Dependencies: 242 3635
-- Name: mv_gastos_veiculos; Type: MATERIALIZED VIEW DATA; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

REFRESH MATERIALIZED VIEW gabriel_trabalho_bd.mv_gastos_veiculos;


--
-- TOC entry 3632 (class 0 OID 73783)
-- Dependencies: 246 3635
-- Name: mv_manutencoes_por_tipo; Type: MATERIALIZED VIEW DATA; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

REFRESH MATERIALIZED VIEW gabriel_trabalho_bd.mv_manutencoes_por_tipo;


-- Completed on 2026-11-03 10:19:49

--
-- PostgreSQL database dump complete
--

\unrestrict iPsgMRF4sQlregf9lmEDr9j8eGhCSOl2Iaw3XInoomFRmHkLzcpJOR0STwiE9vP

