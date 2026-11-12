<?php

namespace Tests\Unit;

use App\Models\Abastecimento;
use App\Services\AbastecimentoService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class AbastecimentoServiceTest extends TestCase
{
    private AbastecimentoService $service;

    protected function setUp(): void
    {
        parent::setUp();

        Schema::dropIfExists('abastecimentos');
        Schema::dropIfExists('veiculos');

        Schema::create('veiculos', function ($table) {
            $table->increments('id_veiculo');
            $table->string('placa')->nullable();
        });

        Schema::create('abastecimentos', function ($table) {
            $table->increments('id_abastecimento');
            $table->integer('id_veiculo');
            $table->date('data_abastecimento');
            $table->string('tipo_combustivel', 30);
            $table->decimal('litros', 10, 2);
            $table->decimal('valor_litro', 10, 2);

            // No SQLite de teste, a trigger do PostgreSQL
            // não existe para preencher este campo.
            $table->decimal('valor_total', 10, 2)->nullable();

            $table->integer('quilometragem');
        });

        $this->service = app(AbastecimentoService::class);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('abastecimentos');
        Schema::dropIfExists('veiculos');

        parent::tearDown();
    }

    private function criarAbastecimento(array $dados = []): void
    {
        DB::table('abastecimentos')->insert(array_merge([
            'id_veiculo' => 1,
            'data_abastecimento' => '2026-10-30',
            'tipo_combustivel' => 'Diesel',
            'litros' => 50.00,
            'valor_litro' => 6.00,
            'valor_total' => 300.00,
            'quilometragem' => 15000,
        ], $dados));
    }

    public function test_lista_abastecimentos(): void
    {
        $this->criarAbastecimento([
            'data_abastecimento' => '2026-10-29',
        ]);

        $this->criarAbastecimento([
            'data_abastecimento' => '2026-10-30',
        ]);

        $resultado = $this->service->listar();

        $this->assertCount(2, $resultado);

        $this->assertEquals(
            '2026-10-30',
            $resultado->first()->data_abastecimento->format('Y-m-d')
        );
    }

    public function test_busca_abastecimento_por_id(): void
    {
        $this->criarAbastecimento();

        $resultado = $this->service->buscarPorId(1);

        $this->assertNotNull($resultado);

        $this->assertEquals(1, $resultado->id_abastecimento);
        $this->assertEquals(1, $resultado->id_veiculo);
        $this->assertEquals('Diesel', $resultado->tipo_combustivel);
        $this->assertEquals(15000, $resultado->quilometragem);
    }

    public function test_retorna_null_quando_abastecimento_nao_existe(): void
    {
        $resultado = $this->service->buscarPorId(999999);

        $this->assertNull($resultado);
    }

    public function test_registra_abastecimento(): void
    {
        $resultado = $this->service->registrar([
            'id_veiculo' => 1,
            'data_abastecimento' => '2026-10-30',
            'tipo_combustivel' => 'Gasolina',
            'litros' => 40.00,
            'valor_litro' => 6.50,
            'quilometragem' => 16000,
        ]);

        $this->assertInstanceOf(Abastecimento::class, $resultado);

        $this->assertNotNull($resultado->id_abastecimento);

        $this->assertEquals(1, $resultado->id_veiculo);
        $this->assertEquals('Gasolina', $resultado->tipo_combustivel);
        $this->assertEquals('40.00', $resultado->litros);
        $this->assertEquals('6.50', $resultado->valor_litro);
        $this->assertEquals(16000, $resultado->quilometragem);

        $this->assertDatabaseHas('abastecimentos', [
            'id_abastecimento' => $resultado->id_abastecimento,
            'id_veiculo' => 1,
            'tipo_combustivel' => 'Gasolina',
            'quilometragem' => 16000,
        ]);
    }

    public function test_registra_abastecimento_sem_informar_valor_total(): void
    {
        $resultado = $this->service->registrar([
            'id_veiculo' => 1,
            'data_abastecimento' => '2026-11-01',
            'tipo_combustivel' => 'Etanol',
            'litros' => 30.00,
            'valor_litro' => 4.50,
            'quilometragem' => 17000,
        ]);

        $this->assertNotNull($resultado->id_abastecimento);

        $this->assertEquals('Etanol', $resultado->tipo_combustivel);

        $this->assertSame('135.00', $resultado->valor_total);
    }
}
