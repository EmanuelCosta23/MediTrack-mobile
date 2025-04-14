import os
import psycopg2
import random
from typing import List, Tuple
from datetime import datetime

def print_com_timestamp(mensagem: str):
    """Imprime mensagem com timestamp."""
    timestamp = datetime.now().strftime('%H:%M:%S')
    print(f"[{timestamp}] {mensagem}")

def conectar_banco():
    """Estabelece conexão com o banco de dados."""
    print_com_timestamp("Tentando conectar ao banco de dados...")
    try:
        conn = psycopg2.connect(
            dbname=os.getenv("DB_NAME"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            host=os.getenv("DB_HOST"),
            port=os.getenv("DB_PORT")
        )
        print_com_timestamp("Conexão estabelecida com sucesso!")
        return conn
    except Exception as e:
        print_com_timestamp(f"❌ Erro ao conectar ao banco: {e}")
        return None

def obter_dados(conn) -> Tuple[List[str], List[str]]:
    """Obtém todos os IDs de medicamentos e postos."""
    print_com_timestamp("Obtendo dados do banco...")
    with conn.cursor() as cur:
        # Obtém medicamentos
        cur.execute("SELECT id, produto FROM medicamento")
        medicamentos = [(row[0], row[1]) for row in cur.fetchall()]

        # Obtém postos
        cur.execute("SELECT id, nome FROM posto")
        postos = [(row[0], row[1]) for row in cur.fetchall()]

        print_com_timestamp(f"✓ Encontrados {len(medicamentos)} medicamentos e {len(postos)} postos")
        return medicamentos, postos

def distribuir_medicamentos(conn, medicamentos: List[Tuple[str, str]], postos: List[Tuple[str, str]]):
    """Realiza a distribuição aleatória dos medicamentos pelos postos."""
    print_com_timestamp("\nIniciando processo de distribuição...")

    with conn.cursor() as cur:
        # Limpa registros existentes
        print_com_timestamp("Limpando registros existentes...")
        cur.execute("DELETE FROM medicamento_posto")
        print_com_timestamp("✓ Registros anteriores removidos")

        total_distribuicoes = 0
        print_com_timestamp("\nIniciando distribuição medicamento por medicamento:")
        print_com_timestamp("=" * 50)

        for medicamento_id, medicamento_nome in medicamentos:
            # Decide aleatoriamente em quantos postos este medicamento estará
            num_postos = random.randint(1, len(postos))

            # Seleciona postos aleatoriamente
            postos_selecionados = random.sample(postos, num_postos)

            print_com_timestamp(f"\nDistribuindo: {medicamento_nome}")
            print_com_timestamp(f"Será distribuído em {num_postos} postos")

            # Para cada posto selecionado, cria um registro com quantidade aleatória
            for posto_id, posto_nome in postos_selecionados:
                quantidade = random.randint(0, 100)

                try:
                    cur.execute("""
                        INSERT INTO medicamento_posto 
                        (medicamento_id, posto_id, quantidade_estoque)
                        VALUES (%s, %s, %s)
                    """, (medicamento_id, posto_id, quantidade))

                    print_com_timestamp(f"  → {posto_nome}: {quantidade} unidades")
                    total_distribuicoes += 1

                except Exception as e:
                    print_com_timestamp(f"❌ Erro ao inserir {medicamento_nome} no posto {posto_nome}: {e}")
                    conn.rollback()
                    continue

        conn.commit()
        print_com_timestamp("\n" + "=" * 50)
        print_com_timestamp(f"✓ Total de distribuições realizadas: {total_distribuicoes}")

def imprimir_estatisticas(conn):
    """Imprime estatísticas detalhadas sobre a distribuição."""
    print_com_timestamp("\nGerando estatísticas finais...")
    print_com_timestamp("=" * 50)

    with conn.cursor() as cur:
        # Total de distribuições
        cur.execute("SELECT COUNT(*) FROM medicamento_posto")
        total = cur.fetchone()[0]
        print_com_timestamp(f"\n📊 Total de distribuições realizadas: {total}")

        # Top 3 medicamentos em mais postos
        cur.execute("""
            SELECT m.produto, COUNT(mp.posto_id) as num_postos
            FROM medicamento m
            JOIN medicamento_posto mp ON m.id = mp.medicamento_id
            GROUP BY m.produto
            ORDER BY num_postos DESC
            LIMIT 3
        """)
        print_com_timestamp("\n🏆 Top 3 medicamentos mais distribuídos:")
        for i, (produto, num_postos) in enumerate(cur.fetchall(), 1):
            print_com_timestamp(f"  {i}º {produto}: {num_postos} postos")

        # Top 3 postos com mais medicamentos
        cur.execute("""
            SELECT p.nome, COUNT(mp.medicamento_id) as num_medicamentos,
                    SUM(mp.quantidade_estoque) as total_estoque
            FROM posto p
            JOIN medicamento_posto mp ON p.id = mp.posto_id
            GROUP BY p.nome
            ORDER BY num_medicamentos DESC
            LIMIT 3
        """)
        print_com_timestamp("\n🏥 Top 3 postos com maior variedade:")
        for i, (posto, num_medicamentos, total_estoque) in enumerate(cur.fetchall(), 1):
            print_com_timestamp(f"  {i}º {posto}: {num_medicamentos} medicamentos (Total em estoque: {total_estoque})")

        # Estatísticas gerais
        cur.execute("""
            SELECT
                AVG(quantidade_estoque)::integer as media_estoque,
                MIN(quantidade_estoque) as min_estoque,
                MAX(quantidade_estoque) as max_estoque
            FROM medicamento_posto
        """)
        media, minimo, maximo = cur.fetchone()
        print_com_timestamp(f"\n📈 Estatísticas de estoque:")
        print_com_timestamp(f"  → Média por distribuição: {media} unidades")
        print_com_timestamp(f"  → Menor quantidade: {minimo} unidades")
        print_com_timestamp(f"  → Maior quantidade: {maximo} unidades")

def main():
    print_com_timestamp("\nIniciando processo de distribuição de medicamentos")
    print_com_timestamp("=" * 50)

    # Conecta ao banco
    conn = conectar_banco()
    if not conn:
        return

    try:
        # Obtém dados necessários
        medicamentos, postos = obter_dados(conn)

        if not medicamentos or not postos:
            print_com_timestamp("❌ Erro: Não foram encontrados medicamentos ou postos no banco")
            return

        # Realiza a distribuição
        distribuir_medicamentos(conn, medicamentos, postos)

        # Imprime estatísticas
        imprimir_estatisticas(conn)

        print_com_timestamp("\n✨ Processo finalizado com sucesso!")

    except Exception as e:
        print_com_timestamp(f"❌ Erro durante a execução: {e}")
    finally:
        conn.close()
        print_com_timestamp("Conexão com o banco fechada")

if __name__ == "__main__":
    main()