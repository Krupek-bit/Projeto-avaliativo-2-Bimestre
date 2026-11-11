<?php

namespace App\Services;

use App\Models\Viagem;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class ViagemService
{
    public function listar(): LengthAwarePaginator
    {
        return Viagem::with(['veiculo', 'motorista'])
            ->orderByDesc('data_saida')
            ->paginate(10);
    }

    public function buscarPorId(int $id): ?Viagem
    {
        return Viagem::with(['veiculo', 'motorista'])->find($id);
    }

    public function iniciar(array $dados): void
    {
        DB::statement(
            'CALL sp_iniciar_viagem(?, ?, ?, ?, ?)',
            [
                $dados['id_veiculo'],
                $dados['id_motorista'],
                $dados['destino'],
                $dados['finalidade'] ?? null,
                $dados['km_inicial'],
            ]
        );
    }

    public function finalizar(int $idViagem, int $kmFinal): void
    {
        DB::statement(
            'CALL sp_finalizar_viagem(?, ?)',
            [
                $idViagem,
                $kmFinal,
            ]
        );
    }
}
