<?php

namespace Tests\Feature\Api;

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class AdditionalApiResourcesTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        foreach (['viagens', 'manutencoes', 'despesas', 'abastecimentos', 'motoristas', 'veiculos'] as $table) {
            Schema::dropIfExists($table);
        }

        Schema::create('veiculos', function (Blueprint $table): void {
            $table->increments('id_veiculo');
            $table->string('placa')->unique();
            $table->string('marca');
            $table->string('modelo');
            $table->integer('ano');
            $table->string('tipo');
            $table->decimal('capacidade', 10, 2)->nullable();
            $table->string('status');
            $table->integer('quilometragem_atual')->default(0);
        });

        Schema::create('motoristas', function (Blueprint $table): void {
            $table->increments('id_motorista');
            $table->string('nome');
            $table->string('cnh')->unique();
            $table->string('categoria_cnh');
            $table->string('telefone')->nullable();
            $table->date('data_admissao');
            $table->date('validade_cnh')->nullable();
            $table->string('status');
        });

        Schema::create('abastecimentos', function (Blueprint $table): void {
            $table->increments('id_abastecimento');
            $table->integer('id_veiculo');
            $table->date('data_abastecimento');
            $table->string('tipo_combustivel');
            $table->decimal('litros', 10, 2);
            $table->decimal('valor_litro', 10, 2);
            $table->decimal('valor_total', 10, 2);
            $table->integer('quilometragem');
        });

        Schema::create('despesas', function (Blueprint $table): void {
            $table->increments('id_despesa');
            $table->integer('id_veiculo');
            $table->date('data_despesa');
            $table->string('tipo_despesa');
            $table->string('descricao')->nullable();
            $table->decimal('valor', 10, 2);
        });

        Schema::create('manutencoes', function (Blueprint $table): void {
            $table->increments('id_manutencao');
            $table->integer('id_veiculo');
            $table->date('data_manutencao');
            $table->string('tipo_manutencao');
            $table->string('descricao');
            $table->string('oficina')->nullable();
            $table->decimal('valor', 10, 2);
            $table->integer('quilometragem');
        });

        Schema::create('viagens', function (Blueprint $table): void {
            $table->increments('id_viagem');
            $table->integer('id_veiculo');
            $table->integer('id_motorista');
            $table->dateTime('data_saida');
            $table->dateTime('data_retorno')->nullable();
            $table->integer('km_inicial');
            $table->integer('km_final')->nullable();
            $table->string('destino');
            $table->string('finalidade')->nullable();
        });
    }

    protected function tearDown(): void
    {
        foreach (['viagens', 'manutencoes', 'despesas', 'abastecimentos', 'motoristas', 'veiculos'] as $table) {
            Schema::dropIfExists($table);
        }

        parent::tearDown();
    }

    public function test_api_lists_the_additional_resources(): void
    {
        foreach (['motoristas', 'viagens', 'abastecimentos', 'manutencoes', 'despesas'] as $resource) {
            $this->getJson('/api/'.$resource)
                ->assertOk()
                ->assertJsonStructure(['data']);
        }
    }

    public function test_api_creates_a_motorista(): void
    {
        $response = $this->postJson('/api/motoristas', [
            'nome' => 'Ana Souza',
            'cnh' => '12345678901',
            'categoria_cnh' => 'B',
            'telefone' => '41999999999',
            'data_admissao' => '2026-01-10',
            'status' => 'ativo',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.nome', 'Ana Souza');

        $this->assertDatabaseHas('motoristas', [
            'cnh' => '12345678901',
        ]);
    }
}
