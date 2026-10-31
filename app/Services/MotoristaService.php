<?php

namespace App\Services;

use App\Models\Motorista;
use Illuminate\Database\Eloquent\Collection;

class MotoristaService
{
    public function listar(): Collection
    {
        return Motorista::all();
    }

    public function buscarPorId(int $id): ?Motorista
    {
        return Motorista::find($id);
    }

    public function cadastrar(array $dados): Motorista
    {
        return Motorista::create($dados);
    }

    public function atualizar(int $id, array $dados): ?Motorista
    {
        $motorista = Motorista::find($id);

        if (!$motorista) {
            return null;
        }

        $motorista->update($dados);

        return $motorista->refresh();
    }

    public function excluir(int $id): bool
    {
        $motorista = Motorista::find($id);

        if (!$motorista) {
            return false;
        }

        return (bool) $motorista->delete();
    }
}
