<?php

namespace Tests\Unit;

use App\Models\Motorista;
use App\Services\MotoristaService;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class MotoristaServiceTest extends TestCase
{
    private MotoristaService $service;

    protected function setUp(): void
    {
        parent::setUp();

        Schema::dropIfExists('motoristas');

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

        $this->service = app(MotoristaService::class);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('motoristas');

        parent::tearDown();
    }

    private function criarMotorista(array $dados = []): Motorista
    {
        return Motorista::create(array_merge([
            'nome' => 'João da Silva',
            'cnh' => '12345678901',
            'categoria_cnh' => 'AB',
            'telefone' => '42999999999',
            'data_admissao' => '2025-01-10',
            'status' => 'ativo',
            'validade_cnh' => '2028-01-10',
        ], $dados));
    }

    public function test_lista_motoristas(): void
    {
        $this->criarMotorista();

        $this->criarMotorista([
            'nome' => 'Maria Oliveira',
            'cnh' => '98765432100',
        ]);

        $resultado = $this->service->listar();

        $this->assertCount(2, $resultado);
    }

    public function test_busca_motorista_por_id(): void
    {
        $motorista = $this->criarMotorista();

        $resultado = $this->service->buscarPorId(
            $motorista->id_motorista
        );

        $this->assertNotNull($resultado);

        $this->assertEquals(
            $motorista->id_motorista,
            $resultado->id_motorista
        );
    }

    public function test_retorna_null_quando_motorista_nao_existe(): void
    {
        $resultado = $this->service->buscarPorId(999999);

        $this->assertNull($resultado);
    }

    public function test_cadastra_motorista(): void
    {
        $dados = [
            'nome' => 'Carlos Souza',
            'cnh' => '11122233344',
            'categoria_cnh' => 'D',
            'telefone' => '42988887777',
            'data_admissao' => '2026-01-15',
            'status' => 'ativo',
            'validade_cnh' => '2029-01-15',
        ];

        $motorista = $this->service->cadastrar($dados);

        $this->assertDatabaseHas('motoristas', [
            'id_motorista' => $motorista->id_motorista,
            'nome' => 'Carlos Souza',
            'cnh' => '11122233344',
        ]);
    }

    public function test_atualiza_motorista(): void
    {
        $motorista = $this->criarMotorista();

        $resultado = $this->service->atualizar(
            $motorista->id_motorista,
            ['nome' => 'João Atualizado']
        );

        $this->assertNotNull($resultado);

        $this->assertEquals('João Atualizado', $resultado->nome);
    }

    public function test_retorna_null_ao_atualizar_motorista_inexistente(): void
    {
        $resultado = $this->service->atualizar(
            999999,
            ['nome' => 'Nome inexistente']
        );

        $this->assertNull($resultado);
    }

    public function test_exclui_motorista(): void
    {
        $motorista = $this->criarMotorista();

        $resultado = $this->service->excluir(
            $motorista->id_motorista
        );

        $this->assertTrue($resultado);

        $this->assertDatabaseMissing('motoristas', [
            'id_motorista' => $motorista->id_motorista,
        ]);
    }

    public function test_retorna_false_ao_excluir_motorista_inexistente(): void
    {
        $resultado = $this->service->excluir(999999);

        $this->assertFalse($resultado);
    }
}
