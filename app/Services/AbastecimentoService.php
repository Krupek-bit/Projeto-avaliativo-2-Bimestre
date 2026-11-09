<?php

namespace App\Services;

use App\Models\Abastecimento;
use Illuminate\Database\Eloquent\Collection;

class AbastecimentoService
{

    public function listar(): Collection
    {
        return Abastecimento::orderByDesc('data_abastecimento')
            ->orderByDesc('id_abastecimento')
            ->get();
    }


    public function buscarPorId(int $id): ?Abastecimento
    {
        return Abastecimento::find($id);
    }


    public function registrar(array $dados): Abastecimento
    {
        $abastecimento = Abastecimento::create([
            'id_veiculo' => $dados['id_veiculo'],
            'data_abastecimento' => $dados['data_abastecimento'],
            'tipo_combustivel' => $dados['tipo_combustivel'],
            'litros' => $dados['litros'],
            'valor_litro' => $dados['valor_litro'],
            'quilometragem' => $dados['quilometragem'],
        ]);

        return $abastecimento->refresh();
    }
}
