<?php

namespace Tests\Unit;

use App\Models\Viagem;
use App\Services\ViagemService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class ViagemServiceTest extends TestCase
{
    private ViagemService $service;

    protected function setUp(): void
    {
        parent::setUp();

        Schema::dropIfExists('viagens');
        Schema::dropIfExists('motoristas');
        Schema::dropIfExists('veiculos');

        Schema::create('veiculos', function ($table) {
            $table->increments('id_veiculo');
            $table->string('placa', 10);
            $table->string('marca', 50);
            $table->string('modelo', 50);
            $table->integer('ano');
            $table->string('tipo', 30);
            $table->decimal('capacidade', 10, 2)->nullable();
            $table->string('status', 20);
            $table->integer('quilometragem_atual')->default(0);
        });

        Schema::create('motoristas', function ($table) {
            $table->increments('id_motorista');
            $table->string('nome', 100);
            $table->string('cnh', 20)->unique();
            $table->string('categoria_cnh', 5);
            $table->string('telefone', 20)->nullable();
            $table->date('data_admissao');
            $table->string('status', 20);
            $table->date('validade_cnh')->nullable();
        });

        Schema::create('viagens', function ($table) {
            $table->increments('id_viagem');
            $table->integer('id_veiculo');
            $table->integer('id_motorista');
            $table->dateTime('data_saida');
            $table->dateTime('data_retorno')->nullable();
            $table->integer('km_inicial');
            $table->integer('km_final')->nullable();
            $table->string('destino', 100);
            $table->string('finalidade', 255)->nullable();
        });

        $this->service = app(ViagemService::class);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('viagens');
        Schema::dropIfExists('motoristas');
        Schema::dropIfExists('veiculos');

        parent::tearDown();
    }

    private function criarDadosRelacionados(): void
    {
        DB::table('veiculos')->insert([
            'id_veiculo' => 1,
            'placa' => 'ABC1D23',
            'marca' => 'Volkswagen',
            'modelo' => 'Saveiro',
            'ano' => 2020,
            'tipo' => 'utilitario',
            'capacidade' => 0.75,
            'status' => 'ativo',
            'quilometragem_atual' => 1000,
        ]);

        DB::table('motoristas')->insert([
            'id_motorista' => 1,
            'nome' => 'João da Silva',
            'cnh' => '12345678901',
            'categoria_cnh' => 'AB',
            'telefone' => '42999999999',
            'data_admissao' => '2025-01-10',
            'status' => 'ativo',
            'validade_cnh' => '2028-01-10',
        ]);
    }

    private function criarViagem(): Viagem
    {
        $this->criarDadosRelacionados();

        return Viagem::create([
            'id_veiculo' => 1,
            'id_motorista' => 1,
            'data_saida' => '2026-10-30 08:00:00',
            'data_retorno' => null,
            'km_inicial' => 1000,
            'km_final' => null,
            'destino' => 'Curitiba',
            'finalidade' => 'Transporte de mercadorias',
        ]);
    }

    public function test_lista_viagens(): void
    {
        $this->criarViagem();

        $resultado = $this->service->listar();

        $this->assertCount(1, $resultado);
    }

    public function test_busca_viagem_por_id(): void
    {
        $viagem = $this->criarViagem();

        $resultado = $this->service->buscarPorId(
            $viagem->id_viagem
        );

        $this->assertNotNull($resultado);

        $this->assertEquals(
            $viagem->id_viagem,
            $resultado->id_viagem
        );

        $this->assertEquals(
            'ABC1D23',
            $resultado->veiculo->placa
        );

        $this->assertEquals(
            'João da Silva',
            $resultado->motorista->nome
        );
    }

    public function test_retorna_null_quando_viagem_nao_existe(): void
    {
        $resultado = $this->service->buscarPorId(999999);

        $this->assertNull($resultado);
    }

    public function test_inicia_viagem_chamando_procedure(): void
    {
        $consultas = DB::connection()->pretend(function () {
            $this->service->iniciar([
                'id_veiculo' => 1,
                'id_motorista' => 1,
                'destino' => 'Curitiba',
                'finalidade' => 'Transporte de mercadorias',
                'km_inicial' => 1000,
            ]);
        });

        $this->assertCount(1, $consultas);

        $this->assertSame(
            "CALL gabriel_trabalho_bd.sp_iniciar_viagem(1, 1, 'Curitiba', 'Transporte de mercadorias', 1000)",
            $consultas[0]['query']
        );
    }

    public function test_finaliza_viagem_chamando_procedure(): void
    {
        $consultas = DB::connection()->pretend(function () {
            $this->service->finalizar(1, 1500);
        });

        $this->assertCount(1, $consultas);

        $this->assertSame(
            'CALL gabriel_trabalho_bd.sp_finalizar_viagem(1, 1500)',
            $consultas[0]['query']
        );
    }

    public function test_inicia_viagem_com_finalidade_nula(): void
    {
        $consultas = DB::connection()->pretend(function () {
            $this->service->iniciar([
                'id_veiculo' => 1,
                'id_motorista' => 1,
                'destino' => 'Curitiba',
                'km_inicial' => 1000,
            ]);
        });

        $this->assertCount(1, $consultas);

        $this->assertSame(
            "CALL gabriel_trabalho_bd.sp_iniciar_viagem(1, 1, 'Curitiba', null, 1000)",
            $consultas[0]['query']
        );
    }
}
