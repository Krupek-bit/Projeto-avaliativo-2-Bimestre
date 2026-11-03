<?php

namespace Tests\Unit;

use App\Models\Modalidade;
use App\Services\ModalidadeService;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class ModalidadeServiceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::dropIfExists('modalidade');

        Schema::create('modalidade', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('nome', 100);
            $table->string('descricao', 255)->nullable();
        });
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('modalidade');

        parent::tearDown();
    }

    public function test_lista_modalidades_em_ordem_alfabetica(): void
    {
        Modalidade::create(['nome' => 'Terceirizada']);
        Modalidade::create(['nome' => 'Própria']);

        $resultado = (new ModalidadeService())->listar();

        $this->assertCount(2, $resultado);
        $this->assertEquals('Própria', $resultado->first()->nome);
        $this->assertEquals('Terceirizada', $resultado->last()->nome);
    }

    public function test_busca_modalidade_por_id(): void
    {
        $modalidade = Modalidade::create([
            'nome' => 'Própria',
            'descricao' => 'Frota própria',
        ]);

        $resultado = (new ModalidadeService())
            ->buscarPorId($modalidade->id);

        $this->assertNotNull($resultado);
        $this->assertEquals($modalidade->id, $resultado->id);
    }

    public function test_retorna_null_quando_modalidade_nao_existe(): void
    {
        $resultado = (new ModalidadeService())
            ->buscarPorId('00000000-0000-4000-8000-000000000000');

        $this->assertNull($resultado);
    }

    public function test_cadastra_modalidade(): void
    {
        $resultado = (new ModalidadeService())->cadastrar([
            'nome' => 'Terceirizada',
            'descricao' => 'Veículos de terceiros',
        ]);

        $this->assertInstanceOf(Modalidade::class, $resultado);
        $this->assertNotEmpty($resultado->id);
        $this->assertEquals('Terceirizada', $resultado->nome);

        $this->assertDatabaseHas('modalidade', [
            'id' => $resultado->id,
            'nome' => 'Terceirizada',
        ]);
    }

    public function test_atualiza_modalidade(): void
    {
        $modalidade = Modalidade::create([
            'nome' => 'Própria',
            'descricao' => 'Descrição antiga',
        ]);

        $resultado = (new ModalidadeService())->atualizar(
            $modalidade->id,
            [
                'nome' => 'Frota própria',
                'descricao' => 'Descrição atualizada',
            ]
        );

        $this->assertNotNull($resultado);
        $this->assertEquals('Frota própria', $resultado->nome);
        $this->assertEquals('Descrição atualizada', $resultado->descricao);
    }

    public function test_retorna_null_ao_atualizar_modalidade_inexistente(): void
    {
        $resultado = (new ModalidadeService())->atualizar(
            '00000000-0000-4000-8000-000000000000',
            ['nome' => 'Nova modalidade']
        );

        $this->assertNull($resultado);
    }

    public function test_exclui_modalidade(): void
    {
        $modalidade = Modalidade::create([
            'nome' => 'Temporária',
        ]);

        $resultado = (new ModalidadeService())->excluir($modalidade->id);

        $this->assertTrue($resultado);

        $this->assertDatabaseMissing('modalidade', [
            'id' => $modalidade->id,
        ]);
    }

    public function test_retorna_false_ao_excluir_modalidade_inexistente(): void
    {
        $resultado = (new ModalidadeService())->excluir(
            '00000000-0000-4000-8000-000000000000'
        );

        $this->assertFalse($resultado);
    }
}
