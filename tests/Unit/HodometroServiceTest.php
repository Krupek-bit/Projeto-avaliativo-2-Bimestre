<?php

namespace Tests\Unit;

use App\Models\Hodometro;
use App\Models\Veiculo;
use App\Services\HodometroService;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class HodometroServiceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::dropIfExists('hodometros');
        Schema::dropIfExists('veiculos');

        Schema::create('veiculos', function (Blueprint $table) {
            $table->increments('id_veiculo');
            $table->string('placa')->unique();
            $table->string('marca')->nullable();
            $table->string('modelo')->nullable();
            $table->string('tipo')->nullable();
            $table->integer('capacidade')->nullable();
            $table->string('status')->nullable();
            $table->integer('ano')->nullable();
            $table->integer('quilometragem_atual')->default(0);
        });

        Schema::create('hodometros', function (Blueprint $table) {
            $table->increments('id_hodometro');
            $table->integer('id_veiculo');
            $table->date('data_registro');
            $table->integer('quilometragem');
            $table->string('observacao', 255)->nullable();
        });
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('hodometros');
        Schema::dropIfExists('veiculos');

        parent::tearDown();
    }

    private function criarVeiculo(): Veiculo
    {
        return Veiculo::create([
            'placa' => 'ABC-1234',
            'marca' => 'Fiat',
            'modelo' => 'Uno',
            'tipo' => 'Carro',
            'capacidade' => 5,
            'status' => 'ativo',
            'ano' => 2020,
            'quilometragem_atual' => 10000,
        ]);
    }

    public function test_lista_hodometros_com_veiculo(): void
    {
        $veiculo = $this->criarVeiculo();

        Hodometro::create([
            'id_veiculo' => $veiculo->id_veiculo,
            'data_registro' => '2026-11-01',
            'quilometragem' => 12000,
            'observacao' => 'Revisão mensal',
        ]);

        $resultado = (new HodometroService)->listar();

        $this->assertInstanceOf(LengthAwarePaginator::class, $resultado);
        $this->assertCount(1, $resultado);
        $this->assertTrue($resultado->first()->relationLoaded('veiculo'));
        $this->assertEquals(
            $veiculo->id_veiculo,
            $resultado->first()->veiculo->id_veiculo
        );
    }

    public function test_busca_hodometro_por_id(): void
    {
        $veiculo = $this->criarVeiculo();

        $hodometro = Hodometro::create([
            'id_veiculo' => $veiculo->id_veiculo,
            'data_registro' => '2026-11-01',
            'quilometragem' => 12000,
            'observacao' => 'Leitura inicial',
        ]);

        $resultado = (new HodometroService)
            ->buscarPorId($hodometro->id_hodometro);

        $this->assertNotNull($resultado);
        $this->assertEquals(
            $hodometro->id_hodometro,
            $resultado->id_hodometro
        );
        $this->assertTrue($resultado->relationLoaded('veiculo'));
    }

    public function test_retorna_null_quando_hodometro_nao_existe(): void
    {
        $resultado = (new HodometroService)->buscarPorId(999);

        $this->assertNull($resultado);
    }

    public function test_registra_novo_hodometro(): void
    {
        $veiculo = $this->criarVeiculo();

        $dados = [
            'id_veiculo' => $veiculo->id_veiculo,
            'data_registro' => '2026-11-03',
            'quilometragem' => 15000,
            'observacao' => 'Leitura de teste',
        ];

        $resultado = (new HodometroService)->registrar($dados);

        $this->assertInstanceOf(Hodometro::class, $resultado);
        $this->assertEquals($veiculo->id_veiculo, $resultado->id_veiculo);
        $this->assertEquals(15000, $resultado->quilometragem);
        $this->assertEquals('Leitura de teste', $resultado->observacao);

        $this->assertDatabaseHas('hodometros', [
            'id_hodometro' => $resultado->id_hodometro,
            'id_veiculo' => $veiculo->id_veiculo,
            'quilometragem' => 15000,
        ]);
    }

    public function test_registra_hodometro_sem_observacao(): void
    {
        $veiculo = $this->criarVeiculo();

        $resultado = (new HodometroService)->registrar([
            'id_veiculo' => $veiculo->id_veiculo,
            'data_registro' => '2026-11-03',
            'quilometragem' => 16000,
        ]);

        $this->assertNotNull($resultado);
        $this->assertNull($resultado->observacao);
    }
}
