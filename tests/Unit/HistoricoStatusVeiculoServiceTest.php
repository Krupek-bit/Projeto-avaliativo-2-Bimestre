<?php

namespace Tests\Unit;

use App\Models\HistoricoStatusVeiculo;
use App\Models\Veiculo;
use App\Services\HistoricoStatusVeiculoService;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class HistoricoStatusVeiculoServiceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::dropIfExists('historico_status_veiculo');
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

        Schema::create('historico_status_veiculo', function (Blueprint $table) {
            $table->increments('id_historico');
            $table->integer('id_veiculo');
            $table->string('status_anterior', 20)->nullable();
            $table->string('status_novo', 20);
            $table->timestamp('data_alteracao')->useCurrent();
        });
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('historico_status_veiculo');
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

    private function criarHistorico(
        int $idVeiculo,
        string $statusAnterior,
        string $statusNovo
    ): HistoricoStatusVeiculo {
        return HistoricoStatusVeiculo::create([
            'id_veiculo' => $idVeiculo,
            'status_anterior' => $statusAnterior,
            'status_novo' => $statusNovo,
        ]);
    }

    public function test_lista_historicos_com_veiculo(): void
    {
        $veiculo = $this->criarVeiculo();

        $this->criarHistorico(
            $veiculo->id_veiculo,
            'ativo',
            'em_manutencao'
        );

        $resultado = (new HistoricoStatusVeiculoService())->listar();

        $this->assertCount(1, $resultado);
        $this->assertTrue($resultado->first()->relationLoaded('veiculo'));
        $this->assertEquals(
            $veiculo->id_veiculo,
            $resultado->first()->veiculo->id_veiculo
        );
    }

    public function test_busca_historico_por_id(): void
    {
        $veiculo = $this->criarVeiculo();

        $historico = $this->criarHistorico(
            $veiculo->id_veiculo,
            'ativo',
            'em_manutencao'
        );

        $resultado = (new HistoricoStatusVeiculoService())
            ->buscarPorId($historico->id_historico);

        $this->assertNotNull($resultado);
        $this->assertEquals(
            $historico->id_historico,
            $resultado->id_historico
        );
        $this->assertTrue($resultado->relationLoaded('veiculo'));
    }

    public function test_retorna_null_quando_historico_nao_existe(): void
    {
        $resultado = (new HistoricoStatusVeiculoService())
            ->buscarPorId(999);

        $this->assertNull($resultado);
    }

    public function test_lista_historicos_de_um_veiculo(): void
    {
        $veiculo1 = $this->criarVeiculo();

        $veiculo2 = Veiculo::create([
            'placa' => 'DEF-5678',
            'marca' => 'Ford',
            'modelo' => 'Ka',
            'tipo' => 'Carro',
            'capacidade' => 5,
            'status' => 'ativo',
            'ano' => 2021,
            'quilometragem_atual' => 20000,
        ]);

        $this->criarHistorico(
            $veiculo1->id_veiculo,
            'ativo',
            'em_manutencao'
        );

        $this->criarHistorico(
            $veiculo2->id_veiculo,
            'ativo',
            'inativo'
        );

        $resultado = (new HistoricoStatusVeiculoService())
            ->listarPorVeiculo($veiculo1->id_veiculo);

        $this->assertCount(1, $resultado);
        $this->assertEquals(
            $veiculo1->id_veiculo,
            $resultado->first()->id_veiculo
        );
    }

    public function test_retorna_lista_vazia_quando_veiculo_nao_tem_historico(): void
    {
        $veiculo = $this->criarVeiculo();

        $resultado = (new HistoricoStatusVeiculoService())
            ->listarPorVeiculo($veiculo->id_veiculo);

        $this->assertCount(0, $resultado);
    }
}
