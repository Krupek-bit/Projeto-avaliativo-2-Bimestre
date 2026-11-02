--
-- PostgreSQL database dump
--
\restrict fRqWZbvdak6sMey4OzCoYWxAv8Ikaq6zgAcuRg0gD8oc7a8JyTNfeQj2uLT74ZJ

-- Dumped from database version 18.6 (4e5fd08)
-- Dumped by pg_dump version 18.4

-- Started on 2026-10-29 20:18:16
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
-- TOC entry 5 (class 2615 OID 24576)
-- Name: gabriel_trabalho_bd; Type: SCHEMA; Schema: -; Owner: neondb_owner
--

CREATE SCHEMA gabriel_trabalho_bd;


ALTER SCHEMA gabriel_trabalho_bd OWNER TO neondb_owner;
--
-- TOC entry 242 (class 1255 OID 65582)
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
-- TOC entry 243 (class 1255 OID 65583)
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
-- TOC entry 244 (class 1255 OID 65584)
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
-- TOC entry 263 (class 1255 OID 65598)
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
-- TOC entry 261 (class 1255 OID 65596)
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
-- TOC entry 260 (class 1255 OID 65595)
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
-- TOC entry 262 (class 1255 OID 65597)
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
-- TOC entry 245 (class 1255 OID 65585)
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
-- TOC entry 258 (class 1255 OID 65591)
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
-- TOC entry 246 (class 1255 OID 65587)
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
-- TOC entry 251 (class 1255 OID 65589)
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
-- TOC entry 3588 (class 0 OID 0)
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
-- TOC entry 3591 (class 0 OID 0)
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
-- TOC entry 3593 (class 0 OID 0)
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
-- TOC entry 3595 (class 0 OID 0)
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
-- TOC entry 3598 (class 0 OID 0)
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
-- TOC entry 3602 (class 0 OID 0)
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
-- TOC entry 3605 (class 0 OID 0)
-- Dependencies: 221
-- Name: veiculos_id_veiculo_seq; Type: SEQUENCE OWNED BY; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER SEQUENCE gabriel_trabalho_bd.veiculos_id_veiculo_seq OWNED BY gabriel_trabalho_bd.veiculos.id_veiculo;


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
    CONSTRAINT chk_viagem_datas CHECK (((data_retorno IS NULL) OR (data_retorno >= data_saida))),
    CONSTRAINT chk_viagem_km CHECK (((km_final IS NULL) OR (km_final >= km_inicial)))
);


ALTER TABLE gabriel_trabalho_bd.viagens OWNER TO neondb_owner;

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
-- TOC entry 3608 (class 0 OID 0)
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
-- TOC entry 3613 (class 0 OID 0)
-- Dependencies: 238
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: professor_bd
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- TOC entry 3344 (class 2604 OID 32824)
-- Name: abastecimentos id_abastecimento; Type: DEFAULT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.abastecimentos ALTER COLUMN id_abastecimento SET DEFAULT nextval('gabriel_trabalho_bd.abastecimentos_id_abastecimento_seq'::regclass);


--
-- TOC entry 3346 (class 2604 OID 32863)
-- Name: despesas id_despesa; Type: DEFAULT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.despesas ALTER COLUMN id_despesa SET DEFAULT nextval('gabriel_trabalho_bd.despesas_id_despesa_seq'::regclass);


--
-- TOC entry 3349 (class 2604 OID 65542)
-- Name: historico_status_veiculo id_historico; Type: DEFAULT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.historico_status_veiculo ALTER COLUMN id_historico SET DEFAULT nextval('gabriel_trabalho_bd.historico_status_veiculo_id_historico_seq'::regclass);


--
-- TOC entry 3343 (class 2604 OID 32808)
-- Name: hodometros id_hodometro; Type: DEFAULT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.hodometros ALTER COLUMN id_hodometro SET DEFAULT nextval('gabriel_trabalho_bd.hodometros_id_hodometro_seq'::regclass);


--
-- TOC entry 3345 (class 2604 OID 32844)
-- Name: manutencoes id_manutencao; Type: DEFAULT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.manutencoes ALTER COLUMN id_manutencao SET DEFAULT nextval('gabriel_trabalho_bd.manutencoes_id_manutencao_seq'::regclass);


--
-- TOC entry 3342 (class 2604 OID 32788)
-- Name: motoristas id_motorista; Type: DEFAULT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.motoristas ALTER COLUMN id_motorista SET DEFAULT nextval('gabriel_trabalho_bd.motoristas_id_motorista_seq'::regclass);


--
-- TOC entry 3340 (class 2604 OID 32772)
-- Name: veiculos id_veiculo; Type: DEFAULT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.veiculos ALTER COLUMN id_veiculo SET DEFAULT nextval('gabriel_trabalho_bd.veiculos_id_veiculo_seq'::regclass);


--
-- TOC entry 3347 (class 2604 OID 32880)
-- Name: viagens id_viagem; Type: DEFAULT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.viagens ALTER COLUMN id_viagem SET DEFAULT nextval('gabriel_trabalho_bd.viagens_id_viagem_seq'::regclass);


--
-- TOC entry 3348 (class 2604 OID 57387)
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: professor_bd
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- TOC entry 3569 (class 0 OID 32821)
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
\.


--
-- TOC entry 3573 (class 0 OID 32860)
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
\.


--
-- TOC entry 3579 (class 0 OID 65539)
-- Dependencies: 241
-- Data for Name: historico_status_veiculo; Type: TABLE DATA; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

COPY gabriel_trabalho_bd.historico_status_veiculo (id_historico, id_veiculo, status_anterior, status_novo, data_alteracao) FROM stdin;
5	11	ativo	em_viagem	2026-10-29 23:10:51.451432
\.


--
-- TOC entry 3567 (class 0 OID 32805)
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
\.


--
-- TOC entry 3571 (class 0 OID 32841)
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
\.


--
-- TOC entry 3561 (class 0 OID 24577)
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
-- TOC entry 3565 (class 0 OID 32785)
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
\.


--
-- TOC entry 3563 (class 0 OID 32769)
-- Dependencies: 222
-- Data for Name: veiculos; Type: TABLE DATA; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

COPY gabriel_trabalho_bd.veiculos (id_veiculo, placa, marca, modelo, ano, tipo, capacidade, status, quilometragem_atual) FROM stdin;
12	abd2e34	volkswagen	constellation	2018	caminhao	12.00	ativo	96200
13	abd3e45	fiat	argo	2022	passeio	0.00	ativo	97900
14	abd4e56	chevrolet	onix	2023	passeio	0.00	ativo	99600
15	abd5e67	hyundai	hb20	2021	passeio	0.00	ativo	101300
16	abd6e78	toyota	corolla	2022	passeio	0.00	ativo	103000
17	abd7e89	volkswagen	virtus	2023	passeio	0.00	ativo	104700
18	abd8e90	renault	duster	2020	suv	0.00	ativo	106400
19	abd9f01	jeep	renegade	2021	suv	0.00	ativo	108100
20	abd0f12	chevrolet	spin	2022	minivan	0.00	ativo	109800
21	abe1f23	fiat	toro	2020	picape	1.00	ativo	109700
22	abe2f34	ford	maverick	2023	picape	0.70	ativo	111400
23	abe3f45	toyota	sw4	2021	suv	0.00	ativo	113100
24	abe4f56	volkswagen	amarok	2022	picape	1.00	ativo	114800
25	abe5f67	mitsubishi	l200	2019	picape	1.00	ativo	116500
26	abe6f78	nissan	frontier	2020	picape	1.00	ativo	118200
27	abe7f89	renault	oroch	2021	picape	0.70	ativo	119900
28	abe8f90	volkswagen	polo	2022	passeio	0.00	ativo	121600
29	abe9g01	fiat	cron​os	2023	passeio	0.00	ativo	123300
30	abe0g12	chevrolet	tracker	2022	suv	0.00	ativo	125000
10	abc0e12	mercedes-benz	atego	2020	caminhao	8.00	ativo	154570
1	abc1d23	volkswagen	saveiro	2020	utilitario	0.75	ativo	77880
2	abc2d34	fiat	strada	2021	utilitario	0.70	ativo	79590
3	abc3d45	chevrolet	montana	2022	utilitario	0.65	ativo	81300
4	abc4d56	toyota	hilux	2021	picape	1.00	ativo	83010
5	abc5d67	ford	ranger	2020	picape	1.00	ativo	84720
6	abc6d78	fiat	ducato	2019	van	1.50	ativo	98930
7	abc7d89	renault	master	2022	van	1.60	ativo	88140
8	abc8d90	mercedes-benz	sprinter	2021	van	1.80	ativo	89850
9	abc9e01	volkswagen	delivery	2019	caminhao	5.00	ativo	126660
11	abd1e23	iveco	daily	2021	caminhao	3.50	em_viagem	94500
\.


--
-- TOC entry 3575 (class 0 OID 32877)
-- Dependencies: 234
-- Data for Name: viagens; Type: TABLE DATA; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

COPY gabriel_trabalho_bd.viagens (id_viagem, id_veiculo, id_motorista, data_saida, data_retorno, km_inicial, km_final, destino, finalidade) FROM stdin;
1	1	1	2026-01-08 07:30:00	2026-01-08 17:20:00	45300	45680	guarapuava	entrega de materiais
2	1	2	2026-02-10 06:50:00	2026-02-10 18:10:00	46800	47250	ponta grossa	entrega de mercadorias
3	1	3	2026-03-12 08:00:00	2026-03-12 16:30:00	48500	48820	prudentopolis	transporte de materiais
4	2	4	2026-01-15 07:00:00	2026-01-15 18:00:00	38300	38750	irati	entrega de produtos
5	2	5	2026-02-18 06:30:00	2026-02-18 19:00:00	39850	40320	curitiba	transporte de mercadorias
6	2	6	2026-03-21 07:40:00	2026-03-21 17:50:00	41500	41900	ponta grossa	entrega de materiais
7	3	7	2026-01-20 08:00:00	2026-01-20 17:00:00	29200	29650	pitanga	servico externo
8	3	8	2026-03-22 07:30:00	2026-03-22 18:20:00	32200	32680	laranjeiras do sul	entrega de equipamentos
9	3	9	2026-05-24 06:40:00	2026-05-24 18:00:00	35500	36050	cascavel	transporte de materiais
10	4	10	2026-01-25 05:30:00	2026-01-25 20:00:00	62600	63350	curitiba	transporte de cargas
11	4	11	2026-03-28 06:00:00	2026-03-28 19:30:00	67200	68020	ponta grossa	entrega de mercadorias
12	4	12	2026-05-30 05:50:00	2026-05-30 21:00:00	71900	72850	sao paulo	transporte de cargas
13	5	13	2026-02-05 05:40:00	2026-02-05 20:30:00	71300	72150	curitiba	transporte de cargas
14	5	14	2026-04-10 06:10:00	2026-04-10 21:20:00	78300	79180	londrina	entrega de mercadorias
15	5	15	2026-06-12 05:30:00	2026-06-12 22:00:00	80700	81650	foz do iguacu	transporte de cargas
16	6	16	2026-01-30 05:00:00	2026-01-30 19:00:00	88500	89350	curitiba	entrega de cargas
17	6	17	2026-03-15 05:30:00	2026-03-15 20:00:00	92200	93100	joinville	transporte de mercadorias
18	6	18	2026-05-18 04:50:00	2026-05-18 21:30:00	96100	97050	florianopolis	entrega de cargas
19	7	19	2026-02-08 06:00:00	2026-02-08 19:30:00	55000	55850	curitiba	transporte de equipamentos
20	7	20	2026-04-12 06:20:00	2026-04-12 18:40:00	60600	61420	ponta grossa	entrega de mercadorias
21	8	1	2026-03-10 05:40:00	2026-03-10 20:00:00	68500	69380	curitiba	transporte de funcionarios
22	8	2	2026-06-15 06:00:00	2026-06-15 20:30:00	76800	77750	londrina	transporte de equipamentos
23	9	3	2026-02-12 04:30:00	2026-02-12 22:00:00	113000	114250	sao paulo	transporte de cargas
24	9	4	2026-04-20 05:00:00	2026-04-20 23:00:00	118000	119400	curitiba	transporte de mercadorias
25	9	5	2026-06-22 04:40:00	2026-06-22 22:30:00	123500	125000	cascavel	transporte de cargas
26	10	6	2026-02-20 04:00:00	2026-02-20 23:00:00	139000	140600	sao paulo	transporte de cargas
27	10	7	2026-04-25 04:30:00	2026-04-25 23:30:00	145000	146750	curitiba	transporte de mercadorias
28	10	8	2026-06-26 04:00:00	2026-06-26 22:00:00	151000	152800	porto alegre	transporte de cargas
29	10	10	2026-10-20 17:00:00	2026-10-21 03:00:00	154570	154720	Campo Mourão	Entrega de mercadorias
30	1	1	2026-10-20 08:00:00	2026-10-20 18:00:00	77880	77985	Curitiba	Transporte de carga
31	2	2	2026-10-20 09:00:00	2026-10-20 19:00:00	79590	79700	Ponta Grossa	Visita técnica
32	3	3	2026-10-20 10:00:00	2026-10-20 20:00:00	81300	81415	Cascavel	Serviço interno
33	4	4	2026-10-20 11:00:00	2026-10-20 21:00:00	83010	83130	Londrina	Entrega de peças
34	5	5	2026-10-20 12:00:00	2026-10-20 22:00:00	84720	84845	Maringá	Entrega de mercadorias
35	6	6	2026-10-20 13:00:00	2026-10-20 23:00:00	98930	99060	Guarapuava	Transporte de carga
36	7	7	2026-10-20 14:00:00	2026-10-21 00:00:00	88140	88275	Pitanga	Visita técnica
37	8	8	2026-10-20 15:00:00	2026-10-21 01:00:00	89850	89990	Irati	Serviço interno
38	9	9	2026-10-20 16:00:00	2026-10-21 02:00:00	126660	126805	Ivaiporã	Entrega de peças
39	11	5	2026-10-29 23:10:51.451432	\N	94500	\N	Guarapuava	Entrega de mercadorias
\.


--
-- TOC entry 3577 (class 0 OID 57384)
-- Dependencies: 239
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: professor_bd
--

COPY public.migrations (id, migration, batch) FROM stdin;
\.


--
-- TOC entry 3614 (class 0 OID 0)
-- Dependencies: 227
-- Name: abastecimentos_id_abastecimento_seq; Type: SEQUENCE SET; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

SELECT pg_catalog.setval('gabriel_trabalho_bd.abastecimentos_id_abastecimento_seq', 310, true);


--
-- TOC entry 3615 (class 0 OID 0)
-- Dependencies: 231
-- Name: despesas_id_despesa_seq; Type: SEQUENCE SET; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

SELECT pg_catalog.setval('gabriel_trabalho_bd.despesas_id_despesa_seq', 41, true);


--
-- TOC entry 3616 (class 0 OID 0)
-- Dependencies: 240
-- Name: historico_status_veiculo_id_historico_seq; Type: SEQUENCE SET; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

SELECT pg_catalog.setval('gabriel_trabalho_bd.historico_status_veiculo_id_historico_seq', 5, true);


--
-- TOC entry 3617 (class 0 OID 0)
-- Dependencies: 225
-- Name: hodometros_id_hodometro_seq; Type: SEQUENCE SET; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

SELECT pg_catalog.setval('gabriel_trabalho_bd.hodometros_id_hodometro_seq', 390, true);


--
-- TOC entry 3618 (class 0 OID 0)
-- Dependencies: 229
-- Name: manutencoes_id_manutencao_seq; Type: SEQUENCE SET; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

SELECT pg_catalog.setval('gabriel_trabalho_bd.manutencoes_id_manutencao_seq', 31, true);


--
-- TOC entry 3619 (class 0 OID 0)
-- Dependencies: 223
-- Name: motoristas_id_motorista_seq; Type: SEQUENCE SET; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

SELECT pg_catalog.setval('gabriel_trabalho_bd.motoristas_id_motorista_seq', 20, true);


--
-- TOC entry 3620 (class 0 OID 0)
-- Dependencies: 221
-- Name: veiculos_id_veiculo_seq; Type: SEQUENCE SET; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

SELECT pg_catalog.setval('gabriel_trabalho_bd.veiculos_id_veiculo_seq', 30, true);


--
-- TOC entry 3621 (class 0 OID 0)
-- Dependencies: 233
-- Name: viagens_id_viagem_seq; Type: SEQUENCE SET; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

SELECT pg_catalog.setval('gabriel_trabalho_bd.viagens_id_viagem_seq', 39, true);


--
-- TOC entry 3622 (class 0 OID 0)
-- Dependencies: 238
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: professor_bd
--

SELECT pg_catalog.setval('public.migrations_id_seq', 1, false);


--
-- TOC entry 3378 (class 2606 OID 32834)
-- Name: abastecimentos abastecimentos_pkey; Type: CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.abastecimentos
    ADD CONSTRAINT abastecimentos_pkey PRIMARY KEY (id_abastecimento);


--
-- TOC entry 3386 (class 2606 OID 32870)
-- Name: despesas despesas_pkey; Type: CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.despesas
    ADD CONSTRAINT despesas_pkey PRIMARY KEY (id_despesa);


--
-- TOC entry 3396 (class 2606 OID 65549)
-- Name: historico_status_veiculo historico_status_veiculo_pkey; Type: CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.historico_status_veiculo
    ADD CONSTRAINT historico_status_veiculo_pkey PRIMARY KEY (id_historico);


--
-- TOC entry 3375 (class 2606 OID 32814)
-- Name: hodometros hodometros_pkey; Type: CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.hodometros
    ADD CONSTRAINT hodometros_pkey PRIMARY KEY (id_hodometro);


--
-- TOC entry 3384 (class 2606 OID 32853)
-- Name: manutencoes manutencoes_pkey; Type: CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.manutencoes
    ADD CONSTRAINT manutencoes_pkey PRIMARY KEY (id_manutencao);


--
-- TOC entry 3363 (class 2606 OID 24584)
-- Name: modalidade modalidade_pkey; Type: CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.modalidade
    ADD CONSTRAINT modalidade_pkey PRIMARY KEY (id);


--
-- TOC entry 3371 (class 2606 OID 32798)
-- Name: motoristas motoristas_cnh_key; Type: CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.motoristas
    ADD CONSTRAINT motoristas_cnh_key UNIQUE (cnh);


--
-- TOC entry 3373 (class 2606 OID 32796)
-- Name: motoristas motoristas_pkey; Type: CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.motoristas
    ADD CONSTRAINT motoristas_pkey PRIMARY KEY (id_motorista);


--
-- TOC entry 3366 (class 2606 OID 32781)
-- Name: veiculos veiculos_pkey; Type: CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.veiculos
    ADD CONSTRAINT veiculos_pkey PRIMARY KEY (id_veiculo);


--
-- TOC entry 3368 (class 2606 OID 32783)
-- Name: veiculos veiculos_placa_key; Type: CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.veiculos
    ADD CONSTRAINT veiculos_placa_key UNIQUE (placa);


--
-- TOC entry 3392 (class 2606 OID 32888)
-- Name: viagens viagens_pkey; Type: CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.viagens
    ADD CONSTRAINT viagens_pkey PRIMARY KEY (id_viagem);


--
-- TOC entry 3394 (class 2606 OID 57392)
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: professor_bd
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 3379 (class 1259 OID 32902)
-- Name: idx_abastecimentos_id_veiculo; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_abastecimentos_id_veiculo ON gabriel_trabalho_bd.abastecimentos USING btree (id_veiculo);


--
-- TOC entry 3380 (class 1259 OID 65569)
-- Name: idx_abastecimentos_veiculo_data; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_abastecimentos_veiculo_data ON gabriel_trabalho_bd.abastecimentos USING btree (id_veiculo, data_abastecimento DESC);


--
-- TOC entry 3387 (class 1259 OID 65557)
-- Name: idx_despesas_id_veiculo; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_despesas_id_veiculo ON gabriel_trabalho_bd.despesas USING btree (id_veiculo);


--
-- TOC entry 3397 (class 1259 OID 65555)
-- Name: idx_historico_status_id_veiculo; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_historico_status_id_veiculo ON gabriel_trabalho_bd.historico_status_veiculo USING btree (id_veiculo);


--
-- TOC entry 3376 (class 1259 OID 65556)
-- Name: idx_hodometros_id_veiculo; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_hodometros_id_veiculo ON gabriel_trabalho_bd.hodometros USING btree (id_veiculo);


--
-- TOC entry 3381 (class 1259 OID 32903)
-- Name: idx_manutencoes_id_veiculo; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_manutencoes_id_veiculo ON gabriel_trabalho_bd.manutencoes USING btree (id_veiculo);


--
-- TOC entry 3382 (class 1259 OID 65573)
-- Name: idx_manutencoes_veiculo_data; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_manutencoes_veiculo_data ON gabriel_trabalho_bd.manutencoes USING btree (id_veiculo, data_manutencao DESC);


--
-- TOC entry 3369 (class 1259 OID 65572)
-- Name: idx_motoristas_status; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_motoristas_status ON gabriel_trabalho_bd.motoristas USING btree (status);


--
-- TOC entry 3364 (class 1259 OID 65571)
-- Name: idx_veiculos_status; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_veiculos_status ON gabriel_trabalho_bd.veiculos USING btree (status);


--
-- TOC entry 3388 (class 1259 OID 65570)
-- Name: idx_viagens_em_andamento; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE UNIQUE INDEX idx_viagens_em_andamento ON gabriel_trabalho_bd.viagens USING btree (id_veiculo) WHERE (data_retorno IS NULL);


--
-- TOC entry 3389 (class 1259 OID 32904)
-- Name: idx_viagens_id_motorista; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_viagens_id_motorista ON gabriel_trabalho_bd.viagens USING btree (id_motorista);


--
-- TOC entry 3390 (class 1259 OID 32905)
-- Name: idx_viagens_id_veiculo; Type: INDEX; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE INDEX idx_viagens_id_veiculo ON gabriel_trabalho_bd.viagens USING btree (id_veiculo);


--
-- TOC entry 3407 (class 2620 OID 65586)
-- Name: abastecimentos trg_abastecimento_valida; Type: TRIGGER; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE TRIGGER trg_abastecimento_valida BEFORE INSERT OR UPDATE ON gabriel_trabalho_bd.abastecimentos FOR EACH ROW EXECUTE FUNCTION gabriel_trabalho_bd.tg_fn_abastecimento_valida();


--
-- TOC entry 3408 (class 2620 OID 65592)
-- Name: abastecimentos trg_km_abastecimentos; Type: TRIGGER; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE TRIGGER trg_km_abastecimentos AFTER INSERT ON gabriel_trabalho_bd.abastecimentos FOR EACH ROW EXECUTE FUNCTION gabriel_trabalho_bd.tg_fn_atualiza_km_veiculo();


--
-- TOC entry 3406 (class 2620 OID 65594)
-- Name: hodometros trg_km_hodometros; Type: TRIGGER; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE TRIGGER trg_km_hodometros AFTER INSERT ON gabriel_trabalho_bd.hodometros FOR EACH ROW EXECUTE FUNCTION gabriel_trabalho_bd.tg_fn_atualiza_km_veiculo();


--
-- TOC entry 3409 (class 2620 OID 65593)
-- Name: manutencoes trg_km_manutencoes; Type: TRIGGER; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE TRIGGER trg_km_manutencoes AFTER INSERT ON gabriel_trabalho_bd.manutencoes FOR EACH ROW EXECUTE FUNCTION gabriel_trabalho_bd.tg_fn_atualiza_km_veiculo();


--
-- TOC entry 3405 (class 2620 OID 65588)
-- Name: veiculos trg_veiculo_historico_status; Type: TRIGGER; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE TRIGGER trg_veiculo_historico_status AFTER UPDATE OF status ON gabriel_trabalho_bd.veiculos FOR EACH ROW WHEN (((old.status)::text IS DISTINCT FROM (new.status)::text)) EXECUTE FUNCTION gabriel_trabalho_bd.tg_fn_veiculo_historico_status();


--
-- TOC entry 3410 (class 2620 OID 65590)
-- Name: viagens trg_viagem_valida; Type: TRIGGER; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

CREATE TRIGGER trg_viagem_valida BEFORE INSERT ON gabriel_trabalho_bd.viagens FOR EACH ROW EXECUTE FUNCTION gabriel_trabalho_bd.tg_fn_viagem_valida();


--
-- TOC entry 3399 (class 2606 OID 32835)
-- Name: abastecimentos abastecimentos_id_veiculo_fkey; Type: FK CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.abastecimentos
    ADD CONSTRAINT abastecimentos_id_veiculo_fkey FOREIGN KEY (id_veiculo) REFERENCES gabriel_trabalho_bd.veiculos(id_veiculo);


--
-- TOC entry 3401 (class 2606 OID 32871)
-- Name: despesas despesas_id_veiculo_fkey; Type: FK CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.despesas
    ADD CONSTRAINT despesas_id_veiculo_fkey FOREIGN KEY (id_veiculo) REFERENCES gabriel_trabalho_bd.veiculos(id_veiculo);


--
-- TOC entry 3404 (class 2606 OID 65550)
-- Name: historico_status_veiculo historico_status_veiculo_id_veiculo_fkey; Type: FK CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.historico_status_veiculo
    ADD CONSTRAINT historico_status_veiculo_id_veiculo_fkey FOREIGN KEY (id_veiculo) REFERENCES gabriel_trabalho_bd.veiculos(id_veiculo);


--
-- TOC entry 3398 (class 2606 OID 32815)
-- Name: hodometros hodometros_id_veiculo_fkey; Type: FK CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.hodometros
    ADD CONSTRAINT hodometros_id_veiculo_fkey FOREIGN KEY (id_veiculo) REFERENCES gabriel_trabalho_bd.veiculos(id_veiculo);


--
-- TOC entry 3400 (class 2606 OID 32854)
-- Name: manutencoes manutencoes_id_veiculo_fkey; Type: FK CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.manutencoes
    ADD CONSTRAINT manutencoes_id_veiculo_fkey FOREIGN KEY (id_veiculo) REFERENCES gabriel_trabalho_bd.veiculos(id_veiculo);


--
-- TOC entry 3402 (class 2606 OID 32894)
-- Name: viagens viagens_id_motorista_fkey; Type: FK CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.viagens
    ADD CONSTRAINT viagens_id_motorista_fkey FOREIGN KEY (id_motorista) REFERENCES gabriel_trabalho_bd.motoristas(id_motorista);


--
-- TOC entry 3403 (class 2606 OID 32889)
-- Name: viagens viagens_id_veiculo_fkey; Type: FK CONSTRAINT; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

ALTER TABLE ONLY gabriel_trabalho_bd.viagens
    ADD CONSTRAINT viagens_id_veiculo_fkey FOREIGN KEY (id_veiculo) REFERENCES gabriel_trabalho_bd.veiculos(id_veiculo);


--
-- TOC entry 3585 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA gabriel_trabalho_bd; Type: ACL; Schema: -; Owner: neondb_owner
--

GRANT USAGE ON SCHEMA gabriel_trabalho_bd TO professor_bd;


--
-- TOC entry 3586 (class 0 OID 0)
-- Dependencies: 6
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO professor_bd;


--
-- TOC entry 3587 (class 0 OID 0)
-- Dependencies: 228
-- Name: TABLE abastecimentos; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.abastecimentos TO professor_bd;


--
-- TOC entry 3589 (class 0 OID 0)
-- Dependencies: 227
-- Name: SEQUENCE abastecimentos_id_abastecimento_seq; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT,USAGE ON SEQUENCE gabriel_trabalho_bd.abastecimentos_id_abastecimento_seq TO professor_bd;


--
-- TOC entry 3590 (class 0 OID 0)
-- Dependencies: 232
-- Name: TABLE despesas; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.despesas TO professor_bd;


--
-- TOC entry 3592 (class 0 OID 0)
-- Dependencies: 231
-- Name: SEQUENCE despesas_id_despesa_seq; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT,USAGE ON SEQUENCE gabriel_trabalho_bd.despesas_id_despesa_seq TO professor_bd;


--
-- TOC entry 3594 (class 0 OID 0)
-- Dependencies: 226
-- Name: TABLE hodometros; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.hodometros TO professor_bd;


--
-- TOC entry 3596 (class 0 OID 0)
-- Dependencies: 225
-- Name: SEQUENCE hodometros_id_hodometro_seq; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT,USAGE ON SEQUENCE gabriel_trabalho_bd.hodometros_id_hodometro_seq TO professor_bd;


--
-- TOC entry 3597 (class 0 OID 0)
-- Dependencies: 230
-- Name: TABLE manutencoes; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.manutencoes TO professor_bd;


--
-- TOC entry 3599 (class 0 OID 0)
-- Dependencies: 229
-- Name: SEQUENCE manutencoes_id_manutencao_seq; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT,USAGE ON SEQUENCE gabriel_trabalho_bd.manutencoes_id_manutencao_seq TO professor_bd;


--
-- TOC entry 3600 (class 0 OID 0)
-- Dependencies: 220
-- Name: TABLE modalidade; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.modalidade TO professor_bd;


--
-- TOC entry 3601 (class 0 OID 0)
-- Dependencies: 224
-- Name: TABLE motoristas; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.motoristas TO professor_bd;


--
-- TOC entry 3603 (class 0 OID 0)
-- Dependencies: 223
-- Name: SEQUENCE motoristas_id_motorista_seq; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT,USAGE ON SEQUENCE gabriel_trabalho_bd.motoristas_id_motorista_seq TO professor_bd;


--
-- TOC entry 3604 (class 0 OID 0)
-- Dependencies: 222
-- Name: TABLE veiculos; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.veiculos TO professor_bd;


--
-- TOC entry 3606 (class 0 OID 0)
-- Dependencies: 221
-- Name: SEQUENCE veiculos_id_veiculo_seq; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT,USAGE ON SEQUENCE gabriel_trabalho_bd.veiculos_id_veiculo_seq TO professor_bd;


--
-- TOC entry 3607 (class 0 OID 0)
-- Dependencies: 234
-- Name: TABLE viagens; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.viagens TO professor_bd;


--
-- TOC entry 3609 (class 0 OID 0)
-- Dependencies: 233
-- Name: SEQUENCE viagens_id_viagem_seq; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT,USAGE ON SEQUENCE gabriel_trabalho_bd.viagens_id_viagem_seq TO professor_bd;


--
-- TOC entry 3610 (class 0 OID 0)
-- Dependencies: 235
-- Name: TABLE vw_gastos_veiculos; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.vw_gastos_veiculos TO professor_bd;


--
-- TOC entry 3611 (class 0 OID 0)
-- Dependencies: 237
-- Name: TABLE vw_historico_abastecimentos; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.vw_historico_abastecimentos TO professor_bd;


--
-- TOC entry 3612 (class 0 OID 0)
-- Dependencies: 236
-- Name: TABLE vw_resumo_viagens; Type: ACL; Schema: gabriel_trabalho_bd; Owner: neondb_owner
--

GRANT SELECT ON TABLE gabriel_trabalho_bd.vw_resumo_viagens TO professor_bd;


--
-- TOC entry 2121 (class 826 OID 16526)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: cloud_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE cloud_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO neon_superuser WITH GRANT OPTION;


--
-- TOC entry 2120 (class 826 OID 16525)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: cloud_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE cloud_admin IN SCHEMA public GRANT ALL ON TABLES TO neon_superuser WITH GRANT OPTION;


-- Completed on 2026-10-29 20:18:19

--
-- PostgreSQL database dump complete
--
\unrestrict fRqWZbvdak6sMey4OzCoYWxAv8Ikaq6zgAcuRg0gD8oc7a8JyTNfeQj2uLT74ZJ

