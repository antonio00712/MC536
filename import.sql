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

-- 1. Consultar escolas com mais de uma fonte de água
SELECT 
  no_entidade,
  (CAST(IN_AGUA_REDE_PUBLICA AS INT) +
   CAST(IN_AGUA_POCO_ARTESIANO AS INT) +
   CAST(IN_AGUA_CACIMBA AS INT) +
   CAST(IN_AGUA_FONTE_RIO AS INT)) AS fontes_agua
FROM escolas
WHERE 
  COALESCE(IN_AGUA_REDE_PUBLICA, FALSE) OR 
  COALESCE(IN_AGUA_POCO_ARTESIANO, FALSE) OR 
  COALESCE(IN_AGUA_CACIMBA, FALSE) OR 
  COALESCE(IN_AGUA_FONTE_RIO, FALSE)
HAVING 
  (CAST(IN_AGUA_REDE_PUBLICA AS INT) +
   CAST(IN_AGUA_POCO_ARTESIANO AS INT) +
   CAST(IN_AGUA_CACIMBA AS INT) +
   CAST(IN_AGUA_FONTE_RIO AS INT)) > 1
ORDER BY fontes_agua DESC;

-- 2. Consultar escolas com internet apenas para administrativo    
SELECT 
  no_entidade,
  SG_UF
FROM escolas
WHERE 
  IN_INTERNET_ADMINISTRATIVO = TRUE AND
  (IN_INTERNET_ALUNOS = FALSE OR IN_INTERNET_ALUNOS IS NULL);


-- 3. melhores rendimentos no enem por escola
SELECT 
  co_entidade,
  no_entidade,
  NU_ANO,
  NU_TAXA_PARTICIPACAO,
  NU_MEDIA_TOT
FROM escolas
WHERE NU_MEDIA_TOT IS NOT NULL
ORDER BY NU_MEDIA_TOT DESC, NU_ANO
LIMIT 20;


-- 4. escolas com todas as dependências presentes
SELECT 
  no_entidade,
  SG_UF
FROM escolas
WHERE 
  IN_AGUA_REDE_PUBLICA = TRUE AND
  IN_ENERGIA_REDE_PUBLICA = TRUE AND
  IN_ESGOTO_REDE_PUBLICA = TRUE AND
  IN_INTERNET = TRUE AND
  IN_BIBLIOTECA = TRUE AND
  IN_BANHEIRO = TRUE AND
  IN_LABORATORIO_INFORMATICA = TRUE;


-- 5. Relação rendimento e dependencia e localização da escola
SELECT 
  tp_dependencia,
  COUNT(*) AS qtd_escolas,
  ROUND(AVG(ENSINO_MEDIO), 2) AS media_ensino_medio
FROM escolas
WHERE ENSINO_MEDIO IS NOT NULL
GROUP BY tp_dependencia
ORDER BY media_ensino_medio DESC;
