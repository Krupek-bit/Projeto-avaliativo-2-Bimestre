<?php

namespace Tests\Feature\Api;

use Tests\TestCase;
use App\Models\Veiculo;
use Illuminate\Foundation\Testing\RefreshDatabase;

class VeiculoApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_api_lista_veiculos(): void
    {
        $response = $this->getJson('/api/veiculos');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data',
            ]);
    }

    public function test_api_cadastra_veiculo(): void
    {
        $dados = [
            'placa' => 'ABC1234',
            'marca' => 'Fiat',
            'modelo' => 'Strada',
            'ano' => 2022,
            'tipo' => 'Utilitario',
            'capacidade' => 750,
            'status' => 'ativo',
        ];

        $response = $this->postJson('/api/veiculos', $dados);

        $response->assertStatus(201)
            ->assertJsonPath('data.placa', 'ABC1234');

        $this->assertDatabaseHas('veiculos', [
            'placa' => 'ABC1234',
        ]);
    }
}
