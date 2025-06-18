################### IMPLEMENTAÇÃO DO BANCO DE DADOS ##########################

# Importando as bibliotecas necessárias
import duckdb
import pandas as pd

# Conectando ao banco de dados DuckDB
con = duckdb.connect(database='path/to/src/database.duckdb', read_only=False) # botar caminho para o arquivo de banco de dados


consultas = [
    {
        "descricao": "1. Escolas com mais de uma fonte de água",
        "sql": """
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
        """
    },
    {
        "descricao": "2. Escolas com internet apenas para administrativo",
        "sql": """
            SELECT 
                no_entidade,
                sg_uf
            FROM escolas
            WHERE 
                in_internet_administrativo = TRUE AND
                COALESCE(in_internet_alunos, FALSE) = FALSE AND 
                COALESCE(in_internet_aprendizagem, FALSE) = FALSE;
        """
    },
    {
        "descricao": "3. Melhores rendimentos no ENEM por escola",
        "sql": """
            SELECT 
                co_entidade,
                no_entidade,
                nu_ano_censo AS nu_ano,
                nu_taxa_participacao,
                nu_media_tot
            FROM escolas
            WHERE nu_media_tot IS NOT NULL
            ORDER BY nu_media_tot DESC, nu_ano;
        """
    },
    {
        "descricao": "Escolas com infraestrutura completa (água, energia e esgoto de rede publica com internet, biblioteca, banheiro e laboratório de informática presentes)",
        "sql": """
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
        """
    },
    {
        "descricao": "5. Relação entre rendimento e dependência da escola",
        "sql": """
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
        """
    },
    {
        "descricao": "6. Distribuição de escolas por localização (urbana/rural) e porte",
        "sql": """
            SELECT 
                tp_localizacao,
                porte_escola,
                COUNT(*) AS qtd_escolas
            FROM escolas
            GROUP BY tp_localizacao, porte_escola
            ORDER BY tp_localizacao, qtd_escolas DESC;
        """
    },
    {
        "descricao": "7. Escolas que oferecem internet mas não possuem laboratório de informática",
        "sql": """
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
        """
    },
    {
        "descricao": "8. Classificação das escolas por faixa de taxa de participação no ENEM",
        "sql": """
            SELECT 
                CASE 
                    WHEN nu_taxa_participacao < 40 THEN 'Baixa participação (<40%)'
                    WHEN nu_taxa_participacao BETWEEN 40 AND 60 THEN 'Média participação (40–60%)'
                    WHEN nu_taxa_participacao > 60 THEN 'Alta participação (>60%)'
                ELSE 'Sem dados'
                END AS faixa_participacao,
                COUNT(*) AS qtd_escolas
            FROM escolas
            GROUP BY faixa_participacao
            ORDER BY qtd_escolas DESC;
        """
    }
]


# Função para criar a tabelas

def create_tables():
    print("Criando tabelas...")
    con.execute("drop table if exists escolas")
    con.execute("create table if not exists escolas (NU_ANO_CENSO integer,CO_ENTIDADE integer,IN_AGUA_REDE_PUBLICA boolean,IN_AGUA_POCO_ARTESIANO boolean," \
    "IN_AGUA_CACIMBA boolean,IN_AGUA_FONTE_RIO boolean" \
    ",IN_AGUA_INEXISTENTE boolean,QT_PROF_SAUDE float,QT_PROF_PSICOLOGO float,QT_PROF_ASSIST_SOCIAL float" \
    ",IN_AREA_VERDE boolean," \
    "IN_BANHEIRO boolean,IN_BIBLIOTECA boolean,IN_LABORATORIO_INFORMATICA boolean," \
    "IN_ENERGIA_REDE_PUBLICA boolean," \
    "IN_ENERGIA_GERADOR_FOSSIL boolean,IN_ENERGIA_RENOVAVEL boolean,IN_ENERGIA_INEXISTENTE boolean," \
    "IN_ESGOTO_REDE_PUBLICA boolean,IN_ESGOTO_FOSSA_SEPTICA boolean,IN_ESGOTO_FOSSA_COMUM boolean," \
    "IN_ESGOTO_FOSSA boolean," \
    "IN_ESGOTO_INEXISTENTE boolean,IN_INTERNET boolean,IN_INTERNET_ALUNOS boolean," \
    "IN_INTERNET_ADMINISTRATIVO boolean," \
    "IN_INTERNET_APRENDIZAGEM boolean,TP_REDE_LOCAL boolean,NU_MATRICULAS float,NU_PARTICIPANTES float," \
    "NU_TAXA_PARTICIPACAO float," \
    "NU_MEDIA_TOT float,PORTE_ESCOLA text,FUNDAMENTAL float,ENSINO_MEDIO float," \
    "NO_ENTIDADE text,TP_DEPENDENCIA text," \
    "TP_LOCALIZACAO text,NO_MUNICIPIO text,SG_UF text)")
    print("Tabelas criadas com sucesso ")

def insert_data():
    print("Iniciando importação de dados...")
    df_escolas = pd.read_csv('/path/to/escolas.csv')  # botar caminho para o arquivo csv
    # registrar o dataframe
    con.register('df_escolas', df_escolas)
    con.execute("insert into escolas select * from df_escolas")
    print("Importação de dados concluída")

def run_queries():
    print("Executando consultas...")
    for idx, consulta in enumerate(consultas, 1):
        print(f"\nConsulta {idx}: {consulta['descricao']}")
        df_resultado = con.execute(consulta["sql"]).fetchdf()
        print(df_resultado)


def main():
    create_tables()
    insert_data()
    result = con.execute("SELECT * FROM escolas LIMIT 5").fetchdf()
    print("Dados importados: \n", result)
    run_queries()

if __name__ == "__main__":
    main()
    con.close()
    print("Conexão com o banco de dados fechada.")
    print("Fim do programa.")

