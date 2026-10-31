<?php

namespace App\Services;

use App\Models\Viagem;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

class ViagemService
{
    public function listar(): Collection
    {
        return Viagem::with(['veiculo', 'motorista'])->get();
    }

    public function buscarPorId(int $id): ?Viagem
    {
        return Viagem::with(['veiculo', 'motorista'])->find($id);
    }

    public function iniciar(array $dados): void
    {
        DB::statement(
            'CALL gabriel_trabalho_bd.sp_iniciar_viagem(?, ?, ?, ?, ?)',
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
            'CALL gabriel_trabalho_bd.sp_finalizar_viagem(?, ?)',
            [
                $idViagem,
                $kmFinal,
            ]
        );
    }
}
