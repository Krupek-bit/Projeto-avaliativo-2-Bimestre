<?php

namespace App\Services;

use App\Models\Hodometro;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class HodometroService
{
    public function listar(): LengthAwarePaginator
    {
        return Hodometro::with('veiculo')
            ->orderByDesc('data_registro')
            ->orderByDesc('id_hodometro')
            ->paginate(10);
    }

    public function buscarPorId(int $id): ?Hodometro
    {
        return Hodometro::with('veiculo')->find($id);
    }

    public function registrar(array $dados): Hodometro
    {
        $hodometro = Hodometro::create([
            'id_veiculo' => $dados['id_veiculo'],
            'data_registro' => $dados['data_registro'],
            'quilometragem' => $dados['quilometragem'],
            'observacao' => $dados['observacao'] ?? null,
        ]);

        return $hodometro->refresh();
    }
}
