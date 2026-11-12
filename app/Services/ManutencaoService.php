<?php

namespace App\Services;

use App\Models\Manutencao;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class ManutencaoService
{
    public function listar(): LengthAwarePaginator
    {
        return Manutencao::with('veiculo')
            ->orderByDesc('data_manutencao')
            ->orderByDesc('id_manutencao')
            ->paginate(10);
    }

    public function buscarPorId(int $id): ?Manutencao
    {
        return Manutencao::with('veiculo')->find($id);
    }

    public function registrar(array $dados): void
    {
        DB::statement(
            'CALL sp_registrar_manutencao(?, ?, ?, ?, ?, ?)',
            [
                $dados['id_veiculo'],
                $dados['tipo_manutencao'],
                $dados['descricao'],
                $dados['oficina'] ?? null,
                $dados['valor'],
                $dados['quilometragem'],
            ]
        );
    }

    public function concluir(int $idVeiculo): void
    {
        DB::statement(
            'CALL sp_concluir_manutencao(?)',
            [
                $idVeiculo,
            ]
        );
    }
}
