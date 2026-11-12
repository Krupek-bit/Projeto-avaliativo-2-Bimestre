<?php

namespace Tests\Unit;

use App\Models\Manutencao;
use App\Services\ManutencaoService;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class ManutencaoServiceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::dropIfExists('manutencoes');
        Schema::dropIfExists('veiculos');

        Schema::create('veiculos', function (Blueprint $table) {
            $table->increments('id_veiculo');
            $table->string('placa')->nullable();
        });

        Schema::create('manutencoes', function (Blueprint $table) {
            $table->increments('id_manutencao');
            $table->integer('id_veiculo');
            $table->date('data_manutencao');
            $table->string('tipo_manutencao', 50);
            $table->string('descricao', 255);
            $table->string('oficina', 100)->nullable();
            $table->decimal('valor', 10, 2);
            $table->integer('quilometragem');
        });
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('manutencoes');
        Schema::dropIfExists('veiculos');

        parent::tearDown();
    }

    public function test_lista_manutencoes_com_veiculos(): void
    {
        DB::table('veiculos')->insert([
            'id_veiculo' => 1,
            'placa' => 'ABC-1234',
        ]);

        DB::table('manutencoes')->insert([
            [
                'id_manutencao' => 1,
                'id_veiculo' => 1,
                'data_manutencao' => '2026-01-10',
                'tipo_manutencao' => 'Preventiva',
                'descricao' => 'Troca de óleo',
                'oficina' => 'Oficina A',
                'valor' => 250.00,
                'quilometragem' => 10000,
            ],
            [
                'id_manutencao' => 2,
                'id_veiculo' => 1,
                'data_manutencao' => '2026-02-10',
                'tipo_manutencao' => 'Corretiva',
                'descricao' => 'Reparo no motor',
                'oficina' => 'Oficina B',
                'valor' => 500.00,
                'quilometragem' => 12000,
            ],
        ]);

        $service = new ManutencaoService;

        $resultado = $service->listar();

        $this->assertInstanceOf(LengthAwarePaginator::class, $resultado);
        $this->assertCount(2, $resultado);
        $this->assertEquals(2, $resultado->first()->id_manutencao);
        $this->assertEquals(
            'ABC-1234',
            $resultado->first()->veiculo->placa
        );
    }

    public function test_busca_manutencao_por_id(): void
    {
        DB::table('veiculos')->insert([
            'id_veiculo' => 1,
            'placa' => 'ABC-1234',
        ]);

        DB::table('manutencoes')->insert([
            'id_manutencao' => 1,
            'id_veiculo' => 1,
            'data_manutencao' => '2026-01-10',
            'tipo_manutencao' => 'Preventiva',
            'descricao' => 'Troca de óleo',
            'oficina' => 'Oficina A',
            'valor' => 250.00,
            'quilometragem' => 10000,
        ]);

        $service = new ManutencaoService;

        $resultado = $service->buscarPorId(1);

        $this->assertInstanceOf(Manutencao::class, $resultado);
        $this->assertEquals(1, $resultado->id_manutencao);
        $this->assertEquals(
            'ABC-1234',
            $resultado->veiculo->placa
        );
    }

    public function test_retorna_null_quando_manutencao_nao_existe(): void
    {
        $service = new ManutencaoService;

        $resultado = $service->buscarPorId(999);

        $this->assertNull($resultado);
    }

    public function test_registra_manutencao_chamando_procedure(): void
    {
        $dados = [
            'id_veiculo' => 1,
            'tipo_manutencao' => 'Preventiva',
            'descricao' => 'Troca de óleo',
            'oficina' => 'Oficina A',
            'valor' => 250.00,
            'quilometragem' => 10000,
        ];

        $queries = DB::connection()->pretend(function () use ($dados) {
            (new ManutencaoService)->registrar($dados);
        });

        $this->assertCount(1, $queries);

        $this->assertStringContainsString(
            'sp_registrar_manutencao',
            $queries[0]['query']
        );
    }

    public function test_conclui_manutencao_chamando_procedure(): void
    {
        $queries = DB::connection()->pretend(function () {
            (new ManutencaoService)->concluir(1);
        });

        $this->assertCount(1, $queries);

        $this->assertStringContainsString(
            'sp_concluir_manutencao',
            $queries[0]['query']
        );
    }
}
