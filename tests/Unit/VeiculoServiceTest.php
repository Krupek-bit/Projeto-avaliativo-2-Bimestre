<?php

namespace Tests\Unit;

use App\Models\Veiculo;
use App\Services\VeiculoService;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class VeiculoServiceTest extends TestCase
{
    private VeiculoService $service;

    protected function setUp(): void
    {
        parent::setUp();

        Schema::dropIfExists('veiculos');

        Schema::create('veiculos', function ($table) {
            $table->increments('id_veiculo');
            $table->string('placa', 10)->unique();
            $table->string('marca', 50);
            $table->string('modelo', 50);
            $table->integer('ano');
            $table->string('tipo', 30);
            $table->decimal('capacidade', 10, 2)->nullable();
            $table->string('status', 20);
            $table->integer('quilometragem_atual')->default(0);
        });

        $this->service = app(VeiculoService::class);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('veiculos');

        parent::tearDown();
    }

    private function criarVeiculo(array $dados = []): Veiculo
    {
        return Veiculo::create(array_merge([
            'placa' => 'ABC1D23',
            'marca' => 'Volkswagen',
            'modelo' => 'Saveiro',
            'ano' => 2020,
            'tipo' => 'utilitario',
            'capacidade' => 0.75,
            'status' => 'ativo',
            'quilometragem_atual' => 1000,
        ], $dados));
    }

    public function test_lista_veiculos(): void
    {
        $this->criarVeiculo();

        $this->criarVeiculo([
            'placa' => 'DEF2G34',
        ]);

        $resultado = $this->service->listar();

        $this->assertCount(2, $resultado);
    }

    public function test_busca_veiculo_por_id(): void
    {
        $veiculo = $this->criarVeiculo();

        $resultado = $this->service->buscarPorId(
            $veiculo->id_veiculo
        );

        $this->assertNotNull($resultado);

        $this->assertEquals(
            $veiculo->id_veiculo,
            $resultado->id_veiculo
        );
    }

    public function test_retorna_null_quando_veiculo_nao_existe(): void
    {
        $resultado = $this->service->buscarPorId(999999);

        $this->assertNull($resultado);
    }

    public function test_cadastra_veiculo(): void
    {
        $dados = [
            'placa' => 'XYZ9A87',
            'marca' => 'Fiat',
            'modelo' => 'Strada',
            'ano' => 2024,
            'tipo' => 'utilitario',
            'capacidade' => 0.80,
            'status' => 'ativo',
            'quilometragem_atual' => 500,
        ];

        $veiculo = $this->service->cadastrar($dados);

        $this->assertDatabaseHas('veiculos', [
            'id_veiculo' => $veiculo->id_veiculo,
            'placa' => 'XYZ9A87',
        ]);
    }

    public function test_atualiza_veiculo(): void
    {
        $veiculo = $this->criarVeiculo();

        $resultado = $this->service->atualizar(
            $veiculo->id_veiculo,
            ['marca' => 'Fiat']
        );

        $this->assertEquals('Fiat', $resultado->marca);
    }

    public function test_retorna_null_ao_atualizar_veiculo_inexistente(): void
    {
        $resultado = $this->service->atualizar(
            999999,
            ['marca' => 'Fiat']
        );

        $this->assertNull($resultado);
    }

    public function test_exclui_veiculo(): void
    {
        $veiculo = $this->criarVeiculo();

        $resultado = $this->service->excluir(
            $veiculo->id_veiculo
        );

        $this->assertTrue($resultado);

        $this->assertDatabaseMissing('veiculos', [
            'id_veiculo' => $veiculo->id_veiculo,
        ]);
    }

    public function test_retorna_false_ao_excluir_veiculo_inexistente(): void
    {
        $resultado = $this->service->excluir(999999);

        $this->assertFalse($resultado);
    }
}
