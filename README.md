# MediTrack Mobile

Aplicativo mobile para o sistema MediTrack de gestão de medicamentos.

## Estrutura do Projeto

O projeto está organizado em duas partes principais:

1. **Frontend (Flutter)**: Aplicativo mobile localizado na pasta raiz.
2. **Backend (Spring Boot)**: API REST localizada na pasta `backend/`.

## Requisitos

- Flutter 3.7.0 ou superior
- Dart 3.0.0 ou superior
- Java 17 ou superior
- Maven 3.8.0 ou superior

## Executando o Backend (API)

Para executar o backend Spring Boot, siga os passos abaixo:

```bash
# Navegue para a pasta do backend
cd backend

# Execute o backend com Maven
./mvnw spring-boot:run
```

Para usuários Windows:
```bash
cd backend
mvnw.cmd spring-boot:run
```

A API estará disponível em `http://localhost:8080`.

## Executando o Aplicativo Flutter

Primeiro, certifique-se de que o backend está em execução. Em seguida, execute o aplicativo Flutter:

```bash
# Na pasta raiz do projeto
flutter pub get
flutter run
```

### Importante para emuladores Android

Se você estiver executando o aplicativo em um emulador Android e o backend localmente, a URL da API deve usar o IP especial `10.0.2.2` que corresponde ao localhost do computador host (em vez de `localhost` ou `127.0.0.1`).

Isso já está configurado no arquivo `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://10.0.2.2:8080/api';
```

Se você executar o aplicativo em um dispositivo físico, precisará alterar este endereço para o IP da máquina onde o backend está rodando.

## Integração Frontend-Backend

A integração entre o aplicativo Flutter e a API Spring Boot é feita através de requisições HTTP. As principais integrações implementadas são:

1. **Cadastro de Usuário**: `/api/usuario/cadastro` (POST)
2. **Login**: `/api/usuario/login` (POST)

As classes responsáveis pela integração estão em:
- `lib/services/api_service.dart`: Serviço para chamadas à API

## Funcionalidades Implementadas

- Formatação de CPF em tempo real (apenas visual)
- Formatação de data de nascimento em tempo real (apenas visual)
- Integração com endpoint de cadastro de usuário
- Implementar a autenticação completa (login/logout)
- Salvar token JWT para manter a sessão
- Implementar integração com endpoints de medicamentos
- Implementar integração com endpoints de postos de saúde
- Implementar integração com Google Maps API

## Próximos Passos

- Alterar ícones e atualizar layouts

## Sobre o Aplicativo

MediTrack é uma aplicação móvel desenvolvida em Flutter que permite aos usuários encontrar medicamentos e postos de saúde próximos à sua localização. Com uma interface intuitiva e fácil de usar, o MediTrack é a solução ideal para quem busca localizar serviços de saúde e medicamentos específicos em sua região.

## Funcionalidades Principais

- **Cadastro e Login de Usuários**: Crie sua conta e acesse o aplicativo de forma segura.
- **Localização de Postos de Saúde**: Encontre postos de saúde próximos à sua localização atual.
- **Busca de Medicamentos**: Pesquise medicamentos específicos e descubra onde encontrá-los.
- **Mapas Integrados**: Visualize no mapa os postos de saúde e farmácias disponíveis.
- **Interface Amigável**: Design moderno e intuitivo para facilitar a navegação.

## Como Instalar

### Pré-requisitos
- Flutter SDK (versão 3.0.0 ou superior)
- Dart SDK
- Um dispositivo Android/iOS ou emulador configurado

### Passos para Instalação

1. Clone este repositório:
   ```
   git clone https://github.com/EmanuelCosta23/MediTrack-mobile.git
   ```

2. Navegue até a pasta do projeto:
   ```
   cd MediTrack-mobile
   ```

3. Instale as dependências:
   ```
   flutter pub get
   ```

4. Execute o aplicativo:
   ```
   flutter run
   ```

## Como Usar

1. **Cadastro**: Ao abrir o aplicativo pela primeira vez, cadastre-se fornecendo as informações solicitadas.
2. **Login**: Após o cadastro, efetue o login com suas credenciais.
3. **Tela Inicial**: Na tela inicial, você verá uma lista de postos de saúde próximos.
4. **Menu Lateral**: Acesse o menu lateral para navegar entre as diferentes funcionalidades:
   - Home
   - Postos de Saúde
   - Remédios
   - Vacinas
   - Mapas
5. **Busca de Medicamentos**: Na seção de remédios, você pode pesquisar por medicamentos específicos.
6. **Mapas**: Utilize a função de mapas para visualizar postos de saúde e farmácias em um mapa interativo.

## Tecnologias Utilizadas

- Flutter
- Dart
- Google Maps API
- Spring-boot

## Desenvolvimento

Este aplicativo foi desenvolvido como parte do projeto acadêmico para a disciplina de Projeto aplicado Multiplataforma da UNIFOR - Universidade de Fortaleza.

---

© 2025 MediTrack. Todos os direitos reservados.