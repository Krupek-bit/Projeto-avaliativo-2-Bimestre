<?php

namespace App\Services;

use App\Models\HistoricoStatusVeiculo;
use Illuminate\Database\Eloquent\Collection;

class HistoricoStatusVeiculoService
{
    public function listar(): Collection
    {
        return HistoricoStatusVeiculo::with('veiculo')
            ->orderByDesc('data_alteracao')
            ->orderByDesc('id_historico')
            ->get();
    }

    public function buscarPorId(int $id): ?HistoricoStatusVeiculo
    {
        return HistoricoStatusVeiculo::with('veiculo')->find($id);
    }

    public function listarPorVeiculo(int $idVeiculo): Collection
    {
        return HistoricoStatusVeiculo::with('veiculo')
            ->where('id_veiculo', $idVeiculo)
            ->orderByDesc('data_alteracao')
            ->orderByDesc('id_historico')
            ->get();
    }
}
