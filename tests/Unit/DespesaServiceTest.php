<?php

namespace Tests\Unit;

use App\Models\Despesa;
use App\Services\DespesaService;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class DespesaServiceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::dropIfExists('despesas');
        Schema::dropIfExists('veiculos');

        Schema::create('veiculos', function (Blueprint $table) {
            $table->increments('id_veiculo');
            $table->string('placa')->nullable();
        });

        Schema::create('despesas', function (Blueprint $table) {
            $table->increments('id_despesa');
            $table->integer('id_veiculo');
            $table->date('data_despesa');
            $table->string('tipo_despesa', 50);
            $table->string('descricao', 255)->nullable();
            $table->decimal('valor', 10, 2);
        });
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('despesas');
        Schema::dropIfExists('veiculos');

        parent::tearDown();
    }

    private function criarVeiculo(): void
    {
        DB::table('veiculos')->insert([
            'id_veiculo' => 1,
            'placa' => 'ABC-1234',
        ]);
    }

    private function criarDespesa(): void
    {
        DB::table('despesas')->insert([
            'id_despesa' => 1,
            'id_veiculo' => 1,
            'data_despesa' => '2026-01-10',
            'tipo_despesa' => 'Combustível',
            'descricao' => 'Abastecimento',
            'valor' => 250.00,
        ]);
    }

    public function test_lista_despesas_com_veiculos(): void
    {
        $this->criarVeiculo();

        DB::table('despesas')->insert([
            [
                'id_despesa' => 1,
                'id_veiculo' => 1,
                'data_despesa' => '2026-01-10',
                'tipo_despesa' => 'Combustível',
                'descricao' => 'Abastecimento',
                'valor' => 250.00,
            ],
            [
                'id_despesa' => 2,
                'id_veiculo' => 1,
                'data_despesa' => '2026-02-10',
                'tipo_despesa' => 'Pedágio',
                'descricao' => 'Viagem',
                'valor' => 50.00,
            ],
        ]);

        $service = new DespesaService;

        $resultado = $service->listar();

        $this->assertInstanceOf(LengthAwarePaginator::class, $resultado);
        $this->assertCount(2, $resultado);
        $this->assertEquals(2, $resultado->first()->id_despesa);
        $this->assertEquals('ABC-1234', $resultado->first()->veiculo->placa);
    }

    public function test_busca_despesa_por_id(): void
    {
        $this->criarVeiculo();
        $this->criarDespesa();

        $service = new DespesaService;

        $resultado = $service->buscarPorId(1);

        $this->assertInstanceOf(Despesa::class, $resultado);
        $this->assertEquals(1, $resultado->id_despesa);
        $this->assertEquals('ABC-1234', $resultado->veiculo->placa);
    }

    public function test_retorna_null_quando_despesa_nao_existe(): void
    {
        $service = new DespesaService;

        $resultado = $service->buscarPorId(999);

        $this->assertNull($resultado);
    }

    public function test_cadastra_despesa(): void
    {
        $this->criarVeiculo();

        $dados = [
            'id_veiculo' => 1,
            'data_despesa' => '2026-03-10',
            'tipo_despesa' => 'Manutenção',
            'descricao' => 'Troca de peças',
            'valor' => 350.00,
        ];

        $service = new DespesaService;

        $resultado = $service->cadastrar($dados);

        $this->assertInstanceOf(Despesa::class, $resultado);
        $this->assertEquals(1, $resultado->id_veiculo);
        $this->assertEquals('Manutenção', $resultado->tipo_despesa);
        $this->assertDatabaseHas('despesas', [
            'id_despesa' => $resultado->id_despesa,
            'descricao' => 'Troca de peças',
        ]);
    }

    public function test_atualiza_despesa(): void
    {
        $this->criarVeiculo();
        $this->criarDespesa();

        $service = new DespesaService;

        $resultado = $service->atualizar(1, [
            'tipo_despesa' => 'Pedágio',
            'descricao' => 'Pedágio da viagem',
            'valor' => 75.00,
        ]);

        $this->assertInstanceOf(Despesa::class, $resultado);
        $this->assertEquals('Pedágio', $resultado->tipo_despesa);
        $this->assertEquals('Pedágio da viagem', $resultado->descricao);
        $this->assertDatabaseHas('despesas', [
            'id_despesa' => 1,
            'tipo_despesa' => 'Pedágio',
        ]);
    }

    public function test_retorna_null_ao_atualizar_despesa_inexistente(): void
    {
        $service = new DespesaService;

        $resultado = $service->atualizar(999, [
            'tipo_despesa' => 'Pedágio',
        ]);

        $this->assertNull($resultado);
    }

    public function test_exclui_despesa(): void
    {
        $this->criarVeiculo();
        $this->criarDespesa();

        $service = new DespesaService;

        $resultado = $service->excluir(1);

        $this->assertTrue($resultado);
        $this->assertDatabaseMissing('despesas', [
            'id_despesa' => 1,
        ]);
    }

    public function test_retorna_false_ao_excluir_despesa_inexistente(): void
    {
        $service = new DespesaService;

        $resultado = $service->excluir(999);

        $this->assertFalse($resultado);
    }
}
