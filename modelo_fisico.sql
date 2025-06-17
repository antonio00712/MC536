--fazendo um código para importar os dados do arquivo CSV para o banco de dados
-- 1. Conectar ao banco de dados
--\c banco_de_dados_Escolas;
-- 2. Criar a tabela para armazenar os dados

DROP TABLE IF EXISTS escolas;
CREATE TABLE escolas (
    co_entidade INTEGER,
    no_entidade VARCHAR(255) NOT NULL,
    tp_dependencia VARCHAR(20),     -- Ex: "Federal", "Estadual", etc.
    tp_localizacao VARCHAR(20),     -- Ex: "Urbana", "Rural"
    NU_ANO_CENSO INTEGER,
    NO_MUNICIPIO VARCHAR(255),
    SG_UF VARCHAR(2),
    -- Agua
    IN_AGUA_REDE_PUBLICA BOOLEAN,
    IN_AGUA_POCO_ARTESIANO BOOLEAN,
    IN_AGUA_CACIMBA BOOLEAN,
    IN_AGUA_FONTE_RIO BOOLEAN,
    IN_AGUA_INEXISTENTE BOOLEAN,
    -- Energia
    IN_ENERGIA_REDE_PUBLICA BOOLEAN,
    IN_ENERGIA_GERADOR_FOSSIL BOOLEAN,
    IN_ENERGIA_RENOVAVEL BOOLEAN,
    IN_ENERGIA_INEXISTENTE BOOLEAN,
    -- Esgoto
    IN_ESGOTO_REDE_PUBLICA BOOLEAN,
    IN_ESGOTO_FOSSA_SEPTICA BOOLEAN,
    IN_ESGOTO_FOSSA_COMUM BOOLEAN,
    IN_ESGOTO_FOSSA BOOLEAN,
    IN_ESGOTO_INEXISTENTE BOOLEAN,
    -- Dependencias
    IN_AREA_VERDE BOOLEAN,
    IN_BANHEIRO BOOLEAN,
    IN_BIBLIOTECA BOOLEAN,
    IN_LABORATORIO_INFORMATICA BOOLEAN,
    -- Internet
    IN_INTERNET BOOLEAN,
    IN_INTERNET_ALUNOS BOOLEAN,
    IN_INTERNET_ADMINISTRATIVO BOOLEAN,
    IN_INTERNET_APRENDIZAGEM BOOLEAN,
    TP_REDE_LOCAL NUMERIC(2,1),
    -- Corpo_docente
    QT_PROF_SAUDE NUMERIC(7,1),
    QT_PROF_PSICOLOGO NUMERIC(7,1),
    QT_PROF_ASSIST_SOCIAL NUMERIC(7,1),
    -- Rendimento
    FUNDAMENTAL NUMERIC(4,1),
    ENSINO_MEDIO NUMERIC(4,1),
    -- Rendimento_enem
    NU_ANO INTEGER,
    NU_MATRICULAS INTEGER,
    NU_PARTICIPANTES INTEGER,
    NU_TAXA_PARTICIPACAO NUMERIC(5,2),
    NU_MEDIA_TOT NUMERIC(5,2),
    PORTE_ESCOLA VARCHAR(255)
);

-- 3. Importar os dados do arquivo CSV para a tabela
-- usando comando \copy para importar os dados do arquivo CSV
-- nome regiao = NO_REGIAO
-- sigla = SG_UF
INSERT INTO ano(NU_ANO_CENSO) VALUES (2023);
\copy regiao_escolar(NO_MUNICIPIO, SG_UF) from '/tmp/data/regiao_escolar_parsed.csv' DELIMITER ',' CSV HEADER;
\copy escolas(CO_ENTIDADE, NO_ENTIDADE, TP_DEPENDENCIA, TP_LOCALIZACAO, regiao_id) from '/tmp/data/escolas_parsed.csv' DELIMITER ',' CSV HEADER;
\copy agua(NU_ANO_CENSO, CO_ENTIDADE,IN_AGUA_REDE_PUBLICA, IN_AGUA_POCO_ARTESIANO, IN_AGUA_CACIMBA, IN_AGUA_FONTE_RIO, IN_AGUA_INEXISTENTE) from '/tmp/data/agua_parsed.csv' DELIMITER ',' CSV HEADER;
\copy energia(NU_ANO_CENSO,CO_ENTIDADE,IN_ENERGIA_REDE_PUBLICA, IN_ENERGIA_GERADOR_FOSSIL, IN_ENERGIA_RENOVAVEL, IN_ENERGIA_INEXISTENTE) from '/tmp/data/energia_parsed.csv' DELIMITER ',' CSV HEADER;
\copy esgoto(NU_ANO_CENSO, CO_ENTIDADE, IN_ESGOTO_REDE_PUBLICA, IN_ESGOTO_FOSSA_SEPTICA, IN_ESGOTO_FOSSA_COMUM, IN_ESGOTO_FOSSA, IN_ESGOTO_INEXISTENTE) from '/tmp/data/esgoto_parsed.csv' DELIMITER ',' CSV HEADER;
\copy dependencias(NU_ANO_CENSO, CO_ENTIDADE, IN_AREA_VERDE, IN_BANHEIRO, IN_BIBLIOTECA, IN_LABORATORIO_INFORMATICA) from '/tmp/data/dependencias_parsed.csv' DELIMITER ',' CSV HEADER;
\copy internet(NU_ANO_CENSO, CO_ENTIDADE, IN_INTERNET, IN_INTERNET_ALUNOS, IN_INTERNET_ADMINISTRATIVO, IN_INTERNET_APRENDIZAGEM, TP_REDE_LOCAL) from '/tmp/data/internet_parsed.csv' DELIMITER ',' CSV HEADER;
\copy corpo_docente(NU_ANO_CENSO, CO_ENTIDADE, QT_PROF_SAUDE, QT_PROF_PSICOLOGO, QT_PROF_ASSIST_SOCIAL) from '/tmp/data/corpo_docente_parsed.csv' DELIMITER ',' CSV HEADER;
\copy rendimento(NU_ANO_CENSO, CO_ENTIDADE, FUNDAMENTAL, ENSINO_MEDIO) from '/tmp/data/serie_parsed.csv' DELIMITER ',' CSV HEADER;
\copy rendimento_enem(NU_ANO, CO_ESCOLA_EDUCACENSO, NU_MATRICULAS, NU_PARTICIPANTES, NU_TAXA_PARTICIPACAO, NU_MEDIA_TOT, PORTE_ESCOLA) from '/tmp/data/rendimento_enem.csv' DELIMITER ',' CSV HEADER;


-- Consultar os dados importados

-- 1. Escolas com mais de uma fonte de água
SELECT 
    no_entidade,
    (
        CAST(SUM(CAST(in_agua_rede_publica AS INT)) +
            SUM(CAST(in_agua_poco_artesiano AS INT)) +
            SUM(CAST(in_agua_cacimba AS INT)) +
            SUM(CAST(in_agua_fonte_rio AS INT))
        AS INT)
    ) AS fontes_agua
FROM escolas
GROUP BY no_entidade
HAVING fontes_agua > 1
ORDER BY fontes_agua DESC;

-- 2. Escolas com internet apenas para administrativo
SELECT 
    no_entidade,
    sg_uf
FROM escolas
WHERE 
    in_internet_administrativo = TRUE AND
    COALESCE(in_internet_alunos, FALSE) = FALSE AND 
    COALESCE(in_internet_aprendizagem, FALSE) = FALSE;

-- 3. Melhores rendimentos no ENEM por escola
SELECT 
    co_entidade,
    no_entidade,
    nu_ano_censo AS nu_ano,
    nu_taxa_participacao,
    nu_media_tot
FROM escolas
WHERE nu_media_tot IS NOT NULL
ORDER BY nu_media_tot DESC, nu_ano;

-- 4. Escolas com água, energia, internet, biblioteca, banheiro e laboratório de informática presentes
SELECT 
    no_entidade,
    sg_uf
FROM escolas
WHERE 
    in_agua_rede_publica = TRUE AND
    in_energia_rede_publica = TRUE AND
    in_esgoto_rede_publica = TRUE AND
    in_internet = TRUE AND
    in_biblioteca = TRUE AND
    in_banheiro = TRUE AND
    in_laboratorio_informatica = TRUE;

-- 5. Relação entre rendimento e dependência da escola
SELECT 
    tp_dependencia,
    COUNT(*) AS qtd_escolas,
    ROUND(AVG(ensino_medio), 2) AS media_ensino_medio,
    ROUND(AVG(fundamental), 2) AS media_ensino_fundamental
FROM escolas
WHERE 
    ensino_medio IS NOT NULL OR fundamental IS NOT NULL
GROUP BY tp_dependencia
ORDER BY media_ensino_medio DESC;

-- 6. Distribuição de escolas por localização (urbana/rural) e porte

SELECT 
    tp_localizacao,
    porte_escola,
    COUNT(*) AS qtd_escolas
FROM escolas
GROUP BY tp_localizacao, porte_escola
ORDER BY tp_localizacao, qtd_escolas DESC;

-- 7. Escolas que oferecem internet mas não possuem laboratório de informática
SELECT 
    no_entidade,
    sg_uf,
    in_internet,
    in_laboratorio_informatica
FROM escolas
WHERE 
    in_internet = TRUE AND
    (in_laboratorio_informatica IS FALSE OR in_laboratorio_informatica IS NULL)
ORDER BY sg_uf;

-- 8. Classificação das escolas por faixa de taxa de participação no ENEM
SELECT 
    CASE 
        WHEN nu_taxa_participacao < 20 THEN 'Baixa participação (<20%)'
        WHEN nu_taxa_participacao BETWEEN 20 AND 60 THEN 'Média participação (20–60%)'
        WHEN nu_taxa_participacao > 60 THEN 'Alta participação (>60%)'
    ELSE 'Sem dados'
    END AS faixa_participacao,
    COUNT(*) AS qtd_escolas
FROM escolas
GROUP BY faixa_participacao
ORDER BY qtd_escolas DESC;

