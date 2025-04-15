import pandas as pd
from geopy.geocoders import Nominatim
from geopy.exc import GeocoderTimedOut, GeocoderUnavailable
import time

def limpar_numero(numero):
    """Função para verificar se o número é válido ou deve ser ignorado"""
    if pd.isna(numero) or str(numero).upper() in ['SN', 'S/N', 'S/NO', 'S/NUM', '']:
        return None
    return str(numero).strip('"')  # Remove aspas extras se houver

def obter_coordenadas(rua, numero=None):
    """Função para obter as coordenadas de um endereço"""
    geolocator = Nominatim(user_agent="postos_saude_fortaleza")
    
    # Construir o endereço completo
    endereco = f"{rua}"
    if numero:
        endereco += f", {numero}"
    endereco += ", Fortaleza, Ceará, Brasil"
    
    try:
        # Aguardar 1 segundo entre as requisições
        time.sleep(1)
        
        # Tentar obter a localização
        location = geolocator.geocode(endereco)
        
        if location:
            return location.latitude, location.longitude
        else:
            # Se não encontrar com número, tentar apenas com a rua
            if numero:
                time.sleep(1)
                endereco = f"{rua}, Fortaleza, Ceará, Brasil"
                location = geolocator.geocode(endereco)
                if location:
                    return location.latitude, location.longitude
            return None, None
            
    except (GeocoderTimedOut, GeocoderUnavailable) as e:
        print(f"Erro ao geocodificar {endereco}: {str(e)}")
        return None, None

def processar_arquivo(arquivo_csv):
    """Função principal para processar o arquivo CSV"""
    # Ler o arquivo CSV com o separador correto e encoding
    df = pd.read_csv(arquivo_csv, sep=';', encoding='utf-8')
    
    # Criar colunas para latitude e longitude
    df['latitude'] = None
    df['longitude'] = None
    
    # Processar cada linha
    for idx, row in df.iterrows():
        rua = row['rua'].strip('"')  # Remove aspas extras
        numero = limpar_numero(row['numero'])
        
        # Imprimir progresso atual
        print(f"Processando {idx+1}/{len(df)}: {row['nome']}")
        
        lat, lon = obter_coordenadas(rua, numero)
        
        df.at[idx, 'latitude'] = lat
        df.at[idx, 'longitude'] = lon
        
        # Imprimir resultado
        print(f"Coordenadas encontradas: Lat: {lat}, Lon: {lon}\n")
    
    # Salvar resultado em um novo arquivo
    arquivo_saida = 'teste.csv'
    df.to_csv(arquivo_saida, sep=';', index=False, encoding='utf-8')
    print(f"\nProcessamento concluído. Resultado salvo em: {arquivo_saida}")

# Uso do programa
if __name__ == "__main__":
    arquivo_csv = "posto_202502170832.csv"  
    processar_arquivo(arquivo_csv)