################### IMPLEMENTAÇÃO DO BANCO DE DADOS ##########################

# Importando as bibliotecas necessárias
import duckdb
import pandas as pd

# Conectando ao banco de dados DuckDB
con = duckdb.connect(database='/home/parcv/Documentos/comput/faculdade/mc536/MC536/src/database.duckdb', read_only=False)

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
    print("Iniciando impoertação de dados...")
    df_escolas = pd.read_csv('/home/parcv/Documentos/comput/faculdade/mc536/MC536/data/escolas.csv')
    # registrar o dataframe
    con.register('df_escolas', df_escolas)
    con.execute("insert into escolas select * from df_escolas")
    print("Importação de dados concluída")

def main():
    create_tables()
    insert_data()
    result = con.execute("SELECT * FROM escolas LIMIT 5").fetchdf()
    print(result)

if __name__ == "__main__":
    main()
    con.close()
    print("Conexão com o banco de dados fechada.")
    print("Fim do programa.")

