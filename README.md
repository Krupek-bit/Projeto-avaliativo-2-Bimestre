# Projeto-avaliativo-2-Bimestre
Projeto avaliativo 2° Bimestre


# Gestão de Frota

Aplicação web para gerenciar a frota de uma empresa fictícia: veículos, motoristas, viagens, abastecimentos, manutenções e despesas. Projeto avaliativo do 2º bimestre de Engenharia de Software (4º e 5º períodos), das disciplinas de **Banco de Dados II** e **Back-end**, do Centro Universitário Campo Real.

## Integrantes e funções

**Gabriel Krupek (Banco de Dados)**
Responsável pela modelagem e criação do banco de dados no Neon, pela implementação de índices, functions, stored procedures e triggers, pelo procedimento de backup e restauração e pela elaboração dos scripts SQL.

**Kauã Delgado (Front-end)**
Responsável pelo desenvolvimento da interface do sistema, utilizando Laravel e Blade, pela estruturação das páginas, componentes visuais e implementação das funcionalidades de interação com o usuário.

**Gustavo Borges (Back-end)**
Responsável pelo desenvolvimento do back-end utilizando Laravel e PHP, pela implementação das regras de negócio, Controllers, Models, Services, rotas da API e integração com o banco de dados.

## Tecnologias

- PHP e Laravel
- PostgreSQL hospedado no Neon
- Blade e Bootstrap 5 (via CDN)
- Git e GitHub
- PHPUnit (testes automatizados)

## Requisitos

- PHP 8.2 ou superior, com as extensões `pdo_pgsql`, `pgsql`, `mbstring`, `openssl` e `intl` ativas
- Composer
- Connection string do banco no Neon

## Instalação

```bash
git clone https://github.com/USUARIO/REPOSITORIO.git
cd REPOSITORIO
composer install
cp .env.example .env
php artisan key:generate
```

No Windows, use `copy .env.example .env` no lugar do `cp`.

## Configuração do banco

Edite o arquivo `.env` com os dados do Neon:

```env
DB_CONNECTION=pgsql
DB_HOST=ep-small-sound-ac44blz3-pooler.sa-east-1.aws.neon.tech
DB_PORT=5432
DB_DATABASE=gabriel_trabalho_BD
DB_USERNAME=neondb_owner
DB_PASSWORD=npg_j2S7AcosDryQ
DB_SSLMODE=require

SESSION_DRIVER=file
CACHE_STORE=file
QUEUE_CONNECTION=sync
```

- `DB_SSLMODE=require` é obrigatório, pois o Neon só aceita conexões com SSL.
- `SESSION_DRIVER=file`, `CACHE_STORE=file` e `QUEUE_CONNECTION=sync` evitam que o Laravel procure as tabelas `sessions`, `cache` e `jobs`, que não existem no banco da frota.
- O arquivo `.env` não é enviado ao repositório.

Para testar a conexão:

```bash
php artisan config:clear
php artisan db:show
```

## Banco de dados

O banco possui as tabelas `veiculos`, `motoristas`, `viagens`, `abastecimentos`, `manutencoes`, `despesas`, `hodometros`, `modalidade` e `historico_status_veiculo`.

O script SQL com a criação da estrutura, dos dados e dos objetos do banco (índices, functions, stored procedures e triggers) está no arquivo `BancoDeDadosDoProjeto.sql`, na raiz do projeto. Para recriar o banco, execute esse script no SQL Editor do Neon ou em uma ferramenta como DBeaver ou pgAdmin.

A tabela `historico_status_veiculo` registra as mudanças de status dos veículos e é preenchida por trigger.

## Executando a aplicação

```bash
php artisan serve
```

Acesse `http://localhost:8000`.


## Testes automatizados

Os testes usam um banco separado, para que o `RefreshDatabase` não apague os dados principais. No Neon, crie uma branch do banco (por exemplo, `testes`) e configure os dados dela no `phpunit.xml` ou no `.env.testing`.

Para executar:

```bash
php artisan test
```

Os testes cobrem as rotas web (exibição de páginas e operações CRUD) e as rotas da API (estrutura das respostas JSON e códigos de status).

## Estrutura do projeto

```
app/
  Http/Controllers/        controllers web e da API
  Http/Resources/          API Resources
  Models/                  models Eloquent
  Services/                regras de negócio
resources/views/
  layouts/app.blade.php    layout base
  partials/menu.blade.php  menu de navegação
  veiculos/ motoristas/ viagens/ abastecimentos/
  manutencoes/ despesas/ historico/
routes/
  web.php                  rotas web
  api.php                  rotas da API
```

## Front-end

- Views com o sistema de templates Blade (`@extends`, `@section`, `@include`).
- Bootstrap 5 por CDN, com layout responsivo: tabelas com rolagem horizontal, formulários que empilham no celular e menu em hambúrguer.
- Formulários com `@csrf`, `old()` para manter os dados digitados e `@error` para exibir as mensagens de validação.

## Versionamento

O projeto usa Git com branches de funcionalidade (`feature/*`) integradas à `main`, com commits pequenos por funcionalidade.


# Comandos Para Fazer O Backup
cd "C:\Program Files\PostgreSQL\18\bin"

set PGPASSWORD=1234

set NEONURL=postgresql://neondb_owner:npg_j2S7AcosDryQ@ep-small-sound-ac44blz3.sa-east-1.aws.neon.tech/gabriel_trabalho_BD?sslmode=require

psql.exe "%NEONURL%" -c "\dt gabriel_trabalho_bd.*"

pg_dump.exe -Fc -f %USERPROFILE%\Documents\BackupDoBanco.dump "%NEONURL%"

psql.exe -h localhost -U postgres -c "CREATE DATABASE gabriel_trabalho_local;"

pg_restore.exe -h localhost -U postgres -v -O -d gabriel_trabalho_local %USERPROFILE%\Documents\BackupDoBanco.dump

psql.exe -h localhost -U postgres -d gabriel_trabalho_local -c "\dt gabriel_trabalho_bd.*"
