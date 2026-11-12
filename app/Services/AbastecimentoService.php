<?php

namespace App\Services;

use App\Models\Abastecimento;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class AbastecimentoService
{
    public function listar(): LengthAwarePaginator
    {
        return Abastecimento::with('veiculo')
            ->orderByDesc('data_abastecimento')
            ->orderByDesc('id_abastecimento')
            ->paginate(10);
    }

    public function buscarPorId(int $id): ?Abastecimento
    {
        return Abastecimento::with('veiculo')->find($id);
    }

    public function registrar(array $dados): Abastecimento
    {
        $abastecimento = Abastecimento::create([
            'id_veiculo' => $dados['id_veiculo'],
            'data_abastecimento' => $dados['data_abastecimento'],
            'tipo_combustivel' => $dados['tipo_combustivel'],
            'litros' => $dados['litros'],
            'valor_litro' => $dados['valor_litro'],
            'valor_total' => round($dados['litros'] * $dados['valor_litro'], 2),
            'quilometragem' => $dados['quilometragem'],
        ]);

        return $abastecimento->refresh();
    }

    public function atualizar(int $id, array $dados): ?Abastecimento
    {
        $abastecimento = Abastecimento::find($id);

        if (! $abastecimento) {
            return null;
        }

        $dados['valor_total'] = round($dados['litros'] * $dados['valor_litro'], 2);
        $abastecimento->update($dados);

        return $abastecimento->refresh();
    }

    public function excluir(int $id): bool
    {
        $abastecimento = Abastecimento::find($id);

        if (! $abastecimento) {
            return false;
        }

        return (bool) $abastecimento->delete();
    }
}
